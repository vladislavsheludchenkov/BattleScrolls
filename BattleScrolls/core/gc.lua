-----------------------------------------------------------
-- GC Module
-- Controlled incremental garbage collection with rate limiting
--
-- The reason this exists is that the game doesn't always
-- reclaim the memory if GC doesn't run often enough, even if
-- GC eventually performed. That was observed for at least
-- hstructures and strings
-- See: https://www.esoui.com/forums/showthread.php?t=11507
--
-- The Add-On Memory gauge accounts for allocator backing memory
-- and some native resources, not just live Lua objects. Prompt
-- GC makes freed space reusable and limits further growth:
-- unpaced dry runs approached 90 MB, while CollectFullAsync
-- pacing held the gauge flat.
--
-- Freeing objects need not immediately lower the gauge. Allocator
-- fragmentation leaves free space mixed with live allocations,
-- and even empty segments may be returned later. Freed space can
-- be reused while those segments remain charged to the gauge.
--
-- Instead of scattered collectgarbage() calls, this module
-- provides a RequestGC() API that performs incremental GC
-- in small steps, yielding between each. Cooldown equals
-- the time the GC cycle took.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class GCModule
---@field private _fiber Fiber<any>|nil Currently running GC effect (includes sleep cooldown)
---@field private _remainingCycles number Number of cycles remaining to run (including current)
local GC = {
    _fiber = nil,
    _remainingCycles = 0,
}

-- Constants
---@type number Step size for collectgarbage("step") calls
local GC_STEP_SIZE = 3000

-- Weak table to detect when GC actually runs
---@type table<string, table|nil>
local weakTable = setmetatable({}, { __mode = "v" })

---Plants a sentinel value in the weak table
---@return table The sentinel object
local function plantGarbage()
    local sentinel = {}
    weakTable.sentinel = sentinel
    return sentinel
end

---Checks if the sentinel was collected
---@return boolean True if garbage was collected
local function isGarbageCollected()
    return weakTable.sentinel == nil
end

---Runs one GC cycle as an Effect
---@type Effect<nil>
local gcCycleEffect = LibEffect.Async(function()
        local cycleStartMs = GetGameTimeMilliseconds()

        local finishedByStep = false
        local finishedByWeak = false
        local sentinelPlanted = false

        while not finishedByStep and not finishedByWeak do
            local stepDone = collectgarbage("step", GC_STEP_SIZE)

            if stepDone then
                finishedByStep = true
            else
                -- Plant sentinel AFTER first step (mid-cycle)
                -- Objects created mid-cycle aren't collected until NEXT cycle,
                -- so if sentinel is gone, at least one full cycle completed.
                -- This is a fallback for when something else steals our 'true'.
                if not sentinelPlanted then
                    plantGarbage()
                    sentinelPlanted = true
                elseif isGarbageCollected() then
                    finishedByWeak = true
                end

                if not finishedByWeak then
                    -- Yield to next frame before continuing
                    LibEffect.Yield():Await()
                end
            end
        end

        local elapsedMs = GetGameTimeMilliseconds() - cycleStartMs

        -- Cooldown equals the time GC took
        if elapsedMs > 0 then
            LibEffect.Sleep(elapsedMs):Await()
        end
    end)
    :Ensure(function()
        GC._fiber = nil
        GC._remainingCycles = GC._remainingCycles - 1

        -- Start another cycle if more are requested
        if GC._remainingCycles > 0 then
            GC:_StartCycle()
        end
    end)

---Starts a new GC cycle
function GC:_StartCycle()
    if self._fiber then
        return -- Already running
    end

    self._fiber = gcCycleEffect:Run()
end

---Max GC stepping time per frame for CollectFullAsync. NOT redundant with
---LibAsync's stall-threshold budgeting: measured in-game, a task Call gets
---roughly one resume per frame, and a single step per frame is OUTPACED by
---ambient allocation on a large heap - the cycle never closes, marking
---outgrows stepping, and the heap runs away to the addon memory kill limit.
---The inner loop is the actual throughput source.
local COLLECT_FULL_FRAME_BUDGET_MS = 10

---Hard deadline per collect call: if reclamation cannot be confirmed within
---this window something is off (pinned sentinel, extreme heap); bail and let
---the caller proceed rather than spin while memory climbs.
local COLLECT_FULL_DEADLINE_MS = 3000

---Steps the collector until garbage that existed BEFORE the call is
---confirmed reclaimed, then resolves. A cycle-boundary return from
---collectgarbage("step") is NOT that proof - boundaries can land immediately
---or be crossed by other addons stepping the shared VM - so this waits for
---the weak sentinel to actually die (a complete mark+sweep over
---pre-existing objects). No cooldown sleep. For allocation-heavy loops that
---must not start the next burst until the previous one is reclaimed.
---@return Effect<boolean> True when the sentinel is reclaimed; false when the deadline expires
function GC:CollectFullAsync()
    return LibEffect.Async(function()
        -- Zero remaining cycles BEFORE cancelling: the cancelled fiber's
        -- Ensure decrements and would otherwise restart a background cycle
        -- underneath us
        self._remainingCycles = 0
        if self._fiber then
            self._fiber:Cancel()
            self._fiber = nil
        end

        -- Only two exits: the sentinel dies (reclamation PROVEN) or the
        -- deadline passes. No boundary-count exit: collectgarbage("step")
        -- returning true is not proof of reclamation, and exiting on it
        -- reintroduces the leak this function exists to prevent.
        plantGarbage()
        local startMs = GetGameTimeMilliseconds()
        while not isGarbageCollected() do
            local frameStartMs = GetGameTimeMilliseconds()
            if frameStartMs - startMs >= COLLECT_FULL_DEADLINE_MS then
                return false
            end
            repeat
                collectgarbage("step", GC_STEP_SIZE)
            until isGarbageCollected()
                or GetGameTimeMilliseconds() - frameStartMs >= COLLECT_FULL_FRAME_BUDGET_MS
            if not isGarbageCollected() then
                LibEffect.Yield():Await()
            end
        end
        return true
    end)
end

---Request garbage collection cycles
---@param count? number Number of cycles to run after this call (default 1)
function GC:RequestGC(count)
    count = count or 1

    if self._fiber ~= nil then
        -- Ensure 'count' MORE cycles after the current one finishes
        local needed = count + 1
        if self._remainingCycles < needed then
            self._remainingCycles = needed
        end
    else
        -- Not active - ensure at least 'count' cycles and start
        if self._remainingCycles < count then
            self._remainingCycles = count
        end
        self:_StartCycle()
    end
end

-- Export to BattleScrolls namespace
BattleScrolls.gc = GC

return GC

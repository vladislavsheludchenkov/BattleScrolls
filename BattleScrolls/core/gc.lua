-----------------------------------------------------------
-- GC Module
-- Controlled incremental garbage collection with rate limiting
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
---@return Effect<nil>
local function gcCycleEffect()
    return LibEffect.Async(function()
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
                -- This is a fallback for when another addon steals our 'true'.
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
    end)            :Ensure(function()
        GC._fiber = nil
        GC._remainingCycles = GC._remainingCycles - 1

        -- Start another cycle if more are requested
        if GC._remainingCycles > 0 then
            GC:_StartCycle()
        end
    end)
end

---Starts a new GC cycle
function GC:_StartCycle()
    if self._fiber then
        return -- Already running
    end

    self._fiber = gcCycleEffect():Run()
end

---Check if GC is currently running (includes sleep cooldown period)
---@return boolean True if GC cycle is active
function GC:_IsActive()
    return self._fiber ~= nil
end

---Request garbage collection cycles
---@param count? number Number of cycles to run after this call (default 1)
function GC:RequestGC(count)
    count = count or 1

    if self:_IsActive() then
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

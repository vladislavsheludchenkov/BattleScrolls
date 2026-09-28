-----------------------------------------------------------
-- Ultimate
-- Ultimate generation and usage tracking for Battle Scrolls
--
-- Generation is attributed per source ability via
-- ACTION_RESULT_POWER_ENERGIZE combat events (e.g. Pillager's
-- Profit); the remainder of actual pool gains (base combat
-- generation, which never fires an energize event) lands in a
-- synthetic bucket with ability id 0. Actual pool movement is
-- tracked via EVENT_POWER_UPDATE so continuous drains (werewolf
-- form, overload, timidity) are visible as totalDrained without
-- being mistaken for casts.
--
-- POWER_UPDATE values are frame-coalesced snapshots: a gain and a
-- drain landing in the same frame arrive as one net delta (the same
-- cancellation that made health-regen tracking off POWER_UPDATE
-- unreliable). Energize combat events stream per change, but their
-- order against the snapshot is NOT reliable - an energize can trail
-- the pool update that already contains it (seen in game 2026-08-23
-- as phantom "drained" equal to the energize amount). So deltas and
-- energizes accrue into a shared window, decomposed at settle: with
-- e = energized-in-window and d = net delta over the window,
--   d >= e: gained += d              (energized + base, no drain)
--   d <  e: gained += e, drained += e - d
-- The window is settled on the 200ms combat tick, but ONLY after a
-- quiet gap since the last ultimate event (so a settle never cuts
-- between a snapshot and its trailing energize, whichever order they
-- arrive in), with a hard age cap so dense event streams can't defer
-- forever - and always at finalize. Only non-energize gains
-- coinciding with drains inside one window remain indistinguishable.
--
-- Minor/Major Heroism generate Ultimate with NO energize event - the
-- gain reaches us only inside POWER_UPDATE deltas and stays in the
-- base bucket. An exact split is impossible: the Decisive weapon trait
-- gives every Ultimate gain a ~50% chance of +1, scaling Heroism's
-- real yield unpredictably. No tracking happens here - the buffs'
-- uptime already lives in the encounter's player-effect stats
-- (effectsOnPlayer, consent-gated there); the base bucket's UI tooltip
-- reads it and shows a trait-less estimate via the exported
-- HEROISM_BUFFS rates (ceil(uptime / 1.5s) * per-tick amount).
-- Minor Timidity is the drain-side mirror (1 Ultimate per 1.5s, also
-- eventless): pure downward movement and gains smaller than the
-- energize ledger both settle into totalDrained, so its ticks are
-- counted there - except when netted against a silent base gain inside
-- one settle window (the documented blind spot). The drained row's
-- tooltip shows its uptime the same way.
--
-- Casts are recorded from the ultimate action slot
-- (EVENT_ACTION_SLOT_ABILITY_USED, slot 8) - the only reliable
-- "the player pressed the button" signal, unaffected by
-- drain-over-time ultimates.
--
-- Interface:
--   ultimate:Initialize()   -- Register events + state observer
--   ultimate:Cleanup()      -- Unregister all events
--   ultimate.newState()     -- Factory for UltimateState subtable
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---A single ultimate cast (button press on the ultimate slot). A cast
---records the nominal slot cost separately from the pool. The renderer handles
---abilities such as Crypt Transfer that use the whole pool for their effect.
---@class UltCastEvent
---@field timeMs number Time offset from fight start in ms
---@field abilityId number Slotted ultimate ability id at press time
---@field poolBefore number|nil Pool value at press (nil in pre-v20 recordings)
---@field cost number|nil Slot cost at press (nil in pre-v20 recordings)

---Per-source ultimate gain accumulation (energize amounts vary per ability)
---@class UltGainBreakdown
---@field total number Total ultimate gained from this source
---@field ticks number Energize events seen (0 for the synthetic base bucket)
---@field minTick number Smallest single energize (0 when ticks == 0)
---@field maxTick number Largest single energize (0 when ticks == 0)

---Live ultimate tracking state (attached to BattleScrollsState)
---@class UltimateState
---@field startUlt number Ultimate points when combat started
---@field maxUlt number Ultimate pool cap at combat start
---@field lastUltValue number Last seen pool value (power update tracking)
---@field gainByAbilityId table<number, UltGainBreakdown> Energize accumulation by source ability id
---@field totalEnergized number Sum of all energize amounts (uncapped)
---@field totalGained number Actual pool increases (capped by pool max)
---@field totalDrained number Actual pool decreases (casts + drains)
---@field windowDelta number Net pool movement accrued since the last window settle
---@field pendingEnergized number Energize accepted by the pool since the last window settle (headroom-clamped)
---@field windowOpenedMs number Game time the open window's first event arrived (0 = no open window)
---@field lastEventMs number Game time of the last energize/power event (settle waits for a quiet gap)
---@field casts UltCastEvent[] Ultimate slot presses in order

---@class BattleScrollsUltimate : StateObserver, TickListener
---@field HEROISM_BUFFS table<number, number> Heroism buff ability id -> Ultimate per tick (exported for the UI tooltip)
---@field TIMIDITY_DEBUFFS table<number, number> Timidity debuff ability id -> Ultimate drained per tick (exported for the UI tooltip)
---@field FIXED_RATE_TICK_MS number Heroism/Timidity tick period (exported for the UI tooltip)
local ultimate = {}

BattleScrolls.ultimate = ultimate

-- Slot 8 = ultimate (ACTION_BAR_ULTIMATE_SLOT_INDEX + 1)
local ULT_SLOT = ACTION_BAR_ULTIMATE_SLOT_INDEX + 1

-- Heroism / Timidity: fixed-rate silent generation and drain. Uptime
-- comes from the encounter's player-effect stats; these rates feed the
-- tooltip estimates (generic named-buff ids, verified in game
-- 2026-08-24).
local FIXED_RATE_TICK_MS = 1500
---@type table<number, number> Buff ability id -> Ultimate per tick
local HEROISM_BUFFS = {
    [61708] = 1, -- Minor Heroism
    [61709] = 3, -- Major Heroism
}
---@type table<number, number> Debuff ability id -> Ultimate drained per tick
local TIMIDITY_DEBUFFS = {
    [140699] = 1, -- Minor Timidity
}
ultimate.HEROISM_BUFFS = HEROISM_BUFFS
ultimate.TIMIDITY_DEBUFFS = TIMIDITY_DEBUFFS
ultimate.FIXED_RATE_TICK_MS = FIXED_RATE_TICK_MS

-- Settle the window only this long after the last ultimate event, so a
-- snapshot and its trailing energize always land in the same window
local WINDOW_QUIET_MS = 100
-- ...but never let a window grow past this (dense streams must not defer
-- settling forever - wide windows blur base gains against drains)
local WINDOW_MAX_MS = 1000

---Creates a fresh UltimateState for a new combat encounter
---@return UltimateState
function ultimate.newState()
    return {
        startUlt = 0,
        maxUlt = 0,
        lastUltValue = 0,
        gainByAbilityId = {},
        totalEnergized = 0,
        totalGained = 0,
        totalDrained = 0,
        windowDelta = 0,
        pendingEnergized = 0,
        windowOpenedMs = 0,
        lastEventMs = 0,
        casts = {},
    }
end

---Stamps window bookkeeping for an incoming ultimate event
---@param u UltimateState
local function markWindowEvent(u)
    local now = GetGameTimeMilliseconds()
    if u.windowOpenedMs == 0 then
        u.windowOpenedMs = now
    end
    u.lastEventMs = now
end

---Captures the starting pool value when combat begins
function ultimate:OnStateInitialized()
    local state = BattleScrolls.state
    local u = state.ultimate
    local current, max = GetUnitPower("player", COMBAT_MECHANIC_FLAGS_ULTIMATE)
    u.startUlt = current or 0
    u.maxUlt = max or 0
    u.lastUltValue = u.startUlt
end

---Handles ultimate energize combat events (per-source attribution)
---@param abilityId number
---@param amount number
local function onUltimateEnergize(abilityId, amount)
    local state = BattleScrolls.state
    if not state or not state.initialized then
        return
    end
    if amount <= 0 then
        return
    end
    local u = state.ultimate
    local entry = u.gainByAbilityId[abilityId]
    if not entry then
        entry = { total = 0, ticks = 0, minTick = 0, maxTick = 0 }
        u.gainByAbilityId[abilityId] = entry
    end
    entry.total = entry.total + amount
    entry.ticks = entry.ticks + 1
    if entry.minTick == 0 or amount < entry.minTick then
        entry.minTick = amount
    end
    if amount > entry.maxTick then
        entry.maxTick = amount
    end
    u.totalEnergized = u.totalEnergized + amount
    -- Accrue into the current window, clamped to the pool's live headroom
    -- (overcapped portions never reach the pool and must not look like
    -- drains at settle)
    local headroom = u.maxUlt - u.lastUltValue - u.pendingEnergized
    if headroom > 0 then
        u.pendingEnergized = u.pendingEnergized + math.min(amount, headroom)
    end
    markWindowEvent(u)
end

---Handles player ultimate pool changes: accrues the delta into the
---current settle window (decomposition happens at settle - see header)
---@param powerValue number
local function onUltimatePowerUpdate(powerValue)
    local state = BattleScrolls.state
    if not state or not state.initialized then
        return
    end
    local u = state.ultimate
    u.windowDelta = u.windowDelta + (powerValue - u.lastUltValue)
    u.lastUltValue = powerValue
    markWindowEvent(u)
end

---Settles and closes the accrued window: decomposes net pool movement
---against the energize ledger into totalGained/totalDrained - see the
---header comment
---@param u UltimateState
local function settleWindow(u)
    local delta = u.windowDelta
    local energized = u.pendingEnergized
    u.windowDelta = 0
    u.pendingEnergized = 0
    u.windowOpenedMs = 0
    if delta == 0 and energized == 0 then
        return
    end
    if delta >= energized then
        u.totalGained = u.totalGained + delta
    else
        u.totalGained = u.totalGained + energized
        u.totalDrained = u.totalDrained + (energized - delta)
    end
end

---Settles the ultimate window on the shared 200ms combat tick, but only
---once the window is quiet (or too old) - see the header comment
function ultimate:OnCombatTick(_calc, _bossCalc)
    local state = BattleScrolls.state
    if not state or not state.initialized then
        return
    end
    local u = state.ultimate
    if u.windowOpenedMs == 0 then
        return
    end
    local now = GetGameTimeMilliseconds()
    if (now - u.lastEventMs) >= WINDOW_QUIET_MS or (now - u.windowOpenedMs) >= WINDOW_MAX_MS then
        settleWindow(u)
    end
end

---Handles ultimate slot presses (cast timestamps)
---@param actionSlotIndex number
local function onActionSlotUsed(actionSlotIndex)
    if actionSlotIndex ~= ULT_SLOT then
        return
    end
    local state = BattleScrolls.state
    if not state or not state.initialized then
        return
    end

    -- Resolve ability id: scribing abilities return craftedAbilityId from GetSlotBoundId
    local abilityId
    if GetSlotType(actionSlotIndex) == ACTION_TYPE_CRAFTED_ABILITY then
        abilityId = GetAbilityIdForCraftedAbilityId(GetSlotBoundId(actionSlotIndex))
    else
        abilityId = GetSlotBoundId(actionSlotIndex)
    end
    if not abilityId or abilityId <= 0 then
        return
    end

    local u = state.ultimate
    u.casts[#u.casts + 1] = {
        timeMs = GetGameTimeMilliseconds() - state.fightStartTimeMs,
        abilityId = abilityId,
        poolBefore = u.lastUltValue,
        cost = GetSlotAbilityCost(actionSlotIndex, COMBAT_MECHANIC_FLAGS_ULTIMATE) or 0,
    }
end

---Encounter-ready ultimate data (stored per encounter)
---@class UltimateData
---@field startUlt number Ultimate points at combat entry
---@field maxUlt number Ultimate pool cap at combat start
---@field gainByAbilityId table<number, UltGainBreakdown> Gains by source ability id (0 = base combat generation, tickless; includes Heroism - the Decisive trait makes an exact split impossible)
---@field totalGained number Actual pool increases over the fight
---@field totalDrained number Actual pool decreases over the fight
---@field casts UltCastEvent[] Ultimate slot presses in order

---Finalizes the state into encounter-ready UltimateData.
---The unattributed remainder of actual gains (base combat generation)
---is folded into ability id 0.
---@param u UltimateState
---@return UltimateData|nil data Nil when nothing was tracked
function ultimate.finalize(u)
    settleWindow(u)
    if u.totalGained == 0 and u.totalDrained == 0 and #u.casts == 0 and u.startUlt == 0 then
        return nil
    end

    ---@type table<number, UltGainBreakdown>
    local gains = {}
    for abilityId, g in pairs(u.gainByAbilityId) do
        gains[abilityId] = { total = g.total, ticks = g.ticks, minTick = g.minTick, maxTick = g.maxTick }
    end
    local base = u.totalGained - u.totalEnergized
    if base > 0 then
        local zero = gains[0]
        if not zero then
            zero = { total = 0, ticks = 0, minTick = 0, maxTick = 0 }
            gains[0] = zero
        end
        zero.total = zero.total + base
    end

    ---@type UltimateData
    return {
        startUlt = u.startUlt,
        maxUlt = u.maxUlt,
        gainByAbilityId = gains,
        totalGained = u.totalGained,
        totalDrained = u.totalDrained,
        casts = u.casts,
    }
end

---Registers all ultimate tracking event handlers
function ultimate:Initialize()
    BattleScrolls.state:RegisterObserver(self)
    BattleScrolls.combatTicker:registerListener(self)

    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Ultimate_Slot", EVENT_ACTION_SLOT_ABILITY_USED,
            function(_, actionSlotIndex)
                onActionSlotUsed(actionSlotIndex)
            end)

    -- Energize events targeting the player; power type checked in Lua
    -- (the C++ POWER_TYPE filter applies to EVENT_POWER_UPDATE, not combat events)
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Ultimate_Energize", EVENT_COMBAT_EVENT,
            function(_, result, isError, _abilityName, _abilityGraphic, _abilityActionSlotType, _sourceName, _sourceType, _targetName, _targetType, hitValue, powerType, _damageType, _log, _sourceUnitID, _targetUnitID, abilityID, _overflow)
                if isError or result ~= ACTION_RESULT_POWER_ENERGIZE then
                    return
                end
                if powerType ~= COMBAT_MECHANIC_FLAGS_ULTIMATE then
                    return
                end
                onUltimateEnergize(abilityID, hitValue)
            end)
    EVENT_MANAGER:AddFilterForEvent("BattleScrolls_Ultimate_Energize", EVENT_COMBAT_EVENT,
            REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_POWER_ENERGIZE,
            REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER,
            REGISTER_FILTER_IS_ERROR, false)

    -- Actual pool movement (base generation, casts, drain-over-time)
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Ultimate_Power", EVENT_POWER_UPDATE,
            function(_, _unitTag, _powerIndex, powerType, powerValue, _powerMax, _powerEffectiveMax)
                if powerType ~= COMBAT_MECHANIC_FLAGS_ULTIMATE then
                    return
                end
                onUltimatePowerUpdate(powerValue)
            end)
    EVENT_MANAGER:AddFilterForEvent("BattleScrolls_Ultimate_Power", EVENT_POWER_UPDATE,
            REGISTER_FILTER_UNIT_TAG, "player",
            REGISTER_FILTER_POWER_TYPE, COMBAT_MECHANIC_FLAGS_ULTIMATE)
end

---Unregisters all event handlers for cleanup/hot reload
function ultimate:Cleanup()
    BattleScrolls.state:UnregisterObserver(self)
    BattleScrolls.combatTicker:unregisterListener(self)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Ultimate_Slot", EVENT_ACTION_SLOT_ABILITY_USED)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Ultimate_Energize", EVENT_COMBAT_EVENT)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Ultimate_Power", EVENT_POWER_UPDATE)
end

-----------------------------------------------------------
-- State
-- Combat state machine for Battle Scrolls
--
-- Tracks all combat data during a fight: damage, healing,
-- unit information, and boss encounters. Uses observer
-- pattern to notify other modules of combat lifecycle.
--
-- Key responsibilities:
--   - Route combat events to appropriate handlers
--   - Maintain damage/healing accumulators
--   - Track boss encounters and fight types
--   - Buffer pre-combat events for replay
--   - Notify observers of combat start/end
--
-- Observer interface:
--   observer:OnStateInitialized()  -- Combat started
--   observer:OnStatePreReset()     -- Combat ended, data available
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---Per-ability damage breakdown with crit stats
---@class DamageBreakdown
---@field total number Total damage value
---@field ticks number Total number of ticks (hits)
---@field critTicks number Number of critical ticks
---@field minTick number|nil Minimum tick value
---@field maxTick number|nil Maximum tick value

---Damage tracking broken down by various dimensions
---@class DamageDone
---@field total number
---@field byDotOrDirect { dot: number , direct: number }
---@field byDamageType table<DamageType, number>
---@field byAbilityId table<number, DamageBreakdown>

---Lean healing totals without crit stats (for aggregates)
---@class HealingTotals
---@field raw number
---@field real number
---@field overheal number

---Per-ability healing breakdown with crit stats
---@class HealingBreakdown
---@field raw number
---@field real number
---@field overheal number
---@field ticks number Total number of ticks (hits)
---@field critTicks number Number of critical ticks
---@field minTick number|nil Minimum tick value (raw)
---@field maxTick number|nil Maximum tick value (raw)

---@class HealingDoneDiffSource
---@field total HealingTotals
---@field byHotVsDirect { hot: HealingTotals, direct: HealingTotals }
---@field bySourceUnitIdByAbilityId table<number, table<number, HealingBreakdown>> Nested: sourceUnitId -> abilityId -> healing

---@class HealingDone
---@field total HealingTotals
---@field byHotVsDirect { hot: HealingTotals, direct: HealingTotals }
---@field byAbilityId table<number, HealingBreakdown>

---@class HealingStats
---@field selfHealing HealingDoneDiffSource
---@field healingOutToGroup table<number, HealingDoneDiffSource> by target id
---@field healingInFromGroup table<number, HealingDone> by source id

---Individual proc occurrence
---@class ProcEvent
---@field targetUnitId number
---@field timestampMs number Absolute game time

---Effect stats for uptime tracking with player attribution
---Mirrors BS_EffectStats hstructure in havok/structures.lua
---@class EffectStats
---@field abilityId number
---@field effectType number BUFF_EFFECT_TYPE_BUFF or BUFF_EFFECT_TYPE_DEBUFF
---@field totalActiveTimeMs number Total time effect was active
---@field timeAtMaxStacksMs number Time spent at max observed stacks (0 if not stackable)
---@field applications number Number of times effect was applied
---@field maxStacks number Peak stack count observed
---@field playerActiveTimeMs number Time YOU kept this effect up
---@field playerTimeAtMaxStacksMs number Time at max stacks applied by you
---@field playerApplications number Times YOU applied this effect
---@field peakConcurrentInstances number Peak number of concurrent instances of this effect (e.g., 2 Relequen)
---@field lastFinalizedMs number Latest endTimeMs when totalActiveTimeMs was accumulated (for retroactive correction)
---@field lastFinalizedMaxStacksMs number Latest endTimeMs when timeAtMaxStacksMs was accumulated (for retroactive correction)
---@field lastFinalizedPlayerMs number Latest endTimeMs when playerActiveTimeMs was accumulated (for retroactive correction)
---@field lastFinalizedPlayerMaxStacksMs number Latest endTimeMs when playerTimeAtMaxStacksMs was accumulated (for retroactive correction)

---Active effect instance for tracking during combat
---@class EffectInstance
---@field abilityId number
---@field effectType number BUFF_EFFECT_TYPE_BUFF or BUFF_EFFECT_TYPE_DEBUFF
---@field startTimeMs number Game time when effect was gained
---@field stackCount number Current stack count
---@field maxStacksStartMs number|nil When we reached max stacks (nil if not at max)
---@field currentMaxStacks number Current observed max for this effect
---@field appliedByPlayer boolean For boss effects: sourceType == COMBAT_UNIT_TYPE_PLAYER
---@field unitTag string Target unit tag (for aggregation lookup)
---@field beginTime number|nil ESO effect begin time (nil for backfilled effects, set on first UPDATED)

---Cached ability metadata
---@class AbilityInfo
---@field overTimeOrDirect { overTime: boolean|nil, direct: boolean|nil }
---@field damageTypes table<number, boolean> Set of ESO damage type constants

---State observer interface for combat lifecycle notifications
---@class StateObserver
---@field OnStateInitialized fun(self: StateObserver)|nil Called when combat starts
---@field OnStatePreReset fun(self: StateObserver)|nil Called when combat ends, before state reset

---Per-boss tracking data
---@class BossData
---@field name string Boss name
---@field unitTag string Boss unit tag ("boss1", "boss2", etc.)
---@field unitId number|nil Boss unit ID (nil until first damage or effect event)
---@field confirmed boolean Whether unitId was set via effect event (authoritative) vs name matching (tentative)
---@field tagSeq number Sequence number within this tag (0=first boss, increments on tag reuse)

---Main combat tracking state
---@class BattleScrollsState : EffectContext
---@field initialized boolean
---@field inCombat boolean
---@field isBossFight boolean
---@field isInPortal boolean Cloudrest/Sunspire portal phases
---@field fightStartTimeMs number
---@field fightStartRealTimeS number
---@field currentZoneId number
---@field unitIdToName table<number, string> Cached names
---@field unitIdToIsFriendly table<number, boolean> Cached friendliness
---@field abilityInfo table<number, AbilityInfo> Cached ability metadata
---@field procs table<number, ProcEvent[]> Proc events by ability ID
---@field damageByUnitId table<number, table<number, DamageDone>> Personal damage done, nested: sourceUnitId -> targetUnitId -> damage
---@field damageByUnitIdGroup table<number, table<number, DamageDone>> Group damage done, nested: sourceUnitId -> targetUnitId -> damage
---@field damageTakenByUnitId table<number, table<number, DamageDone>> Damage taken, nested: sourceUnitId -> targetUnitId -> damage
---@field damageUnknownByUnitId table<number, table<number, DamageDone>> Damage with unknown friendliness, nested: sourceUnitId -> targetUnitId -> damage
---@field healingStats HealingStats
---@field bossesByTag table<string, BossData>
---@field bossesByUnitId table<number, BossData>
---@field bossUnitIdRedirects table<number, number> Maps newUnitId → canonicalUnitId (merging if boss unit recreated on client)
---@field failedToAssignBossUnitIds table<number, boolean>
---@field lastDamageDoneMs number
---@field effectsOnPlayer table<number, EffectStats> Effects on player with attribution, keyed by abilityId
---@field effectsOnBosses table<string, table<number, EffectStats>> Effects on bosses, keyed by unitTag ("boss1")
---@field effectsOnGroup table<string, table<number, EffectStats>> Effects on group members, keyed by displayName ("PlayerName")
---@field activeEffects table<string, EffectInstance> Currently active effects, keyed by "unitTag:effectSlot"
---@field playerAliveState UnitAliveState|nil Player alive/dead state (separate from unitAliveState)
---@field unitAliveState table<string, UnitAliveState> Per-unit alive/dead state tracking, keyed by unitTag (bosses) or displayName (group)
---@field bossNames table<string, string> Maps unitTag to boss name for UI display
---@field pendingSharedData SharedDataEntry[]|nil Shared encounter data received during combat
---@field playerDeathCount number Number of times player died this fight
---@field deathRecaps DeathRecapSnapshot[] All captured death recaps (appended on each death)
---@field playerSetup PlayerSetup|nil

--- @type BattleScrollsState
local state = {}

BattleScrolls.state = state

-- Observer pattern for state lifecycle events
---@type StateObserver[]
local observers = {}

-- =============================================================================
-- PRE-COMBAT EVENT BUFFER
-- Buffers damage events when out of combat, replays last N ms on combat start
-- =============================================================================

local PRE_COMBAT_BUFFER_MAX_SIZE = 200  -- Max events to keep (ring buffer)
local PRE_COMBAT_LOOKBACK_MS = 1000     -- Replay events from last 1 second

---@class PreCombatEvent
---@field timestampMs number Game time when event occurred
---@field type "personal"|"group" Event type for routing replay
---@field result number Combat result
---@field sourceUnitID number
---@field targetUnitID number
---@field abilityID number
---@field hitValue number
---@field overflow number
---@field damageType number
---@field sourceName string
---@field targetName string
---@field sourceType number
---@field targetType number

---@class PreCombatBuffer
---@field head number Ring buffer head (oldest item)
---@field tail number Ring buffer tail (newest item index)
---@field count number Current item count
---@field items table<number, PreCombatEvent>

---@type PreCombatBuffer
local preCombatBuffer = {
    head = 1,
    tail = 0,
    count = 0,
    items = {},
}

---Enqueue an event to the pre-combat buffer (ring buffer)
---@param event PreCombatEvent
local function bufferPreCombatEvent(event)
    preCombatBuffer.tail = preCombatBuffer.tail + 1
    preCombatBuffer.items[preCombatBuffer.tail] = event
    preCombatBuffer.count = preCombatBuffer.count + 1

    -- If buffer is full, advance head (drop oldest)
    if preCombatBuffer.count > PRE_COMBAT_BUFFER_MAX_SIZE then
        preCombatBuffer.items[preCombatBuffer.head] = nil
        preCombatBuffer.head = preCombatBuffer.head + 1
        preCombatBuffer.count = preCombatBuffer.count - 1
    end
end

---Clear the pre-combat buffer
local function clearPreCombatBuffer()
    preCombatBuffer.items = {}
    preCombatBuffer.head = 1
    preCombatBuffer.tail = 0
    preCombatBuffer.count = 0
end

---Get events from buffer within time window
---@param cutoffMs number Only return events with timestampMs >= cutoffMs
---@return PreCombatEvent[] events Events in chronological order
local function getBufferedEventsAfter(cutoffMs)
    local result = {}
    for i = preCombatBuffer.head, preCombatBuffer.tail do
        local event = preCombatBuffer.items[i]
        if event and event.timestampMs >= cutoffMs then
            table.insert(result, event)
        end
    end
    return result
end

---Register an observer to receive state lifecycle notifications
---@param observer StateObserver Object with OnStateInitialized and/or OnStatePreReset methods
function BattleScrolls.state:RegisterObserver(observer)
    table.insert(observers, observer)
end

---Unregister an observer for cleanup/hot reload support
---@param observer StateObserver Observer to unregister
function BattleScrolls.state:UnregisterObserver(observer)
    for i = #observers, 1, -1 do
        if observers[i] == observer then
            table.remove(observers, i)
            return
        end
    end
end

---Notify all observers that state has been initialized (combat started)
function BattleScrolls.state:NotifyInitialized()
    -- Backfill any already-active effects when combat starts
    BattleScrolls.effects.backfill(self)

    for _, observer in ipairs(observers) do
        if observer.OnStateInitialized then
            observer:OnStateInitialized()
        end
    end
end

---Notify all observers before state is reset (combat ended, data still available)
function BattleScrolls.state:NotifyPreReset()
    -- Note: effects.finalize() is now called in scribe's async chain after queue drain

    for _, observer in ipairs(observers) do
        if observer.OnStatePreReset then
            observer:OnStatePreReset()
        end
    end
end

function BattleScrolls.state:Reset()
    -- Notify observers before clearing state (so they can read final data)
    if self.initialized then
        self:NotifyPreReset()
    end

    -- if BattleScrolls.log and self.damageUnknownByUnitId then
    --     BattleScrolls.log.Warn(function ()
    --         local unknownTargets = {}

    --         for _, i in pairs(self.damageUnknownByUnitId) do
    --             for targetUnitId, _ in pairs(i) do
    --                 table.insert(unknownTargets, targetUnitId)
    --             end
    --         end

    --         if #unknownTargets == 0 then
    --             return nil
    --         end

    --         local unknownTargetsByNameOrId = {}
    --         for _, targetUnitId in ipairs(unknownTargets) do
    --             local name = self.unitIdToName[targetUnitId]
    --             if name then
    --                 table.insert(unknownTargetsByNameOrId, string.format("%s (%d)", name, targetUnitId))
    --             else
    --                 table.insert(unknownTargetsByNameOrId, tostring(targetUnitId))
    --             end
    --         end

    --         return string.format("Resetting state. Unknown target unit IDs: %s", table.concat(unknownTargetsByNameOrId, ", "))
    --     end)
    -- end

    self.initialized = false
    self.inCombat = false
    self.isBossFight = false
    self.isPlayerFight = false
    self.isDummyFight = false
    self.isInPortal = false
    self.fightStartTimeMs = 0
    self.fightStartRealTimeS = 0
    self.currentZoneId = 0
    self.unitIdToName = {}
    self.unitIdToIsFriendly = {}

    -- Clear combat tracking state via accumulators module
    BattleScrolls.accumulators.clear(self)
    self.bossesByTag = {}
    self.bossesByUnitId = {}
    self.bossUnitIdRedirects = {}
    self.failedToAssignBossUnitIds = {}
    self.pendingSharedData = nil
    self.playerSetup = nil
    self.lastDamageDoneMs = 0
    self.playerDeathCount = 0
    self.deathRecaps = {}

    -- Clear effect tracking state via effects module
    BattleScrolls.effects.clear(self)

    -- Clear pre-combat event buffer
    clearPreCombatBuffer()
end

---@return BattleScrollsState
function BattleScrolls.state:Snapshot()
    local snapshot = {}

    snapshot.initialized = self.initialized
    snapshot.inCombat = self.inCombat
    snapshot.isBossFight = self.isBossFight
    snapshot.isPlayerFight = self.isPlayerFight
    snapshot.isDummyFight = self.isDummyFight
    snapshot.isInPortal = self.isInPortal
    snapshot.fightStartTimeMs = self.fightStartTimeMs
    snapshot.fightStartRealTimeS = self.fightStartRealTimeS
    snapshot.currentZoneId = self.currentZoneId
    snapshot.unitIdToName = self.unitIdToName
    snapshot.unitIdToIsFriendly = self.unitIdToIsFriendly
    snapshot.abilityInfo = self.abilityInfo
    snapshot.procs = self.procs
    snapshot.damageByUnitId = self.damageByUnitId
    snapshot.damageByUnitIdGroup = self.damageByUnitIdGroup
    snapshot.damageTakenByUnitId = self.damageTakenByUnitId
    snapshot.damageUnknownByUnitId = self.damageUnknownByUnitId
    snapshot.healingStats = self.healingStats
    snapshot.bossesByTag = self.bossesByTag
    snapshot.bossesByUnitId = self.bossesByUnitId
    snapshot.failedToAssignBossUnitIds = self.failedToAssignBossUnitIds
    snapshot.lastDamageDoneMs = self.lastDamageDoneMs
    snapshot.effectsOnPlayer = self.effectsOnPlayer
    snapshot.effectsOnBosses = self.effectsOnBosses
    snapshot.effectsOnGroup = self.effectsOnGroup
    snapshot.activeEffects = self.activeEffects
    snapshot.playerAliveState = self.playerAliveState
    snapshot.unitAliveState = self.unitAliveState
    snapshot.bossNames = self.bossNames
    snapshot.bossUnitIdRedirects = self.bossUnitIdRedirects
    snapshot.pendingSharedData = self.pendingSharedData
    snapshot.playerDeathCount = self.playerDeathCount
    snapshot.deathRecaps = self.deathRecaps
    snapshot.playerSetup = self.playerSetup

    return snapshot
end

BattleScrolls.state:Reset()

-- Local alias for BOSS_TAGS (needed by ShouldReset and RefreshBosses)
---@type table<number, string>
local BOSS_TAGS = BattleScrolls.constants.BOSS_TAGS

---Returns false if in combat, in portal, or bosses are in progress
---@return boolean
function BattleScrolls.state:ShouldReset()
    if not self.initialized then
        -- BattleScrolls.log.Trace("ShouldReset: not initialized")
        return false
    end

    if self.inCombat then
        -- BattleScrolls.log.Trace("ShouldReset: in combat")
        return false
    end
    if self.isInPortal then
        -- BattleScrolls.log.Trace("ShouldReset: in portal")
        return false
    end

    local totalBossHP, maxTotalBossHP = 0, 0

    for i = BOSS_RANK_ITERATION_BEGIN, BOSS_RANK_ITERATION_END do
        local bossTag = BOSS_TAGS[i]
        if GetRawUnitName(bossTag) ~= "" and not IsUnitDead(bossTag) then
            local bossHP, maxBossHP, _ = GetUnitPower(bossTag, COMBAT_MECHANIC_FLAGS_HEALTH)
            totalBossHP = totalBossHP + bossHP
            maxTotalBossHP = maxTotalBossHP + maxBossHP

            -- BattleScrolls.log.Trace(function()
            --     return string.format("ShouldReset: boss %s (%s) exists with HP %d/%d", GetUnitName(bossTag), bossTag, bossHP, maxBossHP)
            -- end)
        end
    end

    -- Don't reset if boss fight is in progress
    if totalBossHP > 0 and totalBossHP < maxTotalBossHP then
        -- BattleScrolls.log.Trace(string.format("ShouldReset: boss fight in progress with total HP %d/%d", totalBossHP, maxTotalBossHP))
        return false
    end

    -- BattleScrolls.log.Trace("ShouldReset: all clear")
    return true
end

function BattleScrolls.state:RefreshBosses()
    for i = BOSS_RANK_ITERATION_BEGIN, BOSS_RANK_ITERATION_END do
        local bossTag = BOSS_TAGS[i]
        local bossName = GetRawUnitName(bossTag)
        if bossName ~= "" and not IsUnitDead(bossTag) then
            local bossData = self.bossesByTag[bossTag]
            if not bossData then
                -- New tag: create BossData
                self.bossesByTag[bossTag] = {
                    name = bossName,
                    unitTag = bossTag,
                    unitId = nil,
                    confirmed = false,
                    tagSeq = 0,
                }
            elseif bossData.name ~= bossName then
                -- Tag reuse: different boss name on same tag. Old BossData stays in bossesByUnitId.
                self.bossesByTag[bossTag] = {
                    name = bossName,
                    unitTag = bossTag,
                    unitId = nil,
                    confirmed = false,
                    tagSeq = (bossData.tagSeq or 0) + 1,
                }
            end
        end
    end
end

---Correlates a boss unit tag with a unit ID from an effect event (authoritative source).
---Called from onBossEffect on every non-faded boss effect event. Fast path (unitId unchanged)
---is two table lookups + comparison.
---@param unitTag string Boss unit tag ("boss1", etc.)
---@param unitId number Unit ID from the effect event
---@param unitName string Boss unit name from the effect event
function BattleScrolls.state:CorrelateBossUnitId(unitTag, unitId, unitName)
    -- Ensure every boss unitId has a name in unitIdToName. Effect events are often
    -- the first source of a boss unitId (before any damage event), and without this,
    -- the unitId can end up in bossesUnits with no corresponding name entry.
    self:UpdateUnitName(unitId, unitName)

    local bossData = self.bossesByTag[unitTag]
    if not bossData then
        -- Tag not tracked yet (effect arrived before RefreshBosses). Create entry now.
        bossData = {
            name = unitName,
            unitTag = unitTag,
            unitId = unitId,
            confirmed = true,
            tagSeq = 0,
        }
        self.bossesByTag[unitTag] = bossData
        self.bossesByUnitId[unitId] = bossData
        self.failedToAssignBossUnitIds[unitId] = nil
        return
    end

    if bossData.unitId == unitId then
        -- Common case: same unit ID, just confirm it
        bossData.confirmed = true
        return
    end

    if self.bossUnitIdRedirects[unitId] then
        return -- Already redirected, nothing to do
    end

    if bossData.unitId == nil then
        -- Fresh assignment from effect event (authoritative)
        bossData.unitId = unitId
        bossData.confirmed = true
        self.bossesByUnitId[unitId] = bossData
        -- Clear from failed set in case damage events had tried and failed
        self.failedToAssignBossUnitIds[unitId] = nil
    elseif bossData.confirmed then
        if bossData.name ~= unitName then
            -- Tag reuse missed by OnBossUnitCreated/RefreshBosses: different boss on same tag.
            -- Old BossData stays in bossesByUnitId. Create new entry for the new boss.
            bossData = {
                name = unitName,
                unitTag = unitTag,
                unitId = unitId,
                confirmed = true,
                tagSeq = (bossData.tagSeq or 0) + 1,
            }
            self.bossesByTag[unitTag] = bossData
            self.bossesByUnitId[unitId] = bossData
            self.failedToAssignBossUnitIds[unitId] = nil
        else
            -- Same boss, new unitId (boss unit recreated on client, e.g. after portal)
            -- Set up redirect: future damage to new unitId → canonical unitId
            local canonicalUnitId = bossData.unitId
            self.bossUnitIdRedirects[unitId] = canonicalUnitId
            self.bossesByUnitId[unitId] = bossData
            self.failedToAssignBossUnitIds[unitId] = nil
            -- Ensure canonical unitId has a name (it may only have been set via effects,
            -- never via a personal damage event)
            self:UpdateUnitName(canonicalUnitId, unitName)
            -- Retroactively merge any damage already recorded under the new unitId
            BattleScrolls.accumulators.redirectBossUnitId(self, unitId, canonicalUnitId)
        end
    else
        -- Tentative assignment was wrong (e.g. copy got matched first)
        -- Remove the wrong mapping, replace with authoritative one
        local oldUnitId = bossData.unitId
        self.bossesByUnitId[oldUnitId] = nil
        bossData.unitId = unitId
        bossData.confirmed = true
        self.bossesByUnitId[unitId] = bossData
        self.failedToAssignBossUnitIds[unitId] = nil
    end
end

---Handles EVENT_UNIT_CREATED for boss tags. Detects tag reuse (different boss name on same tag).
---@param unitTag string Boss unit tag ("boss1", etc.)
function BattleScrolls.state:OnBossUnitCreated(unitTag)
    local bossData = self.bossesByTag[unitTag]
    local bossName = GetRawUnitName(unitTag)
    if not bossData then
        -- First time seeing this tag during combat
        self.bossesByTag[unitTag] = {
            name = bossName,
            unitTag = unitTag,
            unitId = nil,
            confirmed = false,
            tagSeq = 0,
        }
    elseif bossData.name ~= bossName then
        -- Tag reuse: different boss. Old BossData stays in bossesByUnitId.
        self.bossesByTag[unitTag] = {
            name = bossName,
            unitTag = unitTag,
            unitId = nil,
            confirmed = false,
            tagSeq = (bossData.tagSeq or 0) + 1,
        }
    end
    -- Same name: do nothing. Keep existing BossData with canonical unitId.
    -- CorrelateBossUnitId will establish a redirect when the first effect event arrives.
end

-- Local aliases for constants (performance)
---@type table<number, boolean>
local personalTypesSet = BattleScrolls.constants.personalTypesSet
---@type table<number, boolean>
local friendlyTypesSet = BattleScrolls.constants.friendlyTypesSet
---@type table<number, boolean>
local damageResultsSet = BattleScrolls.constants.damageResultsSet
---@type table<number, boolean>
local healingResultsSet = BattleScrolls.constants.healingResultsSet
---@type table<number, boolean>
local ignoredHealingAbilityIds = BattleScrolls.constants.ignoredHealingAbilityIds
---@type table<number, boolean>
local portalEffectsSet = BattleScrolls.constants.portalEffectsSet

---Central combat event dispatcher with Lua-side filtering
---Routes events to appropriate handlers based on source/target type and result
---@param eventCode number
---@param result number
---@param isError boolean
---@param abilityName string
---@param abilityGraphic string
---@param abilityActionSlotType number
---@param sourceName string
---@param sourceType number
---@param targetName string
---@param targetType number
---@param hitValue number
---@param powerType number
---@param damageType number
---@param log string
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param overflow number
function BattleScrolls.state:OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitID, targetUnitID, abilityID, overflow)
    -- Extra safety check for isError (also filtered at ESO level)
    if isError then
        return
    end

    local isPersonalSource = personalTypesSet[sourceType]
    local isPersonalTarget = personalTypesSet[targetType]
    local isGroupSource = sourceType == COMBAT_UNIT_TYPE_GROUP
    local isGroupTarget = targetType == COMBAT_UNIT_TYPE_GROUP
    local isDamageResult = damageResultsSet[result]
    local isHealingResult = healingResultsSet[result]

    -- Damage events
    if isDamageResult then
        -- Personal damage done (source is player/pet/companion)
        if isPersonalSource then
            self:OnPersonalDamageDone(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitID, targetUnitID, abilityID, overflow)
        end

        -- Group damage done (source is group member)
        if isGroupSource or (not isPersonalSource and not isPersonalTarget and not isGroupTarget) then
            self:OnGroupDamageDone(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitID, targetUnitID, abilityID, overflow)
        end

        -- Damage taken (target is player/pet/companion)
        if isPersonalTarget then
            self:OnDamageTaken(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitID, targetUnitID, abilityID, overflow)
        end

        self.lastDamageDoneMs = GetGameTimeMilliseconds()
    end

    -- Healing events
    if isHealingResult and not ignoredHealingAbilityIds[abilityID] then
        -- Self-healing (source and target both personal)
        if isPersonalSource and isPersonalTarget then
            self:OnSelfHealing(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitID, targetUnitID, abilityID, overflow)
        end

        -- Healing out to group (source is personal, target is group)
        if isPersonalSource and isGroupTarget then
            self:OnHealingOut(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitID, targetUnitID, abilityID, overflow)
        end

        -- Healing in from group (source is group, target is personal)
        if isGroupSource and isPersonalTarget then
            self:OnHealingIn(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitID, targetUnitID, abilityID, overflow)
        end
    end
end

---Unregisters all event handlers for cleanup/hot reload
function BattleScrolls.state:Cleanup()
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_State", EVENT_COMBAT_EVENT)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_State", EVENT_PLAYER_COMBAT_STATE)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_State", EVENT_PLAYER_ACTIVATED)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_State", EVENT_BOSSES_CHANGED)

    for abilityId, _ in pairs(portalEffectsSet) do
        local eventName = string.format("BattleScrolls_State_%d", abilityId)
        EVENT_MANAGER:UnregisterForEvent(eventName, EVENT_EFFECT_CHANGED)
    end
end

---Registers event handlers for combat tracking with Lua-side filtering
function BattleScrolls.state:Initialize()
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_State", EVENT_COMBAT_EVENT, function(...)
        self:OnCombatEvent(...)
    end)
    EVENT_MANAGER:AddFilterForEvent("BattleScrolls_State", EVENT_COMBAT_EVENT,
            REGISTER_FILTER_IS_ERROR, false)

    EVENT_MANAGER:RegisterForEvent("BattleScrolls_State", EVENT_PLAYER_COMBAT_STATE,
            function(_, inCombat)
                self:ChangePlayerCombatState(inCombat)
            end)

    for abilityId, _ in pairs(portalEffectsSet) do
        local eventName = string.format("BattleScrolls_State_%d", abilityId)
        EVENT_MANAGER:RegisterForEvent(eventName, EVENT_EFFECT_CHANGED,
                function(eventCode, changeType, _effectSlot, _effectName, _unitTag, _beginTime, _endTime, _stackCount, _iconName, _buffType, _effectType, _abilityType, _statusEffectType, _unitName, _unitId, eventAbilityId, _sourceType)
                    -- Extra safety check for abilityId (also filtered at ESO level)
                    if eventAbilityId ~= abilityId then
                        return
                    end
                    self:OnPortalEffectChanged(eventCode, changeType)
                end)
        EVENT_MANAGER:AddFilterForEvent(eventName, EVENT_EFFECT_CHANGED,
                REGISTER_FILTER_ABILITY_ID, abilityId)
    end

    EVENT_MANAGER:RegisterForEvent("BattleScrolls_State", EVENT_PLAYER_ACTIVATED,
            function()
                self:ExitPortal()
            end)

    EVENT_MANAGER:RegisterForEvent("BattleScrolls_State", EVENT_BOSSES_CHANGED,
            function()
                self:RefreshBosses()
            end
    )
end

---Updates cached ability metadata
---@param abilityId number
---@param isDot boolean
---@param damageType DamageType
function BattleScrolls.state:UpdateAbilityInfo(abilityId, isDot, damageType)
    if not self.abilityInfo[abilityId] then
        self.abilityInfo[abilityId] = {
            overTimeOrDirect = {},
            damageTypes = {}
        }
    end
    ---@type "overTime" | "direct"
    local overTimeOrDirectKey = isDot and "overTime" or "direct"

    self.abilityInfo[abilityId].overTimeOrDirect[overTimeOrDirectKey] = true
    self.abilityInfo[abilityId].damageTypes[damageType] = true
end

-- Use accumulators module for combat result helpers
local isOverTimeResult = BattleScrolls.accumulators.isOverTimeResult
local isCriticalResult = BattleScrolls.accumulators.isCriticalResult

---Updates cached unit name for a given unit ID
---@param unitId number
---@param name string
function BattleScrolls.state:UpdateUnitName(unitId, name)
    if (not self.unitIdToName[unitId]) and name and name ~= "" then
        self.unitIdToName[unitId] = name
    end
end

function BattleScrolls.state:UpdateUnitFriendliness(unitId, unitType)
    if self.unitIdToIsFriendly[unitId] == nil then
        local isFriendly = friendlyTypesSet[unitType] == true
        self.unitIdToIsFriendly[unitId] = isFriendly

        for sourceUnitId, i in pairs(self.damageUnknownByUnitId) do
            if i[unitId] then
                ---@param targetTable table<number, table<number, DamageDone>>
                local function addToTable(targetTable)
                    targetTable[sourceUnitId] = targetTable[sourceUnitId] or {}
                    if not targetTable[sourceUnitId][unitId] then
                        targetTable[sourceUnitId][unitId] = BattleScrolls.structures.newDamageDone()
                    end
                    local unknownDamage = i[unitId]
                    local targetDamage = targetTable[sourceUnitId][unitId]
                    targetDamage.total = targetDamage.total + unknownDamage.total
                    -- byDotOrDirect and byDamageType computed on-demand by Arithmancer from byAbilityId
                    for abilityId, unknownStats in pairs(unknownDamage.byAbilityId) do
                        local targetStats = targetDamage.byAbilityId[abilityId]
                        if not targetStats then
                            targetStats = BattleScrolls.structures.newDamageBreakdown(unknownStats.minTick)
                            targetStats.maxTick = unknownStats.maxTick
                            targetDamage.byAbilityId[abilityId] = targetStats
                        end
                        targetStats.total = targetStats.total + unknownStats.total
                        targetStats.rawTotal = targetStats.rawTotal + (unknownStats.rawTotal or unknownStats.total)
                        targetStats.ticks = targetStats.ticks + unknownStats.ticks
                        targetStats.critTicks = targetStats.critTicks + unknownStats.critTicks
                        targetStats.minTick = targetStats.minTick and unknownStats.minTick and math.min(targetStats.minTick, unknownStats.minTick) or targetStats.minTick or unknownStats.minTick
                        targetStats.maxTick = targetStats.maxTick and unknownStats.maxTick and math.max(targetStats.maxTick, unknownStats.maxTick) or targetStats.maxTick or unknownStats.maxTick
                    end
                end

                -- if not a friendly target, someone from the group dealt this damage!
                if not isFriendly then
                    addToTable(self.damageByUnitIdGroup)
                end

                i[unitId] = nil
            end
        end
    end
end

---Handles combat damage events and tracks damage, ability metadata, proc events
---@param _eventCode number
---@param result number
---@param _isError boolean
---@param _abilityName string
---@param _abilityGraphic string
---@param _abilityActionSlotType number
---@param sourceName string
---@param sourceType number
---@param targetName string
---@param targetType number
---@param hitValue number
---@param _powerType number
---@param damageType number
---@param _log string
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param overflow number
function BattleScrolls.state:OnPersonalDamageDone(_eventCode, result, _isError, _abilityName, _abilityGraphic, _abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, _powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
    if hitValue <= 0 then
        return
    end

    -- Buffer event if not yet in combat (will replay on combat start)
    if not self.initialized then
        bufferPreCombatEvent({
            timestampMs = GetGameTimeMilliseconds(),
            type = "personal",
            result = result,
            sourceUnitID = sourceUnitID,
            targetUnitID = targetUnitID,
            abilityID = abilityID,
            hitValue = hitValue,
            overflow = overflow,
            damageType = damageType,
            sourceName = sourceName,
            targetName = targetName,
            sourceType = sourceType,
            targetType = targetType,
        })
        return
    end

    self:ApplyPersonalDamage(result, sourceName, sourceType, targetName, targetType, hitValue, damageType, sourceUnitID, targetUnitID, abilityID, overflow)
end

---Applies a personal damage event to state (used both for live events and replay)
---@param result number
---@param sourceName string
---@param sourceType number
---@param targetName string
---@param targetType number
---@param hitValue number
---@param damageType number
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param overflow number
function BattleScrolls.state:ApplyPersonalDamage(result, sourceName, sourceType, targetName, targetType, hitValue, damageType, sourceUnitID, targetUnitID, abilityID, overflow)
    self:UpdateUnitName(sourceUnitID, sourceName)
    self:UpdateUnitName(targetUnitID, targetName)
    self:UpdateUnitFriendliness(sourceUnitID, sourceType)
    self:UpdateUnitFriendliness(targetUnitID, targetType)

    -- Redirect boss unit IDs (merging if boss unit recreated on the client,
    -- for example after going in and out of the portal)
    targetUnitID = self.bossUnitIdRedirects[targetUnitID] or targetUnitID

    local isDot = isOverTimeResult(result)
    local isCrit = isCriticalResult(result)

    self:UpdateAbilityInfo(abilityID, isDot, damageType)

    BattleScrolls.accumulators.damage(self.damageByUnitId, sourceUnitID, targetUnitID, abilityID, hitValue, overflow, isCrit)

    -- Boss assignment: try to link this targetUnitID to a known boss
    if self.bossesByUnitId[targetUnitID] then
        self.isBossFight = true
    elseif not self.failedToAssignBossUnitIds[targetUnitID] then
        -- Name-match fallback: only assign to bosses that don't have a unitId yet
        for _, bossData in pairs(self.bossesByTag) do
            if bossData.name == targetName and bossData.unitId == nil then
                bossData.unitId = targetUnitID
                bossData.confirmed = false
                self.bossesByUnitId[targetUnitID] = bossData
                self.isBossFight = true
                break
            end
        end
        if not self.bossesByUnitId[targetUnitID] then
            self.failedToAssignBossUnitIds[targetUnitID] = true
        end
    end

    -- Track fight types based on target unit type
    if targetType == COMBAT_UNIT_TYPE_OTHER then
        self.isPlayerFight = true
    elseif targetType == COMBAT_UNIT_TYPE_TARGET_DUMMY then
        self.isDummyFight = true
    end

    if BattleScrolls.constants.SingleTargetDamageProcAbilityIds[abilityID] then
        if not self.procs[abilityID] then
            self.procs[abilityID] = {}
        end

        table.insert(self.procs[abilityID], {
            targetUnitId = targetUnitID,
            timestampMs = GetGameTimeMilliseconds()
        })
    end
end

---Handles group member damage events (no boss tracking or procs)
---@param _ number eventCode
---@param result number
---@param _isError boolean
---@param _abilityName string
---@param _abilityGraphic string
---@param _abilityActionSlotType number
---@param _sourceName string
---@param _sourceType number
---@param _targetName string
---@param _targetType number
---@param hitValue number
---@param _powerType number
---@param damageType DamageType
---@param _log string
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param overflow number
function BattleScrolls.state:OnGroupDamageDone(_, result, _isError, _abilityName, _abilityGraphic, _abilityActionSlotType, _sourceName, _sourceType, _targetName, _targetType, hitValue, _powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
    -- if math.random() < 0.025 then
    --     BattleScrolls.log.Trace(function()
    --         return string.format("OnGroupDamageDone: sourceUnitID=%d targetUnitID=%d abilityID=%d hitValue=%d sourceUnitType=%s targetUnitType=%s",
    --             sourceUnitID, targetUnitID, abilityID, hitValue, tostring(_sourceType), tostring(_targetType))
    --     end)
    -- end

    if hitValue <= 0 then
        return
    end

    -- Buffer event if not yet in combat (will replay on combat start)
    if not self.initialized then
        bufferPreCombatEvent({
            timestampMs = GetGameTimeMilliseconds(),
            type = "group",
            result = result,
            sourceUnitID = sourceUnitID,
            targetUnitID = targetUnitID,
            abilityID = abilityID,
            hitValue = hitValue,
            overflow = overflow,
            damageType = damageType,
            sourceName = _sourceName,
            targetName = _targetName,
            sourceType = _sourceType,
            targetType = _targetType,
        })
        return
    end

    self:ApplyGroupDamage(result, sourceUnitID, targetUnitID, abilityID, hitValue, overflow, damageType)
end

---Applies a group damage event to state (used both for live events and replay)
---@param result number
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param hitValue number
---@param overflow number
---@param _damageType number
function BattleScrolls.state:ApplyGroupDamage(result, sourceUnitID, targetUnitID, abilityID, hitValue, overflow, _damageType)
    -- Redirect boss unit IDs (merging if boss unit recreated on the client,
    -- for example after going in and out of the portal)
    targetUnitID = self.bossUnitIdRedirects[targetUnitID] or targetUnitID

    local isCrit = isCriticalResult(result)

    if self.unitIdToIsFriendly[targetUnitID] == nil then
        BattleScrolls.accumulators.damage(self.damageUnknownByUnitId, sourceUnitID, targetUnitID, abilityID, hitValue, overflow, isCrit)
    elseif self.unitIdToIsFriendly[targetUnitID] == false then
        BattleScrolls.accumulators.damage(self.damageByUnitIdGroup, sourceUnitID, targetUnitID, abilityID, hitValue, overflow, isCrit)
    end
    -- If target is friendly, incoming damage is not tracked
end

---Handles self-healing events (source and target are both personal: player, pet, companion)
---@param _ number eventCode
---@param result number
---@param _isError boolean
---@param _abilityName string
---@param _abilityGraphic string
---@param _abilityActionSlotType number
---@param sourceName string
---@param sourceType number
---@param targetName string
---@param targetType number
---@param hitValue number
---@param _powerType number
---@param damageType number
---@param _log string
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param overflow number
function BattleScrolls.state:OnSelfHealing(_, result, _isError, _abilityName, _abilityGraphic, _abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, _powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
    if not self.initialized then
        return
    end
    if hitValue + overflow <= 0 then
        return
    end

    self:UpdateUnitName(sourceUnitID, sourceName)
    self:UpdateUnitName(targetUnitID, targetName)
    self:UpdateUnitFriendliness(sourceUnitID, sourceType)
    self:UpdateUnitFriendliness(targetUnitID, targetType)

    local isHot = isOverTimeResult(result)
    local isCrit = isCriticalResult(result)

    self:UpdateAbilityInfo(abilityID, isHot, damageType)

    BattleScrolls.accumulators.healingDiffSource(self.healingStats.selfHealing, sourceUnitID, abilityID, hitValue, overflow, isCrit)
end

---Handles healing out to group members (source is personal, target is group)
---@param _ number eventCode
---@param result number
---@param _isError boolean
---@param _abilityName string
---@param _abilityGraphic string
---@param _abilityActionSlotType number
---@param sourceName string
---@param sourceType number
---@param targetName string
---@param targetType number
---@param hitValue number
---@param _powerType number
---@param damageType number
---@param _log string
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param overflow number
function BattleScrolls.state:OnHealingOut(_, result, _isError, _abilityName, _abilityGraphic, _abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, _powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
    if not self.initialized then
        return
    end
    if hitValue + overflow <= 0 then
        return
    end

    self:UpdateUnitName(sourceUnitID, sourceName)
    self:UpdateUnitName(targetUnitID, targetName)
    self:UpdateUnitFriendliness(sourceUnitID, sourceType)
    self:UpdateUnitFriendliness(targetUnitID, targetType)

    local isHot = isOverTimeResult(result)
    local isCrit = isCriticalResult(result)

    self:UpdateAbilityInfo(abilityID, isHot, damageType)

    if not self.healingStats.healingOutToGroup[targetUnitID] then
        self.healingStats.healingOutToGroup[targetUnitID] = BattleScrolls.structures.newHealingDoneDiffSource()
    end

    BattleScrolls.accumulators.healingDiffSource(self.healingStats.healingOutToGroup[targetUnitID], sourceUnitID, abilityID, hitValue, overflow, isCrit)
end

---Handles healing in from group members (source is group, target is personal)
---@param _ number eventCode
---@param result number
---@param _isError boolean
---@param _abilityName string
---@param _abilityGraphic string
---@param _abilityActionSlotType number
---@param sourceName string
---@param sourceType number
---@param targetName string
---@param targetType number
---@param hitValue number
---@param _powerType number
---@param damageType number
---@param _log string
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param overflow number
function BattleScrolls.state:OnHealingIn(_, result, _isError, _abilityName, _abilityGraphic, _abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, _powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
    if not self.initialized then
        return
    end
    if hitValue + overflow <= 0 then
        return
    end

    self:UpdateUnitName(sourceUnitID, sourceName)
    self:UpdateUnitName(targetUnitID, targetName)
    self:UpdateUnitFriendliness(sourceUnitID, sourceType)
    self:UpdateUnitFriendliness(targetUnitID, targetType)

    local isHot = isOverTimeResult(result)
    local isCrit = isCriticalResult(result)

    self:UpdateAbilityInfo(abilityID, isHot, damageType)

    if not self.healingStats.healingInFromGroup[sourceUnitID] then
        self.healingStats.healingInFromGroup[sourceUnitID] = BattleScrolls.structures.newHealingDone()
    end

    BattleScrolls.accumulators.healingDone(self.healingStats.healingInFromGroup[sourceUnitID], abilityID, hitValue, overflow, isCrit)
end

---Handles damage taken events (target is personal: player, pet, companion)
---@param _ number eventCode
---@param result number
---@param _isError boolean
---@param _abilityName string
---@param _abilityGraphic string
---@param _abilityActionSlotType number
---@param sourceName string
---@param sourceType number
---@param targetName string
---@param targetType number
---@param hitValue number
---@param _powerType number
---@param damageType DamageType
---@param _log string
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param overflow number
function BattleScrolls.state:OnDamageTaken(_, result, _isError, _abilityName, _abilityGraphic, _abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, _powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
    if not self.initialized then
        return
    end
    if hitValue <= 0 then
        return
    end

    self:UpdateUnitName(sourceUnitID, sourceName)
    self:UpdateUnitName(targetUnitID, targetName)
    self:UpdateUnitFriendliness(sourceUnitID, sourceType)
    self:UpdateUnitFriendliness(targetUnitID, targetType)

    -- Redirect boss unit IDs as source (merging if boss unit recreated on the client,
    -- for example after going in and out of the portal)
    sourceUnitID = self.bossUnitIdRedirects[sourceUnitID] or sourceUnitID

    local isDot = isOverTimeResult(result)
    local isCrit = isCriticalResult(result)

    self:UpdateAbilityInfo(abilityID, isDot, damageType)

    BattleScrolls.accumulators.damage(self.damageTakenByUnitId, sourceUnitID, targetUnitID, abilityID, hitValue, overflow, isCrit)

    -- Track player fights when taking damage from enemy players
    if sourceType == COMBAT_UNIT_TYPE_OTHER then
        self.isPlayerFight = true
    end
end

---Initializes fight tracking when combat starts for the first time
---@param inCombat boolean
function BattleScrolls.state:ChangePlayerCombatState(inCombat)
    self.inCombat = inCombat

    if inCombat and not self.initialized then
        self.initialized = true
        self:RefreshBosses()

        local nowMs = GetGameTimeMilliseconds()
        local cutoffMs = nowMs - PRE_COMBAT_LOOKBACK_MS

        -- Get buffered events from the last N ms
        local eventsToReplay = getBufferedEventsAfter(cutoffMs)

        -- Fight start is always initialization time (not backdated from events)
        self.fightStartTimeMs = nowMs
        self.fightStartRealTimeS = GetTimeStamp()
        self.lastDamageDoneMs = nowMs
        self.currentZoneId = GetZoneId(GetCurrentMapZoneIndex())

        -- Replay buffered events to state
        for _, event in ipairs(eventsToReplay) do
            if event.type == "personal" then
                self:ApplyPersonalDamage(
                    event.result, event.sourceName, event.sourceType,
                    event.targetName, event.targetType, event.hitValue,
                    event.damageType, event.sourceUnitID, event.targetUnitID,
                    event.abilityID, event.overflow
                )
            elseif event.type == "group" then
                self:ApplyGroupDamage(
                    event.result, event.sourceUnitID, event.targetUnitID,
                    event.abilityID, event.hitValue, event.overflow, event.damageType
                )
            end
        end

        -- Clear buffer after replay
        clearPreCombatBuffer()

        self:NotifyInitialized()
    end
end

---@param _ number
---@param changeType number EFFECT_RESULT_GAINED or EFFECT_RESULT_FADED
function BattleScrolls.state:OnPortalEffectChanged(_, changeType)
    if changeType == EFFECT_RESULT_GAINED then
        self:EnterPortal()
    else
        self:ExitPortal()
    end
end

function BattleScrolls.state:EnterPortal()
    self.isInPortal = true
end

function BattleScrolls.state:ExitPortal()
    if self.isInPortal then
        self.isInPortal = false
        self:RefreshBosses()
    end
end

if not SemisPlaygroundCheckAccess() then
    return
end

-- Havok Script hstructure definitions for BattleScrolls
-- These provide faster field access and lower memory usage than regular tables
-- See: https://wiki.esoui.com/Lua#hstructure
--
-- IMPORTANT: hstructure names are GLOBAL, so we use BS_ prefix to avoid
-- conflicts with other addons or future ESO API additions.

BattleScrolls = BattleScrolls or {}

-- ============================================================================
-- hstructure Definitions (Havok Script extension - not standard Lua)
-- These are parsed by ESO's Havok Script VM, not by lua-language-server
-- ============================================================================

---@diagnostic disable: undefined-global, lowercase-global

---Tracks alive/dead state and alive time for a unit
---@class UnitAliveState
---@field aliveTimeMs number Total time unit was alive during combat
---@field lastAliveStartMs number|nil When unit became alive (nil if dead)
---@field isDead boolean Whether unit is currently dead
hstructure BS_UnitAliveState
    aliveTimeMs : number
    lastAliveStartMs : number
    isDead : boolean
end

---Effect stats for uptime tracking (base structure)
---@class EffectStats
---@field abilityId number
---@field effectType number BUFF_EFFECT_TYPE_BUFF or BUFF_EFFECT_TYPE_DEBUFF
---@field totalActiveTimeMs number Total time effect was active
---@field timeAtMaxStacksMs number Time spent at max observed stacks
---@field applications number Number of times effect was applied
---@field maxStacks number Peak stack count observed
hstructure BS_EffectStats
    abilityId : number
    effectType : number
    totalActiveTimeMs : number
    timeAtMaxStacksMs : number
    applications : number
    maxStacks : number
end

---Effect stats with player attribution (for boss debuffs, group buffs, player effects)
---@class EffectStatsWithAttribution : EffectStats
---@field playerActiveTimeMs number Time YOU kept this effect up
---@field playerTimeAtMaxStacksMs number Time at max stacks applied by you
---@field playerApplications number Times YOU applied this effect
---@field peakConcurrentInstances number Peak number of concurrent instances of this effect (e.g., 2 Relequen)
hstructure BS_EffectStatsWithAttribution
    abilityId : number
    effectType : number
    totalActiveTimeMs : number
    timeAtMaxStacksMs : number
    applications : number
    maxStacks : number
    playerActiveTimeMs : number
    playerTimeAtMaxStacksMs : number
    playerApplications : number
    peakConcurrentInstances : number
end

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
---@field storageKey string|nil Key for storage lookup (unitTag/displayName)
---@field beginTime number|nil ESO effect begin time (for reapplication detection)
hstructure BS_EffectInstance
    abilityId : number
    effectType : number
    startTimeMs : number
    stackCount : number
    maxStacksStartMs : number
    currentMaxStacks : number
    appliedByPlayer : boolean
    unitTag : string
    storageKey : string
    beginTime : number
end

---Per-ability damage breakdown with crit stats
---@class DamageBreakdown
---@field total number Total damage value (capped by target HP)
---@field rawTotal number Total raw damage value (includes overkill)
---@field ticks number Total number of ticks (hits)
---@field critTicks number Number of critical ticks
---@field minTick number|nil Minimum tick value (raw)
---@field maxTick number|nil Maximum tick value (raw)
hstructure BS_DamageBreakdown
    total : number
    rawTotal : number
    ticks : number
    critTicks : number
    minTick : number
    maxTick : number
end

---Damage tracking broken down by various dimensions
---@class DamageDone
---@field total number
---@field byAbilityId table table<number, DamageBreakdown>
hstructure BS_DamageDone
    total : number
    byAbilityId : table
end

---Lean healing totals without crit stats (for aggregates)
---@class HealingTotals
---@field raw number Total raw healing (real + overheal)
---@field real number Actual healing done
---@field overheal number Overhealing amount
hstructure BS_HealingTotals
    raw : number
    real : number
    overheal : number
end

---Per-ability healing breakdown with crit stats
---@class HealingBreakdown
---@field raw number Total raw healing
---@field real number Actual healing done
---@field overheal number Overhealing amount
---@field ticks number Total number of ticks
---@field critTicks number Number of critical ticks
---@field minTick number|nil Minimum tick value (raw)
---@field maxTick number|nil Maximum tick value (raw)
hstructure BS_HealingBreakdown
    raw : number
    real : number
    overheal : number
    ticks : number
    critTicks : number
    minTick : number
    maxTick : number
end

---Healing done structure with lean totals
---@class HealingDone
---@field total HealingTotals Aggregate totals
---@field byAbilityId table table<number, HealingBreakdown>
hstructure BS_HealingDone
    total : BS_HealingTotals
    byAbilityId : table
end

---Healing done with source differentiation
---@class HealingDoneDiffSource
---@field total HealingTotals Aggregate totals
---@field bySourceUnitIdByAbilityId table table<number, table<number, HealingBreakdown>>
hstructure BS_HealingDoneDiffSource
    total : BS_HealingTotals
    bySourceUnitIdByAbilityId : table
end

---Top-level healing stats container
---@class HealingStats
---@field selfHealing HealingDoneDiffSource Self-healing stats
---@field healingOutToGroup table table<number, HealingDoneDiffSource>
---@field healingInFromGroup table table<number, HealingDone>
hstructure BS_HealingStats
    selfHealing : BS_HealingDoneDiffSource
    healingOutToGroup : table
    healingInFromGroup : table
end

---Effect queue data payload (union of all message type fields)
---Used by: PLAYER_EFFECT, BOSS_EFFECT, GROUP_EFFECT, UNIT_DEATH, UNIT_ALIVE, *_FULL_REFRESH
---@class EffectQueueData
---@field changeType number|nil EFFECT_RESULT_GAINED, EFFECT_RESULT_FADED, etc.
---@field effectSlot number|nil Effect slot number
---@field effectType number|nil BUFF_EFFECT_TYPE_BUFF or BUFF_EFFECT_TYPE_DEBUFF
---@field stackCount number|nil Stack count
---@field abilityId number|nil Ability ID
---@field sourceType number|nil Source type (player, NPC, etc.)
---@field beginTime number|nil Effect begin time
---@field endTime number|nil Effect end time (GROUP_EFFECT only)
---@field unitTag string|nil Unit tag (boss/group)
---@field unitId number|nil Unit ID
hstructure BS_EffectQueueData
    changeType : number
    effectSlot : number
    effectType : number
    stackCount : number
    abilityId : number
    sourceType : number
    beginTime : number
    endTime : number
    unitTag : string
    unitId : number
end

---Effect queue message for async effect event processing
---@class EffectQueueMessage
---@field type EFFECT_QUEUE_MESSAGE_TYPE Message type (PLAYER_EFFECT, BOSS_EFFECT, etc.)
---@field timestampMs number Game time when event occurred
---@field generation number Generation counter at enqueue time
---@field storageKey string Storage key for generation tracking
---@field data EffectQueueData Event-specific data payload
hstructure BS_EffectQueueMessage
    type : string
    timestampMs : number
    generation : number
    storageKey : string
    data : BS_EffectQueueData
end

---@diagnostic enable: undefined-global, lowercase-global

-- ============================================================================
-- Factory Functions (hmake wrappers)
-- ============================================================================

local structures = {}
BattleScrolls.structures = structures

---Creates a new UnitAliveState
---@param startAlive boolean
---@param startTimeMs number|nil
---@return UnitAliveState
function structures.newUnitAliveState(startAlive, startTimeMs)
    local timeMs = startTimeMs or GetGameTimeMilliseconds()
    return hmake BS_UnitAliveState {
        aliveTimeMs = 0,
        lastAliveStartMs = startAlive and timeMs or nil,
        isDead = not startAlive,
    }
end

---Creates a new EffectStats
---@param abilityId number
---@param effectType number
---@return EffectStats
function structures.newEffectStats(abilityId, effectType)
    return hmake BS_EffectStats {
        abilityId = abilityId,
        effectType = effectType,
        totalActiveTimeMs = 0,
        timeAtMaxStacksMs = 0,
        applications = 0,
        maxStacks = 0,
    }
end

---Creates a new EffectStatsWithAttribution (for boss/group/player effects)
---@param abilityId number
---@param effectType number
---@return EffectStatsWithAttribution
function structures.newEffectStatsWithAttribution(abilityId, effectType)
    return hmake BS_EffectStatsWithAttribution {
        abilityId = abilityId,
        effectType = effectType,
        totalActiveTimeMs = 0,
        timeAtMaxStacksMs = 0,
        applications = 0,
        maxStacks = 0,
        playerActiveTimeMs = 0,
        playerTimeAtMaxStacksMs = 0,
        playerApplications = 0,
        peakConcurrentInstances = 1,
    }
end

---Creates a new EffectInstance
---@param abilityId number
---@param effectType number
---@param stackCount number
---@param appliedByPlayer boolean
---@param unitTag string
---@param storageKey string|nil
---@param beginTime number|nil
---@return EffectInstance
function structures.newEffectInstance(abilityId, effectType, stackCount, appliedByPlayer, unitTag, storageKey, beginTime)
    return hmake BS_EffectInstance {
        abilityId = abilityId,
        effectType = effectType,
        startTimeMs = GetGameTimeMilliseconds(),
        stackCount = stackCount,
        maxStacksStartMs = nil,
        currentMaxStacks = stackCount,
        appliedByPlayer = appliedByPlayer,
        unitTag = unitTag,
        storageKey = storageKey,
        beginTime = beginTime,
    }
end

---Creates a new DamageBreakdown
---@param initialRawHit number|nil
---@return DamageBreakdown
function structures.newDamageBreakdown(initialRawHit)
    return hmake BS_DamageBreakdown {
        total = 0,
        rawTotal = 0,
        ticks = 0,
        critTicks = 0,
        minTick = initialRawHit,
        maxTick = initialRawHit,
    }
end

---Creates a new DamageDone
---@return DamageDone
function structures.newDamageDone()
    return hmake BS_DamageDone {
        total = 0,
        byAbilityId = {},
    }
end

---Creates a new HealingTotals
---@return HealingTotals
function structures.newHealingTotals()
    return hmake BS_HealingTotals {
        raw = 0,
        real = 0,
        overheal = 0,
    }
end

---Creates a new HealingBreakdown
---@param initialRawHit number|nil
---@return HealingBreakdown
function structures.newHealingBreakdown(initialRawHit)
    return hmake BS_HealingBreakdown {
        raw = 0,
        real = 0,
        overheal = 0,
        ticks = 0,
        critTicks = 0,
        minTick = initialRawHit,
        maxTick = initialRawHit,
    }
end

---Creates a new HealingDone
---@return HealingDone
function structures.newHealingDone()
    return hmake BS_HealingDone {
        total = structures.newHealingTotals(),
        byAbilityId = {},
    }
end

---Creates a new HealingDoneDiffSource
---@return HealingDoneDiffSource
function structures.newHealingDoneDiffSource()
    return hmake BS_HealingDoneDiffSource {
        total = structures.newHealingTotals(),
        bySourceUnitIdByAbilityId = {},
    }
end

---Creates a new HealingStats
---@return HealingStats
function structures.newHealingStats()
    return hmake BS_HealingStats {
        selfHealing = structures.newHealingDoneDiffSource(),
        healingOutToGroup = {},
        healingInFromGroup = {},
    }
end

---Creates a new empty EffectQueueData
---@return EffectQueueData
function structures.newEffectQueueData()
    return hmake BS_EffectQueueData {}
end

---Creates a new EffectQueueMessage
---@param messageType EFFECT_QUEUE_MESSAGE_TYPE
---@param storageKey string
---@param generation number
---@param data EffectQueueData|nil Optional data payload (defaults to new empty data)
---@return EffectQueueMessage
function structures.newEffectQueueMessage(messageType, storageKey, generation, data)
    return hmake BS_EffectQueueMessage {
        type = messageType,
        timestampMs = GetGameTimeMilliseconds(),
        generation = generation,
        storageKey = storageKey,
        data = data or structures.newEffectQueueData(),
    }
end

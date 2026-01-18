if not SemisPlaygroundCheckAccess() then
    return
end

-- Combat accumulation module for BattleScrolls
-- Self-sufficient module that handles damage/healing data structures and accumulation
-- Does NOT extend BattleScrolls.state - provides pure data operations

BattleScrolls = BattleScrolls or {}

---@class CombatContext
---@field damageByUnitId table<number, table<number, DamageDone>>
---@field damageByUnitIdGroup table<number, table<number, DamageDone>>
---@field damageTakenByUnitId table<number, table<number, DamageDone>>
---@field damageUnknownByUnitId table<number, table<number, DamageDone>>
---@field healingStats HealingStats
---@field procs table<number, ProcEvent[]>
---@field abilityInfo table<number, AbilityInfo>

---@class BattleScrollsAccumulators
local accumulators = {}

BattleScrolls.accumulators = accumulators

-- ============================================================================
-- Combat Result Helpers
-- ============================================================================

---Checks if a combat result is an over-time effect (DOT or HOT)
---@param result number Combat result constant
---@return boolean
function accumulators.isOverTimeResult(result)
    return result == ACTION_RESULT_DOT_TICK
        or result == ACTION_RESULT_DOT_TICK_CRITICAL
        or result == ACTION_RESULT_HOT_TICK
        or result == ACTION_RESULT_HOT_TICK_CRITICAL
end

---Checks if a combat result is a critical hit
---@param result number Combat result constant
---@return boolean
function accumulators.isCriticalResult(result)
    return result == ACTION_RESULT_CRITICAL_DAMAGE
        or result == ACTION_RESULT_DOT_TICK_CRITICAL
        or result == ACTION_RESULT_CRITICAL_HEAL
        or result == ACTION_RESULT_HOT_TICK_CRITICAL
end

-- ============================================================================
-- Damage Accumulation
-- ============================================================================

---Creates a new empty DamageDone structure (uses hstructure)
---@return DamageDone
function accumulators.newDamageDone()
    return BattleScrolls.structures.newDamageDone()
end

---Accumulates damage into the given damage table (nested: sourceUnitId -> targetUnitId -> DamageDone)
---@param damageTable table<number, table<number, DamageDone>>
---@param sourceUnitID number
---@param targetUnitID number
---@param abilityID number
---@param hitValue number
---@param overflow number Overkill damage (damage exceeding target's remaining HP)
---@param isCrit boolean
function accumulators.damage(damageTable, sourceUnitID, targetUnitID, abilityID, hitValue, overflow, isCrit)
    if not damageTable[sourceUnitID] then
        damageTable[sourceUnitID] = {}
    end

    local damageDone = damageTable[sourceUnitID][targetUnitID]
    if not damageDone then
        damageDone = accumulators.newDamageDone()
        damageTable[sourceUnitID][targetUnitID] = damageDone
    end

    damageDone.total = damageDone.total + hitValue
    -- byDotOrDirect and byDamageType computed on-demand by Arithmancer from byAbilityId

    -- Track per-ability damage breakdown with crit stats (uses hstructure)
    -- Use rawHit (hitValue + overflow) for min/max to get true hit value before overkill cap
    local rawHit = hitValue + overflow
    local abilityStats = damageDone.byAbilityId[abilityID]
    if not abilityStats then
        abilityStats = BattleScrolls.structures.newDamageBreakdown(rawHit)
        damageDone.byAbilityId[abilityID] = abilityStats
    end

    abilityStats.total = abilityStats.total + hitValue
    abilityStats.rawTotal = abilityStats.rawTotal + rawHit
    abilityStats.ticks = abilityStats.ticks + 1
    if isCrit then
        abilityStats.critTicks = abilityStats.critTicks + 1
    end
    abilityStats.minTick = abilityStats.minTick and math.min(abilityStats.minTick, rawHit) or rawHit
    abilityStats.maxTick = abilityStats.maxTick and math.max(abilityStats.maxTick, rawHit) or rawHit
end

-- ============================================================================
-- Healing Accumulation
-- ============================================================================

---Creates a new empty HealingTotals (lean, uses hstructure)
---@return HealingTotals
function accumulators.newHealingTotals()
    return BattleScrolls.structures.newHealingTotals()
end

---Adds healing values to a lean HealingTotals (no crit stats)
---@param totals HealingTotals
---@param hitValue number The actual healing done (real)
---@param overflow number The overheal amount
function accumulators.addToHealingTotals(totals, hitValue, overflow)
    totals.real = totals.real + hitValue
    totals.overheal = totals.overheal + overflow
    totals.raw = totals.raw + hitValue + overflow
end

---Creates a new empty HealingBreakdown (full with crit stats, uses hstructure)
---@param initialRawHit number|nil Optional initial raw hit value for minTick/maxTick
---@return HealingBreakdown
function accumulators.newHealingBreakdown(initialRawHit)
    return BattleScrolls.structures.newHealingBreakdown(initialRawHit)
end

---Adds healing values to a full HealingBreakdown (with crit stats)
---@param breakdown HealingBreakdown
---@param hitValue number The actual healing done (real)
---@param overflow number The overheal amount
---@param isCrit boolean Whether this was a critical heal
function accumulators.addToHealingBreakdown(breakdown, hitValue, overflow, isCrit)
    local rawHit = hitValue + overflow
    breakdown.real = breakdown.real + hitValue
    breakdown.overheal = breakdown.overheal + overflow
    breakdown.raw = breakdown.raw + rawHit
    breakdown.ticks = breakdown.ticks + 1
    if isCrit then
        breakdown.critTicks = breakdown.critTicks + 1
    end
    breakdown.minTick = breakdown.minTick and math.min(breakdown.minTick, rawHit) or rawHit
    breakdown.maxTick = breakdown.maxTick and math.max(breakdown.maxTick, rawHit) or rawHit
end

---Creates a new empty HealingDone (with lean totals, uses hstructure)
---@return HealingDone
function accumulators.newHealingDone()
    return BattleScrolls.structures.newHealingDone()
end

---Accumulates healing into a HealingDone structure (tracks by abilityId only)
---@param healingDone HealingDone
---@param abilityID number
---@param hitValue number
---@param overflow number
---@param isCrit boolean
function accumulators.healingDone(healingDone, abilityID, hitValue, overflow, isCrit)
    local rawHit = hitValue + overflow

    -- Lean totals (no crit stats)
    accumulators.addToHealingTotals(healingDone.total, hitValue, overflow)
    -- byHotVsDirect computed on-demand by Arithmancer from byAbilityId

    -- Full breakdown with crit stats per ability
    if not healingDone.byAbilityId[abilityID] then
        healingDone.byAbilityId[abilityID] = accumulators.newHealingBreakdown(rawHit)
    end
    accumulators.addToHealingBreakdown(healingDone.byAbilityId[abilityID], hitValue, overflow, isCrit)
end

---Creates a new empty HealingDoneDiffSource (with lean totals, uses hstructure)
---@return HealingDoneDiffSource
function accumulators.newHealingDoneDiffSource()
    return BattleScrolls.structures.newHealingDoneDiffSource()
end

---Accumulates healing into a HealingDoneDiffSource structure (tracks by sourceUnitId -> abilityId)
---@param healingDone HealingDoneDiffSource
---@param sourceUnitID number
---@param abilityID number
---@param hitValue number
---@param overflow number
---@param isCrit boolean
function accumulators.healingDiffSource(healingDone, sourceUnitID, abilityID, hitValue, overflow, isCrit)
    local rawHit = hitValue + overflow

    -- Lean totals (no crit stats)
    accumulators.addToHealingTotals(healingDone.total, hitValue, overflow)
    -- byHotVsDirect computed on-demand by Arithmancer from byAbilityId

    -- Full breakdown with crit stats per ability
    if not healingDone.bySourceUnitIdByAbilityId[sourceUnitID] then
        healingDone.bySourceUnitIdByAbilityId[sourceUnitID] = {}
    end
    if not healingDone.bySourceUnitIdByAbilityId[sourceUnitID][abilityID] then
        healingDone.bySourceUnitIdByAbilityId[sourceUnitID][abilityID] = accumulators.newHealingBreakdown(rawHit)
    end
    accumulators.addToHealingBreakdown(healingDone.bySourceUnitIdByAbilityId[sourceUnitID][abilityID], hitValue, overflow, isCrit)
end

-- ============================================================================
-- HealingStats Factory and Clear
-- ============================================================================

---Creates a new empty HealingStats structure (uses hstructure)
---@return HealingStats
function accumulators.newHealingStats()
    return BattleScrolls.structures.newHealingStats()
end

---Clears combat tracking state (damage, healing, procs, ability info)
---@param ctx CombatContext
function accumulators.clear(ctx)
    ctx.damageByUnitId = {}
    ctx.damageByUnitIdGroup = {}
    ctx.damageTakenByUnitId = {}
    ctx.damageUnknownByUnitId = {}
    ctx.healingStats = accumulators.newHealingStats()
    ctx.procs = {}
    ctx.abilityInfo = {}
end

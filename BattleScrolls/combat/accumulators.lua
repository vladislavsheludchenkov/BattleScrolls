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
        damageDone = BattleScrolls.structures.newDamageDone()
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

---Adds healing values to a lean HealingTotals (no crit stats)
---@param totals HealingTotals
---@param hitValue number The actual healing done (real)
---@param overflow number The overheal amount
function accumulators.addToHealingTotals(totals, hitValue, overflow)
    totals.real = totals.real + hitValue
    totals.overheal = totals.overheal + overflow
    totals.raw = totals.raw + hitValue + overflow
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
        healingDone.byAbilityId[abilityID] = BattleScrolls.structures.newHealingBreakdown(rawHit)
    end
    accumulators.addToHealingBreakdown(healingDone.byAbilityId[abilityID], hitValue, overflow, isCrit)
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
        healingDone.bySourceUnitIdByAbilityId[sourceUnitID][abilityID] = BattleScrolls.structures.newHealingBreakdown(rawHit)
    end
    accumulators.addToHealingBreakdown(healingDone.bySourceUnitIdByAbilityId[sourceUnitID][abilityID], hitValue, overflow, isCrit)
end

-- ============================================================================
-- HealingStats Factory and Clear
-- ============================================================================

-- ============================================================================
-- Damage Merging (for boss unit ID redirects)
-- ============================================================================

---Merges one DamageBreakdown into another
---@param into DamageBreakdown
---@param from DamageBreakdown
function accumulators.mergeDamageBreakdown(into, from)
    into.total = into.total + from.total
    into.rawTotal = into.rawTotal + from.rawTotal
    into.ticks = into.ticks + from.ticks
    into.critTicks = into.critTicks + from.critTicks
    into.minTick = into.minTick and from.minTick and math.min(into.minTick, from.minTick) or into.minTick or from.minTick
    into.maxTick = into.maxTick and from.maxTick and math.max(into.maxTick, from.maxTick) or into.maxTick or from.maxTick
end

---Merges one DamageDone into another
---@param into DamageDone
---@param from DamageDone
function accumulators.mergeDamageDone(into, from)
    into.total = into.total + from.total
    for abilityId, fromBreakdown in pairs(from.byAbilityId) do
        local intoBreakdown = into.byAbilityId[abilityId]
        if intoBreakdown then
            accumulators.mergeDamageBreakdown(intoBreakdown, fromBreakdown)
        else
            into.byAbilityId[abilityId] = fromBreakdown
        end
    end
end

---Retroactively merges all damage recorded under fromUnitId into toUnitId across all damage tables
---Called when CorrelateBossUnitId establishes a redirect for a boss that got a new unitId
---@param ctx CombatContext
---@param fromUnitId number The new (redirected-from) unit ID
---@param toUnitId number The canonical (redirected-to) unit ID
function accumulators.redirectBossUnitId(ctx, fromUnitId, toUnitId)
    -- Boss as target: damageByUnitId, damageByUnitIdGroup, damageUnknownByUnitId
    local targetTables = { ctx.damageByUnitId, ctx.damageByUnitIdGroup, ctx.damageUnknownByUnitId }
    for _, damageTable in ipairs(targetTables) do
        for _, targetMap in pairs(damageTable) do
            if targetMap[fromUnitId] then
                if not targetMap[toUnitId] then
                    targetMap[toUnitId] = BattleScrolls.structures.newDamageDone()
                end
                accumulators.mergeDamageDone(targetMap[toUnitId], targetMap[fromUnitId])
                targetMap[fromUnitId] = nil
            end
        end
    end

    -- Boss as source: damageTakenByUnitId
    if ctx.damageTakenByUnitId[fromUnitId] then
        if not ctx.damageTakenByUnitId[toUnitId] then
            ctx.damageTakenByUnitId[toUnitId] = {}
        end
        for targetId, fromDamage in pairs(ctx.damageTakenByUnitId[fromUnitId]) do
            if not ctx.damageTakenByUnitId[toUnitId][targetId] then
                ctx.damageTakenByUnitId[toUnitId][targetId] = BattleScrolls.structures.newDamageDone()
            end
            accumulators.mergeDamageDone(ctx.damageTakenByUnitId[toUnitId][targetId], fromDamage)
        end
        ctx.damageTakenByUnitId[fromUnitId] = nil
    end
end

-- ============================================================================
-- State Clear
-- ============================================================================

---Clears combat tracking state (damage, healing, procs, ability info)
---@param ctx CombatContext
function accumulators.clear(ctx)
    ctx.damageByUnitId = {}
    ctx.damageByUnitIdGroup = {}
    ctx.damageTakenByUnitId = {}
    ctx.damageUnknownByUnitId = {}
    ctx.healingStats = BattleScrolls.structures.newHealingStats()
    ctx.procs = {}
    ctx.abilityInfo = {}
end

-----------------------------------------------------------
-- Arithmancer
-- DPS/damage calculation engine for Battle Scrolls
--
-- Provides both static utility functions for computing totals
-- and an instance-based calculator with lazy computation.
--
-- Usage:
--   -- Static: compute total from damage structure
--   local total = Arithmancer.ComputeDamageTotal(damageDone)
--
--   -- Instance: lazy calculator - nothing computed until accessed
--   local calc = Arithmancer:New(encounter, abilityInfo)
--   local dps = calc:personalDPS()  -- computed on first access, cached
--   local share = calc:personalShare()  -- uses cached totals
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

local Arithmancer = {}

BattleScrolls.arithmancer = Arithmancer

-- =============================================================================
-- AGGREGATE COMPUTATION HELPERS
-- =============================================================================
-- These functions compute derived values (total, byDotOrDirect, byDamageType) from
-- byAbilityId data at display time, rather than storing them.

---Gets abilities map from a DamageDone structure
---Handles both verbose (has .byAbilityId) and decoded compact (abilities directly)
---@param damageDone DamageDoneStorage
---@return DamageByAbility abilities
local function getAbilities(damageDone)
    -- Verbose format has .byAbilityId wrapper
    if damageDone.byAbilityId then
        return damageDone.byAbilityId
    end
    -- Decoded compact format: abilities are stored directly (no wrapper)
    return damageDone
end

---Gets abilities map from a DamageDone structure (public API)
---Handles both verbose (has .byAbilityId) and decoded compact (abilities directly)
---@param damageDone DamageDoneStorage
---@return DamageByAbility abilities
function Arithmancer.GetAbilities(damageDone)
    return getAbilities(damageDone)
end

---Computes total damage from a DamageDone structure
---Works with both verbose (has .total) and decoded compact (abilities directly)
---@param damageDone DamageDoneStorage
---@return number total
function Arithmancer.ComputeDamageTotal(damageDone)
    -- Verbose format has .total pre-computed
    if damageDone.total then
        return damageDone.total
    end
    -- Compact format: sum from abilities
    local total = 0
    for _, breakdown in pairs(getAbilities(damageDone)) do
        total = total + breakdown.total
    end
    return total
end

---Computes DOT vs Direct breakdown from a DamageDone structure
---Works with both verbose (has .byDotOrDirect) and decoded compact (abilities directly)
---@param damageDone DamageDoneStorage
---@param abilityInfo table<number, AbilityInfo> Ability metadata for determining DOT/Direct
---@return { dot: number, direct: number } byDotOrDirect
function Arithmancer.ComputeByDotOrDirect(damageDone, abilityInfo)
    -- Verbose format has .byDotOrDirect pre-computed
    if damageDone.byDotOrDirect then
        return damageDone.byDotOrDirect
    end
    -- Compact format: compute from abilities + abilityInfo
    local result = { dot = 0, direct = 0 }
    for abilityId, breakdown in pairs(getAbilities(damageDone)) do
        local info = abilityInfo[abilityId]
        -- overTimeOrDirect is a table: { overTime = true/nil, direct = true/nil }
        local isDot = info and info.overTimeOrDirect and info.overTimeOrDirect.overTime
        if isDot then
            result.dot = result.dot + breakdown.total
        else
            result.direct = result.direct + breakdown.total
        end
    end
    return result
end

---Computes damage by damage type from a DamageDone structure
---Works with both verbose (has .byDamageType) and decoded compact (abilities directly)
---@param damageDone DamageDoneStorage
---@param abilityInfo table<number, AbilityInfo> Ability metadata for determining damage types
---@return table<DamageType, number> byDamageType Map of damageType -> total damage
function Arithmancer.ComputeByDamageType(damageDone, abilityInfo)
    -- Verbose format has .byDamageType pre-computed
    if damageDone.byDamageType then
        return damageDone.byDamageType
    end
    -- Compact format: compute from abilities + abilityInfo
    local result = {}
    for abilityId, breakdown in pairs(getAbilities(damageDone)) do
        local info = abilityInfo[abilityId]
        if info and info.damageTypes then
            for damageType in pairs(info.damageTypes) do
                result[damageType] = (result[damageType] or 0) + breakdown.total
            end
        end
    end
    return result
end

---Computes HOT vs Direct breakdown from a HealingDone structure
---@param healingDone HealingDone|HealingDoneDiffSource
---@param abilityInfo table<number, AbilityInfo> Ability metadata for determining HOT/Direct
---@return { hot: { raw: number, real: number }, direct: { raw: number, real: number } }
function Arithmancer.ComputeByHotVsDirect(healingDone, abilityInfo)
    local result = {
        hot = { raw = 0, real = 0 },
        direct = { raw = 0, real = 0 },
    }
    -- Handle HealingDone (has byAbilityId directly)
    if healingDone.byAbilityId then
        for abilityId, breakdown in pairs(healingDone.byAbilityId) do
            local info = abilityInfo[abilityId]
            local isHot = info and info.overTimeOrDirect and info.overTimeOrDirect.overTime
            local key = isHot and "hot" or "direct"
            result[key].raw = result[key].raw + (breakdown.raw or 0)
            result[key].real = result[key].real + (breakdown.real or 0)
        end
    end
    -- Handle HealingDoneDiffSource (has bySourceUnitIdByAbilityId)
    if healingDone.bySourceUnitIdByAbilityId then
        for _, byAbility in pairs(healingDone.bySourceUnitIdByAbilityId) do
            for abilityId, breakdown in pairs(byAbility) do
                local info = abilityInfo[abilityId]
                local isHot = info and info.overTimeOrDirect and info.overTimeOrDirect.overTime
                local key = isHot and "hot" or "direct"
                result[key].raw = result[key].raw + (breakdown.raw or 0)
                result[key].real = result[key].real + (breakdown.real or 0)
            end
        end
    end
    return result
end

---Computes total damage from a nested damage table (source -> target -> damage)
---@param damageTable table<number, table<number, DamageDoneStorage>>|nil Nested source -> target -> damage
---@return number total
function Arithmancer.ComputeNestedTotal(damageTable)
    if not damageTable then return 0 end
    local total = 0
    for _, byTarget in pairs(damageTable) do
        for _, damageData in pairs(byTarget) do
            total = total + Arithmancer.ComputeDamageTotal(damageData)
        end
    end
    return total
end

-- =============================================================================
-- FILTER UTILITIES
-- =============================================================================
-- These functions create filtered copies of data structures.
-- Use these to pre-filter data once, then pass the filtered copy to display methods
-- instead of passing filters to every method (which causes duplicated iteration).

---Creates a filtered copy of a damage table (damageByUnitId structure)
---Returns a new table containing only entries that match the filters
---@param damageTable table<number, table<number, DamageDoneStorage>>|nil Source -> Target -> DamageDone
---@param targetFilter table<number, boolean>|nil Optional set of target unit IDs to include (nil = all)
---@param sourceFilter table<number, boolean>|nil Optional set of source unit IDs to include (nil = all)
---@return table<number, table<number, DamageDoneStorage>>|nil filteredTable
function Arithmancer.FilterDamageTable(damageTable, targetFilter, sourceFilter)
    if not damageTable then return nil end
    -- If no filters, return original table (no copy needed)
    if not targetFilter and not sourceFilter then
        return damageTable
    end

    local filtered = {}
    for sourceUnitId, byTarget in pairs(damageTable) do
        if not sourceFilter or sourceFilter[sourceUnitId] then
            local filteredByTarget = nil
            for targetUnitId, damageData in pairs(byTarget) do
                if not targetFilter or targetFilter[targetUnitId] then
                    if not filteredByTarget then
                        filteredByTarget = {}
                    end
                    -- Reference original data, don't deep copy (data is read-only)
                    filteredByTarget[targetUnitId] = damageData
                end
            end
            if filteredByTarget then
                filtered[sourceUnitId] = filteredByTarget
            end
        end
    end
    return filtered
end

---Creates a filtered copy of a damage taken table (damageTakenByUnitId structure)
---Source and target are swapped: Source -> Target where Source is the attacker
---@param damageTakenTable table<number, table<number, DamageDoneStorage>>|nil Source -> Target -> DamageDone
---@param sourceFilter table<number, boolean>|nil Optional set of source (attacker) unit IDs to include
---@return table<number, table<number, DamageDoneStorage>>|nil filteredTable
function Arithmancer.FilterDamageTakenTable(damageTakenTable, sourceFilter)
    if not damageTakenTable then return nil end
    if not sourceFilter then return damageTakenTable end

    local filtered = {}
    for sourceUnitId, byTarget in pairs(damageTakenTable) do
        if sourceFilter[sourceUnitId] then
            -- Reference original data
            filtered[sourceUnitId] = byTarget
        end
    end
    return filtered
end

---Creates a filtered copy of healing out data (healingOutToGroup structure)
---@param healingOutToGroup table<number, HealingDoneDiffSource>|nil Target -> HealingData
---@param targetFilter table<number, boolean>|nil Optional set of target unit IDs to include
---@return table<number, HealingDoneDiffSource>|nil filteredTable
function Arithmancer.FilterHealingOutTable(healingOutToGroup, targetFilter)
    if not healingOutToGroup then return nil end
    if not targetFilter then return healingOutToGroup end

    local filtered = {}
    for targetUnitId, healingData in pairs(healingOutToGroup) do
        if targetFilter[targetUnitId] then
            filtered[targetUnitId] = healingData
        end
    end
    return filtered
end

---Creates a filtered copy of healing in data (healingInFromGroup structure)
---@param healingInFromGroup table<number, HealingDone>|nil Source -> HealingData
---@param sourceFilter table<number, boolean>|nil Optional set of source unit IDs to include
---@return table<number, HealingDone>|nil filteredTable
function Arithmancer.FilterHealingInTable(healingInFromGroup, sourceFilter)
    if not healingInFromGroup then return nil end
    if not sourceFilter then return healingInFromGroup end

    local filtered = {}
    for sourceUnitId, healingData in pairs(healingInFromGroup) do
        if sourceFilter[sourceUnitId] then
            filtered[sourceUnitId] = healingData
        end
    end
    return filtered
end

---Computes AOE vs single target breakdown from a damage table
---Works with pre-filtered data (use FilterDamageTable first if filtering needed)
---@param damageTable table<number, table<number, DamageDoneStorage>>|nil
---@return { aoe: number, singleTarget: number }
function Arithmancer.ComputeAoeVsSingleTarget(damageTable)
    if not damageTable then
        return { aoe = 0, singleTarget = 0 }
    end
    local aoeAbilityIds = BattleScrolls.constants.aoeAbilityIds
    local aoeDamage = 0
    local singleTargetDamage = 0

    for _, byTarget in pairs(damageTable) do
        for _, damage in pairs(byTarget) do
            for abilityId, abilityStats in pairs(getAbilities(damage)) do
                if aoeAbilityIds[abilityId] then
                    aoeDamage = aoeDamage + abilityStats.total
                else
                    singleTargetDamage = singleTargetDamage + abilityStats.total
                end
            end
        end
    end

    return { aoe = aoeDamage, singleTarget = singleTargetDamage }
end


-- =============================================================================
-- ARITHMANCER INSTANCE (LAZY COMPUTATION)
-- =============================================================================

---@class ArithmancerCache
---@field durationS number|nil
---@field isBossFight boolean|nil
---@field personalTotalDamage number|nil
---@field bossPersonalTotalDamage number|nil
---@field groupTotalDamage number|nil
---@field bossGroupTotalDamage number|nil
---@field damageTakenTotal number|nil
---@field personalDTPS number|nil
---@field personalDPS number|nil
---@field bossPersonalDPS number|nil
---@field personalShare number|nil
---@field bossPersonalShare number|nil
---@field personalTotalRawHealingOut number|nil
---@field personalTotalEffectiveHealingOut number|nil
---@field personalRawHPSOut number|nil
---@field personalEffectiveHPSOut number|nil
---@field personalAoeVsSingleTarget { aoe: number, singleTarget: number }|nil
---@field bossAoeVsSingleTarget { aoe: number, singleTarget: number }|nil
---@field personalDotVsDirect { dot: number, direct: number }|nil
---@field bossDotVsDirect { dot: number, direct: number }|nil
---@field damageSummary { dps: number, groupDps: number|nil, share: number }|nil
---@field damageComposition { dotPercent: number|nil, directPercent: number|nil, aoePercent: number|nil, stPercent: number|nil }|nil
---@field damageQuality { critRate: number, maxHit: number }|nil
---@field damageTakenSummary { dtps: number, total: number }|nil
---@field damageTakenComposition { dotPercent: number|nil, directPercent: number|nil, aoePercent: number|nil, stPercent: number|nil }|nil
---@field damageTakenQuality { critRate: number, maxHit: number }|nil
---@field healingOutSummary { rawHps: number, effectiveHps: number, total: number, rawTotal: number, overhealPercent: number }|nil
---@field selfHealingSummary { rawHps: number, effectiveHps: number, total: number, rawTotal: number, overhealPercent: number }|nil
---@field healingInSummary { rawHps: number, effectiveHps: number, total: number, rawTotal: number, overhealPercent: number }|nil

---@class ArithmancerInstance
---@field _source BattleScrollsState|Encounter
---@field _abilityInfo table<number, AbilityInfo>
---@field _cache ArithmancerCache Cached computed values
local ArithmancerInstance = {}
local instanceMeta = { __index = ArithmancerInstance }

---Creates a new Arithmancer instance with lazy computation.
---No computation is performed until methods are called.
---@param source BattleScrollsState|Encounter Either BattleScrollsState or Encounter
---@param abilityInfo table<number, AbilityInfo>|nil Ability metadata (optional, uses source.abilityInfo if not provided)
---@return ArithmancerInstance
function Arithmancer:New(source, abilityInfo)
    local instance = {
        _source = source,
        _abilityInfo = abilityInfo or source.abilityInfo or {},
        _cache = {},
    }
    return setmetatable(instance, instanceMeta)
end

-- =============================================================================
-- SYNC METHODS (Simple/Fast Computations)
-- =============================================================================

---Returns fight duration in seconds (sync, computed on demand)
---@return number
function ArithmancerInstance:getDurationS()
    if self._cache.durationS ~= nil then
        return self._cache.durationS
    end

    local source = self._source
    local durationS = 0

    if source.durationMs then
        -- Stored encounter: use pre-computed duration
        durationS = source.durationMs / 1000
    elseif source.fightStartTimeMs and source.fightStartTimeMs > 0 then
        -- Prefer lastDamageDoneMs to prevent DPS ticking down during lingering combat
        -- Fall back to current time only if duration would be 0 (first hit edge case)
        local endTimeMs = source.lastDamageDoneMs
        if not endTimeMs or endTimeMs <= source.fightStartTimeMs then
            endTimeMs = GetGameTimeMilliseconds()
        end
        if endTimeMs >= source.fightStartTimeMs then
            durationS = (endTimeMs - source.fightStartTimeMs) / 1000
        end
    end

    self._cache.durationS = durationS
    return durationS
end

---Returns whether this is a boss fight (sync)
---@return boolean
function ArithmancerInstance:isBossFight()
    if self._cache.isBossFight ~= nil then
        return self._cache.isBossFight
    end

    local source = self._source
    local isBoss = source.isBossFight or (source.bossesUnits and #source.bossesUnits > 0) or false
    self._cache.isBossFight = isBoss
    return isBoss
end

-- =============================================================================
-- SYNC COMPUTED METHODS (Fast Computations - Return Values Directly)
-- These methods compute totals synchronously (<1ms even for large encounters)
-- =============================================================================

---Returns personal total damage (all targets)
---@return number
function ArithmancerInstance:personalTotalDamage()
    if self._cache.personalTotalDamage ~= nil then
        return self._cache.personalTotalDamage
    end

    local source = self._source
    local computeTotal = Arithmancer.ComputeDamageTotal
    local total = 0

    for _, byTarget in pairs(source.damageByUnitId) do
        for _, damage in pairs(byTarget) do
            total = total + computeTotal(damage)
        end
    end

    self._cache.personalTotalDamage = total
    return total
end

---Returns boss personal total damage
---@return number
function ArithmancerInstance:bossPersonalTotalDamage()
    if self._cache.bossPersonalTotalDamage ~= nil then
        return self._cache.bossPersonalTotalDamage
    end

    local source = self._source
    local computeTotal = Arithmancer.ComputeDamageTotal

    -- Build boss filter
    local bossFilter = nil
    if source.bossesUnits then
        bossFilter = {}
        for _, bossId in ipairs(source.bossesUnits) do
            bossFilter[bossId] = true
        end
    elseif source.bossesByUnitId then
        bossFilter = {}
        for unitId in pairs(source.bossesByUnitId) do
            bossFilter[unitId] = true
        end
    end

    if not bossFilter then
        self._cache.bossPersonalTotalDamage = 0
        return 0
    end

    local total = 0
    for _, byTarget in pairs(source.damageByUnitId) do
        for targetId, damage in pairs(byTarget) do
            if bossFilter[targetId] then
                total = total + computeTotal(damage)
            end
        end
    end

    self._cache.bossPersonalTotalDamage = total
    return total
end

---Returns group total damage (personal + group, all targets)
---@return number
function ArithmancerInstance:groupTotalDamage()
    if self._cache.groupTotalDamage ~= nil then
        return self._cache.groupTotalDamage
    end

    local source = self._source
    local computeTotal = Arithmancer.ComputeDamageTotal
    local total = 0

    -- Personal damage
    for _, byTarget in pairs(source.damageByUnitId) do
        for _, damage in pairs(byTarget) do
            total = total + computeTotal(damage)
        end
    end

    -- Group damage
    for _, byTarget in pairs(source.damageByUnitIdGroup) do
        for _, damage in pairs(byTarget) do
            total = total + computeTotal(damage)
        end
    end

    self._cache.groupTotalDamage = total
    return total
end

---Returns boss group total damage (personal + group, all bosses)
---@return number
function ArithmancerInstance:bossGroupTotalDamage()
    if self._cache.bossGroupTotalDamage ~= nil then
        return self._cache.bossGroupTotalDamage
    end

    local source = self._source
    local computeTotal = Arithmancer.ComputeDamageTotal

    -- Build boss filter
    local bossFilter = nil
    if source.bossesUnits then
        bossFilter = {}
        for _, bossId in ipairs(source.bossesUnits) do
            bossFilter[bossId] = true
        end
    elseif source.bossesByUnitId then
        bossFilter = {}
        for unitId in pairs(source.bossesByUnitId) do
            bossFilter[unitId] = true
        end
    end

    if not bossFilter then
        self._cache.bossGroupTotalDamage = 0
        return 0
    end

    local total = 0

    -- Personal damage to bosses
    for _, byTarget in pairs(source.damageByUnitId) do
        for targetId, damage in pairs(byTarget) do
            if bossFilter[targetId] then
                total = total + computeTotal(damage)
            end
        end
    end

    -- Group damage to bosses
    for _, byTarget in pairs(source.damageByUnitIdGroup) do
        for targetId, damage in pairs(byTarget) do
            if bossFilter[targetId] then
                total = total + computeTotal(damage)
            end
        end
    end

    self._cache.bossGroupTotalDamage = total
    return total
end

---Returns total damage taken
---@return number
function ArithmancerInstance:damageTakenTotal()
    if self._cache.damageTakenTotal ~= nil then
        return self._cache.damageTakenTotal
    end

    local source = self._source
    local computeTotal = Arithmancer.ComputeDamageTotal
    local total = 0

    for _, byTarget in pairs(source.damageTakenByUnitId) do
        for _, damage in pairs(byTarget) do
            total = total + computeTotal(damage)
        end
    end

    self._cache.damageTakenTotal = total
    return total
end

---Returns personal DTPS (damage taken per second)
---@return number
function ArithmancerInstance:personalDTPS()
    if self._cache.personalDTPS ~= nil then
        return self._cache.personalDTPS
    end

    local durationS = self:getDurationS()
    local total = self:damageTakenTotal()
    local dtps = durationS >= 0.001 and (total / durationS) or 0
    self._cache.personalDTPS = dtps
    return dtps
end

---Returns personal DPS (all targets)
---@return number
function ArithmancerInstance:personalDPS()
    if self._cache.personalDPS ~= nil then
        return self._cache.personalDPS
    end

    local durationS = self:getDurationS()
    local total = self:personalTotalDamage()
    local dps = durationS >= 0.001 and (total / durationS) or 0
    self._cache.personalDPS = dps
    return dps
end

---Returns boss personal DPS
---@return number
function ArithmancerInstance:bossPersonalDPS()
    if self._cache.bossPersonalDPS ~= nil then
        return self._cache.bossPersonalDPS
    end

    local durationS = self:getDurationS()
    local total = self:bossPersonalTotalDamage()
    local dps = durationS >= 0.001 and (total / durationS) or 0
    self._cache.bossPersonalDPS = dps
    return dps
end

---Returns personal share of total damage (0-100)
---@return number
function ArithmancerInstance:personalShare()
    if self._cache.personalShare ~= nil then
        return self._cache.personalShare
    end

    local personal = self:personalTotalDamage()
    local group = self:groupTotalDamage()
    local share = group > 0 and (personal / group * 100) or 0
    self._cache.personalShare = share
    return share
end

---Returns personal share of boss damage (0-100)
---@return number
function ArithmancerInstance:bossPersonalShare()
    if self._cache.bossPersonalShare ~= nil then
        return self._cache.bossPersonalShare
    end

    local personal = self:bossPersonalTotalDamage()
    local group = self:bossGroupTotalDamage()
    local share = group > 0 and (personal / group * 100) or 0
    self._cache.bossPersonalShare = share
    return share
end

---Returns total raw healing done by personal sources
---@return number
function ArithmancerInstance:personalTotalRawHealingOut()
    if self._cache.personalTotalRawHealingOut ~= nil then
        return self._cache.personalTotalRawHealingOut
    end

    local source = self._source
    local total = 0

    if source.healingStats then
        if source.healingStats.selfHealing then
            total = total + (source.healingStats.selfHealing.total.raw or 0)
        end
        for _, data in pairs(source.healingStats.healingOutToGroup or {}) do
            total = total + (data.total.raw or 0)
        end
    end

    self._cache.personalTotalRawHealingOut = total
    return total
end

---Returns total effective healing done by personal sources
---@return number
function ArithmancerInstance:personalTotalEffectiveHealingOut()
    if self._cache.personalTotalEffectiveHealingOut ~= nil then
        return self._cache.personalTotalEffectiveHealingOut
    end

    local source = self._source
    local total = 0

    if source.healingStats then
        if source.healingStats.selfHealing then
            total = total + (source.healingStats.selfHealing.total.real or 0)
        end
        for _, data in pairs(source.healingStats.healingOutToGroup or {}) do
            total = total + (data.total.real or 0)
        end
    end

    self._cache.personalTotalEffectiveHealingOut = total
    return total
end

---Returns personal raw HPS
---@return number
function ArithmancerInstance:personalRawHPSOut()
    if self._cache.personalRawHPSOut ~= nil then
        return self._cache.personalRawHPSOut
    end

    local durationS = self:getDurationS()
    local total = self:personalTotalRawHealingOut()
    local hps = durationS >= 0.001 and (total / durationS) or 0
    self._cache.personalRawHPSOut = hps
    return hps
end

---Returns personal effective HPS
---@return number
function ArithmancerInstance:personalEffectiveHPSOut()
    if self._cache.personalEffectiveHPSOut ~= nil then
        return self._cache.personalEffectiveHPSOut
    end

    local durationS = self:getDurationS()
    local total = self:personalTotalEffectiveHealingOut()
    local hps = durationS >= 0.001 and (total / durationS) or 0
    self._cache.personalEffectiveHPSOut = hps
    return hps
end

-- =============================================================================
-- BREAKDOWN METHODS (Sync, On-Demand)
-- =============================================================================

---Returns AOE vs single target breakdown for personal damage (all targets)
---@return { aoe: number, singleTarget: number }
function ArithmancerInstance:personalAoeVsSingleTarget()
    if self._cache.personalAoeVsSingleTarget ~= nil then
        return self._cache.personalAoeVsSingleTarget
    end

    local result = Arithmancer.ComputeAoeVsSingleTarget(self._source.damageByUnitId)
    self._cache.personalAoeVsSingleTarget = result
    return result
end

---Returns AOE vs single target breakdown for boss damage only
---@return { aoe: number, singleTarget: number }
function ArithmancerInstance:bossAoeVsSingleTarget()
    if self._cache.bossAoeVsSingleTarget ~= nil then
        return self._cache.bossAoeVsSingleTarget
    end

    local source = self._source

    -- Build boss filter
    local bossFilter = nil
    if source.bossesUnits then
        bossFilter = {}
        for _, bossId in ipairs(source.bossesUnits) do
            bossFilter[bossId] = true
        end
    elseif source.bossesByUnitId then
        bossFilter = {}
        for unitId in pairs(source.bossesByUnitId) do
            bossFilter[unitId] = true
        end
    end

    if not bossFilter then
        local result = { aoe = 0, singleTarget = 0 }
        self._cache.bossAoeVsSingleTarget = result
        return result
    end

    local filtered = Arithmancer.FilterDamageTable(source.damageByUnitId, bossFilter, nil)
    local result = Arithmancer.ComputeAoeVsSingleTarget(filtered)
    self._cache.bossAoeVsSingleTarget = result
    return result
end

---Returns DOT vs Direct breakdown for personal damage (all targets)
---@return { dot: number, direct: number }
function ArithmancerInstance:personalDotVsDirect()
    if self._cache.personalDotVsDirect ~= nil then
        return self._cache.personalDotVsDirect
    end

    local source = self._source
    local abilityInfo = self._abilityInfo
    local dot, direct = 0, 0

    for _, byTarget in pairs(source.damageByUnitId) do
        for _, damage in pairs(byTarget) do
            local breakdown = Arithmancer.ComputeByDotOrDirect(damage, abilityInfo)
            dot = dot + (breakdown.dot or 0)
            direct = direct + (breakdown.direct or 0)
        end
    end

    local result = { dot = dot, direct = direct }
    self._cache.personalDotVsDirect = result
    return result
end

---Returns DOT vs Direct breakdown for boss damage only
---@return { dot: number, direct: number }
function ArithmancerInstance:bossDotVsDirect()
    if self._cache.bossDotVsDirect ~= nil then
        return self._cache.bossDotVsDirect
    end

    local source = self._source
    local abilityInfo = self._abilityInfo

    -- Build boss filter
    local bossFilter = nil
    if source.bossesUnits then
        bossFilter = {}
        for _, bossId in ipairs(source.bossesUnits) do
            bossFilter[bossId] = true
        end
    elseif source.bossesByUnitId then
        bossFilter = {}
        for unitId in pairs(source.bossesByUnitId) do
            bossFilter[unitId] = true
        end
    end

    if not bossFilter then
        local result = { dot = 0, direct = 0 }
        self._cache.bossDotVsDirect = result
        return result
    end

    local dot, direct = 0, 0
    for _, byTarget in pairs(source.damageByUnitId) do
        for targetId, damage in pairs(byTarget) do
            if bossFilter[targetId] then
                local breakdown = Arithmancer.ComputeByDotOrDirect(damage, abilityInfo)
                dot = dot + (breakdown.dot or 0)
                direct = direct + (breakdown.direct or 0)
            end
        end
    end

    local result = { dot = dot, direct = direct }
    self._cache.bossDotVsDirect = result
    return result
end

-- =============================================================================
-- SUMMARY METHODS (Return data objects ready for rendering)
-- These methods support optional filters. Unfiltered results are cached.
-- =============================================================================

---@class DamageSummary
---@field dps number DPS (damage per second)
---@field groupDps number|nil Group DPS (nil if no group data)
---@field share number Personal damage share as percentage (0-100)

---Returns damage summary data for rendering: {dps, groupDps, share}
---@param targetFilter table<number, boolean>|nil Target unit IDs to include
---@param sourceFilter table<number, boolean>|nil Source unit IDs to include
---@param bossOnly boolean|nil If true, only include boss targets
---@return DamageSummary
function ArithmancerInstance:getDamageSummary(targetFilter, sourceFilter, bossOnly)
    local hasFilters = targetFilter or sourceFilter or bossOnly

    -- Check cache for unfiltered (return same table reference)
    if not hasFilters and self._cache.damageSummary then
        return self._cache.damageSummary
    end

    local source = self._source
    local durationS = self:getDurationS()

    -- Build effective target filter for bossOnly
    local effectiveTargetFilter = targetFilter
    if bossOnly and not targetFilter then
        effectiveTargetFilter = {}
        for _, bossId in ipairs(source.bossesUnits or {}) do
            effectiveTargetFilter[bossId] = true
        end
    end

    -- Compute totals
    local personalDamage, groupDamage
    if hasFilters then
        local filteredPersonal = Arithmancer.FilterDamageTable(source.damageByUnitId, effectiveTargetFilter, sourceFilter)
        local filteredGroup = Arithmancer.FilterDamageTable(source.damageByUnitIdGroup, effectiveTargetFilter, nil)
        personalDamage = Arithmancer.ComputeNestedTotal(filteredPersonal)
        local groupOnlyDamage = Arithmancer.ComputeNestedTotal(filteredGroup)
        groupDamage = personalDamage + groupOnlyDamage
    else
        personalDamage = self:personalTotalDamage()
        groupDamage = self:groupTotalDamage()
    end

    -- Compute summary
    local dps = durationS > 0 and (personalDamage / durationS) or 0
    local groupDps = groupDamage > personalDamage and (durationS > 0 and (groupDamage / durationS) or 0) or nil
    local share = groupDamage > 0 and (personalDamage / groupDamage * 100) or 100

    local result = { dps = dps, groupDps = groupDps, share = share }

    -- Cache unfiltered result
    if not hasFilters then
        self._cache.damageSummary = result
    end

    return result
end

---@class DamageComposition
---@field dotPercent number|nil DOT damage percentage (nil if no data)
---@field directPercent number|nil Direct damage percentage (nil if no data)
---@field aoePercent number|nil AOE damage percentage (nil if no data)
---@field stPercent number|nil Single-target damage percentage (nil if no data)

---Returns damage composition data: {dotPercent, directPercent, aoePercent, stPercent}
---@param targetFilter table<number, boolean>|nil Target unit IDs to include
---@param sourceFilter table<number, boolean>|nil Source unit IDs to include
---@param bossOnly boolean|nil If true, only include boss targets
---@return DamageComposition
function ArithmancerInstance:getDamageComposition(targetFilter, sourceFilter, bossOnly)
    local hasFilters = targetFilter or sourceFilter or bossOnly

    -- Check cache for unfiltered (return same table reference)
    if not hasFilters and self._cache.damageComposition then
        return self._cache.damageComposition
    end

    local source = self._source
    local abilityInfo = self._abilityInfo

    -- Build effective target filter for bossOnly
    local effectiveTargetFilter = targetFilter
    if bossOnly and not targetFilter then
        effectiveTargetFilter = {}
        for _, bossId in ipairs(source.bossesUnits or {}) do
            effectiveTargetFilter[bossId] = true
        end
    end

    -- Get filtered damage table
    local damageTable = Arithmancer.FilterDamageTable(source.damageByUnitId, effectiveTargetFilter, sourceFilter)
    if not damageTable then
        return { dotPercent = nil, directPercent = nil, aoePercent = nil, stPercent = nil }
    end

    -- DOT vs Direct
    local dot, direct = 0, 0
    for _, byTarget in pairs(damageTable) do
        for _, damage in pairs(byTarget) do
            local breakdown = Arithmancer.ComputeByDotOrDirect(damage, abilityInfo)
            dot = dot + (breakdown.dot or 0)
            direct = direct + (breakdown.direct or 0)
        end
    end
    local dotTotal = dot + direct
    local dotPercent, directPercent
    if dotTotal > 0 then
        dotPercent = (dot / dotTotal) * 100
        directPercent = (direct / dotTotal) * 100
    end

    -- AOE vs Single Target
    local aoeVsST = Arithmancer.ComputeAoeVsSingleTarget(damageTable)
    local aoeTotal = aoeVsST.aoe + aoeVsST.singleTarget
    local aoePercent, stPercent
    if aoeTotal > 0 then
        aoePercent = (aoeVsST.aoe / aoeTotal) * 100
        stPercent = (aoeVsST.singleTarget / aoeTotal) * 100
    end

    local result = { dotPercent = dotPercent, directPercent = directPercent, aoePercent = aoePercent, stPercent = stPercent }

    -- Cache unfiltered result
    if not hasFilters then
        self._cache.damageComposition = result
    end

    return result
end

---@class DamageQuality
---@field critRate number Critical hit rate as percentage (0-100)
---@field maxHit number Maximum single hit value

---Returns damage quality data: {critRate, maxHit}
---@param targetFilter table<number, boolean>|nil Target unit IDs to include
---@param sourceFilter table<number, boolean>|nil Source unit IDs to include
---@param bossOnly boolean|nil If true, only include boss targets
---@return DamageQuality
function ArithmancerInstance:getDamageQuality(targetFilter, sourceFilter, bossOnly)
    local hasFilters = targetFilter or sourceFilter or bossOnly

    -- Check cache for unfiltered (return same table reference)
    if not hasFilters and self._cache.damageQuality then
        return self._cache.damageQuality
    end

    local source = self._source

    -- Build effective target filter for bossOnly
    local effectiveTargetFilter = targetFilter
    if bossOnly and not targetFilter then
        effectiveTargetFilter = {}
        for _, bossId in ipairs(source.bossesUnits or {}) do
            effectiveTargetFilter[bossId] = true
        end
    end

    -- Get filtered damage table
    local damageTable = Arithmancer.FilterDamageTable(source.damageByUnitId, effectiveTargetFilter, sourceFilter)

    local totalHits = 0
    local critHits = 0
    local maxHit = 0

    if damageTable then
        for _, byTarget in pairs(damageTable) do
            for _, damage in pairs(byTarget) do
                for _, breakdown in pairs(Arithmancer.GetAbilities(damage)) do
                    totalHits = totalHits + (breakdown.ticks or 0)
                    critHits = critHits + (breakdown.critTicks or 0)
                    if breakdown.maxTick and breakdown.maxTick > maxHit then
                        maxHit = breakdown.maxTick
                    end
                end
            end
        end
    end

    local critRate = totalHits > 0 and (critHits / totalHits * 100) or 0
    local result = { critRate = critRate, maxHit = maxHit }

    -- Cache unfiltered result
    if not hasFilters then
        self._cache.damageQuality = result
    end

    return result
end

---@class DamageTakenSummary
---@field dtps number Damage taken per second
---@field total number Total damage taken

---Returns damage taken summary data: {dtps, total}
---@param sourceFilter table<number, boolean>|nil Source (attacker) unit IDs to include
---@return DamageTakenSummary
function ArithmancerInstance:getDamageTakenSummary(sourceFilter)
    local hasFilters = sourceFilter

    -- Check cache for unfiltered (return same table reference)
    if not hasFilters and self._cache.damageTakenSummary then
        return self._cache.damageTakenSummary
    end

    local source = self._source
    local durationS = self:getDurationS()

    local total
    if hasFilters then
        local filtered = Arithmancer.FilterDamageTakenTable(source.damageTakenByUnitId, sourceFilter)
        total = Arithmancer.ComputeNestedTotal(filtered)
    else
        total = self:damageTakenTotal()
    end

    local dtps = durationS > 0 and (total / durationS) or 0
    local result = { dtps = dtps, total = total }

    -- Cache unfiltered result
    if not hasFilters then
        self._cache.damageTakenSummary = result
    end

    return result
end

---Returns damage taken composition data: {dotPercent, directPercent, aoePercent, stPercent}
---@param sourceFilter table<number, boolean>|nil Source (attacker) unit IDs to include
---@return DamageComposition
function ArithmancerInstance:getDamageTakenComposition(sourceFilter)
    local hasFilters = sourceFilter

    -- Check cache for unfiltered (return same table reference)
    if not hasFilters and self._cache.damageTakenComposition then
        return self._cache.damageTakenComposition
    end

    local source = self._source
    local abilityInfo = self._abilityInfo

    -- Get filtered damage taken table
    local damageTakenTable = Arithmancer.FilterDamageTakenTable(source.damageTakenByUnitId, sourceFilter)
    if not damageTakenTable then
        return { dotPercent = nil, directPercent = nil, aoePercent = nil, stPercent = nil }
    end

    -- DOT vs Direct
    local dot, direct = 0, 0
    for _, byTarget in pairs(damageTakenTable) do
        for _, damage in pairs(byTarget) do
            local breakdown = Arithmancer.ComputeByDotOrDirect(damage, abilityInfo)
            dot = dot + (breakdown.dot or 0)
            direct = direct + (breakdown.direct or 0)
        end
    end
    local dotTotal = dot + direct
    local dotPercent, directPercent
    if dotTotal > 0 then
        dotPercent = (dot / dotTotal) * 100
        directPercent = (direct / dotTotal) * 100
    end

    -- AOE vs Single Target
    local aoeVsST = Arithmancer.ComputeAoeVsSingleTarget(damageTakenTable)
    local aoeTotal = aoeVsST.aoe + aoeVsST.singleTarget
    local aoePercent, stPercent
    if aoeTotal > 0 then
        aoePercent = (aoeVsST.aoe / aoeTotal) * 100
        stPercent = (aoeVsST.singleTarget / aoeTotal) * 100
    end

    local result = { dotPercent = dotPercent, directPercent = directPercent, aoePercent = aoePercent, stPercent = stPercent }

    -- Cache unfiltered result
    if not hasFilters then
        self._cache.damageTakenComposition = result
    end

    return result
end

---Returns damage taken quality data: {critRate, maxHit}
---@param sourceFilter table<number, boolean>|nil Source (attacker) unit IDs to include
---@return DamageQuality
function ArithmancerInstance:getDamageTakenQuality(sourceFilter)
    local hasFilters = sourceFilter

    -- Check cache for unfiltered (return same table reference)
    if not hasFilters and self._cache.damageTakenQuality then
        return self._cache.damageTakenQuality
    end

    local source = self._source

    -- Get filtered damage taken table
    local damageTakenTable = Arithmancer.FilterDamageTakenTable(source.damageTakenByUnitId, sourceFilter)

    local totalHits = 0
    local critHits = 0
    local maxHit = 0

    if damageTakenTable then
        for _, byTarget in pairs(damageTakenTable) do
            for _, damage in pairs(byTarget) do
                for _, breakdown in pairs(Arithmancer.GetAbilities(damage)) do
                    totalHits = totalHits + (breakdown.ticks or 0)
                    critHits = critHits + (breakdown.critTicks or 0)
                    if breakdown.maxTick and breakdown.maxTick > maxHit then
                        maxHit = breakdown.maxTick
                    end
                end
            end
        end
    end

    local critRate = totalHits > 0 and (critHits / totalHits * 100) or 0
    local result = { critRate = critRate, maxHit = maxHit }

    -- Cache unfiltered result
    if not hasFilters then
        self._cache.damageTakenQuality = result
    end

    return result
end

---@class HealingSummary
---@field rawHps number Raw HPS (healing per second)
---@field effectiveHps number Effective HPS (excludes overheal)
---@field total number Total effective healing
---@field rawTotal number Total raw healing
---@field overhealPercent number Overheal percentage (0-100)

---Returns healing out summary data: {rawHps, effectiveHps, total, rawTotal, overhealPercent}
---@param targetFilter table<number, boolean>|nil Target unit IDs to include (use -1 for self)
---@return HealingSummary
function ArithmancerInstance:getHealingOutSummary(targetFilter)
    local hasFilters = targetFilter

    -- Check cache for unfiltered (return same table reference)
    if not hasFilters and self._cache.healingOutSummary then
        return self._cache.healingOutSummary
    end

    local source = self._source
    local durationS = self:getDurationS()
    local healingStats = source.healingStats

    if not healingStats then
        return { rawHps = 0, effectiveHps = 0, total = 0, rawTotal = 0, overhealPercent = 0 }
    end

    local rawTotal, effectiveTotal = 0, 0

    -- Filter healing out to group
    local filteredHealingOut = Arithmancer.FilterHealingOutTable(healingStats.healingOutToGroup, targetFilter)
    if filteredHealingOut then
        for _, data in pairs(filteredHealingOut) do
            rawTotal = rawTotal + (data.total.raw or 0)
            effectiveTotal = effectiveTotal + (data.total.real or 0)
        end
    end

    -- Include self healing if not filtered out
    local includeSelf = not targetFilter or targetFilter[-1]
    if includeSelf and healingStats.selfHealing then
        rawTotal = rawTotal + (healingStats.selfHealing.total.raw or 0)
        effectiveTotal = effectiveTotal + (healingStats.selfHealing.total.real or 0)
    end

    local rawHps = durationS > 0 and (rawTotal / durationS) or 0
    local effectiveHps = durationS > 0 and (effectiveTotal / durationS) or 0
    local overhealPercent = rawTotal > 0 and ((rawTotal - effectiveTotal) / rawTotal * 100) or 0

    local result = { rawHps = rawHps, effectiveHps = effectiveHps, total = effectiveTotal, rawTotal = rawTotal, overhealPercent = overhealPercent }

    -- Cache unfiltered result
    if not hasFilters then
        self._cache.healingOutSummary = result
    end

    return result
end

---Returns self healing summary data: {rawHps, effectiveHps, total, rawTotal, overhealPercent}
---@return HealingSummary
function ArithmancerInstance:getSelfHealingSummary()
    -- Check cache (return same table reference)
    if self._cache.selfHealingSummary then
        return self._cache.selfHealingSummary
    end

    local source = self._source
    local durationS = self:getDurationS()
    local healingStats = source.healingStats

    if not healingStats or not healingStats.selfHealing then
        return { rawHps = 0, effectiveHps = 0, total = 0, rawTotal = 0, overhealPercent = 0 }
    end

    local rawTotal = healingStats.selfHealing.total.raw or 0
    local effectiveTotal = healingStats.selfHealing.total.real or 0

    local rawHps = durationS > 0 and (rawTotal / durationS) or 0
    local effectiveHps = durationS > 0 and (effectiveTotal / durationS) or 0
    local overhealPercent = rawTotal > 0 and ((rawTotal - effectiveTotal) / rawTotal * 100) or 0

    local result = { rawHps = rawHps, effectiveHps = effectiveHps, total = effectiveTotal, rawTotal = rawTotal, overhealPercent = overhealPercent }
    self._cache.selfHealingSummary = result
    return result
end

---Returns healing in summary data: {rawHps, effectiveHps, total, rawTotal, overhealPercent}
---@param sourceFilter table<number, boolean>|nil Source unit IDs to include
---@return HealingSummary
function ArithmancerInstance:getHealingInSummary(sourceFilter)
    local hasFilters = sourceFilter

    -- Check cache for unfiltered (return same table reference)
    if not hasFilters and self._cache.healingInSummary then
        return self._cache.healingInSummary
    end

    local source = self._source
    local durationS = self:getDurationS()
    local healingStats = source.healingStats

    if not healingStats or not healingStats.healingInFromGroup then
        return { rawHps = 0, effectiveHps = 0, total = 0, rawTotal = 0, overhealPercent = 0 }
    end

    local rawTotal, effectiveTotal = 0, 0

    local filteredHealingIn = Arithmancer.FilterHealingInTable(healingStats.healingInFromGroup, sourceFilter)
    if filteredHealingIn then
        for _, data in pairs(filteredHealingIn) do
            rawTotal = rawTotal + (data.total.raw or 0)
            effectiveTotal = effectiveTotal + (data.total.real or 0)
        end
    end

    local rawHps = durationS > 0 and (rawTotal / durationS) or 0
    local effectiveHps = durationS > 0 and (effectiveTotal / durationS) or 0
    local overhealPercent = rawTotal > 0 and ((rawTotal - effectiveTotal) / rawTotal * 100) or 0

    local result = { rawHps = rawHps, effectiveHps = effectiveHps, total = effectiveTotal, rawTotal = rawTotal, overhealPercent = overhealPercent }

    -- Cache unfiltered result
    if not hasFilters then
        self._cache.healingInSummary = result
    end

    return result
end

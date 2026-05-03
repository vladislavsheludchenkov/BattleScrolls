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
--   local calc = Arithmancer:Make(encounter, abilityInfo)
--   local dps = calc:personalDPS()  -- computed on first access, cached
--   local share = calc:personalShare()  -- uses cached totals
--
--   -- Boss-filtered instance (auto-builds boss target filter)
--   local bossCalc = Arithmancer:ForBosses(encounter, abilityInfo)
--   local bossDps = bossCalc:personalDPS()  -- boss-only DPS
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

---@param info AbilityInfo|nil
---@return AbilityDeliveryType|nil
function Arithmancer.GetAbilityDeliveryType(info)
    return info and info.deliveryType or nil
end

---@param info AbilityInfo|nil
---@return "hot"|"direct"|"shield"
local function getHealingDeliveryKey(info)
    local deliveryType = Arithmancer.GetAbilityDeliveryType(info)
    if deliveryType and deliveryType.shield then
        return "shield"
    end
    if deliveryType and deliveryType.overTime then
        return "hot"
    end
    return "direct"
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
        local deliveryType = Arithmancer.GetAbilityDeliveryType(info)
        local isDot = deliveryType and deliveryType.overTime
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
---@param abilityInfo table<number, AbilityInfo> Ability metadata for determining healing delivery
---@return { hot: { raw: number, real: number }, direct: { raw: number, real: number }, shield: { raw: number, real: number } }
function Arithmancer.ComputeByHotVsDirect(healingDone, abilityInfo)
    local result = {
        hot = { raw = 0, real = 0 },
        direct = { raw = 0, real = 0 },
        shield = { raw = 0, real = 0 },
    }
    -- Handle HealingDone (has byAbilityId directly)
    if healingDone.byAbilityId then
        for abilityId, breakdown in pairs(healingDone.byAbilityId) do
            local info = abilityInfo[abilityId]
            local key = getHealingDeliveryKey(info)
            result[key].raw = result[key].raw + (breakdown.raw or 0)
            result[key].real = result[key].real + (breakdown.real or 0)
        end
    end
    -- Handle HealingDoneDiffSource (has bySourceUnitIdByAbilityId)
    if healingDone.bySourceUnitIdByAbilityId then
        for _, byAbility in pairs(healingDone.bySourceUnitIdByAbilityId) do
            for abilityId, breakdown in pairs(byAbility) do
                local info = abilityInfo[abilityId]
                local key = getHealingDeliveryKey(info)
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
-- BOSS FILTER HELPER
-- =============================================================================

---Build a target filter containing boss unit IDs from encounter/state data
---@param source BattleScrollsState|Encounter
---@return table<number, boolean>|nil bossFilter nil if no boss data
local function buildBossFilter(source)
    if source.bossesUnits then
        local filter = {}
        for _, bossId in ipairs(source.bossesUnits) do
            filter[bossId] = true
        end
        return filter
    elseif source.bossesByUnitId then
        local filter = {}
        for unitId in pairs(source.bossesByUnitId) do
            filter[unitId] = true
        end
        return filter
    end
    return nil
end

-- =============================================================================
-- ARITHMANCER INSTANCE (LAZY COMPUTATION)
-- =============================================================================

---@class ArithmancerCache
---@field durationS number|nil
---@field isBossFight boolean|nil
---@field personalTotalDamage number|nil
---@field groupTotalDamage number|nil
---@field damageTakenTotal number|nil
---@field personalDTPS number|nil
---@field personalDPS number|nil
---@field personalShare number|nil
---@field personalTotalRawHealingOut number|nil
---@field personalTotalEffectiveHealingOut number|nil
---@field personalRawHPSOut number|nil
---@field personalEffectiveHPSOut number|nil
---@field personalAoeVsSingleTarget { aoe: number, singleTarget: number }|nil
---@field personalDotVsDirect { dot: number, direct: number }|nil
---@field personalDamageByType table<DamageType, number>|nil
---@field damageTakenDotVsDirect { dot: number, direct: number }|nil
---@field damageTakenByType table<DamageType, number>|nil
---@field damageSummary DamageSummary|nil
---@field damageComposition DamageComposition|nil
---@field damageQuality DamageQuality|nil
---@field damageTakenSummary DamageTakenSummary|nil
---@field damageTakenComposition DamageComposition|nil
---@field damageTakenQuality DamageQuality|nil
---@field healingOutSummary HealingSummary|nil
---@field selfHealingSummary HealingSummary|nil
---@field healingInSummary HealingSummary|nil
---@field healingOutQuality HealingQuality|nil
---@field selfHealingQuality HealingQuality|nil
---@field healingInQuality HealingQuality|nil
---@field _filteredDamageTable table<number, table<number, DamageDoneStorage>>|false|nil
---@field _filteredDamageTakenTable table<number, table<number, DamageDoneStorage>>|false|nil
---@field _filteredHealingOutTable table<number, HealingDoneDiffSource>|false|nil
---@field _filteredHealingInTable table<number, HealingDone>|false|nil

---@class ArithmancerInstance
---@field _source BattleScrollsState|Encounter
---@field _abilityInfo table<number, AbilityInfo>
---@field _cache ArithmancerCache Cached computed values
---@field _targetFilter table<number, boolean>|nil Target unit ID filter
---@field _sourceFilter table<number, boolean>|nil Source unit ID filter
local ArithmancerInstance = {}
local instanceMeta = { __index = ArithmancerInstance }

---Creates a new Arithmancer instance with lazy computation and optional filters.
---No computation is performed until methods are called.
---@param source BattleScrollsState|Encounter Either BattleScrollsState or Encounter
---@param abilityInfo table<number, AbilityInfo>|nil Ability metadata (optional, uses source.abilityInfo if not provided)
---@param filters { targetFilter: table<number, boolean>|nil, sourceFilter: table<number, boolean>|nil }|nil Optional filters
---@return ArithmancerInstance
function Arithmancer:Make(source, abilityInfo, filters)
    local instance = {
        _source = source,
        _abilityInfo = abilityInfo or source.abilityInfo or {},
        _cache = {},
        _targetFilter = filters and filters.targetFilter or nil,
        _sourceFilter = filters and filters.sourceFilter or nil,
    }
    return setmetatable(instance, instanceMeta)
end

---Creates a boss-filtered Arithmancer instance.
---Auto-builds a target filter from boss data. If extraFilters.targetFilter is provided,
---it takes precedence over the auto-built filter.
---Returns nil when there are no bosses in the encounter.
---When bosses exist, the target filter is the boss set intersected with any user-provided
---targetFilter (so user filters can only narrow, never widen beyond bosses).
---An empty intersection (user deselected all bosses) returns a valid instance that produces 0s.
---@param source BattleScrollsState|Encounter
---@param abilityInfo table<number, AbilityInfo>|nil
---@param extraFilters { targetFilter: table<number, boolean>|nil, sourceFilter: table<number, boolean>|nil }|nil
---@return ArithmancerInstance|nil
function Arithmancer:ForBosses(source, abilityInfo, extraFilters)
    local bossFilter = buildBossFilter(source)
    if not bossFilter or not next(bossFilter) then
        return nil
    end
    -- Intersect with user's target filter if provided
    local targetFilter = bossFilter
    if extraFilters and extraFilters.targetFilter then
        local intersected = {}
        for unitId in pairs(extraFilters.targetFilter) do
            if bossFilter[unitId] then
                intersected[unitId] = true
            end
        end
        targetFilter = intersected
    end
    local sourceFilter = extraFilters and extraFilters.sourceFilter or nil
    local instance = {
        _source = source,
        _abilityInfo = abilityInfo or source.abilityInfo or {},
        _cache = {},
        _targetFilter = targetFilter,
        _sourceFilter = sourceFilter,
    }
    return setmetatable(instance, instanceMeta)
end


-- =============================================================================
-- FILTERED DATA ACCESSORS (Lazy, Cached)
-- =============================================================================

---Returns filtered damage table (damageByUnitId with targetFilter + sourceFilter applied)
---@return table<number, table<number, DamageDoneStorage>>|nil
function ArithmancerInstance:filteredDamageTable()
    local cached = self._cache._filteredDamageTable
    if cached ~= nil then
        return cached ~= false and cached or nil
    end
    local result = Arithmancer.FilterDamageTable(self._source.damageByUnitId, self._targetFilter, self._sourceFilter)
    self._cache._filteredDamageTable = result or false
    return result
end

---Returns filtered damage taken table (damageTakenByUnitId with sourceFilter applied)
---@return table<number, table<number, DamageDoneStorage>>|nil
function ArithmancerInstance:filteredDamageTakenTable()
    local cached = self._cache._filteredDamageTakenTable
    if cached ~= nil then
        return cached ~= false and cached or nil
    end
    local result = Arithmancer.FilterDamageTakenTable(self._source.damageTakenByUnitId, self._sourceFilter)
    self._cache._filteredDamageTakenTable = result or false
    return result
end

---Returns filtered healing out table (healingOutToGroup with targetFilter applied)
---@return table<number, HealingDoneDiffSource>|nil
function ArithmancerInstance:filteredHealingOutTable()
    local cached = self._cache._filteredHealingOutTable
    if cached ~= nil then
        return cached ~= false and cached or nil
    end
    local healingStats = self._source.healingStats
    local healingOut = healingStats and healingStats.healingOutToGroup or nil
    local result = Arithmancer.FilterHealingOutTable(healingOut, self._targetFilter)
    self._cache._filteredHealingOutTable = result or false
    return result
end

---Returns filtered healing in table (healingInFromGroup with sourceFilter applied)
---@return table<number, HealingDone>|nil
function ArithmancerInstance:filteredHealingInTable()
    local cached = self._cache._filteredHealingInTable
    if cached ~= nil then
        return cached ~= false and cached or nil
    end
    local healingStats = self._source.healingStats
    local healingIn = healingStats and healingStats.healingInFromGroup or nil
    local result = Arithmancer.FilterHealingInTable(healingIn, self._sourceFilter)
    self._cache._filteredHealingInTable = result or false
    return result
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
-- All methods respect constructor filters via filtered data accessors.
-- =============================================================================

---Returns personal total damage (filtered by targetFilter + sourceFilter)
---@return number
function ArithmancerInstance:personalTotalDamage()
    if self._cache.personalTotalDamage ~= nil then
        return self._cache.personalTotalDamage
    end

    local total = Arithmancer.ComputeNestedTotal(self:filteredDamageTable())
    self._cache.personalTotalDamage = total
    return total
end

---Returns group total damage (personal + group, filtered by targetFilter only)
---sourceFilter is intentionally not applied: the group denominator includes all
---sources so that personalShare correctly reflects the player's contribution.
---@return number
function ArithmancerInstance:groupTotalDamage()
    if self._cache.groupTotalDamage ~= nil then
        return self._cache.groupTotalDamage
    end

    local source = self._source
    local targetFilter = self._targetFilter

    -- Personal damage (targetFilter only, no sourceFilter)
    local filteredPersonal = Arithmancer.FilterDamageTable(source.damageByUnitId, targetFilter, nil)
    local total = Arithmancer.ComputeNestedTotal(filteredPersonal)

    -- Group damage (targetFilter only)
    local filteredGroup = Arithmancer.FilterDamageTable(source.damageByUnitIdGroup, targetFilter, nil)
    total = total + Arithmancer.ComputeNestedTotal(filteredGroup)

    self._cache.groupTotalDamage = total
    return total
end

---Returns per-boss group damage breakdown keyed by "bossTag:tagSeq"
---Uses damageByUnitId (personal) + damageByUnitIdGroup (all observed group members)
---Reads bossTagSeqByUnitId from the source data
---@return table<string, number> perBossDamage Maps "bossTag:tagSeq" -> total damage
function ArithmancerInstance:groupDamageByBoss()
    local source = self._source
    local bossTagSeqByUnitId = source.bossTagSeqByUnitId
    if not bossTagSeqByUnitId then return {} end

    local computeTotal = Arithmancer.ComputeDamageTotal
    ---@type table<string, number>
    local result = {}

    -- Personal damage to bosses
    if source.damageByUnitId then
        for _, byTarget in pairs(source.damageByUnitId) do
            for targetId, damage in pairs(byTarget) do
                local key = bossTagSeqByUnitId[targetId]
                if key then
                    result[key] = (result[key] or 0) + computeTotal(damage)
                end
            end
        end
    end

    -- Group damage to bosses
    if source.damageByUnitIdGroup then
        for _, byTarget in pairs(source.damageByUnitIdGroup) do
            for targetId, damage in pairs(byTarget) do
                local key = bossTagSeqByUnitId[targetId]
                if key then
                    result[key] = (result[key] or 0) + computeTotal(damage)
                end
            end
        end
    end

    return result
end

---Returns total damage taken (filtered by sourceFilter)
---@return number
function ArithmancerInstance:damageTakenTotal()
    if self._cache.damageTakenTotal ~= nil then
        return self._cache.damageTakenTotal
    end

    local total = Arithmancer.ComputeNestedTotal(self:filteredDamageTakenTable())
    self._cache.damageTakenTotal = total
    return total
end

---Returns personal DPS (filtered by constructor filters)
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

---Returns personal share of total damage (0-100, filtered by constructor filters)
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

---Returns total raw healing done by personal sources (filtered)
---@return number
function ArithmancerInstance:personalTotalRawHealingOut()
    if self._cache.personalTotalRawHealingOut ~= nil then
        return self._cache.personalTotalRawHealingOut
    end

    local source = self._source
    local total = 0

    if source.healingStats then
        -- Include self healing if not filtered out by targetFilter
        local includeSelf = not self._targetFilter or self._targetFilter[-1]
        if includeSelf and source.healingStats.selfHealing then
            total = total + (source.healingStats.selfHealing.total.raw or 0)
        end
        local filteredHealingOut = self:filteredHealingOutTable()
        if filteredHealingOut then
            for _, data in pairs(filteredHealingOut) do
                total = total + (data.total.raw or 0)
            end
        end
    end

    self._cache.personalTotalRawHealingOut = total
    return total
end

---Returns total effective healing done by personal sources (filtered)
---@return number
function ArithmancerInstance:personalTotalEffectiveHealingOut()
    if self._cache.personalTotalEffectiveHealingOut ~= nil then
        return self._cache.personalTotalEffectiveHealingOut
    end

    local source = self._source
    local total = 0

    if source.healingStats then
        local includeSelf = not self._targetFilter or self._targetFilter[-1]
        if includeSelf and source.healingStats.selfHealing then
            total = total + (source.healingStats.selfHealing.total.real or 0)
        end
        local filteredHealingOut = self:filteredHealingOutTable()
        if filteredHealingOut then
            for _, data in pairs(filteredHealingOut) do
                total = total + (data.total.real or 0)
            end
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

---Returns AOE vs single target breakdown for personal damage (filtered)
---@return { aoe: number, singleTarget: number }
function ArithmancerInstance:personalAoeVsSingleTarget()
    if self._cache.personalAoeVsSingleTarget ~= nil then
        return self._cache.personalAoeVsSingleTarget
    end

    local result = Arithmancer.ComputeAoeVsSingleTarget(self:filteredDamageTable())
    self._cache.personalAoeVsSingleTarget = result
    return result
end

---Returns DOT vs Direct breakdown for personal damage (filtered)
---@return { dot: number, direct: number }
function ArithmancerInstance:personalDotVsDirect()
    if self._cache.personalDotVsDirect ~= nil then
        return self._cache.personalDotVsDirect
    end

    local damageTable = self:filteredDamageTable()
    local abilityInfo = self._abilityInfo
    local dot, direct = 0, 0

    if damageTable then
        for _, byTarget in pairs(damageTable) do
            for _, damage in pairs(byTarget) do
                local breakdown = Arithmancer.ComputeByDotOrDirect(damage, abilityInfo)
                dot = dot + (breakdown.dot or 0)
                direct = direct + (breakdown.direct or 0)
            end
        end
    end

    local result = { dot = dot, direct = direct }
    self._cache.personalDotVsDirect = result
    return result
end

---Returns damage by damage type aggregated across personal damage targets (filtered)
---@return table<DamageType, number> byDamageType Map of damageType -> total damage
function ArithmancerInstance:personalDamageByType()
    if self._cache.personalDamageByType ~= nil then
        return self._cache.personalDamageByType
    end

    local damageTable = self:filteredDamageTable()
    local abilityInfo = self._abilityInfo
    local result = {}

    if damageTable then
        for _, byTarget in pairs(damageTable) do
            for _, damage in pairs(byTarget) do
                local types = Arithmancer.ComputeByDamageType(damage, abilityInfo)
                for damageType, amount in pairs(types) do
                    result[damageType] = (result[damageType] or 0) + amount
                end
            end
        end
    end

    self._cache.personalDamageByType = result
    return result
end

---Returns DOT vs Direct breakdown for damage taken (filtered)
---@return { dot: number, direct: number }
function ArithmancerInstance:damageTakenDotVsDirect()
    if self._cache.damageTakenDotVsDirect ~= nil then
        return self._cache.damageTakenDotVsDirect
    end

    local damageTakenTable = self:filteredDamageTakenTable()
    local abilityInfo = self._abilityInfo
    local dot, direct = 0, 0

    if damageTakenTable then
        for _, byTarget in pairs(damageTakenTable) do
            for _, damage in pairs(byTarget) do
                local breakdown = Arithmancer.ComputeByDotOrDirect(damage, abilityInfo)
                dot = dot + (breakdown.dot or 0)
                direct = direct + (breakdown.direct or 0)
            end
        end
    end

    local result = { dot = dot, direct = direct }
    self._cache.damageTakenDotVsDirect = result
    return result
end

---Returns damage taken by damage type (filtered)
---@return table<DamageType, number> byDamageType Map of damageType -> total damage
function ArithmancerInstance:damageTakenByType()
    if self._cache.damageTakenByType ~= nil then
        return self._cache.damageTakenByType
    end

    local damageTakenTable = self:filteredDamageTakenTable()
    local abilityInfo = self._abilityInfo
    local result = {}

    if damageTakenTable then
        for _, byTarget in pairs(damageTakenTable) do
            for _, damage in pairs(byTarget) do
                local types = Arithmancer.ComputeByDamageType(damage, abilityInfo)
                for damageType, amount in pairs(types) do
                    result[damageType] = (result[damageType] or 0) + amount
                end
            end
        end
    end

    self._cache.damageTakenByType = result
    return result
end

-- =============================================================================
-- SUMMARY METHODS (Return data objects ready for rendering)
-- All methods are parameterless and cache unconditionally.
-- Filters are applied via constructor (Make/ForBosses).
-- =============================================================================

---@class DamageSummary
---@field dps number DPS (damage per second)
---@field groupDps number|nil Group DPS (nil if no group data)
---@field share number Personal damage share as percentage (0-100)
---@field personalTotal number Total personal damage
---@field groupTotal number|nil Total group damage (nil if no group data)

---Returns damage summary data for rendering
---@return DamageSummary
function ArithmancerInstance:getDamageSummary()
    if self._cache.damageSummary then
        return self._cache.damageSummary
    end

    local durationS = self:getDurationS()
    local personalDamage = self:personalTotalDamage()
    local groupDamage = self:groupTotalDamage()

    local dps = durationS > 0 and (personalDamage / durationS) or 0
    local hasGroup = groupDamage > personalDamage
    local groupDps = hasGroup and (durationS > 0 and (groupDamage / durationS) or 0) or nil
    local share = groupDamage > 0 and (personalDamage / groupDamage * 100) or 100

    local result = {
        dps = dps,
        groupDps = groupDps,
        share = share,
        personalTotal = personalDamage,
        groupTotal = hasGroup and groupDamage or nil,
    }

    self._cache.damageSummary = result
    return result
end

---@class DamageComposition
---@field dotPercent number|nil DOT damage percentage (nil if no data)
---@field directPercent number|nil Direct damage percentage (nil if no data)
---@field aoePercent number|nil AOE damage percentage (nil if no data)
---@field stPercent number|nil Single-target damage percentage (nil if no data)

---Returns damage composition data: {dotPercent, directPercent, aoePercent, stPercent}
---@return DamageComposition
function ArithmancerInstance:getDamageComposition()
    if self._cache.damageComposition then
        return self._cache.damageComposition
    end

    local abilityInfo = self._abilityInfo
    local damageTable = self:filteredDamageTable()

    if not damageTable then
        local result = { dotPercent = nil, directPercent = nil, aoePercent = nil, stPercent = nil }
        self._cache.damageComposition = result
        return result
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
    self._cache.damageComposition = result
    return result
end

---@class DamageQuality
---@field critRate number Critical hit rate as percentage (0-100)
---@field maxHit number Maximum single hit value

---Returns damage quality data: {critRate, maxHit}
---@return DamageQuality
function ArithmancerInstance:getDamageQuality()
    if self._cache.damageQuality then
        return self._cache.damageQuality
    end

    local damageTable = self:filteredDamageTable()

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
    self._cache.damageQuality = result
    return result
end

---@class DamageTakenSummary
---@field dtps number Damage taken per second
---@field total number Total damage taken

---Returns damage taken summary data: {dtps, total}
---@return DamageTakenSummary
function ArithmancerInstance:getDamageTakenSummary()
    if self._cache.damageTakenSummary then
        return self._cache.damageTakenSummary
    end

    local durationS = self:getDurationS()
    local total = self:damageTakenTotal()
    local dtps = durationS > 0 and (total / durationS) or 0
    local result = { dtps = dtps, total = total }
    self._cache.damageTakenSummary = result
    return result
end

---Returns damage taken composition data: {dotPercent, directPercent, aoePercent, stPercent}
---@return DamageComposition
function ArithmancerInstance:getDamageTakenComposition()
    if self._cache.damageTakenComposition then
        return self._cache.damageTakenComposition
    end

    local abilityInfo = self._abilityInfo
    local damageTakenTable = self:filteredDamageTakenTable()

    if not damageTakenTable then
        local result = { dotPercent = nil, directPercent = nil, aoePercent = nil, stPercent = nil }
        self._cache.damageTakenComposition = result
        return result
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
    self._cache.damageTakenComposition = result
    return result
end

---Returns damage taken quality data: {critRate, maxHit}
---@return DamageQuality
function ArithmancerInstance:getDamageTakenQuality()
    if self._cache.damageTakenQuality then
        return self._cache.damageTakenQuality
    end

    local damageTakenTable = self:filteredDamageTakenTable()

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
    self._cache.damageTakenQuality = result
    return result
end

---@class HealingSummary
---@field rawHps number Raw HPS (healing per second)
---@field effectiveHps number Effective HPS (excludes overheal)
---@field total number Total effective healing
---@field rawTotal number Total raw healing
---@field overhealPercent number Overheal percentage (0-100)

---Returns healing out summary data: {rawHps, effectiveHps, total, rawTotal, overhealPercent}
---@return HealingSummary
function ArithmancerInstance:getHealingOutSummary()
    if self._cache.healingOutSummary then
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
    local filteredHealingOut = self:filteredHealingOutTable()
    if filteredHealingOut then
        for _, data in pairs(filteredHealingOut) do
            rawTotal = rawTotal + (data.total.raw or 0)
            effectiveTotal = effectiveTotal + (data.total.real or 0)
        end
    end

    -- Include self healing if not filtered out
    local includeSelf = not self._targetFilter or self._targetFilter[-1]
    if includeSelf and healingStats.selfHealing then
        rawTotal = rawTotal + (healingStats.selfHealing.total.raw or 0)
        effectiveTotal = effectiveTotal + (healingStats.selfHealing.total.real or 0)
    end

    local rawHps = durationS > 0 and (rawTotal / durationS) or 0
    local effectiveHps = durationS > 0 and (effectiveTotal / durationS) or 0
    local overhealPercent = rawTotal > 0 and ((rawTotal - effectiveTotal) / rawTotal * 100) or 0

    local result = { rawHps = rawHps, effectiveHps = effectiveHps, total = effectiveTotal, rawTotal = rawTotal, overhealPercent = overhealPercent }
    self._cache.healingOutSummary = result
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
---@return HealingSummary
function ArithmancerInstance:getHealingInSummary()
    if self._cache.healingInSummary then
        return self._cache.healingInSummary
    end

    local source = self._source
    local durationS = self:getDurationS()
    local healingStats = source.healingStats

    if not healingStats or not healingStats.healingInFromGroup then
        return { rawHps = 0, effectiveHps = 0, total = 0, rawTotal = 0, overhealPercent = 0 }
    end

    local rawTotal, effectiveTotal = 0, 0

    local filteredHealingIn = self:filteredHealingInTable()
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
    self._cache.healingInSummary = result
    return result
end

-- =============================================================================
-- SHARED ENCOUNTER DATA
-- =============================================================================

---Build a SharedEncounterData summary for network sharing or display.
---Uses aggregated stats from this arithmancer instance with per-boss breakdowns.
---Reads bossTagSeqByUnitId from the source data.
---@return SharedEncounterData
function ArithmancerInstance:buildSharedEncounterData()
    local source = self._source
    local bossTagSeqByUnitId = source.bossTagSeqByUnitId

    -- Aggregate stats
    local totalDamage = self:personalTotalDamage()
    local qualityData = self:getDamageQuality()
    local critPercent = qualityData.critRate / 100  -- 0-1 range
    local dotVsDirect = self:personalDotVsDirect()
    local aoeVsSt = self:personalAoeVsSingleTarget()
    local damageByTypeMap = self:personalDamageByType()
    local totalDamageTaken = self:damageTakenTotal()

    -- Convert damage by type map to array
    ---@type SharedDamageByType[]
    local damageByType = {}
    for dmgType, amount in pairs(damageByTypeMap) do
        table.insert(damageByType, { type = dmgType, damage = amount })
    end

    -- Per-boss damage (requires manual iteration with bossTagSeqByUnitId mapping)
    ---@type SharedBossDamage[]
    local bossDamage = {}
    ---@type SharedBossDamageTaken[]
    local bossDamageTaken = {}

    if bossTagSeqByUnitId then
        local computeTotal = Arithmancer.ComputeDamageTotal
        local computeByDotOrDirect = Arithmancer.ComputeByDotOrDirect
        local abilityInfo = self._abilityInfo

        -- Per-boss damage output
        ---@type table<string, { damage: number, dotDamage: number, aoeDamage: number, magicalDamage: number, ticks: number, critTicks: number }>
        local bossDamageMap = {}
        local aoeAbilityIds = BattleScrolls.constants.aoeAbilityIds
        local magicalDamageTypes = {
            [DAMAGE_TYPE_MAGIC] = true,
            [DAMAGE_TYPE_FIRE] = true,
            [DAMAGE_TYPE_COLD] = true,
            [DAMAGE_TYPE_SHOCK] = true,
        }
        if source.damageByUnitId then
            for _, byTarget in pairs(source.damageByUnitId) do
                for targetId, dmg in pairs(byTarget) do
                    local key = bossTagSeqByUnitId[targetId]
                    if key then
                        local entry = bossDamageMap[key]
                        if not entry then
                            entry = { damage = 0, dotDamage = 0, aoeDamage = 0, magicalDamage = 0, ticks = 0, critTicks = 0 }
                            bossDamageMap[key] = entry
                        end
                        entry.damage = entry.damage + computeTotal(dmg)
                        local dotDirect = computeByDotOrDirect(dmg, abilityInfo)
                        entry.dotDamage = entry.dotDamage + dotDirect.dot
                        for abilityId, breakdown in pairs(getAbilities(dmg)) do
                            entry.ticks = entry.ticks + (breakdown.ticks or 0)
                            entry.critTicks = entry.critTicks + (breakdown.critTicks or 0)
                            -- AoE classification
                            if aoeAbilityIds[abilityId] then
                                entry.aoeDamage = entry.aoeDamage + breakdown.total
                            end
                            -- Magical classification (magic/fire/frost/shock)
                            local info = abilityInfo[abilityId]
                            if info and info.damageTypes then
                                for dmgType in pairs(info.damageTypes) do
                                    if magicalDamageTypes[dmgType] then
                                        entry.magicalDamage = entry.magicalDamage + breakdown.total
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        for key, entry in pairs(bossDamageMap) do
            local tag, seq = key:match("^(boss%d+):(%d+)$")
            if tag then
                local bossCritPercent = entry.ticks > 0 and (entry.critTicks / entry.ticks) or 0
                local d = entry.damage
                table.insert(bossDamage, {
                    bossTag = tag,
                    tagSeq = tonumber(seq) or 0,
                    damage = d,
                    critPercent = bossCritPercent,
                    dotPercent = d > 0 and (entry.dotDamage / d) or 0,
                    aoePercent = d > 0 and (entry.aoeDamage / d) or 0,
                    magicalPercent = d > 0 and (entry.magicalDamage / d) or 0,
                })
            end
        end

        -- Per-boss damage taken (bosses are at first level: sourceUnitId -> targetUnitId -> damage)
        ---@type table<string, number>
        local bossDtMap = {}
        if source.damageTakenByUnitId then
            for sourceId, byTarget in pairs(source.damageTakenByUnitId) do
                local key = bossTagSeqByUnitId[sourceId]
                if key then
                    for _, dmg in pairs(byTarget) do
                        bossDtMap[key] = (bossDtMap[key] or 0) + computeTotal(dmg)
                    end
                end
            end
        end

        for key, damage in pairs(bossDtMap) do
            local tag, seq = key:match("^(boss%d+):(%d+)$")
            if tag then
                table.insert(bossDamageTaken, {
                    bossTag = tag,
                    tagSeq = tonumber(seq) or 0,
                    damage = damage,
                })
            end
        end
    end

    -- Top 5 damage-taken abilities (aggregated across all sources)
    ---@type SharedDamageTakenAbility[]
    local topDamageTakenAbilities = {}
    if totalDamageTaken > 0 and source.damageTakenByUnitId then
        -- Aggregate damage by ability ID across all sources and targets
        ---@type table<number, number>
        local abilityDamageMap = {}
        for _, byTarget in pairs(source.damageTakenByUnitId) do
            for _, dmg in pairs(byTarget) do
                for abilityId, breakdown in pairs(getAbilities(dmg)) do
                    abilityDamageMap[abilityId] = (abilityDamageMap[abilityId] or 0) + breakdown.total
                end
            end
        end

        -- Sort by damage descending, take top 5
        ---@type { abilityId: number, damage: number }[]
        local sorted = {}
        for abilityId, damage in pairs(abilityDamageMap) do
            table.insert(sorted, { abilityId = abilityId, damage = damage })
        end
        table.sort(sorted, function(a, b) return a.damage > b.damage end)

        for i = 1, math.min(#sorted, 5) do
            table.insert(topDamageTakenAbilities, {
                abilityId = sorted[i].abilityId,
                damagePercent = sorted[i].damage / totalDamageTaken,
            })
        end
    end

    -- Deaths (first + optional last from encounter's deaths field)
    ---@type SharedDeaths|nil
    local deaths = nil
    if source.deaths and source.deaths.deathCount > 0 then
        local recaps = source.deaths.recaps
        deaths = {
            deathCount = math.min(source.deaths.deathCount, 16),
            first = recaps[1] and { timeOffsetMs = recaps[1].timeOffsetMs, attacks = recaps[1].attacks } or nil,
            last = recaps and #recaps > 1 and { timeOffsetMs = recaps[#recaps].timeOffsetMs, attacks = recaps[#recaps].attacks } or nil,
        }
    end

    -- Healing
    ---@type SharedHealing|nil
    local healing = nil
    local healOut = self:getHealingOutSummary()
    local selfHeal = self:getSelfHealingSummary()
    local rawOut = healOut.rawTotal
    local effectiveOut = healOut.total
    local rawSelf = selfHeal.rawTotal
    local effectiveSelf = selfHeal.total

    if rawOut > 0 or rawSelf > 0 then
        healing = {
            rawOut = rawOut,
            effectiveOut = effectiveOut,
            rawSelf = rawSelf,
            effectiveSelf = effectiveSelf,
        }
    end

    ---@type SharedEncounterData
    return {
        timestampS = source.timestampS or 0,
        durationMs = source.durationMs or 0,
        totalDamage = totalDamage,
        critPercent = critPercent,
        dotPercent = totalDamage > 0 and (dotVsDirect.dot / totalDamage) or 0,
        aoePercent = totalDamage > 0 and (aoeVsSt.aoe / totalDamage) or 0,
        maxHit = qualityData.maxHit,
        damageByType = damageByType,
        bossDamage = bossDamage,
        totalDamageTaken = totalDamageTaken,
        bossDamageTaken = bossDamageTaken,
        healing = healing,
        aliveTimeMs = source.playerAliveTimeMs,
        topDamageTakenAbilities = topDamageTakenAbilities,
        deaths = deaths,
    }
end

-- =============================================================================
-- HEALING QUALITY METHODS
-- =============================================================================

---@class HealingQuality
---@field critRate number Critical hit rate as percentage (0-100)
---@field maxHeal number Maximum raw heal value

---Returns healing out quality data: {critRate, maxHeal}
---Aggregates across all healing out targets + self healing (filtered)
---@return HealingQuality
function ArithmancerInstance:getHealingOutQuality()
    if self._cache.healingOutQuality then
        return self._cache.healingOutQuality
    end

    local source = self._source
    local healingStats = source.healingStats
    local totalTicks, totalCritTicks, maxHeal = 0, 0, 0

    if healingStats then
        local filteredHealingOut = self:filteredHealingOutTable()
        if filteredHealingOut then
            for _, targetData in pairs(filteredHealingOut) do
                if targetData.bySourceUnitIdByAbilityId then
                    for _, byAbility in pairs(targetData.bySourceUnitIdByAbilityId) do
                        for _, breakdown in pairs(byAbility) do
                            totalTicks = totalTicks + (breakdown.ticks or 0)
                            totalCritTicks = totalCritTicks + (breakdown.critTicks or 0)
                            if breakdown.maxTick and breakdown.maxTick > maxHeal then
                                maxHeal = breakdown.maxTick
                            end
                        end
                    end
                end
            end
        end

        -- Include self-healing if not filtered out
        local includeSelf = not self._targetFilter or self._targetFilter[-1]
        if includeSelf and healingStats.selfHealing and healingStats.selfHealing.bySourceUnitIdByAbilityId then
            for _, byAbility in pairs(healingStats.selfHealing.bySourceUnitIdByAbilityId) do
                for _, breakdown in pairs(byAbility) do
                    totalTicks = totalTicks + (breakdown.ticks or 0)
                    totalCritTicks = totalCritTicks + (breakdown.critTicks or 0)
                    if breakdown.maxTick and breakdown.maxTick > maxHeal then
                        maxHeal = breakdown.maxTick
                    end
                end
            end
        end
    end

    local critRate = totalTicks > 0 and (totalCritTicks / totalTicks * 100) or 0
    local result = { critRate = critRate, maxHeal = maxHeal }
    self._cache.healingOutQuality = result
    return result
end

---Returns self healing quality data: {critRate, maxHeal}
---@return HealingQuality
function ArithmancerInstance:getSelfHealingQuality()
    if self._cache.selfHealingQuality then
        return self._cache.selfHealingQuality
    end

    local source = self._source
    local healingStats = source.healingStats

    if not healingStats or not healingStats.selfHealing or not healingStats.selfHealing.bySourceUnitIdByAbilityId then
        local result = { critRate = 0, maxHeal = 0 }
        self._cache.selfHealingQuality = result
        return result
    end

    local totalTicks, totalCritTicks, maxHeal = 0, 0, 0
    for _, byAbility in pairs(healingStats.selfHealing.bySourceUnitIdByAbilityId) do
        for _, breakdown in pairs(byAbility) do
            totalTicks = totalTicks + (breakdown.ticks or 0)
            totalCritTicks = totalCritTicks + (breakdown.critTicks or 0)
            if breakdown.maxTick and breakdown.maxTick > maxHeal then
                maxHeal = breakdown.maxTick
            end
        end
    end

    local critRate = totalTicks > 0 and (totalCritTicks / totalTicks * 100) or 0
    local result = { critRate = critRate, maxHeal = maxHeal }
    self._cache.selfHealingQuality = result
    return result
end

---Returns healing in quality data: {critRate, maxHeal}
---Aggregates across all healing in sources + self healing (filtered)
---@return HealingQuality
function ArithmancerInstance:getHealingInQuality()
    if self._cache.healingInQuality then
        return self._cache.healingInQuality
    end

    local source = self._source
    local healingStats = source.healingStats
    local totalTicks, totalCritTicks, maxHeal = 0, 0, 0

    if healingStats then
        local filteredHealingIn = self:filteredHealingInTable()
        if filteredHealingIn then
            for _, sourceData in pairs(filteredHealingIn) do
                if sourceData.byAbilityId then
                    for _, breakdown in pairs(sourceData.byAbilityId) do
                        totalTicks = totalTicks + (breakdown.ticks or 0)
                        totalCritTicks = totalCritTicks + (breakdown.critTicks or 0)
                        if breakdown.maxTick and breakdown.maxTick > maxHeal then
                            maxHeal = breakdown.maxTick
                        end
                    end
                end
            end
        end

        -- Include self-healing if no sourceFilter is active
        if not self._sourceFilter and healingStats.selfHealing and healingStats.selfHealing.bySourceUnitIdByAbilityId then
            for _, byAbility in pairs(healingStats.selfHealing.bySourceUnitIdByAbilityId) do
                for _, breakdown in pairs(byAbility) do
                    totalTicks = totalTicks + (breakdown.ticks or 0)
                    totalCritTicks = totalCritTicks + (breakdown.critTicks or 0)
                    if breakdown.maxTick and breakdown.maxTick > maxHeal then
                        maxHeal = breakdown.maxTick
                    end
                end
            end
        end
    end

    local critRate = totalTicks > 0 and (totalCritTicks / totalTicks * 100) or 0
    local result = { critRate = critRate, maxHeal = maxHeal }
    self._cache.healingInQuality = result
    return result
end

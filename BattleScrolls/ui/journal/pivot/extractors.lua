-----------------------------------------------------------
-- Pivot Extractors
-- Dimension and metric extractor registries for pivot queries
--
-- Extractors bridge raw encounter data and pivot result rows.
-- Each extractor knows how to traverse encounter data and
-- produce (key, value) pairs for a specific dimension or metric.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local pivot = BattleScrolls.journal.pivot
local Arithmancer = BattleScrolls.arithmancer
local constants = BattleScrolls.constants
local journal = BattleScrolls.journal
local utils = BattleScrolls.journal.utils

local extractors = {}
pivot.extractors = extractors

-------------------------
-- Formatting helpers
-------------------------

local function formatCompact(value)
    return utils.formatCompact(value)
end

local function formatPercent(value)
    return string.format("%.1f%%", value)
end

local function formatSeconds(value)
    if value >= 60 then
        return string.format("%d:%02d", math.floor(value / 60), math.floor(value) % 60)
    end
    return zo_strformat(GetString(BATTLESCROLLS_FORMAT_SECONDS), string.format("%.1f", value))
end

local function formatCount(value)
    if value % 1 < 0.005 then
        return string.format("%.0f", value)
    elseif value >= 1 then
        return string.format("%.1f", value)
    else
        return string.format("%.2f", value)
    end
end

-------------------------
-- Dimension Extractors (Decode domains: damage, healing, effects)
-------------------------

---Registry of dimension extractors keyed by dimension ID
---@type table<string, DimensionExtractor>
extractors.dimensions = {}

---Iterate a damage table and group breakdowns by a key function.
---@param damageTable table|nil Nested source->target->DamageDoneStorage
---@param keyFn fun(sourceId: number, targetId: number, abilityId: number, bd: DamageBreakdown): string|nil
---@return table<string, DamageBreakdown[]>
local function groupDamageBreakdowns(damageTable, keyFn)
    if not damageTable then return {} end
    local result = {}
    for sourceId, byTarget in pairs(damageTable) do
        for targetId, damageData in pairs(byTarget) do
            local abilities = Arithmancer.GetAbilities(damageData)
            for abilityId, bd in pairs(abilities) do
                local key = keyFn(sourceId, targetId, abilityId, bd)
                if key then
                    if not result[key] then result[key] = {} end
                    table.insert(result[key], bd)
                end
            end
        end
    end
    return result
end

---Key function: group by ability name
---@param _sourceId number
---@param _targetId number
---@param abilityId number
---@return string
local function keyByAbilityName(_sourceId, _targetId, abilityId)
    local name = GetAbilityName(abilityId, "")
    return name ~= "" and name or tostring(abilityId)
end

---@param healingByUnit table|nil Nested unit->HealingDone or HealingDoneDiffSource
---@return table<string, HealingBreakdown[]>
local function extractAbilitiesFromHealing(healingByUnit)
    if not healingByUnit then return {} end
    local byName = {}
    for _, healData in pairs(healingByUnit) do
        if healData.bySourceUnitIdByAbilityId then
            -- HealingDoneDiffSource: iterate source->ability
            for _, byAbility in pairs(healData.bySourceUnitIdByAbilityId) do
                for abilityId, breakdown in pairs(byAbility) do
                    local name = GetAbilityName(abilityId, "")
                    if name == "" then name = tostring(abilityId) end
                    if not byName[name] then byName[name] = {} end
                    table.insert(byName[name], breakdown)
                end
            end
        elseif healData.byAbilityId then
            -- HealingDone
            for abilityId, breakdown in pairs(healData.byAbilityId) do
                local name = GetAbilityName(abilityId, "")
                if name == "" then name = tostring(abilityId) end
                if not byName[name] then byName[name] = {} end
                table.insert(byName[name], breakdown)
            end
        end
    end
    return byName
end

extractors.dimensions[pivot.Dimension.ABILITY] = {
    id = pivot.Dimension.ABILITY,
    displayName = "BATTLESCROLLS_PIVOT_DIM_ABILITY",
    domains = {
        [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true,
        [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true,
        [pivot.Domain.EFFECTS_SELF] = true, [pivot.Domain.EFFECTS_BOSS] = true, [pivot.Domain.EFFECTS_GROUP] = true,
    },
    extract = function(decoded, _abilityInfo, domain, _unitNames)
        if domain == pivot.Domain.EFFECTS_SELF then
            -- Group player effects by ability name
            local effects = decoded.effectsOnPlayer
            if not effects then return {} end
            local byName = {}
            for abilityId, stats in pairs(effects) do
                local name = GetAbilityName(abilityId, "")
                if name == "" then name = tostring(abilityId) end
                if not byName[name] then byName[name] = {} end
                table.insert(byName[name], stats)
            end
            return byName
        elseif domain == pivot.Domain.EFFECTS_BOSS then
            -- Group boss effects by ability name across all bosses
            local effectsOnBosses = decoded.effectsOnBosses
            if not effectsOnBosses then return {} end
            local byName = {}
            for _, bossEffects in pairs(effectsOnBosses) do
                for abilityId, stats in pairs(bossEffects) do
                    local name = GetAbilityName(abilityId, "")
                    if name == "" then name = tostring(abilityId) end
                    if not byName[name] then byName[name] = {} end
                    table.insert(byName[name], stats)
                end
            end
            return byName
        elseif domain == pivot.Domain.EFFECTS_GROUP then
            -- Group effects by ability name: all group members + player buffs
            local byName = {}
            local effectsOnGroup = decoded.effectsOnGroup
            if effectsOnGroup then
                for _, memberEffects in pairs(effectsOnGroup) do
                    for abilityId, stats in pairs(memberEffects) do
                        local name = GetAbilityName(abilityId, "")
                        if name == "" then name = tostring(abilityId) end
                        if not byName[name] then byName[name] = {} end
                        table.insert(byName[name], stats)
                    end
                end
            end
            -- Also include player buffs from effectsOnPlayer
            local effectsOnPlayer = decoded.effectsOnPlayer
            if effectsOnPlayer then
                for abilityId, stats in pairs(effectsOnPlayer) do
                    if stats.effectType == BUFF_EFFECT_TYPE_BUFF then
                        local name = GetAbilityName(abilityId, "")
                        if name == "" then name = tostring(abilityId) end
                        if not byName[name] then byName[name] = {} end
                        table.insert(byName[name], stats)
                    end
                end
            end
            return byName
        elseif domain == pivot.Domain.HEALING_OUT or domain == pivot.Domain.HEALING_IN then
            local hs = decoded.healingStats
            if not hs then return {} end
            local result = {}
            -- Healing Out: healingOutToGroup + selfHealing
            -- Healing In: healingInFromGroup + selfHealing
            local mainTable = domain == pivot.Domain.HEALING_OUT
                and hs.healingOutToGroup or hs.healingInFromGroup
            if mainTable then
                for k, v in pairs(extractAbilitiesFromHealing(mainTable)) do
                    result[k] = v
                end
            end
            if hs.selfHealing then
                for k, v in pairs(extractAbilitiesFromHealing({ hs.selfHealing })) do
                    if result[k] then
                        for _, bd in ipairs(v) do table.insert(result[k], bd) end
                    else
                        result[k] = v
                    end
                end
            end
            return result
        end
        -- Damage / Damage Taken
        local damageTable = domain == pivot.Domain.DAMAGE_IN
            and decoded.damageTakenByUnitId or decoded.damageByUnitId
        return groupDamageBreakdowns(damageTable, keyByAbilityName)
    end,
}

extractors.dimensions[pivot.Dimension.TARGET] = {
    id = pivot.Dimension.TARGET,
    displayName = "BATTLESCROLLS_PIVOT_DIM_TARGET",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.HEALING_OUT] = true },
    extract = function(decoded, _abilityInfo, domain, unitNames)
        if domain == pivot.Domain.HEALING_OUT then
            -- Healing: group by heal target
            local byTarget = {}
            local hs = decoded.healingStats
            if hs then
                -- healingOutToGroup uses HealingDoneDiffSource (bySourceUnitIdByAbilityId)
                for targetId, healData in pairs(hs.healingOutToGroup or {}) do
                    local rawName = unitNames and unitNames[targetId]
                    local name = rawName and zo_strformat(SI_UNIT_NAME, rawName) or GetString(BATTLESCROLLS_UNKNOWN)
                    if not byTarget[name] then byTarget[name] = {} end
                    for _, byAbility in pairs(healData.bySourceUnitIdByAbilityId or {}) do
                        for _, breakdown in pairs(byAbility) do
                            table.insert(byTarget[name], breakdown)
                        end
                    end
                end
                -- selfHealing uses HealingDoneDiffSource (bySourceUnitIdByAbilityId)
                if hs.selfHealing then
                    local selfName = BattleScrolls.utils.GetUndecoratedDisplayName()
                    if not byTarget[selfName] then byTarget[selfName] = {} end
                    for _, byAbility in pairs(hs.selfHealing.bySourceUnitIdByAbilityId or {}) do
                        for _, breakdown in pairs(byAbility) do
                            table.insert(byTarget[selfName], breakdown)
                        end
                    end
                end
            end
            return byTarget
        end
        -- Damage
        return groupDamageBreakdowns(decoded.damageByUnitId, function(_, targetId)
            local name = unitNames and unitNames[targetId]
            return name and zo_strformat(SI_UNIT_NAME, name) or GetString(BATTLESCROLLS_UNKNOWN)
        end)
    end,
}

extractors.dimensions[pivot.Dimension.SOURCE] = {
    id = pivot.Dimension.SOURCE,
    displayName = "BATTLESCROLLS_PIVOT_DIM_SOURCE",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(decoded, _abilityInfo, domain, unitNames)
        if domain == pivot.Domain.HEALING_IN then
            -- Healing: group by heal source using healingInFromGroup + selfHealing
            local hs = decoded.healingStats
            if not hs then return {} end
            local bySource = {}
            -- healingInFromGroup uses HealingDone (byAbilityId)
            for sourceId, healData in pairs(hs.healingInFromGroup or {}) do
                local rawName = unitNames and unitNames[sourceId]
                local name = rawName and zo_strformat(SI_UNIT_NAME, rawName) or GetString(BATTLESCROLLS_UNKNOWN)
                if not bySource[name] then bySource[name] = {} end
                for _, breakdown in pairs(healData.byAbilityId or {}) do
                    table.insert(bySource[name], breakdown)
                end
            end
            -- selfHealing uses HealingDoneDiffSource (bySourceUnitIdByAbilityId)
            if hs.selfHealing then
                local selfName = BattleScrolls.utils.GetUndecoratedDisplayName()
                if not bySource[selfName] then bySource[selfName] = {} end
                for _, byAbility in pairs(hs.selfHealing.bySourceUnitIdByAbilityId or {}) do
                    for _, breakdown in pairs(byAbility) do
                        table.insert(bySource[selfName], breakdown)
                    end
                end
            end
            return bySource
        end
        -- Damage / Damage Taken
        local damageTable = domain == pivot.Domain.DAMAGE_IN
            and decoded.damageTakenByUnitId or decoded.damageByUnitId
        return groupDamageBreakdowns(damageTable, function(sourceId)
            local name = unitNames and unitNames[sourceId]
            return name and zo_strformat(SI_UNIT_NAME, name) or GetString(BATTLESCROLLS_UNKNOWN)
        end)
    end,
}

extractors.dimensions[pivot.Dimension.BOSS] = {
    id = pivot.Dimension.BOSS,
    displayName = "BATTLESCROLLS_PIVOT_DIM_BOSS",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.EFFECTS_BOSS] = true },
    extract = function(decoded, _abilityInfo, domain, _unitNames)
        if domain == pivot.Domain.EFFECTS_BOSS then
            -- Group boss effects by boss name
            local effectsOnBosses = decoded.effectsOnBosses
            if not effectsOnBosses then return {} end
            local bossNames = decoded.bossNames
            local byBoss = {}
            for unitTag, bossEffects in pairs(effectsOnBosses) do
                local bossName = (bossNames and bossNames[unitTag]) or unitTag
                if not byBoss[bossName] then byBoss[bossName] = {} end
                for _, stats in pairs(bossEffects) do
                    table.insert(byBoss[bossName], stats)
                end
            end
            return byBoss
        end
        -- Damage
        if not decoded.bossTagSeqByUnitId or not decoded.bossSeqNames then return {} end
        return groupDamageBreakdowns(decoded.damageByUnitId, function(_, targetId)
            local tagSeq = decoded.bossTagSeqByUnitId[targetId]
            if not tagSeq then return nil end
            return decoded.bossSeqNames[tagSeq] or GetString(BATTLESCROLLS_UNKNOWN_BOSS)
        end)
    end,
}

extractors.dimensions[pivot.Dimension.DAMAGE_TYPE] = {
    id = pivot.Dimension.DAMAGE_TYPE,
    displayName = "BATTLESCROLLS_PIVOT_DIM_DAMAGE_TYPE",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true },
    extract = function(decoded, abilityInfo, domain, _unitNames)
        local damageTable = domain == pivot.Domain.DAMAGE_IN
            and decoded.damageTakenByUnitId or decoded.damageByUnitId
        if not damageTable then return {} end
        local byType = {}
        for _, byTarget in pairs(damageTable) do
            for _, damageData in pairs(byTarget) do
                local abilities = Arithmancer.GetAbilities(damageData)
                for abilityId, bd in pairs(abilities) do
                    local info = abilityInfo[abilityId]
                    if info and info.damageTypes then
                        for damageType in pairs(info.damageTypes) do
                            local typeName = (journal.DamageTypeNames and journal.DamageTypeNames[damageType]) or tostring(damageType)
                            if not byType[typeName] then byType[typeName] = {} end
                            table.insert(byType[typeName], bd)
                        end
                    end
                end
            end
        end
        return byType
    end,
}

extractors.dimensions[pivot.Dimension.DELIVERY] = {
    id = pivot.Dimension.DELIVERY,
    displayName = "BATTLESCROLLS_PIVOT_DIM_DELIVERY",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.HEALING_OUT] = true },
    extract = function(decoded, abilityInfo, domain, _unitNames)
        if domain == pivot.Domain.HEALING_OUT then
            -- HoT vs Direct healing using Arithmancer
            local healingOut = decoded.healingStats and decoded.healingStats.healingOutToGroup
            if not healingOut then return {} end
            local hotRaw, directRaw, shieldRaw = 0, 0, 0
            for _, healData in pairs(healingOut) do
                local result = Arithmancer.ComputeByHotVsDirect(healData, abilityInfo)
                hotRaw = hotRaw + (result.hot and result.hot.raw or 0)
                directRaw = directRaw + (result.direct and result.direct.raw or 0)
                shieldRaw = shieldRaw + (result.shield and result.shield.raw or 0)
            end
            local byDelivery = {}
            if hotRaw > 0 then
                byDelivery[GetString(BATTLESCROLLS_DELIVERY_HOT)] = {{ raw = hotRaw, real = hotRaw, overheal = 0, ticks = 0, critTicks = 0, minTick = 0, maxTick = 0 }}
            end
            if directRaw > 0 then
                byDelivery[GetString(BATTLESCROLLS_DELIVERY_DIRECT)] = {{ raw = directRaw, real = directRaw, overheal = 0, ticks = 0, critTicks = 0, minTick = 0, maxTick = 0 }}
            end
            if shieldRaw > 0 then
                byDelivery[GetString(BATTLESCROLLS_DELIVERY_SHIELD)] = {{ raw = shieldRaw, real = shieldRaw, overheal = 0, ticks = 0, critTicks = 0, minTick = 0, maxTick = 0 }}
            end
            return byDelivery
        end
        -- Damage
        return groupDamageBreakdowns(decoded.damageByUnitId, function(_, _, abilityId)
            local info = abilityInfo[abilityId]
            local deliveryType = Arithmancer.GetAbilityDeliveryType(info)
            local isDot = deliveryType and deliveryType.overTime
            return isDot and GetString(BATTLESCROLLS_DELIVERY_DOT) or GetString(BATTLESCROLLS_DELIVERY_DIRECT)
        end)
    end,
}

extractors.dimensions[pivot.Dimension.AOE_ST] = {
    id = pivot.Dimension.AOE_ST,
    displayName = "BATTLESCROLLS_PIVOT_DIM_AOE_ST",
    domains = { [pivot.Domain.DAMAGE] = true },
    extract = function(decoded, _abilityInfo, _domain, _unitNames)
        local aoeAbilityIds = constants.aoeAbilityIds
        return groupDamageBreakdowns(decoded.damageByUnitId, function(_, _, abilityId)
            return aoeAbilityIds[abilityId] and GetString(BATTLESCROLLS_AOE) or GetString(BATTLESCROLLS_SINGLE_TARGET)
        end)
    end,
}

extractors.dimensions[pivot.Dimension.BUFF_DEBUFF] = {
    id = pivot.Dimension.BUFF_DEBUFF,
    displayName = "BATTLESCROLLS_PIVOT_DIM_BUFF_DEBUFF",
    domains = { [pivot.Domain.EFFECTS_SELF] = true },
    extract = function(decoded, _abilityInfo, _filters, _unitNames)
        local effects = decoded.effectsOnPlayer
        if not effects then return {} end
        local result = {}
        for _, stats in pairs(effects) do
            local typeName
            if stats.effectType == BUFF_EFFECT_TYPE_BUFF then
                typeName = GetString(BATTLESCROLLS_HEADER_YOUR_BUFFS)
            else
                typeName = GetString(BATTLESCROLLS_HEADER_DEBUFFS_ON_YOU)
            end
            if not result[typeName] then result[typeName] = {} end
            table.insert(result[typeName], stats)
        end
        return result
    end,
}

extractors.dimensions[pivot.Dimension.GROUP_MEMBER] = {
    id = pivot.Dimension.GROUP_MEMBER,
    displayName = "BATTLESCROLLS_PIVOT_DIM_GROUP_MEMBER",
    domains = { [pivot.Domain.EFFECTS_GROUP] = true },
    extract = function(decoded, _abilityInfo, _domain, _unitNames)
        local result = {}
        local effectsOnGroup = decoded.effectsOnGroup
        if effectsOnGroup then
            for displayName, memberEffects in pairs(effectsOnGroup) do
                if not result[displayName] then result[displayName] = {} end
                for _, stats in pairs(memberEffects) do
                    table.insert(result[displayName], stats)
                end
            end
        end
        -- Also include player buffs from effectsOnPlayer
        local effectsOnPlayer = decoded.effectsOnPlayer
        if effectsOnPlayer then
            local playerName = BattleScrolls.utils.GetUndecoratedDisplayName()
            for _, stats in pairs(effectsOnPlayer) do
                if stats.effectType == BUFF_EFFECT_TYPE_BUFF then
                    if not result[playerName] then result[playerName] = {} end
                    table.insert(result[playerName], stats)
                end
            end
        end
        return result
    end,
}

-- Encounter, Instance, and Role dimensions: extract is never called.
-- Engine handles encounter/instance grouping at loop level; Role is GROUP-only
-- (routed through groupDimensions). Stubs satisfy the DimensionExtractor type.
local function stubExtract() return {} end

extractors.dimensions[pivot.Dimension.ENCOUNTER] = {
    id = pivot.Dimension.ENCOUNTER,
    displayName = "BATTLESCROLLS_PIVOT_DIM_ENCOUNTER",
    domains = {
        [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true,
        [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true,
        [pivot.Domain.EFFECTS_SELF] = true, [pivot.Domain.EFFECTS_BOSS] = true, [pivot.Domain.EFFECTS_GROUP] = true,
    },
    extract = stubExtract,
}

extractors.dimensions[pivot.Dimension.INSTANCE] = {
    id = pivot.Dimension.INSTANCE,
    displayName = "BATTLESCROLLS_PIVOT_DIM_INSTANCE",
    domains = {
        [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true,
        [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true,
        [pivot.Domain.EFFECTS_SELF] = true, [pivot.Domain.EFFECTS_BOSS] = true, [pivot.Domain.EFFECTS_GROUP] = true,
    },
    extract = stubExtract,
}

extractors.dimensions[pivot.Dimension.ROLE] = {
    id = pivot.Dimension.ROLE,
    displayName = "BATTLESCROLLS_PIVOT_DIM_ROLE",
    domains = {},
    extract = stubExtract,
}

-------------------------
-- Metric Extractors (Decode domains)
-------------------------

---Aggregate helpers: reusable functions for MetricExtractor.aggregate

---Max of each breakdown's extracted value
---@param ext MetricExtractor
---@return fun(breakdowns: any[], durationS: number): number
local function aggMax(ext)
    return function(breakdowns, durationS)
        local maxVal = 0
        for _, bd in ipairs(breakdowns) do
            local v = ext.extract(bd, durationS)
            if v > maxVal then maxVal = v end
        end
        return maxVal
    end
end

---Min of each breakdown's extracted value (ignoring 0)
---@param ext MetricExtractor
---@return fun(breakdowns: any[], durationS: number): number
local function aggMin(ext)
    return function(breakdowns, durationS)
        local minVal = math.huge
        for _, bd in ipairs(breakdowns) do
            local v = ext.extract(bd, durationS)
            if v > 0 and v < minVal then minVal = v end
        end
        return minVal == math.huge and 0 or minVal
    end
end

---Uptime metrics: dispatch by user-selected aggregation (avg/max/min/sum)
---@param ext MetricExtractor
---@return fun(breakdowns: any[], durationS: number, aliveTimeS: number|nil, aggregation: string|nil): number
---Uptime metrics: always average within-cell (matching Journal behavior).
---Cross-encounter aggregation is handled separately by the accumulator.
local function aggUptime(ext)
    ---@diagnostic disable-next-line: unused-local, redundant-parameter
    return function(breakdowns, durationS, aliveTimeS, _aggregation, aliveTimeLookup)
        local sum = 0
        for _, bd in ipairs(breakdowns) do
            local bdAliveTimeS = aliveTimeLookup and aliveTimeLookup[bd] or aliveTimeS
            sum = sum + ext.extract(bd, durationS, bdAliveTimeS)
        end
        return sum / #breakdowns
    end
end

---@type table<string, MetricExtractor>
extractors.metrics = {}

-- Damage metrics

extractors.metrics[pivot.Metric.TOTAL_DAMAGE] = {
    id = pivot.Metric.TOTAL_DAMAGE,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_TOTAL_DAMAGE",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true, [pivot.Domain.OVERVIEW] = true },
    extract = function(breakdown, _durationS)
        return breakdown.total or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local sum = 0
        for _, bd in ipairs(breakdowns) do sum = sum + (bd.total or 0) end
        return sum
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.DPS] = {
    id = pivot.Metric.DPS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_DPS",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true, [pivot.Domain.OVERVIEW] = true },
    extract = function(breakdown, durationS)
        local total = breakdown.total or 0
        return durationS >= 0.001 and (total / durationS) or 0
    end,
    aggregate = function(breakdowns, durationS)
        local sum = 0
        for _, bd in ipairs(breakdowns) do sum = sum + (bd.total or 0) end
        return durationS >= 0.001 and (sum / durationS) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.CRIT_PERCENT] = {
    id = pivot.Metric.CRIT_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_CRIT_PERCENT",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true, [pivot.Domain.OVERVIEW] = true },
    extract = function(breakdown, _durationS)
        local ticks = breakdown.ticks or 0
        local critTicks = breakdown.critTicks or 0
        return ticks > 0 and (critTicks / ticks * 100) or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local totalTicks, totalCrit = 0, 0
        for _, bd in ipairs(breakdowns) do
            totalTicks = totalTicks + (bd.ticks or 0)
            totalCrit = totalCrit + (bd.critTicks or 0)
        end
        return totalTicks > 0 and (totalCrit / totalTicks * 100) or 0
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.HIT_COUNT] = {
    id = pivot.Metric.HIT_COUNT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_HIT_COUNT",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true },
    extract = function(breakdown, _durationS)
        return breakdown.ticks or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local sum = 0
        for _, bd in ipairs(breakdowns) do sum = sum + (bd.ticks or 0) end
        return sum
    end,
    format = formatCount,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.MAX_HIT] = {
    id = pivot.Metric.MAX_HIT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_MAX_HIT",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true },
    extract = function(breakdown, _durationS)
        return breakdown.maxTick or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.MAX,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.MIN_HIT] = {
    id = pivot.Metric.MIN_HIT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_MIN_HIT",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true },
    extract = function(breakdown, _durationS)
        return breakdown.minTick or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.MIN,
    higherIsBetter = false,
}

extractors.metrics[pivot.Metric.AVG_HIT] = {
    id = pivot.Metric.AVG_HIT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_AVG_HIT",
    domains = { [pivot.Domain.DAMAGE] = true, [pivot.Domain.DAMAGE_IN] = true },
    extract = function(breakdown, _durationS)
        local ticks = breakdown.ticks or 0
        return ticks > 0 and ((breakdown.rawTotal or 0) / ticks) or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local totalRaw, totalTicks = 0, 0
        for _, bd in ipairs(breakdowns) do
            totalRaw = totalRaw + (bd.rawTotal or 0)
            totalTicks = totalTicks + (bd.ticks or 0)
        end
        return totalTicks > 0 and (totalRaw / totalTicks) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

-- Healing metrics

extractors.metrics[pivot.Metric.EFFECTIVE_HEALING] = {
    id = pivot.Metric.EFFECTIVE_HEALING,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HEALING",
    domains = { [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(breakdown, _durationS)
        return breakdown.real or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local sum = 0
        for _, bd in ipairs(breakdowns) do sum = sum + (bd.real or 0) end
        return sum
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.RAW_HEALING] = {
    id = pivot.Metric.RAW_HEALING,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_RAW_HEALING",
    domains = { [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(breakdown, _durationS)
        return breakdown.raw or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local sum = 0
        for _, bd in ipairs(breakdowns) do sum = sum + (bd.raw or 0) end
        return sum
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.RAW_HPS] = {
    id = pivot.Metric.RAW_HPS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_RAW_HPS",
    domains = { [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(breakdown, durationS)
        local raw = breakdown.raw or 0
        return durationS >= 0.001 and (raw / durationS) or 0
    end,
    aggregate = function(breakdowns, durationS)
        local sum = 0
        for _, bd in ipairs(breakdowns) do sum = sum + (bd.raw or 0) end
        return durationS >= 0.001 and (sum / durationS) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.EFFECTIVE_HPS] = {
    id = pivot.Metric.EFFECTIVE_HPS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS",
    domains = { [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(breakdown, durationS)
        local real = breakdown.real or 0
        return durationS >= 0.001 and (real / durationS) or 0
    end,
    aggregate = function(breakdowns, durationS)
        local sum = 0
        for _, bd in ipairs(breakdowns) do sum = sum + (bd.real or 0) end
        return durationS >= 0.001 and (sum / durationS) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.OVERHEAL_PERCENT] = {
    id = pivot.Metric.OVERHEAL_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_OVERHEAL_PERCENT",
    domains = { [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(breakdown, _durationS)
        local raw = breakdown.raw or 0
        local overheal = breakdown.overheal or 0
        return raw > 0 and (overheal / raw * 100) or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local totalRaw, totalOverheal = 0, 0
        for _, bd in ipairs(breakdowns) do
            totalRaw = totalRaw + (bd.raw or 0)
            totalOverheal = totalOverheal + (bd.overheal or 0)
        end
        return totalRaw > 0 and (totalOverheal / totalRaw * 100) or 0
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = false,
}

extractors.metrics[pivot.Metric.HEAL_CRIT_PERCENT] = {
    id = pivot.Metric.HEAL_CRIT_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_HEAL_CRIT_PERCENT",
    domains = { [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(breakdown, _durationS)
        local ticks = breakdown.ticks or 0
        local critTicks = breakdown.critTicks or 0
        return ticks > 0 and (critTicks / ticks * 100) or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local totalTicks, totalCrit = 0, 0
        for _, bd in ipairs(breakdowns) do
            totalTicks = totalTicks + (bd.ticks or 0)
            totalCrit = totalCrit + (bd.critTicks or 0)
        end
        return totalTicks > 0 and (totalCrit / totalTicks * 100) or 0
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.HEAL_HIT_COUNT] = {
    id = pivot.Metric.HEAL_HIT_COUNT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_HEAL_HIT_COUNT",
    domains = { [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(breakdown, _durationS)
        return breakdown.ticks or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local sum = 0
        for _, bd in ipairs(breakdowns) do sum = sum + (bd.ticks or 0) end
        return sum
    end,
    format = formatCount,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.MAX_HEAL] = {
    id = pivot.Metric.MAX_HEAL,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_MAX_HEAL",
    domains = { [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(breakdown, _durationS)
        return breakdown.maxTick or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.MAX,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.AVG_HEAL] = {
    id = pivot.Metric.AVG_HEAL,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_AVG_HEAL",
    domains = { [pivot.Domain.HEALING_OUT] = true, [pivot.Domain.HEALING_IN] = true },
    extract = function(breakdown, _durationS)
        local ticks = breakdown.ticks or 0
        return ticks > 0 and ((breakdown.raw or 0) / ticks) or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local totalRaw, totalTicks = 0, 0
        for _, bd in ipairs(breakdowns) do
            totalRaw = totalRaw + (bd.raw or 0)
            totalTicks = totalTicks + (bd.ticks or 0)
        end
        return totalTicks > 0 and (totalRaw / totalTicks) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

-- Effect metrics

extractors.metrics[pivot.Metric.UPTIME_PERCENT] = {
    id = pivot.Metric.UPTIME_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_UPTIME_PERCENT",
    domains = { [pivot.Domain.EFFECTS_SELF] = true, [pivot.Domain.EFFECTS_BOSS] = true, [pivot.Domain.EFFECTS_GROUP] = true },
    extract = function(stats, durationS, aliveTimeS)
        local baseS = aliveTimeS or durationS
        local baseMs = baseS * 1000
        if baseMs <= 0 then return 0 end
        local activeMs = stats.totalActiveTimeMs or 0
        local peak = stats.peakConcurrentInstances or 1
        return (activeMs / (baseMs * peak)) * 100
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.PLAYER_UPTIME_PERCENT] = {
    id = pivot.Metric.PLAYER_UPTIME_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_PLAYER_UPTIME_PERCENT",
    domains = { [pivot.Domain.EFFECTS_SELF] = true, [pivot.Domain.EFFECTS_BOSS] = true, [pivot.Domain.EFFECTS_GROUP] = true },
    extract = function(stats, durationS, aliveTimeS)
        local baseS = aliveTimeS or durationS
        local baseMs = baseS * 1000
        if baseMs <= 0 then return 0 end
        local activeMs = stats.playerActiveTimeMs or 0
        local peak = stats.peakConcurrentInstances or 1
        return (activeMs / (baseMs * peak)) * 100
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.APPLICATIONS] = {
    id = pivot.Metric.APPLICATIONS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_APPLICATIONS",
    domains = { [pivot.Domain.EFFECTS_SELF] = true, [pivot.Domain.EFFECTS_BOSS] = true, [pivot.Domain.EFFECTS_GROUP] = true },
    extract = function(stats, _durationS)
        return stats.applications or 0
    end,
    aggregate = function(breakdowns, _durationS)
        local sum = 0
        for _, bd in ipairs(breakdowns) do sum = sum + (bd.applications or 0) end
        return sum
    end,
    format = formatCount,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.MAX_STACKS_TIME_PERCENT] = {
    id = pivot.Metric.MAX_STACKS_TIME_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_MAX_STACKS_TIME",
    domains = { [pivot.Domain.EFFECTS_SELF] = true, [pivot.Domain.EFFECTS_BOSS] = true, [pivot.Domain.EFFECTS_GROUP] = true },
    extract = function(stats, durationS, aliveTimeS)
        local baseMs = (aliveTimeS or durationS) * 1000
        if baseMs <= 0 then return 0 end
        return ((stats.timeAtMaxStacksMs or 0) / baseMs) * 100
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

-- Assign aggregate functions that reference the extractor itself
extractors.metrics[pivot.Metric.MAX_HIT].aggregate = aggMax(extractors.metrics[pivot.Metric.MAX_HIT])
extractors.metrics[pivot.Metric.MIN_HIT].aggregate = aggMin(extractors.metrics[pivot.Metric.MIN_HIT])
extractors.metrics[pivot.Metric.MAX_HEAL].aggregate = aggMax(extractors.metrics[pivot.Metric.MAX_HEAL])
extractors.metrics[pivot.Metric.UPTIME_PERCENT].aggregate = aggUptime(extractors.metrics[pivot.Metric.UPTIME_PERCENT])
extractors.metrics[pivot.Metric.PLAYER_UPTIME_PERCENT].aggregate = aggUptime(extractors.metrics[pivot.Metric.PLAYER_UPTIME_PERCENT])
extractors.metrics[pivot.Metric.MAX_STACKS_TIME_PERCENT].aggregate = aggUptime(extractors.metrics[pivot.Metric.MAX_STACKS_TIME_PERCENT])

-- Overview metrics (operate on whole-encounter level)
-- DURATION is also used by GROUP domain via runGroupQuery fallback (line ~714 in engine)

extractors.metrics[pivot.Metric.DURATION] = {
    id = pivot.Metric.DURATION,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_DURATION",
    domains = { [pivot.Domain.OVERVIEW] = true, [pivot.Domain.GROUP] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS)
        return durationS
    end,
    format = formatSeconds,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = false,
}

extractors.metrics[pivot.Metric.DEATH_COUNT] = {
    id = pivot.Metric.DEATH_COUNT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_DEATH_COUNT",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS)
        -- breakdown here is the encounter-level deaths data
        return breakdown.deathCount or 0
    end,
    format = formatCount,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = false,
}

extractors.metrics[pivot.Metric.EFFECTIVE_HPS_OUT] = {
    id = pivot.Metric.EFFECTIVE_HPS_OUT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_OUT",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.RAW_HPS_OUT] = {
    id = pivot.Metric.RAW_HPS_OUT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_OUT",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.RAW_HPS_IN] = {
    id = pivot.Metric.RAW_HPS_IN,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_IN",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.EFFECTIVE_HPS_IN] = {
    id = pivot.Metric.EFFECTIVE_HPS_IN,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_IN",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.BOSS_DPS] = {
    id = pivot.Metric.BOSS_DPS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_BOSS_DPS",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.BOSS_DAMAGE] = {
    id = pivot.Metric.BOSS_DAMAGE,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_BOSS_DAMAGE",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.DTPS] = {
    id = pivot.Metric.DTPS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_DTPS",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = false,
}

extractors.metrics[pivot.Metric.DAMAGE_TAKEN] = {
    id = pivot.Metric.DAMAGE_TAKEN,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_DAMAGE_TAKEN",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = false,
}

-------------------------
-- Weaving Metrics (Overview domain, extracted in Overview engine)
-------------------------

extractors.metrics[pivot.Metric.AVG_WEAVE_TIME] = {
    id = pivot.Metric.AVG_WEAVE_TIME,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_AVG_WEAVE_TIME",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = function(value)
        return zo_strformat(GetString(BATTLESCROLLS_FORMAT_MILLISECONDS), value)
    end,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = false,
}

extractors.metrics[pivot.Metric.LIGHT_ATTACKS_PER_SEC] = {
    id = pivot.Metric.LIGHT_ATTACKS_PER_SEC,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_LIGHT_ATTACKS_PER_SEC",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = function(value)
        return string.format("%.2f", value)
    end,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.metrics[pivot.Metric.WEAVING_ERRORS] = {
    id = pivot.Metric.WEAVING_ERRORS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_WEAVING_ERRORS",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCount,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = false,
}

extractors.metrics[pivot.Metric.TIME_LOST] = {
    id = pivot.Metric.TIME_LOST,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_TIME_LOST",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatSeconds,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = false,
}

extractors.metrics[pivot.Metric.DOUBLE_LA_ERRORS] = {
    id = pivot.Metric.DOUBLE_LA_ERRORS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_DOUBLE_LA_ERRORS",
    domains = { [pivot.Domain.OVERVIEW] = true },
    ---@diagnostic disable-next-line: unused-local
    extract = function(breakdown, durationS) return 0 end, -- extracted in Overview engine
    format = formatCount,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = false,
}

-------------------------
-- Group Metric Extractors (no decode needed)
-------------------------

---@type table<string, GroupMetricExtractor>
extractors.groupMetrics = {}

---Find SharedBossDamage entries matching a boss display name, summing if multiple match
---@param bossDamage SharedBossDamage[]|nil
---@param bossName string -- display name (formatted with zo_strformat)
---@param bossSeqNames table<string, string>|nil
---@return SharedBossDamage|nil -- returns first match (or nil); callers sum across multiple
local function findBossDamage(bossDamage, bossName, bossSeqNames)
    if not bossDamage or not bossSeqNames then return nil end
    for _, bd in ipairs(bossDamage) do
        local key = bd.bossTag .. ":" .. bd.tagSeq
        local name = bossSeqNames[key]
        if name and zo_strformat(SI_UNIT_NAME, name) == bossName then
            return bd
        end
    end
    return nil
end

---Find a SharedBossDamageTaken entry matching a boss display name
---@param bossDamageTaken SharedBossDamageTaken[]|nil
---@param bossName string
---@param bossSeqNames table<string, string>|nil
---@return SharedBossDamageTaken|nil
local function findBossDamageTaken(bossDamageTaken, bossName, bossSeqNames)
    if not bossDamageTaken or not bossSeqNames then return nil end
    for _, bd in ipairs(bossDamageTaken) do
        local key = bd.bossTag .. ":" .. bd.tagSeq
        local name = bossSeqNames[key]
        if name and zo_strformat(SI_UNIT_NAME, name) == bossName then
            return bd
        end
    end
    return nil
end

extractors.groupMetrics[pivot.Metric.GROUP_DPS] = {
    id = pivot.Metric.GROUP_DPS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_DPS",
    extract = function(entry, encounter)
        local durationS = (entry.data.durationMs or encounter.durationMs) / 1000
        return durationS >= 0.001 and (entry.data.totalDamage / durationS) or 0
    end,
    bossExtract = function(entry, encounter, bossName)
        local bd = findBossDamage(entry.data.bossDamage, bossName, encounter.bossSeqNames)
        if not bd then return 0 end
        local durationS = (entry.data.durationMs or encounter.durationMs) / 1000
        return durationS >= 0.001 and (bd.damage / durationS) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_BOSS_DPS] = {
    id = pivot.Metric.GROUP_BOSS_DPS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_BOSS_DPS",
    extract = function(entry, encounter)
        local bossDamage = entry.data.bossDamage
        if not bossDamage or #bossDamage == 0 then return 0 end
        local total = 0
        for _, bd in ipairs(bossDamage) do
            total = total + bd.damage
        end
        local durationS = (entry.data.durationMs or encounter.durationMs) / 1000
        return durationS >= 0.001 and (total / durationS) or 0
    end,
    bossExtract = function(entry, encounter, bossName)
        local bd = findBossDamage(entry.data.bossDamage, bossName, encounter.bossSeqNames)
        if not bd then return 0 end
        local durationS = (entry.data.durationMs or encounter.durationMs) / 1000
        return durationS >= 0.001 and (bd.damage / durationS) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_TOTAL_DAMAGE] = {
    id = pivot.Metric.GROUP_TOTAL_DAMAGE,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_TOTAL_DAMAGE",
    extract = function(entry, _encounter)
        return entry.data.totalDamage or 0
    end,
    bossExtract = function(entry, encounter, bossName)
        local bd = findBossDamage(entry.data.bossDamage, bossName, encounter.bossSeqNames)
        return bd and bd.damage or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_CRIT_PERCENT] = {
    id = pivot.Metric.GROUP_CRIT_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_CRIT_PERCENT",
    extract = function(entry, _encounter)
        return (entry.data.critPercent or 0) * 100
    end,
    bossExtract = function(entry, encounter, bossName)
        local bd = findBossDamage(entry.data.bossDamage, bossName, encounter.bossSeqNames)
        return bd and (bd.critPercent or 0) * 100 or 0
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_DOT_PERCENT] = {
    id = pivot.Metric.GROUP_DOT_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_DOT_PERCENT",
    extract = function(entry, _encounter)
        return (entry.data.dotPercent or 0) * 100
    end,
    bossExtract = function(entry, encounter, bossName)
        local bd = findBossDamage(entry.data.bossDamage, bossName, encounter.bossSeqNames)
        return bd and (bd.dotPercent or 0) * 100 or 0
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_AOE_PERCENT] = {
    id = pivot.Metric.GROUP_AOE_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_AOE_PERCENT",
    extract = function(entry, _encounter)
        return (entry.data.aoePercent or 0) * 100
    end,
    bossExtract = function(entry, encounter, bossName)
        local bd = findBossDamage(entry.data.bossDamage, bossName, encounter.bossSeqNames)
        return bd and (bd.aoePercent or 0) * 100 or 0
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_MAX_HIT] = {
    id = pivot.Metric.GROUP_MAX_HIT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_MAX_HIT",
    extract = function(entry, _encounter)
        return entry.data.maxHit or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.MAX,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_DTPS] = {
    id = pivot.Metric.GROUP_DTPS,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_DTPS",
    extract = function(entry, encounter)
        local durationS = (entry.data.durationMs or encounter.durationMs) / 1000
        local taken = entry.data.totalDamageTaken or 0
        return durationS >= 0.001 and (taken / durationS) or 0
    end,
    bossExtract = function(entry, encounter, bossName)
        local bd = findBossDamageTaken(entry.data.bossDamageTaken, bossName, encounter.bossSeqNames)
        if not bd then return 0 end
        local durationS = (entry.data.durationMs or encounter.durationMs) / 1000
        return durationS >= 0.001 and (bd.damage / durationS) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = false,
}

extractors.groupMetrics[pivot.Metric.GROUP_RAW_HPS_OUT] = {
    id = pivot.Metric.GROUP_RAW_HPS_OUT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_RAW_HPS",
    extract = function(entry, encounter)
        local healing = entry.data.healing
        if not healing then return 0 end
        local durationS = (entry.data.durationMs or encounter.durationMs) / 1000
        return durationS >= 0.001 and (healing.rawOut / durationS) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_EFFECTIVE_HPS_OUT] = {
    id = pivot.Metric.GROUP_EFFECTIVE_HPS_OUT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_EFFECTIVE_HPS",
    extract = function(entry, encounter)
        local healing = entry.data.healing
        if not healing then return 0 end
        local durationS = (entry.data.durationMs or encounter.durationMs) / 1000
        return durationS >= 0.001 and (healing.effectiveOut / durationS) or 0
    end,
    format = formatCompact,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_ALIVE_PERCENT] = {
    id = pivot.Metric.GROUP_ALIVE_PERCENT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_ALIVE_PERCENT",
    extract = function(entry, encounter)
        local alive = entry.data.aliveTimeMs
        local duration = entry.data.durationMs or encounter.durationMs
        if not alive or duration <= 0 then return 100 end
        return (alive / duration) * 100
    end,
    format = formatPercent,
    defaultAggregation = pivot.Aggregation.AVG,
    higherIsBetter = true,
}

extractors.groupMetrics[pivot.Metric.GROUP_DEATH_COUNT] = {
    id = pivot.Metric.GROUP_DEATH_COUNT,
    displayName = "BATTLESCROLLS_PIVOT_METRIC_GROUP_DEATH_COUNT",
    extract = function(entry, _encounter)
        local deaths = entry.data.deaths
        return deaths and deaths.deathCount or 0
    end,
    format = formatCount,
    defaultAggregation = pivot.Aggregation.SUM,
    higherIsBetter = false,
}

---Metrics available when Boss dimension is active in Group domain
---@type table<string, boolean>
extractors.GROUP_BOSS_METRICS = {
    [pivot.Metric.GROUP_DPS] = true,
    -- GROUP_BOSS_DPS excluded: redundant when Boss is already a dimension
    [pivot.Metric.GROUP_TOTAL_DAMAGE] = true,
    [pivot.Metric.GROUP_CRIT_PERCENT] = true,
    [pivot.Metric.GROUP_DOT_PERCENT] = true,
    [pivot.Metric.GROUP_AOE_PERCENT] = true,
    [pivot.Metric.GROUP_DTPS] = true,
}

-------------------------
-- Group Dimension Extractors
-------------------------

---@type table<string, GroupDimensionExtractor>
extractors.groupDimensions = {}

extractors.groupDimensions[pivot.Dimension.GROUP_MEMBER] = {
    id = pivot.Dimension.GROUP_MEMBER,
    displayName = "BATTLESCROLLS_PIVOT_DIM_GROUP_MEMBER",
    extract = function(entry, _encounter, _instance)
        return entry.displayName
    end,
}

extractors.groupDimensions[pivot.Dimension.ROLE] = {
    id = pivot.Dimension.ROLE,
    displayName = "BATTLESCROLLS_PIVOT_DIM_ROLE",
    extract = function(entry, _encounter, _instance)
        local role = entry.role
        if role == LFG_ROLE_TANK then return "Tank"
        elseif role == LFG_ROLE_HEAL then return "Healer"
        elseif role == LFG_ROLE_DPS then return "DPS"
        else return GetString(BATTLESCROLLS_UNKNOWN) end
    end,
}

extractors.groupDimensions[pivot.Dimension.BOSS] = {
    id = pivot.Dimension.BOSS,
    displayName = "BATTLESCROLLS_PIVOT_DIM_BOSS",
    ---Returns an array of boss display names (one row per boss), or nil for non-boss encounters.
    ---@return string[]|nil
    extract = function(_entry, encounter, _instance)
        if not encounter.bossSeqNames then return nil end
        local names = {}
        local seen = {}
        for _, name in pairs(encounter.bossSeqNames) do
            local display = zo_strformat(SI_UNIT_NAME, name)
            if not seen[display] then
                seen[display] = true
                names[#names + 1] = display
            end
        end
        if #names == 0 then return nil end
        return names
    end,
}

-- Encounter and Instance group dimensions are handled by the engine loop
extractors.groupDimensions[pivot.Dimension.ENCOUNTER] = {
    id = pivot.Dimension.ENCOUNTER,
    displayName = "BATTLESCROLLS_PIVOT_DIM_ENCOUNTER",
    extract = function(_entry, _encounter, _instance)
        return ""  -- engine provides the encounter label
    end,
}

extractors.groupDimensions[pivot.Dimension.INSTANCE] = {
    id = pivot.Dimension.INSTANCE,
    displayName = "BATTLESCROLLS_PIVOT_DIM_INSTANCE",
    extract = function(_entry, _encounter, _instance)
        return ""  -- engine provides the instance label
    end,
}

-------------------------
-- Lookup helpers
-------------------------

---Get the display name for a dimension ID
---@param dimensionId string
---@return string
function extractors.getDimensionLabel(dimensionId)
    local ext = extractors.dimensions[dimensionId] or extractors.groupDimensions[dimensionId]
    if ext then
        return GetString(_G[ext.displayName])
    end
    return dimensionId
end

---Get the display name for a metric ID
---@param metricId string
---@return string
function extractors.getMetricLabel(metricId)
    local ext = extractors.metrics[metricId] or extractors.groupMetrics[metricId]
    if ext then
        return GetString(_G[ext.displayName])
    end
    return metricId
end

---Get the format function for a metric ID
---@param metricId string
---@return fun(value: number): string
function extractors.getMetricFormatter(metricId)
    local ext = extractors.metrics[metricId] or extractors.groupMetrics[metricId]
    if ext then return ext.format end
    return formatCompact
end

---Get the default aggregation for a metric ID
---@param metricId string
---@return string
function extractors.getDefaultAggregation(metricId)
    local ext = extractors.metrics[metricId] or extractors.groupMetrics[metricId]
    if ext then return ext.defaultAggregation end
    return pivot.Aggregation.SUM
end

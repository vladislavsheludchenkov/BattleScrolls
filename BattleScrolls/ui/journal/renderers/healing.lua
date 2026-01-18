-----------------------------------------------------------
-- Healing Renderer
-- Standalone renderer for healing-related stats tabs
--
-- All functions receive a JournalRenderContext and operate
-- on the list without needing a class instance.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local utils = journal.utils
local StatIcons = journal.StatIcons
local FilterConstants = journal.FilterConstants

local HealingRenderer = {}

-- Yield frequency for loops (yield every N iterations)
local YIELD_INTERVAL = 20

-- Special unit ID marker for self in combined healing views
local SELF_UNIT_ID = FilterConstants.SELF_UNIT_ID

-------------------------
-- Healing Display Helpers
-------------------------

---Displays healing summary (raw, effective, overheal)
---@param list any
---@param totalRaw number
---@param totalReal number
---@param durationSec number
local function displayHealingSummary(list, totalRaw, totalReal, durationSec)
    -- Guard against division by zero for very short fights
    if durationSec <= 0 then durationSec = 1 end
    local overhealAmount = totalRaw - totalReal
    local overhealPercent = totalRaw > 0 and (overhealAmount / totalRaw * 100) or 0
    utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_RAW_HEALING), ZO_CommaDelimitNumber(totalRaw), StatIcons.HEALING, GetString(BATTLESCROLLS_STAT_SUMMARY))
    utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_RAW_HPS), ZO_CommaDelimitNumber(math.floor(totalRaw / durationSec)), StatIcons.HPS)
    utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_EFFECTIVE_HEALING), ZO_CommaDelimitNumber(totalReal), StatIcons.HEALING)
    utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_EFFECTIVE_HPS), ZO_CommaDelimitNumber(math.floor(totalReal / durationSec)), StatIcons.HPS)
    utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_OVERHEAL), string.format("%s (%.1f%%)", ZO_CommaDelimitNumber(overhealAmount), overhealPercent), StatIcons.OVERHEAL)
end

---Displays unit breakdown with special handling for Self unit ID
---@param list any
---@param unitData table<number, number> Map of unitId to value (SELF_UNIT_ID for self)
---@param total number
---@param durationSec number
---@param unitNames table<number, string>
---@param headerText string
---@param maxEntries number|nil
local function displayHealingUnitBreakdownWithSelf(list, unitData, total, durationSec, unitNames, headerText, maxEntries)
    maxEntries = maxEntries or 10
    local sorted = utils.sortDamageBreakdown(unitData)
    local isFirst = true
    unitNames = unitNames or {}

    for i, entry in ipairs(sorted) do
        if i > maxEntries then
            break
        end

        local unitId = entry.key
        local unitName
        if unitId == SELF_UNIT_ID then
            unitName = BattleScrolls.utils.GetUndecoratedDisplayName()
        else
            local rawName = unitNames[unitId] or GetString(BATTLESCROLLS_UNKNOWN)
            unitName = zo_strformat(SI_UNIT_NAME, rawName)
        end
        local valueStr = utils.formatHealingWithPercent(entry.damage, total, durationSec)

        if isFirst then
            utils.addStatEntry(list, unitName, valueStr, nil, headerText)
            isFirst = false
        else
            utils.addStatEntry(list, unitName, valueStr)
        end
    end
end

---Displays HoT vs Direct healing breakdown
---@param list any
---@param byHotVsDirect table {hot: {raw, real}, direct: {raw, real}}
---@param total number
---@param healingField string "raw" or "real"
---@param headerText string
local function displayHotVsDirectBreakdown(list, byHotVsDirect, total, healingField, headerText)
    local hotHealing = byHotVsDirect.hot and byHotVsDirect.hot[healingField] or 0
    local directHealing = byHotVsDirect.direct and byHotVsDirect.direct[healingField] or 0

    if hotHealing > 0 or directHealing > 0 then
        local hotPercent = total > 0 and (hotHealing / total * 100) or 0
        local directPercent = total > 0 and (directHealing / total * 100) or 0

        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_DIRECT_HEALING), string.format("%s (%.1f%%)", ZO_CommaDelimitNumber(directHealing), directPercent), StatIcons.DIRECT_HEAL, headerText)
        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_HEALING_OVER_TIME), string.format("%s (%.1f%%)", ZO_CommaDelimitNumber(hotHealing), hotPercent), StatIcons.HOT)
    end
end

-------------------------
-- Healing Aggregation Helpers
-------------------------

---Aggregates healing by source+ability from bySourceUnitIdByAbilityId structure (async with yields)
---@param healingData table The healing data with bySourceUnitIdByAbilityId
---@param healingField string "raw" or "real"
---@param filterZero boolean|nil If true, skip entries with 0 value
---@return Effect<table> Sorted array of {sourceUnitId, abilityId, healing, stats}
local function aggregateHealingBySourceAbilityAsync(healingData, healingField, filterZero)
    return LibEffect.Async(function()
        if not healingData then
            return {}
        end
        local byAbility = {}
        local count = 0
        for sourceUnitId, abilityTable in pairs(healingData) do
            for abilityId, healing in pairs(abilityTable) do
                local value = healing[healingField]
                if not filterZero or value > 0 then
                    local key = string.format("%d_%d", sourceUnitId, abilityId)
                    if not byAbility[key] then
                        byAbility[key] = {
                            sourceUnitId = sourceUnitId,
                            abilityId = abilityId,
                            healing = 0,
                            stats = { total = 0, ticks = 0, critTicks = 0, minTick = nil, maxTick = nil }
                        }
                    end
                    byAbility[key].healing = byAbility[key].healing + value
                    -- Aggregate crit stats
                    local stats = byAbility[key].stats
                    stats.total = stats.total + value
                    stats.ticks = stats.ticks + (healing.ticks or 0)
                    stats.critTicks = stats.critTicks + (healing.critTicks or 0)
                    if healing.minTick then
                        stats.minTick = stats.minTick and math.min(stats.minTick, healing.minTick) or healing.minTick
                    end
                    if healing.maxTick then
                        stats.maxTick = stats.maxTick and math.max(stats.maxTick, healing.maxTick) or healing.maxTick
                    end
                end
                count = count + 1
                if count % YIELD_INTERVAL == 0 then
                    LibEffect.Yield():Await()
                end
            end
        end

        local sorted = {}
        count = 0
        for _, data in pairs(byAbility) do
            table.insert(sorted, data)
            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        table.sort(sorted, function(a, b)
            return a.healing > b.healing
        end)

        return sorted
    end)
end

---Aggregates healing by source+ability across multiple targets (for HealingOut structure) - async with yields
---@param healingOutData table Map of targetUnitId to {bySourceUnitIdByAbilityId: table}
---@param healingField string "raw" or "real"
---@param filterZero boolean|nil If true, skip entries with 0 value
---@return Effect<table> Sorted array of {sourceUnitId, abilityId, healing, stats}
local function aggregateHealingBySourceAbilityAcrossTargetsAsync(healingOutData, healingField, filterZero)
    return LibEffect.Async(function()
        local byAbility = {}
        local count = 0
        for _, healingData in pairs(healingOutData) do
            for sourceUnitId, abilityTable in pairs(healingData.bySourceUnitIdByAbilityId) do
                for abilityId, healing in pairs(abilityTable) do
                    local value = healing[healingField]
                    if not filterZero or value > 0 then
                        local key = string.format("%d_%d", sourceUnitId, abilityId)
                        if not byAbility[key] then
                            byAbility[key] = {
                                sourceUnitId = sourceUnitId,
                                abilityId = abilityId,
                                healing = 0,
                                stats = { total = 0, ticks = 0, critTicks = 0, minTick = nil, maxTick = nil }
                            }
                        end
                        byAbility[key].healing = byAbility[key].healing + value
                        -- Aggregate crit stats
                        local stats = byAbility[key].stats
                        stats.total = stats.total + value
                        stats.ticks = stats.ticks + (healing.ticks or 0)
                        stats.critTicks = stats.critTicks + (healing.critTicks or 0)
                        if healing.minTick then
                            stats.minTick = stats.minTick and math.min(stats.minTick, healing.minTick) or healing.minTick
                        end
                        if healing.maxTick then
                            stats.maxTick = stats.maxTick and math.max(stats.maxTick, healing.maxTick) or healing.maxTick
                        end
                    end
                    count = count + 1
                    if count % YIELD_INTERVAL == 0 then
                        LibEffect.Yield():Await()
                    end
                end
            end
        end

        local sorted = {}
        count = 0
        for _, data in pairs(byAbility) do
            table.insert(sorted, data)
            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        table.sort(sorted, function(a, b)
            return a.healing > b.healing
        end)

        return sorted
    end)
end

---Aggregates healing by ability from byAbilityId structure (async with yields)
---@param healingDataTable table Table of healing data entries with byAbilityId
---@param healingField string "raw" or "real"
---@param filterZero boolean|nil If true, skip entries with 0 value
---@return Effect<table<number, {healing: number, stats: {total: number, ticks: number, critTicks: number, minTick: number|nil, maxTick: number|nil}}>> Map of abilityId to {healing, stats}
local function aggregateHealingByAbilityAsync(healingDataTable, healingField, filterZero)
    return LibEffect.Async(function()
        local byAbility = {}
        local count = 0
        for _, healingData in pairs(healingDataTable) do
            for abilityId, healing in pairs(healingData.byAbilityId) do
                local value = healing[healingField]
                if not filterZero or value > 0 then
                    if not byAbility[abilityId] then
                        byAbility[abilityId] = {
                            healing = 0,
                            stats = { total = 0, ticks = 0, critTicks = 0, minTick = nil, maxTick = nil }
                        }
                    end
                    byAbility[abilityId].healing = byAbility[abilityId].healing + value
                    -- Aggregate crit stats
                    local stats = byAbility[abilityId].stats
                    stats.total = stats.total + value
                    stats.ticks = stats.ticks + (healing.ticks or 0)
                    stats.critTicks = stats.critTicks + (healing.critTicks or 0)
                    if healing.minTick then
                        stats.minTick = stats.minTick and math.min(stats.minTick, healing.minTick) or healing.minTick
                    end
                    if healing.maxTick then
                        stats.maxTick = stats.maxTick and math.max(stats.maxTick, healing.maxTick) or healing.maxTick
                    end
                end
                count = count + 1
                if count % YIELD_INTERVAL == 0 then
                    LibEffect.Yield():Await()
                end
            end
        end
        return byAbility
    end)
end

---Aggregates healing totals by unit from healingOut/healingIn data structure
---@param healingData table Map of unitId to {total: {raw: number, real: number}}
---@param healingField string "raw" or "real"
---@param filterZero boolean|nil If true, skip entries with 0 value
---@return table<number, number> Map of unitId to total healing
local function aggregateHealingByUnit(healingData, healingField, filterZero)
    local byUnit = {}
    for unitId, data in pairs(healingData) do
        local value = data.total[healingField]
        if not filterZero or value > 0 then
            byUnit[unitId] = value
        end
    end
    return byUnit
end

-- calculateHealingTotals moved to utils.lua as utils.calculateHealingTotals

---Aggregates HoT vs Direct breakdown across multiple units
---@param healingData table Map of unitId to HealingDone/HealingDoneDiffSource
---@param abilityInfo table<number, AbilityInfo> Ability metadata for computing byHotVsDirect
---@return table {hot: {raw: number, real: number}, direct: {raw: number, real: number}}
local function aggregateHotVsDirectAcrossUnits(healingData, abilityInfo)
    local Arithmancer = BattleScrolls.arithmancer
    local result = {
        hot = { raw = 0, real = 0 },
        direct = { raw = 0, real = 0 }
    }
    for _, data in pairs(healingData) do
        local hotVsDirect = Arithmancer.ComputeByHotVsDirect(data, abilityInfo)
        if hotVsDirect.hot then
            result.hot.raw = result.hot.raw + (hotVsDirect.hot.raw or 0)
            result.hot.real = result.hot.real + (hotVsDirect.hot.real or 0)
        end
        if hotVsDirect.direct then
            result.direct.raw = result.direct.raw + (hotVsDirect.direct.raw or 0)
            result.direct.real = result.direct.real + (hotVsDirect.direct.real or 0)
        end
    end
    return result
end

---Adds self-healing HoT vs Direct data to an aggregated table
---@param aggregated table {hot: {raw, real}, direct: {raw, real}}
---@param selfHealing HealingDoneDiffSource Self-healing data
---@param abilityInfo table<number, AbilityInfo> Ability metadata for computing byHotVsDirect
local function addSelfToHotVsDirect(aggregated, selfHealing, abilityInfo)
    if not selfHealing then return end
    local Arithmancer = BattleScrolls.arithmancer
    local selfHotVsDirect = Arithmancer.ComputeByHotVsDirect(selfHealing, abilityInfo)
    if selfHotVsDirect.hot then
        aggregated.hot.raw = aggregated.hot.raw + (selfHotVsDirect.hot.raw or 0)
        aggregated.hot.real = aggregated.hot.real + (selfHotVsDirect.hot.real or 0)
    end
    if selfHotVsDirect.direct then
        aggregated.direct.raw = aggregated.direct.raw + (selfHotVsDirect.direct.raw or 0)
        aggregated.direct.real = aggregated.direct.real + (selfHotVsDirect.direct.real or 0)
    end
end

-------------------------
-- Healing Quality Helpers (for overview panels)
-------------------------

---Computes crit rate and max heal from HealingDoneDiffSource data (has bySourceUnitIdByAbilityId)
---@param healingDoneDiff HealingDoneDiffSource|nil Healing data with bySourceUnitIdByAbilityId
---@return number critRate Crit percentage (0-100)
---@return number maxHeal Maximum raw heal value
local function computeHealingQualityFromHealingDoneDiffSource(healingDoneDiff)
    if not healingDoneDiff or not healingDoneDiff.bySourceUnitIdByAbilityId then
        return 0, 0
    end
    local totalTicks, totalCritTicks, maxHeal = 0, 0, 0
    for _, byAbility in pairs(healingDoneDiff.bySourceUnitIdByAbilityId) do
        for _, breakdown in pairs(byAbility) do
            totalTicks = totalTicks + (breakdown.ticks or 0)
            totalCritTicks = totalCritTicks + (breakdown.critTicks or 0)
            if breakdown.maxTick and breakdown.maxTick > maxHeal then
                maxHeal = breakdown.maxTick
            end
        end
    end
    local critRate = totalTicks > 0 and (totalCritTicks / totalTicks * 100) or 0
    return critRate, maxHeal
end

---Computes aggregated crit rate and max heal across multiple HealingDoneDiffSource entries
---Used for healing out (one entry per target)
---@param healingDataTable table<number, HealingDoneDiffSource>|nil Map of targetId to healing data
---@return number critRate Crit percentage (0-100)
---@return number maxHeal Maximum raw heal value
local function computeHealingQualityAcrossTargets(healingDataTable, selfHealing)
    local totalTicks, totalCritTicks, maxHeal = 0, 0, 0
    if healingDataTable then
        for _, targetData in pairs(healingDataTable) do
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
    -- Include self-healing if provided
    if selfHealing and selfHealing.bySourceUnitIdByAbilityId then
        for _, byAbility in pairs(selfHealing.bySourceUnitIdByAbilityId) do
            for _, breakdown in pairs(byAbility) do
                totalTicks = totalTicks + (breakdown.ticks or 0)
                totalCritTicks = totalCritTicks + (breakdown.critTicks or 0)
                if breakdown.maxTick and breakdown.maxTick > maxHeal then
                    maxHeal = breakdown.maxTick
                end
            end
        end
    end
    if totalTicks == 0 then
        return 0, 0
    end
    local critRate = totalCritTicks / totalTicks * 100
    return critRate, maxHeal
end

---Computes aggregated crit rate and max heal across multiple HealingDone entries
---Used for healing in (one entry per source)
---@param healingDataTable table<number, HealingDone>|nil Map of sourceId to healing data
---@return number critRate Crit percentage (0-100)
---@return number maxHeal Maximum raw heal value
local function computeHealingQualityAcrossSources(healingDataTable, selfHealing)
    local totalTicks, totalCritTicks, maxHeal = 0, 0, 0
    if healingDataTable then
        for _, sourceData in pairs(healingDataTable) do
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
    -- Include self-healing if provided (has bySourceUnitIdByAbilityId structure)
    if selfHealing and selfHealing.bySourceUnitIdByAbilityId then
        for _, byAbility in pairs(selfHealing.bySourceUnitIdByAbilityId) do
            for _, breakdown in pairs(byAbility) do
                totalTicks = totalTicks + (breakdown.ticks or 0)
                totalCritTicks = totalCritTicks + (breakdown.critTicks or 0)
                if breakdown.maxTick and breakdown.maxTick > maxHeal then
                    maxHeal = breakdown.maxTick
                end
            end
        end
    end
    if totalTicks == 0 then
        return 0, 0
    end
    local critRate = totalCritTicks / totalTicks * 100
    return critRate, maxHeal
end

---Merges self-healing abilities into an ability map (async with yields)
---@param byAbility table<number, {healing: number, stats: table}> Target map to merge into
---@param selfHealingData table Self-healing bySourceUnitIdByAbilityId data
---@param healingField string "raw" or "real"
---@return Effect
local function mergeSelfAbilitiesIntoMapAsync(byAbility, selfHealingData, healingField)
    return LibEffect.Async(function()
        local count = 0
        for _, abilityTable in pairs(selfHealingData) do
            for abilityId, healing in pairs(abilityTable) do
                local value = healing[healingField] or 0
                if value > 0 then
                    if not byAbility[abilityId] then
                        byAbility[abilityId] = {
                            healing = 0,
                            stats = { total = 0, ticks = 0, critTicks = 0, minTick = nil, maxTick = nil }
                        }
                    end
                    byAbility[abilityId].healing = byAbility[abilityId].healing + value
                    local stats = byAbility[abilityId].stats
                    stats.total = stats.total + value
                    stats.ticks = stats.ticks + (healing.ticks or 0)
                    stats.critTicks = stats.critTicks + (healing.critTicks or 0)
                    if healing.minTick then
                        stats.minTick = stats.minTick and math.min(stats.minTick, healing.minTick) or healing.minTick
                    end
                    if healing.maxTick then
                        stats.maxTick = stats.maxTick and math.max(stats.maxTick, healing.maxTick) or healing.maxTick
                    end
                end
                count = count + 1
                if count % YIELD_INTERVAL == 0 then
                    LibEffect.Yield():Await()
                end
            end
        end
    end)
end

---Merges self-healing abilities into a sorted array
---@param sortedAbilities table[] Target array to merge into
---@param selfAbilities table[] Self-healing ability array from aggregateHealingBySourceAbilityAsync
local function mergeSelfAbilitiesIntoArray(sortedAbilities, selfAbilities)
    for _, entry in ipairs(selfAbilities) do
        table.insert(sortedAbilities, entry)
    end
end

-------------------------
-- Ability Breakdown Display
-------------------------

---Core function to display healing ability breakdown (async with yields)
---Groups by ability name, shows breakdown in tooltip when multiple ability IDs share the same name
---@param list any
---@param byAbilityId table<number, {healing: number, stats: {total: number, ticks: number, critTicks: number, minTick: number|nil, maxTick: number|nil}}> Map of abilityId to {healing, stats}
---@param total number
---@param durationSec number
---@param abilityInfo table<number, AbilityInfo>
---@param headerText string
---@param maxEntries number|nil
---@return Effect
local function displayHealingAbilityBreakdownCoreAsync(list, byAbilityId, total, durationSec, abilityInfo, headerText, maxEntries)
    return LibEffect.Async(function()
        maxEntries = maxEntries or 15

        -- Helper to get HoT/Direct description for an ability
        abilityInfo = abilityInfo or {}
        local function getHotOrDirectDesc(abilityId)
            local info = abilityInfo[abilityId]
            if info and info.overTimeOrDirect then
                local hasHot = info.overTimeOrDirect.overTime
                local hasDirect = info.overTimeOrDirect.direct
                if hasHot and hasDirect then
                    return GetString(BATTLESCROLLS_DELIVERY_MIXED)
                elseif hasHot then
                    return GetString(BATTLESCROLLS_DELIVERY_HOT)
                elseif hasDirect then
                    return GetString(BATTLESCROLLS_DELIVERY_DIRECT)
                end
            end
            return nil
        end

        -- Build entries with ability names
        local entries = {}
        local count = 0
        for abilityId, data in pairs(byAbilityId) do
            local abilityName = utils.getAbilityDisplayName(abilityId)
            table.insert(entries, {
                abilityId = abilityId,
                abilityName = abilityName,
                healing = data.healing,
                stats = data.stats,
                hotOrDirectDesc = getHotOrDirectDesc(abilityId),
            })
            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        LibEffect.Yield():Await()

        -- Group by ability name
        local nameGroups = {}
        local groupOrder = {}
        for i, entry in ipairs(entries) do
            if not nameGroups[entry.abilityName] then
                nameGroups[entry.abilityName] = {
                    entries = {},
                    totalHealing = 0,
                    critStats = { total = 0, ticks = 0, critTicks = 0, minTick = nil, maxTick = nil }
                }
                table.insert(groupOrder, entry.abilityName)
            end
            table.insert(nameGroups[entry.abilityName].entries, entry)
            nameGroups[entry.abilityName].totalHealing = nameGroups[entry.abilityName].totalHealing + entry.healing
            -- Aggregate crit stats for the group
            if entry.stats then
                local groupStats = nameGroups[entry.abilityName].critStats
                groupStats.total = groupStats.total + (entry.stats.total or 0)
                groupStats.ticks = groupStats.ticks + (entry.stats.ticks or 0)
                groupStats.critTicks = groupStats.critTicks + (entry.stats.critTicks or 0)
                if entry.stats.minTick then
                    groupStats.minTick = groupStats.minTick and math.min(groupStats.minTick, entry.stats.minTick) or entry.stats.minTick
                end
                if entry.stats.maxTick then
                    groupStats.maxTick = groupStats.maxTick and math.max(groupStats.maxTick, entry.stats.maxTick) or entry.stats.maxTick
                end
            end
            if i % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        LibEffect.Yield():Await()

        -- Build merged list
        local mergedAbilities = {}
        count = 0
        for _, abilityName in ipairs(groupOrder) do
            local group = nameGroups[abilityName]
            table.sort(group.entries, function(a, b)
                return a.healing > b.healing
            end)

            local topEntry = group.entries[1]
            local mergedEntry = {
                abilityName = abilityName,
                totalHealing = group.totalHealing,
                abilityId = topEntry.abilityId,
                critStats = group.critStats,
                breakdown = nil,
            }

            -- If multiple ability IDs share the same name, build breakdown for tooltip
            if #group.entries > 1 then
                local breakdownEntries = {}

                -- Check if HoT/Direct differs between entries
                local uniqueHotOrDirect = {}
                for _, entry in ipairs(group.entries) do
                    uniqueHotOrDirect[entry.hotOrDirectDesc or ""] = true
                end
                local hasDifferentHotOrDirect = next(uniqueHotOrDirect) and next(uniqueHotOrDirect, next(uniqueHotOrDirect))

                for _, entry in ipairs(group.entries) do
                    local displayName
                    if hasDifferentHotOrDirect and entry.hotOrDirectDesc then
                        displayName = entry.hotOrDirectDesc
                    else
                        displayName = string.format("ID %d", entry.abilityId)
                    end
                    table.insert(breakdownEntries, {
                        displayName = displayName,
                        healing = entry.healing,
                        abilityId = entry.abilityId,
                        critStats = entry.stats,
                    })
                end

                -- Handle duplicates by adding ability ID
                local displayNameCounts = {}
                for _, entry in ipairs(breakdownEntries) do
                    displayNameCounts[entry.displayName] = (displayNameCounts[entry.displayName] or 0) + 1
                end
                for _, entry in ipairs(breakdownEntries) do
                    if displayNameCounts[entry.displayName] > 1 then
                        entry.displayName = string.format("%s (ID %d)", entry.displayName, entry.abilityId)
                    end
                end

                mergedEntry.breakdown = {
                    baseName = abilityName,
                    totalHealing = group.totalHealing,
                    entries = breakdownEntries,
                }
            end

            table.insert(mergedAbilities, mergedEntry)
            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        LibEffect.Yield():Await()

        -- Sort by total healing descending
        table.sort(mergedAbilities, function(a, b)
            return a.totalHealing > b.totalHealing
        end)

        -- Display entries
        local isFirst = true
        for i, merged in ipairs(mergedAbilities) do
            if i > maxEntries then
                break
            end

            local abilityIcon = GetAbilityIcon(merged.abilityId)
            local valueStr = utils.formatHealingWithPercent(merged.totalHealing, total, durationSec)

            local entryData = ZO_GamepadEntryData:New(merged.abilityName, abilityIcon)
            entryData.iconFile = abilityIcon  -- Store for frame type detection
            entryData:SetIconTintOnSelection(true)
            entryData:AddSubLabel(valueStr)
            entryData.critStats = merged.critStats

            if merged.breakdown then
                entryData.abilityBreakdown = {
                    baseName = merged.breakdown.baseName,
                    totalDamage = merged.breakdown.totalHealing,
                    critStats = merged.critStats,
                    entries = {}
                }
                for _, be in ipairs(merged.breakdown.entries) do
                    table.insert(entryData.abilityBreakdown.entries, {
                        displayName = be.displayName,
                        damage = be.healing,
                        abilityId = be.abilityId,
                        critStats = be.critStats,
                    })
                end
            end

            if isFirst then
                entryData:SetHeader(headerText)
                list:AddEntryWithHeader("BattleScrolls_AbilityEntryTemplate", entryData)
                isFirst = false
            else
                list:AddEntry("BattleScrolls_AbilityEntryTemplate", entryData)
            end

            if i % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
    end)
end

---Displays healing ability breakdown with source tracking (async with yields)
---Aggregates by abilityId first, then delegates to core display function
---@param list any
---@param abilityData table Sorted array of {sourceUnitId, abilityId, healing, stats}
---@param total number
---@param durationSec number
---@param abilityInfo table<number, AbilityInfo>
---@param headerText string
---@param maxEntries number|nil
---@return Effect
local function displayHealingAbilityBreakdownAsync(list, abilityData, total, durationSec, abilityInfo, headerText, maxEntries)
    return LibEffect.Async(function()
        -- Aggregate by abilityId (sum across different sources), including stats
        local byAbilityId = {}
        for i, entry in ipairs(abilityData) do
            if not byAbilityId[entry.abilityId] then
                byAbilityId[entry.abilityId] = {
                    healing = 0,
                    stats = { total = 0, ticks = 0, critTicks = 0, minTick = nil, maxTick = nil }
                }
            end
            byAbilityId[entry.abilityId].healing = byAbilityId[entry.abilityId].healing + entry.healing
            -- Aggregate crit stats
            if entry.stats then
                local stats = byAbilityId[entry.abilityId].stats
                stats.total = stats.total + (entry.stats.total or 0)
                stats.ticks = stats.ticks + (entry.stats.ticks or 0)
                stats.critTicks = stats.critTicks + (entry.stats.critTicks or 0)
                if entry.stats.minTick then
                    stats.minTick = stats.minTick and math.min(stats.minTick, entry.stats.minTick) or entry.stats.minTick
                end
                if entry.stats.maxTick then
                    stats.maxTick = stats.maxTick and math.max(stats.maxTick, entry.stats.maxTick) or entry.stats.maxTick
                end
            end
            if i % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end

        displayHealingAbilityBreakdownCoreAsync(list, byAbilityId, total, durationSec, abilityInfo, headerText, maxEntries):Await()
    end)
end

---Displays simple ability breakdown (no source tracking) - async version
---Directly delegates to core display function
---@param list any
---@param abilityData table<number, {healing: number, stats: {total: number, ticks: number, critTicks: number, minTick: number|nil, maxTick: number|nil}}> Map of abilityId to {healing, stats}
---@param total number
---@param durationSec number
---@param abilityInfo table<number, AbilityInfo>
---@param headerText string
---@param maxEntries number|nil
---@return Effect
local function displaySimpleHealingAbilityBreakdownAsync(list, abilityData, total, durationSec, abilityInfo, headerText, maxEntries)
    return displayHealingAbilityBreakdownCoreAsync(list, abilityData, total, durationSec, abilityInfo, headerText, maxEntries)
end

-------------------------
-- Unified Healing View
-------------------------

---@class HealingViewConfig
---@field filter table|nil Unit filter (nil = no filter)
---@field filterFunc function|nil Arithmancer filter function
---@field groupData table Group healing data (healingOutToGroup or healingInFromGroup)
---@field selfHealing table Self-healing data
---@field unitHeaderRaw string Header for raw unit breakdown
---@field unitHeaderReal string Header for effective unit breakdown
---@field useSourceAbilityAggregation boolean If true, use aggregateHealingBySourceAbilityAcrossTargetsAsync; if false, use aggregateHealingByAbilityAsync

---Unified healing display for Out and In tabs (async)
---@param list any
---@param durationSec number
---@param abilityInfo table<number, AbilityInfo>
---@param unitNames table<number, string>
---@param config HealingViewConfig
---@return Effect
local function refreshHealingViewAsync(list, durationSec, abilityInfo, unitNames, config)
    return LibEffect.Async(function()
        -- Apply filter if provided
        local filteredData = config.filterFunc and config.filterFunc(config.groupData, config.filter) or config.groupData
        local includeSelf = not config.filter or config.filter[SELF_UNIT_ID] == true

        -- Calculate totals
        local groupRaw, groupReal = utils.calculateHealingTotals(filteredData)
        local selfRaw = includeSelf and (config.selfHealing.total.raw or 0) or 0
        local selfReal = includeSelf and (config.selfHealing.total.real or 0) or 0
        local totalRaw = groupRaw + selfRaw
        local totalReal = groupReal + selfReal

        if totalRaw == 0 then return end

        -- Summary
        displayHealingSummary(list, totalRaw, totalReal, durationSec)
        LibEffect.Yield():Await()

        -- Aggregate HoT vs Direct
        local hotVsDirect = aggregateHotVsDirectAcrossUnits(filteredData, abilityInfo)
        if includeSelf then
            addSelfToHotVsDirect(hotVsDirect, config.selfHealing, abilityInfo)
        end

        -- === RAW SECTIONS ===
        displayHotVsDirectBreakdown(list, hotVsDirect, totalRaw, "raw", GetString(BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT))
        LibEffect.Yield():Await()

        -- Unit breakdown (raw)
        local byUnitRaw = aggregateHealingByUnit(filteredData, "raw", false)
        if includeSelf and selfRaw > 0 then
            byUnitRaw[SELF_UNIT_ID] = selfRaw
        end
        displayHealingUnitBreakdownWithSelf(list, byUnitRaw, totalRaw, durationSec, unitNames, config.unitHeaderRaw)
        LibEffect.Yield():Await()

        -- Ability breakdown (raw)
        if config.useSourceAbilityAggregation then
            local sortedRaw = aggregateHealingBySourceAbilityAcrossTargetsAsync(filteredData, "raw", false):Await()
            if includeSelf then
                local selfAbilitiesRaw = aggregateHealingBySourceAbilityAsync(config.selfHealing.bySourceUnitIdByAbilityId, "raw", false):Await()
                mergeSelfAbilitiesIntoArray(sortedRaw, selfAbilitiesRaw)
            end
            table.sort(sortedRaw, function(a, b) return a.healing > b.healing end)
            displayHealingAbilityBreakdownAsync(list, sortedRaw, totalRaw, durationSec, abilityInfo, GetString(BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY)):Await()
        else
            local byAbilityRaw = aggregateHealingByAbilityAsync(filteredData, "raw", false):Await()
            if includeSelf then
                mergeSelfAbilitiesIntoMapAsync(byAbilityRaw, config.selfHealing.bySourceUnitIdByAbilityId, "raw"):Await()
            end
            displaySimpleHealingAbilityBreakdownAsync(list, byAbilityRaw, totalRaw, durationSec, abilityInfo, GetString(BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY)):Await()
        end

        -- === EFFECTIVE SECTIONS ===
        if totalReal > 0 then
            displayHotVsDirectBreakdown(list, hotVsDirect, totalReal, "real", GetString(BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT))
            LibEffect.Yield():Await()

            -- Unit breakdown (effective)
            local byUnitReal = aggregateHealingByUnit(filteredData, "real", true)
            if includeSelf and selfReal > 0 then
                byUnitReal[SELF_UNIT_ID] = selfReal
            end
            displayHealingUnitBreakdownWithSelf(list, byUnitReal, totalReal, durationSec, unitNames, config.unitHeaderReal)
            LibEffect.Yield():Await()

            -- Ability breakdown (effective)
            if config.useSourceAbilityAggregation then
                local sortedReal = aggregateHealingBySourceAbilityAcrossTargetsAsync(filteredData, "real", true):Await()
                if includeSelf then
                    local selfAbilitiesReal = aggregateHealingBySourceAbilityAsync(config.selfHealing.bySourceUnitIdByAbilityId, "real", true):Await()
                    mergeSelfAbilitiesIntoArray(sortedReal, selfAbilitiesReal)
                end
                table.sort(sortedReal, function(a, b) return a.healing > b.healing end)
                displayHealingAbilityBreakdownAsync(list, sortedReal, totalReal, durationSec, abilityInfo, GetString(BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY)):Await()
            else
                local byAbilityReal = aggregateHealingByAbilityAsync(filteredData, "real", true):Await()
                if includeSelf then
                    mergeSelfAbilitiesIntoMapAsync(byAbilityReal, config.selfHealing.bySourceUnitIdByAbilityId, "real"):Await()
                end
                displaySimpleHealingAbilityBreakdownAsync(list, byAbilityReal, totalReal, durationSec, abilityInfo, GetString(BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY)):Await()
            end
        end
    end)
end

-------------------------
-- Public API
-------------------------

---Renders the Healing Out stats tab
---@param ctx JournalRenderContext
---@return Effect
function HealingRenderer.renderHealingOut(ctx)
    local Arithmancer = BattleScrolls.arithmancer
    return refreshHealingViewAsync(ctx.list, ctx.durationSec, ctx.abilityInfo, ctx.unitNames, {
        filter = ctx.filters.targetFilter,
        filterFunc = Arithmancer.FilterHealingOutTable,
        groupData = ctx.encounter.healingStats.healingOutToGroup,
        selfHealing = ctx.encounter.healingStats.selfHealing,
        unitHeaderRaw = GetString(BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET),
        unitHeaderReal = GetString(BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET),
        useSourceAbilityAggregation = true,
    })
end

---Renders the Self Healing stats tab
---@param ctx JournalRenderContext
---@return Effect
function HealingRenderer.renderSelfHealing(ctx)
    return LibEffect.Async(function()
        local Arithmancer = BattleScrolls.arithmancer
        local selfHealing = ctx.encounter.healingStats.selfHealing
        local totalRaw = selfHealing.total.raw
        local totalReal = selfHealing.total.real

        if totalRaw == 0 then return end

        -- Summary
        displayHealingSummary(ctx.list, totalRaw, totalReal, ctx.durationSec)
        LibEffect.Yield():Await()

        -- Compute HoT vs Direct breakdown
        local selfHotVsDirect = Arithmancer.ComputeByHotVsDirect(selfHealing, ctx.abilityInfo)

        -- Raw sections
        displayHotVsDirectBreakdown(ctx.list, selfHotVsDirect, totalRaw, "raw", GetString(BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT))
        LibEffect.Yield():Await()

        local sortedAbilitiesRaw = aggregateHealingBySourceAbilityAsync(selfHealing.bySourceUnitIdByAbilityId, "raw", false):Await()
        displayHealingAbilityBreakdownAsync(ctx.list, sortedAbilitiesRaw, totalRaw, ctx.durationSec, ctx.abilityInfo, GetString(BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY)):Await()

        -- Effective sections
        if totalReal > 0 then
            displayHotVsDirectBreakdown(ctx.list, selfHotVsDirect, totalReal, "real", GetString(BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT))
            LibEffect.Yield():Await()

            local sortedAbilitiesReal = aggregateHealingBySourceAbilityAsync(selfHealing.bySourceUnitIdByAbilityId, "real", true):Await()
            displayHealingAbilityBreakdownAsync(ctx.list, sortedAbilitiesReal, totalReal, ctx.durationSec, ctx.abilityInfo, GetString(BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY)):Await()
        end
    end)
end

---Renders the Healing In stats tab
---@param ctx JournalRenderContext
---@return Effect
function HealingRenderer.renderHealingIn(ctx)
    local Arithmancer = BattleScrolls.arithmancer
    return refreshHealingViewAsync(ctx.list, ctx.durationSec, ctx.abilityInfo, ctx.unitNames, {
        filter = ctx.filters.sourceFilter,
        filterFunc = Arithmancer.FilterHealingInTable,
        groupData = ctx.encounter.healingStats.healingInFromGroup,
        selfHealing = ctx.encounter.healingStats.selfHealing,
        unitHeaderRaw = GetString(BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE),
        unitHeaderReal = GetString(BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE),
        useSourceAbilityAggregation = false,
    })
end

-------------------------
-- Overview Panel Data Extraction Helpers
-------------------------

---Merges ability totals by display name, returning sorted array
---This is a shared helper used by all healing extraction functions
---@param abilityTotals table<number, number> Map of abilityId to total value
---@param maxCount number Maximum number of results
---@return { abilityId: number, name: string, total: number }[]
local function mergeHealingAbilitiesByName(abilityTotals, maxCount)
    local nameGroups = {}
    local nameOrder = {}

    for abilityId, total in pairs(abilityTotals) do
        local abilityName = utils.GetScribeAwareAbilityDisplayName(abilityId)
        if abilityName == "" then
            abilityName = string.format("%s %d", GetString(BATTLESCROLLS_TOOLTIP_ABILITY), abilityId)
        end

        if not nameGroups[abilityName] then
            nameGroups[abilityName] = {
                abilityId = abilityId,
                name = abilityName,
                total = 0,
            }
            table.insert(nameOrder, abilityName)
        end

        local group = nameGroups[abilityName]
        group.total = group.total + total
        -- Track which abilityId has highest total for icon selection
        if total > (abilityTotals[group.abilityId] or 0) then
            group.abilityId = abilityId
        end
    end

    -- Convert to sorted array
    local abilities = {}
    for _, name in ipairs(nameOrder) do
        table.insert(abilities, nameGroups[name])
    end
    table.sort(abilities, function(a, b) return a.total > b.total end)

    -- Return top N
    local result = {}
    for i = 1, math.min(maxCount, #abilities) do
        table.insert(result, abilities[i])
    end
    return result
end

---Extracts top healing abilities from healingOutToGroup (bySourceUnitIdByAbilityId structure) (async)
---Aggregates across all targets, merges abilities by display name
---@param healingOutToGroup table<number, HealingDoneDiffSource>|nil
---@param maxCount number Maximum number of abilities to return
---@return Effect<{ abilityId: number, name: string, total: number }[]>
function HealingRenderer.extractHealingOutAbilitiesAsync(healingOutToGroup, maxCount)
    return LibEffect.Async(function()
        if not healingOutToGroup then return {} end

        -- Aggregate by abilityId across all targets and sources
        local abilityTotals = {}
        local iterations = 0
        for _, targetData in pairs(healingOutToGroup) do
            if targetData.bySourceUnitIdByAbilityId then
                for _, abilityTable in pairs(targetData.bySourceUnitIdByAbilityId) do
                    for abilityId, breakdown in pairs(abilityTable) do
                        local value = breakdown.raw or 0
                        if value > 0 then
                            abilityTotals[abilityId] = (abilityTotals[abilityId] or 0) + value
                        end
                    end
                end
            end
            iterations = iterations + 1
            if iterations % 20 == 0 then
                LibEffect.YieldWithGC():Await()
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Merge by ability name and return top N
        return mergeHealingAbilitiesByName(abilityTotals, maxCount)
    end)
end

---Extracts top healing abilities from selfHealing (bySourceUnitIdByAbilityId structure) (async)
---Merges abilities by display name
---@param selfHealing HealingDoneDiffSource|nil
---@param maxCount number Maximum number of abilities to return
---@return Effect<{ abilityId: number, name: string, total: number }[]>
function HealingRenderer.extractSelfHealingAbilitiesAsync(selfHealing, maxCount)
    return LibEffect.Async(function()
        if not selfHealing or not selfHealing.bySourceUnitIdByAbilityId then return {} end

        -- Aggregate by abilityId across all sources
        local abilityTotals = {}
        for _, abilityTable in pairs(selfHealing.bySourceUnitIdByAbilityId) do
            for abilityId, breakdown in pairs(abilityTable) do
                local value = breakdown.raw or 0
                if value > 0 then
                    abilityTotals[abilityId] = (abilityTotals[abilityId] or 0) + value
                end
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Merge by ability name and return top N
        return mergeHealingAbilitiesByName(abilityTotals, maxCount)
    end)
end

---Extracts top healing abilities from healingInFromGroup (byAbilityId structure) (async)
---Aggregates across all sources, merges abilities by display name
---@param healingInFromGroup table<number, HealingDone>|nil
---@param maxCount number Maximum number of abilities to return
---@return Effect<{ abilityId: number, name: string, total: number }[]>
function HealingRenderer.extractHealingInAbilitiesAsync(healingInFromGroup, maxCount)
    return LibEffect.Async(function()
        if not healingInFromGroup then return {} end

        -- Aggregate by abilityId across all sources
        local abilityTotals = {}
        for _, sourceData in pairs(healingInFromGroup) do
            if sourceData.byAbilityId then
                for abilityId, breakdown in pairs(sourceData.byAbilityId) do
                    local value = breakdown.raw or 0
                    if value > 0 then
                        abilityTotals[abilityId] = (abilityTotals[abilityId] or 0) + value
                    end
                end
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Merge by ability name and return top N
        return mergeHealingAbilitiesByName(abilityTotals, maxCount)
    end)
end

---Extracts healing target breakdown from healingOutToGroup (keyed by unitId) (async)
---@param healingOutToGroup table<number, HealingDoneDiffSource>|nil
---@param unitNames table<number, string> Unit ID to name lookup
---@param maxCount number Maximum number of targets to return
---@return Effect<{ unitId: number, name: string, total: number }[]>
function HealingRenderer.extractHealingTargetBreakdownAsync(healingOutToGroup, unitNames, maxCount)
    return LibEffect.Async(function()
        if not healingOutToGroup then return {} end

        local targets = {}
        for unitId, data in pairs(healingOutToGroup) do
            local total = data.total.raw or 0
            if total > 0 then
                local rawName = unitNames[unitId] or GetString(BATTLESCROLLS_UNKNOWN)
                local name = zo_strformat(SI_UNIT_NAME, rawName)
                table.insert(targets, { unitId = unitId, name = name, total = total })
            end
        end
        table.sort(targets, function(a, b) return a.total > b.total end)

        -- Return top N
        local result = {}
        for i = 1, math.min(maxCount, #targets) do
            table.insert(result, targets[i])
        end
        return result
    end)
end

---Extracts healing source breakdown from healingInFromGroup (keyed by unitId) (async)
---@param healingInFromGroup table<number, HealingDone>|nil
---@param unitNames table<number, string> Unit ID to name lookup
---@param maxCount number Maximum number of sources to return
---@return Effect<{ unitId: number, name: string, total: number }[]>
function HealingRenderer.extractHealingSourceBreakdownAsync(healingInFromGroup, unitNames, maxCount)
    return LibEffect.Async(function()
        if not healingInFromGroup then return {} end

        local sources = {}
        for unitId, data in pairs(healingInFromGroup) do
            local total = data.total.raw or 0
            if total > 0 then
                local rawName = unitNames[unitId] or GetString(BATTLESCROLLS_UNKNOWN)
                local name = zo_strformat(SI_UNIT_NAME, rawName)
                table.insert(sources, { unitId = unitId, name = name, total = total })
            end
        end
        table.sort(sources, function(a, b) return a.total > b.total end)

        -- Return top N
        local result = {}
        for i = 1, math.min(maxCount, #sources) do
            table.insert(result, sources[i])
        end
        return result
    end)
end

---Merges two ability arrays by name, combining totals and returning top N
---@param abilities1 { abilityId: number, name: string, total: number }[]
---@param abilities2 { abilityId: number, name: string, total: number }[]
---@param maxCount number Maximum number of abilities to return
---@return { abilityId: number, name: string, total: number }[]
local function mergeAbilityArrays(abilities1, abilities2, maxCount)
    local byName = {}
    local order = {}

    -- Add abilities from first array
    for _, ability in ipairs(abilities1) do
        if not byName[ability.name] then
            byName[ability.name] = { abilityId = ability.abilityId, name = ability.name, total = 0 }
            table.insert(order, ability.name)
        end
        byName[ability.name].total = byName[ability.name].total + ability.total
    end

    -- Add/merge abilities from second array
    for _, ability in ipairs(abilities2) do
        if not byName[ability.name] then
            byName[ability.name] = { abilityId = ability.abilityId, name = ability.name, total = 0 }
            table.insert(order, ability.name)
        end
        byName[ability.name].total = byName[ability.name].total + ability.total
    end

    -- Convert to sorted array
    local result = {}
    for _, name in ipairs(order) do
        table.insert(result, byName[name])
    end
    table.sort(result, function(a, b) return a.total > b.total end)

    -- Limit to maxCount
    local limited = {}
    for i = 1, math.min(maxCount, #result) do
        table.insert(limited, result[i])
    end
    return limited
end

-------------------------
-- Overview Panel Refresh Functions
-------------------------

---Refreshes the overview panel for Healing Out tab
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table }
---@return Effect<nil>
function HealingRenderer.refreshPanelForHealingOut(panel, ctx)
    return LibEffect.Async(function()
        local lastControl = nil
        local filters = ctx.filters or {}
        local targetFilter = filters.targetFilter
        local encounter = ctx.encounter
        local durationS = ctx.durationS
        local unitNames = ctx.unitNames
        local arithmancer = ctx.arithmancer
        local abilityInfo = ctx.abilityInfo or encounter.abilityInfo or {}

        -- Filter healing data for Q3/Q4 sections
        local Arithmancer = BattleScrolls.arithmancer
        local healingStats = encounter.healingStats
        local filteredHealingOut = healingStats and Arithmancer.FilterHealingOutTable(healingStats.healingOutToGroup, targetFilter)
        local selfHealing = healingStats and healingStats.selfHealing
        local includeSelf = not targetFilter or targetFilter[SELF_UNIT_ID] == true
        local rawTotal = 0  -- For Q3 ability bars (raw-based)

        -- Q2: Summary - returns {rawHps, effectiveHps, total, rawTotal, overhealPercent}
        local summaryData = arithmancer:getHealingOutSummary(targetFilter)
        rawTotal = summaryData.rawTotal
        lastControl = utils.renderHealingSummarySection(panel, nil, lastControl,
            summaryData.rawHps, summaryData.effectiveHps, summaryData.total)
        LibEffect.Yield():Await()

        -- Efficiency section (Overheal %)
        lastControl = utils.renderHealingEfficiencySection(panel, lastControl, summaryData.overhealPercent)
        LibEffect.Yield():Await()

        -- Composition section (HoT vs Direct)
        if filteredHealingOut or (includeSelf and selfHealing) then
            local hotVsDirect = aggregateHotVsDirectAcrossUnits(filteredHealingOut, abilityInfo)
            if includeSelf and selfHealing then
                addSelfToHotVsDirect(hotVsDirect, selfHealing, abilityInfo)
            end
            local totalRaw = (hotVsDirect.hot.raw or 0) + (hotVsDirect.direct.raw or 0)
            if totalRaw > 0 then
                local hotPercent = hotVsDirect.hot.raw / totalRaw * 100
                local directPercent = hotVsDirect.direct.raw / totalRaw * 100
                -- Only show if meaningful split
                if hotPercent > 5 and directPercent > 5 then
                    lastControl = utils.renderHealingCompositionSection(panel, lastControl, hotPercent, directPercent)
                end
            end
        end
        LibEffect.Yield():Await()

        -- Quality section (Crit Rate, Max Heal)
        local critRate, maxHeal = computeHealingQualityAcrossTargets(filteredHealingOut, includeSelf and selfHealing)
        if critRate > 0 or maxHeal > 0 then
            lastControl = utils.renderHealingQualitySection(panel, lastControl, critRate, maxHeal)
        end
        LibEffect.YieldWithGC():Await()

        -- Q3: Top healing abilities (using filtered data + self if included)
        local q3Control = nil
        local hasGroupData = filteredHealingOut ~= nil
        local hasSelfData = includeSelf and selfHealing
        if hasGroupData or hasSelfData then
            local maxAbilities = panel:GetMaxAbilities()
            local groupAbilities = hasGroupData and HealingRenderer.extractHealingOutAbilitiesAsync(filteredHealingOut, maxAbilities):Await() or {}
            local selfAbilities = hasSelfData and HealingRenderer.extractSelfHealingAbilitiesAsync(selfHealing, maxAbilities):Await() or {}
            local topAbilities = mergeAbilityArrays(groupAbilities, selfAbilities, maxAbilities)
            if #topAbilities > 0 then
                q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_ABILITIES), q3Control)
                local topValue = topAbilities[1].total
                for _, ability in ipairs(topAbilities) do
                    q3Control = panel:AddAbilityBar(ability, topValue, rawTotal, durationS, q3Control)
                end
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Q4: Targets healed with HPS (using filtered data + self if included)
        local q4Control = nil
        if hasGroupData or hasSelfData then
            local maxTargets = panel:GetMaxTargets()
            local targets = hasGroupData and HealingRenderer.extractHealingTargetBreakdownAsync(filteredHealingOut, unitNames, maxTargets):Await() or {}
            -- Add self-healing as a target if included
            if hasSelfData and selfHealing.total and selfHealing.total.raw and selfHealing.total.raw > 0 then
                local selfName = BattleScrolls.utils.GetUndecoratedDisplayName()
                table.insert(targets, { unitId = SELF_UNIT_ID, name = selfName, total = selfHealing.total.raw })
                table.sort(targets, function(a, b) return a.total > b.total end)
                -- Limit to maxTargets
                while #targets > maxTargets do
                    table.remove(targets)
                end
            end
            if #targets > 0 then
                q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_OVERVIEW_TARGETS_HEALED), q4Control)
                for _, target in ipairs(targets) do
                    q4Control = panel:AddTargetRow(target.name, utils.formatTargetHPS(target.total, durationS), q4Control)
                end
            end
        end
    end)
end

---Refreshes the overview panel for Self Healing tab
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table }
---@return Effect<nil>
function HealingRenderer.refreshPanelForSelfHealing(panel, ctx)
    return LibEffect.Async(function()
        local lastControl = nil
        local encounter = ctx.encounter
        local durationS = ctx.durationS
        local arithmancer = ctx.arithmancer
        local abilityInfo = ctx.abilityInfo or encounter.abilityInfo or {}

        local healingStats = encounter and encounter.healingStats
        local selfHealing = healingStats and healingStats.selfHealing
        if not selfHealing then return end

        -- Q2: Summary - returns {rawHps, effectiveHps, total, rawTotal, overhealPercent}
        local summaryData = arithmancer:getSelfHealingSummary()
        local rawTotal = summaryData.rawTotal  -- Keep for Q3 ability bars
        lastControl = utils.renderHealingSummarySection(panel, nil, lastControl,
            summaryData.rawHps, summaryData.effectiveHps, summaryData.total)
        LibEffect.Yield():Await()

        -- Efficiency section (Overheal %)
        lastControl = utils.renderHealingEfficiencySection(panel, lastControl, summaryData.overhealPercent)
        LibEffect.Yield():Await()

        -- Composition section (HoT vs Direct)
        local Arithmancer = BattleScrolls.arithmancer
        local hotVsDirect = Arithmancer.ComputeByHotVsDirect(selfHealing, abilityInfo)
        local totalRaw = (hotVsDirect.hot.raw or 0) + (hotVsDirect.direct.raw or 0)
        if totalRaw > 0 then
            local hotPercent = hotVsDirect.hot.raw / totalRaw * 100
            local directPercent = hotVsDirect.direct.raw / totalRaw * 100
            -- Only show if meaningful split
            if hotPercent > 5 and directPercent > 5 then
                lastControl = utils.renderHealingCompositionSection(panel, lastControl, hotPercent, directPercent)
            end
        end
        LibEffect.Yield():Await()

        -- Quality section (Crit Rate, Max Heal)
        local critRate, maxHeal = computeHealingQualityFromHealingDoneDiffSource(selfHealing)
        if critRate > 0 or maxHeal > 0 then
            lastControl = utils.renderHealingQualitySection(panel, lastControl, critRate, maxHeal)
        end
        LibEffect.YieldWithGC():Await()

        -- Q3: Top self-healing abilities
        local q3Control = nil
        local maxAbilities = panel:GetMaxAbilities()
        local topAbilities = HealingRenderer.extractSelfHealingAbilitiesAsync(selfHealing, maxAbilities):Await()
        if #topAbilities > 0 then
            q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_ABILITIES), q3Control)
            local topValue = topAbilities[1].total
            for _, ability in ipairs(topAbilities) do
                q3Control = panel:AddAbilityBar(ability, topValue, rawTotal, durationS, q3Control)
            end
        end

        -- Q4: Left empty for self-healing (all healing is to self)
    end)
end

---Refreshes the overview panel for Healing In tab
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table }
---@return Effect<nil>
function HealingRenderer.refreshPanelForHealingIn(panel, ctx)
    return LibEffect.Async(function()
        local lastControl = nil
        local filters = ctx.filters or {}
        local sourceFilter = filters.sourceFilter
        local encounter = ctx.encounter
        local durationS = ctx.durationS
        local unitNames = ctx.unitNames
        local arithmancer = ctx.arithmancer
        local abilityInfo = ctx.abilityInfo or encounter.abilityInfo or {}

        local Arithmancer = BattleScrolls.arithmancer
        local healingStats = encounter.healingStats
        if not healingStats then
            return
        end

        -- Filter healing in data for Q3/Q4 sections
        local filteredHealingIn = healingStats.healingInFromGroup and Arithmancer.FilterHealingInTable(healingStats.healingInFromGroup, sourceFilter)
        local selfHealing = healingStats.selfHealing
        local includeSelf = not sourceFilter or sourceFilter[SELF_UNIT_ID] == true
        local rawTotal = 0  -- For Q3 ability bars

        -- Q2: Summary - returns {rawHps, effectiveHps, total, rawTotal, overhealPercent}
        local summaryData = arithmancer:getHealingInSummary(sourceFilter)
        rawTotal = summaryData.rawTotal
        lastControl = utils.renderHealingSummarySection(panel, nil, lastControl,
            summaryData.rawHps, summaryData.effectiveHps, summaryData.total)
        LibEffect.Yield():Await()

        -- Efficiency section (Overheal %)
        lastControl = utils.renderHealingEfficiencySection(panel, lastControl, summaryData.overhealPercent)
        LibEffect.Yield():Await()

        -- Composition section (HoT vs Direct)
        -- Note: For healing in, we use HealingDone structure (byAbilityId) + self-healing if included
        local hasGroupData = filteredHealingIn ~= nil
        local hasSelfData = includeSelf and selfHealing
        if hasGroupData or hasSelfData then
            local totalHot, totalDirect = 0, 0
            if hasGroupData then
                for _, sourceData in pairs(filteredHealingIn) do
                    local hotVsDirect = Arithmancer.ComputeByHotVsDirect(sourceData, abilityInfo)
                    totalHot = totalHot + (hotVsDirect.hot and hotVsDirect.hot.raw or 0)
                    totalDirect = totalDirect + (hotVsDirect.direct and hotVsDirect.direct.raw or 0)
                end
            end
            if hasSelfData then
                local selfHotVsDirect = Arithmancer.ComputeByHotVsDirect(selfHealing, abilityInfo)
                totalHot = totalHot + (selfHotVsDirect.hot and selfHotVsDirect.hot.raw or 0)
                totalDirect = totalDirect + (selfHotVsDirect.direct and selfHotVsDirect.direct.raw or 0)
            end
            local totalRaw = totalHot + totalDirect
            if totalRaw > 0 then
                local hotPercent = totalHot / totalRaw * 100
                local directPercent = totalDirect / totalRaw * 100
                -- Only show if meaningful split
                if hotPercent > 5 and directPercent > 5 then
                    lastControl = utils.renderHealingCompositionSection(panel, lastControl, hotPercent, directPercent)
                end
            end
        end
        LibEffect.Yield():Await()

        -- Quality section (Crit Rate, Max Heal)
        local critRate, maxHeal = computeHealingQualityAcrossSources(filteredHealingIn, hasSelfData and selfHealing)
        if critRate > 0 or maxHeal > 0 then
            lastControl = utils.renderHealingQualitySection(panel, lastControl, critRate, maxHeal)
        end
        LibEffect.YieldWithGC():Await()

        -- Q3: Top incoming healing abilities (using filtered data + self if included)
        local q3Control = nil
        if hasGroupData or hasSelfData then
            local maxAbilities = panel:GetMaxAbilities()
            local groupAbilities = hasGroupData and HealingRenderer.extractHealingInAbilitiesAsync(filteredHealingIn, maxAbilities):Await() or {}
            local selfAbilities = hasSelfData and HealingRenderer.extractSelfHealingAbilitiesAsync(selfHealing, maxAbilities):Await() or {}
            local topAbilities = mergeAbilityArrays(groupAbilities, selfAbilities, maxAbilities)
            if #topAbilities > 0 then
                q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_ABILITIES), q3Control)
                local topValue = topAbilities[1].total
                for _, ability in ipairs(topAbilities) do
                    q3Control = panel:AddAbilityBar(ability, topValue, rawTotal, durationS, q3Control)
                end
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Q4: Healers who healed you with HPS (using filtered data + self if included)
        local q4Control = nil
        if hasGroupData or hasSelfData then
            local maxTargets = panel:GetMaxTargets()
            local healers = hasGroupData and HealingRenderer.extractHealingSourceBreakdownAsync(filteredHealingIn, unitNames, maxTargets):Await() or {}
            -- Add self-healing as a healer source if included
            if hasSelfData and selfHealing.total and selfHealing.total.raw and selfHealing.total.raw > 0 then
                local selfName = BattleScrolls.utils.GetUndecoratedDisplayName()
                table.insert(healers, { unitId = SELF_UNIT_ID, name = selfName, total = selfHealing.total.raw })
                table.sort(healers, function(a, b) return a.total > b.total end)
                -- Limit to maxTargets
                while #healers > maxTargets do
                    table.remove(healers)
                end
            end
            if #healers > 0 then
                q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_OVERVIEW_HEALERS), q4Control)
                for _, healer in ipairs(healers) do
                    q4Control = panel:AddTargetRow(healer.name, utils.formatTargetHPS(healer.total, durationS), q4Control)
                end
            end
        end
    end)
end

-- Export to namespace
journal.renderers.healing = HealingRenderer

-----------------------------------------------------------
-- Damage Renderer
-- Renders damage-related tabs (Boss Damage Done, Damage Done, Damage Taken)
--
-- Receives a JournalRenderContext and populates the list.
-- All functions are stateless - filters come from context.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local utils = journal.utils
local STAT_ICONS = journal.StatIcons
local coreUtils = BattleScrolls.utils
local Arithmancer = BattleScrolls.arithmancer

local DamageRenderer = {}

-- Yield frequency for loops (yield every N iterations)
local YIELD_INTERVAL = 20

-------------------------
-- Internal Helpers
-------------------------

---@class AbilityStats
---@field total number Total damage/value
---@field ticks number Number of ticks
---@field critTicks number Number of critical ticks
---@field maxHit number Maximum hit value

---Merges ability stats by display name, returning sorted array
---This is a shared helper used by both list and panel extraction functions
---@param abilityStats table<number, AbilityStats> Map of abilityId to stats
---@param maxCount number|nil Maximum number of results (nil = unlimited)
---@return { abilityId: number, name: string, total: number, ticks: number, critTicks: number, maxHit: number }[]
local function mergeAbilitiesByName(abilityStats, maxCount)
    local nameGroups = {}
    local nameOrder = {}

    for abilityId, stats in pairs(abilityStats) do
        local abilityName = utils.GetScribeAwareAbilityDisplayName(abilityId)
        if abilityName == "" then
            abilityName = string.format("%s %d", GetString(BATTLESCROLLS_TOOLTIP_ABILITY), abilityId)
        end

        if not nameGroups[abilityName] then
            nameGroups[abilityName] = {
                abilityId = abilityId,
                name = abilityName,
                total = 0,
                ticks = 0,
                critTicks = 0,
                maxHit = 0,
            }
            table.insert(nameOrder, abilityName)
        end

        local group = nameGroups[abilityName]
        group.total = group.total + stats.total
        group.ticks = group.ticks + (stats.ticks or 0)
        group.critTicks = group.critTicks + (stats.critTicks or 0)
        if (stats.maxHit or 0) > group.maxHit then
            group.maxHit = stats.maxHit
        end
        -- Track which abilityId has highest damage for icon selection
        if stats.total > (abilityStats[group.abilityId] and abilityStats[group.abilityId].total or 0) then
            group.abilityId = abilityId
        end
    end

    -- Convert to sorted array
    local abilities = {}
    for _, name in ipairs(nameOrder) do
        table.insert(abilities, nameGroups[name])
    end
    table.sort(abilities, function(a, b) return a.total > b.total end)

    -- Return top N if maxCount specified
    if maxCount and maxCount < #abilities then
        local result = {}
        for i = 1, maxCount do
            table.insert(result, abilities[i])
        end
        return result
    end

    return abilities
end

---Builds ability breakdown entries from a nested damage table (async with yields)
---@param damageTable table<number, table<number, DamageDoneStorage>>
---@param targetFilter table<number, boolean>|nil
---@param sourceFilter table<number, boolean>|nil
---@return Effect<{ abilityId: number, sourceUnitId: number, stats: DamageBreakdown }[]>
local function buildAbilityEntriesAsync(damageTable, targetFilter, sourceFilter)
    return LibEffect.Async(function()
        local getAbilities = Arithmancer.GetAbilities
        local entries = {}
        local count = 0
        for sourceUnitId, byTarget in pairs(damageTable) do
            if not sourceFilter or sourceFilter[sourceUnitId] then
                for targetUnitId, damageData in pairs(byTarget) do
                    if not targetFilter or targetFilter[targetUnitId] then
                        for abilityId, stats in pairs(getAbilities(damageData)) do
                            table.insert(entries, {
                                abilityId = abilityId,
                                sourceUnitId = sourceUnitId,
                                stats = stats,
                            })
                            count = count + 1
                            if count % YIELD_INTERVAL == 0 then
                                LibEffect.Yield():Await()
                            end
                        end
                    end
                end
            end
        end
        return entries
    end)
end

---Displays ability breakdown with merging and tooltips (async)
---@param list any
---@param abilityEntries { abilityId: number, sourceUnitId: number, stats: DamageBreakdown }[]
---@param totalDamage number
---@param durationSec number
---@param abilityInfo table<number, AbilityInfo>
---@param unitNames table<number, string>
---@param headerText string
---@return Effect
local function displayAbilityBreakdownAsync(list, abilityEntries, totalDamage, durationSec, abilityInfo, unitNames, headerText)
    return LibEffect.Async(function()
        if #abilityEntries == 0 then
            return
        end

        -- Build set of player names for O(1) lookup
        local playerNames = {
            [GetRawUnitName("player")] = true,
            [GetDisplayName()] = true,
            [coreUtils.GetUndecoratedDisplayName()] = true,
        }

        -- Helper to get ability info
        abilityInfo = abilityInfo or {}
        local function getAbilityInfo(abilityId)
            return abilityInfo[abilityId]
        end

        -- Get damage type description for an ability
        local function getDamageTypeDesc(abilityId)
            local info = getAbilityInfo(abilityId)
            if info and info.damageTypes then
                local types = {}
                for dmgType in pairs(info.damageTypes) do
                    table.insert(types, utils.getDamageTypeName(dmgType))
                end
                if #types > 0 then
                    table.sort(types)
                    return table.concat(types, "/")
                end
            end
            return nil
        end

        -- Get dot/direct description for an ability
        local function getOverTimeOrDirectDesc(abilityId)
            local info = getAbilityInfo(abilityId)
            if info and info.overTimeOrDirect then
                local hasOverTime = info.overTimeOrDirect.overTime
                local hasDirect = info.overTimeOrDirect.direct
                if hasOverTime and hasDirect then
                    return GetString(BATTLESCROLLS_DELIVERY_MIXED)
                elseif hasOverTime then
                    return GetString(BATTLESCROLLS_DELIVERY_DOT)
                elseif hasDirect then
                    return GetString(BATTLESCROLLS_DELIVERY_DIRECT)
                end
            end
            return nil
        end

        -- Build display entries with base names
        unitNames = unitNames or {}
        local rawEntries = {}
        for i, entry in ipairs(abilityEntries) do
            local abilityName = utils.getAbilityDisplayName(entry.abilityId)

            local baseName
            local rawSourceName = unitNames[entry.sourceUnitId]
            local isPlayer = rawSourceName and playerNames[rawSourceName]

            if not isPlayer and rawSourceName then
                local unitName = zo_strformat(SI_UNIT_NAME, rawSourceName)
                baseName = zo_strformat("<<C:1>> (<<2>>)", abilityName, unitName)
            else
                baseName = zo_strformat("<<C:1>>", abilityName)
            end

            table.insert(rawEntries, {
                abilityId = entry.abilityId,
                stats = entry.stats,
                baseName = baseName,
            })

            if i % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        LibEffect.Yield():Await()

        -- Second pass: aggregate by (baseName, abilityId)
        local aggregated = {}
        local count = 0
        for _, entry in ipairs(rawEntries) do
            local key = string.format("%s_%d", entry.baseName, entry.abilityId)
            if not aggregated[key] then
                aggregated[key] = {
                    abilityId = entry.abilityId,
                    stats = {
                        total = 0,
                        rawTotal = 0,
                        ticks = 0,
                        critTicks = 0,
                        minTick = entry.stats.minTick,
                        maxTick = entry.stats.maxTick,
                    },
                    baseName = entry.baseName,
                    damageTypeDesc = getDamageTypeDesc(entry.abilityId),
                    overTimeOrDirectDesc = getOverTimeOrDirectDesc(entry.abilityId),
                }
            end
            local agg = aggregated[key]
            agg.stats.total = agg.stats.total + entry.stats.total
            agg.stats.rawTotal = agg.stats.rawTotal + (entry.stats.rawTotal or entry.stats.total)
            agg.stats.ticks = agg.stats.ticks + entry.stats.ticks
            agg.stats.critTicks = agg.stats.critTicks + entry.stats.critTicks
            agg.stats.minTick = math.min(agg.stats.minTick, entry.stats.minTick)
            agg.stats.maxTick = math.max(agg.stats.maxTick, entry.stats.maxTick)

            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end

        -- Convert to array
        local displayEntries = {}
        count = 0
        for _, entry in pairs(aggregated) do
            table.insert(displayEntries, entry)
            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        LibEffect.Yield():Await()

        -- Group by base name
        local nameGroups = {}
        local groupOrder = {}
        for i, entry in ipairs(displayEntries) do
            if not nameGroups[entry.baseName] then
                nameGroups[entry.baseName] = {
                    entries = {},
                    totalDamage = 0,
                    stats = {
                        total = 0,
                        rawTotal = 0,
                        ticks = 0,
                        critTicks = 0,
                        minTick = entry.stats.minTick,
                        maxTick = entry.stats.maxTick,
                    },
                }
                table.insert(groupOrder, entry.baseName)
            end
            table.insert(nameGroups[entry.baseName].entries, entry)
            local group = nameGroups[entry.baseName]
            group.totalDamage = group.totalDamage + entry.stats.total
            group.stats.total = group.stats.total + entry.stats.total
            group.stats.rawTotal = group.stats.rawTotal + (entry.stats.rawTotal or entry.stats.total)
            group.stats.ticks = group.stats.ticks + entry.stats.ticks
            group.stats.critTicks = group.stats.critTicks + entry.stats.critTicks
            group.stats.minTick = math.min(group.stats.minTick, entry.stats.minTick)
            group.stats.maxTick = math.max(group.stats.maxTick, entry.stats.maxTick)

            if i % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        LibEffect.Yield():Await()

        -- Build merged ability list
        local mergedAbilities = {}
        count = 0
        for _, baseName in ipairs(groupOrder) do
            local group = nameGroups[baseName]
            table.sort(group.entries, function(a, b)
                return a.stats.total > b.stats.total
            end)

            local topEntry = group.entries[1]
            local mergedEntry = {
                baseName = baseName,
                totalDamage = group.totalDamage,
                abilityId = topEntry.abilityId,
                critStats = group.stats,
                damageTypeDesc = topEntry.damageTypeDesc,
                overTimeOrDirectDesc = topEntry.overTimeOrDirectDesc,
                breakdown = nil,
            }

            -- If multiple entries, build breakdown for tooltip
            if #group.entries > 1 then
                local breakdownEntries = {}

                -- Collect unique damage types for aggregate description
                local uniqueDamageTypes = {}
                local uniqueOverTimeOrDirects = {}
                for _, entry in ipairs(group.entries) do
                    if entry.damageTypeDesc then
                        uniqueDamageTypes[entry.damageTypeDesc] = true
                    end
                    if entry.overTimeOrDirectDesc then
                        uniqueOverTimeOrDirects[entry.overTimeOrDirectDesc] = true
                    end
                end

                -- Build aggregate damage type description
                local allDamageTypes = {}
                for dmgType in pairs(uniqueDamageTypes) do
                    table.insert(allDamageTypes, dmgType)
                end
                table.sort(allDamageTypes)
                mergedEntry.damageTypeDesc = #allDamageTypes > 0 and table.concat(allDamageTypes, ", ") or nil

                -- Build aggregate dot/direct description
                local allOverTimeOrDirect = {}
                for otd in pairs(uniqueOverTimeOrDirects) do
                    table.insert(allOverTimeOrDirect, otd)
                end
                table.sort(allOverTimeOrDirect)
                mergedEntry.overTimeOrDirectDesc = #allOverTimeOrDirect > 0 and table.concat(allOverTimeOrDirect, ", ") or nil

                local hasDifferentDamageTypes = coreUtils.countKeys(uniqueDamageTypes) > 1
                local hasDifferentOverTimeOrDirect = coreUtils.countKeys(uniqueOverTimeOrDirects) > 1

                for _, entry in ipairs(group.entries) do
                    local suffixParts = {}
                    if hasDifferentDamageTypes and entry.damageTypeDesc then
                        table.insert(suffixParts, entry.damageTypeDesc)
                    end
                    if hasDifferentOverTimeOrDirect and entry.overTimeOrDirectDesc then
                        table.insert(suffixParts, entry.overTimeOrDirectDesc)
                    end

                    local displayName
                    if #suffixParts > 0 then
                        displayName = ZO_GenerateCommaSeparatedListWithAnd(suffixParts)
                    else
                        displayName = string.format("ID %d", entry.abilityId)
                    end

                    table.insert(breakdownEntries, {
                        displayName = displayName,
                        damage = entry.stats.total,
                        abilityId = entry.abilityId,
                        critStats = entry.stats,
                    })
                end

                -- Handle duplicates in breakdown by adding ability ID
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
                    baseName = baseName,
                    totalDamage = group.totalDamage,
                    critStats = group.stats,
                    damageTypeDesc = mergedEntry.damageTypeDesc,
                    overTimeOrDirectDesc = mergedEntry.overTimeOrDirectDesc,
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

        -- Sort by total damage descending
        table.sort(mergedAbilities, function(a, b)
            return a.totalDamage > b.totalDamage
        end)

        -- Display merged entries
        local isFirst = true
        local maxAbilities = 25

        for i, merged in ipairs(mergedAbilities) do
            if i > maxAbilities then
                break
            end

            local abilityIcon = GetAbilityIcon(merged.abilityId)
            local valueStr = utils.formatDamageWithPercent(merged.totalDamage, totalDamage, durationSec)

            local entryData = ZO_GamepadEntryData:New(merged.baseName, abilityIcon)
            entryData.iconFile = abilityIcon
            entryData:SetIconTintOnSelection(true)
            entryData:AddSubLabel(valueStr)

            if merged.breakdown then
                entryData.abilityBreakdown = merged.breakdown
            else
                entryData.critStats = merged.critStats
                entryData.damageTypeDesc = merged.damageTypeDesc
                entryData.overTimeOrDirectDesc = merged.overTimeOrDirectDesc
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

---Displays damage type breakdown (async)
local function displayDamageTypeBreakdownAsync(list, damageTable, totalDamage, durationSec, targetFilter, abilityInfo, sourceFilter)
    return LibEffect.Async(function()
        local computeByDamageType = Arithmancer.ComputeByDamageType
        local byDamageType = {}
        local count = 0
        for sourceUnitId, byTarget in pairs(damageTable) do
            if not sourceFilter or sourceFilter[sourceUnitId] then
                for targetUnitId, damageData in pairs(byTarget) do
                    if not targetFilter or targetFilter[targetUnitId] then
                        local damageTypes = computeByDamageType(damageData, abilityInfo or {})
                        for damageType, damage in pairs(damageTypes) do
                            byDamageType[damageType] = (byDamageType[damageType] or 0) + damage
                        end
                        count = count + 1
                        if count % YIELD_INTERVAL == 0 then
                            LibEffect.Yield():Await()
                        end
                    end
                end
            end
        end

        local sortedTypes = utils.sortDamageBreakdown(byDamageType)
        local isFirst = true

        for _, entry in ipairs(sortedTypes) do
            local damageType = entry.key
            local typeName = utils.getDamageTypeName(damageType)
            local typeIcon = utils.getDamageTypeIcon(damageType)
            local valueStr = utils.formatDamageWithPercent(entry.damage, totalDamage, durationSec)

            if isFirst then
                utils.addStatEntry(list, typeName, valueStr, typeIcon, GetString(BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE))
                isFirst = false
            else
                utils.addStatEntry(list, typeName, valueStr, typeIcon)
            end
        end
    end)
end

---Displays direct vs DoT breakdown (async)
local function displayDirectVsDoTBreakdownAsync(list, damageTable, totalDamage, durationSec, targetFilter, abilityInfo, sourceFilter)
    return LibEffect.Async(function()
        local computeByDotOrDirect = Arithmancer.ComputeByDotOrDirect
        local directDmg = 0
        local dotDmg = 0
        local count = 0

        for sourceUnitId, byTarget in pairs(damageTable) do
            if not sourceFilter or sourceFilter[sourceUnitId] then
                for targetUnitId, damageData in pairs(byTarget) do
                    if not targetFilter or targetFilter[targetUnitId] then
                        local breakdown = computeByDotOrDirect(damageData, abilityInfo or {})
                        directDmg = directDmg + (breakdown.direct or 0)
                        dotDmg = dotDmg + (breakdown.dot or 0)
                        count = count + 1
                        if count % YIELD_INTERVAL == 0 then
                            LibEffect.Yield():Await()
                        end
                    end
                end
            end
        end

        if directDmg > 0 or dotDmg > 0 then
            local directStr = utils.formatDamageWithPercent(directDmg, totalDamage, durationSec)
            local dotStr = utils.formatDamageWithPercent(dotDmg, totalDamage, durationSec)

            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_DIRECT_DAMAGE), directStr, STAT_ICONS.DIRECT, GetString(BATTLESCROLLS_HEADER_DIRECT_VS_DOT))
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_DAMAGE_OVER_TIME), dotStr, STAT_ICONS.DOT)
        end
    end)
end

---Displays AOE vs single target breakdown
local function displayAoeVsSingleTargetBreakdown(list, aoeVsSingleTarget, totalDamage, durationSec)
    local aoeDmg = aoeVsSingleTarget.aoe
    local singleTargetDmg = aoeVsSingleTarget.singleTarget

    if aoeDmg > 0 or singleTargetDmg > 0 then
        local aoeStr = utils.formatDamageWithPercent(aoeDmg, totalDamage, durationSec)
        local singleTargetStr = utils.formatDamageWithPercent(singleTargetDmg, totalDamage, durationSec)

        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_AOE_DAMAGE), aoeStr, STAT_ICONS.AOE, GetString(BATTLESCROLLS_HEADER_AOE_VS_SINGLE))
        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE), singleTargetStr, STAT_ICONS.SINGLE_TARGET)
    end
end

---Displays target breakdown (async)
local function displayTargetBreakdownAsync(list, damageTable, totalDamage, durationSec, unitNames, targetFilter, sourceFilter)
    return LibEffect.Async(function()
        local computeTotal = Arithmancer.ComputeDamageTotal
        local byTarget = {}
        local count = 0
        for sourceUnitId, targetTable in pairs(damageTable) do
            if not sourceFilter or sourceFilter[sourceUnitId] then
                for targetUnitId, damageData in pairs(targetTable) do
                    if not targetFilter or targetFilter[targetUnitId] then
                        byTarget[targetUnitId] = (byTarget[targetUnitId] or 0) + computeTotal(damageData)
                        count = count + 1
                        if count % YIELD_INTERVAL == 0 then
                            LibEffect.Yield():Await()
                        end
                    end
                end
            end
        end

        local sortedTargets = utils.sortDamageBreakdown(byTarget)
        local isFirst = true
        local maxTargets = 10
        unitNames = unitNames or {}

        for i, entry in ipairs(sortedTargets) do
            if i > maxTargets then
                break
            end

            local unitId = entry.key
            local rawName = unitNames[unitId] or GetString(BATTLESCROLLS_UNKNOWN)
            local targetName = zo_strformat(SI_UNIT_NAME, rawName)
            local valueStr = utils.formatDamageWithPercent(entry.damage, totalDamage, durationSec)

            if isFirst then
                utils.addStatEntry(list, targetName, valueStr, nil, GetString(BATTLESCROLLS_HEADER_BY_TARGET))
                isFirst = false
            else
                utils.addStatEntry(list, targetName, valueStr)
            end
        end
    end)
end

-------------------------
-- Public Renderer API
-------------------------

---Renders Boss Damage Done tab
---@param ctx JournalRenderContext
---@return Effect
function DamageRenderer.renderBossDamageDone(ctx)
    return LibEffect.Async(function()
        local encounter = ctx.encounter
        local list = ctx.list
        local abilityInfo = ctx.abilityInfo
        local unitNames = ctx.unitNames
        local durationSec = ctx.durationSec
        local targetFilter = ctx.filters.targetFilter
        local sourceFilter = ctx.filters.sourceFilter

        if not encounter.bossesUnits or #encounter.bossesUnits == 0 then
            return
        end
        if durationSec <= 0 then durationSec = 1 end

        -- Use user filter if set, otherwise filter to all bosses
        local bossFilter
        if targetFilter then
            bossFilter = targetFilter
        else
            bossFilter = {}
            for _, bossId in ipairs(encounter.bossesUnits) do
                bossFilter[bossId] = true
            end
        end

        -- Pre-filter damage data
        local filteredDamageTable = Arithmancer.FilterDamageTable(encounter.damageByUnitId, bossFilter, sourceFilter)
        local filteredGroupDamageTable = Arithmancer.FilterDamageTable(encounter.damageByUnitIdGroup, bossFilter, nil)

        -- Calculate totals
        local totalBossDamage = Arithmancer.ComputeNestedTotal(filteredDamageTable)
        local groupOnlyDamage = Arithmancer.ComputeNestedTotal(filteredGroupDamageTable)
        local bossGroupDamage = totalBossDamage + groupOnlyDamage

        -- Summary
        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE), ZO_CommaDelimitNumber(totalBossDamage), STAT_ICONS.DAMAGE, GetString(BATTLESCROLLS_STAT_SUMMARY))
        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_BOSS_DPS), ZO_CommaDelimitNumber(math.floor(totalBossDamage / durationSec)), STAT_ICONS.DPS)
        if bossGroupDamage > totalBossDamage then
            local groupPercent = (totalBossDamage / bossGroupDamage) * 100
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_GROUP_SHARE), string.format("%.1f%%", groupPercent), STAT_ICONS.SHARE)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE), ZO_CommaDelimitNumber(bossGroupDamage), STAT_ICONS.GROUP_DAMAGE)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_GROUP_BOSS_DPS), ZO_CommaDelimitNumber(math.floor(bossGroupDamage / durationSec)), STAT_ICONS.GROUP_DPS)
        end
        LibEffect.Yield():Await()

        -- By Ability
        local abilityEntries = buildAbilityEntriesAsync(filteredDamageTable, nil, nil):Await()
        displayAbilityBreakdownAsync(list, abilityEntries, totalBossDamage, durationSec, abilityInfo, unitNames, GetString(BATTLESCROLLS_HEADER_BY_ABILITY)):Await()

        -- By Damage Type
        displayDamageTypeBreakdownAsync(list, filteredDamageTable, totalBossDamage, durationSec, nil, abilityInfo, nil):Await()

        -- Direct vs DoT
        displayDirectVsDoTBreakdownAsync(list, filteredDamageTable, totalBossDamage, durationSec, nil, abilityInfo, nil):Await()

        -- AOE vs Single Target
        displayAoeVsSingleTargetBreakdown(list, Arithmancer.ComputeAoeVsSingleTarget(filteredDamageTable), totalBossDamage, durationSec)
        LibEffect.Yield():Await()

        -- By Target
        displayTargetBreakdownAsync(list, filteredDamageTable, totalBossDamage, durationSec, unitNames, nil, nil):Await()
    end)
end

---Renders Damage Done tab
---@param ctx JournalRenderContext
---@return Effect
function DamageRenderer.renderDamageDone(ctx)
    return LibEffect.Async(function()
        local encounter = ctx.encounter
        local list = ctx.list
        local abilityInfo = ctx.abilityInfo
        local unitNames = ctx.unitNames
        local durationSec = ctx.durationSec
        local targetFilter = ctx.filters.targetFilter
        local sourceFilter = ctx.filters.sourceFilter

        if durationSec <= 0 then durationSec = 1 end

        -- Pre-filter damage data
        local filteredDamageTable = Arithmancer.FilterDamageTable(encounter.damageByUnitId, targetFilter, sourceFilter)
        local filteredGroupDamageTable = Arithmancer.FilterDamageTable(encounter.damageByUnitIdGroup, targetFilter, nil)

        -- Calculate totals
        local totalDamage = Arithmancer.ComputeNestedTotal(filteredDamageTable)
        local groupOnlyDamage = Arithmancer.ComputeNestedTotal(filteredGroupDamageTable)
        local groupDamage = totalDamage + groupOnlyDamage

        -- Summary
        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_TOTAL_DAMAGE), ZO_CommaDelimitNumber(totalDamage), STAT_ICONS.DAMAGE, GetString(BATTLESCROLLS_STAT_SUMMARY))
        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_DPS), ZO_CommaDelimitNumber(math.floor(totalDamage / durationSec)), STAT_ICONS.DPS)
        if groupDamage > totalDamage then
            local groupPercent = (totalDamage / groupDamage) * 100
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_GROUP_SHARE), string.format("%.1f%%", groupPercent), STAT_ICONS.SHARE)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_GROUP_DAMAGE), ZO_CommaDelimitNumber(groupDamage), STAT_ICONS.GROUP_DAMAGE)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_GROUP_DPS), ZO_CommaDelimitNumber(math.floor(groupDamage / durationSec)), STAT_ICONS.GROUP_DPS)
        end
        LibEffect.Yield():Await()

        -- By Ability
        local abilityEntries = buildAbilityEntriesAsync(filteredDamageTable, nil, nil):Await()
        displayAbilityBreakdownAsync(list, abilityEntries, totalDamage, durationSec, abilityInfo, unitNames, GetString(BATTLESCROLLS_HEADER_BY_ABILITY)):Await()

        -- By Damage Type
        displayDamageTypeBreakdownAsync(list, filteredDamageTable, totalDamage, durationSec, nil, abilityInfo, nil):Await()

        -- Direct vs DoT
        displayDirectVsDoTBreakdownAsync(list, filteredDamageTable, totalDamage, durationSec, nil, abilityInfo, nil):Await()

        -- AOE vs Single Target
        displayAoeVsSingleTargetBreakdown(list, Arithmancer.ComputeAoeVsSingleTarget(filteredDamageTable), totalDamage, durationSec)
        LibEffect.Yield():Await()

        -- By Target
        displayTargetBreakdownAsync(list, filteredDamageTable, totalDamage, durationSec, unitNames, nil, nil):Await()
    end)
end

---Renders Damage Taken tab
---@param ctx JournalRenderContext
---@return Effect
function DamageRenderer.renderDamageTaken(ctx)
    return LibEffect.Async(function()
        local encounter = ctx.encounter
        local list = ctx.list
        local abilityInfo = ctx.abilityInfo
        local unitNames = ctx.unitNames
        local durationSec = ctx.durationSec
        local sourceFilter = ctx.filters.sourceFilter

        if durationSec <= 0 then durationSec = 1 end

        -- Pre-filter damage taken data
        local filteredDamageTaken = Arithmancer.FilterDamageTakenTable(encounter.damageTakenByUnitId, sourceFilter)

        -- Calculate total
        local totalDamageTaken = Arithmancer.ComputeNestedTotal(filteredDamageTaken)

        -- Summary
        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN), ZO_CommaDelimitNumber(totalDamageTaken), STAT_ICONS.DAMAGE_TAKEN, GetString(BATTLESCROLLS_STAT_SUMMARY))
        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_DTPS), ZO_CommaDelimitNumber(math.floor(totalDamageTaken / durationSec)), STAT_ICONS.DPS)
        LibEffect.Yield():Await()

        -- By Ability
        local abilityEntries = buildAbilityEntriesAsync(filteredDamageTaken, nil, nil):Await()
        displayAbilityBreakdownAsync(list, abilityEntries, totalDamageTaken, durationSec, abilityInfo, unitNames, GetString(BATTLESCROLLS_HEADER_BY_ABILITY)):Await()

        -- By Damage Type
        displayDamageTypeBreakdownAsync(list, filteredDamageTaken, totalDamageTaken, durationSec, nil, abilityInfo, nil):Await()

        -- Direct vs DoT
        displayDirectVsDoTBreakdownAsync(list, filteredDamageTaken, totalDamageTaken, durationSec, nil, abilityInfo, nil):Await()

        -- By Source (who dealt the damage to us)
        local bySource = {}
        local count = 0
        local computeTotal = Arithmancer.ComputeDamageTotal
        for sourceUnitId, byTarget in pairs(filteredDamageTaken) do
            for _, damageData in pairs(byTarget) do
                bySource[sourceUnitId] = (bySource[sourceUnitId] or 0) + computeTotal(damageData)
                count = count + 1
                if count % YIELD_INTERVAL == 0 then
                    LibEffect.Yield():Await()
                end
            end
        end

        local sortedSources = utils.sortDamageBreakdown(bySource)
        local isFirst = true
        local maxSources = 10
        unitNames = unitNames or {}

        for i, entry in ipairs(sortedSources) do
            if i > maxSources then
                break
            end

            local unitId = entry.key
            local rawName = unitNames[unitId] or GetString(BATTLESCROLLS_UNKNOWN)
            local sourceName = zo_strformat(SI_UNIT_NAME, rawName)
            local valueStr = utils.formatDamageWithPercent(entry.damage, totalDamageTaken, durationSec)

            if isFirst then
                utils.addStatEntry(list, sourceName, valueStr, nil, GetString(BATTLESCROLLS_HEADER_BY_SOURCE))
                isFirst = false
            else
                utils.addStatEntry(list, sourceName, valueStr)
            end
        end
    end)
end

-------------------------
-- Overview Panel Data Extraction Helpers
-- These are used by both damage panel and overview panel
-------------------------

---Computes crit rate and max hit from a nested damage table (async with yield)
---@param damageTable table<number, table<number, DamageDoneStorage>>
---@param targetFilter table<number, boolean>|nil Optional target filter
---@param sourceFilter table<number, boolean>|nil Optional source filter
---@return Effect<{ critRate: number, maxHit: number }>
function DamageRenderer.computeCritRateAndMaxHitAsync(damageTable, targetFilter, sourceFilter)
    return LibEffect.Async(function()
        local getAbilities = Arithmancer.GetAbilities
        local totalTicks, totalCritTicks = 0, 0
        local maxHit = 0
        local iterations = 0

        for sourceUnitId, byTarget in pairs(damageTable) do
            if not sourceFilter or sourceFilter[sourceUnitId] then
                for targetUnitId, damageData in pairs(byTarget) do
                    if not targetFilter or targetFilter[targetUnitId] then
                        for _, breakdown in pairs(getAbilities(damageData)) do
                            totalTicks = totalTicks + (breakdown.ticks or 0)
                            totalCritTicks = totalCritTicks + (breakdown.critTicks or 0)
                            if breakdown.maxTick and breakdown.maxTick > maxHit then
                                maxHit = breakdown.maxTick
                            end
                        end
                    end
                    iterations = iterations + 1
                    if iterations % YIELD_INTERVAL == 0 then
                        LibEffect.YieldWithGC():Await()
                    end
                end
            end
        end

        local critRate = totalTicks > 0 and ((totalCritTicks / totalTicks) * 100) or 0
        return { critRate = critRate, maxHit = maxHit }
    end)
end

---Computes DOT vs Direct breakdown from a filtered damage table
---@param filteredDamageTable table The pre-filtered damage table
---@param abilityInfo table Ability info lookup for determining DOT/Direct
---@return { dot: number, direct: number }
function DamageRenderer.computeDotVsDirectFromFilteredTable(filteredDamageTable, abilityInfo)
    local result = { dot = 0, direct = 0 }
    if not filteredDamageTable then return result end

    for _, byTarget in pairs(filteredDamageTable) do
        for _, damageData in pairs(byTarget) do
            local dotDirect = Arithmancer.ComputeByDotOrDirect(damageData, abilityInfo)
            result.dot = result.dot + (dotDirect.dot or 0)
            result.direct = result.direct + (dotDirect.direct or 0)
        end
    end
    return result
end

---Extracts top abilities sorted by damage from a damage table with detailed stats (async)
---Merges abilities by display name
---@param damageTable table<number, table<number, DamageDoneStorage>>
---@param targetFilter table<number, boolean>|nil Optional target filter
---@param sourceFilter table<number, boolean>|nil Optional source filter
---@param maxCount number Maximum number of abilities to return
---@return Effect<{ abilityId: number, name: string, total: number, ticks: number, critTicks: number, maxHit: number }[]>
function DamageRenderer.extractTopAbilitiesAsync(damageTable, targetFilter, sourceFilter, maxCount)
    return LibEffect.Async(function()
        if not damageTable then return {} end

        local getAbilities = Arithmancer.GetAbilities
        local computeTotal = Arithmancer.ComputeDamageTotal

        -- Aggregate stats per abilityId
        local abilityStats = {}
        local iterations = 0

        for sourceUnitId, byTarget in pairs(damageTable) do
            if not sourceFilter or sourceFilter[sourceUnitId] then
                for targetUnitId, damageData in pairs(byTarget) do
                    if not targetFilter or targetFilter[targetUnitId] then
                        for abilityId, breakdown in pairs(getAbilities(damageData)) do
                            if not abilityStats[abilityId] then
                                abilityStats[abilityId] = {
                                    total = 0,
                                    ticks = 0,
                                    critTicks = 0,
                                    maxHit = 0,
                                }
                            end
                            local stats = abilityStats[abilityId]
                            stats.total = stats.total + computeTotal(breakdown)
                            stats.ticks = stats.ticks + (breakdown.ticks or 0)
                            stats.critTicks = stats.critTicks + (breakdown.critTicks or 0)
                            if breakdown.maxTick and breakdown.maxTick > stats.maxHit then
                                stats.maxHit = breakdown.maxTick
                            end
                        end
                    end
                    iterations = iterations + 1
                    if iterations % YIELD_INTERVAL == 0 then
                        LibEffect.YieldWithGC():Await()
                    end
                end
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Merge by ability name and return top N
        return mergeAbilitiesByName(abilityStats, maxCount)
    end)
end

---Extracts target damage breakdown from a damage table (async)
---@param damageTable table<number, table<number, DamageDoneStorage>>
---@param unitNames table<number, string>
---@param targetFilter table<number, boolean>|nil Optional target filter
---@param sourceFilter table<number, boolean>|nil Optional source filter
---@param maxCount number Maximum number of targets to return
---@return Effect<{ unitId: number, name: string, total: number }[]>
function DamageRenderer.extractTargetBreakdownAsync(damageTable, unitNames, targetFilter, sourceFilter, maxCount)
    return LibEffect.Async(function()
        if not damageTable then return {} end

        local computeTotal = Arithmancer.ComputeDamageTotal
        local targetTotals = {}
        local iterations = 0

        for sourceUnitId, byTarget in pairs(damageTable) do
            if not sourceFilter or sourceFilter[sourceUnitId] then
                for targetUnitId, damageData in pairs(byTarget) do
                    if not targetFilter or targetFilter[targetUnitId] then
                        targetTotals[targetUnitId] = (targetTotals[targetUnitId] or 0) + computeTotal(damageData)
                    end
                    iterations = iterations + 1
                    if iterations % YIELD_INTERVAL == 0 then
                        LibEffect.YieldWithGC():Await()
                    end
                end
            end
        end

        -- Convert to sorted array with names
        local targets = {}
        for unitId, total in pairs(targetTotals) do
            local rawName = unitNames[unitId] or GetString(BATTLESCROLLS_UNKNOWN)
            local name = zo_strformat(SI_UNIT_NAME, rawName)
            table.insert(targets, { unitId = unitId, name = name, total = total })
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

---Extracts damage taken abilities sorted by damage (async)
---Merges abilities by display name
---@param damageTakenTable table<number, table<number, DamageDoneStorage>>
---@param maxCount number Maximum number of abilities to return
---@return Effect<{ abilityId: number, name: string, total: number, ticks: number, critTicks: number, maxHit: number }[]>
function DamageRenderer.extractDamageTakenAbilitiesAsync(damageTakenTable, maxCount)
    return LibEffect.Async(function()
        if not damageTakenTable then return {} end

        local getAbilities = Arithmancer.GetAbilities
        local computeTotal = Arithmancer.ComputeDamageTotal

        -- Aggregate stats per ability
        local abilityStats = {}
        local iterations = 0

        for _, byTarget in pairs(damageTakenTable) do
            for _, damageData in pairs(byTarget) do
                for abilityId, breakdown in pairs(getAbilities(damageData)) do
                    if not abilityStats[abilityId] then
                        abilityStats[abilityId] = {
                            total = 0,
                            ticks = 0,
                            critTicks = 0,
                            maxHit = 0,
                        }
                    end
                    local stats = abilityStats[abilityId]
                    stats.total = stats.total + computeTotal(breakdown)
                    stats.ticks = stats.ticks + (breakdown.ticks or 0)
                    stats.critTicks = stats.critTicks + (breakdown.critTicks or 0)
                    if breakdown.maxTick and breakdown.maxTick > stats.maxHit then
                        stats.maxHit = breakdown.maxTick
                    end
                end
                iterations = iterations + 1
                if iterations % YIELD_INTERVAL == 0 then
                    LibEffect.YieldWithGC():Await()
                end
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Merge by ability name and return top N
        return mergeAbilitiesByName(abilityStats, maxCount)
    end)
end

---Extracts damage taken source breakdown (async)
---@param damageTakenTable table<number, table<number, DamageDoneStorage>>
---@param unitNames table<number, string>
---@param maxCount number Maximum number of sources to return
---@return Effect<{ name: string, total: number }[]>
function DamageRenderer.extractDamageTakenSourcesAsync(damageTakenTable, unitNames, maxCount)
    return LibEffect.Async(function()
        if not damageTakenTable then return {} end

        local computeTotal = Arithmancer.ComputeDamageTotal
        local sourceTotals = {}
        local iterations = 0

        for sourceUnitId, byTarget in pairs(damageTakenTable) do
            for _, damageData in pairs(byTarget) do
                sourceTotals[sourceUnitId] = (sourceTotals[sourceUnitId] or 0) + computeTotal(damageData)
            end
            iterations = iterations + 1
            if iterations % YIELD_INTERVAL == 0 then
                LibEffect.YieldWithGC():Await()
            end
        end

        -- Convert to sorted array with names
        local sources = {}
        for unitId, total in pairs(sourceTotals) do
            local rawName = unitNames[unitId] or GetString(BATTLESCROLLS_UNKNOWN)
            local name = zo_strformat(SI_UNIT_NAME, rawName)
            table.insert(sources, { name = name, total = total })
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

-------------------------
-- Overview Panel Refresh Functions
-------------------------

---@class DamageDonePanelConfig
---@field useBossFilter boolean If true, build filter from bossesUnits when no targetFilter provided
---@field q4SectionLabel number String ID for Q4 section header (BATTLESCROLLS_OVERVIEW_BOSSES or BATTLESCROLLS_OVERVIEW_TARGETS)

---Shared implementation for Boss Damage and Damage Done panels
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table, abilityInfo: table }
---@param config DamageDonePanelConfig
---@return Effect<nil>
local function refreshDamageDonePanel(panel, ctx, config)
    return LibEffect.Async(function()
        local lastControl = nil
        local filters = ctx.filters or {}
        local targetFilter = filters.targetFilter
        local sourceFilter = filters.sourceFilter
        local encounter = ctx.encounter
        local durationS = ctx.durationS
        local unitNames = ctx.unitNames
        local arithmancer = ctx.arithmancer

        -- Build effective target filter (boss mode uses bossOnly flag if no filter provided)
        local effectiveTargetFilter = targetFilter
        if config.useBossFilter and not targetFilter then
            effectiveTargetFilter = {}
            for _, bossId in ipairs(encounter.bossesUnits or {}) do
                effectiveTargetFilter[bossId] = true
            end
        end

        -- Pre-filter damage data for Q3/Q4 sections (which still need filtered tables)
        local filteredDamageTable = Arithmancer.FilterDamageTable(encounter.damageByUnitId, effectiveTargetFilter, sourceFilter)

        -- Q2: Summary section using Arithmancer - returns {dps, groupDps, share}
        local summaryData = arithmancer:getDamageSummary(effectiveTargetFilter, sourceFilter)
        local personalDamage = summaryData.dps * durationS  -- Reconstruct for Q3 ability bars
        lastControl = utils.renderDamageSummarySection(panel, GetString(BATTLESCROLLS_OVERVIEW_SUMMARY), lastControl,
            summaryData.dps, summaryData.groupDps, summaryData.share)
        LibEffect.YieldWithGC():Await()

        -- Composition section - returns {dotPercent, directPercent, aoePercent, stPercent}
        local compositionData = arithmancer:getDamageComposition(effectiveTargetFilter, sourceFilter)
        lastControl = utils.renderDamageCompositionSection(panel, lastControl,
            compositionData.dotPercent, compositionData.directPercent, compositionData.aoePercent, compositionData.stPercent)
        LibEffect.YieldWithGC():Await()

        -- Quality metrics - returns {critRate, maxHit}
        local qualityData = arithmancer:getDamageQuality(effectiveTargetFilter, sourceFilter)
        if qualityData.critRate > 0 or qualityData.maxHit > 0 then
            lastControl = utils.renderDamageQualitySection(panel, lastControl, qualityData.critRate, qualityData.maxHit)
        end

        LibEffect.Yield():Await()

        -- Q3: Top abilities
        local q3Control = nil
        local maxAbilities = panel:GetMaxAbilities()
        local topAbilities = DamageRenderer.extractTopAbilitiesAsync(filteredDamageTable, nil, nil, maxAbilities):Await()
        if #topAbilities > 0 then
            q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_ABILITIES), q3Control)
            local topValue = topAbilities[1].total
            for _, ability in ipairs(topAbilities) do
                q3Control = panel:AddAbilityBar(ability, topValue, personalDamage, durationS, q3Control)
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Q4: Target breakdown
        local q4Control = nil
        local maxTargets = panel:GetMaxTargets()
        local targets = DamageRenderer.extractTargetBreakdownAsync(filteredDamageTable, unitNames, nil, nil, maxTargets):Await()
        if #targets > 0 then
            q4Control = panel:AddQ4Section(GetString(config.q4SectionLabel), q4Control)
            for _, target in ipairs(targets) do
                q4Control = panel:AddTargetRow(target.name, utils.formatTargetDPS(target.total, durationS), q4Control)
            end
        end
    end)
end

---Refreshes the overview panel for Boss Damage tab
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table, abilityInfo: table }
---@return Effect<nil>
function DamageRenderer.refreshPanelForBossDamage(panel, ctx)
    return refreshDamageDonePanel(panel, ctx, {
        useBossFilter = true,
        q4SectionLabel = BATTLESCROLLS_OVERVIEW_BOSSES,
    })
end

---Refreshes the overview panel for Damage Done tab
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table, abilityInfo: table }
---@return Effect<nil>
function DamageRenderer.refreshPanelForDamageDone(panel, ctx)
    return refreshDamageDonePanel(panel, ctx, {
        useBossFilter = false,
        q4SectionLabel = BATTLESCROLLS_OVERVIEW_TARGETS,
    })
end

---Refreshes the overview panel for Damage Taken tab
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table }
---@return Effect<nil>
function DamageRenderer.refreshPanelForDamageTaken(panel, ctx)
    return LibEffect.Async(function()
        local lastControl = nil
        local filters = ctx.filters or {}
        local sourceFilter = filters.sourceFilter
        local encounter = ctx.encounter
        local durationS = ctx.durationS
        local unitNames = ctx.unitNames
        local arithmancer = ctx.arithmancer

        -- Pre-filter damage taken data for Q3/Q4 sections
        local filteredDamageTaken = Arithmancer.FilterDamageTakenTable(encounter.damageTakenByUnitId, sourceFilter)

        -- Q2: Summary section - returns {dtps, total}
        local summaryData = arithmancer:getDamageTakenSummary(sourceFilter)
        local totalDamageTaken = summaryData.total  -- Keep for Q3 ability bars
        lastControl = utils.renderDamageTakenSummarySection(panel, lastControl, summaryData.dtps, summaryData.total)
        LibEffect.YieldWithGC():Await()

        -- Composition section - returns {dotPercent, directPercent, aoePercent, stPercent}
        local compositionData = arithmancer:getDamageTakenComposition(sourceFilter)
        lastControl = utils.renderDamageCompositionSection(panel, lastControl,
            compositionData.dotPercent, compositionData.directPercent, compositionData.aoePercent, compositionData.stPercent)
        LibEffect.YieldWithGC():Await()

        -- Quality metrics - returns {critRate, maxHit}
        local qualityData = arithmancer:getDamageTakenQuality(sourceFilter)
        if qualityData.critRate > 0 or qualityData.maxHit > 0 then
            lastControl = utils.renderDamageQualitySection(panel, lastControl, qualityData.critRate, qualityData.maxHit)
        end

        LibEffect.Yield():Await()

        -- Q3: Top damage taken abilities (using filtered data)
        local q3Control = nil
        local maxAbilities = panel:GetMaxAbilities()
        local topAbilities = DamageRenderer.extractDamageTakenAbilitiesAsync(filteredDamageTaken, maxAbilities):Await()
        if #topAbilities > 0 then
            q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_INCOMING), q3Control)
            local topValue = topAbilities[1].total
            for _, ability in ipairs(topAbilities) do
                q3Control = panel:AddAbilityBar(ability, topValue, totalDamageTaken, durationS, q3Control)
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Q4: Damage sources (using filtered data)
        local q4Control = nil
        local maxTargets = panel:GetMaxTargets()
        local sources = DamageRenderer.extractDamageTakenSourcesAsync(filteredDamageTaken, unitNames, maxTargets):Await()
        if #sources > 0 then
            q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_OVERVIEW_SOURCES), q4Control)
            for _, source in ipairs(sources) do
                q4Control = panel:AddTargetRow(source.name, utils.formatTargetDPS(source.total, durationS), q4Control)
            end
        end
    end)
end

-- Export to namespace
journal.renderers.damage = DamageRenderer

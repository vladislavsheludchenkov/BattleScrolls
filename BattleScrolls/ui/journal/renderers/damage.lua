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
local tooltips = journal.tooltips
local EntryBuilder = journal.EntryBuilder

local ROW_CONTENT = journal.ROW_CONTENT

local DamageRenderer = {}

-- Yield frequency for loops (yield every N iterations)
local YIELD_INTERVAL = 20

-------------------------
-- Section Builders (for overview panel specs)
-------------------------

---@param col ColumnBuilder
---@param sectionLabel string
---@param dps number
---@param groupDps number|nil
---@param share number
---@return Control|nil
local function buildDamageSummary(col, sectionLabel, dps, groupDps, share)
    return col:Section(sectionLabel,
        col:StatRow(GetString(BATTLESCROLLS_STAT_DPS), utils.formatNumber(dps)),
        groupDps and col:StatRow(GetString(BATTLESCROLLS_STAT_GROUP_DPS), utils.formatNumber(groupDps)),
        col:StatRow(GetString(BATTLESCROLLS_OVERVIEW_SHARE), utils.formatPercent(share))
    )
end

---@param col ColumnBuilder
---@param dotPercent number|nil
---@param directPercent number|nil
---@param aoePercent number|nil
---@param stPercent number|nil
---@return Control|nil
local function buildDamageComposition(col, dotPercent, directPercent, aoePercent, stPercent)
    return col:Section(GetString(BATTLESCROLLS_OVERVIEW_COMPOSITION),
        directPercent and col:StatRow(GetString(BATTLESCROLLS_DELIVERY_DIRECT), utils.formatPercent(directPercent)),
        dotPercent and col:StatRow(GetString(BATTLESCROLLS_DELIVERY_DOT), utils.formatPercent(dotPercent)),
        aoePercent and col:StatRow(GetString(BATTLESCROLLS_AOE), utils.formatPercent(aoePercent)),
        stPercent and col:StatRow(GetString(BATTLESCROLLS_SINGLE_TARGET), utils.formatPercent(stPercent))
    )
end

---@param col ColumnBuilder
---@param critRate number
---@param maxHit number
---@return Control|nil
local function buildDamageQuality(col, critRate, maxHit)
    return col:Section(GetString(BATTLESCROLLS_OVERVIEW_QUALITY),
        critRate > 0 and col:StatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE), utils.formatPercent(critRate)),
        maxHit > 0 and col:StatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HIT), utils.formatNumber(maxHit))
    )
end

---@param col ColumnBuilder
---@param dtps number
---@param total number
---@return Control|nil
local function buildDamageTakenSummary(col, dtps, total)
    return col:Section(GetString(BATTLESCROLLS_OVERVIEW_SUMMARY),
        col:StatRow(GetString(BATTLESCROLLS_STAT_DTPS), utils.formatNumber(dtps)),
        col:StatRow(GetString(BATTLESCROLLS_OVERVIEW_TOTAL), utils.formatNumber(total))
    )
end

-------------------------
-- Internal Helpers
-------------------------

---@class AbilityStats
---@field total number Total damage/value
---@field ticks number Number of ticks
---@field critTicks number Number of critical ticks
---@field maxHit number Maximum hit value

---Builds tooltip text for an ability entry from its critStats and metadata
---@param merged table Merged ability entry
---@return string tooltipText
local function buildAbilityTooltipText(merged)
    local lines = {}

    -- Total line
    table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TOTAL), ZO_CommaDelimitNumber(merged.totalDamage)))

    -- Damage type and delivery info
    if merged.damageTypeDesc then
        table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TYPE), merged.damageTypeDesc))
    end
    if merged.overTimeOrDirectDesc then
        table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_DELIVERY), merged.overTimeOrDirectDesc))
    end

    if merged.breakdown then
        -- Multi-variant breakdown
        tooltips.appendTickStats(lines, merged.breakdown.critStats)

        table.insert(lines, "")

        for _, entry in ipairs(merged.breakdown.entries) do
            local pct = merged.totalDamage > 0 and (entry.damage / merged.totalDamage * 100) or 0
            table.insert(lines, string.format("  %s: %s (%.1f%%)", entry.displayName, ZO_CommaDelimitNumber(entry.damage), pct))
            tooltips.appendTickStats(lines, entry.critStats, "    ")
        end
    else
        -- Single variant
        table.insert(lines, "")
        tooltips.appendTickStats(lines, merged.critStats)
    end

    return table.concat(lines, "\n")
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
            local tooltipText = buildAbilityTooltipText(merged)

            EntryBuilder.addEntry(list, {
                label = merged.baseName,
                sublabel = valueStr,
                icon = abilityIcon,
                frame = true,
                header = isFirst and headerText or nil,
                tooltip = { type = "text", title = merged.baseName, text = tooltipText },
            })
            isFirst = false

            if i % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
    end)
end

---Displays damage type breakdown from pre-computed data
---@param list any
---@param byDamageType table<DamageType, number> Pre-computed damage by type (from calc:personalDamageByType() or calc:damageTakenByType())
---@param totalDamage number
---@param durationSec number
---@param sharedData table|nil
local function displayDamageTypeBreakdown(list, byDamageType, totalDamage, durationSec, sharedData)
    local sortedTypes = utils.sortDamageBreakdown(byDamageType)
    local isFirst = true

    for _, entry in ipairs(sortedTypes) do
        local damageType = entry.key
        local typeName = utils.getDamageTypeName(damageType)
        local typeIcon = utils.getDamageTypeIcon(damageType)
        local valueStr = utils.formatDamageWithPercent(entry.damage, totalDamage, durationSec)

        local _, ttText = tooltips.buildGroupAvgTooltip(sharedData, function(data)
            if not data.damageByType or data.totalDamage <= 0 then return nil end
            for _, dbt in ipairs(data.damageByType) do
                if dbt.type == damageType then
                    return dbt.damage / data.totalDamage * 100
                end
            end
            return 0
        end)

        EntryBuilder.addEntry(list, {
            label = typeName,
            sublabel = valueStr,
            icon = typeIcon,
            header = isFirst and GetString(BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE) or nil,
            tooltip = ttText and { type = "text", title = typeName, text = ttText } or nil,
        })
        isFirst = false
    end
end

---Displays direct vs DoT breakdown from pre-computed data
---@param list any
---@param dotVsDirect { dot: number, direct: number } Pre-computed breakdown (from calc:personalDotVsDirect() or calc:damageTakenDotVsDirect())
---@param totalDamage number
---@param durationSec number
---@param sharedData table|nil
local function displayDirectVsDoTBreakdown(list, dotVsDirect, totalDamage, durationSec, sharedData)
    local directDmg = dotVsDirect.direct
    local dotDmg = dotVsDirect.dot

    if directDmg > 0 or dotDmg > 0 then
        local directStr = utils.formatDamageWithPercent(directDmg, totalDamage, durationSec)
        local dotStr = utils.formatDamageWithPercent(dotDmg, totalDamage, durationSec)

        local _, dotTtText = tooltips.buildGroupAvgTooltip(sharedData, function(data)
            if not data.dotPercent then return nil end
            return data.dotPercent * 100
        end)
        local _, directTtText = tooltips.buildGroupAvgTooltip(sharedData, function(data)
            if not data.dotPercent then return nil end
            return (1 - data.dotPercent) * 100
        end)

        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_DIRECT_DAMAGE),
            sublabel = directStr,
            icon = STAT_ICONS.DIRECT,
            header = GetString(BATTLESCROLLS_HEADER_DIRECT_VS_DOT),
            tooltip = directTtText and { type = "text", title = GetString(BATTLESCROLLS_STAT_DIRECT_DAMAGE), text = directTtText } or nil,
        })
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_DAMAGE_OVER_TIME),
            sublabel = dotStr,
            icon = STAT_ICONS.DOT,
            tooltip = dotTtText and { type = "text", title = GetString(BATTLESCROLLS_STAT_DAMAGE_OVER_TIME), text = dotTtText } or nil,
        })
    end
end

---Displays AOE vs single target breakdown
local function displayAoeVsSingleTargetBreakdown(list, aoeVsSingleTarget, totalDamage, durationSec, sharedData)
    local aoeDmg = aoeVsSingleTarget.aoe
    local singleTargetDmg = aoeVsSingleTarget.singleTarget

    if aoeDmg > 0 or singleTargetDmg > 0 then
        local aoeStr = utils.formatDamageWithPercent(aoeDmg, totalDamage, durationSec)
        local singleTargetStr = utils.formatDamageWithPercent(singleTargetDmg, totalDamage, durationSec)

        local _, aoeTtText = tooltips.buildGroupAvgTooltip(sharedData, function(data)
            if not data.aoePercent then return nil end
            return data.aoePercent * 100
        end)
        local _, stTtText = tooltips.buildGroupAvgTooltip(sharedData, function(data)
            if not data.aoePercent then return nil end
            return (1 - data.aoePercent) * 100
        end)

        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_AOE_DAMAGE),
            sublabel = aoeStr,
            icon = STAT_ICONS.AOE,
            header = GetString(BATTLESCROLLS_HEADER_AOE_VS_SINGLE),
            tooltip = aoeTtText and { type = "text", title = GetString(BATTLESCROLLS_STAT_AOE_DAMAGE), text = aoeTtText } or nil,
        })
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE),
            sublabel = singleTargetStr,
            icon = STAT_ICONS.SINGLE_TARGET,
            tooltip = stTtText and { type = "text", title = GetString(BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE), text = stTtText } or nil,
        })
    end
end

---Displays target breakdown (async)
local function displayTargetBreakdownAsync(list, damageTable, totalDamage, durationSec, unitNames, targetFilter, sourceFilter, encounter, arithmancerInst)
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

            local ttTitle, ttText
            if encounter and arithmancerInst then
                ttTitle, ttText = tooltips.buildBossGroupTooltip(unitId, encounter, arithmancerInst, durationSec)
            end

            EntryBuilder.addEntry(list, {
                label = targetName,
                sublabel = valueStr,
                header = isFirst and GetString(BATTLESCROLLS_HEADER_BY_TARGET) or nil,
                tooltip = ttTitle and { type = "text", title = ttTitle, text = ttText or "" } or nil,
            })
            isFirst = false
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

        -- Create boss-filtered arithmancer instance (ForBosses auto-builds boss targetFilter;
        -- user's targetFilter takes precedence if set)
        local bossCalc = Arithmancer:ForBosses(encounter, abilityInfo, { targetFilter = targetFilter, sourceFilter = sourceFilter })
        if not bossCalc then return end

        -- Pre-filter damage data for breakdowns
        local filteredDamageTable = bossCalc:filteredDamageTable()

        -- Summary via arithmancer
        local summary = bossCalc:getDamageSummary()
        local totalBossDamage = summary.personalTotal

        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE),
            sublabel = ZO_CommaDelimitNumber(totalBossDamage),
            icon = STAT_ICONS.DAMAGE,
            header = GetString(BATTLESCROLLS_STAT_SUMMARY),
        })
        local bossDpsTtTitle, bossDpsTtText = tooltips.buildGroupDpsTooltip(encounter, true)
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_BOSS_DPS),
            sublabel = ZO_CommaDelimitNumber(math.floor(summary.dps)),
            icon = STAT_ICONS.DPS,
            tooltip = bossDpsTtTitle and { type = "text", title = bossDpsTtTitle, text = bossDpsTtText or "" } or nil,
        })
        if summary.groupTotal then
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_GROUP_SHARE),
                sublabel = string.format("%.1f%%", summary.share),
                icon = STAT_ICONS.SHARE,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE),
                sublabel = ZO_CommaDelimitNumber(summary.groupTotal),
                icon = STAT_ICONS.GROUP_DAMAGE,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_GROUP_BOSS_DPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(summary.groupDps)),
                icon = STAT_ICONS.GROUP_DPS,
            })
        end
        LibEffect.Yield():Await()

        -- By Ability
        local abilityEntries = buildAbilityEntriesAsync(filteredDamageTable, nil, nil):Await()
        displayAbilityBreakdownAsync(list, abilityEntries, totalBossDamage, durationSec, abilityInfo, unitNames, GetString(BATTLESCROLLS_HEADER_BY_ABILITY)):Await()

        -- By Damage Type
        displayDamageTypeBreakdown(list, bossCalc:personalDamageByType(), totalBossDamage, durationSec, encounter.sharedData)

        -- Direct vs DoT
        displayDirectVsDoTBreakdown(list, bossCalc:personalDotVsDirect(), totalBossDamage, durationSec, encounter.sharedData)

        -- AOE vs Single Target
        displayAoeVsSingleTargetBreakdown(list, bossCalc:personalAoeVsSingleTarget(), totalBossDamage, durationSec, encounter.sharedData)
        LibEffect.Yield():Await()

        -- By Target
        displayTargetBreakdownAsync(list, filteredDamageTable, totalBossDamage, durationSec, unitNames, nil, nil, encounter, ctx.arithmancer):Await()
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

        -- Create filtered arithmancer if filters are present
        local calc = (targetFilter or sourceFilter)
            and Arithmancer:Make(encounter, abilityInfo, { targetFilter = targetFilter, sourceFilter = sourceFilter })
            or ctx.arithmancer
        local filteredDamageTable = calc:filteredDamageTable()

        -- Summary via arithmancer
        local summary = calc:getDamageSummary()
        local totalDamage = summary.personalTotal

        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_TOTAL_DAMAGE),
            sublabel = ZO_CommaDelimitNumber(totalDamage),
            icon = STAT_ICONS.DAMAGE,
            header = GetString(BATTLESCROLLS_STAT_SUMMARY),
        })
        local dpsTtTitle, dpsTtText = tooltips.buildGroupDpsTooltip(encounter, false)
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_DPS),
            sublabel = ZO_CommaDelimitNumber(math.floor(summary.dps)),
            icon = STAT_ICONS.DPS,
            tooltip = dpsTtTitle and { type = "text", title = dpsTtTitle, text = dpsTtText or "" } or nil,
        })
        if summary.groupTotal then
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_GROUP_SHARE),
                sublabel = string.format("%.1f%%", summary.share),
                icon = STAT_ICONS.SHARE,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_GROUP_DAMAGE),
                sublabel = ZO_CommaDelimitNumber(summary.groupTotal),
                icon = STAT_ICONS.GROUP_DAMAGE,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_GROUP_DPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(summary.groupDps)),
                icon = STAT_ICONS.GROUP_DPS,
            })
        end
        LibEffect.Yield():Await()

        -- By Ability
        local abilityEntries = buildAbilityEntriesAsync(filteredDamageTable, nil, nil):Await()
        displayAbilityBreakdownAsync(list, abilityEntries, totalDamage, durationSec, abilityInfo, unitNames, GetString(BATTLESCROLLS_HEADER_BY_ABILITY)):Await()

        -- By Damage Type
        displayDamageTypeBreakdown(list, calc:personalDamageByType(), totalDamage, durationSec, encounter.sharedData)

        -- Direct vs DoT
        displayDirectVsDoTBreakdown(list, calc:personalDotVsDirect(), totalDamage, durationSec, encounter.sharedData)

        -- AOE vs Single Target
        displayAoeVsSingleTargetBreakdown(list, calc:personalAoeVsSingleTarget(), totalDamage, durationSec, encounter.sharedData)
        LibEffect.Yield():Await()

        -- By Target
        displayTargetBreakdownAsync(list, filteredDamageTable, totalDamage, durationSec, unitNames, nil, nil, encounter, ctx.arithmancer):Await()
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

        -- Create filtered arithmancer if filter is present
        local calc = sourceFilter
            and Arithmancer:Make(encounter, abilityInfo, { sourceFilter = sourceFilter })
            or ctx.arithmancer
        local filteredDamageTaken = calc:filteredDamageTakenTable()

        -- Calculate total
        local totalDamageTaken = Arithmancer.ComputeNestedTotal(filteredDamageTaken)

        -- Summary
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN),
            sublabel = ZO_CommaDelimitNumber(totalDamageTaken),
            icon = STAT_ICONS.DAMAGE_TAKEN,
            header = GetString(BATTLESCROLLS_STAT_SUMMARY),
        })
        local dtpsTtTitle, dtpsTtText = tooltips.buildGroupDtpsTooltip(encounter)
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_DTPS),
            sublabel = ZO_CommaDelimitNumber(math.floor(totalDamageTaken / durationSec)),
            icon = STAT_ICONS.DPS,
            tooltip = dtpsTtTitle and { type = "text", title = dtpsTtTitle, text = dtpsTtText or "" } or nil,
        })
        LibEffect.Yield():Await()

        -- Deaths
        local deaths = encounter.deaths
        if deaths then
            local recaps = deaths.recaps
            local recapCount = #recaps
            local isFirst = true
            for i, recap in ipairs(recaps) do
                local label
                if recapCount == 1 then
                    label = GetString(BATTLESCROLLS_GROUP_DEATH)
                elseif i == 1 then
                    label = GetString(BATTLESCROLLS_GROUP_FIRST_DEATH)
                elseif i == recapCount then
                    label = GetString(BATTLESCROLLS_GROUP_LAST_DEATH)
                else
                    label = zo_strformat(GetString(BATTLESCROLLS_DEATH_N), i)
                end

                local sublabel = zo_strformat(GetString(BATTLESCROLLS_GROUP_DEATH_AT), utils.formatDuration(recap.timeOffsetMs))

                local resolvedRows = {}
                for j, attack in ipairs(recap.attacks) do
                    resolvedRows[#resolvedRows + 1] = {
                        icon = GetAbilityIcon(attack.abilityId),
                        label = utils.getAbilityDisplayName(attack.abilityId),
                        value = utils.formatCompact(attack.damage),
                        isHighlighted = (j == #recap.attacks),
                    }
                end

                EntryBuilder.addEntry(list, {
                    label = label,
                    sublabel = sublabel,
                    icon = STAT_ICONS.DEATH,
                    header = isFirst and GetString(BATTLESCROLLS_HEADER_DEATHS) or nil,
                    tooltip = {
                        type = "detailRows",
                        title = label,
                        subtitle = sublabel,
                        rows = resolvedRows,
                    },
                })
                isFirst = false
            end
        end

        -- By Ability
        local abilityEntries = buildAbilityEntriesAsync(filteredDamageTaken, nil, nil):Await()
        displayAbilityBreakdownAsync(list, abilityEntries, totalDamageTaken, durationSec, abilityInfo, unitNames, GetString(BATTLESCROLLS_HEADER_BY_ABILITY)):Await()

        -- By Damage Type (no group avg -- sharedData has outgoing damage stats, not incoming)
        displayDamageTypeBreakdown(list, calc:damageTakenByType(), totalDamageTaken, durationSec, nil)

        -- Direct vs DoT (no group avg -- same reason)
        displayDirectVsDoTBreakdown(list, calc:damageTakenDotVsDirect(), totalDamageTaken, durationSec, nil)

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

            local ttTitle, ttText = tooltips.buildBossDamageTakenGroupTooltip(unitId, encounter)

            EntryBuilder.addEntry(list, {
                label = sourceName,
                sublabel = valueStr,
                header = isFirst and GetString(BATTLESCROLLS_HEADER_BY_SOURCE) or nil,
                tooltip = ttTitle and { type = "text", title = ttTitle, text = ttText or "" } or nil,
            })
            isFirst = false
        end
    end)
end

-------------------------
-- Overview Panel Data Extraction Helpers
-- These are used by both damage panel and overview panel
-------------------------

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
        return utils.mergeAbilitiesByName(abilityStats, maxCount)
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
        return utils.mergeAbilitiesByName(abilityStats, maxCount)
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

-- Import panel layout constants
local SECTION_GAP = journal.SECTION_GAP
local Q3_INSET = journal.Q3_INSET

---@class DamageDonePanelConfig
---@field useBossFilter boolean If true, build filter from bossesUnits when no targetFilter provided
---@field q4SectionLabel number String ID for Q4 section header (BATTLESCROLLS_OVERVIEW_BOSSES or BATTLESCROLLS_OVERVIEW_TARGETS)

---Shared implementation for Boss Damage and Damage Done panel specs
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table, abilityInfo: table }
---@param config DamageDonePanelConfig
---@return PanelSpec
local function buildDamageDonePanelSpec(ctx, config)
    return {
        layout = "three-column",
        build = function(q2, q3, q4)
            local filters = ctx.filters or {}
            local targetFilter = filters.targetFilter
            local sourceFilter = filters.sourceFilter
            local encounter = ctx.encounter
            local durationS = ctx.durationS
            local unitNames = ctx.unitNames
            local arithmancer = ctx.arithmancer
            local abilityInfo = ctx.abilityInfo

            -- Create filtered arithmancer based on config
            local calc
            if config.useBossFilter then
                -- Boss damage tab: auto-build boss filter when no user targetFilter
                -- ForBosses returns nil only if no bosses exist; tab visibility prevents this but guard for safety
                calc = Arithmancer:ForBosses(encounter, abilityInfo, {
                    targetFilter = targetFilter,
                    sourceFilter = sourceFilter,
                })
                if not calc then return end
            elseif targetFilter or sourceFilter then
                calc = Arithmancer:Make(encounter, abilityInfo, { targetFilter = targetFilter, sourceFilter = sourceFilter })
            else
                calc = arithmancer
            end

            -- Pre-filter damage data for Q3/Q4 sections
            local filteredDamageTable = calc:filteredDamageTable()

            -- Q2: Summary + composition + quality
            local summaryData = calc:getDamageSummary()
            local personalDamage = summaryData.dps * durationS  -- Reconstruct for Q3 ability bars

            local summarySection = buildDamageSummary(q2, GetString(BATTLESCROLLS_OVERVIEW_SUMMARY),
                summaryData.dps, summaryData.groupDps, summaryData.share)
            LibEffect.YieldWithGC():Await()

            local compositionData = calc:getDamageComposition()
            local compSection = buildDamageComposition(q2,
                compositionData.dotPercent, compositionData.directPercent, compositionData.aoePercent, compositionData.stPercent)
            LibEffect.YieldWithGC():Await()

            local qualityData = calc:getDamageQuality()
            local qualitySection
            if qualityData.critRate > 0 or qualityData.maxHit > 0 then
                qualitySection = buildDamageQuality(q2, qualityData.critRate, qualityData.maxHit)
            end

            q2:mount(SECTION_GAP, 0, summarySection, compSection, qualitySection)
            LibEffect.Yield():Await()

            -- Q3: Top abilities
            local maxAbilities = q3:maxItems(ROW_CONTENT.ABILITY_BAR, 10)
            local topAbilities = DamageRenderer.extractTopAbilitiesAsync(filteredDamageTable, nil, nil, maxAbilities):Await()
            if #topAbilities > 0 then
                local topValue = topAbilities[1].total
                local abilityBars = {}
                for _, ability in ipairs(topAbilities) do
                    abilityBars[#abilityBars + 1] = q3:AbilityBar(ability, topValue, personalDamage, durationS)
                end
                local q3Section = q3:Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_ABILITIES), abilityBars)
                q3:mount(SECTION_GAP, Q3_INSET, q3Section)
            end

            LibEffect.YieldWithGC():Await()

            -- Q4: Target breakdown
            local maxTargets = q4:maxItems(ROW_CONTENT.STAT_ROW, 10)
            local targets = DamageRenderer.extractTargetBreakdownAsync(filteredDamageTable, unitNames, nil, nil, maxTargets):Await()
            if #targets > 0 then
                local targetRows = {}
                for _, target in ipairs(targets) do
                    targetRows[#targetRows + 1] = q4:StatRow(target.name, utils.formatTargetDPS(target.total, durationS))
                end
                local q4Section = q4:Section(GetString(config.q4SectionLabel), targetRows)
                q4:mount(SECTION_GAP, Q3_INSET, q4Section)
            end
        end
    }
end

---Builds panel spec for Boss Damage tab
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table, abilityInfo: table }
---@return PanelSpec
function DamageRenderer.buildBossDamagePanelSpec(ctx)
    return buildDamageDonePanelSpec(ctx, {
        useBossFilter = true,
        q4SectionLabel = BATTLESCROLLS_OVERVIEW_BOSSES,
    })
end

---Builds panel spec for Damage Done tab
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table, abilityInfo: table }
---@return PanelSpec
function DamageRenderer.buildDamageDonePanelSpec(ctx)
    return buildDamageDonePanelSpec(ctx, {
        useBossFilter = false,
        q4SectionLabel = BATTLESCROLLS_OVERVIEW_TARGETS,
    })
end

---Builds panel spec for Damage Taken tab
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table }
---@return PanelSpec
function DamageRenderer.buildDamageTakenPanelSpec(ctx)
    return {
        layout = "three-column",
        build = function(q2, q3, q4)
            local filters = ctx.filters or {}
            local sourceFilter = filters.sourceFilter
            local encounter = ctx.encounter
            local durationS = ctx.durationS
            local unitNames = ctx.unitNames
            local arithmancer = ctx.arithmancer
            local abilityInfo = ctx.abilityInfo

            -- Create filtered arithmancer for Q2 summaries and Q3/Q4 display
            local calc = sourceFilter
                and Arithmancer:Make(encounter, abilityInfo, { sourceFilter = sourceFilter })
                or arithmancer
            local filteredDamageTaken = calc:filteredDamageTakenTable()

            -- Q2: Summary + composition + quality
            local summaryData = calc:getDamageTakenSummary()
            local totalDamageTaken = summaryData.total  -- Keep for Q3 ability bars

            local summarySection = buildDamageTakenSummary(q2, summaryData.dtps, summaryData.total)
            LibEffect.YieldWithGC():Await()

            local compositionData = calc:getDamageTakenComposition()
            local compSection = buildDamageComposition(q2,
                compositionData.dotPercent, compositionData.directPercent, compositionData.aoePercent, compositionData.stPercent)
            LibEffect.YieldWithGC():Await()

            local qualityData = calc:getDamageTakenQuality()
            local qualitySection
            if qualityData.critRate > 0 or qualityData.maxHit > 0 then
                qualitySection = buildDamageQuality(q2, qualityData.critRate, qualityData.maxHit)
            end

            q2:mount(SECTION_GAP, 0, summarySection, compSection, qualitySection)
            LibEffect.Yield():Await()

            -- Q3: Top damage taken abilities (using filtered data)
            local maxAbilities = q3:maxItems(ROW_CONTENT.ABILITY_BAR, 10)
            local topAbilities = DamageRenderer.extractDamageTakenAbilitiesAsync(filteredDamageTaken, maxAbilities):Await()
            if #topAbilities > 0 then
                local topValue = topAbilities[1].total
                local abilityBars = {}
                for _, ability in ipairs(topAbilities) do
                    abilityBars[#abilityBars + 1] = q3:AbilityBar(ability, topValue, totalDamageTaken, durationS)
                end
                local q3Section = q3:Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_INCOMING), abilityBars)
                q3:mount(SECTION_GAP, Q3_INSET, q3Section)
            end

            LibEffect.YieldWithGC():Await()

            -- Q4: Damage sources (using filtered data)
            local maxTargets = q4:maxItems(ROW_CONTENT.STAT_ROW, 10)
            local sources = DamageRenderer.extractDamageTakenSourcesAsync(filteredDamageTaken, unitNames, maxTargets):Await()
            if #sources > 0 then
                local sourceRows = {}
                for _, source in ipairs(sources) do
                    sourceRows[#sourceRows + 1] = q4:StatRow(source.name, utils.formatTargetDPS(source.total, durationS))
                end
                local q4Section = q4:Section(GetString(BATTLESCROLLS_OVERVIEW_SOURCES), sourceRows)
                q4:mount(SECTION_GAP, Q3_INSET, q4Section)
            end
        end
    }
end

-- Export to namespace
journal.renderers.damage = DamageRenderer

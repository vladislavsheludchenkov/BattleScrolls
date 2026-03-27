-----------------------------------------------------------
-- Effects Renderer
-- Standalone renderer for effects stats tab
--
-- All functions receive a JournalRenderContext and operate
-- on the list without needing a class instance.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local utils = journal.utils
local tooltips = journal.tooltips
local EntryBuilder = journal.EntryBuilder
local FilterConstants = journal.FilterConstants
local ROW_CONTENT = journal.ROW_CONTENT
local SECTION_GAP = journal.SECTION_GAP
local Q3_INSET = journal.Q3_INSET

local EffectsRenderer = {}

-- Yield frequency for loops (yield every N iterations)
local YIELD_INTERVAL = 20

-- Special display name marker for self in effects filter
local SELF_DISPLAY_NAME = FilterConstants.SELF_DISPLAY_NAME

---Filters a sorted effects array by ability name against a search term
---@param sortedEffects { abilityId: number }[] Sorted array with abilityId field
---@param searchText string Search text from the header edit box
---@return { abilityId: number }[] filtered Filtered array (same reference if no filter)
local function filterBySearch(sortedEffects, searchText)
    if not searchText or searchText == "" then return sortedEffects end
    local lowerSearch = searchText:lower()
    local filtered = {}
    for _, entry in ipairs(sortedEffects) do
        if zo_plainstrfind(utils.getAbilityDisplayName(entry.abilityId):lower(), lowerSearch) then
            filtered[#filtered + 1] = entry
        end
    end
    return filtered
end

-------------------------
-- Effects Display Helpers
-------------------------

---Formats uptime percentage
---@param activeTimeMs number
---@param durationMs number
---@return number uptimePercent
local function calculateUptime(activeTimeMs, durationMs)
    if durationMs <= 0 then
        return 0
    end
    return (activeTimeMs / durationMs) * 100
end

---Formats effect entry value string (brief, for list display)
---Works for player, boss, and group effects (all use same attribution fields)
---When multiple concurrent instances exist, shows average uptime per instance
---@param stats EffectStatsStorage
---@param durationMs number
---@return string
local function formatEffectValueBrief(stats, durationMs)
    local peakInstances = stats.peakConcurrentInstances or 1

    -- Calculate uptime: if multiple instances, show average per instance
    local uptimePercent
    if peakInstances > 1 then
        uptimePercent = calculateUptime(stats.totalActiveTimeMs, durationMs * peakInstances)
    else
        uptimePercent = calculateUptime(stats.totalActiveTimeMs, durationMs)
    end

    -- Build the display string
    if peakInstances > 1 then
        -- Multiple instances: "45% avg (×2)" or "45% avg (30% yours, ×2)"
        if stats.playerActiveTimeMs and stats.playerActiveTimeMs > 0 then
            local playerUptimePercent = calculateUptime(stats.playerActiveTimeMs, durationMs)
            return string.format("%.1f%% %s (%.1f%% %s, ×%d)", uptimePercent, GetString(BATTLESCROLLS_EFFECT_AVG), playerUptimePercent, GetString(BATTLESCROLLS_EFFECT_YOURS), peakInstances)
        end
        return string.format("%.1f%% %s (×%d)", uptimePercent, GetString(BATTLESCROLLS_EFFECT_AVG), peakInstances)
    else
        -- Single instance: normal display
        if stats.playerActiveTimeMs and stats.playerActiveTimeMs > 0 then
            local playerUptimePercent = calculateUptime(stats.playerActiveTimeMs, durationMs)
            return string.format("%.1f%% %s (%.1f%% %s)", uptimePercent, GetString(BATTLESCROLLS_EFFECT_UPTIME), playerUptimePercent, GetString(BATTLESCROLLS_EFFECT_YOURS))
        end
        return string.format("%.1f%% %s", uptimePercent, GetString(BATTLESCROLLS_EFFECT_UPTIME))
    end
end

---Formats group effect entry value string (brief, for list display)
---@param avgUptimePercent number
---@param memberCount number
---@param playerUptimePercent number
---@return string
local function formatGroupEffectValueBrief(avgUptimePercent, memberCount, playerUptimePercent)
    local membersStr = zo_strformat(GetString(BATTLESCROLLS_EFFECT_MEMBERS), memberCount)
    if playerUptimePercent > 0 then
        local yoursStr = zo_strformat(GetString(BATTLESCROLLS_EFFECT_YOURS_PERCENT), string.format("%.1f", playerUptimePercent))
        return string.format("%.1f%% %s (%s, %s)", avgUptimePercent, GetString(BATTLESCROLLS_EFFECT_AVG), yoursStr, membersStr)
    end
    return string.format("%.1f%% %s (%s)", avgUptimePercent, GetString(BATTLESCROLLS_EFFECT_AVG), membersStr)
end

---Gets the favorites table from settings
---@return table<number, boolean>
local function getFavorites()
    local storage = BattleScrolls.storage
    return storage and storage.savedVariables and storage.savedVariables.settings and storage.savedVariables.settings.favoriteEffects or {}
end

---Sorts effects by uptime descending (async with yields), favorites first
---@param effects table<number, EffectStatsStorage>
---@param durationMs number Reference duration for uptime calculation
---@return Effect<{ abilityId: number, stats: EffectStatsStorage }[]>
local function sortEffectsByUptimeAsync(effects, durationMs)
    return LibEffect.Async(function()
        local favorites = getFavorites()
        local sorted = {}
        local count = 0
        for abilityId, stats in pairs(effects) do
            local uptime = durationMs > 0 and (stats.totalActiveTimeMs / durationMs * 100) or 0
            table.insert(sorted, { abilityId = abilityId, stats = stats, uptime = uptime })
            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        table.sort(sorted, function(a, b)
            local aFav = favorites[a.abilityId] or false
            local bFav = favorites[b.abilityId] or false
            if aFav ~= bFav then return aFav end
            if a.uptime ~= b.uptime then return a.uptime > b.uptime end
            return a.abilityId < b.abilityId
        end)
        return sorted
    end)
end

---Displays a list of effect entries with consistent formatting (async with yields)
---@param list any The parametric list
---@param sortedEffects table[] Array of {abilityId, stats, ...}
---@param durationMs number Duration for uptime/tooltip calculations
---@param headerText string Header for the section
---@param formatValueFn function(stats, durationMs): string
---@return Effect
local function displayEffectEntriesAsync(list, sortedEffects, durationMs, headerText, formatValueFn)
    return LibEffect.Async(function()
        local favorites = getFavorites()
        local isFirst = true
        for i, entry in ipairs(sortedEffects) do
            local abilityName = utils.getAbilityDisplayName(entry.abilityId)
            local abilityIcon = GetAbilityIcon(entry.abilityId)
            local valueStr = formatValueFn(entry.stats, durationMs)
            local isFavorite = favorites[entry.abilityId] or false

            local lines = tooltips.buildEffectTooltipLines(entry.stats, durationMs)

            EntryBuilder.addEntry(list, {
                label = abilityName,
                sublabel = valueStr,
                icon = abilityIcon,
                frame = true,
                header = isFirst and headerText or nil,
                tooltip = { type = "text", title = abilityName, text = table.concat(lines, "\n") },
                isFavorite = isFavorite,
                onFavoriteToggle = function()
                    local favs = BattleScrolls.storage.savedVariables.settings.favoriteEffects
                    if favs[entry.abilityId] then
                        favs[entry.abilityId] = nil
                    else
                        favs[entry.abilityId] = true
                    end
                end,
            })

            isFirst = false

            if i % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
    end)
end

---Separates effects into buffs and debuffs, sorted by uptime descending (async with yields)
---@param effects table<number, EffectStatsStorage>
---@param durationMs number Reference duration for uptime calculation
---@return Effect<{ buffs: table[], debuffs: table[] }>
local function separateBuffsAndDebuffsAsync(effects, durationMs)
    return LibEffect.Async(function()
        local favorites = getFavorites()
        local buffs = {}
        local debuffs = {}
        local count = 0
        for abilityId, stats in pairs(effects) do
            local uptime = durationMs > 0 and (stats.totalActiveTimeMs / durationMs * 100) or 0
            if stats.effectType == BUFF_EFFECT_TYPE_BUFF then
                table.insert(buffs, { abilityId = abilityId, stats = stats, uptime = uptime })
            else
                table.insert(debuffs, { abilityId = abilityId, stats = stats, uptime = uptime })
            end
            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        -- Sort each by favorites first, then uptime descending
        table.sort(buffs, function(a, b)
            local aFav = favorites[a.abilityId] or false
            local bFav = favorites[b.abilityId] or false
            if aFav ~= bFav then return aFav end
            if a.uptime ~= b.uptime then return a.uptime > b.uptime end
            return a.abilityId < b.abilityId
        end)
        table.sort(debuffs, function(a, b)
            local aFav = favorites[a.abilityId] or false
            local bFav = favorites[b.abilityId] or false
            if aFav ~= bFav then return aFav end
            if a.uptime ~= b.uptime then return a.uptime > b.uptime end
            return a.abilityId < b.abilityId
        end)
        return { buffs = buffs, debuffs = debuffs }
    end)
end

-------------------------
-- Shared Aggregation Helpers
-------------------------

---@class GroupBuffAggregation
---@field totalActiveTimeMs number Sum of active time across all members
---@field totalEffectiveAliveTimeMs number Sum of effective alive time (alive time × peak instances) for proper avg calculation
---@field timeAtMaxStacksMs number Sum of time at max stacks
---@field applications number Total applications
---@field maxStacks number Maximum stacks observed
---@field memberCount number Number of members with this effect
---@field playerActiveTimeMs number Player's contribution to active time
---@field playerTimeAtMaxStacksMs number Player's contribution to max stacks time
---@field playerApplications number Player's applications

---@class GroupBuffMemberBreakdown
---@field displayName string The display name (or SELF_DISPLAY_NAME for player)
---@field uptimePercent number Uptime percentage for this member
---@field isSelf boolean Whether this is the player

---Aggregates group buff effects across all members (respecting filter, optionally including self)
---Returns raw aggregated data keyed by abilityId, plus per-member breakdown
---@param encounter table The decoded encounter data
---@param durationMs number Fight duration in ms (fallback for missing alive times)
---@param groupFilter table|nil Optional filter for group members
---@return table<number, GroupBuffAggregation> aggregatedByAbility
---@return table<number, GroupBuffMemberBreakdown[]> memberBreakdownByAbility Per-member uptime breakdown keyed by abilityId
---@return boolean includeSelf Whether self was included
---@return number playerAliveTimeMs Player's alive time
local function aggregateGroupBuffs(encounter, durationMs, groupFilter)
    local aggregatedByAbility = {}
    local memberBreakdownByAbility = {}

    local hasGroupEffects = encounter.effectsOnGroup and not ZO_IsTableEmpty(encounter.effectsOnGroup)
    local hasPlayerEffects = encounter.effectsOnPlayer and not ZO_IsTableEmpty(encounter.effectsOnPlayer)
    local playerAliveTimeMs = encounter.playerAliveTimeMs or durationMs

    -- Determine if self should be included
    local includeSelf = hasPlayerEffects and (not groupFilter or groupFilter[SELF_DISPLAY_NAME] == true)

    local function addToAggregation(abilityId, stats, aliveTimeMs, displayName, isSelf)
        if not aggregatedByAbility[abilityId] then
            aggregatedByAbility[abilityId] = {
                totalActiveTimeMs = 0,
                totalEffectiveAliveTimeMs = 0,
                timeAtMaxStacksMs = 0,
                applications = 0,
                maxStacks = 0,
                memberCount = 0,
                playerActiveTimeMs = 0,
                playerTimeAtMaxStacksMs = 0,
                playerApplications = 0,
            }
            memberBreakdownByAbility[abilityId] = {}
        end
        local agg = aggregatedByAbility[abilityId]
        -- Account for multiple concurrent instances when calculating effective alive time
        local peakInstances = stats.peakConcurrentInstances or 1
        local effectiveAliveTimeMs = aliveTimeMs * peakInstances
        agg.totalActiveTimeMs = agg.totalActiveTimeMs + stats.totalActiveTimeMs
        agg.totalEffectiveAliveTimeMs = agg.totalEffectiveAliveTimeMs + effectiveAliveTimeMs
        agg.timeAtMaxStacksMs = agg.timeAtMaxStacksMs + (stats.timeAtMaxStacksMs or 0)
        agg.applications = agg.applications + (stats.applications or 0)
        agg.maxStacks = math.max(agg.maxStacks, stats.maxStacks or 1)
        agg.memberCount = agg.memberCount + 1
        agg.playerActiveTimeMs = agg.playerActiveTimeMs + (stats.playerActiveTimeMs or 0)
        agg.playerTimeAtMaxStacksMs = agg.playerTimeAtMaxStacksMs + (stats.playerTimeAtMaxStacksMs or 0)
        agg.playerApplications = agg.playerApplications + (stats.playerApplications or 0)

        -- Track per-member breakdown
        local uptimePercent = effectiveAliveTimeMs > 0 and (stats.totalActiveTimeMs / effectiveAliveTimeMs * 100) or 0
        table.insert(memberBreakdownByAbility[abilityId], {
            displayName = displayName,
            uptimePercent = uptimePercent,
            isSelf = isSelf,
        })
    end

    -- Include self (player buffs) if included
    if includeSelf then
        for abilityId, stats in pairs(encounter.effectsOnPlayer) do
            if stats.effectType == BUFF_EFFECT_TYPE_BUFF then
                addToAggregation(abilityId, stats, playerAliveTimeMs, SELF_DISPLAY_NAME, true)
            end
        end
    end

    -- Include filtered group members
    if hasGroupEffects then
        for displayName, memberEffects in pairs(encounter.effectsOnGroup) do
            if not groupFilter or groupFilter[displayName] == true then
                local memberAliveTimeMs = encounter.unitAliveTimeMs and encounter.unitAliveTimeMs[displayName] or durationMs
                for abilityId, stats in pairs(memberEffects) do
                    addToAggregation(abilityId, stats, memberAliveTimeMs, displayName, false)
                end
            end
        end
    end

    -- Sort each member breakdown by uptime descending
    for _, breakdown in pairs(memberBreakdownByAbility) do
        table.sort(breakdown, function(a, b)
            if a.uptimePercent ~= b.uptimePercent then return a.uptimePercent > b.uptimePercent end
            return a.displayName < b.displayName
        end)
    end

    return aggregatedByAbility, memberBreakdownByAbility, includeSelf, playerAliveTimeMs
end

---@class BossDebuffAggregation
---@field totalActiveTimeMs number Sum of active time across all bosses
---@field totalEffectiveAliveTimeMs number Sum of effective alive time (alive time × peak instances) for proper avg calculation
---@field applications number Total applications
---@field playerApplications number Player's applications
---@field playerActiveTimeMs number Player's contribution to active time
---@field maxStacks number Maximum stacks observed
---@field bossCount number Number of bosses with this effect

---Aggregates boss debuff effects across all bosses
---Returns raw aggregated data keyed by abilityId
---@param encounter table The decoded encounter data
---@param durationMs number Fight duration in ms (fallback for missing alive times)
---@return table<number, BossDebuffAggregation> aggregatedByAbility
local function aggregateBossDebuffs(encounter, durationMs)
    local aggregatedByAbility = {}

    if not encounter.effectsOnBosses then
        return aggregatedByAbility
    end

    for unitTag, debuffs in pairs(encounter.effectsOnBosses) do
        local bossAliveTimeMs = encounter.unitAliveTimeMs and encounter.unitAliveTimeMs[unitTag] or durationMs
        for abilityId, stats in pairs(debuffs) do
            if not aggregatedByAbility[abilityId] then
                aggregatedByAbility[abilityId] = {
                    totalActiveTimeMs = 0,
                    totalEffectiveAliveTimeMs = 0,
                    applications = 0,
                    playerApplications = 0,
                    playerActiveTimeMs = 0,
                    maxStacks = 0,
                    bossCount = 0,
                }
            end
            local agg = aggregatedByAbility[abilityId]
            -- Account for multiple concurrent instances when calculating effective alive time
            local peakInstances = stats.peakConcurrentInstances or 1
            local effectiveAliveTimeMs = bossAliveTimeMs * peakInstances
            agg.totalActiveTimeMs = agg.totalActiveTimeMs + (stats.totalActiveTimeMs or 0)
            agg.totalEffectiveAliveTimeMs = agg.totalEffectiveAliveTimeMs + effectiveAliveTimeMs
            agg.applications = agg.applications + (stats.applications or 0)
            agg.playerApplications = agg.playerApplications + (stats.playerApplications or 0)
            agg.playerActiveTimeMs = agg.playerActiveTimeMs + (stats.playerActiveTimeMs or 0)
            agg.maxStacks = math.max(agg.maxStacks, stats.maxStacks or 1)
            agg.bossCount = agg.bossCount + 1
        end
    end

    return aggregatedByAbility
end

---Computes average uptime percentage from aggregated group buff data
---Accounts for multiple concurrent instances via totalEffectiveAliveTimeMs
---@param agg GroupBuffAggregation
---@return number avgUptimePercent
---@return number avgEffectiveAliveTimeMs Average effective alive time per member
local function computeGroupBuffAvgUptime(agg)
    if agg.memberCount == 0 or agg.totalEffectiveAliveTimeMs == 0 then
        return 0, 0
    end
    local avgEffectiveAliveTimeMs = agg.totalEffectiveAliveTimeMs / agg.memberCount
    local avgActiveTimeMs = agg.totalActiveTimeMs / agg.memberCount
    local avgUptimePercent = avgEffectiveAliveTimeMs > 0 and (avgActiveTimeMs / avgEffectiveAliveTimeMs * 100) or 0
    return avgUptimePercent, avgEffectiveAliveTimeMs
end

---Computes average player uptime percentage from aggregated group buff data
---@param agg GroupBuffAggregation
---@param avgEffectiveAliveTimeMs number Average effective alive time per member
---@return number avgPlayerUptimePercent
local function computeGroupBuffAvgPlayerUptime(agg, avgEffectiveAliveTimeMs)
    if agg.memberCount == 0 or avgEffectiveAliveTimeMs == 0 then
        return 0
    end
    local avgPlayerActiveTimeMs = agg.playerActiveTimeMs / agg.memberCount
    return avgEffectiveAliveTimeMs > 0 and (avgPlayerActiveTimeMs / avgEffectiveAliveTimeMs * 100) or 0
end

---Computes average uptime percentage from aggregated boss debuff data
---Accounts for multiple concurrent instances via totalEffectiveAliveTimeMs
---@param agg BossDebuffAggregation
---@return number avgUptimePercent
local function computeBossDebuffAvgUptime(agg)
    if agg.bossCount == 0 or agg.totalEffectiveAliveTimeMs == 0 then
        return 0
    end
    local avgEffectiveAliveTimeMs = agg.totalEffectiveAliveTimeMs / agg.bossCount
    local avgActiveTimeMs = agg.totalActiveTimeMs / agg.bossCount
    return avgEffectiveAliveTimeMs > 0 and (avgActiveTimeMs / avgEffectiveAliveTimeMs * 100) or 0
end

---Computes player contribution percentage from aggregated boss debuff data
---@param agg BossDebuffAggregation
---@return number playerPercent
local function computeBossDebuffPlayerPercent(agg)
    if agg.totalActiveTimeMs == 0 then
        return 0
    end
    return (agg.playerActiveTimeMs / agg.totalActiveTimeMs) * 100
end

-------------------------
-- Public API
-------------------------

---Renders the Effects Player sub-view (buffs + debuffs on player)
---@param ctx JournalRenderContext
---@return Effect
function EffectsRenderer.renderEffectsPlayer(ctx)
    return LibEffect.Async(function()
        local list = ctx.list
        local encounter = ctx.encounter
        local durationMs = encounter.durationMs
        local playerAliveTimeMs = encounter.playerAliveTimeMs or durationMs

        if encounter.effectsOnPlayer and not ZO_IsTableEmpty(encounter.effectsOnPlayer) then
            local result = separateBuffsAndDebuffsAsync(encounter.effectsOnPlayer, playerAliveTimeMs):Await()
            result.buffs = filterBySearch(result.buffs, ctx.searchText)
            result.debuffs = filterBySearch(result.debuffs, ctx.searchText)

            if #result.buffs > 0 then
                displayEffectEntriesAsync(list, result.buffs, playerAliveTimeMs, GetString(BATTLESCROLLS_HEADER_YOUR_BUFFS), formatEffectValueBrief):Await()
            end

            if #result.debuffs > 0 then
                displayEffectEntriesAsync(list, result.debuffs, playerAliveTimeMs, GetString(BATTLESCROLLS_HEADER_DEBUFFS_ON_YOU), formatEffectValueBrief):Await()
            end
        end
    end)
end

---Renders the Effects Boss sub-view (debuffs on bosses)
---@param ctx JournalRenderContext
---@return Effect
function EffectsRenderer.renderEffectsBoss(ctx)
    return LibEffect.Async(function()
        local list = ctx.list
        local encounter = ctx.encounter
        local durationMs = encounter.durationMs

        if not encounter.effectsOnBosses or ZO_IsTableEmpty(encounter.effectsOnBosses) then
            return
        end

        local bossList = {}
        local count = 0
        for unitTag, bossEffects in pairs(encounter.effectsOnBosses) do
            if not ZO_IsTableEmpty(bossEffects) then
                local totalUptime = 0
                for _, stats in pairs(bossEffects) do
                    totalUptime = totalUptime + stats.totalActiveTimeMs
                end
                table.insert(bossList, { unitTag = unitTag, effects = bossEffects, totalUptime = totalUptime })
            end
            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        table.sort(bossList, function(a, b)
            if a.totalUptime ~= b.totalUptime then return a.totalUptime > b.totalUptime end
            return a.unitTag < b.unitTag
        end)

        for i, boss in ipairs(bossList) do
            local rawBossName = encounter.bossNames and encounter.bossNames[boss.unitTag] or GetString(BATTLESCROLLS_UNKNOWN_BOSS)
            local bossName = zo_strformat(SI_UNIT_NAME, rawBossName)
            local headerText = zo_strformat(GetString(BATTLESCROLLS_HEADER_DEBUFFS_ON), bossName)

            local bossAliveTimeMs = encounter.unitAliveTimeMs and encounter.unitAliveTimeMs[boss.unitTag] or durationMs

            local sorted = sortEffectsByUptimeAsync(boss.effects, bossAliveTimeMs):Await()
            sorted = filterBySearch(sorted, ctx.searchText)
            displayEffectEntriesAsync(list, sorted, bossAliveTimeMs, headerText, formatEffectValueBrief):Await()

            if i % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
    end)
end

---Renders the Effects Group sub-view (buffs on group members, includes self)
---@param ctx JournalRenderContext
---@return Effect
function EffectsRenderer.renderEffectsGroup(ctx)
    return LibEffect.Async(function()
        local list = ctx.list
        local encounter = ctx.encounter
        local durationMs = encounter.durationMs
        local groupFilter = ctx.filters.groupFilter

        local aggregatedByAbility, memberBreakdownByAbility = aggregateGroupBuffs(encounter, durationMs, groupFilter)
        LibEffect.Yield():Await()

        if ZO_IsTableEmpty(aggregatedByAbility) then
            return
        end

        -- Sort by average uptime descending
        local sorted = {}
        local count = 0
        for abilityId, stats in pairs(aggregatedByAbility) do
            local avgUptimePercent, avgEffectiveAliveTimeMs = computeGroupBuffAvgUptime(stats)
            local avgPlayerUptimePercent = computeGroupBuffAvgPlayerUptime(stats, avgEffectiveAliveTimeMs)
            table.insert(sorted, {
                abilityId = abilityId,
                stats = stats,
                memberBreakdown = memberBreakdownByAbility[abilityId],
                avgEffectiveAliveTimeMs = avgEffectiveAliveTimeMs,
                avgUptimePercent = avgUptimePercent,
                avgPlayerUptimePercent = avgPlayerUptimePercent,
            })
            count = count + 1
            if count % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
        local favorites = getFavorites()
        table.sort(sorted, function(a, b)
            local aFav = favorites[a.abilityId] or false
            local bFav = favorites[b.abilityId] or false
            if aFav ~= bFav then return aFav end
            if a.avgUptimePercent ~= b.avgUptimePercent then return a.avgUptimePercent > b.avgUptimePercent end
            return a.abilityId < b.abilityId
        end)
        LibEffect.Yield():Await()
        sorted = filterBySearch(sorted, ctx.searchText)

        local isFirst = true
        for i, entry in ipairs(sorted) do
            local abilityName = utils.getAbilityDisplayName(entry.abilityId)
            local abilityIcon = GetAbilityIcon(entry.abilityId)
            local valueStr = formatGroupEffectValueBrief(entry.avgUptimePercent, entry.stats.memberCount, entry.avgPlayerUptimePercent)
            local isFavorite = favorites[entry.abilityId] or false

            local lines = tooltips.buildGroupEffectTooltipLines(entry.stats, entry.avgEffectiveAliveTimeMs, entry.memberBreakdown)

            EntryBuilder.addEntry(list, {
                label = abilityName,
                sublabel = valueStr,
                icon = abilityIcon,
                frame = true,
                header = isFirst and GetString(BATTLESCROLLS_HEADER_BUFFS_ON_GROUP) or nil,
                tooltip = { type = "text", title = abilityName, text = table.concat(lines, "\n") },
                isFavorite = isFavorite,
                onFavoriteToggle = function()
                    local favs = BattleScrolls.storage.savedVariables.settings.favoriteEffects
                    if favs[entry.abilityId] then
                        favs[entry.abilityId] = nil
                    else
                        favs[entry.abilityId] = true
                    end
                end,
            })

            isFirst = false

            if i % YIELD_INTERVAL == 0 then
                LibEffect.Yield():Await()
            end
        end
    end)
end

-------------------------
-- Overview Panel Refresh Function
-------------------------

-- Uptime thresholds for progressive fallback
local UPTIME_THRESHOLD_GAPS = 95     -- First pass: show effects with gaps (< 95%)
local UPTIME_THRESHOLD_IMPERFECT = 100 -- Second pass: show non-perfect effects (< 100%)

---Builds a PanelSpec for the Effects tab overview panel
---Q2: Player buffs (< 95% uptime)
---Q3: Group buffs (sorted by uptime x members)
---Q4: Boss debuffs (combined across all bosses)
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table }
---@return PanelSpec
function EffectsRenderer.buildEffectsPanelSpec(ctx)
    return {
        layout = "three-column",
        build = function(q2, q3, q4)
            local encounter = ctx.encounter
            local durationS = ctx.durationS
            local durationMs = encounter.durationMs or (durationS * 1000)
            local filters = ctx.filters or {}
            local groupFilter = filters.groupFilter

            if durationMs <= 0 then
                return
            end

            -- Player alive time (stored separately from unit alive times)
            local playerAliveTimeMs = encounter.playerAliveTimeMs or durationMs

            ---Collect effects with progressive filtering:
            ---1. First try: effects with uptime < 95% (showing gaps)
            ---2. Second try: effects with uptime < 100% (anything not perfect)
            ---3. Fallback: all effects (when all are at 100%)
            ---@param effectsTable table|nil Effects data
            ---@param effectType number|nil Filter by effect type (BUFF_EFFECT_TYPE_BUFF, etc)
            ---@param referenceDurationMs number Duration for uptime calculation
            ---@return table[] effects Sorted effects array (descending by uptime)
            local function collectEffectsWithFallback(effectsTable, effectType, referenceDurationMs)
                if not effectsTable or ZO_IsTableEmpty(effectsTable) then
                    return {}
                end

                local favorites = getFavorites()

                -- First pass: collect all effects of the specified type with their uptimes
                local allEffects = {}
                for abilityId, stats in pairs(effectsTable) do
                    if stats.effectType == effectType or effectType == nil then
                        local peakInstances = stats.peakConcurrentInstances or 1
                        local effectiveDurationMs = referenceDurationMs * peakInstances
                        local uptime = effectiveDurationMs > 0 and (stats.totalActiveTimeMs / effectiveDurationMs) * 100 or 0
                        local entry = {
                            abilityId = abilityId,
                            uptime = uptime,
                            stats = stats,
                            isFavorite = favorites[abilityId] or false,
                        }
                        table.insert(allEffects, entry)
                    end
                end

                if #allEffects == 0 then
                    return {}
                end

                -- Sort by favorites first, then uptime descending
                table.sort(allEffects, function(a, b)
                    if a.isFavorite ~= b.isFavorite then return a.isFavorite end
                    if a.uptime ~= b.uptime then return a.uptime > b.uptime end
                    return a.abilityId < b.abilityId
                end)

                -- Try progressive thresholds, but always include favorites regardless of threshold
                local gapEffects = {}     -- < 95%
                local imperfectEffects = {} -- < 100%

                for _, effect in ipairs(allEffects) do
                    if effect.isFavorite or effect.uptime < UPTIME_THRESHOLD_IMPERFECT then
                        table.insert(imperfectEffects, effect)
                    end
                    if effect.isFavorite or effect.uptime < UPTIME_THRESHOLD_GAPS then
                        table.insert(gapEffects, effect)
                    end
                end

                -- Return based on what we found (prefer showing gaps, then imperfect, then all)
                -- If only favorites matched a threshold, still use that result
                if #gapEffects > 0 then
                    return gapEffects
                end
                if #imperfectEffects > 0 then
                    return imperfectEffects
                end
                return allEffects
            end

            -- Q2: Player buffs (with icons, no bar for narrow space)
            local playerBuffs = collectEffectsWithFallback(
                encounter.effectsOnPlayer, BUFF_EFFECT_TYPE_BUFF, playerAliveTimeMs)
            local maxQ2Effects = q2:maxItems(ROW_CONTENT.EFFECT_ROW, 10)

            if #playerBuffs > 0 then
                local effectRows = {}
                for i = 1, math.min(maxQ2Effects, #playerBuffs) do
                    local effect = playerBuffs[i]
                    local stats = effect.stats
                    local effectStats = {
                        applications = stats.applications,
                        maxStacks = stats.maxStacks,
                        peakInstances = stats.peakConcurrentInstances,
                    }
                    effectRows[#effectRows + 1] = q2:EffectRow(effect.abilityId, effect.uptime, effectStats, effect.isFavorite)
                end
                local q2Section = q2:Section(GetString(BATTLESCROLLS_OVERVIEW_KEY_BUFFS), unpack(effectRows))
                q2:mount(SECTION_GAP, 0, q2Section)
            else
                -- No player buff effects recorded at all
                local noEffectsRow = q2:StatRow(GetString(BATTLESCROLLS_OVERVIEW_NO_EFFECTS), "")
                local q2Section = q2:Section(GetString(BATTLESCROLLS_OVERVIEW_KEY_BUFFS), noEffectsRow)
                q2:mount(SECTION_GAP, 0, q2Section)
            end

            LibEffect.YieldWithGC():Await()

            -- Detect if only self is selected (solo mode) - skip group buffs to avoid duplication with Q2
            local hasGroupEffects = encounter.effectsOnGroup and not ZO_IsTableEmpty(encounter.effectsOnGroup)
            local hasPlayerEffects = encounter.effectsOnPlayer and not ZO_IsTableEmpty(encounter.effectsOnPlayer)
            local includeSelf = hasPlayerEffects and (not groupFilter or groupFilter[SELF_DISPLAY_NAME] == true)

            local onlySelfInGroup = includeSelf
            if onlySelfInGroup and hasGroupEffects then
                for displayName in pairs(encounter.effectsOnGroup) do
                    if not groupFilter or groupFilter[displayName] == true then
                        onlySelfInGroup = false
                        break
                    end
                end
            end

            ---Collect aggregated effects with progressive filtering (for group/boss data)
            ---@param aggregatedData table<number, table> Aggregated effect data keyed by abilityId
            ---@param computeUptime function(agg): number Function to compute uptime from aggregation
            ---@param buildEntry function(abilityId, agg, avgUptime): table Function to build result entry
            ---@return table[] effects Sorted effects array
            local function collectAggregatedWithFallback(aggregatedData, computeUptime, buildEntry)
                if not aggregatedData or ZO_IsTableEmpty(aggregatedData) then
                    return {}
                end

                local favorites = getFavorites()
                local allEffects = {}
                for abilityId, agg in pairs(aggregatedData) do
                    local avgUptime = computeUptime(agg)
                    local entry = buildEntry(abilityId, agg, avgUptime)
                    entry.isFavorite = favorites[abilityId] or false
                    table.insert(allEffects, entry)
                end

                if #allEffects == 0 then
                    return {}
                end

                -- Sort by favorites first, then score (if present) descending, otherwise avgUptime descending
                table.sort(allEffects, function(a, b)
                    if a.isFavorite ~= b.isFavorite then return a.isFavorite end
                    if a.score and b.score and a.score ~= b.score then
                        return a.score > b.score
                    end
                    if a.avgUptime ~= b.avgUptime then return a.avgUptime > b.avgUptime end
                    return a.abilityId < b.abilityId
                end)

                -- Try progressive thresholds, but always include favorites regardless of threshold
                local gapEffects = {}     -- < 95%
                local imperfectEffects = {} -- < 100%

                for _, effect in ipairs(allEffects) do
                    if effect.isFavorite or effect.avgUptime < UPTIME_THRESHOLD_IMPERFECT then
                        table.insert(imperfectEffects, effect)
                    end
                    if effect.isFavorite or effect.avgUptime < UPTIME_THRESHOLD_GAPS then
                        table.insert(gapEffects, effect)
                    end
                end

                -- Return based on what we found (prefer showing gaps, then imperfect, then all)
                if #gapEffects > 0 then
                    return gapEffects
                end
                if #imperfectEffects > 0 then
                    return imperfectEffects
                end
                return allEffects
            end

            -- Compute group buffs using shared helper (skip if solo mode)
            local groupScores = {}
            if not onlySelfInGroup then
                local groupAggregated = aggregateGroupBuffs(encounter, durationMs, groupFilter)

                groupScores = collectAggregatedWithFallback(
                    groupAggregated,
                    computeGroupBuffAvgUptime,
                    function(abilityId, agg, avgUptime)
                        return {
                            abilityId = abilityId,
                            score = avgUptime * agg.memberCount, -- for sorting
                            avgUptime = avgUptime,
                            memberCount = agg.memberCount,
                            applications = agg.applications,
                            maxStacks = agg.maxStacks,
                        }
                    end
                )
            end

            LibEffect.YieldWithGC():Await()

            -- Compute boss debuffs using shared helper
            local bossAggregated = aggregateBossDebuffs(encounter, durationMs)

            local bossDebuffs = collectAggregatedWithFallback(
                bossAggregated,
                computeBossDebuffAvgUptime,
                function(abilityId, agg, avgUptime)
                    return {
                        abilityId = abilityId,
                        avgUptime = avgUptime,
                        bossCount = agg.bossCount,
                        applications = agg.applications,
                        playerPercent = computeBossDebuffPlayerPercent(agg),
                        maxStacks = agg.maxStacks,
                    }
                end
            )

            -- Q3: Group buffs OR boss debuffs (if no group buffs)
            local maxQ3Effects = q3:maxItems(ROW_CONTENT.EFFECT_BAR, 10)

            if #groupScores > 0 then
                -- Show group buffs in Q3
                local bars = {}
                for i = 1, math.min(maxQ3Effects, #groupScores) do
                    local effect = groupScores[i]
                    local effectStats = {
                        suffix = string.format("(%d)", effect.memberCount),
                        applications = effect.applications,
                        maxStacks = effect.maxStacks,
                    }
                    bars[#bars + 1] = q3:EffectBar(effect.abilityId, effect.avgUptime, effectStats, effect.isFavorite)
                end
                local q3Section = q3:Section(GetString(BATTLESCROLLS_OVERVIEW_GROUP_BUFFS), unpack(bars))
                q3:mount(SECTION_GAP, Q3_INSET, q3Section)
            elseif #bossDebuffs > 0 then
                -- No group buffs - show boss debuffs in Q3 (wider space, with bar)
                local bars = {}
                for i = 1, math.min(maxQ3Effects, #bossDebuffs) do
                    local effect = bossDebuffs[i]
                    local effectStats = {
                        applications = effect.applications,
                        playerPercent = effect.playerPercent,
                        maxStacks = effect.maxStacks,
                    }
                    if effect.bossCount > 1 then
                        effectStats.suffix = string.format("(%d)", effect.bossCount)
                    end
                    bars[#bars + 1] = q3:EffectBar(effect.abilityId, effect.avgUptime, effectStats, effect.isFavorite)
                end
                local q3Section = q3:Section(GetString(BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS), unpack(bars))
                q3:mount(SECTION_GAP, Q3_INSET, q3Section)
            end

            LibEffect.YieldWithGC():Await()

            -- Q4: Boss debuffs (only if group buffs shown in Q3, otherwise already in Q3)
            if #groupScores > 0 and #bossDebuffs > 0 then
                local maxQ4Effects = q4:maxItems(ROW_CONTENT.EFFECT_ROW, 10)

                local rows = {}
                for i = 1, math.min(maxQ4Effects, #bossDebuffs) do
                    local effect = bossDebuffs[i]
                    local effectStats = {
                        applications = effect.applications,
                        playerPercent = effect.playerPercent,
                        maxStacks = effect.maxStacks,
                    }
                    if effect.bossCount > 1 then
                        effectStats.suffix = string.format("(%d)", effect.bossCount)
                    end
                    rows[#rows + 1] = q4:EffectRow(effect.abilityId, effect.avgUptime, effectStats, effect.isFavorite)
                end
                local q4Section = q4:Section(GetString(BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS), unpack(rows))
                q4:mount(SECTION_GAP, Q3_INSET, q4Section)
            end
        end,
    }
end

-- Export to namespace
journal.renderers.effects = EffectsRenderer

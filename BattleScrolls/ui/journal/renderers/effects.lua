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
local FilterConstants = journal.FilterConstants

local EffectsRenderer = {}

-- Yield frequency for loops (yield every N iterations)
local YIELD_INTERVAL = 20

-- Special display name marker for self in effects filter
local SELF_DISPLAY_NAME = FilterConstants.SELF_DISPLAY_NAME

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
---@param stats PlayerEffectStatsStorage|BossEffectStatsStorage
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
    if playerUptimePercent > 0 then
        return string.format("%.1f%% %s (%.1f%% %s, %d %s)", avgUptimePercent, GetString(BATTLESCROLLS_EFFECT_AVG), playerUptimePercent, GetString(BATTLESCROLLS_EFFECT_YOURS), memberCount, GetString(BATTLESCROLLS_EFFECT_MEMBERS))
    end
    return string.format("%.1f%% %s (%d %s)", avgUptimePercent, GetString(BATTLESCROLLS_EFFECT_AVG), memberCount, GetString(BATTLESCROLLS_EFFECT_MEMBERS))
end

---Sorts effects by uptime descending (async with yields)
---@param effects table<number, EffectStatsStorage|BossEffectStatsStorage|GroupEffectStatsStorage>
---@param durationMs number Reference duration for uptime calculation
---@return Effect<{ abilityId: number, stats: EffectStatsStorage|BossEffectStatsStorage|GroupEffectStatsStorage }[]>
local function sortEffectsByUptimeAsync(effects, durationMs)
    return LibEffect.Async(function()
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
            return a.uptime > b.uptime
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
        local isFirst = true
        for i, entry in ipairs(sortedEffects) do
            local abilityName = utils.getAbilityDisplayName(entry.abilityId)
            local abilityIcon = GetAbilityIcon(entry.abilityId)
            local valueStr = formatValueFn(entry.stats, durationMs)

            local entryData = ZO_GamepadEntryData:New(abilityName, abilityIcon)
            entryData.iconFile = abilityIcon
            entryData:SetIconTintOnSelection(true)
            entryData:AddSubLabel(valueStr)
            -- Store raw data for lazy tooltip building
            entryData.effectTooltipData = {
                type = "effect",
                title = abilityName,
                stats = entry.stats,
                durationMs = durationMs,
            }

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

---Separates effects into buffs and debuffs, sorted by uptime descending (async with yields)
---@param effects table<number, PlayerEffectStatsStorage>
---@param durationMs number Reference duration for uptime calculation
---@return Effect<{ buffs: table[], debuffs: table[] }>
local function separateBuffsAndDebuffsAsync(effects, durationMs)
    return LibEffect.Async(function()
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
        -- Sort each by uptime descending
        table.sort(buffs, function(a, b)
            return a.uptime > b.uptime
        end)
        table.sort(debuffs, function(a, b)
            return a.uptime > b.uptime
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
        table.sort(breakdown, function(a, b) return a.uptimePercent > b.uptimePercent end)
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

---Renders the Effects stats tab
---@param ctx JournalRenderContext
---@return Effect
function EffectsRenderer.renderEffects(ctx)
    return LibEffect.Async(function()
        local list = ctx.list
        local encounter = ctx.encounter
        local durationMs = encounter.durationMs

        -- Player alive time (stored separately from unit alive times)
        local playerAliveTimeMs = encounter.playerAliveTimeMs or durationMs

        -------------------------
        -- Player Buffs & Debuffs (separated)
        -------------------------
        if encounter.effectsOnPlayer and not ZO_IsTableEmpty(encounter.effectsOnPlayer) then
            local result = separateBuffsAndDebuffsAsync(encounter.effectsOnPlayer, playerAliveTimeMs):Await()
            local buffs = result.buffs
            local debuffs = result.debuffs

            -- Player Buffs section
            if #buffs > 0 then
                displayEffectEntriesAsync(list, buffs, playerAliveTimeMs, GetString(BATTLESCROLLS_HEADER_YOUR_BUFFS), formatEffectValueBrief):Await()
            end

            -- Player Debuffs section
            if #debuffs > 0 then
                displayEffectEntriesAsync(list, debuffs, playerAliveTimeMs, GetString(BATTLESCROLLS_HEADER_DEBUFFS_ON_YOU), formatEffectValueBrief):Await()
            end
        end
        LibEffect.Yield():Await()

        -------------------------
        -- Debuffs on Bosses
        -------------------------
        if encounter.effectsOnBosses and not ZO_IsTableEmpty(encounter.effectsOnBosses) then
            -- Build sorted list of bosses by total debuff uptime
            -- effectsOnBosses is keyed by unitTag (e.g., "boss1")
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
                return a.totalUptime > b.totalUptime
            end)

            for i, boss in ipairs(bossList) do
                -- Look up boss name from bossNames (keyed by unitTag)
                local rawBossName = encounter.bossNames and encounter.bossNames[boss.unitTag] or GetString(BATTLESCROLLS_UNKNOWN_BOSS)
                local bossName = zo_strformat(SI_UNIT_NAME, rawBossName)
                local headerText = zo_strformat(GetString(BATTLESCROLLS_HEADER_DEBUFFS_ON), bossName)

                -- Use per-boss alive time for uptime calculations (keyed by unitTag, falls back to fight duration)
                local bossAliveTimeMs = encounter.unitAliveTimeMs and encounter.unitAliveTimeMs[boss.unitTag] or durationMs

                local sorted = sortEffectsByUptimeAsync(boss.effects, bossAliveTimeMs):Await()
                displayEffectEntriesAsync(list, sorted, bossAliveTimeMs, headerText, formatEffectValueBrief):Await()

                if i % YIELD_INTERVAL == 0 then
                    LibEffect.Yield():Await()
                end
            end
        end

        -------------------------
        -- Buffs on Group Members (includes self by default)
        -------------------------
        local groupFilter = ctx.filters.groupFilter

        -- Use shared helper to aggregate group buffs (includes per-member breakdown)
        local aggregatedByAbility, memberBreakdownByAbility = aggregateGroupBuffs(encounter, durationMs, groupFilter)
        LibEffect.Yield():Await()

        if not ZO_IsTableEmpty(aggregatedByAbility) then
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
                table.sort(sorted, function(a, b)
                    return a.avgUptimePercent > b.avgUptimePercent
                end)
                LibEffect.Yield():Await()

                local isFirst = true
                for i, entry in ipairs(sorted) do
                    local abilityName = utils.getAbilityDisplayName(entry.abilityId)
                    local abilityIcon = GetAbilityIcon(entry.abilityId)
                    local valueStr = formatGroupEffectValueBrief(entry.avgUptimePercent, entry.stats.memberCount, entry.avgPlayerUptimePercent)

                    local entryData = ZO_GamepadEntryData:New(abilityName, abilityIcon)
                    entryData.iconFile = abilityIcon  -- Store for frame type detection
                    entryData:SetIconTintOnSelection(true)
                    entryData:AddSubLabel(valueStr)
                    -- Store raw data for lazy tooltip building
                    entryData.effectTooltipData = {
                        type = "group",
                        title = abilityName,
                        stats = entry.stats,
                        durationMs = entry.avgEffectiveAliveTimeMs,
                        memberBreakdown = entry.memberBreakdown,
                    }

                    if isFirst then
                        entryData:SetHeader(GetString(BATTLESCROLLS_HEADER_BUFFS_ON_GROUP))
                        list:AddEntryWithHeader("BattleScrolls_AbilityEntryTemplate", entryData)
                        isFirst = false
                    else
                        list:AddEntry("BattleScrolls_AbilityEntryTemplate", entryData)
                    end

                    if i % YIELD_INTERVAL == 0 then
                        LibEffect.Yield():Await()
                    end
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

---Refreshes the overview panel for Effects tab
---Q2: Player buffs (< 95% uptime)
---Q3: Group buffs (sorted by uptime × members)
---Q4: Boss debuffs (combined across all bosses)
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table }
---@return Effect<nil>
function EffectsRenderer.refreshPanelForEffects(panel, ctx)
    return LibEffect.Async(function()
        local lastControl = nil
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

            -- First pass: collect all effects of the specified type with their uptimes
            local allEffects = {}
            for abilityId, stats in pairs(effectsTable) do
                if stats.effectType == effectType or effectType == nil then
                    local peakInstances = stats.peakConcurrentInstances or 1
                    local effectiveDurationMs = referenceDurationMs * peakInstances
                    local uptime = effectiveDurationMs > 0 and (stats.totalActiveTimeMs / effectiveDurationMs) * 100 or 0
                    table.insert(allEffects, {
                        abilityId = abilityId,
                        uptime = uptime,
                        stats = stats,
                    })
                end
            end

            if #allEffects == 0 then
                return {}
            end

            -- Sort by uptime descending (highest first)
            table.sort(allEffects, function(a, b) return a.uptime > b.uptime end)

            -- Try progressive thresholds, but always return something
            local gapEffects = {}     -- < 95%
            local imperfectEffects = {} -- < 100%

            for _, effect in ipairs(allEffects) do
                if effect.uptime < UPTIME_THRESHOLD_IMPERFECT then
                    table.insert(imperfectEffects, effect)
                end
                if effect.uptime < UPTIME_THRESHOLD_GAPS then
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

        -- Q2: Player buffs (with icons, no bar for narrow space)
        local playerBuffs = collectEffectsWithFallback(
            encounter.effectsOnPlayer, BUFF_EFFECT_TYPE_BUFF, playerAliveTimeMs)
        local maxQ2Effects = panel:GetMaxQ2EffectRows(0)  -- No prior content used

        if #playerBuffs > 0 then
            lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_KEY_BUFFS), lastControl)

            for i = 1, math.min(maxQ2Effects, #playerBuffs) do
                local effect = playerBuffs[i]
                local stats = effect.stats
                local effectStats = {
                    applications = stats.applications,
                    maxStacks = stats.maxStacks,
                    peakInstances = stats.peakConcurrentInstances,
                }
                lastControl = panel:AddQ2EffectRow(effect.abilityId, effect.uptime, lastControl, effectStats)
            end
        else
            -- No player buff effects recorded at all
            lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_KEY_BUFFS), lastControl)
            lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_NO_EFFECTS), "", lastControl)
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

            local allEffects = {}
            for abilityId, agg in pairs(aggregatedData) do
                local avgUptime = computeUptime(agg)
                local entry = buildEntry(abilityId, agg, avgUptime)
                table.insert(allEffects, entry)
            end

            if #allEffects == 0 then
                return {}
            end

            -- Sort by score (if present) descending, otherwise avgUptime descending
            table.sort(allEffects, function(a, b)
                if a.score and b.score then
                    return a.score > b.score
                end
                return a.avgUptime > b.avgUptime
            end)

            -- Try progressive thresholds, but always return something
            local gapEffects = {}     -- < 95%
            local imperfectEffects = {} -- < 100%

            for _, effect in ipairs(allEffects) do
                if effect.avgUptime < UPTIME_THRESHOLD_IMPERFECT then
                    table.insert(imperfectEffects, effect)
                end
                if effect.avgUptime < UPTIME_THRESHOLD_GAPS then
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
        local q3Control = nil
        local maxQ3Effects = panel:GetMaxEffectBars(panel.q3Container)

        if #groupScores > 0 then
            -- Show group buffs in Q3
            q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_GROUP_BUFFS), q3Control)

            for i = 1, math.min(maxQ3Effects, #groupScores) do
                local effect = groupScores[i]
                local effectStats = {
                    suffix = string.format("(%d)", effect.memberCount),
                    applications = effect.applications,
                    maxStacks = effect.maxStacks,
                }
                q3Control = panel:AddEffectBar(effect.abilityId, effect.avgUptime, q3Control, effectStats)
            end
        elseif #bossDebuffs > 0 then
            -- No group buffs - show boss debuffs in Q3 (wider space, with bar)
            q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS), q3Control)

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
                q3Control = panel:AddEffectBar(effect.abilityId, effect.avgUptime, q3Control, effectStats)
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Q4: Boss debuffs (only if group buffs shown in Q3, otherwise already in Q3)
        local q4Control = nil
        if #groupScores > 0 and #bossDebuffs > 0 then
            local maxQ4Effects = panel:GetMaxEffectRows()
            q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS), q4Control)

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
                q4Control = panel:AddEffectRow(effect.abilityId, effect.avgUptime, q4Control, effectStats)
            end
        end
    end)
end

-- Export to namespace
journal.renderers.effects = EffectsRenderer

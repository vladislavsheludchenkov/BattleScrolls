-----------------------------------------------------------
-- The Chronicler
-- Orchestrates how the battle journal is presented
--
-- This is a standalone module - all functions receive
-- journalUI as a parameter rather than using class methods.
--
-- Responsible for:
-- - Tooltip rendering for all list entries
-- - Tab bar entries for all navigation modes
-- - List refresh dispatch (instances, encounters, stats)
-- - Coordinating async decoding and rendering
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local STATS_TAB = journal.StatsTab
local NAVIGATION_MODE = journal.NavigationMode

local chronicler = {}

-------------------------
-- Tooltips
-------------------------

---Resets the left tooltip
function chronicler.resetTooltips()
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
end

---Called when list selection changes
---@param journalUI BattleScrolls_Journal_Gamepad
---@param selectedData table|nil
function chronicler.onTargetChanged(journalUI, selectedData)
    chronicler.refreshTooltip(journalUI, selectedData)
end

---Helper to append tick stats lines (crit, avg, min, max)
---@param lines string[] Lines array to append to
---@param stats CritStats|nil Tick statistics
---@param indent string|nil Indentation prefix
local function appendTickStats(lines, stats, indent)
    if not stats or stats.ticks == 0 then
        return
    end
    indent = indent or ""
    local critPercent = stats.critTicks / stats.ticks * 100
    -- Use rawTotal for avg (includes overkill), falling back to total for old data
    local rawTotal = stats.rawTotal and stats.rawTotal > 0 and stats.rawTotal or stats.total
    local avgTick = math.floor(rawTotal / stats.ticks)
    table.insert(lines, string.format("%s%s: %.1f%% (%d/%d)", indent, GetString(BATTLESCROLLS_TOOLTIP_CRIT), critPercent, stats.critTicks, stats.ticks))
    table.insert(lines, string.format("%s%s: %s", indent, GetString(BATTLESCROLLS_TOOLTIP_AVG_TICK), ZO_CommaDelimitNumber(avgTick)))
    table.insert(lines, string.format("%s%s: %s", indent, GetString(BATTLESCROLLS_TOOLTIP_MIN_TICK), ZO_CommaDelimitNumber(stats.minTick)))
    table.insert(lines, string.format("%s%s: %s", indent, GetString(BATTLESCROLLS_TOOLTIP_MAX_TICK), ZO_CommaDelimitNumber(stats.maxTick)))
end

---Calculates uptime percentage
---@param activeTimeMs number
---@param durationMs number
---@return number
local function calculateUptime(activeTimeMs, durationMs)
    if durationMs <= 0 then return 0 end
    return (activeTimeMs / durationMs) * 100
end

---Formats a member name for display in tooltips
---@param displayName string The raw display name
---@param isSelf boolean Whether this is the player
---@return string formattedName
local function formatMemberName(displayName, isSelf)
    if isSelf then
        return GetString(BATTLESCROLLS_TOOLTIP_YOU)
    end
    local cleanName = displayName:gsub("^@", "")
    return zo_strformat(SI_UNIT_NAME, cleanName)
end

---Builds tooltip lines for an effect (player/boss)
---@param stats table Effect stats
---@param durationMs number Reference duration
---@return string[] lines
local function buildEffectTooltipLines(stats, durationMs)
    local peakInstances = stats.peakConcurrentInstances or 1
    local lines = {}

    if peakInstances > 1 then
        local avgUptimePercent = calculateUptime(stats.totalActiveTimeMs, durationMs * peakInstances)
        table.insert(lines, string.format("%s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_INSTANCE), avgUptimePercent))
        table.insert(lines, string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_PEAK_INSTANCES), peakInstances))
        table.insert(lines, string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_TOTAL_APPLICATIONS), stats.applications))
    else
        local uptimePercent = calculateUptime(stats.totalActiveTimeMs, durationMs)
        table.insert(lines, string.format("%s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_TOTAL_UPTIME), uptimePercent))
        table.insert(lines, string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_TOTAL_APPLICATIONS), stats.applications))
    end

    if stats.playerActiveTimeMs ~= nil then
        local playerUptimePercent = calculateUptime(stats.playerActiveTimeMs, durationMs)
        if stats.playerActiveTimeMs > 0 or stats.playerApplications > 0 then
            table.insert(lines, "")
            table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_YOUR_CONTRIBUTION) .. ":")
            table.insert(lines, string.format("  %s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_YOUR_UPTIME), playerUptimePercent))
            table.insert(lines, string.format("  %s: %d", GetString(BATTLESCROLLS_TOOLTIP_YOUR_APPLICATIONS), stats.playerApplications))
        end
    end

    if stats.maxStacks > 1 then
        table.insert(lines, "")
        local maxStacksPercent = calculateUptime(stats.timeAtMaxStacksMs, durationMs)
        table.insert(lines, string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_MAX_STACKS), stats.maxStacks))
        table.insert(lines, string.format("%s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_TIME_AT_MAX_STACKS), maxStacksPercent))
        if stats.playerTimeAtMaxStacksMs and stats.playerTimeAtMaxStacksMs > 0 then
            local playerMaxStacksPercent = calculateUptime(stats.playerTimeAtMaxStacksMs, durationMs)
            table.insert(lines, string.format("%s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_YOUR_TIME_AT_MAX), playerMaxStacksPercent))
        end
    end

    return lines
end

---Builds tooltip lines for a group effect
---@param stats table Aggregated group effect stats
---@param durationMs number Reference duration
---@param memberBreakdown table[]|nil Per-member breakdown
---@return string[] lines
local function buildGroupEffectTooltipLines(stats, durationMs, memberBreakdown)
    local avgActiveTimeMs = stats.totalActiveTimeMs / stats.memberCount
    local avgUptimePercent = calculateUptime(avgActiveTimeMs, durationMs)
    local avgPlayerActiveTimeMs = stats.playerActiveTimeMs / stats.memberCount
    local avgPlayerUptimePercent = calculateUptime(avgPlayerActiveTimeMs, durationMs)

    local lines = {}

    table.insert(lines, string.format("%s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_MEMBER), avgUptimePercent))
    table.insert(lines, string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_TOTAL_APPLICATIONS), stats.applications))
    table.insert(lines, string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_MEMBERS_AFFECTED), stats.memberCount))

    if stats.playerActiveTimeMs > 0 or stats.playerApplications > 0 then
        table.insert(lines, "")
        table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_YOUR_CONTRIBUTION) .. ":")
        table.insert(lines, string.format("  %s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_AVG_UPTIME), avgPlayerUptimePercent))
        table.insert(lines, string.format("  %s: %d", GetString(BATTLESCROLLS_TOOLTIP_YOUR_APPLICATIONS), stats.playerApplications))
    end

    if stats.maxStacks > 1 then
        table.insert(lines, "")
        table.insert(lines, string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_MAX_STACKS_OBSERVED), stats.maxStacks))
        local avgTimeAtMaxStacksMs = stats.timeAtMaxStacksMs / stats.memberCount
        local avgMaxStacksPercent = calculateUptime(avgTimeAtMaxStacksMs, durationMs)
        table.insert(lines, string.format("%s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_AVG_TIME_AT_MAX), avgMaxStacksPercent))
        if stats.playerTimeAtMaxStacksMs > 0 then
            local avgPlayerTimeAtMaxStacksMs = stats.playerTimeAtMaxStacksMs / stats.memberCount
            local avgPlayerMaxStacksPercent = calculateUptime(avgPlayerTimeAtMaxStacksMs, durationMs)
            table.insert(lines, string.format("%s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_YOUR_AVG_TIME_AT_MAX), avgPlayerMaxStacksPercent))
        end
    end

    if memberBreakdown then
        table.insert(lines, "")
        table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_PER_MEMBER) .. ":")
        for _, member in ipairs(memberBreakdown) do
            local name = formatMemberName(member.displayName, member.isSelf)
            table.insert(lines, string.format("  %s: %.1f%%", name, member.uptimePercent))
        end
    end

    return lines
end

---Refreshes the tooltip for the selected entry
---@param journalUI BattleScrolls_Journal_Gamepad
---@param selectedData table|nil
function chronicler.refreshTooltip(journalUI, selectedData)
    chronicler.resetTooltips()

    -- Handle overview panel visibility based on selection
    if journalUI.overviewPanel then
        if selectedData and selectedData.isOverviewEntry then
            journalUI.overviewPanel:Refresh(journalUI)
            journalUI.overviewPanel:Show()
        else
            journalUI.overviewPanel:Hide()
        end
    end

    if not selectedData then
        return
    end

    -- Overview entry has no tooltip (uses the panel instead)
    if selectedData.isOverviewEntry then
        return
    end

    -- Show ability breakdown tooltip
    if selectedData.abilityBreakdown then
        local data = selectedData.abilityBreakdown
        local lines = {}
        table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TOTAL), ZO_CommaDelimitNumber(data.totalDamage)))

        -- Show damage type info
        if data.damageTypeDesc then
            table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TYPE), data.damageTypeDesc))
        end
        if data.overTimeOrDirectDesc then
            table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_DELIVERY), data.overTimeOrDirectDesc))
        end

        -- Show aggregate tick stats for the merged ability
        appendTickStats(lines, data.critStats)

        table.insert(lines, "")

        for _, entry in ipairs(data.entries) do
            local percent = data.totalDamage > 0 and (entry.damage / data.totalDamage * 100) or 0
            local label = entry.displayName
            table.insert(lines, string.format("  %s: %s (%.1f%%)", label, ZO_CommaDelimitNumber(entry.damage), percent))

            -- Show per-entry tick stats
            appendTickStats(lines, entry.critStats, "    ")
        end

        local description = table.concat(lines, "\n")
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, data.baseName, description)
        return
    end

    -- Show single ability tick stats tooltip (no breakdown)
    if selectedData.critStats then
        local stats = selectedData.critStats
        local lines = {}
        table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TOTAL), ZO_CommaDelimitNumber(stats.total)))

        -- Show damage type info
        if selectedData.damageTypeDesc then
            table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TYPE), selectedData.damageTypeDesc))
        end
        if selectedData.overTimeOrDirectDesc then
            table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_DELIVERY), selectedData.overTimeOrDirectDesc))
        end

        appendTickStats(lines, stats)

        local description = table.concat(lines, "\n")
        local title = selectedData.text or GetString(BATTLESCROLLS_TOOLTIP_ABILITY)
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, title, description)
        return
    end

    -- Show proc breakdown tooltip
    if selectedData.procData and selectedData.unitNames then
        local procData = selectedData.procData
        local unitNames = selectedData.unitNames

        local abilityName = BattleScrolls.utils.GetScribeAwareAbilityDisplayName(procData.abilityId)
        if abilityName == "" then
            abilityName = string.format("%s %d", GetString(BATTLESCROLLS_TOOLTIP_ABILITY), procData.abilityId)
        end

        -- Build breakdown text
        local lines = {}
        table.insert(lines, string.format("%s: %d %s", GetString(BATTLESCROLLS_TOOLTIP_TOTAL), procData.totalProcs, GetString(BATTLESCROLLS_STAT_TOTAL_PROCS)))

        if procData.meanIntervalMs > 0 then
            table.insert(lines, string.format("%s: %.1fs", GetString(BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL), procData.meanIntervalMs / 1000))
        end
        if procData.medianIntervalMs > 0 then
            table.insert(lines, string.format("%s: %.1fs", GetString(BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL), procData.medianIntervalMs / 1000))
        end

        table.insert(lines, "")
        table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_BY_TARGET) .. ":")

        -- Sort procs by enemy by count descending
        local sortedByEnemy = {}
        for _, enemyData in ipairs(procData.procsByEnemy) do
            table.insert(sortedByEnemy, enemyData)
        end
        table.sort(sortedByEnemy, function(a, b)
            return a.procCount > b.procCount
        end)

        for _, enemyData in ipairs(sortedByEnemy) do
            local rawName = unitNames[enemyData.unitId] or GetString(BATTLESCROLLS_UNKNOWN)
            local enemyName = zo_strformat(SI_UNIT_NAME, rawName)
            local percent = procData.totalProcs > 0 and (enemyData.procCount / procData.totalProcs * 100) or 0
            table.insert(lines, string.format("  %s: %d (%.1f%%)", enemyName, enemyData.procCount, percent))
        end

        local description = table.concat(lines, "\n")
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, abilityName, description)
        return
    end

    -- Show effect tooltip (built lazily from raw data)
    if selectedData.effectTooltipData then
        local data = selectedData.effectTooltipData
        local lines
        if data.type == "group" then
            lines = buildGroupEffectTooltipLines(data.stats, data.durationMs, data.memberBreakdown)
        else
            lines = buildEffectTooltipLines(data.stats, data.durationMs)
        end
        local description = table.concat(lines, "\n")
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, data.title, description)
        return
    end

    -- Show settings tooltip
    if selectedData.tooltipText then
        local title = selectedData.tooltipTitle or selectedData.text or ""
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, title, selectedData.tooltipText)
    end
end

-------------------------
-- Tab Bar Entries
-------------------------

---@class TabBarEntry
---@field text string Tab label text
---@field callback fun() Tab selection callback

---Gets tab bar entries for the instances list
---@param journalUI BattleScrolls_Journal_Gamepad
---@return TabBarEntry[]
function chronicler.getInstanceTabBarEntries(journalUI)
    return journal.controllers.instanceList.getTabBarEntries(journalUI)
end

---Gets tab bar entries for the encounters list
---@param journalUI BattleScrolls_Journal_Gamepad
---@return TabBarEntry[]
function chronicler.getEncounterListTabBarEntries(journalUI)
    return journal.controllers.encounterList.getTabBarEntries(journalUI)
end

---Gets tab bar entries for an encounter stats view
---@param journalUI BattleScrolls_Journal_Gamepad
---@return TabBarEntry[]
function chronicler.getEncounterTabBarEntries(journalUI)
    local entries = {}

    table.insert(entries, {
        text = GetString(BATTLESCROLLS_TAB_OVERVIEW),
        callback = function()
            if journalUI.selectedTab ~= STATS_TAB.OVERVIEW then
                journalUI.selectedTab = STATS_TAB.OVERVIEW
                chronicler.refreshList(journalUI, true)
            end
        end
    })

    -- Use decoded encounter from UI cache (don't decode synchronously)
    local decodedEncounter = journalUI.decodedEncounter
    if not decodedEncounter then
        return entries
    end

    -- Use pre-computed tab visibility flags from decode
    local tabVis = decodedEncounter._tabVisibility
    if not tabVis then
        return entries
    end

    if tabVis.dealtDamageToBosses then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_BOSS_DAMAGE_DONE),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.BOSS_DAMAGE_DONE then
                    journalUI.selectedTab = STATS_TAB.BOSS_DAMAGE_DONE
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    if tabVis.dealtDamage then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_DAMAGE_DONE),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.DAMAGE_DONE then
                    journalUI.selectedTab = STATS_TAB.DAMAGE_DONE
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    if tabVis.hasDamageTaken then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_DAMAGE_TAKEN),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.DAMAGE_TAKEN then
                    journalUI.selectedTab = STATS_TAB.DAMAGE_TAKEN
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    if tabVis.hasHealingOutToGroup then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_HEALING_OUT),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.HEALING_OUT then
                    journalUI.selectedTab = STATS_TAB.HEALING_OUT
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    if tabVis.hasSelfHealing then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_SELF_HEALING),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.SELF_HEALING then
                    journalUI.selectedTab = STATS_TAB.SELF_HEALING
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    if tabVis.hasHealingInFromGroup then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_HEALING_IN),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.HEALING_IN then
                    journalUI.selectedTab = STATS_TAB.HEALING_IN
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    if tabVis.hasEffects then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_EFFECTS),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.EFFECTS then
                    journalUI.selectedTab = STATS_TAB.EFFECTS
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    return entries
end

-------------------------
-- List Population
-------------------------

---Refreshes the instance list
---@param journalUI BattleScrolls_Journal_Gamepad
function chronicler.refreshInstanceList(journalUI)
    journal.controllers.instanceList.refresh(journalUI)
end

---Refreshes the encounter list
---@param journalUI BattleScrolls_Journal_Gamepad
function chronicler.refreshEncounterList(journalUI)
    journal.controllers.encounterList.refresh(journalUI)
end

---Refreshes the stats list
---@param journalUI BattleScrolls_Journal_Gamepad
---@return Effect|nil
function chronicler.refreshStatsList(journalUI)
    return journal.controllers.statsList.refresh(journalUI)
end

---Refreshes the settings list
---@param journalUI BattleScrolls_Journal_Gamepad
function chronicler.refreshSettingsList(journalUI)
    local list = journalUI.settingsList
    journal.renderers.settings.renderSettings(list, function()
        chronicler.refreshList(journalUI)
    end)
end

---Main refresh dispatch based on current mode
---@param journalUI BattleScrolls_Journal_Gamepad
---@param skipHeaderRefresh boolean|nil
function chronicler.refreshList(journalUI, skipHeaderRefresh)
    if not skipHeaderRefresh then
        journalUI:RefreshHeader()
    end

    if journalUI.mode == NAVIGATION_MODE.INSTANCES then
        chronicler.refreshInstanceList(journalUI)
    elseif journalUI.mode == NAVIGATION_MODE.ENCOUNTERS then
        chronicler.refreshEncounterList(journalUI)
    elseif journalUI.mode == NAVIGATION_MODE.STATS then
        chronicler.refreshStatsList(journalUI)
    elseif journalUI.mode == NAVIGATION_MODE.SETTINGS then
        chronicler.refreshSettingsList(journalUI)
    end
end

-- Export to namespace
journal.chronicler = chronicler

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
---@param displayName string The undecorated display name
---@param isSelf boolean Whether this is the player
---@return string formattedName
local function formatMemberName(displayName, isSelf)
    if isSelf then
        return GetString(BATTLESCROLLS_TOOLTIP_YOU)
    end
    return zo_strformat(SI_UNIT_NAME, displayName)
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

-- Style for AcquireCustomControl: reuses the BattleScrolls_DeathAttackRow XML template
-- (same pattern as armory tooltips using AcquireCustomControl with ZO_GamepadInteractiveAttributeRow)
local DEATH_ATTACK_ROW_STYLE = {
    controlTemplate = "BattleScrolls_DeathAttackRow",
    height = 42,
    widthPercent = 100,
}

-- Reserve space for 36px killing blow skull + 4px gap on ALL rows so icons stay aligned (matches overview panel)
local DEATH_TOOLTIP_ICON_OFFSET_X = 40

---Builds and shows a custom tooltip for death recap entries.
---Uses BattleScrolls_DeathAttackRow custom controls via AcquireCustomControl,
---giving us proper icon frames, killing blow skulls, and right-aligned values
---(same pattern as armorytooltips.lua LayoutArmoryBuildAttributes).
---@param title string Death label (e.g. "First Death")
---@param timing string Timing subtitle (e.g. "at 1:23")
---@param attacks SharedDeathRecapAttack[]|nil Attack list
local function showDeathRecapTooltip(title, timing, attacks)
    local tooltip = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    -- Title section
    local headerSection = tooltip:AcquireSection(tooltip:GetStyle("bodyHeader"))
    headerSection:AddLine(title, tooltip:GetStyle("title"))
    tooltip:AddSection(headerSection)

    -- Timing subtitle (reduced spacing to keep it close to the title)
    local timingSection = tooltip:AcquireSection({ customSpacing = 5 }, tooltip:GetStyle("bodySection"))
    timingSection:AddLine(timing, tooltip:GetStyle("bodyDescription"))
    tooltip:AddSection(timingSection)

    -- Attack rows using BattleScrolls_DeathAttackRow custom controls
    if attacks and #attacks > 0 then
        -- Horizontal divider
        local dividerSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
        dividerSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, tooltip:GetStyle("dividerLine"))
        tooltip:AddSection(dividerSection)

        local attackSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
        for i, attack in ipairs(attacks) do
            local isKillingBlow = (i == #attacks)
            -- Acquire from the tooltip object (persistent), not the section (pooled).
            -- Section pools get wiped by ZO_TooltipSection:Initialize (customControlPools = {})
            -- every time a section is re-acquired, causing duplicate name errors.
            -- The tooltip object is never re-initialized, so its pools persist across resets.
            -- This matches armorytooltips.lua which calls self:AcquireCustomControl on the tooltip.
            local row = tooltip:AcquireCustomControl(DEATH_ATTACK_ROW_STYLE)
            row:SetHidden(false)

            -- Icon at consistent offset (reserves skull space on all rows for alignment)
            local icon = row:GetNamedChild("Icon")
            local abilityIcon = GetAbilityIcon(attack.abilityId)
            icon:SetTexture(abilityIcon)
            icon:ClearAnchors()
            icon:SetAnchor(LEFT, row, LEFT, DEATH_TOOLTIP_ICON_OFFSET_X, 0)

            -- Icon frame: square for active abilities, circle for passives
            local isPassive = journal.utils.isPassiveIcon(abilityIcon)
            row:GetNamedChild("EdgeFrame"):SetHidden(isPassive)
            row:GetNamedChild("CircleFrame"):SetHidden(not isPassive)

            -- Killing blow skull (anchored to icon's left in XML, hidden on non-killing rows)
            local killingBlowIcon = row:GetNamedChild("KillingBlow")
            if killingBlowIcon then
                killingBlowIcon:SetHidden(not isKillingBlow)
            end

            -- Ability name and damage value
            row:GetNamedChild("Name"):SetText(journal.utils.getAbilityDisplayName(attack.abilityId))
            row:GetNamedChild("Value"):SetText(journal.utils.formatCompact(attack.damage))

            attackSection:AddCustomControl(row)
        end
        tooltip:AddSection(attackSection)
    end

    -- Show tooltip + background fragments
    SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipFragment(GAMEPAD_LEFT_TOOLTIP))
    if GAMEPAD_TOOLTIPS:DoesAutoShowTooltipBg(GAMEPAD_LEFT_TOOLTIP) then
        SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipBgFragment(GAMEPAD_LEFT_TOOLTIP))
    end
end

---Refreshes the tooltip for the selected entry
---@param journalUI BattleScrolls_Journal_Gamepad
---@param selectedData table|nil
function chronicler.refreshTooltip(journalUI, selectedData)
    chronicler.resetTooltips()

    -- Handle group table visibility on GROUP tab
    local groupTable = BattleScrolls.journal.groupTable
    if journalUI.selectedTab == STATS_TAB.GROUP then
        if selectedData and selectedData.isOverviewEntry then
            -- Show group table for overview entry, hide overview panel
            if groupTable then
                groupTable:Show(journalUI)
            end
            if journalUI.overviewPanel then
                journalUI.overviewPanel:Hide()
            end
        elseif selectedData and selectedData.groupPlayerData then
            -- Show player detail panel, hide group table
            if groupTable and groupTable:IsActive() then
                groupTable:Leave()
                journalUI:SetActiveKeybinds(journalUI.statsKeybindStripDescriptor)
                journalUI:ActivateCurrentList()
            end
            if groupTable then
                groupTable:Hide()
            end
            if journalUI.overviewPanel then
                journalUI.overviewPanel:Refresh(journalUI, selectedData)
                journalUI.overviewPanel:Show()
            end
        else
            if groupTable then groupTable:Hide() end
            if journalUI.overviewPanel then journalUI.overviewPanel:Hide() end
        end
    else
        -- Non-GROUP tab: hide group table, handle overview panel normally
        if groupTable then groupTable:Hide() end
        if journalUI.overviewPanel then
            if selectedData and (selectedData.isOverviewEntry or selectedData.groupPlayerData) then
                journalUI.overviewPanel:Refresh(journalUI, selectedData)
                journalUI.overviewPanel:Show()
            else
                journalUI.overviewPanel:Hide()
            end
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
        table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TOTAL), zo_strformat(GetString(BATTLESCROLLS_STAT_TOTAL_PROCS), procData.totalProcs)))

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

    -- Show death recap tooltip (from Damage Taken tab death entries)
    if selectedData.deathRecapData then
        local recap = selectedData.deathRecapData
        local title = selectedData.text or GetString(BATTLESCROLLS_HEADER_DEATHS)
        local timing = zo_strformat(GetString(BATTLESCROLLS_GROUP_DEATH_AT),
            journal.utils.formatDuration(recap.timeOffsetMs))
        showDeathRecapTooltip(title, timing, recap.attacks)
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

---Computes tab visibility flags for a decoded encounter.
---These flags are cached on the encounter to avoid recomputation in getEncounterTabBarEntries.
---@param decodedEncounter Encounter
function chronicler.computeTabVisibility(decodedEncounter)
    local computeTotal = BattleScrolls.arithmancer.ComputeDamageTotal
    local dealtDamage = false
    local dealtDamageToBosses = false
    local bossesSet = nil

    -- Build boss set for O(1) lookup
    if decodedEncounter.bossesUnits then
        bossesSet = {}
        for _, bossUnitId in ipairs(decodedEncounter.bossesUnits) do
            bossesSet[bossUnitId] = true
        end
    end

    -- Check damage data
    for _, byTarget in pairs(decodedEncounter.damageByUnitId) do
        for targetUnitId, damage in pairs(byTarget) do
            local total = computeTotal(damage)
            if total > 0 then
                dealtDamage = true
                if bossesSet and bossesSet[targetUnitId] then
                    dealtDamageToBosses = true
                    break  -- Found both flags, can exit early
                end
            end
        end
        if dealtDamageToBosses then break end
    end

    -- Check effects (per-type)
    local hasEffectsPlayer = decodedEncounter.effectsOnPlayer and not ZO_IsTableEmpty(decodedEncounter.effectsOnPlayer)
    local hasEffectsBoss = decodedEncounter.effectsOnBosses and not ZO_IsTableEmpty(decodedEncounter.effectsOnBosses)
    local hasEffectsGroup = decodedEncounter.effectsOnGroup and not ZO_IsTableEmpty(decodedEncounter.effectsOnGroup)

    decodedEncounter._tabVisibility = {
        dealtDamage = dealtDamage,
        dealtDamageToBosses = dealtDamageToBosses,
        hasDamageTaken = not ZO_IsTableEmpty(decodedEncounter.damageTakenByUnitId),
        hasHealingOutToGroup = not ZO_IsTableEmpty(decodedEncounter.healingStats.healingOutToGroup),
        hasSelfHealing = decodedEncounter.healingStats.selfHealing.total.raw > 0,
        hasHealingInFromGroup = not ZO_IsTableEmpty(decodedEncounter.healingStats.healingInFromGroup),
        hasEffectsPlayer = hasEffectsPlayer or false,
        hasEffectsBoss = hasEffectsBoss or false,
        hasEffectsGroup = hasEffectsGroup or false,
        hasAnyEffects = (hasEffectsPlayer or hasEffectsBoss or hasEffectsGroup) or false,
        hasGroupData = decodedEncounter.sharedData ~= nil and #decodedEncounter.sharedData >= 2,
    }
end

---Returns the visible sub-views for a tab group, given tab visibility
---@param groupKey TabGroupKey
---@param tabVis table Pre-computed tab visibility flags
---@return StatsTab[] visibleSubViews
local function getVisibleSubViews(groupKey, tabVis)
    local TabGroups = journal.TabGroups
    local visibilityChecks = {
        [STATS_TAB.BOSS_DAMAGE_DONE] = tabVis.dealtDamageToBosses,
        [STATS_TAB.DAMAGE_DONE] = tabVis.dealtDamage,
        [STATS_TAB.HEALING_OUT] = tabVis.hasHealingOutToGroup,
        [STATS_TAB.SELF_HEALING] = tabVis.hasSelfHealing,
        [STATS_TAB.HEALING_IN] = tabVis.hasHealingInFromGroup,
        [STATS_TAB.EFFECTS_PLAYER] = tabVis.hasEffectsPlayer,
        [STATS_TAB.EFFECTS_BOSS] = tabVis.hasEffectsBoss,
        [STATS_TAB.EFFECTS_GROUP] = tabVis.hasEffectsGroup,
    }
    local visible = {}
    for _, tab in ipairs(TabGroups[groupKey]) do
        if visibilityChecks[tab] then
            table.insert(visible, tab)
        end
    end
    return visible
end

---Picks the best sub-view for a tab group: last-used if still visible, otherwise first visible
---@param journalUI BattleScrolls_Journal_Gamepad
---@param groupKey TabGroupKey
---@param visibleSubViews StatsTab[]
---@return StatsTab
local function pickSubView(journalUI, groupKey, visibleSubViews)
    local lastSubView = journalUI.lastSubView and journalUI.lastSubView[groupKey]
    if lastSubView then
        for _, tab in ipairs(visibleSubViews) do
            if tab == lastSubView then
                return lastSubView
            end
        end
    end
    return visibleSubViews[1]
end

---Gets tab bar entries for an encounter stats view
---@param journalUI BattleScrolls_Journal_Gamepad
---@return TabBarEntry[]
function chronicler.getEncounterTabBarEntries(journalUI)
    local entries = {}

    -- 1. Overview (always present)
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

    -- 2. Damage (parent tab — sub-views: Boss Damage Done, Damage Done)
    local damageSubViews = getVisibleSubViews("DAMAGE", tabVis)
    if #damageSubViews > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_DAMAGE),
            callback = function()
                local subView = pickSubView(journalUI, "DAMAGE", damageSubViews)
                if journalUI.selectedTab ~= subView then
                    journalUI.selectedTab = subView
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    -- 3. Damage Taken (standalone)
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

    -- 4. Healing (parent tab — sub-views: Healing Out, Self Healing, Healing In)
    local healingSubViews = getVisibleSubViews("HEALING", tabVis)
    if #healingSubViews > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_HEALING),
            callback = function()
                local subView = pickSubView(journalUI, "HEALING", healingSubViews)
                if journalUI.selectedTab ~= subView then
                    journalUI.selectedTab = subView
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    -- 5. Effects (parent tab — sub-views: Player, Boss, Group)
    local effectsSubViews = getVisibleSubViews("EFFECTS", tabVis)
    if #effectsSubViews > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_EFFECTS),
            callback = function()
                local subView = pickSubView(journalUI, "EFFECTS", effectsSubViews)
                if journalUI.selectedTab ~= subView then
                    journalUI.selectedTab = subView
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    -- 6. Group (standalone)
    if tabVis.hasGroupData then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_GROUP),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.GROUP then
                    journalUI.selectedTab = STATS_TAB.GROUP
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
    -- If group table is active during tab switch, deactivate it first
    local groupTable = BattleScrolls.journal.groupTable
    if groupTable and groupTable:IsActive() then
        groupTable:Leave()
        journalUI:SetActiveKeybinds(journalUI.statsKeybindStripDescriptor)
        journalUI:ActivateCurrentList()
    end

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

    -- Refresh sub-header on every list refresh (handles show/hide based on tab).
    -- Skip when navigating within the sub-header to preserve scroll animation.
    if not journal.subheader.navigating then
        journal.subheader.refresh(journalUI)
    end
end

-- Expose for subheader module
chronicler.getVisibleSubViews = getVisibleSubViews

-- Export to namespace
journal.chronicler = chronicler

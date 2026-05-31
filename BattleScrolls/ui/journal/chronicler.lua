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
---@param data { title: string, subtitle: string|nil, rows: DetailRow[]|nil }
local function showDeathRecapTooltip(data)
    local tooltip = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    -- Title section
    local headerSection = tooltip:AcquireSection(tooltip:GetStyle("bodyHeader"))
    headerSection:AddLine(data.title, tooltip:GetStyle("title"))
    tooltip:AddSection(headerSection)

    -- Timing subtitle (reduced spacing to keep it close to the title)
    local timingSection = tooltip:AcquireSection({ customSpacing = 5 }, tooltip:GetStyle("bodySection"))
    timingSection:AddLine(data.subtitle, tooltip:GetStyle("bodyDescription"))
    tooltip:AddSection(timingSection)

    -- Attack rows using BattleScrolls_DeathAttackRow custom controls
    if data.rows and #data.rows > 0 then
        -- Horizontal divider
        local dividerSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
        dividerSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, tooltip:GetStyle("dividerLine"))
        tooltip:AddSection(dividerSection)

        -- Check if any row is highlighted (killing blow) to reserve skull space on all rows
        local anyHighlighted = false
        for _, row in ipairs(data.rows) do
            if row.isHighlighted then anyHighlighted = true; break end
        end
        local iconOffsetX = anyHighlighted and DEATH_TOOLTIP_ICON_OFFSET_X or 0

        local attackSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
        for _, row in ipairs(data.rows) do
            -- Acquire from the tooltip object (persistent), not the section (pooled).
            -- Section pools get wiped by ZO_TooltipSection:Initialize (customControlPools = {})
            -- every time a section is re-acquired, causing duplicate name errors.
            -- The tooltip object is never re-initialized, so its pools persist across resets.
            -- This matches armorytooltips.lua which calls self:AcquireCustomControl on the tooltip.
            local control = tooltip:AcquireCustomControl(DEATH_ATTACK_ROW_STYLE)
            control:SetHidden(false)

            -- Icon at consistent offset (reserves skull space on all rows for alignment)
            local icon = control:GetNamedChild("Icon")
            icon:SetTexture(row.icon)
            icon:ClearAnchors()
            icon:SetAnchor(LEFT, control, LEFT, iconOffsetX, 0)

            -- Icon frame: square for active abilities, circle for passives
            local isPassive = journal.utils.isPassiveIcon(row.icon)
            control:GetNamedChild("EdgeFrame"):SetHidden(isPassive)
            control:GetNamedChild("CircleFrame"):SetHidden(not isPassive)

            -- Killing blow skull (anchored to icon's left in XML, hidden on non-killing rows)
            local killingBlowIcon = control:GetNamedChild("KillingBlow")
            if killingBlowIcon then
                killingBlowIcon:SetHidden(not row.isHighlighted)
            end

            -- Ability name and damage value
            control:GetNamedChild("Name"):SetText(row.label)
            if row.value then
                control:GetNamedChild("Value"):SetText(row.value)
            else
                control:GetNamedChild("Value"):SetText("")
            end

            attackSection:AddCustomControl(control)
        end
        tooltip:AddSection(attackSection)
    end

    -- Show tooltip + background fragments
    SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipFragment(GAMEPAD_LEFT_TOOLTIP))
    if GAMEPAD_TOOLTIPS:DoesAutoShowTooltipBg(GAMEPAD_LEFT_TOOLTIP) then
        SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipBgFragment(GAMEPAD_LEFT_TOOLTIP))
    end
end

-- Style for AcquireCustomControl: uses same template as overview panel ability rows
local ABILITY_ROW_STYLE = {
    controlTemplate = "BattleScrolls_AbilityIconEntry",
    widthPercent = 100,
}

-- Style for scribing script lines (smaller font, normal text color)
local SCRIBING_SCRIPT_STYLE = {
    fontSize = "$(GP_27)",
    fontColor = ZO_NORMAL_TEXT,
}

-- Section style for scribing scripts (tight spacing between lines)
local SCRIBING_SECTION_STYLE = {
    childSpacing = 1,
    paddingLeft = 0,
    paddingRight = 0,
}

---Builds and shows a custom tooltip for setup bar abilities with icon rows.
---Uses ZO_GamepadSkillLinePreview_AbilityEntry custom controls via AcquireCustomControl,
---giving us proper icon frames and font-adjusting labels (same pattern as showDeathRecapTooltip).
---@param data { type: string, title: string, abilities: TooltipAbility[] }
local function showSetupBarTooltip(data)
    local tooltip = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    -- Title section
    local headerSection = tooltip:AcquireSection(tooltip:GetStyle("bodyHeader"))
    headerSection:AddLine(data.title, tooltip:GetStyle("title"))
    tooltip:AddSection(headerSection)

    -- Horizontal divider
    local dividerSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
    dividerSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, tooltip:GetStyle("dividerLine"))
    tooltip:AddSection(dividerSection)

    -- Ability rows with scribing scripts
    for _, ability in ipairs(data.abilities) do
        if ability.abilityId > 0 then
            local abilitySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
            local row = tooltip:AcquireCustomControl(ABILITY_ROW_STYLE)
            row:SetHidden(false)

            local isUltimate = ability.isUltimate
            journal.utils.populateAbilityRow(row, ability.abilityId, isUltimate)

            abilitySection:AddCustomControl(row)
            tooltip:AddSection(abilitySection)

            local metaSection = tooltip:AcquireSection(SCRIBING_SECTION_STYLE)
            metaSection:AddLine(journal.utils.formatAbilityIdLine(ability.abilityId), SCRIBING_SCRIPT_STYLE)
            tooltip:AddSection(metaSection)

            -- Scribing scripts: each on its own line with inline icon, tight spacing
            if ability.scripts and #ability.scripts > 0 then
                local scriptSection = tooltip:AcquireSection(SCRIBING_SECTION_STYLE)
                for _, script in ipairs(ability.scripts) do
                    local line = ""
                    if script.icon and script.icon ~= "" then
                        line = string.format("|t28:28:%s|t ", script.icon)
                    end
                    scriptSection:AddLine(line .. script.name, SCRIBING_SCRIPT_STYLE)
                end
                tooltip:AddSection(scriptSection)
            end
        end
    end

    -- Show tooltip + background fragments
    SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipFragment(GAMEPAD_LEFT_TOOLTIP))
    if GAMEPAD_TOOLTIPS:DoesAutoShowTooltipBg(GAMEPAD_LEFT_TOOLTIP) then
        SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipBgFragment(GAMEPAD_LEFT_TOOLTIP))
    end
end

-- Styles for champion/iconList tooltip custom controls (our own templates matching armory look)
local CHAMPION_HEADER_STYLE = {
    controlTemplate = "BattleScrolls_ChampionDisciplineHeader",
    height = journal.ChampionRowStyle.HEADER_HEIGHT,
    widthPercent = 100,
}
local CHAMPION_ROW_STYLE = {
    controlTemplate = "BattleScrolls_ChampionSkillRow",
    height = journal.ChampionRowStyle.ROW_HEIGHT,
    widthPercent = 100,
}
local VENGEANCE_PERK_ROW_STYLE = {
    controlTemplate = "BattleScrolls_VengeancePerkTooltipRow",
    height = 80,
    widthPercent = 100,
}

---@param row Control
---@return Control
local function getVengeancePerkTooltipFramedIcon(row)
    if row.vengeanceFramedIcon then
        return row.vengeanceFramedIcon
    end

    local framedIcon = journal.utils.createVengeancePerkFramedIcon(row)
    framedIcon:SetAnchor(CENTER, row, LEFT, 40, 0)
    row.vengeanceFramedIcon = framedIcon
    return framedIcon
end

---Acquires and populates an icon+label row in the given tooltip section.
---@param tooltip table
---@param section table
---@param rowData IconRow
---@param fallbackIcon string|nil
local function addIconRow(tooltip, section, rowData, fallbackIcon)
    if rowData.vengeanceSlotFlag ~= nil then
        local row = tooltip:AcquireCustomControl(VENGEANCE_PERK_ROW_STYLE)
        row:SetHidden(false)
        journal.utils.setupVengeancePerkFramedIcon(
            getVengeancePerkTooltipFramedIcon(row),
            rowData.vengeanceSlotFlag,
            rowData.icon or fallbackIcon or "",
            ZO_GAMEPAD_DEFAULT_LIST_ENTRY_ICON_DIMENSION)
        row:GetNamedChild("Label"):SetText(rowData.label)
        section:AddCustomControl(row)
        return
    end

    if rowData.abilityId and rowData.abilityId > 0 then
        local row = tooltip:AcquireCustomControl(ABILITY_ROW_STYLE)
        row:SetHidden(false)
        journal.utils.populateAbilityRow(row, rowData.abilityId, rowData.isUltimate == true)
        section:AddCustomControl(row)
        return
    end

    local row = tooltip:AcquireCustomControl(CHAMPION_ROW_STYLE)
    row:SetHidden(false)
    row:GetNamedChild("Icon"):SetTexture(rowData.icon or fallbackIcon or "")
    row:GetNamedChild("Label"):SetText(rowData.label)
    section:AddCustomControl(row)
end

---Builds and shows a tooltip for icon-based lists (champion skills, class skill lines).
---Grouped data renders with discipline headers; flat data renders a plain icon+name list.
---@param data TooltipDescriptor
local function showIconListTooltip(data)
    local tooltip = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    -- Title section
    local headerSection = tooltip:AcquireSection(tooltip:GetStyle("bodyHeader"))
    headerSection:AddLine(data.title, tooltip:GetStyle("title"))
    tooltip:AddSection(headerSection)

    local contentSection = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
    if data.groups then
        for groupIdx, group in ipairs(data.groups) do
            if groupIdx > 1 then
                contentSection:SetNextSpacing(25)
            end
            local header = tooltip:AcquireCustomControl(CHAMPION_HEADER_STYLE)
            header:SetHidden(false)
            header:GetNamedChild("Label"):SetText(group.headerLabel)
            local headerIconCtrl = header:GetNamedChild("Icon")
            if headerIconCtrl then
                local hasIcon = group.headerIcon and group.headerIcon ~= ""
                headerIconCtrl:SetHidden(not hasIcon)
                if hasIcon then headerIconCtrl:SetTexture(group.headerIcon) end
            end
            contentSection:AddCustomControl(header)

            contentSection:SetNextSpacing(2)
            local groupIcon = group.headerIcon or ""
            for _, row in ipairs(group.rows) do
                addIconRow(tooltip, contentSection, row, groupIcon)
            end
        end
    elseif data.rows then
        for _, row in ipairs(data.rows) do
            addIconRow(tooltip, contentSection, row)
        end
    end
    tooltip:AddSection(contentSection)

    -- Show tooltip + background fragments
    SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipFragment(GAMEPAD_LEFT_TOOLTIP))
    if GAMEPAD_TOOLTIPS:DoesAutoShowTooltipBg(GAMEPAD_LEFT_TOOLTIP) then
        SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipBgFragment(GAMEPAD_LEFT_TOOLTIP))
    end
end

---@param data TooltipDescriptor
local function createVengeancePerkTooltipData(data)
    local perkDefId = data.perkDefId
    local slotFlag = data.slotFlag or 0
    local getPerkName = _G["GetVengeancePerkName"]
    local getPerkIcon = _G["GetVengeancePerkIcon"]
    local name = type(getPerkName) == "function" and getPerkName(perkDefId) or ""
    local formattedName = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)

    local rankPerkRewardData = { slotFlags = slotFlag }
    function rankPerkRewardData:GetSlotFlags()
        return self.slotFlags
    end

    if ZO_VeterancyPerkData then
        local rewardData = ZO_VeterancyPerkData:New(perkDefId)
        rewardData:SetRawName(name)
        rewardData:SetFormattedName(formattedName)
        if type(getPerkIcon) == "function" then
            rewardData:SetIcon(getPerkIcon(perkDefId))
        end
        rewardData:SetVeterancyRankPerkRewardData(rankPerkRewardData)
        return rewardData
    end

    local perkData = {
        perkDefId = perkDefId,
        formattedName = formattedName,
        rankPerkRewardData = rankPerkRewardData,
    }
    function perkData:GetRewardId()
        return self.perkDefId
    end
    function perkData:GetFormattedName()
        return self.formattedName
    end
    function perkData:GetVeterancyRankPerkRewardData()
        return self.rankPerkRewardData
    end
    return perkData
end

---@param data TooltipDescriptor
local function showVengeancePerkTooltip(data)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    local didLayoutTooltip = false
    if data.perkDefId and data.perkDefId > 0 and GAMEPAD_TOOLTIPS.LayoutVeterancyPerkTooltip then
        didLayoutTooltip = pcall(function()
            GAMEPAD_TOOLTIPS:LayoutVeterancyPerkTooltip(
                GAMEPAD_LEFT_TOOLTIP,
                createVengeancePerkTooltipData(data))
        end)
    end

    if not didLayoutTooltip then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        local getPerkName = _G["GetVengeancePerkName"]
        local getTooltipText = _G["GetVengeancePerkTooltipText"]
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(
            GAMEPAD_LEFT_TOOLTIP,
            type(getPerkName) == "function" and getPerkName(data.perkDefId) or "",
            type(getTooltipText) == "function" and getTooltipText(data.perkDefId) or "")
    end

    SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipFragment(GAMEPAD_LEFT_TOOLTIP))
    if GAMEPAD_TOOLTIPS:DoesAutoShowTooltipBg(GAMEPAD_LEFT_TOOLTIP) then
        SCENE_MANAGER:AddFragment(GAMEPAD_TOOLTIPS:GetTooltipBgFragment(GAMEPAD_LEFT_TOOLTIP))
    end
end

---Tooltip dispatch table: maps tooltip.type to handler functions.
---Renderers set tooltip descriptors on entries via EntryBuilder; chronicler dispatches here.
---@type table<string, fun(data: TooltipDescriptor)>
local tooltipDispatch = {
    text = function(data)
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, data.title, data.text)
    end,
    item = function(data)
        GAMEPAD_TOOLTIPS:LayoutItemWithStackCountSimple(GAMEPAD_LEFT_TOOLTIP, data.itemLink)
    end,
    panel = function()
        -- No-op: overview panel handles this
    end,
    groupTable = function()
        -- No-op: group table handles this
    end,
    detailRows = function(data)
        showDeathRecapTooltip(data)
    end,
    abilityList = function(data)
        showSetupBarTooltip(data)
    end,
    iconList = function(data)
        showIconListTooltip(data)
    end,
    vengeancePerk = function(data)
        showVengeancePerkTooltip(data)
    end,
}

---Refreshes the tooltip for the selected entry
---@param journalUI BattleScrolls_Journal_Gamepad
---@param selectedData table|nil
function chronicler.refreshTooltip(journalUI, selectedData)
    chronicler.resetTooltips()

    local tooltip = selectedData and selectedData.tooltip
    local isGroupTable = tooltip and tooltip.type == "groupTable"
    local panelSpec = tooltip and tooltip.panelSpec

    -- Handle group table visibility on GROUP tab
    local groupTable = BattleScrolls.journal.groupTable
    if journalUI.selectedTab == STATS_TAB.GROUP then
        if isGroupTable then
            -- Overview entry: show group table, hide overview panel
            if groupTable then
                groupTable:Show(journalUI)
            end
            if journalUI.overviewPanel then
                journalUI.overviewPanel:Hide()
            end
        elseif panelSpec then
            -- Player entry: show player detail panel, hide group table
            if groupTable and groupTable:IsActive() then
                groupTable:Leave()
                journalUI:SetActiveKeybinds(journalUI.statsKeybindStripDescriptor)
                journalUI:ActivateCurrentList()
            end
            if groupTable then
                groupTable:Hide()
            end
            if journalUI.overviewPanel then
                journalUI.overviewPanel:Render(panelSpec)
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
            if panelSpec then
                journalUI.overviewPanel:Render(panelSpec)
                journalUI.overviewPanel:Show()
            else
                journalUI.overviewPanel:Hide()
            end
        end
    end

    if not selectedData or not tooltip then
        return
    end

    local handler = tooltipDispatch[tooltip.type]
    if handler then
        handler(tooltip)
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
        hasSetup = decodedEncounter.setup ~= nil,
        hasActivity = (decodedEncounter.procs and #decodedEncounter.procs > 0) or decodedEncounter.weaving ~= nil,
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

    -- 2. Activity (standalone — weaving, procs)
    if tabVis.hasActivity then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_ACTIVITY),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.ACTIVITY then
                    journalUI.selectedTab = STATS_TAB.ACTIVITY
                    chronicler.refreshList(journalUI, true)
                end
            end,
        })
    end

    -- 3. Damage (parent tab — sub-views: Boss Damage Done, Damage Done)
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

    -- 7. Setup (standalone)
    if tabVis.hasSetup then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_BUILD),
            callback = function()
                if journalUI.selectedTab ~= STATS_TAB.SETUP then
                    journalUI.selectedTab = STATS_TAB.SETUP
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

---Get or cache the loading label control
---@param journalUI BattleScrolls_Journal_Gamepad
---@return Control|nil
local function getLoadingLabel(journalUI)
    if journalUI._loadingLabel then return journalUI._loadingLabel end
    local overviewPane = journalUI.control:GetNamedChild("OverviewPane")
    if overviewPane then
        journalUI._loadingLabel = overviewPane:GetNamedChild("LoadingLabel")
    end
    return journalUI._loadingLabel
end

function chronicler.refreshPivotList(journalUI)
    local pivotSubState = journalUI.pivotSubState or BattleScrolls.journal.pivot.SubState.CONFIG
    local loadingLabel = getLoadingLabel(journalUI)

    -- Hide group table (stats-mode) if still visible
    local groupTable = BattleScrolls.journal.groupTable
    if groupTable then groupTable:Hide() end

    if pivotSubState == BattleScrolls.journal.pivot.SubState.CONFIG then
        BattleScrolls.journal.pivot.resultRenderer.hide()
        if journalUI.overviewPanel then journalUI.overviewPanel:Hide() end
        local list = journalUI.pivotConfigList
        local query = journalUI.pivotQuery
        if query then
            -- Update aggregation state before rendering so the entry appears/disappears correctly
            local scopedEncounters = BattleScrolls.journal.pivot.engine.resolveScope(query.scope)
            BattleScrolls.journal.pivot.query.updateAggregation(query, #scopedEncounters)
            BattleScrolls.journal.pivot.configRenderer.render(list, query, journalUI)
        end
    elseif pivotSubState == BattleScrolls.journal.pivot.SubState.LOADING then
        BattleScrolls.journal.pivot.resultRenderer.hide()
        -- Show loading label inside OverviewPane but hide its content containers
        if journalUI.overviewPanel then
            journalUI.overviewPanel.control:SetHidden(false)
            journalUI.overviewPanel:ShowLoading()
        end
        if loadingLabel then
            loadingLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_PIVOT_LOADING), 0, 0))
            loadingLabel:SetHidden(false)
        end
    elseif pivotSubState == BattleScrolls.journal.pivot.SubState.RESULTS then
        if journalUI.overviewPanel then journalUI.overviewPanel:Hide() end
        local result = journalUI.pivotResult
        if result then
            local pivotTableControl = journalUI.control:GetNamedChild("PivotTable")
            BattleScrolls.journal.pivot.resultRenderer.show(result, pivotTableControl)
            if result.rowsCapped then
                ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil,
                    zo_strformat(GetString(BATTLESCROLLS_PIVOT_ROWS_CAPPED), #result.rows))
            end
            if result.columnsCapped then
                ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil,
                    zo_strformat(GetString(BATTLESCROLLS_PIVOT_COLUMNS_CAPPED), #result.columns))
            end
        end
    end
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

    -- When switching tabs via LB/RB (skipHeaderRefresh=true bypasses RefreshHeader),
    -- update search bar visibility and header data pairs (compact on effects, full on others).
    if skipHeaderRefresh then
        if journalUI.textSearchHeaderFocus then
            local groupKey = journalUI.selectedTab and journal.TabToGroup[journalUI.selectedTab]
            if groupKey == "EFFECTS" then
                journalUI:SetTextSearchEntryHidden(false)
            else
                journalUI:ClearSearchText()
                journalUI:SetTextSearchEntryHidden(true)
            end
        end

        if journalUI.mode == NAVIGATION_MODE.STATS and journalUI.selectedEncounter then
            journalUI:buildStatsHeaderData()
            ZO_GamepadGenericHeader_RefreshData(journalUI.header, journalUI.headerData)
            journalUI:applyStatsHeaderLayout()
        end

        -- TabBar_OnDataChanged calls ExitHeader() before the tab callback, which
        -- deactivates the header focus but does NOT re-activate the list. Detect
        -- this state (header inactive + list inactive) and manually restore.
        local currentList = journalUI:GetCurrentList()
        if not journalUI:IsHeaderActive() and currentList and not currentList:IsActive() then
            local REQUESTED_BY_HEADER = true
            journalUI:ActivateCurrentList(REQUESTED_BY_HEADER)
        end
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
    elseif journalUI.mode == NAVIGATION_MODE.PIVOT then
        chronicler.refreshPivotList(journalUI)
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

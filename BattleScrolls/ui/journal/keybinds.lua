if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.journal = BattleScrolls.journal or {}

local journal = BattleScrolls.journal

---@class BattleScrolls_Journal_Keybinds
local keybinds = {}
journal.keybinds = keybinds

---Initializes all keybind strip descriptors and assigns them to the journalUI
---@param journalUI BattleScrolls_Journal_Gamepad
function keybinds.initializeKeybindStripDescriptors(journalUI)
    local NAVIGATION_MODE = BattleScrolls_Journal_NavigationMode
    local STATS_TAB = BattleScrolls_Journal_StatsTab
    local INSTANCE_TAB = BattleScrolls_Journal_InstanceTab
    local ENCOUNTER_TAB = BattleScrolls_Journal_EncounterTab

    -- Instance list keybinds
    journalUI.instanceKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local targetData = journalUI.instanceList:GetTargetData()
                ZO_ConveyorSceneFragment_SetMovingForward()
                if targetData and targetData.isSettings then
                    -- Navigate to settings
                    journalUI.mode = NAVIGATION_MODE.SETTINGS
                    journalUI:SetCurrentList(journalUI.settingsList)
                    journalUI:RefreshList()
                    journalUI:SetActiveKeybinds(journalUI.settingsKeybindStripDescriptor)
                elseif targetData and targetData.data then
                    -- Reset instance-related decoded fields when selecting a new instance
                    journalUI.abilityInfo = nil
                    journalUI.unitNames = nil
                    BattleScrolls.gc:RequestGC(5)
                    journalUI.selectedInstance = targetData.data
                    journalUI.mode = NAVIGATION_MODE.ENCOUNTERS
                    journalUI.selectedEncounterTab = ENCOUNTER_TAB.ALL  -- Reset to first tab when drilling down
                    journalUI.pendingTabIndex = 1  -- Will be applied by RefreshHeader
                    journalUI:SetCurrentList(journalUI.encounterList)
                    journalUI:RefreshList()
                    journalUI:SetActiveKeybinds(journalUI.encounterKeybindStripDescriptor)
                end
            end,
            enabled = function()
                local targetData = journalUI.instanceList:GetTargetData()
                return targetData ~= nil and (targetData.data ~= nil or targetData.isSettings)
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                ZO_ConveyorSceneFragment_SetMovingForward()
                SCENE_MANAGER:HideCurrentScene()
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
        {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = GetString(BATTLESCROLLS_DELETE),
            callback = function()
                journalUI:ShowDeleteInstanceDialog()
            end,
            visible = function()
                local targetData = journalUI.instanceList:GetTargetData()
                return targetData ~= nil and targetData.data ~= nil and not targetData.isSettings
            end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = function()
                local targetData = journalUI.instanceList:GetTargetData()
                if targetData and targetData.data and targetData.data.locked then
                    return GetString(SI_ITEM_ACTION_UNMARK_AS_LOCKED)
                end
                return GetString(SI_ITEM_ACTION_MARK_AS_LOCKED)
            end,
            callback = function()
                journalUI:ToggleInstanceLock()
            end,
            visible = function()
                local targetData = journalUI.instanceList:GetTargetData()
                return targetData ~= nil and targetData.data ~= nil and not targetData.isSettings
            end,
        },
    }

    -- Encounter list keybinds
    journalUI.encounterKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local targetData = journalUI.encounterList:GetTargetData()
                if targetData and targetData.data then
                    -- Reset encounter-related decoded fields when selecting a new encounter
                    journalUI.decodedEncounter = nil
                    journalUI.unitNames = nil  -- v7+: unitNames per-encounter
                    journalUI.arithmancer = nil
                    BattleScrolls.gc:RequestGC(5)
                    journalUI.selectedEncounter = targetData.data
                    journalUI.mode = NAVIGATION_MODE.STATS
                    journalUI.selectedTab = STATS_TAB.OVERVIEW  -- Reset to first tab when drilling down
                    -- Reset all filters when selecting a new encounter
                    journalUI:ResetAllFilters()
                    journalUI.pendingTabIndex = 1  -- Will be applied by RefreshHeader
                    ZO_ConveyorSceneFragment_SetMovingForward()
                    journalUI:SetCurrentList(journalUI.statsList)
                    journalUI:RefreshList()
                    journalUI:SetActiveKeybinds(journalUI.statsKeybindStripDescriptor)
                end
            end,
            enabled = function()
                local targetData = journalUI.encounterList:GetTargetData()
                return targetData ~= nil and targetData.data ~= nil
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                journalUI:NavigateToInstanceList()
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
        {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = GetString(BATTLESCROLLS_DELETE),
            callback = function()
                journalUI:ShowDeleteEncounterDialog()
            end,
            visible = function()
                local targetData = journalUI.encounterList:GetTargetData()
                return targetData ~= nil and targetData.data ~= nil
            end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
    }

    -- Stats view keybinds
    journalUI.statsKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                -- Leave group table if active
                local groupTable = journal.groupTable
                if groupTable and groupTable:IsActive() then
                    groupTable:Leave()
                    journalUI:SetActiveKeybinds(journalUI.statsKeybindStripDescriptor)
                    journalUI:ActivateCurrentList()
                end
                -- Hide group table
                if groupTable then
                    groupTable:Hide()
                end
                -- Deactivate any active horizontal list on the stats list before switching away
                journalUI:DeactivateSelectedSettingsControl()
                journalUI.mode = NAVIGATION_MODE.ENCOUNTERS
                journalUI.pendingTabIndex = journalUI.selectedEncounterTab or ENCOUNTER_TAB.ALL
                -- Clear encounter-related decoded data when going back
                -- (keep abilityInfo/unitNames since they're instance-level)
                journalUI.decodedEncounter = nil
                journalUI.arithmancer = nil
                BattleScrolls.gc:RequestGC(2)
                journalUI:ResetAllFilters()
                ZO_ConveyorSceneFragment_SetMovingBackward()
                journalUI:SetCurrentList(journalUI.encounterList)
                journalUI:RefreshList()
                journalUI:SetActiveKeybinds(journalUI.encounterKeybindStripDescriptor)
                -- Hide overview panel when leaving stats mode
                if journalUI.overviewPanel then
                    journalUI.overviewPanel:Hide()
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
        -- Filter keybind
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = function()
                if journalUI:HasActiveFilter() then
                    return GetString(BATTLESCROLLS_UI_FILTER_ACTIVE)
                end
                return GetString(BATTLESCROLLS_UI_FILTER)
            end,
            callback = function()
                journalUI:ShowFilterDialog()
            end,
            visible = function()
                -- Only show on tabs that support filtering
                return journalUI.selectedTab == STATS_TAB.DAMAGE_DONE
                    or journalUI.selectedTab == STATS_TAB.BOSS_DAMAGE_DONE
                    or journalUI.selectedTab == STATS_TAB.DAMAGE_TAKEN
                    or journalUI.selectedTab == STATS_TAB.HEALING_OUT
                    or journalUI.selectedTab == STATS_TAB.HEALING_IN
                    or journalUI.selectedTab == STATS_TAB.EFFECTS_GROUP
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Favorite effect keybind
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                local targetData = journalUI.statsList:GetTargetData()
                if targetData and targetData.isFavorite then
                    return GetString(BATTLESCROLLS_UNFAVORITE_EFFECT)
                end
                return GetString(BATTLESCROLLS_FAVORITE_EFFECT)
            end,
            callback = function()
                local targetData = journalUI.statsList:GetTargetData()
                if targetData and targetData.onFavoriteToggle then
                    -- Toggle storage via closure (captures abilityId internally)
                    targetData.onFavoriteToggle()
                    local wasFavorite = targetData.isFavorite
                    targetData.isFavorite = not wasFavorite
                    PlaySound(wasFavorite and SOUNDS.CHAMPION_STAR_STAGE_DOWN or SOUNDS.CHAMPION_STAR_STAGE_UP)

                    -- Re-run setup on visible controls so the star icon updates in place
                    journalUI.statsList:RefreshVisible()

                    -- Mark pending so the refresh keybind appears, but don't rebuild the list
                    journalUI.statsRefreshPending = true
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(journalUI.statsKeybindStripDescriptor)
                end
            end,
            visible = function()
                local targetData = journalUI.statsList:GetTargetData()
                return targetData and targetData.onFavoriteToggle ~= nil
            end,
        },
        {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = GetString(SI_GAMEPAD_GROUP_FINDER_SEARCH_RESULTS_REFRESH_KEYBIND),
            callback = function()
                journalUI:RefreshList(true)
            end,
            visible = function()
                return journalUI.statsRefreshPending or false
            end,
            sound = SOUNDS.GROUP_FINDER_REFRESH_SEARCH,
        },
        -- Enter group table
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local groupTable = journal.groupTable
                if groupTable then
                    journalUI:DeactivateCurrentList()
                    groupTable:Enter()
                    journalUI:SetActiveKeybinds(journalUI.groupTableKeybindDescriptor)
                end
            end,
            visible = function()
                local targetData = journalUI.statsList:GetTargetData()
                return targetData and targetData.tooltip and targetData.tooltip.type == "groupTable"
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Sub-view navigation indicators (D-pad left/right)
        -- INPUT_LEFT/RIGHT aren't in GAMEPAD_BUTTON_ORDER so they default to 0, appearing before BACK(2)/FILTER(3).
        -- gamepadOrder = 100 pushes them to the end.
        {
            gamepadOrder = 100,
            keybind = "UI_SHORTCUT_INPUT_LEFT",
            name = function()
                local rightIcon = ZO_Keybindings_GetHighestPriorityBindingStringFromAction("UI_SHORTCUT_INPUT_RIGHT", KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, true, false, BattleScrolls.constants.keybindIconScale) or ""
                local selectedTab = journalUI.selectedTab
                local groupKey = selectedTab and journal.TabToGroup[selectedTab]
                local decodedEncounter = journalUI.decodedEncounter
                if not groupKey or not decodedEncounter or not decodedEncounter._tabVisibility then
                    return ""
                end

                local visibleSubViews = journal.chronicler.getVisibleSubViews(groupKey, decodedEncounter._tabVisibility)
                local count = #visibleSubViews
                if count < 2 then return "" end

                -- Find current index in visible sub-views
                local currentIdx = 1
                for i, tab in ipairs(visibleSubViews) do
                    if tab == selectedTab then
                        currentIdx = i
                        break
                    end
                end

                local leftTab = visibleSubViews[currentIdx == 1 and count or (currentIdx - 1)]
                local rightTab = visibleSubViews[currentIdx == count and 1 or (currentIdx + 1)]

                local function viewName(tab)
                    local labelId = journal.SubViewLabels[tab]
                    return labelId and GetString(_G[labelId]) or ""
                end

                local leftName = zo_strformat(BATTLESCROLLS_UI_SWITCH_TO, viewName(leftTab))
                if leftTab == rightTab then
                    -- 2 sub-views: both directions go to the same tab
                    return string.format("%s %s", rightIcon, leftName)
                else
                    -- 3+ sub-views: different destinations for each direction
                    local rightName = zo_strformat(BATTLESCROLLS_UI_SWITCH_TO, viewName(rightTab))
                    return string.format("%s  %s %s", leftName, rightIcon, rightName)
                end
            end,
            callback = function() end,
            visible = function()
                return journal.subheader.visible or false
            end,
        },
    }

    -- Group table keybinds (active while inside the table)
    journalUI.groupTableKeybindDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                local groupTable = journal.groupTable
                if groupTable then
                    groupTable:Leave()
                end
                journalUI:SetActiveKeybinds(journalUI.statsKeybindStripDescriptor)
                journalUI:ActivateCurrentList()
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
    }

    -- Row select callback: leave table and jump to matching player entry in Q1 list
    local groupTable = journal.groupTable
    if groupTable then
        groupTable.onRowSelected = function(data)
            groupTable:Leave()
            journalUI:SetActiveKeybinds(journalUI.statsKeybindStripDescriptor)
            journalUI:ActivateCurrentList()

            -- Find matching player entry by displayName and select it
            local numItems = journalUI.statsList:GetNumItems()
            for i = 1, numItems do
                local entryData = journalUI.statsList:GetDataForDataIndex(i)
                if entryData and entryData.text == data.displayName then
                    journalUI.statsList:SetSelectedIndexWithoutAnimation(i)
                    break
                end
            end
        end
    end

    -- Helper to check if current control is a slider with dual-speed support
    local function GetSelectedSlider()
        local control = journalUI.settingsList:GetSelectedControl()
        if control then
            local slider = control:GetNamedChild("Slider")
            if slider and slider.SetFastMode then
                return slider
            end
        end
        return nil
    end

    -- Settings view keybinds
    journalUI.settingsKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Primary action: toggle for checkboxes, fast mode for sliders
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                local slider = GetSelectedSlider()
                if slider then
                    if slider.isFastMode then
                        return GetString(BATTLESCROLLS_SETTINGS_SLIDER_RELEASE_PRECISION)
                    else
                        return GetString(BATTLESCROLLS_SETTINGS_SLIDER_HOLD_FAST)
                    end
                end
                local targetData = journalUI.settingsList:GetTargetData()
                if targetData and targetData.callback then
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                end
                return GetString(SI_GAMEPAD_TOGGLE_OPTION)
            end,
            handlesKeyUp = true,
            callback = function(isKeyUp)
                -- Check if we're on a slider - use hold-to-fast behavior
                local slider = GetSelectedSlider()
                if slider then
                    slider:SetFastMode(not isKeyUp)  -- Press = fast on, release = fast off (back to precision)
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(journalUI.settingsKeybindStripDescriptor)
                    return
                end

                -- For non-sliders, only act on key down (not key up)
                if isKeyUp then
                    return
                end

                local targetData = journalUI.settingsList:GetTargetData()
                if targetData then
                    if targetData.toggleFunction then
                        targetData.toggleFunction()
                        journalUI:RefreshList()
                    elseif targetData.callback then
                        targetData.callback()
                    end
                end
            end,
            enabled = function()
                -- Enable for sliders (for fast mode) or for toggle/callback items
                local slider = GetSelectedSlider()
                if slider then
                    return true
                end
                local targetData = journalUI.settingsList:GetTargetData()
                return targetData ~= nil and (targetData.toggleFunction ~= nil or targetData.callback ~= nil)
            end,
            sound = SOUNDS.DEFAULT_CLICK,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                journalUI:DeactivateSelectedSettingsControl()
                journalUI.mode = NAVIGATION_MODE.INSTANCES
                journalUI.pendingTabIndex = journalUI.selectedInstanceTab or INSTANCE_TAB.ALL
                ZO_ConveyorSceneFragment_SetMovingBackward()
                journalUI:SetCurrentList(journalUI.instanceList)
                journalUI:RefreshList()
                journalUI:SetActiveKeybinds(journalUI.instanceKeybindStripDescriptor)
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
    }
end

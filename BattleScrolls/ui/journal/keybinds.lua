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
                elseif targetData and targetData.isPivot then
                    -- Navigate to Aggregate
                    journalUI.pivotSourceMode = NAVIGATION_MODE.INSTANCES
                    journalUI.pivotQuery = BattleScrolls.journal.pivot.defaultQuery()
                    journalUI.pivotSubState = BattleScrolls.journal.pivot.SubState.CONFIG
                    journalUI.mode = NAVIGATION_MODE.PIVOT
                    journalUI:SetCurrentList(journalUI.pivotConfigList)
                    journalUI:RefreshList()
                    journalUI:SetActiveKeybinds(journalUI.pivotConfigKeybindStripDescriptor)
                elseif targetData and targetData.data then
                    -- Reset instance-related decoded fields when selecting a new instance
                    journalUI.abilityInfo = nil
                    journalUI.unitNames = nil
                    BattleScrolls.gc:RequestGC(5)
                    journalUI.selectedInstance = targetData.data
                    journalUI.mode = NAVIGATION_MODE.ENCOUNTERS
                    journalUI.defaultEncounterPosition = 2  -- Skip Aggregate entry
                    journalUI.selectedEncounterTab = ENCOUNTER_TAB.ALL  -- Reset to first tab when drilling down
                    journalUI.pendingTabIndex = 1  -- Will be applied by RefreshHeader
                    journalUI:SetCurrentList(journalUI.encounterList)
                    journalUI:RefreshList()
                    journalUI:SetActiveKeybinds(journalUI.encounterKeybindStripDescriptor)
                end
            end,
            enabled = function()
                local targetData = journalUI.instanceList:GetTargetData()
                return targetData ~= nil and (targetData.data ~= nil or targetData.isSettings or targetData.isPivot)
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
                if targetData and targetData.isPivot then
                    -- Navigate to Aggregate, pre-fill with current instance
                    journalUI.pivotSourceMode = NAVIGATION_MODE.ENCOUNTERS
                    local query = BattleScrolls.journal.pivot.defaultQuery()
                    -- Pre-fill scope: specific instance (using stable instance.index)
                    query.scope.instanceMode = BattleScrolls.journal.pivot.InstanceMode.SPECIFIC
                    if journalUI.selectedInstance and journalUI.selectedInstance.index then
                        query.scope.instanceIds = { [journalUI.selectedInstance.index] = true }
                    end
                    journalUI.pivotQuery = query
                    journalUI.pivotSubState = BattleScrolls.journal.pivot.SubState.CONFIG
                    journalUI.mode = NAVIGATION_MODE.PIVOT
                    ZO_ConveyorSceneFragment_SetMovingForward()
                    journalUI:SetCurrentList(journalUI.pivotConfigList)
                    journalUI:RefreshList()
                    journalUI:SetActiveKeybinds(journalUI.pivotConfigKeybindStripDescriptor)
                elseif targetData and targetData.data then
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
                return targetData ~= nil and (targetData.data ~= nil or targetData.isPivot)
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                if journalUI.pivotReturnState == "encounters" then
                    -- Drilled from pivot results to encounter list — return to pivot
                    journalUI.pivotReturnState = nil
                    journalUI.selectedEncounter = nil
                    journalUI.selectedInstance = nil
                    journalUI.mode = NAVIGATION_MODE.PIVOT
                    journalUI.pivotSubState = BattleScrolls.journal.pivot.SubState.RESULTS
                    ZO_ConveyorSceneFragment_SetMovingBackward()
                    journalUI:SetCurrentList(journalUI.pivotConfigList)
                    journalUI:DeactivateCurrentList()
                    journalUI:SetActiveKeybinds(journalUI.pivotResultKeybindStripDescriptor)
                    journalUI:RefreshList()
                else
                    journalUI:NavigateToInstanceList()
                end
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
                -- Clear encounter-related decoded data
                journalUI.decodedEncounter = nil
                journalUI.arithmancer = nil
                BattleScrolls.gc:RequestGC(2)
                journalUI:ResetAllFilters()
                -- Hide overview panel when leaving stats mode
                if journalUI.overviewPanel then
                    journalUI.overviewPanel:Hide()
                end

                if journalUI.pivotReturnState == "stats" then
                    -- Drilled directly from pivot results to stats — return to pivot
                    BattleScrolls.journal.chronicler.resetTooltips()
                    journalUI.pivotReturnState = nil
                    journalUI.selectedEncounter = nil
                    journalUI.selectedInstance = nil
                    journalUI.mode = NAVIGATION_MODE.PIVOT
                    journalUI.pivotSubState = BattleScrolls.journal.pivot.SubState.RESULTS
                    ZO_ConveyorSceneFragment_SetMovingBackward()
                    journalUI:SetCurrentList(journalUI.pivotConfigList)
                    journalUI:DeactivateCurrentList()
                    journalUI:SetActiveKeybinds(journalUI.pivotResultKeybindStripDescriptor)
                    journalUI:RefreshList()
                else
                    journalUI.mode = NAVIGATION_MODE.ENCOUNTERS
                    journalUI.pendingTabIndex = journalUI.selectedEncounterTab or ENCOUNTER_TAB.ALL
                    ZO_ConveyorSceneFragment_SetMovingBackward()
                    journalUI:SetCurrentList(journalUI.encounterList)
                    journalUI:RefreshList()
                    journalUI:SetActiveKeybinds(journalUI.encounterKeybindStripDescriptor)
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

    -- Helper: get the loading label (cached)
    local function getPivotLoadingLabel()
        if journalUI._loadingLabel then return journalUI._loadingLabel end
        local overviewPane = journalUI.control:GetNamedChild("OverviewPane")
        if overviewPane then
            journalUI._loadingLabel = overviewPane:GetNamedChild("LoadingLabel")
        end
        return journalUI._loadingLabel
    end

    -- Forward declaration (zone/instance selectors reference openFieldSelector for re-open on cancel)
    local openFieldSelector

    -- Helper: open zone selector dialog
    local function openZoneSelector(query, previousMode)
        local pivotCfg = BattleScrolls.journal.pivot.configRenderer
        local zoneNames = pivotCfg.collectZoneNames()
        local items = {}
        for _, zone in ipairs(zoneNames) do
            table.insert(items, { key = zone, label = zone })
        end
        pivotCfg.showCheckboxDialog(
            GetString(BATTLESCROLLS_PIVOT_SELECT_ZONES),
            items,
            query.scope.instanceZones,
            function(selected)
                query.scope.instanceZones = selected
                journalUI:RefreshList()
            end,
            function()
                if previousMode then
                    query.scope.instanceMode = previousMode
                end
                journalUI:RefreshList()
            end,
            function() openFieldSelector("instanceScope", query) end
        )
    end

    -- Helper: open instance selector dialog
    local function openInstanceSelector(query, previousMode)
        local pivotCfg = BattleScrolls.journal.pivot.configRenderer
        local instances = pivotCfg.collectInstanceEntries()
        local items = {}
        for _, inst in ipairs(instances) do
            table.insert(items, { key = inst.index, label = inst.label })
        end
        pivotCfg.showCheckboxDialog(
            GetString(BATTLESCROLLS_PIVOT_SELECT_INSTANCES),
            items,
            query.scope.instanceIds,
            function(selected)
                query.scope.instanceIds = selected
                journalUI:RefreshList()
            end,
            function()
                if previousMode then
                    query.scope.instanceMode = previousMode
                end
                journalUI:RefreshList()
            end,
            function() openFieldSelector("instanceScope", query) end
        )
    end

    -- Helper: open encounter selector dialog (for specific encounters)
    local function openEncounterSelector(query, previousCategory)
        local pivotCfg = BattleScrolls.journal.pivot.configRenderer
        local encounters = pivotCfg.collectEncounters(query.scope)
        if #encounters == 0 then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString(BATTLESCROLLS_PIVOT_NO_ENCOUNTERS))
            if previousCategory then
                query.scope.encounterCategory = previousCategory
            end
            journalUI:RefreshList()
            return
        end
        local items = {}
        local lastInstanceLabel = nil
        for _, enc in ipairs(encounters) do
            local header = nil
            if enc.instanceLabel ~= lastInstanceLabel then
                header = enc.instanceLabel
                lastInstanceLabel = enc.instanceLabel
            end
            table.insert(items, { key = enc.key, label = enc.label, header = header })
        end
        pivotCfg.showCheckboxDialog(
            GetString(BATTLESCROLLS_PIVOT_SELECT_ENCOUNTERS),
            items,
            query.scope.encounterIds,
            function(selected)
                query.scope.encounterIds = selected
                journalUI:RefreshList()
            end,
            function()
                if previousCategory then
                    query.scope.encounterCategory = previousCategory
                end
                journalUI:RefreshList()
            end,
            function() openFieldSelector("encounterFilter", query) end
        )
    end

    -- Helper: open boss name selector dialog
    local function openBossSelector(query, previousCategory)
        local pivotCfg = BattleScrolls.journal.pivot.configRenderer
        local bossNames = pivotCfg.collectBossNames(query.scope)
        if #bossNames == 0 then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString(BATTLESCROLLS_PIVOT_NO_BOSSES))
            if previousCategory then
                query.scope.encounterCategory = previousCategory
            end
            journalUI:RefreshList()
            return
        end
        local items = {}
        for _, name in ipairs(bossNames) do
            table.insert(items, { key = name, label = zo_strformat(SI_UNIT_NAME, name) })
        end
        pivotCfg.showCheckboxDialog(
            GetString(BATTLESCROLLS_PIVOT_SELECT_BOSSES),
            items,
            query.scope.encounterBosses,
            function(selected)
                query.scope.encounterBosses = selected
                journalUI:RefreshList()
            end,
            function()
                if previousCategory then
                    query.scope.encounterCategory = previousCategory
                end
                journalUI:RefreshList()
            end,
            function() openFieldSelector("encounterFilter", query) end
        )
    end

    -- Helper: open values (metrics) multi-select dialog
    local function openValuesSelector(query)
        local pivotCfg = BattleScrolls.journal.pivot.configRenderer
        local pivot = BattleScrolls.journal.pivot
        local metrics = pivot.DomainMetrics[query.domain] or {}
        -- When Boss is a dimension in Group domain, only show boss-compatible metrics
        local bossFilter = query.domain == pivot.Domain.GROUP
            and (query.rowDimension == pivot.Dimension.BOSS or query.columnMode == pivot.Dimension.BOSS)
            and pivot.extractors.GROUP_BOSS_METRICS or nil
        local items = {}
        for _, metricId in ipairs(metrics) do
            if not bossFilter or bossFilter[metricId] then
                table.insert(items, { key = metricId, label = pivot.extractors.getMetricLabel(metricId) })
            end
        end

        -- Build current selection from query.metrics
        local currentSelection = {}
        for _, m in ipairs(query.metrics) do
            currentSelection[m] = true
        end

        local pendingState = {}
        for _, item in ipairs(items) do
            pendingState[item.key] = currentSelection[item.key] or false
        end

        local entries = pivotCfg.buildCheckboxEntries(items, pendingState)

        BattleScrolls.journal.dialogs.showParametricDialog({
            title = GetString(BATTLESCROLLS_PIVOT_SELECT_METRICS),
            parametricList = entries,
            onConfirm = function()
                -- Collect selected metrics in domain order, cap at 10
                local selected = {}
                for _, metricId in ipairs(metrics) do
                    if pendingState[metricId] then
                        table.insert(selected, metricId)
                        if #selected >= 10 then break end
                    end
                end
                -- Must keep at least one metric
                if #selected > 0 then
                    -- Reset aggregation when the primary metric changes
                    if selected[1] ~= query.metrics[1] then
                        query.aggregation = nil
                    end
                    query.metrics = selected
                end
                journalUI:RefreshList()
            end,
            onCancel = function() end,
            resetText = GetString(BATTLESCROLLS_PIVOT_SELECT_ALL),
            onReset = function()
                for key in pairs(pendingState) do
                    pendingState[key] = true
                end
            end,
            deselectAllText = GetString(BATTLESCROLLS_PIVOT_DESELECT_ALL),
            onDeselectAll = function()
                for key in pairs(pendingState) do
                    pendingState[key] = false
                end
            end,
        })
    end



    -- Field title mapping for single-select dialogs
    local FIELD_TITLES = {
        instanceScope = BATTLESCROLLS_PIVOT_INSTANCE_SCOPE,
        timeFilter = BATTLESCROLLS_PIVOT_TIME_FILTER,
        encounterFilter = BATTLESCROLLS_PIVOT_ENCOUNTER_FILTER,
        domain = BATTLESCROLLS_PIVOT_DOMAIN,
        targets = BATTLESCROLLS_PIVOT_TARGETS,
        rows = BATTLESCROLLS_PIVOT_ROWS,
        columns = BATTLESCROLLS_PIVOT_COLUMNS,
        values = BATTLESCROLLS_PIVOT_VALUES,
        aggregation = BATTLESCROLLS_PIVOT_AGGREGATION,
    }

    ---Open a single-select dialog for any config field, then handle post-select actions
    ---@param field string
    ---@param query PivotQuery
    function openFieldSelector(field, query)
        local pivotCfg = BattleScrolls.journal.pivot.configRenderer
        local pivotQ = BattleScrolls.journal.pivot.query
        local pivot = BattleScrolls.journal.pivot
        local options = pivotCfg.getFieldOptions(field, query)
        if #options == 0 then return end

        local currentValue = pivotQ.getCurrentFieldValue(query, field)
        local initialIndex = nil

        local entries = {}
        for i, opt in ipairs(options) do
            local isCurrent = opt.key == currentValue
            if isCurrent then initialIndex = i end

            table.insert(entries, {
                template = "ZO_GamepadMenuEntryTemplate",
                text = opt.label,
                icon = isCurrent and "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds" or nil,
                templateData = {
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    tooltipTitle = opt.label,
                    tooltipText = opt.tooltip,
                    callback = function(dialog)
                        -- "Custom..." time input opens a text dialog instead of applying directly
                        if field == "timeFilter" and opt.key == "custom" then
                            dialog.nextAction = function()
                                BattleScrolls.journal.dialogs.showTextInputDialog({
                                    title = GetString(BATTLESCROLLS_PIVOT_CUSTOM_RANGE_TITLE),
                                    mainText = GetString(BATTLESCROLLS_PIVOT_CUSTOM_DAYS_PROMPT),
                                    defaultText = "14",
                                    onConfirm = function(text)
                                        local days = tonumber(text)
                                        if days and days > 0 then
                                            days = math.min(math.floor(days), 9999)
                                            pivotQ.applyFieldSelection(query, "timeFilter", days)
                                            journalUI:RefreshList()
                                        end
                                    end,
                                })
                            end
                            PlaySound(SOUNDS.DIALOG_ACCEPT)
                            dialog:Hide()
                            return
                        end

                        -- Save previous value before applying (for revert on sub-dialog cancel)
                        local previousValue = pivotQ.getCurrentFieldValue(query, field)
                        pivotQ.applyFieldSelection(query, field, opt.key)

                        -- Queue sub-selector to open after this dialog fully closes
                        if field == "instanceScope" and opt.key == pivot.InstanceMode.ZONES then
                            dialog.nextAction = function() openZoneSelector(query, previousValue) end
                        elseif field == "instanceScope" and opt.key == pivot.InstanceMode.SPECIFIC then
                            dialog.nextAction = function() openInstanceSelector(query, previousValue) end
                        elseif field == "encounterFilter" and opt.key == pivot.EncounterCategory.SPECIFIC then
                            dialog.nextAction = function() openEncounterSelector(query, previousValue) end
                        elseif field == "encounterFilter" and opt.key == pivot.EncounterCategory.BOSS_NAMES then
                            dialog.nextAction = function() openBossSelector(query, previousValue) end
                        end

                        PlaySound(SOUNDS.DIALOG_ACCEPT)
                        dialog:Hide()
                        journalUI:RefreshList()
                    end,
                },
            })
        end

        BattleScrolls.journal.dialogs.showParametricDialog({
            title = GetString(FIELD_TITLES[field] or BATTLESCROLLS_PIVOT_QUERY),
            parametricList = entries,
            initialIndex = initialIndex,
            onConfirm = function() end,
            onCancel = function() end,
        })
    end

    -- Helper: generate auto name for save
    local function generateQueryName(query)
        return BattleScrolls.journal.pivot.configRenderer.describeQuery(query)
    end

    -- Pivot config keybinds
    journalUI.pivotConfigKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local targetData = journalUI.pivotConfigList:GetTargetData()
                if not targetData or not targetData.pivotField then return end

                local field = targetData.pivotField
                local query = journalUI.pivotQuery

                -- Multi-select fields open their own specialized dialogs
                if field == "values" and query.columnMode == BattleScrolls.journal.pivot.ColumnMode.METRICS then
                    openValuesSelector(query)
                else
                    -- All single-select fields open a selection dialog
                    openFieldSelector(field, query)
                end
            end,
            enabled = function()
                local targetData = journalUI.pivotConfigList:GetTargetData()
                return targetData ~= nil and targetData.pivotField ~= nil
            end,
            sound = SOUNDS.DEFAULT_CLICK,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                -- Cancel any running pivot query
                if journalUI.pivotFiber then
                    journalUI.pivotFiber:Cancel()
                    journalUI.pivotFiber = nil
                end
                BattleScrolls.journal.pivot.resultRenderer.hide()
                -- Hide loading label if visible
                local loadingLabel = getPivotLoadingLabel()
                if loadingLabel then loadingLabel:SetHidden(true) end
                -- Navigate back to source mode
                local sourceMode = journalUI.pivotSourceMode or NAVIGATION_MODE.INSTANCES
                journalUI.pivotQuery = nil
                journalUI.pivotResult = nil
                journalUI.pivotSourceMode = nil
                journalUI.pivotSubState = nil
                ZO_ConveyorSceneFragment_SetMovingBackward()
                if sourceMode == NAVIGATION_MODE.ENCOUNTERS then
                    journalUI.mode = NAVIGATION_MODE.ENCOUNTERS
                    journalUI:SetCurrentList(journalUI.encounterList)
                    journalUI:RefreshList()
                    journalUI:SetActiveKeybinds(journalUI.encounterKeybindStripDescriptor)
                else
                    journalUI.mode = NAVIGATION_MODE.INSTANCES
                    journalUI.pendingTabIndex = journalUI.selectedInstanceTab or 1
                    journalUI:SetCurrentList(journalUI.instanceList)
                    journalUI:RefreshList()
                    journalUI:SetActiveKeybinds(journalUI.instanceKeybindStripDescriptor)
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(BATTLESCROLLS_PIVOT_RUN),
            callback = function()
                local query = journalUI.pivotQuery
                if not query then return end

                -- Check scope for empty result (aggregation already updated by refresh)
                local scopedEncounters = BattleScrolls.journal.pivot.engine.resolveScope(query.scope)
                if #scopedEncounters == 0 then
                    -- Show "no encounters" message in the overview pane (stay in CONFIG for editing)
                    local loadingLabel = getPivotLoadingLabel()
                    if loadingLabel then
                        if journalUI.overviewPanel then
                            journalUI.overviewPanel.control:SetHidden(false)
                            journalUI.overviewPanel:ShowLoading()
                        end
                        loadingLabel:SetText(GetString(BATTLESCROLLS_PIVOT_NO_ENCOUNTERS))
                        loadingLabel:SetHidden(false)
                    end
                    PlaySound(SOUNDS.NEGATIVE_CLICK)
                    return
                end

                -- Switch to loading state (deactivate list, show only Back keybind)
                local pivotSubState = BattleScrolls.journal.pivot.SubState
                journalUI.pivotSubState = pivotSubState.LOADING
                BattleScrolls.journal.chronicler.resetTooltips()
                journalUI:DeactivateCurrentList()
                journalUI:SetActiveKeybinds(journalUI.pivotLoadingKeybindStripDescriptor)
                journalUI:RefreshList()

                -- Get loading label for progress updates
                local loadingLabel = getPivotLoadingLabel()

                -- Run the query
                local pivotEngine = BattleScrolls.journal.pivot.engine
                journalUI.pivotFiber = BattleScrolls.Effect.Async(function()
                    local result = pivotEngine.runQueryAsync(query, function(current, total)
                        if loadingLabel then
                            loadingLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_PIVOT_LOADING), current, total))
                        end
                    end):Await()
                    if result then
                        if #result.rows == 0 then
                            -- Return to config with "no data" message
                            journalUI.pivotSubState = pivotSubState.CONFIG
                            journalUI:ActivateCurrentList()
                            journalUI:SetActiveKeybinds(journalUI.pivotConfigKeybindStripDescriptor)
                            journalUI:RefreshList()
                            -- Show message after refresh (refresh hides the pane, so re-show)
                            if journalUI.overviewPanel then
                                journalUI.overviewPanel.control:SetHidden(false)
                                journalUI.overviewPanel:ShowLoading()
                            end
                            if loadingLabel then
                                loadingLabel:SetText(GetString(BATTLESCROLLS_PIVOT_NO_RESULTS))
                                loadingLabel:SetHidden(false)
                            end
                        else
                            journalUI.pivotResult = result
                            journalUI.pivotSubState = pivotSubState.RESULTS
                            journalUI:DeactivateCurrentList()
                            journalUI:SetActiveKeybinds(journalUI.pivotResultKeybindStripDescriptor)
                            journalUI:RefreshList()

                            -- Enable row drill-down for encounter/instance row dimensions
                            local pivotNs = BattleScrolls.journal.pivot
                            local rowDim = result.query.rowDimension
                            if rowDim == pivotNs.Dimension.ENCOUNTER or rowDim == pivotNs.Dimension.INSTANCE then
                                pivotNs.resultRenderer.setOnRowSelected(function(data)
                                    local history = BattleScrolls.storage.savedVariables.history
                                    local instIdx = data.instanceIndex
                                    if not instIdx or not history[instIdx] then return end
                                    local inst = history[instIdx]

                                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)

                                    if rowDim == pivotNs.Dimension.ENCOUNTER and data.encounterIndex then
                                        local enc = inst.encounters and inst.encounters[data.encounterIndex]
                                        if not enc then return end
                                        -- Navigate to encounter stats
                                        journalUI.decodedEncounter = nil
                                        journalUI.unitNames = nil
                                        journalUI.arithmancer = nil
                                        journalUI.abilityInfo = nil
                                        BattleScrolls.gc:RequestGC(5)
                                        journalUI.selectedInstance = inst
                                        journalUI.selectedEncounter = enc
                                        journalUI.mode = NAVIGATION_MODE.STATS
                                        journalUI.selectedTab = STATS_TAB.OVERVIEW
                                        journalUI:ResetAllFilters()
                                        journalUI.pendingTabIndex = 1
                                        journalUI.pivotReturnState = "stats"
                                        ZO_ConveyorSceneFragment_SetMovingForward()
                                        journalUI:SetCurrentList(journalUI.statsList)
                                        journalUI:RefreshList()
                                        journalUI:SetActiveKeybinds(journalUI.statsKeybindStripDescriptor)
                                    else
                                        -- Navigate to encounter list for this instance
                                        journalUI.abilityInfo = nil
                                        journalUI.unitNames = nil
                                        BattleScrolls.gc:RequestGC(5)
                                        journalUI.selectedInstance = inst
                                        journalUI.mode = NAVIGATION_MODE.ENCOUNTERS
                                        journalUI.defaultEncounterPosition = 1  -- no Aggregate entry when drilling from pivot
                                        journalUI.selectedEncounterTab = ENCOUNTER_TAB.ALL
                                        journalUI.pendingTabIndex = 1
                                        journalUI.pivotReturnState = "encounters"
                                        ZO_ConveyorSceneFragment_SetMovingForward()
                                        journalUI:SetCurrentList(journalUI.encounterList)
                                        journalUI:RefreshList()
                                        journalUI:SetActiveKeybinds(journalUI.encounterKeybindStripDescriptor)
                                    end

                                    -- Hide table after new view is set up (avoids flicker)
                                    pivotNs.resultRenderer.hide()
                                end)
                            else
                                pivotNs.resultRenderer.setOnRowSelected(nil)
                            end
                        end
                    end
                end):Ensure(function()
                    journalUI.pivotFiber = nil
                end):Run()
            end,
            sound = SOUNDS.POSITIVE_CLICK,
        },
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(BATTLESCROLLS_PIVOT_LOAD),
            callback = function()
                local savedQueries = BattleScrolls.journal.pivot.saved.listQueries()
                if #savedQueries == 0 then return end

                local function buildEntries()
                    local entries = {}
                    for _, queryName in ipairs(BattleScrolls.journal.pivot.saved.listQueries()) do
                        table.insert(entries, {
                            template = "ZO_GamepadMenuEntryTemplate",
                            text = queryName,
                            templateData = {
                                setup = ZO_SharedGamepadEntry_OnSetup,
                                callback = function(dialog)
                                    local loaded = BattleScrolls.journal.pivot.saved.loadQuery(queryName)
                                    if loaded then
                                        journalUI.pivotQuery = loaded
                                        PlaySound(SOUNDS.DIALOG_ACCEPT)
                                        dialog:Hide()
                                        journalUI:RefreshList()
                                    end
                                end,
                            },
                        })
                    end
                    return entries
                end

                BattleScrolls.journal.dialogs.showParametricDialog({
                    title = GetString(BATTLESCROLLS_PIVOT_LOAD_TITLE),
                    parametricList = buildEntries(),
                    onConfirm = function() end,
                    onCancel = function() end,
                    resetText = GetString(BATTLESCROLLS_PIVOT_DELETE_QUERY),
                    onReset = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        if not targetData then return end
                        local queryName = targetData.text
                        BattleScrolls.journal.pivot.saved.deleteQuery(queryName)
                        dialog.parametricList = buildEntries()
                        if #dialog.parametricList == 0 then
                            dialog:Hide()
                        end
                    end,
                })
            end,
            enabled = function()
                local savedQueries = BattleScrolls.journal.pivot.saved.listQueries()
                return #savedQueries > 0
            end,
            sound = SOUNDS.DEFAULT_CLICK,
        },
        {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = GetString(BATTLESCROLLS_PIVOT_SAVE),
            callback = function()
                local query = journalUI.pivotQuery
                if not query then return end

                local defaultName = generateQueryName(query)
                BattleScrolls.journal.dialogs.showTextInputDialog({
                    title = GetString(BATTLESCROLLS_PIVOT_SAVE_TITLE),
                    mainText = GetString(BATTLESCROLLS_PIVOT_SAVE_PROMPT),
                    defaultText = defaultName,
                    onConfirm = function(text)
                        local function doSave()
                            BattleScrolls.journal.pivot.saved.saveQuery(text, query)
                            journalUI:RefreshList()
                        end
                        if BattleScrolls.journal.pivot.saved.queryExists(text) then
                            BattleScrolls.journal.dialogs.showBasicDialog({
                                title = GetString(BATTLESCROLLS_PIVOT_SAVE_TITLE),
                                mainText = zo_strformat(GetString(BATTLESCROLLS_PIVOT_SAVE_OVERWRITE), text),
                                onConfirm = doSave,
                            })
                        else
                            doSave()
                        end
                    end,
                })
            end,
            sound = SOUNDS.DEFAULT_CLICK,
        },
    }

    -- Pivot loading keybinds (only Back to cancel)
    journalUI.pivotLoadingKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_CANCEL),
            callback = function()
                if journalUI.pivotFiber then
                    journalUI.pivotFiber:Cancel()
                    journalUI.pivotFiber = nil
                end
                local loadingLabel = getPivotLoadingLabel()
                if loadingLabel then loadingLabel:SetHidden(true) end
                if journalUI.overviewPanel then journalUI.overviewPanel:Hide() end
                journalUI.pivotSubState = BattleScrolls.journal.pivot.SubState.CONFIG
                journalUI:ActivateCurrentList()
                journalUI:SetActiveKeybinds(journalUI.pivotConfigKeybindStripDescriptor)
                journalUI:RefreshList()
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
    }

    -- Pivot result keybinds
    journalUI.pivotResultKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                BattleScrolls.journal.pivot.resultRenderer.hide()
                journalUI.pivotResult = nil
                journalUI.pivotSubState = BattleScrolls.journal.pivot.SubState.CONFIG
                journalUI:SetCurrentList(journalUI.pivotConfigList)
                journalUI:SetActiveKeybinds(journalUI.pivotConfigKeybindStripDescriptor)
                journalUI:RefreshList()
                journalUI:ActivateCurrentList()
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
    }

    -- Text search header keybinds (shown when the search bar has focus)
    journalUI.textSearchKeybindStripDescriptor = {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                journalUI:SetTextSearchFocused(true)
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(
        journalUI.textSearchKeybindStripDescriptor,
        GAME_NAVIGATION_TYPE_BUTTON,
        function()
            journalUI:RequestLeaveHeader()
        end
    )
end

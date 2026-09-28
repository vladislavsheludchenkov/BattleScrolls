---@diagnostic disable: undefined-field, inject-field -- the ESO Control/ZO_* API stubs are too incomplete for field checking in UI code
if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

local NAVIGATION_MODE = BattleScrolls.journal.NavigationMode
local STATS_TAB = BattleScrolls.journal.StatsTab
local INSTANCE_TAB = BattleScrolls.journal.InstanceTab
local ENCOUNTER_TAB = BattleScrolls.journal.EncounterTab

local function isEffectsTab(tab)
    return tab == STATS_TAB.EFFECTS_PLAYER or tab == STATS_TAB.EFFECTS_BOSS or tab == STATS_TAB.EFFECTS_GROUP
end

local canAddToMainMenu = false

-------------------------
-- BattleScrolls Journal UI (Gamepad)
-------------------------
---@diagnostic disable-next-line: undefined-doc-class -- ESO API base class not in type definitions
---@class BattleScrolls_Journal_Gamepad : ZO_Gamepad_ParametricList_Screen
---@field control Control The root control
---@field mode NavigationMode Current navigation mode
---@field selectedInstance Instance|nil Currently selected instance
---@field selectedEncounter CompactEncounter|nil Currently selected encounter (metadata)
---@field decodedEncounter DecodedEncounter|nil Decoded encounter data
---@field abilityInfo table<number, AbilityInfo>|nil Ability info cache
---@field unitNames table<number, string>|nil Unit names cache
---@field arithmancer ArithmancerInstance|nil Calculator instance
---@field selectedTab StatsTab|nil Currently selected stats tab
---@field selectedInstanceTab InstanceTab Selected instance filter tab
---@field selectedEncounterTab EncounterTab Selected encounter filter tab
---@field pendingTabIndex number|nil Tab index to select after refresh
---@field statsRefreshPending boolean|nil True if favorites changed and list can be re-sorted to account for it
---@field filters table<StatsTab, JournalFilters> Filter state by tab
---@field overviewPanel BattleScrolls_Journal_OverviewPanel|nil Overview panel instance
---@field instanceList ZO_ParametricScrollList Instance list control
---@field encounterList ZO_ParametricScrollList Encounter list control
---@field statsList ZO_ParametricScrollList Stats list control
---@field settingsList ZO_ParametricScrollList Settings list control
---@field whatsNewList ZO_ParametricScrollList Release history list
---@field pivotConfigList ZO_ParametricScrollList Pivot config list control
---@field pivotQuery PivotQuery|nil Current pivot query being configured
---@field pivotResult PivotResult|nil Current pivot result
---@field pivotSourceMode NavigationMode|nil Mode that launched pivot (for back navigation)
---@field pivotSubState number|nil Pivot sub-state (CONFIG or RESULTS)
---@field pivotFiber Effect|nil Running pivot query fiber
---@field pivotReturnState string|nil "stats" or "encounters" — Back returns to pivot results
---@field keybindStripDescriptor table|nil Active keybind descriptor
---@field instanceKeybindStripDescriptor table Instance list keybinds
---@field encounterKeybindStripDescriptor table Encounter list keybinds
---@field statsKeybindStripDescriptor table Stats view keybinds
---@field settingsKeybindStripDescriptor table Settings view keybinds
---@field whatsNewKeybindStripDescriptor table Release history keybinds
---@field pivotConfigKeybindStripDescriptor table Pivot config keybinds
---@field pivotResultKeybindStripDescriptor table Pivot result keybinds
---@field textSearchKeybindStripDescriptor table Search header keybinds
---@field header Control Header control
---@field headerData table Header configuration
---@field defaultInstancePosition number|nil Default scroll position (instance list)
---@field defaultEncounterPosition number|nil Default scroll position (encounter list)
---@field lastSubView table<TabGroupKey, StatsTab> Remembered sub-view per tab group within session
BattleScrolls_Journal_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function BattleScrolls_Journal_Gamepad:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

-------------------------
-- Main Menu Integration
-------------------------
local function AddToMainMenu()
    local menuData = {
        name = GetString(BATTLESCROLLS_UI_NAME),
        icon = "EsoUI/Art/TreeIcons/Gamepad/gp_tutorial_idexIcon_combat.dds",
        scene = "battleScrollsJournalGamepad",
    }

    local entry = ZO_GamepadEntryData:New(menuData.name, menuData.icon)
    entry:SetIconTintOnSelection(true)
    entry:SetIconDisabledTintOnSelection(true)
    entry.data = menuData
    entry.id = 998 -- High number to avoid conflicts

    -- Find Journal entry and add as submenu item
    local journalEntry = nil
    for _, v in ipairs(ZO_MENU_ENTRIES) do
        if v.id == ZO_MENU_MAIN_ENTRIES.JOURNAL then
            journalEntry = v
            break
        end
    end

    if journalEntry and journalEntry.subMenu then
        table.insert(journalEntry.subMenu, entry)
    else
        -- Fallback: add to main menu
        table.insert(ZO_MENU_ENTRIES, entry)
    end

    if MAIN_MENU_GAMEPAD then
        MAIN_MENU_GAMEPAD:RefreshLists()
        MAIN_MENU_GAMEPAD:UpdateEntryEnabledStates()
    end

    canAddToMainMenu = false
end

function BattleScrolls_Journal_Gamepad:Initialize(control)
    self.control = control
    self.defaultInstancePosition = 4  -- First instance, after What's New, Settings and Aggregate
    self.defaultEncounterPosition = 2  -- Skip Aggregate entry

    LibEffect.Async(function()
        LibEffect.Sleep(1850):Await()

        -- Initialize overview panel (before fragment/scene so it's available
        -- to character stats integration before the Journal is ever opened)
        local overviewPane = control:GetNamedChild("OverviewPane")
        if overviewPane and BattleScrolls_Journal_OverviewPanel then
            self.overviewPanel = BattleScrolls_Journal_OverviewPanel:New(overviewPane)
        end

        -- Create fragment
        BATTLESCROLLS_JOURNAL_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
        BATTLESCROLLS_JOURNAL_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(_oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                -- Failsafe: restore panel parent if it was re-parented away
                -- (e.g. by character stats integration)
                if self.overviewPanel then
                    self.overviewPanel:RestoreParent()
                end

                -- Check if onboarding needs to be shown
                if BattleScrolls.onboarding and BattleScrolls.onboarding:NeedsOnboarding() then
                    BattleScrolls.onboarding:Show(function()
                        -- Callback: refresh journal after onboarding completes
                        self:RefreshList(true)
                    end)
                    return -- Don't initialize the normal journal UI
                end

                self.mode = NAVIGATION_MODE.INSTANCES
                self.selectedInstance = nil
                self.selectedEncounter = nil
                self.decodedEncounter = nil
                self.abilityInfo = nil
                self.unitNames = nil
                self.arithmancer = nil
                BattleScrolls.gc:RequestGC(5)
                self.selectedTab = nil
                self.lastSubView = {}
                self.selectedInstanceTab = INSTANCE_TAB.ALL
                self.selectedEncounterTab = ENCOUNTER_TAB.ALL
                self.pendingTabIndex = 1  -- Start at first tab
                self:ResetAllFilters()
                if BattleScrolls.shareUrl.isBusy() then
                    -- An upload chain survived a hide/re-show round-trip
                    -- (URL confirm, browser switch): land back on the stepper
                    self.mode = NAVIGATION_MODE.SHARE
                    self.shareSourceMode = nil
                    self:SetCurrentList(self.shareList)
                    self:RefreshList()
                    self:SetActiveKeybinds(self.shareKeybindStripDescriptor)
                else
                    self:SetCurrentList(self.instanceList)
                    self:RefreshList()
                    self:SetActiveKeybinds(self.instanceKeybindStripDescriptor)
                end
            elseif newState == SCENE_FRAGMENT_HIDDEN then
                self:ClearSearchText()
                self:ResetTooltips()
                -- Deactivate any active settings control to release DIRECTIONAL_INPUT
                self:DeactivateSelectedSettingsControl()
                -- Hide group table
                local groupTable = BattleScrolls.journal.groupTable
                if groupTable then
                    groupTable:Hide()
                end
                -- Cancel any in-progress async refresh before clearing its data
                if self.taskInProgress then
                    self.taskInProgress:Cancel()
                    self.taskInProgress = nil
                end
                -- Cancel pivot fiber if running
                if self.pivotFiber then
                    self.pivotFiber:Cancel()
                    self.pivotFiber = nil
                end
                -- Hide pivot result table
                BattleScrolls.journal.pivot.resultRenderer.hide()
                -- Clean up pivot state
                self.pivotQuery = nil
                self.pivotResult = nil
                self.pivotSourceMode = nil
                self.pivotSubState = nil
                self.pivotReturnState = nil
                -- Clean up decoded data and request GC when leaving journal
                self.decodedEncounter = nil
                self.abilityInfo = nil
                self.unitNames = nil
                self.arithmancer = nil
                BattleScrolls.gc:RequestGC(2)
            end
        end)
        LibEffect.YieldWithGC():Await()

        -- Create scene
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE = ZO_Scene:New("battleScrollsJournalGamepad", SCENE_MANAGER)
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(FRAME_TARGET_DISTANCE_GAMEPAD_FAR_FRAGMENT)
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(GAMEPAD_GENERIC_FOOTER_FRAGMENT)
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(BATTLESCROLLS_JOURNAL_GAMEPAD_FRAGMENT)

        -- Cancelling the cross-environment URL confirm with B forces the
        -- ingame scene manager to the base scene (see network/shareurl.lua
        -- header), tearing the journal down mid-share. Bring the stepper
        -- back so the chain is not stranded on the HUD.
        EVENT_MANAGER:RegisterForEvent("BattleScrolls_JournalShareKick", EVENT_REMOTE_SCENE_REQUEST,
            function(_, messageOrigin, requestType)
                if messageOrigin == SCENE_MANAGER_MESSAGE_ORIGIN_INTERNAL
                    and requestType == REMOTE_SCENE_REQUEST_TYPE_SHOW_BASE_SCENE
                    and self.mode == NAVIGATION_MODE.SHARE
                    and BattleScrolls.shareUrl.isBusy() then
                    zo_callLater(function()
                        if BattleScrolls.shareUrl.isBusy()
                            and not SCENE_MANAGER:IsShowing("battleScrollsJournalGamepad") then
                            SCENE_MANAGER:Show("battleScrollsJournalGamepad")
                        end
                    end, 400)
                end
            end)
        LibEffect.YieldWithGC():Await()

        -- Initialize base class
        local ACTIVATE_ON_SHOW = true
        ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, ACTIVATE_ON_SHOW, BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE)

        -- Enable gamepad input handling
        self:SetListsUseTriggerKeybinds(true)
        LibEffect.YieldWithGC():Await()

        if canAddToMainMenu then
            AddToMainMenu()
        end
    end):Run()
end

function BattleScrolls_Journal_Gamepad:OnDeferredInitialize()
    -- Initialize search bar before RefreshHeader so the header layout can see it
    self:AddSearch(
        self.textSearchKeybindStripDescriptor,
        function(_editBox)
            self:OnEffectsSearchTextChanged()
        end
    )
    self:SetTextSearchEntryHidden(true)

    self:RefreshHeader()
    self:InitializeLists()

    -- Initialize sub-header for tab group sub-navigation
    BattleScrolls.journal.subheader.initialize(self)
end

function BattleScrolls_Journal_Gamepad:PerformUpdate()
    self.dirty = false
end

-------------------------
-- Header
-------------------------
function BattleScrolls_Journal_Gamepad:RefreshHeader()
    self.headerData = {
        titleText = "",
        subtitleText = "",
        tabBarEntries = nil
    }

    if self.mode == NAVIGATION_MODE.INSTANCES then
        self.headerData.tabBarEntries = self:GetInstanceTabBarEntries()
    elseif self.mode == NAVIGATION_MODE.ENCOUNTERS and self.selectedInstance then
        self.headerData.tabBarEntries = self:GetEncounterListTabBarEntries()
    elseif self.mode == NAVIGATION_MODE.STATS and self.selectedEncounter and self.selectedInstance then
        self.headerData.tabBarEntries = self:GetEncounterTabBarEntries()
        self:buildStatsHeaderData()
    elseif self.mode == NAVIGATION_MODE.SETTINGS then
        self.headerData.titleText = GetString(BATTLESCROLLS_UI_NAME)
        self.headerData.subtitleText = GetString(BATTLESCROLLS_UI_SETTINGS)
    elseif self.mode == NAVIGATION_MODE.WHATS_NEW then
        self.headerData.titleText = GetString(BATTLESCROLLS_UI_NAME)
        self.headerData.subtitleText = GetString(BATTLESCROLLS_WHATS_NEW)
    elseif self.mode == NAVIGATION_MODE.SHARE then
        self.headerData.titleText = GetString(BATTLESCROLLS_UI_NAME)
        self.headerData.subtitleText = GetString(BATTLESCROLLS_SHARE_TITLE)
    elseif self.mode == NAVIGATION_MODE.PIVOT then
        self.headerData.titleText = GetString(BATTLESCROLLS_UI_NAME)
        local pivotSubState = self.pivotSubState or BattleScrolls.journal.pivot.SubState.CONFIG
        if pivotSubState == BattleScrolls.journal.pivot.SubState.RESULTS and self.pivotQuery then
            self.headerData.subtitleText = BattleScrolls.journal.pivot.configRenderer.describeQuery(self.pivotQuery)
        else
            self.headerData.subtitleText = GetString(BATTLESCROLLS_PIVOT_TITLE)
        end
    end

    if self.mode == NAVIGATION_MODE.STATS then
        ZO_GamepadGenericHeader_SetDataLayout(self.header, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE)
    end

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData, true)
    self:applyStatsHeaderLayout()
    self:refreshFooter()

    if self.headerData.tabBarEntries then
        if self.pendingTabIndex then
            ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, self.pendingTabIndex, true)
            self.pendingTabIndex = nil
        end
        ZO_GamepadGenericHeader_Activate(self.header)
    else
        ZO_GamepadGenericHeader_Deactivate(self.header)
    end

    -- Refresh sub-header (show/hide based on current tab group)
    BattleScrolls.journal.subheader.refresh(self)

    -- Show/hide search bar based on effects tab
    if self.textSearchHeaderControl then
        local showSearch = self.mode == NAVIGATION_MODE.STATS and isEffectsTab(self.selectedTab)
        self:SetTextSearchEntryHidden(not showSearch)
        if not showSearch then
            self:ClearSearchText()
        end
    end
end

---Builds header data pairs for the current stats tab.
function BattleScrolls_Journal_Gamepad:buildStatsHeaderData()
    self.headerData.data1HeaderText = GetString(BATTLESCROLLS_STAT_DURATION)
    self.headerData.data1Text = BattleScrolls.journal.utils.formatPreciseDuration(self.selectedEncounter.durationMs)
    if self.selectedEncounter.gameVersion then
        self.headerData.data2HeaderText = GetString(BATTLESCROLLS_STAT_PATCH)
        self.headerData.data2Text = self.selectedEncounter.gameVersion
    else
        self.headerData.data2HeaderText = nil
        self.headerData.data2Text = nil
    end
    self.headerData.data3HeaderText = nil
    self.headerData.data3Text = nil
end

---Re-anchors data pairs below the subheader when it is visible, and keeps the
---effects search box below the data pairs. Must be called after
---RefreshData / RefreshData since reflow resets DATA1HEADER anchors.
function BattleScrolls_Journal_Gamepad:applyStatsHeaderLayout()
    if self.mode ~= NAVIGATION_MODE.STATS then return end

    -- RefreshData reflow resets DATA1HEADER to the divider. When subheader is visible,
    -- re-anchor it below the subheader (same as subheader.refresh, which may be skipped
    -- during subtab navigation). Applies to all tab groups with sub-views.
    local subheader = BattleScrolls.journal.subheader
    if subheader.visible and subheader.control and subheader.data1Header then
        subheader.data1Header:ClearAnchors()
        subheader.data1Header:SetAnchor(BOTTOMLEFT, subheader.control, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)
        subheader.data1Header:SetAnchor(BOTTOMRIGHT, subheader.control, BOTTOMRIGHT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)
    end

    if not isEffectsTab(self.selectedTab) then return end

    -- RefreshData anchored search to DATA1HEADER (first match in anchor
    -- targets), which would overlap the value row — re-anchor below DATA1
    local data1 = self.header.controls[ZO_GAMEPAD_HEADER_CONTROLS.DATA1]
    if self.textSearchHeaderControl and data1 then
        self.textSearchHeaderControl:ClearAnchors()
        self.textSearchHeaderControl:SetAnchor(TOPLEFT, data1, BOTTOMLEFT, 0, 0)
    end
end

---Shows the account name in the generic footer (bottom right, like the main
---menu) while in stats mode; clears it elsewhere. Account only - history is
---account-wide and the recording character is not stored, so the current
---character's name would be wrong for encounters recorded on another one.
function BattleScrolls_Journal_Gamepad:refreshFooter()
    if self.mode == NAVIGATION_MODE.STATS then
        GAMEPAD_GENERIC_FOOTER:Refresh({
            data1HeaderText = GetString(BATTLESCROLLS_GROUP_COL_NAME),
            data1Text = BattleScrolls.utils.GetUndecoratedDisplayName(),
        })
    else
        GAMEPAD_GENERIC_FOOTER:Refresh({})
    end
end

function BattleScrolls_Journal_Gamepad:OnHiding()
    ZO_GamepadGenericHeader_Deactivate(self.header)
    BattleScrolls.journal.subheader.deactivate(self)
    -- The generic footer is shared with other scenes — leave it clean
    GAMEPAD_GENERIC_FOOTER:Refresh({})
end

-------------------------
-- Keybinds
-------------------------
function BattleScrolls_Journal_Gamepad:InitializeKeybindStripDescriptors()
    BattleScrolls.journal.keybinds.initializeKeybindStripDescriptors(self)
end

-------------------------
-- Ability Entry Setup (with icon frames)
-------------------------
local function BattleScrolls_AbilityEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    -- Call base setup first
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

    -- Get frame controls
    local edgeFrame = control:GetNamedChild("EdgeFrame")
    local circleFrame = control:GetNamedChild("CircleFrame")

    if not edgeFrame or not circleFrame then
        return
    end

    -- Check if icon path indicates a passive ability
    -- Use iconFile property set when creating entry (data:GetIcon() returns nil/empty)
    local isPassive = BattleScrolls.journal.utils.isPassiveIcon(data.iconFile)

    -- Show appropriate frame
    if isPassive then
        edgeFrame:SetHidden(true)
        circleFrame:SetHidden(false)
    else
        edgeFrame:SetHidden(false)
        circleFrame:SetHidden(true)
    end
end

local function getVengeancePerkEntryFramedIcon(control)
    if control.vengeanceFramedIcon then
        return control.vengeanceFramedIcon
    end

    local framedIcon = BattleScrolls.journal.utils.createVengeancePerkFramedIcon(control)
    framedIcon:SetAnchor(CENTER, control:GetNamedChild("Label"), LEFT, ZO_GAMEPAD_DEFAULT_LIST_ENTRY_ICON_X_OFFSET, 0)
    control.vengeanceFramedIcon = framedIcon
    return framedIcon
end

local function BattleScrolls_VengeancePerkEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

    local icon = control:GetNamedChild("Icon")
    if icon then
        icon:SetHidden(true)
    end

    if data.vengeanceSlotFlag ~= nil then
        local framedIcon = getVengeancePerkEntryFramedIcon(control)
        BattleScrolls.journal.utils.setupVengeancePerkFramedIcon(
            framedIcon,
            data.vengeanceSlotFlag,
            data.iconFile or "",
            ZO_GAMEPAD_DEFAULT_LIST_ENTRY_ICON_DIMENSION)
    elseif control.vengeanceFramedIcon then
        control.vengeanceFramedIcon:SetHidden(true)
    end
end

-------------------------
-- Lists
-------------------------
function BattleScrolls_Journal_Gamepad:InitializeLists()
    local function SetupList(list, noItemText)
        list:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
        -- Ability entry template with icon frames
        list:AddDataTemplate("BattleScrolls_AbilityEntryTemplate", BattleScrolls_AbilityEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("BattleScrolls_AbilityEntryTemplate", BattleScrolls_AbilityEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
        list:AddDataTemplate("BattleScrolls_VengeancePerkEntryTemplate", BattleScrolls_VengeancePerkEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("BattleScrolls_VengeancePerkEntryTemplate", BattleScrolls_VengeancePerkEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
        list:SetNoItemText(noItemText)
        list:SetReselectBehavior(ZO_PARAMETRIC_SCROLL_LIST_RESELECT_BEHAVIOR.RESELECT_OLD_INDEX)
    end

    self.instanceList = self:AddList("Instances", function(list)
        SetupList(list, GetString(BATTLESCROLLS_LIST_NO_DATA))
    end)
    self.encounterList = self:AddList("Encounters", function(list)
        SetupList(list, GetString(BATTLESCROLLS_LIST_NO_ENCOUNTERS))
    end)
    self.statsList = self:AddList("Stats", function(list)
        SetupList(list, GetString(BATTLESCROLLS_LIST_NO_STATS))
        -- Register horizontal list template for group tab's combat/build switcher
        local hList = BattleScrolls.journal.horizontalList
        list:AddDataTemplate("BattleScrolls_HorizontalListRow", hList.iconSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:SetDataTemplateReleaseFunction("BattleScrolls_HorizontalListRow", hList.release)
    end)
    self.settingsList = self:AddList("Settings", function(list)
        BattleScrolls.journal.settingsTemplates.setupSettingsList(list)
    end)
    self.whatsNewList = self:AddList("WhatsNew", function(list)
        SetupList(list, GetString(BATTLESCROLLS_LIST_NO_DATA))
    end)
    self.pivotConfigList = self:AddList("PivotConfig", function(list)
        SetupList(list, GetString(BATTLESCROLLS_PIVOT_NO_RESULTS))
    end)
    self.shareList = self:AddList("Share", function(list)
        SetupList(list, GetString(BATTLESCROLLS_LIST_NO_DATA))
    end)

    -- Header layout can change the viewport after Commit has culled its rows.
    -- Let ESO refresh visible controls and fade gradients when that happens,
    -- so entries above the selection appear without waiting for a scroll.
    for _, list in pairs(self.lists) do
        list:SetHandleDynamicViewProperties(true)
    end

    -- The share stepper re-renders on every transport transition (part fired,
    -- part settled, build finished/failed). It also restores the real keybind
    -- strip that the send keybind swaps for the in-flight B sink while a
    -- part's URL confirm is in flight.
    BattleScrolls.shareUrl.onStateChanged = function()
        if self.mode ~= NAVIGATION_MODE.SHARE
            or not SCENE_MANAGER:IsShowing("battleScrollsJournalGamepad") then
            return
        end
        self:RefreshList()
        if BattleScrolls.shareUrl.isSendBlocked() then
            -- Part still in flight (or a dialog owns input): keep the sink
            return
        end
        if self.keybindStripDescriptor ~= self.shareKeybindStripDescriptor then
            self:SetActiveKeybinds(self.shareKeybindStripDescriptor)
        else
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    self.mode = NAVIGATION_MODE.INSTANCES
end

-------------------------
-- Settings Control Management
-------------------------

---Deactivates the currently selected settings control (slider or horizontal list)
---and any active horizontal list on the stats list (group tab's combat/build switcher).
---Must be called when leaving settings/stats or hiding the scene to release DIRECTIONAL_INPUT.
function BattleScrolls_Journal_Gamepad:DeactivateSelectedSettingsControl()
    local selectedControl = self.settingsList:GetSelectedControl()
    if selectedControl then
        if selectedControl.slider then
            selectedControl.slider:SetActive(false)
            if selectedControl.slider.SetFastMode then
                selectedControl.slider:SetFastMode(false)
            end
        end
        if selectedControl.horizontalListObject then
            selectedControl.horizontalListObject:Deactivate()
        end
    end

    -- Also deactivate any horizontal list on the stats list (group tab entries)
    local statsControl = self.statsList:GetSelectedControl()
    if statsControl and statsControl.horizontalListObject then
        statsControl.horizontalListObject:Deactivate()
    end
end

-------------------------
-- Keybind Management
-------------------------
function BattleScrolls_Journal_Gamepad:SetActiveKeybinds(keybindDescriptor)
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
    self.keybindStripDescriptor = keybindDescriptor
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

-------------------------
-- Search
-------------------------

---Called when the search edit box text changes; refreshes effects list
function BattleScrolls_Journal_Gamepad:OnEffectsSearchTextChanged()
    if self.mode == NAVIGATION_MODE.STATS and isEffectsTab(self.selectedTab) then
        self:RefreshList(true)
    end
end

---Returns the current search text from the header edit box
---@return string
function BattleScrolls_Journal_Gamepad:GetSearchText()
    if self.textSearchHeaderFocus then
        return self.textSearchHeaderFocus:GetText()
    end
    return ""
end


-------------------------
-- Navigation Helpers
-------------------------

---Navigates back to the instance list
function BattleScrolls_Journal_Gamepad:NavigateToInstanceList()
    self.mode = NAVIGATION_MODE.INSTANCES
    self.selectedInstance = nil
    self.selectedEncounter = nil
    self.decodedEncounter = nil
    self.arithmancer = nil
    self.pendingTabIndex = self.selectedInstanceTab or INSTANCE_TAB.ALL
    ZO_ConveyorSceneFragment_SetMovingBackward()
    self:SetCurrentList(self.instanceList)
    self:RefreshList()
    self:SetActiveKeybinds(self.instanceKeybindStripDescriptor)
end

-------------------------
-- Delete Dialogs
-------------------------

---Shows delete instance confirmation dialog
function BattleScrolls_Journal_Gamepad:ShowDeleteInstanceDialog()
    local targetData = self.instanceList:GetTargetData()
    if not targetData or not targetData.data then return end

    local instance = targetData.data
    local storage = BattleScrolls.storage
    local utils = BattleScrolls.journal.utils

    -- Own and shared setups referenced by nothing else go with the instance
    local instanceSize = storage:EstimateInstanceSize(instance) + storage:EstimateOrphanedSetupBytes(instance.encounters)
    local totalBytes = storage:EstimateSavedSize().totalBytes
    local limitBytes = storage:GetSizeLimitBytes()
    local usagePercent = limitBytes > 0 and (totalBytes / limitBytes * 100) or 0

    local encounterCount = #instance.encounters
    local instanceName = string.format("%s (%d)", instance.customName or instance.zone, encounterCount)

    local mainText = table.concat({
        zo_strformat(GetString(BATTLESCROLLS_DELETE_INSTANCE_TEXT), instanceName),
        zo_strformat(GetString(BATTLESCROLLS_DELETE_MEMORY_FREE), utils.formatBytes(instanceSize)),
        zo_strformat(GetString(BATTLESCROLLS_DELETE_MEMORY_STATUS),
            utils.formatBytes(totalBytes), utils.formatBytes(limitBytes), string.format("%.0f", usagePercent)),
    }, "\n\n")

    BattleScrolls.journal.dialogs.showBasicDialog({
        title = GetString(BATTLESCROLLS_DELETE_INSTANCE_TITLE),
        mainText = mainText,
        warning = GetString(BATTLESCROLLS_DELETE_WARNING),
        confirmSound = SOUNDS.INVENTORY_DESTROY_JUNK,
        onConfirm = function()
            storage:DeleteInstance(instance.index)
            self:RefreshList()
        end,
    })
end

---Shows delete encounter confirmation dialog
function BattleScrolls_Journal_Gamepad:ShowDeleteEncounterDialog()
    local targetData = self.encounterList:GetTargetData()
    if not targetData or not targetData.data then return end

    local encounter = targetData.data
    local instance = self.selectedInstance
    local storage = BattleScrolls.storage
    local utils = BattleScrolls.journal.utils

    -- The last encounter takes its instance with it; setups referenced by
    -- nothing else go too
    local encounterSize = (#instance.encounters == 1 and storage:EstimateInstanceSize(instance)
        or storage:EstimateEncounterSize(encounter)) + storage:EstimateOrphanedSetupBytes({ encounter })
    local totalBytes = storage:EstimateSavedSize().totalBytes
    local limitBytes = storage:GetSizeLimitBytes()
    local usagePercent = limitBytes > 0 and (totalBytes / limitBytes * 100) or 0

    local encounterName = encounter.customName or encounter.displayName

    local mainText = table.concat({
        zo_strformat(GetString(BATTLESCROLLS_DELETE_ENCOUNTER_TEXT), encounterName),
        zo_strformat(GetString(BATTLESCROLLS_DELETE_MEMORY_FREE), utils.formatBytes(encounterSize)),
        zo_strformat(GetString(BATTLESCROLLS_DELETE_MEMORY_STATUS),
            utils.formatBytes(totalBytes), utils.formatBytes(limitBytes), string.format("%.0f", usagePercent)),
    }, "\n\n")

    BattleScrolls.journal.dialogs.showBasicDialog({
        title = GetString(BATTLESCROLLS_DELETE_ENCOUNTER_TITLE),
        mainText = mainText,
        warning = GetString(BATTLESCROLLS_DELETE_WARNING),
        confirmSound = SOUNDS.INVENTORY_DESTROY_JUNK,
        onConfirm = function()
            local _, instanceDeleted = storage:DeleteEncounter(instance, encounter)
            if instanceDeleted or #instance.encounters == 0 then
                self:NavigateToInstanceList()
            else
                self:RefreshList()
            end
        end,
    })
end

-------------------------
-- Rename Dialogs
-------------------------

---Shows rename dialog for the targeted instance. Entering the original zone
---name (or the same text) clears the custom name back to the default.
function BattleScrolls_Journal_Gamepad:ShowRenameInstanceDialog()
    local targetData = self.instanceList:GetTargetData()
    if not targetData or not targetData.data then return end

    local instance = targetData.data
    local defaultName = instance.zone or ""

    BattleScrolls.journal.dialogs.showTextInputDialog({
        title = GetString(BATTLESCROLLS_RENAME),
        mainText = zo_strformat(GetString(BATTLESCROLLS_RENAME_TEXT), defaultName),
        defaultText = instance.customName or defaultName,
        onConfirm = function(text)
            text = zo_strtrim(text)
            if text == "" or text == defaultName then
                instance.customName = nil
            else
                instance.customName = text
            end
            self:RefreshList()
        end,
    })
end

---Shows rename dialog for the targeted encounter. Entering the original
---display name (or the same text) clears the custom name back to the default.
function BattleScrolls_Journal_Gamepad:ShowRenameEncounterDialog()
    local targetData = self.encounterList:GetTargetData()
    if not targetData or not targetData.data then return end

    local encounter = targetData.data
    local defaultName = encounter.displayName or ""

    BattleScrolls.journal.dialogs.showTextInputDialog({
        title = GetString(BATTLESCROLLS_RENAME),
        mainText = zo_strformat(GetString(BATTLESCROLLS_RENAME_TEXT), defaultName),
        defaultText = encounter.customName or defaultName,
        onConfirm = function(text)
            text = zo_strtrim(text)
            if text == "" or text == defaultName then
                encounter.customName = nil
            else
                encounter.customName = text
            end
            self:RefreshList()
        end,
    })
end

-------------------------
-- Instance Lock
-------------------------

---Toggles the lock state of the selected instance
function BattleScrolls_Journal_Gamepad:ToggleInstanceLock()
    local targetData = self.instanceList:GetTargetData()
    if not targetData or not targetData.data then return end

    local instance = targetData.data
    local storage = BattleScrolls.storage

    if instance.locked then
        -- Unlock the instance
        storage:UnlockInstance(instance.index)
        PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
        self:RefreshList()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    else
        -- Try to lock the instance
        local success = storage:LockInstance(instance.index)
        if success then
            PlaySound(SOUNDS.INVENTORY_ITEM_LOCKED)
            self:RefreshList()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        else
            self:ShowLockErrorDialog(instance)
        end
    end
end

---Shows error dialog when locking would exceed storage limit
---@param instance Instance The instance that cannot be locked
function BattleScrolls_Journal_Gamepad:ShowLockErrorDialog(instance)
    local storage = BattleScrolls.storage
    local utils = BattleScrolls.journal.utils

    local instanceSize = storage:EstimateInstanceSize(instance)
    local lockedSize = storage:GetLockedInstancesSize()
    local limitBytes = storage:GetSizeLimitBytes()

    local mainText = table.concat({
        GetString(BATTLESCROLLS_LOCK_ERROR_TEXT),
        "",
        zo_strformat(GetString(BATTLESCROLLS_LOCK_LOCKED_SIZE), utils.formatBytes(lockedSize)),
        zo_strformat(GetString(BATTLESCROLLS_LOCK_INSTANCE_SIZE), utils.formatBytes(instanceSize)),
        zo_strformat(GetString(BATTLESCROLLS_LOCK_LIMIT), utils.formatBytes(limitBytes)),
    }, "\n")

    BattleScrolls.journal.dialogs.showBasicDialog({
        title = GetString(BATTLESCROLLS_LOCK_ERROR_TITLE),
        mainText = mainText,
        infoOnly = true,
    })
    PlaySound(SOUNDS.NEGATIVE_CLICK)
end

-------------------------
-- Chronicler Wrappers
-- These methods delegate to the chronicler module
-------------------------

function BattleScrolls_Journal_Gamepad:ResetTooltips()
    BattleScrolls.journal.chronicler.resetTooltips()
end

function BattleScrolls_Journal_Gamepad:OnTargetChanged(_list, selectedData)
    BattleScrolls.journal.chronicler.onTargetChanged(self, selectedData)
end

function BattleScrolls_Journal_Gamepad:RefreshTargetTooltip(selectedData)
    BattleScrolls.journal.chronicler.refreshTooltip(self, selectedData)
end

function BattleScrolls_Journal_Gamepad:GetInstanceTabBarEntries()
    return BattleScrolls.journal.chronicler.getInstanceTabBarEntries(self)
end

function BattleScrolls_Journal_Gamepad:GetEncounterListTabBarEntries()
    return BattleScrolls.journal.chronicler.getEncounterListTabBarEntries(self)
end

function BattleScrolls_Journal_Gamepad:GetEncounterTabBarEntries()
    return BattleScrolls.journal.chronicler.getEncounterTabBarEntries(self)
end

function BattleScrolls_Journal_Gamepad:RefreshList(skipHeaderRefresh)
    BattleScrolls.journal.chronicler.refreshList(self, skipHeaderRefresh)
end

-------------------------
-- Global XML Functions
-------------------------
function BattleScrolls_Journal_Gamepad_OnInitialized(control)
    BATTLESCROLLS_JOURNAL_GAMEPAD = BattleScrolls_Journal_Gamepad:New(control)
    BattleScrolls.journalUI = BATTLESCROLLS_JOURNAL_GAMEPAD
end

-------------------------
-- Filter Management
-- Filters are stored keyed by tab, with normalized keys (targetFilter, sourceFilter, groupFilter)
-------------------------

---Resets all filter state for the current encounter
function BattleScrolls_Journal_Gamepad:ResetAllFilters()
    self.filters = {}
    BattleScrolls.gc:RequestGC(5)
end

---Checks if the current tab has an active filter
---@return boolean
function BattleScrolls_Journal_Gamepad:HasActiveFilter()
    local tabFilters = self.filters and self.filters[self.selectedTab]
    if not tabFilters then
        return false
    end
    -- Check if any filter value is non-nil
    for _, v in pairs(tabFilters) do
        if v ~= nil then
            return true
        end
    end
    return false
end

---Gets the filters for a specific tab
---@param tab number The stats tab constant
---@return table filters Table with normalized filter keys (targetFilter, sourceFilter, groupFilter)
function BattleScrolls_Journal_Gamepad:GetFiltersForTab(tab)
    return self.filters and self.filters[tab] or {}
end

---Sets the filters for a specific tab
---@param tab number The stats tab constant
---@param filters table Table with normalized filter keys (targetFilter, sourceFilter, groupFilter)
function BattleScrolls_Journal_Gamepad:SetFiltersForTab(tab, filters)
    self.filters = self.filters or {}
    self.filters[tab] = filters
    BattleScrolls.gc:RequestGC()
end

---Shows the filter dialog for the current tab
function BattleScrolls_Journal_Gamepad:ShowFilterDialog()
    BattleScrolls.journal.filters.showDialog(self)
end

-- Register to add menu entry after player is activated
EVENT_MANAGER:RegisterForEvent("BattleScrolls_JournalUI", EVENT_PLAYER_ACTIVATED, function()
    local sceneExists = SCENE_MANAGER:GetScene("battleScrollsJournalGamepad") ~= nil
    if sceneExists then
        AddToMainMenu()
    else
        canAddToMainMenu = true
    end

    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_JournalUI", EVENT_PLAYER_ACTIVATED)
end)

-- Label widths are measured at render time; a resize changes glyph metrics
EVENT_MANAGER:RegisterForEvent("BattleScrolls_JournalUI_Resize", EVENT_SCREEN_RESIZED, function()
    local journalUI = BattleScrolls.journalUI
    if not journalUI or not SCENE_MANAGER:IsShowing("battleScrollsJournalGamepad") then
        return
    end
    local list = journalUI:GetCurrentList()
    if list then
        journalUI:RefreshTargetTooltip(list:GetTargetData())
    end
end)

-------------------------
-- LibHarvensAddonSettings Integration
-------------------------
-- If LibHarvensAddonSettings is present, register addon with a button to open our scene
if LibHarvensAddonSettings then
    local addonSettings = LibHarvensAddonSettings:AddAddon(GetString(BATTLESCROLLS_UI_NAME))

    -- Add a button that opens our scene
    addonSettings:AddSetting({
        type = LibHarvensAddonSettings.ST_BUTTON,
        label = BATTLESCROLLS_LIBHARVENS_OPEN_BUTTON,
        tooltip = function()
            -- Format the tooltip with the localized Journal menu name
            return zo_strformat(GetString(BATTLESCROLLS_LIBHARVENS_TOOLTIP), GetString(SI_MAIN_MENU_JOURNAL))
        end,
        buttonText = BATTLESCROLLS_LIBHARVENS_OPEN_BUTTON,
        clickHandler = function()
            -- Close the settings scene and open our scene
            SCENE_MANAGER:Show("battleScrollsJournalGamepad")
        end,
    })
end

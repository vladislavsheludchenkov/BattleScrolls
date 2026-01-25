if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

-------------------------
-- Navigation & Tab Constants (defined here, loaded first)
-------------------------
BattleScrolls_Journal_NavigationMode = {
    INSTANCES = 1,
    ENCOUNTERS = 2,
    STATS = 3,
    SETTINGS = 4,
}

BattleScrolls_Journal_StatsTab = {
    OVERVIEW = 1,
    BOSS_DAMAGE_DONE = 2,
    DAMAGE_DONE = 3,
    DAMAGE_TAKEN = 4,
    HEALING_OUT = 5,
    SELF_HEALING = 6,
    HEALING_IN = 7,
    EFFECTS = 8,
}

BattleScrolls_Journal_InstanceTab = {
    ALL = 1,
    INSTANCED = 2,
    OVERLAND = 3,
    HOUSE = 4,
    PVP = 5,
}

BattleScrolls_Journal_EncounterTab = {
    ALL = 1,
    BOSS = 2,
    TRASH = 3,
    PLAYER = 4,
    DUMMY = 5,
}

local NAVIGATION_MODE = BattleScrolls_Journal_NavigationMode
local STATS_TAB = BattleScrolls_Journal_StatsTab
local INSTANCE_TAB = BattleScrolls_Journal_InstanceTab
local ENCOUNTER_TAB = BattleScrolls_Journal_EncounterTab

-- Filter constants
local SELF_UNIT_ID = -1  -- Special ID for self in healing filters
local SELF_DISPLAY_NAME = "__SELF__"  -- Special key for self in effects filter

-- Export constants for other modules
BattleScrolls_Journal_FilterConstants = {
    SELF_UNIT_ID = SELF_UNIT_ID,
    SELF_DISPLAY_NAME = SELF_DISPLAY_NAME,
}

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
---@field filters table<StatsTab, JournalFilters> Filter state by tab
---@field overviewPanel BattleScrolls_Journal_OverviewPanel|nil Overview panel instance
---@field instanceList ZO_ParametricScrollList Instance list control
---@field encounterList ZO_ParametricScrollList Encounter list control
---@field statsList ZO_ParametricScrollList Stats list control
---@field settingsList ZO_ParametricScrollList Settings list control
---@field keybindStripDescriptor table|nil Active keybind descriptor
---@field instanceKeybindStripDescriptor table Instance list keybinds
---@field encounterKeybindStripDescriptor table Encounter list keybinds
---@field statsKeybindStripDescriptor table Stats view keybinds
---@field settingsKeybindStripDescriptor table Settings view keybinds
---@field header Control Header control
---@field headerData table Header configuration
---@field defaultInstancePosition number Default scroll position
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
    self.defaultInstancePosition = 2

    LibEffect.Sleep(1850):FlatMap(function()
        return LibEffect.Async(function()
            -- Create fragment
            BATTLESCROLLS_JOURNAL_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
            BATTLESCROLLS_JOURNAL_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(_oldState, newState)
                if newState == SCENE_FRAGMENT_SHOWING then
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
                    self.selectedInstanceTab = INSTANCE_TAB.ALL
                    self.selectedEncounterTab = ENCOUNTER_TAB.ALL
                    self.pendingTabIndex = 1  -- Start at first tab
                    self:ResetAllFilters()
                    self:SetCurrentList(self.instanceList)
                    self:RefreshList()
                    self:SetActiveKeybinds(self.instanceKeybindStripDescriptor)
                elseif newState == SCENE_FRAGMENT_HIDDEN then
                    self:ResetTooltips()
                    -- Deactivate any active settings control to release DIRECTIONAL_INPUT
                    self:DeactivateSelectedSettingsControl()
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
            BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
            BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(GAMEPAD_GENERIC_FOOTER_FRAGMENT)
            BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)
            BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(BATTLESCROLLS_JOURNAL_GAMEPAD_FRAGMENT)
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
        end)
    end):Run()
end

function BattleScrolls_Journal_Gamepad:OnDeferredInitialize()
    self:RefreshHeader()
    self:InitializeLists()

    -- Initialize overview panel (for stats screen right-side display)
    local overviewPane = self.control:GetNamedChild("OverviewPane")
    if overviewPane and BattleScrolls_Journal_OverviewPanel then
        self.overviewPanel = BattleScrolls_Journal_OverviewPanel:New(overviewPane)
    end
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
    elseif self.mode == NAVIGATION_MODE.SETTINGS then
        self.headerData.titleText = GetString(BATTLESCROLLS_UI_NAME)
        self.headerData.subtitleText = GetString(BATTLESCROLLS_UI_SETTINGS)
    end

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData, true)

    if self.headerData.tabBarEntries then
        if self.pendingTabIndex then
            ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, self.pendingTabIndex, true)
            self.pendingTabIndex = nil
        end
        ZO_GamepadGenericHeader_Activate(self.header)
    else
        ZO_GamepadGenericHeader_Deactivate(self.header)
    end
end

function BattleScrolls_Journal_Gamepad:OnHiding()
    ZO_GamepadGenericHeader_Deactivate(self.header)
end

-------------------------
-- Keybinds
-------------------------
function BattleScrolls_Journal_Gamepad:InitializeKeybindStripDescriptors()
    -- Instance list keybinds
    self.instanceKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local targetData = self.instanceList:GetTargetData()
                ZO_ConveyorSceneFragment_SetMovingForward()
                if targetData and targetData.isSettings then
                    -- Navigate to settings
                    self.mode = NAVIGATION_MODE.SETTINGS
                    self:SetCurrentList(self.settingsList)
                    self:RefreshList()
                    self:SetActiveKeybinds(self.settingsKeybindStripDescriptor)
                elseif targetData and targetData.data then
                    -- Reset instance-related decoded fields when selecting a new instance
                    self.abilityInfo = nil
                    self.unitNames = nil
                    BattleScrolls.gc:RequestGC(5)
                    self.selectedInstance = targetData.data
                    self.mode = NAVIGATION_MODE.ENCOUNTERS
                    self.selectedEncounterTab = ENCOUNTER_TAB.ALL  -- Reset to first tab when drilling down
                    self.pendingTabIndex = 1  -- Will be applied by RefreshHeader
                    self:SetCurrentList(self.encounterList)
                    self:RefreshList()
                    self:SetActiveKeybinds(self.encounterKeybindStripDescriptor)
                end
            end,
            enabled = function()
                local targetData = self.instanceList:GetTargetData()
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
                self:ShowDeleteInstanceDialog()
            end,
            visible = function()
                local targetData = self.instanceList:GetTargetData()
                return targetData ~= nil and targetData.data ~= nil and not targetData.isSettings
            end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = function()
                local targetData = self.instanceList:GetTargetData()
                if targetData and targetData.data and targetData.data.locked then
                    return GetString(SI_ITEM_ACTION_UNMARK_AS_LOCKED)
                end
                return GetString(SI_ITEM_ACTION_MARK_AS_LOCKED)
            end,
            callback = function()
                self:ToggleInstanceLock()
            end,
            visible = function()
                local targetData = self.instanceList:GetTargetData()
                return targetData ~= nil and targetData.data ~= nil and not targetData.isSettings
            end,
        },
    }

    -- Encounter list keybinds
    self.encounterKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local targetData = self.encounterList:GetTargetData()
                if targetData and targetData.data then
                    -- Reset encounter-related decoded fields when selecting a new encounter
                    self.decodedEncounter = nil
                    self.unitNames = nil  -- v7+: unitNames per-encounter
                    self.arithmancer = nil
                    BattleScrolls.gc:RequestGC(5)
                    self.selectedEncounter = targetData.data
                    self.mode = NAVIGATION_MODE.STATS
                    self.selectedTab = STATS_TAB.OVERVIEW  -- Reset to first tab when drilling down
                    -- Reset all filters when selecting a new encounter
                    self:ResetAllFilters()
                    self.pendingTabIndex = 1  -- Will be applied by RefreshHeader
                    ZO_ConveyorSceneFragment_SetMovingForward()
                    self:SetCurrentList(self.statsList)
                    self:RefreshList()
                    self:SetActiveKeybinds(self.statsKeybindStripDescriptor)
                end
            end,
            enabled = function()
                local targetData = self.encounterList:GetTargetData()
                return targetData ~= nil and targetData.data ~= nil
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                self:NavigateToInstanceList()
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
        {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = GetString(BATTLESCROLLS_DELETE),
            callback = function()
                self:ShowDeleteEncounterDialog()
            end,
            visible = function()
                local targetData = self.encounterList:GetTargetData()
                return targetData ~= nil and targetData.data ~= nil
            end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
    }

    -- Stats view keybinds
    self.statsKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                self.mode = NAVIGATION_MODE.ENCOUNTERS
                self.pendingTabIndex = self.selectedEncounterTab or ENCOUNTER_TAB.ALL
                -- Clear encounter-related decoded data when going back
                -- (keep abilityInfo/unitNames since they're instance-level)
                self.decodedEncounter = nil
                self.arithmancer = nil
                BattleScrolls.gc:RequestGC(2)
                self:ResetAllFilters()
                ZO_ConveyorSceneFragment_SetMovingBackward()
                self:SetCurrentList(self.encounterList)
                self:RefreshList()
                self:SetActiveKeybinds(self.encounterKeybindStripDescriptor)
                -- Hide overview panel when leaving stats mode
                if self.overviewPanel then
                    self.overviewPanel:Hide()
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
        -- Filter keybind
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = function()
                if self:HasActiveFilter() then
                    return GetString(BATTLESCROLLS_UI_FILTER_ACTIVE)
                end
                return GetString(BATTLESCROLLS_UI_FILTER)
            end,
            callback = function()
                self:ShowFilterDialog()
            end,
            visible = function()
                -- Only show on tabs that support filtering
                return self.selectedTab == STATS_TAB.DAMAGE_DONE
                    or self.selectedTab == STATS_TAB.BOSS_DAMAGE_DONE
                    or self.selectedTab == STATS_TAB.DAMAGE_TAKEN
                    or self.selectedTab == STATS_TAB.HEALING_OUT
                    or self.selectedTab == STATS_TAB.HEALING_IN
                    or self.selectedTab == STATS_TAB.EFFECTS
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }

    -- Helper to check if current control is a slider with dual-speed support
    local function GetSelectedSlider()
        local control = self.settingsList:GetSelectedControl()
        if control then
            local slider = control:GetNamedChild("Slider")
            if slider and slider.SetFastMode then
                return slider
            end
        end
        return nil
    end

    -- Settings view keybinds
    self.settingsKeybindStripDescriptor = {
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
                local targetData = self.settingsList:GetTargetData()
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
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.settingsKeybindStripDescriptor)
                    return
                end

                -- For non-sliders, only act on key down (not key up)
                if isKeyUp then
                    return
                end

                local targetData = self.settingsList:GetTargetData()
                if targetData then
                    if targetData.toggleFunction then
                        targetData.toggleFunction()
                        self:RefreshList()
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
                local targetData = self.settingsList:GetTargetData()
                return targetData ~= nil and (targetData.toggleFunction ~= nil or targetData.callback ~= nil)
            end,
            sound = SOUNDS.DEFAULT_CLICK,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                self:DeactivateSelectedSettingsControl()
                self.mode = NAVIGATION_MODE.INSTANCES
                self.pendingTabIndex = self.selectedInstanceTab or INSTANCE_TAB.ALL
                ZO_ConveyorSceneFragment_SetMovingBackward()
                self:SetCurrentList(self.instanceList)
                self:RefreshList()
                self:SetActiveKeybinds(self.instanceKeybindStripDescriptor)
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
    }
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
        list:SetNoItemText(noItemText)
        list:SetReselectBehavior(ZO_PARAMETRIC_SCROLL_LIST_RESELECT_BEHAVIOR.RESELECT_OLD_INDEX)
    end

    local function SetupSettingsList(list)
        -- Custom checkbox setup that mimics native options but uses our data
        local function CheckboxSetup(control, data, selected, _reselectingDuringRebuild, _enabled, _active)
            control.data = data

            -- Set up the name label
            local nameControl = control:GetNamedChild("Name")
            if nameControl then
                nameControl:SetText(data.text or "")
            end

            -- Get current value
            local currentValue = data.getFunction and data.getFunction() or false

            -- Set up checkbox state
            local checkBoxControl = control:GetNamedChild("Checkbox")
            if checkBoxControl then
                ZO_CheckButton_SetCheckState(checkBoxControl, currentValue)
                checkBoxControl.selected = selected
                checkBoxControl:SetHidden(selected)
            end

            -- Set up On/Off labels (gamepad style)
            local onLabel = control:GetNamedChild("On")
            local offLabel = control:GetNamedChild("Off")
            if onLabel and offLabel then
                onLabel:SetHidden(not selected)
                offLabel:SetHidden(not selected)
                onLabel:SetColor((currentValue and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT):UnpackRGBA())
                offLabel:SetColor((currentValue and ZO_DISABLED_TEXT or ZO_SELECTED_TEXT):UnpackRGBA())
            end

            -- Handle visual state
            local color = ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, false)
            if nameControl then
                nameControl:SetColor(color:UnpackRGBA())
            end
            control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
        end

        -- Custom slider setup with dual-speed mode support
        local function SliderSetup(control, data, selected, _reselectingDuringRebuild, enabled, _active)
            control.data = data

            -- Set up the name label
            local nameControl = control:GetNamedChild("Name")
            if nameControl then
                nameControl:SetText(data.text or "")
            end

            -- Get slider control
            local slider = control:GetNamedChild("Slider")
            if slider then
                -- Remove handler during setup to prevent callbacks
                slider:SetHandler("OnValueChanged", nil)

                -- Set min/max
                slider:SetMinMax(data.minValue or 0, data.maxValue or 100)

                -- Calculate step values for dual-speed mode
                local range = (data.maxValue or 100) - (data.minValue or 0)
                local precisionStepPercent = data.gamepadValueStepPercent or 0.5
                local fastStepPercent = data.gamepadValueStepPercentFast or 5
                local precisionStep = range * (precisionStepPercent / 100)
                local fastStep = range * (fastStepPercent / 100)

                -- Store step values on slider for dynamic switching
                slider.precisionStep = precisionStep
                slider.fastStep = fastStep
                slider.isFastMode = false

                -- Default to precision step (fine control by default)
                slider:SetValueStep(precisionStep)

                -- Set current value
                local currentValue = data.getFunction and data.getFunction() or data.minValue
                slider:SetValue(currentValue)

                -- Set up value changed handler
                slider:SetHandler("OnValueChanged", function(_, value)
                    if data.setFunction then
                        data.setFunction(value)
                    end
                    -- Update value label
                    local valueLabelControl = control:GetNamedChild("ValueLabel")
                    if valueLabelControl then
                        valueLabelControl:SetText(string.format("%d", value))
                    end
                    -- Call onChange callback if defined
                    if data.onChangeFunction then
                        data.onChangeFunction(value)
                    end
                end)

                -- Method to toggle fast mode (hold for fast, release for precision)
                slider.SetFastMode = function(sliderSelf, isFast)
                    if sliderSelf.isFastMode ~= isFast then
                        sliderSelf.isFastMode = isFast
                        sliderSelf:SetValueStep(isFast and sliderSelf.fastStep or sliderSelf.precisionStep)
                    end
                end

                -- Activate/deactivate based on selection
                slider:SetActive(selected and enabled)
            end

            -- Set up value label
            local valueLabelControl = control:GetNamedChild("ValueLabel")
            if valueLabelControl then
                local currentValue = data.getFunction and data.getFunction() or data.minValue
                valueLabelControl:SetText(string.format("%d", currentValue))
            end

            -- Handle visual state
            local color = ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, false)
            if nameControl then
                nameControl:SetColor(color:UnpackRGBA())
            end
            control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
        end

        local function SliderRelease(control)
            local slider = control:GetNamedChild("Slider")
            if slider then
                slider:SetActive(false)
                if slider.SetFastMode then
                    slider:SetFastMode(false)  -- Reset to precision mode when released
                end
            end
        end

        -- Custom label/button setup for invoke callbacks
        local function LabelSetup(control, data, selected, _reselectingDuringRebuild, _enabled, _active)
            control.data = data

            -- Set up the name label
            local nameControl = control:GetNamedChild("Name")
            if nameControl then
                nameControl:SetText(data.text or "")
            end

            -- Handle visual state
            local color = ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, false)
            if nameControl then
                nameControl:SetColor(color:UnpackRGBA())
            end
            control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
        end

        -- Custom horizontal list setup for dropdown-style options
        -- Uses ZO_GamepadHorizontalListRow which has built-in horizontalListObject
        local function HorizontalListSetup(control, data, selected, _reselectingDuringRebuild, _enabled, _active)
            control.data = data

            -- Set up the name label (control.label is set by ZO_GamepadHorizontalListRow_Initialize)
            if control.label then
                control.label:SetText(data.text or "")
            end

            -- The template already creates control.horizontalListObject in OnInitialized
            local horizontalList = control.horizontalListObject
            if not horizontalList then
                return
            end

            -- Clear and populate the list
            horizontalList:Clear()
            local currentValue = data.getFunction and data.getFunction() or nil
            local selectedIndex = 1

            for i, option in ipairs(data.valid) do
                local entryData = {
                    text = data.valueStrings and data.valueStrings[i] or tostring(option),
                    value = option,
                    parentControl = control,
                }
                horizontalList:AddEntry(entryData)
                if option == currentValue then
                    selectedIndex = i
                end
            end

            -- Set up selection changed callback
            horizontalList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, reselecting)
                if oldData and not reselecting and selectedData then
                    if data.setFunction then
                        data.setFunction(selectedData.value)
                    end
                    if data.onChangeFunction then
                        data.onChangeFunction(selectedData.value)
                    end
                end
            end)

            horizontalList:Commit()
            local ALLOW_EVEN_IF_DISABLED = true
            local NO_ANIMATION = true
            horizontalList:SetSelectedDataIndex(selectedIndex, ALLOW_EVEN_IF_DISABLED, NO_ANIMATION)
            horizontalList:SetActive(selected)
            horizontalList:SetSelectedFromParent(selected)
            horizontalList:RefreshVisible(selected)

            -- Handle visual state
            local color = ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, false)
            if control.label then
                control.label:SetColor(color:UnpackRGBA())
            end
            control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
        end

        local function HorizontalListRelease(control)
            if control.horizontalListObject then
                control.horizontalListObject:Deactivate()
            end
        end

        list:AddDataTemplate("ZO_GamepadOptionsCheckboxRow", CheckboxSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "Checkbox")
        list:AddDataTemplateWithHeader("ZO_GamepadOptionsCheckboxRow", CheckboxSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsHeaderTemplate", nil, "CheckboxHeader")
        list:AddDataTemplate("ZO_GamepadOptionsSliderRow", SliderSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadOptionsSliderRow", SliderSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsHeaderTemplate", nil, "SliderHeader")
        list:SetDataTemplateReleaseFunction("ZO_GamepadOptionsSliderRow", SliderRelease)
        list:SetDataTemplateWithHeaderReleaseFunction("ZO_GamepadOptionsSliderRow", SliderRelease)
        list:AddDataTemplate("ZO_GamepadHorizontalListRow", HorizontalListSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadHorizontalListRow", HorizontalListSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsHeaderTemplate", nil, "HorizontalListHeader")
        list:SetDataTemplateReleaseFunction("ZO_GamepadHorizontalListRow", HorizontalListRelease)
        list:SetDataTemplateWithHeaderReleaseFunction("ZO_GamepadHorizontalListRow", HorizontalListRelease)
        list:AddDataTemplate("ZO_GamepadOptionsLabelRow", LabelSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:SetNoItemText(GetString(BATTLESCROLLS_LIST_NO_SETTINGS))
    end

    self.instanceList = self:AddList("Instances", function(list)
        SetupList(list, GetString(BATTLESCROLLS_LIST_NO_DATA))
    end)
    self.encounterList = self:AddList("Encounters", function(list)
        SetupList(list, GetString(BATTLESCROLLS_LIST_NO_ENCOUNTERS))
    end)
    self.statsList = self:AddList("Stats", function(list)
        SetupList(list, GetString(BATTLESCROLLS_LIST_NO_STATS))
    end)
    self.settingsList = self:AddList("Settings", function(list)
        SetupSettingsList(list)
    end)

    self.mode = NAVIGATION_MODE.INSTANCES
end

-------------------------
-- Settings Control Management
-------------------------

---Deactivates the currently selected settings control (slider or horizontal list)
---This must be called when leaving settings or hiding the scene to release DIRECTIONAL_INPUT
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

    local instanceSize = storage:EstimateInstanceSize(instance)
    local totalBytes, _, _ = storage:EstimateHistorySize()
    local preset = storage:GetCurrentSizePreset()
    local limitBytes = preset.memoryMB * 1000000
    local usagePercent = limitBytes > 0 and (totalBytes / limitBytes * 100) or 0

    local encounterCount = #instance.encounters
    local instanceName = string.format("%s (%d)", instance.zone, encounterCount)

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

    local encounterSize = storage:EstimateEncounterSize(encounter)
    local totalBytes, _, _ = storage:EstimateHistorySize()
    local preset = storage:GetCurrentSizePreset()
    local limitBytes = preset.memoryMB * 1000000
    local usagePercent = limitBytes > 0 and (totalBytes / limitBytes * 100) or 0

    local encounterName = encounter.displayName

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
    local preset = storage:GetCurrentSizePreset()
    local limitBytes = preset.memoryMB * 1000000

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

function BattleScrolls_Journal_Gamepad:RefreshInstanceList()
    BattleScrolls.journal.chronicler.refreshInstanceList(self)
end

function BattleScrolls_Journal_Gamepad:RefreshEncounterList()
    BattleScrolls.journal.chronicler.refreshEncounterList(self)
end

function BattleScrolls_Journal_Gamepad:RefreshStatsList()
    return BattleScrolls.journal.chronicler.refreshStatsList(self)
end

function BattleScrolls_Journal_Gamepad:RefreshSettingsList()
    BattleScrolls.journal.chronicler.refreshSettingsList(self)
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

---Resets the filter for the current tab
function BattleScrolls_Journal_Gamepad:ResetCurrentFilter()
    if self.filters then
        self.filters[self.selectedTab] = nil
    end
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

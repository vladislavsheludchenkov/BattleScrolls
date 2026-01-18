if not SemisPlaygroundCheckAccess() then
    return
end

-- =============================================================================
-- ONBOARDING SYSTEM (Quest-Dialogue Style)
-- =============================================================================
-- Non-intrusive first-time setup using a quest-dialogue inspired UI:
-- 1. On first login: show chat message directing to Journal
-- 2. When Journal is opened: show onboarding in quest-dialog style
-- 3. All features disabled by default until onboarding is completed

local onboarding = {}
BattleScrolls.onboarding = onboarding

-- Center offset matching ESO's interact window positioning
BS_ONBOARDING_CENTER_OFFSET = 15 + ZO_GAMEPAD_DEFAULT_LIST_ENTRY_SELECTED_HEIGHT / 2

-- Step definitions (used as step identifiers, not indices)
local STEP = {
    WELCOME = "welcome",
    METER = "meter",
    STORAGE = "storage",
    EFFECTS = "effects",
    COMPLETE = "complete",
}

-- Builds the list of steps to show
local function BuildActiveSteps()
    return { STEP.WELCOME, STEP.METER, STEP.STORAGE, STEP.EFFECTS, STEP.COMPLETE }
end

-------------------------
-- Preset String Mappings
-------------------------

local meterPresetStrings = {
    personal_minimal = { label = "BATTLESCROLLS_PRESET_PERSONAL_MINIMAL", desc = "BATTLESCROLLS_PRESET_PERSONAL_MINIMAL_DESC" },
    full_stacked = { label = "BATTLESCROLLS_PRESET_FULL_STACKED", desc = "BATTLESCROLLS_PRESET_FULL_STACKED_DESC" },
    hodor = { label = "BATTLESCROLLS_PRESET_HODOR", desc = "BATTLESCROLLS_PRESET_HODOR_DESC" },
    bar = { label = "BATTLESCROLLS_PRESET_BAR", desc = "BATTLESCROLLS_PRESET_BAR_DESC" },
    colorful = { label = "BATTLESCROLLS_PRESET_COLORFUL", desc = "BATTLESCROLLS_PRESET_COLORFUL_DESC" },
    disabled = { label = "BATTLESCROLLS_PRESET_DISABLED", desc = "BATTLESCROLLS_PRESET_DISABLED_DESC" },
}

-------------------------
-- Option Builders
-------------------------

local function BuildMeterOptions()
    local options = {}
    local storage = BattleScrolls.storage
    for _, presetKey in ipairs(storage.meterPresetOrder) do
        local strings = meterPresetStrings[presetKey]
        if strings then
            table.insert(options, {
                id = presetKey,
                label = GetString(_G[strings.label]),
                description = GetString(_G[strings.desc]),
            })
        end
    end
    return options
end

local function BuildStorageOptions()
    return {
        {
            id = "xs",
            label = GetString(BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL),
            description = GetString(BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC),
        },
        {
            id = "medium",
            label = GetString(BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE),
            description = GetString(BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC),
        },
        {
            id = "xl",
            label = GetString(BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS),
            description = GetString(BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC),
        },
    }
end

local function BuildEffectsOptions()
    return {
        {
            id = "full",
            label = GetString(BATTLESCROLLS_ONBOARDING_EFFECTS_FULL),
            description = GetString(BATTLESCROLLS_ONBOARDING_EFFECTS_FULL_DESC),
        },
        {
            id = "essential",
            label = GetString(BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL),
            description = GetString(BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL_DESC),
        },
        {
            id = "disabled",
            label = GetString(BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED),
            description = GetString(BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED_DESC),
        },
    }
end

local function BuildWelcomeOptions()
    return {
        {
            id = "start",
            label = GetString(BATTLESCROLLS_ONBOARDING_GET_STARTED),
            description = GetString(BATTLESCROLLS_ONBOARDING_GET_STARTED_DESC),
        },
        {
            id = "skip",
            label = GetString(BATTLESCROLLS_ONBOARDING_SKIP),
            description = GetString(BATTLESCROLLS_ONBOARDING_SKIP_DESC),
        },
    }
end

local function BuildCompleteOptions()
    return {
        {
            id = "done",
            label = GetString(BATTLESCROLLS_ONBOARDING_LETS_GO),
        },
    }
end

-- =============================================================================
-- ONBOARDING GAMEPAD CLASS
-- =============================================================================

BattleScrolls_Onboarding_Gamepad = ZO_Object:Subclass()

function BattleScrolls_Onboarding_Gamepad:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function BattleScrolls_Onboarding_Gamepad:Initialize(control)
    self.control = control
    self.initialized = false

    -- State tracking
    self.activeSteps = {}
    self.currentStepIndex = 1
    self.pendingPreset = nil
    self.pendingStoragePreset = nil
    self.pendingEffects = nil

    -- Completion callback (set by caller to avoid circular dependency)
    self.onCompleteCallback = nil

    -- Meter preview state
    self.savedMeterSettings = nil
    self.isPreviewActive = false

    -- Defer heavy initialization until actually needed
    -- This avoids loading game assets when onboarding isn't required
end

---Lazily initializes controls, scene, and keybinds on first use
function BattleScrolls_Onboarding_Gamepad:EnsureInitialized()
    if self.initialized then return end
    self.initialized = true

    self:InitializeControls()
    self:InitializeList()
    self:InitializeKeybinds()
    self:InitializeScene()
end

function BattleScrolls_Onboarding_Gamepad:InitializeControls()
    self.titleControl = self.control:GetNamedChild("Title")
    self.subtitleControl = self.control:GetNamedChild("Subtitle")

    local container = self.control:GetNamedChild("Container")
    self.containerControl = container
    self.textControl = container:GetNamedChild("Text")
    self.dividerControl = container:GetNamedChild("Divider")

    local optionsContainer = container:GetNamedChild("Options")
    self.listControl = optionsContainer:GetNamedChild("List")

    -- Setup step transition animation (fade out, update, fade in)
    self.stepTransitionTimeline = ANIMATION_MANAGER:CreateTimeline()

    local fadeOut = self.stepTransitionTimeline:InsertAnimation(ANIMATION_ALPHA, container, 0)
    fadeOut:SetAlphaValues(1.0, 0.0)
    fadeOut:SetDuration(150)
    fadeOut:SetEasingFunction(ZO_EaseOutQuadratic)

    local fadeIn = self.stepTransitionTimeline:InsertAnimation(ANIMATION_ALPHA, container, 150)
    fadeIn:SetAlphaValues(0.0, 1.0)
    fadeIn:SetDuration(150)
    fadeIn:SetEasingFunction(ZO_EaseInQuadratic)

    -- Refresh content at midpoint (when faded out)
    self.stepTransitionTimeline:SetHandler("OnStop", function()
        container:SetAlpha(1.0)
    end)
end

function BattleScrolls_Onboarding_Gamepad:InitializeList()
    self.itemList = ZO_GamepadVerticalItemParametricScrollList:New(self.listControl)

    -- Match interact window positioning
    ZO_GamepadQuadrants_SetBackgroundArrowCenterOffsetY(self.control:GetNamedChild("BG"), LEFT, BS_ONBOARDING_CENTER_OFFSET)
    self.itemList:SetFixedCenterOffset(BS_ONBOARDING_CENTER_OFFSET)
    self.itemList:SetSelectedItemOffsets(0, 10)
    self.itemList:SetAlignToScreenCenter(true)
    self.itemList:SetHandleDynamicViewProperties(true)
    self.itemList:SetDrawScrollArrows(true)

    -- Setup option template
    local function SetupOption(control, data, selected, _selectedDuringRebuild, _enabled, _activated)
        local labelControl = control:GetNamedChild("Text")
        local descControl = control:GetNamedChild("Description")

        -- Set label text and color
        labelControl:SetText(data.optionData.label)
        if selected then
            labelControl:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        else
            labelControl:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        end

        -- Show description only when selected
        if selected and data.optionData.description then
            descControl:SetText(data.optionData.description)
            descControl:SetHidden(false)
            -- Adjust control height to fit description
            local labelHeight = labelControl:GetTextHeight()
            local descHeight = descControl:GetTextHeight()
            control:SetHeight(labelHeight + descHeight + 8)
        else
            descControl:SetHidden(true)
            control:SetHeight(labelControl:GetTextHeight())
        end
    end

    self.itemList:AddDataTemplate("BattleScrolls_OnboardingOption_Gamepad", SetupOption, ZO_GamepadMenuEntryTemplateParametricListFunction)

    -- Selection change callback - refresh to update description visibility and meter preview
    self.itemList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        list:RefreshVisible()
        -- Update meter preview when on METER step
        if self:GetCurrentStep() == STEP.METER and selectedData and selectedData.optionData then
            self:UpdateMeterPreview(selectedData.optionData.id)
        end
    end)

    -- Setup narration for accessibility
    local narrationInfo = {
        canNarrate = function()
            return self.scene:IsShowing()
        end,
        headerNarrationFunction = function()
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(BATTLESCROLLS_UI_NAME))
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.itemList, narrationInfo)
end

function BattleScrolls_Onboarding_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
    }

    -- Primary action: Select and advance
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON,
        function() -- callback
            self:SelectCurrentOption()
        end,
        function() -- name
            if self:IsLastStep() then
                return GetString(BATTLESCROLLS_ONBOARDING_FINISH)
            else
                return GetString(BATTLESCROLLS_ONBOARDING_CONTINUE)
            end
        end,
        nil, -- visible
        nil  -- enabled
    )

    -- Back action: Cancel onboarding
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON,
        function()
            self:Cancel()
        end
    )
end

function BattleScrolls_Onboarding_Gamepad:InitializeScene()
    self.fragment = ZO_FadeSceneFragment:New(self.control)

    self.scene = ZO_Scene:New("battleScrollsOnboarding", SCENE_MANAGER)
    self.scene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
    self.scene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_LEFT)
    -- Note: We don't add GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT because
    -- the XML already has ZO_LeftArrowGamepadNavQuadrant_4Wide_Background_Template
    self.scene:AddFragment(self.fragment)
    self.scene:AddFragment(INTERACT_WINDOW_SOUNDS)

    self.scene:RegisterCallback("StateChange", function(_oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_SHOWN then
            self:OnShown()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)
end

function BattleScrolls_Onboarding_Gamepad:OnShowing()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self.itemList:Activate()
end

function BattleScrolls_Onboarding_Gamepad:OnShown()
    -- Start meter preview after fade-in animation completes
    if self:GetCurrentStep() == STEP.METER and not self.isPreviewActive then
        self:StartMeterPreview()
    end
end

function BattleScrolls_Onboarding_Gamepad:OnHidden()
    self.itemList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self:StopMeterPreview()
end

-------------------------
-- Meter Preview
-------------------------

function BattleScrolls_Onboarding_Gamepad:StartMeterPreview()
    local storage = BattleScrolls.storage
    local settings = storage.savedVariables and storage.savedVariables.settings
    if not settings then return end

    -- Save current settings
    self.savedMeterSettings = {
        dpsMeterPersonalEnabled = settings.dpsMeterPersonalEnabled,
        dpsMeterPersonalDesign = settings.dpsMeterPersonalDesign,
        dpsMeterPersonalOffsetX = settings.dpsMeterPersonalOffsetX,
        dpsMeterPersonalOffsetY = settings.dpsMeterPersonalOffsetY,
        dpsMeterPersonalScale = settings.dpsMeterPersonalScale,
        dpsMeterGroupEnabled = settings.dpsMeterGroupEnabled,
        dpsMeterGroupDesign = settings.dpsMeterGroupDesign,
        dpsMeterGroupPosition = settings.dpsMeterGroupPosition,
        dpsMeterGroupOffsetX = settings.dpsMeterGroupOffsetX,
        dpsMeterGroupOffsetY = settings.dpsMeterGroupOffsetY,
        dpsMeterGroupScale = settings.dpsMeterGroupScale,
    }
    self.isPreviewActive = true

    -- Apply first preset as initial preview
    local firstOption = self.itemList:GetTargetData()
    if firstOption and firstOption.optionData then
        self:UpdateMeterPreview(firstOption.optionData.id)
    end
end

function BattleScrolls_Onboarding_Gamepad:UpdateMeterPreview(presetKey)
    if not self.isPreviewActive then return end

    local storage = BattleScrolls.storage
    local preset = storage.meterPresets[presetKey]
    if not preset then return end

    local settings = storage.savedVariables and storage.savedVariables.settings
    if not settings then return end

    -- Apply preset settings temporarily
    for key, value in pairs(preset) do
        if key ~= "key" then
            settings[key] = value
        end
    end

    -- Update the DPS meter display
    local meter = BattleScrolls.dpsMeter
    if meter then
        meter:ApplyPersonalDesign()
        meter:ApplyGroupDesign()
        meter:ApplyPersonalOffsets()
        meter:ApplyGroupPosition()
        meter:ApplyPersonalScale()
        meter:ApplyGroupScale()
        meter:ShowPreview()
    end
end

function BattleScrolls_Onboarding_Gamepad:StopMeterPreview()
    if not self.isPreviewActive then return end

    -- End preview immediately to hide the meter before restoring settings
    -- This prevents a visual flash of the old configuration
    local meter = BattleScrolls.dpsMeter
    if meter then
        meter:EndPreview()
    end

    local storage = BattleScrolls.storage
    local settings = storage.savedVariables and storage.savedVariables.settings
    if not settings or not self.savedMeterSettings then
        self.savedMeterSettings = nil
        self.isPreviewActive = false
        return
    end

    -- Restore original settings
    for key, value in pairs(self.savedMeterSettings) do
        settings[key] = value
    end

    self.savedMeterSettings = nil
    self.isPreviewActive = false
end

-------------------------
-- Step Management
-------------------------

function BattleScrolls_Onboarding_Gamepad:GetCurrentStep()
    return self.activeSteps[self.currentStepIndex]
end

function BattleScrolls_Onboarding_Gamepad:GetTotalSteps()
    return #self.activeSteps
end

function BattleScrolls_Onboarding_Gamepad:IsLastStep()
    return self.currentStepIndex >= #self.activeSteps
end

function BattleScrolls_Onboarding_Gamepad:GetStepTitle(step)
    if step == STEP.WELCOME then
        return GetString(BATTLESCROLLS_ONBOARDING_WELCOME_TEXT)
    elseif step == STEP.METER then
        return GetString(BATTLESCROLLS_ONBOARDING_METER_QUESTION)
    elseif step == STEP.STORAGE then
        return GetString(BATTLESCROLLS_ONBOARDING_STORAGE_QUESTION)
    elseif step == STEP.EFFECTS then
        return GetString(BATTLESCROLLS_ONBOARDING_EFFECTS_QUESTION)
    elseif step == STEP.COMPLETE then
        return GetString(BATTLESCROLLS_ONBOARDING_COMPLETE_TEXT)
    end
    return ""
end

function BattleScrolls_Onboarding_Gamepad:GetOptionsForStep(step)
    if step == STEP.WELCOME then
        return BuildWelcomeOptions()
    elseif step == STEP.METER then
        return BuildMeterOptions()
    elseif step == STEP.STORAGE then
        return BuildStorageOptions()
    elseif step == STEP.EFFECTS then
        return BuildEffectsOptions()
    elseif step == STEP.COMPLETE then
        return BuildCompleteOptions()
    end
    return {}
end

function BattleScrolls_Onboarding_Gamepad:AnimateToNextStep()
    -- Deactivate list during animation to prevent input
    self.itemList:Deactivate()

    -- Play fade out/in animation
    self.stepTransitionTimeline:PlayFromStart()

    -- Refresh content at midpoint (150ms = fade out duration)
    zo_callLater(function()
        self:RefreshForCurrentStep()
        self.itemList:Activate()
    end, 150)
end

function BattleScrolls_Onboarding_Gamepad:RefreshForCurrentStep()
    local currentStep = self:GetCurrentStep()
    local isComplete = (currentStep == STEP.COMPLETE)

    -- Handle meter preview - start when entering METER step, stop when leaving
    -- Only start preview here if scene is already shown (step transitions).
    -- For initial show, OnShown() handles starting the preview after fade-in completes.
    local sceneIsShown = self.scene and self.scene:GetState() == SCENE_SHOWN
    if currentStep == STEP.METER and not self.isPreviewActive and sceneIsShown then
        self:StartMeterPreview()
    elseif currentStep ~= STEP.METER and self.isPreviewActive then
        self:StopMeterPreview()
    end

    -- Update title
    local isWelcome = (currentStep == STEP.WELCOME)
    if isComplete then
        self.titleControl:SetText(GetString(BATTLESCROLLS_ONBOARDING_COMPLETE_TITLE))
        self.subtitleControl:SetText("") -- No step indicator on completion
    elseif isWelcome then
        self.titleControl:SetText(GetString(BATTLESCROLLS_ONBOARDING_WELCOME_TITLE))
        self.subtitleControl:SetText("") -- No step indicator on welcome
    else
        self.titleControl:SetText(GetString(BATTLESCROLLS_UI_NAME))
        -- Don't count welcome and completion in step numbers
        self.subtitleControl:SetText(zo_strformat(GetString(BATTLESCROLLS_ONBOARDING_STEP_FORMAT), self.currentStepIndex - 1, self:GetTotalSteps() - 2))
    end

    -- Update question/message text
    self.textControl:SetText(self:GetStepTitle(currentStep))

    -- Rebuild options list (empty for completion step)
    self.itemList:Clear()

    local options = self:GetOptionsForStep(currentStep)
    for _, option in ipairs(options) do
        local entryData = ZO_GamepadEntryData:New(option.label)
        entryData.optionData = option
        entryData.narrationText = function()
            return {
                SCREEN_NARRATION_MANAGER:CreateNarratableObject(option.label),
                SCREEN_NARRATION_MANAGER:CreateNarratableObject(option.description or "")
            }
        end
        self.itemList:AddEntry("BattleScrolls_OnboardingOption_Gamepad", entryData)
    end

    self.itemList:Commit()

    -- Reset selection to first item (only if there are options)
    if #options > 0 then
        self.itemList:SetSelectedIndexWithoutAnimation(1)
    end

    -- Update keybind strip to reflect current step
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function BattleScrolls_Onboarding_Gamepad:SelectCurrentOption()
    local currentStep = self:GetCurrentStep()

    -- Completion step - just finish
    if currentStep == STEP.COMPLETE then
        PlaySound(SOUNDS.DIALOG_ACCEPT)
        self:ApplyAndFinish()
        return
    end

    local targetData = self.itemList:GetTargetData()
    if not targetData or not targetData.optionData then
        return
    end

    local option = targetData.optionData

    -- Handle skip option on welcome screen - apply defaults and finish
    if currentStep == STEP.WELCOME and option.id == "skip" then
        PlaySound(SOUNDS.DIALOG_ACCEPT)
        self:ApplyDefaultsAndFinish()
        return
    end

    -- Store the selection based on current step
    if currentStep == STEP.METER then
        self.pendingPreset = option.id
    elseif currentStep == STEP.STORAGE then
        self.pendingStoragePreset = option.id
    elseif currentStep == STEP.EFFECTS then
        -- "full" = all tracking, "essential" = player/boss only, "disabled" = none
        self.pendingEffects = option.id
    end

    -- Advance to next step or finish
    self.currentStepIndex = self.currentStepIndex + 1
    PlaySound(SOUNDS.DIALOG_ACCEPT)
    if self.currentStepIndex > self:GetTotalSteps() then
        self:ApplyAndFinish()
    else
        self:AnimateToNextStep()
    end
end

function BattleScrolls_Onboarding_Gamepad:ApplyAndFinish()
    local storage = BattleScrolls.storage
    local settings = storage.savedVariables.settings

    -- Apply meter preset
    if self.pendingPreset then
        storage:ApplyMeterPreset(self.pendingPreset)
    end

    -- Apply storage preset
    if self.pendingStoragePreset then
        settings.storageSizePreset = self.pendingStoragePreset
    end

    -- Apply effects tracking based on selection
    if self.pendingEffects then
        if self.pendingEffects == "full" then
            -- Track everything including group buffs
            settings.effectTrackingEnabled = true
            settings.trackPlayerBuffs = true
            settings.trackPlayerDebuffs = true
            settings.trackGroupBuffs = true
            settings.trackBossDebuffs = true
        elseif self.pendingEffects == "essential" then
            -- Track player and boss only (no group)
            settings.effectTrackingEnabled = true
            settings.trackPlayerBuffs = true
            settings.trackPlayerDebuffs = true
            settings.trackGroupBuffs = false
            settings.trackBossDebuffs = true
        elseif self.pendingEffects == "disabled" then
            -- Disable all effect tracking
            settings.effectTrackingEnabled = false
            settings.trackPlayerBuffs = false
            settings.trackPlayerDebuffs = false
            settings.trackGroupBuffs = false
            settings.trackBossDebuffs = false
        end
    end

    -- Enable recording
    settings.recordingEnabled = true

    -- Mark onboarding as complete
    settings.hasCompletedOnboarding = true

    -- Apply DPS meter settings to UI
    local meter = BattleScrolls.dpsMeter
    if meter then
        meter:ApplyPersonalDesign()
        meter:ApplyGroupDesign()
        meter:ApplyPersonalOffsets()
        meter:ApplyGroupPosition()
        meter:ApplyPersonalScale()
        meter:ApplyGroupScale()
    end

    -- Hide scene
    SCENE_MANAGER:Hide("battleScrollsOnboarding")

    -- Call completion callback if provided (decouples from journalUI)
    if self.onCompleteCallback then
        self.onCompleteCallback()
        self.onCompleteCallback = nil
    end
end

---Applies default settings (first option from each step) and finishes onboarding
function BattleScrolls_Onboarding_Gamepad:ApplyDefaultsAndFinish()
    local storage = BattleScrolls.storage

    -- Apply first meter preset (from meterPresetOrder)
    local firstMeterPreset = storage.meterPresetOrder and storage.meterPresetOrder[1] or "full_stacked"
    self.pendingPreset = firstMeterPreset
    self.pendingStoragePreset = "medium"
    self.pendingEffects = "essential"

    -- Use the regular apply and finish
    self:ApplyAndFinish()
end

function BattleScrolls_Onboarding_Gamepad:Cancel()
    -- User cancelled - don't mark as complete, features stay disabled
    PlaySound(SOUNDS.DIALOG_DECLINE)
    self:ResetState()
    SCENE_MANAGER:Hide("battleScrollsOnboarding")
end

function BattleScrolls_Onboarding_Gamepad:ResetState()
    -- Stop any active preview before resetting
    self:StopMeterPreview()

    self.activeSteps = BuildActiveSteps()
    self.currentStepIndex = 1
    self.pendingPreset = nil
    self.pendingStoragePreset = nil
    self.pendingEffects = nil
    self.savedMeterSettings = nil
    self.isPreviewActive = false
end

-------------------------
-- Public API
-------------------------

---Shows the onboarding scene
---@param onComplete function|nil Optional callback when onboarding completes
function BattleScrolls_Onboarding_Gamepad:Show(onComplete)
    self:EnsureInitialized()
    self:ResetState()
    self.onCompleteCallback = onComplete
    self:RefreshForCurrentStep()
    SCENE_MANAGER:Show("battleScrollsOnboarding")
end

-- =============================================================================
-- ONBOARDING MODULE (API for external callers)
-- =============================================================================

---Shows the onboarding dialog
---@param onComplete function|nil Optional callback when onboarding completes (decouples from caller)
function onboarding:Show(onComplete)
    if BATTLESCROLLS_ONBOARDING_GAMEPAD then
        BATTLESCROLLS_ONBOARDING_GAMEPAD:Show(onComplete)
    end
end

---Checks if onboarding needs to be completed
---@return boolean needsOnboarding
function onboarding:NeedsOnboarding()
    local storage = BattleScrolls.storage
    if storage.savedVariables and storage.savedVariables.settings then
        return not storage.savedVariables.settings.hasCompletedOnboarding
    end
    return true
end

---Shows chat message directing user to Journal (called on first login)
function onboarding:ShowChatMessage()
    if self:NeedsOnboarding() then
        d("|cffffff" .. GetString(BATTLESCROLLS_ONBOARDING_CHAT_MESSAGE))
    end
end

---Resets onboarding state (for testing)
function onboarding:Reset()
    local storage = BattleScrolls.storage
    if storage.savedVariables and storage.savedVariables.settings then
        storage.savedVariables.settings.hasCompletedOnboarding = false
        -- Also disable features
        storage.savedVariables.settings.dpsMeterPersonalEnabled = false
        storage.savedVariables.settings.dpsMeterGroupEnabled = false
        storage.savedVariables.settings.recordingEnabled = false
        storage.savedVariables.settings.effectTrackingEnabled = false
    end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function BattleScrolls_Onboarding_Gamepad_OnInitialized(control)
    BATTLESCROLLS_ONBOARDING_GAMEPAD = BattleScrolls_Onboarding_Gamepad:New(control)
end

-- Show chat message on player activation (not intrusive dialog)
local function OnPlayerActivated()
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Onboarding", EVENT_PLAYER_ACTIVATED)
    -- Just show a chat message, don't pop up a dialog
    BattleScrolls.onboarding:ShowChatMessage()
end

---Initializes onboarding system (called from main.lua after storage is ready)
function onboarding:Initialize()
    -- Wait for player activation to show chat message
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Onboarding", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

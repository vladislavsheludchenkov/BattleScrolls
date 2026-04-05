-----------------------------------------------------------
-- Custom Dialog Module
-- Bypasses the shared gamepad dialog keybind pool to avoid
-- security tainting issues with protected functions.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local dialogs = {}

-----------------------------------------------------------
-- Basic Confirmation Dialog
-----------------------------------------------------------

local BasicDialog = {}

function BasicDialog:Initialize(control)
    self.control = control
    local ALWAYS_ANIMATE = true
    self.fragment = ZO_TranslateFromLeftSceneFragment:New(control, ALWAYS_ANIMATE)

    -- Get references to child controls (matching ESO's ZO_GenericGamepadDialog_OnInitialized approach)
    self.headerControl = control:GetNamedChild("HeaderContainer")
    self.headerData = {}
    if self.headerControl then
        -- HeaderContainer uses .header property set by ZO_GamepadScreenHeaderContainer
        self.header = self.headerControl.header
        if self.header then
            ZO_GamepadGenericHeader_Initialize(self.header)
        end
    end

    -- Get scroll container and child controls step-by-step (not concatenated)
    -- This matches ESO's initialization in zo_genericdialog_gamepad.lua:570-577
    self.container = control:GetNamedChild("Container")
    if self.container then
        self.scrollChild = self.container:GetNamedChild("ScrollChild")
        if self.scrollChild then
            self.mainTextControl = self.scrollChild:GetNamedChild("MainText")
            self.subTextControl = self.scrollChild:GetNamedChild("SubText")
            self.warningTextControl = self.scrollChild:GetNamedChild("WarningText")
        end
    end

    -- Keybind descriptors - plain tables, not DialogKeybindStripDescriptor objects
    self.keybindStripDescriptor = {}

    -- State
    self.isShowing = false
    self.data = nil
    self.onConfirm = nil
    self.onCancel = nil

    -- Fragment callbacks for proper timing (matches ESO's dialog system)
    self.fragment:RegisterCallback("StateChange", function(_oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
end

function BasicDialog:OnShowing()
    -- Push keybind state to save journal's keybinds
    self.keybindState = KEYBIND_STRIP:PushKeybindGroupState()
    -- Activate directional input for gamepad
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function BasicDialog:OnShown()
    -- Add our keybinds to the new state
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.keybindState)
    PlaySound(SOUNDS.GAMEPAD_OPEN_WINDOW)
end

-- Required for DIRECTIONAL_INPUT
function BasicDialog:UpdateDirectionalInput()
    -- No-op for basic dialog (no scrolling needed)
end

function BasicDialog:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.keybindState)
    DIRECTIONAL_INPUT:Deactivate(self)
end

function BasicDialog:OnHidden()
    -- Pop keybind state to restore journal's keybinds
    KEYBIND_STRIP:PopKeybindGroupState()

    self.isShowing = false
    self.data = nil
    self.onConfirm = nil
    self.onCancel = nil
    self.confirmSound = nil
    self.infoOnly = false
end

function BasicDialog:SetupKeybinds()
    if self.infoOnly then
        -- Info-only dialog: single dismiss button
        self.keybindStripDescriptor = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            {
                keybind = "UI_SHORTCUT_NEGATIVE",
                name = GetString(SI_GAMEPAD_BACK_OPTION),
                callback = function()
                    self:Hide()
                    PlaySound(SOUNDS.GAMEPAD_CLOSE_WINDOW)
                end,
            },
        }
    else
        -- Confirmation dialog: confirm and cancel buttons
        self.keybindStripDescriptor = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            {
                keybind = "UI_SHORTCUT_PRIMARY",
                name = GetString(SI_DIALOG_CONFIRM),
                callback = function()
                    local onConfirm = self.onConfirm
                    local confirmSound = self.confirmSound or SOUNDS.DIALOG_ACCEPT
                    self:Hide()
                    PlaySound(confirmSound)
                    if onConfirm then
                        onConfirm()
                    end
                end,
            },
            {
                keybind = "UI_SHORTCUT_NEGATIVE",
                name = GetString(SI_DIALOG_CANCEL),
                callback = function()
                    local onCancel = self.onCancel
                    self:Hide()
                    PlaySound(SOUNDS.DIALOG_DECLINE)
                    if onCancel then
                        onCancel()
                    end
                end,
            },
        }
    end
end

function BasicDialog:Show(data)
    if self.isShowing then
        return
    end

    self.data = data
    self.onConfirm = data.onConfirm
    self.onCancel = data.onCancel
    self.confirmSound = data.confirmSound
    self.infoOnly = data.infoOnly or false

    -- Set header/title with left alignment
    if self.header then
        self.headerData.titleText = data.title or ""
        self.headerData.titleTextAlignment = TEXT_ALIGN_LEFT
        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end

    -- Set main text
    if self.mainTextControl then
        self.mainTextControl:SetText(data.mainText or "")
    end

    -- Set warning text
    if self.warningTextControl then
        if data.warning and data.warning ~= "" then
            self.warningTextControl:SetText(data.warning)
            self.warningTextControl:SetHidden(false)
        else
            self.warningTextControl:SetHidden(true)
        end
    end

    -- Setup keybinds (will be added in OnShown callback)
    self:SetupKeybinds()

    -- Show the fragment (callbacks handle the rest)
    SCENE_MANAGER:AddFragment(self.fragment)
    self.isShowing = true
end

function BasicDialog:Hide()
    if not self.isShowing then
        return
    end

    -- Hide fragment (callbacks handle cleanup)
    SCENE_MANAGER:RemoveFragment(self.fragment)
end

function BasicDialog:IsShowing()
    return self.isShowing
end

-----------------------------------------------------------
-- Parametric List Dialog (for filters)
-----------------------------------------------------------

local ParametricDialog = {}

-- Setup function that calls data.setup (matches ESO's ParametricListControlSetupFunc)
local function ParametricSetupFunc(control, data, selected, reselectingDuringRebuild, enabled, active)
    if control.resetFunction then
        control.resetFunction()
    end
    if data.setup then
        data.setup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end
end

function ParametricDialog:Initialize(control)
    self.control = control
    local ALWAYS_ANIMATE = true
    self.fragment = ZO_TranslateFromLeftSceneFragment:New(control, ALWAYS_ANIMATE)

    -- Get references to child controls (matching ESO's approach)
    self.headerControl = control:GetNamedChild("HeaderContainer")
    self.headerData = {}
    if self.headerControl then
        -- HeaderContainer uses .header property set by ZO_GamepadScreenHeaderContainer
        self.header = self.headerControl.header
        if self.header then
            ZO_GamepadGenericHeader_Initialize(self.header)
        end
    end

    -- Setup parametric list
    local entryListControl = control:GetNamedChild("EntryList")
    if entryListControl then
        local listControl = entryListControl:GetNamedChild("List")
        if listControl then
            self.entryList = ZO_GamepadVerticalItemParametricScrollList:New(listControl)
            self.entryList:SetAlignToScreenCenter(true)
            self.entryList:SetHandleDynamicViewProperties(true)
        end
    end

    -- Keybind descriptors
    self.keybindStripDescriptor = {}

    -- State
    self.isShowing = false
    self.parametricList = nil
    self.onConfirm = nil
    self.onCancel = nil
    self.onReset = nil

    -- Fragment callbacks for proper timing (matches ESO's dialog system)
    self.fragment:RegisterCallback("StateChange", function(_oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ParametricDialog:OnShowing()
    -- Push keybind state to save journal's keybinds
    self.keybindState = KEYBIND_STRIP:PushKeybindGroupState()
end

function ParametricDialog:OnShown()
    -- Add keybinds to the new state
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.keybindState)

    -- Selection changed callback to update keybinds and show tooltips
    self.entryList:SetOnSelectedDataChangedCallback(function(_, selectedData)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor, self.keybindState)
        if selectedData and selectedData.tooltipText then
            GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, selectedData.tooltipTitle or "", selectedData.tooltipText)
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end)

    -- Show tooltip for initially focused entry
    local selectedData = self.entryList:GetTargetData()
    if selectedData and selectedData.tooltipText then
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, selectedData.tooltipTitle or "", selectedData.tooltipText)
    end

    PlaySound(SOUNDS.GAMEPAD_OPEN_WINDOW)
end

function ParametricDialog:OnHiding()
    -- Deactivate list
    if self.entryList then
        self.entryList:Deactivate()
        self.entryList:SetOnSelectedDataChangedCallback(nil)
    end

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.keybindState)
end

function ParametricDialog:OnHidden()
    -- Pop keybind state to restore journal's keybinds
    KEYBIND_STRIP:PopKeybindGroupState()

    self.isShowing = false
    self.parametricList = nil
    self.onConfirm = nil
    self.onCancel = nil
    self.onReset = nil
    self.resetText = nil
    self.onDeselectAll = nil
    self.deselectAllText = nil

    -- Execute any queued follow-up action (e.g., opening a second dialog)
    local nextAction = self.nextAction
    self.nextAction = nil
    if nextAction then
        nextAction()
    end
end

function ParametricDialog:SetupKeybinds()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local targetData = self.entryList:GetTargetData()
                if targetData and targetData.callback then
                    -- Pass self as "dialog" for compatibility with existing callbacks
                    targetData.callback(self)
                    -- Refresh list to show updated state
                    self.entryList:RefreshVisible()
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
                end
            end,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_DIALOG_CANCEL),
            callback = function()
                local onCancel = self.onCancel
                self:Hide()
                PlaySound(SOUNDS.DIALOG_DECLINE)
                if onCancel then
                    onCancel(self)
                end
            end,
        },
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_DIALOG_CONFIRM),
            callback = function()
                local onConfirm = self.onConfirm
                self:Hide()
                PlaySound(SOUNDS.DIALOG_ACCEPT)
                if onConfirm then
                    onConfirm()
                end
            end,
        },
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                return self.resetText or GetString(SI_DIALOG_RESET)
            end,
            callback = function()
                if self.onReset then
                    self.onReset(self)
                    local RESELECT = true
                    self:RebuildList(RESELECT)
                    PlaySound(SOUNDS.DEFAULT_CLICK)
                end
            end,
            visible = function()
                return self.onReset ~= nil
            end,
        },
        {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = function()
                return self.deselectAllText or ""
            end,
            callback = function()
                if self.onDeselectAll then
                    self.onDeselectAll(self)
                    local RESELECT = true
                    self:RebuildList(RESELECT)
                    PlaySound(SOUNDS.DEFAULT_CLICK)
                end
            end,
            visible = function()
                return self.onDeselectAll ~= nil
            end,
        },
    }
end

function ParametricDialog:RebuildList(reselect)
    if not self.entryList or not self.parametricList then
        return
    end

    self.entryList:Clear()

    for i, entryInfoTable in ipairs(self.parametricList) do
        local visible = true
        local entryDataOverrides = entryInfoTable.templateData

        -- Check visibility
        if entryDataOverrides and (entryDataOverrides.visible ~= nil) then
            visible = entryDataOverrides.visible
            if type(visible) == "function" then
                visible = visible(self)
            end
        end

        if visible then
            -- Create entry data
            local entryDataText = entryInfoTable.text or (entryDataOverrides and entryDataOverrides.text)
            if entryDataText ~= nil then
                if type(entryDataText) == "number" then
                    entryDataText = GetString(entryDataText)
                elseif type(entryDataText) == "function" then
                    entryDataText = entryDataText(self)
                end
            else
                entryDataText = "EntryItem" .. tostring(i)
            end

            local entryData = ZO_GamepadEntryData:New(entryDataText, entryInfoTable.icon)

            -- Copy templateData fields onto entry data
            if entryDataOverrides then
                for dataKey, dataValue in pairs(entryDataOverrides) do
                    if dataKey ~= "text" then
                        entryData[dataKey] = dataValue
                    end
                end
            end

            -- Set dialog reference for callback compatibility
            entryData.dialog = self

            -- Register template if needed
            local entryTemplate = entryInfoTable.template
            if not self.entryList:HasDataTemplate(entryTemplate) then
                self.entryList:AddDataTemplateWithHeader(entryTemplate, ParametricSetupFunc, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, entryInfoTable.headerTemplate or "ZO_GamepadMenuEntryHeaderTemplate")
                self.entryList:AddDataTemplate(entryTemplate, ParametricSetupFunc, ZO_GamepadMenuEntryTemplateParametricListFunction)
            end

            -- Add entry with or without header
            local headerText = entryInfoTable.header
            if headerText ~= nil then
                if type(headerText) == "number" then
                    headerText = GetString(headerText)
                elseif type(headerText) == "function" then
                    headerText = headerText(self)
                end
                entryData:SetHeader(headerText)
                self.entryList:AddEntryWithHeader(entryTemplate, entryData)
            else
                self.entryList:AddEntry(entryTemplate, entryData)
            end
        end
    end

    if reselect then
        self.entryList:Commit()
    else
        self.entryList:CommitWithoutReselect()
    end
end

function ParametricDialog:Show(data)
    if self.isShowing then
        return
    end

    self.onConfirm = data.onConfirm
    self.onCancel = data.onCancel
    self.onReset = data.onReset
    self.resetText = data.resetText
    self.onDeselectAll = data.onDeselectAll
    self.deselectAllText = data.deselectAllText
    self.parametricList = data.parametricList

    -- Set header/title with left alignment
    if self.header then
        self.headerData.titleText = data.title or ""
        self.headerData.titleTextAlignment = TEXT_ALIGN_LEFT
        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end

    -- Build the list (with reselect to ensure first item is selected)
    local RESELECT = true
    self:RebuildList(RESELECT)

    -- Focus the initially selected entry, or reset to the top
    if data.initialIndex and data.initialIndex >= 1 and data.initialIndex <= self.entryList:GetNumEntries() then
        self.entryList:SetSelectedIndexWithoutAnimation(data.initialIndex)
    else
        self.entryList:SetSelectedIndexWithoutAnimation(1)
    end

    -- Setup keybinds (will be added in OnShown callback)
    self:SetupKeybinds()

    -- Show the fragment and activate list immediately (matching ESO's timing)
    -- This ensures the list fade animation runs in parallel with the slide animation
    SCENE_MANAGER:AddFragment(self.fragment)
    self.entryList:Activate()
    self.isShowing = true
end

function ParametricDialog:Hide()
    if not self.isShowing then
        return
    end

    -- Hide fragment (callbacks handle cleanup)
    SCENE_MANAGER:RemoveFragment(self.fragment)
end

function ParametricDialog:IsShowing()
    return self.isShowing
end

function ParametricDialog:GetEntryList()
    return self.entryList
end

-----------------------------------------------------------
-- Text Input Dialog
-----------------------------------------------------------

local TextInputDialog = {}

function TextInputDialog:Initialize(control)
    self.control = control
    local ALWAYS_ANIMATE = true
    self.fragment = ZO_TranslateFromLeftSceneFragment:New(control, ALWAYS_ANIMATE)

    self.headerControl = control:GetNamedChild("HeaderContainer")
    self.headerData = {}
    if self.headerControl then
        self.header = self.headerControl.header
        if self.header then
            ZO_GamepadGenericHeader_Initialize(self.header)
        end
    end

    self.container = control:GetNamedChild("Container")
    if self.container then
        self.scrollChild = self.container:GetNamedChild("ScrollChild")
        if self.scrollChild then
            self.mainTextControl = self.scrollChild:GetNamedChild("MainText")
        end
    end

    -- Create edit box with backdrop below main text
    if self.scrollChild then
        local editBg = CreateControl(control:GetName() .. "EditBg", self.scrollChild, CT_BACKDROP)
        editBg:SetAnchor(TOPLEFT, self.mainTextControl, BOTTOMLEFT, 0, 20)
        editBg:SetAnchor(TOPRIGHT, self.mainTextControl, BOTTOMRIGHT, 0, 20)
        editBg:SetHeight(50)
        editBg:SetCenterColor(0, 0, 0, 0.5)
        editBg:SetEdgeColor(0.5, 0.5, 0.5, 0.8)
        editBg:SetEdgeTexture("", 1, 1, 1)
        self.editBg = editBg

        local editBox = CreateControl(control:GetName() .. "EditBox", editBg, CT_EDITBOX)
        editBox:SetFont("ZoFontGamepad34")
        editBox:SetMaxInputChars(100)
        editBox:SetColor(1, 1, 1, 1)
        editBox:SetAnchor(TOPLEFT, editBg, TOPLEFT, 10, 5)
        editBox:SetAnchor(BOTTOMRIGHT, editBg, BOTTOMRIGHT, -10, -5)
        editBox:SetHandler("OnEnter", function()
            self:Confirm()
        end)
        self.editBox = editBox
    end

    self.keybindStripDescriptor = {}
    self.isShowing = false
    self.onConfirm = nil
    self.onCancel = nil

    self.fragment:RegisterCallback("StateChange", function(_oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
end

function TextInputDialog:OnShowing()
    self.keybindState = KEYBIND_STRIP:PushKeybindGroupState()
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function TextInputDialog:OnShown()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.keybindState)
    if self.editBox then
        self.editBox:TakeFocus()
    end
    PlaySound(SOUNDS.GAMEPAD_OPEN_WINDOW)
end

function TextInputDialog:UpdateDirectionalInput()
    -- No-op for text input dialog
end

function TextInputDialog:OnHiding()
    if self.editBox then
        self.editBox:LoseFocus()
    end
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.keybindState)
    DIRECTIONAL_INPUT:Deactivate(self)
end

function TextInputDialog:OnHidden()
    KEYBIND_STRIP:PopKeybindGroupState()
    self.isShowing = false
    self.onConfirm = nil
    self.onCancel = nil
end

function TextInputDialog:Confirm()
    local text = self.editBox and self.editBox:GetText() or ""
    if text == "" then return end
    local onConfirm = self.onConfirm
    self:Hide()
    PlaySound(SOUNDS.DIALOG_ACCEPT)
    if onConfirm then
        onConfirm(text)
    end
end

function TextInputDialog:SetupKeybinds()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_DIALOG_CONFIRM),
            callback = function()
                self:Confirm()
            end,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_DIALOG_CANCEL),
            callback = function()
                local onCancel = self.onCancel
                self:Hide()
                PlaySound(SOUNDS.DIALOG_DECLINE)
                if onCancel then
                    onCancel()
                end
            end,
        },
    }
end

function TextInputDialog:Show(data)
    if self.isShowing then return end

    self.onConfirm = data.onConfirm
    self.onCancel = data.onCancel

    if self.header then
        self.headerData.titleText = data.title or ""
        self.headerData.titleTextAlignment = TEXT_ALIGN_LEFT
        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end

    if self.mainTextControl then
        self.mainTextControl:SetText(data.mainText or "")
    end

    if self.editBox then
        self.editBox:SetText(data.defaultText or "")
        self.editBox:SelectAll()
    end

    self:SetupKeybinds()
    SCENE_MANAGER:AddFragment(self.fragment)
    self.isShowing = true
end

function TextInputDialog:Hide()
    if not self.isShowing then return end
    SCENE_MANAGER:RemoveFragment(self.fragment)
end

function TextInputDialog:IsShowing()
    return self.isShowing
end

-----------------------------------------------------------
-- Global initialization functions (called from XML)
-----------------------------------------------------------

function BattleScrolls_BasicDialog_OnInitialized(control)
    local dialog = setmetatable({}, { __index = BasicDialog })
    dialog:Initialize(control)
    BattleScrolls.dialogs.basic = dialog
end

function BattleScrolls_ParametricDialog_OnInitialized(control)
    local dialog = setmetatable({}, { __index = ParametricDialog })
    dialog:Initialize(control)
    BattleScrolls.dialogs.parametric = dialog
end

function BattleScrolls_TextInputDialog_OnInitialized(control)
    local dialog = setmetatable({}, { __index = TextInputDialog })
    dialog:Initialize(control)
    BattleScrolls.dialogs.textInput = dialog
end

-----------------------------------------------------------
-- Public API
-----------------------------------------------------------

---Shows a basic confirmation dialog or info dialog
---@param data {title: string, mainText: string, warning: string|nil, onConfirm: function|nil, onCancel: function|nil, confirmSound: string|nil, infoOnly: boolean|nil}
function dialogs.showBasicDialog(data)
    if BattleScrolls.dialogs.basic then
        BattleScrolls.dialogs.basic:Show(data)
    end
end

---Shows a parametric list dialog
---@param data {title: string, parametricList: table[], onConfirm: function|nil, onCancel: function|nil, onReset: fun(dialog: table)|nil, resetText: string|nil}
function dialogs.showParametricDialog(data)
    if BattleScrolls.dialogs.parametric then
        BattleScrolls.dialogs.parametric:Show(data)
    end
end

---Shows a text input dialog
---@param data {title: string, mainText: string, defaultText: string|nil, onConfirm: fun(text: string)|nil, onCancel: function|nil}
function dialogs.showTextInputDialog(data)
    if BattleScrolls.dialogs.textInput then
        BattleScrolls.dialogs.textInput:Show(data)
    end
end

-- Initialize namespace
BattleScrolls.dialogs = BattleScrolls.dialogs or {}
BattleScrolls.journal = BattleScrolls.journal or {}
BattleScrolls.journal.dialogs = dialogs

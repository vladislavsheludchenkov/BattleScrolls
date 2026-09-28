---@diagnostic disable: undefined-field, inject-field -- the ESO Control/ZO_* API stubs are too incomplete for field checking in UI code
if not SemisPlaygroundCheckAccess() then
    return
end

local utils = BattleScrolls.dpsMeterUtils
local factories = BattleScrolls.dpsMeterRowFactories

---@class GroupBarColorKeybind
---@field keybind string
---@field name string
---@field enabled? fun(): boolean
---@field callback fun()
---@field sound? string

---@class GroupBarColorKeybindGroup
---@field alignment number
---@field [integer] GroupBarColorKeybind

---An isolated draft editor: only Save writes settings or broadcasts a preference.
---Uses the game's color wheel and the meter's real row factory, without borrowing
---the HUD controls or the shared gamepad dialog keybind pool.
---@class GroupBarColorPicker
---@field control Control
---@field panel Control
---@field fragment ZO_SimpleSceneFragment
---@field colorSelect Control
---@field brightness Control
---@field brightnessTexture Control
---@field editBox Control
---@field hexHighlight Control
---@field errorLabel Control
---@field newLabel Control
---@field currentRow Control
---@field newRow Control
---@field keybinds GroupBarColorKeybindGroup
---@field keybindState number|nil
---@field isShowing boolean
---@field updating boolean
---@field valid boolean
---@field draftIsDefault boolean
---@field draftHex string
---@field hexEditWasDefault boolean|nil
---@field hexEditInitialHex string|nil
---@field onChanged fun()|nil
---@field committed boolean
local picker = { isShowing = false, updating = false, valid = true, committed = false }
BattleScrolls.journal.colorPicker = picker

---@param row Control
---@param r number
---@param g number
---@param b number
local function colorRow(row, r, g, b)
    row:GetNamedChild("Bar"):SetColor(r, g, b, 1)
end

---Use the same rounding as the saved 8-bit channels for an exact preview.
---@param r number
---@param g number
---@param b number
---@return string hex
local function toHex(r, g, b)
    return string.format("%02X%02X%02X", zo_round(r * 255), zo_round(g * 255), zo_round(b * 255))
end

---@param control Control
function picker:initialize(control)
    self.control = control
    self.panel = control:GetNamedChild("Panel")
    local panel = self.panel
    self.colorSelect = panel:GetNamedChild("ColorSelect")
    self.colorSelect:SetColorWheelThumbTextureControl(self.colorSelect:GetNamedChild("Thumb"))
    self.brightness = panel:GetNamedChild("Brightness")
    self.brightness:GetThumbTextureControl():SetDrawLayer(DL_OVERLAY)
    self.brightnessTexture = self.brightness:GetNamedChild("Texture")
    self.editBox = panel:GetNamedChild("HexBackground"):GetNamedChild("Edit")
    self.hexHighlight = panel:GetNamedChild("HexBackground"):GetNamedChild("Highlight")
    self.errorLabel = panel:GetNamedChild("Error")
    self.newLabel = panel:GetNamedChild("NewLabel")

    self.currentRow = factories.CreateBarsRow(control:GetName() .. "CurrentBar", panel)
    self.newRow = factories.CreateBarsRow(control:GetName() .. "NewBar", panel)
    self.currentRow:SetAnchor(TOP, panel:GetNamedChild("CurrentLabel"), BOTTOM, 0, 8)
    self.newRow:SetAnchor(TOP, self.newLabel, BOTTOM, 0, 8)

    self.colorSelect:SetHandler("OnColorSelected", function()
        if self.updating then return end
        self.draftIsDefault = false
        self:updatePreview()
    end)
    self.brightness:SetHandler("OnValueChanged", function(_, value)
        if self.updating then return end
        self.colorSelect:SetValue(1 - value)
    end)
    self.editBox:SetMaxInputChars(7)
    self.editBox:SetHandler("OnTextChanged", function()
        if not self.updating then self:readHex() end
    end)
    self.editBox:SetHandler("OnFocusGained", function(edit)
        self.hexHighlight:SetHidden(false)
        self.hexEditWasDefault = self.draftIsDefault
        self.hexEditInitialHex = self.draftHex
        ZO_GamepadEditBox_FocusGained(edit)
    end)
    self.editBox:SetHandler("OnFocusLost", function(edit)
        self.hexHighlight:SetHidden(true)
        ZO_GamepadEditBox_FocusLost(edit)
        self.hexEditWasDefault = nil
        self.hexEditInitialHex = nil
    end)

    self.keybinds = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(BATTLESCROLLS_COLOR_SAVE),
            enabled = function() return self.valid end,
            callback = function() self:save() end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_DIALOG_CANCEL),
            callback = function() self:hide() end,
            sound = SOUNDS.DIALOG_DECLINE,
        },
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(BATTLESCROLLS_COLOR_DEFAULT),
            callback = function() self:resetToDefault() end,
        },
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(BATTLESCROLLS_COLOR_HEX),
            callback = function()
                self.editBox:TakeFocus()
                self.editBox:SelectAll()
            end,
        },
    }

    self.fragment = ZO_SimpleSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(_, state)
        if state == SCENE_FRAGMENT_SHOWING then
            self.keybindState = KEYBIND_STRIP:PushKeybindGroupState()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybinds, self.keybindState)
            DIRECTIONAL_INPUT:Activate(self, self.control)
            PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
        elseif state == SCENE_FRAGMENT_HIDING then
            self.editBox:LoseFocus()
            DIRECTIONAL_INPUT:Deactivate(self)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybinds, self.keybindState)
        elseif state == SCENE_FRAGMENT_HIDDEN then
            KEYBIND_STRIP:PopKeybindGroupState()
            self.keybindState = nil
            self.isShowing = false
            local onChanged = self.committed and self.onChanged
            self.onChanged = nil
            self.committed = false
            PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
            if onChanged then onChanged() end
        end
    end)
end

---Refresh the real bar, gradient and hex value without touching saved settings.
---@param preserveHexInput boolean|nil Don't replace text while typing a valid hex value.
function picker:updatePreview(preserveHexInput)
    local r, g, b = self.colorSelect:GetColorAsRGB()
    self.draftHex = toHex(r, g, b)
    colorRow(self.newRow, zo_round(r * 255) / 255, zo_round(g * 255) / 255, zo_round(b * 255) / 255)
    local fullR, fullG, fullB = self.colorSelect:GetFullValuedColorAsRGB()
    self.brightnessTexture:SetGradientColors(ORIENTATION_VERTICAL, 0, 0, 0, 1, fullR, fullG, fullB, 1)
    self.newLabel:SetText(self.draftIsDefault and GetString(BATTLESCROLLS_COLOR_DEFAULT) or GetString(SI_COLOR_PICKER_NEW))
    self.valid = true
    self.errorLabel:SetHidden(true)
    if not preserveHexInput then
        self.updating = true
        self.editBox:SetText("#" .. self.draftHex)
        self.updating = false
    end
    if self.keybindState then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybinds, self.keybindState)
    end
end

---@param r number
---@param g number
---@param b number
---@param isDefault boolean
---@param preserveHexInput boolean|nil
function picker:setColor(r, g, b, isDefault, preserveHexInput)
    self.updating = true
    self.colorSelect:SetColorAsRGB(r, g, b)
    self.brightness:SetValue(1 - self.colorSelect:GetValue())
    self.updating = false
    self.draftIsDefault = isDefault
    self:updatePreview(preserveHexInput)
end

function picker:readHex()
    local hex = self.editBox:GetText():match("^#?(%x%x%x%x%x%x)$")
    if not hex then
        self.valid = false
        self.errorLabel:SetHidden(false)
        if self.keybindState then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybinds, self.keybindState)
        end
        return
    end
    local value = tonumber(hex, 16)
    -- Cancelling hex entry restores its original text; preserve Default's meaning too.
    local isDefault = self.hexEditWasDefault == true and hex:upper() == self.hexEditInitialHex
    self:setColor(math.floor(value / 65536) / 255, math.floor(value / 256) % 256 / 255, value % 256 / 255, isDefault, true)
end

function picker:resetToDefault()
    local r, g, b = utils.defaultColorFromName(BattleScrolls.utils.GetUndecoratedDisplayName())
    self:setColor(r, g, b, true)
end

---The directional-input dispatcher requires this ESO method name.
---@param deltaS number
function picker:UpdateDirectionalInput(deltaS)
    if self.editBox:HasFocus() then
        DIRECTIONAL_INPUT:ConsumeAll()
        return
    end
    -- ESO's D-pad query polls private IsKeyDown, which addons cannot call.
    -- Block navigation behind the editor without querying that device.
    DIRECTIONAL_INPUT:Consume(ZO_DI_DPAD)
    local x, y = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK)
    if not zo_floatsAreEqual(x, 0) or not zo_floatsAreEqual(y, 0) then
        local thumbX, thumbY = self.colorSelect:GetThumbNormalizedPosition()
        thumbX, thumbY = thumbX + x * deltaS, thumbY - y * deltaS
        local radius = math.sqrt(thumbX * thumbX + thumbY * thumbY)
        if radius > 1 then thumbX, thumbY = thumbX / radius, thumbY / radius end
        self.colorSelect:SetThumbNormalizedPosition(thumbX, thumbY)
    end
    local _, brightnessY = DIRECTIONAL_INPUT:GetXY(ZO_DI_RIGHT_STICK)
    if not zo_floatsAreEqual(brightnessY, 0) then
        self.brightness:SetValue(zo_clamp(self.brightness:GetValue() - brightnessY * deltaS * 0.5, 0, 1))
    end
end

---@param onChanged fun()
function picker:show(onChanged)
    if self.isShowing then return end
    local meter = BattleScrolls.dpsMeter
    if meter and meter.isPreviewActive then meter:EndPreview() end
    self.onChanged = onChanged
    self.committed = false
    local displayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local r, g, b = utils.ColorFromName(displayName)
    for _, row in ipairs({ self.currentRow, self.newRow }) do
        row:GetNamedChild("Name"):SetText(displayName)
        row:GetNamedChild("Value"):SetText(utils.FormatDPS(78200))
        row:GetNamedChild("Icon"):SetTexture(utils.GetRoleIcon(BattleScrolls.utils.getUnitRole("player")))
        row:GetNamedChild("Bar"):SetValue(78)
        row:GetNamedChild("BarGloss"):SetValue(78)
        row:SetHidden(false)
    end
    colorRow(self.currentRow, r, g, b)
    self:setColor(r, g, b, BattleScrolls.prefsShare.GetOwnColor() == nil)
    self.panel:SetScale(1)
    self.panel:SetScale(math.min(1, (GuiRoot:GetHeight() - 100) / self.panel:GetHeight(), (GuiRoot:GetWidth() - 40) / 930))
    self.isShowing = true
    SCENE_MANAGER:AddFragment(self.fragment)
end

function picker:save()
    if not self.isShowing or not self.valid then return end
    local settings = BattleScrolls.storage.savedVariables.settings
    local hex = not self.draftIsDefault and self.draftHex or nil
    if settings.groupBarColor ~= hex then
        settings.groupBarColor = hex
        BattleScrolls.prefsShare:OnColorChanged()
        self.committed = true
    end
    self:hide()
end

function picker:hide()
    if self.isShowing then SCENE_MANAGER:RemoveFragment(self.fragment) end
end

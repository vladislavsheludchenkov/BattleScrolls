-- Exercise draft/commit and UI lifecycle against the real picker, color resolver
-- and preference sender. ESO controls are mocked; layout still needs in-game QA.
local function newEditor(initialHex)
    local env = setmetatable({}, { __index = _G })
    local sent, refreshes, endedPreviews = {}, 0, 0
    local settings = { groupBarColor = initialHex }
    env.BattleScrolls = {
        journal = {},
        storage = { savedVariables = { settings = settings } },
        utils = {
            GetUndecoratedDisplayName = function() return "TestPlayer" end,
            getUnitRole = function() return 1 end,
            GetRoleIcon = function() return "role.dds" end,
        },
        dpsMeter = {
            isPreviewActive = false,
            EndPreview = function(self)
                endedPreviews = endedPreviews + 1
                self.isPreviewActive = false
            end,
        },
    }
    env.zo_round = function(n) return math.floor(n + 0.5) end
    env.zo_clamp = function(n, low, high) return math.min(high, math.max(low, n)) end
    env.zo_floatsAreEqual = function(a, b) return math.abs(a - b) < 0.000001 end
    env.IsUnitGrouped = function() return true end
    env.ZO_AbbreviateAndLocalizeNumber = tostring
    env.ZO_CreateStringId = function(id) env[id] = id end
    env.GetString = function(id) assert(id); return id end
    env.SOUNDS = { DIALOG_ACCEPT = "accept", DIALOG_DECLINE = "decline", GAMEPAD_MENU_FORWARD = "forward", GAMEPAD_MENU_BACK = "back" }
    env.PlaySound = function(sound) assert(sound, "missing sound") end
    for _, key in ipairs({ "SI_DIALOG_CANCEL", "SI_COLOR_PICKER_NEW", "SCENE_FRAGMENT_SHOWING",
        "SCENE_FRAGMENT_HIDING", "SCENE_FRAGMENT_HIDDEN", "ZO_DI_LEFT_STICK", "ZO_DI_DPAD", "ZO_DI_RIGHT_STICK" }) do
        env[key] = key
    end

    local Control = {}
    function Control.new() return setmetatable({ children = {}, handlers = {}, text = "", value = 1 }, { __index = Control }) end
    function Control:GetNamedChild(name)
        self.children[name] = self.children[name] or Control.new()
        return self.children[name]
    end
    function Control:GetName() return "TestColorPicker" end
    function Control:SetHandler(event, callback) self.handlers[event] = callback end
    function Control:fire(event, ...)
        if self.handlers[event] then self.handlers[event](self, ...) end
    end
    function Control:SetText(text) self.text = text; self:fire("OnTextChanged") end
    function Control:GetText() return self.text end
    function Control:SetColor(...) self.color = { ... } end
    function Control:SetValue(value) self.value = value; self:fire("OnValueChanged", value) end
    function Control:GetValue() return self.value end
    function Control:SetHidden(hidden) self.hidden = hidden end
    function Control:SetTexture(texture) self.texture = texture end
    function Control:SetScale(scale) self.scale = scale end
    function Control:GetHeight() return 560 end -- XML layout is supplied by ESO in game.
    function Control:SetGradientColors(...) self.gradient = { ... } end
    function Control:SetColorAsRGB(r, g, b)
        self.rgb = { r, g, b }
        self.value = math.max(r, g, b)
        self:fire("OnColorSelected")
    end
    function Control:GetColorAsRGB() return table.unpack(self.rgb) end
    function Control:GetThumbNormalizedPosition() return self.thumbX or 0, self.thumbY or 0 end
    function Control:SetThumbNormalizedPosition(x, y) self.thumbX, self.thumbY = x, y end
    function Control:GetFullValuedColorAsRGB()
        if self.value == 0 then return 1, 1, 1 end
        return self.rgb[1] / self.value, self.rgb[2] / self.value, self.rgb[3] / self.value
    end
    function Control:TakeFocus() self.focused = true; self:fire("OnFocusGained") end
    function Control:LoseFocus()
        if self.focused then self.focused = false; self:fire("OnFocusLost") end
    end
    function Control:HasFocus() return self.focused end
    function Control:GetThumbTextureControl() return self:GetNamedChild("Thumb") end
    function Control:SetAnchor() end
    function Control:SetDrawLayer() end
    function Control:SetColorWheelThumbTextureControl() end
    function Control:SetMaxInputChars() end
    function Control:SelectAll() end

    env.GuiRoot = { GetHeight = function() return 1080 end, GetWidth = function() return 1920 end }
    env.BattleScrolls.dpsMeterRowFactories = { CreateBarsRow = Control.new }
    env.KEYBIND_STRIP = {
        depth = 0,
        PushKeybindGroupState = function(self) self.depth = self.depth + 1; return self.depth end,
        PopKeybindGroupState = function(self) self.depth = self.depth - 1 end,
        AddKeybindButtonGroup = function() end,
        RemoveKeybindButtonGroup = function() end,
        UpdateKeybindButtonGroup = function() end,
    }
    env.DIRECTIONAL_INPUT = {
        axes = {},
        consumed = {},
        queries = {},
        Activate = function(self, owner) self.owner = owner end,
        Deactivate = function(self, owner) assert_eq(self.owner, owner); self.owner = nil end,
        Consume = function(self, ...)
            for _, device in ipairs({ ... }) do self.consumed[device] = true end
        end,
        ConsumeAll = function(self)
            self:Consume(env.ZO_DI_LEFT_STICK, env.ZO_DI_RIGHT_STICK, env.ZO_DI_DPAD)
        end,
        GetXY = function(self, ...)
            -- ESO's D-pad query calls private IsKeyDown even when no key is held.
            -- Model that boundary instead of silently accepting every device.
            for _, device in ipairs({ ... }) do
                assert(device ~= env.ZO_DI_DPAD, "IsKeyDown is private to ESO UI code")
                self.queries[#self.queries + 1] = device
            end
            self:Consume(...)
            local axes = self.axes[select(1, ...)] or { 0, 0 }
            return axes[1], axes[2]
        end,
    }
    env.ZO_GamepadEditBox_FocusGained = function(edit)
        edit.oldText = edit:GetText()
        env.KEYBIND_STRIP:PushKeybindGroupState()
    end
    env.ZO_GamepadEditBox_FocusLost = function() env.KEYBIND_STRIP:PopKeybindGroupState() end
    env.ZO_SimpleSceneFragment = {
        New = function()
            return { RegisterCallback = function(self, _, callback) self.onState = callback end }
        end,
    }
    env.SCENE_MANAGER = {
        AddFragment = function(_, fragment) fragment.onState(nil, env.SCENE_FRAGMENT_SHOWING) end,
        RemoveFragment = function(_, fragment)
            fragment.onState(nil, env.SCENE_FRAGMENT_HIDING)
            fragment.onState(nil, env.SCENE_FRAGMENT_HIDDEN)
        end,
    }
    local function loadModule(path) assert(loadfile(path, "t", env))() end
    loadModule("BattleScrolls/lang/default.lua")
    loadModule("BattleScrolls/network/prefsshare.lua")
    env.BattleScrolls.prefsShare.protocol = { Send = function(_, data) sent[#sent + 1] = data end }
    loadModule("BattleScrolls/ui/meter/utils.lua")
    loadModule("BattleScrolls/ui/journal/color_picker.lua")
    local editor = env.BattleScrolls.journal.colorPicker
    editor:initialize(Control.new())
    return {
        editor = editor, env = env, settings = settings, sent = sent,
        open = function() editor:show(function() refreshes = refreshes + 1 end) end,
        refreshes = function() return refreshes end,
        endedPreviews = function() return endedPreviews end,
    }
end

describe("Group bar color editor", function()
    it("handles idle frames without private key polling or leaking D-pad input", function()
        local test = newEditor("123456")
        test.open()
        test.editor:UpdateDirectionalInput(1 / 60)
        assert_eq(test.editor.draftHex, "123456")
        assert_eq(test.env.DIRECTIONAL_INPUT.consumed[test.env.ZO_DI_DPAD], true)
        assert_eq(#test.sent, 0)
    end)

    it("moves the wheel with the left stick and brightness with the right stick", function()
        local test = newEditor("808080")
        test.open()
        local input = test.env.DIRECTIONAL_INPUT
        input.axes[test.env.ZO_DI_LEFT_STICK] = { 0.6, 0.8 }
        input.axes[test.env.ZO_DI_RIGHT_STICK] = { 0, 1 }
        local previousBrightness = test.editor.brightness:GetValue()
        test.editor:UpdateDirectionalInput(0.5)
        assert_eq(test.editor.colorSelect.thumbX, 0.3)
        assert_eq(test.editor.colorSelect.thumbY, -0.4)
        assert_eq(test.editor.brightness:GetValue(), previousBrightness - 0.25)
        assert_eq(test.settings.groupBarColor, "808080")
        assert_eq(#test.sent, 0)
    end)

    it("consumes navigation without polling or changing the color during hex entry", function()
        local test = newEditor("123456")
        test.open()
        test.editor.editBox:TakeFocus()
        local input = test.env.DIRECTIONAL_INPUT
        test.editor:UpdateDirectionalInput(1 / 60)
        assert_eq(#input.queries, 0)
        assert_eq(input.consumed[test.env.ZO_DI_LEFT_STICK], true)
        assert_eq(input.consumed[test.env.ZO_DI_RIGHT_STICK], true)
        assert_eq(input.consumed[test.env.ZO_DI_DPAD], true)
        assert_eq(test.editor.draftHex, "123456")
    end)

    it("opens with the player's actual color and keeps edits local until Save", function()
        local test = newEditor("FF5A5A")
        test.open()
        assert_eq(test.endedPreviews(), 0, "do not call EndPreview on live meter data")
        assert_eq(test.editor.currentRow:GetNamedChild("Name"):GetText(), "TestPlayer")
        assert_eq(test.editor.currentRow:GetNamedChild("Bar").color[1], 1)
        test.editor.editBox:SetText("#12abef")
        assert_eq(test.settings.groupBarColor, "FF5A5A")
        assert_eq(#test.sent, 0)
        assert_eq(test.editor.draftHex, "12ABEF")
        assert_eq(test.editor.newRow:GetNamedChild("Bar").color[2], 0xAB / 255)
        test.editor:save()
        assert_eq(test.settings.groupBarColor, "12ABEF")
        assert_eq(#test.sent, 1)
        assert_eq(test.sent[1].color24, 0x12ABEF)
        assert_eq(test.refreshes(), 1)
        assert_eq(test.env.KEYBIND_STRIP.depth, 0)
        assert_eq(test.env.DIRECTIONAL_INPUT.owner, nil)
    end)

    it("ends an existing floating preview and discards changes on Cancel", function()
        local test = newEditor("FF5A5A")
        test.env.BattleScrolls.dpsMeter.isPreviewActive = true
        test.open()
        assert_eq(test.endedPreviews(), 1)
        test.editor.editBox:SetText("123456")
        test.editor:hide()
        assert_eq(test.settings.groupBarColor, "FF5A5A")
        assert_eq(#test.sent, 0)
        assert_eq(test.refreshes(), 0)
        assert_eq(test.editor.isShowing, false)
    end)

    it("rejects malformed hex without saving the last valid draft", function()
        local test = newEditor("123456")
        test.open()
        for _, input in ipairs({ "", "#123", "1234567", "GG0000", "-00001", "0x1234", " 12345" }) do
            test.editor.editBox:SetText(input)
            assert_eq(test.editor.valid, false, input)
            test.editor:save()
            assert_eq(test.editor.isShowing, true)
            assert_eq(test.settings.groupBarColor, "123456")
            assert_eq(#test.sent, 0)
        end
        test.editor.editBox:SetText("000000")
        test.editor:save()
        assert_eq(test.settings.groupBarColor, "000000")
        assert_eq(test.sent[1].color24, 0, "black is a valid custom color")
    end)

    it("previews Default without clearing the override until Save", function()
        local test = newEditor("FFFFFF")
        test.open()
        test.editor:resetToDefault()
        assert_eq(test.settings.groupBarColor, "FFFFFF")
        assert_eq(test.editor.draftIsDefault, true)
        test.editor:hide()
        assert_eq(#test.sent, 0)
        test.open()
        test.editor:resetToDefault()
        test.editor:save()
        assert_eq(test.settings.groupBarColor, nil)
        assert_eq(#test.sent, 1)
        assert_eq(test.sent[1].color24, nil, "default is sent as an absent color")
    end)

    it("leaves an unchanged default or custom preference untouched", function()
        for _, test in ipairs({ newEditor(nil), newEditor("3EB6FF") }) do
            test.open()
            test.editor:save()
            assert_eq(#test.sent, 0)
            assert_eq(test.refreshes(), 0)
        end
    end)

    it("preserves Default when a nested hex edit is cancelled", function()
        local test = newEditor(nil)
        test.open()
        local edit = test.editor.editBox
        edit:TakeFocus()
        assert_eq(test.env.KEYBIND_STRIP.depth, 2)
        edit:SetText("#FF0000")
        -- The native edit box's Cancel callback restores oldText before losing focus.
        edit:SetText(edit.oldText)
        edit:LoseFocus()
        assert_eq(test.editor.draftIsDefault, true)
        test.editor:save()
        assert_eq(test.settings.groupBarColor, nil)
        assert_eq(#test.sent, 0)
        assert_eq(test.env.KEYBIND_STRIP.depth, 0)
    end)

    it("cleans up focused input and discards a draft when the scene closes", function()
        local test = newEditor("123456")
        test.open()
        test.editor.editBox:TakeFocus()
        test.editor.editBox:SetText("#FF0000")
        test.env.SCENE_MANAGER:RemoveFragment(test.editor.fragment)
        assert_eq(test.env.KEYBIND_STRIP.depth, 0)
        assert_eq(test.env.DIRECTIONAL_INPUT.owner, nil)
        assert_eq(test.settings.groupBarColor, "123456")
        assert_eq(#test.sent, 0)
        assert_eq(test.editor.onChanged, nil)
    end)
end)

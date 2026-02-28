if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.journal = BattleScrolls.journal or {}

local journal = BattleScrolls.journal

---@class BattleScrolls_Journal_SettingsTemplates
local settingsTemplates = {}
journal.settingsTemplates = settingsTemplates

---Registers all settings list data templates (checkbox, slider, horizontal list, label)
---@param list ZO_ParametricScrollList
function settingsTemplates.setupSettingsList(list)
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

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.journal = BattleScrolls.journal or {}

local journal = BattleScrolls.journal

---@class BattleScrolls_Journal_HorizontalList
local horizontalList = {}
journal.horizontalList = horizontalList

-------------------------
-- Horizontal List Setup/Release (shared between settings and stats lists)
-------------------------

---Setup function for ZO_GamepadHorizontalListRow template.
---Uses data.text, data.valid, data.valueStrings, data.getFunction, data.setFunction.
---@param control Control
---@param data table
---@param selected boolean
local function HorizontalListSetup(control, data, selected, _reselectingDuringRebuild, _enabled, _active)
    control.data = data

    -- Set up the name label (control.label is set by ZO_GamepadHorizontalListRow_Initialize)
    if control.label then
        control.label:SetText(data.text or "")
    end

    -- The template already creates control.horizontalListObject in OnInitialized
    local hList = control.horizontalListObject
    if not hList then
        return
    end

    -- Clear and populate the list
    hList:Clear()
    local currentValue = data.getFunction and data.getFunction() or nil
    local selectedIndex = 1

    for i, option in ipairs(data.valid) do
        local entryData = {
            text = data.valueStrings and data.valueStrings[i] or tostring(option),
            value = option,
            parentControl = control,
        }
        hList:AddEntry(entryData)
        if option == currentValue then
            selectedIndex = i
        end
    end

    -- Set up selection changed callback
    hList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, reselecting)
        if oldData and not reselecting and selectedData then
            if data.setFunction then
                data.setFunction(selectedData.value)
            end
            if data.onChangeFunction then
                data.onChangeFunction(selectedData.value)
            end
        end
    end)

    hList:Commit()
    local ALLOW_EVEN_IF_DISABLED = true
    local NO_ANIMATION = true
    hList:SetSelectedDataIndex(selectedIndex, ALLOW_EVEN_IF_DISABLED, NO_ANIMATION)
    hList:SetActive(selected)
    hList:SetSelectedFromParent(selected)
    hList:RefreshVisible(selected)

    -- Handle visual state
    local color = ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, false)
    if control.label then
        control.label:SetColor(color:UnpackRGBA())
    end
    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
end

---Release function for ZO_GamepadHorizontalListRow template.
---@param control Control
local function HorizontalListRelease(control)
    if control.horizontalListObject then
        control.horizontalListObject:Deactivate()
    end
end

horizontalList.setup = HorizontalListSetup
horizontalList.release = HorizontalListRelease

-------------------------
-- BattleScrolls_HorizontalListRow (left-aligned label + icon + horizontal list)
-------------------------

---OnInitialized handler for BattleScrolls_HorizontalListRow template (called from XML).
---Sets up icon/label refs via ZO_SharedGamepadEntry_OnInitialized, then creates the horizontal list.
---@param self Control
function BattleScrolls_HorizontalListRow_OnInitialized(self)
    ZO_SharedGamepadEntry_OnInitialized(self)
    self.horizontalListControl = self:GetNamedChild("HorizontalList")
    self.horizontalListObject = ZO_HorizontalScrollList_Gamepad:New(
        self.horizontalListControl, "ZO_GamepadHorizontalListEntry", 1,
        ZO_GamepadDefaultHorizontalListEntrySetup)
    self.horizontalListObject:SetAllowWrapping(true)
    self.GetHeight = function(control)
        if control.horizontalListControl:IsHidden() then
            return control.label:GetTextHeight()
        end
        return control.label:GetTextHeight() + control.horizontalListControl:GetHeight()
    end
end

---Setup function for BattleScrolls_HorizontalListRow template.
---Delegates label/icon to ZO_SharedGamepadEntry_OnSetup, then populates the horizontal list.
---@param control Control
---@param data table
---@param selected boolean
local function IconHorizontalListSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    control.data = data

    -- Standard label + icon setup
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

    -- Horizontal list — only visible when selected and has multiple options
    local hList = control.horizontalListObject
    if not hList then return end

    local hasMultipleOptions = #data.valid > 1
    local showList = selected and hasMultipleOptions
    control.horizontalListControl:SetHidden(not showList)

    hList:Clear()
    local currentValue = data.getFunction and data.getFunction() or nil
    local selectedIndex = 1

    for i, option in ipairs(data.valid) do
        local entryData = {
            text = data.valueStrings and data.valueStrings[i] or tostring(option),
            value = option,
            parentControl = control,
        }
        hList:AddEntry(entryData)
        if option == currentValue then
            selectedIndex = i
        end
    end

    hList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, reselecting)
        if oldData and not reselecting and selectedData then
            if data.setFunction then
                data.setFunction(selectedData.value)
            end
        end
    end)

    hList:Commit()
    local ALLOW_EVEN_IF_DISABLED = true
    local NO_ANIMATION = true
    hList:SetSelectedDataIndex(selectedIndex, ALLOW_EVEN_IF_DISABLED, NO_ANIMATION)
    hList:SetActive(showList)
    hList:SetSelectedFromParent(showList)
    hList:RefreshVisible(showList)
end

horizontalList.iconSetup = IconHorizontalListSetup

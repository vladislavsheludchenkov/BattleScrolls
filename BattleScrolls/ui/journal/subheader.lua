-----------------------------------------------------------
-- Sub-Header Component
-- Pinned sub-navigation for tab groups (Damage, Healing, Effects)
--
-- Standalone module - all functions receive journalUI as a parameter.
-- Uses ZO_HorizontalScrollList_Gamepad for D-pad ←→ navigation between
-- sub-views within a parent tab.  Tab bar uses LB/RB (not D-pad), so
-- there is no input conflict.
--
-- Positioned as child of header, between the pipped divider (dots) and
-- data pairs (name/duration). When visible, data pairs are re-anchored
-- below the sub-header; ZO_GamepadGenericHeader_Refresh restores the
-- default anchors before each refresh, so no manual cleanup is needed.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal

---@class SubheaderComponent
---@field control Control Root control
---@field horizontalList table ZO_HorizontalScrollList_Gamepad instance
---@field data1Header Control|nil Header's Data1Header label (re-anchored when visible)
---@field visible boolean Whether the sub-header is currently showing
---@field navigating boolean True while processing a sub-view switch (suppresses refresh)
local subheader = {}

local SUBHEADER_HEIGHT = 50

---Entry setup function for the horizontal scroll list
local function entrySetup(entryControl, data, _selected, _reselectingDuringRebuild, _enabled, _selectedFromParent)
    entryControl:SetText(data.text)
    entryControl:SetFont("ZoFontGamepad34")
    entryControl:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
end

---Equality function so Commit() can find the matching entry after repopulation
local function entryEquality(oldData, newData)
    return oldData.tab == newData.tab
end

---Creates the sub-header control hierarchy inside the header
---@param journalUI BattleScrolls_Journal_Gamepad
function subheader.initialize(journalUI)
    local header = journalUI.header
    if not header then return end

    -- Cache header's internal controls for re-anchoring data pairs
    local dividerSimple = header:GetNamedChild("DividerSimple")

    -- Root control: child of header, anchored below the divider (dots).
    -- When visible, data pairs are re-anchored below this control.
    local control = CreateControl("BattleScrolls_SubHeader", header, CT_CONTROL)
    control:SetAnchor(TOPLEFT, dividerSimple, BOTTOMLEFT, 0, 5)
    control:SetAnchor(TOPRIGHT, dividerSimple, BOTTOMRIGHT, 0, 5)
    control:SetHeight(0)
    control:SetHidden(true)

    -- Horizontal scroll list from ESO's gamepad template (trusted UpdateDirectionalInput)
    local hlControl = CreateControlFromVirtual("$(parent)HL", control, "ZO_GamepadHorizontalListTemplate")
    hlControl:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
    hlControl:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, 0, 0)

    local horizontalList = ZO_HorizontalScrollList_Gamepad:New(hlControl, "ZO_GamepadHorizontalListEntry", 1, entrySetup, entryEquality)
    horizontalList:SetAllowWrapping(true)
    horizontalList:SetSelectedFromParent(true)

    subheader.control = control
    subheader.horizontalList = horizontalList
    subheader.data1Header = header:GetNamedChild("Data1Header")
    subheader.visible = false
    subheader.navigating = false
end

---Refreshes the sub-header (show/hide, update entries, activate/deactivate)
---@param journalUI BattleScrolls_Journal_Gamepad
function subheader.refresh(journalUI)
    if not subheader.control then return end

    local selectedTab = journalUI.selectedTab
    local TabToGroup = journal.TabToGroup
    local groupKey = selectedTab and TabToGroup[selectedTab]

    if not groupKey then
        subheader.hide()
        return
    end

    local decodedEncounter = journalUI.decodedEncounter
    if not decodedEncounter or not decodedEncounter._tabVisibility then
        subheader.hide()
        return
    end

    local chronicler = journal.chronicler
    local visibleSubViews = chronicler.getVisibleSubViews(groupKey, decodedEncounter._tabVisibility)

    if #visibleSubViews <= 1 then
        subheader.hide()
        return
    end

    -- Show sub-header
    subheader.control:SetHidden(false)
    subheader.control:SetHeight(SUBHEADER_HEIGHT)
    subheader.visible = true

    -- Re-anchor data pairs below the sub-header instead of below the divider.
    -- ZO_GamepadGenericHeader_Refresh already ran and set default anchors;
    -- we override Data1Header so the entire data chain shifts down.
    local data1Header = subheader.data1Header
    if data1Header then
        data1Header:ClearAnchors()
        data1Header:SetAnchor(BOTTOMLEFT, subheader.control, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)
        data1Header:SetAnchor(BOTTOMRIGHT, subheader.control, BOTTOMRIGHT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)
    end

    -- Populate horizontal list with sub-view entries
    local horizontalList = subheader.horizontalList
    horizontalList:Clear()

    local selectedIndex = 1
    for i, tab in ipairs(visibleSubViews) do
        local labelId = journal.SubViewLabels[tab]
        horizontalList:AddEntry({
            text = labelId and GetString(_G[labelId]) or "",
            tab = tab,
        })
        if tab == selectedTab then
            selectedIndex = i
        end
    end

    horizontalList:SetOnSelectedDataChangedCallback(function(selectedData, oldData, reselecting)
        if reselecting or not oldData or not selectedData then return end
        if selectedData.tab == journalUI.selectedTab then return end
        journalUI.selectedTab = selectedData.tab
        journalUI.lastSubView = journalUI.lastSubView or {}
        journalUI.lastSubView[groupKey] = selectedData.tab
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
        -- Skip subheader.refresh during this refreshList to preserve scroll animation
        subheader.navigating = true
        chronicler.refreshList(journalUI, true)
        subheader.navigating = false
    end)

    horizontalList:Commit()
    local ALLOW_EVEN_IF_DISABLED = true
    local NO_ANIMATION = true
    horizontalList:SetSelectedDataIndex(selectedIndex, ALLOW_EVEN_IF_DISABLED, NO_ANIMATION)
    horizontalList:Activate()
end

---Hides the sub-header and deactivates input
function subheader.hide()
    if not subheader.control then return end
    subheader.control:SetHidden(true)
    subheader.control:SetHeight(0)
    subheader.visible = false
    if subheader.horizontalList and subheader.horizontalList:IsActive() then
        subheader.horizontalList:Deactivate()
    end
end

---Deactivates input (called when hiding scene)
---@param _journalUI BattleScrolls_Journal_Gamepad|nil
function subheader.deactivate(_journalUI)
    if subheader.horizontalList and subheader.horizontalList:IsActive() then
        subheader.horizontalList:Deactivate()
    end
end

-- Export to namespace
journal.subheader = subheader

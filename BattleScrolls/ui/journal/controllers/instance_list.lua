-----------------------------------------------------------
-- Instance List Controller
-- Handles instance list population and tab bar entries
--
-- This controller manages:
-- - Building instance list entries with filtering
-- - Generating tab bar entries based on available zone types
-- - Instance icon and time header utilities
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local INSTANCE_TAB = journal.InstanceTab
local utils = journal.utils

journal.controllers = journal.controllers or {}

local InstanceListController = {}

-------------------------
-- Utility Functions
-------------------------

---Check if instance passes the current tab filter
---@param instance Instance
---@param selectedTab number
---@return boolean
local function instancePassesFilter(instance, selectedTab)
    if selectedTab == INSTANCE_TAB.INSTANCED then
        return not instance.isOverland and not instance.isHouse and not instance.isPvP
    elseif selectedTab == INSTANCE_TAB.OVERLAND then
        return instance.isOverland and not instance.isHouse and not instance.isPvP
    elseif selectedTab == INSTANCE_TAB.HOUSE then
        return instance.isHouse == true
    elseif selectedTab == INSTANCE_TAB.PVP then
        return instance.isPvP == true
    end
    return true  -- ALL tab shows everything
end

---Counts instances by zone type for conditional tab display
---@param history Instance[]|nil
---@return table<string, number>
local function countByZoneType(history)
    local counts = { instanced = 0, overland = 0, house = 0, pvp = 0 }
    if history then
        for _, instance in ipairs(history) do
            if instance.isHouse then
                counts.house = counts.house + 1
            elseif instance.isPvP then
                counts.pvp = counts.pvp + 1
            elseif instance.isOverland then
                counts.overland = counts.overland + 1
            else
                counts.instanced = counts.instanced + 1
            end
        end
    end
    return counts
end

-------------------------
-- Public API
-------------------------

---Gets tab bar entries for the instances list
---@param journalUI BattleScrolls_Journal_Gamepad The journal UI instance
---@return table[] entries Tab bar entry definitions
function InstanceListController.getTabBarEntries(journalUI)
    local entries = {}
    local history = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.history
    local counts = countByZoneType(history)

    -- All tab is always shown
    table.insert(entries, {
        text = GetString(BATTLESCROLLS_TAB_ALL_ZONES),
        callback = function()
            if journalUI.selectedInstanceTab ~= INSTANCE_TAB.ALL then
                journalUI.selectedInstanceTab = INSTANCE_TAB.ALL
                journalUI:RefreshList(true)
            end
        end
    })

    if counts.instanced > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_INSTANCED),
            callback = function()
                if journalUI.selectedInstanceTab ~= INSTANCE_TAB.INSTANCED then
                    journalUI.selectedInstanceTab = INSTANCE_TAB.INSTANCED
                    journalUI:RefreshList(true)
                end
            end
        })
    end

    if counts.overland > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_OVERLAND),
            callback = function()
                if journalUI.selectedInstanceTab ~= INSTANCE_TAB.OVERLAND then
                    journalUI.selectedInstanceTab = INSTANCE_TAB.OVERLAND
                    journalUI:RefreshList(true)
                end
            end
        })
    end

    if counts.house > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_HOUSES),
            callback = function()
                if journalUI.selectedInstanceTab ~= INSTANCE_TAB.HOUSE then
                    journalUI.selectedInstanceTab = INSTANCE_TAB.HOUSE
                    journalUI:RefreshList(true)
                end
            end
        })
    end

    if counts.pvp > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_PVP),
            callback = function()
                if journalUI.selectedInstanceTab ~= INSTANCE_TAB.PVP then
                    journalUI.selectedInstanceTab = INSTANCE_TAB.PVP
                    journalUI:RefreshList(true)
                end
            end
        })
    end

    return entries
end

---Refreshes the instance list
---@param journalUI BattleScrolls_Journal_Gamepad The journal UI instance
function InstanceListController.refresh(journalUI)
    local list = journalUI.instanceList
    local initialTimestampS
    do
        local selectedData = list:GetSelectedData()
        if selectedData and selectedData.data then
            initialTimestampS = list:GetSelectedData().data.timestampS
        end
    end
    list:Clear()

    -- Add Settings entry at the top
    local settingsEntry = ZO_GamepadEntryData:New(GetString(BATTLESCROLLS_UI_SETTINGS), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_settings.dds")
    settingsEntry.isSettings = true
    settingsEntry:SetIconTintOnSelection(true)
    settingsEntry:SetIconDisabledTintOnSelection(true)
    list:AddEntry("ZO_GamepadItemSubEntryTemplate", settingsEntry)

    local history = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.history
    if history then
        -- Show instances in reverse chronological order (newest first)
        local currentHeader = nil
        local selectedTab = journalUI.selectedInstanceTab or INSTANCE_TAB.ALL
        for i = #history, 1, -1 do
            local instance = history[i]

            if instancePassesFilter(instance, selectedTab) then
                local encounterCount = instance.encounters and #instance.encounters or 0

                local displayName = string.format("%s (%d)", instance.zone, encounterCount)
                local icon = utils.getInstanceIcon(instance)

                local entryData = ZO_GamepadEntryData:New(displayName, icon)
                entryData.data = instance
                entryData:SetIconTintOnSelection(true)
                entryData:SetIconDisabledTintOnSelection(true)
                entryData:SetLocked(instance.locked or false)

                -- Add time as sublabel
                entryData:AddSubLabel(BattleScrolls.utils.formatTime(instance.timestampS))

                -- Group by relative time (Today, Yesterday, Earlier)
                local header = utils.getTimeGroupHeader(instance.timestampS)
                if header ~= currentHeader then
                    currentHeader = header
                    entryData:SetHeader(header)
                    list:AddEntryWithHeader("ZO_GamepadItemSubEntryTemplate", entryData)
                else
                    list:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
                end
            end
        end
    end

    list:Commit()

    -- Set default selection to second item (first actual instance) if available
    if journalUI.defaultInstancePosition and journalUI.defaultInstancePosition <= list:GetNumEntries() then
        list:SetSelectedIndexWithoutAnimation(journalUI.defaultInstancePosition)
        journalUI.defaultInstancePosition = nil
    elseif initialTimestampS and list:GetNumEntries() > 0 then
        -- Try to restore previous selection
        local newIndex = utils.findMatchingIndex(initialTimestampS, list.dataList, list:GetSelectedIndex(), function(item)
            return item and item.data and item.data.timestampS
        end, true)
        list:SetSelectedIndexWithoutAnimation(newIndex)
    end
end

-- Export to namespace
journal.controllers.instanceList = InstanceListController

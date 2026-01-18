-----------------------------------------------------------
-- Encounter List Controller
-- Handles encounter list population and tab bar entries
--
-- This controller manages:
-- - Building encounter list entries with filtering
-- - Generating tab bar entries based on available fight types
-- - Encounter icon and display name utilities
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local ENCOUNTER_TAB = journal.EncounterTab
local utils = journal.utils

journal.controllers = journal.controllers or {}

local EncounterListController = {}

-------------------------
-- Utility Functions
-------------------------

---Check if encounter passes the current tab filter
---@param encounter Encounter
---@param selectedTab number
---@return boolean
local function encounterPassesFilter(encounter, selectedTab)
    if selectedTab == ENCOUNTER_TAB.BOSS then
        return utils.isBossEncounter(encounter) and not encounter.isDummyFight and not encounter.isPlayerFight
    elseif selectedTab == ENCOUNTER_TAB.TRASH then
        return not utils.isBossEncounter(encounter) and not encounter.isDummyFight and not encounter.isPlayerFight
    elseif selectedTab == ENCOUNTER_TAB.PLAYER then
        return encounter.isPlayerFight == true
    elseif selectedTab == ENCOUNTER_TAB.DUMMY then
        return encounter.isDummyFight == true
    end
    return true  -- ALL tab shows everything
end

---Counts encounters by fight type for conditional tab display
---@param instance Instance|nil
---@return table<string, number>
local function countByFightType(instance)
    local counts = { boss = 0, trash = 0, player = 0, dummy = 0 }
    if instance and instance.encounters then
        for _, encounter in ipairs(instance.encounters) do
            if encounter.isDummyFight then
                counts.dummy = counts.dummy + 1
            elseif encounter.isPlayerFight then
                counts.player = counts.player + 1
            elseif utils.isBossEncounter(encounter) then
                counts.boss = counts.boss + 1
            else
                counts.trash = counts.trash + 1
            end
        end
    end
    return counts
end

-------------------------
-- Public API
-------------------------

---Gets tab bar entries for the encounters list
---@param journalUI BattleScrolls_Journal_Gamepad The journal UI instance
---@return table[] entries Tab bar entry definitions
function EncounterListController.getTabBarEntries(journalUI)
    local entries = {}
    local counts = countByFightType(journalUI.selectedInstance)

    -- All tab is always shown
    table.insert(entries, {
        text = GetString(BATTLESCROLLS_TAB_ALL_ENCOUNTERS),
        callback = function()
            if journalUI.selectedEncounterTab ~= ENCOUNTER_TAB.ALL then
                journalUI.selectedEncounterTab = ENCOUNTER_TAB.ALL
                journalUI:RefreshList(true)
            end
        end
    })

    if counts.boss > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_BOSS_ENCOUNTERS),
            callback = function()
                if journalUI.selectedEncounterTab ~= ENCOUNTER_TAB.BOSS then
                    journalUI.selectedEncounterTab = ENCOUNTER_TAB.BOSS
                    journalUI:RefreshList(true)
                end
            end
        })
    end

    if counts.trash > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_OTHER_ENCOUNTERS),
            callback = function()
                if journalUI.selectedEncounterTab ~= ENCOUNTER_TAB.TRASH then
                    journalUI.selectedEncounterTab = ENCOUNTER_TAB.TRASH
                    journalUI:RefreshList(true)
                end
            end
        })
    end

    if counts.player > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_PLAYER_ENCOUNTERS),
            callback = function()
                if journalUI.selectedEncounterTab ~= ENCOUNTER_TAB.PLAYER then
                    journalUI.selectedEncounterTab = ENCOUNTER_TAB.PLAYER
                    journalUI:RefreshList(true)
                end
            end
        })
    end

    if counts.dummy > 0 then
        table.insert(entries, {
            text = GetString(BATTLESCROLLS_TAB_TARGET_DUMMY),
            callback = function()
                if journalUI.selectedEncounterTab ~= ENCOUNTER_TAB.DUMMY then
                    journalUI.selectedEncounterTab = ENCOUNTER_TAB.DUMMY
                    journalUI:RefreshList(true)
                end
            end
        })
    end

    return entries
end

---Refreshes the encounter list
---@param journalUI BattleScrolls_Journal_Gamepad The journal UI instance
function EncounterListController.refresh(journalUI)
    local list = journalUI.encounterList
    local initialTimestampS
    do
        local selectedData = list:GetSelectedData()
        if selectedData and selectedData.data then
            initialTimestampS = selectedData.data.timestampS
        end
    end
    list:Clear()

    local instance = journalUI.selectedInstance
    local encounters = instance and instance.encounters

    if encounters then
        local selectedTab = journalUI.selectedEncounterTab or ENCOUNTER_TAB.ALL
        for _, rawEncounter in ipairs(encounters) do
            -- Use raw encounter for filtering - bossesUnits is stored unencoded
            if encounterPassesFilter(rawEncounter, selectedTab) then
                local displayName = rawEncounter.displayName
                local icon = utils.getEncounterIcon(rawEncounter)

                local entryData = ZO_GamepadEntryData:New(displayName, icon)
                entryData.data = rawEncounter  -- Store raw, decode on drill-down
                entryData:SetIconTintOnSelection(true)
                entryData:SetIconDisabledTintOnSelection(true)

                -- Use raw encounter fields (stored unencoded in compact format)
                local timeSinceInstanceStart = rawEncounter.timestampS - instance.timestampS
                entryData:AddSubLabel(ZO_FormatTime(timeSinceInstanceStart, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_SECONDS) .. " " .. GetString(BATTLESCROLLS_ENCOUNTER_INTO_INSTANCE))

                list:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
            end
        end
    end

    list:Commit()

    if initialTimestampS and list:GetNumEntries() > 0 then
        -- Try to restore previous selection
        local newIndex = utils.findMatchingIndex(initialTimestampS, list.dataList, list:GetSelectedIndex() or 1, function(item)
            return item and item.data and item.data.timestampS
        end, false)
        list:SetSelectedIndexWithoutAnimation(newIndex)
    end
end

-- Export to namespace
journal.controllers.encounterList = EncounterListController

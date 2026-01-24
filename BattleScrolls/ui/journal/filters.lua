-----------------------------------------------------------
-- Filter Dialog Module
-- Standalone module for journal filter dialog
--
-- All functions receive journalUI as a parameter rather
-- than using class methods directly.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local StatsTab = journal.StatsTab
local FilterConstants = journal.FilterConstants
local SELF_UNIT_ID = FilterConstants.SELF_UNIT_ID
local SELF_DISPLAY_NAME = FilterConstants.SELF_DISPLAY_NAME

local filters = {}

---@type table<number|string, boolean> Temporary filter state while dialog is open (unitId/displayName -> selected)
local pendingFilterState = {}
---@type table<number, boolean> Temporary source filter state (sourceUnitId -> selected)
local pendingSourceFilterState = {}
---@type table[] Cached parametric list entries for dialog
local cachedParametricList = {}

-------------------------
-- Filter Dialog Title
-------------------------

---Gets the title for the filter dialog based on current tab
---@param journalUI BattleScrolls_Journal_Gamepad
---@return string
function filters.getDialogTitle(journalUI)
    local selectedTab = journalUI.selectedTab
    if selectedTab == StatsTab.DAMAGE_DONE then
        return GetString(BATTLESCROLLS_FILTER_DAMAGE_DONE)
    elseif selectedTab == StatsTab.BOSS_DAMAGE_DONE then
        return GetString(BATTLESCROLLS_FILTER_BOSS_DAMAGE)
    elseif selectedTab == StatsTab.DAMAGE_TAKEN then
        return GetString(BATTLESCROLLS_FILTER_BY_SOURCE)
    elseif selectedTab == StatsTab.HEALING_OUT then
        return GetString(BATTLESCROLLS_FILTER_BY_TARGET)
    elseif selectedTab == StatsTab.HEALING_IN then
        return GetString(BATTLESCROLLS_FILTER_BY_SOURCE)
    elseif selectedTab == StatsTab.EFFECTS then
        return GetString(BATTLESCROLLS_FILTER_BY_GROUP_MEMBER)
    end
    return GetString(BATTLESCROLLS_FILTER)
end

-------------------------
-- Pending Filter State Management
-------------------------

---Initializes pending filter state from current filters
---@param journalUI BattleScrolls_Journal_Gamepad
function filters.initializePending(journalUI)
    pendingFilterState = {}
    pendingSourceFilterState = {}

    local tabFilters = journalUI:GetFiltersForTab(journalUI.selectedTab)
    local currentTargetFilter = tabFilters.targetFilter
    local currentSourceFilter = tabFilters.sourceFilter
    local currentGroupFilter = tabFilters.groupFilter

    local units = filters.getFilterableUnits(journalUI)

    -- Determine which filter applies based on tab
    local currentMainFilter
    if journalUI.selectedTab == StatsTab.DAMAGE_TAKEN or journalUI.selectedTab == StatsTab.HEALING_IN then
        currentMainFilter = currentSourceFilter
    elseif journalUI.selectedTab == StatsTab.EFFECTS then
        currentMainFilter = currentGroupFilter
    else
        currentMainFilter = currentTargetFilter
    end

    for _, unit in ipairs(units) do
        local unitIds = unit.ids
        for _, unitId in ipairs(unitIds) do
            if currentMainFilter == nil then
                pendingFilterState[unitId] = true
            else
                pendingFilterState[unitId] = currentMainFilter[unitId] or false
            end
        end
    end

    -- For Damage Done tabs, also initialize source filter
    if journalUI.selectedTab == StatsTab.DAMAGE_DONE or journalUI.selectedTab == StatsTab.BOSS_DAMAGE_DONE then
        local sources = filters.getFilterableSources(journalUI)
        for _, source in ipairs(sources) do
            local sourceIds = source.ids or { source.id }
            for _, sourceId in ipairs(sourceIds) do
                if currentSourceFilter == nil then
                    pendingSourceFilterState[sourceId] = true
                else
                    pendingSourceFilterState[sourceId] = currentSourceFilter[sourceId] or false
                end
            end
        end
    end
    BattleScrolls.gc:RequestGC(2)
end

---Resets all pending filters to selected
function filters.resetPending()
    for id in pairs(pendingFilterState) do
        pendingFilterState[id] = true
    end
    for id in pairs(pendingSourceFilterState) do
        pendingSourceFilterState[id] = true
    end
end

---Applies pending filter state to journal
---@param journalUI BattleScrolls_Journal_Gamepad
function filters.applyPending(journalUI)
    local allMainSelected = true
    for _, selected in pairs(pendingFilterState) do
        if not selected then
            allMainSelected = false
            break
        end
    end

    local mainFilter = nil
    if not allMainSelected then
        mainFilter = {}
        for id, selected in pairs(pendingFilterState) do
            if selected then
                mainFilter[id] = true
            end
        end
    end

    local sourceFilter = nil
    if journalUI.selectedTab == StatsTab.DAMAGE_DONE or journalUI.selectedTab == StatsTab.BOSS_DAMAGE_DONE then
        local allSourcesSelected = true
        for _, selected in pairs(pendingSourceFilterState) do
            if not selected then
                allSourcesSelected = false
                break
            end
        end

        if not allSourcesSelected then
            sourceFilter = {}
            for id, selected in pairs(pendingSourceFilterState) do
                if selected then
                    sourceFilter[id] = true
                end
            end
        end
    end

    local tabFilters = {}
    if journalUI.selectedTab == StatsTab.DAMAGE_DONE or journalUI.selectedTab == StatsTab.BOSS_DAMAGE_DONE then
        tabFilters.targetFilter = mainFilter
        tabFilters.sourceFilter = sourceFilter
    elseif journalUI.selectedTab == StatsTab.DAMAGE_TAKEN or journalUI.selectedTab == StatsTab.HEALING_IN then
        tabFilters.sourceFilter = mainFilter
    elseif journalUI.selectedTab == StatsTab.HEALING_OUT then
        tabFilters.targetFilter = mainFilter
    elseif journalUI.selectedTab == StatsTab.EFFECTS then
        tabFilters.groupFilter = mainFilter
    end

    local hasFilters = tabFilters.targetFilter or tabFilters.sourceFilter or tabFilters.groupFilter
    journalUI:SetFiltersForTab(journalUI.selectedTab, hasFilters and tabFilters or nil)
    BattleScrolls.gc:RequestGC(2)
end

function filters.togglePending(id)
    pendingFilterState[id] = not pendingFilterState[id]
end

function filters.isPendingSelected(id)
    return pendingFilterState[id] == true
end

function filters.togglePendingSource(id)
    pendingSourceFilterState[id] = not pendingSourceFilterState[id]
end

function filters.isPendingSourceSelected(id)
    return pendingSourceFilterState[id] == true
end

function filters.togglePendingSourceGroup(ids)
    local newState = not pendingSourceFilterState[ids[1]]
    for _, id in ipairs(ids) do
        pendingSourceFilterState[id] = newState
    end
end

function filters.isPendingSourceGroupSelected(ids)
    for _, id in ipairs(ids) do
        if pendingSourceFilterState[id] ~= true then
            return false
        end
    end
    return true
end

function filters.togglePendingGroup(ids)
    local newState = not pendingFilterState[ids[1]]
    for _, id in ipairs(ids) do
        pendingFilterState[id] = newState
    end
end

function filters.isPendingGroupSelected(ids)
    for _, id in ipairs(ids) do
        if pendingFilterState[id] ~= true then
            return false
        end
    end
    return true
end

-------------------------
-- Get Filterable Sources/Units
-------------------------

---@class FilterableSource
---@field id number|nil Single source unit ID (for self)
---@field ids number[]|nil Array of source unit IDs (for grouped non-self sources)
---@field name string Display name
---@field isSelf boolean Whether this is the player

---Returns sources (player, pets, companions) for Damage Done filtering
---@param journalUI BattleScrolls_Journal_Gamepad
---@return FilterableSource[]
function filters.getFilterableSources(journalUI)
    local sources = {}
    local encounter = journalUI.decodedEncounter
    if not encounter then
        return sources
    end

    local unitNames = journalUI.unitNames or {}
    local utils = BattleScrolls.utils
    local playerUnitId = encounter.playerUnitId

    local nonSelfByName = {}

    for sourceUnitId in pairs(encounter.damageByUnitId or {}) do
        local rawName = unitNames[sourceUnitId] or GetString(BATTLESCROLLS_UNKNOWN)
        local displayName = zo_strformat(SI_UNIT_NAME, rawName)
        local isSelf = (sourceUnitId == playerUnitId)

        if isSelf then
            local selfDisplayName = utils.GetUndecoratedDisplayName() .. " " .. GetString(BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX)
            table.insert(sources, { id = sourceUnitId, name = selfDisplayName, isSelf = true })
        else
            if not nonSelfByName[displayName] then
                nonSelfByName[displayName] = { ids = {}, name = displayName }
            end
            table.insert(nonSelfByName[displayName].ids, sourceUnitId)
        end
    end

    for _, group in pairs(nonSelfByName) do
        table.insert(sources, { ids = group.ids, name = group.name, isSelf = false })
    end

    table.sort(sources, function(a, b)
        if a.isSelf ~= b.isSelf then
            return a.isSelf
        end
        return a.name < b.name
    end)

    return sources
end

---@class FilterableUnit
---@field ids (number|string)[] Array of unit IDs (grouped by name)
---@field name string Display name for UI
---@field isSelf boolean Whether this represents the player

---Groups unit IDs by display name
---@param unitIdToName table<number|string, string> Map of unitId to display name
---@param selfId number|string|nil Self ID to exclude from grouping
---@param selfName string|nil Self display name
---@return FilterableUnit[]
local function groupUnitsByName(unitIdToName, selfId, selfName)
    local units = {}

    -- Self is never grouped with others
    if selfId and unitIdToName[selfId] then
        table.insert(units, { ids = { selfId }, name = selfName or unitIdToName[selfId], isSelf = true })
    end

    -- Group non-self by name
    local byName = {}
    for unitId, displayName in pairs(unitIdToName) do
        if unitId ~= selfId then
            byName[displayName] = byName[displayName] or {}
            table.insert(byName[displayName], unitId)
        end
    end

    for name, ids in pairs(byName) do
        table.insert(units, { ids = ids, name = name, isSelf = false })
    end

    table.sort(units, function(a, b)
        if a.isSelf ~= b.isSelf then
            return a.isSelf
        end
        return a.name < b.name
    end)

    return units
end

---@param journalUI BattleScrolls_Journal_Gamepad
---@return FilterableUnit[]
function filters.getFilterableUnits(journalUI)
    local encounter = journalUI.decodedEncounter
    if not encounter then
        return {}
    end

    local unitNames = journalUI.unitNames or {}
    local utils = BattleScrolls.utils
    local selectedTab = journalUI.selectedTab

    if selectedTab == StatsTab.DAMAGE_DONE then
        local targets = {}
        for _, byTarget in pairs(encounter.damageByUnitId or {}) do
            for targetUnitId in pairs(byTarget) do
                local rawName = unitNames[targetUnitId] or GetString(BATTLESCROLLS_UNKNOWN)
                targets[targetUnitId] = zo_strformat(SI_UNIT_NAME, rawName)
            end
        end
        return groupUnitsByName(targets, nil, nil)

    elseif selectedTab == StatsTab.BOSS_DAMAGE_DONE then
        local bossTargets = {}
        for _, bossUnitId in ipairs(encounter.bossesUnits or {}) do
            local rawName = unitNames[bossUnitId] or GetString(BATTLESCROLLS_UNKNOWN_BOSS)
            bossTargets[bossUnitId] = zo_strformat(SI_UNIT_NAME, rawName)
        end
        return groupUnitsByName(bossTargets, nil, nil)

    elseif selectedTab == StatsTab.DAMAGE_TAKEN then
        local sources = {}
        for sourceUnitId in pairs(encounter.damageTakenByUnitId or {}) do
            local rawName = unitNames[sourceUnitId] or GetString(BATTLESCROLLS_UNKNOWN)
            sources[sourceUnitId] = zo_strformat(SI_UNIT_NAME, rawName)
        end
        return groupUnitsByName(sources, nil, nil)

    elseif selectedTab == StatsTab.HEALING_OUT then
        local selfName = utils.GetUndecoratedDisplayName()
        local hasSelfHealing = encounter.healingStats and encounter.healingStats.selfHealing
            and encounter.healingStats.selfHealing.total
            and encounter.healingStats.selfHealing.total.raw > 0
        local targets = {}
        if hasSelfHealing then
            targets[SELF_UNIT_ID] = selfName .. " " .. GetString(BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX)
        end
        for targetUnitId in pairs(encounter.healingStats and encounter.healingStats.healingOutToGroup or {}) do
            local rawName = unitNames[targetUnitId] or GetString(BATTLESCROLLS_UNKNOWN)
            targets[targetUnitId] = zo_strformat(SI_UNIT_NAME, rawName)
        end
        return groupUnitsByName(targets, SELF_UNIT_ID, targets[SELF_UNIT_ID])

    elseif selectedTab == StatsTab.HEALING_IN then
        local selfName = utils.GetUndecoratedDisplayName()
        local hasSelfHealing = encounter.healingStats and encounter.healingStats.selfHealing
            and encounter.healingStats.selfHealing.total
            and encounter.healingStats.selfHealing.total.raw > 0
        local sources = {}
        if hasSelfHealing then
            sources[SELF_UNIT_ID] = selfName .. " " .. GetString(BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX)
        end
        for sourceUnitId in pairs(encounter.healingStats and encounter.healingStats.healingInFromGroup or {}) do
            local rawName = unitNames[sourceUnitId] or GetString(BATTLESCROLLS_UNKNOWN)
            sources[sourceUnitId] = zo_strformat(SI_UNIT_NAME, rawName)
        end
        return groupUnitsByName(sources, SELF_UNIT_ID, sources[SELF_UNIT_ID])

    elseif selectedTab == StatsTab.EFFECTS then
        local selfName = utils.GetUndecoratedDisplayName()
        local hasPlayerEffects = encounter.effectsOnPlayer and not ZO_IsTableEmpty(encounter.effectsOnPlayer)
        local members = {}
        if hasPlayerEffects then
            members[SELF_DISPLAY_NAME] = selfName .. " " .. GetString(BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX)
        end
        for displayName in pairs(encounter.effectsOnGroup or {}) do
            members[displayName] = displayName
        end
        return groupUnitsByName(members, SELF_DISPLAY_NAME, members[SELF_DISPLAY_NAME])
    end

    return {}
end

-------------------------
-- Build Dialog Entries
-------------------------

---Builds the parametric list entries for the filter dialog
---@param journalUI BattleScrolls_Journal_Gamepad
---@return table[] parametricList Dialog entry definitions
function filters.buildDialogEntries(journalUI)
    local parametricList = {}
    local selectedTab = journalUI.selectedTab

    -- For Damage Done tabs, add source entries first
    if selectedTab == StatsTab.DAMAGE_DONE or selectedTab == StatsTab.BOSS_DAMAGE_DONE then
        local sources = filters.getFilterableSources(journalUI)
        if #sources > 1 then
            for i, source in ipairs(sources) do
                local sourceIds = source.ids or { source.id }
                local entry = {
                    template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
                    text = source.name,
                    templateData = {
                        sourceIds = sourceIds,
                        isSourceEntry = true,
                        setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                            ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                            ZO_CheckButton_SetCheckState(control.checkBox, filters.isPendingSourceGroupSelected(data.sourceIds))
                        end,
                        callback = function(dialog)
                            local targetControl = dialog.entryList:GetTargetControl()
                            if targetControl then
                                ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                                local targetData = dialog.entryList:GetTargetData()
                                if targetData then
                                    filters.togglePendingSourceGroup(targetData.sourceIds)
                                end
                            end
                        end,
                        checked = function(_data)
                            return filters.isPendingSourceGroupSelected(sourceIds)
                        end,
                    },
                }
                if i == 1 then
                    entry.header = GetString(BATTLESCROLLS_FILTER_DAMAGE_DONE_BY)
                end
                table.insert(parametricList, entry)
            end
        end
    end

    -- Add target/unit entries
    local units = filters.getFilterableUnits(journalUI)
    for i, unit in ipairs(units) do
        local unitIds = unit.ids
        local entry = {
            template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
            text = unit.name,
            templateData = {
                unitIds = unitIds,
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    ZO_CheckButton_SetCheckState(control.checkBox, filters.isPendingGroupSelected(data.unitIds))
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetControl then
                        ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                        local targetData = dialog.entryList:GetTargetData()
                        if targetData then
                            filters.togglePendingGroup(targetData.unitIds)
                        end
                    end
                end,
                checked = function(_data)
                    return filters.isPendingGroupSelected(unitIds)
                end,
            },
        }

        if i == 1 then
            if selectedTab == StatsTab.DAMAGE_DONE then
                entry.header = GetString(BATTLESCROLLS_FILTER_DAMAGE_DONE_TO)
            elseif selectedTab == StatsTab.BOSS_DAMAGE_DONE then
                entry.header = GetString(BATTLESCROLLS_FILTER_BOSS_TARGET)
            else
                entry.header = filters.getDialogTitle(journalUI)
            end
        end

        table.insert(parametricList, entry)
    end

    return parametricList
end

-------------------------
-- Show Dialog
-------------------------

---Cleans up dialog state
local function CleanupDialogState()
    pendingFilterState = {}
    pendingSourceFilterState = {}
    cachedParametricList = {}
    BattleScrolls.gc:RequestGC(2)
end

---Shows the filter dialog
---@param journalUI BattleScrolls_Journal_Gamepad
function filters.showDialog(journalUI)
    if not journalUI.decodedEncounter then
        return
    end

    filters.initializePending(journalUI)
    cachedParametricList = filters.buildDialogEntries(journalUI)

    if #cachedParametricList == 0 then
        return
    end

    journal.dialogs.showParametricDialog({
        title = filters.getDialogTitle(journalUI),
        parametricList = cachedParametricList,
        onConfirm = function()
            filters.applyPending(journalUI)
            CleanupDialogState()
            journal.chronicler.refreshList(journalUI, true)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(journalUI.statsKeybindStripDescriptor)
        end,
        onCancel = function()
            CleanupDialogState()
        end,
        onReset = function()
            filters.resetPending()
        end,
        resetText = GetString(BATTLESCROLLS_FILTER_RESET),
    })
end

-- Export to namespace
journal.filters = filters

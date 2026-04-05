-----------------------------------------------------------
-- Pivot Config Renderer
-- Renders the query configuration form as a parametric list
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local pivot = BattleScrolls.journal.pivot
local journal = BattleScrolls.journal
local EntryBuilder = journal.EntryBuilder

local configRenderer = {}
pivot.configRenderer = configRenderer

-------------------------
-- Display Name Lookups
-------------------------

local DOMAIN_LABELS = {
    [pivot.Domain.OVERVIEW] = "BATTLESCROLLS_PIVOT_DOMAIN_OVERVIEW",
    [pivot.Domain.DAMAGE] = "BATTLESCROLLS_PIVOT_DOMAIN_DAMAGE",
    [pivot.Domain.DAMAGE_IN] = "BATTLESCROLLS_TAB_DAMAGE_TAKEN",
    [pivot.Domain.HEALING_OUT] = "BATTLESCROLLS_PIVOT_DOMAIN_HEALING_OUT",
    [pivot.Domain.HEALING_IN] = "BATTLESCROLLS_PIVOT_DOMAIN_HEALING_IN",
    [pivot.Domain.EFFECTS_SELF] = "BATTLESCROLLS_TAB_EFFECTS_PLAYER",
    [pivot.Domain.EFFECTS_BOSS] = "BATTLESCROLLS_TAB_EFFECTS_BOSS",
    [pivot.Domain.EFFECTS_GROUP] = "BATTLESCROLLS_TAB_EFFECTS_GROUP",
    [pivot.Domain.GROUP] = "BATTLESCROLLS_PIVOT_DOMAIN_GROUP",
}

local INSTANCE_MODE_LABELS = {
    [pivot.InstanceMode.EVERYTHING] = "BATTLESCROLLS_PIVOT_SCOPE_EVERYTHING",
    [pivot.InstanceMode.INSTANCED] = "BATTLESCROLLS_PIVOT_SCOPE_INSTANCED",
    [pivot.InstanceMode.OVERLAND] = "BATTLESCROLLS_PIVOT_SCOPE_OVERLAND",
    [pivot.InstanceMode.HOUSES] = "BATTLESCROLLS_PIVOT_SCOPE_HOUSES",
    [pivot.InstanceMode.PVP] = "BATTLESCROLLS_PIVOT_SCOPE_PVP",
    [pivot.InstanceMode.ZONES] = "BATTLESCROLLS_PIVOT_SCOPE_ZONES",
    [pivot.InstanceMode.SPECIFIC] = "BATTLESCROLLS_PIVOT_SCOPE_SPECIFIC",
}

---Time filter presets: key = days back (0 = today), label = string ID
---@type { days: number, label: string }[]
local TIME_PRESETS = {
    { days = 0,  label = "BATTLESCROLLS_PIVOT_TIME_TODAY" },
    { days = 1,  label = "BATTLESCROLLS_PIVOT_TIME_24H" },
    { days = 3,  label = "BATTLESCROLLS_PIVOT_TIME_3D" },
    { days = 7,  label = "BATTLESCROLLS_PIVOT_TIME_7D" },
    { days = 14, label = "BATTLESCROLLS_PIVOT_TIME_14D" },
    { days = 30, label = "BATTLESCROLLS_PIVOT_TIME_30D" },
    { days = 90, label = "BATTLESCROLLS_PIVOT_TIME_90D" },
}

local ENC_CATEGORY_LABELS = {
    [pivot.EncounterCategory.ALL] = "BATTLESCROLLS_PIVOT_ENC_ALL",
    [pivot.EncounterCategory.BOSS] = "BATTLESCROLLS_PIVOT_ENC_BOSS",
    [pivot.EncounterCategory.BOSS_NAMES] = "BATTLESCROLLS_PIVOT_ENC_BOSS_NAMES",
    [pivot.EncounterCategory.TRASH] = "BATTLESCROLLS_PIVOT_ENC_TRASH",
    [pivot.EncounterCategory.PLAYER] = "BATTLESCROLLS_PIVOT_ENC_PLAYER",
    [pivot.EncounterCategory.DUMMY] = "BATTLESCROLLS_PIVOT_ENC_DUMMY",
    [pivot.EncounterCategory.SPECIFIC] = "BATTLESCROLLS_PIVOT_ENC_SPECIFIC",
}

local TARGET_MODE_LABELS = {
    [pivot.TargetMode.ALL] = "BATTLESCROLLS_PIVOT_TARGETS_ALL",
    [pivot.TargetMode.BOSSES] = "BATTLESCROLLS_PIVOT_TARGETS_BOSSES",
}

local AGG_LABELS = {
    [pivot.Aggregation.SUM] = "BATTLESCROLLS_PIVOT_AGG_SUM",
    [pivot.Aggregation.AVG] = "BATTLESCROLLS_PIVOT_AGG_AVG",
    [pivot.Aggregation.MAX] = "BATTLESCROLLS_PIVOT_AGG_MAX",
    [pivot.Aggregation.MIN] = "BATTLESCROLLS_PIVOT_AGG_MIN",
}

---Get display text for a label string ID
---@param stringId string
---@return string
local function getLabel(stringId)
    return GetString(_G[stringId])
end

---Get display text for a dimension ID
---@param dimId string
---@return string
local function getDimensionLabel(dimId)
    return pivot.extractors.getDimensionLabel(dimId)
end

---Get display text for current column mode value
---@param query PivotQuery
---@return string
local function getColumnModeLabel(query)
    if query.columnMode == pivot.ColumnMode.METRICS then
        return getLabel("BATTLESCROLLS_PIVOT_COL_METRICS")
    end
    return getDimensionLabel(query.columnMode)
end

---Get display text for selected metrics
---@param query PivotQuery
---@return string
local function getMetricsLabel(query)
    local labels = {}
    for _, metricId in ipairs(query.metrics) do
        table.insert(labels, pivot.extractors.getMetricLabel(metricId))
    end
    return table.concat(labels, ", ")
end

-------------------------
-- Config List Rendering
-------------------------

---Render the pivot configuration form into a parametric list
---@param list ZO_ParametricScrollList
---@param query PivotQuery
---@param _journalUI BattleScrolls_Journal_Gamepad -- reserved for future selector panel
function configRenderer.render(list, query, _journalUI)
    list:Clear()

    -- SCOPE section
    -- Instance scope sublabel includes selection count for zone/specific modes
    local scopeSublabel = getLabel(INSTANCE_MODE_LABELS[query.scope.instanceMode] or "BATTLESCROLLS_PIVOT_SCOPE_EVERYTHING")
    if query.scope.instanceMode == pivot.InstanceMode.ZONES and query.scope.instanceZones then
        scopeSublabel = scopeSublabel .. " (" .. configRenderer.getSelectionSublabel(query.scope.instanceZones) .. ")"
    elseif query.scope.instanceMode == pivot.InstanceMode.SPECIFIC and query.scope.instanceIds then
        scopeSublabel = scopeSublabel .. " (" .. configRenderer.getSelectionSublabel(query.scope.instanceIds) .. ")"
    end

    local scopeEntry = EntryBuilder.addEntry(list, {
        label = getLabel("BATTLESCROLLS_PIVOT_INSTANCE_SCOPE"),
        sublabel = scopeSublabel,
        icon = "EsoUI/Art/TreeIcons/Gamepad/gp_lorelibrary_categoryicon_places.dds",
        header = getLabel("BATTLESCROLLS_PIVOT_SCOPE"),
    })
    scopeEntry.pivotField = "instanceScope"

    -- Time filter sublabel
    local timeSublabel
    if query.scope.timeMode == pivot.TimeMode.ALL then
        timeSublabel = getLabel("BATTLESCROLLS_PIVOT_TIME_ALL")
    elseif query.scope.timeFrom then
        -- Check if it matches a preset
        local daysAgo = math.floor((GetTimeStamp() - query.scope.timeFrom) / 86400)
        local matched = false
        for _, preset in ipairs(TIME_PRESETS) do
            if preset.days == daysAgo then
                timeSublabel = getLabel(preset.label)
                matched = true
                break
            end
        end
        if not matched then
            timeSublabel = zo_strformat(GetString(BATTLESCROLLS_PIVOT_CUSTOM_DAYS), daysAgo)
        end
    else
        timeSublabel = getLabel("BATTLESCROLLS_PIVOT_TIME_ALL")
    end

    local timeEntry = EntryBuilder.addEntry(list, {
        label = getLabel("BATTLESCROLLS_PIVOT_TIME_FILTER"),
        sublabel = timeSublabel,
        icon = journal.StatIcons.DURATION,
    })
    timeEntry.pivotField = "timeFilter"

    local encSublabel
    if query.scope.encounterCategory == pivot.EncounterCategory.BOSS_NAMES and query.scope.encounterBosses then
        encSublabel = getLabel("BATTLESCROLLS_PIVOT_ENC_BOSS_NAMES")
            .. " (" .. configRenderer.getSelectionSublabel(query.scope.encounterBosses) .. ")"
    else
        encSublabel = getLabel(ENC_CATEGORY_LABELS[query.scope.encounterCategory] or "BATTLESCROLLS_PIVOT_ENC_ALL")
    end

    local encEntry = EntryBuilder.addEntry(list, {
        label = getLabel("BATTLESCROLLS_PIVOT_ENCOUNTER_FILTER"),
        sublabel = encSublabel,
        icon = "EsoUI/Art/TreeIcons/Gamepad/gp_tutorial_idexIcon_combat.dds",
    })
    encEntry.pivotField = "encounterFilter"

    -- QUERY section
    local domainEntry = EntryBuilder.addEntry(list, {
        label = getLabel("BATTLESCROLLS_PIVOT_DOMAIN"),
        sublabel = getLabel(DOMAIN_LABELS[query.domain] or "BATTLESCROLLS_PIVOT_DOMAIN_DAMAGE"),
        icon = journal.StatIcons.DPS,
        header = getLabel("BATTLESCROLLS_PIVOT_QUERY"),
    })
    domainEntry.pivotField = "domain"

    -- Target filter (Damage domain only)
    if query.domain == pivot.Domain.DAMAGE then
        local targetMode = query.targetMode or pivot.TargetMode.ALL
        local targetEntry = EntryBuilder.addEntry(list, {
            label = getLabel("BATTLESCROLLS_PIVOT_TARGETS"),
            sublabel = getLabel(TARGET_MODE_LABELS[targetMode] or "BATTLESCROLLS_PIVOT_TARGETS_ALL"),
            icon = "EsoUI/Art/ZoneStories/completionTypeIcon_groupBoss.dds",
        })
        targetEntry.pivotField = "targets"
    end

    local rowEntry = EntryBuilder.addEntry(list, {
        label = getLabel("BATTLESCROLLS_PIVOT_ROWS"),
        sublabel = getDimensionLabel(query.rowDimension),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_groups.dds",
    })
    rowEntry.pivotField = "rows"

    -- Overview only supports Metrics columns (Encounter/Instance are the only dimensions)
    if query.domain ~= pivot.Domain.OVERVIEW then
        local colEntry = EntryBuilder.addEntry(list, {
            label = getLabel("BATTLESCROLLS_PIVOT_COLUMNS"),
            sublabel = getColumnModeLabel(query),
            icon = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_all.dds",
        })
        colEntry.pivotField = "columns"
    end

    local valEntry = EntryBuilder.addEntry(list, {
        label = getLabel("BATTLESCROLLS_PIVOT_VALUES"),
        sublabel = getMetricsLabel(query),
        icon = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_scoring.dds",
    })
    valEntry.pivotField = "values"

    -- Aggregation (only when needed)
    if query.aggregation then
        local aggEntry = EntryBuilder.addEntry(list, {
            label = getLabel("BATTLESCROLLS_PIVOT_AGGREGATION"),
            sublabel = getLabel(AGG_LABELS[query.aggregation] or "BATTLESCROLLS_PIVOT_AGG_AVG"),
            icon = "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_refine.dds",
            tooltip = { type = "text", title = getLabel("BATTLESCROLLS_PIVOT_AGGREGATION"), text = GetString(BATTLESCROLLS_PIVOT_TIP_AGGREGATION) },
        })
        aggEntry.pivotField = "aggregation"
    end

    list:Commit()
end

-------------------------
-- Field Option Generators
-------------------------

---Get the available options for a config field
---@param fieldName string The pivotField value
---@param query PivotQuery
---@return { key: string|any, label: string }[]
function configRenderer.getFieldOptions(fieldName, query)
    local options = {}

    if fieldName == "instanceScope" then
        for _, mode in ipairs({
            pivot.InstanceMode.EVERYTHING,
            pivot.InstanceMode.INSTANCED,
            pivot.InstanceMode.OVERLAND,
            pivot.InstanceMode.HOUSES,
            pivot.InstanceMode.PVP,
            pivot.InstanceMode.ZONES,
            pivot.InstanceMode.SPECIFIC,
        }) do
            table.insert(options, { key = mode, label = getLabel(INSTANCE_MODE_LABELS[mode]) })
        end
    elseif fieldName == "timeFilter" then
        -- "All time" as first option
        table.insert(options, { key = "all", label = getLabel("BATTLESCROLLS_PIVOT_TIME_ALL") })
        -- Inline presets (days back)
        for _, preset in ipairs(TIME_PRESETS) do
            table.insert(options, { key = preset.days, label = getLabel(preset.label) })
        end
        -- Custom input
        table.insert(options, { key = "custom", label = getLabel("BATTLESCROLLS_PIVOT_TIME_CUSTOM") })
    elseif fieldName == "encounterFilter" then
        for _, cat in ipairs({
            pivot.EncounterCategory.ALL,
            pivot.EncounterCategory.BOSS,
            pivot.EncounterCategory.BOSS_NAMES,
            pivot.EncounterCategory.TRASH,
            pivot.EncounterCategory.PLAYER,
            pivot.EncounterCategory.DUMMY,
            pivot.EncounterCategory.SPECIFIC,
        }) do
            local opt = { key = cat, label = getLabel(ENC_CATEGORY_LABELS[cat]) }
            if cat == pivot.EncounterCategory.BOSS_NAMES then
                opt.tooltip = GetString(BATTLESCROLLS_PIVOT_TIP_ENC_BOSS_NAMES)
            end
            table.insert(options, opt)
        end
    elseif fieldName == "targets" then
        for _, mode in ipairs({ pivot.TargetMode.ALL, pivot.TargetMode.BOSSES }) do
            table.insert(options, { key = mode, label = getLabel(TARGET_MODE_LABELS[mode]) })
        end
    elseif fieldName == "domain" then
        for _, domain in ipairs({
            pivot.Domain.OVERVIEW,
            pivot.Domain.DAMAGE,
            pivot.Domain.DAMAGE_IN,
            pivot.Domain.HEALING_OUT,
            pivot.Domain.HEALING_IN,
            pivot.Domain.EFFECTS_SELF,
            pivot.Domain.EFFECTS_BOSS,
            pivot.Domain.EFFECTS_GROUP,
            pivot.Domain.GROUP,
        }) do
            local opt = { key = domain, label = getLabel(DOMAIN_LABELS[domain]) }
            if domain == pivot.Domain.OVERVIEW then
                opt.tooltip = GetString(BATTLESCROLLS_PIVOT_TIP_DOMAIN_OVERVIEW)
            elseif domain == pivot.Domain.GROUP then
                opt.tooltip = GetString(BATTLESCROLLS_PIVOT_TIP_DOMAIN_GROUP)
            end
            table.insert(options, opt)
        end
    elseif fieldName == "rows" or fieldName == "columns" then
        local excludeKey = fieldName == "rows" and query.columnMode or query.rowDimension
        if fieldName == "columns" then
            table.insert(options, { key = pivot.ColumnMode.METRICS, label = getLabel("BATTLESCROLLS_PIVOT_COL_METRICS") })
        end
        local dims = pivot.DomainDimensions[query.domain] or {}
        for _, dimId in ipairs(dims) do
            if dimId ~= excludeKey then
                local opt = { key = dimId, label = getDimensionLabel(dimId) }
                if dimId == pivot.Dimension.DELIVERY then
                    opt.tooltip = GetString(BATTLESCROLLS_PIVOT_TIP_DIM_DELIVERY)
                elseif dimId == pivot.Dimension.DAMAGE_TYPE then
                    opt.tooltip = GetString(BATTLESCROLLS_PIVOT_TIP_DIM_DAMAGE_TYPE)
                end
                table.insert(options, opt)
            end
        end
    elseif fieldName == "values" then
        local metrics = pivot.DomainMetrics[query.domain] or {}
        -- When Boss is a dimension in Group domain, only show boss-compatible metrics
        local bossFilter = query.domain == pivot.Domain.GROUP
            and (query.rowDimension == pivot.Dimension.BOSS or query.columnMode == pivot.Dimension.BOSS)
            and pivot.extractors.GROUP_BOSS_METRICS or nil
        for _, metricId in ipairs(metrics) do
            if not bossFilter or bossFilter[metricId] then
                table.insert(options, { key = metricId, label = pivot.extractors.getMetricLabel(metricId) })
            end
        end
    elseif fieldName == "aggregation" then
        for _, agg in ipairs({
            pivot.Aggregation.SUM,
            pivot.Aggregation.AVG,
            pivot.Aggregation.MAX,
            pivot.Aggregation.MIN,
        }) do
            table.insert(options, { key = agg, label = getLabel(AGG_LABELS[agg]) })
        end
    end

    return options
end

-------------------------
-- Data Collection Helpers
-------------------------

---Collect unique zone names from storage history
---@return string[]
function configRenderer.collectZoneNames()
    local zones = {}
    local history = BattleScrolls.storage.savedVariables.history
    for _, instance in ipairs(history) do
        if instance.zone and instance.zone ~= "" then
            zones[instance.zone] = true
        end
    end
    local sorted = {}
    for zone in pairs(zones) do
        table.insert(sorted, zone)
    end
    table.sort(sorted)
    return sorted
end

---Collect instance entries from storage history
---@return { index: number, label: string }[]
function configRenderer.collectInstanceEntries()
    local entries = {}
    local history = BattleScrolls.storage.savedVariables.history
    for i = #history, 1, -1 do
        local instance = history[i]
        local zone = instance.zone or GetString(BATTLESCROLLS_UNKNOWN)
        local label
        if instance.timestampS then
            label = os.date("%m/%d %H:%M", instance.timestampS) .. " — " .. zone
        else
            label = zone
        end
        table.insert(entries, { index = instance.index, label = label })
    end
    return entries
end

---Collect encounters matching the instance + time scope (for specific encounter picker)
---@param scope PivotScope
---@return { key: number, label: string, instanceLabel: string }[]
function configRenderer.collectEncounters(scope)
    local filteredScope = {
        instanceMode = scope.instanceMode,
        instanceZones = scope.instanceZones,
        instanceIds = scope.instanceIds,
        timeMode = scope.timeMode,
        timeFrom = scope.timeFrom,
        timeTo = scope.timeTo,
        encounterCategory = pivot.EncounterCategory.ALL,
        encounterBosses = nil,
    }
    local scoped = pivot.engine.resolveScope(filteredScope)

    -- resolveScope returns encounters grouped by instance in ascending order.
    -- We want instances descending, encounters ascending within each.
    local groups = {}
    local curGroup = nil
    for _, se in ipairs(scoped) do
        if not curGroup or se.instance.index ~= curGroup.instIndex then
            local zone = se.instance.zone or GetString(BATTLESCROLLS_UNKNOWN)
            curGroup = {
                instIndex = se.instance.index,
                instLabel = se.instance.timestampS
                    and (os.date("%m/%d %H:%M", se.instance.timestampS) .. " — " .. zone)
                    or zone,
                encounters = {},
            }
            groups[#groups + 1] = curGroup
        end
        local name = se.encounter.displayName
        if not name or name == "" then
            name = string.format("#%d", se.encounterIndex)
        end
        local ts = se.encounter.timestampS
        local time = ts and os.date("%m/%d %H:%M", ts) or ""
        curGroup.encounters[#curGroup.encounters + 1] = {
            key = ts,
            label = time ~= "" and string.format("%s — %s", time, name) or name,
            instanceLabel = curGroup.instLabel,
        }
    end

    local result = {}
    for i = #groups, 1, -1 do
        for _, entry in ipairs(groups[i].encounters) do
            result[#result + 1] = entry
        end
    end
    return result
end

---Collect unique boss names from encounters matching the current scope
---(instance + time filters applied; encounter category forced to BOSS, boss names excluded)
---@param scope PivotScope
---@return string[]
function configRenderer.collectBossNames(scope)
    local filteredScope = {
        instanceMode = scope.instanceMode,
        instanceZones = scope.instanceZones,
        instanceIds = scope.instanceIds,
        timeMode = scope.timeMode,
        timeFrom = scope.timeFrom,
        timeTo = scope.timeTo,
        encounterCategory = pivot.EncounterCategory.BOSS,
        encounterIds = nil,
        encounterBosses = nil,
    }
    local scopedEncounters = pivot.engine.resolveScope(filteredScope)
    local bosses = {}
    for _, se in ipairs(scopedEncounters) do
        if se.encounter.bossSeqNames then
            for _, name in pairs(se.encounter.bossSeqNames) do
                bosses[name] = true
            end
        end
    end
    local sorted = {}
    for name in pairs(bosses) do
        table.insert(sorted, name)
    end
    table.sort(sorted)
    return sorted
end

-------------------------
-- Checkbox Dialog Helpers
-------------------------

---Build checkbox parametric list entries for a dialog
---@param items { key: any, label: string, header: string|nil }[]
---@param pendingState table<any, boolean>
---@return table[]
function configRenderer.buildCheckboxEntries(items, pendingState)
    local entries = {}
    for _, item in ipairs(items) do
        table.insert(entries, {
            template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
            text = item.label,
            header = item.header,
            templateData = {
                key = item.key,
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    ZO_CheckButton_SetCheckState(control.checkBox, pendingState[data.key] == true)
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetControl then
                        ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                        local targetData = dialog.entryList:GetTargetData()
                        if targetData then
                            pendingState[targetData.key] = not pendingState[targetData.key]
                        end
                    end
                end,
            },
        })
    end
    return entries
end

---Show a checkbox selection dialog
---@param title string
---@param items { key: any, label: string }[]
---@param currentSelection table<any, boolean>|nil
---@param onConfirm fun(selected: table<any, boolean>|nil)
---@param onCancel fun()|nil Called on cancel (receives dialog as first arg)
---@param reopenAction fun()|nil If set, re-opens this action after cancel animation completes
function configRenderer.showCheckboxDialog(title, items, currentSelection, onConfirm, onCancel, reopenAction)
    if #items == 0 then
        if onCancel then onCancel() end
        return
    end

    local pendingState = {}
    for _, item in ipairs(items) do
        pendingState[item.key] = currentSelection and currentSelection[item.key] or false
    end

    local entries = configRenderer.buildCheckboxEntries(items, pendingState)

    journal.dialogs.showParametricDialog({
        title = title,
        parametricList = entries,
        onConfirm = function()
            local selected = {}
            local anySelected = false
            for key, sel in pairs(pendingState) do
                if sel then
                    selected[key] = true
                    anySelected = true
                end
            end
            onConfirm(anySelected and selected or nil)
        end,
        onCancel = function(dialog)
            if onCancel then onCancel() end
            if reopenAction and dialog then
                dialog.nextAction = reopenAction
            end
        end,
        resetText = GetString(BATTLESCROLLS_PIVOT_SELECT_ALL),
        onReset = function()
            for key in pairs(pendingState) do
                pendingState[key] = true
            end
        end,
        deselectAllText = GetString(BATTLESCROLLS_PIVOT_DESELECT_ALL),
        onDeselectAll = function()
            for key in pairs(pendingState) do
                pendingState[key] = false
            end
        end,
    })
end

---Get a sublabel describing a selection count
---@param selection table<any, boolean>|nil
---@return string
function configRenderer.getSelectionSublabel(selection)
    if not selection then
        return getLabel("BATTLESCROLLS_PIVOT_NONE_SELECTED")
    end
    local count = 0
    for _, v in pairs(selection) do
        if v then count = count + 1 end
    end
    if count == 0 then
        return getLabel("BATTLESCROLLS_PIVOT_NONE_SELECTED")
    end
    return zo_strformat(GetString(BATTLESCROLLS_PIVOT_SELECTED_COUNT), count)
end

-------------------------
-- Query State Helpers
-------------------------

---Metrics shared between multiple domains — domain prefix needed for disambiguation
local AMBIGUOUS_METRICS = {
    [pivot.Metric.DPS] = true,
    [pivot.Metric.TOTAL_DAMAGE] = true,
    [pivot.Metric.CRIT_PERCENT] = true,
    [pivot.Metric.HIT_COUNT] = true,
    [pivot.Metric.MAX_HIT] = true,
    [pivot.Metric.MIN_HIT] = true,
    [pivot.Metric.AVG_HIT] = true,
    [pivot.Metric.RAW_HEALING] = true,
    [pivot.Metric.EFFECTIVE_HEALING] = true,
    [pivot.Metric.RAW_HPS] = true,
    [pivot.Metric.EFFECTIVE_HPS] = true,
    [pivot.Metric.OVERHEAL_PERCENT] = true,
    [pivot.Metric.HEAL_CRIT_PERCENT] = true,
    [pivot.Metric.HEAL_HIT_COUNT] = true,
    [pivot.Metric.MAX_HEAL] = true,
    [pivot.Metric.AVG_HEAL] = true,
    [pivot.Metric.UPTIME_PERCENT] = true,
    [pivot.Metric.PLAYER_UPTIME_PERCENT] = true,
    [pivot.Metric.APPLICATIONS] = true,
    [pivot.Metric.MAX_STACKS_TIME_PERCENT] = true,
}

---Generate a natural text description of the query
---@param query PivotQuery
---@return string
function configRenderer.describeQuery(query)
    -- Metric part
    local metricPart
    local firstMetric = query.metrics[1]
    if #query.metrics == 1 then
        metricPart = pivot.extractors.getMetricLabel(firstMetric)
        -- Prefix domain when the metric is ambiguous across domains
        if AMBIGUOUS_METRICS[firstMetric] then
            metricPart = getLabel(DOMAIN_LABELS[query.domain] or "BATTLESCROLLS_PIVOT_DOMAIN_DAMAGE") .. " " .. metricPart
        end
    else
        metricPart = zo_strformat(GetString(BATTLESCROLLS_PIVOT_DESC_N_METRICS), #query.metrics)
        -- Prefix domain when all selected metrics are ambiguous
        local allAmbiguous = true
        for _, m in ipairs(query.metrics) do
            if not AMBIGUOUS_METRICS[m] then
                allAmbiguous = false
                break
            end
        end
        if allAmbiguous then
            metricPart = getLabel(DOMAIN_LABELS[query.domain] or "BATTLESCROLLS_PIVOT_DOMAIN_DAMAGE") .. " " .. metricPart
        end
    end

    -- "Metrics by Row"
    local desc = zo_strformat(GetString(BATTLESCROLLS_PIVOT_DESC_BY), metricPart, getDimensionLabel(query.rowDimension))

    -- "× Column" for cross-dimension
    if query.columnMode ~= pivot.ColumnMode.METRICS then
        desc = desc .. " " .. zo_strformat(GetString(BATTLESCROLLS_PIVOT_DESC_CROSS), getDimensionLabel(query.columnMode))
    end

    -- Aggregation method
    if query.aggregation then
        desc = desc .. " (" .. getLabel(AGG_LABELS[query.aggregation]) .. ")"
    end

    -- Scope qualifiers (only when narrowed from defaults)
    local qualifiers = {}
    if query.targetMode == pivot.TargetMode.BOSSES then
        qualifiers[#qualifiers + 1] = getLabel("BATTLESCROLLS_PIVOT_TARGETS_BOSSES")
    end
    local scope = query.scope
    if scope.encounterCategory ~= pivot.EncounterCategory.ALL then
        qualifiers[#qualifiers + 1] = getLabel(ENC_CATEGORY_LABELS[scope.encounterCategory])
    end
    if scope.timeMode == pivot.TimeMode.CUSTOM and scope.timeFrom then
        local daysAgo = math.floor((GetTimeStamp() - scope.timeFrom) / 86400)
        qualifiers[#qualifiers + 1] = zo_strformat(GetString(BATTLESCROLLS_PIVOT_CUSTOM_DAYS), daysAgo)
    end
    if scope.instanceMode ~= pivot.InstanceMode.EVERYTHING then
        qualifiers[#qualifiers + 1] = getLabel(INSTANCE_MODE_LABELS[scope.instanceMode])
    end
    if #qualifiers > 0 then
        desc = desc .. " — " .. table.concat(qualifiers, ", ")
    end

    return desc
end


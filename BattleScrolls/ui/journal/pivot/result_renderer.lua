-----------------------------------------------------------
-- Pivot Result Renderer
-- Renders pivot query results as a sortable table
--
-- Uses ZO_GamepadInteractiveSortFilterList as a base,
-- with dynamic column creation from the PivotResult columns.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local pivot = BattleScrolls.journal.pivot

local PivotTable = ZO_GamepadInteractiveSortFilterList:Subclass()
local DATA_TYPE = 1

local resultRenderer = {}
pivot.resultRenderer = resultRenderer

-------------------------
-- Column Layout Constants
-------------------------

local COL_VALUE_WIDTH = 90
local COL_ROW_LABEL_MIN = 140
local ROW_HEIGHT = 65
local HIGHLIGHT_PAD = ZO_GAMEPAD_INTERACTIVE_FILTER_HIGHLIGHT_PADDING  -- 10
local ARROW_PAD = ZO_GAMEPAD_INTERACTIVE_FILTER_ARROW_PADDING  -- 15
local HEADER_DOUBLE_PAD = ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X

-------------------------
-- Sort Keys (built dynamically)
-------------------------

---Build sort keys table from PivotResult columns
---@param columns string[]
---@return table
local function buildSortKeys(columns)
    local keys = {}
    -- Row label is always sortable by name
    keys["rowLabel"] = { isNumeric = false }

    -- Value columns are numeric, tiebreak to rowLabel
    for _, colKey in ipairs(columns) do
        local safeKey = "col_" .. colKey
        keys[safeKey] = { isNumeric = true, tiebreaker = "rowLabel" }
    end

    return keys
end

-------------------------
-- PivotTable Class
-------------------------

function PivotTable:Initialize(control)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)
    -- Base Initialize calls self:InitializeSortFilterList and self:InitializeKeybinds

    -- Hide filter UI (search/dropdown) — same pattern as GroupTable
    self:RemoveFilters()

    -- Hide content header and re-anchor Headers higher
    if self.contentHeader then
        self.contentHeader:SetHidden(true)
        self.contentHeader:SetHeight(0)
    end
    local headers = self.container:GetNamedChild("Headers")
    if headers then
        headers:ClearAnchors()
        headers:SetAnchor(TOPLEFT, self.container, TOPLEFT, ZO_GAMEPAD_INTERACTIVE_FILTER_HIGHLIGHT_PADDING, 15)
        headers:SetAnchor(TOPRIGHT, self.container, TOPRIGHT, 0, 15)
    end

    -- State
    self.pivotResult = nil
    self.masterList = {}
    self.columnKeys = {}
    self.columnLabels = {}
    self._headerControls = {}
    self._fragmentAdded = false

    -- Replace default focus animation (0.4↔1.0) with custom (0.7↔1.0)
    local fadeTimeline = ANIMATION_MANAGER:CreateTimeline()
    local fadeAnim = fadeTimeline:InsertAnimation(ANIMATION_ALPHA, self.list, 0)
    fadeAnim:SetDuration(150)
    fadeAnim:SetAlphaValues(0.7, 1)
    self.list.focusedChangedAnimation = fadeTimeline
end

function PivotTable:InitializeSortFilterList(control)
    ZO_GamepadInteractiveSortFilterList.InitializeSortFilterList(self, control)

    -- Register row data type
    ZO_ScrollList_AddDataType(self.list, DATA_TYPE, "ZO_GamepadInteractiveSortFilterListRow", ROW_HEIGHT, function(rowControl, data)
        self:SetupRow(rowControl, data)
    end)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
end

function PivotTable:InitializeKeybinds()
    -- Exact same pattern as GroupTable: set focal area keybinds directly,
    -- do NOT call base InitializeKeybinds.

    -- Header: A button sorts by selected column
    local headerKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SORT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self.sortHeaderGroup:SortBySelected()
            end,
        },
    }

    if self.headersFocalArea then
        self.headersFocalArea:SetKeybindDescriptor(headerKeybindStripDescriptor)
    end

    -- Panel: primary action selects a row (callback set externally via onRowSelected)
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedData = ZO_ScrollList_GetSelectedData(self.list)
                if selectedData and self.onRowSelected then
                    self.onRowSelected(selectedData)
                end
            end,
            visible = function()
                return self.onRowSelected ~= nil
            end,
        },
    }
    self.panelFocalArea:SetKeybindDescriptor(self.keybindStripDescriptor)
end


---Show the pivot result table
---@param pivotResult PivotResult
---@param _parentControl Control Parent to anchor to (reserved)
function PivotTable:Show(pivotResult, _parentControl)
    self.pivotResult = pivotResult
    self.columnKeys = pivotResult.columns
    self.columnLabels = pivotResult.columnLabels

    -- Build dynamic sort keys
    self.sortKeys = buildSortKeys(self.columnKeys)
    self.currentSortKey = self.columnKeys[1] and ("col_" .. self.columnKeys[1]) or "rowLabel"
    self.currentSortOrder = ZO_SORT_ORDER_DOWN

    -- Setup headers dynamically
    self:SetupHeaders()

    -- Show via scene fragment (before RefreshData, matching GroupTable pattern)
    if not self._fragmentAdded and BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE then
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(self.listFragment)
        self._fragmentAdded = true
    end

    -- Refresh data
    self:RefreshData()

    -- Auto-activate so the table is scrollable immediately
    self:Activate()
end

function PivotTable:Hide()
    if self.isActive then
        self:Deactivate()
    end
    if self._fragmentAdded and BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE then
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:RemoveFragment(self.listFragment)
        self._fragmentAdded = false
    end
    self.pivotResult = nil
    self.masterList = {}
end

function PivotTable:Enter()
    self:Activate()
end

function PivotTable:Leave()
    self:Deactivate()
end

function PivotTable:IsActive()
    return self.isActive or false
end

-------------------------
-- Dynamic Header Setup
-------------------------

function PivotTable:SetupHeaders()
    local headersControl = self.headersContainer
    if not headersControl then return end

    -- Hide existing dynamic headers
    for _, hdr in pairs(self._headerControls) do
        hdr:SetHidden(true)
    end

    -- Compute widths: subtract scrollbar width (rows are in Content, narrower than Headers)
    local numCols = #self.columnKeys
    local valueWidth = COL_VALUE_WIDTH
    local rawWidth = (headersControl:GetWidth() > 0) and headersControl:GetWidth() or 1050
    local totalWidth = rawWidth - ZO_SCROLL_BAR_WIDTH
    local valueTotalWidth = numCols * valueWidth + math.max(0, numCols - 1) * HEADER_DOUBLE_PAD
    local nameWidth = totalWidth - HIGHLIGHT_PAD - valueTotalWidth - HEADER_DOUBLE_PAD
    if nameWidth < COL_ROW_LABEL_MIN then nameWidth = COL_ROW_LABEL_MIN end
    self._nameWidth = nameWidth

    -- Row label header (positional key so headers are reused across queries)
    local rowLabelHeader = self:GetOrCreateHeader("header_0", headersControl)
    rowLabelHeader:SetWidth(nameWidth)
    rowLabelHeader:ClearAnchors()
    rowLabelHeader:SetAnchor(TOPLEFT, headersControl, TOPLEFT, HIGHLIGHT_PAD, 0)
    rowLabelHeader:SetHidden(false)

    if self.sortHeaderGroup then
        -- Clear existing headers (no RemoveAllHeaders API)
        self.sortHeaderGroup:DeselectHeader()
        ZO_ClearNumericallyIndexedTable(self.sortHeaderGroup.sortHeaders)
        self.sortHeaderGroup.selectedIndex = nil

        ZO_GamepadInteractiveSortFilterHeader_Initialize(rowLabelHeader,
            self.pivotResult.rowDimensionLabel, "rowLabel", TEXT_ALIGN_LEFT)
        self.sortHeaderGroup:AddHeader(rowLabelHeader)
    end

    -- Value column headers: chain after Name with HEADER_DOUBLE_PAD spacing
    local prevHeader = rowLabelHeader
    for i, colKey in ipairs(self.columnKeys) do
        local safeKey = "col_" .. colKey
        local header = self:GetOrCreateHeader("header_" .. i, headersControl)
        header:SetWidth(valueWidth)
        header:ClearAnchors()
        header:SetAnchor(TOPLEFT, prevHeader, TOPRIGHT, HEADER_DOUBLE_PAD, 0)
        header:SetHidden(false)

        local label = zo_strformat(SI_UNIT_NAME, self.columnLabels[colKey] or colKey)
        if self.sortHeaderGroup then
            ZO_GamepadInteractiveSortFilterHeader_Initialize(header,
                label, safeKey, TEXT_ALIGN_RIGHT)
            self.sortHeaderGroup:AddHeader(header)
        end

        prevHeader = header
    end

    -- Select default sort column
    if self.sortHeaderGroup and self.currentSortKey then
        self.sortHeaderGroup:SelectHeaderByKey(self.currentSortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, nil, ZO_SORT_ORDER_DOWN)
    end
end

---Get or create a header control
---@param key string
---@param parent Control
---@return Control
function PivotTable:GetOrCreateHeader(key, parent)
    if self._headerControls[key] then
        return self._headerControls[key]
    end

    local name = parent:GetName() .. "_" .. key
    local header = CreateControlFromVirtual(name, parent, "ZO_GamepadInteractiveFilterHeader")
    self._headerControls[key] = header
    return header
end

-------------------------
-- Data Population
-------------------------

function PivotTable:BuildMasterList()
    self.masterList = {}
    if not self.pivotResult then return end

    for _, row in ipairs(self.pivotResult.rows) do
        local entry = {
            rowLabel = row.key,
            values = row.values,
            instanceIndex = row.instanceIndex,
            encounterIndex = row.encounterIndex,
        }

        -- Set sort values for each column (dynamic keys for sort infrastructure)
        for _, colKey in ipairs(self.columnKeys) do
            local safeKey = "col_" .. colKey
            ---@diagnostic disable-next-line: assign-type-mismatch -- dynamic sort key on untyped table
            entry[safeKey] = row.values[colKey] or 0
        end

        table.insert(self.masterList, entry)
    end
end

function PivotTable:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, entry in ipairs(self.masterList) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE, entry))
    end
end

function PivotTable:CommitScrollList()
    -- Assign ranks
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    for i, dataEntry in ipairs(scrollData) do
        dataEntry.data.rank = i
    end
    ZO_GamepadInteractiveSortFilterList.CommitScrollList(self)
end

-------------------------
-- Row Rendering
-------------------------

---Configure row column controls (only once per column configuration change)
function PivotTable:ConfigureRowColumns(rowControl)
    local numCols = #self.columnKeys
    local nameWidth = self._nameWidth or COL_ROW_LABEL_MIN

    -- Name label: stretchy, left-aligned, vertically centered
    local nameLabel = rowControl:GetNamedChild("Name")
    if not nameLabel then
        nameLabel = CreateControl(rowControl:GetName() .. "Name", rowControl, CT_LABEL)
        nameLabel:SetFont("ZoFontGamepadBold27")
        nameLabel:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        nameLabel:SetMaxLineCount(1)
        nameLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        nameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    end
    nameLabel:ClearAnchors()
    nameLabel:SetWidth(nameWidth)
    nameLabel:SetAnchor(LEFT, rowControl, LEFT, HIGHLIGHT_PAD, 0)

    -- Value cells: wrapper Control + inner Label (matching GroupTable pattern)
    -- Chain anchored after Name with same spacing as headers
    local prevControl = nameLabel
    for i = 1, numCols do
        local wrapperName = rowControl:GetName() .. "Col" .. i
        local wrapper = rowControl:GetNamedChild("Col" .. i)
        if not wrapper then
            wrapper = CreateControl(wrapperName, rowControl, CT_CONTROL)
            local inner = CreateControl(wrapperName .. "Label", wrapper, CT_LABEL)
            inner:SetFont("ZoFontGamepad27")
            inner:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
            inner:SetVerticalAlignment(TEXT_ALIGN_CENTER)
            inner:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
            inner:SetAnchor(LEFT, wrapper, LEFT, 0, 0)
            inner:SetAnchor(RIGHT, wrapper, RIGHT, -ARROW_PAD, 0)
        end

        wrapper:SetDimensions(COL_VALUE_WIDTH, ROW_HEIGHT)
        wrapper:ClearAnchors()
        wrapper:SetAnchor(LEFT, prevControl, RIGHT, HEADER_DOUBLE_PAD, 0)
        wrapper:SetHidden(false)
        prevControl = wrapper
    end

    -- Hide extra columns from previous configurations
    local idx = numCols + 1
    while true do
        local extra = rowControl:GetNamedChild("Col" .. idx)
        if not extra then break end
        extra:SetHidden(true)
        idx = idx + 1
    end

    rowControl._pivotColCount = numCols
end

function PivotTable:SetupRow(rowControl, data)
    -- Configure columns only when count changes
    if rowControl._pivotColCount ~= #self.columnKeys then
        self:ConfigureRowColumns(rowControl)
    end

    -- Set name (zo_strformat strips ESO grammar annotations like ^m)
    local nameLabel = rowControl:GetNamedChild("Name")
    if nameLabel then
        nameLabel:SetText(zo_strformat(SI_UNIT_NAME, data.rowLabel or ""))
    end

    -- Set value cells
    local query = self.pivotResult and self.pivotResult.query
    local metricIds = query and query.metrics or {}

    for i, colKey in ipairs(self.columnKeys) do
        local wrapper = rowControl:GetNamedChild("Col" .. i)
        if wrapper then
            local inner = wrapper:GetNamedChild("Label")
            if inner then
                local value = data.values and data.values[colKey] or 0
                local formatter
                if query and query.columnMode == pivot.ColumnMode.METRICS then
                    formatter = pivot.extractors.getMetricFormatter(colKey)
                else
                    formatter = pivot.extractors.getMetricFormatter(metricIds[1])
                end
                inner:SetText(formatter(value))
            end
        end
    end
end

-------------------------
-- Module Interface
-------------------------

local pivotTableInstance = nil

---Get or create the singleton pivot table
---@param control Control The parent control from journal.xml
function resultRenderer.getInstance(control)
    if not pivotTableInstance then
        pivotTableInstance = PivotTable:New(control)
    end
    return pivotTableInstance
end

---Set a callback invoked when a row is selected via primary keybind
---@param callback fun(data: table)|nil
function resultRenderer.setOnRowSelected(callback)
    if pivotTableInstance then
        pivotTableInstance.onRowSelected = callback
        -- Refresh keybind visibility so the primary action appears/disappears immediately
        if pivotTableInstance.keybindStripDescriptor then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(pivotTableInstance.keybindStripDescriptor)
        end
    end
end

---Show results
---@param pivotResult PivotResult
---@param parentControl Control
function resultRenderer.show(pivotResult, parentControl)
    local instance = resultRenderer.getInstance(parentControl)
    instance:Show(pivotResult, parentControl)
end

---Hide results (full teardown: removes fragment)
function resultRenderer.hide()
    if pivotTableInstance then
        pivotTableInstance:Hide()
    end
end

---Enter the table (activate gamepad focus)
function resultRenderer.enter()
    if pivotTableInstance then
        pivotTableInstance:Enter()
    end
end

---Leave the table
function resultRenderer.leave()
    if pivotTableInstance then
        pivotTableInstance:Leave()
    end
end

---Check if the table is active
---@return boolean
function resultRenderer.isActive()
    return pivotTableInstance ~= nil and pivotTableInstance:IsActive()
end

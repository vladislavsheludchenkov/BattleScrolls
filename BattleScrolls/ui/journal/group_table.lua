-----------------------------------------------------------
-- Group Table
-- Sortable table for Group tab overview using
-- ZO_GamepadInteractiveSortFilterList subclass.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then return end

local journal = BattleScrolls.journal
local utils = journal.utils

local ROW_HEIGHT = 65
local DATA_TYPE = 1 -- ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE
local PADDING = ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
local HIGHLIGHT_PAD = ZO_GAMEPAD_INTERACTIVE_FILTER_HIGHLIGHT_PADDING
local ARROW_PAD = ZO_GAMEPAD_INTERACTIVE_FILTER_ARROW_PADDING

local MAX_BOSSES = 4
local INACTIVE_LIST_ALPHA = 0.7
local FADE_DURATION_MS = 150

local SORT_KEYS = {
    displayName = {},  -- Terminal sort key (unique per player, no tiebreaker needed)
    dps         = { isNumeric = true, tiebreaker = "displayName" },
    boss1Dps    = { isNumeric = true, tiebreaker = "dps" },
    boss2Dps    = { isNumeric = true, tiebreaker = "dps" },
    boss3Dps    = { isNumeric = true, tiebreaker = "dps" },
    boss4Dps    = { isNumeric = true, tiebreaker = "dps" },
    critPercent = { isNumeric = true, tiebreaker = "dps" },
    dtps        = { isNumeric = true, tiebreaker = "dps" },
    hps         = { isNumeric = true, tiebreaker = "dps" },
    alive       = { isNumeric = true, tiebreaker = "dps" },
    deaths      = { isNumeric = true, tiebreaker = "dps" },
}

-- Column widths (px)
local COL_RANK  = 40
local COL_BOSS_MIN  = 110
local COL_BOSS_STEP = 45  -- extra width per missing boss (245/200/155/110 for 1/2/3/4)
local COL_DPS   = 90
local COL_CRIT  = 60
local COL_DTPS  = 80
local COL_HPS   = 80
local COL_ALIVE = 70
local COL_DEATHS = 80

---@diagnostic disable-next-line: undefined-doc-class -- ESO API base class
---@class BattleScrolls_GroupTable : ZO_GamepadInteractiveSortFilterList
local GroupTable = ZO_GamepadInteractiveSortFilterList:Subclass()

function GroupTable:New(control)
    return ZO_GamepadInteractiveSortFilterList.New(self, control)
end

-------------------------
-- Initialization
-------------------------

function GroupTable:InitializeSortFilterList(control)
    -- Set header sort keys BEFORE base scans via AddHeadersFromContainer
    local headers = self.container:GetNamedChild("Headers")

    -- Rank: display-only, no sort key (uses disabled header template)
    local rankHeader = headers:GetNamedChild("Rank")
    if rankHeader then
        local label = rankHeader:GetNamedChild("Name")
        if label then
            label:SetText("#")
            label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        end
    end

    -- Native gamepad pattern: right-aligned headers have -15px arrow padding
    -- (ZO_GAMEPAD_INTERACTIVE_FILTER_ARROW_PADDING). Row cells use matching inset
    -- via wrapper Control + inner Label (see XML template).
    local function initSortHeader(name, text, key, align)
        local h = headers:GetNamedChild(name)
        if h then
            ZO_GamepadInteractiveSortFilterHeader_Initialize(h, text, key, align or TEXT_ALIGN_RIGHT)
        end
    end

    initSortHeader("Name", GetString(BATTLESCROLLS_GROUP_COL_NAME), "displayName", TEXT_ALIGN_LEFT)
    initSortHeader("Boss1", "", "boss1Dps")
    initSortHeader("Boss2", "", "boss2Dps")
    initSortHeader("Boss3", "", "boss3Dps")
    initSortHeader("Boss4", "", "boss4Dps")
    initSortHeader("DPS", GetString(BATTLESCROLLS_STAT_DPS), "dps")
    initSortHeader("Crit", GetString(BATTLESCROLLS_GROUP_COL_CRIT), "critPercent")
    initSortHeader("DTPS", GetString(BATTLESCROLLS_STAT_DTPS), "dtps")
    initSortHeader("HPS", GetString(BATTLESCROLLS_STAT_HPS), "hps")
    initSortHeader("Alive", GetString(BATTLESCROLLS_GROUP_COL_ALIVE), "alive")
    initSortHeader("Deaths", GetString(BATTLESCROLLS_GROUP_COL_DEATHS), "deaths")

    -- Base call creates sortHeaderGroup, list, sortFunction
    ZO_GamepadInteractiveSortFilterList.InitializeSortFilterList(self, control)

    -- Register row data type
    ZO_ScrollList_AddDataType(self.list, DATA_TYPE, "BattleScrolls_GroupTableRow", ROW_HEIGHT,
        function(rowControl, data) self:SetupRow(rowControl, data) end)

    -- Default sort: DPS descending
    self.sortKeys = SORT_KEYS
    self.currentSortKey = "dps"
    self.currentSortOrder = ZO_SORT_ORDER_DOWN
    if self.sortHeaderGroup then
        self.sortHeaderGroup:SelectHeaderByKey("dps", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, nil, ZO_SORT_ORDER_DOWN)
    end
end

function GroupTable:InitializeKeybinds()
    -- Header sort keybind: A button triggers sort on selected column header
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

    -- Panel keybind: A button selects row → fires onRowSelected callback
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
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }
    self.panelFocalArea:SetKeybindDescriptor(self.keybindStripDescriptor)
end

function GroupTable:Initialize(control)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)

    -- Hide filter UI (search/dropdown)
    self:RemoveFilters()

    -- Hide content header and re-anchor Headers higher
    if self.contentHeader then
        self.contentHeader:SetHidden(true)
        self.contentHeader:SetHeight(0)
    end
    local headers = self.container:GetNamedChild("Headers")
    if headers then
        headers:ClearAnchors()
        headers:SetAnchor(TOPLEFT, self.container, TOPLEFT, HIGHLIGHT_PAD, 15)
        headers:SetAnchor(TOPRIGHT, self.container, TOPRIGHT, 0, 15)
    end

    -- State
    self.bossCount = 0
    self.bossColWidth = 0
    self.bossKeys = {}
    self.nameWidth = 500
    self.members = nil
    self.masterList = {}
    self.fragmentAdded = false

    -- Hide boss sort headers initially
    if self.sortHeaderGroup then
        for i = 1, MAX_BOSSES do
            self.sortHeaderGroup:SetHeaderHiddenForKey(string.format("boss%dDps", i), true)
        end
    end

    -- Replace the default focus animation (0.4↔1.0) with a custom one (0.7↔1.0)
    -- so the table is more readable when visible but not entered
    local fadeTimeline = ANIMATION_MANAGER:CreateTimeline()
    local fadeAnim = fadeTimeline:InsertAnimation(ANIMATION_ALPHA, self.list, 0)
    fadeAnim:SetDuration(FADE_DURATION_MS)
    fadeAnim:SetAlphaValues(INACTIVE_LIST_ALPHA, 1)
    self.list.focusedChangedAnimation = fadeTimeline
end

-------------------------
-- Public API
-------------------------

---@param journalUI BattleScrolls_Journal_Gamepad
function GroupTable:Show(journalUI)
    local arithmancer = journalUI.arithmancer
    local enc = journalUI.decodedEncounter
    if not arithmancer or not enc then return end

    local ctx = {
        arithmancer = arithmancer,
        encounter = enc,
        durationS = arithmancer:getDurationS(),
    }

    local members = journal.renderers.group.buildMemberList(ctx)
    if #members == 0 then return end
    self.members = members

    -- Discover boss columns: collect all unique bosses, pick top by total damage dealt
    local bossDamageTotal = {}
    for _, member in ipairs(members) do
        if member.data.bossDamage then
            for _, bd in ipairs(member.data.bossDamage) do
                local key = string.format("%s:%d", bd.bossTag, bd.tagSeq)
                bossDamageTotal[key] = (bossDamageTotal[key] or 0) + bd.damage
            end
        end
    end
    local bossKeys = {}
    for key in pairs(bossDamageTotal) do
        table.insert(bossKeys, key)
    end
    table.sort(bossKeys, function(a, b)
        return bossDamageTotal[a] > bossDamageTotal[b]
    end)
    if #bossKeys > MAX_BOSSES then
        for i = #bossKeys, MAX_BOSSES + 1, -1 do bossKeys[i] = nil end
    end
    self.bossKeys = bossKeys

    -- Resolve boss display names
    local bossNames = {}
    for _, key in ipairs(bossKeys) do
        local tag = key:match("^(.+):%d+$")
        local name = enc.bossSeqNames and enc.bossSeqNames[key]
        table.insert(bossNames, zo_strformat(SI_UNIT_NAME, name or tag or key))
    end

    self:ConfigureBossColumns(bossNames)

    -- Show via scene fragment system (ESO requires fragments for visibility)
    if not self.fragmentAdded then
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:AddFragment(self.listFragment)
        self.fragmentAdded = true
    end

    self:RefreshData()

    -- Start at inactive brightness (fixes first-open being at full alpha before Enter)
    self.list:SetAlpha(INACTIVE_LIST_ALPHA)
end

function GroupTable:Hide()
    if self.isActive then
        self:Deactivate()
    end
    -- Always remove fragment (safe even when scene is hiding/hidden — just dequeues
    -- the fragment so it won't reappear next time the scene shows)
    if self.fragmentAdded then
        BATTLESCROLLS_JOURNAL_GAMEPAD_SCENE:RemoveFragment(self.listFragment)
        self.fragmentAdded = false
    end
    self.members = nil
end

function GroupTable:Enter()
    self:Activate()
end

function GroupTable:Leave()
    self:Deactivate()
end

function GroupTable:IsActive()
    return self.isActive == true
end

-------------------------
-- Column Layout
-------------------------

---@param bossNames string[]
function GroupTable:ConfigureBossColumns(bossNames)
    self.bossCount = #bossNames
    self.bossColWidth = self.bossCount > 0
        and (COL_BOSS_MIN + COL_BOSS_STEP * (MAX_BOSSES - self.bossCount))
        or 0
    local headers = self.container:GetNamedChild("Headers")

    -- Show/hide boss headers, set text and dynamic width
    for i = 1, MAX_BOSSES do
        local bossHeader = headers:GetNamedChild("Boss" .. i)
        if bossHeader then
            local visible = i <= self.bossCount
            bossHeader:SetHidden(not visible)
            if visible then
                bossHeader:SetWidth(self.bossColWidth)
                local label = bossHeader:GetNamedChild("Name")
                if label then label:SetText(bossNames[i]) end
            end
        end
    end

    -- DPS header text: "Total" when bosses present, "DPS" otherwise
    local dpsHeader = headers:GetNamedChild("DPS")
    if dpsHeader then
        local label = dpsHeader:GetNamedChild("Name")
        if label then
            label:SetText(self.bossCount > 0
                and GetString(BATTLESCROLLS_GROUP_COL_TOTAL)
                or GetString(BATTLESCROLLS_STAT_DPS))
        end
    end

    -- Compute Name column width (stretchy: absorbs remaining space).
    -- Subtract ZO_SCROLL_BAR_WIDTH because rows live in the Content area which is
    -- narrower than Headers by the scrollbar width. Using the content-area width for
    -- both headers and rows keeps all columns aligned.
    local rightFixed = COL_DPS + COL_CRIT + COL_DTPS + COL_HPS + COL_ALIVE + COL_DEATHS + (5 * PADDING)
    local bossWidth = self.bossCount * (self.bossColWidth + PADDING)
    local rawWidth = (headers:GetWidth() > 0) and headers:GetWidth() or 1050
    local totalWidth = rawWidth - ZO_SCROLL_BAR_WIDTH
    self.nameWidth = totalWidth - COL_RANK - PADDING - bossWidth - rightFixed - PADDING
                   - HIGHLIGHT_PAD
    if self.nameWidth < 60 then self.nameWidth = 60 end

    -- Set Name header width
    local nameHeader = headers:GetNamedChild("Name")
    if nameHeader then nameHeader:SetWidth(self.nameWidth) end

    -- Re-anchor DPS header after last visible boss (or Name when no bosses)
    if dpsHeader then
        local prev = nameHeader
        if self.bossCount > 0 then
            prev = headers:GetNamedChild("Boss" .. self.bossCount)
        end
        dpsHeader:ClearAnchors()
        dpsHeader:SetAnchor(TOPLEFT, prev, TOPRIGHT, PADDING, 0)
    end

    -- Update sort header group
    if self.sortHeaderGroup then
        for i = 1, MAX_BOSSES do
            self.sortHeaderGroup:SetHeaderHiddenForKey(
                string.format("boss%dDps", i), i > self.bossCount)
        end
    end
end

--- Configures dynamic columns on a row: Name width, boss visibility, DPS predecessor.
--- The static tail (Crit→DTPS→HPS→Alive) is anchored via XML $(parent) relativeTo.
--- Only runs when the boss configuration has changed for this row control.
---@param rowControl Control
function GroupTable:ConfigureRowColumns(rowControl)
    local name = rowControl:GetNamedChild("Name")
    if name then
        name:ClearAnchors()
        name:SetAnchor(LEFT, rowControl:GetNamedChild("Rank"), RIGHT, PADDING, 0)
        name:SetWidth(self.nameWidth)
    end

    -- Show/hide boss columns, set dynamic width, and chain after Name
    local prev = name
    for i = 1, MAX_BOSSES do
        local boss = rowControl:GetNamedChild("Boss" .. i)
        if boss then
            local visible = i <= self.bossCount
            boss:SetHidden(not visible)
            if visible then
                boss:SetWidth(self.bossColWidth)
                local label = boss:GetNamedChild("Label")
                if label then label:SetWidth(self.bossColWidth - ARROW_PAD) end
                boss:ClearAnchors()
                boss:SetAnchor(LEFT, prev, RIGHT, PADDING, 0)
                prev = boss
            end
        end
    end

    -- Re-anchor DPS after last visible boss (or Name when no bosses)
    local dps = rowControl:GetNamedChild("DPS")
    if dps then
        dps:ClearAnchors()
        dps:SetAnchor(LEFT, prev, RIGHT, PADDING, 0)
    end
end

-------------------------
-- Sort Filter List Overrides
-------------------------

function GroupTable:BuildMasterList()
    self.masterList = {}
    if not self.members then return end

    for _, member in ipairs(self.members) do
        local data = member.data
        local durationS = data.durationMs / 1000
        if durationS <= 0 then durationS = 1 end

        local entry = {
            displayName = member.displayName,
            role = member.role,
            dps = data.totalDamage / durationS,
            critPercent = (data.critPercent or 0) * 100,
            dtps = (data.totalDamageTaken or 0) / durationS,
            hps = data.healing and (data.healing.rawOut / durationS) or 0,
            alive = data.aliveTimeMs and data.durationMs > 0
                and (data.aliveTimeMs / data.durationMs * 100) or 100,
            deaths = data.deaths and data.deaths.deathCount or 0,
            isLocal = member.isLocal,
            boss1Dps = 0, boss2Dps = 0, boss3Dps = 0, boss4Dps = 0,
            rank = 0,
        }

        if data.bossDamage and #self.bossKeys > 0 then
            for _, bd in ipairs(data.bossDamage) do
                local key = string.format("%s:%d", bd.bossTag, bd.tagSeq)
                for i, bossKey in ipairs(self.bossKeys) do
                    if bossKey == key and i <= MAX_BOSSES then
                        entry[string.format("boss%dDps", i)] = bd.damage / durationS
                        break
                    end
                end
            end
        end

        table.insert(self.masterList, entry)
    end
end

function GroupTable:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)
    for _, entry in ipairs(self.masterList) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE, entry))
    end
end

function GroupTable:CommitScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    for i, scrollEntry in ipairs(scrollData) do
        scrollEntry.data.rank = i
    end
    ZO_GamepadInteractiveSortFilterList.CommitScrollList(self)
end

function GroupTable:SetupRow(rowControl, data)
    -- Configure dynamic columns only when boss configuration changes
    if rowControl._bossConfig ~= self.bossCount then
        self:ConfigureRowColumns(rowControl)
        rowControl._bossConfig = self.bossCount
    end

    -- Right-aligned columns use wrapper Control + inner Label (matching header arrow padding).
    -- Unwrapped columns (Rank, Name) have no "Label" child, so fall back to the control itself.
    local function getLabel(child)
        local ctrl = rowControl:GetNamedChild(child)
        if not ctrl then return nil end
        return ctrl:GetNamedChild("Label") or ctrl
    end

    local function setText(child, text)
        local label = getLabel(child)
        if label then label:SetText(text) end
    end

    local function setColor(child, color)
        local label = getLabel(child)
        if label then label:SetColor(color:UnpackRGBA()) end
    end

    setText("Rank", tostring(data.rank))
    if self.bossCount >= 3 then
        setText("Name", data.displayName)
    else
        local roleIcon = BattleScrolls.utils.GetRoleIcon(data.role or LFG_ROLE_DPS)
        setText("Name", string.format("|t100%%:100%%:%s|t %s", roleIcon, data.displayName))
    end
    setText("DPS", data.dps > 0 and utils.formatCompact(data.dps) or "-")
    setText("Crit", data.critPercent > 0 and string.format("%.0f%%", data.critPercent) or "-")
    setText("DTPS", data.dtps > 0 and utils.formatCompact(data.dtps) or "-")
    setText("HPS", data.hps > 0 and utils.formatCompact(data.hps) or "-")
    setText("Alive", string.format("%.0f%%", data.alive))
    setText("Deaths", data.deaths > 0 and tostring(data.deaths) or "-")

    for i = 1, MAX_BOSSES do
        local val = data[string.format("boss%dDps", i)] or 0
        setText("Boss" .. i, val > 0 and utils.formatCompact(val) or "-")
    end

    -- Colors: white for all data (matching leaderboard pattern), highlight for local player
    local defaultColor = ZO_SELECTED_TEXT
    setColor("Rank", defaultColor)
    setColor("Name", data.isLocal and ZO_HIGHLIGHT_TEXT or defaultColor)
    for _, col in ipairs({"DPS", "Crit", "DTPS", "HPS", "Alive", "Deaths", "Boss1", "Boss2", "Boss3", "Boss4"}) do
        setColor(col, defaultColor)
    end
end

-------------------------
-- Global Init
-------------------------

function BattleScrolls_GroupTable_OnInitialized(control)
    BattleScrolls.journal.groupTable = GroupTable:New(control)
end

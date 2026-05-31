-----------------------------------------------------------
-- Component Factory
-- Factory functions that build real ESO Controls.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local ControlPool = BattleScrolls.journal.ControlPool
local journal = BattleScrolls.journal
local utils = BattleScrolls.utils

-------------------------
-- Constants (moved from overview_panel.lua)
-------------------------

local ROW_CONTENT = {
    SECTION_HEADER = 50,
    ABILITY_BAR = 54,
    ABILITY_ICON_ROW = journal.AbilityIconStyle.ROW_HEIGHT,
    CHAMPION_HEADER = journal.ChampionRowStyle.HEADER_HEIGHT,
    CHAMPION_ROW = journal.ChampionRowStyle.ROW_HEIGHT,
    EFFECT_BAR = 54,
    EFFECT_ROW = 54,
    STAT_ROW = 36,
}

-- Default gap between children inside a Section
local DEFAULT_CHILD_GAP = 10

-- Gap between top-level sections when mounted
local SECTION_GAP = 15

-- Default max items when container height is unavailable
local DEFAULT_MAX_ITEMS = 10

-- Icon sizing for horizontal ability rows
local HORIZONTAL_ICON_SIZE = 46
local HORIZONTAL_ICON_GAP = 8
local HORIZONTAL_FRAME_INSET = 4
local HORIZONTAL_ULT_FRAME_INSET = 6
local HORIZONTAL_ROW_HEIGHT = 56

-- Q2 icon text row sizing
local ICON_TEXT_ICON_SIZE = 28
local ICON_TEXT_FRAME_INSET = 2
local ICON_TEXT_LABEL_OFFSET = 38
local ICON_TEXT_ROW_HEIGHT = 32

-- Champion row sizing
local CHAMP_ROW_HEIGHT = 40
local CHAMP_ICON_SIZE = 32
local CHAMP_ICON_GAP = 16

-- Vengeance perk row sizing. Basegame uses a 52px icon/background with a 104px border.
local VENGEANCE_PERK_ICON_SIZE = 40
local VENGEANCE_PERK_FRAME_SIZE = VENGEANCE_PERK_ICON_SIZE * 2
local VENGEANCE_PERK_ROW_HEIGHT = VENGEANCE_PERK_FRAME_SIZE
local VENGEANCE_PERK_OVERVIEW_ICON_SIZE = 52
local VENGEANCE_PERK_OVERVIEW_FRAME_SIZE = VENGEANCE_PERK_OVERVIEW_ICON_SIZE * 2
local VENGEANCE_PERK_OVERVIEW_ROW_HEIGHT = VENGEANCE_PERK_OVERVIEW_FRAME_SIZE
local VENGEANCE_PERK_LABEL_GAP = 20

-- 3-column champion row
local CHAMP_3COL_ROW_HEIGHT = 36
local CHAMP_3COL_ICON_GAP = 8

-- Group member card
local GROUP_CARD_HEIGHT = 100

-- Death attack row
local DEATH_ROW_HEIGHT = 42
local DEATH_ICON_OFFSET_X = 40

-- Side-by-side bar positioning
local BAR_LABEL_HEIGHT = 30
local SIDE_BY_SIDE_GAP = 40

-- Label-value row sizing
local LABEL_VALUE_PADDING = 10
local MAX_VALUE_WIDTH_RATIO = 0.5

-------------------------
-- Font Cascades
-------------------------

local SECTION_TITLE_FONTS = {
    { font = "ZoFontGamepadBold34", lineLimit = 1 },
    { font = "ZoFontGamepadBold27", lineLimit = 1 },
    { font = "ZoFontGamepad27", lineLimit = 1, dontUseForAdjusting = true },
}

local STAT_HEADER_FONTS = {
    { font = "ZoFontGamepad27", lineLimit = 1 },
    { font = "ZoFontGamepad27", lineLimit = 2 },
    { font = "ZoFontGamepad22", lineLimit = 2, dontUseForAdjusting = true },
}

local NAME_LABEL_FONTS = {
    { font = "ZoFontGamepad22", lineLimit = 1 },
    { font = "ZoFontGamepad18", lineLimit = 1, dontUseForAdjusting = true },
}

local GROUP_CARD_NAME_FONTS = {
    { font = "ZoFontGamepadBold27", lineLimit = 1 },
    { font = "ZoFontGamepadBold22", lineLimit = 1 },
    { font = "ZoFontGamepadBold18", lineLimit = 1, dontUseForAdjusting = true },
}

local GROUP_CARD_INFO_FONTS = {
    { font = "ZoFontGamepad22", lineLimit = 1 },
    { font = "ZoFontGamepad18", lineLimit = 1, dontUseForAdjusting = true },
}

-------------------------
-- Shared Utility Functions
-------------------------

---Initializes a label with font-adjusting for i18n text overflow (one-time)
---@param label Control
---@param fonts table
local function initFontAdjusting(label, fonts)
    if not label.fontAdjustingInitialized then
        ZO_FontAdjustingWrapLabel_OnInitialized(label, fonts, TEXT_WRAP_MODE_ELLIPSIS)
        label.fontAdjustingInitialized = true
    end
end

---Sets up icon frame visibility based on passive/active
---@param control Control Control with EdgeFrame and CircleFrame children
---@param abilityIcon string|nil Icon path
local function setupIconFrame(control, abilityIcon)
    local edgeFrame = control:GetNamedChild("EdgeFrame")
    local circleFrame = control:GetNamedChild("CircleFrame")
    if edgeFrame and circleFrame then
        local isPassive = journal.utils.isPassiveIcon(abilityIcon)
        edgeFrame:SetHidden(isPassive)
        circleFrame:SetHidden(not isPassive)
    end
end

---Sets up label widths and row height dynamically for a label-value row.
---@param row Control BattleScrolls_OverviewStatRow template
---@param headerText string
---@param valueText string
---@param containerWidth number
local function setupLabelValueRow(row, headerText, valueText, containerWidth)
    local headerLabel = row:GetNamedChild("Header")
    local valueLabel = row:GetNamedChild("Value")

    valueLabel:SetWidth(containerWidth)
    valueLabel:SetText(valueText)
    local maxValueWidth = math.floor(containerWidth * MAX_VALUE_WIDTH_RATIO)
    local valueWidth = math.min(valueLabel:GetTextWidth(), maxValueWidth)
    valueLabel:SetWidth(valueWidth)

    local headerWidth = containerWidth - valueWidth - LABEL_VALUE_PADDING
    headerLabel:SetWidth(headerWidth)
    initFontAdjusting(headerLabel, STAT_HEADER_FONTS)
    headerLabel:SetText(headerText)

    local contentHeight = math.max(headerLabel:GetTextHeight(), valueLabel:GetTextHeight())
    row:SetHeight(contentHeight)
end

---Populates a horizontal icon container with ability icons.
---@param container Control Container with .icons sub-control array
---@param abilities PlayerSetupAbility[]
local function populateHorizontalIcons(container, abilities)
    -- Ensure enough icon sub-controls exist (one per slot, including empty)
    if not container.icons then container.icons = {} end
    local slotCount = #abilities

    while #container.icons < slotCount do
        local idx = #container.icons + 1
        local iconControl = CreateControl(container:GetName() .. "Icon" .. idx, container, CT_TEXTURE)
        iconControl:SetDimensions(HORIZONTAL_ICON_SIZE, HORIZONTAL_ICON_SIZE)
        iconControl:SetHidden(true)

        local edgeFrame = CreateControl(container:GetName() .. "Icon" .. idx .. "Edge", container, CT_BACKDROP)
        edgeFrame:SetEdgeTexture("EsoUI/Art/Miscellaneous/Gamepad/edgeframeGamepadBorder.dds", 128, 16)
        edgeFrame:SetCenterColor(0, 0, 0, 0)
        edgeFrame:SetEdgeColor(ZO_NORMAL_TEXT:UnpackRGBA())
        edgeFrame:SetHidden(true)

        local circleFrame = CreateControl(container:GetName() .. "Icon" .. idx .. "Circle", container, CT_TEXTURE)
        circleFrame:SetTexture("EsoUI/Art/Miscellaneous/Gamepad/gp_passiveFrame_64.dds")
        circleFrame:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        circleFrame:SetHidden(true)

        container.icons[idx] = { icon = iconControl, edgeFrame = edgeFrame, circleFrame = circleFrame }
    end

    -- Hide all first
    for _, entry in ipairs(container.icons) do
        entry.icon:SetHidden(true)
        entry.edgeFrame:SetHidden(true)
        entry.circleFrame:SetHidden(true)
    end

    -- Populate all slots (including empty ones — empty slots show frame only)
    for i, ability in ipairs(abilities) do
        local entry = container.icons[i]
        local isUltimate = (i == #abilities)
        local isEmpty = ability.abilityId == 0

        local offsetX = HORIZONTAL_FRAME_INSET + (i - 1) * (HORIZONTAL_ICON_SIZE + HORIZONTAL_ICON_GAP)
        entry.icon:ClearAnchors()
        entry.icon:SetAnchor(TOPLEFT, container, TOPLEFT, offsetX, 4)

        if isEmpty then
            entry.icon:SetHidden(true)
        else
            local abilityIcon = journal.utils.getAbilityIcon(ability.abilityId)
            entry.icon:SetTexture(abilityIcon)
            entry.icon:SetHidden(false)
        end

        local isPassive = not isEmpty and journal.utils.isPassiveIcon(journal.utils.getAbilityIcon(ability.abilityId))
        local frameInset = isUltimate and HORIZONTAL_ULT_FRAME_INSET or HORIZONTAL_FRAME_INSET

        entry.edgeFrame:ClearAnchors()
        entry.edgeFrame:SetAnchor(TOPLEFT, entry.icon, TOPLEFT, -frameInset, -frameInset)
        entry.edgeFrame:SetAnchor(BOTTOMRIGHT, entry.icon, BOTTOMRIGHT, frameInset, frameInset)
        if isUltimate then
            entry.edgeFrame:SetEdgeColor(unpack(journal.AbilityIconStyle.ULT_EDGE_COLOR))
        else
            entry.edgeFrame:SetEdgeColor(ZO_NORMAL_TEXT:UnpackRGBA())
        end
        entry.edgeFrame:SetHidden(isPassive)

        entry.circleFrame:ClearAnchors()
        entry.circleFrame:SetAnchor(TOPLEFT, entry.icon, TOPLEFT, -frameInset, -frameInset)
        entry.circleFrame:SetAnchor(BOTTOMRIGHT, entry.icon, BOTTOMRIGHT, frameInset, frameInset)
        entry.circleFrame:SetHidden(not isPassive)
    end
end

---Flattens varargs into a list, filtering out nils and flattening arrays.
---Collects varargs into a flat list, skipping nil/false and flattening arrays.
---Uses select() to handle nil holes in varargs that ipairs would stop at.
---@return Control[]
local function collectArgs(...)
    local result = {}
    local n = select('#', ...)
    for i = 1, n do
        local arg = select(i, ...)
        if arg then
            if type(arg) == "table" and not arg.GetName then
                for _, child in ipairs(arg) do
                    if child then result[#result + 1] = child end
                end
            else
                result[#result + 1] = arg
            end
        end
    end
    return result
end

-------------------------
-- ComponentFactory
-------------------------

---@class ComponentFactory
---@field pools table<string, ControlPool>
local ComponentFactory = {}
ComponentFactory.__index = ComponentFactory

---@class VengeancePerkRowItem
---@field slotFlag number
---@field icon string
---@field name string

function ComponentFactory.new()
    return setmetatable({ pools = {} }, ComponentFactory)
end

function ComponentFactory:Initialize(panel)
    local parent = panel.q2ScrollChild or panel.q2Container
    self.pools = {
        -- Template-based pools
        container       = ControlPool.new(nil, parent, "Container"),
        section         = ControlPool.new("BattleScrolls_OverviewSectionHeader", parent, "Section"),
        statRow         = ControlPool.new("BattleScrolls_OverviewStatRow", parent, "StatRow"),
        abilityBar      = ControlPool.new("BattleScrolls_OverviewAbilityBar", parent, "AbilityBar"),
        effectBar       = ControlPool.new("BattleScrolls_OverviewEffectBar", parent, "EffectBar"),
        effectRow       = ControlPool.new("BattleScrolls_OverviewEffectRow", parent, "EffectRow"),
        abilityIconEntry = ControlPool.new("BattleScrolls_AbilityIconEntry", parent, "AbilityIcon"),
        subHeader       = ControlPool.new("BattleScrolls_ChampionDisciplineHeader", parent, "SubHdr"),
        groupCard       = ControlPool.new("BattleScrolls_GroupMemberCard", parent, "GrpCard"),
        deathRow        = ControlPool.new("BattleScrolls_DeathAttackRow", parent, "DeathRow"),
        -- Programmatic pools (sub-controls created on first use in factories)
        labeledBar      = ControlPool.new(nil, parent, "LabeledBar"),
        sideBySideBars  = ControlPool.new(nil, parent, "SideBars"),
        championRow2Col = ControlPool.new(nil, parent, "Champ2Col"),
        vengeancePerkRow2Col = ControlPool.new(nil, parent, "VengPerk2Col"),
        iconTextRow     = ControlPool.new(nil, parent, "IconText"),
        plainTextRow    = ControlPool.new(nil, parent, "PlainText"),
        horizontalStack = ControlPool.new(nil, parent, "HStack"),
        iconTextRow3Col = ControlPool.new(nil, parent, "IconText3Col"),
        textRow3Col     = ControlPool.new(nil, parent, "Text3Col"),
        championRow3Col = ControlPool.new(nil, parent, "Champ3Col"),
        vengeancePerkRow3Col = ControlPool.new(nil, parent, "VengPerk3Col"),
    }
end

function ComponentFactory:ReleaseAll()
    for _, pool in pairs(self.pools) do
        pool:ReleaseAll()
    end
end

-------------------------
-- ColumnBuilder
-------------------------

---@class ColumnBuilder
---@field parent Control ScrollChild to mount into
---@field width number Available width
---@field pools table<string, ControlPool> Shared pools
local ColumnBuilder = {}
ColumnBuilder.__index = ColumnBuilder

---Creates a column builder for a scroll child.
---@param scrollChild Control
---@return ColumnBuilder
function ComponentFactory:column(scrollChild)
    return setmetatable({
        parent = scrollChild,
        width = scrollChild:GetWidth(),
        pools = self.pools,
    }, ColumnBuilder)
end

-------------------------
-- Leaf Factories
-------------------------

---Creates a label-value stat row.
---@param label string Left-aligned label
---@param value string Right-aligned value
---@return Control
function ColumnBuilder:StatRow(label, value)
    local row = self.pools.statRow:Acquire()
    setupLabelValueRow(row, label, value, self.width)
    return row
end

---Creates a plain text row (programmatic, no XML template).
---@param text string
---@param color ZO_ColorDef|table|nil
---@param indent number|nil Left indent in pixels
---@return Control
function ColumnBuilder:PlainTextRow(text, color, indent)
    local row = self.pools.plainTextRow:Acquire()
    indent = indent or 0

    -- Lazy init sub-controls
    if not row.label then
        row.label = CreateControl(row:GetName() .. "Label", row, CT_LABEL)
        row.label:SetFont("ZoFontGamepad27")
        row.label:SetVerticalAlignment(TEXT_ALIGN_TOP)
        row.label:SetAnchor(TOPLEFT, row, TOPLEFT, 0, 0)
    end

    row.label:SetWidth(self.width - indent)
    row.label:ClearAnchors()
    row.label:SetAnchor(TOPLEFT, row, TOPLEFT, indent, 0)
    row.label:SetText(text)

    if color then
        if color.UnpackRGBA then
            row.label:SetColor(color:UnpackRGBA())
        else
            row.label:SetColor(unpack(color))
        end
    else
        row.label:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    end

    local textHeight = row.label:GetTextHeight()
    row:SetHeight(math.max(28, textHeight))
    row.label:SetHidden(false)
    row._topGap = 6
    return row
end

---Creates an icon + text row (small framed icon with label).
---@param icon string Texture path
---@param text string
---@param color ZO_ColorDef|table|nil
---@param showFrame boolean|nil Whether to show icon frame (default true)
---@return Control
function ColumnBuilder:IconTextRow(icon, text, color, showFrame)
    local row = self.pools.iconTextRow:Acquire()

    -- Lazy init sub-controls
    if not row.iconCtrl then
        row.iconCtrl = CreateControl(row:GetName() .. "Icon", row, CT_TEXTURE)
        row.iconCtrl:SetDimensions(ICON_TEXT_ICON_SIZE, ICON_TEXT_ICON_SIZE)
        row.iconCtrl:SetAnchor(LEFT, row, LEFT, ICON_TEXT_FRAME_INSET, 0)

        row.frame = CreateControl(row:GetName() .. "Frame", row, CT_BACKDROP)
        row.frame:SetEdgeTexture("EsoUI/Art/Miscellaneous/Gamepad/edgeframeGamepadBorder.dds", 128, 8)
        row.frame:SetCenterColor(0, 0, 0, 0)
        row.frame:SetEdgeColor(ZO_NORMAL_TEXT:UnpackRGBA())
        row.frame:SetDrawLevel(1)
        row.frame:SetAnchor(TOPLEFT, row.iconCtrl, TOPLEFT, -ICON_TEXT_FRAME_INSET, -ICON_TEXT_FRAME_INSET)
        row.frame:SetAnchor(BOTTOMRIGHT, row.iconCtrl, BOTTOMRIGHT, ICON_TEXT_FRAME_INSET, ICON_TEXT_FRAME_INSET)

        row.circleFrame = CreateControl(row:GetName() .. "CircleFrame", row, CT_TEXTURE)
        row.circleFrame:SetTexture("EsoUI/Art/Miscellaneous/Gamepad/gp_passiveFrame_64.dds")
        row.circleFrame:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        row.circleFrame:SetDrawLevel(1)
        row.circleFrame:SetAnchor(TOPLEFT, row.iconCtrl, TOPLEFT, -ICON_TEXT_FRAME_INSET, -ICON_TEXT_FRAME_INSET)
        row.circleFrame:SetAnchor(BOTTOMRIGHT, row.iconCtrl, BOTTOMRIGHT, ICON_TEXT_FRAME_INSET, ICON_TEXT_FRAME_INSET)

        row.label = CreateControl(row:GetName() .. "Label", row, CT_LABEL)
        row.label:SetFont("ZoFontGamepad27")
        row.label:SetAnchor(LEFT, row, LEFT, ICON_TEXT_LABEL_OFFSET, 0)
        row.label:SetMaxLineCount(1)
        row.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        row.label:SetVerticalAlignment(TEXT_ALIGN_CENTER)

        row._layoutWidth = function(control, width)
            control:SetWidth(width)
            control.label:SetWidth(math.max(0, width - ICON_TEXT_LABEL_OFFSET))
            control.label:SetHeight(ICON_TEXT_ROW_HEIGHT)
        end
        row._measureWidth = function(control)
            return ICON_TEXT_LABEL_OFFSET + control.label:GetTextWidth() + 4
        end
    end

    row:SetHeight(ICON_TEXT_ROW_HEIGHT)
    row._layoutWidth(row, self.width)
    row.iconCtrl:SetTexture(icon)
    row.iconCtrl:SetHidden(false)

    local frameVisible = showFrame ~= false
    local isPassive = frameVisible and journal.utils.isPassiveIcon(icon)
    row.frame:SetHidden(not frameVisible or isPassive)
    row.circleFrame:SetHidden(not frameVisible or not isPassive)

    row.label:SetText(text)

    if color then
        if color.UnpackRGBA then
            row.label:SetColor(color:UnpackRGBA())
        else
            row.label:SetColor(unpack(color))
        end
    else
        row.label:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    end
    row.label:SetHidden(false)

    row._topGap = 6
    return row
end

---Creates an ability bar with icon, name, progress bar, and stats.
---@param abilityData table { abilityId, name, icon, total, ticks, critTicks, maxHit }
---@param topValue number Highest value for relative bar scaling
---@param totalDamage number Total damage/healing for share calculation
---@param durationS number Fight duration for DPS/HPS
---@return Control
function ColumnBuilder:AbilityBar(abilityData, topValue, totalDamage, durationS)
    local bar = self.pools.abilityBar:Acquire()
    local abilityId = abilityData.abilityId

    local icon = bar:GetNamedChild("Icon")
    local abilityIcon = abilityData.icon or journal.utils.getAbilityIcon(abilityId)
    icon:SetTexture(abilityIcon)
    setupIconFrame(bar, abilityIcon)

    local nameLabel = bar:GetNamedChild("Name")
    initFontAdjusting(nameLabel, NAME_LABEL_FONTS)
    nameLabel:SetText(abilityData.name or utils.GetScribeAwareAbilityDisplayName(abilityId))

    local statusBar = bar:GetNamedChild("Bar")
    local barPercent = topValue > 0 and zo_clamp(abilityData.total / topValue * 100, 0, 100) or 0
    statusBar:SetMinMax(0, 100)
    statusBar:SetValue(barPercent)
    ZO_StatusBar_SetGradientColor(statusBar, ZO_XP_BAR_GRADIENT_COLORS)

    local shareLabel = bar:GetNamedChild("Share")
    if abilityData.isSupplemental then
        shareLabel:SetText("")
    else
        local shareTotal = abilityData.shareTotal or totalDamage
        local sharePercent = shareTotal > 0 and (abilityData.total / shareTotal * 100) or 0
        shareLabel:SetText(string.format("%.1f%%", sharePercent))
    end
    shareLabel:ClearAnchors()
    shareLabel:SetAnchor(TOPRIGHT, bar, TOPRIGHT, 0, 0)

    local dpsLabel = bar:GetNamedChild("DPS")
    local dps = durationS > 0 and (abilityData.total / durationS) or 0
    dpsLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_STAT_PER_SECOND), journal.utils.formatDPS(dps)))

    local critLabel = bar:GetNamedChild("Crit")
    local ticks = abilityData.ticks or 0
    local critTicks = abilityData.critTicks or 0
    if ticks > 0 then
        critLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_STAT_CRIT_PERCENT), string.format("%.0f", critTicks / ticks * 100)))
    else
        critLabel:SetText("")
    end

    local maxHitLabel = bar:GetNamedChild("MaxHit")
    local maxHit = abilityData.maxHit or 0
    if maxHit > 0 then
        maxHitLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_STAT_MAX_PREFIX),
            ZO_AbbreviateAndLocalizeNumber(maxHit, NUMBER_ABBREVIATION_PRECISION_TENTHS, true)))
    else
        maxHitLabel:SetText("")
    end

    bar:SetHeight(ROW_CONTENT.ABILITY_BAR)
    return bar
end

---Creates an effect bar with icon, name, uptime bar, and stats.
---@param abilityId number
---@param percent number Uptime percentage (0-100)
---@param stats table|nil { applications, playerPercent, maxStacks, suffix }
---@param isFavorite boolean|nil
---@return Control
function ColumnBuilder:EffectBar(abilityId, percent, stats, isFavorite)
    local bar = self.pools.effectBar:Acquire()

    local icon = bar:GetNamedChild("Icon")
    local abilityIcon = journal.utils.getAbilityIcon(abilityId)
    icon:SetTexture(abilityIcon)
    setupIconFrame(bar, abilityIcon)

    local favoriteIcon = bar:GetNamedChild("FavoriteIcon")
    if favoriteIcon then favoriteIcon:SetHidden(not isFavorite) end

    local nameLabel = bar:GetNamedChild("Name")
    initFontAdjusting(nameLabel, NAME_LABEL_FONTS)
    local abilityName = utils.GetScribeAwareAbilityDisplayName(abilityId)
    if stats and stats.suffix then
        nameLabel:SetText(abilityName .. " " .. stats.suffix)
    else
        nameLabel:SetText(abilityName)
    end

    local statusBar = bar:GetNamedChild("Bar")
    statusBar:SetMinMax(0, 100)
    statusBar:SetValue(percent)
    ZO_StatusBar_SetGradientColor(statusBar, ZO_XP_BAR_GRADIENT_COLORS)

    local valueLabel = bar:GetNamedChild("Value")
    valueLabel:SetText(string.format("%.0f%%", percent))
    valueLabel:ClearAnchors()
    valueLabel:SetAnchor(TOPRIGHT, bar, TOPRIGHT, 0, 0)

    local appsLabel = bar:GetNamedChild("Apps")
    local playerLabel = bar:GetNamedChild("Player")
    local stacksLabel = bar:GetNamedChild("Stacks")

    if stats then
        appsLabel:SetText(stats.applications and stats.applications > 0
            and zo_strformat(GetString(BATTLESCROLLS_EFFECT_APPS_COUNT), stats.applications) or "")
        playerLabel:SetText(stats.playerPercent and stats.playerPercent > 0
            and zo_strformat(GetString(BATTLESCROLLS_EFFECT_YOURS_PERCENT), string.format("%.0f", stats.playerPercent)) or "")
        stacksLabel:SetText(stats.maxStacks and stats.maxStacks > 1
            and zo_strformat(GetString(BATTLESCROLLS_EFFECT_STACKS_COUNT), stats.maxStacks) or "")
    else
        appsLabel:SetText("")
        playerLabel:SetText("")
        stacksLabel:SetText("")
    end

    bar:SetHeight(ROW_CONTENT.EFFECT_BAR)
    return bar
end

---Creates a compact effect row (no progress bar).
---Unifies AddEffectRow (Q4) and AddQ2EffectRow (Q2) — peakInstances handled automatically.
---@param abilityId number
---@param percent number Uptime percentage (0-100)
---@param stats table|nil { applications, playerPercent, maxStacks, peakInstances, suffix }
---@param isFavorite boolean|nil
---@return Control
function ColumnBuilder:EffectRow(abilityId, percent, stats, isFavorite)
    local row = self.pools.effectRow:Acquire()

    local icon = row:GetNamedChild("Icon")
    local abilityIcon = journal.utils.getAbilityIcon(abilityId)
    icon:SetTexture(abilityIcon)
    setupIconFrame(row, abilityIcon)

    local favoriteIcon = row:GetNamedChild("FavoriteIcon")
    if favoriteIcon then favoriteIcon:SetHidden(not isFavorite) end

    local nameLabel = row:GetNamedChild("Name")
    initFontAdjusting(nameLabel, NAME_LABEL_FONTS)
    local abilityName = utils.GetScribeAwareAbilityDisplayName(abilityId)
    if stats and stats.suffix then
        nameLabel:SetText(abilityName .. " " .. stats.suffix)
    else
        nameLabel:SetText(abilityName)
    end

    local valueLabel = row:GetNamedChild("Value")
    local peakInstances = stats and stats.peakInstances or 1
    if peakInstances > 1 then
        valueLabel:SetText(string.format("%.0f%% %s", percent, GetString(BATTLESCROLLS_EFFECT_AVG)))
    else
        valueLabel:SetText(string.format("%.0f%%", percent))
    end

    local statsLabel = row:GetNamedChild("Stats")
    local statParts = {}
    if stats then
        if stats.peakInstances and stats.peakInstances > 1 then
            statParts[#statParts + 1] = string.format("×%d", stats.peakInstances)
        end
        if stats.applications and stats.applications > 0 then
            statParts[#statParts + 1] = zo_strformat(GetString(BATTLESCROLLS_EFFECT_APPS_COUNT), stats.applications)
        end
        if stats.playerPercent and stats.playerPercent > 0 then
            statParts[#statParts + 1] = zo_strformat(GetString(BATTLESCROLLS_EFFECT_YOURS_PERCENT), string.format("%.0f", stats.playerPercent))
        end
        if stats.maxStacks and stats.maxStacks > 1 then
            statParts[#statParts + 1] = zo_strformat(GetString(BATTLESCROLLS_EFFECT_STACKS_COUNT), stats.maxStacks)
        end
    end
    statsLabel:SetText(table.concat(statParts, " · "))

    row:SetHeight(ROW_CONTENT.EFFECT_ROW)
    return row
end

---Creates a sub-header (champion discipline header style).
---@param text string
---@return Control
function ColumnBuilder:SubHeader(text)
    local header = self.pools.subHeader:Acquire()
    header:GetNamedChild("Label"):SetText(text)
    header:SetHeight(ROW_CONTENT.CHAMPION_HEADER)
    header._topGap = 12
    return header
end

---Creates an ability icon entry with icon, frame, and name.
---@param abilityId number
---@param isUltimate boolean|nil
---@return Control
function ColumnBuilder:AbilityIconEntry(abilityId, isUltimate)
    local entry = self.pools.abilityIconEntry:Acquire()
    journal.utils.populateAbilityRow(entry, abilityId, isUltimate == true)
    entry:SetHeight(ROW_CONTENT.ABILITY_ICON_ROW)
    entry._topGap = 4
    return entry
end

---Creates a group member card.
---@param memberData { displayName: string, primaryLabel: string, barPercent: number, shareText: string, infoLine: string }
---@return Control
function ColumnBuilder:GroupMemberCard(memberData)
    local card = self.pools.groupCard:Acquire()

    local nameLabel = card:GetNamedChild("Name")
    if nameLabel.fontCascade ~= GROUP_CARD_NAME_FONTS then
        initFontAdjusting(nameLabel, GROUP_CARD_NAME_FONTS)
        nameLabel.fontCascade = GROUP_CARD_NAME_FONTS
    end
    nameLabel:SetText(zo_strformat("<<C:1>>", memberData.displayName))
    nameLabel:SetHeight(26)

    local metricLabel = card:GetNamedChild("Metric")
    metricLabel:SetText(memberData.primaryLabel)
    metricLabel:SetFont("ZoFontGamepadBold27")
    metricLabel:SetHeight(26)

    local statusBar = card:GetNamedChild("Bar")
    statusBar:SetMinMax(0, 100)
    statusBar:SetValue(memberData.barPercent)
    ZO_StatusBar_SetGradientColor(statusBar, ZO_XP_BAR_GRADIENT_COLORS)
    statusBar:ClearAnchors()
    statusBar:SetAnchor(TOPLEFT, card, TOPLEFT, 0, 34)
    statusBar:SetAnchor(TOPRIGHT, card, TOPRIGHT, -115, 34)
    statusBar:SetHeight(20)

    local shareLabel = card:GetNamedChild("Share")
    shareLabel:SetText(memberData.shareText)
    shareLabel:ClearAnchors()
    shareLabel:SetAnchor(TOPRIGHT, card, TOPRIGHT, 0, 34)
    shareLabel:SetHeight(20)

    local infoLineLabel = card:GetNamedChild("InfoLine")
    if infoLineLabel.fontCascade ~= GROUP_CARD_INFO_FONTS then
        initFontAdjusting(infoLineLabel, GROUP_CARD_INFO_FONTS)
        infoLineLabel.fontCascade = GROUP_CARD_INFO_FONTS
    end
    infoLineLabel:SetText(memberData.infoLine or "")
    infoLineLabel:ClearAnchors()
    infoLineLabel:SetAnchor(TOPLEFT, card, TOPLEFT, 0, 60)
    infoLineLabel:SetAnchor(TOPRIGHT, card, TOPRIGHT, 0, 60)
    infoLineLabel:SetHeight(20)

    card:SetHeight(GROUP_CARD_HEIGHT)
    return card
end

---Creates a death attack row with icon, name, damage value, and optional killing blow skull.
---@param attack SharedDeathRecapAttack { abilityId, damage }
---@param isKillingBlow boolean|nil
---@return Control
function ColumnBuilder:DeathAttackRow(attack, isKillingBlow)
    local row = self.pools.deathRow:Acquire()

    local icon = row:GetNamedChild("Icon")
    local abilityIcon = journal.utils.getAbilityIcon(attack.abilityId)
    icon:SetTexture(abilityIcon)
    icon:ClearAnchors()
    icon:SetAnchor(LEFT, row, LEFT, DEATH_ICON_OFFSET_X, 0)
    setupIconFrame(row, abilityIcon)

    local killingBlowIcon = row:GetNamedChild("KillingBlow")
    if killingBlowIcon then killingBlowIcon:SetHidden(not isKillingBlow) end

    row:GetNamedChild("Name"):SetText(journal.utils.getAbilityDisplayName(attack.abilityId))
    row:GetNamedChild("Value"):SetText(journal.utils.formatCompact(attack.damage))

    row:SetHeight(DEATH_ROW_HEIGHT)
    row._topGap = 6
    return row
end

-------------------------
-- Composite Factories
-------------------------

---Creates a horizontal stack using each child's measured width.
---Accepts controls as varargs or as arrays, matching Section()/mount().
---@param gap number Horizontal gap between children
---@param ... Control|Control[]|nil Children
---@return Control|nil container
function ColumnBuilder:HorizontalStack(gap, ...)
    local children = collectArgs(...)
    if #children == 0 then return nil end

    local container = self.pools.horizontalStack:Acquire()
    local childCount = #children
    gap = gap or 0
    local totalGap = gap * math.max(0, childCount - 1)
    local availableWidth = math.max(0, self.width - totalGap)
    local childWidths = {}
    local totalChildWidth = 0
    for index, child in ipairs(children) do
        local childWidth = child._measureWidth and child._measureWidth(child) or child:GetWidth()
        childWidth = math.max(0, math.floor(childWidth or 0))
        childWidths[index] = childWidth
        totalChildWidth = totalChildWidth + childWidth
    end

    if totalChildWidth > availableWidth and totalChildWidth > 0 then
        local scale = availableWidth / totalChildWidth
        local scaledTotal = 0
        for index, childWidth in ipairs(childWidths) do
            childWidth = math.max(0, math.floor(childWidth * scale))
            childWidths[index] = childWidth
            scaledTotal = scaledTotal + childWidth
        end
        childWidths[childCount] = childWidths[childCount] + (availableWidth - scaledTotal)
    end

    local offsetX = 0
    local maxHeight = 0

    for index, child in ipairs(children) do
        local childWidth = childWidths[index]
        child:SetParent(container)
        child:ClearAnchors()
        child:SetAnchor(TOPLEFT, container, TOPLEFT, offsetX, 0)
        child:SetWidth(childWidth)
        if child._layoutWidth then
            child._layoutWidth(child, childWidth)
        end
        child:SetHidden(false)

        maxHeight = math.max(maxHeight, child:GetHeight())
        offsetX = offsetX + childWidth + gap
    end

    container:SetHeight(maxHeight)
    container:SetWidth(math.max(0, offsetX - gap))
    container._topGap = children[1]._topGap or DEFAULT_CHILD_GAP
    return container
end

---Creates a section with header and stacked children.
---Returns nil if no children (conditional rendering).
---@param title string Section header text
---@param ... Control|Control[]|nil Children (nils filtered, arrays flattened)
---@return Control|nil container Hidden container, or nil if empty
function ColumnBuilder:Section(title, ...)
    local children = collectArgs(...)
    if #children == 0 then return nil end

    local container = self.pools.container:Acquire()
    local header = self.pools.section:Acquire()

    local titleLabel = header:GetNamedChild("Title")
    initFontAdjusting(titleLabel, SECTION_TITLE_FONTS)
    titleLabel:SetText(title)

    -- Clear any previous timing label
    local timingLabel = header:GetNamedChild("Timing")
    if timingLabel then timingLabel:SetHidden(true) end

    header:SetParent(container)
    header:ClearAnchors()
    header:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
    header:SetAnchor(TOPRIGHT, container, TOPRIGHT, 0, 0)
    header:SetHidden(false)

    local offset = ROW_CONTENT.SECTION_HEADER
    for _, child in ipairs(children) do
        if child then
            local gap = child._topGap or DEFAULT_CHILD_GAP
            offset = offset + gap
            child:SetParent(container)
            child:ClearAnchors()
            child:SetAnchor(TOPLEFT, container, TOPLEFT, 0, offset)
            child:SetAnchor(TOPRIGHT, container, TOPRIGHT, 0, offset)
            child:SetHidden(false)
            offset = offset + child:GetHeight()
        end
    end

    container:SetHeight(offset)
    container:SetWidth(self.width)
    container._header = header
    -- Container stays hidden — mount()/mountFitted() shows it
    return container
end

---Creates a single labeled ability bar (label + icon row).
---@param abilities PlayerSetupAbility[]
---@param label string
---@return Control
function ColumnBuilder:LabeledBar(abilities, label)
    local wrapper = self.pools.labeledBar:Acquire()

    if not wrapper.label then
        wrapper.label = CreateControl(wrapper:GetName() .. "Label", wrapper, CT_LABEL)
        wrapper.label:SetFont("ZoFontGamepadBold27")
        wrapper.label:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        wrapper.label:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)

        wrapper.icons = CreateControl(wrapper:GetName() .. "Icons", wrapper, CT_CONTROL)
        wrapper.icons:SetHeight(HORIZONTAL_ROW_HEIGHT)
        wrapper.icons.icons = {}
    end

    wrapper.label:SetText(label)
    wrapper.label:ClearAnchors()
    wrapper.label:SetAnchor(TOPLEFT, wrapper, TOPLEFT, 0, 0)
    wrapper.label:SetWidth(0)
    wrapper.label:SetHeight(BAR_LABEL_HEIGHT)
    wrapper.label:SetHidden(false)

    local barWidth = #abilities * (HORIZONTAL_ICON_SIZE + HORIZONTAL_ICON_GAP) - HORIZONTAL_ICON_GAP
    wrapper.icons:ClearAnchors()
    wrapper.icons:SetAnchor(TOPLEFT, wrapper, TOPLEFT, -1, BAR_LABEL_HEIGHT)
    wrapper.icons:SetWidth(barWidth)
    wrapper.icons:SetHidden(false)
    populateHorizontalIcons(wrapper.icons, abilities)

    wrapper:SetHeight(BAR_LABEL_HEIGHT + HORIZONTAL_ROW_HEIGHT)
    wrapper:SetWidth(self.width)
    return wrapper
end

---Creates a side-by-side ability bar display (front + back bars with labels).
---@param frontAbilities PlayerSetupAbility[]
---@param backAbilities PlayerSetupAbility[]
---@param frontLabel string
---@param backLabel string
---@param frontWeapon string|nil Optional weapon text (inline suffix on label)
---@param backWeapon string|nil Optional weapon text (inline suffix on label)
---@param tightFit boolean|nil When true, back bar follows front bar tightly (Q2 style)
---@return Control
function ColumnBuilder:SideBySideBars(frontAbilities, backAbilities, frontLabel, backLabel, frontWeapon, backWeapon, tightFit)
    local wrapper = self.pools.sideBySideBars:Acquire()

    -- Lazy init sub-controls
    if not wrapper.frontLabel then
        wrapper.frontLabel = CreateControl(wrapper:GetName() .. "FLabel", wrapper, CT_LABEL)
        wrapper.frontLabel:SetFont("ZoFontGamepadBold27")
        wrapper.frontLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        wrapper.frontLabel:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)

        wrapper.backLabel = CreateControl(wrapper:GetName() .. "BLabel", wrapper, CT_LABEL)
        wrapper.backLabel:SetFont("ZoFontGamepadBold27")
        wrapper.backLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        wrapper.backLabel:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)

        wrapper.frontWeaponLabel = CreateControl(wrapper:GetName() .. "FWeapon", wrapper, CT_LABEL)
        wrapper.frontWeaponLabel:SetFont("ZoFontGamepad22")
        wrapper.frontWeaponLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        wrapper.frontWeaponLabel:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        wrapper.frontWeaponLabel:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        wrapper.frontWeaponLabel:SetMaxLineCount(1)

        wrapper.backWeaponLabel = CreateControl(wrapper:GetName() .. "BWLabel", wrapper, CT_LABEL)
        wrapper.backWeaponLabel:SetFont("ZoFontGamepad22")
        wrapper.backWeaponLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        wrapper.backWeaponLabel:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        wrapper.backWeaponLabel:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        wrapper.backWeaponLabel:SetMaxLineCount(1)

        wrapper.frontIcons = CreateControl(wrapper:GetName() .. "FIcons", wrapper, CT_CONTROL)
        wrapper.frontIcons:SetHeight(HORIZONTAL_ROW_HEIGHT)
        wrapper.frontIcons.icons = {}

        wrapper.backIcons = CreateControl(wrapper:GetName() .. "BIcons", wrapper, CT_CONTROL)
        wrapper.backIcons:SetHeight(HORIZONTAL_ROW_HEIGHT)
        wrapper.backIcons.icons = {}
    end

    local barWidth = math.max(#frontAbilities, #backAbilities)
        * (HORIZONTAL_ICON_SIZE + HORIZONTAL_ICON_GAP) - HORIZONTAL_ICON_GAP
    local backOffsetX
    if tightFit then
        backOffsetX = barWidth + HORIZONTAL_FRAME_INSET + SIDE_BY_SIDE_GAP
    else
        backOffsetX = math.floor(self.width / 2)
    end

    local hasWeapon = (frontWeapon and frontWeapon ~= "") or (backWeapon and backWeapon ~= "")

    -- Labels — auto-size when weapon suffix present, fixed width otherwise
    wrapper.frontLabel:SetText(frontLabel)
    wrapper.frontLabel:ClearAnchors()
    wrapper.frontLabel:SetAnchor(TOPLEFT, wrapper, TOPLEFT, 0, 0)
    wrapper.frontLabel:SetWidth(hasWeapon and 0 or barWidth)
    wrapper.frontLabel:SetHeight(BAR_LABEL_HEIGHT)
    wrapper.frontLabel:SetHidden(false)

    wrapper.backLabel:SetText(backLabel)
    wrapper.backLabel:ClearAnchors()
    wrapper.backLabel:SetAnchor(TOPLEFT, wrapper, TOPLEFT, backOffsetX, 0)
    wrapper.backLabel:SetWidth(hasWeapon and 0 or barWidth)
    wrapper.backLabel:SetHeight(BAR_LABEL_HEIGHT)
    wrapper.backLabel:SetHidden(false)

    -- Weapon text as inline suffix on the same line as the bar label
    if hasWeapon then
        wrapper.frontWeaponLabel:SetText(frontWeapon or "")
        wrapper.frontWeaponLabel:ClearAnchors()
        wrapper.frontWeaponLabel:SetAnchor(LEFT, wrapper.frontLabel, RIGHT, 8, 2)
        wrapper.frontWeaponLabel:SetHidden(not frontWeapon or frontWeapon == "")

        wrapper.backWeaponLabel:SetText(backWeapon or "")
        wrapper.backWeaponLabel:ClearAnchors()
        wrapper.backWeaponLabel:SetAnchor(LEFT, wrapper.backLabel, RIGHT, 8, 2)
        wrapper.backWeaponLabel:SetHidden(not backWeapon or backWeapon == "")
    else
        wrapper.frontWeaponLabel:SetHidden(true)
        wrapper.backWeaponLabel:SetHidden(true)
    end

    -- Icon containers
    wrapper.frontIcons:ClearAnchors()
    wrapper.frontIcons:SetAnchor(TOPLEFT, wrapper, TOPLEFT, -1, BAR_LABEL_HEIGHT)
    wrapper.frontIcons:SetWidth(barWidth)
    wrapper.frontIcons:SetHidden(false)
    populateHorizontalIcons(wrapper.frontIcons, frontAbilities)

    wrapper.backIcons:ClearAnchors()
    wrapper.backIcons:SetAnchor(TOPLEFT, wrapper, TOPLEFT, backOffsetX - 1, BAR_LABEL_HEIGHT)
    wrapper.backIcons:SetWidth(barWidth)
    wrapper.backIcons:SetHidden(false)
    populateHorizontalIcons(wrapper.backIcons, backAbilities)

    wrapper:SetHeight(BAR_LABEL_HEIGHT + HORIZONTAL_ROW_HEIGHT)
    wrapper:SetWidth(self.width)
    return wrapper
end

---Creates a 2-column champion row (icon + label per column).
---@param leftName string
---@param leftIcon string
---@param rightName string|nil
---@param rightIcon string|nil
---@return Control
function ColumnBuilder:ChampionRow2Col(leftName, leftIcon, rightName, rightIcon)
    local row = self.pools.championRow2Col:Acquire()

    -- Lazy init sub-controls
    if not row.leftIcon then
        row.leftIcon = CreateControl(row:GetName() .. "LIcon", row, CT_TEXTURE)
        row.leftIcon:SetDimensions(CHAMP_ICON_SIZE, CHAMP_ICON_SIZE)
        row.leftIcon:SetAnchor(LEFT, row, LEFT, 0, 0)

        row.leftLabel = CreateControl(row:GetName() .. "LLabel", row, CT_LABEL)
        row.leftLabel:SetFont("ZoFontGamepad34")
        row.leftLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        row.leftLabel:SetMaxLineCount(1)
        row.leftLabel:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        row.leftLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        row.leftLabel:SetAnchor(LEFT, row.leftIcon, RIGHT, CHAMP_ICON_GAP, 0)
        row.leftLabel:SetHeight(CHAMP_ROW_HEIGHT)

        row.rightIcon = CreateControl(row:GetName() .. "RIcon", row, CT_TEXTURE)
        row.rightIcon:SetDimensions(CHAMP_ICON_SIZE, CHAMP_ICON_SIZE)
        row.rightIcon:SetHidden(true)

        row.rightLabel = CreateControl(row:GetName() .. "RLabel", row, CT_LABEL)
        row.rightLabel:SetFont("ZoFontGamepad34")
        row.rightLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        row.rightLabel:SetMaxLineCount(1)
        row.rightLabel:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        row.rightLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        row.rightLabel:SetHeight(CHAMP_ROW_HEIGHT)
        row.rightLabel:SetHidden(true)
    end

    local halfWidth = math.floor(self.width / 2)

    row.leftIcon:SetTexture(leftIcon)
    row.leftIcon:SetHidden(false)
    row.leftLabel:SetText(leftName)
    row.leftLabel:SetWidth(halfWidth - CHAMP_ICON_SIZE - CHAMP_ICON_GAP)
    row.leftLabel:SetHidden(false)

    if rightName and rightIcon then
        row.rightIcon:ClearAnchors()
        row.rightIcon:SetAnchor(LEFT, row, LEFT, halfWidth, 0)
        row.rightIcon:SetTexture(rightIcon)
        row.rightIcon:SetHidden(false)
        row.rightLabel:ClearAnchors()
        row.rightLabel:SetAnchor(LEFT, row.rightIcon, RIGHT, CHAMP_ICON_GAP, 0)
        row.rightLabel:SetText(rightName)
        row.rightLabel:SetWidth(halfWidth - CHAMP_ICON_SIZE - CHAMP_ICON_GAP)
        row.rightLabel:SetHidden(false)
    else
        row.rightIcon:SetHidden(true)
        row.rightLabel:SetHidden(true)
    end

    row:SetHeight(CHAMP_ROW_HEIGHT)
    row:SetWidth(self.width)
    row._topGap = 3
    return row
end

---Ensures a programmatic Vengeance perk row has enough columns.
---@param row Control
---@param count number
local function ensureVengeancePerkColumns(row, count)
    if not row.perkCols then row.perkCols = {} end

    while #row.perkCols < count do
        local index = #row.perkCols + 1
        local col = {}

        col.framedIcon = journal.utils.createVengeancePerkFramedIcon(row)

        col.label = CreateControl(row:GetName() .. "C" .. index .. "Label", row, CT_LABEL)
        col.label:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        col.label:SetMaxLineCount(1)
        col.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        col.label:SetVerticalAlignment(TEXT_ALIGN_CENTER)

        row.perkCols[index] = col
    end
end

---@param col table
---@param item VengeancePerkRowItem|nil
---@param row Control
---@param offsetX number
---@param colWidth number
---@param iconSize number
---@param frameSize number
---@param rowHeight number
---@param font string
local function layoutVengeancePerkColumn(col, item, row, offsetX, colWidth, iconSize, frameSize, rowHeight, font)
    if not item or item.name == "" then
        col.framedIcon:SetHidden(true)
        col.label:SetHidden(true)
        return
    end

    local frameBleed = math.max(0, math.floor((frameSize - iconSize) / 2))
    local iconCenterX = offsetX + frameBleed + math.floor(iconSize / 2)

    journal.utils.setupVengeancePerkFramedIcon(col.framedIcon, item.slotFlag, item.icon, iconSize)
    col.framedIcon:ClearAnchors()
    col.framedIcon:SetAnchor(CENTER, row, LEFT, iconCenterX, 0)

    local labelOffsetX = offsetX + frameBleed + iconSize + VENGEANCE_PERK_LABEL_GAP
    col.label:SetFont(font)
    col.label:SetHeight(rowHeight)
    col.label:ClearAnchors()
    col.label:SetAnchor(LEFT, row, LEFT, labelOffsetX, 0)
    col.label:SetWidth(math.max(0, colWidth - frameBleed - iconSize - VENGEANCE_PERK_LABEL_GAP))
    col.label:SetText(item.name)
    col.label:SetHidden(false)
end

---Creates a 2-column Vengeance perk row with ESO-style framed icons.
---@param left VengeancePerkRowItem
---@param right VengeancePerkRowItem|nil
---@return Control
function ColumnBuilder:VengeancePerkRow2Col(left, right)
    local row = self.pools.vengeancePerkRow2Col:Acquire()
    ensureVengeancePerkColumns(row, 2)

    local halfWidth = math.floor(self.width / 2)
    layoutVengeancePerkColumn(row.perkCols[1], left, row, 0, halfWidth,
        VENGEANCE_PERK_ICON_SIZE, VENGEANCE_PERK_FRAME_SIZE, VENGEANCE_PERK_ROW_HEIGHT, "ZoFontGamepad34")
    layoutVengeancePerkColumn(row.perkCols[2], right, row, halfWidth, halfWidth,
        VENGEANCE_PERK_ICON_SIZE, VENGEANCE_PERK_FRAME_SIZE, VENGEANCE_PERK_ROW_HEIGHT, "ZoFontGamepad34")

    row:SetHeight(VENGEANCE_PERK_ROW_HEIGHT)
    row:SetWidth(self.width)
    row._topGap = 1
    return row
end

---Creates a 3-column Vengeance perk row with larger overview icons.
---@param items (VengeancePerkRowItem|nil)[]
---@return Control
function ColumnBuilder:VengeancePerkRow3Col(items)
    local row = self.pools.vengeancePerkRow3Col:Acquire()
    ensureVengeancePerkColumns(row, 3)

    local colWidth = math.floor(self.width / 3)
    for c = 1, 3 do
        layoutVengeancePerkColumn(row.perkCols[c], items[c], row, (c - 1) * colWidth, colWidth,
            VENGEANCE_PERK_OVERVIEW_ICON_SIZE, VENGEANCE_PERK_OVERVIEW_FRAME_SIZE,
            VENGEANCE_PERK_OVERVIEW_ROW_HEIGHT, "ZoFontGamepad27")
    end

    row:SetHeight(VENGEANCE_PERK_OVERVIEW_ROW_HEIGHT)
    row:SetWidth(self.width)
    row._topGap = 1
    return row
end

---Creates a 3-column icon + text row.
---@param items { icon: string, text: string, color: ZO_ColorDef|nil, showFrame: boolean|nil }[]
---@return Control
function ColumnBuilder:IconTextRow3Col(items)
    local row = self.pools.iconTextRow3Col:Acquire()

    -- Lazy init: 3 columns of icon + frame + label
    if not row.cols then
        row.cols = {}
        for c = 1, 3 do
            local col = {}
            col.icon = CreateControl(row:GetName() .. "C" .. c .. "Icon", row, CT_TEXTURE)
            col.icon:SetDimensions(ICON_TEXT_ICON_SIZE, ICON_TEXT_ICON_SIZE)

            col.frame = CreateControl(row:GetName() .. "C" .. c .. "Frame", row, CT_BACKDROP)
            col.frame:SetEdgeTexture("EsoUI/Art/Miscellaneous/Gamepad/edgeframeGamepadBorder.dds", 128, 8)
            col.frame:SetCenterColor(0, 0, 0, 0)
            col.frame:SetEdgeColor(ZO_NORMAL_TEXT:UnpackRGBA())
            col.frame:SetDrawLevel(1)
            col.frame:SetAnchor(TOPLEFT, col.icon, TOPLEFT, -ICON_TEXT_FRAME_INSET, -ICON_TEXT_FRAME_INSET)
            col.frame:SetAnchor(BOTTOMRIGHT, col.icon, BOTTOMRIGHT, ICON_TEXT_FRAME_INSET, ICON_TEXT_FRAME_INSET)

            col.label = CreateControl(row:GetName() .. "C" .. c .. "Label", row, CT_LABEL)
            col.label:SetFont("ZoFontGamepad27")

            row.cols[c] = col
        end
    end

    local colCount = #items > 0 and #items or 1
    local colWidth = math.floor(self.width / colCount)

    for c = 1, 3 do
        local col = row.cols[c]
        local item = items[c]
        if item then
            local offsetX = (c - 1) * colWidth
            col.icon:ClearAnchors()
            col.icon:SetAnchor(LEFT, row, LEFT, offsetX + ICON_TEXT_FRAME_INSET, 0)
            col.icon:SetTexture(item.icon)
            col.icon:SetHidden(false)
            col.frame:SetHidden(item.showFrame == false)

            col.label:ClearAnchors()
            col.label:SetAnchor(LEFT, row, LEFT, offsetX + ICON_TEXT_LABEL_OFFSET, 0)
            col.label:SetWidth(colWidth - ICON_TEXT_LABEL_OFFSET)
            col.label:SetText(item.text)
            local color = item.color or ZO_NORMAL_TEXT
            if color.UnpackRGBA then
                col.label:SetColor(color:UnpackRGBA())
            else
                col.label:SetColor(unpack(color))
            end
            col.label:SetHidden(false)
        else
            col.icon:SetHidden(true)
            col.frame:SetHidden(true)
            col.label:SetHidden(true)
        end
    end

    row:SetHeight(ICON_TEXT_ROW_HEIGHT)
    row:SetWidth(self.width)
    row._topGap = 6
    return row
end

---Creates a 3-column text-only row.
---@param items { text: string, color: ZO_ColorDef|nil, uppercase: boolean|nil }[]
---@return Control
function ColumnBuilder:TextRow3Col(items)
    local row = self.pools.textRow3Col:Acquire()

    -- Lazy init: 3 labels
    if not row.labels then
        row.labels = {}
        for c = 1, 3 do
            local label = CreateControl(row:GetName() .. "L" .. c, row, CT_LABEL)
            label:SetFont("ZoFontGamepad27")
            label:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
            label:SetMaxLineCount(1)
            label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
            label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
            label:SetHeight(CHAMP_3COL_ROW_HEIGHT)
            row.labels[c] = label
        end
    end

    local colCount = #items > 0 and #items or 1
    local colWidth = math.floor(self.width / colCount)

    for c = 1, 3 do
        local label = row.labels[c]
        local item = items[c]
        if item then
            label:ClearAnchors()
            label:SetAnchor(LEFT, row, LEFT, (c - 1) * colWidth, 0)
            label:SetWidth(colWidth - 16)
            label:SetModifyTextType(item.uppercase and MODIFY_TEXT_TYPE_UPPERCASE or MODIFY_TEXT_TYPE_NONE)
            label:SetText(item.text)
            local color = item.color or ZO_NORMAL_TEXT
            if color.UnpackRGBA then
                label:SetColor(color:UnpackRGBA())
            else
                label:SetColor(unpack(color))
            end
            label:SetHidden(false)
        else
            label:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
            label:SetHidden(true)
        end
    end

    row:SetHeight(CHAMP_3COL_ROW_HEIGHT)
    row:SetWidth(self.width)
    row._topGap = 3
    return row
end

---Creates a 3-column champion skill row.
---@param names (string|nil)[] Up to 3 skill names
---@param icons (string|nil)[] Up to 3 skill icons
---@return Control
function ColumnBuilder:ChampionRow3Col(names, icons)
    local row = self.pools.championRow3Col:Acquire()

    -- Lazy init: 3 icon+label pairs
    if not row.cols then
        row.cols = {}
        for c = 1, 3 do
            local col = {}
            col.icon = CreateControl(row:GetName() .. "C" .. c .. "Icon", row, CT_TEXTURE)
            col.icon:SetDimensions(CHAMP_ICON_SIZE, CHAMP_ICON_SIZE)

            col.label = CreateControl(row:GetName() .. "C" .. c .. "Label", row, CT_LABEL)
            col.label:SetFont("ZoFontGamepad27")
            col.label:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
            col.label:SetMaxLineCount(1)
            col.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
            col.label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
            col.label:SetHeight(CHAMP_3COL_ROW_HEIGHT)

            row.cols[c] = col
        end
    end

    local colWidth = math.floor(self.width / 3)

    for c = 1, 3 do
        local col = row.cols[c]
        if names[c] and icons[c] then
            local offsetX = (c - 1) * colWidth
            col.icon:ClearAnchors()
            col.icon:SetAnchor(LEFT, row, LEFT, offsetX, 0)
            col.icon:SetTexture(icons[c])
            col.icon:SetHidden(false)

            col.label:ClearAnchors()
            col.label:SetAnchor(LEFT, col.icon, RIGHT, CHAMP_3COL_ICON_GAP, 0)
            col.label:SetText(names[c])
            col.label:SetWidth(colWidth - CHAMP_ICON_SIZE - CHAMP_3COL_ICON_GAP)
            col.label:SetHidden(false)
        else
            col.icon:SetHidden(true)
            col.label:SetHidden(true)
        end
    end

    row:SetHeight(CHAMP_3COL_ROW_HEIGHT)
    row:SetWidth(self.width)
    row._topGap = 3
    return row
end

-------------------------
-- Section Timing Decorator
-------------------------

---Adds or updates a right-aligned timing subtitle on a Section's header.
---@param sectionContainer Control|nil The container returned by Section()
---@param text string|nil Timing text (e.g. "1:23") or nil to hide
function ColumnBuilder:SetSectionTiming(sectionContainer, text)
    if not sectionContainer or not sectionContainer._header then return end
    local header = sectionContainer._header

    local timingLabel = header:GetNamedChild("Timing")
    if not timingLabel then
        timingLabel = CreateControl(header:GetName() .. "Timing", header, CT_LABEL)
        timingLabel:SetFont("ZoFontGamepad22")
        timingLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        timingLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
        timingLabel:SetVerticalAlignment(TEXT_ALIGN_BOTTOM)
        timingLabel:SetAnchor(BOTTOMRIGHT, header, BOTTOMRIGHT, 0, -5)
        timingLabel:SetDimensions(120, 50)
    end
    if text then
        timingLabel:SetText(text)
        timingLabel:SetHidden(false)
    else
        timingLabel:SetHidden(true)
    end
end

-------------------------
-- Mount Methods
-------------------------

---Mounts components into the column's scroll child using offset anchoring.
---@param gap number Vertical gap between components
---@param insetX number Horizontal inset from edges
---@param ... Control|Control[]|nil Components to mount
function ColumnBuilder:mount(gap, insetX, ...)
    local components = collectArgs(...)
    local offset = 0

    for i, control in ipairs(components) do
        if i > 1 then offset = offset + (control._topGap or gap) end
        control:SetParent(self.parent)
        control:ClearAnchors()
        control:SetAnchor(TOPLEFT, self.parent, TOPLEFT, insetX, offset)
        control:SetAnchor(TOPRIGHT, self.parent, TOPRIGHT, -insetX, offset)
        control:SetHidden(false)
        offset = offset + control:GetHeight()
    end
end

---Calculates how many items of a given height can fit in this column.
---Accounts for a section header + gap overhead.
---@param contentHeight number Height per item
---@param gap number Gap between items
---@param reservedHeight number|nil Additional height already used
---@return number
function ColumnBuilder:maxItems(contentHeight, gap, reservedHeight)
    local container = self.parent:GetParent()
    if not container then return DEFAULT_MAX_ITEMS end
    local available = container:GetHeight() - ROW_CONTENT.SECTION_HEADER - SECTION_GAP - (reservedHeight or 0)
    if available <= 0 or contentHeight <= 0 then return DEFAULT_MAX_ITEMS end
    return math.max(1, math.floor((available + gap) / (contentHeight + gap)))
end

---Mounts components by priority, fitting as many as possible in available height.
---@param gap number Gap between mounted components
---@param insetX number Horizontal inset
---@param candidates { priority: number, order: number, component: Control|nil }[]
function ColumnBuilder:mountFitted(gap, insetX, candidates)
    local eligible = {}
    for _, c in ipairs(candidates) do
        if c.component then
            eligible[#eligible + 1] = c
        end
    end

    -- Select by priority (lower number = higher priority)
    table.sort(eligible, function(a, b) return a.priority < b.priority end)

    local container = self.parent:GetParent()
    local available = container and container:GetHeight() or 0
    local selected = {}
    local usedHeight = 0

    for _, c in ipairs(eligible) do
        local needed = c.component:GetHeight()
        if #selected > 0 then needed = needed + gap end
        if usedHeight + needed <= available or available == 0 then
            selected[#selected + 1] = c
            usedHeight = usedHeight + needed
        end
    end

    -- Mount in display order
    table.sort(selected, function(a, b) return a.order < b.order end)

    local components = {}
    for _, c in ipairs(selected) do
        components[#components + 1] = c.component
    end
    self:mount(gap, insetX, components)
end

-------------------------
-- Exports
-------------------------

-- Export constants for use by overview_panel.lua and renderers
journal.ROW_CONTENT = ROW_CONTENT
journal.SECTION_GAP = SECTION_GAP
journal.Q3_INSET = 2
journal.DEFAULT_MAX_ITEMS = DEFAULT_MAX_ITEMS

journal.ComponentFactory = ComponentFactory

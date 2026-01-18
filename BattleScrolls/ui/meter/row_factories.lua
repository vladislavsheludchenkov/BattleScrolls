if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.dpsMeterRowFactories = BattleScrolls.dpsMeterRowFactories or {}

local factories = BattleScrolls.dpsMeterRowFactories
local utils = BattleScrolls.dpsMeterUtils

-- ==================== Hodor Design Constants ====================

factories.HODOR_ROW_HEIGHT = 22
factories.HODOR_ICON_SIZE = 22
factories.HODOR_ROW_WIDTH = 320
factories.HODOR_VALUE_WIDTH = 120
factories.HODOR_NAME_WIDTH = factories.HODOR_ROW_WIDTH - factories.HODOR_ICON_SIZE - 10

factories.HODOR_HEADER_OPACITY = 0.8
factories.HODOR_ROW_EVEN_OPACITY = 0.65
factories.HODOR_ROW_ODD_OPACITY = 0.45
factories.HODOR_PLAYER_HIGHLIGHT = { 0, 1, 0, 0.36 }

factories.HODOR_NAME_FONT = "$(BOLD_FONT)|$(KB_18)|outline"
factories.HODOR_VALUE_FONT = "$(GAMEPAD_MEDIUM_FONT)|$(KB_19)|outline"
factories.HODOR_HEADER_FONT = "$(MEDIUM_FONT)|$(KB_16)|outline"

-- ==================== Bars Design Constants ====================

factories.BARS_BAR_WIDTH = 350
factories.BARS_BAR_HEIGHT = 32
factories.BARS_ICON_SIZE = 32
factories.BARS_ROW_WIDTH = factories.BARS_BAR_WIDTH + factories.BARS_ICON_SIZE + 6

-- ==================== Hodor Row Creation ====================

---Create a Hodor-style row control entirely in Lua (matches HodorReflexes layout)
---@param name string Control name
---@param parent Control Parent control
---@return Control control The created row control
function factories.CreateHodorRow(name, parent)
    -- Create row container
    local control = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    control:SetDimensions(factories.HODOR_ROW_WIDTH, factories.HODOR_ROW_HEIGHT)

    -- Create background (black, opacity set dynamically) - using CT_BACKDROP for reliable rendering
    local bg = WINDOW_MANAGER:CreateControl(name .. "Background", control, CT_BACKDROP)
    bg:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
    bg:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, 0, 0)
    bg:SetCenterColor(0, 0, 0, factories.HODOR_ROW_EVEN_OPACITY)
    bg:SetEdgeColor(0, 0, 0, 0)
    bg:SetEdgeTexture("", 1, 1, 1, 0)

    -- Create role icon
    local icon = WINDOW_MANAGER:CreateControl(name .. "Icon", control, CT_TEXTURE)
    icon:SetAnchor(LEFT, control, LEFT, 2, 0)
    icon:SetDimensions(factories.HODOR_ICON_SIZE, factories.HODOR_ICON_SIZE)
    icon:SetTexture(utils.DEFAULT_ROLE_ICON)

    -- Create value label first (right-aligned) so name can anchor to it
    local valueLabel = WINDOW_MANAGER:CreateControl(name .. "Value", control, CT_LABEL)
    valueLabel:SetFont(factories.HODOR_VALUE_FONT)
    valueLabel:SetColor(1, 1, 1, 1)
    valueLabel:SetAnchor(RIGHT, control, RIGHT, -2, 0)
    valueLabel:SetDimensions(factories.HODOR_VALUE_WIDTH, factories.HODOR_ROW_HEIGHT)
    valueLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    valueLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)

    -- Create name label (left-aligned, anchored between icon and value)
    local nameLabel = WINDOW_MANAGER:CreateControl(name .. "Name", control, CT_LABEL)
    nameLabel:SetFont(factories.HODOR_NAME_FONT)
    nameLabel:SetColor(1, 1, 1, 1)
    nameLabel:SetAnchor(LEFT, icon, RIGHT, 5, 0)
    nameLabel:SetAnchor(RIGHT, valueLabel, LEFT, -3, 0)
    nameLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    nameLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    nameLabel:SetMaxLineCount(1)

    return control
end

-- ==================== Bars Row Creation ====================

---Create a Bars-style row control entirely in Lua
---@param name string Control name
---@param parent Control Parent control
---@return Control control The created row control
function factories.CreateBarsRow(name, parent)
    -- Create row container
    local control = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    control:SetDimensions(factories.BARS_ROW_WIDTH, factories.BARS_BAR_HEIGHT + 4)

    -- Create background outline (full row background)
    local bgOutline = WINDOW_MANAGER:CreateControl(name .. "BackgroundOutline", control, CT_BACKDROP)
    bgOutline:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
    bgOutline:SetDimensions(factories.BARS_ROW_WIDTH, factories.BARS_BAR_HEIGHT + 4)
    bgOutline:SetCenterColor(0, 0, 0, 0.6)
    bgOutline:SetEdgeColor(0, 0, 0, 0.8)
    bgOutline:SetEdgeTexture("", 1, 1, 1, 0)

    -- Create icon background (left side square)
    local iconBg = WINDOW_MANAGER:CreateControl(name .. "IconBg", control, CT_BACKDROP)
    iconBg:SetAnchor(LEFT, bgOutline, LEFT, 0, 0)
    iconBg:SetDimensions(factories.BARS_ICON_SIZE + 4, factories.BARS_BAR_HEIGHT + 4)
    iconBg:SetCenterColor(0, 0, 0, 0.8)
    iconBg:SetEdgeColor(0, 0, 0, 0.9)
    iconBg:SetEdgeTexture("", 1, 1, 1, 0)

    -- Create role icon
    local icon = WINDOW_MANAGER:CreateControl(name .. "Icon", control, CT_TEXTURE)
    icon:SetAnchor(CENTER, iconBg, CENTER, 0, 0)
    icon:SetDimensions(factories.BARS_ICON_SIZE, factories.BARS_ICON_SIZE)
    icon:SetTexture(utils.DEFAULT_ROLE_ICON)
    icon:SetDrawLayer(2)

    -- Create bar using CT_STATUSBAR with flat texture for full cell coverage
    local bar = WINDOW_MANAGER:CreateControl(name .. "Bar", control, CT_STATUSBAR)
    bar:SetAnchor(TOPLEFT, iconBg, TOPRIGHT, 0, 0)
    bar:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, 0, 0)
    bar:SetTexture("EsoUI/Art/Miscellaneous/Gamepad/gp_dynamicBar_medium_fill.dds")
    bar:SetTextureCoords(0, 1, 0.25, 0.75)
    bar:SetMinMax(0, 100)
    bar:SetValue(0)
    bar:SetColor(1, 1, 1, 1)
    bar:SetDrawLayer(1)

    -- Create gloss overlay for gradient effect
    local barGloss = WINDOW_MANAGER:CreateControl(name .. "BarGloss", control, CT_STATUSBAR)
    barGloss:SetAnchor(TOPLEFT, bar, TOPLEFT, 0, 0)
    barGloss:SetAnchor(BOTTOMRIGHT, bar, BOTTOMRIGHT, 0, 0)
    barGloss:SetTexture("EsoUI/Art/Miscellaneous/Gamepad/gp_dynamicBar_medium_gloss.dds")
    barGloss:SetTextureCoords(0, 1, 0.25, 0.75)
    barGloss:SetMinMax(0, 100)
    barGloss:SetValue(0)
    barGloss:SetDrawLayer(1)
    barGloss:SetDrawLevel(50)  -- Above the main bar

    -- Create name label (left-aligned, vertically centered)
    local nameLabel = WINDOW_MANAGER:CreateControl(name .. "Name", control, CT_LABEL)
    nameLabel:SetFont("ZoFontGamepad27")
    nameLabel:SetColor(1, 1, 1, 1)
    nameLabel:SetAnchor(LEFT, iconBg, RIGHT, 6, 0)
    nameLabel:SetDimensions(factories.BARS_BAR_WIDTH * 0.55, factories.BARS_BAR_HEIGHT)
    nameLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    nameLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    nameLabel:SetDrawLayer(2)

    -- Create value label (right-aligned, vertically centered)
    local valueLabel = WINDOW_MANAGER:CreateControl(name .. "Value", control, CT_LABEL)
    valueLabel:SetFont("ZoFontGamepad27")
    valueLabel:SetColor(1, 1, 1, 1)
    valueLabel:SetAnchor(RIGHT, control, RIGHT, -6, 0)
    valueLabel:SetDimensions(factories.BARS_BAR_WIDTH * 0.40, factories.BARS_BAR_HEIGHT)
    valueLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    valueLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    valueLabel:SetDrawLayer(2)

    return control
end

-- ==================== Row Configuration Helpers ====================

---Configure a Hodor row as a header
---@param control Control The row control
---@param text string Header text
function factories.ConfigureHodorHeader(control, text)
    local nameLabel = control:GetNamedChild("Name")
    local valueLabel = control:GetNamedChild("Value")
    local icon = control:GetNamedChild("Icon")
    local bg = control:GetNamedChild("Background")

    if nameLabel then
        nameLabel:SetText(text)
        nameLabel:SetFont(factories.HODOR_HEADER_FONT)
        nameLabel:SetWidth(factories.HODOR_NAME_WIDTH)
    end
    if valueLabel then valueLabel:SetText("") end
    if icon then icon:SetHidden(true) end
    if bg then bg:SetCenterColor(0, 0, 0, factories.HODOR_HEADER_OPACITY) end
end

---Configure a Bars row as a header
---@param control Control The row control
---@param text string Header text
function factories.ConfigureBarsHeader(control, text)
    local nameLabel = control:GetNamedChild("Name")
    local valueLabel = control:GetNamedChild("Value")
    local icon = control:GetNamedChild("Icon")
    local bar = control:GetNamedChild("Bar")
    local barGloss = control:GetNamedChild("BarGloss")

    if nameLabel then
        nameLabel:SetText(text)
        nameLabel:SetWidth(factories.BARS_BAR_WIDTH)
    end
    if valueLabel then valueLabel:SetText("") end
    if icon then icon:SetHidden(true) end
    if bar then bar:SetValue(0) end
    if barGloss then barGloss:SetValue(0) end
end

---Configure a Hodor row with data
---@param control Control The row control
---@param member GroupMemberEntry Member data
---@param rowIndex number Row index (1-based)
---@param isPlayer boolean Whether this is the current player
---@param isBossFight boolean Whether in boss fight
function factories.ConfigureHodorDataRow(control, member, rowIndex, isPlayer, isBossFight)
    local nameLabel = control:GetNamedChild("Name")
    local valueLabel = control:GetNamedChild("Value")
    local icon = control:GetNamedChild("Icon")
    local bg = control:GetNamedChild("Background")

    if nameLabel then
        nameLabel:SetText(member.name)
        nameLabel:SetFont(factories.HODOR_NAME_FONT)
    end

    if valueLabel then
        local valueText
        if member.showHealing then
            valueText = string.format("%s / %s",
                utils.FormatDPS(member.effectiveHPS),
                utils.FormatDPS(member.rawHPS))
        elseif isBossFight and member.bossDPS then
            valueText = string.format("%s / %s",
                utils.FormatDPS(member.bossDPS),
                utils.FormatDPS(member.allDPS))
        else
            valueText = utils.FormatDPS(member.allDPS)
        end
        valueLabel:SetText(valueText)
    end

    if icon then
        icon:SetHidden(false)
        icon:SetTexture(utils.GetRoleIcon(member.role))
    end

    if bg then
        if isPlayer then
            local h = factories.HODOR_PLAYER_HIGHLIGHT
            bg:SetCenterColor(h[1], h[2], h[3], h[4])
        else
            local opacity = (rowIndex % 2 == 0) and factories.HODOR_ROW_EVEN_OPACITY or factories.HODOR_ROW_ODD_OPACITY
            bg:SetCenterColor(0, 0, 0, opacity)
        end
    end
end

---Configure a Bars row with data
---@param control Control The row control
---@param member GroupMemberEntry Member data
---@param maxValue number Maximum value for scaling bar
---@param isBossFight boolean Whether in boss fight
function factories.ConfigureBarsDataRow(control, member, maxValue, isBossFight)
    local nameLabel = control:GetNamedChild("Name")
    local valueLabel = control:GetNamedChild("Value")
    local icon = control:GetNamedChild("Icon")
    local bar = control:GetNamedChild("Bar")
    local barGloss = control:GetNamedChild("BarGloss")

    if nameLabel then
        nameLabel:SetText(member.name)
    end

    if valueLabel then
        local valueText
        if member.showHealing then
            valueText = string.format("%s / %s",
                utils.FormatDPS(member.effectiveHPS),
                utils.FormatDPS(member.rawHPS))
        elseif isBossFight and member.bossDPS then
            valueText = string.format("%s / %s",
                utils.FormatDPS(member.bossDPS),
                utils.FormatDPS(member.allDPS))
        else
            valueText = utils.FormatDPS(member.allDPS)
        end
        valueLabel:SetText(valueText)
    end

    if icon then
        icon:SetHidden(false)
        icon:SetTexture(utils.GetRoleIcon(member.role))
    end

    -- Calculate bar fill percentage
    local barValue = member.sortValue or 0
    local fillPercent = maxValue > 0 and (barValue / maxValue * 100) or 0
    fillPercent = math.min(100, math.max(0, fillPercent))

    -- Get player color
    local r, g, b, a = utils.ColorFromName(member.name)

    if bar then
        bar:SetValue(fillPercent)
        bar:SetColor(r, g, b, a)
    end
    if barGloss then
        barGloss:SetValue(fillPercent)
    end
end

---Configure a summary/total row for Hodor
---@param control Control The row control
---@param text string Summary text (e.g., "Total")
---@param value string Value text
function factories.ConfigureHodorSummaryRow(control, text, value)
    local nameLabel = control:GetNamedChild("Name")
    local valueLabel = control:GetNamedChild("Value")
    local icon = control:GetNamedChild("Icon")
    local bg = control:GetNamedChild("Background")

    if nameLabel then
        nameLabel:SetText(text)
        nameLabel:SetFont(factories.HODOR_NAME_FONT)
    end
    if valueLabel then valueLabel:SetText(value) end
    if icon then icon:SetHidden(true) end
    if bg then bg:SetCenterColor(0.2, 0.2, 0.2, 0.7) end
end

---Configure a summary/total row for Bars
---@param control Control The row control
---@param text string Summary text (e.g., "Total")
---@param value string Value text
---@param fillPercent number Bar fill percentage (0-100)
function factories.ConfigureBarsSummaryRow(control, text, value, fillPercent)
    local nameLabel = control:GetNamedChild("Name")
    local valueLabel = control:GetNamedChild("Value")
    local icon = control:GetNamedChild("Icon")
    local bar = control:GetNamedChild("Bar")
    local barGloss = control:GetNamedChild("BarGloss")

    if nameLabel then nameLabel:SetText(text) end
    if valueLabel then valueLabel:SetText(value) end
    if icon then icon:SetHidden(true) end
    if bar then
        bar:SetValue(fillPercent)
        bar:SetColor(0.4, 0.4, 0.4, 1)  -- Neutral gray for total
    end
    if barGloss then barGloss:SetValue(fillPercent) end
end

-- ==================== Row Positioning ====================

---@class RowPositionData
---@field control Control The row control
---@field isHeader boolean Whether this is a header row
---@field isNewSection boolean Whether this starts a new section

---Position rows based on growth direction
---@param allRows RowPositionData[]
---@param container Control The parent container control
---@param growUpward boolean Whether content grows upward
---@param sectionGap number|nil Gap between sections (default 4)
function factories.PositionRows(allRows, container, growUpward, sectionGap)
    sectionGap = sectionGap or 4
    local prevRow = nil
    local startIdx, endIdx, step

    if growUpward then
        startIdx, endIdx, step = #allRows, 1, -1
    else
        startIdx, endIdx, step = 1, #allRows, 1
    end

    local pendingSectionGap = false

    for i = startIdx, endIdx, step do
        local rowData = allRows[i]
        local control = rowData.control
        control:ClearAnchors()

        if growUpward then
            local offsetY = pendingSectionGap and -sectionGap or 0
            if not prevRow then
                control:SetAnchor(BOTTOMLEFT, container, BOTTOMLEFT, 0, 0)
            else
                control:SetAnchor(BOTTOMLEFT, prevRow, TOPLEFT, 0, offsetY)
            end
            pendingSectionGap = rowData.isNewSection
        else
            local offsetY = rowData.isNewSection and sectionGap or 0
            if not prevRow then
                control:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
            else
                control:SetAnchor(TOPLEFT, prevRow, BOTTOMLEFT, 0, offsetY)
            end
        end

        prevRow = control
    end
end

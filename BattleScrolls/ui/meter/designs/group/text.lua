if not SemisPlaygroundCheckAccess() then
    return
end

local utils = BattleScrolls.dpsMeterUtils
local registry = BattleScrolls.dpsMeterDesigns

-- Use shared font constants from utils
local TEXT_FONT = utils.TEXT_FONT
local TEXT_HEADER_FONT = utils.TEXT_HEADER_FONT
local TEXT_TOTAL_FONT = utils.TEXT_TOTAL_FONT

---@class TextGroupDesign : GroupDesignModule
local design = {
    id = "text",
    displayName = GetString(BATTLESCROLLS_DESIGN_GROUP_TEXT),
    order = 10,
    supportsHPS = true,
    settings = {
        { id = "columns", displayName = GetString(BATTLESCROLLS_DESIGN_TEXT_COLUMNS), options = {1, 2}, default = 2,
          tooltipTitle = GetString(BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TITLE),
          tooltipText = GetString(BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TEXT) },
    },
}

-- Private state (container set during Initialize, before createLabel is called)
---@type Control
local container
local labels = {}  -- Pre-created label controls
-- Max labels: 2 headers + 12 members + 1 total + buffer
local MAX_LABELS = 2 + MAX_GROUP_SIZE_THRESHOLD + 1 + 1

local function createLabel(index)
    local label = WINDOW_MANAGER:CreateControl(
        "BattleScrolls_DPSMeterTextLabel" .. index,
        container,
        CT_LABEL
    )
    label:SetFont(TEXT_FONT)
    label:SetColor(1, 1, 1, 1)
    label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    label:SetHidden(true)
    return label
end

function design:Initialize(_meter)
    container = BattleScrolls_DPSMeterGroupDefault

    -- Pre-create all labels upfront
    for i = 1, MAX_LABELS do
        labels[i] = createLabel(i)
    end
end

function design:GetContainer()
    return container
end

function design:Show()
    if container then container:SetHidden(false) end
end

function design:Hide()
    if container then container:SetHidden(true) end
end

function design:Release()
    for _, label in ipairs(labels) do
        label:SetHidden(true)
        label:ClearAnchors()
    end
end

function design:Destroy()
    for _, label in ipairs(labels) do
        label:SetHidden(true)
        label:SetParent(nil)
    end
    labels = {}
end

---@param members GroupMemberEntry[]
---@param ctx GroupRenderContext
function design:Render(members, ctx)
    self:Release()

    if #labels == 0 then return end

    -- Get column setting, but force 1 column for small groups (4 or fewer members)
    local columnsSetting = registry.GetGroupDesignSetting("text", "columns") or 2
    local columns = (#members <= 4) and 1 or columnsSetting

    -- Split members into DPS and HPS groups
    local dpsMembers, hpsMembers = utils.SplitMembersByRole(members)

    -- Build list of all items to display with their text and type
    local items = {}  -- { text, font, isHeader, isNewSection }

    -- DPS Section
    if #dpsMembers > 0 then
        local dpsHeader = ctx.isBossFight and GetString(BATTLESCROLLS_METER_BOSS_ALL_DAMAGE) or GetString(BATTLESCROLLS_METER_ALL_DAMAGE)
        table.insert(items, { text = dpsHeader, font = TEXT_HEADER_FONT, isHeader = true, isNewSection = false })

        for _, member in ipairs(dpsMembers) do
            local text
            if ctx.isBossFight and member.bossDPS then
                text = string.format("%s: %s / %s",
                    member.name,
                    utils.FormatDPS(member.bossDPS),
                    utils.FormatDPS(member.allDPS))
            else
                text = string.format("%s: %s", member.name, utils.FormatDPS(member.allDPS))
            end
            table.insert(items, { text = text, font = TEXT_FONT, isHeader = false, isNewSection = false })
        end

        -- Add Total row if 2+ DPS members
        if #dpsMembers >= 2 and ctx.groupDPS then
            local totalText
            if ctx.isBossFight and ctx.bossGroupDPS then
                totalText = string.format("%s: %s / %s",
                    GetString(BATTLESCROLLS_METER_TOTAL),
                    utils.FormatDPS(ctx.bossGroupDPS),
                    utils.FormatDPS(ctx.groupDPS))
            else
                totalText = string.format("%s: %s", GetString(BATTLESCROLLS_METER_TOTAL), utils.FormatDPS(ctx.groupDPS))
            end
            table.insert(items, { text = totalText, font = TEXT_TOTAL_FONT, isHeader = true, isNewSection = false })
        end
    end

    -- HPS Section
    if #hpsMembers > 0 then
        table.insert(items, { text = GetString(BATTLESCROLLS_METER_EFFECTIVE_RAW_HEALING), font = TEXT_HEADER_FONT, isHeader = true, isNewSection = true })

        for _, member in ipairs(hpsMembers) do
            local text = string.format("%s: %s / %s",
                member.name,
                utils.FormatDPS(member.effectiveHPS or 0),
                utils.FormatDPS(member.rawHPS or 0))
            table.insert(items, { text = text, font = TEXT_FONT, isHeader = false, isNewSection = false })
        end
    end

    -- Configure labels from pre-created array
    local labelData = {}  -- { control, item, textWidth }
    for i, item in ipairs(items) do
        if i > MAX_LABELS then break end
        local label = labels[i]
        label:SetText(item.text)
        label:SetFont(item.font)
        if item.isHeader then
            label:SetColor(0.7, 0.7, 0.7, 1)
        else
            label:SetColor(1, 1, 1, 1)
        end
        label:SetWidth(1000)
        labelData[i] = { control = label, item = item, textWidth = label:GetTextWidth() }
    end

    -- Calculate column widths for 2-column layout
    local maxColumnWidth = 0
    if columns == 2 then
        for _, data in ipairs(labelData) do
            if not data.item.isHeader then
                if data.textWidth > maxColumnWidth then
                    maxColumnWidth = data.textWidth
                end
            end
        end
    end

    -- Position all labels
    local lastRowLabel = nil
    local currentColumn = 1
    local growUpward = ctx.growUpward

    local startIdx, endIdx, step
    if growUpward then
        startIdx, endIdx, step = #labelData, 1, -1
    else
        startIdx, endIdx, step = 1, #labelData, 1
    end

    local pendingSectionGap = false

    for i = startIdx, endIdx, step do
        local data = labelData[i]
        local label = data.control
        local item = data.item

        label:ClearAnchors()

        if growUpward then
            local offsetY = pendingSectionGap and -10 or -2
            if item.isHeader then
                if not lastRowLabel then
                    label:SetAnchor(BOTTOMLEFT, container, BOTTOMLEFT, 0, 0)
                else
                    label:SetAnchor(BOTTOMLEFT, lastRowLabel, TOPLEFT, 0, pendingSectionGap and -10 or -2)
                end
                pendingSectionGap = item.isNewSection
                lastRowLabel = label
                currentColumn = 1
            elseif columns == 1 then
                pendingSectionGap = false
                if not lastRowLabel then
                    label:SetAnchor(BOTTOMLEFT, container, BOTTOMLEFT, 0, 0)
                else
                    label:SetAnchor(BOTTOMLEFT, lastRowLabel, TOPLEFT, 0, offsetY)
                end
                lastRowLabel = label
            else
                pendingSectionGap = false
                if currentColumn == 1 then
                    if not lastRowLabel then
                        label:SetAnchor(BOTTOMLEFT, container, BOTTOMLEFT, 0, 0)
                    else
                        label:SetAnchor(BOTTOMLEFT, lastRowLabel, TOPLEFT, 0, offsetY)
                    end
                    label:SetWidth(maxColumnWidth + 10)
                    lastRowLabel = label
                    currentColumn = 2
                else
                    label:SetAnchor(LEFT, lastRowLabel, RIGHT, 15, 0)
                    label:SetWidth(maxColumnWidth + 10)
                    currentColumn = 1
                end
            end
        else
            if item.isHeader then
                local offsetY = item.isNewSection and 10 or 2
                if not lastRowLabel then
                    label:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
                else
                    label:SetAnchor(TOPLEFT, lastRowLabel, BOTTOMLEFT, 0, offsetY)
                end
                lastRowLabel = label
                currentColumn = 1
            elseif columns == 1 then
                if not lastRowLabel then
                    label:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
                else
                    label:SetAnchor(TOPLEFT, lastRowLabel, BOTTOMLEFT, 0, 2)
                end
                lastRowLabel = label
            else
                if currentColumn == 1 then
                    if not lastRowLabel then
                        label:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
                    else
                        label:SetAnchor(TOPLEFT, lastRowLabel, BOTTOMLEFT, 0, 2)
                    end
                    label:SetWidth(maxColumnWidth + 10)
                    lastRowLabel = label
                    currentColumn = 2
                else
                    label:SetAnchor(LEFT, lastRowLabel, RIGHT, 15, 0)
                    label:SetWidth(maxColumnWidth + 10)
                    currentColumn = 1
                end
            end
        end

        label:SetHidden(false)
    end
end

function design:RenderPreview(members, ctx)
    self:Render(members, ctx)
end

function design:OnSettingChanged(_settingId, _value)
    -- Setting changed, will re-render on next update
end

-- Register with the registry
registry.RegisterGroupDesign(design)

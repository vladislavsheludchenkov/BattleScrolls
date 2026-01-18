if not SemisPlaygroundCheckAccess() then
    return
end

local utils = BattleScrolls.dpsMeterUtils
local registry = BattleScrolls.dpsMeterDesigns
local factories = BattleScrolls.dpsMeterRowFactories

---@class HodorGroupDesign : GroupDesignModule
local design = {
    id = "hodor",
    displayName = GetString(BATTLESCROLLS_DESIGN_GROUP_HODOR),
    description = GetString(BATTLESCROLLS_DESIGN_GROUP_HODOR_DESC),
    order = 20,
    supportsHPS = true,
    settings = {},  -- No custom settings
}

-- Private state
local container = nil
local rows = {}  -- Pre-created row controls
local headerControl = nil
local summaryControl = nil  -- Repurposed as HPS section header
-- Max rows: 12 members + 1 total row
local MAX_ROWS = MAX_GROUP_SIZE_THRESHOLD + 1

local function resetRow(row)
    row:SetHidden(true)
    row:ClearAnchors()
    local bg = row:GetNamedChild("Background")
    if bg then bg:SetCenterColor(0, 0, 0, factories.HODOR_ROW_EVEN_OPACITY) end
end

function design:Initialize(_meter)
    container = BattleScrolls_DPSMeterGroupHodor

    if not container then return end

    local rowsContainer = container:GetNamedChild("Rows")

    -- Hide XML-created controls if they exist
    local xmlHeader = container:GetNamedChild("Header")
    local xmlSummary = container:GetNamedChild("Summary")
    if xmlHeader then xmlHeader:SetHidden(true) end
    if xmlSummary then xmlSummary:SetHidden(true) end

    -- Create header dynamically
    headerControl = factories.CreateHodorRow("BattleScrolls_DPSMeterGroupHodorHeaderLua", container)
    headerControl:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
    local headerBg = headerControl:GetNamedChild("Background")
    if headerBg then headerBg:SetCenterColor(0, 0, 0, factories.HODOR_HEADER_OPACITY) end
    local headerIcon = headerControl:GetNamedChild("Icon")
    if headerIcon then headerIcon:SetHidden(true) end
    local headerNameLabel = headerControl:GetNamedChild("Name")
    if headerNameLabel then headerNameLabel:SetFont(factories.HODOR_HEADER_FONT) end

    -- Create summary/healing header dynamically
    summaryControl = factories.CreateHodorRow("BattleScrolls_DPSMeterGroupHodorSummaryLua", container)
    local summaryBg = summaryControl:GetNamedChild("Background")
    if summaryBg then summaryBg:SetCenterColor(0, 0, 0, factories.HODOR_HEADER_OPACITY) end
    local summaryIcon = summaryControl:GetNamedChild("Icon")
    if summaryIcon then summaryIcon:SetHidden(true) end
    local summaryNameLabel = summaryControl:GetNamedChild("Name")
    if summaryNameLabel then summaryNameLabel:SetFont(factories.HODOR_HEADER_FONT) end

    -- Pre-create all rows upfront
    for i = 1, MAX_ROWS do
        local row = factories.CreateHodorRow(
            "BattleScrolls_DPSMeterHodorRow" .. i,
            rowsContainer or container
        )
        row:SetHidden(true)
        rows[i] = row
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
    for _, row in ipairs(rows) do
        resetRow(row)
    end
    -- Hide header controls to prevent leftover backdrops when group tracker is hidden
    if headerControl then
        headerControl:SetHidden(true)
    end
    if summaryControl then
        summaryControl:SetHidden(true)
    end
end

function design:Destroy()
    for _, row in ipairs(rows) do
        row:SetHidden(true)
        row:SetParent(nil)
    end
    rows = {}
    -- Also destroy the header controls
    if headerControl then
        headerControl:SetHidden(true)
        headerControl:SetParent(nil)
        headerControl = nil
    end
    if summaryControl then
        summaryControl:SetHidden(true)
        summaryControl:SetParent(nil)
        summaryControl = nil
    end
end

---Configure header control
local function configureHeader(control, text)
    if not control then return end
    local nameLabel = control:GetNamedChild("Name")
    local valueLabel = control:GetNamedChild("Value")
    local icon = control:GetNamedChild("Icon")

    if nameLabel then
        nameLabel:SetText(text)
        nameLabel:ClearAnchors()
        nameLabel:SetAnchor(LEFT, control, LEFT, 4, 0)
        nameLabel:SetWidth(factories.HODOR_NAME_WIDTH)
    end
    if valueLabel then valueLabel:SetText("") end
    if icon then icon:SetHidden(true) end
end

---@param members GroupMemberEntry[]
---@param ctx GroupRenderContext
function design:Render(members, ctx)
    self:Release()

    if #rows == 0 then return end

    -- Split members
    local dpsMembers, hpsMembers = utils.SplitMembersByRole(members)

    -- Get current player's display name for highlighting
    local playerDisplayName = ctx.playerDisplayName

    -- Collect all rows for positioning
    local allRows = {}
    local rowIndex = 0

    -- === DPS Section ===
    if #dpsMembers > 0 then
        local dpsHeader = ctx.isBossFight and GetString(BATTLESCROLLS_METER_BOSS_ALL_DAMAGE) or GetString(BATTLESCROLLS_METER_ALL_DAMAGE)
        configureHeader(headerControl, dpsHeader)
        headerControl:SetWidth(factories.HODOR_ROW_WIDTH)
        headerControl:SetHidden(false)
        table.insert(allRows, { control = headerControl, isHeader = true, isNewSection = false })

        for _, member in ipairs(dpsMembers) do
            if rowIndex >= MAX_GROUP_SIZE_THRESHOLD then break end
            rowIndex = rowIndex + 1

            local row = rows[rowIndex]
            local nameLabel = row:GetNamedChild("Name")
            local valueLabel = row:GetNamedChild("Value")
            local bg = row:GetNamedChild("Background")
            local icon = row:GetNamedChild("Icon")

            if nameLabel then nameLabel:SetText(member.name) end
            if valueLabel then
                if ctx.isBossFight then
                    valueLabel:SetText(utils.FormatDPS(member.bossDPS or 0) .. " / " .. utils.FormatDPS(member.allDPS or 0))
                else
                    valueLabel:SetText(utils.FormatDPS(member.allDPS or 0))
                end
            end

            if icon then
                icon:SetTexture(utils.GetRoleIcon(member.role))
                icon:SetHidden(false)
            end

            if bg then
                local isCurrentPlayer = playerDisplayName and member.name == playerDisplayName
                -- Fallback highlight for preview mode when player isn't in the list
                local isFallbackHighlight = not isCurrentPlayer and ctx.highlightFallbackName == member.name
                if isCurrentPlayer or isFallbackHighlight then
                    local h = factories.HODOR_PLAYER_HIGHLIGHT
                    bg:SetCenterColor(h[1], h[2], h[3], h[4])
                else
                    local opacity = (rowIndex % 2 == 0) and factories.HODOR_ROW_EVEN_OPACITY or factories.HODOR_ROW_ODD_OPACITY
                    bg:SetCenterColor(0, 0, 0, opacity)
                end
            end

            row:SetWidth(factories.HODOR_ROW_WIDTH)
            row:SetHidden(false)
            table.insert(allRows, { control = row, isHeader = false, isNewSection = false })
        end

        -- Add Total row if 2+ DPS members
        if #dpsMembers >= 2 and ctx.groupDPS then
            rowIndex = rowIndex + 1
            if rowIndex <= MAX_ROWS then
                local totalRow = rows[rowIndex]
                local nameLabel = totalRow:GetNamedChild("Name")
                local valueLabel = totalRow:GetNamedChild("Value")
                local bg = totalRow:GetNamedChild("Background")
                local icon = totalRow:GetNamedChild("Icon")

                if nameLabel then nameLabel:SetText(GetString(BATTLESCROLLS_METER_TOTAL)) end
                if valueLabel then
                    if ctx.isBossFight and ctx.bossGroupDPS then
                        valueLabel:SetText(utils.FormatDPS(ctx.bossGroupDPS) .. " / " .. utils.FormatDPS(ctx.groupDPS))
                    else
                        valueLabel:SetText(utils.FormatDPS(ctx.groupDPS))
                    end
                end
                if icon then icon:SetHidden(true) end
                if bg then bg:SetCenterColor(0, 0, 0, factories.HODOR_HEADER_OPACITY) end

                totalRow:SetWidth(factories.HODOR_ROW_WIDTH)
                totalRow:SetHidden(false)
                table.insert(allRows, { control = totalRow, isHeader = true, isNewSection = false })
            end
        end
    else
        headerControl:SetHidden(true)
    end

    -- === HPS Section ===
    if #hpsMembers > 0 then
        configureHeader(summaryControl, GetString(BATTLESCROLLS_METER_EFFECTIVE_RAW_HEALING))
        summaryControl:SetWidth(factories.HODOR_ROW_WIDTH)
        summaryControl:SetHidden(false)
        table.insert(allRows, { control = summaryControl, isHeader = true, isNewSection = true })

        for _, member in ipairs(hpsMembers) do
            if rowIndex >= MAX_ROWS then break end
            rowIndex = rowIndex + 1

            local row = rows[rowIndex]
            local nameLabel = row:GetNamedChild("Name")
            local valueLabel = row:GetNamedChild("Value")
            local bg = row:GetNamedChild("Background")
            local icon = row:GetNamedChild("Icon")

            if nameLabel then nameLabel:SetText(member.name) end
            if valueLabel then
                valueLabel:SetText(utils.FormatDPS(member.effectiveHPS or 0) .. " / " .. utils.FormatDPS(member.rawHPS or 0))
            end

            if icon then
                icon:SetTexture(utils.GetRoleIcon(member.role))
                icon:SetHidden(false)
            end

            if bg then
                local isCurrentPlayer = playerDisplayName and member.name == playerDisplayName
                -- Fallback highlight for preview mode when player isn't in the list
                local isFallbackHighlight = not isCurrentPlayer and ctx.highlightFallbackName == member.name
                if isCurrentPlayer or isFallbackHighlight then
                    local h = factories.HODOR_PLAYER_HIGHLIGHT
                    bg:SetCenterColor(h[1], h[2], h[3], h[4])
                else
                    local opacity = (rowIndex % 2 == 0) and factories.HODOR_ROW_EVEN_OPACITY or factories.HODOR_ROW_ODD_OPACITY
                    bg:SetCenterColor(0, 0, 0, opacity)
                end
            end

            row:SetWidth(factories.HODOR_ROW_WIDTH)
            row:SetHidden(false)
            table.insert(allRows, { control = row, isHeader = false, isNewSection = false })
        end
    else
        summaryControl:SetHidden(true)
    end

    -- Position all rows
    factories.PositionRows(allRows, container, ctx.growUpward, 4)
end

function design:RenderPreview(members, ctx)
    self:Render(members, ctx)
end

-- Register with the registry
registry.RegisterGroupDesign(design)

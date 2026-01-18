if not SemisPlaygroundCheckAccess() then
    return
end

local utils = BattleScrolls.dpsMeterUtils
local registry = BattleScrolls.dpsMeterDesigns
local factories = BattleScrolls.dpsMeterRowFactories

---@class BarsGroupDesign : GroupDesignModule
local design = {
    id = "bars",
    displayName = GetString(BATTLESCROLLS_DESIGN_GROUP_BARS),
    description = GetString(BATTLESCROLLS_DESIGN_GROUP_BARS_DESC),
    order = 30,
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
    local bar = row:GetNamedChild("Bar")
    if bar then bar:SetValue(0) end
    local barGloss = row:GetNamedChild("BarGloss")
    if barGloss then barGloss:SetValue(0) end
end

function design:Initialize(_meter)
    container = BattleScrolls_DPSMeterGroupBars

    if not container then return end

    local rowsContainer = container:GetNamedChild("Rows")

    -- Hide XML-created controls if they exist
    local xmlHeader = container:GetNamedChild("Header")
    local xmlSummary = container:GetNamedChild("Summary")
    if xmlHeader then xmlHeader:SetHidden(true) end
    if xmlSummary then xmlSummary:SetHidden(true) end

    -- Create header dynamically
    headerControl = factories.CreateBarsRow("BattleScrolls_DPSMeterGroupBarsHeaderLua", container)
    headerControl:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
    local headerIcon = headerControl:GetNamedChild("Icon")
    if headerIcon then headerIcon:SetHidden(true) end
    local headerBar = headerControl:GetNamedChild("Bar")
    if headerBar then headerBar:SetValue(0) end
    local headerBarGloss = headerControl:GetNamedChild("BarGloss")
    if headerBarGloss then headerBarGloss:SetValue(0) end

    -- Create summary/healing header dynamically
    summaryControl = factories.CreateBarsRow("BattleScrolls_DPSMeterGroupBarsSummaryLua", container)
    local summaryIcon = summaryControl:GetNamedChild("Icon")
    if summaryIcon then summaryIcon:SetHidden(true) end
    local summaryBar = summaryControl:GetNamedChild("Bar")
    if summaryBar then summaryBar:SetValue(0) end
    local summaryBarGloss = summaryControl:GetNamedChild("BarGloss")
    if summaryBarGloss then summaryBarGloss:SetValue(0) end

    -- Pre-create all rows upfront
    for i = 1, MAX_ROWS do
        local row = factories.CreateBarsRow(
            "BattleScrolls_DPSMeterBarsRow" .. i,
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

---@param members GroupMemberEntry[]
---@param ctx GroupRenderContext
function design:Render(members, ctx)
    self:Release()

    if #rows == 0 then return end

    -- Split members
    local dpsMembers, hpsMembers = utils.SplitMembersByRole(members)

    -- Find max values for bar scaling (separate for each section)
    local maxDPS = 0
    for _, member in ipairs(dpsMembers) do
        local value = ctx.isBossFight and member.bossDPS or member.allDPS
        if value and value > maxDPS then maxDPS = value end
    end

    local maxHPS = 0
    for _, member in ipairs(hpsMembers) do
        if member.rawHPS and member.rawHPS > maxHPS then maxHPS = member.rawHPS end
    end

    -- Collect all rows for positioning
    local allRows = {}
    local rowIndex = 0

    -- === DPS Section ===
    if #dpsMembers > 0 then
        local dpsHeader = ctx.isBossFight and GetString(BATTLESCROLLS_METER_BOSS_ALL_DAMAGE) or GetString(BATTLESCROLLS_METER_ALL_DAMAGE)
        configureHeader(headerControl, dpsHeader)
        headerControl:SetHidden(false)
        table.insert(allRows, { control = headerControl, isHeader = true, isNewSection = false })

        for _, member in ipairs(dpsMembers) do
            if rowIndex >= MAX_GROUP_SIZE_THRESHOLD then break end
            rowIndex = rowIndex + 1

            local row = rows[rowIndex]
            local nameLabel = row:GetNamedChild("Name")
            local valueLabel = row:GetNamedChild("Value")
            local bar = row:GetNamedChild("Bar")
            local barGloss = row:GetNamedChild("BarGloss")
            local icon = row:GetNamedChild("Icon")

            local barValue = ctx.isBossFight and member.bossDPS or member.allDPS

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

            if bar then
                local r, g, b, a = utils.ColorFromName(member.name)
                bar:SetColor(r, g, b, a)
                if maxDPS > 0 then
                    local percent = ((barValue or 0) / maxDPS) * 100
                    bar:SetValue(percent)
                    if barGloss then barGloss:SetValue(percent) end
                end
            end

            row:SetWidth(factories.BARS_ROW_WIDTH)
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
                local bar = totalRow:GetNamedChild("Bar")
                local barGloss = totalRow:GetNamedChild("BarGloss")
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
                if bar then
                    bar:SetColor(0.4, 0.4, 0.4, 1)
                    bar:SetValue(100)
                end
                if barGloss then barGloss:SetValue(100) end

                totalRow:SetWidth(factories.BARS_ROW_WIDTH)
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
        summaryControl:SetWidth(factories.BARS_ROW_WIDTH)
        summaryControl:SetHidden(false)
        table.insert(allRows, { control = summaryControl, isHeader = true, isNewSection = true })

        for _, member in ipairs(hpsMembers) do
            if rowIndex >= MAX_ROWS then break end
            rowIndex = rowIndex + 1

            local row = rows[rowIndex]
            local nameLabel = row:GetNamedChild("Name")
            local valueLabel = row:GetNamedChild("Value")
            local bar = row:GetNamedChild("Bar")
            local barGloss = row:GetNamedChild("BarGloss")
            local icon = row:GetNamedChild("Icon")

            local barValue = member.rawHPS

            if nameLabel then nameLabel:SetText(member.name) end
            if valueLabel then
                valueLabel:SetText(utils.FormatDPS(member.effectiveHPS or 0) .. " / " .. utils.FormatDPS(member.rawHPS or 0))
            end
            if icon then
                icon:SetTexture(utils.GetRoleIcon(member.role))
                icon:SetHidden(false)
            end

            if bar then
                local r, g, b, a = utils.ColorFromName(member.name)
                bar:SetColor(r, g, b, a)
                if maxHPS > 0 then
                    local percent = ((barValue or 0) / maxHPS) * 100
                    bar:SetValue(percent)
                    if barGloss then barGloss:SetValue(percent) end
                end
            end

            row:SetWidth(factories.BARS_ROW_WIDTH)
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

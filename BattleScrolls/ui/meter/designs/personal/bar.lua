if not SemisPlaygroundCheckAccess() then
    return
end

-- ESO UI globals created from XML (defined at runtime by UI framework)
---@type any
BattleScrolls_DPSMeterPersonalBar = BattleScrolls_DPSMeterPersonalBar
---@type any
BattleScrolls_DPSMeterPersonalBarProgressBar = BattleScrolls_DPSMeterPersonalBarProgressBar
---@type any
BattleScrolls_DPSMeterPersonalBarProgressBarLeft = BattleScrolls_DPSMeterPersonalBarProgressBarLeft
---@type any
BattleScrolls_DPSMeterPersonalBarTextOverlayValue = BattleScrolls_DPSMeterPersonalBarTextOverlayValue
---@type any
BattleScrolls_DPSMeterPersonalBarTextOverlayDuration = BattleScrolls_DPSMeterPersonalBarTextOverlayDuration

local utils = BattleScrolls.dpsMeterUtils
local registry = BattleScrolls.dpsMeterDesigns

-- ESO resource bar colors (dark/start values)
local COLOR_HEALTH = { 0.447, 0.137, 0.137 }  -- Red
local COLOR_STAMINA = { 0, 0.4, 0.4 }          -- Teal/Cyan
local COLOR_MAGICKA = { 0, 0.184, 0.510 }      -- Blue

---@class BarPersonalDesign : PersonalDesignModule
local design = {
    id = "bar",
    displayName = GetString(BATTLESCROLLS_DESIGN_PERSONAL_BAR),
    order = 30,
    settings = {
        {
            id = "direction",
            displayName = GetString(BATTLESCROLLS_DESIGN_BAR_DIRECTION),
            options = { "right", "left", "center" },
            optionLabels = {
                GetString(BATTLESCROLLS_DESIGN_BAR_DIRECTION_RIGHT),
                GetString(BATTLESCROLLS_DESIGN_BAR_DIRECTION_LEFT),
                GetString(BATTLESCROLLS_DESIGN_BAR_DIRECTION_CENTER),
            },
            default = "right",
        },
    },

    -- Group meter alignment: frame overlay extends ~2px left, thick bar needs vertical padding
    groupAlignmentOffsetX = -2,
    groupPaddingY = 8,
}

-- Private state
local container              ---@type any
local barFill                ---@type any Primary bar (right-facing)
local barFillGloss           ---@type any Gloss for primary bar
local barFillOverlay         ---@type any Overlay (frame) for primary bar
local barFillLeft            ---@type any Secondary bar (left-facing)
local barFillLeftGloss       ---@type any Gloss for secondary bar
local barFillLeftOverlay     ---@type any Overlay (frame) for secondary bar
local barValueLabel          ---@type any
local barDurationLabel       ---@type any
local currentDirection       ---@type string|nil

---Apply label positions based on direction setting
---@param direction string "right", "left", or "center"
local function applyLabelPositions(direction)
    if not barValueLabel or not barDurationLabel then return end

    -- Offsets depend on where the arrow is:
    -- Arrow side needs more clearance (~34px), flat side needs less (~14px)
    local ARROW_OFFSET_LEFT = 34   -- arrow on left side
    local ARROW_OFFSET_RIGHT = -34 -- arrow on right side
    local FLAT_OFFSET_LEFT = 14    -- flat cap on left side
    local FLAT_OFFSET_RIGHT = -14  -- flat cap on right side

    barValueLabel:ClearAnchors()
    barDurationLabel:ClearAnchors()

    if direction == "left" then
        -- Left mode: arrow on left, flat on right
        -- Value on left (at arrow), duration on right (at flat)
        barValueLabel:SetAnchor(TOPLEFT, barValueLabel:GetParent(), TOPLEFT, ARROW_OFFSET_LEFT, 0)
        barValueLabel:SetAnchor(BOTTOMLEFT, barValueLabel:GetParent(), BOTTOMLEFT, ARROW_OFFSET_LEFT, 0)
        barValueLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        barDurationLabel:SetHidden(false)
        barDurationLabel:SetAnchor(TOPRIGHT, barDurationLabel:GetParent(), TOPRIGHT, FLAT_OFFSET_RIGHT, 0)
        barDurationLabel:SetAnchor(BOTTOMRIGHT, barDurationLabel:GetParent(), BOTTOMRIGHT, FLAT_OFFSET_RIGHT, 0)
        barDurationLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    elseif direction == "center" then
        -- Center mode: single centered label (duration + value combined)
        barValueLabel:SetAnchor(CENTER, barValueLabel:GetParent(), CENTER, 0, 0)
        barValueLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

        barDurationLabel:SetHidden(true)
    else  -- "right" (default)
        -- Right mode: flat on left, arrow on right
        -- Value on right (at arrow), duration on left (at flat)
        barValueLabel:SetAnchor(TOPRIGHT, barValueLabel:GetParent(), TOPRIGHT, ARROW_OFFSET_RIGHT, 0)
        barValueLabel:SetAnchor(BOTTOMRIGHT, barValueLabel:GetParent(), BOTTOMRIGHT, ARROW_OFFSET_RIGHT, 0)
        barValueLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

        barDurationLabel:SetHidden(false)
        barDurationLabel:SetAnchor(TOPLEFT, barDurationLabel:GetParent(), TOPLEFT, FLAT_OFFSET_LEFT, 0)
        barDurationLabel:SetAnchor(BOTTOMLEFT, barDurationLabel:GetParent(), BOTTOMLEFT, FLAT_OFFSET_LEFT, 0)
        barDurationLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    end
end

---Apply bar alignment based on direction setting
local function applyDirection()
    if not barFill or not barFillLeft then return end

    local direction = registry.GetPersonalDesignSetting("bar", "direction") or "right"
    if direction == currentDirection then return end
    currentDirection = direction

    -- Apply label positions based on direction
    applyLabelPositions(direction)

    if direction == "center" then
        -- Center mode: use both bars meeting exactly at center (like ESO health bar)
        -- Left bar: LEFT edge to CENTER
        -- Right bar: CENTER to RIGHT edge
        -- No overlap = no gloss brightness issue
        barFill:SetHidden(false)
        barFillLeft:SetHidden(false)

        -- Get container height for proper vertical anchoring
        local _, containerHeight = container:GetDimensions()

        -- Anchor like ESO's health bar: bars meet exactly at center
        -- Use full corner anchoring to ensure proper dimensions
        barFillLeft:ClearAnchors()
        barFillLeft:SetAnchor(TOPLEFT, container, TOPLEFT)
        barFillLeft:SetAnchor(BOTTOMRIGHT, container, TOP, 0, containerHeight)  -- RIGHT edge at horizontal center
        barFillLeft:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
        if barFillLeftGloss then
            barFillLeftGloss:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
        end

        barFill:ClearAnchors()
        barFill:SetAnchor(TOPLEFT, container, TOP, 0, 0)  -- LEFT edge at horizontal center
        barFill:SetAnchor(BOTTOMRIGHT, container, BOTTOMRIGHT)
        barFill:SetBarAlignment(BAR_ALIGNMENT_NORMAL)
        if barFillGloss then
            barFillGloss:SetBarAlignment(BAR_ALIGNMENT_NORMAL)
        end

        -- Hide inner frame/BG edges for seamless center appearance
        -- AND re-anchor Middle textures so they extend to the edge (not to the hidden element)
        if barFillOverlay then
            local leftEdge = barFillOverlay:GetNamedChild("Left")
            local middle = barFillOverlay:GetNamedChild("Middle")
            if leftEdge then leftEdge:SetHidden(true) end
            -- Re-anchor Middle to extend from left edge of barFill (not from hidden Left texture)
            if middle then
                middle:ClearAnchors()
                middle:SetAnchor(TOPLEFT, barFill, TOPLEFT)
                middle:SetAnchor(BOTTOMRIGHT, barFillOverlay:GetNamedChild("Right"), BOTTOMLEFT)
            end
        end
        if barFillLeftOverlay then
            local rightEdge = barFillLeftOverlay:GetNamedChild("Right")
            local middle = barFillLeftOverlay:GetNamedChild("Middle")
            if rightEdge then rightEdge:SetHidden(true) end
            -- Re-anchor Middle to extend to right edge of barFillLeft (not to hidden Right texture)
            if middle then
                middle:ClearAnchors()
                middle:SetAnchor(TOPLEFT, barFillLeftOverlay:GetNamedChild("Left"), TOPRIGHT)
                middle:SetAnchor(BOTTOMRIGHT, barFillLeft, BOTTOMRIGHT)
            end
        end
        -- Also hide BG inner edges and re-anchor their Middle/Fill textures
        local barFillBG = barFill and barFill:GetNamedChild("BG")
        if barFillBG then
            local bgLeft = barFillBG:GetNamedChild("Left")
            local bgFill = barFillBG:GetNamedChild("Fill")
            if bgLeft then bgLeft:SetHidden(true) end
            -- Re-anchor Fill to extend from left edge (not from hidden Left)
            if bgFill then
                bgFill:ClearAnchors()
                bgFill:SetAnchor(TOPLEFT, barFill, TOPLEFT)
                bgFill:SetAnchor(BOTTOMRIGHT, barFillBG:GetNamedChild("Right"), BOTTOMLEFT)
            end
        end
        local barFillLeftBG = barFillLeft and barFillLeft:GetNamedChild("BG")
        if barFillLeftBG then
            local bgRight = barFillLeftBG:GetNamedChild("Right")
            local bgFill = barFillLeftBG:GetNamedChild("Fill")
            if bgRight then bgRight:SetHidden(true) end
            -- Re-anchor Fill to extend to right edge (not to hidden Right)
            if bgFill then
                bgFill:ClearAnchors()
                bgFill:SetAnchor(TOPLEFT, barFillLeftBG:GetNamedChild("Left"), TOPRIGHT)
                bgFill:SetAnchor(BOTTOMRIGHT, barFillLeft, BOTTOMRIGHT)
            end
        end

    elseif direction == "left" then
        -- Left mode: use left-facing bar only (with mirrored textures)
        barFill:SetHidden(true)
        barFillLeft:SetHidden(false)

        barFillLeft:ClearAnchors()
        barFillLeft:SetAnchor(TOPLEFT, container, TOPLEFT)
        barFillLeft:SetAnchor(BOTTOMRIGHT, container, BOTTOMRIGHT)
        barFillLeft:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
        if barFillLeftGloss then
            barFillLeftGloss:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
        end

        -- Restore frame edges and Middle anchors (in case switching from center mode)
        if barFillLeftOverlay then
            local rightEdge = barFillLeftOverlay:GetNamedChild("Right")
            local leftEdge = barFillLeftOverlay:GetNamedChild("Left")
            local middle = barFillLeftOverlay:GetNamedChild("Middle")
            if rightEdge then rightEdge:SetHidden(false) end
            -- Restore Middle's original anchoring between Left and Right
            if middle and leftEdge and rightEdge then
                middle:ClearAnchors()
                middle:SetAnchor(TOPLEFT, leftEdge, TOPRIGHT)
                middle:SetAnchor(BOTTOMRIGHT, rightEdge, BOTTOMLEFT)
            end
        end
        -- Restore BG Fill anchors
        local barFillLeftBG = barFillLeft and barFillLeft:GetNamedChild("BG")
        if barFillLeftBG then
            local bgRight = barFillLeftBG:GetNamedChild("Right")
            local bgLeft = barFillLeftBG:GetNamedChild("Left")
            local bgFill = barFillLeftBG:GetNamedChild("Fill")
            if bgRight then bgRight:SetHidden(false) end
            -- Restore Fill's original anchoring between Left and Right
            if bgFill and bgLeft and bgRight then
                bgFill:ClearAnchors()
                bgFill:SetAnchor(TOPLEFT, bgLeft, TOPRIGHT)
                bgFill:SetAnchor(BOTTOMRIGHT, bgRight, BOTTOMLEFT)
            end
        end

    else  -- "right" (default)
        -- Right mode: use right-facing bar only
        barFill:SetHidden(false)
        barFillLeft:SetHidden(true)

        barFill:ClearAnchors()
        barFill:SetAnchor(TOPLEFT, container, TOPLEFT)
        barFill:SetAnchor(BOTTOMRIGHT, container, BOTTOMRIGHT)
        barFill:SetBarAlignment(BAR_ALIGNMENT_NORMAL)
        if barFillGloss then
            barFillGloss:SetBarAlignment(BAR_ALIGNMENT_NORMAL)
        end

        -- Restore frame/BG edges and Middle anchors (in case switching from center mode)
        if barFillOverlay then
            local leftEdge = barFillOverlay:GetNamedChild("Left")
            local rightEdge = barFillOverlay:GetNamedChild("Right")
            local middle = barFillOverlay:GetNamedChild("Middle")
            if leftEdge then leftEdge:SetHidden(false) end
            -- Restore Middle's original anchoring between Left and Right
            if middle and leftEdge and rightEdge then
                middle:ClearAnchors()
                middle:SetAnchor(TOPLEFT, leftEdge, TOPRIGHT)
                middle:SetAnchor(BOTTOMRIGHT, rightEdge, BOTTOMLEFT)
            end
        end
        local barFillBG = barFill and barFill:GetNamedChild("BG")
        if barFillBG then
            local bgLeft = barFillBG:GetNamedChild("Left")
            local bgRight = barFillBG:GetNamedChild("Right")
            local bgFill = barFillBG:GetNamedChild("Fill")
            if bgLeft then bgLeft:SetHidden(false) end
            -- Restore Fill's original anchoring between Left and Right
            if bgFill and bgLeft and bgRight then
                bgFill:ClearAnchors()
                bgFill:SetAnchor(TOPLEFT, bgLeft, TOPRIGHT)
                bgFill:SetAnchor(BOTTOMRIGHT, bgRight, BOTTOMLEFT)
            end
        end
    end
end

---Handle setting changes
function design:OnSettingChanged(settingId, _value)
    if settingId == "direction" then
        applyDirection()
    end
end

function design:Initialize(_meter)
    container = BattleScrolls_DPSMeterPersonalBar
    barFill = BattleScrolls_DPSMeterPersonalBarProgressBar
    barFillGloss = barFill and barFill:GetNamedChild("Gloss")
    barFillOverlay = barFill and barFill:GetNamedChild("Overlay")
    barFillLeft = BattleScrolls_DPSMeterPersonalBarProgressBarLeft
    barFillLeftGloss = barFillLeft and barFillLeft:GetNamedChild("Gloss")
    barFillLeftOverlay = barFillLeft and barFillLeft:GetNamedChild("Overlay")
    barValueLabel = BattleScrolls_DPSMeterPersonalBarTextOverlayValue
    barDurationLabel = BattleScrolls_DPSMeterPersonalBarTextOverlayDuration

    -- Apply initial direction setting
    applyDirection()
end

function design:GetContainer()
    return container
end

function design:GetBottomAnchor()
    return container
end

function design:GetTopAnchor()
    return container
end

function design:Show()
    -- Ensure direction is applied (in case setting changed while hidden)
    applyDirection()
    -- Initialize bars BEFORE making container visible to avoid white flash
    -- Must initialize both bars regardless of visibility since applyDirection() may change which is visible
    if barFill then
        barFill:SetMinMax(0, 100)
        barFill:SetValue(0)
        barFill:SetColor(COLOR_STAMINA[1], COLOR_STAMINA[2], COLOR_STAMINA[3], 1)
    end
    if barFillLeft then
        barFillLeft:SetMinMax(0, 100)
        barFillLeft:SetValue(0)
        barFillLeft:SetColor(COLOR_STAMINA[1], COLOR_STAMINA[2], COLOR_STAMINA[3], 1)
    end
    -- Now make container visible
    if container then container:SetHidden(false) end
end

function design:Hide()
    if container then container:SetHidden(true) end
end

---Count DDs in the current group
---@return number numDDs Number of players with DPS role (minimum 1)
local function countGroupDDs()
    local groupSize = GetGroupSize()
    if groupSize == 0 then
        return 1  -- Solo, count self as DD
    end

    local ddCount = 0
    for i = 1, groupSize do
        local unitTag = GetGroupUnitTagByIndex(i)
        if unitTag then
            local role = GetGroupMemberSelectedRole(unitTag)
            if role == LFG_ROLE_DPS then
                ddCount = ddCount + 1
            end
        end
    end

    -- Fallback: if no DDs found (everyone is tank/healer or roles not set), assume all are DDs
    if ddCount == 0 then
        ddCount = groupSize > 0 and groupSize or 1
    end

    return ddCount
end

---@param _calc ArithmancerInstance Unused, context contains computed values
---@param ctx PersonalRenderContext
function design:Render(_calc, ctx)
    if not barFill then return end

    local barPercent
    if ctx.showHealing then
        -- Healing: 50% bar = target HPS based on group size
        -- Up to 6 people: 6k HPS per person
        -- Above 6 people: +2k HPS per additional person
        local groupSize = math.max(1, GetGroupSize())
        local basePeople = math.min(groupSize, 6)
        local extraPeople = math.max(0, groupSize - 6)
        local targetHPS = 6000 * basePeople + 2000 * extraPeople
        local rawHPS = ctx.personalRawHPS
        barPercent = (rawHPS / targetHPS) * 50
    else
        -- Damage
        local share = ctx.isBossFight and ctx.bossPersonalShare or ctx.personalShare
        local numDDs = countGroupDDs()
        if numDDs <= 1 then
            -- Solo or single DD: no scaling, direct percentage
            barPercent = share
        else
            -- Multiple DDs: 50% bar = fair share (100% / numDDs)
            local fairShare = 100 / numDDs
            barPercent = (share / fairShare) * 50
        end
    end

    -- Clamp to 0-100%
    barPercent = math.max(0, math.min(100, barPercent))

    -- Set bar color based on performance using ESO resource colors
    -- Health (red) = low, Stamina (teal) = average, Magicka (blue) = high
    local r, g, b
    if barPercent >= 80 then
        -- High performance: magicka blue
        r, g, b = COLOR_MAGICKA[1], COLOR_MAGICKA[2], COLOR_MAGICKA[3]
    elseif barPercent >= 60 then
        -- Above average: stamina to magicka
        local t = (barPercent - 60) / 20
        r, g, b = utils.LerpColorHSL(COLOR_STAMINA, COLOR_MAGICKA, t)
    elseif barPercent >= 40 then
        -- Average (fair share): stamina teal
        r, g, b = COLOR_STAMINA[1], COLOR_STAMINA[2], COLOR_STAMINA[3]
    elseif barPercent >= 20 then
        -- Below average: health to stamina
        local t = (barPercent - 20) / 20
        r, g, b = utils.LerpColorHSL(COLOR_HEALTH, COLOR_STAMINA, t)
    else
        -- Low performance: health red
        r, g, b = COLOR_HEALTH[1], COLOR_HEALTH[2], COLOR_HEALTH[3]
    end

    -- Set bar value(s) based on direction mode
    if currentDirection == "center" then
        -- Center mode: both bars show the same percentage (each covers half the width)
        if barFill and not barFill:IsHidden() then
            barFill:SetMinMax(0, 100)
            barFill:SetValue(barPercent)
            barFill:SetColor(r, g, b, 1)
        end
        if barFillLeft and not barFillLeft:IsHidden() then
            barFillLeft:SetMinMax(0, 100)
            barFillLeft:SetValue(barPercent)
            barFillLeft:SetColor(r, g, b, 1)
        end
    elseif currentDirection == "left" then
        -- Left mode: only update the left-facing bar
        if barFillLeft then
            barFillLeft:SetMinMax(0, 100)
            barFillLeft:SetValue(barPercent)
            barFillLeft:SetColor(r, g, b, 1)
        end
    else  -- "right"
        -- Right mode: only update the right-facing bar
        if barFill then
            barFill:SetMinMax(0, 100)
            barFill:SetValue(barPercent)
            barFill:SetColor(r, g, b, 1)
        end
    end

    -- Set value label
    local valueText
    if ctx.showHealing then
        valueText = string.format("%s HPS", utils.FormatDPS(ctx.personalRawHPS))
    else
        if ctx.isBossFight then
            valueText = string.format("%s DPS", utils.FormatDPSWithShare(ctx.bossPersonalDPS, ctx.bossPersonalShare))
        else
            valueText = string.format("%s DPS", utils.FormatDPSWithShare(ctx.personalDPS, ctx.personalShare))
        end
    end

    -- Set labels based on direction mode
    if currentDirection == "center" then
        -- Center mode: combined label "[duration] value"
        barValueLabel:SetText(string.format("[%s] %s", ctx.durationStr, valueText))
    else
        barValueLabel:SetText(valueText)
        barDurationLabel:SetText(string.format("[%s]", ctx.durationStr))
    end
end

-- Register with the registry
registry.RegisterPersonalDesign(design)

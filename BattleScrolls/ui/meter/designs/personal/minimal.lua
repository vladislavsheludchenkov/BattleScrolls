if not SemisPlaygroundCheckAccess() then
    return
end

local utils = BattleScrolls.dpsMeterUtils
local registry = BattleScrolls.dpsMeterDesigns

---@class MinimalPersonalDesign : PersonalDesignModule
local design = {
    id = "minimal",
    displayName = GetString(BATTLESCROLLS_DESIGN_PERSONAL_MINIMAL),
    order = 20,
    settings = {},  -- No custom settings

    -- No group alignment offset needed - plain text with no decorations
    -- groupAlignmentOffsetX defaults to 0
    -- groupPaddingY defaults to 0
}

-- Private state
local container = nil
local lineLabel = nil

function design:Initialize(_meter)
    container = BattleScrolls_DPSMeterPersonalMinimal
    lineLabel = BattleScrolls_DPSMeterPersonalMinimalLine
end

function design:GetContainer()
    return container
end

function design:GetBottomAnchor()
    return lineLabel
end

function design:GetTopAnchor()
    return lineLabel
end

function design:Show()
    if container then container:SetHidden(false) end
end

function design:Hide()
    if container then container:SetHidden(true) end
end

---@param _calc ArithmancerInstance Unused, context contains computed values
---@param ctx PersonalRenderContext
function design:Render(_calc, ctx)
    if not lineLabel then return end

    local text
    if ctx.showHealing then
        local effectivePct = ctx.personalTotalRawHealingOut > 0 and
                (ctx.personalTotalEffectiveHealingOut / ctx.personalTotalRawHealingOut * 100) or 0
        text = string.format("[%s] %s %s (%.0f%% %s)",
                ctx.durationStr,
                utils.FormatDPS(ctx.personalRawHPS),
                "HPS",
                effectivePct,
                GetString(BATTLESCROLLS_METER_EFF))
    else
        if not ctx.isBossFight then
            text = string.format("[%s] %s",
                    ctx.durationStr,
                    utils.FormatDPSWithShare(ctx.personalDPS, ctx.personalShare))
        else
            text = string.format("[%s] %s: %s",
                    ctx.durationStr,
                    GetString(BATTLESCROLLS_METER_BOSS),
                    utils.FormatDPSWithShare(ctx.bossPersonalDPS, ctx.bossPersonalShare))
        end
    end

    lineLabel:SetText(text)
end

-- Register with the registry
registry.RegisterPersonalDesign(design)

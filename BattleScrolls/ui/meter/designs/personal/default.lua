if not SemisPlaygroundCheckAccess() then
    return
end

local utils = BattleScrolls.dpsMeterUtils
local registry = BattleScrolls.dpsMeterDesigns

---@class DefaultPersonalDesign : PersonalDesignModule
local design = {
    id = "default",
    displayName = GetString(BATTLESCROLLS_DESIGN_PERSONAL_DEFAULT),
    order = 10,
    settings = {},  -- No custom settings

    -- Group meter alignment: background texture extends 10px left of text
    groupAlignmentOffsetX = -10,
}

-- Private state
local container = nil
local line1Label = nil
local line2Label = nil

function design:Initialize(_meter)
    container = BattleScrolls_DPSMeterPersonalDefault
    line1Label = BattleScrolls_DPSMeterPersonalDefaultLine1
    line2Label = BattleScrolls_DPSMeterPersonalDefaultLine2
end

function design:GetContainer()
    return container
end

function design:GetBottomAnchor()
    return line2Label
end

function design:GetTopAnchor()
    return line1Label
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
    if not line1Label or not line2Label then return end

    if ctx.showHealing then
        local line1 = string.format("%s HPS", utils.FormatDPS(ctx.personalRawHPS))
        line1Label:SetText(line1)

        local effectivePct = ctx.personalTotalRawHealingOut > 0 and
                (ctx.personalTotalEffectiveHealingOut / ctx.personalTotalRawHealingOut * 100) or 0
        line2Label:SetText(string.format("[%s] %.0f%% %s", ctx.durationStr, effectivePct, GetString(BATTLESCROLLS_METER_EFFECTIVE)))
    else
        if not ctx.isBossFight then
            line1Label:SetText(utils.FormatDPSAndShare(ctx.personalDPS, ctx.personalShare))
            line2Label:SetText(string.format("[%s] %s", ctx.durationStr, GetString(BATTLESCROLLS_METER_ALL_DAMAGE)))
        else
            line1Label:SetText(GetString(BATTLESCROLLS_METER_BOSS) .. ": " .. utils.FormatDPSAndShare(ctx.bossPersonalDPS, ctx.bossPersonalShare))
            line2Label:SetText(string.format("[%s] %s: %s", ctx.durationStr, GetString(BATTLESCROLLS_METER_ALL), utils.FormatDPSAndShare(ctx.personalDPS, ctx.personalShare)))
        end
    end
end

-- Register with the registry
registry.RegisterPersonalDesign(design)

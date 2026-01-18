-----------------------------------------------------------
-- DPSMeter
-- Real-time DPS/HPS display controller for Battle Scrolls
--
-- Shows personal and group damage/healing metrics during
-- combat with configurable designs and positioning.
--
-- Features:
--   - Plugin-based design system (personal/group designs)
--   - Position/scale customization
--   - Linger mode (display persists after combat)
--   - Group DPS aggregation via DPSShare
--   - Preview mode for settings
--
-- State machine: HIDDEN → ACTIVE → LINGERING → HIDDEN
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

-- ESO UI globals created from XML (defined at runtime by UI framework)
---@type any
BattleScrolls_DPSMeterPersonal = BattleScrolls_DPSMeterPersonal
---@type any
BattleScrolls_DPSMeterPersonalDefault = BattleScrolls_DPSMeterPersonalDefault
---@type any
BattleScrolls_DPSMeterPersonalMinimal = BattleScrolls_DPSMeterPersonalMinimal
---@type any
BattleScrolls_DPSMeterPersonalDefaultLine1 = BattleScrolls_DPSMeterPersonalDefaultLine1
---@type any
BattleScrolls_DPSMeterPersonalDefaultLine2 = BattleScrolls_DPSMeterPersonalDefaultLine2
---@type any
BattleScrolls_DPSMeterPersonalMinimalLine = BattleScrolls_DPSMeterPersonalMinimalLine
---@type any
BattleScrolls_DPSMeterGroup = BattleScrolls_DPSMeterGroup
---@type any
BattleScrolls_DPSMeterGroupDefault = BattleScrolls_DPSMeterGroupDefault
---@type any
BattleScrolls_DPSMeterGroupHodor = BattleScrolls_DPSMeterGroupHodor
---@type any
BattleScrolls_DPSMeterGroupBars = BattleScrolls_DPSMeterGroupBars

BattleScrolls = BattleScrolls or {}

local utils = BattleScrolls.dpsMeterUtils
local registry = BattleScrolls.dpsMeterDesigns

---@class DPSMeterGroupData
---@field allTargetsDPS number DPS against all targets
---@field bossDPS number|nil DPS against bosses only
---@field rawHPS number Raw healing per second
---@field effectiveHPS number Effective (non-overheal) HPS
---@field role number LFG_ROLE_* constant (DPS, HEAL, TANK)

---@class DPSMeterPersonalValues
---@field dps number Personal DPS (all targets)
---@field share number Personal damage share percentage
---@field rawHPS number Personal raw HPS
---@field totalRawHealingOut number Total raw healing
---@field totalEffectiveHealingOut number Total effective healing
---@field bossDPS number Personal boss DPS
---@field bossShare number Personal boss damage share

---@class DPSMeter
---@field personalControl Control|nil TopLevelControl for personal meter
---@field groupControl Control|nil TopLevelControl for group meter
---@field state DPSMeterState Current display state
---@field lingerTimerId number|nil Timer ID for linger countdown
---@field previewTimerId number|nil Timer ID for preview auto-hide
---@field groupMetrics table<string, DPSMeterGroupData> DPS/HPS data from group members by display name
---@field task Effect|nil Currently running update task (if any)
---@field isBossFight boolean Whether current fight has bosses
---@field calculator ArithmancerInstance|nil Current Arithmancer calculator instance
---@field currentPersonalDesign PersonalDesignModule|nil Active personal design
---@field currentGroupDesign GroupDesignModule|nil Active group design
---@field savedGroupMetrics table<string, DPSMeterGroupData>|nil Saved group metrics during preview
---@field savedIsBossFight boolean|nil Saved boss fight flag during preview
---@field isPreviewActive boolean True while preview is showing, prevents normal updates
---@field groupDPS number|nil Group DPS from current/last combat
---@field bossGroupDPS number|nil Boss group DPS from current/last combat
---@field personalValues DPSMeterPersonalValues|nil Personal values from current/last combat
---@field lastCombatEndTimeMs number|nil Timestamp when combat ended

---@type DPSMeter
local dpsMeter = {
    personalControl = nil,
    groupControl = nil,
    state = "HIDDEN",
    lingerTimerId = nil,
    previewTimerId = nil,
    savedPersonalTier = nil,
    savedPersonalLayer = nil,
    savedGroupTier = nil,
    savedGroupLayer = nil,
    groupMetrics = {},
    isBossFight = false,
    calculator = nil,
    currentPersonalDesign = nil,
    currentGroupDesign = nil,
    -- Preview state preservation
    savedGroupMetrics = nil,
    savedIsBossFight = nil,
    isPreviewActive = false,
    -- Track when combat ended for linger time calculations
    lastCombatEndTimeMs = nil,
}

BattleScrolls.dpsMeter = dpsMeter

-- Constants
local UPDATE_INTERVAL_MS = 200
local PREVIEW_DURATION_MS = 1200

---@type GroupMemberEntry[]
local reusableMembers = {}

---Get group DPS from stored state or groupMetrics fallback
---@return number|nil groupDPS All targets group DPS
---@return number|nil bossGroupDPS Boss-only group DPS (nil if not boss fight)
function dpsMeter:GetGroupDPS()
    -- Use stored values from last RenderDisplay
    if self.groupDPS then
        return self.groupDPS, self.bossGroupDPS
    end

    -- Fallback: sum from groupMetrics (different semantics - sums member-reported DPS)
    if self.groupMetrics then
        local totalDPS = 0
        local totalBossDPS = 0
        local hasBossDPS = false

        for _, data in pairs(self.groupMetrics) do
            local allDPS = data.allTargetsDPS or 0
            local rawHPS = data.rawHPS or 0
            if allDPS >= rawHPS then
                totalDPS = totalDPS + allDPS
                if data.bossDPS then
                    totalBossDPS = totalBossDPS + data.bossDPS
                    hasBossDPS = true
                end
            end
        end

        if totalDPS > 0 then
            return totalDPS, hasBossDPS and totalBossDPS or nil
        end
    end

    return nil, nil
end

---Initialize the DPS meter module
function dpsMeter:Initialize()
    LibEffect.Async(function()
        LibEffect.Sleep(1333):Await()

        -- Get control references
        self.personalControl = BattleScrolls_DPSMeterPersonal
        self.groupControl = BattleScrolls_DPSMeterGroup

        if not self.personalControl then
            -- BattleScrolls.log.Error("DPSMeter: Could not find control BattleScrolls_DPSMeterPersonal")
            return
        end

        -- Initialize all registered designs
        registry.InitializeAllDesigns(self)
        LibEffect.YieldWithGC():Await()

        -- Apply initial design and position settings
        self:ApplyPersonalDesign()
        self:ApplyGroupDesign()
        LibEffect.YieldWithGC():Await()

        self:ApplyPersonalOffsets()
        self:ApplyGroupPosition()
        LibEffect.YieldWithGC():Await()

        self:ApplyPersonalScale()
        self:ApplyGroupScale()
        LibEffect.YieldWithGC():Await()

        -- Register as state observer
        BattleScrolls.state:RegisterObserver(self)

        -- Hide when menus are open (HUD is hidden)
        HUD_SCENE:RegisterCallback("StateChange", function(_oldState, newState)
            self:OnHUDStateChange(newState)
        end)
        HUD_UI_SCENE:RegisterCallback("StateChange", function(_oldState, newState)
            self:OnHUDStateChange(newState)
        end)

        BattleScrolls.dpsShare:RegisterCallback("BattleScrolls_DPSMeter", function(unitTag, allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
            self:OnGroupDataArrived(unitTag, allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
        end)

        -- BattleScrolls.log.Info("DPSMeter initialized")
    end):Run()
end

---Check if personal DPS meter is enabled in settings
---@return boolean
function dpsMeter:IsPersonalEnabled()
    local settings = utils.GetSettings()
    return settings.dpsMeterPersonalEnabled ~= false
end

---Check if group DPS meter is enabled in settings
---@return boolean
function dpsMeter:IsGroupEnabled()
    local settings = utils.GetSettings()
    return settings.dpsMeterGroupEnabled ~= false
end

---Check if any meter (personal or group) is enabled
---@return boolean
function dpsMeter:IsAnyMeterEnabled()
    return self:IsPersonalEnabled() or self:IsGroupEnabled()
end

---Check if group should show when solo (only player in group data)
---@return boolean
function dpsMeter:ShouldShowGroupSolo()
    local settings = utils.GetSettings()
    return settings.dpsMeterGroupShowSolo == true
end

---Get linger duration from settings
---@return number lingerMs (-1 = always show, 0 = no linger, positive = linger time)
function dpsMeter:GetLingerMs()
    local settings, defaults = utils.GetSettings()
    return settings.dpsMeterLingerMs or defaults.dpsMeterLingerMs
end

---Called when the linger setting changes, applies the new value immediately
function dpsMeter:OnLingerSettingChanged()
    -- Cancel any existing linger timer
    if self.lingerTimerId then
        zo_removeCallLater(self.lingerTimerId)
        self.lingerTimerId = nil
    end

    -- If in combat or no data, setting will apply when combat ends
    if self.state == "ACTIVE" or not self.calculator or not self:IsAnyMeterEnabled() then
        return
    end

    -- Calculate remaining linger time
    local lingerMs = self:GetLingerMs()
    local remainingMs
    if lingerMs == -1 then
        remainingMs = -1  -- infinite
    elseif lingerMs == 0 or not self.lastCombatEndTimeMs then
        remainingMs = 0
    else
        remainingMs = lingerMs - (GetGameTimeMilliseconds() - self.lastCombatEndTimeMs)
        if remainingMs < 0 then remainingMs = 0 end
    end

    -- Should be hidden
    if remainingMs == 0 then
        if self.state ~= "HIDDEN" then
            self:Hide()
        end
        return
    end

    -- Should be visible - update state, controls will show when menu closes via OnHUDStateChange
    if self.state == "HIDDEN" then
        self.state = "LINGERING"
        -- Personal meter already rendered during combat, just update group display
        self:UpdateGroupDisplay()
    end

    -- Set timer if not infinite
    if remainingMs > 0 then
        self.lingerTimerId = zo_callLater(function()
            self.lingerTimerId = nil
            self:Hide()
        end, remainingMs)
    end
end

---Apply personal design from settings
function dpsMeter:ApplyPersonalDesign()
    local settings, defaults = utils.GetSettings()
    local designId = settings.dpsMeterPersonalDesign or defaults.dpsMeterPersonalDesign

    -- Hide all personal design containers
    for _, id in ipairs(registry.GetPersonalDesignIds()) do
        local design = registry.GetPersonalDesign(id)
        if design then
            design:Hide()
        end
    end

    -- Show the selected design
    local design = registry.GetPersonalDesign(designId)
    if design then
        design:Show()
        self.currentPersonalDesign = design
    else
        -- Fallback to first available and update setting
        local firstId = registry.GetPersonalDesignIds()[1]
        if firstId then
            design = registry.GetPersonalDesign(firstId)
            if design then
                design:Show()
                self.currentPersonalDesign = design
                -- Update saved setting to valid fallback
                settings.dpsMeterPersonalDesign = firstId
                -- BattleScrolls.log.Warn("DPSMeter: Personal design '" .. designId .. "' not found, using '" .. firstId .. "'")
            end
        end
    end
end

---Apply group design from settings
function dpsMeter:ApplyGroupDesign()
    local settings, defaults = utils.GetSettings()
    local designId = settings.dpsMeterGroupDesign or defaults.dpsMeterGroupDesign

    -- Hide all group design containers
    for _, id in ipairs(registry.GetGroupDesignIds()) do
        local design = registry.GetGroupDesign(id)
        if design then
            design:Hide()
        end
    end

    -- Show the selected design
    local design = registry.GetGroupDesign(designId)
    if design then
        design:Show()
        self.currentGroupDesign = design
    else
        -- Fallback to first available and update setting
        local firstId = registry.GetGroupDesignIds()[1]
        if firstId then
            design = registry.GetGroupDesign(firstId)
            if design then
                design:Show()
                self.currentGroupDesign = design
                -- Update saved setting to valid fallback
                settings.dpsMeterGroupDesign = firstId
                -- BattleScrolls.log.Warn("DPSMeter: Group design '" .. designId .. "' not found, using '" .. firstId .. "'")
            end
        end
    end
end

---Apply personal offsets from settings
function dpsMeter:ApplyPersonalOffsets()
    if not self.personalControl then return end

    local settings, defaults = utils.GetSettings()
    local offsetX = settings.dpsMeterPersonalOffsetX or defaults.dpsMeterPersonalOffsetX
    local offsetY = settings.dpsMeterPersonalOffsetY or defaults.dpsMeterPersonalOffsetY

    self.personalControl:ClearAnchors()
    self.personalControl:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, offsetX, offsetY)
end

---Get the bottom anchor control for group positioning (from current personal design)
function dpsMeter:GetPersonalBottomAnchor()
    if self.currentPersonalDesign and self.currentPersonalDesign.GetBottomAnchor then
        return self.currentPersonalDesign:GetBottomAnchor()
    end
    return self.personalControl
end

---Get the top anchor control for group positioning (from current personal design)
function dpsMeter:GetPersonalTopAnchor()
    if self.currentPersonalDesign and self.currentPersonalDesign.GetTopAnchor then
        return self.currentPersonalDesign:GetTopAnchor()
    end
    return self.personalControl
end

---Apply group position mode and offsets
function dpsMeter:ApplyGroupPosition()
    if not self.groupControl then return end

    local settings, defaults = utils.GetSettings()
    local position = settings.dpsMeterGroupPosition or defaults.dpsMeterGroupPosition
    local personalScale = settings.dpsMeterPersonalScale or defaults.dpsMeterPersonalScale

    -- When personal meter is disabled, force separate positioning (but don't change the saved setting)
    local personalEnabled = self:IsPersonalEnabled()
    if not personalEnabled then
        position = "separate"
    end

    -- Get alignment offsets from current personal design (extensible - no hardcoded design IDs)
    -- Offsets are scaled by personal scale to maintain alignment at all scales
    local alignmentOffsetX = 0
    local paddingY = 0
    if self.currentPersonalDesign then
        alignmentOffsetX = (self.currentPersonalDesign.groupAlignmentOffsetX or 0) * personalScale
        paddingY = (self.currentPersonalDesign.groupPaddingY or 0) * personalScale
    end

    -- Ensure all design containers are anchored to fill their parent (groupControl)
    -- This restores the XML-defined anchors in case they were cleared previously
    for _, id in ipairs(registry.GetGroupDesignIds()) do
        local design = registry.GetGroupDesign(id)
        if design then
            local container = design:GetContainer()
            if container then
                container:ClearAnchors()
                container:SetAnchor(TOPLEFT, self.groupControl, TOPLEFT, 0, 0)
                container:SetAnchor(BOTTOMRIGHT, self.groupControl, BOTTOMRIGHT, 0, 0)
            end
        end
    end

    -- Position the main group control
    self.groupControl:ClearAnchors()

    if position == "separate" then
        local offsetX = settings.dpsMeterGroupOffsetX or defaults.dpsMeterGroupOffsetX
        local offsetY = settings.dpsMeterGroupOffsetY or defaults.dpsMeterGroupOffsetY
        self.groupControl:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, offsetX, offsetY)
    elseif position == "above" then
        local topAnchor = self:GetPersonalTopAnchor()
        self.groupControl:SetAnchor(BOTTOMLEFT, topAnchor, TOPLEFT, alignmentOffsetX, -paddingY)
    else -- below
        local bottomAnchor = self:GetPersonalBottomAnchor()
        self.groupControl:SetAnchor(TOPLEFT, bottomAnchor, BOTTOMLEFT, alignmentOffsetX, paddingY)
    end
end

---Apply personal scale from settings
function dpsMeter:ApplyPersonalScale()
    if not self.personalControl then return end
    local settings, defaults = utils.GetSettings()
    local scale = settings.dpsMeterPersonalScale or defaults.dpsMeterPersonalScale
    self.personalControl:SetScale(scale)
end

---Apply group scale from settings
function dpsMeter:ApplyGroupScale()
    if not self.groupControl then return end
    local settings, defaults = utils.GetSettings()
    local scale = settings.dpsMeterGroupScale or defaults.dpsMeterGroupScale
    self.groupControl:SetScale(scale)
end

-- Sample data for group preview
local PREVIEW_DATA = {
    { name = "Acuity Nuke", role = LFG_ROLE_DPS, isHealer = false },
    { name = "Simmering", role = LFG_ROLE_DPS, isHealer = false },
    { name = "Beam Machine", role = LFG_ROLE_DPS, isHealer = false },
    { name = "Sul-Xan Catcher", role = LFG_ROLE_DPS, isHealer = false },
    { name = "Chill-den", role = LFG_ROLE_DPS, isHealer = false },
    { name = "Still-in-Kilt", role = LFG_ROLE_DPS, isHealer = false },
    { name = "Oakensoul Enjoyer", role = LFG_ROLE_DPS, isHealer = false },
    { name = "Zen's War Machine", role = LFG_ROLE_DPS, isHealer = false },
    { name = "Healcarver", role = LFG_ROLE_HEAL, isHealer = true },
    { name = "Drops SPC", role = LFG_ROLE_HEAL, isHealer = true },
    { name = "Yolnahkriin Fan", role = LFG_ROLE_TANK, isHealer = false },
    { name = "Permablock", role = LFG_ROLE_TANK, isHealer = false },
}

-- Mock calculator for personal meter preview (conforms to ArithmancerInstance)
local PREVIEW_CALC = {
    -- Duration
    getDurationS = function() return 102 end,  -- 1:42

    -- Personal damage
    personalTotalDamage = function() return 7976400 end,  -- 78.2K DPS * 102s
    personalDPS = function() return 78200 end,
    personalShare = function() return 28 end,

    -- Boss damage
    bossPersonalTotalDamage = function() return 6987000 end,  -- 68.5K DPS * 102s
    bossPersonalDPS = function() return 68500 end,
    bossPersonalShare = function() return 25 end,
    bossGroupTotalDamage = function() return 27948000 end,  -- 4x personal boss damage

    -- Group damage
    groupTotalDamage = function() return 28487143 end,  -- personal / 0.28

    -- Damage taken
    damageTakenTotal = function() return 850000 end,

    -- Healing out
    personalTotalRawHealingOut = function() return 4590000 end,  -- 45K HPS * 102s
    personalTotalEffectiveHealingOut = function() return 3213000 end,  -- 70% effective
    personalRawHPSOut = function() return 45000 end,
    personalEffectiveHPSOut = function() return 31500 end,

    -- Breakdowns (on-demand, return mock data)
    personalAoeVsSingleTarget = function() return { aoe = 4786000, singleTarget = 3190400 } end,  -- 60/40 split
    bossAoeVsSingleTarget = function() return { aoe = 3493500, singleTarget = 3493500 } end,  -- 50/50 split
    personalDotVsDirect = function() return { dot = 3190560, direct = 4785840 } end,  -- 40/60 split
    bossDotVsDirect = function() return { dot = 2794800, direct = 4192200 } end,  -- 40/60 split

    -- Boss fight flag
    isBossFight = function() return true end,
}

---Show both personal and group meters temporarily on top of all UI for preview
function dpsMeter:ShowPreview()
    if not self.personalControl then return end

    if self.previewTimerId then
        zo_removeCallLater(self.previewTimerId)
        self.previewTimerId = nil
    end

    self.isPreviewActive = true

    -- Show personal meter preview only if enabled
    if self:IsPersonalEnabled() then
        if not self.savedPersonalTier then
            self.savedPersonalTier = self.personalControl:GetDrawTier()
        end
        if not self.savedPersonalLayer then
            self.savedPersonalLayer = self.personalControl:GetDrawLayer()
        end

        self.personalControl:SetDrawLayer(DL_OVERLAY)
        self.personalControl:SetDrawTier(DT_HIGH)
        self.personalControl:SetHidden(false)

        -- Save current state before overwriting with preview data
        if self.savedPersonalValues == nil then
            self.savedPersonalValues = self.personalValues
            self.savedCalculator = self.calculator
            self.savedIsBossFightPersonal = self.isBossFight
        end

        -- Set preview data and render using normal code path
        self.calculator = PREVIEW_CALC
        self.isBossFight = true
        self.personalValues = {
            dps = PREVIEW_CALC:personalDPS(),
            share = PREVIEW_CALC:personalShare(),
            rawHPS = PREVIEW_CALC:personalRawHPSOut(),
            totalRawHealingOut = PREVIEW_CALC:personalTotalRawHealingOut(),
            totalEffectiveHealingOut = PREVIEW_CALC:personalTotalEffectiveHealingOut(),
            bossDPS = PREVIEW_CALC:bossPersonalDPS(),
            bossShare = PREVIEW_CALC:bossPersonalShare(),
        }
        self:UpdatePersonalDisplay(true)
    else
        -- Hide personal when disabled
        self.personalControl:SetHidden(true)
    end

    -- Show or hide group meter based on enabled state
    if self.groupControl then
        if self:IsGroupEnabled() then
            if not self.savedGroupTier then
                self.savedGroupTier = self.groupControl:GetDrawTier()
            end
            if not self.savedGroupLayer then
                self.savedGroupLayer = self.groupControl:GetDrawLayer()
            end

            self.groupControl:SetDrawLayer(DL_OVERLAY)
            self.groupControl:SetDrawTier(DT_HIGH)
            self.groupControl:SetHidden(false)

            -- Save current state before overwriting with preview data
            if self.savedGroupMetrics == nil then
                self.savedGroupMetrics = self.groupMetrics
                self.savedIsBossFight = self.isBossFight
            end

            -- Generate preview data
            self.groupMetrics = {}
            local ddRank = 0
            local healerRank = 0
            local tankRank = 0

            for i = 1, 12 do
                local data = PREVIEW_DATA[i]
                if data.isHealer then
                    healerRank = healerRank + 1
                    local rawHPS = 60000 - (healerRank - 1) * 8000
                    local effectiveHPS = rawHPS * (0.90 - (healerRank - 1) * 0.05)
                    self.groupMetrics[data.name] = {
                        allTargetsDPS = rawHPS * 0.1,
                        bossDPS = rawHPS * 0.08,
                        rawHPS = rawHPS,
                        effectiveHPS = effectiveHPS,
                        role = data.role
                    }
                elseif data.role == LFG_ROLE_TANK then
                    tankRank = tankRank + 1
                    local dps = 8000 - (tankRank - 1) * 2000
                    self.groupMetrics[data.name] = {
                        allTargetsDPS = dps,
                        bossDPS = dps * 0.85,
                        rawHPS = 0,
                        effectiveHPS = 0,
                        role = data.role
                    }
                else
                    ddRank = ddRank + 1
                    local dps = 80000 - (ddRank - 1) * 5000
                    self.groupMetrics[data.name] = {
                        allTargetsDPS = dps,
                        bossDPS = dps * 0.85,
                        rawHPS = 0,
                        effectiveHPS = 0,
                        role = data.role
                    }
                end
            end

            self.isBossFight = true
            self:UpdateGroupDisplay(true)  -- forceRender for preview mode
        else
            -- Hide group meter if disabled
            self.groupControl:SetHidden(true)
            self:ReleaseGroupDesign()
        end
    end

    -- Auto-hide after preview duration
    self.previewTimerId = zo_callLater(function()
        self:EndPreview()
    end, PREVIEW_DURATION_MS)
end


---End preview mode and restore normal state
function dpsMeter:EndPreview()
    if self.previewTimerId then
        zo_removeCallLater(self.previewTimerId)
        self.previewTimerId = nil
    end

    self.isPreviewActive = false

    if self.personalControl then
        if self.savedPersonalTier then
            self.personalControl:SetDrawTier(self.savedPersonalTier)
            self.savedPersonalTier = nil
        end
        if self.savedPersonalLayer then
            self.personalControl:SetDrawLayer(self.savedPersonalLayer)
            self.savedPersonalLayer = nil
        end

        -- Hide personal if state is HIDDEN or personal is disabled
        if self.state == "HIDDEN" or not self:IsPersonalEnabled() or not HUD_FRAGMENT:IsShowing() then
            self.personalControl:SetHidden(true)
        end
    end

    if self.groupControl then
        if self.savedGroupTier then
            self.groupControl:SetDrawTier(self.savedGroupTier)
            self.savedGroupTier = nil
        end
        if self.savedGroupLayer then
            self.groupControl:SetDrawLayer(self.savedGroupLayer)
            self.savedGroupLayer = nil
        end

        if self.state == "HIDDEN" then
            self.groupControl:SetHidden(true)
            self:ReleaseGroupDesign()
        elseif not HUD_FRAGMENT:IsShowing() then
            self.groupControl:SetHidden(true)
        end
    end

    -- Restore saved personal state or clear
    if self.savedPersonalValues ~= nil then
        self.personalValues = self.savedPersonalValues
        self.calculator = self.savedCalculator
        self.isBossFight = self.savedIsBossFightPersonal or false
        self.savedPersonalValues = nil
        self.savedCalculator = nil
        self.savedIsBossFightPersonal = nil
    else
        self.personalValues = nil
        self.calculator = nil
        self.isBossFight = false
    end

    -- Restore saved group state or clear
    if self.savedGroupMetrics ~= nil then
        self.groupMetrics = self.savedGroupMetrics
        -- Only restore isBossFight from group if personal didn't set it
        if self.savedIsBossFight ~= nil then
            self.isBossFight = self.savedIsBossFight
        end
        self.savedGroupMetrics = nil
        self.savedIsBossFight = nil
    else
        self.groupMetrics = {}
    end

    -- Re-render displays to restore actual values if meter is visible
    if self.state ~= "HIDDEN" then
        self:UpdatePersonalDisplay()
        self:UpdateGroupDisplay()
    end
end

---Release current group design resources
function dpsMeter:ReleaseGroupDesign()
    if self.currentGroupDesign and self.currentGroupDesign.Release then
        self.currentGroupDesign:Release()
    end
end

---Destroy current group design pool objects to free memory
function dpsMeter:DestroyGroupDesign()
    if self.currentGroupDesign and self.currentGroupDesign.Destroy then
        self.currentGroupDesign:Destroy()
    elseif self.currentGroupDesign and self.currentGroupDesign.Release then
        -- Fallback to release if design doesn't implement Destroy
        self.currentGroupDesign:Release()
    end
end

---Called when HUD visibility changes
function dpsMeter:OnHUDStateChange(newState)
    if newState == SCENE_HIDDEN then
        if self.personalControl then
            self.personalControl:SetHidden(true)
        end
        if self.groupControl then
            self.groupControl:SetHidden(true)
        end
    elseif newState == SCENE_SHOWN then
        if self.state ~= "HIDDEN" then
            if self.personalControl and self:IsPersonalEnabled() then
                self.personalControl:SetHidden(false)
            end
            if self.groupControl and self:IsGroupEnabled() then
                self.groupControl:SetHidden(false)
            end
        end
    end
end

---Called when combat starts
function dpsMeter:OnStateInitialized()
    if not self:IsAnyMeterEnabled() then return end

    if self.lingerTimerId then
        zo_removeCallLater(self.lingerTimerId)
        self.lingerTimerId = nil
    end

    self.state = "ACTIVE"
    self.groupMetrics = {}
    -- Clear stored computed values from previous combat
    self.groupDPS = nil
    self.bossGroupDPS = nil
    self.personalValues = nil

    if self.personalControl and self:IsPersonalEnabled() then
        self.personalControl:SetHidden(false)
    end
    if self.groupControl and self:IsGroupEnabled() then
        self.groupControl:SetHidden(false)
    end

    EVENT_MANAGER:RegisterForUpdate("BattleScrolls_DPSMeter_Update", UPDATE_INTERVAL_MS, function()
        self:UpdateDisplay()
    end)
end

---Called when combat ends
function dpsMeter:OnStatePreReset()
    EVENT_MANAGER:UnregisterForUpdate("BattleScrolls_DPSMeter_Update")

    self:UpdateDisplay(true)

    -- Record when combat ended for linger time calculations
    self.lastCombatEndTimeMs = GetGameTimeMilliseconds()

    local lingerMs = self:GetLingerMs()

    if lingerMs == -1 then
        self.state = "LINGERING"
        return
    end

    if lingerMs > 0 then
        self.state = "LINGERING"
        self.lingerTimerId = zo_callLater(function()
            self.lingerTimerId = nil
            self:Hide()
        end, lingerMs)
    else
        self:Hide()
    end
end

---Hide the DPS meter (preserves calculator for potential re-show via setting change)
function dpsMeter:Hide()
    self.state = "HIDDEN"

    if self.personalControl then
        self.personalControl:SetHidden(true)
    end
    if self.groupControl then
        self.groupControl:SetHidden(true)
    end
    -- Release pool objects (but keep design initialized for potential re-show)
    self:ReleaseGroupDesign()
end

---Format DPS number for display (delegate to utils)
function dpsMeter:FormatDPS(dps)
    return utils.FormatDPS(dps)
end

---Format DPS and share for display (delegate to utils)
function dpsMeter:FormatDPSAndShare(dps, share)
    return utils.FormatDPSAndShare(dps, share)
end

---Format DPS with share for minimal design (delegate to utils)
function dpsMeter:FormatDPSWithShare(dps, share)
    return utils.FormatDPSWithShare(dps, share)
end

---Update the group display based on current design
---@param forceRender boolean|nil If true, skip state checks (for preview mode)
function dpsMeter:UpdateGroupDisplay(forceRender)
    if not self:IsGroupEnabled() then
        self:ReleaseGroupDesign()
        return
    end

    if not forceRender and self.state == "HIDDEN" then
        self:ReleaseGroupDesign()
        return
    end

    -- Collect and sort group data
    utils.ClearMembers(reusableMembers)

    for displayName, data in pairs(self.groupMetrics) do
        local allDPS = data.allTargetsDPS or 0
        local bossDPS = data.bossDPS
        local rawHPS = data.rawHPS or 0
        local effectiveHPS = data.effectiveHPS or 0
        local showHealing = rawHPS > allDPS
        local sortValue = showHealing and rawHPS or (self.isBossFight and bossDPS or allDPS)

        if sortValue and sortValue > 0 then
            local entry = utils.GetMemberEntry()
            entry.name = displayName
            entry.allDPS = allDPS
            entry.bossDPS = bossDPS
            entry.rawHPS = rawHPS
            entry.effectiveHPS = effectiveHPS
            entry.showHealing = showHealing
            entry.sortValue = sortValue
            entry.role = data.role
            table.insert(reusableMembers, entry)
        end
    end

    local members = reusableMembers

    -- Hide if no members, or if only one member and "show solo" is disabled
    local minMembers = self:ShouldShowGroupSolo() and 1 or 2
    if #members < minMembers then
        self:ReleaseGroupDesign()
        return
    end

    table.sort(members, function(a, b)
        return a.sortValue > b.sortValue
    end)

    -- Get current position setting
    local settings, defaults = utils.GetSettings()
    local position = settings.dpsMeterGroupPosition or defaults.dpsMeterGroupPosition
    local growUpward = (position == "above")

    -- Get player display name for highlighting
    local playerDisplayName = GetUnitDisplayName("player")
    if playerDisplayName then
        playerDisplayName = zo_strformat("<<1>>", playerDisplayName)
    end

    -- Check if player's name is in the members list
    local playerFoundInMembers = false
    for _, member in ipairs(members) do
        if member.name == playerDisplayName then
            playerFoundInMembers = true
            break
        end
    end

    -- If player not found (e.g., preview mode), compute a stable fallback highlight
    -- based on player's display name so different players see different rows highlighted
    local highlightFallbackName = nil
    if not playerFoundInMembers and playerDisplayName and #members > 0 then
        local hash = 0
        for i = 1, #playerDisplayName do
            hash = (hash * 31 + string.byte(playerDisplayName, i)) % 2147483647
        end
        local fallbackIndex = (hash % #members) + 1
        highlightFallbackName = members[fallbackIndex].name
    end

    -- Get group totals
    local groupDPS, bossGroupDPS = self:GetGroupDPS()

    -- Build context for design
    local ctx = {
        isBossFight = self.isBossFight,
        growUpward = growUpward,
        playerDisplayName = playerDisplayName,
        highlightFallbackName = highlightFallbackName,
        groupDPS = groupDPS,
        bossGroupDPS = bossGroupDPS,
        dpsMeter = self,
    }

    -- Render using current group design
    if self.currentGroupDesign then
        self.currentGroupDesign:Render(members, ctx)
    end
end

---Update the display with current values (async)
---@param force boolean|nil If true, cancels current computation and starts new one with snapshot
function dpsMeter:UpdateDisplay(force)
    -- Skip updates during preview to preserve preview display
    if self.isPreviewActive then return end

    if self.task ~= nil then
        if force == true then
            self.task:Cancel()
        else
            return
        end
    end

    local source = force and BattleScrolls.state:Snapshot() or BattleScrolls.state

    self.task = LibEffect.Async(function()
        local calc = BattleScrolls.arithmancer:New(source)
        local isBossFight = calc:isBossFight()
        local durationS = calc:getDurationS()

        -- Compute all values needed by personal designs
        local personalDPS = calc:personalDPS()
        local personalShare = calc:personalShare()
        local personalRawHPS = calc:personalRawHPSOut()
        local personalTotalRawHealingOut = calc:personalTotalRawHealingOut()
        local personalTotalEffectiveHealingOut = calc:personalTotalEffectiveHealingOut()

        local bossPersonalDPS = 0
        local bossPersonalShare = 0
        if isBossFight then
            bossPersonalDPS = calc:bossPersonalDPS()
            bossPersonalShare = calc:bossPersonalShare()
        end

        -- Compute group values
        local groupTotalDamage = calc:groupTotalDamage()
        local bossGroupTotalDamage = 0
        if isBossFight then
            bossGroupTotalDamage = calc:bossGroupTotalDamage()
        end

        local groupDPS = durationS > 0 and groupTotalDamage / durationS or nil
        local bossGroupDPS = (durationS > 0 and bossGroupTotalDamage > 0) and bossGroupTotalDamage / durationS or nil

        -- Build personal values for designs
        local personalValues = {
            dps = personalDPS,
            share = personalShare,
            rawHPS = personalRawHPS,
            totalRawHealingOut = personalTotalRawHealingOut,
            totalEffectiveHealingOut = personalTotalEffectiveHealingOut,
            bossDPS = bossPersonalDPS,
            bossShare = bossPersonalShare,
        }

        self:RenderDisplay(calc, personalValues, groupDPS, bossGroupDPS)
    end):Ensure(function()
        self.task = nil
    end):Run()
end

---Render the display with calculated values
---@param calc ArithmancerInstance The calculator instance
---@param personalValues DPSMeterPersonalValues Pre-computed personal values for designs
---@param groupDPS number|nil Group DPS
---@param bossGroupDPS number|nil Boss group DPS
function dpsMeter:RenderDisplay(calc, personalValues, groupDPS, bossGroupDPS)
    self.isBossFight = calc:isBossFight()
    self.calculator = calc

    -- Store computed values for GetGroupDPS and re-renders
    self.personalValues = personalValues
    self.groupDPS = groupDPS
    self.bossGroupDPS = bossGroupDPS

    -- Render personal and group meters
    self:UpdatePersonalDisplay()
    self:UpdateGroupDisplay()
end

---Update the personal meter display
---@param forceRender boolean|nil If true, render even when hidden (for preview mode)
function dpsMeter:UpdatePersonalDisplay(forceRender)
    if not self:IsPersonalEnabled() then return end
    if not forceRender and self.state == "HIDDEN" then return end
    if not self.currentPersonalDesign then return end
    if not self.calculator or not self.personalValues then return end

    local personalValues = self.personalValues
    local durationStr = utils.FormatDuration(self.calculator:getDurationS())
    local showHealing = utils.ShouldShowHealing(personalValues.dps, personalValues.rawHPS)

    local ctx = {
        durationStr = durationStr,
        showHealing = showHealing,
        isBossFight = self.isBossFight,
        dpsMeter = self,
        -- Pre-computed values for designs (no calc method calls needed)
        personalDPS = personalValues.dps,
        personalShare = personalValues.share,
        personalRawHPS = personalValues.rawHPS,
        personalTotalRawHealingOut = personalValues.totalRawHealingOut,
        personalTotalEffectiveHealingOut = personalValues.totalEffectiveHealingOut,
        bossPersonalDPS = personalValues.bossDPS,
        bossPersonalShare = personalValues.bossShare,
    }

    self.currentPersonalDesign:Render(self.calculator, ctx)
end

---Handle group member data arrival
---@param unitTag string Unit tag (e.g., "group1")
---@param allTargetsDPS number DPS against all targets
---@param bossDPS number|nil DPS against bosses only
---@param rawHPS number Raw healing per second
---@param effectiveHPS number Effective HPS
function dpsMeter:OnGroupDataArrived(unitTag, allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
    local displayName = GetUnitDisplayName(unitTag)
    if not displayName then return end

    displayName = zo_strformat("<<1>>", displayName)

    local role = LFG_ROLE_DPS
    if IsUnitGrouped("player") then
        role = GetGroupMemberSelectedRole(unitTag) or LFG_ROLE_DPS
    end

    local data = {
        allTargetsDPS = allTargetsDPS,
        bossDPS = bossDPS,
        rawHPS = rawHPS,
        effectiveHPS = effectiveHPS,
        role = role,
    }

    -- During preview, update saved metrics instead of active preview data
    if self.isPreviewActive and self.savedGroupMetrics then
        self.savedGroupMetrics[displayName] = data
        return  -- Don't update display during preview
    end

    self.groupMetrics[displayName] = data

    if self.state ~= "HIDDEN" then
        self:UpdateGroupDisplay()
    end
end

---Cleanup all event registrations for hot reload support
function dpsMeter:Cleanup()
    -- Cancel any running task
    if self.task then
        self.task:Cancel()
        self.task = nil
    end

    -- Cancel any timers
    if self.lingerTimerId then
        zo_removeCallLater(self.lingerTimerId)
        self.lingerTimerId = nil
    end
    if self.previewTimerId then
        zo_removeCallLater(self.previewTimerId)
        self.previewTimerId = nil
    end

    -- Unregister update timer
    EVENT_MANAGER:UnregisterForUpdate("BattleScrolls_DPSMeter_Update")

    -- Unregister from state observer
    if BattleScrolls.state and BattleScrolls.state.UnregisterObserver then
        BattleScrolls.state:UnregisterObserver(self)
    end

    -- Unregister from dpsShare
    if BattleScrolls.dpsShare and BattleScrolls.dpsShare.UnregisterCallback then
        BattleScrolls.dpsShare:UnregisterCallback("BattleScrolls_DPSMeter")
    end

    -- Note: HUD_SCENE callbacks are managed by ESO scene system
    -- and don't have a clean unregister API

    self.state = "HIDDEN"
    self.calculator = nil
    self.groupMetrics = {}
    -- Clear stored computed values
    self.groupDPS = nil
    self.bossGroupDPS = nil
    self.personalValues = nil
end

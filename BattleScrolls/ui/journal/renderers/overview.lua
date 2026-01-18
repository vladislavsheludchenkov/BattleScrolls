-----------------------------------------------------------
-- Overview Renderer
-- Standalone renderer for overview stats tab
--
-- All functions receive a JournalRenderContext and operate
-- on the list without needing a class instance.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local utils = journal.utils
local StatIcons = journal.StatIcons

local OverviewRenderer = {}

-------------------------
-- Height Calculation Helpers
-------------------------

-- Row heights for section calculation (must match XML and overview_panel.lua constants)
local ROW_CONTENT = {
    SECTION_HEADER = 50,  -- BattleScrolls_OverviewSectionHeader
    STAT_ROW = 36,        -- BattleScrolls_OverviewStatRow
}
local ROW_GAPS = {
    SECTION_HEADER = 15,  -- Anchor gap between sections
    STAT_ROW = 10,        -- Anchor gap between stat rows
}

---Calculates height for a Q2 section (header + N rows)
---@param rowCount number Number of stat rows in the section
---@return number height Total height in pixels
local function CalculateSectionHeight(rowCount)
    local headerHeight = ROW_CONTENT.SECTION_HEADER + ROW_GAPS.SECTION_HEADER
    local rowsHeight = rowCount * ROW_CONTENT.STAT_ROW + math.max(0, rowCount - 1) * ROW_GAPS.STAT_ROW
    return headerHeight + rowsHeight
end

---Calculates dynamic section priorities based on player metrics
---Lower priority number = higher importance (selected first)
---@param dps number Personal DPS
---@param hps number Prevalent healing HPS (from most relevant healing type)
---@param dtps number Damage taken per second
---@return number encounterPriority Always 1 (always show)
---@return number damagePriority Priority for damage section
---@return number healingPriority Priority for healing section
---@return number damageTakenPriority Priority for damage taken section
local function CalculateDynamicPriorities(dps, hps, dtps)
    -- Weight DTPS to make it comparable to DPS/HPS (tanks typically have lower raw DTPS)
    local weightedDTPS = dtps * 10

    -- Calculate total activity score
    local totalActivity = dps + hps + weightedDTPS
    if totalActivity == 0 then
        -- Default priorities when no activity
        return 1, 2, 3, 4
    end

    -- Calculate relevance scores (0 to 1)
    local dpsRelevance = dps / totalActivity
    local hpsRelevance = hps / totalActivity
    local dtpsRelevance = weightedDTPS / totalActivity

    -- Map relevance to priority range
    -- Higher relevance → lower priority number (higher priority)
    -- Priority range: 2 (highest for role-specific) to 5 (lowest)
    local priorityRange = 3  -- 5 - 2 = 3
    local basePriority = 2

    -- Encounter is always priority 1
    local encounterPriority = 1

    -- Damage priority: high DPS relevance → low priority number
    local damagePriority = basePriority + priorityRange * (1 - dpsRelevance)

    -- Healing priority: high HPS relevance → low priority number
    local healingPriority = basePriority + priorityRange * (1 - hpsRelevance)

    -- Damage taken priority: high DTPS relevance → low priority number
    local damageTakenPriority = basePriority + priorityRange * (1 - dtpsRelevance)

    return encounterPriority, damagePriority, healingPriority, damageTakenPriority
end

-------------------------
-- Public API
-------------------------

---Renders the Overview stats tab
---@param ctx JournalRenderContext
---@return Effect
function OverviewRenderer.renderOverview(ctx)
    return LibEffect.Async(function()
        local list = ctx.list
        local encounter = ctx.encounter
        local unitNames = ctx.unitNames
        local durationSec = ctx.durationSec
        local arithmancer = ctx.arithmancer

        -------------------------
        -- Summary
        -------------------------
        utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_DURATION), utils.formatDuration(encounter.durationMs), StatIcons.DURATION, GetString(BATTLESCROLLS_STAT_SUMMARY))

        -------------------------
        -- Boss Damage Done
        -------------------------
        local bossPersonalTotalDamage = arithmancer:bossPersonalTotalDamage()
        local bossGroupTotalDamage = arithmancer:bossGroupTotalDamage()

        if bossPersonalTotalDamage > 0 then
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE), ZO_CommaDelimitNumber(bossPersonalTotalDamage), StatIcons.DAMAGE, GetString(BATTLESCROLLS_HEADER_BOSS_DAMAGE_DONE))
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_PERSONAL_BOSS_DPS), ZO_CommaDelimitNumber(math.floor(bossPersonalTotalDamage / durationSec)), StatIcons.DPS)

            -- Only show share if there's actual group data (group damage > personal damage)
            if bossGroupTotalDamage > bossPersonalTotalDamage then
                local groupPercent = (bossPersonalTotalDamage / bossGroupTotalDamage) * 100
                utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE_SHARE), string.format("%.1f%%", groupPercent), StatIcons.SHARE)
            end
        end
        LibEffect.Yield():Await()

        -------------------------
        -- Total Damage Done
        -------------------------
        local personalTotalDamage = arithmancer:personalTotalDamage()
        local groupTotalDamage = arithmancer:groupTotalDamage()

        if personalTotalDamage > 0 then
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_PERSONAL_DAMAGE), ZO_CommaDelimitNumber(personalTotalDamage), StatIcons.DAMAGE, GetString(BATTLESCROLLS_HEADER_TOTAL_DAMAGE_DONE))
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_PERSONAL_DPS), ZO_CommaDelimitNumber(math.floor(personalTotalDamage / durationSec)), StatIcons.DPS)

            -- Only show share if there's actual group data (group damage > personal damage)
            if groupTotalDamage > personalTotalDamage then
                local groupPercent = (personalTotalDamage / groupTotalDamage) * 100
                utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_PERSONAL_SHARE), string.format("%.1f%%", groupPercent), StatIcons.SHARE)
            end
        end
        LibEffect.Yield():Await()

        -------------------------
        -- Damage Taken
        -------------------------
        local damageTakenTotal = arithmancer:damageTakenTotal()
        if damageTakenTotal > 0 then
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN), ZO_CommaDelimitNumber(damageTakenTotal), StatIcons.DAMAGE_TAKEN, GetString(BATTLESCROLLS_HEADER_DAMAGE_TAKEN))
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_DTPS), ZO_CommaDelimitNumber(math.floor(damageTakenTotal / durationSec)), StatIcons.DPS)
        end
        LibEffect.Yield():Await()

        -------------------------
        -- Healing
        -------------------------
        local healingSectionStarted = false

        -- Self Healing
        local selfHealingRaw = encounter.healingStats.selfHealing.total.raw
        local selfHealingReal = encounter.healingStats.selfHealing.total.real
        if selfHealingRaw > 0 then
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_RAW_SELF_HEALING), ZO_CommaDelimitNumber(selfHealingRaw), StatIcons.HEALING, GetString(BATTLESCROLLS_HEADER_HEALING))
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_RAW_SELF_HPS), ZO_CommaDelimitNumber(math.floor(selfHealingRaw / durationSec)), StatIcons.HPS)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_EFFECTIVE_SELF_HEALING), ZO_CommaDelimitNumber(selfHealingReal), StatIcons.HEALING)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_EFFECTIVE_SELF_HPS), ZO_CommaDelimitNumber(math.floor(selfHealingReal / durationSec)), StatIcons.HPS)
            healingSectionStarted = true
        end

        -- Healing Out
        local healingOutRaw, healingOutReal = utils.calculateHealingTotals(encounter.healingStats.healingOutToGroup)
        if healingOutRaw > 0 then
            local header = healingSectionStarted and nil or GetString(BATTLESCROLLS_HEADER_HEALING)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_RAW_HEALING_OUT), ZO_CommaDelimitNumber(healingOutRaw), StatIcons.HEALING, header)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_RAW_HEALING_OUT_HPS), ZO_CommaDelimitNumber(math.floor(healingOutRaw / durationSec)), StatIcons.HPS)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT), ZO_CommaDelimitNumber(healingOutReal), StatIcons.HEALING)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT_HPS), ZO_CommaDelimitNumber(math.floor(healingOutReal / durationSec)), StatIcons.HPS)
            healingSectionStarted = true
        end

        -- Healing In
        local healingInRaw, healingInReal = utils.calculateHealingTotals(encounter.healingStats.healingInFromGroup)
        if healingInRaw > 0 then
            local header = healingSectionStarted and nil or GetString(BATTLESCROLLS_HEADER_HEALING)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_RAW_HEALING_IN), ZO_CommaDelimitNumber(healingInRaw), StatIcons.HEALING, header)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_RAW_HEALING_IN_HPS), ZO_CommaDelimitNumber(math.floor(healingInRaw / durationSec)), StatIcons.HPS)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN), ZO_CommaDelimitNumber(healingInReal), StatIcons.HEALING)
            utils.addStatEntry(list, GetString(BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN_HPS), ZO_CommaDelimitNumber(math.floor(healingInReal / durationSec)), StatIcons.HPS)
        end
        LibEffect.Yield():Await()

        -------------------------
        -- Proc Tracking
        -------------------------
        if encounter.procs and #encounter.procs > 0 then
            local isFirst = true
            for _, procData in ipairs(encounter.procs) do
                local abilityName = BattleScrolls.utils.GetScribeAwareAbilityDisplayName(procData.abilityId)
                if abilityName == "" then
                    abilityName = string.format("%s %d", GetString(BATTLESCROLLS_TOOLTIP_ABILITY), procData.abilityId)
                end

                local abilityIcon = GetAbilityIcon(procData.abilityId)
                local valueStr
                if procData.medianIntervalMs > 0 then
                    valueStr = string.format("%d %s (%s %.1fs)", procData.totalProcs, GetString(BATTLESCROLLS_STAT_TOTAL_PROCS), GetString(BATTLESCROLLS_STAT_MEDIAN_INTERVAL), procData.medianIntervalMs / 1000)
                else
                    valueStr = string.format("%d %s", procData.totalProcs, GetString(BATTLESCROLLS_STAT_TOTAL_PROCS))
                end

                local entryData = ZO_GamepadEntryData:New(abilityName, abilityIcon)
                entryData.iconFile = abilityIcon  -- Store for frame type detection
                entryData:SetIconTintOnSelection(true)
                entryData:AddSubLabel(valueStr)
                entryData.procData = procData
                entryData.unitNames = unitNames  -- Store for tooltip display

                if isFirst then
                    entryData:SetHeader(GetString(BATTLESCROLLS_HEADER_PROC_TRACKING))
                    list:AddEntryWithHeader("BattleScrolls_AbilityEntryTemplate", entryData)
                    isFirst = false
                else
                    list:AddEntry("BattleScrolls_AbilityEntryTemplate", entryData)
                end
            end
        end
    end)
end

-------------------------
-- Overview Panel Helpers
-------------------------

---Determines the player's primary role based on fight metrics
---Used for Q3/Q4 content selection (top abilities and targets)
---@param dps number Personal DPS
---@param hps number Personal effective HPS
---@param dtps number Damage taken per second
---@return string role "dps", "healer", or "tank"
local function DetectPlayerRole(dps, hps, dtps)
    local tankScore = dtps * 10
    local healingScore = hps
    local ddScore = dps

    if tankScore > healingScore and tankScore > ddScore then
        return "tank"
    end

    if healingScore > ddScore then
        return "healer"
    end

    return "dps"
end

-------------------------
-- Overview Panel Refresh Function
-------------------------

---Determines the most prevalent healing type based on raw HPS
---@param selfHealingData table|nil Self healing summary data
---@param healingOutData table|nil Healing out summary data
---@param healingInData table|nil Healing in summary data
---@return string|nil healingType "selfHealing", "healingOut", "healingIn", or nil if no healing
---@return table|nil healingData The data for the most prevalent type
---@return string|nil healingLabel The localized label for the section
local function GetMostPrevalentHealingType(selfHealingData, healingOutData, healingInData)
    local selfHPS = selfHealingData and selfHealingData.rawHps or 0
    local outHPS = healingOutData and healingOutData.rawHps or 0
    local inHPS = healingInData and healingInData.rawHps or 0

    -- For healing out, subtract self-healing to get "group healing out" contribution
    local groupOutHPS = math.max(0, outHPS - selfHPS)
    -- For healing in, subtract self-healing to get "group healing in" contribution
    local groupInHPS = math.max(0, inHPS - selfHPS)

    -- Find the most prevalent
    if groupOutHPS >= selfHPS and groupOutHPS >= groupInHPS and healingOutData then
        return "healingOut", healingOutData, GetString(BATTLESCROLLS_HEALING_OUT)
    elseif selfHPS >= groupInHPS and selfHealingData then
        return "selfHealing", selfHealingData, GetString(BATTLESCROLLS_SELF_HEALING)
    elseif healingInData then
        return "healingIn", healingInData, GetString(BATTLESCROLLS_HEALING_IN)
    end

    return nil, nil, nil
end

---Refreshes the overview panel for Overview tab
---Uses priority-based section selection: shows most important sections that fit within available height
---Sections: Encounter (always), Damage Output, Healing (most prevalent type), Damage Taken
---Priorities are calculated dynamically based on player DPS/HPS/DTPS relevance
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, abilityInfo: table }
---@return Effect<nil>
function OverviewRenderer.refreshPanelForOverview(panel, ctx)
    return LibEffect.Async(function()
        local arithmancer = ctx.arithmancer
        local encounter = ctx.encounter
        local durationS = ctx.durationS
        local unitNames = ctx.unitNames
        local DamageRenderer = journal.renderers.damage
        local HealingRenderer = journal.renderers.healing

        -- Pre-compute data using Arithmancer summary methods
        local isBossFight = arithmancer:isBossFight()

        -- Damage summaries: {dps, groupDps, share}
        local bossDamageSummary = isBossFight and arithmancer:getDamageSummary(nil, nil, true) or nil
        local totalDamageSummary = arithmancer:getDamageSummary()
        local hasDamage = totalDamageSummary.dps > 0
        local personalDPS = totalDamageSummary.dps
        local totalDamage = personalDPS * durationS  -- For Q3 ability share calculations

        -- Damage taken summary: {dtps, total}
        local damageTakenSummary = arithmancer:getDamageTakenSummary()
        local damageTaken = damageTakenSummary.total
        local hasDamageTaken = damageTaken > 0
        local personalDTPS = damageTakenSummary.dtps

        -- Healing summaries: {rawHps, effectiveHps, total, rawTotal, overhealPercent}
        local selfHealingData = arithmancer:getSelfHealingSummary()
        local healingOutData = arithmancer:getHealingOutSummary()
        local healingInData = arithmancer:getHealingInSummary()

        -- Normalize healing data (nil if no data)
        if selfHealingData.rawTotal == 0 then selfHealingData = nil end
        if healingOutData.rawTotal == 0 then healingOutData = nil end
        if healingInData.rawTotal == 0 then healingInData = nil end

        -- Determine most prevalent healing type FIRST (needed for HPS calculation)
        local prevalentHealingType, prevalentHealingData, prevalentHealingLabel =
            GetMostPrevalentHealingType(selfHealingData, healingOutData, healingInData)

        -- Use the prevalent healing type's HPS for role detection and priority calculation
        -- This ensures the healing section's priority matches what we're actually showing
        local prevalentHPS = prevalentHealingData and prevalentHealingData.rawHps or 0

        -- Detect the player's primary role based on fight metrics (for Q3/Q4 content)
        local playerRole = DetectPlayerRole(personalDPS, prevalentHPS, personalDTPS)

        -- Pre-compute composition data: {dotPercent, directPercent, aoePercent, stPercent}
        local compositionData = arithmancer:getDamageComposition(nil, nil, isBossFight)

        -- Pre-compute quality data: {critRate, maxHit}
        local qualityData = arithmancer:getDamageQuality(nil, nil, isBossFight)
        local critRate = qualityData.critRate
        local maxHit = qualityData.maxHit

        -- Compute HoT% for the prevalent healing type
        local prevalentHotPercent = nil
        if prevalentHealingType and encounter.healingStats then
            local Arithmancer = BattleScrolls.arithmancer
            local abilityInfo = encounter.abilityInfo or {}
            local healingRawData = nil

            if prevalentHealingType == "selfHealing" then
                healingRawData = encounter.healingStats.selfHealing
            elseif prevalentHealingType == "healingOut" then
                -- Aggregate across all targets for healing out
                local healingOutToGroup = encounter.healingStats.healingOutToGroup
                if healingOutToGroup then
                    local totalHot, totalDirect = 0, 0
                    for _, targetData in pairs(healingOutToGroup) do
                        local hotVsDirect = Arithmancer.ComputeByHotVsDirect(targetData, abilityInfo)
                        totalHot = totalHot + (hotVsDirect.hot and hotVsDirect.hot.raw or 0)
                        totalDirect = totalDirect + (hotVsDirect.direct and hotVsDirect.direct.raw or 0)
                    end
                    local totalRaw = totalHot + totalDirect
                    if totalRaw > 0 then
                        prevalentHotPercent = totalHot / totalRaw * 100
                    end
                end
            elseif prevalentHealingType == "healingIn" then
                -- Aggregate across all sources for healing in
                local healingInFromGroup = encounter.healingStats.healingInFromGroup
                if healingInFromGroup then
                    local totalHot, totalDirect = 0, 0
                    for _, sourceData in pairs(healingInFromGroup) do
                        local hotVsDirect = Arithmancer.ComputeByHotVsDirect(sourceData, abilityInfo)
                        totalHot = totalHot + (hotVsDirect.hot and hotVsDirect.hot.raw or 0)
                        totalDirect = totalDirect + (hotVsDirect.direct and hotVsDirect.direct.raw or 0)
                    end
                    local totalRaw = totalHot + totalDirect
                    if totalRaw > 0 then
                        prevalentHotPercent = totalHot / totalRaw * 100
                    end
                end
            end

            -- For selfHealing, compute directly
            if healingRawData and not prevalentHotPercent then
                local hotVsDirect = Arithmancer.ComputeByHotVsDirect(healingRawData, abilityInfo)
                local totalHot = hotVsDirect.hot and hotVsDirect.hot.raw or 0
                local totalDirect = hotVsDirect.direct and hotVsDirect.direct.raw or 0
                local totalRaw = totalHot + totalDirect
                if totalRaw > 0 then
                    prevalentHotPercent = totalHot / totalRaw * 100
                end
            end
        end

        LibEffect.Yield():Await()

        -------------------------
        -- Q2: Priority-Based Section Selection
        -------------------------

        -- Calculate dynamic priorities based on player metrics
        local encounterPriority, damagePriority, healingPriority, damageTakenPriority =
            CalculateDynamicPriorities(personalDPS, prevalentHPS, personalDTPS)

        -- Pre-calculate row counts for each section
        -- Damage Output: Total DPS (1) + optional Boss DPS, Share, Crit, MaxHit, DoT%, AoE%
        local damageRowCount = 1  -- Always Total DPS
        local bossDps = bossDamageSummary and bossDamageSummary.dps or nil
        if bossDps and bossDps > 0 then damageRowCount = damageRowCount + 1 end
        if totalDamageSummary.groupDps and totalDamageSummary.groupDps > personalDPS then damageRowCount = damageRowCount + 1 end
        if critRate > 0 then damageRowCount = damageRowCount + 1 end
        if maxHit > 0 then damageRowCount = damageRowCount + 1 end
        if compositionData.dotPercent and compositionData.dotPercent > 5 and compositionData.dotPercent < 95 then damageRowCount = damageRowCount + 1 end
        if compositionData.aoePercent and compositionData.aoePercent > 5 and compositionData.aoePercent < 95 then damageRowCount = damageRowCount + 1 end

        -- Healing: Raw HPS, Effective HPS, Overheal% (3) + optional HoT%
        local healingRowCount = 3
        if prevalentHotPercent and prevalentHotPercent > 5 and prevalentHotPercent < 95 then healingRowCount = healingRowCount + 1 end

        -- Damage Taken: DTPS, Total (2)
        local damageTakenRowCount = 2

        -- Define all Q2 sections with priority, displayOrder, condition, height, and render function
        ---@type { id: string, priority: number, displayOrder: number, condition: boolean, height: number, render: fun(lastControl: Control|nil): Control }[]
        local sections = {
            {
                id = "encounter",
                priority = encounterPriority,
                displayOrder = 1,
                condition = true,  -- Always show encounter section
                height = CalculateSectionHeight(1),  -- Duration row only
                render = function(lastControl)
                    lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_ENCOUNTER), lastControl)
                    local minutes = math.floor(durationS / 60)
                    local seconds = durationS % 60
                    local durationStr = minutes > 0
                        and string.format("%d:%04.1f", minutes, seconds)
                        or string.format("%.1fs", seconds)
                    return panel:AddStatRow(GetString(BATTLESCROLLS_TOOLTIP_DURATION), durationStr, lastControl)
                end,
            },
            {
                id = "damage",
                priority = damagePriority,
                displayOrder = 2,
                condition = hasDamage,
                height = CalculateSectionHeight(damageRowCount),
                render = function(lastControl)
                    return utils.renderDamageOutputSection(
                        panel, lastControl,
                        bossDps,
                        totalDamageSummary.dps,
                        totalDamageSummary.groupDps,
                        totalDamageSummary.share,
                        critRate,
                        maxHit,
                        compositionData.dotPercent,
                        compositionData.aoePercent
                    )
                end,
            },
            {
                id = "healing",
                priority = healingPriority,
                displayOrder = 3,
                condition = prevalentHealingData ~= nil,
                height = CalculateSectionHeight(healingRowCount),
                render = function(lastControl)
                    return utils.renderHealingSectionCompact(
                        panel, prevalentHealingLabel, lastControl,
                        prevalentHealingData.rawHps,
                        prevalentHealingData.effectiveHps,
                        prevalentHealingData.overhealPercent,
                        prevalentHotPercent
                    )
                end,
            },
            {
                id = "damageTaken",
                priority = damageTakenPriority,
                displayOrder = 4,
                condition = hasDamageTaken,
                height = CalculateSectionHeight(damageTakenRowCount),
                render = function(lastControl)
                    return utils.renderDamageTakenSection(panel, lastControl,
                        damageTakenSummary.dtps, damageTakenSummary.total)
                end,
            },
        }

        -- Filter to only sections that should be shown (condition is true)
        local eligibleSections = {}
        for _, section in ipairs(sections) do
            if section.condition then
                table.insert(eligibleSections, section)
            end
        end

        -- Get available height for Q2 container
        local container = panel.q2Container or panel.container
        local availableHeight = container and container:GetHeight() or 0

        -- Select sections by priority order while they fit
        table.sort(eligibleSections, function(a, b) return a.priority < b.priority end)

        local selectedIds = {}
        local usedHeight = 0
        local gapBetweenSections = ROW_GAPS.SECTION_HEADER

        for _, section in ipairs(eligibleSections) do
            local heightNeeded = section.height
            if usedHeight > 0 then
                heightNeeded = heightNeeded + gapBetweenSections
            end
            if usedHeight + heightNeeded <= availableHeight or availableHeight == 0 then
                selectedIds[section.id] = true
                usedHeight = usedHeight + heightNeeded
            end
        end

        -- Render selected sections in display order (each section adds only 3-5 entries, no per-section yield needed)
        table.sort(eligibleSections, function(a, b) return a.displayOrder < b.displayOrder end)

        local lastControl = nil
        for _, section in ipairs(eligibleSections) do
            if selectedIds[section.id] then
                lastControl = section.render(lastControl)
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Q3: Top abilities - role-dependent content
        local q3Control = nil
        local maxAbilities = panel:GetMaxAbilities()
        local healingStats = encounter and encounter.healingStats

        if playerRole == "healer" and healingStats then
            -- For healers: show top healing abilities
            local topHealingAbilities = HealingRenderer.extractHealingOutAbilitiesAsync(healingStats.healingOutToGroup, maxAbilities):Await()
            local selfHealingAbilities = HealingRenderer.extractSelfHealingAbilitiesAsync(healingStats.selfHealing, maxAbilities):Await()
            -- Merge and sort
            local allHealingAbilities = {}
            for _, ability in ipairs(topHealingAbilities) do
                table.insert(allHealingAbilities, ability)
            end
            for _, ability in ipairs(selfHealingAbilities) do
                local found = false
                for _, existing in ipairs(allHealingAbilities) do
                    if existing.name == ability.name then
                        existing.total = existing.total + ability.total
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(allHealingAbilities, ability)
                end
            end
            table.sort(allHealingAbilities, function(a, b) return a.total > b.total end)
            -- Limit to maxAbilities
            local topAbilities = {}
            for i = 1, math.min(maxAbilities, #allHealingAbilities) do
                table.insert(topAbilities, allHealingAbilities[i])
            end

            if #topAbilities > 0 then
                q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_HEALING), q3Control)
                LibEffect.Yield():Await()
                local topValue = topAbilities[1].total
                local totalHealing = (healingOutData and healingOutData.effectiveTotal or 0)
                    + (selfHealingData and selfHealingData.effectiveTotal or 0)
                for _, ability in ipairs(topAbilities) do
                    local abilityData = {
                        abilityId = ability.abilityId,
                        name = ability.name,
                        total = ability.total,
                        ticks = 0,
                        critTicks = 0,
                        maxHit = 0,
                    }
                    q3Control = panel:AddAbilityBar(abilityData, topValue, totalHealing, durationS, q3Control)
                end
            end
        elseif playerRole == "tank" and hasDamageTaken then
            -- For tanks: show top damage taken abilities (what's hurting them most)
            local topAbilities = DamageRenderer.extractDamageTakenAbilitiesAsync(encounter.damageTakenByUnitId, maxAbilities):Await()
            if #topAbilities > 0 then
                q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_INCOMING), q3Control)
                LibEffect.Yield():Await()
                local topValue = topAbilities[1].total
                for _, ability in ipairs(topAbilities) do
                    q3Control = panel:AddAbilityBar(ability, topValue, damageTaken, durationS, q3Control)
                end
            end
        else
            -- For DPS: show top damage abilities
            local topAbilities = DamageRenderer.extractTopAbilitiesAsync(encounter.damageByUnitId, nil, nil, maxAbilities):Await()
            if #topAbilities > 0 then
                q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_TOP_ABILITIES), q3Control)
                LibEffect.Yield():Await()
                local topValue = topAbilities[1].total
                for _, ability in ipairs(topAbilities) do
                    q3Control = panel:AddAbilityBar(ability, topValue, totalDamage, durationS, q3Control)
                end
            end
        end

        LibEffect.YieldWithGC():Await()

        -- Q4: Role-dependent target/source display
        local q4Control = nil
        local maxTargets = panel:GetMaxTargets()

        if playerRole == "healer" and healingStats and healingStats.healingOutToGroup then
            -- For healers: show healing targets
            local targets = HealingRenderer.extractHealingTargetBreakdownAsync(healingStats.healingOutToGroup, unitNames, maxTargets):Await()
            if #targets > 0 then
                q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_OVERVIEW_HEALING_TARGETS), q4Control)
                for _, target in ipairs(targets) do
                    q4Control = panel:AddTargetRow(target.name, utils.formatTargetHPS(target.total, durationS), q4Control)
                end
            end
        elseif playerRole == "tank" and hasDamageTaken then
            -- For tanks: show damage sources
            local sources = DamageRenderer.extractDamageTakenSourcesAsync(encounter.damageTakenByUnitId, unitNames, maxTargets):Await()
            if #sources > 0 then
                q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES), q4Control)
                for _, source in ipairs(sources) do
                    local dtps = durationS > 0 and (source.total / durationS) or 0
                    q4Control = panel:AddTargetRow(source.name, string.format("%s DTPS", utils.formatDPS(dtps)), q4Control)
                end
            end
        elseif isBossFight then
            -- For DPS in boss fights: show bosses
            local bossUnitIds = encounter.bossesUnits or {}
            local bossFilter = {}
            for _, bossId in ipairs(bossUnitIds) do
                bossFilter[bossId] = true
            end
            local bosses = DamageRenderer.extractTargetBreakdownAsync(encounter.damageByUnitId, unitNames, bossFilter, nil, maxTargets):Await()
            if #bosses > 0 then
                q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_OVERVIEW_BOSSES), q4Control)
                for _, boss in ipairs(bosses) do
                    q4Control = panel:AddTargetRow(boss.name, utils.formatTargetDPS(boss.total, durationS), q4Control)
                end
            end
        else
            -- For DPS in non-boss fights: show targets
            local targets = DamageRenderer.extractTargetBreakdownAsync(encounter.damageByUnitId, unitNames, nil, nil, maxTargets):Await()
            if #targets > 0 then
                q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_OVERVIEW_TARGETS), q4Control)
                for _, target in ipairs(targets) do
                    q4Control = panel:AddTargetRow(target.name, utils.formatTargetDPS(target.total, durationS), q4Control)
                end
            end
        end
    end)
end

-- Export to namespace
journal.renderers.overview = OverviewRenderer

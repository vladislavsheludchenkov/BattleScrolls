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
local EntryBuilder = journal.EntryBuilder

local OverviewRenderer = {}

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
    -- Higher relevance -> lower priority number (higher priority)
    -- Priority range: 2 (highest for role-specific) to 5 (lowest)
    local priorityRange = 3  -- 5 - 2 = 3
    local basePriority = 2

    -- Encounter gets lowest priority (shown only if space remains)
    local encounterPriority = 100

    -- Damage priority: high DPS relevance -> low priority number
    local damagePriority = basePriority + priorityRange * (1 - dpsRelevance)

    -- Healing priority: high HPS relevance -> low priority number
    local healingPriority = basePriority + priorityRange * (1 - hpsRelevance)

    -- Damage taken priority: high DTPS relevance -> low priority number
    local damageTakenPriority = basePriority + priorityRange * (1 - dtpsRelevance)

    return encounterPriority, damagePriority, healingPriority, damageTakenPriority
end

---@class OverviewHealingDeliveryPercents
---@field hot number|nil
---@field shield number|nil
---@field regen number|nil

---@param hotRaw number
---@param directRaw number
---@param shieldRaw number
---@param regenRaw number
---@return OverviewHealingDeliveryPercents
local function computeOverviewHealingDeliveryPercents(hotRaw, directRaw, shieldRaw, regenRaw)
    regenRaw = regenRaw or 0
    local totalRaw = hotRaw + directRaw + shieldRaw + regenRaw
    if totalRaw <= 0 then return { hot = nil, shield = nil, regen = nil } end

    local hotPercent = hotRaw / totalRaw * 100
    local directPercent = directRaw / totalRaw * 100
    local shieldPercent = shieldRaw / totalRaw * 100
    local regenPercent = regenRaw / totalRaw * 100
    local visibleCount = (hotPercent > 5 and 1 or 0)
        + (directPercent > 5 and 1 or 0)
        + (shieldPercent > 5 and 1 or 0)
        + (regenPercent > 5 and 1 or 0)
    if visibleCount <= 1 then return { hot = nil, shield = nil, regen = nil } end

    return {
        hot = hotPercent > 5 and hotPercent or nil,
        shield = shieldPercent > 5 and shieldPercent or nil,
        regen = regenPercent > 5 and regenPercent or nil,
    }
end

---@param totals { hot: number, direct: number, shield: number, regen: number }
---@param healingData HealingDone|HealingDoneDiffSource
---@param abilityInfo table<number, AbilityInfo>
local function addHealingDeliveryTotals(totals, healingData, abilityInfo)
    local hotVsDirect = BattleScrolls.arithmancer.ComputeByHotVsDirect(healingData, abilityInfo)
    totals.hot = totals.hot + (hotVsDirect.hot and hotVsDirect.hot.raw or 0)
    totals.direct = totals.direct + (hotVsDirect.direct and hotVsDirect.direct.raw or 0)
    totals.shield = totals.shield + (hotVsDirect.shield and hotVsDirect.shield.raw or 0)
    totals.regen = totals.regen + (hotVsDirect.regen and hotVsDirect.regen.raw or 0)
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
        local durationSec = ctx.durationSec

        -------------------------
        -- Summary
        -------------------------
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_DURATION),
            sublabel = utils.formatDuration(encounter.durationMs),
            icon = StatIcons.DURATION,
            header = GetString(BATTLESCROLLS_STAT_SUMMARY),
        })

        -------------------------
        -- Boss Damage Done
        -------------------------
        local Arithmancer = BattleScrolls.arithmancer
        local bossCalc = Arithmancer:ForBosses(encounter, ctx.abilityInfo)
        local bossPersonalTotalDamage = bossCalc and bossCalc:personalTotalDamage() or 0
        local bossGroupTotalDamage = bossCalc and bossCalc:groupTotalDamage() or 0

        if bossPersonalTotalDamage > 0 then
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE),
                sublabel = ZO_CommaDelimitNumber(bossPersonalTotalDamage),
                icon = StatIcons.DAMAGE,
                header = GetString(BATTLESCROLLS_HEADER_BOSS_DAMAGE_DONE),
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_PERSONAL_BOSS_DPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(bossPersonalTotalDamage / durationSec)),
                icon = StatIcons.DPS,
            })

            -- Only show share if there's actual group data (group damage > personal damage)
            if bossGroupTotalDamage > bossPersonalTotalDamage then
                local groupPercent = (bossPersonalTotalDamage / bossGroupTotalDamage) * 100
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE_SHARE),
                    sublabel = string.format("%.1f%%", groupPercent),
                    icon = StatIcons.SHARE,
                })
            end
        end
        LibEffect.Yield():Await()

        -------------------------
        -- Total Damage Done
        -------------------------
        local arithmancer = ctx.arithmancer
        local personalTotalDamage = arithmancer:personalTotalDamage()
        local groupTotalDamage = arithmancer:groupTotalDamage()

        if personalTotalDamage > 0 then
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_PERSONAL_DAMAGE),
                sublabel = ZO_CommaDelimitNumber(personalTotalDamage),
                icon = StatIcons.DAMAGE,
                header = GetString(BATTLESCROLLS_HEADER_TOTAL_DAMAGE_DONE),
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_PERSONAL_DPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(personalTotalDamage / durationSec)),
                icon = StatIcons.DPS,
            })

            -- Only show share if there's actual group data (group damage > personal damage)
            if groupTotalDamage > personalTotalDamage then
                local groupPercent = (personalTotalDamage / groupTotalDamage) * 100
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_PERSONAL_SHARE),
                    sublabel = string.format("%.1f%%", groupPercent),
                    icon = StatIcons.SHARE,
                })
            end
        end
        LibEffect.Yield():Await()

        -------------------------
        -- Damage Taken
        -------------------------
        local damageTakenTotal = arithmancer:damageTakenTotal()
        if damageTakenTotal > 0 then
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN),
                sublabel = ZO_CommaDelimitNumber(damageTakenTotal),
                icon = StatIcons.DAMAGE_TAKEN,
                header = GetString(BATTLESCROLLS_HEADER_DAMAGE_TAKEN),
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_DTPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(damageTakenTotal / durationSec)),
                icon = StatIcons.DPS,
            })
            if encounter.deaths then
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_DEATH_COUNT),
                    sublabel = tostring(encounter.deaths.deathCount),
                    icon = StatIcons.DEATH,
                })
            end
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
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_RAW_SELF_HEALING),
                sublabel = ZO_CommaDelimitNumber(selfHealingRaw),
                icon = StatIcons.HEALING,
                header = GetString(BATTLESCROLLS_HEADER_HEALING),
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_RAW_SELF_HPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(selfHealingRaw / durationSec)),
                icon = StatIcons.HPS,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_EFFECTIVE_SELF_HEALING),
                sublabel = ZO_CommaDelimitNumber(selfHealingReal),
                icon = StatIcons.HEALING,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_EFFECTIVE_SELF_HPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(selfHealingReal / durationSec)),
                icon = StatIcons.HPS,
            })
            healingSectionStarted = true
        end

        -- Healing Out
        local healingOutRaw, healingOutReal = utils.calculateHealingTotals(encounter.healingStats.healingOutToGroup)
        if healingOutRaw > 0 then
            local header = nil
            if not healingSectionStarted then
                header = GetString(BATTLESCROLLS_HEADER_HEALING)
            end
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_RAW_HEALING_OUT),
                sublabel = ZO_CommaDelimitNumber(healingOutRaw),
                icon = StatIcons.HEALING,
                header = header,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_RAW_HEALING_OUT_HPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(healingOutRaw / durationSec)),
                icon = StatIcons.HPS,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT),
                sublabel = ZO_CommaDelimitNumber(healingOutReal),
                icon = StatIcons.HEALING,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT_HPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(healingOutReal / durationSec)),
                icon = StatIcons.HPS,
            })
            healingSectionStarted = true
        end

        -- Healing In
        local healingInRaw, healingInReal = utils.calculateHealingTotals(encounter.healingStats.healingInFromGroup)
        if healingInRaw > 0 then
            local header = nil
            if not healingSectionStarted then
                header = GetString(BATTLESCROLLS_HEADER_HEALING)
            end
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_RAW_HEALING_IN),
                sublabel = ZO_CommaDelimitNumber(healingInRaw),
                icon = StatIcons.HEALING,
                header = header,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_RAW_HEALING_IN_HPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(healingInRaw / durationSec)),
                icon = StatIcons.HPS,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN),
                sublabel = ZO_CommaDelimitNumber(healingInReal),
                icon = StatIcons.HEALING,
            })
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN_HPS),
                sublabel = ZO_CommaDelimitNumber(math.floor(healingInReal / durationSec)),
                icon = StatIcons.HPS,
            })
        end
    end)
end

-------------------------
-- Overview Panel Helpers
-------------------------

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

---Builds a PanelSpec for the Overview tab overview panel
---Uses priority-based section selection: shows most important sections that fit within available height
---Sections: Encounter (always), Damage Output, Healing (most prevalent type), Damage Taken
---Priorities are calculated dynamically based on player DPS/HPS/DTPS relevance
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, abilityInfo: table }
---@return PanelSpec
function OverviewRenderer.buildOverviewPanelSpec(ctx)
    return {
        layout = "wide-right",
        ---@diagnostic disable-next-line: unused-local -- wide-right layout doesn't use Q4
        build = function(q2, q3, q4)
            local arithmancer = ctx.arithmancer
            local encounter = ctx.encounter
            local durationS = ctx.durationS
            local abilityInfo = ctx.abilityInfo
            -- Damage summaries: {dps, groupDps, share}
            local Arithmancer = BattleScrolls.arithmancer
            local bossCalc = Arithmancer:ForBosses(encounter, abilityInfo)
            local bossDamageSummary = bossCalc and bossCalc:getDamageSummary() or nil
            local totalDamageSummary = arithmancer:getDamageSummary()
            local hasDamage = totalDamageSummary.dps > 0
            local personalDPS = totalDamageSummary.dps

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

            -- Pre-compute composition data: {dotPercent, directPercent, aoePercent, stPercent}
            local compositionCalc = bossCalc or arithmancer
            local compositionData = compositionCalc:getDamageComposition()

            -- Pre-compute quality data: {critRate, maxHit}
            local qualityData = compositionCalc:getDamageQuality()
            local critRate = qualityData.critRate
            local maxHit = qualityData.maxHit

            -- Compute delivery percentages for the prevalent healing type
            local prevalentDelivery = { hot = nil, shield = nil, regen = nil }
            if prevalentHealingType and encounter.healingStats then
                local healingRawData = nil

                if prevalentHealingType == "selfHealing" then
                    healingRawData = encounter.healingStats.selfHealing
                elseif prevalentHealingType == "healingOut" then
                    -- Aggregate across all targets for healing out
                    local healingOutToGroup = encounter.healingStats.healingOutToGroup
                    if healingOutToGroup then
                        local totals = { hot = 0, direct = 0, shield = 0, regen = 0 }
                        for _, targetData in pairs(healingOutToGroup) do
                            addHealingDeliveryTotals(totals, targetData, abilityInfo)
                        end
                        prevalentDelivery = computeOverviewHealingDeliveryPercents(totals.hot, totals.direct, totals.shield, totals.regen)
                    end
                elseif prevalentHealingType == "healingIn" then
                    -- Aggregate across all sources for healing in
                    local healingInFromGroup = encounter.healingStats.healingInFromGroup
                    if healingInFromGroup then
                        local totals = { hot = 0, direct = 0, shield = 0, regen = 0 }
                        for _, sourceData in pairs(healingInFromGroup) do
                            addHealingDeliveryTotals(totals, sourceData, abilityInfo)
                        end
                        prevalentDelivery = computeOverviewHealingDeliveryPercents(totals.hot, totals.direct, totals.shield, totals.regen)
                    end
                end

                -- For selfHealing, compute directly
                if healingRawData and not prevalentDelivery.hot and not prevalentDelivery.shield and not prevalentDelivery.regen then
                    local totals = { hot = 0, direct = 0, shield = 0, regen = 0 }
                    addHealingDeliveryTotals(totals, healingRawData, abilityInfo)
                    prevalentDelivery = computeOverviewHealingDeliveryPercents(totals.hot, totals.direct, totals.shield, totals.regen)
                end
            end

            LibEffect.Yield():Await()

            -------------------------
            -- Q2: Priority-Based Section Selection
            -------------------------

            -- Calculate dynamic priorities based on player metrics
            local encounterPriority, damagePriority, healingPriority, damageTakenPriority =
                CalculateDynamicPriorities(personalDPS, prevalentHPS, personalDTPS)

            local bossDps = bossDamageSummary and bossDamageSummary.dps or nil
            local deathCount = encounter.deaths and encounter.deaths.deathCount or 0

            -- Build sections using ColumnBuilder
            local encounterSection = q2:Section(GetString(BATTLESCROLLS_OVERVIEW_ENCOUNTER),
                q2:StatRow(GetString(BATTLESCROLLS_TOOLTIP_DURATION), utils.formatPreciseDuration(encounter.durationMs))
            )

            local dmgSection = hasDamage
                and q2:Section(GetString(BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT),
                    (bossDps and bossDps > 0) and q2:StatRow(GetString(BATTLESCROLLS_BOSS_DAMAGE), utils.formatNumber(bossDps) .. " DPS"),
                    q2:StatRow(GetString(BATTLESCROLLS_DAMAGE_DONE), utils.formatNumber(totalDamageSummary.dps) .. " DPS"),
                    (totalDamageSummary.groupDps and totalDamageSummary.groupDps > totalDamageSummary.dps) and q2:StatRow(GetString(BATTLESCROLLS_OVERVIEW_SHARE), utils.formatPercent(totalDamageSummary.share)),
                    critRate > 0 and q2:StatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE), utils.formatPercent(critRate)),
                    maxHit > 0 and q2:StatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HIT), utils.formatNumber(maxHit)),
                    compositionData.directPercent and q2:StatRow(GetString(BATTLESCROLLS_DELIVERY_DIRECT), utils.formatPercent(compositionData.directPercent)),
                    compositionData.aoePercent and q2:StatRow(GetString(BATTLESCROLLS_AOE), utils.formatPercent(compositionData.aoePercent)))
                or nil

            local healSection = prevalentHealingData
                and q2:Section(prevalentHealingLabel,
                    q2:StatRow(GetString(BATTLESCROLLS_HEALING_RAW_HPS), utils.formatNumber(prevalentHealingData.rawHps)),
                    q2:StatRow(GetString(BATTLESCROLLS_HEALING_EFFECTIVE_HPS), utils.formatNumber(prevalentHealingData.effectiveHps)),
                    q2:StatRow(GetString(BATTLESCROLLS_HEALING_OVERHEAL), utils.formatPercent(prevalentHealingData.overhealPercent)),
                    prevalentDelivery.hot and q2:StatRow(GetString(BATTLESCROLLS_DELIVERY_HOT), utils.formatPercent(prevalentDelivery.hot)),
                    prevalentDelivery.shield and q2:StatRow(GetString(BATTLESCROLLS_DELIVERY_SHIELD), utils.formatPercent(prevalentDelivery.shield)),
                    prevalentDelivery.regen and q2:StatRow(GetString(BATTLESCROLLS_DELIVERY_REGEN), utils.formatPercent(prevalentDelivery.regen)))
                or nil

            local dtSection = hasDamageTaken
                and q2:Section(GetString(BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN),
                    q2:StatRow(GetString(BATTLESCROLLS_STAT_DTPS), utils.formatNumber(damageTakenSummary.dtps)),
                    q2:StatRow(GetString(BATTLESCROLLS_OVERVIEW_TOTAL), utils.formatNumber(damageTakenSummary.total)),
                    (deathCount and deathCount > 0) and q2:StatRow(GetString(BATTLESCROLLS_STAT_DEATH_COUNT), tostring(deathCount)))
                or nil

            q2:mountFitted(journal.SECTION_GAP, 0, {
                { priority = encounterPriority, order = 1, component = encounterSection },
                { priority = damagePriority, order = 2, component = dmgSection },
                { priority = healingPriority, order = 3, component = healSection },
                { priority = damageTakenPriority, order = 4, component = dtSection },
            })

            LibEffect.YieldWithGC():Await()

            -- Q3: Setup data
            local durationMs = encounter.durationMs or (durationS * 1000)
            local playerAliveTimeMs = encounter.playerAliveTimeMs or durationMs
            journal.renderers.setup.renderSetupToQ3(q3, encounter.setup, playerAliveTimeMs)
        end,
    }
end

-- Export to namespace
journal.renderers.overview = OverviewRenderer

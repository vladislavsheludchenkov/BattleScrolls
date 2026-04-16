-----------------------------------------------------------
-- Activity Renderer
-- Renders the Activity tab: proc tracking and weaving stats
--
-- Receives a JournalRenderContext and populates the list.
-- All functions are stateless - filters come from context.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local utils = journal.utils
local StatIcons = journal.StatIcons
local EntryBuilder = journal.EntryBuilder
local ROW_CONTENT = journal.ROW_CONTENT

local SECTION_GAP = journal.SECTION_GAP
local Q3_INSET = journal.Q3_INSET

local ActivityRenderer = {}

-------------------------
-- Weaving Helpers
-------------------------

---Formats weaving time in ms for display
---@param ms number Weaving time in milliseconds
---@return string
local function formatWeaveTime(ms)
    return zo_strformat(GetString(BATTLESCROLLS_FORMAT_MILLISECONDS), ms)
end

---Formats a duration in seconds with localized unit suffix
---@param sec number
---@return string
local function formatSeconds(sec)
    return zo_strformat(GetString(BATTLESCROLLS_FORMAT_SECONDS), string.format("%.1f", sec))
end

---Formats a rate value with localized "/s" suffix
---@param rate number
---@return string
local function formatRate(rate)
    return zo_strformat(GetString(BATTLESCROLLS_STAT_PER_SECOND), string.format("%.2f", rate))
end

---Computes encounter-level weaving totals from per-ability "after" data
---@param weaving WeavingData
---@return number totalAfterSum
---@return number totalAfterCount
local function computeWeavingTotals(weaving)
    local totalSum, totalCount = 0, 0
    for _, entry in ipairs(weaving.byAbility) do
        totalSum = totalSum + entry.afterSum
        totalCount = totalCount + entry.afterCount
    end
    return totalSum, totalCount
end

-------------------------
-- Summary Tooltip Builders
-------------------------

---Builds tooltip for the Avg Cast Delay summary stat
---@param avgMs number Average inter-cast delay
---@param totalSum number Total inter-cast time (ms)
---@param totalCount number Number of measurements
---@return string
local function buildCastDelayTooltip(avgMs, totalSum, totalCount)
    local lines = {}
    lines[#lines + 1] = GetString(BATTLESCROLLS_TOOLTIP_INTER_CAST_DESC)
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("%s (%d×)", formatWeaveTime(avgMs), totalCount)
    lines[#lines + 1] = string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TOTAL), formatSeconds(totalSum / 1000))
    return table.concat(lines, "\n")
end

---Builds tooltip for the Time Lost summary stat
---@param totalSum number Total inter-cast time (ms)
---@param durationSec number Fight duration in seconds
---@return string
local function buildTimeLostTooltip(totalSum, durationSec)
    local lines = {}
    lines[#lines + 1] = GetString(BATTLESCROLLS_TOOLTIP_TIME_LOST_DESC)
    lines[#lines + 1] = ""
    local timeLostSec = totalSum / 1000
    local pctOfFight = durationSec > 0 and (timeLostSec / durationSec * 100) or 0
    lines[#lines + 1] = string.format("%s / %s (%.1f%%)", formatSeconds(timeLostSec), formatSeconds(durationSec), pctOfFight)
    return table.concat(lines, "\n")
end

---Builds tooltip for the Missed LAs summary stat
---@param errors number Total missed LA count
---@param skillActivations number Total skill activations
---@return string
local function buildMissedLaTooltip(errors, skillActivations)
    local lines = {}
    lines[#lines + 1] = GetString(BATTLESCROLLS_TOOLTIP_MISSED_LA_DESC)
    if skillActivations > 0 then
        lines[#lines + 1] = ""
        local pct = errors / skillActivations * 100
        lines[#lines + 1] = string.format("%d / %d (%.1f%%)", errors, skillActivations, pct)
    end
    return table.concat(lines, "\n")
end

---Builds tooltip for the Double LAs summary stat
---@param errors number Double LA count
---@param lightAttacks number Total LA count
---@return string
local function buildDoubleLaTooltip(errors, lightAttacks)
    local lines = {}
    lines[#lines + 1] = GetString(BATTLESCROLLS_TOOLTIP_DOUBLE_LA_DESC)
    lines[#lines + 1] = ""
    local pct = errors / lightAttacks * 100
    lines[#lines + 1] = string.format("%d / %d (%.1f%%)", errors, lightAttacks, pct)
    return table.concat(lines, "\n")
end

-------------------------
-- Per-Ability Tooltip Builder
-------------------------

---Builds tooltip text for a weaving ability entry
---@param entry WeavingAbilityData
---@param totalActivations number Total skill activations in the encounter
---@return string
local function buildWeavingAbilityTooltipText(entry, totalActivations)
    local lines = {}

    -- Casts with share
    local castShare = totalActivations > 0 and (entry.activations / totalActivations * 100) or 0
    lines[#lines + 1] = string.format("%s: %d (%.1f%%)", GetString(BATTLESCROLLS_STAT_CASTS), entry.activations, castShare)

    -- Delay after cast
    if entry.afterCount > 0 then
        local afterAvg = entry.afterSum / entry.afterCount
        lines[#lines + 1] = string.format("%s: %s (%d×)",
            GetString(BATTLESCROLLS_TOOLTIP_DELAY_AFTER), formatWeaveTime(afterAvg), entry.afterCount)
    end

    -- Delay before cast
    if entry.beforeCount > 0 then
        local beforeAvg = entry.beforeSum / entry.beforeCount
        lines[#lines + 1] = string.format("%s: %s (%d×)",
            GetString(BATTLESCROLLS_TOOLTIP_DELAY_BEFORE), formatWeaveTime(beforeAvg), entry.beforeCount)
    end

    -- Missed LAs (skill→skill after this ability)
    if entry.weavingErrors > 0 then
        lines[#lines + 1] = string.format("%s: %d", GetString(BATTLESCROLLS_STAT_MISSED_LA), entry.weavingErrors)
    end

    return table.concat(lines, "\n")
end

-------------------------
-- Proc Tooltip Builder
-------------------------

---Builds tooltip text for a proc entry, showing per-enemy breakdown
---@param procData ProcData
---@param unitNames table<number, string>
---@return string text Formatted tooltip text with per-enemy breakdown
local function buildProcTooltipText(procData, unitNames)
    local lines = {}

    lines[#lines + 1] = string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TOTAL),
        zo_strformat(GetString(BATTLESCROLLS_STAT_TOTAL_PROCS), procData.totalProcs))

    if procData.meanIntervalMs > 0 then
        lines[#lines + 1] = string.format("%s: %s",
            GetString(BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL), formatSeconds(procData.meanIntervalMs / 1000))
    end
    if procData.medianIntervalMs > 0 then
        lines[#lines + 1] = string.format("%s: %s",
            GetString(BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL), formatSeconds(procData.medianIntervalMs / 1000))
    end

    if procData.procsByEnemy and #procData.procsByEnemy > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = GetString(BATTLESCROLLS_TOOLTIP_BY_TARGET) .. ":"

        local sortedByEnemy = {}
        for _, enemyData in ipairs(procData.procsByEnemy) do
            sortedByEnemy[#sortedByEnemy + 1] = enemyData
        end
        table.sort(sortedByEnemy, function(a, b)
            return a.procCount > b.procCount
        end)

        for _, enemyData in ipairs(sortedByEnemy) do
            local rawName = unitNames[enemyData.unitId] or GetString(BATTLESCROLLS_UNKNOWN)
            local enemyName = zo_strformat(SI_UNIT_NAME, rawName)
            local percent = procData.totalProcs > 0 and (enemyData.procCount / procData.totalProcs * 100) or 0
            lines[#lines + 1] = string.format("  %s: %d (%.1f%%)", enemyName, enemyData.procCount, percent)
        end
    end

    return table.concat(lines, "\n")
end

-------------------------
-- Public Renderer API
-------------------------

---Renders the Activity stats tab
---@param ctx JournalRenderContext
---@return Effect
function ActivityRenderer.renderActivity(ctx)
    return LibEffect.Async(function()
        local list = ctx.list
        local encounter = ctx.encounter
        local unitNames = ctx.unitNames
        local durationSec = ctx.durationSec
        local weaving = encounter.weaving

        -------------------------
        -- Proc Tracking (top, right after Overview entry)
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
                local totalProcsStr = zo_strformat(GetString(BATTLESCROLLS_STAT_TOTAL_PROCS), procData.totalProcs)
                if procData.medianIntervalMs > 0 then
                    valueStr = string.format("%s (%s %s)", totalProcsStr, GetString(BATTLESCROLLS_STAT_MEDIAN_INTERVAL), formatSeconds(procData.medianIntervalMs / 1000))
                else
                    valueStr = totalProcsStr
                end

                EntryBuilder.addEntry(list, {
                    label = abilityName,
                    sublabel = valueStr,
                    icon = abilityIcon,
                    frame = true,
                    header = isFirst and GetString(BATTLESCROLLS_HEADER_PROC_TRACKING) or nil,
                    tooltip = {
                        type = "text",
                        title = abilityName,
                        text = buildProcTooltipText(procData, unitNames),
                    },
                })
                isFirst = false
            end
        end

        -------------------------
        -- Weaving Section
        -------------------------
        if weaving then
            local totalSum, totalCount = computeWeavingTotals(weaving)

            -- Avg Cast Delay (with explanatory tooltip)
            if totalCount > 0 then
                local avgMs = totalSum / totalCount
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_AVG_WEAVE_TIME),
                    sublabel = formatWeaveTime(avgMs),
                    icon = StatIcons.DURATION,
                    header = GetString(BATTLESCROLLS_HEADER_WEAVING),
                    tooltip = {
                        type = "text",
                        title = GetString(BATTLESCROLLS_STAT_AVG_WEAVE_TIME),
                        text = buildCastDelayTooltip(avgMs, totalSum, totalCount),
                    },
                })
            end

            -- Time Lost
            if totalSum > 0 then
                local timeLostSec = totalSum / 1000
                local pctOfFight = durationSec > 0 and (timeLostSec / durationSec * 100) or 0
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_TIME_LOST),
                    sublabel = string.format("%s (%.1f%%)", formatSeconds(timeLostSec), pctOfFight),
                    icon = StatIcons.DURATION,
                    header = totalCount == 0 and GetString(BATTLESCROLLS_HEADER_WEAVING) or nil,
                    tooltip = {
                        type = "text",
                        title = GetString(BATTLESCROLLS_STAT_TIME_LOST),
                        text = buildTimeLostTooltip(totalSum, durationSec),
                    },
                })
            end

            -- Light attacks
            local lightAttacks = weaving.lightAttackHits
            if lightAttacks > 0 then
                local laPerSec = durationSec > 0 and (lightAttacks / durationSec) or 0
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_LIGHT_ATTACKS),
                    sublabel = string.format("%d (%s)", lightAttacks, formatRate(laPerSec)),
                    icon = StatIcons.DPS,
                })
            end

            -- Heavy attacks
            local heavyAttacks = weaving.heavyAttackHits
            if heavyAttacks > 0 then
                local haPerSec = durationSec > 0 and (heavyAttacks / durationSec) or 0
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_HEAVY_ATTACKS),
                    sublabel = string.format("%d (%s)", heavyAttacks, formatRate(haPerSec)),
                    icon = StatIcons.DPS,
                })
            end

            -- Skill activations
            if weaving.skillActivations > 0 then
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_SKILL_ACTIVATIONS),
                    sublabel = tostring(weaving.skillActivations),
                    icon = StatIcons.SUMMARY,
                })
            end

            -- Missed light attacks (skill→skill) — with tooltip
            if weaving.totalWeavingErrors > 0 then
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_MISSED_LA),
                    sublabel = tostring(weaving.totalWeavingErrors),
                    icon = StatIcons.DAMAGE_TAKEN,
                    tooltip = {
                        type = "text",
                        title = GetString(BATTLESCROLLS_STAT_MISSED_LA),
                        text = buildMissedLaTooltip(weaving.totalWeavingErrors, weaving.skillActivations),
                    },
                })
            end

            -- Double light attacks (la→la) — with tooltip
            if weaving.doubleLaErrors and weaving.doubleLaErrors > 0 then
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_DOUBLE_LA),
                    sublabel = tostring(weaving.doubleLaErrors),
                    icon = StatIcons.DAMAGE_TAKEN,
                    tooltip = {
                        type = "text",
                        title = GetString(BATTLESCROLLS_STAT_DOUBLE_LA),
                        text = buildDoubleLaTooltip(weaving.doubleLaErrors, weaving.lightAttackHits),
                    },
                })
            end

            LibEffect.Yield():Await()

            -------------------------
            -- Per-Ability Weaving Breakdown
            -------------------------
            if #weaving.byAbility > 0 then
                -- Sort by activations descending (most-cast skills first)
                local sorted = {}
                for _, entry in ipairs(weaving.byAbility) do
                    sorted[#sorted + 1] = entry
                end
                table.sort(sorted, function(a, b)
                    return a.activations > b.activations
                end)

                local totalActivations = weaving.skillActivations
                local isFirst = true
                local maxAbilities = 25
                for i, entry in ipairs(sorted) do
                    if i > maxAbilities then break end

                    local abilityName = utils.getAbilityDisplayName(entry.abilityId)
                    local abilityIcon = GetAbilityIcon(entry.abilityId)

                    -- Sublabel: casts first (primary), then avg delay (secondary)
                    local sublabel
                    if entry.afterCount > 0 then
                        local avgMs = entry.afterSum / entry.afterCount
                        sublabel = string.format("%d× (%s)", entry.activations, formatWeaveTime(avgMs))
                    else
                        sublabel = string.format("%d×", entry.activations)
                    end

                    EntryBuilder.addEntry(list, {
                        label = zo_strformat("<<C:1>>", abilityName),
                        sublabel = sublabel,
                        icon = abilityIcon,
                        frame = true,
                        header = isFirst and GetString(BATTLESCROLLS_HEADER_WEAVING_BY_ABILITY) or nil,
                        tooltip = {
                            type = "text",
                            title = zo_strformat("<<C:1>>", abilityName),
                            text = buildWeavingAbilityTooltipText(entry, totalActivations),
                        },
                    })
                    isFirst = false

                    if i % 20 == 0 then
                        LibEffect.Yield():Await()
                    end
                end
            end

            LibEffect.Yield():Await()
        end
    end)
end

-------------------------
-- Overview Panel
-------------------------

---Builds a PanelSpec for the Activity tab overview panel
---Q2: Weaving summary stats
---Q3: Top abilities by cast count with icons
---Q4: Proc summary with icons (only when procs exist)
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table, abilityInfo: table }
---@return PanelSpec
function ActivityRenderer.buildActivityPanelSpec(ctx)
    return {
        layout = "wide-right",
        build = function(q2, q3)
            local encounter = ctx.encounter
            local durationS = ctx.durationS
            local weaving = encounter.weaving

            -------------------------
            -- Q2: Weaving Summary
            -------------------------
            if weaving then
                local totalSum, totalCount = computeWeavingTotals(weaving)

                local avgWeaveRow
                if totalCount > 0 then
                    avgWeaveRow = q2:StatRow(GetString(BATTLESCROLLS_STAT_AVG_WEAVE_TIME), formatWeaveTime(totalSum / totalCount))
                end

                local timeLostRow
                if totalSum > 0 then
                    local timeLostSec = totalSum / 1000
                    local pctOfFight = durationS > 0 and (timeLostSec / durationS * 100) or 0
                    timeLostRow = q2:StatRow(GetString(BATTLESCROLLS_STAT_TIME_LOST), string.format("%s (%.1f%%)", formatSeconds(timeLostSec), pctOfFight))
                end

                local lightAttacks = weaving.lightAttackHits
                local laRow
                if lightAttacks > 0 then
                    local laPerSec = durationS > 0 and (lightAttacks / durationS) or 0
                    laRow = q2:StatRow(GetString(BATTLESCROLLS_STAT_LIGHT_ATTACKS), string.format("%d (%s)", lightAttacks, formatRate(laPerSec)))
                end

                local heavyAttacks = weaving.heavyAttackHits
                local haRow
                if heavyAttacks > 0 then
                    local haPerSec = durationS > 0 and (heavyAttacks / durationS) or 0
                    haRow = q2:StatRow(GetString(BATTLESCROLLS_STAT_HEAVY_ATTACKS), string.format("%d (%s)", heavyAttacks, formatRate(haPerSec)))
                end

                local skillRow = weaving.skillActivations > 0
                    and q2:StatRow(GetString(BATTLESCROLLS_STAT_SKILL_ACTIVATIONS), tostring(weaving.skillActivations))
                    or nil

                local missedLaRow = weaving.totalWeavingErrors > 0
                    and q2:StatRow(GetString(BATTLESCROLLS_STAT_MISSED_LA), tostring(weaving.totalWeavingErrors))
                    or nil

                local doubleLaRow = weaving.doubleLaErrors and weaving.doubleLaErrors > 0
                    and q2:StatRow(GetString(BATTLESCROLLS_STAT_DOUBLE_LA), tostring(weaving.doubleLaErrors))
                    or nil

                local weavingSection = q2:Section(GetString(BATTLESCROLLS_HEADER_WEAVING),
                    avgWeaveRow, timeLostRow, laRow, haRow, skillRow, missedLaRow, doubleLaRow)
                q2:mount(SECTION_GAP, 0, weavingSection)
            end

            LibEffect.Yield():Await()

            -------------------------
            -- Q3: Procs + Abilities (combined right column)
            -------------------------
            local sections = {}

            if encounter.procs and #encounter.procs > 0 then
                local maxProcs = q3:maxItems(ROW_CONTENT.STAT_ROW, 10)
                local rows = {}
                for i, procData in ipairs(encounter.procs) do
                    if i > maxProcs then break end
                    local name = BattleScrolls.utils.GetScribeAwareAbilityDisplayName(procData.abilityId)
                    if name == "" then
                        name = string.format("ID %d", procData.abilityId)
                    end
                    local icon = GetAbilityIcon(procData.abilityId)
                    local text
                    if procData.medianIntervalMs > 0 then
                        text = string.format("%s — %d (%s)", name, procData.totalProcs, formatSeconds(procData.medianIntervalMs / 1000))
                    else
                        text = string.format("%s — %d", name, procData.totalProcs)
                    end
                    rows[#rows + 1] = q3:IconTextRow(icon, text, nil, true)
                end

                if #rows > 0 then
                    sections[#sections + 1] = q3:Section(GetString(BATTLESCROLLS_HEADER_PROC_TRACKING), rows)
                end
            end

            if weaving and #weaving.byAbility > 0 then
                local sorted = {}
                for _, entry in ipairs(weaving.byAbility) do
                    sorted[#sorted + 1] = entry
                end
                table.sort(sorted, function(a, b)
                    return a.activations > b.activations
                end)

                local maxAbilities = q3:maxItems(ROW_CONTENT.STAT_ROW, 10)
                local rows = {}
                for i, entry in ipairs(sorted) do
                    if i > maxAbilities then break end
                    local name = zo_strformat("<<C:1>>", utils.getAbilityDisplayName(entry.abilityId))
                    local icon = GetAbilityIcon(entry.abilityId)
                    local text
                    if entry.afterCount > 0 then
                        local avgMs = entry.afterSum / entry.afterCount
                        text = string.format("%s — %d× (%s)", name, entry.activations, formatWeaveTime(avgMs))
                    else
                        text = string.format("%s — %d×", name, entry.activations)
                    end
                    rows[#rows + 1] = q3:IconTextRow(icon, text, nil, true)
                end

                if #rows > 0 then
                    sections[#sections + 1] = q3:Section(GetString(BATTLESCROLLS_HEADER_WEAVING_BY_ABILITY), rows)
                end
            end

            if #sections > 0 then
                q3:mount(SECTION_GAP, Q3_INSET, unpack(sections))
            end
        end,
    }
end

-- Export to namespace
journal.renderers.activity = ActivityRenderer

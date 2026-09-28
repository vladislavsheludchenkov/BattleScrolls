-----------------------------------------------------------
-- Activity Renderer
-- Renders the Activity tab: procs, ultimate, Crux, support,
-- Z'en and weaving. Receives a JournalRenderContext and
-- populates the list; buildActivityPanelSpec builds the
-- three-column overview panel from the same data.
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

local VALUE_SEP = " · "

local TOME_BEARER_INSPIRATION_ID = 186452
local BANNER_BEARER_ID = 217699
-- Crypt Transfer donates the whole pool despite a nominal slot cost of 1.
local CRYPT_TRANSFER_ABILITY_ID = 195031

local ActivityRenderer = {}

-------------------------
-- Formatting Helpers
-------------------------

---@param ms number
---@return string
local function formatWeaveTime(ms)
    return zo_strformat(GetString(BATTLESCROLLS_FORMAT_MILLISECONDS), math.floor(ms + 0.5))
end

---@param sec number
---@return string
local function formatSeconds(sec)
    return zo_strformat(GetString(BATTLESCROLLS_FORMAT_SECONDS), string.format("%.1f", sec))
end

---@param rate number
---@return string
local function formatRate(rate)
    return zo_strformat(GetString(BATTLESCROLLS_STAT_PER_SECOND), string.format("%.2f", rate))
end

---@param count number
---@param durationSec number
---@return string
local function formatPerMinute(count, durationSec)
    local perMin = durationSec > 0 and (count / durationSec * 60) or 0
    return zo_strformat(GetString(BATTLESCROLLS_STAT_PER_MINUTE), string.format("%.1f", perMin))
end

---"N (x.x%)", or just "N" when there is nothing to take a share of
---@param count number
---@param total number
---@return string
local function formatCountShare(count, total)
    if count == 0 or total == 0 then
        return tostring(count)
    end
    return string.format("%d (%.1f%%)", count, count / total * 100)
end

---@param name string
---@return string
local function capitalized(name)
    return zo_strformat("<<C:1>>", name)
end

-------------------------
-- Weaving
-------------------------

-- FIXME: Move weaving totals into Arithmancer for the list and panel to share.

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

---@param avgMs number
---@param totalSum number
---@param totalCount number
---@return string
local function buildCastDelayTooltip(avgMs, totalSum, totalCount)
    local lines = {}
    lines[#lines + 1] = GetString(BATTLESCROLLS_TOOLTIP_INTER_CAST_DESC)
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("%s (%d×)", formatWeaveTime(avgMs), totalCount)
    lines[#lines + 1] = string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_TOTAL), formatSeconds(totalSum / 1000))
    return table.concat(lines, "\n")
end

---@param totalSum number
---@param durationSec number
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

---@param downtimeMs number
---@param gaps number
---@param durationSec number
---@return string
local function buildDowntimeTooltip(downtimeMs, gaps, durationSec)
    local lines = {}
    lines[#lines + 1] = GetString(BATTLESCROLLS_TOOLTIP_DOWNTIME_DESC)
    lines[#lines + 1] = ""
    local downtimeSec = downtimeMs / 1000
    local pctOfFight = durationSec > 0 and (downtimeSec / durationSec * 100) or 0
    lines[#lines + 1] = string.format("%s / %s (%.1f%%), %d×", formatSeconds(downtimeSec), formatSeconds(durationSec), pctOfFight, gaps)
    return table.concat(lines, "\n")
end

---@param errors number
---@param skillActivations number
---@return string
local function buildMissedLaTooltip(errors, skillActivations)
    local lines = {}
    lines[#lines + 1] = GetString(BATTLESCROLLS_TOOLTIP_MISSED_LA_DESC)
    if skillActivations > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = string.format("%d / %d (%.1f%%)", errors, skillActivations, errors / skillActivations * 100)
    end
    return table.concat(lines, "\n")
end

---@param errors number
---@param lightAttacks number
---@return string
local function buildDoubleLaTooltip(errors, lightAttacks)
    local lines = {}
    lines[#lines + 1] = GetString(BATTLESCROLLS_TOOLTIP_DOUBLE_LA_DESC)
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("%d / %d (%.1f%%)", errors, lightAttacks, errors / lightAttacks * 100)
    return table.concat(lines, "\n")
end

---@param entry WeavingAbilityData
---@param totalActivations number
---@return string
local function buildWeavingAbilityTooltipText(entry, totalActivations)
    local lines = {}
    lines[#lines + 1] = string.format("%s: %s", GetString(BATTLESCROLLS_STAT_CASTS), formatCountShare(entry.activations, totalActivations))
    if entry.afterCount > 0 then
        lines[#lines + 1] = string.format("%s: %s (%d×)",
            GetString(BATTLESCROLLS_TOOLTIP_DELAY_AFTER), formatWeaveTime(entry.afterSum / entry.afterCount), entry.afterCount)
    end
    if entry.beforeCount > 0 then
        lines[#lines + 1] = string.format("%s: %s (%d×)",
            GetString(BATTLESCROLLS_TOOLTIP_DELAY_BEFORE), formatWeaveTime(entry.beforeSum / entry.beforeCount), entry.beforeCount)
    end
    if entry.weavingErrors > 0 then
        lines[#lines + 1] = string.format("%s: %d", GetString(BATTLESCROLLS_STAT_MISSED_LA), entry.weavingErrors)
    end
    lines[#lines + 1] = ""
    utils.appendAbilityIdLine(lines, entry.abilityId)
    return table.concat(lines, "\n")
end

---@param weaving WeavingData
---@return WeavingAbilityData[]
local function sortedWeavingAbilities(weaving)
    local sorted = {}
    for _, entry in ipairs(weaving.byAbility) do
        sorted[#sorted + 1] = entry
    end
    table.sort(sorted, function(a, b)
        return a.activations > b.activations
    end)
    return sorted
end

---"45× · 1234ms delay"
---@param entry WeavingAbilityData
---@return string
local function weavingAbilityDetail(entry)
    if entry.afterCount > 0 then
        return string.format("%d×%s%s", entry.activations, VALUE_SEP,
            zo_strformat(GetString(BATTLESCROLLS_DETAIL_DELAY), formatWeaveTime(entry.afterSum / entry.afterCount)))
    end
    return string.format("%d×", entry.activations)
end

-------------------------
-- Procs
-------------------------

---@param procData ProcData
---@param unitNames table<number, string>
---@return string
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

    lines[#lines + 1] = ""
    utils.appendAbilityIdLine(lines, procData.abilityId)
    return table.concat(lines, "\n")
end

---"41× · median 8.0s"
---@param procData ProcData
---@return string
local function procDetail(procData)
    if procData.medianIntervalMs > 0 then
        return string.format("%d×%s%s", procData.totalProcs, VALUE_SEP,
            zo_strformat(GetString(BATTLESCROLLS_DETAIL_MEDIAN), formatSeconds(procData.medianIntervalMs / 1000)))
    end
    return string.format("%d×", procData.totalProcs)
end

---@param procData ProcData
---@return string
local function procDisplayName(procData)
    local name = BattleScrolls.utils.GetScribeAwareAbilityDisplayName(procData.abilityId)
    if name == "" then
        return string.format("%s %d", GetString(BATTLESCROLLS_TOOLTIP_ABILITY), procData.abilityId)
    end
    return name
end

-------------------------
-- Ultimate
-------------------------

---Appends "Includes X: uptime%, ~N" lines for fixed-rate silent ultimate
---sources/drains (Heroism, Timidity) whose uptime lives in the player-effect stats
---@param lines string[]
---@param effectsOnPlayer table<number, EffectStats>|nil
---@param ratePerTick table<number, number>
---@param durationSec number
local function appendSilentUltLines(lines, effectsOnPlayer, ratePerTick, durationSec)
    if not effectsOnPlayer then
        return
    end
    local ids = {}
    for buffId in pairs(ratePerTick) do
        local stats = effectsOnPlayer[buffId]
        if stats and stats.totalActiveTimeMs > 0 then
            ids[#ids + 1] = buffId
        end
    end
    table.sort(ids)
    for _, buffId in ipairs(ids) do
        local activeMs = effectsOnPlayer[buffId].totalActiveTimeMs
        local approx = math.ceil(activeMs / BattleScrolls.ultimate.FIXED_RATE_TICK_MS) * ratePerTick[buffId]
        local uptimePct = durationSec > 0 and (activeMs / (durationSec * 1000) * 100) or 0
        lines[#lines + 1] = zo_strformat(GetString(BATTLESCROLLS_ULT_HEROISM_LINE),
            utils.getAbilityDisplayName(buffId), string.format("%.1f", uptimePct), approx)
    end
end

-- FIXME: Move ultimate spending/source/cast calculations into Arithmancer,
-- preserving legacy unknown-cost handling and the Crypt Transfer exception.
---@class UltSpend
---@field known boolean True when every cast carries its pool/cost (v20+ recordings)
---@field spent number Sum of cast costs
---@field lost number Pool consumed above the costs
---@field drained number Pool decreases outside casts

---@param ult UltimateData
---@return UltSpend
local function computeUltSpend(ult)
    local spent, poolSum = 0, 0
    for _, cast in ipairs(ult.casts) do
        if not cast.cost or not cast.poolBefore then
            return { known = false, spent = 0, lost = 0, drained = ult.totalDrained }
        end
        spent = spent + (cast.abilityId == CRYPT_TRANSFER_ABILITY_ID and cast.poolBefore or cast.cost)
        poolSum = poolSum + cast.poolBefore
    end
    return {
        known = #ult.casts > 0,
        spent = spent,
        lost = math.max(0, poolSum - spent),
        drained = math.max(0, ult.totalDrained - poolSum),
    }
end

---@class UltSourceEntry
---@field abilityId number
---@field gain UltGainBreakdown

---@param ult UltimateData
---@return UltSourceEntry[] sources
---@return number gainTotal
local function collectUltSources(ult)
    local gainTotal = 0
    local sources = {}
    for abilityId, gain in pairs(ult.gainByAbilityId) do
        gainTotal = gainTotal + gain.total
        sources[#sources + 1] = { abilityId = abilityId, gain = gain }
    end
    table.sort(sources, function(a, b) return a.gain.total > b.gain.total end)
    return sources, gainTotal
end

---@class UltCastGroup
---@field abilityId number
---@field times number[]
---@field lost number Pool consumed above cost across the casts (0 when unknown)

---Groups ultimate casts per ability, preserving first-cast order
---@param casts UltCastEvent[]
---@return UltCastGroup[]
local function collectUltCasts(casts)
    local byUlt = {}
    local groups = {}
    for _, cast in ipairs(casts) do
        local group = byUlt[cast.abilityId]
        if not group then
            group = { abilityId = cast.abilityId, times = {}, lost = 0 }
            byUlt[cast.abilityId] = group
            groups[#groups + 1] = group
        end
        group.times[#group.times + 1] = cast.timeMs
        if cast.cost and cast.poolBefore and cast.abilityId ~= CRYPT_TRANSFER_ABILITY_ID then
            group.lost = group.lost + math.max(0, cast.poolBefore - cast.cost)
        end
    end
    return groups
end

---@param abilityId number
---@return string name
---@return string icon
local function ultSourceNameIcon(abilityId)
    if abilityId == 0 then
        return GetString(BATTLESCROLLS_ULT_BASE_GENERATION), StatIcons.HEROISM
    end
    return capitalized(utils.getAbilityDisplayName(abilityId)), utils.getAbilityIcon(abilityId)
end

---"343 (80%) · 2.61/s"
---@param source UltSourceEntry
---@param gainTotal number
---@param durationSec number
---@return string
local function ultSourceDetail(source, gainTotal, durationSec)
    local pct = gainTotal > 0 and (source.gain.total / gainTotal * 100) or 0
    return string.format("%d (%.0f%%)%s%s", source.gain.total, pct, VALUE_SEP,
        formatRate(durationSec > 0 and source.gain.total / durationSec or 0))
end

---"9× · 831 lost"
---@param group UltCastGroup
---@param spend UltSpend
---@return string
local function ultCastDetail(group, spend)
    if spend.known then
        return string.format("%d×%s%s", #group.times, VALUE_SEP, zo_strformat(GetString(BATTLESCROLLS_DETAIL_LOST), group.lost))
    end
    return string.format("%d×", #group.times)
end

---@param list any
---@param ult UltimateData
---@param durationSec number
---@param effectsOnPlayer table<number, EffectStats>|nil
local function renderUltimateSection(list, ult, durationSec, effectsOnPlayer)
    EntryBuilder.addEntry(list, {
        label = GetString(BATTLESCROLLS_STAT_ULT_AT_ENTRY),
        sublabel = string.format("%d / %d", ult.startUlt, ult.maxUlt),
        icon = StatIcons.COMBAT,
        header = GetString(BATTLESCROLLS_HEADER_ULTIMATE),
    })

    if ult.totalGained > 0 then
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_ULT_GENERATED),
            sublabel = string.format("%d (%s)", ult.totalGained, formatRate(durationSec > 0 and ult.totalGained / durationSec or 0)),
            icon = StatIcons.ULTIMATE,
        })
    end

    local spend = computeUltSpend(ult)
    if spend.known then
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_ULT_SPENT),
            sublabel = tostring(spend.spent),
            icon = StatIcons.DPS,
        })
        if spend.lost > 0 then
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_ULT_LOST),
                sublabel = tostring(spend.lost),
                icon = StatIcons.DAMAGE_TAKEN,
                tooltip = { type = "text", title = GetString(BATTLESCROLLS_STAT_ULT_LOST), text = GetString(BATTLESCROLLS_STAT_ULT_LOST_TT) },
            })
        end
    end
    if spend.drained > 0 then
        local drainLines = {}
        appendSilentUltLines(drainLines, effectsOnPlayer, BattleScrolls.ultimate.TIMIDITY_DEBUFFS, durationSec)
        local label = GetString(spend.known and BATTLESCROLLS_STAT_ULT_DRAINED or BATTLESCROLLS_STAT_ULT_SPENT_DRAINED)
        EntryBuilder.addEntry(list, {
            label = label,
            sublabel = tostring(spend.drained),
            icon = StatIcons.DAMAGE_TAKEN,
            tooltip = #drainLines > 0 and { type = "text", title = label, text = table.concat(drainLines, "\n") } or nil,
        })
    end

    local sources, gainTotal = collectUltSources(ult)
    local isFirst = true
    for _, source in ipairs(sources) do
        local name, icon = ultSourceNameIcon(source.abilityId)
        local gain = source.gain
        local pct = gainTotal > 0 and (gain.total / gainTotal * 100) or 0
        local tooltipLines = {
            string.format("%s: %d (%.1f%%)", GetString(BATTLESCROLLS_TOOLTIP_TOTAL), gain.total, pct),
            formatRate(durationSec > 0 and gain.total / durationSec or 0),
        }
        if gain.ticks > 0 then
            tooltipLines[#tooltipLines + 1] = ""
            tooltipLines[#tooltipLines + 1] = string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_TICKS), gain.ticks)
            tooltipLines[#tooltipLines + 1] = string.format("%s: %.1f", GetString(BATTLESCROLLS_TOOLTIP_AVG_TICK), gain.total / gain.ticks)
            tooltipLines[#tooltipLines + 1] = string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_MIN_TICK), gain.minTick)
            tooltipLines[#tooltipLines + 1] = string.format("%s: %d", GetString(BATTLESCROLLS_TOOLTIP_MAX_TICK), gain.maxTick)
        else
            appendSilentUltLines(tooltipLines, effectsOnPlayer, BattleScrolls.ultimate.HEROISM_BUFFS, durationSec)
        end
        if source.abilityId ~= 0 then
            tooltipLines[#tooltipLines + 1] = ""
            utils.appendAbilityIdLine(tooltipLines, source.abilityId)
        end

        EntryBuilder.addEntry(list, {
            label = name,
            sublabel = ultSourceDetail(source, gainTotal, durationSec),
            icon = icon,
            frame = source.abilityId ~= 0,
            header = isFirst and GetString(BATTLESCROLLS_HEADER_ULT_SOURCES) or nil,
            tooltip = { type = "text", title = name, text = table.concat(tooltipLines, "\n") },
        })
        isFirst = false
    end

    local castGroups = collectUltCasts(ult.casts)
    isFirst = true
    for _, group in ipairs(castGroups) do
        local name = capitalized(utils.getAbilityDisplayName(group.abilityId))
        local timeStrings = {}
        for _, timeMs in ipairs(group.times) do
            timeStrings[#timeStrings + 1] = utils.formatDuration(timeMs)
        end
        local tooltipLines = {
            string.format("%s: %d", GetString(BATTLESCROLLS_STAT_CASTS), #group.times),
        }
        if spend.known then
            tooltipLines[#tooltipLines + 1] = string.format("%s: %d", GetString(BATTLESCROLLS_STAT_ULT_LOST), group.lost)
        end
        tooltipLines[#tooltipLines + 1] = ""
        tooltipLines[#tooltipLines + 1] = table.concat(timeStrings, ", ")
        tooltipLines[#tooltipLines + 1] = ""
        utils.appendAbilityIdLine(tooltipLines, group.abilityId)

        EntryBuilder.addEntry(list, {
            label = name,
            sublabel = ultCastDetail(group, spend),
            icon = utils.getAbilityIcon(group.abilityId),
            frame = true,
            header = isFirst and GetString(BATTLESCROLLS_HEADER_ULT_CASTS) or nil,
            tooltip = { type = "text", title = name, text = table.concat(tooltipLines, "\n") },
        })
        isFirst = false
    end
end

-------------------------
-- Crux
-------------------------

-- FIXME: Move Crux gain/waste and understacked-spend aggregates into Arithmancer.

---@class CruxGainEntry
---@field abilityId number
---@field gained number
---@field wasted number Procs that found Crux full (conditional sources only)
---@field casts number|nil Cast count (generators only)

---Crux gains per source, sorted by gained descending. Generators contribute
---their observed gains; conditional sources their paired procs.
---@param crux CruxData
---@return CruxGainEntry[]
local function collectCruxGains(crux)
    local gains = {}
    for abilityId, activity in pairs(crux.byAbility) do
        if not BattleScrolls.crux.CRUX_SPENDERS[abilityId] and (activity.gained or 0) > 0 then
            gains[#gains + 1] = { abilityId = abilityId, gained = activity.gained, wasted = 0, casts = activity.casts }
        end
    end
    local conditional = crux.conditionalGains or {}
    local wasted = crux.conditionalWasted or {}
    for abilityId, count in pairs(conditional) do
        if count > 0 or (wasted[abilityId] or 0) > 0 then
            gains[#gains + 1] = { abilityId = abilityId, gained = count, wasted = wasted[abilityId] or 0 }
        end
    end
    for abilityId, count in pairs(wasted) do
        if count > 0 and (conditional[abilityId] or 0) == 0 then
            gains[#gains + 1] = { abilityId = abilityId, gained = 0, wasted = count }
        end
    end
    table.sort(gains, function(a, b)
        if a.gained ~= b.gained then return a.gained > b.gained end
        return a.wasted > b.wasted
    end)
    return gains
end

---@param crux CruxData
---@return number
local function cruxProcWastedTotal(crux)
    local total = 0
    for _, count in pairs(crux.conditionalWasted or {}) do
        total = total + count
    end
    return total
end

---"+58 · 12 at full"
---@param entry CruxGainEntry
---@return string
local function cruxGainDetail(entry)
    if entry.wasted > 0 then
        return string.format("+%d%s%s", entry.gained, VALUE_SEP, zo_strformat(GetString(BATTLESCROLLS_DETAIL_AT_FULL), entry.wasted))
    end
    return string.format("+%d", entry.gained)
end

---@param crux CruxData
---@return number
local function cruxUnderTotal(crux)
    return (crux.spenderUnder[1] or 0) + (crux.spenderUnder[2] or 0) + (crux.spenderUnder[3] or 0)
end

---@param list any
---@param crux CruxData
local function renderCruxSection(list, crux)
    local needsHeader = true
    local function takeHeader()
        if needsHeader then
            needsHeader = false
            return GetString(BATTLESCROLLS_HEADER_CRUX)
        end
        return nil
    end

    if crux.generatorCasts > 0 then
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_CRUX_GENERATORS),
            sublabel = tostring(crux.generatorCasts),
            icon = StatIcons.DPS,
            header = takeHeader(),
        })
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_CRUX_AT_FULL),
            sublabel = formatCountShare(crux.generatorAtFull, crux.generatorCasts),
            icon = StatIcons.DAMAGE_TAKEN,
        })
    end

    if crux.spenderCasts > 0 then
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_CRUX_SPENDERS),
            sublabel = tostring(crux.spenderCasts),
            icon = StatIcons.AOE,
            header = takeHeader(),
        })
        local tooltipLines = {}
        for cruxCount = 0, 2 do
            tooltipLines[#tooltipLines + 1] = zo_strformat(GetString(BATTLESCROLLS_CRUX_AT_N), cruxCount, crux.spenderUnder[cruxCount + 1] or 0)
        end
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_CRUX_UNDER),
            sublabel = formatCountShare(cruxUnderTotal(crux), crux.spenderCasts),
            icon = StatIcons.DAMAGE_TAKEN,
            tooltip = { type = "text", title = GetString(BATTLESCROLLS_STAT_CRUX_UNDER), text = table.concat(tooltipLines, "\n") },
        })
    end

    local procWasted = cruxProcWastedTotal(crux)
    if procWasted > 0 then
        local tooltipLines = {
            zo_strformat(GetString(BATTLESCROLLS_STAT_CRUX_PROC_WASTED_TT),
                utils.getAbilityDisplayName(TOME_BEARER_INSPIRATION_ID), utils.getAbilityDisplayName(BANNER_BEARER_ID)),
            "",
        }
        for _, entry in ipairs(collectCruxGains(crux)) do
            if entry.wasted > 0 then
                tooltipLines[#tooltipLines + 1] = string.format("%s: %d",
                    capitalized(utils.getAbilityDisplayName(entry.abilityId)), entry.wasted)
            end
        end
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_CRUX_PROC_WASTED),
            sublabel = tostring(procWasted),
            icon = StatIcons.DAMAGE_TAKEN,
            header = takeHeader(),
            tooltip = { type = "text", title = GetString(BATTLESCROLLS_STAT_CRUX_PROC_WASTED), text = table.concat(tooltipLines, "\n") },
        })
    end

    if (crux.deathEvents or 0) > 0 then
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_CRUX_DEATH),
            sublabel = string.format("%d (%d×)", crux.deathStacks, crux.deathEvents),
            icon = StatIcons.DEATH,
            header = takeHeader(),
        })
    end
    if crux.passiveEvents > 0 then
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_CRUX_PASSIVE),
            sublabel = string.format("%d (%d×)", crux.passiveStacks, crux.passiveEvents),
            icon = StatIcons.DURATION,
            header = takeHeader(),
            tooltip = { type = "text", title = GetString(BATTLESCROLLS_STAT_CRUX_PASSIVE), text = GetString(BATTLESCROLLS_STAT_CRUX_PASSIVE_TT) },
        })
    end

    local isFirstGain = true
    for _, entry in ipairs(collectCruxGains(crux)) do
        local name = capitalized(utils.getAbilityDisplayName(entry.abilityId))
        local tooltipLines = {}
        if entry.casts then
            tooltipLines[#tooltipLines + 1] = string.format("%s: %d", GetString(BATTLESCROLLS_STAT_CASTS), entry.casts)
        else
            tooltipLines[#tooltipLines + 1] = GetString(BATTLESCROLLS_STAT_CRUX_CONDITIONAL_TT)
        end
        if entry.wasted > 0 then
            tooltipLines[#tooltipLines + 1] = string.format("%s: %d", GetString(BATTLESCROLLS_STAT_CRUX_PROC_WASTED), entry.wasted)
        end
        tooltipLines[#tooltipLines + 1] = ""
        utils.appendAbilityIdLine(tooltipLines, entry.abilityId)
        EntryBuilder.addEntry(list, {
            label = name,
            sublabel = cruxGainDetail(entry),
            icon = utils.getAbilityIcon(entry.abilityId),
            frame = true,
            header = isFirstGain and GetString(BATTLESCROLLS_HEADER_CRUX_GAINED) or nil,
            tooltip = { type = "text", title = name, text = table.concat(tooltipLines, "\n") },
        })
        isFirstGain = false
    end
    if crux.unattributedGains > 0 then
        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_STAT_CRUX_OTHER),
            sublabel = string.format("+%d", crux.unattributedGains),
            icon = StatIcons.DURATION,
            header = isFirstGain and GetString(BATTLESCROLLS_HEADER_CRUX_GAINED) or nil,
            tooltip = {
                type = "text",
                title = GetString(BATTLESCROLLS_STAT_CRUX_OTHER),
                text = GetString(BATTLESCROLLS_STAT_CRUX_OTHER_TT),
            },
        })
    end

    local badAbilities = {}
    for abilityId, activity in pairs(crux.byAbility) do
        if activity.bad > 0 then
            badAbilities[#badAbilities + 1] = {
                abilityId = abilityId,
                casts = activity.casts,
                bad = activity.bad,
                spender = BattleScrolls.crux.CRUX_SPENDERS[abilityId] ~= nil,
            }
        end
    end
    table.sort(badAbilities, function(a, b) return a.bad > b.bad end)

    local isFirst = true
    for _, entry in ipairs(badAbilities) do
        local name = capitalized(utils.getAbilityDisplayName(entry.abilityId))
        local badPct = entry.casts > 0 and (entry.bad / entry.casts * 100) or 0
        local badLabel = GetString(entry.spender and BATTLESCROLLS_STAT_CRUX_UNDER or BATTLESCROLLS_STAT_CRUX_AT_FULL)
        local tooltipLines = {
            string.format("%s: %d", GetString(BATTLESCROLLS_STAT_CASTS), entry.casts),
            string.format("%s: %d", badLabel, entry.bad),
            "",
        }
        utils.appendAbilityIdLine(tooltipLines, entry.abilityId)
        EntryBuilder.addEntry(list, {
            label = name,
            sublabel = string.format("%d / %d (%.1f%%)", entry.bad, entry.casts, badPct),
            icon = utils.getAbilityIcon(entry.abilityId),
            frame = true,
            header = isFirst and GetString(BATTLESCROLLS_HEADER_CRUX_BY_ABILITY) or nil,
            tooltip = { type = "text", title = name, text = table.concat(tooltipLines, "\n") },
        })
        isFirst = false
    end
end

-------------------------
-- Resurrections
-------------------------

---@class ResurrectionTargetEntry
---@field displayName string
---@field count number

---@param log ResurrectionEvent[]|nil
---@return ResurrectionTargetEntry[]
local function collectResurrectionTargets(log)
    local byName = {}
    local entries = {}
    for _, event in ipairs(log or {}) do
        local entry = byName[event.displayName]
        if not entry then
            entry = { displayName = event.displayName, count = 0 }
            byName[event.displayName] = entry
            entries[#entries + 1] = entry
        end
        entry.count = entry.count + 1
    end
    table.sort(entries, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.displayName < b.displayName
    end)
    return entries
end

---@param log ResurrectionEvent[]
---@return string
local function buildResurrectionTooltip(log)
    local lines = {}
    for _, event in ipairs(log) do
        lines[#lines + 1] = string.format("%s  %s", utils.formatDuration(event.timeMs), event.displayName)
    end
    return table.concat(lines, "\n")
end

-------------------------
-- Z'en / DoT Stacking
-------------------------

-- FIXME: Move Z'en bucket summary calculations into Arithmancer.

---@class ZenSummary
---@field totalMs number
---@field avgDots number
---@field zenPct number Player's Z'en debuff uptime %
---@field hasZen boolean Whether the player's debuff was ever up
---@field peakDots number Highest DoT count that occurred (5 = tracking cap, i.e. 5+)
---@field peakPct number Time share at that DoT count %

---@param buckets number[]
---@return ZenSummary
local function computeZenSummary(buckets)
    local totalMs, dotWeightedMs, zenMs = 0, 0, 0
    local bucketMs = {}
    for dots = 0, 5 do
        local noZen = buckets[dots * 2 + 1] or 0
        local withZen = buckets[dots * 2 + 2] or 0
        bucketMs[dots] = noZen + withZen
        totalMs = totalMs + noZen + withZen
        dotWeightedMs = dotWeightedMs + dots * (noZen + withZen)
        zenMs = zenMs + withZen
    end
    if totalMs == 0 then
        return { totalMs = 0, avgDots = 0, zenPct = 0, hasZen = false, peakDots = 0, peakPct = 0 }
    end
    local peakDots = 0
    for dots = 5, 1, -1 do
        if bucketMs[dots] > 0 then
            peakDots = dots
            break
        end
    end
    return {
        totalMs = totalMs,
        avgDots = dotWeightedMs / totalMs,
        zenPct = zenMs / totalMs * 100,
        hasZen = zenMs > 0,
        peakDots = peakDots,
        peakPct = bucketMs[peakDots] / totalMs * 100,
    }
end

---@param dots number
---@return string
local function formatZenDotsLabel(dots)
    return zo_strformat(GetString(BATTLESCROLLS_ZEN_DOTS_LABEL), dots == 5 and "5+" or tostring(dots))
end

---"85% · avg 3.2 DoTs · 60% at 5+ DoTs" (uptime omitted when the player's
---debuff never landed)
---@param s ZenSummary
---@return string
local function zenDetail(s)
    local parts = {}
    if s.hasZen then
        parts[#parts + 1] = string.format("%.0f%%", s.zenPct)
    end
    parts[#parts + 1] = zo_strformat(GetString(BATTLESCROLLS_DETAIL_AVG_DOTS), string.format("%.1f", s.avgDots))
    parts[#parts + 1] = zo_strformat(GetString(BATTLESCROLLS_DETAIL_AT_DOTS), string.format("%.0f%%", s.peakPct), formatZenDotsLabel(s.peakDots))
    return table.concat(parts, VALUE_SEP)
end

---@param zen ZenData
---@return string[]
local function sortedZenKeys(zen)
    local keys = {}
    for key in pairs(zen) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

---Keys are "bossTag:tagSeq", the shape bossSeqNames uses
---@param encounter DecodedEncounter
---@param key string
---@return string
local function zenBossName(encounter, key)
    local rawBossName = (encounter.bossSeqNames and encounter.bossSeqNames[key])
        or key:match("^(.-):%d+$") or key
    return zo_strformat(SI_UNIT_NAME, rawBossName)
end

---@param list any
---@param zen ZenData
---@param encounter DecodedEncounter
local function renderZenSection(list, zen, encounter)
    local isFirst = true
    for _, key in ipairs(sortedZenKeys(zen)) do
        local buckets = zen[key]
        local s = computeZenSummary(buckets)
        if s.totalMs > 0 then
            local bossName = zenBossName(encounter, key)
            local tooltipLines = {
                GetString(BATTLESCROLLS_ZEN_NOTE),
                "",
                string.format("%s: %.1f", GetString(BATTLESCROLLS_ZEN_AVG_DOTS), s.avgDots),
                string.format("%s: %.1f%%", GetString(BATTLESCROLLS_ZEN_UPTIME), s.zenPct),
                string.format("%s: %.1f%%", zo_strformat(GetString(BATTLESCROLLS_ZEN_PEAK_TIME), formatZenDotsLabel(s.peakDots)), s.peakPct),
                "",
                GetString(BATTLESCROLLS_ZEN_DISTRIBUTION_NOTE),
                "",
            }
            for dots = 0, 5 do
                local noZen = buckets[dots * 2 + 1] or 0
                local withZen = buckets[dots * 2 + 2] or 0
                local bucketMs = noZen + withZen
                if bucketMs > 0 then
                    local bucketPct = bucketMs / s.totalMs * 100
                    local dotsLabel = formatZenDotsLabel(dots)
                    if withZen > 0 then
                        tooltipLines[#tooltipLines + 1] = string.format("%s: %.1f%% (%s %.0f%%)",
                            dotsLabel, bucketPct, GetString(BATTLESCROLLS_ZEN_SHORT), withZen / bucketMs * 100)
                    else
                        tooltipLines[#tooltipLines + 1] = string.format("%s: %.1f%%", dotsLabel, bucketPct)
                    end
                end
            end

            EntryBuilder.addEntry(list, {
                label = bossName,
                sublabel = zenDetail(s),
                icon = StatIcons.DOT,
                header = isFirst and GetString(BATTLESCROLLS_HEADER_ZEN) or nil,
                tooltip = { type = "text", title = bossName, text = table.concat(tooltipLines, "\n") },
            })
            isFirst = false
        end
    end
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

        if encounter.procs and #encounter.procs > 0 then
            local isFirst = true
            for _, procData in ipairs(encounter.procs) do
                local abilityName = procDisplayName(procData)
                EntryBuilder.addEntry(list, {
                    label = abilityName,
                    sublabel = procDetail(procData),
                    icon = utils.getAbilityIcon(procData.abilityId),
                    frame = true,
                    header = isFirst and GetString(BATTLESCROLLS_HEADER_PROC_TRACKING) or nil,
                    tooltip = { type = "text", title = abilityName, text = buildProcTooltipText(procData, unitNames) },
                })
                isFirst = false
            end
        end
        LibEffect.Yield():Await()

        if encounter.ultimate then
            renderUltimateSection(list, encounter.ultimate, durationSec, encounter.effectsOnPlayer)
            LibEffect.Yield():Await()
        end

        if encounter.crux then
            renderCruxSection(list, encounter.crux)
            LibEffect.Yield():Await()
        end

        if encounter.resurrections and encounter.resurrections > 0 then
            local log = encounter.resurrectionLog
            EntryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_STAT_RESURRECTIONS),
                sublabel = tostring(encounter.resurrections),
                icon = StatIcons.GROUP,
                header = GetString(BATTLESCROLLS_HEADER_SUPPORT),
                tooltip = log and { type = "text", title = GetString(BATTLESCROLLS_STAT_RESURRECTIONS), text = buildResurrectionTooltip(log) } or nil,
            })
        end

        if encounter.zen then
            renderZenSection(list, encounter.zen, encounter)
            LibEffect.Yield():Await()
        end

        if weaving then
            local totalSum, totalCount = computeWeavingTotals(weaving)

            if totalCount > 0 then
                local avgMs = totalSum / totalCount
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_AVG_WEAVE_TIME),
                    sublabel = formatWeaveTime(avgMs),
                    icon = StatIcons.DURATION,
                    header = GetString(BATTLESCROLLS_HEADER_WEAVING),
                    tooltip = { type = "text", title = GetString(BATTLESCROLLS_STAT_AVG_WEAVE_TIME), text = buildCastDelayTooltip(avgMs, totalSum, totalCount) },
                })
            end

            if totalSum > 0 then
                local timeLostSec = totalSum / 1000
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_TIME_LOST),
                    sublabel = string.format("%s (%.1f%%)", formatSeconds(timeLostSec), durationSec > 0 and (timeLostSec / durationSec * 100) or 0),
                    icon = StatIcons.DURATION,
                    header = totalCount == 0 and GetString(BATTLESCROLLS_HEADER_WEAVING) or nil,
                    tooltip = { type = "text", title = GetString(BATTLESCROLLS_STAT_TIME_LOST), text = buildTimeLostTooltip(totalSum, durationSec) },
                })
            end

            if (weaving.downtimeGaps or 0) > 0 then
                local downtimeSec = weaving.downtimeMs / 1000
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_DOWNTIME),
                    sublabel = string.format("%s (%.1f%%)", formatSeconds(downtimeSec), durationSec > 0 and (downtimeSec / durationSec * 100) or 0),
                    icon = StatIcons.DURATION,
                    tooltip = { type = "text", title = GetString(BATTLESCROLLS_STAT_DOWNTIME), text = buildDowntimeTooltip(weaving.downtimeMs, weaving.downtimeGaps, durationSec) },
                })
            end

            if weaving.lightAttackHits > 0 then
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_LIGHT_ATTACKS),
                    sublabel = string.format("%d (%s)", weaving.lightAttackHits, formatPerMinute(weaving.lightAttackHits, durationSec)),
                    icon = StatIcons.DPS,
                })
            end

            if weaving.heavyAttackHits > 0 then
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_HEAVY_ATTACKS),
                    sublabel = string.format("%d (%s)", weaving.heavyAttackHits, formatPerMinute(weaving.heavyAttackHits, durationSec)),
                    icon = StatIcons.DPS,
                })
            end

            if weaving.skillActivations > 0 then
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_SKILL_ACTIVATIONS),
                    sublabel = tostring(weaving.skillActivations),
                    icon = StatIcons.SUMMARY,
                })
            end

            if weaving.totalWeavingErrors > 0 then
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_MISSED_LA),
                    sublabel = tostring(weaving.totalWeavingErrors),
                    icon = StatIcons.DAMAGE_TAKEN,
                    tooltip = { type = "text", title = GetString(BATTLESCROLLS_STAT_MISSED_LA), text = buildMissedLaTooltip(weaving.totalWeavingErrors, weaving.skillActivations) },
                })
            end

            if weaving.doubleLaErrors and weaving.doubleLaErrors > 0 then
                EntryBuilder.addEntry(list, {
                    label = GetString(BATTLESCROLLS_STAT_DOUBLE_LA),
                    sublabel = tostring(weaving.doubleLaErrors),
                    icon = StatIcons.DAMAGE_TAKEN,
                    tooltip = { type = "text", title = GetString(BATTLESCROLLS_STAT_DOUBLE_LA), text = buildDoubleLaTooltip(weaving.doubleLaErrors, weaving.lightAttackHits) },
                })
            end

            LibEffect.Yield():Await()

            if #weaving.byAbility > 0 then
                local totalActivations = weaving.skillActivations
                local isFirst = true
                local maxAbilities = 25
                for i, entry in ipairs(sortedWeavingAbilities(weaving)) do
                    if i > maxAbilities then break end
                    local abilityName = capitalized(utils.getAbilityDisplayName(entry.abilityId))
                    EntryBuilder.addEntry(list, {
                        label = abilityName,
                        sublabel = weavingAbilityDetail(entry),
                        icon = utils.getAbilityIcon(entry.abilityId),
                        frame = true,
                        header = isFirst and GetString(BATTLESCROLLS_HEADER_WEAVING_BY_ABILITY) or nil,
                        tooltip = { type = "text", title = abilityName, text = buildWeavingAbilityTooltipText(entry, totalActivations) },
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
---Left: weaving summary + per-ability weaving (present in nearly every fight)
---Middle: ultimate (summary, sources, casts) and Z'en per boss
---Right: procs, support and Crux
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, filters: table, abilityInfo: table }
---@return PanelSpec
function ActivityRenderer.buildActivityPanelSpec(ctx)
    return {
        layout = "three-equal",
        build = function(left, mid, right)
            local encounter = ctx.encounter
            local durationS = ctx.durationS
            local weaving = encounter.weaving

            -- mount() anchors from the column top on every call, so each
            -- column's sections must go through ONE call or they overlap
            local leftSections = {}

            if weaving then
                local totalSum, totalCount = computeWeavingTotals(weaving)
                local rows = {}

                if totalCount > 0 then
                    rows[#rows + 1] = left:StatRow(GetString(BATTLESCROLLS_STAT_AVG_WEAVE_TIME), formatWeaveTime(totalSum / totalCount))
                end
                if totalSum > 0 then
                    local timeLostSec = totalSum / 1000
                    rows[#rows + 1] = left:StatRow(GetString(BATTLESCROLLS_STAT_TIME_LOST),
                        string.format("%s (%.1f%%)", formatSeconds(timeLostSec), durationS > 0 and (timeLostSec / durationS * 100) or 0))
                end
                if (weaving.downtimeGaps or 0) > 0 then
                    local downtimeSec = weaving.downtimeMs / 1000
                    rows[#rows + 1] = left:StatRow(GetString(BATTLESCROLLS_STAT_DOWNTIME),
                        string.format("%s (%.1f%%)", formatSeconds(downtimeSec), durationS > 0 and (downtimeSec / durationS * 100) or 0))
                end
                if weaving.lightAttackHits > 0 then
                    rows[#rows + 1] = left:StatRow(GetString(BATTLESCROLLS_STAT_LIGHT_ATTACKS),
                        string.format("%d (%s)", weaving.lightAttackHits, formatPerMinute(weaving.lightAttackHits, durationS)))
                end
                if weaving.heavyAttackHits > 0 then
                    rows[#rows + 1] = left:StatRow(GetString(BATTLESCROLLS_STAT_HEAVY_ATTACKS),
                        string.format("%d (%s)", weaving.heavyAttackHits, formatPerMinute(weaving.heavyAttackHits, durationS)))
                end
                if weaving.skillActivations > 0 then
                    rows[#rows + 1] = left:StatRow(GetString(BATTLESCROLLS_STAT_SKILL_ACTIVATIONS), tostring(weaving.skillActivations))
                end
                if weaving.totalWeavingErrors > 0 then
                    rows[#rows + 1] = left:StatRow(GetString(BATTLESCROLLS_STAT_MISSED_LA), tostring(weaving.totalWeavingErrors))
                end
                if weaving.doubleLaErrors and weaving.doubleLaErrors > 0 then
                    rows[#rows + 1] = left:StatRow(GetString(BATTLESCROLLS_STAT_DOUBLE_LA), tostring(weaving.doubleLaErrors))
                end
                leftSections[#leftSections + 1] = left:Section(GetString(BATTLESCROLLS_HEADER_WEAVING), rows)

                if #weaving.byAbility > 0 then
                    local maxAbilities = left:maxItems(ROW_CONTENT.ICON_DETAIL_ROW, 6)
                    local abilityRows = {}
                    for i, entry in ipairs(sortedWeavingAbilities(weaving)) do
                        if i > maxAbilities then break end
                        abilityRows[#abilityRows + 1] = left:IconDetailRow(utils.getAbilityIcon(entry.abilityId),
                            capitalized(utils.getAbilityDisplayName(entry.abilityId)), weavingAbilityDetail(entry))
                    end
                    leftSections[#leftSections + 1] = left:Section(GetString(BATTLESCROLLS_HEADER_BY_ABILITY), abilityRows)
                end
            end

            if #leftSections > 0 then
                left:mount(SECTION_GAP, 0, unpack(leftSections))
            end

            LibEffect.Yield():Await()

            local midSections = {}

            local ult = encounter.ultimate
            if ult then
                local rows = {}
                rows[#rows + 1] = mid:StatRow(GetString(BATTLESCROLLS_STAT_ULT_AT_ENTRY), string.format("%d / %d", ult.startUlt, ult.maxUlt))
                if ult.totalGained > 0 then
                    rows[#rows + 1] = mid:StatRow(GetString(BATTLESCROLLS_STAT_ULT_GENERATED),
                        string.format("%d (%s)", ult.totalGained, formatRate(durationS > 0 and ult.totalGained / durationS or 0)))
                end
                local spend = computeUltSpend(ult)
                if spend.known then
                    rows[#rows + 1] = mid:StatRow(GetString(BATTLESCROLLS_STAT_ULT_SPENT), tostring(spend.spent))
                    if spend.lost > 0 then
                        rows[#rows + 1] = mid:StatRow(GetString(BATTLESCROLLS_STAT_ULT_LOST), tostring(spend.lost))
                    end
                end
                if spend.drained > 0 then
                    rows[#rows + 1] = mid:StatRow(GetString(spend.known and BATTLESCROLLS_STAT_ULT_DRAINED or BATTLESCROLLS_STAT_ULT_SPENT_DRAINED),
                        tostring(spend.drained))
                end

                midSections[#midSections + 1] = mid:Section(GetString(BATTLESCROLLS_HEADER_ULTIMATE), rows)

                local sources, gainTotal = collectUltSources(ult)
                local sourceRows = {}
                for _, source in ipairs(sources) do
                    local name, icon = ultSourceNameIcon(source.abilityId)
                    sourceRows[#sourceRows + 1] = mid:IconDetailRow(icon, name, ultSourceDetail(source, gainTotal, durationS), source.abilityId ~= 0)
                end
                midSections[#midSections + 1] = mid:Section(GetString(BATTLESCROLLS_OVERVIEW_SOURCES), sourceRows)

                local castRows = {}
                for _, group in ipairs(collectUltCasts(ult.casts)) do
                    castRows[#castRows + 1] = mid:IconDetailRow(utils.getAbilityIcon(group.abilityId),
                        capitalized(utils.getAbilityDisplayName(group.abilityId)), ultCastDetail(group, spend))
                end
                midSections[#midSections + 1] = mid:Section(GetString(BATTLESCROLLS_HEADER_CASTS), castRows)
            end

            if encounter.zen then
                local rows = {}
                for _, key in ipairs(sortedZenKeys(encounter.zen)) do
                    local s = computeZenSummary(encounter.zen[key])
                    if s.hasZen then
                        rows[#rows + 1] = mid:IconDetailRow(StatIcons.DOT, zenBossName(encounter, key), zenDetail(s), false)
                    end
                end
                midSections[#midSections + 1] = mid:Section(GetString(BATTLESCROLLS_HEADER_ZEN), rows)
            end

            if #midSections > 0 then
                mid:mount(SECTION_GAP, Q3_INSET, unpack(midSections))
            end

            LibEffect.Yield():Await()

            local rightSections = {}

            if encounter.procs and #encounter.procs > 0 then
                local maxProcs = right:maxItems(ROW_CONTENT.ICON_DETAIL_ROW, 6)
                local rows = {}
                for i, procData in ipairs(encounter.procs) do
                    if i > maxProcs then break end
                    rows[#rows + 1] = right:IconDetailRow(utils.getAbilityIcon(procData.abilityId), procDisplayName(procData), procDetail(procData))
                end
                rightSections[#rightSections + 1] = right:Section(GetString(BATTLESCROLLS_HEADER_PROC_TRACKING), rows)
            end

            if encounter.resurrections and encounter.resurrections > 0 then
                local rows = { right:StatRow(GetString(BATTLESCROLLS_STAT_RESURRECTIONS), tostring(encounter.resurrections)) }
                for _, target in ipairs(collectResurrectionTargets(encounter.resurrectionLog)) do
                    rows[#rows + 1] = right:IconStatRow(StatIcons.GROUP, target.displayName, string.format("%d×", target.count), false)
                end
                rightSections[#rightSections + 1] = right:Section(GetString(BATTLESCROLLS_HEADER_SUPPORT), rows)
            end

            local crux = encounter.crux
            if crux then
                local rows = {}
                if crux.generatorCasts > 0 then
                    rows[#rows + 1] = right:StatRow(GetString(BATTLESCROLLS_STAT_CRUX_GENERATORS), tostring(crux.generatorCasts))
                    rows[#rows + 1] = right:StatRow(GetString(BATTLESCROLLS_STAT_CRUX_AT_FULL), formatCountShare(crux.generatorAtFull, crux.generatorCasts))
                end
                if crux.spenderCasts > 0 then
                    rows[#rows + 1] = right:StatRow(GetString(BATTLESCROLLS_STAT_CRUX_SPENDERS), tostring(crux.spenderCasts))
                    rows[#rows + 1] = right:StatRow(GetString(BATTLESCROLLS_STAT_CRUX_UNDER), formatCountShare(cruxUnderTotal(crux), crux.spenderCasts))
                end
                local procWasted = cruxProcWastedTotal(crux)
                if procWasted > 0 then
                    rows[#rows + 1] = right:StatRow(GetString(BATTLESCROLLS_STAT_CRUX_PROC_WASTED), tostring(procWasted))
                end
                if (crux.deathEvents or 0) > 0 then
                    rows[#rows + 1] = right:StatRow(GetString(BATTLESCROLLS_STAT_CRUX_DEATH), tostring(crux.deathStacks))
                end
                if crux.passiveEvents > 0 then
                    rows[#rows + 1] = right:StatRow(GetString(BATTLESCROLLS_STAT_CRUX_PASSIVE), tostring(crux.passiveStacks))
                end

                rightSections[#rightSections + 1] = right:Section(GetString(BATTLESCROLLS_HEADER_CRUX), rows)

                local gainRows = {}
                for _, entry in ipairs(collectCruxGains(crux)) do
                    gainRows[#gainRows + 1] = right:IconDetailRow(utils.getAbilityIcon(entry.abilityId),
                        capitalized(utils.getAbilityDisplayName(entry.abilityId)), cruxGainDetail(entry))
                end
                if crux.unattributedGains > 0 then
                    gainRows[#gainRows + 1] = right:IconStatRow(StatIcons.DURATION, GetString(BATTLESCROLLS_STAT_CRUX_OTHER),
                        string.format("+%d", crux.unattributedGains), false)
                end
                rightSections[#rightSections + 1] = right:Section(GetString(BATTLESCROLLS_HEADER_BY_ABILITY), gainRows)
            end

            if #rightSections > 0 then
                right:mount(SECTION_GAP, 0, unpack(rightSections))
            end
        end,
    }
end

journal.renderers.activity = ActivityRenderer

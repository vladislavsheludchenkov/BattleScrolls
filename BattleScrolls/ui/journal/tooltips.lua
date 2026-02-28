-----------------------------------------------------------
-- Journal Tooltips
-- Group context tooltip builders for journal list entries
--
-- These build multi-line tooltip text for group damage/healing
-- breakdowns shown when hovering over list entries.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal

local tooltips = {}

---Formats a numeric value with "/s" suffix using localized string
---@param value number
---@return string
local function formatRate(value)
    return zo_strformat(GetString(BATTLESCROLLS_STAT_PER_SECOND), ZO_CommaDelimitNumber(value))
end

---Formats a display name for tooltip use
---@param displayName string The undecorated display name
---@return string
local function formatMemberDisplayName(displayName)
    return zo_strformat(SI_UNIT_NAME, displayName)
end

---Builds a tooltip for boss target rows showing group damage breakdown
---@param unitId number The boss unit ID
---@param encounter DecodedEncounter
---@param arithmancer ArithmancerInstance
---@param durationSec number
---@return string|nil tooltipTitle
---@return string|nil tooltipText
function tooltips.buildBossGroupTooltip(unitId, encounter, arithmancer, durationSec)
    if not encounter.sharedData or #encounter.sharedData < 2 or not encounter.bossTagSeqByUnitId then
        return nil, nil
    end

    local bossKey = encounter.bossTagSeqByUnitId[unitId]
    if not bossKey then
        return nil, nil
    end

    -- Get group total for this boss
    local groupBossTotals = arithmancer:groupDamageByBoss()
    local groupTotal = groupBossTotals[bossKey]
    if not groupTotal or groupTotal <= 0 then
        return nil, nil
    end

    local groupDps = durationSec > 0 and math.floor(groupTotal / durationSec) or 0

    -- Per-member breakdown from sharedData
    local myDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local members = {}
    for _, entry in ipairs(encounter.sharedData) do
        for _, bd in ipairs(entry.data.bossDamage or {}) do
            local key = bd.bossTag .. ":" .. bd.tagSeq
            if key == bossKey and bd.damage > 0 then
                table.insert(members, {
                    displayName = entry.displayName,
                    damage = bd.damage,
                    durationMs = entry.data.durationMs,
                    isSelf = entry.displayName == myDisplayName,
                })
            end
        end
    end
    table.sort(members, function(a, b)
        local aDps = a.durationMs > 0 and (a.damage / a.durationMs) or 0
        local bDps = b.durationMs > 0 and (b.damage / b.durationMs) or 0
        return aDps > bDps
    end)

    local lines = {}
    table.insert(lines, string.format("%s: %s", GetString(BATTLESCROLLS_TOOLTIP_GROUP_DPS), formatRate(groupDps)))

    if #members > 0 then
        table.insert(lines, "")
        table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_PER_MEMBER) .. ":")
        for _, m in ipairs(members) do
            local name = m.isSelf and GetString(BATTLESCROLLS_TOOLTIP_YOU) or formatMemberDisplayName(m.displayName)
            local memberDuration = m.durationMs / 1000
            local memberDps = memberDuration > 0 and math.floor(m.damage / memberDuration) or 0
            local pct = groupTotal > 0 and (m.damage / groupTotal * 100) or 0
            table.insert(lines, string.format("  %s: %s (%.1f%%)", name, formatRate(memberDps), pct))
        end
    end

    return GetString(BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN), table.concat(lines, "\n")
end

---Builds a tooltip for damage taken source rows showing group breakdown
---@param unitId number The source (boss) unit ID
---@param encounter DecodedEncounter
---@return string|nil tooltipTitle
---@return string|nil tooltipText
function tooltips.buildBossDamageTakenGroupTooltip(unitId, encounter)
    if not encounter.sharedData or #encounter.sharedData < 2 or not encounter.bossTagSeqByUnitId then
        return nil, nil
    end

    local bossKey = encounter.bossTagSeqByUnitId[unitId]
    if not bossKey then
        return nil, nil
    end

    local myDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local members = {}
    local groupTotal = 0
    for _, entry in ipairs(encounter.sharedData) do
        for _, bdt in ipairs(entry.data.bossDamageTaken or {}) do
            local key = bdt.bossTag .. ":" .. bdt.tagSeq
            if key == bossKey and bdt.damage > 0 then
                groupTotal = groupTotal + bdt.damage
                table.insert(members, {
                    displayName = entry.displayName,
                    damage = bdt.damage,
                    durationMs = entry.data.durationMs,
                    isSelf = entry.displayName == myDisplayName,
                })
            end
        end
    end

    if groupTotal <= 0 then
        return nil, nil
    end

    table.sort(members, function(a, b)
        local aDtps = a.durationMs > 0 and (a.damage / a.durationMs) or 0
        local bDtps = b.durationMs > 0 and (b.damage / b.durationMs) or 0
        return aDtps > bDtps
    end)

    local lines = {}
    for _, m in ipairs(members) do
        local name = m.isSelf and GetString(BATTLESCROLLS_TOOLTIP_YOU) or formatMemberDisplayName(m.displayName)
        local memberDuration = m.durationMs / 1000
        local memberDtps = memberDuration > 0 and math.floor(m.damage / memberDuration) or 0
        table.insert(lines, string.format("%s: %s", name, formatRate(memberDtps)))
    end

    return GetString(BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_TAKEN), table.concat(lines, "\n")
end

---Builds a group average tooltip for composition rows (DDs only).
---Excludes healers (HPS > DPS) and tanks (damage < 1/10th of top).
---@param sharedData SharedDataEntry[]|nil
---@param extractPercent fun(data: SharedEncounterData): number|nil
---@return string|nil tooltipTitle
---@return string|nil tooltipText
function tooltips.buildGroupAvgTooltip(sharedData, extractPercent)
    if not sharedData or #sharedData < 2 then
        return nil, nil
    end

    local topDamage = 0
    for _, entry in ipairs(sharedData) do
        if entry.data.totalDamage > topDamage then
            topDamage = entry.data.totalDamage
        end
    end

    local sum = 0
    local count = 0
    for _, entry in ipairs(sharedData) do
        local data = entry.data
        local isDD = true
        if data.healing and data.healing.rawOut > data.totalDamage then
            isDD = false
        end
        if data.totalDamage < topDamage / 10 then
            isDD = false
        end
        if isDD then
            local pct = extractPercent(data)
            if pct then
                sum = sum + pct
                count = count + 1
            end
        end
    end

    if count == 0 then
        return nil, nil
    end

    local avg = sum / count
    return nil, string.format("%s: %.1f%%", GetString(BATTLESCROLLS_TOOLTIP_GROUP_AVG), avg)
end

---Builds a group healing tooltip for healing summary rows
---@param encounter DecodedEncounter
---@param effective boolean If true, show effective HPS; else show raw HPS
---@return string|nil tooltipTitle
---@return string|nil tooltipText
function tooltips.buildHealingGroupTooltip(encounter, effective)
    if not encounter.sharedData or #encounter.sharedData < 2 then
        return nil, nil
    end

    local myDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local members = {}

    for _, entry in ipairs(encounter.sharedData) do
        local healing = entry.data.healing
        if healing then
            local memberDuration = entry.data.durationMs / 1000
            local value = effective and healing.effectiveOut or healing.rawOut
            local hps = memberDuration > 0 and math.floor(value / memberDuration) or 0
            table.insert(members, {
                displayName = entry.displayName,
                hps = hps,
                isSelf = entry.displayName == myDisplayName,
            })
        end
    end

    if #members == 0 then
        return nil, nil
    end

    table.sort(members, function(a, b) return a.hps > b.hps end)

    local lines = {}
    table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_PER_MEMBER) .. ":")
    for _, m in ipairs(members) do
        local name = m.isSelf and GetString(BATTLESCROLLS_TOOLTIP_YOU) or formatMemberDisplayName(m.displayName)
        table.insert(lines, string.format("  %s: %s", name, formatRate(m.hps)))
    end

    return GetString(BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN), table.concat(lines, "\n")
end

---Builds a group DPS tooltip showing per-member DPS
---@param encounter DecodedEncounter
---@param bossOnly boolean If true, sum bossDamage; else use totalDamage
---@return string|nil tooltipTitle
---@return string|nil tooltipText
function tooltips.buildGroupDpsTooltip(encounter, bossOnly)
    if not encounter.sharedData or #encounter.sharedData < 2 then
        return nil, nil
    end

    local myDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local members = {}
    for _, entry in ipairs(encounter.sharedData) do
        local damage
        if bossOnly then
            damage = 0
            for _, bd in ipairs(entry.data.bossDamage or {}) do
                damage = damage + bd.damage
            end
        else
            damage = entry.data.totalDamage
        end
        if damage > 0 then
            local memberDuration = entry.data.durationMs / 1000
            local memberDps = memberDuration > 0 and math.floor(damage / memberDuration) or 0
            table.insert(members, {
                displayName = entry.displayName,
                dps = memberDps,
                isSelf = entry.displayName == myDisplayName,
            })
        end
    end

    if #members == 0 then
        return nil, nil
    end

    table.sort(members, function(a, b) return a.dps > b.dps end)

    local lines = {}
    table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_PER_MEMBER) .. ":")
    for _, m in ipairs(members) do
        local name = m.isSelf and GetString(BATTLESCROLLS_TOOLTIP_YOU) or formatMemberDisplayName(m.displayName)
        table.insert(lines, string.format("  %s: %s", name, formatRate(m.dps)))
    end

    return GetString(BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN), table.concat(lines, "\n")
end

---Builds a group DTPS tooltip showing per-member DTPS
---@param encounter DecodedEncounter
---@return string|nil tooltipTitle
---@return string|nil tooltipText
function tooltips.buildGroupDtpsTooltip(encounter)
    if not encounter.sharedData or #encounter.sharedData < 2 then
        return nil, nil
    end

    local myDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local members = {}
    for _, entry in ipairs(encounter.sharedData) do
        local damageTaken = entry.data.totalDamageTaken or 0
        if damageTaken > 0 then
            local memberDuration = entry.data.durationMs / 1000
            local memberDtps = memberDuration > 0 and math.floor(damageTaken / memberDuration) or 0
            table.insert(members, {
                displayName = entry.displayName,
                dtps = memberDtps,
                isSelf = entry.displayName == myDisplayName,
            })
        end
    end

    if #members == 0 then
        return nil, nil
    end

    table.sort(members, function(a, b) return a.dtps > b.dtps end)

    local lines = {}
    table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_PER_MEMBER) .. ":")
    for _, m in ipairs(members) do
        local name = m.isSelf and GetString(BATTLESCROLLS_TOOLTIP_YOU) or formatMemberDisplayName(m.displayName)
        table.insert(lines, string.format("  %s: %s", name, formatRate(m.dtps)))
    end

    return GetString(BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN), table.concat(lines, "\n")
end

---Builds a group overheal tooltip showing per-member overheal %
---@param encounter DecodedEncounter
---@return string|nil tooltipTitle
---@return string|nil tooltipText
function tooltips.buildGroupOverhealTooltip(encounter)
    if not encounter.sharedData or #encounter.sharedData < 2 then
        return nil, nil
    end

    local myDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local members = {}
    for _, entry in ipairs(encounter.sharedData) do
        local healing = entry.data.healing
        if healing and healing.rawOut > 0 then
            local overheal = healing.rawOut - healing.effectiveOut
            local overhealPct = overheal / healing.rawOut * 100
            table.insert(members, {
                displayName = entry.displayName,
                overhealPct = overhealPct,
                isSelf = entry.displayName == myDisplayName,
            })
        end
    end

    if #members == 0 then
        return nil, nil
    end

    table.sort(members, function(a, b) return a.overhealPct > b.overhealPct end)

    local lines = {}
    table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_PER_MEMBER) .. ":")
    for _, m in ipairs(members) do
        local name = m.isSelf and GetString(BATTLESCROLLS_TOOLTIP_YOU) or formatMemberDisplayName(m.displayName)
        table.insert(lines, string.format("  %s: %.1f%%", name, m.overhealPct))
    end

    return GetString(BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN), table.concat(lines, "\n")
end

---Builds a self-healing overheal tooltip showing per-member self-healing overheal %
---@param encounter DecodedEncounter
---@return string|nil tooltipTitle
---@return string|nil tooltipText
function tooltips.buildSelfHealingOverhealTooltip(encounter)
    if not encounter.sharedData or #encounter.sharedData < 2 then
        return nil, nil
    end

    local myDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local members = {}
    for _, entry in ipairs(encounter.sharedData) do
        local healing = entry.data.healing
        if healing and healing.rawSelf and healing.rawSelf > 0 then
            local overheal = healing.rawSelf - healing.effectiveSelf
            local overhealPct = overheal / healing.rawSelf * 100
            table.insert(members, {
                displayName = entry.displayName,
                overhealPct = overhealPct,
                isSelf = entry.displayName == myDisplayName,
            })
        end
    end

    if #members == 0 then
        return nil, nil
    end

    table.sort(members, function(a, b) return a.overhealPct > b.overhealPct end)

    local lines = {}
    table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_PER_MEMBER) .. ":")
    for _, m in ipairs(members) do
        local name = m.isSelf and GetString(BATTLESCROLLS_TOOLTIP_YOU) or formatMemberDisplayName(m.displayName)
        table.insert(lines, string.format("  %s: %.1f%%", name, m.overhealPct))
    end

    return GetString(BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN), table.concat(lines, "\n")
end

---Builds a self-healing group tooltip showing per-member self-healing HPS
---@param encounter DecodedEncounter
---@param effective boolean If true, show effective HPS; else show raw HPS
---@return string|nil tooltipTitle
---@return string|nil tooltipText
function tooltips.buildSelfHealingGroupTooltip(encounter, effective)
    if not encounter.sharedData or #encounter.sharedData < 2 then
        return nil, nil
    end

    local myDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local members = {}
    for _, entry in ipairs(encounter.sharedData) do
        local healing = entry.data.healing
        if healing and healing.rawSelf and healing.rawSelf > 0 then
            local memberDuration = entry.data.durationMs / 1000
            local value = effective and healing.effectiveSelf or healing.rawSelf
            local hps = memberDuration > 0 and math.floor(value / memberDuration) or 0
            table.insert(members, {
                displayName = entry.displayName,
                hps = hps,
                isSelf = entry.displayName == myDisplayName,
            })
        end
    end

    if #members == 0 then
        return nil, nil
    end

    table.sort(members, function(a, b) return a.hps > b.hps end)

    local lines = {}
    table.insert(lines, GetString(BATTLESCROLLS_TOOLTIP_PER_MEMBER) .. ":")
    for _, m in ipairs(members) do
        local name = m.isSelf and GetString(BATTLESCROLLS_TOOLTIP_YOU) or formatMemberDisplayName(m.displayName)
        table.insert(lines, string.format("  %s: %s", name, formatRate(m.hps)))
    end

    return GetString(BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN), table.concat(lines, "\n")
end

-- Export to namespace
journal.tooltips = tooltips

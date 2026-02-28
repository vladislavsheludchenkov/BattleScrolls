-----------------------------------------------------------
-- Group Renderer
-- Renders the Group tab showing shared encounter data from
-- group members with comparison views.
--
-- All functions are stateless - context comes from parameters.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local utils = journal.utils

local GroupRenderer = {}

-------------------------
-- Internal Helpers
-------------------------

---Computes DPS from damage and duration
---@param damage number
---@param durationMs number
---@return number dps
local function computeDPS(damage, durationMs)
    local durationS = durationMs / 1000
    if durationS <= 0 then return 0 end
    return damage / durationS
end

---Computes boss DPS from a SharedEncounterData's bossDamage array
---@param sharedData SharedEncounterData
---@return number bossDPS
local function computeBossDPS(sharedData)
    if not sharedData.bossDamage or #sharedData.bossDamage == 0 then
        return 0
    end
    local totalBossDamage = 0
    for _, bd in ipairs(sharedData.bossDamage) do
        totalBossDamage = totalBossDamage + bd.damage
    end
    return computeDPS(totalBossDamage, sharedData.durationMs)
end

---Builds a SharedEncounterData-compatible table for the local player
---from the encounter's own data using the arithmancer.
---@param ctx JournalRenderContext
---@return SharedEncounterData|nil localData
---@return string|nil localDisplayName
local function buildLocalPlayerData(ctx)
    local arithmancer = ctx.arithmancer
    if not arithmancer then return nil, nil end

    local localDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local localData = arithmancer:buildSharedEncounterData()
    return localData, localDisplayName
end

---Determines if there are any bosses across all shared data entries
---@param memberList { displayName: string, data: SharedEncounterData, isLocal: boolean }[]
---@return boolean hasBosses
local function hasBossData(memberList)
    for _, member in ipairs(memberList) do
        if member.data.bossDamage and #member.data.bossDamage > 0 then
            return true
        end
    end
    return false
end

---Computes the sort key for a member (boss DPS if bosses present, else total DPS)
---@param data SharedEncounterData
---@param useBossDPS boolean
---@return number sortKey
local function computeSortKey(data, useBossDPS)
    if useBossDPS then
        return computeBossDPS(data)
    end
    return computeDPS(data.totalDamage, data.durationMs)
end

---Builds and sorts the member list from shared data + local player
---@param ctx JournalRenderContext
---@return { displayName: string, data: SharedEncounterData, isLocal: boolean, sortKey: number }[]
local function buildMemberList(ctx)
    local enc = ctx.encounter
    local sharedData = enc.sharedData
    local members = {}
    local localDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()
    local localAlreadyPresent = false

    -- Add shared data entries
    if sharedData then
        for _, entry in ipairs(sharedData) do
            local isLocal = entry.displayName == localDisplayName
            if isLocal then
                localAlreadyPresent = true
            end
            table.insert(members, {
                displayName = entry.displayName,
                data = entry.data,
                isLocal = isLocal,
                role = entry.role,
            })
        end
    end

    -- Add local player if not already in shared data
    if not localAlreadyPresent then
        local localData, localName = buildLocalPlayerData(ctx)
        if localData and localName then
            table.insert(members, {
                displayName = localName,
                data = localData,
                isLocal = true,
                role = BattleScrolls.utils.getUnitRole("player"),
            })
        end
    end

    -- Determine sort mode and compute sort keys
    local useBossDPS = hasBossData(members)
    for _, member in ipairs(members) do
        member.sortKey = computeSortKey(member.data, useBossDPS)
    end

    -- Sort by sort key descending (highest DPS first)
    table.sort(members, function(a, b)
        return a.sortKey > b.sortKey
    end)

    return members
end

---Determines if a member is primarily a healer (HPS > DPS)
---@param data SharedEncounterData
---@return boolean isHealer
local function isHealer(data)
    if not data.healing or data.durationMs <= 0 then return false end
    return data.healing.rawOut > data.totalDamage
end

---Resolves a boss name from bossSeqNames using tag and seq
---@param bossSeqNames table<string, string>|nil
---@param bossTag string
---@param tagSeq number
---@return string bossName
local function resolveBossName(bossSeqNames, bossTag, tagSeq)
    if bossSeqNames then
        local key = string.format("%s:%d", bossTag, tagSeq)
        local name = bossSeqNames[key]
        if name then
            return zo_strformat(SI_UNIT_NAME, name)
        end
    end
    return zo_strformat(SI_UNIT_NAME, bossTag)
end

---Computes group average DPS across the top damage dealers.
---Stops at the first healer (HPS > DPS) or tank (damage < 1/10th of top).
---Members MUST be sorted by DPS descending.
---@param members { displayName: string, data: SharedEncounterData }[]
---@param useBossDPS boolean
---@return number averageDPS
---@return number ddCount
local function computeGroupAverageDPS(members, useBossDPS)
    if #members == 0 then return 0, 0 end

    local topDamage = 0
    for _, member in ipairs(members) do
        if member.data.totalDamage > topDamage then
            topDamage = member.data.totalDamage
        end
    end

    local total = 0
    local count = 0
    for _, member in ipairs(members) do
        if isHealer(member.data) or member.data.totalDamage < topDamage / 10 then
            break
        end
        local dps
        if useBossDPS then
            dps = computeBossDPS(member.data)
        else
            dps = computeDPS(member.data.totalDamage, member.data.durationMs)
        end
        total = total + dps
        count = count + 1
    end

    if count == 0 then return 0, 0 end
    return total / count, count
end

---Finds a member's DPS rank in the sorted list (1-indexed)
---@param members { displayName: string, data: SharedEncounterData, sortKey: number }[]
---@param targetName string
---@return number rank
local function findMemberRank(members, targetName)
    for i, member in ipairs(members) do
        if member.displayName == targetName then
            return i
        end
    end
    return #members
end

-------------------------
-- Public Renderer API
-------------------------

---Renders the Group tab list (Q1 parametric list)
---@param ctx JournalRenderContext
---@return Effect
function GroupRenderer.renderGroup(ctx)
    return LibEffect.Sync(function()
        local list = ctx.list
        local enc = ctx.encounter

        -- Must have shared data or enough data to show local player
        if not enc.sharedData and not ctx.arithmancer then
            return
        end

        local members = buildMemberList(ctx)
        if #members == 0 then
            return
        end

        local useBossDPS = hasBossData(members)

        for _, member in ipairs(members) do
            local data = member.data
            local dps
            if useBossDPS then
                dps = computeBossDPS(data)
            else
                dps = computeDPS(data.totalDamage, data.durationMs)
            end

            -- Build role-differentiated sublabel
            local metrics = {}
            local memberIsHealer = isHealer(data)

            if memberIsHealer then
                -- Healer: "HPS | Overheal% | DTPS"
                local durationS = data.durationMs / 1000
                if durationS <= 0 then durationS = 1 end
                local hps = data.healing.rawOut / durationS
                table.insert(metrics, zo_strformat(GetString(BATTLESCROLLS_GROUP_METRIC_HPS), utils.formatCompact(hps)))
                if data.healing.rawOut > 0 then
                    local overhealPercent = (data.healing.rawOut - data.healing.effectiveOut) / data.healing.rawOut * 100
                    table.insert(metrics, zo_strformat(GetString(BATTLESCROLLS_GROUP_METRIC_OVERHEAL), string.format("%.0f", overhealPercent)))
                end
            else
                -- DPS: "DPS | Crit% | DTPS"
                table.insert(metrics, zo_strformat(GetString(BATTLESCROLLS_GROUP_METRIC_DPS), utils.formatCompact(dps)))
                if data.critPercent and data.critPercent > 0 then
                    table.insert(metrics, zo_strformat(GetString(BATTLESCROLLS_GROUP_METRIC_CRIT), string.format("%.0f", data.critPercent * 100)))
                end
            end

            -- DTPS (both roles)
            if data.totalDamageTaken and data.totalDamageTaken > 0 then
                local dtps = computeDPS(data.totalDamageTaken, data.durationMs)
                table.insert(metrics, zo_strformat(GetString(BATTLESCROLLS_GROUP_METRIC_DTPS), utils.formatCompact(dtps)))
            end

            -- Death count
            if data.deaths then
                table.insert(metrics, zo_strformat(GetString(BATTLESCROLLS_GROUP_DEATH_COUNT), data.deaths.deathCount))
            end

            local sublabel = table.concat(metrics, "  ·  ")

            local roleIcon = BattleScrolls.utils.GetRoleIcon(member.role or LFG_ROLE_DPS)
            local entryData = ZO_GamepadEntryData:New(member.displayName, roleIcon)
            entryData:SetIconTintOnSelection(true)
            entryData:AddSubLabel(sublabel)
            entryData.isOverviewEntry = false
            entryData.groupPlayerData = data
            entryData.groupPlayerName = member.displayName
            entryData.groupIsLocalPlayer = member.isLocal

            list:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
        end
    end)
end

-------------------------
-- Overview Panel: Player Detail
-------------------------

---Renders the overview panel when a player entry is selected
---Q2: Performance stats, Q3: Boss damage bars with per-boss metrics, Q4: Survivability + Damage by type + vs DD average
---@param panel BattleScrolls_Journal_OverviewPanel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, abilityInfo: table, filters: table }
---@param data SharedEncounterData
---@param playerName string Display name of the player
---@param members { displayName: string, data: SharedEncounterData, isLocal: boolean, sortKey: number }[]
---@return Effect
local function refreshPanelForPlayerEntry(panel, ctx, data, playerName, members)
    return LibEffect.Async(function()
        local enc = ctx.encounter
        local bossSeqNames = enc.bossSeqNames
        local durationS = data.durationMs / 1000
        if durationS <= 0 then durationS = 1 end
        local useBossDPS = hasBossData(members)
        local memberCount = #members

        -- =====================
        -- Q2: Damage Output → vs DD Average → Survivability → Healing Output
        -- =====================
        local lastControl = nil

        -- Damage Output section
        local dps = data.totalDamage / durationS
        lastControl = panel:AddSection(GetString(BATTLESCROLLS_GROUP_DAMAGE_OUTPUT), lastControl)
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_STAT_DPS), utils.formatCompact(dps), lastControl)
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_STAT_TOTAL_DAMAGE), utils.formatNumber(data.totalDamage), lastControl)

        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE),
            string.format("%.1f%%", (data.critPercent or 0) * 100), lastControl)
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HIT),
            utils.formatCompact(data.maxHit or 0), lastControl)

        -- Composition (DoT% / AoE%)
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_DIRECT),
            string.format("%.0f%%", (1 - (data.dotPercent or 0)) * 100), lastControl)
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_AOE),
            string.format("%.0f%%", (data.aoePercent or 0) * 100), lastControl)

        -- Rank
        if memberCount > 1 then
            local rank = findMemberRank(members, playerName)
            lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_GROUP_RANK),
                string.format("#%d / %d", rank, memberCount), lastControl)
        end

        LibEffect.Yield():Await()

        -- vs DD Average section (evaluative context for the DPS number above)
        if memberCount > 1 then
            local avgDPS, ddCount = computeGroupAverageDPS(members, useBossDPS)
            local playerDPS
            if useBossDPS then
                playerDPS = computeBossDPS(data)
            else
                playerDPS = data.totalDamage / durationS
            end

            if avgDPS > 0 then
                lastControl = panel:AddSection(GetString(BATTLESCROLLS_GROUP_VS_AVERAGE), lastControl)
                local vsPercent = (playerDPS / avgDPS * 100) - 100
                local vsStr
                if vsPercent >= 0 then
                    vsStr = string.format("+%.0f%%", vsPercent)
                else
                    vsStr = string.format("%.0f%%", vsPercent)
                end
                lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_STAT_DPS),
                    vsStr, lastControl)
                lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_GROUP_DD_COUNTED),
                    tostring(ddCount), lastControl)
            end
        end

        -- Survivability section
        lastControl = panel:AddSection(GetString(BATTLESCROLLS_STAT_SURVIVABILITY), lastControl)
        local totalDamageTakenQ2 = data.totalDamageTaken or 0
        local dtps = totalDamageTakenQ2 / durationS
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_STAT_DTPS),
            utils.formatCompact(dtps), lastControl)
        local aliveTimeMs = data.aliveTimeMs or data.durationMs
        local alivePercent = data.durationMs > 0 and (aliveTimeMs / data.durationMs * 100) or 100
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_GROUP_CARD_ALIVE),
            string.format("%.0f%% (%s)", alivePercent, utils.formatDuration(aliveTimeMs)),
            lastControl)
        if data.deaths then
            lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_GROUP_DEATHS),
                tostring(data.deaths.deathCount), lastControl)
        end

        LibEffect.Yield():Await()

        -- Healing Output section (shown for everyone)
        if data.healing then
            local h = data.healing
            if h.rawOut > 0 or h.rawSelf > 0 then
                lastControl = panel:AddSection(GetString(BATTLESCROLLS_GROUP_HEALING_OUTPUT), lastControl)

                if h.rawOut > 0 then
                    local rawHps = h.rawOut / durationS
                    local effHps = h.effectiveOut / durationS
                    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_HEALING_RAW_HPS),
                        utils.formatCompact(rawHps), lastControl)
                    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_HEALING_EFFECTIVE_HPS),
                        utils.formatCompact(effHps), lastControl)
                    local overhealPercent = h.rawOut > 0 and ((h.rawOut - h.effectiveOut) / h.rawOut * 100) or 0
                    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_HEALING_OVERHEAL),
                        string.format("%.0f%%", overhealPercent), lastControl)
                end

                if h.rawSelf > 0 then
                    local selfHps = h.rawSelf / durationS
                    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_SELF_HEALING),
                        string.format("%s HPS", utils.formatCompact(selfHps)), lastControl)
                end
            end
        end

        LibEffect.Yield():Await()

        -- =====================
        -- Q3: Boss Damage Bars with Per-Boss Metrics
        -- =====================


        -- Boss Damage section
        local q3Control = nil
        if data.bossDamage and #data.bossDamage > 0 then
            q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_OVERVIEW_BOSS_DAMAGE), q3Control)

            -- Per-boss group totals from encounter data (captures all group members)
            local groupBossTotals = ctx.arithmancer:groupDamageByBoss()

            local sorted = {}
            for _, bd in ipairs(data.bossDamage) do
                table.insert(sorted, bd)
            end
            table.sort(sorted, function(a, b) return a.damage > b.damage end)

            local topValue = sorted[1].damage
            if topValue <= 0 then topValue = 1 end

            for _, bd in ipairs(sorted) do
                local bossName = resolveBossName(bossSeqNames, bd.bossTag, bd.tagSeq)

                -- Group share
                local bossKey = string.format("%s:%d", bd.bossTag, bd.tagSeq)
                local groupTotal = groupBossTotals[bossKey] or 0
                local groupShare = groupTotal > 0 and (bd.damage / groupTotal * 100) or 0

                -- Stats line: total + breakdown
                local statParts = {}
                local bossDPS = durationS > 0 and (bd.damage / durationS) or 0
                table.insert(statParts, utils.formatCompact(bd.damage))
                if bd.critPercent and bd.critPercent > 0 then
                    table.insert(statParts, string.format("%.0f%% Crit", bd.critPercent * 100))
                end
                local bdDirectPercent = 1 - (bd.dotPercent or 0)
                if bdDirectPercent > 0 and bdDirectPercent < 1 then
                    table.insert(statParts, string.format("%.0f%% %s", bdDirectPercent * 100, GetString(BATTLESCROLLS_DELIVERY_DIRECT)))
                end
                if bd.aoePercent and bd.aoePercent > 0 then
                    table.insert(statParts,
                        string.format("%.0f%% %s", bd.aoePercent * 100, GetString(BATTLESCROLLS_AOE)))
                end
                if bd.magicalPercent and bd.magicalPercent > 0 then
                    table.insert(statParts,
                        string.format("%.0f%% %s", bd.magicalPercent * 100, GetString(BATTLESCROLLS_GROUP_MAGICAL)))
                end

                q3Control = panel:AddGroupMemberCard({
                    displayName = bossName,
                    primaryLabel = string.format("%s DPS", utils.formatCompact(bossDPS)),
                    barPercent = topValue > 0 and (bd.damage / topValue * 100) or 0,
                    shareText = string.format("%.1f%% %s", groupShare, GetString(BATTLESCROLLS_GROUP_CARD_OF_GROUP)),
                    infoLine = table.concat(statParts, " · "),
                }, q3Control)
            end
        end

        LibEffect.Yield():Await()

        -- Boss Damage Taken section
        if data.bossDamageTaken and #data.bossDamageTaken > 0 then
            q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_BOSS_DAMAGE_TAKEN), q3Control)

            local sorted = {}
            for _, bt in ipairs(data.bossDamageTaken) do
                table.insert(sorted, bt)
            end
            table.sort(sorted, function(a, b) return a.damage > b.damage end)

            local topValue = sorted[1].damage
            if topValue <= 0 then topValue = 1 end
            local totalDamageTaken = data.totalDamageTaken or sorted[1].damage

            for _, bt in ipairs(sorted) do
                local bossName = resolveBossName(bossSeqNames, bt.bossTag, bt.tagSeq)
                local sharePercent = totalDamageTaken > 0 and (bt.damage / totalDamageTaken * 100) or 0
                local bossDPS = durationS > 0 and (bt.damage / durationS) or 0

                q3Control = panel:AddGroupMemberCard({
                    displayName = bossName,
                    primaryLabel = string.format("%s DPS", utils.formatCompact(bossDPS)),
                    barPercent = topValue > 0 and (bt.damage / topValue * 100) or 0,
                    shareText = string.format("%.1f%%", sharePercent),
                    infoLine = utils.formatCompact(bt.damage),
                }, q3Control)
            end
        end

        -- Death Recaps (section header with timing + attack rows)
        if data.deaths then
            if data.deaths.first then
                local hasMultiple = data.deaths.last ~= nil
                q3Control = panel:AddQ3Section(GetString(hasMultiple and BATTLESCROLLS_GROUP_FIRST_DEATH or BATTLESCROLLS_GROUP_DEATH), q3Control)
                panel:SetQ3SectionTiming(q3Control,
                    zo_strformat(GetString(BATTLESCROLLS_GROUP_DEATH_AT), utils.formatDuration(data.deaths.first.timeOffsetMs)))
                local firstAttacks = data.deaths.first.attacks
                for i, attack in ipairs(firstAttacks) do
                    q3Control = panel:AddDeathAttackRow(attack, q3Control, i == #firstAttacks)
                end
            end
            if data.deaths.last then
                q3Control = panel:AddQ3Section(GetString(BATTLESCROLLS_GROUP_LAST_DEATH), q3Control)
                panel:SetQ3SectionTiming(q3Control,
                    zo_strformat(GetString(BATTLESCROLLS_GROUP_DEATH_AT), utils.formatDuration(data.deaths.last.timeOffsetMs)))
                local lastAttacks = data.deaths.last.attacks
                for i, attack in ipairs(lastAttacks) do
                    q3Control = panel:AddDeathAttackRow(attack, q3Control, i == #lastAttacks)
                end
            end
        end

        -- Collapse Q3 if no boss data or death recaps were rendered
        if not q3Control then
            panel:SetQ3Hidden(true)
        end

        LibEffect.Yield():Await()

        -- =====================
        -- Q4: Damage by Type + Top Incoming Damage
        -- =====================
        local q4Control = nil

        -- Damage by Type (no cap — Q4 scrolls)
        if data.damageByType and #data.damageByType > 0 then
            q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_GROUP_DAMAGE_BY_TYPE), q4Control)

            local sortedTypes = {}
            local totalTypeDamage = 0
            for _, dbt in ipairs(data.damageByType) do
                table.insert(sortedTypes, dbt)
                totalTypeDamage = totalTypeDamage + dbt.damage
            end
            table.sort(sortedTypes, function(a, b) return a.damage > b.damage end)

            for _, entry in ipairs(sortedTypes) do
                local typeName = utils.getDamageTypeName(entry.type)
                local percent = totalTypeDamage > 0 and (entry.damage / totalTypeDamage * 100) or 0
                q4Control = panel:AddTargetRow(typeName,
                    string.format("%.0f%%", percent),
                    q4Control)
            end
        end

        -- Top Incoming Damage
        if data.topDamageTakenAbilities and #data.topDamageTakenAbilities > 0 then
            q4Control = panel:AddQ4Section(GetString(BATTLESCROLLS_GROUP_TOP_INCOMING_DAMAGE), q4Control)

            for _, entry in ipairs(data.topDamageTakenAbilities) do
                local abilityName = utils.getAbilityDisplayName(entry.abilityId)
                q4Control = panel:AddTargetRow(abilityName,
                    string.format("%.0f%%", entry.damagePercent * 100),
                    q4Control)
            end
        end
    end)
end

---Refreshes the overview panel for a selected group player
---@param panel BattleScrolls_Journal_OverviewPanel
---@param ctx { arithmancer: table, encounter: table, durationS: number, unitNames: table, abilityInfo: table, filters: table, selectedListData: table|nil }
---@return Effect
function GroupRenderer.refreshPanelForGroupPlayer(panel, ctx)
    return LibEffect.Async(function()
        local members = buildMemberList(ctx)
        if #members == 0 then
            return
        end

        local selectedData = ctx.selectedListData
        local playerName = selectedData.groupPlayerName or "Unknown"
        refreshPanelForPlayerEntry(panel, ctx, selectedData.groupPlayerData, playerName, members):Await()
    end)
end

---Exposes the member list builder for use by the group table
---@param ctx JournalRenderContext
---@return { displayName: string, data: SharedEncounterData, isLocal: boolean, sortKey: number }[]
function GroupRenderer.buildMemberList(ctx)
    return buildMemberList(ctx)
end

-- Export to namespace
journal.renderers.group = GroupRenderer

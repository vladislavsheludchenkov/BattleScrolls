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
-- Overview Panel: Player Detail
-------------------------

---Renders the overview panel columns for a group player entry.
---Called from inside an Async context (via panelSpec.build), so yields work normally.
---@param q2 ColumnBuilder
---@param q3 ColumnBuilder
---@param q4 ColumnBuilder
---@param ctx table
---@param data SharedEncounterData
---@param playerName string
---@param members table[]
local function buildGroupPlayerPanel(q2, q3, q4, ctx, data, playerName, members)
    local enc = ctx.encounter
    local bossSeqNames = enc.bossSeqNames
    local durationS = data.durationMs / 1000
    if durationS <= 0 then durationS = 1 end
    local useBossDPS = hasBossData(members)
    local memberCount = #members

    -- =====================
    -- Q2: Damage Output -> vs DD Average -> Survivability -> Healing Output
    -- =====================
    local col2 = q2

    -- Damage Output section
    local dps = data.totalDamage / durationS
    local damageRows = {
        col2:StatRow(GetString(BATTLESCROLLS_STAT_DPS), utils.formatCompact(dps)),
        col2:StatRow(GetString(BATTLESCROLLS_STAT_TOTAL_DAMAGE), utils.formatNumber(data.totalDamage)),
        col2:StatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE),
            string.format("%.1f%%", (data.critPercent or 0) * 100)),
        col2:StatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HIT),
            utils.formatCompact(data.maxHit or 0)),
        col2:StatRow(GetString(BATTLESCROLLS_DELIVERY_DIRECT),
            string.format("%.0f%%", (1 - (data.dotPercent or 0)) * 100)),
        col2:StatRow(GetString(BATTLESCROLLS_AOE),
            string.format("%.0f%%", (data.aoePercent or 0) * 100)),
    }
    if memberCount > 1 then
        local rank = findMemberRank(members, playerName)
        table.insert(damageRows, col2:StatRow(GetString(BATTLESCROLLS_GROUP_RANK),
            string.format("#%d / %d", rank, memberCount)))
    end
    local damageSection = col2:Section(GetString(BATTLESCROLLS_GROUP_DAMAGE_OUTPUT), unpack(damageRows))

    LibEffect.Yield():Await()

    -- vs DD Average section (evaluative context for the DPS number above)
    local vsAverageSection
    if memberCount > 1 then
        local avgDPS, ddCount = computeGroupAverageDPS(members, useBossDPS)
        local playerDPS
        if useBossDPS then
            playerDPS = computeBossDPS(data)
        else
            playerDPS = data.totalDamage / durationS
        end

        if avgDPS > 0 then
            local vsPercent = (playerDPS / avgDPS * 100) - 100
            local vsStr
            if vsPercent >= 0 then
                vsStr = string.format("+%.0f%%", vsPercent)
            else
                vsStr = string.format("%.0f%%", vsPercent)
            end
            vsAverageSection = col2:Section(GetString(BATTLESCROLLS_GROUP_VS_AVERAGE),
                col2:StatRow(GetString(BATTLESCROLLS_STAT_DPS), vsStr),
                col2:StatRow(GetString(BATTLESCROLLS_GROUP_DD_COUNTED), tostring(ddCount)))
        end
    end

    -- Survivability section
    local totalDamageTakenQ2 = data.totalDamageTaken or 0
    local dtps = totalDamageTakenQ2 / durationS
    local aliveTimeMs = data.aliveTimeMs or data.durationMs
    local alivePercent = data.durationMs > 0 and (aliveTimeMs / data.durationMs * 100) or 100
    local survivabilityRows = {
        col2:StatRow(GetString(BATTLESCROLLS_STAT_DTPS), utils.formatCompact(dtps)),
        col2:StatRow(GetString(BATTLESCROLLS_GROUP_CARD_ALIVE),
            string.format("%.0f%% (%s)", alivePercent, utils.formatDuration(aliveTimeMs))),
    }
    if data.deaths then
        table.insert(survivabilityRows,
            col2:StatRow(GetString(BATTLESCROLLS_GROUP_DEATHS), tostring(data.deaths.deathCount)))
    end
    local survivabilitySection = col2:Section(GetString(BATTLESCROLLS_STAT_SURVIVABILITY), unpack(survivabilityRows))

    LibEffect.Yield():Await()

    -- Healing Output section (shown for everyone)
    local healingSection
    if data.healing then
        local h = data.healing
        if h.rawOut > 0 or h.rawSelf > 0 then
            local healingRows = {}

            if h.rawOut > 0 then
                local rawHps = h.rawOut / durationS
                local effHps = h.effectiveOut / durationS
                table.insert(healingRows, col2:StatRow(GetString(BATTLESCROLLS_HEALING_RAW_HPS),
                    utils.formatCompact(rawHps)))
                table.insert(healingRows, col2:StatRow(GetString(BATTLESCROLLS_HEALING_EFFECTIVE_HPS),
                    utils.formatCompact(effHps)))
                local overhealPercent = h.rawOut > 0 and ((h.rawOut - h.effectiveOut) / h.rawOut * 100) or 0
                table.insert(healingRows, col2:StatRow(GetString(BATTLESCROLLS_HEALING_OVERHEAL),
                    string.format("%.0f%%", overhealPercent)))
            end

            if h.rawSelf > 0 then
                local selfHps = h.rawSelf / durationS
                table.insert(healingRows, col2:StatRow(GetString(BATTLESCROLLS_SELF_HEALING),
                    string.format("%s HPS", utils.formatCompact(selfHps))))
            end

            healingSection = col2:Section(GetString(BATTLESCROLLS_GROUP_HEALING_OUTPUT), unpack(healingRows))
        end
    end

    col2:mount(journal.SECTION_GAP, 0, damageSection, vsAverageSection, survivabilitySection, healingSection)

    LibEffect.Yield():Await()

    -- =====================
    -- Q3: Boss Damage Bars with Per-Boss Metrics
    -- =====================
    local col3 = q3
    local q3Sections = {}

    -- Boss Damage section
    if data.bossDamage and #data.bossDamage > 0 then
        -- Per-boss group totals from encounter data (captures all group members)
        local groupBossTotals = ctx.arithmancer:groupDamageByBoss()

        local sorted = {}
        for _, bd in ipairs(data.bossDamage) do
            table.insert(sorted, bd)
        end
        table.sort(sorted, function(a, b) return a.damage > b.damage end)

        local topValue = sorted[1].damage
        if topValue <= 0 then topValue = 1 end

        local bossDamageChildren = {}
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

            table.insert(bossDamageChildren, col3:GroupMemberCard({
                displayName = bossName,
                primaryLabel = string.format("%s DPS", utils.formatCompact(bossDPS)),
                barPercent = topValue > 0 and (bd.damage / topValue * 100) or 0,
                shareText = string.format("%.1f%% %s", groupShare, GetString(BATTLESCROLLS_GROUP_CARD_OF_GROUP)),
                infoLine = table.concat(statParts, " · "),
            }))
        end

        local bossDamageSection = col3:Section(GetString(BATTLESCROLLS_OVERVIEW_BOSS_DAMAGE), unpack(bossDamageChildren))
        table.insert(q3Sections, bossDamageSection)
    end

    LibEffect.Yield():Await()

    -- Boss Damage Taken section
    if data.bossDamageTaken and #data.bossDamageTaken > 0 then
        local sorted = {}
        for _, bt in ipairs(data.bossDamageTaken) do
            table.insert(sorted, bt)
        end
        table.sort(sorted, function(a, b) return a.damage > b.damage end)

        local topValue = sorted[1].damage
        if topValue <= 0 then topValue = 1 end
        local totalDamageTaken = data.totalDamageTaken or sorted[1].damage

        local bossTakenChildren = {}
        for _, bt in ipairs(sorted) do
            local bossName = resolveBossName(bossSeqNames, bt.bossTag, bt.tagSeq)
            local sharePercent = totalDamageTaken > 0 and (bt.damage / totalDamageTaken * 100) or 0
            local bossDPS = durationS > 0 and (bt.damage / durationS) or 0

            table.insert(bossTakenChildren, col3:GroupMemberCard({
                displayName = bossName,
                primaryLabel = string.format("%s DPS", utils.formatCompact(bossDPS)),
                barPercent = topValue > 0 and (bt.damage / topValue * 100) or 0,
                shareText = string.format("%.1f%%", sharePercent),
                infoLine = utils.formatCompact(bt.damage),
            }))
        end

        local bossTakenSection = col3:Section(GetString(BATTLESCROLLS_BOSS_DAMAGE_TAKEN), unpack(bossTakenChildren))
        table.insert(q3Sections, bossTakenSection)
    end

    -- Death Recaps (section header with timing + attack rows)
    if data.deaths then
        if data.deaths.first then
            local hasMultiple = data.deaths.last ~= nil
            local firstAttacks = data.deaths.first.attacks
            local firstChildren = {}
            for i, attack in ipairs(firstAttacks) do
                table.insert(firstChildren, col3:DeathAttackRow(attack, i == #firstAttacks))
            end
            local firstDeathSection = col3:Section(
                GetString(hasMultiple and BATTLESCROLLS_GROUP_FIRST_DEATH or BATTLESCROLLS_GROUP_DEATH),
                unpack(firstChildren))
            col3:SetSectionTiming(firstDeathSection,
                zo_strformat(GetString(BATTLESCROLLS_GROUP_DEATH_AT), utils.formatDuration(data.deaths.first.timeOffsetMs)))
            table.insert(q3Sections, firstDeathSection)
        end
        if data.deaths.last then
            local lastAttacks = data.deaths.last.attacks
            local lastChildren = {}
            for i, attack in ipairs(lastAttacks) do
                table.insert(lastChildren, col3:DeathAttackRow(attack, i == #lastAttacks))
            end
            local lastDeathSection = col3:Section(
                GetString(BATTLESCROLLS_GROUP_LAST_DEATH),
                unpack(lastChildren))
            col3:SetSectionTiming(lastDeathSection,
                zo_strformat(GetString(BATTLESCROLLS_GROUP_DEATH_AT), utils.formatDuration(data.deaths.last.timeOffsetMs)))
            table.insert(q3Sections, lastDeathSection)
        end
    end

    if #q3Sections > 0 then
        col3:mount(journal.SECTION_GAP, journal.Q3_INSET, unpack(q3Sections))
    end

    LibEffect.Yield():Await()

    -- =====================
    -- Q4: Damage by Type + Top Incoming Damage
    -- =====================
    local col4 = q4
    local q4Sections = {}

    -- Damage by Type (no cap -- Q4 scrolls)
    if data.damageByType and #data.damageByType > 0 then
        local sortedTypes = {}
        local totalTypeDamage = 0
        for _, dbt in ipairs(data.damageByType) do
            table.insert(sortedTypes, dbt)
            totalTypeDamage = totalTypeDamage + dbt.damage
        end
        table.sort(sortedTypes, function(a, b) return a.damage > b.damage end)

        local typeRows = {}
        for _, entry in ipairs(sortedTypes) do
            local typeName = utils.getDamageTypeName(entry.type)
            local percent = totalTypeDamage > 0 and (entry.damage / totalTypeDamage * 100) or 0
            table.insert(typeRows, col4:StatRow(typeName, string.format("%.0f%%", percent)))
        end
        local typeSection = col4:Section(GetString(BATTLESCROLLS_GROUP_DAMAGE_BY_TYPE), unpack(typeRows))
        table.insert(q4Sections, typeSection)
    end

    -- Top Incoming Damage
    if data.topDamageTakenAbilities and #data.topDamageTakenAbilities > 0 then
        local incomingRows = {}
        for _, entry in ipairs(data.topDamageTakenAbilities) do
            local abilityName = utils.getAbilityDisplayName(entry.abilityId)
            table.insert(incomingRows, col4:StatRow(abilityName,
                string.format("%.0f%%", entry.damagePercent * 100)))
        end
        local incomingSection = col4:Section(GetString(BATTLESCROLLS_GROUP_TOP_INCOMING_DAMAGE), unpack(incomingRows))
        table.insert(q4Sections, incomingSection)
    end

    if #q4Sections > 0 then
        col4:mount(journal.SECTION_GAP, 0, unpack(q4Sections))
    end
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

        local setupRenderer = journal.renderers.setup
        local setupShare = BattleScrolls.setupShare

        for _, member in ipairs(members) do
            local memberData = member.data
            local memberName = member.displayName
            local hasQ3Content = (memberData.bossDamage and #memberData.bossDamage > 0)
                or (memberData.bossDamageTaken and #memberData.bossDamageTaken > 0)
                or (memberData.deaths and (memberData.deaths.first or memberData.deaths.last))

            -- Combat panelSpec (always available)
            local combatPanelSpec = {
                layout = hasQ3Content and "three-column" or "two-column",
                build = function(q2, q3, q4)
                    buildGroupPlayerPanel(q2, q3, q4, ctx, memberData, memberName, members)
                end,
            }

            -- Build panelSpec (only when CompactSetup available)
            local buildPanelSpec = nil
            local setupHash = memberData.setupHash
            if setupHash and setupShare then
                local compactSetup = setupShare:getSetup(memberName, setupHash)
                if compactSetup then
                    buildPanelSpec = setupRenderer.buildCompactSetupPanelSpec(compactSetup)
                end
            end

            local hasSetupData = buildPanelSpec ~= nil

            -- Role icon for entry
            local roleIconPath = BattleScrolls.utils.GetRoleIcon(member.role or LFG_ROLE_DPS)

            -- Track current view mode per entry (closure captures this)
            local viewMode = "combat"

            -- Tooltip with dynamic panelSpec (updated by setFunction)
            local tooltip = {
                type = "panel",
                panelSpec = combatPanelSpec,
            }

            -- Create horizontal list entry with icon
            local entryData = ZO_GamepadEntryData:New(memberName, roleIconPath)
            entryData:SetIconTintOnSelection(true)
            entryData.tooltip = tooltip
            entryData.valid = hasSetupData
                and { "combat", "build" }
                or { "combat" }
            entryData.valueStrings = hasSetupData
                and { GetString(BATTLESCROLLS_ENCOUNTER_COMBAT), GetString(BATTLESCROLLS_TAB_BUILD) }
                or { GetString(BATTLESCROLLS_ENCOUNTER_COMBAT) }
            entryData.getFunction = function() return viewMode end
            entryData.setFunction = function(value)
                viewMode = value
                if value == "build" and buildPanelSpec then
                    tooltip.panelSpec = buildPanelSpec
                else
                    tooltip.panelSpec = combatPanelSpec
                end
                -- Re-render the overview panel with the new panelSpec
                local journalUI = ctx.journalUI
                if journalUI and journalUI.overviewPanel then
                    journalUI.overviewPanel:Render(tooltip.panelSpec)
                end
            end

            list:AddEntry("BattleScrolls_HorizontalListRow", entryData)
        end
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

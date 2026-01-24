-----------------------------------------------------------
-- Journal Utilities
-- Standalone helper functions for journal UI rendering
--
-- All functions are stateless and can be called without
-- a class instance. Renderers use these for common operations.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local utils = {}

-------------------------
-- List Entry Helpers
-------------------------

---Creates a stat entry for the list
---@param list ZO_ParametricScrollList The parametric list
---@param label string Main text
---@param value string|number|nil Value to display as sublabel
---@param icon string|nil Optional icon path
---@param header string|nil Optional header for section grouping
function utils.addStatEntry(list, label, value, icon, header)
    local entryData = ZO_GamepadEntryData:New(label, icon)
    entryData:SetIconTintOnSelection(true)
    if value then
        entryData:AddSubLabel(tostring(value))
    end

    if header then
        entryData:SetHeader(header)
        list:AddEntryWithHeader("ZO_GamepadItemSubEntryTemplate", entryData)
    else
        list:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
    end
end

---Adds an Overview entry at the top of the stats list
---@param list ZO_ParametricScrollList The parametric list
function utils.addOverviewEntry(list)
    local entryData = ZO_GamepadEntryData:New(GetString(BATTLESCROLLS_TAB_OVERVIEW), journal.StatIcons.SUMMARY)
    entryData:SetIconTintOnSelection(true)
    entryData.isOverviewEntry = true
    list:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
end

-------------------------
-- Formatting Helpers
-------------------------

---Formats duration in milliseconds as MM:SS
---@param durationMs number
---@return string
function utils.formatDuration(durationMs)
    local seconds = math.floor(durationMs / 1000)
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

---Formats value with rate and percentage
---@param value number
---@param total number
---@param durationSec number
---@param rateLabel string "DPS" or "HPS"
---@return string
function utils.formatValueWithPercent(value, total, durationSec, rateLabel)
    local percent = total > 0 and (value / total * 100) or 0
    local rate = durationSec > 0 and math.floor(value / durationSec) or 0
    return string.format("%s (%s %s, %.1f%%)", ZO_CommaDelimitNumber(value), ZO_CommaDelimitNumber(rate), rateLabel, percent)
end

---Formats damage with percentage
---@param damage number
---@param total number
---@param durationSec number
---@return string
function utils.formatDamageWithPercent(damage, total, durationSec)
    return utils.formatValueWithPercent(damage, total, durationSec, "DPS")
end

---Formats healing with percentage
---@param healing number
---@param total number
---@param durationSec number
---@return string
function utils.formatHealingWithPercent(healing, total, durationSec)
    return utils.formatValueWithPercent(healing, total, durationSec, "HPS")
end

-------------------------
-- Panel Formatting Helpers
-- Used by overview panel renderers for compact display
-------------------------

---Formats a number with commas
---@param num number
---@return string
function utils.formatNumber(num)
    return ZO_CommaDelimitNumber(math.floor(num))
end

---Formats a percentage value
---@param num number
---@return string
function utils.formatPercent(num)
    return string.format("%.1f%%", num)
end

---Formats bytes as human-readable string (KB or MB)
---@param bytes number
---@return string
function utils.formatBytes(bytes)
    if bytes >= 1000000 then
        return string.format("%.1f MB", bytes / 1000000)
    elseif bytes >= 1000 then
        return string.format("%.1f KB", bytes / 1000)
    else
        return string.format("%d bytes", bytes)
    end
end

---Formats DPS value, rounding small values appropriately
---@param dps number Raw DPS value
---@return string Formatted DPS string
function utils.formatDPS(dps)
    if dps >= 1000 then
        -- USE_UPPERCASE_NUMBER_SUFFIXES = true
        return ZO_AbbreviateAndLocalizeNumber(dps, NUMBER_ABBREVIATION_PRECISION_TENTHS, true)
    elseif dps >= 10 then
        return string.format("%.0f", dps)
    elseif dps >= 1 then
        return string.format("%.1f", dps)
    else
        return string.format("%.2f", dps)
    end
end

---Formats a target/source value with DPS
---@param damage number The damage amount
---@param durationS number Fight duration in seconds for DPS calculation
---@return string formatted Formatted string like "1.2K DPS"
function utils.formatTargetDPS(damage, durationS)
    local dps = durationS > 0 and (damage / durationS) or 0
    return string.format("%s DPS", utils.formatDPS(dps))
end

---Formats a healing target value with HPS
---@param healing number The healing amount
---@param durationS number Fight duration for HPS calculation
---@return string formatted Formatted string like "1.2K HPS"
function utils.formatTargetHPS(healing, durationS)
    local hps = durationS > 0 and (healing / durationS) or 0
    return string.format("%s HPS", utils.formatDPS(hps))
end

---Gets ability display name with Scribe awareness (wrapper for BattleScrolls.utils)
---@param abilityId number
---@return string
function utils.GetScribeAwareAbilityDisplayName(abilityId)
    return BattleScrolls.utils.GetScribeAwareAbilityDisplayName(abilityId)
end

-------------------------
-- Icon Helpers
-------------------------

---Determines if an icon indicates a passive ability
---@param abilityIcon string|nil The icon path
---@return boolean
function utils.isPassiveIcon(abilityIcon)
    if not abilityIcon then return false end
    return string.find(abilityIcon, "passive", 1, true) ~= nil
        or string.find(abilityIcon, "ability_dragonknight_023", 1, true) ~= nil
        or string.find(abilityIcon, "ability_dragonknight_031", 1, true) ~= nil
        or string.find(abilityIcon, "ability_psijic_009", 1, true) ~= nil
        or string.find(abilityIcon, "ability_psijic_010", 1, true) ~= nil
        or string.find(abilityIcon, "ability_sorcerer_026", 1, true) ~= nil
        or string.find(abilityIcon, "ability_sorcerer_047", 1, true) ~= nil
        or string.find(abilityIcon, "ability_sorcerer_054", 1, true) ~= nil
        or string.find(abilityIcon, "ability_templar_012", 1, true) ~= nil
        or string.find(abilityIcon, "ability_templar_014", 1, true) ~= nil
        or string.find(abilityIcon, "ability_templar_028", 1, true) ~= nil
        or string.find(abilityIcon, "ability_weapon_001", 1, true) ~= nil
        or string.find(abilityIcon, "ability_weapon_021", 1, true) ~= nil
        or string.find(abilityIcon, "ability_weapon_027", 1, true) ~= nil
        or string.find(abilityIcon, "ability_weapon_028", 1, true) ~= nil
        or string.find(abilityIcon, "ability_werewolf_010", 1, true) ~= nil
end

-------------------------
-- Damage Type Helpers
-------------------------

---Gets a readable name for a damage type
---@param damageType number
---@return string
function utils.getDamageTypeName(damageType)
    return journal.DamageTypeNames[damageType] or string.format("Type %d", damageType)
end

---Gets an icon for a damage type
---@param damageType number
---@return string|nil
function utils.getDamageTypeIcon(damageType)
    return journal.DamageTypeIcons[damageType]
end

-------------------------
-- Ability Name Helpers
-------------------------

---Gets display name for an ability with fallback to "Ability ID"
---@param abilityId number
---@return string
function utils.getAbilityDisplayName(abilityId)
    local abilityName = BattleScrolls.utils.GetScribeAwareAbilityDisplayName(abilityId)
    if abilityName == "" then
        return string.format("%s %d", GetString(BATTLESCROLLS_TOOLTIP_ABILITY), abilityId)
    end
    return abilityName
end

-------------------------
-- Sorting Helpers
-------------------------

---@class SortedDamageEntry
---@field key number|string The key from the original table (usually abilityId or unitId)
---@field damage number The damage value

---Sorts a damage breakdown table by damage descending
---@param damageTable table<number|string, number>
---@return SortedDamageEntry[]
function utils.sortDamageBreakdown(damageTable)
    local sorted = {}
    for key, damage in pairs(damageTable) do
        table.insert(sorted, { key = key, damage = damage })
    end
    table.sort(sorted, function(a, b)
        return a.damage > b.damage
    end)
    return sorted
end

-------------------------
-- Instance/Encounter Icons
-------------------------

---Gets icon for an instance based on zone type
---@param instance Instance
---@return string
function utils.getInstanceIcon(instance)
    if instance.isHouse then
        return "EsoUI/Art/Icons/mapKey/mapKey_housing.dds"
    elseif instance.isPvP then
        return "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_battlegrounds.dds"
    elseif instance.isOverland then
        return "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_zoneStories.dds"
    else
        return "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_Dungeon.dds"
    end
end

---Gets icon for an encounter based on fight type
---@param encounter Encounter
---@return string
function utils.getEncounterIcon(encounter)
    if encounter.isDummyFight then
        return "EsoUI/Art/TreeIcons/gamepad/GP_collectionIcon_furnishings.dds"
    elseif encounter.isPlayerFight then
        return "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_duel.dds"
    elseif utils.isBossEncounter(encounter) then
        return "EsoUI/Art/ZoneStories/completionTypeIcon_groupBoss.dds"
    else
        return "EsoUI/Art/ZoneStories/completionTypeIcon_pointOfInterest.dds"
    end
end

---Checks if encounter is a boss fight
---@param encounter Encounter
---@return boolean
function utils.isBossEncounter(encounter)
    return encounter.bossesUnits and #encounter.bossesUnits > 0
end

-------------------------
-- Time Grouping
-------------------------

---Gets a header string for grouping by time
---@param timestampS number
---@return string
function utils.getTimeGroupHeader(timestampS)
    local now = GetTimeStamp()
    local rendered = BattleScrolls.utils.formatDate(timestampS)

    if rendered == BattleScrolls.utils.formatDate(now) then
        return GetString(BATTLESCROLLS_TIME_TODAY)
    elseif rendered == BattleScrolls.utils.formatDate(now - 24 * 60 * 60) then
        return GetString(BATTLESCROLLS_TIME_YESTERDAY)
    else
        return rendered
    end
end

-------------------------
-- Index Finding
-------------------------

---FindMatchingIndex finds the best matching index in a new data list based on an old value
---@generic T
---@param oldValue number
---@param newDataList T[]
---@param selectedIndex integer
---@param getNewValueFunction fun(item: T): number
---@param sortedDescending boolean
---@return integer
function utils.findMatchingIndex(oldValue, newDataList, selectedIndex, getNewValueFunction, sortedDescending)
    local currentIndex = zo_clamp(selectedIndex, 1, #newDataList)
    local newValue = getNewValueFunction(newDataList[currentIndex])
    if newValue == nil then
        return currentIndex
    end
    local deltaNow = newValue - oldValue
    if deltaNow == 0 then
        return currentIndex
    end

    if deltaNow > 0 and sortedDescending or deltaNow < 0 and not sortedDescending then
        -- search downwards
        for i = currentIndex, #newDataList do
            newValue = getNewValueFunction(newDataList[i])
            if newValue == nil then
                return currentIndex
            end
            local newDelta = newValue - oldValue
            -- if sign flipped, we either at or just passed the target
            if (deltaNow > 0 and newDelta <= 0) or (deltaNow < 0 and newDelta >= 0) then
                if math.abs(deltaNow) <= math.abs(newDelta) then
                    return currentIndex
                else
                    return i
                end
            end
            deltaNow = newDelta
            currentIndex = i
        end
        return currentIndex
    else
        -- search upwards
        for i = currentIndex, 1, -1 do
            newValue = getNewValueFunction(newDataList[i])
            if newValue == nil then
                return currentIndex
            end
            local newDelta = newValue - oldValue
            -- if sign flipped, we either at or just passed the target
            if (deltaNow > 0 and newDelta <= 0) or (deltaNow < 0 and newDelta >= 0) then
                if math.abs(deltaNow) <= math.abs(newDelta) then
                    return currentIndex
                else
                    return i
                end
            end
            deltaNow = newDelta
            currentIndex = i
        end
        return currentIndex
    end
end

-------------------------
-- Encounter Display Names
-------------------------

---Gets the top enemies for an encounter by damage taken
---@param encounter Encounter
---@param unitNames table<number, string>
---@param maxCount number
---@return string|nil result Formatted string like "Enemy1, Enemy2 (x2), Enemy3", or nil if no data
function utils.getTopEnemies(encounter, unitNames, maxCount)
    if not encounter.damageByUnitId then
        return nil
    end

    local computeTotal = BattleScrolls.arithmancer.ComputeDamageTotal
    -- Group damage by enemy name (formatted), iterating nested structure
    local damageByName = {}
    local countByName = {}
    local uniqueTargetIds = {}
    for _, byTarget in pairs(encounter.damageByUnitId) do
        for targetUnitId, dmg in pairs(byTarget) do
            local rawName = unitNames[targetUnitId] or "Unknown"
            local name = zo_strformat(SI_UNIT_NAME, rawName)
            damageByName[name] = (damageByName[name] or 0) + computeTotal(dmg)
            if not uniqueTargetIds[targetUnitId] then
                uniqueTargetIds[targetUnitId] = true
                countByName[name] = (countByName[name] or 0) + 1
            end
        end
    end

    -- Convert to sortable array
    local enemies = {}
    for name, dmg in pairs(damageByName) do
        table.insert(enemies, { name = name, damage = dmg, count = countByName[name] })
    end

    -- Sort by damage descending
    table.sort(enemies, function(a, b)
        return a.damage > b.damage
    end)

    -- Take top N, but only include if damage is at least half of top-1
    -- Also limit total string length to ~50 characters
    local MAX_LENGTH = 50
    local result = {}
    local charCount = 0
    local topDamage = enemies[1] and enemies[1].damage or 0
    for i = 1, math.min(maxCount, #enemies) do
        local enemy = enemies[i]
        -- Only include if at least half of top damage (top-1 always included)
        if i == 1 or enemy.damage >= topDamage / 2 then
            -- Estimate length this enemy would add
            local nameLen = utf8.len(enemy.name) or #enemy.name
            local addLen = nameLen
            if enemy.count > 1 then
                addLen = addLen + 5-- " (xN)"
            end
            if #result > 0 then
                addLen = addLen + 2 -- ", " separator
            end

            -- Stop if adding this would exceed limit (always include at least one)
            if charCount + addLen > MAX_LENGTH and #result > 0 then
                break
            end

            charCount = charCount + addLen
            if enemy.count > 1 then
                table.insert(result, string.format("%s (x%d)", enemy.name, enemy.count))
            else
                table.insert(result, enemy.name)
            end
        end
    end

    return #result > 0 and ZO_GenerateCommaSeparatedListWithAnd(result) or nil
end

---Gets display name for an encounter
---@param encounter Encounter
---@param unitNames table<number, string>
---@return string
function utils.getEncounterDisplayName(encounter, unitNames)
    -- Boss fights: just show boss name(s)
    if encounter.bossesUnits and #encounter.bossesUnits > 0 then
        local namesCount = {}
        for _, bossId in ipairs(encounter.bossesUnits) do
            local bossName = unitNames[bossId] or "Unknown"
            namesCount[bossName] = (namesCount[bossName] or 0) + 1
        end
        local names = {}
        for name, count in pairs(namesCount) do
            if count > 1 then
                table.insert(names, string.format("%s (x%d)", zo_strformat(SI_UNIT_NAME, name), count))
            else
                table.insert(names, zo_strformat(SI_UNIT_NAME, name))
            end
        end

        return ZO_GenerateCommaSeparatedListWithAnd(names)
    end

    -- Non-boss fights: "Fight in {location} with {enemies}"
    local enemies = utils.getTopEnemies(encounter, unitNames, 3)
    local location = encounter.location

    if location and enemies then
        return zo_strformat(GetString(BATTLESCROLLS_ENCOUNTER_FIGHT_IN_WITH), location, enemies)
    elseif enemies then
        return zo_strformat(GetString(BATTLESCROLLS_ENCOUNTER_FIGHT_WITH), enemies)
    elseif location then
        return zo_strformat(GetString(BATTLESCROLLS_ENCOUNTER_FIGHT_IN), location)
    else
        return GetString(BATTLESCROLLS_ENCOUNTER_COMBAT)
    end
end

-------------------------
-- Healing Data Helpers
-------------------------

---Calculates total raw and real healing from a multi-unit healing data structure
---@param healingData table<number, {total: {raw: number, real: number}}> Map of unitId to healing totals
---@return number totalRaw
---@return number totalReal
function utils.calculateHealingTotals(healingData)
    local totalRaw = 0
    local totalReal = 0
    for _, data in pairs(healingData) do
        totalRaw = totalRaw + data.total.raw
        totalReal = totalReal + data.total.real
    end
    return totalRaw, totalReal
end

-------------------------
-- Shared Q2 Section Renderers
-- Used by both overview panel and tab-specific panels
-------------------------

---Renders damage summary section (DPS, Group DPS, Share)
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param sectionLabel string Section header label
---@param lastControl Control|nil Previous control for anchoring
---@param dps number Personal DPS
---@param groupDps number|nil Group DPS (nil if solo)
---@param share number Personal share percentage (0-100)
---@return Control lastControl The last rendered control
function utils.renderDamageSummarySection(panel, sectionLabel, lastControl, dps, groupDps, share)
    lastControl = panel:AddSection(sectionLabel, lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_STAT_DPS), utils.formatNumber(dps), lastControl)
    if groupDps then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_STAT_GROUP_DPS), utils.formatNumber(groupDps), lastControl)
    end
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_SHARE), utils.formatPercent(share), lastControl)
    return lastControl
end

---Renders damage composition section (DOT/Direct, AOE/ST)
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param lastControl Control|nil Previous control for anchoring
---@param dotPercent number|nil DOT damage percentage (0-100)
---@param directPercent number|nil Direct damage percentage (0-100)
---@param aoePercent number|nil AOE damage percentage (0-100)
---@param stPercent number|nil Single target damage percentage (0-100)
---@return Control lastControl The last rendered control
function utils.renderDamageCompositionSection(panel, lastControl, dotPercent, directPercent, aoePercent, stPercent)
    lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_COMPOSITION), lastControl)
    if dotPercent and directPercent then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_DOT), utils.formatPercent(dotPercent), lastControl)
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_DIRECT), utils.formatPercent(directPercent), lastControl)
    end
    if aoePercent and stPercent then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_AOE), utils.formatPercent(aoePercent), lastControl)
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_SINGLE_TARGET), utils.formatPercent(stPercent), lastControl)
    end
    return lastControl
end

---Renders damage quality section (Crit Rate, Max Hit)
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param lastControl Control|nil Previous control for anchoring
---@param critRate number Crit rate percentage (0-100)
---@param maxHit number Maximum hit value
---@return Control lastControl The last rendered control
function utils.renderDamageQualitySection(panel, lastControl, critRate, maxHit)
    lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_QUALITY), lastControl)
    if critRate > 0 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE), utils.formatPercent(critRate), lastControl)
    end
    if maxHit > 0 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HIT), utils.formatNumber(maxHit), lastControl)
    end
    return lastControl
end

---Renders damage taken summary section (DTPS, Total)
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param lastControl Control|nil Previous control for anchoring
---@param dtps number Damage taken per second
---@param total number Total damage taken
---@return Control lastControl The last rendered control
function utils.renderDamageTakenSummarySection(panel, lastControl, dtps, total)
    lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_SUMMARY), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_STAT_DTPS), utils.formatNumber(dtps), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_TOTAL), utils.formatNumber(total), lastControl)
    return lastControl
end

---Renders healing summary section (Raw HPS, Effective HPS, Total)
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param sectionLabel string|nil Section header label (defaults to "Summary")
---@param lastControl Control|nil Previous control for anchoring
---@param rawHps number Raw healing per second
---@param effectiveHps number Effective healing per second
---@param total number Total effective healing
---@return Control lastControl The last rendered control
function utils.renderHealingSummarySection(panel, sectionLabel, lastControl, rawHps, effectiveHps, total)
    lastControl = panel:AddSection(sectionLabel or GetString(BATTLESCROLLS_OVERVIEW_SUMMARY), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_HEALING_RAW_HPS), utils.formatNumber(rawHps), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_HEALING_EFFECTIVE_HPS), utils.formatNumber(effectiveHps), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_TOTAL), utils.formatNumber(total), lastControl)
    return lastControl
end

---Renders healing efficiency section (Overheal %)
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param lastControl Control|nil Previous control for anchoring
---@param overhealPercent number Overheal percentage (0-100)
---@return Control lastControl The last rendered control
function utils.renderHealingEfficiencySection(panel, lastControl, overhealPercent)
    lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_EFFICIENCY), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_HEALING_OVERHEAL), utils.formatPercent(overhealPercent), lastControl)
    return lastControl
end

---Renders healing composition section (HoT vs Direct)
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param lastControl Control|nil Previous control for anchoring
---@param hotPercent number|nil HoT healing percentage (0-100)
---@param directPercent number|nil Direct healing percentage (0-100)
---@return Control lastControl The last rendered control
function utils.renderHealingCompositionSection(panel, lastControl, hotPercent, directPercent)
    lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_COMPOSITION), lastControl)
    if hotPercent and directPercent then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_HOT), utils.formatPercent(hotPercent), lastControl)
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_DIRECT), utils.formatPercent(directPercent), lastControl)
    end
    return lastControl
end

---Renders healing quality section (Crit Rate, Max Heal)
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param lastControl Control|nil Previous control for anchoring
---@param critRate number Crit rate percentage (0-100)
---@param maxHeal number Maximum heal value
---@return Control lastControl The last rendered control
function utils.renderHealingQualitySection(panel, lastControl, critRate, maxHeal)
    lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_QUALITY), lastControl)
    if critRate > 0 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE), utils.formatPercent(critRate), lastControl)
    end
    if maxHeal > 0 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HEAL), utils.formatNumber(maxHeal), lastControl)
    end
    return lastControl
end

---Renders consolidated damage output section (DPS, Composition, Quality in one section)
---Used by Overview tab for a cleaner, more compact display
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param lastControl Control|nil Previous control for anchoring
---@param bossDps number|nil Boss DPS (nil if not boss fight or no boss damage)
---@param totalDps number Total DPS
---@param groupDps number|nil Group DPS (nil if solo)
---@param share number Personal share percentage (0-100)
---@param critRate number Crit rate percentage (0-100)
---@param maxHit number Maximum hit value
---@param dotPercent number|nil DOT damage percentage
---@param aoePercent number|nil AOE damage percentage
---@return Control lastControl The last rendered control
function utils.renderDamageOutputSection(panel, lastControl, bossDps, totalDps, groupDps, share, critRate, maxHit, dotPercent, aoePercent)
    lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT), lastControl)

    -- Boss DPS if applicable
    if bossDps and bossDps > 0 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_BOSS_DAMAGE), utils.formatNumber(bossDps) .. " DPS", lastControl)
    end

    -- Total DPS
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_DAMAGE_DONE), utils.formatNumber(totalDps) .. " DPS", lastControl)

    -- Share (only if group data exists)
    if groupDps and groupDps > totalDps then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_SHARE), utils.formatPercent(share), lastControl)
    end

    -- Quality metrics inline
    if critRate > 0 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE), utils.formatPercent(critRate), lastControl)
    end
    if maxHit > 0 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HIT), utils.formatNumber(maxHit), lastControl)
    end

    -- Composition inline (only show if there's a meaningful split)
    if dotPercent and dotPercent > 5 and dotPercent < 95 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_DOT), utils.formatPercent(dotPercent), lastControl)
    end
    if aoePercent and aoePercent > 5 and aoePercent < 95 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_AOE), utils.formatPercent(aoePercent), lastControl)
    end

    return lastControl
end

---Renders healing section with overheal and HoT% inline (no separate sections)
---Used by Overview tab for a cleaner, more compact display
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param sectionLabel string Section header label (e.g., "Healing Out", "Self Healing")
---@param lastControl Control|nil Previous control for anchoring
---@param rawHps number Raw healing per second
---@param effectiveHps number Effective healing per second
---@param overhealPercent number Overheal percentage (0-100)
---@param hotPercent number|nil HoT percentage (0-100), only shown if meaningful split
---@return Control lastControl The last rendered control
function utils.renderHealingSectionCompact(panel, sectionLabel, lastControl, rawHps, effectiveHps, overhealPercent, hotPercent)
    lastControl = panel:AddSection(sectionLabel, lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_HEALING_RAW_HPS), utils.formatNumber(rawHps), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_HEALING_EFFECTIVE_HPS), utils.formatNumber(effectiveHps), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_HEALING_OVERHEAL), utils.formatPercent(overhealPercent), lastControl)
    -- HoT% only shown if there's a meaningful split (>5% and <95%)
    if hotPercent and hotPercent > 5 and hotPercent < 95 then
        lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_HOT), utils.formatPercent(hotPercent), lastControl)
    end
    return lastControl
end

---Renders damage taken section with proper header
---@param panel BattleScrolls_Journal_OverviewPanel The overview panel
---@param lastControl Control|nil Previous control for anchoring
---@param dtps number Damage taken per second
---@param total number Total damage taken
---@return Control lastControl The last rendered control
function utils.renderDamageTakenSection(panel, lastControl, dtps, total)
    lastControl = panel:AddSection(GetString(BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_STAT_DTPS), utils.formatNumber(dtps), lastControl)
    lastControl = panel:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_TOTAL), utils.formatNumber(total), lastControl)
    return lastControl
end

-- Export to namespace
journal.utils = utils

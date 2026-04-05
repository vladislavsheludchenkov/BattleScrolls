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

---Formats duration in milliseconds with fractional seconds (M:SS.s or S.ss)
---@param durationMs number
---@return string
function utils.formatPreciseDuration(durationMs)
    local durationS = durationMs / 1000
    local minutes = math.floor(durationS / 60)
    local seconds = durationS % 60
    if minutes > 0 then
        return string.format("%d:%04.1f", minutes, seconds)
    end
    return string.format("%.1fs", seconds)
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

---Formats a number compactly (e.g., 45200 -> "45.2K")
---@param value number
---@return string
function utils.formatCompact(value)
    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    elseif value % 1 < 0.005 then
        return string.format("%.0f", value)
    elseif value >= 1 then
        return string.format("%.1f", value)
    else
        return string.format("%.2f", value)
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
-- Ability Merging
-------------------------

---Merges ability stats by display name (grouping morphs/variants with the same name).
---Works with both damage stats (table values with .total, .ticks, .critTicks, .maxHit)
---and healing stats (plain number values). The icon abilityId is chosen from the
---highest-total variant within each name group.
---@param abilityStats table<number, CritStats|number> Ability ID -> stats (table) or total (number)
---@param maxCount number|nil Maximum entries to return (nil = all)
---@return { abilityId: number, name: string, total: number, ticks: number, critTicks: number, maxHit: number }[]
function utils.mergeAbilitiesByName(abilityStats, maxCount)
    local nameGroups = {}
    local nameOrder = {}

    for abilityId, stats in pairs(abilityStats) do
        local abilityName = utils.getAbilityDisplayName(abilityId)

        if not nameGroups[abilityName] then
            nameGroups[abilityName] = {
                abilityId = abilityId,
                name = abilityName,
                total = 0,
                ticks = 0,
                critTicks = 0,
                maxHit = 0,
            }
            table.insert(nameOrder, abilityName)
        end

        local group = nameGroups[abilityName]
        local isTable = type(stats) == "table"
        local total = isTable and stats.total or stats
        group.total = group.total + total
        if isTable then
            group.ticks = group.ticks + (stats.ticks or 0)
            group.critTicks = group.critTicks + (stats.critTicks or 0)
            if (stats.maxHit or 0) > group.maxHit then
                group.maxHit = stats.maxHit
            end
        end
        -- Track which abilityId has highest total for icon selection
        local prevStats = abilityStats[group.abilityId]
        local prevTotal = type(prevStats) == "table" and prevStats.total or (prevStats or 0)
        if total > prevTotal then
            group.abilityId = abilityId
        end
    end

    -- Convert to sorted array
    local abilities = {}
    for _, name in ipairs(nameOrder) do
        table.insert(abilities, nameGroups[name])
    end
    table.sort(abilities, function(a, b) return a.total > b.total end)

    -- Return top N if maxCount specified
    if maxCount and maxCount < #abilities then
        local result = {}
        for i = 1, maxCount do
            table.insert(result, abilities[i])
        end
        return result
    end

    return abilities
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
-- Ability Icon Helpers
-------------------------

---Configures edge/circle frame for an ability icon control.
---@param edgeFrame Control Backdrop control for square frame
---@param circleFrame Control Texture control for circle frame
---@param icon Control Icon texture control (anchor target)
---@param isPassive boolean Whether the ability is passive
---@param isUltimate boolean Whether the ability is an ultimate
local function setupAbilityIconFrame(edgeFrame, circleFrame, icon, isPassive, isUltimate)
    local style = journal.AbilityIconStyle
    local frameInset = isUltimate and style.ULT_FRAME_INSET or style.FRAME_INSET

    edgeFrame:ClearAnchors()
    edgeFrame:SetAnchor(TOPLEFT, icon, TOPLEFT, -frameInset, -frameInset)
    edgeFrame:SetAnchor(BOTTOMRIGHT, icon, BOTTOMRIGHT, frameInset, frameInset)
    if isUltimate then
        edgeFrame:SetEdgeColor(unpack(style.ULT_EDGE_COLOR))
    else
        edgeFrame:SetEdgeColor(ZO_NORMAL_TEXT:UnpackRGBA())
    end
    edgeFrame:SetHidden(isPassive)

    circleFrame:ClearAnchors()
    circleFrame:SetAnchor(TOPLEFT, icon, TOPLEFT, -frameInset, -frameInset)
    circleFrame:SetAnchor(BOTTOMRIGHT, icon, BOTTOMRIGHT, frameInset, frameInset)
    circleFrame:SetHidden(not isPassive)
end

---Populates an ability icon row created from BattleScrolls_AbilityIconEntry template.
---Used by both the overview panel and tooltip to guarantee identical rendering.
---@param row Control Control with Icon, EdgeFrame, CircleFrame, Name children
---@param abilityId number
---@param isUltimate boolean
function utils.populateAbilityRow(row, abilityId, isUltimate)
    local icon = row:GetNamedChild("Icon")
    local edgeFrame = row:GetNamedChild("EdgeFrame")
    local circleFrame = row:GetNamedChild("CircleFrame")
    local nameLabel = row:GetNamedChild("Name")

    local abilityIcon = GetAbilityIcon(abilityId)
    icon:SetTexture(abilityIcon)

    local isPassive = utils.isPassiveIcon(abilityIcon)
    setupAbilityIconFrame(edgeFrame, circleFrame, icon, isPassive, isUltimate)

    nameLabel:SetText(utils.GetScribeAwareAbilityDisplayName(abilityId))
end

-- Export to namespace
journal.utils = utils

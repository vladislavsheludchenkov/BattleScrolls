-----------------------------------------------------------
-- Utils
-- General utility functions for Battle Scrolls
--
-- Contains:
--   - String utilities (prefix checking, display name formatting)
--   - Location/zone name helpers
--   - Table utilities (median calculation)
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class BattleScrollsUtils
local utils = {}

BattleScrolls.utils = utils

---isPrefix returns true if string a is a prefix of string b
---@param a string
---@param b string
---@return boolean
local function isPrefix(a, b)
    return string.sub(b, 1, #a) == a
end

---MaybeLocationName returns the player's current location name, if it is different from the zone name
---@return string|nil
function utils.MaybeLocationName()
    ---@type string
    local zoneName = GetPlayerActiveZoneName()

    ---@param locationName string
    ---@return string|nil
    local function checkCandidate(locationName)
        if locationName and locationName ~= "" and locationName ~= zoneName and not isPrefix(locationName, zoneName) then
            return locationName
        else
            return nil
        end
    end

    return checkCandidate(GetPlayerLocationName()) or checkCandidate(GetPlayerActiveSubzoneName())
end

---Returns the player's current zone name, formatted
---@return string Formatted zone name
function utils.FormattedZoneName()
    local rawName = GetPlayerActiveZoneName()
    return zo_strformat("<<C:1>>", rawName)
end

---Calculates the median of an array of numbers
---@param values number[] Array of numbers (will be sorted in place)
---@return number Median value, or 0 if array is empty
function utils.median(values)
    local n = #values
    if n == 0 then
        return 0
    end

    table.sort(values)
    local mid = math.floor(n / 2)
    if n % 2 == 0 then
        return (values[mid] + values[mid + 1]) / 2
    else
        return values[mid + 1]
    end
end

---Formats a timestamp as a date string
---@param timestampS number Timestamp in seconds
---@return string Formatted date string "Day, DD Mon YYYY", e.g. "Mon, 01 Jan 2024"
function utils.formatDate(timestampS)
    ---@diagnostic disable-next-line: return-type-mismatch
    return os.date("%a, %d %b %Y", timestampS)
end

---Formats a timestamp as a time string
---@param timestampS number Timestamp in seconds
---@return string Formatted time string "HH:MM", e.g. "14:30"
function utils.formatTime(timestampS)
    ---@diagnostic disable-next-line: return-type-mismatch
    return os.date("%H:%M", timestampS)
end

---Counts the number of keys in a table
---@param t table The table to count keys in
---@return number The number of keys
function utils.countKeys(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

---Gets the display name of an ability, using base grimoire name if it is a scribed ability
---@param abilityId number The ability ID
---@return string The display name of the ability
function utils.GetScribeAwareAbilityDisplayName(abilityId)
    local craftedAbilityId = GetAbilityCraftedAbilityId(abilityId)
    if craftedAbilityId and craftedAbilityId ~= 0 then
        local craftedAbilityDisplayName = GetCraftedAbilityDisplayName(craftedAbilityId)
        if craftedAbilityDisplayName and craftedAbilityDisplayName ~= "" then
            return zo_strformat("<<C:1>>", craftedAbilityDisplayName)
        end
    end
    ---@diagnostic disable-next-line: missing-parameter
    return zo_strformat("<<C:1>>", GetAbilityName(abilityId))
end

-- ==================== Role Icons & Helpers ====================

utils.ROLE_ICONS = {
    [LFG_ROLE_DPS]  = "/esoui/art/lfg/gamepad/lfg_roleicon_dps.dds",
    [LFG_ROLE_HEAL] = "/esoui/art/lfg/gamepad/lfg_roleicon_healer.dds",
    [LFG_ROLE_TANK] = "/esoui/art/lfg/gamepad/lfg_roleicon_tank.dds",
}
utils.DEFAULT_ROLE_ICON = "/esoui/art/lfg/gamepad/lfg_roleicon_dps.dds"

---Get role icon texture path
---@param role number LFG_ROLE_* constant
---@return string texturePath
function utils.GetRoleIcon(role)
    return utils.ROLE_ICONS[role] or utils.DEFAULT_ROLE_ICON
end

---Get the LFG role for a unit tag.
---For player: uses group role when grouped, otherwise selected LFG role.
---For others: uses group role with DPS fallback.
---Handles both nil and LFG_ROLE_INVALID (0) from GetGroupMemberSelectedRole.
---@param unitTag string
---@return number role LFG_ROLE_DPS, LFG_ROLE_HEAL, or LFG_ROLE_TANK
function utils.getUnitRole(unitTag)
    if AreUnitsEqual(unitTag, "player") then
        if IsUnitGrouped("player") then
            local role = GetGroupMemberSelectedRole(unitTag)
            if role and role ~= LFG_ROLE_INVALID then return role end
        end
        return GetSelectedLFGRole()
    end
    local role = GetGroupMemberSelectedRole(unitTag)
    if role and role ~= LFG_ROLE_INVALID then return role end
    return LFG_ROLE_DPS
end

---Gets the undecorated display name of a unit
---@param unitTag string|nil The unit tag, player if nil
---@return string|nil The undecorated display name, or nil if not available
function utils.GetUndecoratedDisplayName(unitTag)
    local displayName
    if unitTag == nil then
        displayName = GetDisplayName()
    else
        displayName = GetUnitDisplayName(unitTag)
    end
    if displayName == nil then
        return nil
    end
    return UndecorateDisplayName(displayName)
end


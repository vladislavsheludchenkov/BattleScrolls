if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.dpsMeterUtils = BattleScrolls.dpsMeterUtils or {}

local utils = BattleScrolls.dpsMeterUtils

-- ==================== Settings Access ====================

---Get settings with defaults fallback
---@return table settings
---@return table defaults
function utils.GetSettings()
    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    local defaults = BattleScrolls.storage.defaults.settings
    return settings or defaults, defaults
end

---Get a specific setting with default fallback
---@param key string
---@return any
function utils.GetSetting(key)
    local settings, defaults = utils.GetSettings()
    local value = settings[key]
    if value == nil then
        return defaults[key]
    end
    return value
end

-- ==================== Formatting ====================

---Format DPS number for display (abbreviated)
---@param dps number
---@return string
function utils.FormatDPS(dps)
    if dps < 1000 then
        return string.format("%.0f", dps)
    else
        return ZO_AbbreviateAndLocalizeNumber(dps, 1, false) or tostring(dps)
    end
end

---Format DPS and share for display (e.g., "68.5K DPS (25%)")
---@param dps number
---@param share number
---@return string
function utils.FormatDPSAndShare(dps, share)
    local dpsStr = utils.FormatDPS(dps)
    if share > 0 and share < 100 then
        return string.format("%s DPS (%.0f%%)", dpsStr, share)
    else
        return string.format("%s DPS", dpsStr)
    end
end

---Format DPS with share for compact display (e.g., "68.5K (25%)")
---@param dps number
---@param share number
---@return string
function utils.FormatDPSWithShare(dps, share)
    local dpsStr = utils.FormatDPS(dps)
    if share > 0 and share < 100 then
        return string.format("%s (%.0f%%)", dpsStr, share)
    else
        return dpsStr
    end
end

---Format duration for display
---@param durationS number Duration in seconds
---@return string Formatted as "M:SS"
function utils.FormatDuration(durationS)
    return (ZO_FormatTime(durationS, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS))
end

---Format duration with brackets for display
---@param durationS number Duration in seconds
---@return string Formatted as "[M:SS]"
function utils.FormatDurationBracketed(durationS)
    return "[" .. utils.FormatDuration(durationS) .. "]"
end

-- ==================== Mode Detection ====================

---Determine if healing mode should be shown based on settings and values
---@param personalDPS number Personal DPS value
---@param personalHPS number Personal HPS value
---@return boolean showHealing
function utils.ShouldShowHealing(personalDPS, personalHPS)
    local mode = utils.GetSetting("dpsMeterPersonalMode")
    if mode == "healing" then
        return true
    elseif mode == "damage" then
        return false
    else -- "auto"
        return personalHPS > personalDPS
    end
end

-- ==================== Color Utilities ====================

---Convert HSL to RGB
---@param h number Hue (0-1)
---@param s number Saturation (0-1)
---@param l number Lightness (0-1)
---@return number r Red (0-1)
---@return number g Green (0-1)
---@return number b Blue (0-1)
function utils.HSLToRGB(h, s, l)
    if s == 0 then
        return l, l, l
    end

    local function hueToRgb(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1/6 then return p + (q - p) * 6 * t end
        if t < 1/2 then return q end
        if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
        return p
    end

    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q

    return hueToRgb(p, q, h + 1/3),
           hueToRgb(p, q, h),
           hueToRgb(p, q, h - 1/3)
end

---Convert RGB to HSL
---@param r number Red (0-1)
---@param g number Green (0-1)
---@param b number Blue (0-1)
---@return number h Hue (0-1)
---@return number s Saturation (0-1)
---@return number l Lightness (0-1)
function utils.RGBToHSL(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local l = (max + min) / 2
    local h, s

    if max == min then
        h, s = 0, 0
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)

        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, l
end

---Interpolate between two RGB colors in HSL space
---@param c1 number[] RGB color {r, g, b}
---@param c2 number[] RGB color {r, g, b}
---@param t number Interpolation factor (0-1)
---@return number r
---@return number g
---@return number b
function utils.LerpColorHSL(c1, c2, t)
    local h1, s1, l1 = utils.RGBToHSL(c1[1], c1[2], c1[3])
    local h2, s2, l2 = utils.RGBToHSL(c2[1], c2[2], c2[3])

    -- Take shortest path around hue circle
    local dh = h2 - h1
    if dh > 0.5 then
        h1 = h1 + 1
    elseif dh < -0.5 then
        h2 = h2 + 1
    end

    local h = h1 + (h2 - h1) * t
    if h >= 1 then h = h - 1 end
    if h < 0 then h = h + 1 end

    local s = s1 + (s2 - s1) * t
    local l = l1 + (l2 - l1) * t

    return utils.HSLToRGB(h, s, l)
end

-- Color cache (weak keys for GC)
local colorCache = setmetatable({}, { __mode = "k" })

---Generate a stable, vivid color from a display name
---Uses golden ratio to spread hues evenly, keeps saturation and lightness tuned for visibility
---Results are cached for performance
---@param displayName string
---@return number r Red (0-1)
---@return number g Green (0-1)
---@return number b Blue (0-1)
---@return number a Alpha (always 1)
function utils.ColorFromName(displayName)
    local cached = colorCache[displayName]
    if cached then
        return cached[1], cached[2], cached[3], cached[4]
    end

    local hash = 0
    for i = 1, #displayName do
        hash = (hash * 31 + string.byte(displayName, i)) % 2147483647
    end

    local goldenRatio = 0.618033988749895
    local hue = (hash * goldenRatio) % 1.0
    local saturation = 0.65 + (hash % 1000) / 4000  -- 0.65-0.90
    local lightness = 0.40 + (hash % 500) / 5000   -- 0.40-0.50

    local r, g, b = utils.HSLToRGB(hue, saturation, lightness)
    colorCache[displayName] = { r, g, b, 1 }
    return r, g, b, 1
end

-- ==================== Role Icons ====================

utils.ROLE_ICONS = {
    [LFG_ROLE_DPS] = "/esoui/art/lfg/gamepad/lfg_roleicon_dps.dds",
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

-- ==================== Member Table Pooling ====================

local memberPool = {}
local MEMBER_POOL_LIMIT = 24

---Get a recycled member table or create a new one
---@return table
function utils.GetMemberEntry()
    return table.remove(memberPool) or {}
end

---Recycle a member table back to the pool
---@param entry table
function utils.RecycleMemberEntry(entry)
    if #memberPool < MEMBER_POOL_LIMIT then
        table.insert(memberPool, entry)
    end
end

---Clear and recycle all entries from a members array
---@param members table[]
function utils.ClearMembers(members)
    for i = #members, 1, -1 do
        utils.RecycleMemberEntry(members[i])
        members[i] = nil
    end
end

-- ==================== Member Splitting ====================

---Split members array into DPS and HPS groups
---@param members table[] Array of member entries with showHealing field
---@return table[] dpsMembers
---@return table[] hpsMembers
function utils.SplitMembersByRole(members)
    local dpsMembers = {}
    local hpsMembers = {}
    for _, member in ipairs(members) do
        if member.showHealing then
            table.insert(hpsMembers, member)
        else
            table.insert(dpsMembers, member)
        end
    end
    return dpsMembers, hpsMembers
end

-- ==================== Member Formatting ====================

---Format a member entry for text display
---@param member table Member entry with name, allDPS, bossDPS, rawHPS, effectiveHPS, showHealing
---@param isBossFight boolean Whether this is a boss fight
---@return string
function utils.FormatMemberText(member, isBossFight)
    if member.showHealing then
        return string.format("%s: %s HPS (%s eff)",
                member.name,
                utils.FormatDPS(member.rawHPS),
                utils.FormatDPS(member.effectiveHPS))
    elseif isBossFight and member.bossDPS then
        return string.format("%s: %s / %s",
                member.name,
                utils.FormatDPS(member.bossDPS),
                utils.FormatDPS(member.allDPS))
    else
        return string.format("%s: %s",
                member.name,
                utils.FormatDPS(member.allDPS))
    end
end

-- ==================== Constants ====================

-- Text design fonts
utils.TEXT_FONT = "ZoFontGamepad27"
utils.TEXT_HEADER_FONT = "ZoFontGamepad27"
utils.TEXT_TOTAL_FONT = "ZoFontGamepad22"

-- Update intervals
utils.UPDATE_INTERVAL_MS = 200
utils.PREVIEW_DURATION_MS = 3000

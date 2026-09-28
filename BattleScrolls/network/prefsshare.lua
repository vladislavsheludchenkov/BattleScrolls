-----------------------------------------------------------
-- PrefsShare
-- User preference sharing via LibGroupBroadcast (protocol 435)
--
-- Currently carries one preference: the member's chosen bar
-- color for the colorful group bars meter design. Sent on
-- activation, on group joins (throttled) and whenever the
-- setting changes; received colors are kept per display name
-- for the session.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class PrefsShare
---@field protocol Protocol|nil LibGroupBroadcast user prefs protocol instance (435)
local prefsShare = {}
BattleScrolls.prefsShare = prefsShare

-- Minimum ms between broadcasts triggered by group roster changes
-- Roster changes arrive in bursts (several joins while a group fills); wait
-- for the dust to settle before sending, and let each new change restart the
-- timer so one send covers the whole burst.
local ROSTER_SEND_DELAY_MS = 2500

---@class MemberColor
---@field r number 0-1
---@field g number 0-1
---@field b number 0-1

---Received colors by undecorated display name (session-scoped)
---@type table<string, MemberColor>
local colorsByDisplayName = {}

-- Debounce token: each roster change bumps it; only the latest timer fires
local rosterSendToken = 0

---Parses an "RRGGBB" hex string into 0-1 components
---@param hex string|nil
---@return MemberColor|nil
local function parseHexColor(hex)
    if type(hex) ~= "string" or #hex ~= 6 then
        return nil
    end
    local value = tonumber(hex, 16)
    if not value then
        return nil
    end
    return {
        r = math.floor(value / 65536) / 255,
        g = math.floor(value / 256) % 256 / 255,
        b = value % 256 / 255,
    }
end

---Returns the local player's configured bar color, or nil for default
---@return MemberColor|nil
function prefsShare.GetOwnColor()
    local settings = BattleScrolls.storage.savedVariables.settings
    return parseHexColor(settings and settings.groupBarColor)
end

---Returns the chosen bar color for a group member (or the local player), or
---nil when they haven't picked one / don't run the addon.
---@param displayName string Undecorated display name
---@return MemberColor|nil
function prefsShare.GetColorFor(displayName)
    if displayName == BattleScrolls.utils.GetUndecoratedDisplayName() then
        return prefsShare.GetOwnColor()
    end
    return colorsByDisplayName[displayName]
end

---Broadcasts the current preferences to the group
function prefsShare:Send()
    if not self.protocol or not IsUnitGrouped("player") then
        return
    end
    local settings = BattleScrolls.storage.savedVariables.settings
    local hex = settings and settings.groupBarColor
    local color24 = nil
    if type(hex) == "string" and #hex == 6 then
        color24 = tonumber(hex, 16)
    end
    self.protocol:Send({ color24 = color24 })
end

---Called by the settings UI when the color preference changes
function prefsShare:OnColorChanged()
    self:Send()
end

---Initialize the prefs sharing protocol with LibGroupBroadcast
function prefsShare:Initialize()
    local LGB = LibGroupBroadcast
    if not LGB then
        return
    end
    local handler = BattleScrolls.lgbHandler
    if not handler then
        return
    end

    local protocol = handler:DeclareProtocol(435, "BattleScrolls_UserPrefs")
    protocol:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("color24", { minValue = 0, numBits = 24 })))
    protocol:OnData(function(unitTag, data)
        if AreUnitsEqual(unitTag, "player") then return end
        local displayName = BattleScrolls.utils.GetUndecoratedDisplayName(unitTag)
        if not displayName or displayName == "" then return end
        if data.color24 then
            colorsByDisplayName[displayName] = {
                r = math.floor(data.color24 / 65536) / 255,
                g = math.floor(data.color24 / 256) % 256 / 255,
                b = data.color24 % 256 / 255,
            }
        else
            colorsByDisplayName[displayName] = nil
        end
    end)
    if not protocol:Finalize({ isRelevantInCombat = false, replaceQueuedMessages = true }) then
        BattleScrolls.log.Warn("PrefsShare: protocol 435 failed to finalize")
        return
    end
    self.protocol = protocol

    EVENT_MANAGER:RegisterForEvent("BattleScrolls_PrefsShare", EVENT_PLAYER_ACTIVATED, function()
        self:Send()
    end)
    -- Send after group composition changes, debounced a couple of seconds so
    -- freshly joined members have their addon and LGB session ready
    local function onRosterChanged()
        rosterSendToken = rosterSendToken + 1
        local token = rosterSendToken
        zo_callLater(function()
            if token == rosterSendToken then
                self:Send()
            end
        end, ROSTER_SEND_DELAY_MS)
    end
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_PrefsShare", EVENT_GROUP_MEMBER_JOINED, onRosterChanged)
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_PrefsShare", EVENT_GROUP_MEMBER_LEFT, onRosterChanged)
end

---Unregisters event handlers for cleanup/hot reload
function prefsShare:Cleanup()
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_PrefsShare", EVENT_PLAYER_ACTIVATED)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_PrefsShare", EVENT_GROUP_MEMBER_JOINED)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_PrefsShare", EVENT_GROUP_MEMBER_LEFT)
end

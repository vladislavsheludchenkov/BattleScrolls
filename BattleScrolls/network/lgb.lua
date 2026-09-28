-----------------------------------------------------------
-- LibGroupBroadcast Handler
-- Centralized LGB handler registration for Battle Scrolls
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

local LGB = LibGroupBroadcast
if not LGB then
    -- BattleScrolls.log.Warn("LibGroupBroadcast not available")
    return
end

local handler = LGB:RegisterHandler("BattleScrolls")
handler:SetDisplayName("Battle Scrolls")
handler:SetDescription("Shares DPS and HPS data between group members using Battle Scrolls addon.")

BattleScrolls.lgbHandler = handler

-- Large payloads span multiple broadcasts and can be interrupted by a loading
-- screen. LGB completes a partially sent message before starting another on
-- the same protocol, so both copies can be queued immediately. Both protocols
-- use replaceQueuedMessages=false and their receivers upsert by identity.
-- Live meter updates and preferences should not be repeated.

---@param protocol Protocol
---@param payload table
---@return boolean queued Whether the first copy was queued
function BattleScrolls.sendLargeGroupMessage(protocol, payload)
    if not IsUnitGrouped("player") or not protocol:Send(payload) then
        return false
    end
    protocol:Send(payload)
    return true
end

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
    return
end

local handler = LGB:RegisterHandler("BattleScrolls")
handler:SetDisplayName("Battle Scrolls")
handler:SetDescription("Shares DPS and HPS data between group members using Battle Scrolls addon.")

BattleScrolls.lgbHandler = handler

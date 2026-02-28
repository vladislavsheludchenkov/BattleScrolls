-----------------------------------------------------------
-- DPSSender
-- Broadcasts personal DPS/HPS to group via DPSShare
--
-- Listens to CombatTicker for periodic updates during combat.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class DPSSender : TickListener
local dpsSender = {}
BattleScrolls.dpsSender = dpsSender

---Initialize the DPS sender and register as a tick listener
function dpsSender:Initialize()
    BattleScrolls.combatTicker:registerListener(self)
end

---TickListener callback: called every 200ms during combat with a shared calculator
---@param calc ArithmancerInstance
---@param bossCalc ArithmancerInstance|nil
function dpsSender:OnCombatTick(calc, bossCalc)
    BattleScrolls.dpsShare:SendData(
        calc:personalDPS(),
        bossCalc and bossCalc:personalDPS() or 0,
        calc:personalRawHPSOut(),
        calc:personalEffectiveHPSOut()
    )
end

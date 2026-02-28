-----------------------------------------------------------
-- CombatTicker
-- Unified 200ms combat timer that shares a single
-- ArithmancerInstance across all tick listeners (meter, sender)
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

local UPDATE_INTERVAL_MS = 300

---@class TickListener
---@field OnCombatTick fun(self: TickListener, calc: ArithmancerInstance, bossCalc: ArithmancerInstance|nil)

---@class CombatTicker : StateObserver
local combatTicker = {}
BattleScrolls.combatTicker = combatTicker

---@type TickListener[]
local listeners = {}

---Register a listener to receive tick updates during combat
---@param listener TickListener
function combatTicker:registerListener(listener)
    table.insert(listeners, listener)
end

---Unregister a previously registered tick listener
---@param listener TickListener
function combatTicker:unregisterListener(listener)
    for i = #listeners, 1, -1 do
        if listeners[i] == listener then
            table.remove(listeners, i)
            return
        end
    end
end

---Create shared ArithmancerInstances and dispatch to all listeners
local function tick()
    local state = BattleScrolls.state
    local calc = BattleScrolls.arithmancer:Make(state)
    local bossCalc = BattleScrolls.arithmancer:ForBosses(state)
    for _, listener in ipairs(listeners) do
        listener:OnCombatTick(calc, bossCalc)
    end
end

function combatTicker:OnStateInitialized()
    EVENT_MANAGER:RegisterForUpdate("BattleScrolls_CombatTicker", UPDATE_INTERVAL_MS, tick)
end

function combatTicker:OnStatePreReset()
    tick()
    EVENT_MANAGER:UnregisterForUpdate("BattleScrolls_CombatTicker")
end

function combatTicker:Initialize()
    BattleScrolls.state:RegisterObserver(self)
end

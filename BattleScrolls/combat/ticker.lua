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
---@field OnCombatTick fun(self: TickListener, calc: ArithmancerInstance)

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

---Create a shared ArithmancerInstance and dispatch to all listeners
local function tick()
    local calc = BattleScrolls.arithmancer:New(BattleScrolls.state)
    for _, listener in ipairs(listeners) do
        listener:OnCombatTick(calc)
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

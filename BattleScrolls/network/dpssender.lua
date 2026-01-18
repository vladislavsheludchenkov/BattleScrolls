-----------------------------------------------------------
-- DPSSender
-- Broadcasts personal DPS/HPS to group via DPSShare
--
-- Observes combat state and periodically sends personal
-- metrics to group members.
--
-- Update interval: 300ms during combat
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class DPSSender : StateObserver
local dpsSender = {}
BattleScrolls.dpsSender = dpsSender

---@type number Update interval in milliseconds for DPS reporting during combat
local UPDATE_INTERVAL_MS = 300

---Initialize the DPS sender and register as a state observer
function dpsSender:Initialize()
    BattleScrolls.state:RegisterObserver(self)
end

---@param force boolean|nil If true, use a snapshot of the current state
function dpsSender:ReportDps(force)
    local source = force and BattleScrolls.state:Snapshot() or BattleScrolls.state

    -- All arithmancer methods are synchronous
    local calc = BattleScrolls.arithmancer:New(source)
    local personalDPS = calc:personalDPS()
    local bossPersonalDPS = calc:bossPersonalDPS()
    local personalRawHPS = calc:personalRawHPSOut()
    local personalEffectiveHPS = calc:personalEffectiveHPSOut()
    BattleScrolls.dpsShare:SendData(
            personalDPS,
            bossPersonalDPS,
            personalRawHPS,
            personalEffectiveHPS
    )
end

---StateObserver callback: Called when combat starts
---Starts periodic DPS reporting to group
function dpsSender:OnStateInitialized()
    self:ReportDps()
    self:StartUpdating()
end

---StateObserver callback: Called when combat ends, before state reset
---Reports final DPS and stops the update loop
function dpsSender:OnStatePreReset()
    self:ReportDps(true)
    self:StopUpdating()
end

---Start the periodic display update
function dpsSender:StartUpdating()
    EVENT_MANAGER:RegisterForUpdate("BattleScrolls_DPSSender", UPDATE_INTERVAL_MS, function()
        self:ReportDps()
    end)
end

---Stop the periodic display update
function dpsSender:StopUpdating()
    EVENT_MANAGER:UnregisterForUpdate("BattleScrolls_DPSSender")
end
-----------------------------------------------------------
-- ShareCoordinator
-- Heartbeat-based TDMA protocol for encounter data sharing
--
-- Ensures only one sender transmits encounter data at a time
-- via an always-running turn cycle. Works around an LGB bug
-- where multi-frame FlexSizeDataMessage chunks from different
-- senders can corrupt each other during reassembly.
--
-- Protocols: 433 (Heartbeat), 434 (TurnDone), 435 (ShareAck)
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

-- =============================================================================
-- CONSTANTS
-- =============================================================================

local HEARTBEAT_INTERVAL_MS = 3000
local HEARTBEAT_TIMEOUT_MS = 15000
local TURN_TIMEOUT_MS = 60000
local PROBATION_MIN_MS = 6000
local PROBATION_FAILSAFE_MS = 75000
local EVENT_NAMESPACE = "BattleScrolls_ShareCoordinator"

-- =============================================================================
-- MODULE
-- =============================================================================

---@class ShareCoordinator
---@field active boolean
---@field roster table<string, number>
---@field rosterCapabilities table<string, number>
---@field currentTurnHolder string|nil
---@field inProbation boolean
---@field probationStartMs number|nil
---@field hasSeenTurnDone boolean
---@field isSending boolean
---@field sendQueue function[]
---@field heartbeatHandle number|nil
---@field turnTimeoutHandle number|nil
---@field probationFailsafeHandle number|nil
---@field heartbeatProtocol Protocol|nil
---@field turnDoneProtocol Protocol|nil
---@field ackProtocol Protocol|nil
---@field selfDisplayName string|nil
local coordinator = {
    active = false,
    roster = {},
    rosterCapabilities = {},
    currentTurnHolder = nil,
    inProbation = false,
    probationStartMs = nil,
    hasSeenTurnDone = false,
    isSending = false,
    sendQueue = {},
    heartbeatHandle = nil,
    turnTimeoutHandle = nil,
    probationFailsafeHandle = nil,
    heartbeatProtocol = nil,
    turnDoneProtocol = nil,
    ackProtocol = nil,
    selfDisplayName = nil,
}
BattleScrolls.shareCoordinator = coordinator

-- =============================================================================
-- HELPERS
-- =============================================================================

---Get the current time in milliseconds
---@return number
local function nowMs()
    return GetGameTimeMilliseconds()
end

---Cancel a zo_callLater handle if it exists
---@param handle number|nil
---@return nil
local function cancelTimer(handle)
    if handle then
        zo_removeCallLater(handle)
    end
    return nil
end

---Get a sorted list of display names from the roster
---@return string[]
function coordinator:getSortedRoster()
    local sorted = {}
    local now = nowMs()
    for name, lastMs in pairs(self.roster) do
        if name == self.selfDisplayName or (now - lastMs) < HEARTBEAT_TIMEOUT_MS then
            table.insert(sorted, name)
        end
    end
    table.sort(sorted)
    return sorted
end

---Check if a display name is still online (heartbeat within timeout)
---@param displayName string
---@return boolean
function coordinator:isOnline(displayName)
    if displayName == self.selfDisplayName then
        return true
    end
    local lastMs = self.roster[displayName]
    if not lastMs then
        return false
    end
    return (nowMs() - lastMs) < HEARTBEAT_TIMEOUT_MS
end

---Find the next turn holder after the given name in the sorted roster
---@param afterName string
---@return string|nil
function coordinator:nextInRoster(afterName)
    local sorted = self:getSortedRoster()
    if #sorted == 0 then
        return nil
    end

    -- Find the position of afterName (or the first name that sorts after it,
    -- which handles the case where afterName was pruned from the roster)
    for i, name in ipairs(sorted) do
        if name == afterName then
            return sorted[(i % #sorted) + 1]
        elseif name > afterName then
            return sorted[i]
        end
    end

    -- afterName sorts after everyone → wrap to first
    return sorted[1]
end

---Check if any group member (excluding self) can receive encounter data
---@return boolean
function coordinator:hasEncounterReceiver()
    for name, capability in pairs(self.rosterCapabilities) do
        if name ~= self.selfDisplayName and capability then
            return true
        end
    end
    return false
end

-- =============================================================================
-- TURN MANAGEMENT
-- =============================================================================

---Start the turn timeout for the current holder
function coordinator:startTurnTimeout()
    self.turnTimeoutHandle = cancelTimer(self.turnTimeoutHandle)
    if not self.currentTurnHolder then
        return
    end
    self.turnTimeoutHandle = zo_callLater(function()
        self.turnTimeoutHandle = nil
        if not self.active then
            return
        end
        BattleScrolls.log.Warn(function()
            return "ShareCoordinator: turn timeout for " .. tostring(self.currentTurnHolder)
        end)
        self:advanceTurn()
    end, TURN_TIMEOUT_MS)
end

---Advance to the next person in the roster
function coordinator:advanceTurn()
    self.turnTimeoutHandle = cancelTimer(self.turnTimeoutHandle)

    if not self.active then
        return
    end

    local sorted = self:getSortedRoster()
    if #sorted == 0 then
        self.currentTurnHolder = nil
        return
    end

    local nextHolder
    if self.currentTurnHolder then
        nextHolder = self:nextInRoster(self.currentTurnHolder)
    else
        nextHolder = sorted[1]
    end

    -- Skip offline nodes immediately
    local visited = 0
    while nextHolder and not self:isOnline(nextHolder) and visited < #sorted do
        nextHolder = self:nextInRoster(nextHolder)
        visited = visited + 1
    end

    if visited >= #sorted then
        -- Everyone is offline? Shouldn't happen (self is always online)
        self.currentTurnHolder = self.selfDisplayName
    else
        self.currentTurnHolder = nextHolder
    end

    BattleScrolls.log.Debug(function()
        return "ShareCoordinator: turn advanced to " .. tostring(self.currentTurnHolder)
    end)

    if self.currentTurnHolder == self.selfDisplayName then
        self:onMyTurn()
    else
        self:startTurnTimeout()
    end
end

---Handle when it's this node's turn
function coordinator:onMyTurn()
    if not self.active then
        return
    end

    local sorted = self:getSortedRoster()

    -- During probation: force-skip (unless mid-send)
    if self.inProbation and not self.isSending then
        BattleScrolls.log.Debug("ShareCoordinator: in probation, force-skipping turn")
        if #sorted > 1 then
            self:broadcastTurnDone(true)
        end
        -- Solo probation: stay idle. tryExitProbation will call onMyTurn when ready.
        return
    end

    -- Pop one callback from the send queue
    local callback = table.remove(self.sendQueue, 1)
    if not callback then
        if #sorted > 1 then
            -- Multi-user: broadcast skip, advance to next person
            self:broadcastTurnDone(true)
        end
        -- Solo or multi: if no data, idle. queueSend triggers onMyTurn when data arrives.
        return
    end

    if #sorted <= 1 then
        -- Solo: fire without network, drain queue
        while callback do
            BattleScrolls.log.Debug("ShareCoordinator: solo send (no network)")
            callback(false)
            callback = table.remove(self.sendQueue, 1)
        end
    else
        -- Group send: fire callback with network, wait for Ack or timeout
        self.isSending = true
        BattleScrolls.log.Debug("ShareCoordinator: sending encounter data on network")
        callback(true)
        -- Ack or turn timeout will call turnSendComplete
        self:startTurnTimeout()
    end
end

---Called when the current send is complete (Ack received or timeout)
function coordinator:turnSendComplete()
    if not self.isSending then
        return
    end
    self.isSending = false
    self:broadcastTurnDone(false)
end

---Broadcast TurnDone signal
---@param skipped boolean Whether this turn was skipped (no data)
function coordinator:broadcastTurnDone(skipped)
    if self.turnDoneProtocol and IsUnitGrouped("player") then
        self.turnDoneProtocol:Send({ skipped = skipped })
    end
    -- Advance turn locally regardless
    self:advanceTurn()
end

-- =============================================================================
-- PROBATION
-- =============================================================================

---Enter probation mode
function coordinator:enterProbation()
    self.inProbation = true
    self.probationStartMs = nowMs()
    self.hasSeenTurnDone = false
    self.currentTurnHolder = nil

    -- Start failsafe timer
    self.probationFailsafeHandle = cancelTimer(self.probationFailsafeHandle)
    self.probationFailsafeHandle = zo_callLater(function()
        self.probationFailsafeHandle = nil
        if not self.active or not self.inProbation then
            return
        end
        BattleScrolls.log.Warn("ShareCoordinator: probation failsafe triggered")
        local sorted = self:getSortedRoster()
        self.currentTurnHolder = sorted[1]
        self.inProbation = false
        if self.currentTurnHolder == self.selfDisplayName then
            self:onMyTurn()
        else
            self:startTurnTimeout()
        end
    end, PROBATION_FAILSAFE_MS)

    BattleScrolls.log.Debug("ShareCoordinator: entered probation")
end

---Try to exit probation if conditions are met
function coordinator:tryExitProbation()
    if not self.inProbation then
        return
    end

    local elapsed = nowMs() - self.probationStartMs
    if elapsed < PROBATION_MIN_MS then
        return
    end

    local sorted = self:getSortedRoster()

    -- Exit condition: seen a TurnDone, OR roster is solo
    if self.hasSeenTurnDone or #sorted <= 1 then
        self.inProbation = false
        self.probationFailsafeHandle = cancelTimer(self.probationFailsafeHandle)
        BattleScrolls.log.Debug("ShareCoordinator: exited probation")

        -- If we don't have a turn holder yet, bootstrap
        if not self.currentTurnHolder then
            if #sorted > 0 then
                self.currentTurnHolder = sorted[1]
            end
        end

        if self.currentTurnHolder == self.selfDisplayName then
            self:onMyTurn()
        elseif self.currentTurnHolder then
            self:startTurnTimeout()
        end
    end
end

-- =============================================================================
-- HEARTBEAT
-- =============================================================================

---Send a heartbeat and prune offline nodes
function coordinator:sendHeartbeat()
    if not self.active then
        return
    end

    -- Send heartbeat
    local hasData = #self.sendQueue > 0
    if self.heartbeatProtocol and IsUnitGrouped("player") then
        self.heartbeatProtocol:Send({ hasData = hasData, canReceiveEncounterData = false })
    end

    -- Prune offline nodes from roster
    local now = nowMs()
    local turnHolderPruned = false
    for name, lastMs in pairs(self.roster) do
        if name ~= self.selfDisplayName and (now - lastMs) >= HEARTBEAT_TIMEOUT_MS then
            BattleScrolls.log.Debug(function()
                return "ShareCoordinator: pruning offline node " .. name
            end)
            if name == self.currentTurnHolder then
                turnHolderPruned = true
            end
            self.roster[name] = nil
            self.rosterCapabilities[name] = nil
        end
    end

    -- If the current turn holder was pruned, advance immediately
    if turnHolderPruned and not self.isSending then
        self:advanceTurn()
    end

    -- During probation, check exit conditions each heartbeat
    if self.inProbation then
        self:tryExitProbation()
    end
end

---Start the periodic heartbeat timer
function coordinator:startHeartbeating()
    self:stopHeartbeating()

    -- Send first heartbeat immediately
    self:sendHeartbeat()

    -- Schedule periodic heartbeats
    local function heartbeatLoop()
        if not self.active then
            return
        end
        self:sendHeartbeat()
        self.heartbeatHandle = zo_callLater(heartbeatLoop, HEARTBEAT_INTERVAL_MS)
    end
    self.heartbeatHandle = zo_callLater(heartbeatLoop, HEARTBEAT_INTERVAL_MS)
end

---Stop the periodic heartbeat timer
function coordinator:stopHeartbeating()
    self.heartbeatHandle = cancelTimer(self.heartbeatHandle)
end

-- =============================================================================
-- ACTIVATION / DEACTIVATION
-- =============================================================================

---Activate the coordinator (when joining a group)
function coordinator:activate()
    if self.active then
        return
    end
    self.active = true
    self.selfDisplayName = BattleScrolls.utils.GetUndecoratedDisplayName()

    -- Self is always in the roster
    self.roster = {}
    self.roster[self.selfDisplayName] = nowMs()
    self.rosterCapabilities = {}

    -- Enter probation and start heartbeating
    self:enterProbation()
    self:startHeartbeating()

    BattleScrolls.log.Info("ShareCoordinator: activated")
end

---Deactivate the coordinator (when leaving a group)
function coordinator:deactivate()
    if not self.active then
        return
    end
    self.active = false

    self:stopHeartbeating()
    self.turnTimeoutHandle = cancelTimer(self.turnTimeoutHandle)
    self.probationFailsafeHandle = cancelTimer(self.probationFailsafeHandle)

    self.roster = {}
    self.rosterCapabilities = {}
    self.currentTurnHolder = nil
    self.inProbation = false
    self.probationStartMs = nil
    self.hasSeenTurnDone = false
    self.isSending = false
    self.sendQueue = {}

    BattleScrolls.log.Info("ShareCoordinator: deactivated")
end

-- =============================================================================
-- PROTOCOL HANDLERS
-- =============================================================================

---Handle incoming heartbeat from a group member
---@param unitTag string
---@param data table
function coordinator:onHeartbeatReceived(unitTag, data)
    if not self.active then
        return
    end
    if AreUnitsEqual(unitTag, "player") then
        return
    end

    local displayName = BattleScrolls.utils.GetUndecoratedDisplayName(unitTag)
    if not displayName or displayName == "" then
        return
    end

    self.roster[displayName] = nowMs()
    self.rosterCapabilities[displayName] = data.canReceiveEncounterData
end

---Handle incoming TurnDone from a group member
---@param unitTag string
---@param _data table
function coordinator:onTurnDoneReceived(unitTag, _data)
    if not self.active then
        return
    end
    if AreUnitsEqual(unitTag, "player") then
        return
    end

    local senderName = BattleScrolls.utils.GetUndecoratedDisplayName(unitTag)
    if not senderName or senderName == "" then
        return
    end

    -- Update roster (TurnDone is also proof of life)
    self.roster[senderName] = nowMs()

    -- Track for probation exit
    if self.inProbation then
        self.hasSeenTurnDone = true
    end

    -- Critical invariant: only advance if sender matches current turn holder
    if senderName ~= self.currentTurnHolder then
        BattleScrolls.log.Debug(function()
            return "ShareCoordinator: ignoring TurnDone from " .. senderName
                .. " (current holder: " .. tostring(self.currentTurnHolder) .. ")"
        end)

        -- During probation, use this TurnDone to sync our turn holder
        if self.inProbation then
            local nextHolder = self:nextInRoster(senderName)
            if nextHolder then
                self.currentTurnHolder = nextHolder
                BattleScrolls.log.Debug(function()
                    return "ShareCoordinator: synced turn holder to " .. nextHolder
                end)
            end
            self:tryExitProbation()
        end
        return
    end

    BattleScrolls.log.Debug(function()
        return "ShareCoordinator: received TurnDone from " .. senderName
    end)

    self:advanceTurn()
end

---Handle incoming Ack from a group member
---@param unitTag string
---@param _data table
function coordinator:onAckReceived(unitTag, _data)
    if not self.active then
        return
    end
    if AreUnitsEqual(unitTag, "player") then
        return
    end

    -- Only relevant if we're the current sender
    if not self.isSending then
        return
    end

    local senderName = BattleScrolls.utils.GetUndecoratedDisplayName(unitTag)
    BattleScrolls.log.Debug(function()
        return "ShareCoordinator: received Ack from " .. tostring(senderName)
    end)

    self:turnSendComplete()
end

---Called by encounterShare when encounter data is received from another node
---Triggers an Ack back to the sender
---@param senderDisplayName string
function coordinator:onEncounterReceived(senderDisplayName)
    if not self.active then
        return
    end
    if not self.ackProtocol then
        return
    end
    if not IsUnitGrouped("player") then
        return
    end

    BattleScrolls.log.Debug(function()
        return "ShareCoordinator: sending Ack for encounter from " .. senderDisplayName
    end)

    self.ackProtocol:Send({})
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

---Queue a send callback. Called by encounterShare:send().
---The callback receives a boolean `shouldSendNetwork` parameter.
---@param callback fun(shouldSendNetwork: boolean)
function coordinator:queueSend(callback)
    if not self.active then
        -- Not grouped: fire immediately without network send
        callback(false)
        return
    end

    -- No receivers capable of processing encounter data: skip network send
    if not self:hasEncounterReceiver() then
        callback(false)
        return
    end

    table.insert(self.sendQueue, callback)

    BattleScrolls.log.Debug(function()
        return "ShareCoordinator: queued send (queue size: " .. #self.sendQueue .. ")"
    end)

    -- If it's currently our turn and we're not already sending, trigger immediately
    if self.currentTurnHolder == self.selfDisplayName and not self.isSending and not self.inProbation then
        self:onMyTurn()
    end
end

-- =============================================================================
-- INITIALIZE
-- =============================================================================

---Initialize the coordinator: register protocols and group-change events
function coordinator:Initialize()
    local LGB = LibGroupBroadcast
    if not LGB then
        BattleScrolls.log.Warn("ShareCoordinator: LibGroupBroadcast not available")
        return
    end

    local handler = BattleScrolls.lgbHandler
    if not handler then
        return
    end

    -- Protocol 433: Heartbeat (7 data bits → FixedSizeDataMessage)
    local heartbeatProtocol = handler:DeclareProtocol(433, "BattleScrolls_Heartbeat")
    heartbeatProtocol:AddField(LGB.CreateFlagField("hasData"))
    heartbeatProtocol:AddField(LGB.CreateFlagField("canReceiveEncounterData"))
    heartbeatProtocol:AddField(LGB.CreateReservedField("reserved", 5))
    heartbeatProtocol:OnData(function(unitTag, data)
        coordinator:onHeartbeatReceived(unitTag, data)
    end)
    heartbeatProtocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })
    self.heartbeatProtocol = heartbeatProtocol

    -- Protocol 434: TurnDone (7 data bits → FixedSizeDataMessage)
    local turnDoneProtocol = handler:DeclareProtocol(434, "BattleScrolls_TurnDone")
    turnDoneProtocol:AddField(LGB.CreateFlagField("skipped"))
    turnDoneProtocol:AddField(LGB.CreateReservedField("reserved", 6))
    turnDoneProtocol:OnData(function(unitTag, data)
        coordinator:onTurnDoneReceived(unitTag, data)
    end)
    turnDoneProtocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })
    self.turnDoneProtocol = turnDoneProtocol

    -- Protocol 435: ShareAck (7 data bits → FixedSizeDataMessage)
    local ackProtocol = handler:DeclareProtocol(435, "BattleScrolls_ShareAck")
    ackProtocol:AddField(LGB.CreateReservedField("reserved", 7))
    ackProtocol:OnData(function(unitTag, data)
        coordinator:onAckReceived(unitTag, data)
    end)
    ackProtocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })
    self.ackProtocol = ackProtocol

    -- Group change events
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_MEMBER_JOINED, function()
        if not IsUnitGrouped("player") then
            return
        end
        if not self.active then
            self:activate()
        else
            -- Re-enter probation on group composition change
            self:onGroupCompositionChanged()
        end
    end)

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_MEMBER_LEFT, function()
        if not IsUnitGrouped("player") then
            self:deactivate()
        else
            self:onGroupCompositionChanged()
        end
    end)

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_TYPE_CHANGED, function()
        if IsUnitGrouped("player") then
            self:onGroupCompositionChanged()
        end
    end)

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_UPDATE, function()
        if IsUnitGrouped("player") then
            if not self.active then
                self:activate()
            else
                self:onGroupCompositionChanged()
            end
        else
            self:deactivate()
        end
    end)

    -- Check if already in a group at load time
    if IsUnitGrouped("player") then
        self:activate()
    end

    BattleScrolls.log.Info("ShareCoordinator: initialized")
end

---Handle group composition changes (member join/leave, group type change)
---Re-enters probation but does not interrupt in-flight transmissions
function coordinator:onGroupCompositionChanged()
    if not self.active then
        return
    end

    BattleScrolls.log.Debug("ShareCoordinator: group composition changed, re-entering probation")

    -- Cancel turn timeout (will be restarted after probation)
    self.turnTimeoutHandle = cancelTimer(self.turnTimeoutHandle)

    -- Re-enter probation (does not clear roster or interrupt isSending)
    self:enterProbation()
end

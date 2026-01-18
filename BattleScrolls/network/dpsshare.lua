-----------------------------------------------------------
-- DPSShare
-- Group DPS/HPS data sharing protocol for Battle Scrolls
--
-- Uses LibGroupBroadcast to share combat metrics with
-- group members. Defines the protocol format and handles
-- incoming data from other Battle Scrolls users.
--
-- Protocol fields: allTargetsDPS, bossDPS, rawHPS, effectiveHPS
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class DPSShareData
---@field allTargetsDPS number DPS against all targets
---@field bossDPS number|nil DPS against boss targets only (nil if no boss fight)
---@field rawHPS number Raw healing per second output
---@field effectiveHPS number Effective (non-overheal) healing per second output

---@class DPSShareFields
---@field allTargetsDPS NumericField LibGroupBroadcast numeric field
---@field bossDPS OptionalField LibGroupBroadcast optional numeric field
---@field rawHPS NumericField LibGroupBroadcast numeric field
---@field effectiveHPS NumericField LibGroupBroadcast numeric field
---@field maxValue number Maximum value for numeric fields (2^20 - 1)

---@class DPSShare
---@field protocol Protocol|nil LibGroupBroadcast protocol instance
---@field fields DPSShareFields|nil Protocol field definitions
local dpsShare = {}
BattleScrolls.dpsShare = dpsShare

---@alias DPSShareCallback fun(unitTag: string, allTargetsDPS: number, bossDPS: number|nil, rawHPS: number, effectiveHPS: number): void

---@type table<string, DPSShareCallback>
local callbacks = {}

---Notify all registered callbacks with the received data
---@param unitTag string The unit tag of the sender ("player" for local, group unit tag for remote)
---@param data DPSShareData The received DPS/HPS data
local notifyAllCallbacks = function(unitTag, data)
    local allTargetsDPS = data.allTargetsDPS
    local bossDPS = data.bossDPS
    local rawHPS = data.rawHPS
    local effectiveHPS = data.effectiveHPS

    for _, callback in pairs(callbacks) do
        callback(unitTag, allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
    end
end

---Initialize the DPS sharing protocol with LibGroupBroadcast
---Registers protocol fields and sets up data reception callback
function dpsShare:Initialize()
    local LGB = LibGroupBroadcast
    local handler = LGB:RegisterHandler("BattleScrolls")
    handler:SetDisplayName("Battle Scrolls")
    handler:SetDescription("Shares DPS and HPS data between group members using Battle Scrolls addon.")

    local protocol = handler:DeclareProtocol(438, "BattleScrolls_DPSHPSData")
    local allTargetsDpsField = LGB.CreateNumericField("allTargetsDPS", { minValue = 0, numBits = 20 })

    protocol:AddField(allTargetsDpsField)

    local bossDPSField = LGB.CreateOptionalField(LGB.CreateNumericField("bossDPS", { minValue = 0, numBits = 20 }))
    protocol:AddField(bossDPSField)

    local rawHPSField = LGB.CreateNumericField("rawHPS", { minValue = 0, numBits = 20, trimValues = true })
    protocol:AddField(rawHPSField)

    local effectiveHPSField = LGB.CreateNumericField("effectiveHPS", { minValue = 0, numBits = 20, trimValues = true })
    protocol:AddField(effectiveHPSField)

    protocol:OnData(notifyAllCallbacks)

    protocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })

    dpsShare.protocol = protocol

    dpsShare.fields = {
        allTargetsDPS = allTargetsDpsField,
        bossDPS = bossDPSField,
        rawHPS = rawHPSField,
        effectiveHPS = effectiveHPSField,
        maxValue = 1048575 -- 2^20 - 1
    }
end

--- @param name string The name of the callback.
--- @param callback DPSShareCallback The callback function to register.
function dpsShare:RegisterCallback(name, callback)
    callbacks[name] = callback
end

--- @param name string The name of the callback to unregister.
function dpsShare:UnregisterCallback(name)
    callbacks[name] = nil
end

---Send DPS/HPS data to group members and notify local callbacks
---@param allTargetsDPS number DPS against all targets
---@param bossDPS number|nil DPS against boss targets only
---@param rawHPS number Raw healing per second output
---@param effectiveHPS number Effective healing per second output
function dpsShare:SendData(allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
    ---@type DPSShareData
    local data = {
        allTargetsDPS = allTargetsDPS,
        bossDPS = bossDPS,
        rawHPS = rawHPS,
        effectiveHPS = effectiveHPS
    }
    if dpsShare.protocol then
        dpsShare.protocol:Send(data)
    end

    notifyAllCallbacks("player", data)
end


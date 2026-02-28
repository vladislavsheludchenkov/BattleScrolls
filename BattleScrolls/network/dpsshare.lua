-----------------------------------------------------------
-- DPSShare
-- Group DPS/HPS data sharing protocol for Battle Scrolls
--
-- Uses LibGroupBroadcast to share combat metrics with
-- group members. Defines the protocol format and handles
-- incoming data from other Battle Scrolls users.
--
-- Callbacks receive either DPSShareDamageData or DPSShareHealingData
-- as a discriminated union based on the dominant metric.
-- Old wire format (protocol 438) is classified on receive.
-- New wire formats (430 damage, 431 healing) are natively typed.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class DPSShareDamageData
---@field messageType "damage"
---@field allTargetsDPS number DPS against all targets
---@field bossDPS number|nil DPS against boss targets only (nil if no boss fight)

---@class DPSShareHealingData
---@field messageType "healing"
---@field rawHPS number Raw healing per second output
---@field effectiveHPS number Effective (non-overheal) healing per second output

---@alias DPSShareTypedData DPSShareDamageData | DPSShareHealingData

---@class DPSShare
---@field legacyProtocol Protocol|nil LibGroupBroadcast legacy protocol instance (438)
local dpsShare = {}
BattleScrolls.dpsShare = dpsShare

---@alias DPSShareCallback fun(unitTag: string, data: DPSShareTypedData): void

---@type table<string, DPSShareCallback>
local callbacks = {}

---Classify legacy 4-field data into a typed message based on dominant metric
---@param allTargetsDPS number
---@param bossDPS number|nil
---@param rawHPS number
---@param effectiveHPS number
---@return DPSShareTypedData
local function classifyLegacyData(allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
    if rawHPS > allTargetsDPS then
        return { messageType = "healing", rawHPS = rawHPS, effectiveHPS = effectiveHPS }
    else
        return { messageType = "damage", allTargetsDPS = allTargetsDPS, bossDPS = bossDPS }
    end
end

---Notify all registered callbacks with typed data
---@param unitTag string The unit tag of the sender ("player" for local, group unit tag for remote)
---@param data DPSShareTypedData The typed DPS or HPS data
local notifyAllCallbacks = function(unitTag, data)
    for _, callback in pairs(callbacks) do
        callback(unitTag, data)
    end
end

---@diagnostic disable-next-line: unused-function, unused-local -- used in phase 2 when sending new format
local function encodeMetric(x)
    if x > 1000000 then
        return 1023 -- corresponds to math.huge
    elseif x <= 99 then
        return math.floor(math.max(x, 0))
    else
        return 100 + zo_round(922 * math.log(x / 100) / math.log(10000))
    end
end

local function decodeMetric(i)
    if i >= 1023 then
        return math.huge
    elseif i <= 99 then
        return i
    else
        return zo_round(100 * 10000 ^ ((i - 100) / 922))
    end
end

---Initialize the DPS sharing protocols with LibGroupBroadcast
---Registers legacy protocol (438) and new typed protocols (430 damage, 431 healing)
function dpsShare:Initialize()
    local LGB = LibGroupBroadcast
    local handler = BattleScrolls.lgbHandler
    if not handler then
        return
    end

    -- Legacy protocol (438): 4-field format, classified on receive
    local legacyProtocol = handler:DeclareProtocol(438, "BattleScrolls_DPSHPSData")
    legacyProtocol:AddField(LGB.CreateNumericField("allTargetsDPS", { minValue = 0, numBits = 20 }))
    legacyProtocol:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("bossDPS", { minValue = 0, numBits = 20 })))
    legacyProtocol:AddField(LGB.CreateNumericField("rawHPS", { minValue = 0, numBits = 20, trimValues = true }))
    legacyProtocol:AddField(LGB.CreateNumericField("effectiveHPS", { minValue = 0, numBits = 20, trimValues = true }))
    legacyProtocol:OnData(function(unitTag, data)
        if AreUnitsEqual(unitTag, "player") then return end
        local typed = classifyLegacyData(data.allTargetsDPS, data.bossDPS, data.rawHPS, data.effectiveHPS)
        notifyAllCallbacks(unitTag, typed)
    end)
    legacyProtocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })
    dpsShare.legacyProtocol = legacyProtocol

    -- Damage protocol (430): encoded allTargetsDPS + optional bossDPS
    local damageProtocol = handler:DeclareProtocol(430, "BattleScrolls_DamageData")
    damageProtocol:AddField(LGB.CreateNumericField("encodedAllDPS", { minValue = 0, numBits = 10 }))
    damageProtocol:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("encodedBossDPS", { minValue = 0, numBits = 10 })))
    damageProtocol:OnData(function(unitTag, data)
        if AreUnitsEqual(unitTag, "player") then return end
        local allTargetsDPS = decodeMetric(data.encodedAllDPS)
        local bossDPS = data.encodedBossDPS and decodeMetric(data.encodedBossDPS) or nil
        ---@type DPSShareDamageData
        local typed = { messageType = "damage", allTargetsDPS = allTargetsDPS, bossDPS = bossDPS }
        notifyAllCallbacks(unitTag, typed)
    end)
    damageProtocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })

    -- Healing protocol (431): encoded rawHPS + effectiveHPS
    local healingProtocol = handler:DeclareProtocol(431, "BattleScrolls_HealingData")
    healingProtocol:AddField(LGB.CreateNumericField("encodedRawHPS", { minValue = 0, numBits = 10 }))
    healingProtocol:AddField(LGB.CreateNumericField("encodedEffectiveHPS", { minValue = 0, numBits = 10 }))
    healingProtocol:OnData(function(unitTag, data)
        if AreUnitsEqual(unitTag, "player") then return end
        local rawHPS = decodeMetric(data.encodedRawHPS)
        local effectiveHPS = decodeMetric(data.encodedEffectiveHPS)
        ---@type DPSShareHealingData
        local typed = { messageType = "healing", rawHPS = rawHPS, effectiveHPS = effectiveHPS }
        notifyAllCallbacks(unitTag, typed)
    end)
    healingProtocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })
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
---Sends old format over the wire (phase 1). Local callbacks receive typed data.
---@param allTargetsDPS number DPS against all targets
---@param bossDPS number|nil DPS against boss targets only
---@param rawHPS number Raw healing per second output
---@param effectiveHPS number Effective healing per second output
function dpsShare:SendData(allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
    -- Network: still old format (phase 1)
    -- LGB will log a warning and will not send anything when trying to send data while not grouped
    if dpsShare.legacyProtocol and IsUnitGrouped("player") then
        dpsShare.legacyProtocol:Send({
            allTargetsDPS = allTargetsDPS,
            bossDPS = bossDPS,
            rawHPS = rawHPS,
            effectiveHPS = effectiveHPS,
        })
    end

    -- Local: classify and emit typed
    local typed = classifyLegacyData(allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
    notifyAllCallbacks("player", typed)
end


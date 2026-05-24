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
-- Old wire format (protocol 438) is read-only and classified on receive.
-- New wire formats (430 damage, 431 healing) are sent and received natively typed.
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
---@field damageProtocol Protocol|nil LibGroupBroadcast damage protocol instance (430)
---@field healingProtocol Protocol|nil LibGroupBroadcast healing protocol instance (431)
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
local function classifyData(allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
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

-- Encoding: 0..literalMax are stored exactly, (literalMax+1)..maxVal-1 use log scale, maxVal = overflow sentinel.
-- literalMax is chosen so that the log step at the boundary is >= 1 (every index decodes to a distinct integer).
local LOG_CAP = BattleScrolls.constants.huge -- 2 ^ 20

local function makeCodec(numBits, literalMax)
    local maxVal = 2 ^ numBits - 1
    local logBase = literalMax + 1
    local logRange = maxVal - logBase - 1
    local logFactor = LOG_CAP / logBase

    local function encode(x)
        if x > LOG_CAP then return maxVal end
        if x <= literalMax then return math.floor(math.max(x, 0)) end
        return logBase + zo_round(logRange * math.log(x / logBase) / math.log(logFactor))
    end

    local function decode(i)
        if i >= maxVal then return math.huge end
        if i <= literalMax then return i end
        return zo_round(logBase * logFactor ^ ((i - logBase) / logRange))
    end

    return encode, decode
end

local encode11, decode11 = makeCodec(11, 255)
local encode12, decode12 = makeCodec(12, 511)

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
        local typed = classifyData(data.allTargetsDPS, data.bossDPS, data.rawHPS, data.effectiveHPS)
        notifyAllCallbacks(unitTag, typed)
    end)
    legacyProtocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })

    -- Damage protocol (430): encoded allTargetsDPS + optional bossDPS
    local damageProtocol = handler:DeclareProtocol(430, "BattleScrolls_DamageData")
    damageProtocol:AddField(LGB.CreateNumericField("encodedAllDPS", { minValue = 0, numBits = 11 }))
    damageProtocol:AddField(LGB.CreateOptionalField(LGB.CreateNumericField("encodedBossDPS", { minValue = 0, numBits = 12 })))
    damageProtocol:OnData(function(unitTag, data)
        if AreUnitsEqual(unitTag, "player") then return end
        local allTargetsDPS = decode11(data.encodedAllDPS)
        local bossDPS = data.encodedBossDPS and decode12(data.encodedBossDPS) or nil
        ---@type DPSShareDamageData
        local typed = { messageType = "damage", allTargetsDPS = allTargetsDPS, bossDPS = bossDPS }
        notifyAllCallbacks(unitTag, typed)
    end)
    damageProtocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })
    dpsShare.damageProtocol = damageProtocol

    -- Healing protocol (431): encoded rawHPS + effectiveHPS
    local healingProtocol = handler:DeclareProtocol(431, "BattleScrolls_HealingData")
    healingProtocol:AddField(LGB.CreateNumericField("encodedRawHPS", { minValue = 0, numBits = 12 }))
    healingProtocol:AddField(LGB.CreateNumericField("encodedEffectiveHPS", { minValue = 0, numBits = 12 }))
    healingProtocol:OnData(function(unitTag, data)
        if AreUnitsEqual(unitTag, "player") then return end
        local rawHPS = decode12(data.encodedRawHPS)
        local effectiveHPS = decode12(data.encodedEffectiveHPS)
        ---@type DPSShareHealingData
        local typed = { messageType = "healing", rawHPS = rawHPS, effectiveHPS = effectiveHPS }
        notifyAllCallbacks(unitTag, typed)
    end)
    healingProtocol:Finalize({ isRelevantInCombat = true, replaceQueuedMessages = true })
    dpsShare.healingProtocol = healingProtocol
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
---Sends the new typed format over the wire. Local callbacks receive typed data.
---@param allTargetsDPS number DPS against all targets
---@param bossDPS number|nil DPS against boss targets only
---@param rawHPS number Raw healing per second output
---@param effectiveHPS number Effective healing per second output
function dpsShare:SendData(allTargetsDPS, bossDPS, rawHPS, effectiveHPS)
    local typed = classifyData(allTargetsDPS, bossDPS, rawHPS, effectiveHPS)

    -- Network: protocol 438 remains receive-only for older clients.
    -- LGB logs and drops sends while not grouped, so avoid the call when solo.
    if IsUnitGrouped("player") then
        if typed.messageType == "healing" then
            if dpsShare.healingProtocol then
                dpsShare.healingProtocol:Send({
                    encodedRawHPS = encode12(typed.rawHPS),
                    encodedEffectiveHPS = encode12(typed.effectiveHPS),
                })
            end
        elseif dpsShare.damageProtocol then
            dpsShare.damageProtocol:Send({
                encodedAllDPS = encode11(typed.allTargetsDPS),
                encodedBossDPS = typed.bossDPS and encode12(typed.bossDPS) or nil,
            })
        end
    end

    -- Local: emit exact typed values without encode/decode loss.
    notifyAllCallbacks("player", typed)
end

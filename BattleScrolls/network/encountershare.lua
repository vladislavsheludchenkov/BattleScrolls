-----------------------------------------------------------
-- EncounterShare
-- Post-combat encounter data sharing via LibGroupBroadcast
--
-- Send-only version for 1.3.3: broadcasts encounter stats
-- to group members but does not process incoming data.
-- Uses LGB protocol 432.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class EncounterShare
---@field protocol Protocol|nil LibGroupBroadcast encounter share protocol instance (432)
local encounterShare = {}
BattleScrolls.encounterShare = encounterShare

-- =============================================================================
-- CONSTANTS
-- =============================================================================

local TIMESTAMP_LOW_MASK = 131071 -- 2^17 - 1

-- =============================================================================
-- HELPERS
-- =============================================================================

---Extract boss number (0-indexed) from a boss unit tag string
---@param tag string Boss unit tag like "boss1", "boss2", etc.
---@return number bossNum 0-indexed boss number (0=boss1, 11=boss12)
local function bossTagToNum(tag)
    return tonumber(tag:match("boss(%d+)")) - 1
end

-- =============================================================================
-- SEND PAYLOAD
-- =============================================================================

---Send pre-built SharedEncounterData via LGB
---@param sharedData SharedEncounterData The encounter data to send
---@param timestampS number The encounter timestamp (for wire format)
function encounterShare:send(sharedData, timestampS)
    if not encounterShare.protocol then
        return
    end

    -- Convert SharedEncounterData → wire payload
    local timestampLow17 = BitAnd(timestampS, TIMESTAMP_LOW_MASK)

    -- Convert boss damage: string tags → 0-indexed numbers
    ---@type { bossTag: number, tagSeq: number, damage: number, critPercent: number, dotPercent: number, aoePercent: number, magicalPercent: number }[]
    local wireBossDamage = {}
    for _, bd in ipairs(sharedData.bossDamage) do
        table.insert(wireBossDamage, {
            bossTag = bossTagToNum(bd.bossTag),
            tagSeq = bd.tagSeq,
            damage = bd.damage,
            critPercent = bd.critPercent,
            dotPercent = bd.dotPercent,
            aoePercent = bd.aoePercent,
            magicalPercent = bd.magicalPercent,
        })
    end

    ---@type { bossTag: number, tagSeq: number, damage: number }[]
    local wireBossDamageTaken = {}
    for _, bdt in ipairs(sharedData.bossDamageTaken) do
        table.insert(wireBossDamageTaken, {
            bossTag = bossTagToNum(bdt.bossTag),
            tagSeq = bdt.tagSeq,
            damage = bdt.damage,
        })
    end

    local payload = {
        timestampLow17 = timestampLow17,
        durationMs = sharedData.durationMs,
        totalDamage = sharedData.totalDamage,
        critPercent = sharedData.critPercent,
        dotPercent = sharedData.dotPercent,
        aoePercent = sharedData.aoePercent,
        maxHit = sharedData.maxHit,
        damageByType = sharedData.damageByType,
        bossDamage = wireBossDamage,
        totalDamageTaken = sharedData.totalDamageTaken,
        bossDamageTaken = wireBossDamageTaken,
        healing = sharedData.healing,
        playerAliveTimeMs = sharedData.aliveTimeMs,
    }

    BattleScrolls.shareCoordinator:queueSend(function(shouldSendNetwork)
        if shouldSendNetwork then
            ---@diagnostic disable-next-line: invisible -- intentional: toggle finalized to allow sending
            encounterShare.protocol.finalized = true
            encounterShare.protocol:Send(payload)
            ---@diagnostic disable-next-line: invisible -- intentional: block incoming deserialization
            encounterShare.protocol.finalized = false
        end
        BattleScrolls.log.Debug("EncounterShare: sent encounter data")
    end)
end

-- =============================================================================
-- INITIALIZE
-- =============================================================================

---Initialize the encounter sharing protocol with LibGroupBroadcast
function encounterShare:Initialize()
    local LGB = LibGroupBroadcast
    if not LGB then
        BattleScrolls.log.Warn("EncounterShare: LibGroupBroadcast not available")
        return
    end

    local handler = BattleScrolls.lgbHandler
    if not handler then
        return
    end

    -- Declare protocol 432 (automatically uses FlexSizeDataMessage for variable-length payloads)
    local shareProtocol = handler:DeclareProtocol(432, "BattleScrolls_EncounterShare")

    shareProtocol:AddField(LGB.CreateNumericField("timestampLow17", { minValue = 0, numBits = 17 }))
    shareProtocol:AddField(LGB.CreateNumericField("durationMs", { minValue = 0, numBits = 24 }))
    shareProtocol:AddField(LGB.CreateNumericField("totalDamage", { minValue = 0, numBits = 30 }))
    shareProtocol:AddField(LGB.CreatePercentageField("critPercent", { numBits = 10 }))
    shareProtocol:AddField(LGB.CreatePercentageField("dotPercent", { numBits = 10 }))
    shareProtocol:AddField(LGB.CreatePercentageField("aoePercent", { numBits = 10 }))
    shareProtocol:AddField(LGB.CreateNumericField("maxHit", { minValue = 0, numBits = 24 }))

    shareProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("damageByType", {
            LGB.CreateNumericField("type", { minValue = 0, numBits = 4 }),
            LGB.CreateNumericField("damage", { minValue = 0, numBits = 30 }),
        }),
        { maxLength = 13 }
    ))

    shareProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("bossDamage", {
            LGB.CreateNumericField("bossTag", { minValue = 0, numBits = 4 }),
            LGB.CreateNumericField("tagSeq", { minValue = 0, numBits = 3 }),
            LGB.CreateNumericField("damage", { minValue = 0, numBits = 30 }),
            LGB.CreatePercentageField("critPercent", { numBits = 10 }),
            LGB.CreatePercentageField("dotPercent", { numBits = 10 }),
            LGB.CreatePercentageField("aoePercent", { numBits = 10 }),
            LGB.CreatePercentageField("magicalPercent", { numBits = 10 }),
        }),
        { maxLength = 24 }
    ))

    shareProtocol:AddField(LGB.CreateNumericField("totalDamageTaken", { minValue = 0, numBits = 30 }))

    shareProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("bossDamageTaken", {
            LGB.CreateNumericField("bossTag", { minValue = 0, numBits = 4 }),
            LGB.CreateNumericField("tagSeq", { minValue = 0, numBits = 3 }),
            LGB.CreateNumericField("damage", { minValue = 0, numBits = 30 }),
        }),
        { maxLength = 24 }
    ))

    shareProtocol:AddField(LGB.CreateOptionalField(
        LGB.CreateTableField("healing", {
            LGB.CreateNumericField("rawOut", { minValue = 0, numBits = 30 }),
            LGB.CreateNumericField("effectiveOut", { minValue = 0, numBits = 30 }),
            LGB.CreateNumericField("rawSelf", { minValue = 0, numBits = 30 }),
            LGB.CreateNumericField("effectiveSelf", { minValue = 0, numBits = 30 }),
        })
    ))

    shareProtocol:AddField(LGB.CreateOptionalField(
        LGB.CreateNumericField("playerAliveTimeMs", { minValue = 0, numBits = 24 })
    ))

    shareProtocol:OnData(function() end)
    shareProtocol:Finalize({ isRelevantInCombat = false, replaceQueuedMessages = false })
    ---@diagnostic disable-next-line: invisible -- intentional: block incoming deserialization
    shareProtocol.finalized = false
    encounterShare.protocol = shareProtocol

    BattleScrolls.log.Info("EncounterShare: initialized")
end

-----------------------------------------------------------
-- EncounterShare
-- Post-combat encounter data sharing via LibGroupBroadcast
--
-- Defines the protocol format for sharing combat stats with
-- group members after each fight. Uses LGB protocol 437
-- with a required setupHash. The one-bit reserved field before
-- setupHash preserves the old optional-field wire layout.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class EncounterShare
---@field protocol Protocol|nil LibGroupBroadcast encounter share protocol instance (437)
local encounterShare = {}
BattleScrolls.encounterShare = encounterShare

-- =============================================================================
-- CONSTANTS
-- =============================================================================

local TIMESTAMP_LOW_MASK = 131071 -- 2^17 - 1
local TIMESTAMP_HALF_RANGE = 43200 -- 12 hours in seconds
local TIMESTAMP_FULL_RANGE = 131072 -- 2^17

-- =============================================================================
-- CALLBACKS
-- =============================================================================

---@alias EncounterShareCallback fun(unitTag: string, sharedData: SharedEncounterData)

---@type table<string, EncounterShareCallback>
local callbacks = {}

-- =============================================================================
-- HELPERS
-- =============================================================================

---Extract boss number (0-indexed) from a boss unit tag string
---@param tag string Boss unit tag like "boss1", "boss2", etc.
---@return number bossNum 0-indexed boss number (0=boss1, 11=boss12)
local function bossTagToNum(tag)
    return tonumber(tag:match("boss(%d+)")) - 1
end

---Reconstruct boss unit tag string from 0-indexed boss number
---@param bossNum number 0-indexed boss number
---@return string tag Boss unit tag like "boss1", "boss2", etc.
local function numToBossTag(bossNum)
    return "boss" .. (bossNum + 1)
end

---Notify all registered callbacks with received data
---@param unitTag string The unit tag of the sender
---@param sharedData SharedEncounterData The received encounter data
local function notifyAllCallbacks(unitTag, sharedData)
    for _, callback in pairs(callbacks) do
        callback(unitTag, sharedData)
    end
end

-- =============================================================================
-- CALLBACK REGISTRATION
-- =============================================================================

---Register a callback for incoming encounter share data
---@param name string The name of the callback
---@param callback EncounterShareCallback The callback function
function encounterShare:RegisterCallback(name, callback)
    callbacks[name] = callback
end

---Unregister a callback
---@param name string The name of the callback to unregister
function encounterShare:UnregisterCallback(name)
    callbacks[name] = nil
end

-- =============================================================================
-- ON RECEIVE
-- =============================================================================

---Handle incoming encounter share data from LGB
---@param unitTag string Unit tag of the sender
---@param data table Raw protocol data from LGB
local function onReceive(unitTag, data)
    if AreUnitsEqual(unitTag, "player") then
        return
    end

    -- Bidirectional privacy: if we don't share our encounter history,
    -- we don't receive or display others' shared encounters either.
    if not BattleScrolls.storage:ShouldShareEncounterHistory() then
        return
    end

    -- Reconstruct full timestamp from 17 low bits
    -- Handle clock drift in both directions (sender ahead or behind)
    local now = GetTimeStamp()
    local highBits = now - BitAnd(now, TIMESTAMP_LOW_MASK)
    local reconstructed = highBits + data.timestampLow17
    if reconstructed > now + TIMESTAMP_HALF_RANGE then
        reconstructed = reconstructed - TIMESTAMP_FULL_RANGE
    elseif reconstructed < now - TIMESTAMP_HALF_RANGE then
        reconstructed = reconstructed + TIMESTAMP_FULL_RANGE
    end

    -- Convert boss damage array: numeric bossTag back to string
    ---@type SharedBossDamage[]
    local bossDamage = {}
    if data.bossDamage then
        for _, entry in ipairs(data.bossDamage) do
            table.insert(bossDamage, {
                bossTag = numToBossTag(entry.bossTag),
                tagSeq = entry.tagSeq,
                damage = entry.damage,
                critPercent = entry.critPercent,
                dotPercent = entry.dotPercent,
                aoePercent = entry.aoePercent,
                magicalPercent = entry.magicalPercent,
            })
        end
    end

    -- Convert boss damage taken array: numeric bossTag back to string
    ---@type SharedBossDamageTaken[]
    local bossDamageTaken = {}
    if data.bossDamageTaken then
        for _, entry in ipairs(data.bossDamageTaken) do
            table.insert(bossDamageTaken, {
                bossTag = numToBossTag(entry.bossTag),
                tagSeq = entry.tagSeq,
                damage = entry.damage,
            })
        end
    end

    -- Convert deaths: timeOffsetMs stays as-is (already relative to fight start)
    ---@type SharedDeaths|nil
    local deaths = nil
    if data.deaths then
        deaths = {
            deathCount = data.deaths.deathCount,
            first = data.deaths.first,
            last = data.deaths.last,
        }
    end

    ---@type SharedEncounterData
    local sharedData = {
        timestampS = reconstructed,
        durationMs = data.durationMs,
        totalDamage = data.totalDamage,
        critPercent = data.critPercent,
        dotPercent = data.dotPercent,
        aoePercent = data.aoePercent,
        maxHit = data.maxHit,
        damageByType = data.damageByType or {},
        bossDamage = bossDamage,
        totalDamageTaken = data.totalDamageTaken,
        bossDamageTaken = bossDamageTaken,
        healing = data.healing,
        aliveTimeMs = data.playerAliveTimeMs,
        topDamageTakenAbilities = data.topDamageTakenAbilities or {},
        deaths = deaths,
        setupHash = data.setupHash,
    }

    notifyAllCallbacks(unitTag, sharedData)
end

-- =============================================================================
-- SEND PAYLOAD
-- =============================================================================

---Send pre-built SharedEncounterData via LGB
---@param sharedData SharedEncounterData The encounter data to send
---@param timestampS number The encounter timestamp (for wire format)
---@param setupHash number 16-bit setup hash (protocol 437)
function encounterShare:send(sharedData, timestampS, setupHash)
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

    -- Convert deaths for wire format
    local wireDeaths = nil
    if sharedData.deaths then
        wireDeaths = {
            deathCount = sharedData.deaths.deathCount,
            first = sharedData.deaths.first,
            last = sharedData.deaths.last,
        }
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
        topDamageTakenAbilities = sharedData.topDamageTakenAbilities,
        deaths = wireDeaths,
        setupHash = setupHash,
    }

    -- Store setupHash on sharedData for local callbacks
    sharedData.setupHash = setupHash

    -- Privacy: only broadcast to the group when encounter-history sharing is on.
    -- The local "player" callback still fires so the player's own Journal works.
    if IsUnitGrouped("player") and BattleScrolls.storage:ShouldShareEncounterHistory() then
        encounterShare.protocol:Send(payload)
    end
    notifyAllCallbacks("player", sharedData)
    -- BattleScrolls.log.Debug("EncounterShare: sent encounter data")
end

-- =============================================================================
-- INITIALIZE
-- =============================================================================

---Adds all shared encounter data fields to a protocol
---@param protocol Protocol The protocol to add fields to
---@param LGB table LibGroupBroadcast reference
local function addEncounterFields(protocol, LGB)
    protocol:AddField(LGB.CreateNumericField("timestampLow17", { minValue = 0, numBits = 17, trimValues = true }))
    protocol:AddField(LGB.CreateNumericField("durationMs", { minValue = 0, numBits = 24, trimValues = true }))
    protocol:AddField(LGB.CreateNumericField("totalDamage", { minValue = 0, numBits = 30, trimValues = true }))
    protocol:AddField(LGB.CreatePercentageField("critPercent", { numBits = 10, trimValues = true }))
    protocol:AddField(LGB.CreatePercentageField("dotPercent", { numBits = 10, trimValues = true }))
    protocol:AddField(LGB.CreatePercentageField("aoePercent", { numBits = 10, trimValues = true }))
    protocol:AddField(LGB.CreateNumericField("maxHit", { minValue = 0, numBits = 24, trimValues = true }))

    protocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("damageByType", {
            LGB.CreateNumericField("type", { minValue = 0, numBits = 4, trimValues = true }),
            LGB.CreateNumericField("damage", { minValue = 0, numBits = 30, trimValues = true }),
        }),
        { maxLength = 13 }
    ))

    protocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("bossDamage", {
            LGB.CreateNumericField("bossTag", { minValue = 0, numBits = 4, trimValues = true }),
            LGB.CreateNumericField("tagSeq", { minValue = 0, numBits = 3, trimValues = true }),
            LGB.CreateNumericField("damage", { minValue = 0, numBits = 30, trimValues = true }),
            LGB.CreatePercentageField("critPercent", { numBits = 10, trimValues = true }),
            LGB.CreatePercentageField("dotPercent", { numBits = 10, trimValues = true }),
            LGB.CreatePercentageField("aoePercent", { numBits = 10, trimValues = true }),
            LGB.CreatePercentageField("magicalPercent", { numBits = 10, trimValues = true }),
        }),
        { maxLength = 24 }
    ))

    protocol:AddField(LGB.CreateNumericField("totalDamageTaken", { minValue = 0, numBits = 30, trimValues = true }))

    protocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("bossDamageTaken", {
            LGB.CreateNumericField("bossTag", { minValue = 0, numBits = 4, trimValues = true }),
            LGB.CreateNumericField("tagSeq", { minValue = 0, numBits = 3, trimValues = true }),
            LGB.CreateNumericField("damage", { minValue = 0, numBits = 30, trimValues = true }),
        }),
        { maxLength = 24 }
    ))

    protocol:AddField(LGB.CreateOptionalField(
        LGB.CreateTableField("healing", {
            LGB.CreateNumericField("rawOut", { minValue = 0, numBits = 30, trimValues = true }),
            LGB.CreateNumericField("effectiveOut", { minValue = 0, numBits = 30, trimValues = true }),
            LGB.CreateNumericField("rawSelf", { minValue = 0, numBits = 30, trimValues = true }),
            LGB.CreateNumericField("effectiveSelf", { minValue = 0, numBits = 30, trimValues = true }),
        })
    ))

    protocol:AddField(LGB.CreateOptionalField(
        LGB.CreateNumericField("playerAliveTimeMs", { minValue = 0, numBits = 24, trimValues = true })
    ))

    protocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("topDamageTakenAbilities", {
            LGB.CreateNumericField("abilityId", { minValue = 0, numBits = 20, trimValues = true }),
            LGB.CreatePercentageField("damagePercent", { numBits = 10, trimValues = true }),
        }),
        { maxLength = 5 }
    ))

    protocol:AddField(LGB.CreateOptionalField(
        LGB.CreateTableField("deaths", {
            LGB.CreateNumericField("deathCount", { minValue = 1, numBits = 4, trimValues = true }),
            LGB.CreateTableField("first", {
                LGB.CreateNumericField("timeOffsetMs", { minValue = 0, numBits = 24, trimValues = true }),
                LGB.CreateArrayField(
                    LGB.CreateTableField("attacks", {
                        LGB.CreateNumericField("abilityId", { minValue = 0, numBits = 20, trimValues = true }),
                        LGB.CreateNumericField("damage", { minValue = 0, maxValue = 102300, numBits = 10, precision = 100, trimValues = true }),
                    }),
                    { maxLength = 6 }
                ),
            }),
            LGB.CreateOptionalField(
                LGB.CreateTableField("last", {
                    LGB.CreateNumericField("timeOffsetMs", { minValue = 0, numBits = 24, trimValues = true }),
                    LGB.CreateArrayField(
                        LGB.CreateTableField("attacks", {
                            LGB.CreateNumericField("abilityId", { minValue = 0, numBits = 20, trimValues = true }),
                            LGB.CreateNumericField("damage", { minValue = 0, maxValue = 102300, numBits = 10, precision = 100, trimValues = true }),
                        }),
                        { maxLength = 6 }
                    ),
                })
            ),
        })
    ))
end

---Initialize the encounter sharing protocol with LibGroupBroadcast
function encounterShare:Initialize()
    local LGB = LibGroupBroadcast
    if not LGB then
        -- BattleScrolls.log.Warn("EncounterShare: LibGroupBroadcast not available")
        return
    end

    local handler = BattleScrolls.lgbHandler
    if not handler then
        return
    end

    local protocol = handler:DeclareProtocol(437, "BattleScrolls_EncounterShareV2")
    addEncounterFields(protocol, LGB)
    protocol:AddField(LGB.CreateReservedField("reservedSetupHashIsNil", 1))
    protocol:AddField(LGB.CreateNumericField("setupHash", { minValue = 0, numBits = 16, trimValues = true }))
    protocol:OnData(onReceive)
    protocol:Finalize({ isRelevantInCombat = false, replaceQueuedMessages = false })
    encounterShare.protocol = protocol

    -- BattleScrolls.log.Info("EncounterShare: initialized")
end

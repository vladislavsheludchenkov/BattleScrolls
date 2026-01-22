if not SemisPlaygroundCheckAccess() then
    return
end

-- Binary Storage Encoding Module for BattleScrolls
-- Encounter and instance encoding/decoding using BitEncoder/BitDecoder from bitcodec.lua

BattleScrolls = BattleScrolls or {}

---Binary storage module for encoding/decoding combat data
---@class BinaryStorage
local binaryStorage = {}
BattleScrolls.binaryStorage = binaryStorage

local CURRENT_VERSION = 7

-- Import BitEncoder/BitDecoder from bitcodec module
local BitEncoder = BattleScrolls.bitcodec.BitEncoder
local BitDecoder = BattleScrolls.bitcodec.BitDecoder

-- =============================================================================
-- BIT ALLOCATION CONSTANTS
-- =============================================================================

---Bit width constants for binary encoding/decoding
---@class BitWidthConstants
---@field TOTAL number 30 bits - damage/healing totals (up to ~1 billion)
---@field TICK_VALUE number 24 bits - individual tick values (up to 16M)
---@field COUNT number 16 bits - tick/proc counts (up to 65535)
---@field ABILITY_ID number 20 bits - ability IDs (up to 1M, ESO uses ~200K)
---@field UNIT_ID number 24 bits - unit IDs (up to 16M)
---@field TIME_MS number 24 bits - duration/time in ms (up to ~4.6 hours)
---@field EFFECT_TYPE number 4 bits - effect type enum (up to 16 types)
---@field MAX_STACKS number 4 bits - max stacks (up to 15)
---@field APPLICATIONS number 12 bits - effect applications (up to 4095)
---@field INTERVAL_MS number 16 bits - proc interval in ms (up to 65535)
---@field MAP_COUNT number 16 bits - map/array count (up to 65535 entries)

---@type BitWidthConstants
local BITS = {
    -- Damage/healing totals (30 bits = up to ~1 billion)
    TOTAL = 30,

    -- Individual tick values (24 bits = up to 16M)
    TICK_VALUE = 24,

    -- Counts (16 bits = up to 65535)
    COUNT = 16,

    -- Ability ID (20 bits = up to 1M, ESO uses ~200K)
    ABILITY_ID = 20,

    -- Unit ID (24 bits = up to 16M)
    UNIT_ID = 24,

    -- Duration/time in ms (24 bits = up to ~4.6 hours)
    TIME_MS = 24,

    -- Effect type (4 bits = up to 16 types)
    EFFECT_TYPE = 4,

    -- Max stacks (4 bits = up to 15 stacks)
    MAX_STACKS = 4,

    -- Applications (12 bits = up to 4095)
    APPLICATIONS = 12,

    -- Proc interval (16 bits = up to 65535 ms)
    INTERVAL_MS = 16,

    -- Map/array count (16 bits = up to 65535 entries)
    MAP_COUNT = 16,
}


-- =============================================================================
-- LOW-LEVEL WRITE HELPERS
-- =============================================================================

---Writes a DamageBreakdown to encoder
---@param encoder BitEncoder
---@param breakdown DamageBreakdown
local function writeDamageBreakdown(encoder, breakdown)
    encoder:writeUInt(breakdown.total or 0, BITS.TOTAL)
    encoder:writeUInt(breakdown.rawTotal or breakdown.total or 0, BITS.TOTAL)
    encoder:writeUInt(breakdown.ticks or 0, BITS.COUNT)
    encoder:writeUInt(breakdown.critTicks or 0, BITS.COUNT)
    encoder:writeUInt(breakdown.minTick or 0, BITS.TICK_VALUE)
    encoder:writeUInt(breakdown.maxTick or 0, BITS.TICK_VALUE)
end

---Reads a DamageBreakdown from decoder
---@param decoder BitDecoder
---@return DamageBreakdown
local function readDamageBreakdown(decoder)
    return BattleScrolls.structures.makeDamageBreakdown(
        decoder:readUInt(BITS.TOTAL),
        decoder:readUInt(BITS.TOTAL),
        decoder:readUInt(BITS.COUNT),
        decoder:readUInt(BITS.COUNT),
        decoder:readUInt(BITS.TICK_VALUE),
        decoder:readUInt(BITS.TICK_VALUE)
    )
end

---Writes a HealingTotals to encoder
---@param encoder BitEncoder
---@param totals HealingTotals|nil
local function writeHealingTotals(encoder, totals)
    encoder:writeUInt(totals and totals.raw or 0, BITS.TOTAL)
    encoder:writeUInt(totals and totals.real or 0, BITS.TOTAL)
    encoder:writeUInt(totals and totals.overheal or 0, BITS.TOTAL)
end

---Reads a HealingTotals from decoder
---@param decoder BitDecoder
---@return HealingTotals
local function readHealingTotals(decoder)
    return BattleScrolls.structures.makeHealingTotals(
        decoder:readUInt(BITS.TOTAL),
        decoder:readUInt(BITS.TOTAL),
        decoder:readUInt(BITS.TOTAL)
    )
end

---Writes a HealingBreakdown to encoder
---@param encoder BitEncoder
---@param breakdown HealingBreakdown
local function writeHealingBreakdown(encoder, breakdown)
    encoder:writeUInt(breakdown.raw or 0, BITS.TOTAL)
    encoder:writeUInt(breakdown.real or 0, BITS.TOTAL)
    encoder:writeUInt(breakdown.overheal or 0, BITS.TOTAL)
    encoder:writeUInt(breakdown.ticks or 0, BITS.COUNT)
    encoder:writeUInt(breakdown.critTicks or 0, BITS.COUNT)
    encoder:writeUInt(breakdown.minTick or 0, BITS.TICK_VALUE)
    encoder:writeUInt(breakdown.maxTick or 0, BITS.TICK_VALUE)
end

---Reads a HealingBreakdown from decoder
---@param decoder BitDecoder
---@return HealingBreakdown
local function readHealingBreakdown(decoder)
    return BattleScrolls.structures.makeHealingBreakdown(
        decoder:readUInt(BITS.TOTAL),
        decoder:readUInt(BITS.TOTAL),
        decoder:readUInt(BITS.TOTAL),
        decoder:readUInt(BITS.COUNT),
        decoder:readUInt(BITS.COUNT),
        decoder:readUInt(BITS.TICK_VALUE),
        decoder:readUInt(BITS.TICK_VALUE)
    )
end

---Writes an EffectStats to encoder
---@param encoder BitEncoder
---@param stats EffectStats|BossEffectStats|GroupEffectStats
local function writeEffectStats(encoder, stats)
    encoder:writeUInt(stats.abilityId or 0, BITS.ABILITY_ID)
    encoder:writeUInt(stats.effectType or 0, BITS.EFFECT_TYPE)
    encoder:writeUInt(stats.totalActiveTimeMs or 0, BITS.TIME_MS)
    encoder:writeUInt(stats.timeAtMaxStacksMs or 0, BITS.TIME_MS)
    encoder:writeUInt(stats.applications or 0, BITS.APPLICATIONS)
    encoder:writeUInt(stats.maxStacks or 0, BITS.MAX_STACKS)
    encoder:writeUInt(stats.playerActiveTimeMs or 0, BITS.TIME_MS)
    encoder:writeUInt(stats.playerTimeAtMaxStacksMs or 0, BITS.TIME_MS)
    encoder:writeUInt(stats.playerApplications or 0, BITS.APPLICATIONS)
    -- v5: peakConcurrentInstances
    encoder:writeUInt(stats.peakConcurrentInstances or 1, BITS.MAX_STACKS)
end

---Reads an EffectStats from decoder
---@param decoder BitDecoder
---@return BossEffectStats
local function readEffectStats(decoder)
    return BattleScrolls.structures.makeEffectStatsWithAttribution(
        decoder:readUInt(BITS.ABILITY_ID),
        decoder:readUInt(BITS.EFFECT_TYPE),
        decoder:readUInt(BITS.TIME_MS),
        decoder:readUInt(BITS.TIME_MS),
        decoder:readUInt(BITS.APPLICATIONS),
        decoder:readUInt(BITS.MAX_STACKS),
        decoder:readUInt(BITS.TIME_MS),
        decoder:readUInt(BITS.TIME_MS),
        decoder:readUInt(BITS.APPLICATIONS),
        decoder:readUInt(BITS.MAX_STACKS)
    )
end

-- =============================================================================
-- DAMAGE MAP ENCODING (nested: sourceId -> targetId -> abilityId -> breakdown)
-- =============================================================================

---Writes a damage map to encoder
---@param encoder BitEncoder
---@param damageMap table<number, table<number, DamageDone|DamageByAbility>>|nil Nested: sourceId -> targetId -> damage
local function writeDamageMap(encoder, damageMap)
    -- Count sources
    local sourceCount = 0
    for _ in pairs(damageMap or {}) do sourceCount = sourceCount + 1 end
    encoder:writeUInt(sourceCount, BITS.MAP_COUNT)

    for sourceId, byTarget in pairs(damageMap or {}) do
        encoder:writeUInt(sourceId, BITS.UNIT_ID)

        -- Count targets
        local targetCount = 0
        for _ in pairs(byTarget) do targetCount = targetCount + 1 end
        encoder:writeUInt(targetCount, BITS.MAP_COUNT)

        for targetId, damageDone in pairs(byTarget) do
            encoder:writeUInt(targetId, BITS.UNIT_ID)

            -- Count abilities (damageDone.byAbilityId or damageDone itself if already decoded format)
            local byAbility = damageDone.byAbilityId or damageDone
            local abilityCount = 0
            for _ in pairs(byAbility) do abilityCount = abilityCount + 1 end
            encoder:writeUInt(abilityCount, BITS.MAP_COUNT)

            for abilityId, breakdown in pairs(byAbility) do
                encoder:writeUInt(abilityId, BITS.ABILITY_ID)
                writeDamageBreakdown(encoder, breakdown)
            end
        end
    end
end

---Reads a damage map from decoder
---@param decoder BitDecoder
---@return table<number, table<number, DamageByAbility>> Nested: sourceId -> targetId -> (abilityId -> DamageBreakdown)
local function readDamageMap(decoder)
    local result = {}
    local sourceCount = decoder:readUInt(BITS.MAP_COUNT)

    for _ = 1, sourceCount do
        local sourceId = decoder:readUInt(BITS.UNIT_ID)
        result[sourceId] = {}

        local targetCount = decoder:readUInt(BITS.MAP_COUNT)
        for _ = 1, targetCount do
            local targetId = decoder:readUInt(BITS.UNIT_ID)
            result[sourceId][targetId] = {}

            local abilityCount = decoder:readUInt(BITS.MAP_COUNT)
            for _ = 1, abilityCount do
                local abilityId = decoder:readUInt(BITS.ABILITY_ID)
                result[sourceId][targetId][abilityId] = readDamageBreakdown(decoder)
            end
        end
    end

    return result
end

-- =============================================================================
-- HEALING STATS ENCODING
-- =============================================================================

---Writes HealingDoneDiffSource to encoder
---@param encoder BitEncoder
---@param healing HealingDoneDiffSource
local function writeHealingDoneDiffSource(encoder, healing)
    writeHealingTotals(encoder, healing.total)
    -- v6+: byHotVsDirect computed on-demand from byAbilityId + abilityInfo

    -- bySourceUnitIdByAbilityId
    local sourceCount = 0
    for _ in pairs(healing.bySourceUnitIdByAbilityId or {}) do sourceCount = sourceCount + 1 end
    encoder:writeUInt(sourceCount, BITS.MAP_COUNT)

    for sourceId, byAbility in pairs(healing.bySourceUnitIdByAbilityId or {}) do
        encoder:writeUInt(sourceId, BITS.UNIT_ID)

        local abilityCount = 0
        for _ in pairs(byAbility) do abilityCount = abilityCount + 1 end
        encoder:writeUInt(abilityCount, BITS.MAP_COUNT)

        for abilityId, breakdown in pairs(byAbility) do
            encoder:writeUInt(abilityId, BITS.ABILITY_ID)
            writeHealingBreakdown(encoder, breakdown)
        end
    end
end

---Reads HealingDoneDiffSource from decoder
---@param decoder BitDecoder
---@return HealingDoneDiffSource
local function readHealingDoneDiffSource(decoder)
    local result = {
        total = readHealingTotals(decoder),
        bySourceUnitIdByAbilityId = {},
    }

    local sourceCount = decoder:readUInt(BITS.MAP_COUNT)
    for _ = 1, sourceCount do
        local sourceId = decoder:readUInt(BITS.UNIT_ID)
        result.bySourceUnitIdByAbilityId[sourceId] = {}

        local abilityCount = decoder:readUInt(BITS.MAP_COUNT)
        for _ = 1, abilityCount do
            local abilityId = decoder:readUInt(BITS.ABILITY_ID)
            result.bySourceUnitIdByAbilityId[sourceId][abilityId] = readHealingBreakdown(decoder)
        end
    end

    return result
end

---Writes HealingDone to encoder
---@param encoder BitEncoder
---@param healing HealingDone
local function writeHealingDone(encoder, healing)
    writeHealingTotals(encoder, healing.total)
    -- v6+: byHotVsDirect computed on-demand from byAbilityId + abilityInfo

    local abilityCount = 0
    for _ in pairs(healing.byAbilityId or {}) do abilityCount = abilityCount + 1 end
    encoder:writeUInt(abilityCount, BITS.MAP_COUNT)

    for abilityId, breakdown in pairs(healing.byAbilityId or {}) do
        encoder:writeUInt(abilityId, BITS.ABILITY_ID)
        writeHealingBreakdown(encoder, breakdown)
    end
end

---Reads HealingDone from decoder
---@param decoder BitDecoder
---@return HealingDone
local function readHealingDone(decoder)
    local result = {
        total = readHealingTotals(decoder),
        byAbilityId = {},
    }

    local abilityCount = decoder:readUInt(BITS.MAP_COUNT)
    for _ = 1, abilityCount do
        local abilityId = decoder:readUInt(BITS.ABILITY_ID)
        result.byAbilityId[abilityId] = readHealingBreakdown(decoder)
    end

    return result
end

---Writes HealingStats to encoder
---@param encoder BitEncoder
---@param healingStats HealingStats
local function writeHealingStats(encoder, healingStats)
    writeHealingDoneDiffSource(encoder, healingStats.selfHealing)

    -- healingOutToGroup
    local outCount = 0
    for _ in pairs(healingStats.healingOutToGroup or {}) do outCount = outCount + 1 end
    encoder:writeUInt(outCount, BITS.MAP_COUNT)

    for targetId, healing in pairs(healingStats.healingOutToGroup or {}) do
        encoder:writeUInt(targetId, BITS.UNIT_ID)
        writeHealingDoneDiffSource(encoder, healing)
    end

    -- healingInFromGroup
    local inCount = 0
    for _ in pairs(healingStats.healingInFromGroup or {}) do inCount = inCount + 1 end
    encoder:writeUInt(inCount, BITS.MAP_COUNT)

    for sourceId, healing in pairs(healingStats.healingInFromGroup or {}) do
        encoder:writeUInt(sourceId, BITS.UNIT_ID)
        writeHealingDone(encoder, healing)
    end
end

---Reads HealingStats from decoder
---@param decoder BitDecoder
---@return HealingStats
local function readHealingStats(decoder)
    local result = {
        selfHealing = readHealingDoneDiffSource(decoder),
        healingOutToGroup = {},
        healingInFromGroup = {},
    }

    local outCount = decoder:readUInt(BITS.MAP_COUNT)
    for _ = 1, outCount do
        local targetId = decoder:readUInt(BITS.UNIT_ID)
        result.healingOutToGroup[targetId] = readHealingDoneDiffSource(decoder)
    end

    local inCount = decoder:readUInt(BITS.MAP_COUNT)
    for _ = 1, inCount do
        local sourceId = decoder:readUInt(BITS.UNIT_ID)
        result.healingInFromGroup[sourceId] = readHealingDone(decoder)
    end

    return result
end

-- =============================================================================
-- PROCS ENCODING
-- =============================================================================

---Writes procs to encoder
---@param encoder BitEncoder
---@param procs ProcData[]
local function writeProcs(encoder, procs)
    encoder:writeUInt(#(procs or {}), BITS.MAP_COUNT)

    for _, proc in ipairs(procs or {}) do
        encoder:writeUInt(proc.abilityId, BITS.ABILITY_ID)
        encoder:writeUInt(proc.totalProcs or 0, BITS.COUNT)
        encoder:writeUInt(proc.meanIntervalMs or 0, BITS.INTERVAL_MS)
        encoder:writeUInt(proc.medianIntervalMs or 0, BITS.INTERVAL_MS)

        encoder:writeUInt(#(proc.procsByEnemy or {}), BITS.MAP_COUNT)
        for _, enemy in ipairs(proc.procsByEnemy or {}) do
            encoder:writeUInt(enemy.unitId, BITS.UNIT_ID)
            encoder:writeUInt(enemy.procCount or 0, BITS.COUNT)
        end
    end
end

---Reads procs from decoder
---@param decoder BitDecoder
---@return ProcData[]
local function readProcs(decoder)
    local result = {}
    local procCount = decoder:readUInt(BITS.MAP_COUNT)

    for _ = 1, procCount do
        local proc = {
            abilityId = decoder:readUInt(BITS.ABILITY_ID),
            totalProcs = decoder:readUInt(BITS.COUNT),
            meanIntervalMs = decoder:readUInt(BITS.INTERVAL_MS),
            medianIntervalMs = decoder:readUInt(BITS.INTERVAL_MS),
            procsByEnemy = {},
        }

        local enemyCount = decoder:readUInt(BITS.MAP_COUNT)
        for _ = 1, enemyCount do
            proc.procsByEnemy[#proc.procsByEnemy + 1] = {
                unitId = decoder:readUInt(BITS.UNIT_ID),
                procCount = decoder:readUInt(BITS.COUNT),
            }
        end

        result[#result + 1] = proc
    end

    return result
end

-- =============================================================================
-- EFFECTS ENCODING
-- =============================================================================

---Writes effectsOnPlayer to encoder
---@param encoder BitEncoder
---@param effectsOnPlayer table<number, PlayerEffectStats>|nil
local function writeEffectsOnPlayer(encoder, effectsOnPlayer)
    local count = 0
    for _ in pairs(effectsOnPlayer or {}) do count = count + 1 end
    encoder:writeUInt(count, BITS.MAP_COUNT)

    for abilityId, stats in pairs(effectsOnPlayer or {}) do
        encoder:writeUInt(abilityId, BITS.ABILITY_ID)
        writeEffectStats(encoder, stats)
    end
end

---Reads effectsOnPlayer from decoder
---@param decoder BitDecoder
---@return table<number, PlayerEffectStats>|nil
local function readEffectsOnPlayer(decoder)
    local count = decoder:readUInt(BITS.MAP_COUNT)
    if count == 0 then return nil end

    local result = {}
    for _ = 1, count do
        local abilityId = decoder:readUInt(BITS.ABILITY_ID)
        result[abilityId] = readEffectStats(decoder)
        result[abilityId].abilityId = abilityId  -- Ensure abilityId is set
    end
    return result
end

---Writes effectsOnBosses to encoder
---@param encoder BitEncoder
---@param effectsOnBosses table<string, table<number, BossEffectStats>>|nil
local function writeEffectsOnBosses(encoder, effectsOnBosses)
    local unitCount = 0
    for _ in pairs(effectsOnBosses or {}) do unitCount = unitCount + 1 end
    encoder:writeUInt(unitCount, BITS.MAP_COUNT)

    for unitTag, byAbility in pairs(effectsOnBosses or {}) do
        encoder:writeString(unitTag)

        local abilityCount = 0
        for _ in pairs(byAbility) do abilityCount = abilityCount + 1 end
        encoder:writeUInt(abilityCount, BITS.MAP_COUNT)

        for abilityId, stats in pairs(byAbility) do
            encoder:writeUInt(abilityId, BITS.ABILITY_ID)
            writeEffectStats(encoder, stats)
        end
    end
end

---Reads effectsOnBosses from decoder
---@param decoder BitDecoder
---@return table<string, table<number, BossEffectStats>>|nil
local function readEffectsOnBosses(decoder)
    local unitCount = decoder:readUInt(BITS.MAP_COUNT)
    if unitCount == 0 then return nil end

    local result = {}
    for _ = 1, unitCount do
        local unitTag = decoder:readString()
        result[unitTag] = {}

        local abilityCount = decoder:readUInt(BITS.MAP_COUNT)
        for _ = 1, abilityCount do
            local abilityId = decoder:readUInt(BITS.ABILITY_ID)
            result[unitTag][abilityId] = readEffectStats(decoder)
            result[unitTag][abilityId].abilityId = abilityId
        end
    end
    return result
end

---Writes effectsOnGroup to encoder
---@param encoder BitEncoder
---@param effectsOnGroup table<string, table<number, GroupEffectStats>>|nil
local function writeEffectsOnGroup(encoder, effectsOnGroup)
    local memberCount = 0
    for _ in pairs(effectsOnGroup or {}) do memberCount = memberCount + 1 end
    encoder:writeUInt(memberCount, BITS.MAP_COUNT)

    for displayName, byAbility in pairs(effectsOnGroup or {}) do
        encoder:writeString(displayName)

        local abilityCount = 0
        for _ in pairs(byAbility) do abilityCount = abilityCount + 1 end
        encoder:writeUInt(abilityCount, BITS.MAP_COUNT)

        for abilityId, stats in pairs(byAbility) do
            encoder:writeUInt(abilityId, BITS.ABILITY_ID)
            writeEffectStats(encoder, stats)
        end
    end
end

---Reads effectsOnGroup from decoder
---@param decoder BitDecoder
---@return table<string, table<number, GroupEffectStats>>|nil
local function readEffectsOnGroup(decoder)
    local memberCount = decoder:readUInt(BITS.MAP_COUNT)
    if memberCount == 0 then return nil end

    local result = {}
    for _ = 1, memberCount do
        local displayName = decoder:readString()
        result[displayName] = {}

        local abilityCount = decoder:readUInt(BITS.MAP_COUNT)
        for _ = 1, abilityCount do
            local abilityId = decoder:readUInt(BITS.ABILITY_ID)
            result[displayName][abilityId] = readEffectStats(decoder)
            result[displayName][abilityId].abilityId = abilityId
        end
    end
    return result
end

-- =============================================================================
-- BOSS NAMES & ALIVE TIMES
-- =============================================================================

---Writes bossNames to encoder
---@param encoder BitEncoder
---@param bossNames table<string, string>|nil
local function writeBossNames(encoder, bossNames)
    local count = 0
    for _ in pairs(bossNames or {}) do count = count + 1 end
    encoder:writeUInt(count, BITS.MAP_COUNT)

    for unitTag, name in pairs(bossNames or {}) do
        encoder:writeString(unitTag)
        encoder:writeString(name)
    end
end

---Reads bossNames from decoder
---@param decoder BitDecoder
---@return table<string, string>|nil
local function readBossNames(decoder)
    local count = decoder:readUInt(BITS.MAP_COUNT)
    if count == 0 then return nil end

    local result = {}
    for _ = 1, count do
        local unitTag = decoder:readString()
        local name = decoder:readString()
        result[unitTag] = name
    end
    return result
end

---Writes unitAliveTimeMs to encoder
---@param encoder BitEncoder
---@param unitAliveTimeMs table<string, number>|nil
local function writeUnitAliveTimes(encoder, unitAliveTimeMs)
    local count = 0
    for _ in pairs(unitAliveTimeMs or {}) do count = count + 1 end
    encoder:writeUInt(count, BITS.MAP_COUNT)

    for unitKey, timeMs in pairs(unitAliveTimeMs or {}) do
        encoder:writeString(unitKey)
        encoder:writeUInt(timeMs, BITS.TIME_MS)
    end
end

---Reads unitAliveTimeMs from decoder
---@param decoder BitDecoder
---@return table<string, number>|nil
local function readUnitAliveTimes(decoder)
    local count = decoder:readUInt(BITS.MAP_COUNT)
    if count == 0 then return nil end

    local result = {}
    for _ = 1, count do
        local unitKey = decoder:readString()
        local timeMs = decoder:readUInt(BITS.TIME_MS)
        result[unitKey] = timeMs
    end
    return result
end

---Writes unitNames to encoder
---@param encoder BitEncoder
---@param unitNames table<number, string>|nil
local function writeUnitNames(encoder, unitNames)
    unitNames = unitNames or {}
    local count = 0
    for _ in pairs(unitNames) do count = count + 1 end
    encoder:writeUInt(count, BITS.MAP_COUNT)

    for unitId, name in pairs(unitNames) do
        encoder:writeUInt(unitId, BITS.UNIT_ID)
        encoder:writeString(name)
    end
end

---Reads unitNames from decoder
---@param decoder BitDecoder
---@return table<number, string>
local function readUnitNames(decoder)
    local result = {}
    local count = decoder:readUInt(BITS.MAP_COUNT)

    for _ = 1, count do
        local unitId = decoder:readUInt(BITS.UNIT_ID)
        local name = decoder:readString()
        result[unitId] = name
    end

    return result
end

-- =============================================================================
-- MAIN ENCODE/DECODE FUNCTIONS
-- =============================================================================

---Encodes an encounter to binary format asynchronously.
---Returns an Effect that resolves to the binary-encoded encounter.
---@param encounter Encounter The encounter to encode (includes unitNames for v7+)
---@return Effect Effect that resolves to binaryEncounter
function binaryStorage.encodeEncounterAsync(encounter)
    return LibEffect.Async(function()
        local encoder = BitEncoder.new()

        -- Write all data directly to encoder, yielding between major sections
        writeDamageMap(encoder, encounter.damageByUnitId)
        LibEffect.YieldWithGC():Await()
        writeDamageMap(encoder, encounter.damageByUnitIdGroup)
        LibEffect.YieldWithGC():Await()
        writeDamageMap(encoder, encounter.damageTakenByUnitId)
        LibEffect.YieldWithGC():Await()
        writeHealingStats(encoder, encounter.healingStats)
        LibEffect.YieldWithGC():Await()
        writeProcs(encoder, encounter.procs)
        LibEffect.YieldWithGC():Await()
        writeEffectsOnPlayer(encoder, encounter.effectsOnPlayer)
        LibEffect.YieldWithGC():Await()
        writeEffectsOnBosses(encoder, encounter.effectsOnBosses)
        LibEffect.YieldWithGC():Await()
        writeEffectsOnGroup(encoder, encounter.effectsOnGroup)
        LibEffect.YieldWithGC():Await()
        writeBossNames(encoder, encounter.bossNames)

        -- playerAliveTimeMs (optional)
        if encounter.playerAliveTimeMs then
            encoder:writeBit(true)
            encoder:writeUInt(encounter.playerAliveTimeMs, BITS.TIME_MS)
        else
            encoder:writeBit(false)
        end

        LibEffect.YieldWithGC():Await()

        writeUnitAliveTimes(encoder, encounter.unitAliveTimeMs)

        LibEffect.YieldWithGC():Await()

        -- v7+: encode unitNames in encounter buffer
        writeUnitNames(encoder, encounter.unitNames)

        LibEffect.YieldWithGC():Await()

        local chunks = encoder:finish()

        -- Return encounter with binary data and preserved metadata
        return {
            _v = CURRENT_VERSION,
            _data = chunks,  -- Array of base64 chunks (SavedVariables 2K string limit)
            -- Preserved metadata for list display and filtering
            displayName = encounter.displayName,
            location = encounter.location,
            timestampS = encounter.timestampS,
            durationMs = encounter.durationMs,
            bossesUnits = encounter.bossesUnits,
            isPlayerFight = encounter.isPlayerFight,
            isDummyFight = encounter.isDummyFight,
        }
    end)
end

---Decodes a binary-encoded encounter asynchronously.
---Returns an Effect that resolves to the decoded encounter.
---Yields between major decode steps to spread work across frames.
---@param binaryEncounter CompactEncounter The binary-encoded encounter
---@return Effect Effect that resolves to Encounter
function binaryStorage.decodeEncounterAsync(binaryEncounter)
    return LibEffect.Async(function()
        if binaryEncounter._v ~= 7 then
            error("Invalid binary encounter version: " .. tostring(binaryEncounter._v) .. " (expected 7)")
        end

        local decoder = BitDecoder.new(binaryEncounter._data)

        ---@type Encounter
        local result = {
            displayName = binaryEncounter.displayName,
            location = binaryEncounter.location,
            timestampS = binaryEncounter.timestampS,
            durationMs = binaryEncounter.durationMs,
            bossesUnits = binaryEncounter.bossesUnits,
            isPlayerFight = binaryEncounter.isPlayerFight,
            isDummyFight = binaryEncounter.isDummyFight,
        }

        result.damageByUnitId = readDamageMap(decoder)
        LibEffect.YieldWithGC():Await()

        result.damageByUnitIdGroup = readDamageMap(decoder)
        LibEffect.YieldWithGC():Await()

        result.damageTakenByUnitId = readDamageMap(decoder)
        LibEffect.YieldWithGC():Await()

        result.healingStats = readHealingStats(decoder)
        LibEffect.YieldWithGC():Await()

        result.procs = readProcs(decoder)
        LibEffect.YieldWithGC():Await()

        result.effectsOnPlayer = readEffectsOnPlayer(decoder)
        result.effectsOnBosses = readEffectsOnBosses(decoder)
        result.effectsOnGroup = readEffectsOnGroup(decoder)
        result.bossNames = readBossNames(decoder)

        -- playerAliveTimeMs (optional)
        if decoder:readBit() then
            result.playerAliveTimeMs = decoder:readUInt(BITS.TIME_MS)
        end

        result.unitAliveTimeMs = readUnitAliveTimes(decoder)
        LibEffect.YieldWithGC():Await()

        result.unitNames = readUnitNames(decoder)

        return result
    end)
end

---Checks if an encounter is in binary format
---@param encounter Encounter|CompactEncounter
---@return boolean
function binaryStorage.isBinaryEncounter(encounter)
    return encounter._v >= 3 and encounter._data ~= nil
end

-- =============================================================================
-- INSTANCE-LEVEL ENCODING: abilityInfo and unitNames
-- =============================================================================

-- Additional bit allocations for instance-level encoding
local BITS_DAMAGE_TYPE = 4  -- DamageType enum (16 values max)

---Reads abilityInfo from decoder
---@param decoder BitDecoder
---@return table<number, AbilityInfoStorage>
local function readAbilityInfo(decoder)
    local result = {}
    local count = decoder:readUInt(BITS.MAP_COUNT)

    for _ = 1, count do
        local abilityId = decoder:readUInt(BITS.ABILITY_ID)

        local overTime = decoder:readBit()
        local direct = decoder:readBit()

        local typeCount = decoder:readUInt(4)
        local damageTypes = {}
        for _ = 1, typeCount do
            local damageType = decoder:readUInt(BITS_DAMAGE_TYPE)
            damageTypes[damageType] = true
        end

        result[abilityId] = {
            overTimeOrDirect = { overTime = overTime or nil, direct = direct or nil },
            damageTypes = damageTypes,
        }
    end

    return result
end

---Encoded instance fields result
---@class EncodedInstanceFields
---@field _instanceData string[] Base64 encoded data chunks

---Encodes instance-level abilityInfo to binary format asynchronously.
---Returns an Effect that resolves to the encoded fields.
---@param abilityInfo table<number, AbilityInfo> The ability info to encode
---@return Effect Effect that resolves to EncodedInstanceFields
function binaryStorage.encodeInstanceFieldsAsync(abilityInfo)
    return LibEffect.Async(function()
        local encoder = BitEncoder.new()

        -- Write abilityInfo with yields
        abilityInfo = abilityInfo or {}
        local count = 0
        for _ in pairs(abilityInfo) do count = count + 1 end
        encoder:writeUInt(count, BITS.MAP_COUNT)

        local i = 0
        for abilityId, info in pairs(abilityInfo) do
            encoder:writeUInt(abilityId, BITS.ABILITY_ID)

            local overTimeOrDirect = info.overTimeOrDirect or {}
            encoder:writeBit(overTimeOrDirect.overTime)
            encoder:writeBit(overTimeOrDirect.direct)

            local typeCount = 0
            for _ in pairs(info.damageTypes or {}) do typeCount = typeCount + 1 end
            encoder:writeUInt(typeCount, 4)

            for damageType in pairs(info.damageTypes or {}) do
                encoder:writeUInt(damageType, BITS_DAMAGE_TYPE)
            end

            i = i + 1
            if i % 50 == 0 then
                LibEffect.YieldWithGC():Await()
            end
        end
        LibEffect.YieldWithGC():Await()

        local chunks = encoder:finish()

        return {
            _instanceData = chunks,
        }
    end)
end

---Decodes instance-level abilityInfo asynchronously.
---Returns an Effect that resolves to { abilityInfo, {} }.
---Note: unitNames are stored at encounter level (not instance level).
---@param instance InstanceStorage The instance with encoded _instanceData
---@return Effect Effect that resolves to DecodedInstanceFields
function binaryStorage.decodeInstanceFieldsAsync(instance)
    return LibEffect.Async(function()
        if not instance._instanceData then
            error("Instance missing _instanceData - corrupted or incompatible format")
        end

        local decoder = BitDecoder.new(instance._instanceData)
        LibEffect.YieldWithGC():Await()

        local abilityInfo = readAbilityInfo(decoder)
        LibEffect.YieldWithGC():Await()

        return { abilityInfo, {} }
    end)
end

---Checks if an instance has encoded fields
---@param instance Instance
---@return boolean
function binaryStorage.hasEncodedInstanceFields(instance)
    return instance._instanceData ~= nil
end

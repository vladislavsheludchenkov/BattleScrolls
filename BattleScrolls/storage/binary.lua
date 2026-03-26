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

local CURRENT_VERSION = 11

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

    -- Death attack count (3 bits = up to 6 attacks per recap)
    DEATH_ATTACK_COUNT = 3,

    -- Setup encoding (v9+)
    CHAMPION_SKILL_ID = 16,
    DISCIPLINE_ID = 8,
    CHAMPION_COUNT = 6,
    SCRIPT_ID = 16,
    CRAFTED_ABILITY_ID = 16,

    RACE_ID = 8,
    CLASS_ID = 8,
    SKILL_LINE_ID = 16,
    MUNDUS_COUNT = 2,
    FOOD_COUNT = 2,
}

local EQUIP_SLOT_COUNT = 14

-- Number of encoded items (breakdowns, healing breakdowns, effect stats, etc.)
-- between yield checkpoints. Each item averages ~8-10 writeUInt calls, but the
-- slow path for non-byte-aligned writes (30-bit damage totals) roughly doubles
-- the cost
local ITEMS_PER_YIELD = 50

---@class EncodeProgress
---@field count number Items encoded since last yield

---Increments progress counter and yields if threshold reached.
---Must only be called from within a LibEffect.Async coroutine.
---@param progress EncodeProgress
local function countAndMaybeYield(progress)
    progress.count = progress.count + 1
    if progress.count >= ITEMS_PER_YIELD then
        progress.count = 0
        LibEffect.YieldWithGC():Await()
    end
end

---Yields if any items have been counted since last yield (flushes remaining work)
---@param progress EncodeProgress
local function flushProgress(progress)
    if progress.count > 0 then
        progress.count = 0
        LibEffect.YieldWithGC():Await()
    end
end

---Writes a count value clamped to the max representable value for the bit width.
---Returns the clamped count for use as a loop bound.
---@param encoder BitEncoder
---@param count number
---@param bits number
---@return number clampedCount
local function writeCount(encoder, count, bits)
    local maxVal = BitLShift(1, bits) - 1
    if count > maxVal then count = maxVal end
    encoder:writeUInt(count, bits)
    return count
end

---Counts entries in a hash table, writes the clamped count, returns the clamped count.
---@param encoder BitEncoder
---@param tbl table
---@param bits number
---@return number clampedCount
local function writeTableCount(encoder, tbl, bits)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return writeCount(encoder, count, bits)
end


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
---@param stats EffectStats
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
---@return EffectStats
local function readEffectStats(decoder)
    return BattleScrolls.structures.makeEffectStats(
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
---@param progress EncodeProgress
local function writeDamageMap(encoder, damageMap, progress)
    local sourceCount = writeTableCount(encoder, damageMap or {}, BITS.MAP_COUNT)

    local sourcesWritten = 0
    for sourceId, byTarget in pairs(damageMap or {}) do
        if sourcesWritten >= sourceCount then break end
        sourcesWritten = sourcesWritten + 1
        encoder:writeUInt(sourceId, BITS.UNIT_ID)

        local targetCount = writeTableCount(encoder, byTarget, BITS.MAP_COUNT)

        local targetsWritten = 0
        for targetId, damageDone in pairs(byTarget) do
            if targetsWritten >= targetCount then break end
            targetsWritten = targetsWritten + 1
            encoder:writeUInt(targetId, BITS.UNIT_ID)

            local byAbility = damageDone.byAbilityId or damageDone
            local abilityCount = writeTableCount(encoder, byAbility, BITS.MAP_COUNT)

            local abilitiesWritten = 0
            for abilityId, breakdown in pairs(byAbility) do
                if abilitiesWritten >= abilityCount then break end
                abilitiesWritten = abilitiesWritten + 1
                encoder:writeUInt(abilityId, BITS.ABILITY_ID)
                writeDamageBreakdown(encoder, breakdown)
                countAndMaybeYield(progress)
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
---@param progress EncodeProgress
local function writeHealingDoneDiffSource(encoder, healing, progress)
    writeHealingTotals(encoder, healing.total)
    -- v6+: byHotVsDirect computed on-demand from byAbilityId + abilityInfo

    local sourceCount = writeTableCount(encoder, healing.bySourceUnitIdByAbilityId or {}, BITS.MAP_COUNT)

    local sourcesWritten = 0
    for sourceId, byAbility in pairs(healing.bySourceUnitIdByAbilityId or {}) do
        if sourcesWritten >= sourceCount then break end
        sourcesWritten = sourcesWritten + 1
        encoder:writeUInt(sourceId, BITS.UNIT_ID)

        local abilityCount = writeTableCount(encoder, byAbility, BITS.MAP_COUNT)

        local abilitiesWritten = 0
        for abilityId, breakdown in pairs(byAbility) do
            if abilitiesWritten >= abilityCount then break end
            abilitiesWritten = abilitiesWritten + 1
            encoder:writeUInt(abilityId, BITS.ABILITY_ID)
            writeHealingBreakdown(encoder, breakdown)
            countAndMaybeYield(progress)
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
---@param progress EncodeProgress
local function writeHealingDone(encoder, healing, progress)
    writeHealingTotals(encoder, healing.total)
    -- v6+: byHotVsDirect computed on-demand from byAbilityId + abilityInfo

    local abilityCount = writeTableCount(encoder, healing.byAbilityId or {}, BITS.MAP_COUNT)

    local abilitiesWritten = 0
    for abilityId, breakdown in pairs(healing.byAbilityId or {}) do
        if abilitiesWritten >= abilityCount then break end
        abilitiesWritten = abilitiesWritten + 1
        encoder:writeUInt(abilityId, BITS.ABILITY_ID)
        writeHealingBreakdown(encoder, breakdown)
        countAndMaybeYield(progress)
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
---@param progress EncodeProgress
local function writeHealingStats(encoder, healingStats, progress)
    writeHealingDoneDiffSource(encoder, healingStats.selfHealing, progress)

    -- healingOutToGroup
    local outCount = writeTableCount(encoder, healingStats.healingOutToGroup or {}, BITS.MAP_COUNT)

    local outWritten = 0
    for targetId, healing in pairs(healingStats.healingOutToGroup or {}) do
        if outWritten >= outCount then break end
        outWritten = outWritten + 1
        encoder:writeUInt(targetId, BITS.UNIT_ID)
        writeHealingDoneDiffSource(encoder, healing, progress)
    end

    -- healingInFromGroup
    local inCount = writeTableCount(encoder, healingStats.healingInFromGroup or {}, BITS.MAP_COUNT)

    local inWritten = 0
    for sourceId, healing in pairs(healingStats.healingInFromGroup or {}) do
        if inWritten >= inCount then break end
        inWritten = inWritten + 1
        encoder:writeUInt(sourceId, BITS.UNIT_ID)
        writeHealingDone(encoder, healing, progress)
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
    procs = procs or {}
    local procCount = writeCount(encoder, #procs, BITS.MAP_COUNT)

    for i = 1, procCount do
        local proc = procs[i]
        encoder:writeUInt(proc.abilityId, BITS.ABILITY_ID)
        encoder:writeUInt(proc.totalProcs or 0, BITS.COUNT)
        encoder:writeUInt(proc.meanIntervalMs or 0, BITS.INTERVAL_MS)
        encoder:writeUInt(proc.medianIntervalMs or 0, BITS.INTERVAL_MS)

        local enemies = proc.procsByEnemy or {}
        local enemyCount = writeCount(encoder, #enemies, BITS.MAP_COUNT)
        for j = 1, enemyCount do
            encoder:writeUInt(enemies[j].unitId, BITS.UNIT_ID)
            encoder:writeUInt(enemies[j].procCount or 0, BITS.COUNT)
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
---@param effectsOnPlayer table<number, EffectStats>|nil
---@param progress EncodeProgress
local function writeEffectsOnPlayer(encoder, effectsOnPlayer, progress)
    local count = writeTableCount(encoder, effectsOnPlayer or {}, BITS.MAP_COUNT)

    local written = 0
    for abilityId, stats in pairs(effectsOnPlayer or {}) do
        if written >= count then break end
        written = written + 1
        encoder:writeUInt(abilityId, BITS.ABILITY_ID)
        writeEffectStats(encoder, stats)
        countAndMaybeYield(progress)
    end
end

---Reads effectsOnPlayer from decoder
---@param decoder BitDecoder
---@return table<number, EffectStats>|nil
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
---@param effectsOnBosses table<string, table<number, EffectStats>>|nil
---@param progress EncodeProgress
local function writeEffectsOnBosses(encoder, effectsOnBosses, progress)
    local unitCount = writeTableCount(encoder, effectsOnBosses or {}, BITS.MAP_COUNT)

    local unitsWritten = 0
    for unitTag, byAbility in pairs(effectsOnBosses or {}) do
        if unitsWritten >= unitCount then break end
        unitsWritten = unitsWritten + 1
        encoder:writeString(unitTag)

        local abilityCount = writeTableCount(encoder, byAbility, BITS.MAP_COUNT)

        local abilitiesWritten = 0
        for abilityId, stats in pairs(byAbility) do
            if abilitiesWritten >= abilityCount then break end
            abilitiesWritten = abilitiesWritten + 1
            encoder:writeUInt(abilityId, BITS.ABILITY_ID)
            writeEffectStats(encoder, stats)
            countAndMaybeYield(progress)
        end
    end
end

---Reads effectsOnBosses from decoder
---@param decoder BitDecoder
---@return table<string, table<number, EffectStats>>|nil
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
---@param effectsOnGroup table<string, table<number, EffectStats>>|nil
---@param progress EncodeProgress
local function writeEffectsOnGroup(encoder, effectsOnGroup, progress)
    local memberCount = writeTableCount(encoder, effectsOnGroup or {}, BITS.MAP_COUNT)

    local membersWritten = 0
    for displayName, byAbility in pairs(effectsOnGroup or {}) do
        if membersWritten >= memberCount then break end
        membersWritten = membersWritten + 1
        encoder:writeString(displayName)

        local abilityCount = writeTableCount(encoder, byAbility, BITS.MAP_COUNT)

        local abilitiesWritten = 0
        for abilityId, stats in pairs(byAbility) do
            if abilitiesWritten >= abilityCount then break end
            abilitiesWritten = abilitiesWritten + 1
            encoder:writeUInt(abilityId, BITS.ABILITY_ID)
            writeEffectStats(encoder, stats)
            countAndMaybeYield(progress)
        end
    end
end

---Reads effectsOnGroup from decoder
---@param decoder BitDecoder
---@return table<string, table<number, EffectStats>>|nil
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
    local count = writeTableCount(encoder, bossNames or {}, BITS.MAP_COUNT)

    local written = 0
    for unitTag, name in pairs(bossNames or {}) do
        if written >= count then break end
        written = written + 1
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
    local count = writeTableCount(encoder, unitAliveTimeMs or {}, BITS.MAP_COUNT)

    local written = 0
    for unitKey, timeMs in pairs(unitAliveTimeMs or {}) do
        if written >= count then break end
        written = written + 1
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
---@param progress EncodeProgress
local function writeUnitNames(encoder, unitNames, progress)
    unitNames = unitNames or {}
    local count = writeTableCount(encoder, unitNames, BITS.MAP_COUNT)

    local written = 0
    for unitId, name in pairs(unitNames) do
        if written >= count then break end
        written = written + 1
        encoder:writeUInt(unitId, BITS.UNIT_ID)
        encoder:writeString(name)
        countAndMaybeYield(progress)
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
-- DEATH RECAP ENCODING (v8+)
-- =============================================================================

---Writes a single death recap to encoder
---@param encoder BitEncoder
---@param recap SharedDeathRecap
local function writeDeathRecap(encoder, recap)
    encoder:writeUInt(recap.timeOffsetMs or 0, BITS.TIME_MS)
    local attacks = recap.attacks or {}
    local attackCount = writeCount(encoder, #attacks, BITS.DEATH_ATTACK_COUNT)
    for i = 1, attackCount do
        encoder:writeUInt(attacks[i].abilityId, BITS.ABILITY_ID)
        encoder:writeUInt(attacks[i].damage, BITS.TICK_VALUE)
    end
end

---Reads a single death recap from decoder
---@param decoder BitDecoder
---@return SharedDeathRecap
local function readDeathRecap(decoder)
    local timeOffsetMs = decoder:readUInt(BITS.TIME_MS)
    local attackCount = decoder:readUInt(BITS.DEATH_ATTACK_COUNT)
    local attacks = {}
    for _ = 1, attackCount do
        attacks[#attacks + 1] = {
            abilityId = decoder:readUInt(BITS.ABILITY_ID),
            damage = decoder:readUInt(BITS.TICK_VALUE),
        }
    end
    return { timeOffsetMs = timeOffsetMs, attacks = attacks }
end

---Writes EncounterDeaths to encoder (1-bit flag prefix)
---@param encoder BitEncoder
---@param deaths EncounterDeaths|nil
local function writeDeaths(encoder, deaths)
    if not deaths then
        encoder:writeBit(false)
        return
    end
    encoder:writeBit(true)
    encoder:writeUInt(deaths.deathCount, BITS.MAP_COUNT)
    local recaps = deaths.recaps or {}
    local recapCount = writeCount(encoder, #recaps, BITS.MAP_COUNT)
    for i = 1, recapCount do
        writeDeathRecap(encoder, recaps[i])
    end
end

---Reads EncounterDeaths from decoder (1-bit flag prefix)
---@param decoder BitDecoder
---@return EncounterDeaths|nil
local function readDeaths(decoder)
    if not decoder:readBit() then
        return nil
    end
    local deathCount = decoder:readUInt(BITS.MAP_COUNT)
    local recapCount = decoder:readUInt(BITS.MAP_COUNT)
    local recaps = {}
    for _ = 1, recapCount do
        recaps[#recaps + 1] = readDeathRecap(decoder)
    end
    return { deathCount = deathCount, recaps = recaps }
end

-- =============================================================================
-- SETUP ENCODING (v9+)
-- =============================================================================

---Writes an ability bar (array of PlayerSetupAbility) to the encoder.
---@param encoder BitEncoder
---@param bar PlayerSetupAbility[]
local function writeAbilityBar(encoder, bar)
    for i = 1, 6 do
        local ability = bar[i] or {}
        encoder:writeUInt(ability.abilityId or 0, BITS.ABILITY_ID)
        local isCrafted = ability.craftedAbilityId ~= nil
        encoder:writeBit(isCrafted)
        if isCrafted then
            encoder:writeUInt(ability.craftedAbilityId, BITS.CRAFTED_ABILITY_ID)
            local scripts = ability.scriptIds or {}
            encoder:writeUInt(scripts[1] or 0, BITS.SCRIPT_ID)
            encoder:writeUInt(scripts[2] or 0, BITS.SCRIPT_ID)
            encoder:writeUInt(scripts[3] or 0, BITS.SCRIPT_ID)
        end
    end
end

---Reads an ability bar (6 slots) from the decoder.
---@param decoder BitDecoder
---@return PlayerSetupAbility[]
local function readAbilityBar(decoder)
    local bar = {}
    for _ = 1, 6 do
        local abilityId = decoder:readUInt(BITS.ABILITY_ID)
        local isCrafted = decoder:readBit()
        ---@type PlayerSetupAbility
        local ability
        if isCrafted then
            local craftedAbilityId = decoder:readUInt(BITS.CRAFTED_ABILITY_ID)
            local s1 = decoder:readUInt(BITS.SCRIPT_ID)
            local s2 = decoder:readUInt(BITS.SCRIPT_ID)
            local s3 = decoder:readUInt(BITS.SCRIPT_ID)
            ability = {
                abilityId = abilityId,
                craftedAbilityId = craftedAbilityId,
                scriptIds = { s1, s2, s3 },
            }
        else
            ability = { abilityId = abilityId }
        end
        bar[#bar + 1] = ability
    end
    return bar
end

local function writeSetup(encoder, setup)
    -- Abilities: 12 slots (6 front + 6 back)
    writeAbilityBar(encoder, setup.abilities.front)
    writeAbilityBar(encoder, setup.abilities.back)

    -- Champion: variable-length
    local champion = setup.champion or {}
    local championCount = writeCount(encoder, #champion, BITS.CHAMPION_COUNT)
    for i = 1, championCount do
        encoder:writeUInt(champion[i].skillId, BITS.CHAMPION_SKILL_ID)
        encoder:writeUInt(champion[i].disciplineId, BITS.DISCIPLINE_ID)
    end

    -- Equipment: 14 fixed slots as item link strings (no poison)
    local equipSlots = setup.equipSlots or {}
    for i = 1, EQUIP_SLOT_COUNT do
        local link = equipSlots[i]
        if link and link ~= "" then
            encoder:writeBit(true)
            encoder:writeString(link)
        else
            encoder:writeBit(false)
        end
    end

    -- Bar disabled flags (bar swap locked)
    encoder:writeBit(setup.frontBarDisabled or false)
    encoder:writeBit(setup.backBarDisabled or false)

    -- Poisons: 2 slots (front, back) as item link strings (v11+)
    if setup.frontPoison then
        encoder:writeBit(true)
        encoder:writeString(setup.frontPoison.itemLink)
    else
        encoder:writeBit(false)
    end
    if setup.backPoison then
        encoder:writeBit(true)
        encoder:writeString(setup.backPoison.itemLink)
    else
        encoder:writeBit(false)
    end

    -- Race, class, skill lines, mundus, food
    encoder:writeUInt(setup.raceId or 0, BITS.RACE_ID)
    encoder:writeUInt(setup.classId or 0, BITS.CLASS_ID)

    local classSkillLineIds = setup.classSkillLineIds or {}
    for i = 1, 3 do
        encoder:writeUInt(classSkillLineIds[i] or 0, BITS.SKILL_LINE_ID)
    end

    local mundus = setup.mundusAbilityIds or {}
    local mundusCount = writeCount(encoder, #mundus, BITS.MUNDUS_COUNT)
    for i = 1, mundusCount do
        encoder:writeUInt(mundus[i], BITS.ABILITY_ID)
    end

    local foods = setup.foods or {}
    local foodCount = writeCount(encoder, #foods, BITS.FOOD_COUNT)
    for i = 1, foodCount do
        encoder:writeUInt(foods[i].abilityId, BITS.ABILITY_ID)
        if foods[i].uptimeMs then
            encoder:writeBit(true)
            encoder:writeUInt(foods[i].uptimeMs, BITS.TIME_MS)
        else
            encoder:writeBit(false)
        end
    end

    -- v10+: werewolf bar
    if setup.werewolfAbilities then
        encoder:writeBit(true)
        encoder:writeBit(setup.werewolfEntireFight or false)
        writeAbilityBar(encoder, setup.werewolfAbilities)
    else
        encoder:writeBit(false)
    end
end

---Reads a PlayerSetup from decoder
---@param decoder BitDecoder
---@param version number Binary format version
---@return PlayerSetup
local function readSetup(decoder, version)
    -- Abilities: 12 slots (6 front + 6 back)
    local front = readAbilityBar(decoder)
    local back = readAbilityBar(decoder)

    -- Champion
    local championCount = decoder:readUInt(BITS.CHAMPION_COUNT)
    local champion = {}
    for _ = 1, championCount do
        champion[#champion + 1] = {
            skillId = decoder:readUInt(BITS.CHAMPION_SKILL_ID),
            disciplineId = decoder:readUInt(BITS.DISCIPLINE_ID),
        }
    end

    -- Equipment: 14 fixed slots as item link strings
    local equipSlots = {}
    for i = 1, EQUIP_SLOT_COUNT do
        if decoder:readBit() then
            equipSlots[i] = decoder:readString()
        else
            equipSlots[i] = false
        end
    end

    -- Bar disabled flags (bar swap locked)
    local frontBarDisabled = decoder:readBit()
    local backBarDisabled = decoder:readBit()

    -- Poisons: v11+ stores item link strings, v10 stored ability IDs (decoded as nil)
    local frontPoison = nil
    local backPoison = nil
    if version >= 11 then
        if decoder:readBit() then
            frontPoison = { itemLink = decoder:readString() }
        end
        if decoder:readBit() then
            backPoison = { itemLink = decoder:readString() }
        end
    else
        -- v10: consume old format (bit + uint) but discard
        if decoder:readBit() then decoder:readUInt(BITS.ABILITY_ID) end
        if decoder:readBit() then decoder:readUInt(BITS.ABILITY_ID) end
    end

    ---@type PlayerSetup
    local result = {
        abilities = { front = front, back = back },
        champion = champion,
        equipSlots = equipSlots,
        frontBarDisabled = frontBarDisabled,
        backBarDisabled = backBarDisabled,
        frontPoison = frontPoison,
        backPoison = backPoison,
    }

    -- Race, class, skill lines, mundus, food
    result.raceId = decoder:readUInt(BITS.RACE_ID)
    result.classId = decoder:readUInt(BITS.CLASS_ID)

    local classSkillLineIds = {}
    for i = 1, 3 do
        classSkillLineIds[i] = decoder:readUInt(BITS.SKILL_LINE_ID)
    end
    result.classSkillLineIds = classSkillLineIds

    local mundusCount = decoder:readUInt(BITS.MUNDUS_COUNT)
    if mundusCount > 0 then
        local mundus = {}
        for _ = 1, mundusCount do
            mundus[#mundus + 1] = decoder:readUInt(BITS.ABILITY_ID)
        end
        result.mundusAbilityIds = mundus
    end

    local foodCount = decoder:readUInt(BITS.FOOD_COUNT)
    if foodCount > 0 then
        local foods = {}
        for _ = 1, foodCount do
            local abilityId = decoder:readUInt(BITS.ABILITY_ID)
            local hasUptime = decoder:readBit()
            ---@type PlayerSetupFood
            local food = { abilityId = abilityId }
            if hasUptime then
                food.uptimeMs = decoder:readUInt(BITS.TIME_MS)
            end
            foods[#foods + 1] = food
        end
        result.foods = foods
    end

    -- v10+: werewolf bar
    if version >= 10 and decoder:readBit() then
        result.werewolfEntireFight = decoder:readBit()
        result.werewolfAbilities = readAbilityBar(decoder)
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
        local progress = { count = 0 }

        -- Heavy sections: damage maps and healing (yield based on data volume)
        writeDamageMap(encoder, encounter.damageByUnitId, progress)
        writeDamageMap(encoder, encounter.damageByUnitIdGroup, progress)
        writeDamageMap(encoder, encounter.damageTakenByUnitId, progress)
        writeHealingStats(encoder, encounter.healingStats, progress)
        flushProgress(progress)

        -- Light section: procs (always small, no per-item yields)
        writeProcs(encoder, encounter.procs)

        -- Effects (yield based on data volume, consistent with damage/healing)
        writeEffectsOnPlayer(encoder, encounter.effectsOnPlayer, progress)
        writeEffectsOnBosses(encoder, encounter.effectsOnBosses, progress)
        writeEffectsOnGroup(encoder, encounter.effectsOnGroup, progress)
        flushProgress(progress)

        -- Metadata (must match decode order in decodeEncounterAsync)
        writeBossNames(encoder, encounter.bossNames)
        if encounter.playerAliveTimeMs then
            encoder:writeBit(true)
            encoder:writeUInt(encounter.playerAliveTimeMs, BITS.TIME_MS)
        else
            encoder:writeBit(false)
        end
        writeUnitAliveTimes(encoder, encounter.unitAliveTimeMs)
        writeUnitNames(encoder, encounter.unitNames, progress)
        writeDeaths(encoder, encounter.deaths)
        -- v9+: player setup
        writeSetup(encoder, encounter.setup)
        flushProgress(progress)

        local chunks = encoder:finish()

        return {
            _v = CURRENT_VERSION,
            _data = chunks,
            displayName = encounter.displayName,
            location = encounter.location,
            timestampS = encounter.timestampS,
            durationMs = encounter.durationMs,
            bossesUnits = encounter.bossesUnits,
            isPlayerFight = encounter.isPlayerFight,
            isDummyFight = encounter.isDummyFight,
            sharedData = encounter.sharedData,
            bossSeqNames = encounter.bossSeqNames,
            bossTagSeqByUnitId = encounter.bossTagSeqByUnitId,
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
        local _v = binaryEncounter._v
        if _v < 7 or _v > 11 then
            error("Invalid binary encounter version: " .. tostring(_v) .. " (expected 7-11)")
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
            sharedData = binaryEncounter.sharedData,
            bossSeqNames = binaryEncounter.bossSeqNames,
            bossTagSeqByUnitId = binaryEncounter.bossTagSeqByUnitId,
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

        -- v8+: death recap data
        if _v >= 8 then
            result.deaths = readDeaths(decoder)
        end

        -- v9+: player setup
        if _v >= 9 then
            result.setup = readSetup(decoder, _v)
        end

        return result
    end)
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
        local progress = { count = 0 }

        abilityInfo = abilityInfo or {}
        local count = writeTableCount(encoder, abilityInfo, BITS.MAP_COUNT)

        local written = 0
        for abilityId, info in pairs(abilityInfo) do
            if written >= count then break end
            written = written + 1
            encoder:writeUInt(abilityId, BITS.ABILITY_ID)

            local overTimeOrDirect = info.overTimeOrDirect or {}
            encoder:writeBit(overTimeOrDirect.overTime)
            encoder:writeBit(overTimeOrDirect.direct)

            local typeCount = writeTableCount(encoder, info.damageTypes or {}, 4)

            local typesWritten = 0
            for damageType in pairs(info.damageTypes or {}) do
                if typesWritten >= typeCount then break end
                typesWritten = typesWritten + 1
                encoder:writeUInt(damageType, BITS_DAMAGE_TYPE)
            end

            countAndMaybeYield(progress)
        end
        flushProgress(progress)

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


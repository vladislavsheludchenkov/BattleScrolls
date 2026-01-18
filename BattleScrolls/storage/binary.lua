if not SemisPlaygroundCheckAccess() then
    return
end

-- Binary Storage Encoding Module for BattleScrolls
-- Custom BinaryBuffer implementation for bit-level encoding
-- Stores data directly as characters for efficient string output

BattleScrolls = BattleScrolls or {}

---Binary storage module for encoding/decoding combat data
---@class BinaryStorage
---@field BitBuffer BitBuffer BitBuffer class for bit-level encoding
local binaryStorage = {}
BattleScrolls.binaryStorage = binaryStorage

local CURRENT_VERSION = 7

-- =============================================================================
-- CUSTOM BIT BUFFER IMPLEMENTATION (optimized for base64 output)
-- =============================================================================

-- Pre-computed lookup tables for performance
local B64_ENCODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64_DECODE = {}
for i = 1, 64 do
    B64_DECODE[B64_ENCODE:sub(i, i)] = i - 1
end

-- Pre-compute base64 char lookup (index 0-63 → char)
local B64_CHAR = {}
for i = 0, 63 do
    B64_CHAR[i] = B64_ENCODE:sub(i + 1, i + 1)
end

---@class BitBuffer
---@field bytes number[] Array of byte values (0-255)
---@field totalBits number Total bits written
---@field readBitPos number Current read position (0-indexed bit offset)
---@field currentByte number Current byte being written (0-255)
---@field currentBits number Bits written to currentByte (0-7)
local BitBuffer = {}
BitBuffer.__index = BitBuffer

---Creates a new BitBuffer for writing
---@return BitBuffer
function BitBuffer:New()
    return setmetatable({
        bytes = {},
        totalBits = 0,
        readBitPos = 0,
        currentByte = 0,
        currentBits = 0,
    }, BitBuffer)
end

---Creates a BitBuffer from byte array for reading
---@param bytes number[] Array of byte values
---@param totalBits number Total bits in the buffer
---@return BitBuffer
function BitBuffer:FromBytes(bytes, totalBits)
    return setmetatable({
        bytes = bytes,
        totalBits = totalBits,
        readBitPos = 0,
        currentByte = 0,
        currentBits = 0,
    }, BitBuffer)
end

---Flushes any pending bits to bytes array
function BitBuffer:Flush()
    if self.currentBits > 0 then
        self.bytes[#self.bytes + 1] = self.currentByte
        self.currentByte = 0
        self.currentBits = 0
    end
end

-- SavedVariables string limit
local CHUNK_SIZE = 1999

---Converts buffer directly to base64 chunks (no intermediate full string)
---@return string[] chunks Array of base64 strings (each ≤2000 chars)
---@return number totalBits
function BitBuffer:ToBase64Chunks()
    self:Flush()
    local bytes = self.bytes
    local len = #bytes
    local chunks = {}
    local currentChunk = {}
    local chunkLen = 0
    local i = 1

    -- Helper to emit 4 chars, starting new chunk if needed
    local function emit(c1, c2, c3, c4)
        if chunkLen + 4 > CHUNK_SIZE then
            chunks[#chunks + 1] = table.concat(currentChunk)
            currentChunk = {}
            chunkLen = 0
        end
        currentChunk[#currentChunk + 1] = c1
        currentChunk[#currentChunk + 1] = c2
        currentChunk[#currentChunk + 1] = c3
        currentChunk[#currentChunk + 1] = c4
        chunkLen = chunkLen + 4
    end

    -- Process 3 bytes at a time → 4 base64 chars
    while i <= len - 2 do
        local b1, b2, b3 = bytes[i], bytes[i + 1], bytes[i + 2]
        local n = b1 * 65536 + b2 * 256 + b3
        emit(
            B64_CHAR[math.floor(n / 262144)],
            B64_CHAR[math.floor(n / 4096) % 64],
            B64_CHAR[math.floor(n / 64) % 64],
            B64_CHAR[n % 64]
        )
        i = i + 3
    end

    -- Handle remaining 1 or 2 bytes
    local remaining = len - i + 1
    if remaining == 2 then
        local b1, b2 = bytes[i], bytes[i + 1]
        local n = b1 * 65536 + b2 * 256
        emit(
            B64_CHAR[math.floor(n / 262144)],
            B64_CHAR[math.floor(n / 4096) % 64],
            B64_CHAR[math.floor(n / 64) % 64],
            "="
        )
    elseif remaining == 1 then
        local b1 = bytes[i]
        local n = b1 * 65536
        emit(
            B64_CHAR[math.floor(n / 262144)],
            B64_CHAR[math.floor(n / 4096) % 64],
            "=",
            "="
        )
    end

    -- Flush remaining chunk
    if #currentChunk > 0 then
        chunks[#chunks + 1] = table.concat(currentChunk)
    end

    return chunks, self.totalBits
end

---Decodes base64 chunks directly to BitBuffer (no intermediate join)
---@param chunks string[]|string Array of base64 chunks or single string
---@param totalBits number
---@return BitBuffer
function BitBuffer:FromBase64Chunks(chunks, totalBits)
    local bytes = {}
    local chunkIdx = 1
    local posInChunk = 1

    -- Helper to get next char across chunk boundaries
    local function nextChar()
        if chunkIdx > #chunks then return nil end
        local chunk = chunks[chunkIdx]
        if posInChunk > #chunk then
            chunkIdx = chunkIdx + 1
            posInChunk = 1
            if chunkIdx > #chunks then return nil end
            chunk = chunks[chunkIdx]
        end
        local c = chunk:sub(posInChunk, posInChunk)
        posInChunk = posInChunk + 1
        return c
    end

    -- Read 4 chars at a time → 3 bytes
    while true do
        local c1 = nextChar()
        if not c1 then break end
        local c2 = nextChar()
        local c3 = nextChar()
        local c4 = nextChar()
        if not c2 or not c3 or not c4 then break end

        local v1, v2 = B64_DECODE[c1], B64_DECODE[c2]
        local v3, v4 = B64_DECODE[c3] or 0, B64_DECODE[c4] or 0

        local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4

        bytes[#bytes + 1] = math.floor(n / 65536)
        if c3 ~= "=" then
            bytes[#bytes + 1] = math.floor(n / 256) % 256
        end
        if c4 ~= "=" then
            bytes[#bytes + 1] = n % 256
        end
    end

    return BitBuffer:FromBytes(bytes, totalBits)
end

---Writes an unsigned integer of specified bit width
---@param value number The value to write
---@param bits number Number of bits to use
function BitBuffer:WriteUInt(value, bits)
    value = value or 0
    local currentByte = self.currentByte
    local currentBits = self.currentBits
    local bytes = self.bytes

    -- Fast path: byte-aligned writes for full bytes
    if currentBits == 0 then
        while bits >= 8 do
            bytes[#bytes + 1] = BitAnd(value, 0xFF)
            value = BitRShift(value, 8)
            bits = bits - 8
            self.totalBits = self.totalBits + 8
        end
    end

    -- Remaining bits (or non-aligned writes)
    while bits > 0 do
        local bit = BitAnd(value, 1)
        value = BitRShift(value, 1)

        currentByte = BitOr(currentByte, BitLShift(bit, currentBits))
        currentBits = currentBits + 1
        self.totalBits = self.totalBits + 1
        bits = bits - 1

        if currentBits == 8 then
            bytes[#bytes + 1] = currentByte
            currentByte = 0
            currentBits = 0
        end
    end

    self.currentByte = currentByte
    self.currentBits = currentBits
end

---Reads an unsigned integer of specified bit width
---@param bits number Number of bits to read
---@return number value
function BitBuffer:ReadUInt(bits)
    local value = 0
    local readBitPos = self.readBitPos
    local bytes = self.bytes
    local bitOffset = 0

    -- Fast path: byte-aligned reads for full bytes
    if readBitPos % 8 == 0 then
        local byteIndex = BitRShift(readBitPos, 3) + 1  -- readBitPos / 8 + 1
        while bits >= 8 do
            value = BitOr(value, BitLShift(bytes[byteIndex], bitOffset))
            byteIndex = byteIndex + 1
            readBitPos = readBitPos + 8
            bitOffset = bitOffset + 8
            bits = bits - 8
        end
    end

    -- Remaining bits (or non-aligned reads)
    while bits > 0 do
        local byteIndex = BitRShift(readBitPos, 3) + 1
        local bitIndex = BitAnd(readBitPos, 7)  -- readBitPos % 8

        local bit = BitAnd(BitRShift(bytes[byteIndex], bitIndex), 1)
        value = BitOr(value, BitLShift(bit, bitOffset))

        readBitPos = readBitPos + 1
        bitOffset = bitOffset + 1
        bits = bits - 1
    end

    self.readBitPos = readBitPos
    return value
end

---Writes a single bit
---@param value boolean|number
function BitBuffer:WriteBit(value)
    self:WriteUInt(value and 1 or 0, 1)
end

---Reads a single bit
---@return boolean
function BitBuffer:ReadBit()
    return self:ReadUInt(1) == 1
end

---Writes a string (raw bytes, no length prefix)
---@param str string
function BitBuffer:WriteString(str)
    for idx = 1, #str do
        self:WriteUInt(string.byte(str, idx), 8)
    end
end

---Reads a string of specified length
---@param length number
---@return string
function BitBuffer:ReadString(length)
    local chars = {}
    for idx = 1, length do
        chars[idx] = string.char(self:ReadUInt(8))
    end
    return table.concat(chars)
end

-- Make BitBuffer accessible
binaryStorage.BitBuffer = BitBuffer

function binaryStorage.Initialize()
    -- No initialization needed
end

-- =============================================================================
-- BIT ALLOCATION CONSTANTS (conservative as requested)
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
---@field STRING_LENGTH number 8 bits - string length byte (up to 255 chars)
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

    -- String length byte (8 bits = up to 255 chars)
    STRING_LENGTH = 8,

    -- Map/array count (16 bits = up to 65535 entries)
    MAP_COUNT = 16,
}


-- =============================================================================
-- LOW-LEVEL WRITE HELPERS
-- =============================================================================

---Writes a string to buffer (length-prefixed)
---@param buffer BitBuffer
---@param str string
local function writeString(buffer, str)
    local len = str and #str or 0
    buffer:WriteUInt(len, BITS.STRING_LENGTH)
    if len > 0 then
        buffer:WriteString(str)
    end
end

---Reads a string from buffer (length-prefixed)
---@param buffer BitBuffer
---@return string
local function readString(buffer)
    local len = buffer:ReadUInt(BITS.STRING_LENGTH)
    if len == 0 then
        return ""
    end
    return buffer:ReadString(len)
end

---Writes a DamageBreakdown to buffer
---@param buffer BitBuffer
---@param breakdown DamageBreakdown
local function writeDamageBreakdown(buffer, breakdown)
    buffer:WriteUInt(breakdown.total or 0, BITS.TOTAL)
    buffer:WriteUInt(breakdown.rawTotal or breakdown.total or 0, BITS.TOTAL)
    buffer:WriteUInt(breakdown.ticks or 0, BITS.COUNT)
    buffer:WriteUInt(breakdown.critTicks or 0, BITS.COUNT)
    buffer:WriteUInt(breakdown.minTick or 0, BITS.TICK_VALUE)
    buffer:WriteUInt(breakdown.maxTick or 0, BITS.TICK_VALUE)
end

---Reads a DamageBreakdown from buffer
---@param buffer BitBuffer
---@return DamageBreakdown
local function readDamageBreakdown(buffer)
    return {
        total = buffer:ReadUInt(BITS.TOTAL),
        rawTotal = buffer:ReadUInt(BITS.TOTAL),
        ticks = buffer:ReadUInt(BITS.COUNT),
        critTicks = buffer:ReadUInt(BITS.COUNT),
        minTick = buffer:ReadUInt(BITS.TICK_VALUE),
        maxTick = buffer:ReadUInt(BITS.TICK_VALUE),
    }
end

---Writes a HealingTotals to buffer
---@param buffer BitBuffer
---@param totals HealingTotals|nil
local function writeHealingTotals(buffer, totals)
    buffer:WriteUInt(totals and totals.raw or 0, BITS.TOTAL)
    buffer:WriteUInt(totals and totals.real or 0, BITS.TOTAL)
    buffer:WriteUInt(totals and totals.overheal or 0, BITS.TOTAL)
end

---Reads a HealingTotals from buffer
---@param buffer BitBuffer
---@return HealingTotals
local function readHealingTotals(buffer)
    return {
        raw = buffer:ReadUInt(BITS.TOTAL),
        real = buffer:ReadUInt(BITS.TOTAL),
        overheal = buffer:ReadUInt(BITS.TOTAL),
    }
end

---Writes a HealingBreakdown to buffer
---@param buffer BitBuffer
---@param breakdown HealingBreakdown
local function writeHealingBreakdown(buffer, breakdown)
    buffer:WriteUInt(breakdown.raw or 0, BITS.TOTAL)
    buffer:WriteUInt(breakdown.real or 0, BITS.TOTAL)
    buffer:WriteUInt(breakdown.overheal or 0, BITS.TOTAL)
    buffer:WriteUInt(breakdown.ticks or 0, BITS.COUNT)
    buffer:WriteUInt(breakdown.critTicks or 0, BITS.COUNT)
    buffer:WriteUInt(breakdown.minTick or 0, BITS.TICK_VALUE)
    buffer:WriteUInt(breakdown.maxTick or 0, BITS.TICK_VALUE)
end

---Reads a HealingBreakdown from buffer
---@param buffer BitBuffer
---@return HealingBreakdown
local function readHealingBreakdown(buffer)
    return {
        raw = buffer:ReadUInt(BITS.TOTAL),
        real = buffer:ReadUInt(BITS.TOTAL),
        overheal = buffer:ReadUInt(BITS.TOTAL),
        ticks = buffer:ReadUInt(BITS.COUNT),
        critTicks = buffer:ReadUInt(BITS.COUNT),
        minTick = buffer:ReadUInt(BITS.TICK_VALUE),
        maxTick = buffer:ReadUInt(BITS.TICK_VALUE),
    }
end

---Writes an EffectStats to buffer
---@param buffer BitBuffer
---@param stats EffectStats|BossEffectStats|GroupEffectStats
local function writeEffectStats(buffer, stats)
    buffer:WriteUInt(stats.abilityId or 0, BITS.ABILITY_ID)
    buffer:WriteUInt(stats.effectType or 0, BITS.EFFECT_TYPE)
    buffer:WriteUInt(stats.totalActiveTimeMs or 0, BITS.TIME_MS)
    buffer:WriteUInt(stats.timeAtMaxStacksMs or 0, BITS.TIME_MS)
    buffer:WriteUInt(stats.applications or 0, BITS.APPLICATIONS)
    buffer:WriteUInt(stats.maxStacks or 0, BITS.MAX_STACKS)
    buffer:WriteUInt(stats.playerActiveTimeMs or 0, BITS.TIME_MS)
    buffer:WriteUInt(stats.playerTimeAtMaxStacksMs or 0, BITS.TIME_MS)
    buffer:WriteUInt(stats.playerApplications or 0, BITS.APPLICATIONS)
    -- v5: peakConcurrentInstances
    buffer:WriteUInt(stats.peakConcurrentInstances or 1, BITS.MAX_STACKS)
end

---Reads an EffectStats from buffer
---@param buffer BitBuffer
---@return BossEffectStats
local function readEffectStats(buffer)
    return {
        abilityId = buffer:ReadUInt(BITS.ABILITY_ID),
        effectType = buffer:ReadUInt(BITS.EFFECT_TYPE),
        totalActiveTimeMs = buffer:ReadUInt(BITS.TIME_MS),
        timeAtMaxStacksMs = buffer:ReadUInt(BITS.TIME_MS),
        applications = buffer:ReadUInt(BITS.APPLICATIONS),
        maxStacks = buffer:ReadUInt(BITS.MAX_STACKS),
        playerActiveTimeMs = buffer:ReadUInt(BITS.TIME_MS),
        playerTimeAtMaxStacksMs = buffer:ReadUInt(BITS.TIME_MS),
        playerApplications = buffer:ReadUInt(BITS.APPLICATIONS),
        peakConcurrentInstances = buffer:ReadUInt(BITS.MAX_STACKS),
    }
end

-- =============================================================================
-- DAMAGE MAP ENCODING (nested: sourceId -> targetId -> abilityId -> breakdown)
-- =============================================================================

---Writes a damage map to buffer
---@param buffer BitBuffer
---@param damageMap table<number, table<number, DamageDone|DamageByAbility>>|nil Nested: sourceId -> targetId -> damage
local function writeDamageMap(buffer, damageMap)
    -- Count sources
    local sourceCount = 0
    for _ in pairs(damageMap or {}) do sourceCount = sourceCount + 1 end
    buffer:WriteUInt(sourceCount, BITS.MAP_COUNT)

    for sourceId, byTarget in pairs(damageMap or {}) do
        buffer:WriteUInt(sourceId, BITS.UNIT_ID)

        -- Count targets
        local targetCount = 0
        for _ in pairs(byTarget) do targetCount = targetCount + 1 end
        buffer:WriteUInt(targetCount, BITS.MAP_COUNT)

        for targetId, damageDone in pairs(byTarget) do
            buffer:WriteUInt(targetId, BITS.UNIT_ID)

            -- Count abilities (damageDone.byAbilityId or damageDone itself if already decoded format)
            local byAbility = damageDone.byAbilityId or damageDone
            local abilityCount = 0
            for _ in pairs(byAbility) do abilityCount = abilityCount + 1 end
            buffer:WriteUInt(abilityCount, BITS.MAP_COUNT)

            for abilityId, breakdown in pairs(byAbility) do
                buffer:WriteUInt(abilityId, BITS.ABILITY_ID)
                writeDamageBreakdown(buffer, breakdown)
            end
        end
    end
end

---Reads a damage map from buffer
---@param buffer BitBuffer
---@return table<number, table<number, DamageByAbility>> Nested: sourceId -> targetId -> (abilityId -> DamageBreakdown)
local function readDamageMap(buffer)
    local result = {}
    local sourceCount = buffer:ReadUInt(BITS.MAP_COUNT)

    for _ = 1, sourceCount do
        local sourceId = buffer:ReadUInt(BITS.UNIT_ID)
        result[sourceId] = {}

        local targetCount = buffer:ReadUInt(BITS.MAP_COUNT)
        for _ = 1, targetCount do
            local targetId = buffer:ReadUInt(BITS.UNIT_ID)
            result[sourceId][targetId] = {}

            local abilityCount = buffer:ReadUInt(BITS.MAP_COUNT)
            for _ = 1, abilityCount do
                local abilityId = buffer:ReadUInt(BITS.ABILITY_ID)
                result[sourceId][targetId][abilityId] = readDamageBreakdown(buffer)
            end
        end
    end

    return result
end

-- =============================================================================
-- HEALING STATS ENCODING
-- =============================================================================

---Writes HealingDoneDiffSource to buffer
---@param buffer BitBuffer
---@param healing HealingDoneDiffSource
local function writeHealingDoneDiffSource(buffer, healing)
    writeHealingTotals(buffer, healing.total)
    -- v6+: byHotVsDirect computed on-demand from byAbilityId + abilityInfo

    -- bySourceUnitIdByAbilityId
    local sourceCount = 0
    for _ in pairs(healing.bySourceUnitIdByAbilityId or {}) do sourceCount = sourceCount + 1 end
    buffer:WriteUInt(sourceCount, BITS.MAP_COUNT)

    for sourceId, byAbility in pairs(healing.bySourceUnitIdByAbilityId or {}) do
        buffer:WriteUInt(sourceId, BITS.UNIT_ID)

        local abilityCount = 0
        for _ in pairs(byAbility) do abilityCount = abilityCount + 1 end
        buffer:WriteUInt(abilityCount, BITS.MAP_COUNT)

        for abilityId, breakdown in pairs(byAbility) do
            buffer:WriteUInt(abilityId, BITS.ABILITY_ID)
            writeHealingBreakdown(buffer, breakdown)
        end
    end
end

---Reads HealingDoneDiffSource from buffer
---@param buffer BitBuffer
---@return HealingDoneDiffSource
local function readHealingDoneDiffSource(buffer)
    local result = {
        total = readHealingTotals(buffer),
        bySourceUnitIdByAbilityId = {},
    }

    local sourceCount = buffer:ReadUInt(BITS.MAP_COUNT)
    for _ = 1, sourceCount do
        local sourceId = buffer:ReadUInt(BITS.UNIT_ID)
        result.bySourceUnitIdByAbilityId[sourceId] = {}

        local abilityCount = buffer:ReadUInt(BITS.MAP_COUNT)
        for _ = 1, abilityCount do
            local abilityId = buffer:ReadUInt(BITS.ABILITY_ID)
            result.bySourceUnitIdByAbilityId[sourceId][abilityId] = readHealingBreakdown(buffer)
        end
    end

    return result
end

---Writes HealingDone to buffer
---@param buffer BitBuffer
---@param healing HealingDone
local function writeHealingDone(buffer, healing)
    writeHealingTotals(buffer, healing.total)
    -- v6+: byHotVsDirect computed on-demand from byAbilityId + abilityInfo

    local abilityCount = 0
    for _ in pairs(healing.byAbilityId or {}) do abilityCount = abilityCount + 1 end
    buffer:WriteUInt(abilityCount, BITS.MAP_COUNT)

    for abilityId, breakdown in pairs(healing.byAbilityId or {}) do
        buffer:WriteUInt(abilityId, BITS.ABILITY_ID)
        writeHealingBreakdown(buffer, breakdown)
    end
end

---Reads HealingDone from buffer
---@param buffer BitBuffer
---@return HealingDone
local function readHealingDone(buffer)
    local result = {
        total = readHealingTotals(buffer),
        byAbilityId = {},
    }

    local abilityCount = buffer:ReadUInt(BITS.MAP_COUNT)
    for _ = 1, abilityCount do
        local abilityId = buffer:ReadUInt(BITS.ABILITY_ID)
        result.byAbilityId[abilityId] = readHealingBreakdown(buffer)
    end

    return result
end

---Writes HealingStats to buffer
---@param buffer BitBuffer
---@param healingStats HealingStats
local function writeHealingStats(buffer, healingStats)
    writeHealingDoneDiffSource(buffer, healingStats.selfHealing)

    -- healingOutToGroup
    local outCount = 0
    for _ in pairs(healingStats.healingOutToGroup or {}) do outCount = outCount + 1 end
    buffer:WriteUInt(outCount, BITS.MAP_COUNT)

    for targetId, healing in pairs(healingStats.healingOutToGroup or {}) do
        buffer:WriteUInt(targetId, BITS.UNIT_ID)
        writeHealingDoneDiffSource(buffer, healing)
    end

    -- healingInFromGroup
    local inCount = 0
    for _ in pairs(healingStats.healingInFromGroup or {}) do inCount = inCount + 1 end
    buffer:WriteUInt(inCount, BITS.MAP_COUNT)

    for sourceId, healing in pairs(healingStats.healingInFromGroup or {}) do
        buffer:WriteUInt(sourceId, BITS.UNIT_ID)
        writeHealingDone(buffer, healing)
    end
end

---Reads HealingStats from buffer
---@param buffer BitBuffer
---@return HealingStats
local function readHealingStats(buffer)
    local result = {
        selfHealing = readHealingDoneDiffSource(buffer),
        healingOutToGroup = {},
        healingInFromGroup = {},
    }

    local outCount = buffer:ReadUInt(BITS.MAP_COUNT)
    for _ = 1, outCount do
        local targetId = buffer:ReadUInt(BITS.UNIT_ID)
        result.healingOutToGroup[targetId] = readHealingDoneDiffSource(buffer)
    end

    local inCount = buffer:ReadUInt(BITS.MAP_COUNT)
    for _ = 1, inCount do
        local sourceId = buffer:ReadUInt(BITS.UNIT_ID)
        result.healingInFromGroup[sourceId] = readHealingDone(buffer)
    end

    return result
end

-- =============================================================================
-- PROCS ENCODING
-- =============================================================================

---Writes procs to buffer
---@param buffer BitBuffer
---@param procs ProcData[]
local function writeProcs(buffer, procs)
    buffer:WriteUInt(#(procs or {}), BITS.MAP_COUNT)

    for _, proc in ipairs(procs or {}) do
        buffer:WriteUInt(proc.abilityId, BITS.ABILITY_ID)
        buffer:WriteUInt(proc.totalProcs or 0, BITS.COUNT)
        buffer:WriteUInt(proc.meanIntervalMs or 0, BITS.INTERVAL_MS)
        buffer:WriteUInt(proc.medianIntervalMs or 0, BITS.INTERVAL_MS)

        buffer:WriteUInt(#(proc.procsByEnemy or {}), BITS.MAP_COUNT)
        for _, enemy in ipairs(proc.procsByEnemy or {}) do
            buffer:WriteUInt(enemy.unitId, BITS.UNIT_ID)
            buffer:WriteUInt(enemy.procCount or 0, BITS.COUNT)
        end
    end
end

---Reads procs from buffer
---@param buffer BitBuffer
---@return ProcData[]
local function readProcs(buffer)
    local result = {}
    local procCount = buffer:ReadUInt(BITS.MAP_COUNT)

    for _ = 1, procCount do
        local proc = {
            abilityId = buffer:ReadUInt(BITS.ABILITY_ID),
            totalProcs = buffer:ReadUInt(BITS.COUNT),
            meanIntervalMs = buffer:ReadUInt(BITS.INTERVAL_MS),
            medianIntervalMs = buffer:ReadUInt(BITS.INTERVAL_MS),
            procsByEnemy = {},
        }

        local enemyCount = buffer:ReadUInt(BITS.MAP_COUNT)
        for _ = 1, enemyCount do
            proc.procsByEnemy[#proc.procsByEnemy + 1] = {
                unitId = buffer:ReadUInt(BITS.UNIT_ID),
                procCount = buffer:ReadUInt(BITS.COUNT),
            }
        end

        result[#result + 1] = proc
    end

    return result
end

-- =============================================================================
-- EFFECTS ENCODING
-- =============================================================================

---Writes effectsOnPlayer to buffer
---@param buffer BitBuffer
---@param effectsOnPlayer table<number, PlayerEffectStats>|nil
local function writeEffectsOnPlayer(buffer, effectsOnPlayer)
    local count = 0
    for _ in pairs(effectsOnPlayer or {}) do count = count + 1 end
    buffer:WriteUInt(count, BITS.MAP_COUNT)

    for abilityId, stats in pairs(effectsOnPlayer or {}) do
        buffer:WriteUInt(abilityId, BITS.ABILITY_ID)
        writeEffectStats(buffer, stats)
    end
end

---Reads effectsOnPlayer from buffer
---@param buffer BitBuffer
---@return table<number, PlayerEffectStats>|nil
local function readEffectsOnPlayer(buffer)
    local count = buffer:ReadUInt(BITS.MAP_COUNT)
    if count == 0 then return nil end

    local result = {}
    for _ = 1, count do
        local abilityId = buffer:ReadUInt(BITS.ABILITY_ID)
        result[abilityId] = readEffectStats(buffer)
        result[abilityId].abilityId = abilityId  -- Ensure abilityId is set
    end
    return result
end

---Writes effectsOnBosses to buffer
---@param buffer BitBuffer
---@param effectsOnBosses table<string, table<number, BossEffectStats>>|nil
local function writeEffectsOnBosses(buffer, effectsOnBosses)
    local unitCount = 0
    for _ in pairs(effectsOnBosses or {}) do unitCount = unitCount + 1 end
    buffer:WriteUInt(unitCount, BITS.MAP_COUNT)

    for unitTag, byAbility in pairs(effectsOnBosses or {}) do
        writeString(buffer, unitTag)

        local abilityCount = 0
        for _ in pairs(byAbility) do abilityCount = abilityCount + 1 end
        buffer:WriteUInt(abilityCount, BITS.MAP_COUNT)

        for abilityId, stats in pairs(byAbility) do
            buffer:WriteUInt(abilityId, BITS.ABILITY_ID)
            writeEffectStats(buffer, stats)
        end
    end
end

---Reads effectsOnBosses from buffer
---@param buffer BitBuffer
---@return table<string, table<number, BossEffectStats>>|nil
local function readEffectsOnBosses(buffer)
    local unitCount = buffer:ReadUInt(BITS.MAP_COUNT)
    if unitCount == 0 then return nil end

    local result = {}
    for _ = 1, unitCount do
        local unitTag = readString(buffer)
        result[unitTag] = {}

        local abilityCount = buffer:ReadUInt(BITS.MAP_COUNT)
        for _ = 1, abilityCount do
            local abilityId = buffer:ReadUInt(BITS.ABILITY_ID)
            result[unitTag][abilityId] = readEffectStats(buffer)
            result[unitTag][abilityId].abilityId = abilityId
        end
    end
    return result
end

---Writes effectsOnGroup to buffer
---@param buffer BitBuffer
---@param effectsOnGroup table<string, table<number, GroupEffectStats>>|nil
local function writeEffectsOnGroup(buffer, effectsOnGroup)
    local memberCount = 0
    for _ in pairs(effectsOnGroup or {}) do memberCount = memberCount + 1 end
    buffer:WriteUInt(memberCount, BITS.MAP_COUNT)

    for displayName, byAbility in pairs(effectsOnGroup or {}) do
        writeString(buffer, displayName)

        local abilityCount = 0
        for _ in pairs(byAbility) do abilityCount = abilityCount + 1 end
        buffer:WriteUInt(abilityCount, BITS.MAP_COUNT)

        for abilityId, stats in pairs(byAbility) do
            buffer:WriteUInt(abilityId, BITS.ABILITY_ID)
            writeEffectStats(buffer, stats)
        end
    end
end

---Reads effectsOnGroup from buffer
---@param buffer BitBuffer
---@return table<string, table<number, GroupEffectStats>>|nil
local function readEffectsOnGroup(buffer)
    local memberCount = buffer:ReadUInt(BITS.MAP_COUNT)
    if memberCount == 0 then return nil end

    local result = {}
    for _ = 1, memberCount do
        local displayName = readString(buffer)
        result[displayName] = {}

        local abilityCount = buffer:ReadUInt(BITS.MAP_COUNT)
        for _ = 1, abilityCount do
            local abilityId = buffer:ReadUInt(BITS.ABILITY_ID)
            result[displayName][abilityId] = readEffectStats(buffer)
            result[displayName][abilityId].abilityId = abilityId
        end
    end
    return result
end

-- =============================================================================
-- BOSS NAMES & ALIVE TIMES
-- =============================================================================

---Writes bossNames to buffer
---@param buffer BitBuffer
---@param bossNames table<string, string>|nil
local function writeBossNames(buffer, bossNames)
    local count = 0
    for _ in pairs(bossNames or {}) do count = count + 1 end
    buffer:WriteUInt(count, BITS.MAP_COUNT)

    for unitTag, name in pairs(bossNames or {}) do
        writeString(buffer, unitTag)
        writeString(buffer, name)
    end
end

---Reads bossNames from buffer
---@param buffer BitBuffer
---@return table<string, string>|nil
local function readBossNames(buffer)
    local count = buffer:ReadUInt(BITS.MAP_COUNT)
    if count == 0 then return nil end

    local result = {}
    for _ = 1, count do
        local unitTag = readString(buffer)
        local name = readString(buffer)
        result[unitTag] = name
    end
    return result
end

---Writes unitAliveTimeMs to buffer
---@param buffer BitBuffer
---@param unitAliveTimeMs table<string, number>|nil
local function writeUnitAliveTimes(buffer, unitAliveTimeMs)
    local count = 0
    for _ in pairs(unitAliveTimeMs or {}) do count = count + 1 end
    buffer:WriteUInt(count, BITS.MAP_COUNT)

    for unitKey, timeMs in pairs(unitAliveTimeMs or {}) do
        writeString(buffer, unitKey)
        buffer:WriteUInt(timeMs, BITS.TIME_MS)
    end
end

---Reads unitAliveTimeMs from buffer
---@param buffer BitBuffer
---@return table<string, number>|nil
local function readUnitAliveTimes(buffer)
    local count = buffer:ReadUInt(BITS.MAP_COUNT)
    if count == 0 then return nil end

    local result = {}
    for _ = 1, count do
        local unitKey = readString(buffer)
        local timeMs = buffer:ReadUInt(BITS.TIME_MS)
        result[unitKey] = timeMs
    end
    return result
end

---Writes unitNames to buffer
---@param buffer BitBuffer
---@param unitNames table<number, string>|nil
local function writeUnitNames(buffer, unitNames)
    unitNames = unitNames or {}
    local count = 0
    for _ in pairs(unitNames) do count = count + 1 end
    buffer:WriteUInt(count, BITS.MAP_COUNT)

    for unitId, name in pairs(unitNames) do
        buffer:WriteUInt(unitId, BITS.UNIT_ID)
        writeString(buffer, name)
    end
end

---Reads unitNames from buffer
---@param buffer BitBuffer
---@return table<number, string>
local function readUnitNames(buffer)
    local result = {}
    local count = buffer:ReadUInt(BITS.MAP_COUNT)

    for _ = 1, count do
        local unitId = buffer:ReadUInt(BITS.UNIT_ID)
        local name = readString(buffer)
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
function binaryStorage.EncodeEncounterAsync(encounter)
    return LibEffect.Async(function()
        local buffer = BitBuffer:New()

        -- Write all data directly to buffer, yielding between major sections
        writeDamageMap(buffer, encounter.damageByUnitId)
        LibEffect.YieldWithGC():Await()
        writeDamageMap(buffer, encounter.damageByUnitIdGroup)
        LibEffect.YieldWithGC():Await()
        writeDamageMap(buffer, encounter.damageTakenByUnitId)
        LibEffect.YieldWithGC():Await()
        writeHealingStats(buffer, encounter.healingStats)
        LibEffect.YieldWithGC():Await()
        writeProcs(buffer, encounter.procs)
        LibEffect.YieldWithGC():Await()
        writeEffectsOnPlayer(buffer, encounter.effectsOnPlayer)
        LibEffect.YieldWithGC():Await()
        writeEffectsOnBosses(buffer, encounter.effectsOnBosses)
        LibEffect.YieldWithGC():Await()
        writeEffectsOnGroup(buffer, encounter.effectsOnGroup)
        LibEffect.YieldWithGC():Await()
        writeBossNames(buffer, encounter.bossNames)

        -- playerAliveTimeMs (optional)
        if encounter.playerAliveTimeMs then
            buffer:WriteBit(true)
            buffer:WriteUInt(encounter.playerAliveTimeMs, BITS.TIME_MS)
        else
            buffer:WriteBit(false)
        end

        LibEffect.YieldWithGC():Await()

        writeUnitAliveTimes(buffer, encounter.unitAliveTimeMs)

        LibEffect.YieldWithGC():Await()

        -- v7+: encode unitNames in encounter buffer
        writeUnitNames(buffer, encounter.unitNames)

        LibEffect.YieldWithGC():Await()

        local chunks, bitLength = buffer:ToBase64Chunks()

        -- Return encounter with binary data and preserved metadata
        return {
            _v = CURRENT_VERSION,  -- Schema version (v4 adds rawTotal to DamageBreakdown)
            _bits = bitLength,
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
function binaryStorage.DecodeEncounterAsync(binaryEncounter)
    return LibEffect.Async(function()
        if binaryEncounter._v ~= 7 then
            error("Invalid binary encounter version: " .. tostring(binaryEncounter._v) .. " (expected 7)")
        end

        local buffer = BitBuffer:FromBase64Chunks(binaryEncounter._data, binaryEncounter._bits)

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

        result.damageByUnitId = readDamageMap(buffer)
        LibEffect.YieldWithGC():Await()

        result.damageByUnitIdGroup = readDamageMap(buffer)
        LibEffect.YieldWithGC():Await()

        result.damageTakenByUnitId = readDamageMap(buffer)
        LibEffect.YieldWithGC():Await()

        result.healingStats = readHealingStats(buffer)
        LibEffect.YieldWithGC():Await()

        result.procs = readProcs(buffer)
        LibEffect.YieldWithGC():Await()

        result.effectsOnPlayer = readEffectsOnPlayer(buffer)
        result.effectsOnBosses = readEffectsOnBosses(buffer)
        result.effectsOnGroup = readEffectsOnGroup(buffer)
        result.bossNames = readBossNames(buffer)

        -- playerAliveTimeMs (optional)
        if buffer:ReadBit() then
            result.playerAliveTimeMs = buffer:ReadUInt(BITS.TIME_MS)
        end

        result.unitAliveTimeMs = readUnitAliveTimes(buffer)
        LibEffect.YieldWithGC():Await()

        result.unitNames = readUnitNames(buffer)

        return result
    end)
end

---Checks if an encounter is in binary format
---@param encounter Encounter|CompactEncounter
---@return boolean
function binaryStorage.IsBinaryEncounter(encounter)
    return encounter._v >= 3 and encounter._data ~= nil
end

-- =============================================================================
-- INSTANCE-LEVEL ENCODING: abilityInfo and unitNames
-- =============================================================================

-- Additional bit allocations for instance-level encoding
local BITS_DAMAGE_TYPE = 4  -- DamageType enum (16 values max)

---Reads abilityInfo from buffer
---@param buffer BitBuffer
---@return table<number, AbilityInfoStorage>
local function readAbilityInfo(buffer)
    local result = {}
    local count = buffer:ReadUInt(BITS.MAP_COUNT)

    for _ = 1, count do
        local abilityId = buffer:ReadUInt(BITS.ABILITY_ID)

        local overTime = buffer:ReadBit()
        local direct = buffer:ReadBit()

        local typeCount = buffer:ReadUInt(4)
        local damageTypes = {}
        for _ = 1, typeCount do
            local damageType = buffer:ReadUInt(BITS_DAMAGE_TYPE)
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
---@field _instanceBits number Total bit length

---Encodes instance-level abilityInfo to binary format asynchronously.
---Returns an Effect that resolves to the encoded fields.
---@param abilityInfo table<number, AbilityInfo> The ability info to encode
---@return Effect Effect that resolves to EncodedInstanceFields
function binaryStorage.EncodeInstanceFieldsAsync(abilityInfo)
    return LibEffect.Async(function()
        local buffer = BitBuffer:New()

        -- Write abilityInfo with yields
        abilityInfo = abilityInfo or {}
        local count = 0
        for _ in pairs(abilityInfo) do count = count + 1 end
        buffer:WriteUInt(count, BITS.MAP_COUNT)

        local i = 0
        for abilityId, info in pairs(abilityInfo) do
            buffer:WriteUInt(abilityId, BITS.ABILITY_ID)

            local overTimeOrDirect = info.overTimeOrDirect or {}
            buffer:WriteBit(overTimeOrDirect.overTime)
            buffer:WriteBit(overTimeOrDirect.direct)

            local typeCount = 0
            for _ in pairs(info.damageTypes or {}) do typeCount = typeCount + 1 end
            buffer:WriteUInt(typeCount, 4)

            for damageType in pairs(info.damageTypes or {}) do
                buffer:WriteUInt(damageType, BITS_DAMAGE_TYPE)
            end

            i = i + 1
            if i % 50 == 0 then
                LibEffect.YieldWithGC():Await()
            end
        end
        LibEffect.YieldWithGC():Await()

        local chunks, bitLength = buffer:ToBase64Chunks()

        return {
            _instanceData = chunks,
            _instanceBits = bitLength,
        }
    end)
end

---Decodes instance-level abilityInfo asynchronously.
---Returns an Effect that resolves to { abilityInfo, {} }.
---Note: unitNames are stored at encounter level (not instance level).
---@param instance InstanceStorage The instance with encoded _instanceData
---@return Effect Effect that resolves to DecodedInstanceFields
function binaryStorage.DecodeInstanceFieldsAsync(instance)
    return LibEffect.Async(function()
        if not instance._instanceData then
            error("Instance missing _instanceData - corrupted or incompatible format")
        end

        local buffer = BitBuffer:FromBase64Chunks(instance._instanceData, instance._instanceBits)
        LibEffect.YieldWithGC():Await()

        local abilityInfo = readAbilityInfo(buffer)
        LibEffect.YieldWithGC():Await()

        return { abilityInfo, {} }
    end)
end

---Checks if an instance has encoded fields
---@param instance Instance
---@return boolean
function binaryStorage.HasEncodedInstanceFields(instance)
    return instance._instanceData ~= nil
end

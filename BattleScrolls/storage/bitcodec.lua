if not SemisPlaygroundCheckAccess() then
    return
end

-- Bit Codec Module for BattleScrolls
-- Provides streaming bit-level encoding/decoding to/from base64 chunks
-- Used by binary.lua for encounter and instance encoding

BattleScrolls = BattleScrolls or {}

---@class BitCodec
---@field BitEncoder BitEncoder Encoder class for writing to base64 chunks
---@field BitDecoder BitDecoder Decoder class for reading from base64 chunks
local bitcodec = {}
BattleScrolls.bitcodec = bitcodec

-- =============================================================================
-- BASE64 LOOKUP TABLES
-- =============================================================================

-- Base64 alphabet
local B64_ENCODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Byte-indexed base64 decode lookup (byte code -> 0-63 value)
local B64_DECODE_BYTE = {}
for i = 1, 64 do
    B64_DECODE_BYTE[string.byte(B64_ENCODE, i)] = i - 1
end
local EQUALS_BYTE = string.byte("=")  -- 61

-- Index 0-63 -> base64 char
local B64_CHAR = {}
for i = 0, 63 do
    B64_CHAR[i] = B64_ENCODE:sub(i + 1, i + 1)
end

-- =============================================================================
-- ENCODER THRESHOLD
-- =============================================================================

-- Flush to chunk when we have this many bytes
-- PS5 investigation: reduced from 1497 (1996 chars) to 180 (240 chars) to test
-- if string length causes SavedVariables corruption on PS5
local ENCODE_FLUSH_BYTES = 180

-- =============================================================================
-- BIT ENCODER - Write-only, streams directly to base64 chunks
-- =============================================================================

---@class BitEncoder
---@field private _chunks string[] Completed base64 chunks
---@field private _bytes number[] Pending bytes (not yet converted to base64)
---@field private _currentByte number Partial byte being built
---@field private _currentBits number Bits in partial byte (0-7)
local BitEncoder = {}
BitEncoder.__index = BitEncoder

---Creates a new BitEncoder
---@return BitEncoder
function BitEncoder.new()
    return setmetatable({
        _chunks = {},
        _bytes = {},
        _currentByte = 0,
        _currentBits = 0,
    }, BitEncoder)
end

---Writes an unsigned integer
---@param value number
---@param bits number
function BitEncoder:writeUInt(value, bits)
    value = value or 0
    local currentByte = self._currentByte
    local currentBits = self._currentBits
    local bytes = self._bytes

    -- Fast path: byte-aligned writes
    if currentBits == 0 then
        while bits >= 8 do
            bytes[#bytes + 1] = BitAnd(value, 0xFF)
            value = BitRShift(value, 8)
            bits = bits - 8
        end
    end

    -- Remaining bits
    while bits > 0 do
        local bit = BitAnd(value, 1)
        value = BitRShift(value, 1)
        currentByte = BitOr(currentByte, BitLShift(bit, currentBits))
        currentBits = currentBits + 1
        bits = bits - 1

        if currentBits == 8 then
            bytes[#bytes + 1] = currentByte
            currentByte = 0
            currentBits = 0
        end
    end

    self._currentByte = currentByte
    self._currentBits = currentBits

    -- Flush to chunk if we have enough bytes
    if #bytes >= ENCODE_FLUSH_BYTES then
        self:_flushToChunk()
    end
end

---Writes a single bit
---@param value boolean|number
function BitEncoder:writeBit(value)
    self:writeUInt(value and 1 or 0, 1)
end

---Writes a length-prefixed string (8-bit length + raw bytes)
---Strings longer than 255 bytes are truncated.
---@param str string|nil String to write (nil treated as empty)
function BitEncoder:writeString(str)
    local len = str and #str or 0
    if len > 255 then
        len = 255
    end
    self:writeUInt(len, 8)
    for i = 1, len do
        self:writeUInt(string.byte(str, i), 8)
    end
end

---Flushes pending bytes to a base64 chunk
---@private
function BitEncoder:_flushToChunk()
    local bytes = self._bytes
    local len = #bytes
    local processBytes = math.floor(len / 3) * 3  -- Only complete triplets
    if processBytes == 0 then return end

    local chunk = {}
    for i = 1, processBytes, 3 do
        local b1, b2, b3 = bytes[i], bytes[i + 1], bytes[i + 2]
        local n = b1 * 65536 + b2 * 256 + b3
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 262144)]
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 4096) % 64]
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 64) % 64]
        chunk[#chunk + 1] = B64_CHAR[n % 64]
    end

    self._chunks[#self._chunks + 1] = table.concat(chunk)

    -- Keep remainder
    local newBytes = {}
    for i = processBytes + 1, len do
        newBytes[#newBytes + 1] = bytes[i]
    end
    self._bytes = newBytes
end

---Finalizes encoding and returns chunks
---@return string[] chunks
function BitEncoder:finish()
    -- Flush partial byte
    if self._currentBits > 0 then
        self._bytes[#self._bytes + 1] = self._currentByte
        self._currentByte = 0
        self._currentBits = 0
    end

    local chunks = self._chunks
    local bytes = self._bytes
    local len = #bytes

    if len == 0 then
        return chunks
    end

    -- Process remaining bytes
    local chunk = {}
    local i = 1

    -- Complete triplets
    while i <= len - 2 do
        local b1, b2, b3 = bytes[i], bytes[i + 1], bytes[i + 2]
        local n = b1 * 65536 + b2 * 256 + b3
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 262144)]
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 4096) % 64]
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 64) % 64]
        chunk[#chunk + 1] = B64_CHAR[n % 64]
        i = i + 3
    end

    -- Remaining 1-2 bytes with padding
    local remaining = len - i + 1
    if remaining == 2 then
        local b1, b2 = bytes[i], bytes[i + 1]
        local n = b1 * 65536 + b2 * 256
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 262144)]
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 4096) % 64]
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 64) % 64]
        chunk[#chunk + 1] = "="
    elseif remaining == 1 then
        local b1 = bytes[i]
        local n = b1 * 65536
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 262144)]
        chunk[#chunk + 1] = B64_CHAR[math.floor(n / 4096) % 64]
        chunk[#chunk + 1] = "="
        chunk[#chunk + 1] = "="
    end

    if #chunk > 0 then
        chunks[#chunks + 1] = table.concat(chunk)
    end

    return chunks
end

-- =============================================================================
-- BIT DECODER - Read-only, lazy streaming from base64 chunks
-- =============================================================================

---@class BitDecoder
---@field private _chunks string[] Source base64 chunks
---@field private _chunkIdx number Current chunk index
---@field private _posInChunk number Position within current chunk
---@field private _bytes number[] Decoded bytes buffer (consumed bytes are removed)
---@field private _bitOffset number Bit offset within _bytes[1] (0-7)
local BitDecoder = {}
BitDecoder.__index = BitDecoder

---Creates a new BitDecoder from base64 chunks
---@param chunks string[]
---@return BitDecoder
function BitDecoder.new(chunks)
    return setmetatable({
        _chunks = chunks,
        _chunkIdx = 1,
        _posInChunk = 1,
        _bytes = {},
        _bitOffset = 0,
    }, BitDecoder)
end

---Gets next base64 character from chunks
---@private
---@return number|nil
function BitDecoder:_nextChar()
    local chunks = self._chunks
    if self._chunkIdx > #chunks then return nil end

    local chunk = chunks[self._chunkIdx]
    if self._posInChunk > #chunk then
        self._chunkIdx = self._chunkIdx + 1
        self._posInChunk = 1
        if self._chunkIdx > #chunks then return nil end
        chunk = chunks[self._chunkIdx]
    end

    local c = string.byte(chunk, self._posInChunk)
    self._posInChunk = self._posInChunk + 1
    return c
end

---Ensures bytes array has at least `needed` bytes decoded
---@private
---@param needed number Byte count needed
function BitDecoder:_ensureBytes(needed)
    local bytes = self._bytes
    while #bytes < needed do
        local c1 = self:_nextChar()
        if not c1 then break end
        local c2 = self:_nextChar()
        local c3 = self:_nextChar()
        local c4 = self:_nextChar()
        if not c2 or not c3 or not c4 then break end

        local v1 = B64_DECODE_BYTE[c1]
        local v2 = B64_DECODE_BYTE[c2]
        local v3 = c3 ~= EQUALS_BYTE and B64_DECODE_BYTE[c3] or 0
        local v4 = c4 ~= EQUALS_BYTE and B64_DECODE_BYTE[c4] or 0

        local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4

        bytes[#bytes + 1] = math.floor(n / 65536)
        if c3 ~= EQUALS_BYTE then
            bytes[#bytes + 1] = math.floor(n / 256) % 256
        end
        if c4 ~= EQUALS_BYTE then
            bytes[#bytes + 1] = n % 256
        end
    end
end

---Reads an unsigned integer
---@param bits number
---@return number
function BitDecoder:readUInt(bits)
    -- Ensure enough bytes for this read
    local totalBitsNeeded = self._bitOffset + bits
    local bytesNeeded = math.ceil(totalBitsNeeded / 8)
    self:_ensureBytes(bytesNeeded)

    local bytes = self._bytes
    local readPos = self._bitOffset  -- bit position within buffer
    local value = 0
    local outBit = 0

    -- Fast path: byte-aligned reads
    if readPos == 0 then
        local byteIdx = 1
        while bits >= 8 do
            value = BitOr(value, BitLShift(bytes[byteIdx], outBit))
            byteIdx = byteIdx + 1
            outBit = outBit + 8
            bits = bits - 8
        end
        readPos = (byteIdx - 1) * 8
    end

    -- Remaining bits (bit-by-bit)
    while bits > 0 do
        local byteIdx = BitRShift(readPos, 3) + 1
        local bitIdx = BitAnd(readPos, 7)
        local bit = BitAnd(BitRShift(bytes[byteIdx], bitIdx), 1)
        value = BitOr(value, BitLShift(bit, outBit))
        readPos = readPos + 1
        outBit = outBit + 1
        bits = bits - 1
    end

    -- Shift out consumed bytes
    local consumedBytes = BitRShift(readPos, 3)
    if consumedBytes > 0 then
        local newLen = #bytes - consumedBytes
        for i = 1, newLen do
            bytes[i] = bytes[i + consumedBytes]
        end
        for i = newLen + 1, #bytes do
            bytes[i] = nil
        end
    end
    self._bitOffset = BitAnd(readPos, 7)

    return value
end

---Reads a single bit
---@return boolean
function BitDecoder:readBit()
    return self:readUInt(1) == 1
end

---Reads a length-prefixed string (8-bit length + raw bytes)
---@return string
function BitDecoder:readString()
    local len = self:readUInt(8)
    if len == 0 then
        return ""
    end
    local chars = {}
    for i = 1, len do
        chars[i] = string.char(self:readUInt(8))
    end
    return table.concat(chars)
end

-- =============================================================================
-- EXPORTS
-- =============================================================================

bitcodec.BitEncoder = BitEncoder
bitcodec.BitDecoder = BitDecoder

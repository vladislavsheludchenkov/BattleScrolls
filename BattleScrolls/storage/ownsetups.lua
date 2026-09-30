-- Personal build identity is independent of the compact 16-bit sharing hash.
-- Hash and compare encoded snapshots directly, without joining their chunks.
if not SemisPlaygroundCheckAccess() then return end

---@class OwnSetupPoolModule
local ownSetupPool = {}
BattleScrolls.ownSetupPool = ownSetupPool

local KEY_SPACE = 65536
local FNV_OFFSET = 2166136261 % KEY_SPACE
local FNV_PRIME = 16777619 % KEY_SPACE
local byte = string.byte
local bitXor = BitXor

---Low 16 bits of FNV-1a over the four-byte little-endian format version and
---the chunk stream. Reducing the constants modulo 2^16 keeps the arithmetic
---exact and keys nonnegative. Chunk boundaries do not affect identity.
---@param entry OwnSetupPoolEntry
---@return number hash Unsigned 16-bit hash
function ownSetupPool.hash(entry)
    local hash = FNV_OFFSET
    local version = entry.v
    for _ = 1, 4 do
        hash = bitXor(hash, version % 256)
        hash = (hash * FNV_PRIME) % KEY_SPACE
        version = math.floor(version / 256)
    end
    for _, chunk in ipairs(entry.c) do
        for i = 1, #chunk do
            hash = bitXor(hash, byte(chunk, i))
            hash = (hash * FNV_PRIME) % KEY_SPACE
        end
    end
    return hash
end

---@param a OwnSetupPoolEntry
---@param b OwnSetupPoolEntry
---@return boolean
local function samePayload(a, b)
    if a.v ~= b.v then return false end
    -- The normal case compares interned strings, without a byte walk.
    local identical = #a.c == #b.c
    if identical then
        for i = 1, #a.c do
            if a.c[i] ~= b.c[i] then identical = false; break end
        end
    end
    if identical then return true end

    -- Older saves may split the same stream at different chunk boundaries.
    local bIndex, bOffset = 1, 1
    for _, chunk in ipairs(a.c) do
        for i = 1, #chunk do
            while bIndex <= #b.c and bOffset > #b.c[bIndex] do
                bIndex, bOffset = bIndex + 1, 1
            end
            if bIndex > #b.c or byte(chunk, i) ~= byte(b.c[bIndex], bOffset) then return false end
            bOffset = bOffset + 1
        end
    end
    while bIndex <= #b.c and bOffset > #b.c[bIndex] do
        bIndex, bOffset = bIndex + 1, 1
    end
    return bIndex > #b.c
end

---Finds an identical snapshot or inserts the supplied object by reference.
---A true hash collision probes the next key instead of replacing a build.
---@param pool table<number, OwnSetupPoolEntry>
---@param entry OwnSetupPoolEntry
---@return number key Persistent encounter reference (may differ from hash after probing)
---@return boolean added
function ownSetupPool.intern(pool, entry)
    local key = ownSetupPool.hash(entry)
    local firstKey = key
    while pool[key] do
        if samePayload(pool[key], entry) then return key, false end
        key = (key + 1) % KEY_SPACE
        if key == firstKey then error("Personal build pool is full") end
    end
    pool[key] = entry
    return key, true
end

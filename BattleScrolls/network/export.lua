-----------------------------------------------------------
-- Export
-- Builds self-contained binary export streams for online sharing.
--
-- Wire format v8 (bytes, before URL transport):
--   u8  wireVersion (8 adds platform/world; storage v20 blob semantics:
--       24-bit section mask,
--       ULTIMATE/RESURRECTIONS/CRUX/ZEN sections, attacker-name refs inside
--       death recap attacks. Blobs otherwise keep the wire layout:
--       column-oriented damage/effect sections, permille effect times,
--       playerTimeAtMaxStacksMs dropped (see storage/binary.lua's wire
--       writers; web/src/shared/decoder.ts is the only reader))
--   u8  flags: bit0 = body is raw-DEFLATE compressed, bit1 = archive profile
--   body (compressed when bit0 is set):
--     varint createdAtS               (export time)
--     u8 platform                     (device: 1 PC/Mac, 2 Xbox, 3 PlayStation)
--     string worldName                (GetWorldName; not the player's location)
--     string instanceName             (string = varint byte length + bytes)
--     varint instanceTimestampS       (when the run started)
--     u8 instanceFlags: bit0 overland, bit1 house, bit2 PvP,
--        bit3 adventure zone
--     varint abilityCount, varint abilityId ...
--     sparse per-ability classification from the instance's recorded
--       abilityInfo, scoped to this export's own combat recordings (most
--       rows are zero, so only the nonzero ones ship):
--       varint presentCount, then per nonzero row:
--         varint indexDelta (first row = absolute 0-based registry index,
--           then the gap to the previous row's index)
--         u8  deliveryFlags: bit0 direct, bit1 over time, bit2 shield,
--             bit3 regen, bit4 heal absorption
--         u16 damageTypeMask (LE): bit N = DAMAGE_TYPE N was recorded
--     varint nameCount, string name ...
--     varint memberSetupCount, then per pooled member setup the CompactSetup
--       struct (the lossy group-broadcast build summary, deduped across
--       encounters; shared entries reference it by 1-based index):
--         u8 flags: bit0 vengeance, bit1 hasFront, bit2 hasBack,
--                   bit3 hasWerewolf, bit4 hasClassMastery
--         varint raceId, varint classId
--         per present bar: 6x varint abilityId
--         varint setCount, per: varint setId, varint frontCount,
--           varint backCount
--         3x varint armorWeights (light, medium, heavy)
--         4x varint weaponTypes (frontMH, frontOH, backMH, backOH)
--         armorTraits, armorEnchants, jewelryTraits, jewelryEnchants:
--           varint count, per: varint id, varint count
--         4x varint weaponTraits, 4x varint weaponEnchants
--         12x varint champion skillId (positional, 4 per discipline)
--         foods, mundus, classSkillLines: varint count + varint ids
--         when hasClassMastery: varint count + varint abilityIds
--         varint scribedCount, per: varint abilityId, 3x varint scriptId
--         u8 poisonMask: bit0 frontItemId, bit1 backItemId,
--            bit2 frontEffect, bit3 backEffect; then the present varints
--         when vengeance: varint loadoutSkillLineId, 3x varint perkDefId
--     varint encounterCount
--     per encounter:
--       u8 metaFlags: bit0 boss fight, bit1 player fight (duel),
--          bit2 dummy fight
--       string displayName
--       string gameVersion            ("" when unknown)
--       varint timestampS
--       varint durationMs
--       varint playerUnitId           (the unit id the recorder attributed
--         personal rows to; 0 = unknown (pre-v18 recordings))
--       varint bossUnitCount, varint unitId ...            (bossesUnits)
--       varint tagSeqCount, (varint unitId, string key) ...(bossTagSeqByUnitId)
--       varint seqNameCount, (string key, string name) ... (bossSeqNames)
--       varint dataLen, then dataLen bytes of wire-layout _data
--         (re-encoded against the export registry, WITHOUT the setup
--         section - the build ships as the compact struct below)
--       varint sharedCount
--       per entry: u8 entryFlags (bit0 = the uploader's own entry, bit1 =
--           explicit payloadVersion follows),
--         varint nameRef (0-based name-pool index of the member's
--           displayName; interned during the build),
--         varint role,
--         when entryFlags bit1: varint payloadVersion (absent = the
--           storage version this build ships, i.e. binary.lua's
--           CURRENT_VERSION),
--         zigzag timestampS  - encounter timestampS,
--         zigzag durationMs  - encounter durationMs,
--         varint setupRef (0 = none, else 1-based member-setup pool index),
--         varint payloadLen, then payload bytes (binary shared entry;
--         timestamp/duration live OUTSIDE the payload in storage too)
--       u8 hasSetup; when 1, the compact setup struct:
--         u8 flags: bit0 vengeance, bit1 werewolfEntireFight,
--                   bit2 frontBarDisabled, bit3 backBarDisabled
--         varint raceId, varint classId
--         u8 barMask (bit0 front, bit1 back, bit2 werewolf); per present bar
--           6 slots: varint abilityId, u8 crafted; when crafted:
--           varint craftedAbilityId + 3x varint scriptId
--         varint championCount, per: varint skillId, varint disciplineId
--         varint mundusCount, per: varint abilityId
--         varint foodCount, per: varint abilityId, varint uptimeMs+1 (0=none)
--         varint classSkillLineCount, per: varint skillLineId
--         varint masteryCount, per: varint abilityId
--         varint equipCount, per slot: u8 slotIndex(1-14; capture position
--           in combat/setup.lua's EQUIP_SLOTS order, NOT EQUIP_SLOT_* -
--           HAND sits between WAIST and LEGS there), varint itemId,
--           varint traitType+1 (0=unknown; from GetItemLinkTraitType, so
--           retrait truth survives - itemId alone would lie for retraits),
--           varint enchantId, varint quality (GetItemLinkDisplayQuality:
--           6 = mythic override, unlike the functional variant)
--         u8 poisonMask (bit0 front, bit1 back), per: varint itemId
--         when vengeance: 4x varint weaponType, varint loadoutSkillLineId,
--           3x varint vengeancePerkDefId
--
-- The compact equip slots replace the ~70-char itemLinks: name, set, weight
-- and equip slot resolve from the item database by itemId on the viewer side.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class BattleScrollsExport
local export = {}
BattleScrolls.export = export

export.WIRE_VERSION = 8
export.PROFILE_VIEW = 1
export.PROFILE_ARCHIVE = 2

local FLAG_DEFLATE = 1
local FLAG_ARCHIVE = 2

-- Only bother compressing bodies that could plausibly shave a URL chunk
local COMPRESS_MIN_BYTES = 4096

-- =============================================================================
-- BASE64 <-> BYTES (same alphabet as bitcodec)
-- =============================================================================

local B64_ENCODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local B64_VALUE = {} ---@type table<number, number> byte code -> 0-63
for i = 1, 64 do
    B64_VALUE[string.byte(B64_ENCODE, i)] = i - 1
end

local B64_CHAR = {} ---@type table<number, string> 0-63 -> char
for i = 0, 63 do
    B64_CHAR[i] = B64_ENCODE:sub(i + 1, i + 1)
end

---Decodes concatenated base64 chunks (as produced by one BitEncoder) to bytes.
---@param chunks string[] Base64 chunks
---@return string bytes
function export.chunksToBytes(chunks)
    local s = table.concat(chunks):gsub("=", "")
    local n = #s
    local out = {}
    local oi = 0
    local i = 1
    while i + 3 <= n do
        local a = B64_VALUE[string.byte(s, i)]
        local b = B64_VALUE[string.byte(s, i + 1)]
        local c = B64_VALUE[string.byte(s, i + 2)]
        local d = B64_VALUE[string.byte(s, i + 3)]
        local v = ((a * 64 + b) * 64 + c) * 64 + d
        oi = oi + 1
        out[oi] = string.char(math.floor(v / 65536), math.floor(v / 256) % 256, v % 256)
        i = i + 4
    end
    local rem = n - i + 1
    if rem == 2 then
        local a = B64_VALUE[string.byte(s, i)]
        local b = B64_VALUE[string.byte(s, i + 1)]
        oi = oi + 1
        out[oi] = string.char(math.floor((a * 64 + b) / 16))
    elseif rem == 3 then
        local a = B64_VALUE[string.byte(s, i)]
        local b = B64_VALUE[string.byte(s, i + 1)]
        local c = B64_VALUE[string.byte(s, i + 2)]
        local v = (a * 64 + b) * 64 + c
        oi = oi + 1
        out[oi] = string.char(math.floor(v / 1024), math.floor(v / 4) % 256)
    end
    return table.concat(out)
end

---Encodes a byte string as standard padded base64 (BitDecoder requires
---complete 4-char groups, so the padding is not optional).
---@param bytes string
---@return string base64
function export.bytesToBase64(bytes)
    local n = #bytes
    local out = {}
    local oi = 0
    local i = 1
    while i + 2 <= n do
        local a, b, c = string.byte(bytes, i, i + 2)
        local v = (a * 256 + b) * 256 + c
        oi = oi + 1
        out[oi] = B64_CHAR[math.floor(v / 262144)]
            .. B64_CHAR[math.floor(v / 4096) % 64]
            .. B64_CHAR[math.floor(v / 64) % 64]
            .. B64_CHAR[v % 64]
        i = i + 3
    end
    local rem = n - i + 1
    if rem == 1 then
        local a = string.byte(bytes, i)
        oi = oi + 1
        out[oi] = B64_CHAR[math.floor(a / 4)] .. B64_CHAR[(a % 4) * 16] .. "=="
    elseif rem == 2 then
        local a, b = string.byte(bytes, i, i + 1)
        local v = a * 256 + b
        oi = oi + 1
        out[oi] = B64_CHAR[math.floor(v / 1024)]
            .. B64_CHAR[math.floor(v / 16) % 64]
            .. B64_CHAR[(v % 16) * 4] .. "="
    end
    return table.concat(out)
end

-- =============================================================================
-- BYTE WRITER (wire-level framing; encounter payloads come from bitcodec)
-- =============================================================================

---@class ExportByteWriter
---@field _parts string[]
---@field _count number
local ByteWriter = {}
ByteWriter.__index = ByteWriter

---@return ExportByteWriter
function ByteWriter.new()
    return setmetatable({ _parts = {}, _count = 0 }, ByteWriter)
end

---@param byte number 0-255
function ByteWriter:writeByte(byte)
    self._count = self._count + 1
    self._parts[self._count] = string.char(byte)
end

---LEB128, identical to BitEncoder:writeVarUInt
---@param value number
function ByteWriter:writeVarUInt(value)
    value = math.floor(value or 0)
    if value < 0 then
        value = 0
    end
    while value >= 128 do
        self:writeByte(128 + value % 128)
        value = math.floor(value / 128)
    end
    self:writeByte(value)
end

---Zigzag varint for signed wire-level deltas
---@param value number
function ByteWriter:writeZigZag(value)
    if value >= 0 then
        self:writeVarUInt(value * 2)
    else
        self:writeVarUInt(-value * 2 - 1)
    end
end

---@param bytes string
function ByteWriter:writeBytes(bytes)
    self._count = self._count + 1
    self._parts[self._count] = bytes
end

---Varint byte length + raw bytes (wire-level strings; NOT bitcodec's u8-prefixed form)
---@param str string|nil
function ByteWriter:writeString(str)
    str = str or ""
    self:writeVarUInt(#str)
    self:writeBytes(str)
end

---@return string
function ByteWriter:finish()
    return table.concat(self._parts)
end

-- =============================================================================
-- COMPACT SETUP (wire form of PlayerSetup; replaces the bit-packed blob)
-- =============================================================================

---@class ExportEquipSlot
---@field slotIndex number 1-14
---@field itemId number
---@field traitType number GetItemLinkTraitType result (retrait-aware); -1 unknown
---@field enchantId number
---@field quality number

---@class ExportSetup
---@field setup PlayerSetup The decoded setup (bars, champion, mundus, ...)
---@field equipSlots ExportEquipSlot[]
---@field frontPoisonItemId number 0 when none
---@field backPoisonItemId number 0 when none

---@param link string
---@return number itemId
local function linkItemId(link)
    return tonumber(link:match("|H%d:item:(%d+)")) or 0
end

---Precomputes per-slot facts the viewer cannot derive from the itemId alone.
---Runs in-game where the item link APIs are available.
---@param setup PlayerSetup
---@return ExportSetup
local function buildExportSetup(setup)
    local equipSlots = {}
    for i = 1, 14 do
        local link = setup.equipSlots and setup.equipSlots[i]
        if link and link ~= "" then
            equipSlots[#equipSlots + 1] = {
                slotIndex = i,
                itemId = linkItemId(link),
                traitType = GetItemLinkTraitType(link),
                enchantId = GetItemLinkFinalEnchantId(link),
                -- Display quality: functional quality caps at Legendary,
                -- only the display variant reports the Mythic override
                quality = GetItemLinkDisplayQuality(link),
            }
        end
    end
    return {
        setup = setup,
        equipSlots = equipSlots,
        frontPoisonItemId = setup.frontPoison and linkItemId(setup.frontPoison.itemLink) or 0,
        backPoisonItemId = setup.backPoison and linkItemId(setup.backPoison.itemLink) or 0,
    }
end

---@param body ExportByteWriter
---@param bar PlayerSetupAbility[]
local function writeExportBar(body, bar)
    for i = 1, 6 do
        local ability = bar[i] or {}
        body:writeVarUInt(ability.abilityId or 0)
        if ability.craftedAbilityId then
            body:writeByte(1)
            body:writeVarUInt(ability.craftedAbilityId)
            local scripts = ability.scriptIds or {}
            body:writeVarUInt(scripts[1] or 0)
            body:writeVarUInt(scripts[2] or 0)
            body:writeVarUInt(scripts[3] or 0)
        else
            body:writeByte(0)
        end
    end
end

---@param body ExportByteWriter
---@param exportSetup ExportSetup|nil
local function writeExportSetup(body, exportSetup)
    if not exportSetup then
        body:writeByte(0)
        return
    end
    body:writeByte(1)
    local setup = exportSetup.setup
    body:writeByte((setup.isVengeance and 1 or 0)
        + (setup.werewolfEntireFight and 2 or 0)
        + (setup.frontBarDisabled and 4 or 0)
        + (setup.backBarDisabled and 8 or 0))
    body:writeVarUInt(setup.raceId or 0)
    body:writeVarUInt(setup.classId or 0)

    local front = setup.abilities and setup.abilities.front
    local back = setup.abilities and setup.abilities.back
    local werewolf = setup.werewolfAbilities
    body:writeByte((front and 1 or 0) + (back and 2 or 0) + (werewolf and 4 or 0))
    if front then writeExportBar(body, front) end
    if back then writeExportBar(body, back) end
    if werewolf then writeExportBar(body, werewolf) end

    local champion = setup.champion or {}
    body:writeVarUInt(#champion)
    for _, skill in ipairs(champion) do
        body:writeVarUInt(skill.skillId)
        body:writeVarUInt(skill.disciplineId)
    end

    local mundus = setup.mundusAbilityIds or {}
    body:writeVarUInt(#mundus)
    for _, id in ipairs(mundus) do
        body:writeVarUInt(id)
    end

    local foods = setup.foods or {}
    body:writeVarUInt(#foods)
    for _, food in ipairs(foods) do
        body:writeVarUInt(food.abilityId)
        body:writeVarUInt((food.uptimeMs or -1) + 1)
    end

    local skillLines = setup.classSkillLineIds or {}
    body:writeVarUInt(#skillLines)
    for _, id in ipairs(skillLines) do
        body:writeVarUInt(id)
    end

    local mastery = setup.classMasteryAbilityIds or {}
    body:writeVarUInt(#mastery)
    for _, id in ipairs(mastery) do
        body:writeVarUInt(id)
    end

    body:writeVarUInt(#exportSetup.equipSlots)
    for _, slot in ipairs(exportSetup.equipSlots) do
        body:writeByte(slot.slotIndex)
        body:writeVarUInt(slot.itemId)
        body:writeVarUInt((slot.traitType or -1) + 1)
        body:writeVarUInt(slot.enchantId or 0)
        body:writeVarUInt(slot.quality or 0)
    end

    body:writeByte((exportSetup.frontPoisonItemId > 0 and 1 or 0)
        + (exportSetup.backPoisonItemId > 0 and 2 or 0))
    if exportSetup.frontPoisonItemId > 0 then
        body:writeVarUInt(exportSetup.frontPoisonItemId)
    end
    if exportSetup.backPoisonItemId > 0 then
        body:writeVarUInt(exportSetup.backPoisonItemId)
    end

    if setup.isVengeance then
        local weaponTypes = setup.weaponTypes or {}
        for i = 1, 4 do
            body:writeVarUInt(weaponTypes[i] or 0)
        end
        body:writeVarUInt(setup.loadoutSkillLineId or 0)
        local perks = setup.vengeancePerkDefIds or {}
        for i = 1, 3 do
            body:writeVarUInt(perks[i] or 0)
        end
    end
end

-- =============================================================================
-- STREAM BUILDER
-- =============================================================================

---@class ExportEncounterEntry
---@field displayName string
---@field gameVersion string Patch string at recording time; "" when unknown
---@field timestampS number
---@field durationMs number
---@field playerUnitId number Unit id the recorder attributed personal rows to; 0 = unknown (pre-v18 recording)
---@field isBoss boolean
---@field isPlayerFight boolean
---@field isDummyFight boolean
---@field bossesUnits number[]
---@field bossTagSeqByUnitId table<number, string>
---@field bossSeqNames table<string, string>
---@field dataBytes string
---@field shared ExportSharedEntry[]
---@field exportSetup ExportSetup|nil

---@class ExportSharedEntry
---@field isSelf boolean True when this is the uploader's own entry
---@field displayName string
---@field nameRef number 1-based name-pool index of displayName (interned at collect time, before the frame writes the pool)
---@field role number
---@field payloadVersion number
---@field timestampS number
---@field durationMs number
---@field setupHash number 16-bit build hash from the broadcast; 0 = none
---@field setupRef number 1-based member-setup pool index; 0 = none
---@field payloadBytes string

---@class ExportResult
---@field bytes string Final stream (header + body, body possibly compressed)
---@field profile number export.PROFILE_VIEW or export.PROFILE_ARCHIVE
---@field encounterCount number Encounters included
---@field skipped number Encounters that failed to decode (archive only)

---Extracts binary shared entries for one encounter. Reuses the stored binary
---payloads when present (v17+); legacy plain sharedData is encoded fresh.
---Display names are interned into the export registry's name pool here -
---during the encounter loop, before the frame writes the pool - so the
---frame can reference them instead of shipping inline strings.
---@param encounter CompactEncounter
---@param decoded Encounter
---@param registry EncounterRegistry
---@return ExportSharedEntry[]
local function collectSharedEntries(encounter, decoded, registry)
    local binaryStorage = BattleScrolls.binaryStorage
    -- The uploader's own broadcast entry is marked explicitly: the viewer
    -- must not have to guess which member the personal data belongs to
    local ownName = BattleScrolls.utils.GetUndecoratedDisplayName("player")
    local entries = {}
    local compactEntries = encounter._shared
    if not compactEntries and decoded.sharedData then
        compactEntries = {}
        for i, entry in ipairs(decoded.sharedData) do
            compactEntries[i] = binaryStorage.encodeSharedEntry(entry)
        end
    end
    for i, compact in ipairs(compactEntries or {}) do
        entries[i] = {
            displayName = compact.d or "",
            nameRef = binaryStorage.internName(registry, compact.d or ""),
            isSelf = compact.d == ownName,
            role = compact.r or 0,
            payloadVersion = compact.v or 17,
            timestampS = compact.t or 0,
            durationMs = compact.u or 0,
            setupHash = compact.h or 0,
            payloadBytes = export.chunksToBytes(compact.c),
        }
    end
    return entries
end

---Wire facts for one ability, from the delivery flags and damage-type set the
---combat recorder stored per instance: a delivery-flags byte plus a 16-bit
---mask of every damage type recorded (lossless - multi-type abilities keep
---their full type list instead of collapsing to "unknown").
---@param info AbilityInfo|nil
---@return number delivery Delivery-flags byte
---@return number maskLo Damage-type mask low byte
---@return number maskHi Damage-type mask high byte
local function factsBytes(info)
    local delivery = info and info.deliveryType or {}
    local deliveryByte = (delivery.direct and 1 or 0)
        + (delivery.overTime and 2 or 0)
        + (delivery.shield and 4 or 0)
        + (delivery.regen and 8 or 0)
        + (delivery.healAbsorption and 16 or 0)
    local mask = 0
    for dt in pairs(info and info.damageTypes or {}) do
        if dt >= 0 and dt <= 15 then
            mask = BitOr(mask, BitLShift(1, dt))
        end
    end
    return deliveryByte, mask % 256, math.floor(mask / 256)
end

---Decodes and re-encodes the given stored encounters against a fresh export
---registry, then frames everything into one wire body.
---@param instance InstanceStorage
---@param encounters CompactEncounter[]
---@param profile number
---@return Effect Effect resolving to ExportResult
local function buildStreamAsync(instance, encounters, profile)
    return LibEffect.Async(function()
        local binaryStorage = BattleScrolls.binaryStorage
        local registry = binaryStorage.newRegistry()

        -- The instance's recorded abilityInfo (delivery flags + damage types
        -- seen in combat) classifies every export registry id - it has been
        -- part of every recording, so old encounters are covered too
        ---@type table<number, AbilityInfo>
        local abilityInfo
        if instance.abilityInfo then
            abilityInfo = instance.abilityInfo
        elseif instance._instanceData then
            abilityInfo = BattleScrolls.storage.DecodeInstanceFieldsAsync(instance):Await()[1]
        else
            abilityInfo = {}
        end
        ---@type ExportEncounterEntry[]
        local entries = {}
        local skipped = 0
        -- Member builds pool: unique CompactSetups referenced by shared
        -- entries, deduped by (member, hash) so a build repeated across the
        -- instance's encounters ships once
        ---@type CompactSetup[]
        local memberSetups = {}
        ---@type table<string, number>
        local memberSetupIndex = {}

        for _, encounter in ipairs(encounters) do
            ---@type Encounter|nil
            local decoded = BattleScrolls.storage.DecodeEncounterAsync(encounter, instance)
                :Recover(function() return nil end):Await()
            if decoded then
                -- The build travels as the compact wire struct, not the
                -- bit-packed blob: strip it before encoding the encounter
                local exportSetup = decoded.setup and buildExportSetup(decoded.setup) or nil
                decoded.setup = nil
                local compact = binaryStorage.encodeEncounterWireAsync(
                    decoded, registry, encounter.durationMs or 0):Await()
                local shared = collectSharedEntries(encounter, decoded, registry)
                for _, entry in ipairs(shared) do
                    entry.setupRef = 0
                    if not entry.isSelf and entry.setupHash > 0 then
                        local key = entry.displayName .. ":" .. entry.setupHash
                        local ref = memberSetupIndex[key]
                        if ref == nil then
                            local memberSetup = BattleScrolls.setupShare:getSetup(
                                entry.displayName, entry.setupHash)
                            if memberSetup then
                                memberSetups[#memberSetups + 1] = memberSetup
                                ref = #memberSetups
                            else
                                ref = 0
                            end
                            memberSetupIndex[key] = ref
                        end
                        entry.setupRef = ref
                    end
                end
                entries[#entries + 1] = {
                    -- A local rename travels as "custom (real)" so the share
                    -- keeps both the user's label and the recognizable name
                    displayName = encounter.customName
                        and string.format("%s (%s)", encounter.customName, encounter.displayName or "")
                        or (encounter.displayName or ""),
                    gameVersion = encounter.gameVersion or "",
                    timestampS = encounter.timestampS or 0,
                    durationMs = encounter.durationMs or 0,
                    playerUnitId = encounter.playerUnitId or 0,
                    isBoss = next(encounter.bossesUnits or {}) ~= nil,
                    isPlayerFight = encounter.isPlayerFight == true,
                    isDummyFight = encounter.isDummyFight == true,
                    bossesUnits = encounter.bossesUnits or {},
                    bossTagSeqByUnitId = encounter.bossTagSeqByUnitId or {},
                    bossSeqNames = encounter.bossSeqNames or {},
                    dataBytes = export.chunksToBytes(compact._data),
                    shared = shared,
                    exportSetup = exportSetup,
                }
            else
                skipped = skipped + 1
            end
            -- Keep only the encoded export entry while reclaiming the
            -- decoded encounter before the next allocation burst.
            decoded = nil
            BattleScrolls.gc:CollectFullAsync():Await()
        end

        if #entries == 0 then
            error("export: no encounter could be decoded")
        end

        local body = ByteWriter.new()
        body:writeVarUInt(GetTimeStamp())
        -- Device platform is independent of the account service and world:
        -- Xbox Play Anywhere runs on PC while using Xbox accounts/servers.
        -- GetUIPlatform is the client platform, not the preferred input mode.
        local uiPlatform = GetUIPlatform()
        local platform = uiPlatform == UI_PLATFORM_XBOX and 2
            or (uiPlatform == UI_PLATFORM_PS4 or uiPlatform == UI_PLATFORM_PS5) and 3 or 1
        body:writeByte(platform)
        body:writeString(GetWorldName())
        -- The journal titles instances by zone; instanceName on the wire is
        -- the same string ("Earthen Root Enclave", "Sunspire", ...). A local
        -- rename travels as "custom (real)".
        body:writeString(instance.customName
            and string.format("%s (%s)", instance.customName, instance.zone or "")
            or (instance.zone or ""))
        body:writeVarUInt(instance.timestampS or 0)
        body:writeByte((instance.isOverland and 1 or 0)
            + (instance.isHouse and 2 or 0)
            + (instance.isPvP and 4 or 0)
            + (instance.isAdventureZone and 8 or 0))
        body:writeVarUInt(#registry.abilityIds)
        for i = 1, #registry.abilityIds do
            body:writeVarUInt(registry.abilityIds[i])
        end
        -- Per-ability classification, scoped to this export: the recorder
        -- saw every registry id's combat events in this very instance, so
        -- coverage is exact - and a bad actor can only mislabel their own
        -- share. Sparse: most registry ids carry no classification, so only
        -- nonzero rows ship, delta-indexed
        ---@type {index: number, delivery: number, maskLo: number, maskHi: number}[]
        local factRows = {}
        for i = 1, #registry.abilityIds do
            local delivery, maskLo, maskHi = factsBytes(abilityInfo[registry.abilityIds[i]])
            if delivery ~= 0 or maskLo ~= 0 or maskHi ~= 0 then
                factRows[#factRows + 1] =
                    { index = i - 1, delivery = delivery, maskLo = maskLo, maskHi = maskHi }
            end
        end
        body:writeVarUInt(#factRows)
        local prevFactIndex = 0
        for _, row in ipairs(factRows) do
            body:writeVarUInt(row.index - prevFactIndex)
            prevFactIndex = row.index
            body:writeByte(row.delivery)
            body:writeByte(row.maskLo)
            body:writeByte(row.maskHi)
        end
        body:writeVarUInt(#registry.names)
        for i = 1, #registry.names do
            body:writeString(registry.names[i])
        end
        body:writeVarUInt(#memberSetups)
        for _, memberSetup in ipairs(memberSetups) do
            BattleScrolls.binaryStorage.writeSharedSetup(body, memberSetup)
        end
        body:writeVarUInt(#entries)
        for _, entry in ipairs(entries) do
            body:writeByte((entry.isBoss and 1 or 0)
                + (entry.isPlayerFight and 2 or 0)
                + (entry.isDummyFight and 4 or 0))
            body:writeString(entry.displayName)
            body:writeString(entry.gameVersion)
            body:writeVarUInt(entry.timestampS)
            body:writeVarUInt(entry.durationMs)
            body:writeVarUInt(entry.playerUnitId)
            body:writeVarUInt(#entry.bossesUnits)
            for _, unitId in ipairs(entry.bossesUnits) do
                body:writeVarUInt(unitId)
            end
            local tagSeqCount = 0
            for _ in pairs(entry.bossTagSeqByUnitId) do
                tagSeqCount = tagSeqCount + 1
            end
            body:writeVarUInt(tagSeqCount)
            for unitId, key in pairs(entry.bossTagSeqByUnitId) do
                body:writeVarUInt(unitId)
                body:writeString(key)
            end
            local seqNameCount = 0
            for _ in pairs(entry.bossSeqNames) do
                seqNameCount = seqNameCount + 1
            end
            body:writeVarUInt(seqNameCount)
            for key, name in pairs(entry.bossSeqNames) do
                body:writeString(key)
                body:writeString(name)
            end
            body:writeVarUInt(#entry.dataBytes)
            body:writeBytes(entry.dataBytes)
            body:writeVarUInt(#entry.shared)
            for _, shared in ipairs(entry.shared) do
                -- payloadVersion ships only when it differs from the build's
                -- storage version (it never does today - every stored entry
                -- is re-encoded at CURRENT_VERSION - but the escape hatch
                -- keeps old web decoders honest against future bumps)
                local explicitVersion =
                    shared.payloadVersion ~= binaryStorage.CURRENT_VERSION
                body:writeByte((shared.isSelf and 1 or 0)
                    + (explicitVersion and 2 or 0))
                body:writeVarUInt(shared.nameRef - 1)
                body:writeVarUInt(shared.role)
                if explicitVersion then
                    body:writeVarUInt(shared.payloadVersion)
                end
                body:writeZigZag(shared.timestampS - entry.timestampS)
                body:writeZigZag(shared.durationMs - entry.durationMs)
                body:writeVarUInt(shared.setupRef)
                body:writeVarUInt(#shared.payloadBytes)
                body:writeBytes(shared.payloadBytes)
            end
            writeExportSetup(body, entry.exportSetup)
        end

        local bodyBytes = body:finish()
        local flags = profile == export.PROFILE_ARCHIVE and FLAG_ARCHIVE or 0

        -- Optional compression: only when the module is present and it wins.
        -- Level 6: on a measured real archive it beats the LibDeflate default
        -- (level 1) by 4.2% and drops a whole URL part; the compressor yields
        -- across frames, so the extra CPU spreads out instead of hitching.
        local deflate = BattleScrolls.deflate
        if deflate and #bodyBytes >= COMPRESS_MIN_BYTES then
            local compressed = deflate.compressAsync(bodyBytes, 6):Await()
            if compressed and #compressed < #bodyBytes then
                bodyBytes = compressed
                flags = flags + FLAG_DEFLATE
            end
        end

        return {
            bytes = string.char(export.WIRE_VERSION, flags) .. bodyBytes,
            profile = profile,
            encounterCount = #entries,
            skipped = skipped,
        }
    end)
end

---Builds a single-encounter share (view profile; same per-encounter fidelity
---as the archive).
---@param instance InstanceStorage
---@param encounter CompactEncounter
---@return Effect Effect resolving to ExportResult
function export.buildEncounterShareAsync(instance, encounter)
    return buildStreamAsync(instance, { encounter }, export.PROFILE_VIEW)
end

---Builds a whole-instance archive (full fidelity). bossesOnly keeps just the
---encounters with boss units - trash pulls dominate archive size (group
---effect tables scale with members x effects, not fight length), so this
---variant typically needs far fewer URL parts.
---@param instance InstanceStorage
---@param bossesOnly boolean|nil
---@return Effect Effect resolving to ExportResult
function export.buildInstanceArchiveAsync(instance, bossesOnly)
    local encounters = instance.encounters
    if bossesOnly then
        encounters = {}
        for _, encounter in ipairs(instance.encounters) do
            if next(encounter.bossesUnits or {}) ~= nil then
                encounters[#encounters + 1] = encounter
            end
        end
    end
    return buildStreamAsync(instance, encounters, export.PROFILE_ARCHIVE)
end

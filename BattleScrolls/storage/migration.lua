-----------------------------------------------------------
-- Migration
-- One-time automatic upgrade of stored combat history to the
-- current binary format (varint rows, section mask, per-instance
-- registries, pooled own setups, binary shared data and shared setups).
--
-- Runs on its own shortly after login when legacy encounters or shared
-- setups exist. Per-instance transaction: every encounter is decoded,
-- re-encoded and decoded again, and the result is deep-verified
-- against the original BEFORE anything is committed. If any
-- encounter of an instance fails verification the whole
-- instance is left untouched in its old format (which stays
-- readable forever) and marked so it is not retried every
-- session. Interruption-safe: committed instances are detected
-- as migrated on the next load and skipped.
--
-- Memory pacing: one encounter is the unit of work; a full
-- confirmed GC collection runs between units (see
-- core/gc.lua CollectFullAsync). Migration pauses while the
-- player is in combat.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class MigrationModule
local migration = {}
BattleScrolls.migration = migration

local EVENT_NAMESPACE = "BattleScrolls_Migration"

---Delay after login before migration starts (let the world settle)
local START_DELAY_MS = 60000

---Poll interval while waiting out combat
local COMBAT_POLL_MS = 5000

---Tolerance for the 12-bit quantized percents of shared entries
local PERCENT_TOLERANCE = 1 / 4095

-- =============================================================================
-- VERIFICATION
-- =============================================================================

---Havok hstructures report type "struct" but iterate like tables.
---@param v any
---@return boolean
local function isTableLike(v)
    local t = type(v)
    return t == "table" or t == "struct"
end

---Deep-compares decoded encounter data. Numbers may differ by tolerance
---(used for the quantized percents of shared entries; 0 for encounter data).
---@param a any
---@param b any
---@param path string
---@param tolerance number
---@return boolean equal
---@return string|nil firstMismatch
local function deepEq(a, b, path, tolerance)
    if type(a) ~= type(b) then
        -- Absent v17 sections decode to canonical empty defaults
        if a == nil and type(b) == "table" and next(b) == nil then
            return true
        end
        if b == nil and type(a) == "table" and next(a) == nil then
            return true
        end
        return false, path .. " type " .. type(a) .. " vs " .. type(b)
    end
    if type(a) == "number" then
        if math.abs(a - b) > tolerance then
            return false, string.format("%s: %s vs %s", path, tostring(a), tostring(b))
        end
        return true
    end
    if not isTableLike(a) then
        if a ~= b then
            return false, string.format("%s: %s vs %s", path, tostring(a), tostring(b))
        end
        return true
    end
    for k, v in pairs(a) do
        local ok, err = deepEq(v, b[k], path .. "." .. tostring(k), tolerance)
        if not ok then
            return false, err
        end
    end
    for k, bv in pairs(b) do
        -- Mirror of the nil-vs-empty allowance above: decoders materialize
        -- canonical empty containers for fields older data never had
        if a[k] == nil and not (isTableLike(bv) and next(bv) == nil) then
            return false, path .. "." .. tostring(k) .. " unexpected in re-decode"
        end
    end
    return true
end

---Fields verified for the encounter round trip (setup included: migration
---commits the pool, so pooled setups resolve during verification).
local COMPARED_FIELDS = {
    "damageByUnitId", "damageByUnitIdGroup", "damageTakenByUnitId",
    "healingStats", "procs", "effectsOnPlayer", "effectsOnBosses",
    "effectsOnGroup", "bossNames", "playerAliveTimeMs", "unitAliveTimeMs",
    "unitNames", "deaths", "weaving", "setup", "ultimate", "crux",
    "resurrections", "resurrectionLog", "zen",
}

-- =============================================================================
-- MIGRATION
-- =============================================================================

---@param chunks string[]|nil
---@return number chars
local function chunkChars(chunks)
    local total = 0
    for _, chunk in ipairs(chunks or {}) do
        total = total + #chunk
    end
    return total
end

---@param encounter CompactEncounter
---@return boolean
local function encounterIsLegacy(encounter)
    return (encounter._v or 0) < BattleScrolls.binaryStorage.CURRENT_VERSION
        or encounter.sharedData ~= nil
end

---@param setup StoredSharedSetup
---@return boolean
local function sharedSetupIsLegacy(setup)
    return rawget(setup, "c") == nil and not rawget(setup, "_migrationFailed")
end

---@return boolean
local function hasLegacySharedSetups()
    for _, byHash in pairs(BattleScrolls.storage.savedVariables.sharedSetups or {}) do
        for _, setup in pairs(byHash) do
            if sharedSetupIsLegacy(setup) then return true end
        end
    end
    return false
end

---Conservative check backing the persistent savedVariables.migrationDoneV20Setups
---flag: no encounter anywhere may be legacy, INCLUDING the live instance
---(which the migration run itself skips - it must stay reachable in a later
---session). Shared setups must also be encoded. Failed instances and setups
---are excluded: they stay readable in their original format. An empty save
---passes too.
---@return boolean
local function everythingMigrated()
    if hasLegacySharedSetups() then return false end
    for _, instance in ipairs(BattleScrolls.storage.savedVariables.history) do
        if not instance._migrationFailed then
            for _, encounter in ipairs(instance.encounters) do
                if encounterIsLegacy(encounter) then
                    return false
                end
            end
        end
    end
    return true
end

---True when the instance still holds encounters in a pre-v20 format
---@param instance InstanceStorage
---@return boolean
function migration.hasLegacyEncounters(instance)
    for _, encounter in ipairs(instance.encounters) do
        if encounterIsLegacy(encounter) then
            return true
        end
    end
    return false
end

---@param instance InstanceWithIndex
---@return boolean
local function instanceNeedsMigration(instance)
    if instance._migrationFailed then
        return false
    end
    -- The live instance is owned by scribe (registry, appends); it migrates
    -- in a later session once left
    if instance == BattleScrolls.scribe.instance then
        return false
    end
    return migration.hasLegacyEncounters(instance)
end

---@generic T
---@param arr T[]
---@return T[]
local function copyArray(arr)
    local copy = {}
    for i, v in ipairs(arr) do
        copy[i] = v
    end
    return copy
end

---Blocks (async) while the player is in combat.
local function waitOutCombat()
    while BattleScrolls.state.inCombat do
        LibEffect.Sleep(COMBAT_POLL_MS):Await()
    end
end

---@class MigrationTotals
---@field migrated number Encounters successfully re-encoded
---@field poolGrowth number Estimated memory of setup-pool entries created while migrating
---@field migratedSetups number Shared setups successfully encoded
---@field sharedFreed number Estimated memory freed by encoding shared setups

---The export layout pads fixed-width numeric arrays with zeros and treats
---false/nil Vengeance flags identically. Normalize only those differences
---and discard storage bookkeeping before comparing every build field.
---@param setup CompactSetup
---@return CompactSetup
local function comparableSharedSetup(setup)
    local result = {}
    for k, v in pairs(setup) do result[k] = v end
    result._estimatedSize, result._estimatedSizeV, result._migrationFailed = nil, nil, nil
    result.isVengeance = setup.isVengeance or nil
    local widths = {
        armorWeights = 3, weaponTypes = 4, weaponTraits = 4, weaponEnchants = 4, champion = 12,
    }
    if setup.frontAbilities then widths.frontAbilities = 6 end
    if setup.backAbilities then widths.backAbilities = 6 end
    if setup.werewolfAbilities then widths.werewolfAbilities = 6 end
    if setup.isVengeance then widths.vengeancePerkDefIds = 3 end
    for field, width in pairs(widths) do
        local values = {}
        for k, v in pairs(setup[field] or {}) do values[k] = v end
        for i = 1, width do values[i] = values[i] or 0 end
        result[field] = values
    end
    return result
end

---@param setup CompactSetup
---@return EncodedSharedSetup|nil
---@return string|nil
local function encodeVerifiedSharedSetup(setup)
    local encoded = BattleScrolls.binaryStorage.encodeSharedSetup(setup)
    local decoded = BattleScrolls.binaryStorage.decodeSharedSetup(encoded)
    local equal, mismatch = deepEq(comparableSharedSetup(setup), decoded, "sharedSetup", 0)
    if not equal then return nil, mismatch end
    return encoded
end

---Each setup commits synchronously under the write mutex. Re-read it after
---waiting: pruning or a fresh broadcast may have replaced it in the meantime.
---No decoded builds are retained after verification.
---@param totals MigrationTotals
local function migrateSharedSetupsAsync(totals)
    local storage = BattleScrolls.storage
    for displayName, byHash in pairs(storage.savedVariables.sharedSetups or {}) do
        local attempted = false
        for hash, stored in pairs(byHash) do
            if sharedSetupIsLegacy(stored) then
                attempted = true
                waitOutCombat()
                storage.writeMutex:WithPermit(LibEffect.Async(function()
                    local pool = storage.savedVariables.sharedSetups
                    local current = pool and pool[displayName]
                    local setup = current and current[hash]
                    if not setup or not sharedSetupIsLegacy(setup) then return end
                    ---@cast setup CompactSetup
                    local ok, encoded, mismatch = pcall(encodeVerifiedSharedSetup, setup)
                    if not ok or not encoded then
                        setup._migrationFailed = true
                        BattleScrolls.log.Warn(string.format(
                            "Migration: shared setup %s/%d failed verification (%s), leaving it plain",
                            displayName, hash, tostring(ok and mismatch or encoded)))
                        return
                    end
                    totals.sharedFreed = totals.sharedFreed + storage:EstimateValueMemory(setup)
                        - storage:EstimateValueMemory(encoded)
                    current[hash] = encoded
                    totals.migratedSetups = totals.migratedSetups + 1
                end)):Await()
                LibEffect.YieldWithGC():Await()
            end
        end
        if attempted then BattleScrolls.gc:CollectFullAsync():Await() end
    end
end

---Re-encodes one legacy encounter and verifies the result.
---@param encounter CompactEncounter
---@param instance InstanceWithIndex
---@param staged EncounterRegistry
---@return CompactEncounter|nil reencoded Nil when decode/verify failed
---@return string|nil failReason
---@return number|nil poolGrowthBytes Estimated memory of a pool entry newly created for this setup
local function migrateEncounter(encounter, instance, staged)
    local binaryStorage = BattleScrolls.binaryStorage

    ---@type Encounter|nil
    local decoded = BattleScrolls.storage.DecodeEncounterAsync(encounter, instance)
        :Recover(function() return nil end):Await()
    if not decoded then
        return nil, "decode failed"
    end

    -- Setup: normalize historical volatility, then pool the build
    local setupHash = nil
    local poolGrowthBytes = 0
    if decoded.setup then
        BattleScrolls.setupCapture.normalizeSetup(decoded.setup)
        local added
        setupHash, added = BattleScrolls.storage:InternOwnSetup(decoded.setup)
        if added then
            -- Charge new pool entries against the freed total
            poolGrowthBytes = BattleScrolls.storage:EstimateValueMemory(
                BattleScrolls.storage.savedVariables.ownSetups[setupHash])
        end
    end

    ---@type CompactEncounter|nil
    local reencoded = binaryStorage.encodeEncounterAsync(decoded, setupHash ~= nil, staged)
        :Recover(function() return nil end):Await()
    if not reencoded then
        return nil, "re-encode failed", poolGrowthBytes
    end
    -- A correct v17 re-encode never inflates the stream (denser format,
    -- canonical encoder). Growth means the legacy decode fabricated data
    -- from a misparsed stream - garbage that would pass the round-trip
    -- verification below faithfully
    local oldChars = chunkChars(encounter._data)
    local newChars = chunkChars(reencoded._data)
    if newChars > oldChars + 512 then
        return nil, string.format("re-encode grew %d -> %d chars", oldChars, newChars), poolGrowthBytes
    end
    reencoded._setupHash = setupHash
    -- Compact-only metadata the decode does not carry
    reencoded.gameVersion = encounter.gameVersion

    -- Shared entries: plain -> binary sibling
    reencoded.sharedData = nil
    local oldShared = decoded.sharedData
    if oldShared then
        local compactShared = {}
        for i, entry in ipairs(oldShared) do
            compactShared[i] = binaryStorage.encodeSharedEntry(entry)
        end
        reencoded._shared = compactShared
    end

    -- Verify the full round trip before this encounter may be committed
    ---@type Encounter|nil
    local redecoded = binaryStorage.decodeEncounterAsync(reencoded, staged)
        :Recover(function() return nil end):Await()
    if not redecoded then
        return nil, "verify decode failed", poolGrowthBytes
    end
    for _, field in ipairs(COMPARED_FIELDS) do
        local ok, err = deepEq(decoded[field], redecoded[field], field, 0)
        if not ok then
            return nil, err, poolGrowthBytes
        end
    end
    if oldShared then
        local ok, err = deepEq(oldShared, redecoded.sharedData, "sharedData", PERCENT_TOLERANCE)
        if not ok then
            return nil, err, poolGrowthBytes
        end
    end

    return reencoded, nil, poolGrowthBytes
end

---Migrates one instance transactionally. Commits only when every encounter
---verified; otherwise the instance is left untouched. Runs under the storage
---write mutex: the setups interned along the way are referenced only once
---the instance commits, and a prune in between would drop them.
---@param instance InstanceWithIndex
---@param totals MigrationTotals
---@return boolean committed
local function migrateInstance(instance, totals)
    local binaryStorage = BattleScrolls.binaryStorage

    -- Stage a registry seeded from the instance's existing one (mixed
    -- instances may already hold v17 encounters whose indices must survive)
    local existing = BattleScrolls.storage:GetInstanceRegistryAsync(instance):Await()
    local staged = binaryStorage.newRegistry(copyArray(existing.abilityIds), copyArray(existing.names))

    ---@type table<number, AbilityInfo>
    local abilityInfo
    if instance.abilityInfo then
        abilityInfo = instance.abilityInfo
    elseif instance._instanceData then
        abilityInfo = binaryStorage.decodeInstanceFieldsAsync(instance):Await()[1]
    else
        abilityInfo = {}
    end

    local newEncounters = {}
    local migratedHere = 0

    for i, encounter in ipairs(instance.encounters) do
        if not encounterIsLegacy(encounter) then
            newEncounters[i] = encounter
        else
            waitOutCombat()

            local reencoded, failReason, poolGrowthBytes = migrateEncounter(encounter, instance, staged)
            -- Interned pool entries persist even when the instance later
            -- fails verification, so charge them unconditionally
            totals.poolGrowth = totals.poolGrowth + (poolGrowthBytes or 0)
            if not reencoded then
                BattleScrolls.log.Warn(string.format(
                    "Migration: instance %d encounter %d failed verification (%s), leaving instance in old format",
                    instance.index or -1, i, failReason or "?"))
                return false
            end
            newEncounters[i] = reencoded
            migratedHere = migratedHere + 1

            -- One encounter is the unit of work: do not start the next burst
            -- until this one's garbage is confirmed reclaimed
            BattleScrolls.gc:CollectFullAsync():Await()
        end
    end

    local encodedFields = binaryStorage.encodeInstanceFieldsAsync(abilityInfo, staged):Await()
    -- Commit: swap encounters, fields and size cache without yielding. Empty
    -- caches must not accumulate until the after-pass: a synchronous UI read
    -- could otherwise remeasure every migrated instance in one call.
    instance.encounters = newEncounters
    instance._instanceData = encodedFields._instanceData
    instance._instanceDataVersion = encodedFields._instanceDataVersion
    BattleScrolls.storage:CacheInstanceRegistry(instance, staged)
    BattleScrolls.storage:EstimateInstanceSize(instance, true)

    totals.migrated = totals.migrated + migratedHere
    return true
end

---Center-screen announcement (discovered-location style). Console chat boxes
---clip long messages; CSAs are the base game's channel for event one-liners.
---@param secondaryText string
---@param sound string
local function announce(secondaryText, sound)
    ---@diagnostic disable-next-line: undefined-field -- CreateMessageParams missing from the CSA stub
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, sound)
    messageParams:SetText(GetString(BATTLESCROLLS_UI_NAME), secondaryText)
    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST)
    ---@diagnostic disable-next-line: undefined-field -- AddMessageWithParams missing from the CSA stub
    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
end

---Measures the whole history with the current model for both sides of the
---migration comparison. Normal reads accept older caches, so explicitly
---refresh one instance at a time and yield before measuring the next.
---@return number bytes
local function historyMemoryAsync()
    local totalBytes = 0
    for _, instance in ipairs(BattleScrolls.storage.savedVariables.history) do
        totalBytes = totalBytes + BattleScrolls.storage:EstimateInstanceSize(instance, true)
        LibEffect.YieldWithGC():Await()
    end
    return totalBytes
end

local function runMigrationAsync()
    LibEffect.Async(function()
        -- Re-evaluated here: scribe binds the live instance asynchronously,
        -- so the scheduling scan may have seen it as migratable
        local pending = {}
        for _, instance in ipairs(BattleScrolls.storage.savedVariables.history) do
            if instanceNeedsMigration(instance) then
                pending[#pending + 1] = instance
            end
        end
        if #pending == 0 and not hasLegacySharedSetups() then
            if everythingMigrated() then
                BattleScrolls.storage.savedVariables.migrationDoneV20Setups = true
            end
            return
        end

        -- DEFER_NOTIFICATION: audible but soft (MESSAGE_BROADCAST is silent,
        -- quest/objective sounds demand too much attention)
        announce(GetString(BATTLESCROLLS_MIGRATION_START), SOUNDS.DEFER_NOTIFICATION)

        ---@type MigrationTotals
        local totals = { migrated = 0, poolGrowth = 0, migratedSetups = 0, sharedFreed = 0 }
        local historyBefore = historyMemoryAsync()

        for _, instance in ipairs(pending) do
            waitOutCombat()
            local migrated = BattleScrolls.storage.writeMutex:WithPermit(LibEffect.Async(function()
                return migrateInstance(instance, totals)
            end)):Await()
            if not migrated then
                -- Not user-facing: nothing actionable, the old format
                -- stays readable. Details are in the Warn log.
                instance._migrationFailed = true
            end
        end

        migrateSharedSetupsAsync(totals)

        -- Freed = the actual change of the settings "History" figure, minus
        -- what the own-setup pool gained, plus the shared-setup savings. MiB, matching
        -- the settings tooltip's unit. Observed on the real
        -- Xbox run: the Add-On Memory gauge showed this drop only after the
        -- next UI reload - allocator fragmentation and delayed segment
        -- release can keep the gauge elevated after GC (core/gc.lua header).
        local freedMb = math.max(0,
            historyBefore - historyMemoryAsync() - totals.poolGrowth + totals.sharedFreed) / BattleScrolls.sizeModel.MIB
        announce(zo_strformat(GetString(BATTLESCROLLS_MIGRATION_DONE),
            totals.migrated, string.format("%.1f", freedMb)), SOUNDS.QUEST_COMPLETED)
        if totals.migrated > 0 or totals.migratedSetups > 0 then
            -- The one durable takeaway goes to chat (short enough to fit);
            -- default-yellow prefix + white body, matching core/log.lua
            d(string.format("[%s]|cffffff %s",
                GetString(BATTLESCROLLS_UI_NAME), GetString(BATTLESCROLLS_MIGRATION_TIP)))
        end

        if everythingMigrated() then
            BattleScrolls.storage.savedVariables.migrationDoneV20Setups = true
        end

        BattleScrolls.gc:RequestGC(2)
    end):Run()
end

---Schedules the migration when legacy encounters or shared setups exist. Once
---migrationDoneV20Setups is set this is a no-op forever. Until then, the
---first activation decides for the whole session (the scan is a couple of
---field reads per stored encounter, no decoding); remaining legacy
---instances (interrupted session, live instance, failed ones excluded) are
---picked up on later loads. The flag is versioned so a format bump only
---has to introduce a fresh flag name to re-arm the whole pipeline.
function migration:Initialize()
    if BattleScrolls.storage.savedVariables.migrationDoneV20Setups then
        return
    end
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, function()
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED)
        if everythingMigrated() then
            BattleScrolls.storage.savedVariables.migrationDoneV20Setups = true
            return
        end
        if hasLegacySharedSetups() then
            zo_callLater(runMigrationAsync, START_DELAY_MS)
            return
        end
        for _, instance in ipairs(BattleScrolls.storage.savedVariables.history) do
            if instanceNeedsMigration(instance) then
                zo_callLater(runMigrationAsync, START_DELAY_MS)
                return
            end
        end
        -- Legacy data exists but only where this session cannot touch it
        -- (the live instance); the next session picks it up
    end)
end

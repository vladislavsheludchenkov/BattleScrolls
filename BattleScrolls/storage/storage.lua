-----------------------------------------------------------
-- Storage
-- SavedVariables management and persistence for Battle Scrolls
--
-- Handles:
--   - SavedVariables initialization and access
--   - Combat history management (instances and encounters)
--   - Memory management and cleanup (size presets)
--   - Encoding/decoding coordination with binaryStorage
--   - Settings access and defaults
--
-- Storage hierarchy:
--   savedVariables.history[] → InstanceStorage
--   InstanceStorage.encounters[] → CompactEncounter
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

-- Storage types are aliases of the live State types (defined in state.lua)
-- They are structurally identical - data is copied directly from state to storage
--
-- DamageDoneStorage handles two formats:
-- 1. Verbose (DamageDone): { total, byDotOrDirect, byDamageType, byAbilityId }
-- 2. Decoded compact (DamageByAbility): just { [abilityId] = DamageBreakdown, ... }
-- Use Arithmancer.GetAbilities() to get abilities from either format.
---@alias DamageByAbility table<number, DamageBreakdown>
---@alias DamageDoneStorage DamageDone | DamageByAbility
---@alias HealingBreakdownStorage HealingBreakdown
---@alias HealingDoneDiffSourceStorage HealingDoneDiffSource
---@alias HealingDoneStorage HealingDone
---@alias HealingStatsStorage HealingStats
---@alias AbilityInfoStorage AbilityInfo
---@alias EffectStatsStorage EffectStats
---@alias BossEffectStatsStorage BossEffectStats
---@alias GroupEffectStatsStorage GroupEffectStats
---@alias PlayerEffectStatsStorage PlayerEffectStats

---@class EnemyProcCount
---@field unitId number
---@field procCount number

---@class ProcData
---@field abilityId number
---@field totalProcs number
---@field procsByEnemy EnemyProcCount[] Procs broken down by enemy
---@field meanIntervalMs number Mean time between procs in milliseconds
---@field medianIntervalMs number Median time between procs in milliseconds

---Binary-encoded encounter (v3+)
---@class CompactEncounter
---@field _v number Schema version (3+)
---@field _bits number Bit length of encoded data
---@field _data string[] Array of base64-encoded data chunks
---@field displayName string|nil Pre-computed display name for encounter list UI
---@field location string|nil Location within the zone
---@field timestampS number Absolute timestamp when encounter started
---@field durationMs number Duration of the encounter in milliseconds
---@field bossesUnits number[]|nil Unit IDs of bosses involved in this encounter
---@field isPlayerFight boolean|nil True if this was a PvP fight
---@field isDummyFight boolean|nil True if this was a training dummy fight

---@class Encounter
---@field displayName string|nil Pre-computed display name for encounter list UI (avoids decoding entire encounter)
---@field location string|nil Location within the zone (e.g., "Courtyard", "Faceted Gallery") if defined and different from zone name
---@field timestampS number Absolute timestamp when encounter started
---@field durationMs number Duration of the encounter in milliseconds
---@field bossesUnits number[] Unit IDs of bosses involved in this encounter, if any
---@field damageByUnitId table<number, table<number, DamageDoneStorage>> Personal damage done, nested: sourceUnitId -> targetUnitId -> damage
---@field damageByUnitIdGroup table<number, table<number, DamageDoneStorage>> Group damage done, nested: sourceUnitId -> targetUnitId -> damage
---@field damageTakenByUnitId table<number, table<number, DamageDoneStorage>> Damage taken, nested: sourceUnitId -> targetUnitId -> damage
---@field healingStats HealingStatsStorage All healing data for this encounter
---@field procs ProcData[]
---@field effectsOnPlayer table<number, PlayerEffectStatsStorage>|nil Effects on player with attribution, keyed by abilityId
---@field effectsOnBosses table<string, table<number, BossEffectStatsStorage>>|nil Effects on bosses, nested: unitTag ("boss1") -> abilityId -> stats
---@field effectsOnGroup table<string, table<number, GroupEffectStatsStorage>>|nil Effects on group members, nested: displayName ("@Player") -> abilityId -> stats
---@field bossNames table<string, string>|nil Maps unitTag to boss name for UI display (e.g., "boss1" -> "Magma Incarnate")
---@field playerAliveTimeMs number|nil Player alive time in ms (for uptime calculations)
---@field unitAliveTimeMs table<string, number>|nil Per-unit alive time in ms (for uptime calculations), keyed by unitTag (bosses) or displayName (group)
---@field unitNames table<number, string>|nil Unit names lookup (v7+: stored per-encounter, v3-v6: at instance level)

-- Instance types distinguish between live state (during combat) and storage format.
-- InstanceState: Live instance with uncompressed abilityInfo and unitNames
-- InstanceStorage: Persisted instance with potentially compressed data (_instanceData/_instanceBits)
-- Instance: Union type for code that handles both formats

---@class InstanceState
---@field zone string Zone or instance name (e.g., "Eastmarch", "Sunspire", "Lucent Citadel")
---@field isOverland boolean True if this is an overland zone (not a dungeon/trial/arena)
---@field timestampS number Absolute timestamp when this instance visit started
---@field abilityInfo table<number, AbilityInfoStorage> Lookup table of ability ID to name and icon
---@field unitNames table<number, string> Lookup table of unit ID to unit name
---@field encounters Encounter[] Array of encounters in this instance

---@class InstanceStorage
---@field zone string Zone or instance name
---@field isOverland boolean True if this is an overland zone
---@field left boolean True if player left this zone
---@field timestampS number Absolute timestamp when this instance visit started
---@field abilityInfo table<number, AbilityInfoStorage>|nil Uncompressed ability info (nil if compressed)
---@field unitNames table<number, string>|nil Uncompressed unit names (nil if compressed)
---@field _instanceData string[]|nil Compressed abilityInfo and unitNames (base64 chunks)
---@field _instanceBits number|nil Bit length of compressed data
---@field encounters Encounter[] Array of encounters in this instance

---@alias Instance InstanceState|InstanceStorage

---@class InstanceWithIndex : InstanceStorage
---@field index number Index of this instance in the history

---Zone types for recording filter
---@alias RecordZoneType "instanced"|"overland"|"house"|"pvp"

---Fight types for recording filter
---@alias RecordFightType "boss"|"trash"|"player"|"dummy"

---@class StorageSettings
---@field dpsMeterLingerMs number Linger duration (0 = no linger, -1 = always show)
---@field dpsMeterPersonalEnabled boolean
---@field dpsMeterPersonalMode "auto"|"damage"|"healing"
---@field dpsMeterPersonalDesign "default"|"minimal"|"bar"
---@field dpsMeterPersonalOffsetX number
---@field dpsMeterPersonalOffsetY number
---@field dpsMeterPersonalScale number
---@field dpsMeterGroupEnabled boolean
---@field dpsMeterGroupShowSolo boolean
---@field dpsMeterGroupDesign "text"|"hodor"|"bars"
---@field dpsMeterGroupPosition "above"|"below"|"separate"
---@field dpsMeterGroupOffsetX number
---@field dpsMeterGroupOffsetY number
---@field dpsMeterGroupScale number
---@field dpsMeterPersonalDesignSettings table<string, table<string, any>>
---@field dpsMeterGroupDesignSettings table<string, table<string, any>>
---@field recordingEnabled boolean
---@field recordInZones table<RecordZoneType, boolean>
---@field recordInFights table<RecordFightType, boolean>
---@field effectTrackingEnabled boolean
---@field trackPlayerBuffs boolean
---@field trackPlayerDebuffs boolean
---@field trackGroupBuffs boolean
---@field trackBossDebuffs boolean
---@field effectReconciliationPreset "max"|"high"|"normal"|"low"|"off"
---@field storageSizePreset "xs"|"small"|"medium"|"large"|"xl"|"caution"|"yolo"
---@field hasCompletedOnboarding boolean

---@class StorageData
---@field version number Version of the saved variables structure
---@field history InstanceWithIndex[] Flat array of all instances/locations visited
---@field settings StorageSettings User settings

---@class SizePreset
---@field key string Preset key
---@field labelStringId string Localization string ID
---@field memoryMB number Maximum memory in megabytes

---@class AsyncSpeedPreset
---@field key string Preset key
---@field fps number FPS threshold for LibAsync stall detection

---@class MeterPreset
---@field key string Preset key
---@field dpsMeterPersonalEnabled boolean|nil
---@field dpsMeterPersonalDesign string|nil
---@field dpsMeterPersonalOffsetX number|nil
---@field dpsMeterPersonalOffsetY number|nil
---@field dpsMeterPersonalScale number|nil
---@field dpsMeterGroupEnabled boolean|nil
---@field dpsMeterGroupShowSolo boolean|nil
---@field dpsMeterGroupDesign string|nil
---@field dpsMeterGroupPosition string|nil
---@field dpsMeterGroupOffsetX number|nil
---@field dpsMeterGroupOffsetY number|nil
---@field dpsMeterGroupScale number|nil

---@class Storage
---@field savedVariables StorageData
---@field defaults StorageData
---@field cleanupTask Effect|nil Currently running cleanup task (nil if none)
---@field sizePresets table<string, SizePreset> Available memory size presets
---@field sizePresetOrder string[] Ordered list of size preset keys
---@field asyncSpeedPresets table<string, AsyncSpeedPreset> Available async speed presets
---@field asyncSpeedPresetOrder string[] Ordered list of async speed preset keys
---@field meterPresets table<string, MeterPreset> Available meter configuration presets
---@field meterPresetOrder string[] Ordered list of meter preset keys

---@type Storage
local storage = {
    cleanupTask = nil,
}

BattleScrolls.storage = storage

storage.defaults = {
    version = 1,
    history = {},
    settings = {
        dpsMeterLingerMs = 30000, -- 0 = no linger, -1 = always show
        -- Personal meter settings (disabled by default until onboarding)
        dpsMeterPersonalEnabled = false,
        dpsMeterPersonalMode = "auto", -- "auto", "damage", "healing"
        dpsMeterPersonalDesign = "default", -- "default" | "minimal" | "bar"
        dpsMeterPersonalOffsetX = 70,
        dpsMeterPersonalOffsetY = 450,
        dpsMeterPersonalScale = 1.0, -- 0.5, 0.75, 1.0, 1.25, 1.5
        -- Group meter settings (disabled by default until onboarding)
        dpsMeterGroupEnabled = false,
        dpsMeterGroupShowSolo = false, -- show group meter when you're the only one
        dpsMeterGroupDesign = "text", -- "text" | "hodor" | "bars"
        dpsMeterGroupPosition = "below", -- "above" | "below" | "separate"
        dpsMeterGroupOffsetX = 70, -- only used when position = "separate" or personal disabled
        dpsMeterGroupOffsetY = 550, -- only used when position = "separate" or personal disabled
        dpsMeterGroupScale = 1.0, -- 0.5, 0.75, 1.0, 1.25, 1.5
        -- Design-specific settings (per design id)
        dpsMeterPersonalDesignSettings = {},
        dpsMeterGroupDesignSettings = {},
        recordingEnabled = false, -- disabled by default until onboarding
        recordInZones = { instanced = true, overland = true, house = true, pvp = true }, -- set of zone types to record
        recordInFights = { boss = true, trash = true, player = true, dummy = true }, -- set of fight types to record
        effectTrackingEnabled = false, -- disabled by default until onboarding
        trackPlayerBuffs = true, -- track buffs on player
        trackPlayerDebuffs = true, -- track debuffs on player
        trackGroupBuffs = true, -- track buffs on group members
        trackBossDebuffs = true, -- track debuffs on bosses
        effectReconciliationPreset = "normal", -- Effect reconciliation precision preset
        storageSizePreset = "medium", -- Storage size preset key
        hasCompletedOnboarding = false, -- whether user has completed initial setup
    }
}

-- Memory size presets
-- Reference sizes: dungeon ~0.25-0.5 MB, trial ~0.5-1 MB
-- ESO addon pool limit: 100 MB total (warning at 70 MB)
storage.sizePresets = {
    xs = { key = "xs", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XS", memoryMB = 5 },
    small = { key = "small", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_SMALL", memoryMB = 8 },
    medium = { key = "medium", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_MEDIUM", memoryMB = 12 },
    large = { key = "large", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_LARGE", memoryMB = 18 },
    xl = { key = "xl", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XL", memoryMB = 25 },
    caution = { key = "caution", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_CAUTION", memoryMB = 40 },
    yolo = { key = "yolo", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_YOLO", memoryMB = 60 },
}

-- Ordered list of preset keys for UI
storage.sizePresetOrder = { "xs", "small", "medium", "large", "xl", "caution", "yolo" }

-- Async speed presets (LibAsync stall threshold in FPS)
-- Lower FPS = more aggressive processing = faster but may cause stutters
-- Higher FPS = gentler processing = smoother but slower
storage.asyncSpeedPresets = {
    performance = { key = "performance", fps = 15 },
    balanced = { key = "balanced", fps = 30 },
    smooth = { key = "smooth", fps = 60 },
}
storage.asyncSpeedPresetOrder = { "performance", "balanced", "smooth" }

-- Effect reconciliation presets
-- Controls how often we call GetUnitBuffInfo to catch missed effect events
-- WARNING: Each GetUnitBuffInfo call consumes addon memory that is NEVER returned!
-- checkIntervalMs: how often to check if reconciliation is needed
-- cooldownPerUnitMs: minimum time between reconciling the same unit
storage.reconciliationPresets = {
    max = { key = "max", labelStringId = "BATTLESCROLLS_SETTINGS_RECON_MAX", checkIntervalMs = 50, cooldownPerUnitMs = 500 },
    high = { key = "high", labelStringId = "BATTLESCROLLS_SETTINGS_RECON_HIGH", checkIntervalMs = 100, cooldownPerUnitMs = 900 },
    normal = { key = "normal", labelStringId = "BATTLESCROLLS_SETTINGS_RECON_NORMAL", checkIntervalMs = 200, cooldownPerUnitMs = 1500 },
    low = { key = "low", labelStringId = "BATTLESCROLLS_SETTINGS_RECON_LOW", checkIntervalMs = 500, cooldownPerUnitMs = 3000 },
    off = { key = "off", labelStringId = "BATTLESCROLLS_SETTINGS_RECON_OFF", checkIntervalMs = 0, cooldownPerUnitMs = 0 },
}
storage.reconciliationPresetOrder = { "max", "high", "normal", "low", "off" }

-- Complete DPS meter presets for onboarding
-- Each preset configures personal meter, group meter, positions, and designs as a complete package
storage.meterPresets = {
    personal_minimal = {
        key = "personal_minimal",
        -- Personal meter: enabled, minimal design, top-left
        dpsMeterPersonalEnabled = true,
        dpsMeterPersonalDesign = "minimal",
        dpsMeterPersonalOffsetX = 10,
        dpsMeterPersonalOffsetY = -21,
        dpsMeterPersonalScale = 0.75,
        -- Group meter: disabled
        dpsMeterGroupEnabled = false,
    },
    full_stacked = {
        key = "full_stacked",
        -- Personal meter: enabled, default design, upper-left
        dpsMeterPersonalEnabled = true,
        dpsMeterPersonalDesign = "default",
        dpsMeterPersonalOffsetX = 70,
        dpsMeterPersonalOffsetY = 450,
        dpsMeterPersonalScale = 1.0,
        -- Group meter: enabled, stacked below personal
        dpsMeterGroupEnabled = true,
        dpsMeterGroupDesign = "text",
        dpsMeterGroupPosition = "below",
        dpsMeterGroupScale = 1.0,
    },
    hodor = {
        key = "hodor",
        -- Personal meter: disabled
        dpsMeterPersonalEnabled = false,
        -- Group meter: enabled, hodor design, always visible
        dpsMeterGroupEnabled = true,
        dpsMeterGroupShowSolo = true,
        dpsMeterGroupDesign = "hodor",
        dpsMeterGroupPosition = "separate",
        dpsMeterGroupOffsetX = 100,
        dpsMeterGroupOffsetY = 400,
        dpsMeterGroupScale = 1.0,
    },
    bar = {
        key = "bar",
        -- Personal meter: enabled, bar design
        dpsMeterPersonalEnabled = true,
        dpsMeterPersonalDesign = "bar",
        dpsMeterPersonalOffsetX = 100,
        dpsMeterPersonalOffsetY = 400,
        dpsMeterPersonalScale = 1.0,
        -- Group meter: disabled
        dpsMeterGroupEnabled = false,
    },
    colorful = {
        key = "colorful",
        -- Personal meter: enabled, bar design
        dpsMeterPersonalEnabled = true,
        dpsMeterPersonalDesign = "bar",
        dpsMeterPersonalOffsetX = 100,
        dpsMeterPersonalOffsetY = 400,
        dpsMeterPersonalScale = 1.0,
        -- Group meter: enabled, bars design, stacked below personal
        dpsMeterGroupEnabled = true,
        dpsMeterGroupShowSolo = false,
        dpsMeterGroupDesign = "bars",
        dpsMeterGroupPosition = "below",
        dpsMeterGroupScale = 1.0,
    },
    disabled = {
        key = "disabled",
        -- Both meters disabled
        dpsMeterPersonalEnabled = false,
        dpsMeterGroupEnabled = false,
    },
}
storage.meterPresetOrder = { "full_stacked", "personal_minimal", "hodor", "bar", "colorful", "disabled" }

---Applies a meter preset to settings
---@param presetKey string The preset key
function storage:ApplyMeterPreset(presetKey)
    local preset = self.meterPresets[presetKey]
    if not preset then return end

    local settings = self.savedVariables.settings
    for key, value in pairs(preset) do
        if key ~= "key" then
            settings[key] = value
        end
    end
end

---Gets the async speed preset key from the current LibAsync stall threshold
---Returns nil if the value doesn't match any preset (custom value)
---@return string|nil presetKey
function storage:GetAsyncSpeedPresetKey()
    local currentFPS = AsyncSavedVars and AsyncSavedVars.ASYNC_STALL_THRESHOLD or 15
    for _, preset in pairs(self.asyncSpeedPresets) do
        if preset.fps == currentFPS then
            return preset.key
        end
    end
    return nil -- Custom value
end

---Gets the current async stall threshold FPS value
---@return number fps
function storage:GetAsyncStallThreshold()
    return AsyncSavedVars and AsyncSavedVars.ASYNC_STALL_THRESHOLD or 15
end

---Sets the LibAsync stall threshold
---@param fps number The FPS threshold value
function storage:SetAsyncStallThreshold(fps)
    if AsyncSavedVars then
        AsyncSavedVars.ASYNC_STALL_THRESHOLD = fps
        -- LibAsync reads from ASYNC_STALL_THRESHOLD global, need to update via its API
        -- The actual global is internal to LibAsync, but we can set the saved var
        -- which will be picked up on next load
    end
end

---Gets the current size preset configuration
---@return SizePreset preset The preset configuration table
function storage:GetCurrentSizePreset()
    local presetKey = self.savedVariables and self.savedVariables.settings and self.savedVariables.settings.storageSizePreset
    return self.sizePresets[presetKey] or self.sizePresets.medium
end

---Rounds up to the next power of 2 (Lua allocates array/hash in powers of 2)
---@param n number
---@return number
local function nextPow2(n)
    if n <= 0 then return 0 end
    local p = 1
    while p < n do p = p * 2 end
    return p
end

---Estimates memory usage of a value in bytes (Lua 5.1 64-bit layout)
---Based on actual Lua 5.1 memory structures:
--- - TValue: 16 bytes (8-byte Value union + 4-byte type tag + 4 padding)
--- - TString: 32 bytes header (CommonHeader + reserved + hash + len) + string length + 1 null
--- - Table: 72 bytes header, plus (allocated in powers of 2):
---   - Array part (keys 1..n): 16 bytes per slot
---   - Hash part: 40 bytes per Node (key TValue + value TValue + next ptr)
--- - Short strings (<=40 chars) are interned, long strings are separate allocations
---@param value any Value to estimate size of
---@param visited table<any, boolean>|nil Table to track visited tables/strings to avoid counting duplicates
---@return number bytes Estimated memory in bytes
local function estimateValueSize(value, visited)
    local valueType = type(value)

    if valueType == "nil" then
        return 0
    elseif valueType == "boolean" or valueType == "number" then
        -- These are stored directly in TValue, no separate heap allocation
        -- The table slot (counted in table overhead) provides the TValue space
        return 0
    elseif valueType == "string" then
        local len = #value
        -- Lua 5.1 interns short strings (≤40 chars), long strings are separate allocations
        if len <= 40 then
            visited = visited or {}
            if visited[value] then
                return 0 -- Already counted this interned string
            end
            visited[value] = true
        end
        -- TString: CommonHeader(16) + reserved(1) + padding(3) + hash(4) + len(8) = 32 bytes
        -- Plus string content + null terminator
        return 32 + len + 1
    elseif valueType == "table" then
        visited = visited or {}
        if visited[value] then
            return 0 -- Already counted this table reference
        end
        visited[value] = true

        -- Table struct header: ~72 bytes
        local size = 72

        -- Check if this is a pure array (consecutive integers 1..n)
        local arrayLen = #value
        local totalKeys = 0
        local isPureArray = arrayLen > 0
        local stringKeyBytes = 0

        for k, v in pairs(value) do
            totalKeys = totalKeys + 1

            -- Check if key breaks pure array pattern
            if isPureArray then
                local kType = type(k)
                if kType ~= "number" or k < 1 or k > arrayLen or k % 1 ~= 0 then
                    isPureArray = false
                end
            end

            -- Track string key overhead (short strings interned, long strings always counted)
            if type(k) == "string" then
                local kLen = #k
                if kLen > 40 or not visited[k] then
                    if kLen <= 40 then visited[k] = true end
                    stringKeyBytes = stringKeyBytes + 32 + kLen + 1
                end
            end

            -- Recursively count value
            size = size + estimateValueSize(v, visited)
        end

        if isPureArray and totalKeys == arrayLen then
            -- Pure array: 16 bytes per TValue slot (allocated in powers of 2)
            size = size + nextPow2(arrayLen) * 16
        else
            -- Hash table: 40 bytes per node + string key overhead (allocated in powers of 2)
            size = size + nextPow2(totalKeys) * 40 + stringKeyBytes
        end

        return size
    else
        -- function, userdata, thread - shouldn't appear in saved data
        return 0
    end
end

-- Correction factor for memory estimates.
-- Our Lua 5.1 memory model underestimates actual ESO memory usage by ~50% due to:
-- - ZO_SavedVars wrapper overhead (nested account/world tables)
-- - Memory allocator bookkeeping per allocation
-- - Possible differences in Havok Lua vs standard Lua 5.1
local MEMORY_ESTIMATE_CORRECTION_FACTOR = 1.5

---Gets the estimated size of an instance in bytes, using cached value if available
---Calculates and caches the size on first access
---@param instance Instance
---@return number bytes Estimated memory in bytes
local function getInstanceSize(instance)
    if instance._estimatedSize then
        return instance._estimatedSize
    end
    -- Calculate and cache for future use (with correction factor applied)
    local size = estimateValueSize(instance) * MEMORY_ESTIMATE_CORRECTION_FACTOR
    BattleScrolls.gc:RequestGC() -- estimateValueSize generates a lot of garbage
    instance._estimatedSize = size
    return size
end

function storage:Initialize()
    self.savedVariables = ZO_SavedVars:NewAccountWide("BattleScrollsSavedVariables", 4, nil, self.defaults, GetWorldName())
end

---PushInstance adds an instance to the history, cleaning up old entries if necessary and assigning it a unique index
---@param instance Instance The instance to add
function storage:PushInstance(instance)
    local index

    if self.savedVariables.history[#self.savedVariables.history] then
        index = self.savedVariables.history[#self.savedVariables.history].index + 1
    else
        index = 1
    end

    instance.index = index

    table.insert(self.savedVariables.history, instance)
end

---Async version of CleanupIfNecessary
---Cancels any previous cleanup task and starts a new one
function storage:CleanupIfNecessaryAsync()
    if self.cleanupTask then
        self.cleanupTask:Cancel()
        self.cleanupTask = nil
    end

    local preset = self:GetCurrentSizePreset()
    local byteLimit = preset.memoryMB * 1000000
    local history = self.savedVariables.history

    if #history == 0 then
        return
    end

    self.cleanupTask = LibEffect.Async(function()
        -- Sum sizes (yields per instance)
        local currentBytes = 0
        local instanceSizes = {}

        for i, instance in ipairs(history) do
            local size = getInstanceSize(instance)
            instanceSizes[i] = size
            currentBytes = currentBytes + size
            LibEffect.YieldWithGC():Await()
        end
        LibEffect.YieldWithGC():Await()

        -- Check if cleanup needed
        if currentBytes <= byteLimit or #history <= 1 then
            return
        end

        -- Calculate how many instances to remove
        local removeCount = 0
        local excess = currentBytes - byteLimit
        local removed = 0

        for i = 1, #history - 1 do
            removed = removed + instanceSizes[i]
            removeCount = removeCount + 1
            if removed >= excess then
                break
            end
        end

        if removeCount > 0 then
            BattleScrolls.utils.removePrefixInPlace(history, removeCount)
            -- GC after removing instances (big cleanup done, nothing important happening)
            BattleScrolls.gc:RequestGC(2)
            -- BattleScrolls.log.Info(string.format("Cleaned up %d old instance(s)",
            --     removeCount))
        end
    end):Ensure(function()
        self.cleanupTask = nil
    end):Run()
end

---Estimates total memory usage of the combat history in bytes
---Based on Lua 5.1 64-bit memory layout
---Uses cached per-instance sizes for efficiency
---@return number bytes Total estimated memory in bytes
---@return number encounterCount Total number of encounters
---@return number instanceCount Total number of instances
function storage:EstimateHistorySize()
    local history = self.savedVariables.history
    if not history then
        return 0, 0, 0
    end

    local totalBytes = 0
    local encounterCount = 0

    for _, instance in ipairs(history) do
        totalBytes = totalBytes + getInstanceSize(instance)
        encounterCount = encounterCount + #instance.encounters
    end

    return totalBytes, encounterCount, #history
end

-- =============================================================================
-- PUBLIC API: Encode/Decode/Check Functions
-- =============================================================================

---Encodes an encounter to binary format for storage asynchronously
---Returns an Effect that resolves to the encoded encounter.
---@param encounter Encounter
---@return Effect
function storage.EncodeEncounterAsync(encounter)
    return BattleScrolls.binaryStorage.EncodeEncounterAsync(encounter)
end

---Tab visibility flags computed from encounter data
---@class TabVisibility
---@field dealtDamage boolean Player dealt any damage
---@field dealtDamageToBosses boolean Player dealt damage to boss units
---@field hasDamageTaken boolean Encounter has damage taken data
---@field hasHealingOutToGroup boolean Player healed group members
---@field hasSelfHealing boolean Player healed self
---@field hasHealingInFromGroup boolean Player received healing from group
---@field hasEffects boolean Encounter has any effect tracking data

---Computes tab visibility flags for a decoded encounter.
---These flags are cached on the encounter to avoid recomputation in GetEncounterTabBarEntries.
---@param decodedEncounter Encounter
---@return Encounter decodedEncounter The same encounter with _tabVisibility field added
local function computeTabVisibility(decodedEncounter)
    local computeTotal = BattleScrolls.arithmancer.ComputeDamageTotal
    local dealtDamage = false
    local dealtDamageToBosses = false
    local bossesSet = nil

    -- Build boss set for O(1) lookup
    if decodedEncounter.bossesUnits then
        bossesSet = {}
        for _, bossUnitId in ipairs(decodedEncounter.bossesUnits) do
            bossesSet[bossUnitId] = true
        end
    end

    -- Check damage data
    for _, byTarget in pairs(decodedEncounter.damageByUnitId) do
        for targetUnitId, damage in pairs(byTarget) do
            local total = computeTotal(damage)
            if total > 0 then
                dealtDamage = true
                if bossesSet and bossesSet[targetUnitId] then
                    dealtDamageToBosses = true
                    break  -- Found both flags, can exit early
                end
            end
        end
        if dealtDamageToBosses then break end
    end

    -- Check effects
    local hasEffects = (decodedEncounter.effectsOnPlayer and not ZO_IsTableEmpty(decodedEncounter.effectsOnPlayer))
        or (decodedEncounter.effectsOnBosses and not ZO_IsTableEmpty(decodedEncounter.effectsOnBosses))
        or (decodedEncounter.effectsOnGroup and not ZO_IsTableEmpty(decodedEncounter.effectsOnGroup))

    decodedEncounter._tabVisibility = {
        dealtDamage = dealtDamage,
        dealtDamageToBosses = dealtDamageToBosses,
        hasDamageTaken = not ZO_IsTableEmpty(decodedEncounter.damageTakenByUnitId),
        hasHealingOutToGroup = not ZO_IsTableEmpty(decodedEncounter.healingStats.healingOutToGroup),
        hasSelfHealing = decodedEncounter.healingStats.selfHealing.total.raw > 0,
        hasHealingInFromGroup = not ZO_IsTableEmpty(decodedEncounter.healingStats.healingInFromGroup),
        hasEffects = hasEffects,
    }

    return decodedEncounter
end

---Decodes a binary encounter to verbose format asynchronously.
---Returns an Effect that resolves to the decoded encounter.
---Yields per major section to prevent frame spikes.
---Caching is managed by the caller (UI stores in self.decodedEncounter).
---@param encounter CompactEncounter The binary-encoded encounter
---@return Effect Effect that resolves to Encounter
function storage.DecodeEncounterAsync(encounter)
    return LibEffect.Async(function()
        local decoded = BattleScrolls.binaryStorage.DecodeEncounterAsync(encounter):Await()
        return computeTabVisibility(decoded)
    end)
end

-- =============================================================================
-- INSTANCE-LEVEL FIELD ENCODING/DECODING
-- =============================================================================

---Decoded instance fields tuple: [1] = abilityInfo, [2] = unitNames (empty, stored at encounter level)
---@alias DecodedInstanceFields { [1]: table<number, AbilityInfo>, [2]: table<number, string> }

---Decodes abilityInfo for an instance asynchronously.
---Returns an Effect that resolves to { abilityInfo, {} }.
---Note: unitNames are stored at encounter level, not instance level.
---@param instance Instance
---@return Effect Effect that resolves to DecodedInstanceFields
function storage.DecodeInstanceFieldsAsync(instance)
    return BattleScrolls.binaryStorage.DecodeInstanceFieldsAsync(instance)
end


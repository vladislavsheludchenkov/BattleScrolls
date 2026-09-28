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

---@class EnemyProcCount
---@field unitId number
---@field procCount number

---@class ProcData
---@field abilityId number
---@field totalProcs number
---@field procsByEnemy EnemyProcCount[] Procs broken down by enemy
---@field meanIntervalMs number Mean time between procs in milliseconds
---@field medianIntervalMs number Median time between procs in milliseconds

---@class WeavingAbilityData
---@field abilityId number
---@field activations number Total times this skill was activated
---@field afterSum number Total ms of weave gaps after this skill
---@field afterCount number Number of "after" measurements
---@field beforeSum number Total ms of weave gaps before this skill (can be negative)
---@field beforeCount number Number of "before" measurements
---@field weavingErrors number Times a skill→skill happened after this skill (no LA in between)

---@class WeavingData
---@field lightAttackHits number Light attack count (confirmed by combat events)
---@field heavyAttackHits number Heavy attack count (from ACTION_RESULT_BEGIN)
---@field skillActivations number Total skill/ultimate activations
---@field totalWeavingErrors number Total skill→skill count (no LA in between)
---@field doubleLaErrors number Total la→la count (double light attack without a skill)
---@field downtimeMs number Sum of gaps of 3s or more between casts, kept out of the per-ability delays (0 in pre-v20 recordings)
---@field downtimeGaps number Count of those gaps
---@field byAbility WeavingAbilityData[] Per-ability weaving breakdown

---Binary-encoded encounter (v3+)
---@class CompactEncounter
---@field _v number Schema version (3+)
---@field _data string[] Array of base64-encoded data chunks
---@field _shared CompactSharedEntry[]|nil Binary-encoded shared group entries (v17+; pre-v17 encounters use the plain sharedData field)
---@field _setupHash number|nil 16-bit hash referencing the own-setup pool when the setup section was deduplicated out of _data (v17+)
---@field displayName string|nil Pre-computed display name for encounter list UI
---@field location string|nil Location within the zone
---@field timestampS number Absolute timestamp when encounter started
---@field durationMs number Duration of the encounter in milliseconds
---@field bossesUnits number[]|nil Unit IDs of bosses involved in this encounter
---@field isPlayerFight boolean|nil True if this was a PvP fight
---@field isDummyFight boolean|nil True if this was a training dummy fight
---@field sharedData SharedDataEntry[]|nil Shared stats from group members
---@field bossSeqNames table<string, string>|nil Maps "tag:seq" to boss name for shared data display
---@field deaths EncounterDeaths|nil Death recap data (nil if player never died)
---@field bossTagSeqByUnitId table<number, string>|nil Maps boss unitId to "tag:seq" key for local player boss damage mapping
---@field gameVersion string|nil Game patch version at time of encounter (e.g. "11.3.5")
---@field playerUnitId number|nil The player's own source unit id in this encounter's damage maps (nil on encounters recorded before it was captured)
---@field customName string|nil User-set name override (plain field, editable without re-encoding)

---@class Encounter
---@field isPlayerFight boolean|nil True when a player/duel fight
---@field isDummyFight boolean|nil True when the target is a target dummy
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
---@field effectsOnPlayer table<number, EffectStatsStorage>|nil Effects on player with attribution, keyed by abilityId
---@field effectsOnBosses table<string, table<number, EffectStatsStorage>>|nil Effects on bosses, nested: unitTag ("boss1") -> abilityId -> stats
---@field effectsOnGroup table<string, table<number, EffectStatsStorage>>|nil Effects on group members, nested: displayName ("PlayerName") -> abilityId -> stats
---@field bossNames table<string, string>|nil Maps unitTag to boss name for UI display (e.g., "boss1" -> "Magma Incarnate")
---@field playerAliveTimeMs number|nil Player alive time in ms (for uptime calculations)
---@field unitAliveTimeMs table<string, number>|nil Per-unit alive time in ms (for uptime calculations), keyed by unitTag (bosses) or displayName (group)
---@field unitNames table<number, string>|nil Unit names lookup (v7+: stored per-encounter, v3-v6: at instance level)
---@field sharedData SharedDataEntry[]|nil Shared stats from group members
---@field bossSeqNames table<string, string>|nil Maps "tag:seq" to boss name for shared data display
---@field deaths EncounterDeaths|nil Death recap data (nil if player never died)
---@field bossTagSeqByUnitId table<number, string>|nil Maps boss unitId to "tag:seq" key for local player boss damage mapping
---@field setup PlayerSetup|nil  -- Player build snapshot (v9+)
---@field weaving WeavingData|nil Weaving/rotation activity data (v12+)
---@field gameVersion string|nil Game patch version at time of encounter (e.g. "11.3.5")
---@field playerUnitId number|nil The player's own source unit id in this encounter's damage maps (nil on encounters recorded before it was captured)
---@field customName string|nil User-set name override (plain field on the compact encounter)
---@field ultimate UltimateData|nil Ultimate generation/usage data (v19+)
---@field crux CruxData|nil Arcanist Crux economy data (v19+)
---@field resurrections number|nil Successful resurrection casts by the player (v19+)
---@field resurrectionLog ResurrectionEvent[]|nil Who was resurrected and when (v20+)
---@field zen ZenData|nil Per-boss DoT-count/Z'en time buckets (v19+)

-- Instance types distinguish between live state (during combat) and storage format.
-- InstanceState: Live instance with uncompressed abilityInfo and unitNames
-- InstanceStorage: Persisted instance with potentially compressed data (_instanceData)
-- Instance: Union type for code that handles both formats

---@class InstanceState
---@field zone string Zone or instance name (e.g., "Eastmarch", "Sunspire", "Lucent Citadel")
---@field isOverland boolean True if this is an overland zone (not a dungeon/trial/arena)
---@field timestampS number Absolute timestamp when this instance visit started
---@field abilityInfo table<number, AbilityInfoStorage> Lookup table of ability ID to name and icon
---@field unitNames table<number, string> Lookup table of unit ID to unit name
---@field encounters Encounter[] Array of encounters in this instance

---@class InstanceStorage
---@field isHouse boolean|nil True when the zone is a player house
---@field isPvP boolean|nil True when an AvA/battleground zone
---@field isAdventureZone boolean|nil True when an adventure zone (night market)
---@field _estimatedSize number|nil Cached chunk bytes (BattleScrolls.sizeModel)
---@field _estimatedSizeV number|nil Model version the cache was computed with
---@field index number|nil Position in history (set by the journal list)
---@field zone string Zone or instance name
---@field isOverland boolean True if this is an overland zone
---@field left boolean True if player left this zone
---@field locked boolean|nil True if instance is locked from automatic cleanup
---@field timestampS number Absolute timestamp when this instance visit started
---@field abilityInfo table<number, AbilityInfoStorage>|nil Uncompressed ability info (nil if compressed)
---@field unitNames table<number, string>|nil Uncompressed unit names (nil if compressed)
---@field _instanceData string[]|nil Compressed abilityInfo (base64 chunks)
---@field _instanceDataVersion number|nil Schema version for _instanceData
---@field _migrationFailed boolean|nil True when v17 migration failed verification for this instance (left in old format, not retried)
---@field customName string|nil User-set name override for the instance
---@field encounters CompactEncounter[] Array of encounters in this instance

---@alias Instance InstanceState|InstanceStorage

---@class InstanceWithIndex : InstanceStorage
---@field index number Index of this instance in the history

---Zone types for recording filter
---@alias RecordZoneType "instanced"|"overland"|"house"|"pvp"

---Fight types for recording filter
---@alias RecordFightType "boss"|"trash"|"player"|"dummy"

---@class StorageSettings
---@field logLevel number|nil Minimum level for chat log output
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
---@field recordInAdventureZone boolean|nil
---@field recordInFights table<RecordFightType, boolean>
---@field effectTrackingEnabled boolean
---@field trackPlayerBuffs boolean
---@field trackPlayerDebuffs boolean
---@field trackGroupBuffs boolean
---@field trackBossDebuffs boolean
---@field effectReconciliationPreset "max"|"high"|"normal"|"low"|"off"
---@field storageSizePreset "xs"|"small"|"medium"|"large"|"xl"|"caution"|"yolo"
---@field favoriteEffects table<number, boolean>
---@field pivotQueries table<string, PivotQuery>|nil Saved pivot queries
---@field hasCompletedOnboarding boolean
---@field groupBarColor string|nil Own bar color for the colorful group bars design ("RRGGBB" hex; nil = per-name default)

---@class OwnSetupPoolEntry
---@field v number Schema version the setup was encoded with
---@field c string[] Base64 chunks of the binary-encoded PlayerSetup
---@field _estimatedSize number|nil Cached chunk bytes (BattleScrolls.sizeModel)
---@field _estimatedSizeV number|nil Model version the cache was computed with

---@class StorageData
---@field version number Version of the saved variables structure
---@field history InstanceWithIndex[] Flat array of all instances/locations visited
---@field nextInstanceIndex number|nil High-water mark for instance.index assignment (auto-initialized from history)
---@field settings StorageSettings User settings
---@field sharedSetups table<string, table<number, StoredSharedSetup>>|nil Encoded shared builds by player and hash; plain entries remain readable until migration
---@field ownSetups table<number, OwnSetupPoolEntry>|nil Player's own full setups deduplicated by 16-bit setup hash (v17+; referenced by CompactEncounter._setupHash)
---@field migrationDoneV20Setups boolean|nil True once encounters and shared setups are migrated (failed entries excluded). Never in defaults: ZO_SavedVars would apply it to existing installations

---@class SizePreset
---@field key string Preset key
---@field labelStringId string Localization string ID
---@field memoryMiB number History limit in MiB, the unit of the game's memory display

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
---@field cleanupTask Fiber|nil Currently running cleanup fiber (nil if none)
---@field writeMutex Semaphore Serializes structural writes to the history and the setup pools; see the field's initializer
---@field sizePresets table<string, SizePreset> Available memory size presets
---@field sizePresetOrder string[] Ordered list of size preset keys
---@field asyncSpeedPresets table<string, AsyncSpeedPreset> Available async speed presets
---@field asyncSpeedPresetOrder string[] Ordered list of async speed preset keys
---@field meterPresets table<string, MeterPreset> Available meter configuration presets
---@field meterPresetOrder string[] Ordered list of meter preset keys
local storage = {
    cleanupTask = nil,
    -- Held by every multi-frame write to the history and the setup pools: the
    -- finalize (intern -> encode -> insert -> push), a migration instance
    -- commit, the cleanup task's eviction and the orphan prune. Overlapping
    -- finalizes would share an instance's append-only registry and could
    -- persist a registry snapshot missing entries a stored encounter needs;
    -- a prune between an intern and its insert would drop the pool entry the
    -- encounter is about to reference. Everything here is CPU-bound, so a
    -- queued fiber is reordered behind the holder rather than stalled.
    writeMutex = LibEffect.Semaphore.New(1),
}

BattleScrolls.storage = storage

storage.defaults = {
    version = 1,
    history = {},
    sharedSetups = {},
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
        recordInAdventureZone = false, -- record fights in adventure zones (overrides zone type when enabled)
        recordInFights = { boss = true, trash = true, player = true, dummy = true }, -- set of fight types to record
        effectTrackingEnabled = false, -- disabled by default until onboarding
        trackPlayerBuffs = true, -- track buffs on player
        trackPlayerDebuffs = true, -- track debuffs on player
        trackGroupBuffs = true, -- track buffs on group members
        trackBossDebuffs = true, -- track debuffs on bosses
        effectReconciliationPreset = "normal", -- Effect reconciliation precision preset
        storageSizePreset = "medium", -- Storage size preset key
        favoriteEffects = {}, -- Favorite effects keyed by abilityId (account-wide)
        hasCompletedOnboarding = false, -- whether user has completed initial setup
    }
}

-- History size presets, in MiB of estimated gauge cost (storage/sizemodel.lua).
-- Reference sizes: dungeon ~0.15 MiB, trial run ~0.3 MiB, a night of prog ~1 MiB.
-- ESO addon pool: 100 MiB for all addons together, warning popup at 70.
storage.sizePresets = {
    xs = { key = "xs", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XS", memoryMiB = 5 },
    small = { key = "small", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_SMALL", memoryMiB = 8 },
    medium = { key = "medium", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_MEDIUM", memoryMiB = 12 },
    large = { key = "large", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_LARGE", memoryMiB = 18 },
    xl = { key = "xl", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XL", memoryMiB = 25 },
    caution = { key = "caution", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_CAUTION", memoryMiB = 35 },
    yolo = { key = "yolo", labelStringId = "BATTLESCROLLS_SETTINGS_STORAGE_SIZE_YOLO", memoryMiB = 50 },
}

-- Ordered list of preset keys for UI
storage.sizePresetOrder = { "xs", "small", "medium", "large", "xl", "caution", "yolo" }

-- Async speed presets (LibAsync stall threshold in FPS)
-- Lower FPS = more aggressive processing = faster but may cause stutters
-- Higher FPS = gentler processing = smoother but slower
-- Note: "smooth" at 30 FPS may cause encounters to fail loading in Journal
storage.asyncSpeedPresets = {
    performance = { key = "performance", fps = 15 },
    smooth = { key = "smooth", fps = 30 },
}
storage.asyncSpeedPresetOrder = { "performance", "smooth" }

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

---Sets the LibAsync stall threshold (applied immediately)
---@param fps number The FPS threshold value
function storage:SetAsyncStallThreshold(fps)
    -- No-op when unchanged: LibAsync's slash handler prints to chat, so it
    -- must only run on an actual change
    if self:GetAsyncStallThreshold() == fps then
        return
    end
    -- Use LibAsync's slash command handler to apply the change immediately
    -- This updates both the saved var and the internal threshold
    if LibAsync and LibAsync.Slash then
        LibAsync:Slash("stall", fps)
    elseif AsyncSavedVars then
        -- Fallback: just set the saved var (will apply on next load)
        AsyncSavedVars.ASYNC_STALL_THRESHOLD = fps
    end
end

---Gets the current size preset configuration
---@return SizePreset preset The preset configuration table
function storage:GetCurrentSizePreset()
    local presetKey = self.savedVariables and self.savedVariables.settings and self.savedVariables.settings.storageSizePreset
    return self.sizePresets[presetKey] or self.sizePresets.medium
end

---History limit of the current preset in bytes
---@return number bytes
function storage:GetSizeLimitBytes()
    return self:GetCurrentSizePreset().memoryMiB * BattleScrolls.sizeModel.MIB
end

---Gets the estimated gauge cost of an instance in bytes. The chunk bytes are
---cached on the instance; normal reads accept older model estimates.
-- FIXME: Temporary migration-dependent cache policy. Restoring version-based
-- invalidation here lets synchronous EstimateSavedSize/GetLockedInstancesSize
-- walk the whole history and exceed ESO's 1000ms continuous-run allowance,
-- shutting off the addon. Migration refreshes estimates with per-instance
-- yields, but its completion flag means future model changes need an explicit
-- paced refresh. Missing instance caches, setup pools and other saved roots
-- still need bounded async measurement; this is not a general stall fix.
---@param instance Instance
---@param forceRefresh boolean|nil Recompute now; bulk callers must yield between instances
---@return number bytes Estimated gauge bytes
local function getInstanceSize(instance, forceRefresh)
    local sizeModel = BattleScrolls.sizeModel
    if forceRefresh or not instance._estimatedSize then
        instance._estimatedSize = sizeModel.measure(instance)
        instance._estimatedSizeV = sizeModel.VERSION
        BattleScrolls.gc:RequestGC() -- the walk generates a lot of garbage
    end
    return instance._estimatedSize * sizeModel.GAUGE_PER_CHUNK_BYTE
end

---Model bytes of a setup pool payload, cached on the payload with the model
---version; unlike instances, older payload caches are recomputed on access.
---Strings shared between payloads count once per payload, a small
---overstatement.
---@param payload OwnSetupPoolEntry|StoredSharedSetup
---@return number modelBytes
local function payloadModelBytes(payload)
    local sizeModel = BattleScrolls.sizeModel
    if not payload._estimatedSize or payload._estimatedSizeV ~= sizeModel.VERSION then
        payload._estimatedSize = sizeModel.measure(payload)
        payload._estimatedSizeV = sizeModel.VERSION
    end
    return payload._estimatedSize
end

---Model bytes of both setup pools, containers included
---@param sv StorageData
---@return number modelBytes
local function setupPoolsModelBytes(sv)
    local sizeModel = BattleScrolls.sizeModel
    local bytes = 0
    if sv.ownSetups then
        local count = 0
        for _, payload in pairs(sv.ownSetups) do
            bytes = bytes + payloadModelBytes(payload)
            count = count + 1
        end
        bytes = bytes + sizeModel.tableShell(count)
    end
    if sv.sharedSetups then
        local players = 0
        for _, byHash in pairs(sv.sharedSetups) do
            local count = 0
            for _, payload in pairs(byHash) do
                bytes = bytes + payloadModelBytes(payload)
                count = count + 1
            end
            bytes = bytes + sizeModel.tableShell(count)
            players = players + 1
        end
        bytes = bytes + sizeModel.tableShell(players)
    end
    return bytes
end

-- Model bytes of everything else the saved global loads, measured once per
-- session: settings, indexes and flags of this world, and any other world's
-- data in the same file. Only settings change it during a session.
local otherModelBytes = nil

---@param sv StorageData
---@return number modelBytes
local function otherRootsModelBytes(sv)
    if otherModelBytes then
        return otherModelBytes
    end
    local root = rawget(_G, "BattleScrollsSavedVariables")
    if type(root) ~= "table" then
        otherModelBytes = 0
        return 0
    end
    -- Exclude what history and the pools count for themselves
    local visited = { [sv.history] = true }
    if sv.ownSetups then visited[sv.ownSetups] = true end
    if sv.sharedSetups then visited[sv.sharedSetups] = true end
    otherModelBytes = BattleScrolls.sizeModel.measure(root, visited)
    return otherModelBytes
end

function storage:Initialize()
    self.savedVariables = ZO_SavedVars:NewAccountWide("BattleScrollsSavedVariables", 4, nil, self.defaults, GetWorldName())
end

---PushInstance adds an instance to the history, cleaning up old entries if necessary and assigning it a unique index
---@param instance Instance The instance to add
function storage:PushInstance(instance)
    -- Initialize high-water mark from existing history if not yet set (handles migration)
    if not self.savedVariables.nextInstanceIndex then
        local maxIndex = 0
        for _, inst in ipairs(self.savedVariables.history) do
            if inst.index and inst.index > maxIndex then
                maxIndex = inst.index
            end
        end
        self.savedVariables.nextInstanceIndex = maxIndex + 1
    end

    instance.index = self.savedVariables.nextInstanceIndex
    self.savedVariables.nextInstanceIndex = self.savedVariables.nextInstanceIndex + 1

    table.insert(self.savedVariables.history, instance)
end

---@class SetupReferences
---@field own table<number, boolean> Own-pool hashes referenced
---@field shared table<string, table<number, boolean>> Shared-pool hashes referenced, by display name

---Adds the setup pool references an encounter holds: its own setup hash and
---the (display name, hash) pairs of its shared entries, binary (v17+) or plain.
---@param encounter CompactEncounter
---@param refs SetupReferences
local function collectSetupReferences(encounter, refs)
    if encounter._setupHash then
        refs.own[encounter._setupHash] = true
    end
    if encounter.sharedData then
        for _, entry in ipairs(encounter.sharedData) do
            local hash = entry.data and entry.data.setupHash
            if hash then
                refs.shared[entry.displayName] = refs.shared[entry.displayName] or {}
                refs.shared[entry.displayName][hash] = true
            end
        end
    end
    if encounter._shared then
        for _, entry in ipairs(encounter._shared) do
            if entry.h then
                refs.shared[entry.d] = refs.shared[entry.d] or {}
                refs.shared[entry.d][entry.h] = true
            end
        end
    end
end

---References held by every encounter in the history except the excluded ones
---@param history Instance[]|nil
---@param excluded table<CompactEncounter, boolean>|nil Encounters about to be removed
---@return SetupReferences
local function remainingSetupReferences(history, excluded)
    ---@type SetupReferences
    local refs = { own = {}, shared = {} }
    for _, instance in ipairs(history or {}) do
        for _, enc in ipairs(instance.encounters) do
            if not (excluded and excluded[enc]) then
                collectSetupReferences(enc, refs)
            end
        end
    end
    return refs
end

---Removes the setup pool entries no remaining encounter references. Runs
---after every deletion, manual or by the limit, so a delete frees what the
---dialog promised. Callers hold writeMutex (the cleanup task directly, manual
---deletes through PruneOrphanedSetupsAsync): an encounter still encoding has
---interned its setup but does not reference it from the history yet.
function storage:PruneOrphanedSetups()
    local sv = self.savedVariables
    local refs = remainingSetupReferences(sv.history)
    local shared = sv.sharedSetups
    if shared then
        for displayName, hashMap in pairs(shared) do
            local refHashes = refs.shared[displayName]
            if not refHashes then
                shared[displayName] = nil
            else
                for hash in pairs(hashMap) do
                    if not refHashes[hash] then
                        hashMap[hash] = nil
                    end
                end
                if not next(hashMap) then
                    shared[displayName] = nil
                end
            end
        end
    end
    local own = sv.ownSetups
    if own then
        for hash in pairs(own) do
            if not refs.own[hash] then
                own[hash] = nil
            end
        end
    end
end

---Prunes once the write mutex is free: at once when nothing is encoding,
---otherwise after the in-flight finalize or migration commit has put its
---encounters in the history
function storage:PruneOrphanedSetupsAsync()
    self.writeMutex:WithPermit(LibEffect.Async(function()
        self:PruneOrphanedSetups()
    end)):Run()
end

---Gauge bytes of the setup pool entries that only the given encounters
---reference, which deleting them lets PruneOrphanedSetups release
---@param encounters CompactEncounter[]
---@return number bytes
function storage:EstimateOrphanedSetupBytes(encounters)
    local sv = self.savedVariables
    ---@type table<CompactEncounter, boolean>
    local excluded = {}
    ---@type SetupReferences
    local wanted = { own = {}, shared = {} }
    for _, enc in ipairs(encounters) do
        excluded[enc] = true
        collectSetupReferences(enc, wanted)
    end
    local kept = remainingSetupReferences(sv.history, excluded)
    local bytes = 0
    local own = sv.ownSetups
    if own then
        for hash in pairs(wanted.own) do
            if own[hash] and not kept.own[hash] then
                bytes = bytes + payloadModelBytes(own[hash])
            end
        end
    end
    local shared = sv.sharedSetups
    if shared then
        for displayName, hashes in pairs(wanted.shared) do
            local pool, keptHashes = shared[displayName], kept.shared[displayName]
            if pool then
                for hash in pairs(hashes) do
                    if pool[hash] and not (keptHashes and keptHashes[hash]) then
                        bytes = bytes + payloadModelBytes(pool[hash])
                    end
                end
            end
        end
    end
    return bytes * BattleScrolls.sizeModel.GAUGE_PER_CHUNK_BYTE
end

---Async version of CleanupIfNecessary
---Cancels any previous cleanup task and starts a new one
function storage:CleanupIfNecessaryAsync()
    if self.cleanupTask then
        self.cleanupTask:Cancel()
        self.cleanupTask = nil
    end

    local byteLimit = self:GetSizeLimitBytes()
    local history = self.savedVariables.history

    if #history == 0 then
        return
    end

    self.cleanupTask = self.writeMutex:WithPermit(LibEffect.Async(function()
        -- Sum sizes (yields per instance); the setup pools and the other saved
        -- roots count against the limit too, but only instances are evicted.
        -- Setups orphaned by an eviction are pruned below, a bonus the
        -- selection does not rely on.
        local instanceSizes = {}
        local currentBytes = 0
        for i, instance in ipairs(history) do
            local size = getInstanceSize(instance)
            instanceSizes[i] = size
            currentBytes = currentBytes + size
            LibEffect.YieldWithGC():Await()
        end
        local factor = BattleScrolls.sizeModel.GAUGE_PER_CHUNK_BYTE
        currentBytes = currentBytes + (setupPoolsModelBytes(self.savedVariables) + otherRootsModelBytes(self.savedVariables)) * factor
        LibEffect.YieldWithGC():Await()

        -- Check if cleanup needed
        if currentBytes <= byteLimit or #history <= 1 then
            return
        end

        -- Calculate which instances to remove (skip locked instances)
        local excess = currentBytes - byteLimit
        local removed = 0
        local indicesToRemove = {}

        for i = 1, #history - 1 do
            if not history[i].locked then
                removed = removed + instanceSizes[i]
                table.insert(indicesToRemove, i)
                if removed >= excess then
                    break
                end
            end
        end

        -- Remove in reverse order to maintain correct indices
        if #indicesToRemove > 0 then
            for i = #indicesToRemove, 1, -1 do
                table.remove(history, indicesToRemove[i])
            end
            -- GC after removing instances (big cleanup done, nothing important happening)
            BattleScrolls.gc:RequestGC(2)
            -- BattleScrolls.log.Info(string.format("Cleaned up %d old instance(s)",
            --     #indicesToRemove))

            self:PruneOrphanedSetups()
        end
    end)):Ensure(function()
        self.cleanupTask = nil
    end):Run()
end

---@class SavedSizeEstimate
---@field totalBytes number Gauge bytes of everything the saved file loads: history, setup pools and the other roots
---@field historyBytes number History instances
---@field lockedBytes number The locked instances' share of historyBytes
---@field setupBytes number Own and shared setup pools
---@field otherBytes number Everything else in the saved global: settings, indexes, other worlds' data
---@field encounterCount number
---@field instanceCount number

---Estimates the gauge cost of everything the saved file loads
---(storage/sizemodel.lua): history from cached per-instance sizes, the setup
---pools from a session cache per payload, and the other saved roots measured
---once per session. The history limit compares against totalBytes.
---@return SavedSizeEstimate
function storage:EstimateSavedSize()
    ---@type SavedSizeEstimate
    local estimate = {
        totalBytes = 0, historyBytes = 0, lockedBytes = 0, setupBytes = 0, otherBytes = 0,
        encounterCount = 0, instanceCount = 0,
    }
    local sv = self.savedVariables
    if not sv then
        return estimate
    end
    local history = sv.history
    if history then
        for _, instance in ipairs(history) do
            local bytes = getInstanceSize(instance)
            estimate.historyBytes = estimate.historyBytes + bytes
            if instance.locked then
                estimate.lockedBytes = estimate.lockedBytes + bytes
            end
            estimate.encounterCount = estimate.encounterCount + #instance.encounters
        end
        estimate.instanceCount = #history
    end
    local factor = BattleScrolls.sizeModel.GAUGE_PER_CHUNK_BYTE
    estimate.setupBytes = setupPoolsModelBytes(sv) * factor
    estimate.otherBytes = otherRootsModelBytes(sv) * factor
    estimate.totalBytes = estimate.historyBytes + estimate.setupBytes + estimate.otherBytes
    return estimate
end

---Estimates the gauge cost of an encounter in bytes
---@param encounter CompactEncounter|Encounter
---@return number bytes Estimated memory in bytes
function storage:EstimateEncounterSize(encounter)
    return BattleScrolls.sizeModel.gaugeBytes(encounter)
end

---Estimates the gauge cost of an arbitrary stored value in bytes
---(pool entries, individual fields; same model as EstimateEncounterSize)
---@param value any
---@return number bytes Estimated memory in bytes
function storage:EstimateValueMemory(value)
    return BattleScrolls.sizeModel.gaugeBytes(value)
end

---Gets the estimated size of an instance in bytes
---@param instance Instance
---@param forceRefresh boolean|nil Recompute now; bulk callers must yield between instances
---@return number bytes Estimated memory in bytes
function storage:EstimateInstanceSize(instance, forceRefresh)
    return getInstanceSize(instance, forceRefresh)
end

---Gets the total size of all locked instances
---@return number bytes Total size of locked instances in bytes
function storage:GetLockedInstancesSize()
    local history = self.savedVariables.history
    local totalSize = 0
    for _, instance in ipairs(history) do
        if instance.locked then
            totalSize = totalSize + getInstanceSize(instance)
        end
    end
    return totalSize
end

---Checks if an instance can be locked without exceeding storage limit
---@param instanceIndex number The unique index of the instance to check
---@return boolean canLock True if the instance can be locked
function storage:CanLockInstance(instanceIndex)
    local history = self.savedVariables.history
    if #history == 0 then
        return false
    end

    local byteLimit = self:GetSizeLimitBytes()

    -- Find the instance
    local targetInstance = nil
    for _, instance in ipairs(history) do
        if instance.index == instanceIndex then
            targetInstance = instance
            break
        end
    end

    if not targetInstance then
        return false
    end

    -- If already locked, it can stay locked
    if targetInstance.locked then
        return true
    end

    -- Calculate protected size: locked instances + this instance
    local lockedSize = self:GetLockedInstancesSize()
    local thisInstanceSize = getInstanceSize(targetInstance)

    local protectedSize = lockedSize + thisInstanceSize
    return protectedSize <= byteLimit
end

---Locks an instance to prevent automatic cleanup
---@param instanceIndex number The unique index of the instance
---@return boolean success True if instance was locked
function storage:LockInstance(instanceIndex)
    if not self:CanLockInstance(instanceIndex) then
        return false
    end

    local history = self.savedVariables.history
    for _, instance in ipairs(history) do
        if instance.index == instanceIndex then
            instance.locked = true
        end
    end
    return true
end

---Unlocks an instance to allow automatic cleanup
---@param instanceIndex number The unique index of the instance
function storage:UnlockInstance(instanceIndex)
    local history = self.savedVariables.history
    for _, instance in ipairs(history) do
        if instance.index == instanceIndex then
            instance.locked = nil  -- Use nil to save storage space
        end
    end
end

---Deletes an instance from history by its unique index
---@param instanceIndex number The unique index of the instance
---@return boolean success True if instance was found and deleted
function storage:DeleteInstance(instanceIndex)
    local history = self.savedVariables.history
    for i, instance in ipairs(history) do
        if instance.index == instanceIndex then
            -- Notify scribe in case this is the active instance
            if BattleScrolls.scribe then
                BattleScrolls.scribe:OnInstanceRemoved(instance)
            end
            table.remove(history, i)
            self:PruneOrphanedSetupsAsync()
            BattleScrolls.gc:RequestGC(2)
            return true
        end
    end
    return false
end

---Deletes an encounter from an instance by reference
---@param instance Instance The instance containing the encounter
---@param encounter CompactEncounter The encounter object to delete (compared by reference)
---@return boolean success True if encounter was found and deleted
---@return boolean instanceDeleted True if instance was also deleted (was last encounter)
function storage:DeleteEncounter(instance, encounter)
    instance._estimatedSize = nil  -- Invalidate cached size
    for i, enc in ipairs(instance.encounters) do
        if enc == encounter then  -- Direct reference comparison
            table.remove(instance.encounters, i)
            BattleScrolls.gc:RequestGC(2)
            if #instance.encounters == 0 then
                -- Notify scribe in case this is the active instance
                if BattleScrolls.scribe then
                    BattleScrolls.scribe:OnInstanceRemoved(instance)
                end
                -- Delete the now-empty instance
                local history = self.savedVariables.history
                for j, inst in ipairs(history) do
                    if inst == instance then
                        table.remove(history, j)
                        break
                    end
                end
                self:PruneOrphanedSetupsAsync()
                return true, true
            end
            self:PruneOrphanedSetupsAsync()
            return true, false
        end
    end
    return false, false
end

-- =============================================================================
-- PUBLIC API: Encode/Decode/Check Functions
-- =============================================================================

---Encodes an encounter to binary format for storage asynchronously
---Returns an Effect that resolves to the encoded encounter.
---@param encounter Encounter
---@param setupPooled boolean|nil When true the setup build is pool-referenced (caller sets _setupHash on the result); the encounter keeps only the food uptime overlay
---@param registry EncounterRegistry The instance's ability/name registry
---@return Effect
function storage.EncodeEncounterAsync(encounter, setupPooled, registry)
    return BattleScrolls.binaryStorage.encodeEncounterAsync(encounter, setupPooled, registry)
end

---Interns the player's own setup in the ownSetups pool, keyed by the 16-bit
---setup hash. Returns true when the encounter can reference the pool entry;
---false on a hash collision with a different setup (caller keeps it inline).
---
---Called under writeMutex, which the caller keeps until the referencing
---encounter is in the history; the prune takes the same mutex, so the entry
---cannot be removed while the encode yields in between.
---@param hash number
---@param setup PlayerSetup
---@return boolean pooled
function storage:InternOwnSetup(hash, setup)
    local pool = self.savedVariables.ownSetups
    if not pool then
        pool = {}
        self.savedVariables.ownSetups = pool
    end
    local chunks, version = BattleScrolls.binaryStorage.encodeSetupStandalone(
        BattleScrolls.binaryStorage.buildPoolableSetup(setup))
    local existing = pool[hash]
    if existing then
        if #existing.c ~= #chunks then
            return false
        end
        for i = 1, #chunks do
            if existing.c[i] ~= chunks[i] then
                return false
            end
        end
        return true
    end
    pool[hash] = { v = version, c = chunks }
    return true
end

---Whether the instance table is currently in the history (by reference)
---@param instance Instance
---@return boolean
function storage:IsInHistory(instance)
    for _, inst in ipairs(self.savedVariables.history) do
        if inst == instance then
            return true
        end
    end
    return false
end

---Resolves a pooled own setup by hash.
---@param hash number
---@return PlayerSetup|nil
function storage:GetOwnSetup(hash)
    local pool = self.savedVariables and self.savedVariables.ownSetups
    local entry = pool and pool[hash]
    if not entry then
        return nil
    end
    return BattleScrolls.binaryStorage.decodeSetupStandalone(entry.c, entry.v)
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
---@field hasGroupData boolean Encounter has shared group member data

---Per-instance decoded registry cache. Weak keys: entries die with their
---instances. The live instance's entry is registered by scribe and shares the
---append-only arrays by reference, so it stays current across finalizes.
---@type table<Instance, RegistryArrays>
local registryCache = setmetatable({}, { __mode = "k" })

---@type RegistryArrays
local EMPTY_REGISTRY = { abilityIds = {}, names = {} }

---Registers the live registry arrays for an instance (called by scribe after
---finalize so decodes of the active instance skip the _instanceData decode).
---@param instance Instance
---@param registry RegistryArrays
function storage:CacheInstanceRegistry(instance, registry)
    registryCache[instance] = registry
end

---Resolves the ability/name registry arrays for an instance's encounters.
---@param instance Instance
---@return Effect Effect that resolves to RegistryArrays
function storage:GetInstanceRegistryAsync(instance)
    return LibEffect.Async(function()
        local cached = registryCache[instance]
        if cached then
            return cached
        end
        if (instance._instanceDataVersion or 0) >= 17 and instance._instanceData then
            local fields = BattleScrolls.binaryStorage.decodeInstanceFieldsAsync(instance):Await()
            ---@type RegistryArrays
            local registry = { abilityIds = fields[3] or {}, names = fields[4] or {} }
            registryCache[instance] = registry
            return registry
        end
        return EMPTY_REGISTRY
    end)
end

---Decodes a binary encounter to verbose format asynchronously.
---Returns an Effect that resolves to the decoded encounter.
---Yields per major section to prevent frame spikes.
---Caching is managed by the caller (UI stores in self.decodedEncounter).
---@param encounter CompactEncounter The binary-encoded encounter
---@param instance Instance The instance owning the encounter (registry source for v17+)
---@return Effect Effect that resolves to Encounter
function storage.DecodeEncounterAsync(encounter, instance)
    return LibEffect.Async(function()
        ---@type RegistryArrays|nil
        local registry
        if (encounter._v or 0) >= 17 then
            registry = storage:GetInstanceRegistryAsync(instance):Await()
        end
        return BattleScrolls.binaryStorage.decodeEncounterAsync(encounter, registry):Await()
    end)
end

-- =============================================================================
-- INSTANCE-LEVEL FIELD ENCODING/DECODING
-- =============================================================================

---Decoded instance fields tuple: [1] = abilityInfo, [2] = unitNames (empty,
---stored at encounter level), [3] = ability id registry, [4] = name registry
---@alias DecodedInstanceFields { [1]: table<number, AbilityInfo>, [2]: table<number, string>, [3]: number[], [4]: string[] }

---Decodes abilityInfo for an instance asynchronously.
---Returns an Effect that resolves to { abilityInfo, {} }.
---Note: unitNames are stored at encounter level, not instance level.
---@param instance Instance
---@return Effect Effect that resolves to DecodedInstanceFields
function storage.DecodeInstanceFieldsAsync(instance)
    return BattleScrolls.binaryStorage.decodeInstanceFieldsAsync(instance)
end

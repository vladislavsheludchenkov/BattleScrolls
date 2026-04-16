-----------------------------------------------------------
-- Pivot Builder Types
-- Type definitions and constants for the pivot query system
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.journal = BattleScrolls.journal or {}
BattleScrolls.journal.pivot = {}

local pivot = BattleScrolls.journal.pivot

-------------------------
-- Domains
-------------------------
pivot.Domain = {
    DAMAGE = "damage",
    DAMAGE_IN = "damageIn",
    HEALING_OUT = "healingOut",
    HEALING_IN = "healingIn",
    EFFECTS_SELF = "effectsSelf",
    EFFECTS_BOSS = "effectsBoss",
    EFFECTS_GROUP = "effectsGroup",
    GROUP = "group",
    OVERVIEW = "overview",
}

-------------------------
-- Dimension IDs
-------------------------
pivot.Dimension = {
    ABILITY = "ability",
    TARGET = "target",
    SOURCE = "source",
    BOSS = "boss",
    DAMAGE_TYPE = "damageType",
    DELIVERY = "delivery",
    AOE_ST = "aoeSt",
    BUFF_DEBUFF = "buffDebuff",
    GROUP_MEMBER = "groupMember",
    ROLE = "role",
    ENCOUNTER = "encounter",
    INSTANCE = "instance",
}

-------------------------
-- Metric IDs
-------------------------
pivot.Metric = {
    -- Damage
    TOTAL_DAMAGE = "totalDamage",
    DPS = "dps",
    CRIT_PERCENT = "critPercent",
    HIT_COUNT = "hitCount",
    MAX_HIT = "maxHit",
    MIN_HIT = "minHit",
    AVG_HIT = "avgHit",

    -- Healing
    EFFECTIVE_HEALING = "effectiveHealing",
    RAW_HEALING = "rawHealing",
    EFFECTIVE_HPS = "effectiveHps",
    RAW_HPS = "rawHps",
    OVERHEAL_PERCENT = "overhealPercent",
    HEAL_CRIT_PERCENT = "healCritPercent",
    HEAL_HIT_COUNT = "healHitCount",
    MAX_HEAL = "maxHeal",
    AVG_HEAL = "avgHeal",

    -- Effects
    UPTIME_PERCENT = "uptimePercent",
    PLAYER_UPTIME_PERCENT = "playerUptimePercent",
    APPLICATIONS = "applications",
    MAX_STACKS_TIME_PERCENT = "maxStacksTimePercent",

    -- Group (from SharedEncounterData)
    GROUP_DPS = "groupDps",
    GROUP_BOSS_DPS = "groupBossDps",
    GROUP_TOTAL_DAMAGE = "groupTotalDamage",
    GROUP_CRIT_PERCENT = "groupCritPercent",
    GROUP_DOT_PERCENT = "groupDotPercent",
    GROUP_AOE_PERCENT = "groupAoePercent",
    GROUP_MAX_HIT = "groupMaxHit",
    GROUP_DTPS = "groupDtps",
    GROUP_RAW_HPS_OUT = "groupRawHpsOut",
    GROUP_EFFECTIVE_HPS_OUT = "groupEffectiveHpsOut",
    GROUP_ALIVE_PERCENT = "groupAlivePercent",
    GROUP_DEATH_COUNT = "groupDeathCount",

    -- Activity / Weaving
    AVG_WEAVE_TIME = "avgWeaveTime",
    TIME_LOST = "timeLost",
    LIGHT_ATTACKS_PER_SEC = "lightAttacksPerSec",
    WEAVING_ERRORS = "weavingErrors",
    DOUBLE_LA_ERRORS = "doubleLaErrors",

    -- Overview
    BOSS_DPS = "bossDps",
    BOSS_DAMAGE = "bossDamage",
    DTPS = "dtps",
    DAMAGE_TAKEN = "damageTaken",
    RAW_HPS_OUT = "rawHpsOut",
    EFFECTIVE_HPS_OUT = "effectiveHpsOut",
    RAW_HPS_IN = "rawHpsIn",
    EFFECTIVE_HPS_IN = "effectiveHpsIn",
    DURATION = "duration",
    DEATH_COUNT = "deathCount",
}

-------------------------
-- Column Mode
-------------------------
pivot.ColumnMode = {
    METRICS = "metrics",  -- columns are selected metrics (multi-select values)
    -- Any dimension ID can also be a column mode (single-select value)
}

-------------------------
-- Target Filter Modes (Damage domain only)
-------------------------
pivot.TargetMode = {
    ALL = "all",
    BOSSES = "bosses",
}

-------------------------
-- Aggregation Functions
-------------------------
pivot.Aggregation = {
    SUM = "sum",
    AVG = "avg",
    MAX = "max",
    MIN = "min",
}

-------------------------
-- Instance Scope Modes
-------------------------
pivot.InstanceMode = {
    EVERYTHING = "everything",
    INSTANCED = "instanced",
    OVERLAND = "overland",
    HOUSES = "houses",
    PVP = "pvp",
    ZONES = "zones",
    SPECIFIC = "specific",
}

-------------------------
-- Time Filter Modes
-------------------------
pivot.TimeMode = {
    ALL = "all",
    CUSTOM = "custom",
}

-------------------------
-- Encounter Category
-------------------------
pivot.EncounterCategory = {
    ALL = "all",
    BOSS = "boss",
    TRASH = "trash",
    PLAYER = "player",
    DUMMY = "dummy",
    SPECIFIC = "specific",
    BOSS_NAMES = "bossNames",
}

-------------------------
-- Pivot Sub-State (config vs results)
-------------------------
pivot.SubState = {
    CONFIG = 1,
    RESULTS = 2,
    LOADING = 3,
}

-------------------------
-- Type Definitions
-------------------------

---@class PivotScope
---@field instanceMode string             -- pivot.InstanceMode value
---@field instanceZones table<string, boolean>|nil  -- for "zones" mode: zone name → true
---@field instanceIds table<number, boolean>|nil    -- for "specific" mode: instance.index → true
---@field timeMode string                 -- pivot.TimeMode value
---@field timeFrom number|nil             -- unix epoch, for "custom" mode
---@field timeTo number|nil               -- unix epoch, for "custom" mode
---@field encounterCategory string        -- pivot.EncounterCategory value
---@field encounterIds table<number, boolean>|nil  -- for "specific" encounters: timestampS → true
---@field encounterBosses table<string, boolean>|nil  -- boss name → true (OR filter)

---@class PivotQuery
---@field scope PivotScope
---@field domain string                   -- pivot.Domain value
---@field targetMode string|nil           -- pivot.TargetMode value (DAMAGE domain only, nil = ALL)
---@field rowDimension string             -- pivot.Dimension value
---@field columnMode string               -- "metrics" or a pivot.Dimension value
---@field metrics string[]                -- pivot.Metric values (1+ if metrics mode, 1 if dimension mode)
---@field aggregation string|nil          -- pivot.Aggregation value, nil when not needed
---@field filters table<string, table<string, boolean>>  -- dimensionId → selected values

---@class PivotResultRow
---@field key string                      -- row dimension display value
---@field sortKey string|number           -- for stable sorting (e.g., numeric value or lowercase name)
---@field values table<string, number>    -- column key → numeric value
---@field instanceIndex number|nil        -- storage index (set when row dimension is encounter or instance)
---@field encounterIndex number|nil       -- encounter index within instance (set when row dimension is encounter)

---@class PivotResult
---@field rows PivotResultRow[]
---@field columns string[]                -- ordered column keys
---@field columnLabels table<string, string>  -- column key → display label
---@field rowDimensionLabel string        -- display name of the row dimension
---@field encounterCount number           -- how many encounters were processed
---@field query PivotQuery                -- the query that produced this result
---@field rowsCapped boolean|nil          -- true if rows were dropped due to MAX_RESULT_ROWS limit
---@field columnsCapped boolean|nil       -- true if columns were dropped due to MAX_VALUE_COLUMNS limit

---@class ScopedEncounter
---@field instance InstanceStorage
---@field instanceIndex number
---@field encounter CompactEncounter
---@field encounterIndex number

---@class DimensionExtractor
---@field id string
---@field displayName string
---@field domains table<string, boolean>  -- domain → true
---@field extract fun(decoded: DecodedEncounter, abilityInfo: table<number, AbilityInfo>, domain: string, unitNames: table<number, string>|nil): table<string, any[]>

---@class GroupDimensionExtractor
---@field id string
---@field displayName string
---@field extract fun(entry: SharedDataEntry, encounter: CompactEncounter, instance: InstanceStorage): string|string[]|nil

---@class MetricExtractor
---@field id string
---@field displayName string
---@field domains table<string, boolean>  -- domain → true
---@field extract fun(breakdown: any, durationS: number, aliveTimeS: number|nil): number
---@field aggregate fun(breakdowns: any[], durationS: number, aliveTimeS: number|nil, aggregation: string|nil, aliveTimeLookup: table|nil): number
---@field format fun(value: number): string
---@field defaultAggregation string       -- pivot.Aggregation value
---@field higherIsBetter boolean          -- default sort direction

---@class GroupMetricExtractor
---@field id string
---@field displayName string
---@field extract fun(entry: SharedDataEntry, encounter: CompactEncounter): number
---@field bossExtract (fun(entry: SharedDataEntry, encounter: CompactEncounter, bossName: string): number)|nil  -- per-boss extract by display name; nil means metric not available for Boss dimension
---@field format fun(value: number): string
---@field defaultAggregation string
---@field higherIsBetter boolean

-------------------------
-- Domain → Dimension/Metric Compatibility
-------------------------

---Dimensions available per domain
---@type table<string, string[]>
pivot.DomainDimensions = {
    [pivot.Domain.DAMAGE] = {
        pivot.Dimension.ABILITY,
        pivot.Dimension.TARGET,
        pivot.Dimension.SOURCE,
        pivot.Dimension.BOSS,
        pivot.Dimension.DAMAGE_TYPE,
        pivot.Dimension.DELIVERY,
        pivot.Dimension.AOE_ST,
        pivot.Dimension.ENCOUNTER,
        pivot.Dimension.INSTANCE,
    },
    [pivot.Domain.DAMAGE_IN] = {
        pivot.Dimension.ABILITY,
        pivot.Dimension.SOURCE,
        pivot.Dimension.DAMAGE_TYPE,
        pivot.Dimension.ENCOUNTER,
        pivot.Dimension.INSTANCE,
    },
    [pivot.Domain.HEALING_OUT] = {
        pivot.Dimension.ABILITY,
        pivot.Dimension.TARGET,
        pivot.Dimension.ENCOUNTER,
        pivot.Dimension.INSTANCE,
    },
    [pivot.Domain.HEALING_IN] = {
        pivot.Dimension.ABILITY,
        pivot.Dimension.SOURCE,
        pivot.Dimension.ENCOUNTER,
        pivot.Dimension.INSTANCE,
    },
    [pivot.Domain.EFFECTS_SELF] = {
        pivot.Dimension.ABILITY,
        pivot.Dimension.BUFF_DEBUFF,
        pivot.Dimension.ENCOUNTER,
        pivot.Dimension.INSTANCE,
    },
    [pivot.Domain.EFFECTS_BOSS] = {
        pivot.Dimension.ABILITY,
        pivot.Dimension.BOSS,
        pivot.Dimension.ENCOUNTER,
        pivot.Dimension.INSTANCE,
    },
    [pivot.Domain.EFFECTS_GROUP] = {
        pivot.Dimension.ABILITY,
        pivot.Dimension.GROUP_MEMBER,
        pivot.Dimension.ENCOUNTER,
        pivot.Dimension.INSTANCE,
    },
    [pivot.Domain.GROUP] = {
        pivot.Dimension.GROUP_MEMBER,
        pivot.Dimension.ROLE,
        pivot.Dimension.BOSS,
        pivot.Dimension.ENCOUNTER,
        pivot.Dimension.INSTANCE,
    },
    [pivot.Domain.OVERVIEW] = {
        pivot.Dimension.ENCOUNTER,
        pivot.Dimension.INSTANCE,
    },
}

---Metrics available per domain
---@type table<string, string[]>
pivot.DomainMetrics = {
    [pivot.Domain.DAMAGE] = {
        pivot.Metric.DPS,
        pivot.Metric.TOTAL_DAMAGE,
        pivot.Metric.CRIT_PERCENT,
        pivot.Metric.HIT_COUNT,
        pivot.Metric.AVG_HIT,
        pivot.Metric.MAX_HIT,
        pivot.Metric.MIN_HIT,
    },
    [pivot.Domain.DAMAGE_IN] = {
        pivot.Metric.DPS,
        pivot.Metric.TOTAL_DAMAGE,
        pivot.Metric.CRIT_PERCENT,
        pivot.Metric.HIT_COUNT,
        pivot.Metric.AVG_HIT,
        pivot.Metric.MAX_HIT,
        pivot.Metric.MIN_HIT,
    },
    [pivot.Domain.HEALING_OUT] = {
        pivot.Metric.RAW_HPS,
        pivot.Metric.RAW_HEALING,
        pivot.Metric.EFFECTIVE_HPS,
        pivot.Metric.EFFECTIVE_HEALING,
        pivot.Metric.OVERHEAL_PERCENT,
        pivot.Metric.HEAL_CRIT_PERCENT,
        pivot.Metric.HEAL_HIT_COUNT,
        pivot.Metric.AVG_HEAL,
        pivot.Metric.MAX_HEAL,
    },
    [pivot.Domain.HEALING_IN] = {
        pivot.Metric.RAW_HPS,
        pivot.Metric.RAW_HEALING,
        pivot.Metric.EFFECTIVE_HPS,
        pivot.Metric.EFFECTIVE_HEALING,
        pivot.Metric.OVERHEAL_PERCENT,
        pivot.Metric.HEAL_CRIT_PERCENT,
        pivot.Metric.HEAL_HIT_COUNT,
        pivot.Metric.AVG_HEAL,
        pivot.Metric.MAX_HEAL,
    },
    [pivot.Domain.EFFECTS_SELF] = {
        pivot.Metric.UPTIME_PERCENT,
        pivot.Metric.PLAYER_UPTIME_PERCENT,
        pivot.Metric.APPLICATIONS,
        pivot.Metric.MAX_STACKS_TIME_PERCENT,
    },
    [pivot.Domain.EFFECTS_BOSS] = {
        pivot.Metric.UPTIME_PERCENT,
        pivot.Metric.PLAYER_UPTIME_PERCENT,
        pivot.Metric.APPLICATIONS,
        pivot.Metric.MAX_STACKS_TIME_PERCENT,
    },
    [pivot.Domain.EFFECTS_GROUP] = {
        pivot.Metric.UPTIME_PERCENT,
        pivot.Metric.PLAYER_UPTIME_PERCENT,
        pivot.Metric.APPLICATIONS,
        pivot.Metric.MAX_STACKS_TIME_PERCENT,
    },
    [pivot.Domain.GROUP] = {
        pivot.Metric.GROUP_DPS,
        pivot.Metric.GROUP_BOSS_DPS,
        pivot.Metric.GROUP_TOTAL_DAMAGE,
        pivot.Metric.GROUP_CRIT_PERCENT,
        pivot.Metric.GROUP_DOT_PERCENT,
        pivot.Metric.GROUP_AOE_PERCENT,
        pivot.Metric.GROUP_MAX_HIT,
        pivot.Metric.GROUP_DTPS,
        pivot.Metric.GROUP_RAW_HPS_OUT,
        pivot.Metric.GROUP_EFFECTIVE_HPS_OUT,
        pivot.Metric.GROUP_ALIVE_PERCENT,
        pivot.Metric.GROUP_DEATH_COUNT,
        pivot.Metric.DURATION,
    },
    [pivot.Domain.OVERVIEW] = {
        pivot.Metric.BOSS_DPS,
        pivot.Metric.BOSS_DAMAGE,
        pivot.Metric.DPS,
        pivot.Metric.TOTAL_DAMAGE,
        pivot.Metric.CRIT_PERCENT,
        pivot.Metric.DTPS,
        pivot.Metric.DAMAGE_TAKEN,
        pivot.Metric.EFFECTIVE_HPS_OUT,
        pivot.Metric.RAW_HPS_OUT,
        pivot.Metric.EFFECTIVE_HPS_IN,
        pivot.Metric.RAW_HPS_IN,
        pivot.Metric.AVG_WEAVE_TIME,
        pivot.Metric.TIME_LOST,
        pivot.Metric.LIGHT_ATTACKS_PER_SEC,
        pivot.Metric.WEAVING_ERRORS,
        pivot.Metric.DOUBLE_LA_ERRORS,
        pivot.Metric.DURATION,
        pivot.Metric.DEATH_COUNT,
    },
}

-------------------------
-- Default Query
-------------------------

---@return PivotQuery
function pivot.defaultQuery()
    return {
        scope = {
            instanceMode = pivot.InstanceMode.EVERYTHING,
            instanceZones = nil,
            instanceIds = nil,
            timeMode = pivot.TimeMode.ALL,
            timeFrom = nil,
            timeTo = nil,
            encounterCategory = pivot.EncounterCategory.ALL,
            encounterIds = nil,
            encounterBosses = nil,
        },
        domain = pivot.Domain.DAMAGE,
        targetMode = nil,
        rowDimension = pivot.Dimension.ENCOUNTER,
        columnMode = pivot.ColumnMode.METRICS,
        metrics = { pivot.Metric.DPS, pivot.Metric.CRIT_PERCENT },
        aggregation = nil,
        filters = {},
    }
end

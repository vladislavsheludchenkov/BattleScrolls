-----------------------------------------------------------
-- Journal Types
-- Shared constants and type definitions for journal UI
--
-- Loaded first, before all other journal modules.
-- Other modules reference these via BattleScrolls.journal.*
-----------------------------------------------------------

---Decoded encounter is the fully expanded Encounter structure (not compact)
---@alias DecodedEncounter Encounter

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.journal = BattleScrolls.journal or {}
BattleScrolls.journal.renderers = {}
BattleScrolls.journal.controllers = {}

local journal = BattleScrolls.journal

-------------------------
-- Navigation Mode
-------------------------
journal.NavigationMode = {
    INSTANCES = 1,
    ENCOUNTERS = 2,
    STATS = 3,
    SETTINGS = 4,
}

-------------------------
-- Stats Tabs
-------------------------
journal.StatsTab = {
    OVERVIEW = 1,
    BOSS_DAMAGE_DONE = 2,
    DAMAGE_DONE = 3,
    DAMAGE_TAKEN = 4,
    HEALING_OUT = 5,
    SELF_HEALING = 6,
    HEALING_IN = 7,
    EFFECTS = 8,
    GROUP = 9,
}

-------------------------
-- Instance Filter Tabs
-------------------------
journal.InstanceTab = {
    ALL = 1,
    INSTANCED = 2,
    OVERLAND = 3,
    HOUSE = 4,
    PVP = 5,
}

-------------------------
-- Encounter Filter Tabs
-------------------------
journal.EncounterTab = {
    ALL = 1,
    BOSS = 2,
    TRASH = 3,
    PLAYER = 4,
    DUMMY = 5,
}

-------------------------
-- Filter Constants
-------------------------
journal.FilterConstants = {
    SELF_UNIT_ID = -1,           -- Special ID for self in healing filters
    SELF_DISPLAY_NAME = "__SELF__", -- Special key for self in effects filter
}

-------------------------
-- Damage Type Names (localized)
-------------------------
journal.DamageTypeNames = {
    [DAMAGE_TYPE_NONE] = GetString(BATTLESCROLLS_DAMAGE_TYPE_NONE),
    [DAMAGE_TYPE_GENERIC] = GetString(BATTLESCROLLS_DAMAGE_TYPE_GENERIC),
    [DAMAGE_TYPE_PHYSICAL] = GetString(BATTLESCROLLS_DAMAGE_TYPE_PHYSICAL),
    [DAMAGE_TYPE_FIRE] = GetString(BATTLESCROLLS_DAMAGE_TYPE_FIRE),
    [DAMAGE_TYPE_SHOCK] = GetString(BATTLESCROLLS_DAMAGE_TYPE_SHOCK),
    [DAMAGE_TYPE_OBLIVION] = GetString(BATTLESCROLLS_DAMAGE_TYPE_OBLIVION),
    [DAMAGE_TYPE_COLD] = GetString(BATTLESCROLLS_DAMAGE_TYPE_FROST),
    [DAMAGE_TYPE_EARTH] = GetString(BATTLESCROLLS_DAMAGE_TYPE_EARTH),
    [DAMAGE_TYPE_MAGIC] = GetString(BATTLESCROLLS_DAMAGE_TYPE_MAGIC),
    [DAMAGE_TYPE_DROWN] = GetString(BATTLESCROLLS_DAMAGE_TYPE_DROWN),
    [DAMAGE_TYPE_DISEASE] = GetString(BATTLESCROLLS_DAMAGE_TYPE_DISEASE),
    [DAMAGE_TYPE_POISON] = GetString(BATTLESCROLLS_DAMAGE_TYPE_POISON),
    [DAMAGE_TYPE_BLEED] = GetString(BATTLESCROLLS_DAMAGE_TYPE_BLEED),
}

-------------------------
-- Damage Type Icons
-------------------------
journal.DamageTypeIcons = {
    [DAMAGE_TYPE_PHYSICAL] = "EsoUI/Art/Icons/scribing_primary_physical.dds",
    [DAMAGE_TYPE_FIRE] = "EsoUI/Art/Icons/scribing_primary_flame.dds",
    [DAMAGE_TYPE_SHOCK] = "EsoUI/Art/Icons/scribing_primary_shock.dds",
    [DAMAGE_TYPE_COLD] = "EsoUI/Art/Icons/scribing_primary_frost.dds",
    [DAMAGE_TYPE_MAGIC] = "EsoUI/Art/Icons/scribing_primary_magicka.dds",
    [DAMAGE_TYPE_BLEED] = "EsoUI/Art/Icons/scribing_primary_bleeding.dds",
    [DAMAGE_TYPE_POISON] = "EsoUI/Art/Icons/scribing_primary_poison.dds",
    [DAMAGE_TYPE_DISEASE] = "EsoUI/Art/Icons/scribing_primary_disease.dds",
    [DAMAGE_TYPE_OBLIVION] = "EsoUI/Art/Icons/scribing_secondary_soulcollapse.dds",
    [DAMAGE_TYPE_EARTH] = "EsoUI/Art/Icons/death_recap_earth_ranged.dds",
}

-------------------------
-- Stat Icons
-------------------------
journal.StatIcons = {
    -- General
    DURATION = "EsoUI/Art/TreeIcons/Gamepad/gp_tutorial_idexIcon_timedActivities.dds",
    SUMMARY = "EsoUI/Art/TreeIcons/Gamepad/achievement_categoryicon_summary.dds",

    -- Damage
    DPS = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps.dds",
    DAMAGE = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_scoring.dds",
    DAMAGE_TAKEN = "EsoUI/Art/TreeIcons/Gamepad/gp_tutorial_idexIcon_synergy.dds",
    SHARE = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_groups.dds",

    -- Healing
    HEALING = "EsoUI/Art/Icons/scribing_primary_healing.dds",
    HPS = "EsoUI/Art/Icons/scribing_secondary_healovertime.dds",
    OVERHEAL = "EsoUI/Art/Icons/scribing_tertiary_vitality.dds",

    -- Direct vs DoT
    DIRECT = "EsoUI/Art/Icons/scribing_primary_stunned.dds",
    DIRECT_HEAL = "EsoUI/Art/Icons/scribing_primary_healing.dds",
    DOT = "EsoUI/Art/Icons/scribing_secondary_damageovertime.dds",
    HOT = "EsoUI/Art/Icons/scribing_secondary_healovertime.dds",

    -- AOE vs Single Target
    AOE = "EsoUI/Art/Icons/scribing_primary_multihit.dds",
    SINGLE_TARGET = "EsoUI/Art/Icons/scribing_tertiary_vulnerability.dds",

    -- Deaths
    DEATH = "EsoUI/Art/ZoneStories/completionTypeIcon_groupBoss.dds",

    -- Group/Target
    GROUP = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_currentGroup.dds",
    GROUP_DAMAGE = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_currentGroup.dds",
    GROUP_DPS = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_currentGroup.dds",
}

-------------------------
-- Tick Statistics
-------------------------
---@class CritStats
---@field total number Total damage/healing
---@field rawTotal number|nil Raw total (includes overkill)
---@field ticks number Total tick count
---@field critTicks number Critical tick count
---@field minTick number|nil Minimum tick value
---@field maxTick number|nil Maximum tick value

-------------------------
-- Render Context Type
-------------------------
---@class JournalRenderContext
---@field list ZO_ParametricScrollList ESO parametric list to populate
---@field encounter DecodedEncounter Decoded encounter data
---@field abilityInfo table<number, AbilityInfo> Ability info lookup
---@field unitNames table<number, string> Unit names lookup
---@field durationSec number Fight duration in seconds
---@field filters JournalFilters Current filter state
---@field arithmancer ArithmancerInstance|nil Calculator instance (optional, some tabs don't need it)

---@class JournalFilters
---@field targetFilter table<number, boolean>|nil Target unit filter (unitId -> true)
---@field sourceFilter table<number, boolean>|nil Source filter (unitId -> true)
---@field groupFilter table<string, boolean>|nil Group filter for effects (displayName -> true)

---@alias NavigationMode
---| 1 # INSTANCES
---| 2 # ENCOUNTERS
---| 3 # STATS
---| 4 # SETTINGS

---@alias StatsTab
---| 1 # OVERVIEW
---| 2 # BOSS_DAMAGE_DONE
---| 3 # DAMAGE_DONE
---| 4 # DAMAGE_TAKEN
---| 5 # HEALING_OUT
---| 6 # SELF_HEALING
---| 7 # HEALING_IN
---| 8 # EFFECTS
---| 9 # GROUP

---@alias InstanceTab
---| 1 # ALL
---| 2 # INSTANCED
---| 3 # OVERLAND
---| 4 # HOUSE
---| 5 # PVP

---@alias EncounterTab
---| 1 # ALL
---| 2 # BOSS
---| 3 # TRASH
---| 4 # PLAYER
---| 5 # DUMMY

-------------------------
-- Shared Encounter Data
-------------------------
---@class SharedBossDamage
---@field bossTag string Boss unit tag (e.g. "boss1")
---@field tagSeq number Sequence within tag (0=first boss, increments on tag reuse)
---@field damage number Total damage to this boss
---@field critPercent number Critical hit percentage (0-1)
---@field dotPercent number DoT damage percentage (0-1)
---@field aoePercent number AoE damage percentage (0-1)
---@field magicalPercent number Magical damage percentage (0-1, magic/fire/frost/shock)

---@class SharedBossDamageTaken
---@field bossTag string Boss unit tag
---@field tagSeq number Sequence within tag
---@field damage number Total damage taken from this boss

---@class SharedDamageByType
---@field type number Damage type enum value
---@field damage number Total damage of this type

---@class SharedHealing
---@field rawOut number Raw healing output
---@field effectiveOut number Effective healing output
---@field rawSelf number Raw self-healing
---@field effectiveSelf number Effective self-healing

---@class SharedDeathRecapAttack
---@field abilityId number
---@field damage number

---@class SharedDeathRecap
---@field timeOffsetMs number Ms from fight start when death occurred
---@field attacks SharedDeathRecapAttack[]

---@class DeathRecapSnapshot
---@field timeMs number Ms from fight start when death occurred
---@field attacks SharedDeathRecapAttack[]

---@class SharedDeaths
---@field deathCount number Total deaths (1-15)
---@field first SharedDeathRecap First death recap
---@field last SharedDeathRecap|nil Last death (nil if same as first or only one death)

---@class EncounterDeaths
---@field deathCount number Total deaths (may exceed #recaps if a death had 0 killing attacks)
---@field recaps SharedDeathRecap[] All death recaps with attack details

---@class SharedDamageTakenAbility
---@field abilityId number
---@field damagePercent number 0-1 fraction of total damage taken

---@class SharedEncounterData
---@field timestampS number Sender's fight start (Unix epoch)
---@field durationMs number Sender's fight duration in ms
---@field totalDamage number All-target personal damage
---@field critPercent number Critical hit percentage (0-1)
---@field dotPercent number DoT damage percentage (0-1)
---@field aoePercent number AoE damage percentage (0-1)
---@field maxHit number Single biggest hit
---@field damageByType SharedDamageByType[] Damage breakdown by type
---@field bossDamage SharedBossDamage[] Per-boss damage stats
---@field totalDamageTaken number Total damage taken
---@field bossDamageTaken SharedBossDamageTaken[] Per-boss damage taken
---@field healing SharedHealing|nil Healing stats (nil if not a healer)
---@field aliveTimeMs number|nil Player alive time in ms
---@field topDamageTakenAbilities SharedDamageTakenAbility[] Top 5 damage-taken abilities
---@field deaths SharedDeaths|nil Death recap data (nil if player never died)

---@class SharedDataEntry
---@field displayName string Sender's display name (undecorated)
---@field data SharedEncounterData
---@field role number|nil LFG_ROLE_* constant captured at match time

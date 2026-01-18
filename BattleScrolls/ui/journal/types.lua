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

    -- Group/Target
    GROUP = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_currentGroup.dds",
    GROUP_DAMAGE = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_currentGroup.dds",
    GROUP_DPS = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_currentGroup.dds",
    TARGET = "EsoUI/Art/ZoneStories/completionTypeIcon_groupBoss.dds",

    -- Roles
    TANK = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank.dds",
    HEALER = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer.dds",
}

-------------------------
-- Instance Icons
-------------------------
journal.InstanceIcons = {
    DUNGEON = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_groupDungeon.dds",
    TRIAL = "EsoUI/Art/LFG/Gamepad/LFG_activityIcon_trial.dds",
    ARENA = "EsoUI/Art/LFG/Gamepad/LFG_activityIcon_delve.dds",
    OVERLAND = "EsoUI/Art/WorldMap/Gamepad/gp_maplocationhistory_mainquestzoneicon.dds",
    HOUSE = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_housing.dds",
    PVP = "EsoUI/Art/TreeIcons/Gamepad/gp_tutorial_idexIcon_Alliance_War.dds",
    UNKNOWN = "EsoUI/Art/TreeIcons/Gamepad/gp_tutorial_idexIcon_ESOPlus.dds",
}

-------------------------
-- Encounter Icons
-------------------------
journal.EncounterIcons = {
    BOSS = "EsoUI/Art/UnitFrames/Gamepad/gp_targetUnitFrame_boss.dds",
    TRASH = "EsoUI/Art/UnitFrames/Gamepad/gp_targetUnitFrame_elite.dds",
    PLAYER = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_playerList.dds",
    DUMMY = "EsoUI/Art/TreeIcons/Gamepad/gp_tutorial_idexIcon_dummies.dds",
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
---@field sourceFilter table<string, boolean>|nil Source filter (sourceType -> true: "player", "pets", "companions")
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

-----------------------------------------------------------
-- Constants
-- Lookup tables and ability IDs for Battle Scrolls
--
-- Contains:
--   - Proc ability ID sets (for tracking proc events)
--   - AoE ability ID sets (for categorization)
--   - Combat result sets (damage, healing, crit)
--   - Unit type sets (personal, friendly)
--   - Portal effect IDs (for phase tracking)
--   - Zone IDs (special handling zones)
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

-- Pre-computed boss tag strings (avoid string concatenation in hot paths)
-- Built using BOSS_RANK_ITERATION_BEGIN/END for consistency with ESO API
---@type table<number, string>
local BOSS_TAGS = {}
for i = BOSS_RANK_ITERATION_BEGIN, BOSS_RANK_ITERATION_END do
    BOSS_TAGS[i] = "boss" .. i
end

---@class BattleScrollsConstants
---@field BOSS_TAGS table<number, string> Pre-computed boss tag strings ("boss1" to "boss12")
---@field SingleTargetDamageProcAbilityIds table<number, boolean> A set of ability IDs that damage one target, regardless of if it's targeted specifically or hit by an AOE.
---@field DAMAGE_SHIELDED_ABILITY_ID number Synthetic ability id for damage absorbed by damage shields
---@field HEAL_ABSORBED_ABILITY_ID number Synthetic ability id for healing absorbed by heal absorption effects
---@field HEALTH_RECOVERY_ABILITY_ID number Synthetic ability id for natural health recovery
---@field INFERRED_PLAYER_UNIT_ID number Synthetic player unit id used until ESO reports the real id
---@field INFERRED_COMPANION_UNIT_ID number Synthetic companion unit id used until ESO reports the real id
---@field DAMAGE_SHIELDED_ICON string Synthetic shielded damage icon
---@field HEAL_ABSORBED_ICON string Synthetic absorbed healing icon
---@field HEALTH_RECOVERY_ICON string Synthetic health recovery icon
---@field VENGEANCE_LOADOUTS_BY_SKILL_LINE_ID table<number, VengeanceLoadoutDef> Vengeance loadout metadata keyed by skill line id
---@field VENGEANCE_PERK_SLOTS number[] Positional perk slot order: red, yellow, blue

---@type BattleScrollsConstants
local constants = {}

BattleScrolls.constants = constants

-- |k| markup scales relative to font height; the keybind strip uses
-- ZoFontGamepad22 for the key icon and ZoFontGamepad34 for the name label.
-- CJK font strings remap these sizes (17/28 instead of 22/34), so the
-- embedded icon scale must differ.  180 * keyFont / nameFont.
-- CJK lang files set BattleScrolls._keybindIconScale before constants.lua loads.
constants.keybindIconScale = BATTLESCROLLS_KEYBIND_ICON_SCALE or 117
BATTLESCROLLS_KEYBIND_ICON_SCALE = nil

-- The maximum supported DPS, anything above may be represented by math.huge when transferring
constants.huge = 2 ^ 20

constants.BOSS_TAGS = BOSS_TAGS

-- Synthetic ability/unit ids must fit binary storage bit widths:
-- ability id is 20-bit unsigned, unit id is 24-bit unsigned.
constants.DAMAGE_SHIELDED_ABILITY_ID = 1048574
constants.HEAL_ABSORBED_ABILITY_ID = 1048573
constants.HEALTH_RECOVERY_ABILITY_ID = 1048575
constants.INFERRED_PLAYER_UNIT_ID = 16777215
constants.INFERRED_COMPANION_UNIT_ID = 16777214
constants.DAMAGE_SHIELDED_ICON = "EsoUI/Art/Icons/scribing_primary_damageshield.dds"
constants.HEAL_ABSORBED_ICON = "EsoUI/Art/Icons/scribing_primary_trauma.dds"
constants.HEALTH_RECOVERY_ICON = GetAbilityIcon(61698) -- Major Fortitude

---@class VengeanceLoadoutDef
---@field skillLineId number
---@field icon string

constants.VENGEANCE_LOADOUTS_BY_SKILL_LINE_ID = {
    [339] = { skillLineId = 339, icon = "EsoUI/Art/Icons/Vengeance/loadout_soldier.dds" },
    [340] = { skillLineId = 340, icon = "EsoUI/Art/Icons/Vengeance/loadout_vanguard.dds" },
    [341] = { skillLineId = 341, icon = "EsoUI/Art/Icons/Vengeance/loadout_battlemedic.dds" },
    [342] = { skillLineId = 342, icon = "EsoUI/Art/Icons/Vengeance/loadout_scout.dds" },
}

constants.VENGEANCE_PERK_SLOTS = {
    VENGEANCE_PERK_SLOT_RED,
    VENGEANCE_PERK_SLOT_YELLOW,
    VENGEANCE_PERK_SLOT_BLUE,
}

constants.SingleTargetDamageProcAbilityIds = {
    [185843] = true, -- Inspired Scholarship
    [186453] = true, -- Tome-Bearer's Inspiration
    [183048] = true, -- Recuperative Treatise
    [80170] = true, -- Burning Light
    [220863] = true  -- Sliver Assault
}

-- Combat unit type filter sets (for Lua-side O(1) lookup)
constants.personalTypesSet = {
    [COMBAT_UNIT_TYPE_PLAYER] = true,
    [COMBAT_UNIT_TYPE_PLAYER_PET] = true,
    [COMBAT_UNIT_TYPE_PLAYER_COMPANION] = true,
}

constants.friendlyTypesSet = {
    [COMBAT_UNIT_TYPE_PLAYER] = true,
    [COMBAT_UNIT_TYPE_PLAYER_PET] = true,
    [COMBAT_UNIT_TYPE_PLAYER_COMPANION] = true,
    [COMBAT_UNIT_TYPE_GROUP] = true,
}

-- Combat result filter sets
constants.damageResultsSet = {
    [ACTION_RESULT_DOT_TICK] = true,
    [ACTION_RESULT_DOT_TICK_CRITICAL] = true,
    [ACTION_RESULT_CRITICAL_DAMAGE] = true,
    [ACTION_RESULT_DAMAGE] = true,
    [ACTION_RESULT_BLOCKED_DAMAGE] = true,
    -- ACTION_RESULT_DAMAGE_SHIELDED handled separately with a synthetic ability ID
    [ACTION_RESULT_PRECISE_DAMAGE] = true,
    [ACTION_RESULT_WRECKING_DAMAGE] = true,
}

constants.healingResultsSet = {
    [ACTION_RESULT_HOT_TICK] = true,
    [ACTION_RESULT_HEAL] = true,
    [ACTION_RESULT_CRITICAL_HEAL] = true,
    [ACTION_RESULT_HOT_TICK_CRITICAL] = true,
    -- ACTION_RESULT_HEAL_ABSORBED handled separately with a synthetic ability ID
}

-- Healing ability IDs to ignore (e.g., pet initialization heals)
constants.ignoredHealingAbilityIds = {
    [126366] = true, -- Pet Battle Spirit: pets cast on themselves when summoned to initialize health
}

-- Portal phase ability IDs (prevents premature reset during portal phases)
constants.portalEffectsSet = {
    [108045] = true, -- Cloudrest
    [121216] = true, -- Sunspire
}

-- Copied from https://github.com/Shienar/AreaDamage/blob/main/table.lua
constants.aoeAbilityIds = {
    -- CATEGORY: Item Set>Arena>Maelstrom Arena
    [71646] = true, -- Winterborn | Last Checked: U47

    -- CATEGORY: Item Set>Arena>Vateshran Hollows
    [147694] = true, -- Explosive Rebuke | Last Checked: U47

    -- CATEGORY: Item Set>Craftable
    [34502] = true, -- Ashen Grip | Last Checked: U47
    [163293] = true, -- Deadlands Demolisher | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Bedlam Veil
    [214756] = true, -- Reflected Fury | Last Checked: U47
    [214520] = true, -- Tarnished Nightmare | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Bloodroot Forge
    [97574] = true, -- Flame Blossom | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Castle Thorn
    [141642] = true, -- Crimson Twilight | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Coral Aerie
    [167115] = true, -- Glacial Guardian | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Cradle of Shadows
    [84355] = true, -- Hand of Mephala | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Depths of Malatar
    [116920] = true, -- Auroran's Thunder | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Dread Cellar
    [159275] = true, -- Rush of Agony | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Exiled Redoubt
    [235745] = true, -- Jerensi's Bladestorm (Delayed) | Last Checked: U47
    [236163] = true, -- Jerensi's Bladestorm (Initial) | Last Checked: U47
    [235836] = true, -- Vandorallen's Resonance | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Falkreath Hold
    [97716] = true, -- Pillar of Nirn (Initial hit only) | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Oathsworn Pit
    [214889] = true, -- Cinders of Anthelmir | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Red Petal Bastion
    [159253] = true, -- Thunder Caller | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Shipwright's Regret
    [167062] = true, -- Turning Tide | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon>Unhallowed Grave
    [133494] = true, -- Aegis Caller | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Castle Thorn
    [142305] = true, -- Lady Thorn | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Coral Aerie
    [167048] = true, -- Kargaeda's Storm (Kargaeda) | Last Checked: U47
    [167607] = true, -- Kargaeda's Wind (Kargaeda) | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Earthen Root Enclave
    [176816] = true, -- Archdruid Devyric | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Fang Lair
    [102094] = true, -- Thurvokun | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Graven Deep
    [175349] = true, -- Euphotic Gatekeeper | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Lair of Maarselok
    [126941] = true, -- Maarselok | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Lep Seclusa
    [236655] = true, -- Orpheon the Tactician (Stunned) | Last Checked: U47
    [236789] = true, -- Orpheon the Tactician (Immune to Stun) | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Naj-Caldeesh
    [248631] = true, -- Bar-Sakka | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Red Petal Bastion
    [159516] = true, -- Prior Thierric | Last Checked: U47

    -- CATEGORY: Item Set>DLC Dungeon (Monster)>Scalecaller Peak
    [102136] = true, -- Z'aans | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon>City of Ash I/II
    [59696] = true, -- Embershield | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon>Direfrost Keep
    [34404] = true, -- Frostfire (The Ice Furnace) | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon>Tempest Island
    [67136] = true, -- Overwhelming Surge | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>Arx Corinium
    [80544] = true, -- Sellistrix (Spawn of Mephala) | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>City of Ash I
    [83409] = true, -- Infernal Guardian | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>City of Ash II
    [61273] = true, -- Valkyn Skoria (All other enemies in 5 meters) | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>Crypt of Hearts I
    [80526] = true, -- Ilambris | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>Crypt of Hearts II
    [59593] = true, -- Nerieneth | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>Direfrost Keep
    [80561] = true, -- Iceheart | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>Fungal Grotto I
    [80565] = true, -- Kragh | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>Tempest Island
    [80521] = true, -- Stormfist (Final Hit) | Last Checked: U47
    [80522] = true, -- Stormfist (First 3s) | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>Vault's of Madness
    [84502] = true, -- Grothdarr | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster)>Volenfell
    [80865] = true, -- Tremorscale | Last Checked: U47

    -- CATEGORY: Item Set>Dungeon (Monster) >Fungal Grotto II
    [59498] = true, -- Mephala's Web | Last Checked: U47

    -- CATEGORY: Item Set>Imperial City (Monster)
    [167742] = true, -- Baron Thirsk | Last Checked: U47
    [166788] = true, -- Lady Malygda (Dmg going out) | Last Checked: U47
    [167962] = true, -- Lady Malygda (Dmg  coming back) | Last Checked: U47
    [167680] = true, -- Nunatak | Last Checked: U47

    -- CATEGORY: Item Set>Infinite Archive>Necromancer
    [227072] = true, -- Corpsebuster | Last Checked: U47

    -- CATEGORY: Item Set>Mythic
    [173734] = true, -- Dov-Rha Sabatons | Last Checked: U47
    [239711] = true, -- Mad God's Dancing Shoes (Exploding Cheese Wheel) | Last Checked: U47
    [240131] = true, -- Mad God's Dancing Shoes (Enemies Facing You) | Last Checked: U47

    -- CATEGORY: Item Set>Overland
    [75692] = true, -- Bahraha's Curse | Last Checked: U47
    [154347] = true, -- Deadlands Assassin | Last Checked: U47
    [93307] = true, -- Defiler | Last Checked: U47
    [243309] = true, -- Mad Tinkerer | Last Checked: U47
    [57209] = true, -- Storm Knight's Plate | Last Checked: U47
    [76344] = true, -- Syvarra's Scales (Only the weak initial tick.) | Last Checked: U47
    [33497] = true, -- Thunderbugs Carapace | Last Checked: U47
    [71658] = true, -- Trinimac's Valor | Last Checked: U47
    [137526] = true, -- Venomous Smite (Only to nearby enemies.) | Last Checked: U47

    -- CATEGORY: Item Set>PvP
    [159386] = true, -- Dark Convergence (Whole Circle) | Last Checked: U47
    [159387] = true, -- Dark Convergence (Inner Circle) | Last Checked: U47

    -- CATEGORY: Item Set>Trial>Aetherian Archive
    [50992] = true, -- Defending Warrior | Last Checked: U47

    -- CATEGORY: Item Set>Trial>Dreadsail Reef
    [172672] = true, -- Whorl of the Depths (Whirlpool) | Last Checked: U47

    -- CATEGORY: Item Set>Trial>Maw of Lorkhaj
    [75752] = true, -- Roar of Alkosh (Initial hit only) | Last Checked: U47

    -- CATEGORY: Skill>Class>Arcanist>Herald of the Tome
    [185817] = true, -- Abyssal Impact | Last Checked: U47
    [183006] = true, -- Cephaliarc's Flail | Last Checked: U47
    [183123] = true, -- Exhausting Fatecarver | Last Checked: U47
    [185808] = true, -- Fatecarver | Last Checked: U47
    [185407] = true, -- Fulminating Rune (6 second Detonation) | Last Checked: U47
    [186370] = true, -- Pragmatic Fatecarver | Last Checked: U47
    [191078] = true, -- Runebreak (The Imperfect Ring Synergy) | Last Checked: U47
    [185823] = true, -- Tentacular Dread | Last Checked: U47
    [189869] = true, -- The Languid Eye | Last Checked: U47
    [189793] = true, -- The Unblinking Eye | Last Checked: U47

    -- CATEGORY: Skill>Class>Arcanist>Soldier of Apocrypha
    [183678] = true, -- Gibbering Shield (Difficult to test.) | Last Checked: U47
    [193275] = true, -- Sanctum of the Abyssal Sea (Difficult to test.) | Last Checked: U47

    -- CATEGORY: Skill>Class>Dragonknight>Ardent Flame
    [31842] = true, -- Core of Flame | Last Checked: U49 PTS 4
    [328787] = true, -- Heart of Flame (Only findable with logs. EVENT_COMBAT_EVENT returned a hit value of 0 for this) | Last Checked: U49 PTS 4
    [28969] = true, -- Inferno | Last Checked: U49 PTS 4
    [61945] = true, -- Incinerate | Last Checked: U49 PTS 4
    [20824] = true, -- Power Lash (Flame lash with stacks) | Last Checked: U49 PTS 4
    [98438] = true, -- Shackle (Synergy DMG) | Last Checked: U49 PTS 4
    [32960] = true, -- Shifting Standard | Last Checked: U49 PTS 4
    [32794] = true, -- Soul of Flame | Last Checked: U49 PTS 4
    [256798] = true, -- Volcanic Whip | Last Checked: U49 PTS 4
    [20252] = true, -- Burning Talons (Initial Hit) | Last Checked: U49 PTS 4

    -- CATEGORY: Skill>Class>Dragonknight>Draconic Power
    [20251] = true, -- Choking Talons | Last Checked: U49 PTS 4
    [20245] = true, -- Dark Talons | Last Checked: U47
    [20944] = true, -- Disintegrating Dragonfire (Initial Hit) | Last Checked: U49 PTS 4
    [29014] = true, -- Dragon Leap | Last Checked: U49 PTS 4
    [20917] = true, -- Dragonfire Breath (Initial Hit) | Last Checked: U49 PTS 4
    [31104] = true, -- Engulfing Dragonfire | Last Checked: U49 PTS 4
    [32716] = true, -- Ferocious Leap | Last Checked: U47
    [32974] = true, -- Ignite (Synergy DMG from talons) | Last Checked:  U49 PTS 4
    [32720] = true, -- Take Flight | Last Checked: U49 PTS 4

    -- CATEGORY: Skill>Class>Dragonknight>Earthen Heart
    [17879] = true, -- Corrosive Armor (DMG to Nearby Enemies) | Last Checked: U47

    -- CATEGORY: Skill>Class>Necromancer>Bone Tyrant
    [115115] = true, -- Death Scythe | Last Checked: U47
    [118314] = true, -- Ghostly Embrace (First Circle On-Hit) | Last Checked: U47
    [143944] = true, -- Ghostly Embrace (Second Circle On-Hit) | Last Checked: U47
    [143946] = true, -- Ghostly Embrace (Third Circle On-hit) | Last Checked: U47
    [118223] = true, -- Hungry Scythe | Last Checked: U47
    [118720] = true, -- Pummeling Goliath | Last Checked: U47
    [118618] = true, -- Pure Agony (Agony Totem Synergy) | Last Checked: U47
    [118289] = true, -- Ravenous Goliath | Last Checked: U47
    [118266] = true, -- Ruinous Scythe | Last Checked: U47

    -- CATEGORY: Skill>Class>Necromancer>Grave Lord
    [117854] = true, -- Avid Boneyard | Last Checked: U47
    [117715] = true, -- Blighted Skeletal Detonation | Last Checked: U47
    [115254] = true, -- Boneyard | Last Checked: U47
    [124468] = true, -- Deathbolt (Skeletal Arcanist AOE Dmg) | Last Checked: U47
    [118766] = true, -- Detonating Siphon (DOT) | Last Checked: U47
    [123082] = true, -- Detonating Siphon (Terminatiing Explosion) | Last Checked: U47
    [122178] = true, -- Frozen Colossus (Hits 1-3) | Last Checked: U47
    [122392] = true, -- Glacial Colossus (Hits 1-3) | Last Checked: U47
    [220098] = true, -- Grave Lord's Sacrifice ("Buffed 3rd skull hit base morph.") | Last Checked: U47
    [220101] = true, -- Grave Lord's Sacrifice (Buffed 3rd venom skull hit.) | Last Checked: U47
    [220104] = true, -- Grave Lord's Sacrifice (Buffed 3rd ricochet skull hit.) | Last Checked: U47
    [115572] = true, -- Grave Robber (Boneyard Synergy) | Last Checked: U47
    [118011] = true, -- Mystic Siphon | Last Checked: U47
    [122399] = true, -- Pestilent Colossus (Hit 1) | Last Checked: U47
    [122400] = true, -- Pestilent Colossus (Hit 2) | Last Checked: U47
    [122401] = true, -- Pestilent Colossus (Hit 3) | Last Checked: U47
    [116410] = true, -- Shocking Siphon | Last Checked: U47
    [117809] = true, -- Unnerving Boneyard | Last Checked: U47

    -- CATEGORY: Skill>Class>Nightblade>Assassination
    [25494] = true, -- Lotus Fan (Initial Hit) | Last Checked: U47

    -- CATEGORY: Skill>Class>Nightblade>Shadow
    [108936] = true, -- Corrossive Drain (From Dark Shade Skill) | Last Checked: U47
    [36052] = true, -- Twisting Path | Last Checked: U47
    [36490] = true, -- Veil of Blades | Last Checked: U47

    -- CATEGORY: Skill>Class>Nightblade>Siphoning
    [33316] = true, -- Drain Power | Last Checked: U47
    [36901] = true, -- Power Extraction | Last Checked: U47
    [36891] = true, -- Sap Essence | Last Checked: U47
    [25091] = true, -- Soul Shred (Initial Hit) | Last Checked: U47
    [35460] = true, -- Soul Tether (Initial Hit) | Last Checked: U47

    -- CATEGORY: Skill>Class>Sorcerer>Daedric Summoning
    [24329] = true, -- Daedric Prey | Last Checked: U47
    [29809] = true, -- Atronach Lightning Strike (Every 2s - Charged Atronach) | Last Checked: U47
    [23667] = true, -- Summon Charged Atronach (Initial Hit) | Last Checked: U47
    [24327] = true, -- Daedric Curse | Last Checked: U47
    [23664] = true, -- Greater Storm Atronach (Initial Hit) | Last Checked: U47
    [24331] = true, -- Haunting Curse (Same ID for both ticks.) | Last Checked: U47
    [23659] = true, -- Summon Storm Atronach (Initial Hit) | Last Checked: U47
    [29529] = true, -- Summon Unstable Clannfear (Tailswipe) | Last Checked: U47
    [108844] = true, -- Summon Unstable Familiar (Every 2s) | Last Checked: U47
    [77186] = true, -- Summon Volatile Familiar (Every 2s) | Last Checked: U47

    -- CATEGORY: Skill>Class>Sorcerer>Dark Magic
    [28309] = true, -- Shattering Spines | Last Checked: U47
    [80435] = true, -- Suppression Field | Last Checked: U47

    -- CATEGORY: Skill>Class>Sorcerer>Storm Calling
    [23214] = true, -- Boundless Storm | Last Checked: U47
    [23196] = true, -- Conduit (Synergy DMG) | Last Checked: U47
    [44491] = true, -- Endless Fury (Only to other enemies nearby) | Last Checked: U47
    [114798] = true, -- Energy Overload (Heavy Attacks) | Last Checked: U47
    [23232] = true, -- Hurricane | Last Checked: U47
    [23208] = true, -- Lightning Flood | Last Checked: U47
    [23211] = true, -- Lightning Form | Last Checked: U47
    [23189] = true, -- Lightning Splash | Last Checked: U47
    [23202] = true, -- Liquid Lightning | Last Checked: U47
    [44483] = true, -- Mage's Fury (Only to other enemies nearby) | Last Checked: U47
    [19128] = true, -- Mage's Wrath (20% Explosion) | Last Checked: U47
    [24798] = true, -- Overload (Heavy Attacks) | Last Checked: U47
    [7102] = true, -- Power Overload (Heavy Attacks) | Last Checked: U47
    [23239] = true, -- Streak | Last Checked: U47

    -- CATEGORY: Skill>Class>Templar>Aedric Spear
    [44432] = true, -- Biting Jabs | Last Checked: U47
    [22181] = true, -- Blazing Shield (Max reflected damage increases.) | Last Checked: U47
    [26871] = true, -- Blazing Spear (Initial Hit) | Last Checked: U47
    [26879] = true, -- Blazing Spear (DOT) | Last Checked: U47
    [22139] = true, -- Crescent Sweep (Initial Hit) | Last Checked: U47
    [62606] = true, -- Crescent Sweep (Every 2s) | Last Checked: U47
    [22144] = true, -- Everlasting Sweep (Initial Hit) | Last Checked: U47
    [62598] = true, -- Everlasting Sweep (Every 2s) | Last Checked: U47
    [22165] = true, -- Explosive Charge | Last Checked: U47
    [26859] = true, -- Luminous Shards (Initial Hit) | Last Checked: U47
    [95955] = true, -- Luminous Shards (DOT) | Last Checked: U47
    [44426] = true, -- Puncturing Strikes | Last Checked: U47
    [44436] = true, -- Puncturing Sweep | Last Checked: U47
    [22138] = true, -- Radial Sweep (Initial Hit) | Last Checked: U47
    [62550] = true, -- Radial Sweep (Every 2s) | Last Checked: U47
    [22182] = true, -- Radiant Ward (Initial Hit) | Last Checked: U47
    [26192] = true, -- Spear Shards (Initial Hit) | Last Checked: U47
    [95931] = true, -- Spear Shards (DOT) | Last Checked: U47
    [22178] = true, -- Sun Shield (Initial Hit) | Last Checked: U47

    -- CATEGORY: Skill>Class>Templar>Dawn's Wrath
    [31604] = true, -- Gravity Crush (Solar Prison synergy) | Last Checked: U47
    [21753] = true, -- Nova (Caster DOT) | Last Checked: U47
    [21732] = true, -- Reflective Light (Only the initial hit.) | Last Checked: U47
    [100218] = true, -- Solar Barrage (Every 2s) | Last Checked: U47
    [21759] = true, -- Solar Distrubance (Caster DOT) | Last Checked: U47
    [21756] = true, -- Solar Prison (Caster DOT) | Last Checked: U47
    [31540] = true, -- Supernova (Nova synergy) | Last Checked: U47
    [127791] = true, -- Unstable Core (First Hit) | Last Checked: U47
    [127792] = true, -- Unstable Core (Second Hit) | Last Checked: U47
    [127793] = true, -- Unstable Core (Third Hit) | Last Checked: U47

    -- CATEGORY: Skill>Class>Templar>Restoring Light
    [80172] = true, -- Ritual of Retribution | Last Checked: U47

    -- CATEGORY: Skill>Class>Warden>Animal Companions
    [89128] = true, -- Crushing Swipe (Feral Guardian attack) | Last Checked: U47
    [89220] = true, -- Crushing Swipe (Wild Guardian attack) | Last Checked: U47
    [105907] = true, -- Crushing Swipe (Eternal Guardian attack) | Last Checked: U47
    [94424] = true, -- Deep Fissure (1st hit) | Last Checked: U47
    [181331] = true, -- Deep Fissure (2nd hit) | Last Checked: U47
    [130170] = true, -- Growing Swarm (Every 2s to nearby enemies) | Last Checked: U47
    [94411] = true, -- Scorch (1st hit) | Last Checked: U47
    [181330] = true, -- Scorch (2nd hit) | Last Checked: U47
    [94445] = true, -- Subterranean Assault (1st & 2nd hit.) | Last Checked: U47

    -- CATEGORY: Skill>Class>Warden>Winter's Embrace
    [86156] = true, -- Arctic Blast (Initial Hit) | Last Checked: U47
    [130406] = true, -- Arctic Blast (Every 2s to enemies hit.) | Last Checked: U47
    [88791] = true, -- Gripping Shards | Last Checked: U47
    [88783] = true, -- Impaing Shards | Last Checked: U47
    [88860] = true, -- Northern Storm | Last Checked: U47
    [88863] = true, -- Permafrost | Last Checked: U47
    [86247] = true, -- Sleet Storm | Last Checked: U47
    [88802] = true, -- Winter's Revenge | Last Checked: U47

    -- CATEGORY: Skill>Guild>Fighters Guild
    [35713] = true, -- Dawnbreaker (Initial Hit) | Last Checked: U47
    [40158] = true, -- Dawnbreaker of Smiting (Initial Hit) | Last Checked: U47
    [40161] = true, -- Flawless Dawnbreaker (Initial Hit) | Last Checked: U47
    [40300] = true, -- Silver Shards (All 3 bolts are affected.) | Last Checked: U47

    -- CATEGORY: Skill>Guild>Mages Guild
    [31635] = true, -- Fire Rune | Last Checked: U47
    [63454] = true, -- Ice Comet (DOT) | Last Checked: U47
    [63457] = true, -- Ice Comet  (Initial hit) | Last Checked: U47
    [63429] = true, -- Meteor (DOT) | Last Checked: U47
    [172912] = true, -- Meteor (Initial hit) | Last Checked: U47
    [40469] = true, -- Scalding Rune (Initial Hit Only) | Last Checked: U47
    [63471] = true, -- Shooting Star (DOT) | Last Checked: U47
    [63474] = true, -- Shooting Star (Initial hit) | Last Checked: U47
    [40473] = true, -- Volcanic Rune | Last Checked: U47

    -- CATEGORY: Skill>Guild>Undaunted
    [85432] = true, -- Combustion (Damage from Orb Synergy.) | Last Checked: U47
    [42029] = true, -- Mystic Orb | Last Checked: U47
    [39299] = true, -- Necrotic Orb | Last Checked: U47
    [41839] = true, -- Radiate (AOE part of Inner fire synergy.) | Last Checked: U47
    [126720] = true, -- Shadow Silk (Initial hit) | Last Checked: U47
    [80107] = true, -- Shadow Sillk (After 10s) | Last Checked: U47
    [80129] = true, -- Tangling Webs (After 10s) | Last Checked: U47
    [126722] = true, -- Tangling Webs (Initial hit) | Last Checked: U47
    [80083] = true, -- Trapping Webs (After 10s) | Last Checked: U47
    [126718] = true, -- Trapping Webs (Initial Hit) | Last Checked: U47

    -- CATEGORY: Skill>PvP>Assault
    [40267] = true, -- Anti-Cavalry Caltrops | Last Checked: U47
    [38561] = true, -- Caltrops | Last Checked: U47
    [61493] = true, -- Inevitable Detonation | Last Checked: U47
    [61488] = true, -- Magicka Detonation | Last Checked: U47
    [61502] = true, -- Proximity Detonation | Last Checked: U47
    [40252] = true, -- Razor Caltrops | Last Checked: U47

    -- CATEGORY: Skill>Scribing
    [217231] = true, -- Elemental Explosion (Flame/Frost/Magic/Frost Focus Scripts - Initial Hit) | Last Checked: U47
    [229600] = true, -- Elemental Explosion (Physical Focus Script - Initial Hit) | Last Checked: U47
    [217178] = true, -- Smash (Physical/Blood/Poison Focus - Initial Hit) | Last Checked: U47
    [217179] = true, -- Smash (Magic Focus - Initial Hit) | Last Checked: U47
    [219972] = true, -- Smash (Knockback/Stun Focus - Initial Hit) | Last Checked: U47
    [227609] = true, -- Smash (Taunt Focus -Initial Hit) | Last Checked: U47
    [217459] = true, -- Soul Burst (Magic/Fire/Frost/Shock Focus - Initial Hit) | Last Checked: U47
    [217465] = true, -- Soul Burst (Physical/Bleed/Disease Focus - Initial Hit) | Last Checked: U47
    [217631] = true, -- Torch (Physical/Bleed Focus - Initial hit) | Last Checked: U47
    [217632] = true, -- Torch (Fire/Frost Focus - Initial hit) | Last Checked: U47
    [217679] = true, -- Trample (Physical/Disease Focus - Initial Hit) | Last Checked: U47
    [217682] = true, -- Trample (Magic/Frost Focus - Initial Hit) | Last Checked: U47
    [220543] = true, -- Trample (Stun Focus - Initial Hit) | Last Checked: U47
    [220544] = true, -- Trample (Dispelling/Knockback Focus - Initial Hit) | Last Checked: U47
    [217348] = true, -- Traveling Knife (Multi-Target Focus AOE) | Last Checked: U47
    [217359] = true, -- Traveling Knife (Physical/Bloody/Poison Focus - Between You and Them) | Last Checked: U47
    [219705] = true, -- Traveling Knife (Magic/Frost Focus - Between You and Them) | Last Checked: U47
    [217605] = true, -- Ulfsild's Contingency (Magic/Fire/Frost/Shock Focus - Initial Hit) | Last Checked: U47
    [221354] = true, -- Ulfsild's Contingency (Immobilize Focus - Initial Hit) | Last Checked: U47
    [229656] = true, -- Ulfsild's Contingency (Bleed Focus - Initial Hit) | Last Checked: U47
    [214960] = true, -- Vault (Physical/Bloody/Disease/Poison Focus) | Last Checked: U47
    [214974] = true, -- Vault (Immobilize Focus) | Last Checked: U47
    [214978] = true, -- Vault (Flame Focus) | Last Checked: U47
    [216674] = true, -- Vault (Taunt Focus) | Last Checked: U47

    -- CATEGORY: Skill>Scribing>Signature
    [217689] = true, -- Hunter's Focus (Trample) | Last Checked: U47
    [217500] = true, -- Sorcerer's Class Mastery (Traveling Knife) | Last Checked: U47
    [220135] = true, -- Sorcerer's Class Mastery (Vault) | Last Checked: U47
    [220509] = true, -- Sorcerer's Class Mastery (Wield Soul) | Last Checked: U47
    [220620] = true, -- Sorcerer's Class Mastery (Soul Burst) | Last Checked: U47
    [220831] = true, -- Sorcerer's Class Mastery (Shield Throw) | Last Checked: U47
    [221132] = true, -- Sorcerer's Class Mastery (Mender's Bond) | Last Checked: U47
    [221166] = true, -- Sorcerer's Class Mastery (Ulfsild's Contingency) | Last Checked: U47
    [221289] = true, -- Sorcerer's Class Mastery (Elemental Explosion) | Last Checked: U47
    [221374] = true, -- Sorcerer's Class Mastery (Trample) | Last Checked: U47
    [221573] = true, -- Sorcerer's Class Mastery (Torch) | Last Checked: U47
    [221644] = true, -- Sorcerer's Class Mastery (Smash) | Last Checked: U47
    [227096] = true, -- Sorcerer's Class Mastery (Banner) | Last Checked: U47

    -- CATEGORY: Skill>Weapon>Bow
    [38724] = true, -- Acid Spray (Initial Hit Only) | Last Checked: U47
    [38696] = true, -- Arrow Barrage | Last Checked: U47
    [38722] = true, -- Arrow Spray | Last Checked: U47
    [38723] = true, -- Bombard | Last Checked: U47
    [38690] = true, -- Endless Hail | Last Checked: U47
    [28877] = true, -- Volley | Last Checked: U47

    -- CATEGORY: Skill>Weapon>Destruction Staff
    [62912] = true, -- Blockade of Fire | Last Checked: U47
    [62951] = true, -- Blockade of Frost | Last Checked: U47
    [62990] = true, -- Blockade of Storms | Last Checked: U47
    [83683] = true, -- Eye of Flame | Last Checked: U47
    [83685] = true, -- Eye of Frost | Last Checked: U47
    [83687] = true, -- Eye of Lightning | Last Checked: U47
    [85127] = true, -- Fiery Rage | Last Checked: U47
    [28794] = true, -- Fire Impulse | Last Checked: U47
    [39149] = true, -- Fire Ring | Last Checked: U47
    [83626] = true, -- Fire Storm | Last Checked: U47
    [170989] = true, -- Flame Pulsar | Last Checked: U47
    [28798] = true, -- Frost Impulse | Last Checked: U47
    [170990] = true, -- Frost Pulsar | Last Checked: U47
    [39151] = true, -- Frost Ring | Last Checked: U47
    [83629] = true, -- Ice Storm | Last Checked: U47
    [85129] = true, -- Icy Rage | Last Checked: U47
    [146553] = true, -- Shock Impulse | Last Checked: U47
    [39153] = true, -- Shock Ring | Last Checked: U47
    [146593] = true, -- Storm Pulsar | Last Checked: U47
    [83631] = true, -- Thunder Storm | Last Checked: U47
    [85131] = true, -- Thunderous Rage | Last Checked: U47
    [39054] = true, -- Unstable Wall of Fire (DOT) | Last Checked: U47
    [39056] = true, -- Unstable Wall of Fire (Explosion) | Last Checked: U47
    [39071] = true, -- Unstable Wall of Frost (DOT) | Last Checked: U47
    [39072] = true, -- Unstable Wall of Frost (Explosion) | Last Checked: U47
    [39079] = true, -- Unstable Wall of Storms (DOT) | Last Checked: U47
    [39080] = true, -- Unstable Wall of Storms (Explosion) | Last Checked: U47
    [62896] = true, -- Wall of Fire | Last Checked: U47
    [62931] = true, -- Wall of Frost | Last Checked: U47
    [62971] = true, -- Wall of Storms | Last Checked: U47

    -- CATEGORY: Skill>Weapon>Dual Wield
    [62522] = true, -- Blade Cloak | Last Checked: U47
    [62547] = true, -- Deadly Cloak | Last Checked: U47
    [62529] = true, -- Quick Cloak | Last Checked: U47
    [38861] = true, -- Steel Tornado | Last Checked: U47
    [38891] = true, -- Whirling Blades | Last Checked: U47
    [28591] = true, -- Whirlwind | Last Checked: U47

    -- CATEGORY: Skill>Weapon>Two-Handed
    [38754] = true, -- Brawler | Last Checked: U47
    [38745] = true, -- Carve (Initial Hit Only) | Last Checked: U47
    [20919] = true, -- Cleave | Last Checked: U47
    [38823] = true, -- Reverse Slice | Last Checked: U47
    [38792] = true, -- Stampede (Initial Hit) | Last Checked: U47
    [126474] = true, -- Stampede (DOT) | Last Checked: U47

    -- CATEGORY: Skill>World>Soul Magic
    [40416] = true, -- Shatter Soul (Ending explosion) | Last Checked: U47
    [45584] = true, -- Soul Shatter (Passive) | Last Checked: U47

    -- CATEGORY: Skill>World>Vampire
    [38968] = true, -- Blood Mist (Every 2s) | Last Checked: U47
    [38935] = true, -- Swarming Scion (Bat AOE) | Last Checked: U47

    -- CATEGORY: Skill>World>Werewolf
    [137184] = true, -- Brutal Carnage (Recast DMG) | Last Checked: U47
    [58864] = true, -- Claws of Anguish (Initial Hit) | Last Checked: U47
    [58879] = true, -- Claws of Life (Initial Hit) | Last Checked: U47
    [58855] = true, -- Infectious Claw (Initial Hit) | Last Checked: U47
}

-------------------------
-- Race Icons (gamepad character create icons, keyed by raceId)
-------------------------

---@type table<number, string>
constants.raceIcons = {
    [1]  = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_bretonIcon_down.dds",
    [2]  = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_redguardIcon_down.dds",
    [3]  = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_orcIcon_down.dds",
    [4]  = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_dunmerIcon_down.dds",
    [5]  = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_nordIcon_down.dds",
    [6]  = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_argonianIcon_down.dds",
    [7]  = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_altmerIcon_down.dds",
    [8]  = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_bosmerIcon_down.dds",
    [9]  = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_khajiitIcon_down.dds",
    [10] = "EsoUI/Art/CharacterCreate/Gamepad/CharacterCreate_imperialIcon_down.dds",
}

-------------------------
-- Food Buff Ability IDs
-------------------------

--- Maps food stat combination keys (sorted, comma-joined IDs from foodAbilityInfo arrays)
--- to localized string IDs for display.
---@type table<string, number>
constants.FOOD_COMBO_STRINGS = {
    ["1"] = BATTLESCROLLS_FOOD_MAX_HEALTH,
    ["2"] = BATTLESCROLLS_FOOD_MAX_MAGICKA,
    ["3"] = BATTLESCROLLS_FOOD_MAX_STAMINA,
    ["1,2"] = BATTLESCROLLS_FOOD_MAX_HEALTH_MAGICKA,
    ["1,3"] = BATTLESCROLLS_FOOD_MAX_HEALTH_STAMINA,
    ["2,3"] = BATTLESCROLLS_FOOD_MAX_MAGICKA_STAMINA,
    ["1,2,3"] = BATTLESCROLLS_FOOD_MAX_TRISTAT,
    ["4"] = BATTLESCROLLS_FOOD_HEALTH_RECOVERY,
    ["5"] = BATTLESCROLLS_FOOD_MAGICKA_RECOVERY,
    ["6"] = BATTLESCROLLS_FOOD_STAMINA_RECOVERY,
    ["4,5"] = BATTLESCROLLS_FOOD_HEALTH_MAGICKA_RECOVERY,
    ["4,6"] = BATTLESCROLLS_FOOD_HEALTH_STAMINA_RECOVERY,
    ["5,6"] = BATTLESCROLLS_FOOD_MAGICKA_STAMINA_RECOVERY,
    ["4,5,6"] = BATTLESCROLLS_FOOD_RECOVERY_TRISTAT,
}

--- Food buff ability ID registry.
--- Value is either an itemId (number) for unique foods, or a stat array (number[]) for generic foods.
--- Stat IDs: 1=Max Health, 2=Max Magicka, 3=Max Stamina, 4=Health Recovery, 5=Magicka Recovery, 6=Stamina Recovery
---@type table<number, number|number[]>
constants.foodAbilityInfo = {
    -- Generic foods (shared ability across many items)
    [61218] = { 1, 2, 3 }, -- Max Health, Max Magicka, Max Stamina
    [61255] = { 1, 3 }, -- Max Health, Max Stamina
    [61257] = { 1, 2 }, -- Max Health, Max Magicka
    [61259] = { 1 }, -- Max Health
    [61260] = { 2 }, -- Max Magicka
    [61261] = { 3 }, -- Max Stamina
    [61294] = { 2, 3 }, -- Max Magicka, Max Stamina
    [61322] = { 4 }, -- Health Recovery
    [61325] = { 5 }, -- Magicka Recovery
    [61328] = { 6 }, -- Stamina Recovery
    [61335] = { 4, 5 }, -- Health Recovery, Magicka Recovery
    [61340] = { 4, 6 }, -- Health Recovery, Stamina Recovery
    [61345] = { 5, 6 }, -- Magicka Recovery, Stamina Recovery
    [61350] = { 4, 5, 6 }, -- Health Recovery, Magicka Recovery, Stamina Recovery
    [66551] = { 1 }, -- Max Health (scaling)
    [66568] = { 2 }, -- Max Magicka (scaling)
    [66576] = { 3 }, -- Max Stamina (scaling)
    [66586] = { 4 }, -- Health Recovery (scaling)
    [66590] = { 5 }, -- Magicka Recovery (scaling)
    [66594] = { 6 }, -- Stamina Recovery (scaling)
    [84678] = { 2 }, -- Max Magicka (event food)
    -- Unique foods (single item per ability)
    [68411] = 64711, -- Crown Fortifying Meal
    [68416] = 64712, -- Crown Refreshing Drink
    [72816] = 71056, -- Orzorga's Red Frothgar
    [72819] = 71057, -- Orzorga's Tripe Trifle Pocket
    [72822] = 71058, -- Orzorga's Blood Price Pie
    [72824] = 71059, -- Orzorga's Smoked Bear Haunch
    [72956] = 71074, -- Cyrodilic Field Tack
    [72959] = 71075, -- Cyrodilic Field Treat
    [72961] = 71076, -- Cyrodilic Field Bar
    [72965] = 71077, -- Cyrodilic Field Brew
    [72968] = 71078, -- Cyrodilic Field Tea
    [72971] = 71079, -- Cyrodilic Field Tonic
    [84681] = 87686, -- Crisp and Crunchy Pumpkin Snack Skewer
    [84700] = 87687, -- Bowl of "Peeled Eyeballs"
    [84704] = 87690, -- Witchmother's Party Punch
    [84709] = 87691, -- Crunchy Spider Skewer
    [84720] = 87695, -- Ghastly Eye Bowl
    [84725] = 87696, -- Frosted Brains
    [84731] = 87697, -- Witchmother's Potent Brew
    [84735] = 87699, -- Purifying Bloody Mara
    [85484] = 94437, -- Crown Crate Fortifying Meal
    [85497] = 94438, -- Crown Crate Refreshing Drink
    [86559] = 101879, -- Hissmir Fish-Eye Rye
    [86673] = 112425, -- Lava Foot Soup-and-Saltrice
    [86677] = 112426, -- Bergama Warning Fire
    [86746] = 112433, -- Betnikh Twice-Spiked Ale
    [86749] = 112434, -- Jagga-Drenched "Mud Ball"
    [86787] = 112438, -- Rajhin's Sugar Claws
    [86789] = 112439, -- Alcaire Festival Sword-Pie
    [86791] = 112440, -- Snow Bear Glow-Wine
    [89955] = 120762, -- Candied Jester's Coins
    [89957] = 120763, -- Dubious Camoran Throne
    [89971] = 120764, -- Jewels of Misrule
    [92433] = 124677, -- Crown Stout Magic Liqueur
    [92435] = 124675, -- Crown Combat Mystic's Stew
    [92474] = 124676, -- Crown Vigorous Ragout
    [92476] = 124678, -- Crown Vigorous Tincture
    [100488] = 133555, -- Spring-Loaded Infusion
    [100498] = 133556, -- Clockwork Citrus Filet
    [100502] = 133554, -- Deregulated Mushroom Stew
    [107748] = 139016, -- Artaeum Pickled Fish Bowl
    [107789] = 139018, -- Artaeum Takeaway Broth
    [127531] = 153625, -- Corrupting Bloody Mara
    [127572] = 153627, -- Pack Leader's Bone Broth
    [127596] = 153629, -- Bewitched Sugar Skulls
    [148633] = 171322, -- Sparkling Mudcrab Apple Cider
    [245302] = 120436, -- Princess's Delight
}

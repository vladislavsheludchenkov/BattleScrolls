-- Battle Scrolls Localization - English (Default)
-- This file defines all string IDs using ZO_CreateStringId
-- Other language files use SafeAddString to provide translations

-------------------------
-- Core UI Labels
-------------------------
ZO_CreateStringId("BATTLESCROLLS_UI_NAME", "Battle Scrolls")
ZO_CreateStringId("BATTLESCROLLS_UI_SETTINGS", "Settings")
ZO_CreateStringId("BATTLESCROLLS_UI_FILTER", "Filter")
ZO_CreateStringId("BATTLESCROLLS_UI_FILTER_ACTIVE", "Filter (Active)")
ZO_CreateStringId("BATTLESCROLLS_UI_SWITCH_TO", "Switch to <<1>>")

-------------------------
-- Zone/Instance Tabs
-------------------------
ZO_CreateStringId("BATTLESCROLLS_TAB_ALL_ZONES", "All zones")
ZO_CreateStringId("BATTLESCROLLS_TAB_INSTANCED", "Instanced")
ZO_CreateStringId("BATTLESCROLLS_TAB_OVERLAND", "Overland")
ZO_CreateStringId("BATTLESCROLLS_TAB_HOUSES", "Houses")
ZO_CreateStringId("BATTLESCROLLS_TAB_PVP", "PvP")

-------------------------
-- Encounter Tabs
-------------------------
ZO_CreateStringId("BATTLESCROLLS_TAB_ALL_ENCOUNTERS", "All encounters")
ZO_CreateStringId("BATTLESCROLLS_TAB_BOSS_ENCOUNTERS", "Boss encounters")
ZO_CreateStringId("BATTLESCROLLS_TAB_OTHER_ENCOUNTERS", "Other encounters")
ZO_CreateStringId("BATTLESCROLLS_TAB_PLAYER_ENCOUNTERS", "Player encounters")
ZO_CreateStringId("BATTLESCROLLS_TAB_TARGET_DUMMY", "Target dummy")

-------------------------
-- Stats Tabs
-------------------------
ZO_CreateStringId("BATTLESCROLLS_TAB_OVERVIEW", "Overview")
ZO_CreateStringId("BATTLESCROLLS_TAB_BOSS_DAMAGE_DONE", "Boss Damage Done")
ZO_CreateStringId("BATTLESCROLLS_TAB_DAMAGE_DONE", "Damage Done")
ZO_CreateStringId("BATTLESCROLLS_TAB_DAMAGE_TAKEN", "Damage Taken")
ZO_CreateStringId("BATTLESCROLLS_TAB_HEALING_OUT", "Healing Out")
ZO_CreateStringId("BATTLESCROLLS_TAB_SELF_HEALING", "Self Healing")
ZO_CreateStringId("BATTLESCROLLS_TAB_HEALING_IN", "Healing In")
ZO_CreateStringId("BATTLESCROLLS_TAB_DAMAGE", "Damage")
ZO_CreateStringId("BATTLESCROLLS_TAB_HEALING", "Healing")
ZO_CreateStringId("BATTLESCROLLS_TAB_EFFECTS", "Effects")
ZO_CreateStringId("BATTLESCROLLS_TAB_EFFECTS_PLAYER", "Your Effects")
ZO_CreateStringId("BATTLESCROLLS_TAB_EFFECTS_BOSS", "Boss Effects")
ZO_CreateStringId("BATTLESCROLLS_TAB_EFFECTS_GROUP", "Group Effects")
ZO_CreateStringId("BATTLESCROLLS_TAB_GROUP", "Group")
ZO_CreateStringId("BATTLESCROLLS_TAB_ACTIVITY", "Activity")

-------------------------
-- Weaving Stats
-------------------------
ZO_CreateStringId("BATTLESCROLLS_HEADER_WEAVING", "Weaving")
ZO_CreateStringId("BATTLESCROLLS_HEADER_WEAVING_BY_ABILITY", "Weaving by Ability")
ZO_CreateStringId("BATTLESCROLLS_STAT_AVG_WEAVE_TIME", "Average Cast Delay")
ZO_CreateStringId("BATTLESCROLLS_STAT_WEAVE_TIME_BEFORE", "Weave Time Before")
ZO_CreateStringId("BATTLESCROLLS_STAT_TIME_LOST", "Time Lost")
ZO_CreateStringId("BATTLESCROLLS_STAT_LIGHT_ATTACKS", "Light Attacks")
ZO_CreateStringId("BATTLESCROLLS_STAT_HEAVY_ATTACKS", "Heavy Attacks")
ZO_CreateStringId("BATTLESCROLLS_STAT_SKILL_ACTIVATIONS", "Skill Casts")
ZO_CreateStringId("BATTLESCROLLS_STAT_CASTS", "Casts")
ZO_CreateStringId("BATTLESCROLLS_STAT_WEAVING_ERRORS", "Weaving Errors")
ZO_CreateStringId("BATTLESCROLLS_STAT_MISSED_LA", "Missed Light Attacks")
ZO_CreateStringId("BATTLESCROLLS_STAT_DOUBLE_LA", "Double Light Attacks")

-- Weaving Tooltip Descriptions
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_DELAY_AFTER", "Delay After Cast")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_DELAY_BEFORE", "Delay Before Cast")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_INTER_CAST_DESC", "Average gap between casts, measured from the end of a skill's global cooldown or cast time to your next action. Combat Metrics calls this Weaving Average.")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_TIME_LOST_DESC", "Short cast delays added up over the fight, excluding gaps of 3 seconds or more (Downtime). Combat Metrics calls this Weaving Total.")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MISSED_LA_DESC", "Skills cast right after another skill, with no light attack in between.")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_DOUBLE_LA_DESC", "Two light attacks in a row, with no skill in between.")
ZO_CreateStringId("BATTLESCROLLS_FORMAT_SECONDS", "<<1>>s")
ZO_CreateStringId("BATTLESCROLLS_FORMAT_MILLISECONDS", "<<1>>ms")

-------------------------
-- Time Headers
-------------------------
ZO_CreateStringId("BATTLESCROLLS_TIME_TODAY", "Today")
ZO_CreateStringId("BATTLESCROLLS_TIME_YESTERDAY", "Yesterday")

-------------------------
-- DPS Meter Settings
-------------------------
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_DPS_METER", "DPS Meter")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_KEEP_AFTER_COMBAT", "Keep After Combat")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_HIDE_IMMEDIATELY", "Hide immediately")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_10_SECONDS", "10 seconds")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_30_SECONDS", "30 seconds")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_2_MINUTES", "2 minutes")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_5_MINUTES", "5 minutes")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_UNTIL_RELOAD", "Until reload")

ZO_CreateStringId("BATTLESCROLLS_SETTINGS_PERSONAL_METER", "Personal Meter")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_GROUP_METER", "Group Meter")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT", "Members of your group will still be able to see your DPS if they have the add-on installed.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_ENABLED", "Enabled")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_MODE", "Mode")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_DESIGN", "Design")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_OFFSET_FROM_LEFT", "Offset from Left")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_OFFSET_FROM_TOP", "Offset from Top")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SIZE", "Size")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RESET_POSITION", "Reset Position")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_POSITION", "Position")

-- Meter modes
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_MODE_AUTO", "Auto")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_MODE_DAMAGE", "Damage")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_MODE_HEALING", "Healing")

-- Meter size options
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SIZE_EXTRA_SMALL", "Extra Small")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SIZE_SMALL", "Small")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SIZE_MEDIUM", "Medium")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SIZE_LARGE", "Large")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SIZE_EXTRA_LARGE", "Extra Large")

-- Meter position options
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_POSITION_BELOW", "Below Personal")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_POSITION_ABOVE", "Above Personal")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_POSITION_SEPARATE", "Separate")

-- Auto mode tooltip
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_AUTO_MODE_TITLE", "Auto Mode")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_AUTO_MODE_TEXT", "Shows whichever value is higher - DPS or HPS.")

-------------------------
-- Personal Meter Designs
-------------------------
ZO_CreateStringId("BATTLESCROLLS_DESIGN_PERSONAL_DEFAULT", "Default")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_PERSONAL_MINIMAL", "Minimal")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_PERSONAL_BAR", "Bar")

-- Bar design settings
ZO_CreateStringId("BATTLESCROLLS_DESIGN_BAR_DIRECTION", "Bar Direction")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_BAR_DIRECTION_RIGHT", "Right")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_BAR_DIRECTION_LEFT", "Left")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_BAR_DIRECTION_CENTER", "Bidirectional")

-------------------------
-- Group Meter Designs
-------------------------
ZO_CreateStringId("BATTLESCROLLS_DESIGN_GROUP_TEXT", "Text")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_GROUP_HODOR", "Hodor")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_GROUP_HODOR_DESC", "Closely based on Hodor Reflexes by @andy.s and @m00nyONE.")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_GROUP_BARS", "Bars")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_GROUP_BARS_DESC", "Loosely inspired by Hodor Restyle by Hyperioxes.")

-- Text design settings
ZO_CreateStringId("BATTLESCROLLS_DESIGN_TEXT_COLUMNS", "Columns")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TITLE", "Column Layout")
ZO_CreateStringId("BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TEXT", "Groups of 4 or fewer always use 1 column.")

-------------------------
-- DPS Meter Display Strings
-- Note: DPS/HPS are universal gaming terms, hardcoded in code
-------------------------
ZO_CreateStringId("BATTLESCROLLS_METER_EFFECTIVE", "effective")
ZO_CreateStringId("BATTLESCROLLS_METER_EFF", "eff")
ZO_CreateStringId("BATTLESCROLLS_METER_BOSS", "Boss")
ZO_CreateStringId("BATTLESCROLLS_METER_ALL", "All")
ZO_CreateStringId("BATTLESCROLLS_METER_ALL_DAMAGE", "All damage")
ZO_CreateStringId("BATTLESCROLLS_METER_TOTAL", "Total")
ZO_CreateStringId("BATTLESCROLLS_METER_BOSS_ALL_DAMAGE", "Boss Damage / All Damage")
ZO_CreateStringId("BATTLESCROLLS_METER_EFFECTIVE_RAW_HEALING", "Effective / Raw Healing")

-- Group tracker tooltips
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA", "Show Without Group Data")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA_TEXT", "When enabled, the group tracker will display even when no other group members are sharing their DPS data. You'll see only your own stats on the tracker.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_GROUP_TRACKER_DESIGN", "Group Tracker Design")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION", "Group Tracker Position")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION_TEXT", "Below/Above: Attaches the group tracker to your personal meter.\nSeparate: Places the group tracker independently, allowing custom positioning.")

-------------------------
-- Recording Settings
-------------------------
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORDING", "Recording")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED", "Record in Instanced Zones")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED_TEXT", "Instanced zones include Dungeons, Trials, Arenas, and Infinite Archive.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_IN_OVERLAND", "Record in Overland Zones")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_IN_HOUSES", "Record in Houses")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_IN_PVP", "Record in PvP Zones")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_BOSS_FIGHTS", "Record Boss Fights")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS", "Record Basepop Fights")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS_TEXT", "Fights against non-boss, non-player enemies.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS", "Record Player Fights")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS_TEXT", "PvP fights against other players.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_DUMMY_FIGHTS", "Record Target Dummy Fights")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_IN_ADVENTURE_ZONE_TEXT",
    "When enabled, overrides Overland and Instanced zone toggles and records all fights in <<1>>. When disabled, has no effect.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE", "Recording Filters")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT", "Zone and fight type filters are combined: a fight must match at least one zone AND one fight type to be recorded.")

-- Storage/History settings
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT", "History Size Limit")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT_TITLE", "History Size Limit")
-- Storage size preset labels (dropdown options)
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XS", "Extra Small")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_SIZE_SMALL", "Small")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_SIZE_MEDIUM", "Medium")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_SIZE_LARGE", "Large")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XL", "Extra Large")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_SIZE_CAUTION", "Be Careful")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_SIZE_YOLO", "What Could Go Wrong?")
-- Storage tooltip
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC", "How much combat history to keep. When you exceed the limit, the oldest unlocked zones are automatically removed. You can lock individual zones to protect them from cleanup.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE", "This limit covers saved data only: fights, builds and settings. The add-on also uses memory for tracking the current combat and rendering the UI, so total usage will be higher than what's shown here.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT", "History: <<1>> MB of <<2>> MB (<<3>>%)")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_PROTECTED", "Locked fights, builds and settings alone exceed the limit: cleanup cannot get below it.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS", "Presets (trial run ~0.3 MB, dungeon ~0.15 MB, a night of prog ~1 MB):")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_XS", "  Extra Small: 5 MB - the freshest scrolls only")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL", "  Small: 8 MB - a healthy stack of scrolls")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM", "  Medium: 12 MB - a well-kept journal")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE", "  Large: 18 MB - a personal library")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_XL", "  Extra Large: 25 MB - a grand archive")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION", "  Be Careful: 35 MB - you really like data")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO", "  What Could Go Wrong?: 50 MB - you did that to yourself")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING", "About ESO memory limits: all add-ons share a 100 MB pool. At 70 MB, ESO shows a warning popup. At 100 MB, the UI reloads and disables everything. If you run many add-ons, pick a smaller preset. Tip: type /addonmemdisplay in chat to see a real-time memory tracker.")

-------------------------
-- Effect Tracking Settings
-------------------------
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_EFFECT_TRACKING", "Effect Tracking")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_PLAYER_BUFFS", "Buffs on yourself")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_PLAYER_DEBUFFS", "Debuffs on yourself")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_GROUP_BUFFS", "Group Buffs")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_BOSS_DEBUFFS", "Boss Debuffs")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECON_PRECISION", "Reconciliation")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECON_PRECISION_TOOLTIP", "How often to verify effect tracking against game state. Higher precision catches more missed events but uses more memory. Memory from verification calls is only freed on UI reload.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECON_MAX", "Max")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECON_HIGH", "High")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECON_NORMAL", "Normal")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECON_LOW", "Low")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECON_OFF", "Off")

-------------------------
-- Slider keybinds
-------------------------
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SLIDER_HOLD_FAST", "Hold to move faster")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SLIDER_RELEASE_PRECISION", "Release for precision")

-------------------------
-- Overview Stats
-------------------------
ZO_CreateStringId("BATTLESCROLLS_STAT_DURATION", "Duration")
ZO_CreateStringId("BATTLESCROLLS_STAT_PATCH", "Patch")
ZO_CreateStringId("BATTLESCROLLS_STAT_SUMMARY", "Summary")

-- Boss Damage
ZO_CreateStringId("BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE", "Personal Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_PERSONAL_BOSS_DPS", "Personal Boss DPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE_SHARE", "Personal Boss Damage Share")
ZO_CreateStringId("BATTLESCROLLS_HEADER_BOSS_DAMAGE_DONE", "Boss Damage Done")

-- Total Damage
ZO_CreateStringId("BATTLESCROLLS_STAT_PERSONAL_DAMAGE", "Personal Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_PERSONAL_DPS", "Personal DPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_PERSONAL_SHARE", "Personal Share")
ZO_CreateStringId("BATTLESCROLLS_HEADER_TOTAL_DAMAGE_DONE", "Total Damage Done")

-- Damage Taken
ZO_CreateStringId("BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN", "Total Damage Taken")
ZO_CreateStringId("BATTLESCROLLS_STAT_DTPS", "DTPS")
ZO_CreateStringId("BATTLESCROLLS_HEADER_DAMAGE_TAKEN", "Damage Taken")

-- Healing Overview
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_SELF_HEALING", "Raw Self Healing")
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_SELF_HPS", "Raw Self HPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_SELF_HEALING", "Effective Self Healing")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_SELF_HPS", "Effective Self HPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_HEALING_OUT", "Raw Healing Out")
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_HEALING_OUT_HPS", "Raw Healing Out HPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT", "Effective Healing Out")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT_HPS", "Effective Healing Out HPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_HEALING_IN", "Raw Healing In")
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_HEALING_IN_HPS", "Raw Healing In HPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN", "Effective Healing In")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN_HPS", "Effective Healing In HPS")
ZO_CreateStringId("BATTLESCROLLS_HEADER_HEALING", "Healing")
ZO_CreateStringId("BATTLESCROLLS_STAT_HPS", "HPS")

-- Proc Tracking
ZO_CreateStringId("BATTLESCROLLS_HEADER_PROC_TRACKING", "Proc Tracking")
ZO_CreateStringId("BATTLESCROLLS_STAT_TOTAL_PROCS", "<<1[$d proc/$d procs]>>")

-------------------------
-- Damage Stats Details
-------------------------
ZO_CreateStringId("BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE", "Total Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_BOSS_DPS", "Boss DPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_SHARE", "Group Share")
ZO_CreateStringId("BATTLESCROLLS_STAT_TOTAL_DAMAGE", "Total Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_DPS", "DPS")

ZO_CreateStringId("BATTLESCROLLS_HEADER_BY_ABILITY", "By Ability")
ZO_CreateStringId("BATTLESCROLLS_HEADER_CASTS", "Casts")
ZO_CreateStringId("BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE", "By Damage Type")
ZO_CreateStringId("BATTLESCROLLS_HEADER_DIRECT_VS_DOT", "Direct vs DoT")
ZO_CreateStringId("BATTLESCROLLS_HEADER_DAMAGE_DELIVERY", "Damage Delivery")
ZO_CreateStringId("BATTLESCROLLS_HEADER_AOE_VS_SINGLE", "AoE vs Single Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_BY_TARGET", "By Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_BY_SOURCE", "By Source")

ZO_CreateStringId("BATTLESCROLLS_STAT_DIRECT_DAMAGE", "Direct Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_DAMAGE_OVER_TIME", "Damage over Time")
ZO_CreateStringId("BATTLESCROLLS_STAT_AOE_DAMAGE", "AoE Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE", "Single Target Damage")

-------------------------
-- Healing Stats Details
-------------------------
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_HEALING", "Raw Healing")
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_HPS", "Raw HPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_HEALING", "Effective Healing")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_HPS", "Effective HPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_OVERHEAL", "Overheal")

ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT", "Raw Healing by Type")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT", "Effective Healing by Type")
ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET", "Raw Healing By Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY", "Raw Healing By Ability")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET", "Effective Healing By Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY", "Effective Healing By Ability")
ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE", "Raw Healing By Source")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE", "Effective Healing By Source")

ZO_CreateStringId("BATTLESCROLLS_STAT_DIRECT_HEALING", "Direct Healing")
ZO_CreateStringId("BATTLESCROLLS_STAT_HEALING_OVER_TIME", "Healing over Time")
ZO_CreateStringId("BATTLESCROLLS_STAT_SHIELD_HEALING", "Damage Shields")
ZO_CreateStringId("BATTLESCROLLS_STAT_REGEN_HEALING", "Health Recovery")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_UNKNOWN_SHIELDED", "Unknown (Shielded)")
ZO_CreateStringId("BATTLESCROLLS_HEALING_UNKNOWN_ABSORBED", "Unknown (Absorbed)")
ZO_CreateStringId("BATTLESCROLLS_HEALING_HEALTH_RECOVERY", "Health Recovery")

-------------------------
-- Effects Stats
-------------------------
ZO_CreateStringId("BATTLESCROLLS_HEADER_YOUR_BUFFS", "Your Buffs")
ZO_CreateStringId("BATTLESCROLLS_HEADER_DEBUFFS_ON_YOU", "Debuffs On You")
ZO_CreateStringId("BATTLESCROLLS_HEADER_BUFFS_ON_GROUP", "Buffs on Group")
ZO_CreateStringId("BATTLESCROLLS_HEADER_DEBUFFS_ON", "Debuffs on <<1>>")

ZO_CreateStringId("BATTLESCROLLS_EFFECT_UPTIME", "uptime")
ZO_CreateStringId("BATTLESCROLLS_EFFECT_YOURS", "yours")
ZO_CreateStringId("BATTLESCROLLS_EFFECT_AVG", "avg")
ZO_CreateStringId("BATTLESCROLLS_EFFECT_MEMBERS", "<<1[$d member/$d members]>>")

-------------------------
-- Effect Tooltips
-------------------------
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_TOTAL_UPTIME", "Total uptime")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_TOTAL_APPLICATIONS", "Total applications")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_YOUR_CONTRIBUTION", "Your contribution")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_YOUR_UPTIME", "Uptime")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_YOUR_APPLICATIONS", "Applications")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MAX_STACKS", "Max stacks")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_TIME_AT_MAX_STACKS", "Time at max stacks")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_YOUR_TIME_AT_MAX", "Your time at max")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_MEMBER", "Avg uptime per member")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MEMBERS_AFFECTED", "Members affected")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_AVG_UPTIME", "Avg uptime")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MAX_STACKS_OBSERVED", "Max stacks observed")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_AVG_TIME_AT_MAX", "Avg time at max stacks")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_YOUR_AVG_TIME_AT_MAX", "Your avg time at max")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_PEAK_INSTANCES", "Peak concurrent instances")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_INSTANCE", "Avg uptime per instance")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_PER_MEMBER", "Per member")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_YOU", "You")

-------------------------
-- Ability Tooltips
-------------------------
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_TOTAL", "Total")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_TYPE", "Type")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_DELIVERY", "Delivery")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_CRIT", "Crit")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_AVG_TICK", "Avg tick")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MIN_TICK", "Min tick")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MAX_TICK", "Max tick")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_TICKS", "Ticks")

ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_BY_TARGET", "By Target")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL", "Mean interval")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL", "Median interval")

ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_ABILITY", "Ability")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_ABILITY_ID", "Ability ID")

-------------------------
-- Damage Types
-------------------------
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_NONE", "None")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_GENERIC", "Generic")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_PHYSICAL", "Physical")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_FIRE", "Fire")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_SHOCK", "Shock")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_OBLIVION", "Oblivion")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_FROST", "Frost")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_EARTH", "Earth")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_MAGIC", "Magic")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_DROWN", "Drown")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_DISEASE", "Disease")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_POISON", "Poison")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_TYPE_BLEED", "Bleed")

-------------------------
-- Over Time/Direct Descriptions
-------------------------
ZO_CreateStringId("BATTLESCROLLS_DELIVERY_MIXED", "Mixed")
ZO_CreateStringId("BATTLESCROLLS_DELIVERY_DOT", "DoT")
ZO_CreateStringId("BATTLESCROLLS_DELIVERY_DIRECT", "Direct")
ZO_CreateStringId("BATTLESCROLLS_DELIVERY_HOT", "HoT")
ZO_CreateStringId("BATTLESCROLLS_DELIVERY_SHIELD", "Shield")
ZO_CreateStringId("BATTLESCROLLS_DELIVERY_REGEN", "Regen")
ZO_CreateStringId("BATTLESCROLLS_DELIVERY_HEAL_ABSORPTION", "Heal Absorption")

-------------------------
-- Filter Dialog
-------------------------
ZO_CreateStringId("BATTLESCROLLS_FILTER_DAMAGE_DONE", "Filter Damage Done")
ZO_CreateStringId("BATTLESCROLLS_FILTER_BOSS_DAMAGE", "Filter Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_FILTER_BY_SOURCE", "Filter by Source")
ZO_CreateStringId("BATTLESCROLLS_FILTER_BY_TARGET", "Filter by Target")
ZO_CreateStringId("BATTLESCROLLS_FILTER_BY_GROUP_MEMBER", "Filter by Group Member")
ZO_CreateStringId("BATTLESCROLLS_FILTER", "Filter")
ZO_CreateStringId("BATTLESCROLLS_FILTER_RESET", "Reset")
ZO_CreateStringId("BATTLESCROLLS_FILTER_DAMAGE_DONE_BY", "Damage Done By")
ZO_CreateStringId("BATTLESCROLLS_FILTER_DAMAGE_DONE_TO", "Damage Done To")
ZO_CreateStringId("BATTLESCROLLS_FILTER_BOSS_TARGET", "Boss Target")

-------------------------
-- Encounter Display
-------------------------
ZO_CreateStringId("BATTLESCROLLS_ENCOUNTER_FIGHT_IN_WITH", "Fight <<l:1>> with <<2>>")
ZO_CreateStringId("BATTLESCROLLS_ENCOUNTER_FIGHT_WITH", "Fight with <<1>>")
ZO_CreateStringId("BATTLESCROLLS_ENCOUNTER_FIGHT_IN", "Fight <<l:1>>")
ZO_CreateStringId("BATTLESCROLLS_ENCOUNTER_COMBAT", "Combat")
ZO_CreateStringId("BATTLESCROLLS_ENCOUNTER_MULTIPLE_ENEMIES", "<<2*1>>")
ZO_CreateStringId("BATTLESCROLLS_ENCOUNTER_INTO_INSTANCE", "into instance")
ZO_CreateStringId("BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX", "(Self)")

-------------------------
-- List States
-------------------------
ZO_CreateStringId("BATTLESCROLLS_LIST_LOADING", "Loading")
ZO_CreateStringId("BATTLESCROLLS_LIST_NO_DATA", "No combat data recorded")
ZO_CreateStringId("BATTLESCROLLS_LIST_NO_ENCOUNTERS", "No encounters")
ZO_CreateStringId("BATTLESCROLLS_LIST_NO_STATS", "No stats available")
ZO_CreateStringId("BATTLESCROLLS_LIST_NO_SETTINGS", "No settings available")

-------------------------
-- LibHarvensAddonSettings Integration
-------------------------
ZO_CreateStringId("BATTLESCROLLS_LIBHARVENS_OPEN_BUTTON", "Open Battle Scrolls")
ZO_CreateStringId("BATTLESCROLLS_LIBHARVENS_TOOLTIP", "You can also access Battle Scrolls from the <<1>> menu.")

-------------------------
-- Overview Panel
-------------------------
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_ENCOUNTER", "Encounter")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT", "Damage Output")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_SUMMARY", "Summary")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_TOTAL", "Total")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_SHARE", "Share")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_COMPOSITION", "Composition")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_QUALITY", "Quality")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_CRIT_RATE", "Crit Rate")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_MAX_HIT", "Max Hit")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_MAX_HEAL", "Max Heal")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_KEY_BUFFS", "Your Buffs")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_NO_EFFECTS", "No effects recorded")

-- Overview Panel Q3/Q4 Headers
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_TOP_ABILITIES", "Top Abilities")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_BOSSES", "Bosses")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_TARGETS", "Targets")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_SOURCES", "Sources")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_TARGETS_HEALED", "Targets Healed")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_HEALERS", "Healers")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_GROUP_BUFFS", "Group Buffs")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS", "Boss Debuffs")

ZO_CreateStringId("BATTLESCROLLS_BOSS_DAMAGE", "Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_DAMAGE_DONE", "Damage Done")
ZO_CreateStringId("BATTLESCROLLS_HEALING_OUT", "Healing Out")
ZO_CreateStringId("BATTLESCROLLS_SELF_HEALING", "Self Healing")
ZO_CreateStringId("BATTLESCROLLS_HEALING_IN", "Healing In")
ZO_CreateStringId("BATTLESCROLLS_AOE", "AoE")
ZO_CreateStringId("BATTLESCROLLS_SINGLE_TARGET", "Single Target")
ZO_CreateStringId("BATTLESCROLLS_HEALING_RAW_HPS", "Raw HPS")
ZO_CreateStringId("BATTLESCROLLS_HEALING_EFFECTIVE_HPS", "Effective HPS")
ZO_CreateStringId("BATTLESCROLLS_HEALING_OVERHEAL", "Overheal")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_DURATION", "Duration")

-------------------------
-- Group Stats
-------------------------
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_DAMAGE", "Group Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_DPS", "Group DPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE", "Group Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_BOSS_DPS", "Group Boss DPS")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_BOSS_DAMAGE", "Boss Damage")
-- Group Tab Enhancements
ZO_CreateStringId("BATTLESCROLLS_STAT_SURVIVABILITY", "Survivability")
ZO_CreateStringId("BATTLESCROLLS_BOSS_DAMAGE_TAKEN", "Boss Damage Taken")

-- Group Member Card Strings
ZO_CreateStringId("BATTLESCROLLS_GROUP_CARD_OF_GROUP", "of group")
ZO_CreateStringId("BATTLESCROLLS_GROUP_CARD_ALIVE", "Alive")

-- Group Tab Redesign
ZO_CreateStringId("BATTLESCROLLS_GROUP_DAMAGE_BY_TYPE", "Damage by Type")
ZO_CreateStringId("BATTLESCROLLS_GROUP_VS_AVERAGE", "vs DD Average")
ZO_CreateStringId("BATTLESCROLLS_GROUP_DD_COUNTED", "DDs Counted")
ZO_CreateStringId("BATTLESCROLLS_GROUP_DAMAGE_OUTPUT", "Damage Output")
ZO_CreateStringId("BATTLESCROLLS_GROUP_HEALING_OUTPUT", "Healing Output")
ZO_CreateStringId("BATTLESCROLLS_GROUP_RANK", "Rank")
ZO_CreateStringId("BATTLESCROLLS_GROUP_MAGICAL", "Magical")
ZO_CreateStringId("BATTLESCROLLS_GROUP_DEATH", "Death")
ZO_CreateStringId("BATTLESCROLLS_GROUP_FIRST_DEATH", "First Death")
ZO_CreateStringId("BATTLESCROLLS_GROUP_LAST_DEATH", "Last Death")
ZO_CreateStringId("BATTLESCROLLS_GROUP_DEATHS", "Deaths")
ZO_CreateStringId("BATTLESCROLLS_GROUP_COL_DEATHS", "Deaths")
ZO_CreateStringId("BATTLESCROLLS_GROUP_DEATH_COUNT", "<<1[$d Death/$d Deaths]>>")
ZO_CreateStringId("BATTLESCROLLS_GROUP_METRIC_DPS", "<<1>> DPS")
ZO_CreateStringId("BATTLESCROLLS_GROUP_METRIC_HPS", "<<1>> HPS")
ZO_CreateStringId("BATTLESCROLLS_GROUP_METRIC_DTPS", "<<1>> DTPS")
ZO_CreateStringId("BATTLESCROLLS_GROUP_METRIC_CRIT", "<<1>>% Crit")
ZO_CreateStringId("BATTLESCROLLS_GROUP_METRIC_OVERHEAL", "<<1>>% Overheal")
ZO_CreateStringId("BATTLESCROLLS_GROUP_TOP_INCOMING_DAMAGE", "Top Incoming Damage")
ZO_CreateStringId("BATTLESCROLLS_GROUP_DEATH_AT", "at <<1>>")
ZO_CreateStringId("BATTLESCROLLS_HEADER_DEATHS", "Deaths")
ZO_CreateStringId("BATTLESCROLLS_STAT_DEATH_COUNT", "Death Count")
ZO_CreateStringId("BATTLESCROLLS_DEATH_N", "Death <<1>>")

-------------------------
-- Group Context Tooltips
-------------------------
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_GROUP_TOTAL", "Group Total")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_GROUP_DPS", "Group DPS")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_GROUP_AVG", "DD Average")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN", "Group Breakdown")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_TAKEN", "Group Damage Taken")

-------------------------
-- Overview Panel - Ability Stats
-------------------------
ZO_CreateStringId("BATTLESCROLLS_STAT_MAX_PREFIX", "Max: <<1>>")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRIT_PERCENT", "<<1>>% crit")
ZO_CreateStringId("BATTLESCROLLS_STAT_PER_SECOND", "<<1>>/s")

-------------------------
-- Overview Panel - Effect Stats
-------------------------
ZO_CreateStringId("BATTLESCROLLS_EFFECT_APPS_COUNT", "<<1[$d application/$d applications]>>")
ZO_CreateStringId("BATTLESCROLLS_EFFECT_YOURS_PERCENT", "<<1>>% yours")
ZO_CreateStringId("BATTLESCROLLS_EFFECT_STACKS_COUNT", "×<<1[$d stack/$d stacks]>>")

-------------------------
-- Build Tab
-------------------------
ZO_CreateStringId("BATTLESCROLLS_TAB_BUILD", "Build")
ZO_CreateStringId("BATTLESCROLLS_SETUP_ABILITIES", "Abilities")
ZO_CreateStringId("BATTLESCROLLS_SETUP_FRONT_BAR", "Front Bar")
ZO_CreateStringId("BATTLESCROLLS_SETUP_BACK_BAR", "Back Bar")

ZO_CreateStringId("BATTLESCROLLS_SETUP_GEAR_SETS", "Gear Sets")
ZO_CreateStringId("BATTLESCROLLS_SETUP_EQUIPMENT", "Equipment")
ZO_CreateStringId("BATTLESCROLLS_SETUP_POISONS", "Poisons")
ZO_CreateStringId("BATTLESCROLLS_SETUP_CHARACTER", "Character")
ZO_CreateStringId("BATTLESCROLLS_SETUP_CLASS_SKILLS", "Class Skill Lines")
ZO_CreateStringId("BATTLESCROLLS_SETUP_CLASS_MASTERY", "Class Mastery")
ZO_CreateStringId("BATTLESCROLLS_SETUP_LOADOUT", "Loadout")
ZO_CreateStringId("BATTLESCROLLS_SETUP_PERKS", "Perks")
ZO_CreateStringId("BATTLESCROLLS_SETUP_MUNDUS", "Mundus")
ZO_CreateStringId("BATTLESCROLLS_SETUP_FOOD", "Food")
ZO_CreateStringId("BATTLESCROLLS_WEAPON_GREATSWORD", "Greatsword")
ZO_CreateStringId("BATTLESCROLLS_WEAPON_BATTLE_AXE", "Battle Axe")
ZO_CreateStringId("BATTLESCROLLS_WEAPON_MAUL", "Maul")

-------------------------
-- Food Buff Descriptions (generic foods, 14 stat combinations)
-------------------------
ZO_CreateStringId("BATTLESCROLLS_FOOD_MAX_HEALTH", "Maximum Health")
ZO_CreateStringId("BATTLESCROLLS_FOOD_MAX_MAGICKA", "Maximum Magicka")
ZO_CreateStringId("BATTLESCROLLS_FOOD_MAX_STAMINA", "Maximum Stamina")
ZO_CreateStringId("BATTLESCROLLS_FOOD_MAX_HEALTH_MAGICKA", "Maximum Health and Magicka")
ZO_CreateStringId("BATTLESCROLLS_FOOD_MAX_HEALTH_STAMINA", "Maximum Health and Stamina")
ZO_CreateStringId("BATTLESCROLLS_FOOD_MAX_MAGICKA_STAMINA", "Maximum Magicka and Stamina")
ZO_CreateStringId("BATTLESCROLLS_FOOD_MAX_TRISTAT", "Maximum Health, Magicka, and Stamina")
ZO_CreateStringId("BATTLESCROLLS_FOOD_HEALTH_RECOVERY", "Health Recovery")
ZO_CreateStringId("BATTLESCROLLS_FOOD_MAGICKA_RECOVERY", "Magicka Recovery")
ZO_CreateStringId("BATTLESCROLLS_FOOD_STAMINA_RECOVERY", "Stamina Recovery")
ZO_CreateStringId("BATTLESCROLLS_FOOD_HEALTH_MAGICKA_RECOVERY", "Health and Magicka Recovery")
ZO_CreateStringId("BATTLESCROLLS_FOOD_HEALTH_STAMINA_RECOVERY", "Health and Stamina Recovery")
ZO_CreateStringId("BATTLESCROLLS_FOOD_MAGICKA_STAMINA_RECOVERY", "Magicka and Stamina Recovery")
ZO_CreateStringId("BATTLESCROLLS_FOOD_RECOVERY_TRISTAT", "Health, Magicka, and Stamina Recovery")

-------------------------
-- Alchemy Traits
-------------------------
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT1", "Restore Health")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT2", "Ravage Health")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT3", "Restore Magicka")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT4", "Ravage Magicka")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT5", "Restore Stamina")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT6", "Ravage Stamina")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT7", "Increase Spell Resist")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT8", "Breach")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT9", "Increase Armor")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT10", "Fracture")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT11", "Increase Spell Power")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT12", "Cowardice")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT13", "Increase Weapon Power")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT14", "Maim")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT15", "Spell Critical")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT16", "Uncertainty")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT17", "Weapon Critical")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT18", "Enervation")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT19", "Unstoppable")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT20", "Entrapment")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT21", "Detection")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT22", "Invisible")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT23", "Speed")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT24", "Hindrance")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT25", "Protection")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT26", "Vulnerability")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT27", "Lingering Health")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT28", "Gradual Ravage Health")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT29", "Vitality")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT30", "Defile")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT31", "Heroism")
ZO_CreateStringId("BATTLESCROLLS_ALCHEMY_TRAIT32", "Timidity")

-------------------------
-- Misc
-------------------------
ZO_CreateStringId("BATTLESCROLLS_UNKNOWN", "Unknown")
ZO_CreateStringId("BATTLESCROLLS_UNKNOWN_BOSS", "Unknown Boss")

-------------------------
-- LibAsync Settings
-------------------------
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_PERFORMANCE", "Performance")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_ASYNC_SPEED", "Processing Speed")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_ASYNC_SPEED_PERFORMANCE", "Performance")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_ASYNC_SPEED_SMOOTH", "Smooth")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM", "Custom (<<1>> FPS)")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE", "Processing Speed")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT", "Controls how quickly background tasks are processed. This mostly affects the Journal UI and the time between combat ending and the encounter appearing in the list.\n\nPerformance: Fastest processing. May cause brief stutters in large content.\nSmooth: Smoother gameplay, slower processing. May cause encounters to get stuck loading or fail to appear in Journal.\n\nThis setting affects ALL add-ons using LibAsync.")

-------------------------
-- Onboarding
-------------------------
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_WELCOME_TITLE", "Welcome to Battle Scrolls")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_WELCOME_TEXT", "Battle Scrolls records your combat encounters and lets you review them later in the Journal.\n\nFeatures include:\n- Real-time DPS/HPS meters\n- Detailed damage and healing breakdowns\n- Buff/debuff uptime tracking\n- Boss debuff monitoring\n\nLet's configure a few things to get started.")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_GET_STARTED", "Get Started")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_GET_STARTED_DESC", "Walk me through the setup options")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_SKIP", "Skip Setup")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_SKIP_DESC", "I'll figure it out myself. Use recommended defaults.")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_METER_QUESTION", "Choose your DPS meter style:")
-- Meter preset labels and descriptions
ZO_CreateStringId("BATTLESCROLLS_PRESET_PERSONAL_MINIMAL", "Minimal")
ZO_CreateStringId("BATTLESCROLLS_PRESET_PERSONAL_MINIMAL_DESC", "Compact personal meter in screen corner")
ZO_CreateStringId("BATTLESCROLLS_PRESET_FULL_STACKED", "Personal + Group")
ZO_CreateStringId("BATTLESCROLLS_PRESET_FULL_STACKED_DESC", "Personal meter with group rankings below")
ZO_CreateStringId("BATTLESCROLLS_PRESET_HODOR", "Hodor Style")
ZO_CreateStringId("BATTLESCROLLS_PRESET_HODOR_DESC", "Group meter only, closely based on Hodor Reflexes (@andy.s, @m00nyONE)")
ZO_CreateStringId("BATTLESCROLLS_PRESET_BAR", "Progress Bar")
ZO_CreateStringId("BATTLESCROLLS_PRESET_BAR_DESC", "Progress bar for personal DPS")
ZO_CreateStringId("BATTLESCROLLS_PRESET_COLORFUL", "Colorful Bars")
ZO_CreateStringId("BATTLESCROLLS_PRESET_COLORFUL_DESC", "Colorful bars for personal and group DPS, group loosely inspired by Hodor Restyle (Hyperioxes)")
ZO_CreateStringId("BATTLESCROLLS_PRESET_DISABLED", "Disabled")
ZO_CreateStringId("BATTLESCROLLS_PRESET_DISABLED_DESC", "No meters, recording only")
-- Storage options
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_QUESTION", "How much history should we keep?")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL", "Minimal (5 MB)")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC", "About 15 trials worth")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE", "Moderate (12 MB)")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC", "About 40 trials worth")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS", "Generous (25 MB)")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC", "About 80 trials worth")
-- Effects tracking
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_EFFECTS_QUESTION", "How much buff/debuff tracking do you want?")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_EFFECTS_FULL", "Full Tracking")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_EFFECTS_FULL_DESC", "Track your buffs, boss debuffs, AND group buff uptimes (e.g. Major Courage uptimes across all group members)")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL", "Essential Only")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL_DESC", "Track your buffs and boss debuffs only. Skips group tracking to reduce memory usage.")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED", "Disabled")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED_DESC", "No buff/debuff tracking. Lowest memory usage, but no uptime data in reports.")
-- Completion
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_COMPLETE_TITLE", "You're All Set!")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_COMPLETE_TEXT", "Battle Scrolls is ready to track your combat.\n\nNow go fight something!\n\nYour encounters will appear here in the Journal. You can adjust these settings anytime from the Settings tab.")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_CHAT_MESSAGE", "[Battle Scrolls] Thanks for installing! Open Journal > Battle Scrolls to set up and activate.")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_CONTINUE", "Continue")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_FINISH", "Finish Setup")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_LETS_GO", "Let's Go!")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STEP_FORMAT", "Step <<1>> of <<2>>")

-------------------------
-- Delete Functionality
-------------------------
ZO_CreateStringId("BATTLESCROLLS_DELETE", "Delete")
ZO_CreateStringId("BATTLESCROLLS_DELETE_INSTANCE_TITLE", "Delete Zone")
ZO_CreateStringId("BATTLESCROLLS_DELETE_INSTANCE_TEXT", "Delete <<1>> and all its encounters?")
ZO_CreateStringId("BATTLESCROLLS_DELETE_ENCOUNTER_TITLE", "Delete Encounter")
ZO_CreateStringId("BATTLESCROLLS_DELETE_ENCOUNTER_TEXT", "Delete <<1>>?")
ZO_CreateStringId("BATTLESCROLLS_DELETE_WARNING", "This action cannot be undone.")
ZO_CreateStringId("BATTLESCROLLS_DELETE_MEMORY_FREE", "Frees approximately <<1>>")
ZO_CreateStringId("BATTLESCROLLS_DELETE_MEMORY_STATUS", "Memory: <<1>> of <<2>> (<<3>>%)")

-------------------------
-- Instance Locking
-------------------------
ZO_CreateStringId("BATTLESCROLLS_LOCK_ERROR_TITLE", "Cannot Lock")
ZO_CreateStringId("BATTLESCROLLS_LOCK_ERROR_TEXT", "Locking this zone would exceed your memory limit. Locked zones and the most recent zone are protected from cleanup.\n\nTo free up space, unlock or delete some locked zones, or increase your memory limit in Settings.")
ZO_CreateStringId("BATTLESCROLLS_LOCK_LOCKED_SIZE", "Currently locked: <<1>>")
ZO_CreateStringId("BATTLESCROLLS_LOCK_INSTANCE_SIZE", "This zone: <<1>>")
ZO_CreateStringId("BATTLESCROLLS_LOCK_LIMIT", "Memory limit: <<1>>")

-------------------------
-- Favorite Effects
-------------------------
ZO_CreateStringId("BATTLESCROLLS_FAVORITE_EFFECT", "Favorite")
ZO_CreateStringId("BATTLESCROLLS_UNFAVORITE_EFFECT", "Unfavorite")
ZO_CreateStringId("BATTLESCROLLS_CLEAR_ALL_FAVORITES", "Clear All Favorites")
ZO_CreateStringId("BATTLESCROLLS_CLEAR_ALL_FAVORITES_TOOLTIP", "Remove all effects from favorites. Favorite effects are shown at the top of every effects list.")

-------------------------
-- Dynamic Overview Panel
-------------------------
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN", "Damage Taken")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_TOP_HEALING", "Top Healing")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_TOP_INCOMING", "Top Incoming")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_HEALING_TARGETS", "Healing Targets")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES", "Damage Sources")

-------------------------
-- Group Table
-------------------------
ZO_CreateStringId("BATTLESCROLLS_GROUP_COL_NAME", "Name")
ZO_CreateStringId("BATTLESCROLLS_GROUP_COL_TOTAL", "Total")
ZO_CreateStringId("BATTLESCROLLS_GROUP_COL_CRIT", "Crit")
ZO_CreateStringId("BATTLESCROLLS_GROUP_COL_ALIVE", "Alive")

-------------------------
-- Aggregate
-------------------------
-- Navigation
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TITLE", "Aggregate")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENTRY", "Aggregate")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENTRY_DESC", "Build custom queries across encounters and instances")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENTRY_DESC_ENCOUNTER", "Aggregate metrics across encounters in this instance")

-- Scope section
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SCOPE", "Scope")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_INSTANCE_SCOPE", "Instance Scope")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_FILTER", "Time")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENCOUNTER_FILTER", "Encounter Filter")

-- Instance scope options
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SCOPE_EVERYTHING", "Everything")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SCOPE_INSTANCED", "All Instanced")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SCOPE_OVERLAND", "All Overland")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SCOPE_HOUSES", "All Houses")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SCOPE_PVP", "All PvP")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SCOPE_ZONES", "By Zone Name")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SCOPE_SPECIFIC", "Specific Instances")

-- Time filter options
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_ALL", "All Time")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_TODAY", "Today")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_24H", "Last 24 Hours")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_3D", "Last 3 Days")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_7D", "Last 7 Days")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_14D", "Last 14 Days")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_30D", "Last 30 Days")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_90D", "Last 90 Days")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIME_CUSTOM", "Custom...")

-- Encounter category options
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENC_ALL", "All Encounters")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENC_BOSS", "Boss Fights")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENC_TRASH", "Basepop Fights")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENC_PLAYER", "Player Fights")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENC_DUMMY", "Dummy Fights")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENC_SPECIFIC", "Specific Encounters")

-- Query section
ZO_CreateStringId("BATTLESCROLLS_PIVOT_QUERY", "Query")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DOMAIN", "Domain")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ROWS", "Rows")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_COLUMNS", "Columns")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_VALUES", "Values")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_AGGREGATION", "Aggregation")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_FILTERS", "Filters")

-- Target filter (Damage domain)
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TARGETS", "Targets")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TARGETS_ALL", "All Targets")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TARGETS_BOSSES", "Bosses Only")

-- Domain names
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DOMAIN_DAMAGE", "Damage")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DOMAIN_HEALING_OUT", "Healing Out")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DOMAIN_HEALING_IN", "Healing In")
-- Effects domain labels reuse BATTLESCROLLS_TAB_EFFECTS_* strings
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DOMAIN_GROUP", "Group")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DOMAIN_OVERVIEW", "Overview")

-- Dimension names
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_ABILITY", "Ability")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_TARGET", "Target")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_SOURCE", "Source")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_BOSS", "Boss")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_DAMAGE_TYPE", "Damage Type")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_DELIVERY", "Delivery")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_AOE_ST", "AoE / Single Target")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_BUFF_DEBUFF", "Buff / Debuff")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_GROUP_MEMBER", "Group Member")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_ROLE", "Role")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_ENCOUNTER", "Encounter")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DIM_INSTANCE", "Instance")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_COL_METRICS", "Metrics")

-- Metric names
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_TOTAL_DAMAGE", "Total Damage")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_DPS", "DPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_CRIT_PERCENT", "Crit %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_HIT_COUNT", "Hits")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_MAX_HIT", "Max Hit")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_MIN_HIT", "Min Hit")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_AVG_HIT", "Avg Hit")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HEALING", "Effective Healing")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_RAW_HEALING", "Raw Healing")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_RAW_HPS", "Raw HPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS", "Effective HPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_OVERHEAL_PERCENT", "Overheal %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_HEAL_CRIT_PERCENT", "Heal Crit %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_HEAL_HIT_COUNT", "Heal Hits")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_MAX_HEAL", "Max Heal")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_AVG_HEAL", "Avg Heal")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_UPTIME_PERCENT", "Uptime %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_PLAYER_UPTIME_PERCENT", "Your Uptime %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_APPLICATIONS", "Applications")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_MAX_STACKS_TIME", "Max Stacks Time %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_DPS", "DPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_BOSS_DPS", "Boss DPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_TOTAL_DAMAGE", "Total Damage")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_CRIT_PERCENT", "Crit %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_DOT_PERCENT", "DoT %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_AOE_PERCENT", "AoE %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_MAX_HIT", "Max Hit")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_DTPS", "DTPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_RAW_HPS", "Raw HPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_EFFECTIVE_HPS", "Effective HPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_OUT", "Effective HPS Out")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_OUT", "Raw HPS Out")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_IN", "Effective HPS In")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_IN", "Raw HPS In")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_BOSS_DPS", "Boss DPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_BOSS_DAMAGE", "Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_DTPS", "DTPS")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_DAMAGE_TAKEN", "Damage Taken")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_ALIVE_PERCENT", "Alive %")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_GROUP_DEATH_COUNT", "Deaths")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_DURATION", "Duration")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_DEATH_COUNT", "Deaths")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_AVG_WEAVE_TIME", "Average Cast Delay")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_TIME_LOST", "Time Lost")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_LIGHT_ATTACKS_PER_SEC", "LA/s")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_WEAVING_ERRORS", "Missed LAs")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_METRIC_DOUBLE_LA_ERRORS", "Double LAs")

-- Aggregation options
ZO_CreateStringId("BATTLESCROLLS_PIVOT_AGG_SUM", "Sum")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_AGG_AVG", "Average")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_AGG_MAX", "Max")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_AGG_MIN", "Min")

-- Actions
ZO_CreateStringId("BATTLESCROLLS_PIVOT_RUN", "Run Query")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SAVE", "Save Query")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_LOAD", "Load Query")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DELETE_QUERY", "Delete Query")

-- Loading / Results
ZO_CreateStringId("BATTLESCROLLS_PIVOT_LOADING", "Loading encounters... <<1>> / <<2>>")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_NO_RESULTS", "No data matches your query")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_NO_ENCOUNTERS", "No encounters match your filters")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_NO_BOSSES", "No boss encounters match your filters")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENCOUNTERS_PROCESSED", "<<1[$d encounter/$d encounters]>> processed")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ROWS_CAPPED", "Results limited to <<1>> rows")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_COLUMNS_CAPPED", "Results limited to <<1>> columns")

-- Save / Load dialogs
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SAVE_TITLE", "Save Query")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SAVE_PROMPT", "Enter a name for this query:")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SAVE_OVERWRITE", "A query named \"<<1>>\" already exists. Overwrite?")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_QUERY_SAVED", "Query saved as \"<<1>>\"")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_LOAD_TITLE", "Load Query")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DELETE_CONFIRM", "Delete query \"<<1>>\"?")

-- Selector dialogs
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SELECT_ZONES", "Select Zones")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SELECT_INSTANCES", "Select Instances")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SELECT_ENCOUNTERS", "Select Encounters")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SELECT_BOSSES", "Select Boss Names")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SELECT_METRICS", "Select Metrics")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SELECTED_COUNT", "<<1>> selected")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_SELECT_ALL", "Select All")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DESELECT_ALL", "Deselect All")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_NONE_SELECTED", "None selected")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_ENC_BOSS_NAMES", "By Boss Name")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_CUSTOM_DAYS", "Last <<1>> days")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_CUSTOM_RANGE_TITLE", "Custom Time Range")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_CUSTOM_DAYS_PROMPT", "Number of days back")

-- Tooltips for selector options
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIP_DOMAIN_OVERVIEW", "Aggregated summary across all damage, healing, and effects domains. Shows combined totals rather than individual breakdowns.")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIP_ENC_BOSS_NAMES", "Filters to encounters that feature the selected bosses. Select boss names in the next step.")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIP_DIM_DELIVERY", "Splits data by delivery method: Direct, DoT (Damage over Time), Heal Absorption, HoT (Heal over Time), Regen, Shield, or Mixed.")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIP_DIM_DAMAGE_TYPE", "Splits data by damage type: Physical, Fire, Shock, Frost, Magic, Poison, Disease, Bleed, Oblivion, and others.")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIP_DOMAIN_GROUP", "Per-member combat metrics like DPS, total damage, and crit rate. For buff/debuff uptimes on group members, use Group Effects.")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_TIP_AGGREGATION", "How values are combined when multiple encounters contribute to the same cell. For example, Average DPS shows the mean across encounters, while Max shows the best single encounter.")

-- Query description (subtitle)
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DESC_BY", "<<1>> by <<2>>")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DESC_CROSS", "× <<1>>")
ZO_CreateStringId("BATTLESCROLLS_PIVOT_DESC_N_METRICS", "<<1[$d metric/$d metrics]>>")

-- v17 storage migration (auto-runs once after login when legacy encounters exist)
ZO_CreateStringId("BATTLESCROLLS_MIGRATION_START", "One-time storage upgrade in progress - expect brief stutters for a few minutes")
ZO_CreateStringId("BATTLESCROLLS_MIGRATION_DONE", "Storage upgrade complete! <<1>> fights re-encoded, <<2>> MB freed")
ZO_CreateStringId("BATTLESCROLLS_MIGRATION_TIP", "You can now lower the memory preset in the settings - the new format fits far more history in every MB.")

-- Online sharing (journal keybinds -> browser upload at the share site)
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SHARE_PART_SIZE", "Share Part Size")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_SHARE_PART_SIZE_TEXT", "How much combat data to send each time the browser opens, measured in characters. Smaller parts can help if confirming a share does not open the browser. Larger parts need fewer confirmations, but may fail to open. Default: 7000. To use a new size, cancel any current share and start sharing again.")
ZO_CreateStringId("BATTLESCROLLS_SHARE_FIGHT", "Share Fight")
ZO_CreateStringId("BATTLESCROLLS_SHARE_INSTANCE", "Upload All Fights")
ZO_CreateStringId("BATTLESCROLLS_SHARE_PREPARING", "Preparing your share...")
ZO_CreateStringId("BATTLESCROLLS_SHARE_TITLE", "Sharing")
ZO_CreateStringId("BATTLESCROLLS_SHARE_PROGRESS_HEADER", "Parts")
ZO_CreateStringId("BATTLESCROLLS_SHARE_PART_SENT", "Part <<1>> — sent")
ZO_CreateStringId("BATTLESCROLLS_SHARE_PART_READY", "Part <<1>> — ready to send")
ZO_CreateStringId("BATTLESCROLLS_SHARE_PART_PENDING", "Part <<1>>")
ZO_CreateStringId("BATTLESCROLLS_SHARE_SEND_PART", "Send Part <<1>> of <<2>>")
ZO_CreateStringId("BATTLESCROLLS_SHARE_HINT_HEADER", "How this works")
ZO_CreateStringId("BATTLESCROLLS_SHARE_PRIVACY_TITLE", "Player names and combat data will be stored online")
ZO_CreateStringId("BATTLESCROLLS_SHARE_PRIVACY_NOTICE", "Uploads include your and other players' names, platform, game server, combat statistics and builds. Reports have no automatic expiry, and anyone with the link can view or download them. Let affected players know before sharing. Privacy and removal requests: <<1>>")
ZO_CreateStringId("BATTLESCROLLS_SHARE_TT_READY", "Confirm the prompt the game shows — the browser page it opens forwards this part of the combat data to the share site, then the browser can be closed. Return to the game and send the next part; progress is kept even if you leave this screen. Once every part has arrived, the page shows your unlisted share link and QR code.")
ZO_CreateStringId("BATTLESCROLLS_SHARE_TT_SENT", "This part has already been handed to the browser. If the browser page reports it missing (a crashed tab loses its part), select this row and press the resend keybind.")
ZO_CreateStringId("BATTLESCROLLS_SHARE_TT_PENDING", "Parts are sent one at a time, in order — this one unlocks when its turn comes.")
ZO_CreateStringId("BATTLESCROLLS_SHARE_TT_DONE", "The browser page now shows the unlisted share link and QR code — only people with the link can open it. If the page reports missing parts, select them above and resend them. Finish Sharing forgets the upload on the game side.")
ZO_CreateStringId("BATTLESCROLLS_SHARE_CHOICE_HEADER", "Choose what to send")
ZO_CreateStringId("BATTLESCROLLS_SHARE_CHOICE_FULL", "All fights (<<1>>)")
ZO_CreateStringId("BATTLESCROLLS_SHARE_CHOICE_BOSSES", "Bosses only (<<1>>)")
ZO_CreateStringId("BATTLESCROLLS_SHARE_CHOICE_PARTS", "Parts to send: <<1>>")
ZO_CreateStringId("BATTLESCROLLS_SHARE_TT_CHOICE_FULL", "Every recorded fight in this instance, including basepop fights. More data — more parts to send through the browser.")
ZO_CreateStringId("BATTLESCROLLS_SHARE_TT_CHOICE_BOSSES", "Boss fights only. Basepop fights usually dominate the upload size, so this needs far fewer parts.")
ZO_CreateStringId("BATTLESCROLLS_SHARE_DONE_HEADER", "All parts sent")
ZO_CreateStringId("BATTLESCROLLS_SHARE_DONE_HINT", "The share link and QR code are on the browser page.")
ZO_CreateStringId("BATTLESCROLLS_SHARE_CONTINUE", "Continue Sharing")
ZO_CreateStringId("BATTLESCROLLS_SHARE_CANCEL", "Cancel Sharing")
ZO_CreateStringId("BATTLESCROLLS_SHARE_FAILED", "Could not prepare the share.")
ZO_CreateStringId("BATTLESCROLLS_SHARE_RESEND_PART", "Resend Part <<1>>")
ZO_CreateStringId("BATTLESCROLLS_SHARE_PART_RESENDING", "Part <<1>> — resending…")
ZO_CreateStringId("BATTLESCROLLS_SHARE_FINISH", "Finish Sharing")

-- Renaming (instances/encounters)
ZO_CreateStringId("BATTLESCROLLS_RENAME", "Rename")
ZO_CreateStringId("BATTLESCROLLS_RENAME_TEXT", "Enter a new name. Enter the original name (<<1>>) to reset it.")

-- Group damage tab (everything the client observed: self + others, one pool)
ZO_CreateStringId("BATTLESCROLLS_TAB_GROUP_DAMAGE", "Group Damage")
ZO_CreateStringId("BATTLESCROLLS_FILTER_GROUP_DAMAGE", "Filter Group Damage")
ZO_CreateStringId("BATTLESCROLLS_FILTER_OTHERS", "Others")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_SCOPE", "All damage your game client observed: your own (including pets and companions) and damage from other players nearby. ESO does not identify those other players, so their damage is combined under Others.")

-- Group table resurrection column
ZO_CreateStringId("BATTLESCROLLS_GROUP_COL_RES", "Res")

-- Group bar color preference
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_BAR_COLOR", "Your Bar Color")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_BAR_COLOR_TEXT", "Group members using Battle Scrolls with the Bars design see your bar in this color. This works even if you use another design or turn off your own group meter.")
ZO_CreateStringId("BATTLESCROLLS_COLOR_DEFAULT", "Default")
ZO_CreateStringId("BATTLESCROLLS_COLOR_WHEEL", "Hue and saturation")
ZO_CreateStringId("BATTLESCROLLS_COLOR_BRIGHTNESS", "Brightness")
ZO_CreateStringId("BATTLESCROLLS_COLOR_HEX", "Hex code")
ZO_CreateStringId("BATTLESCROLLS_COLOR_HEX_INVALID", "Enter six hex digits, for example #3EB6FF.")
ZO_CreateStringId("BATTLESCROLLS_COLOR_SAVE", "Save")
ZO_CreateStringId("BATTLESCROLLS_COLOR_SAVE_HINT", "Your bar will use this color in everyone’s Battle Scrolls Bars meter, whatever design you use.")

-- Ultimate tracking (Activity tab)
ZO_CreateStringId("BATTLESCROLLS_HEADER_ULTIMATE", "Ultimate")
ZO_CreateStringId("BATTLESCROLLS_STAT_ULT_AT_ENTRY", "Ultimate at Combat Start")
ZO_CreateStringId("BATTLESCROLLS_STAT_ULT_GENERATED", "Ultimate Generated")
ZO_CreateStringId("BATTLESCROLLS_STAT_ULT_SPENT_DRAINED", "Ultimate Spent & Drained")
ZO_CreateStringId("BATTLESCROLLS_STAT_ULT_SPENT", "Ultimate Spent")
ZO_CreateStringId("BATTLESCROLLS_STAT_ULT_LOST", "Lost on Cast")
ZO_CreateStringId("BATTLESCROLLS_STAT_ULT_LOST_TT", "Casting an ultimate empties the whole pool, so anything above its cost is lost.")
ZO_CreateStringId("BATTLESCROLLS_STAT_ULT_DRAINED", "Ultimate Drained")
ZO_CreateStringId("BATTLESCROLLS_HEADER_ULT_SOURCES", "Ultimate Generation by Source")
ZO_CreateStringId("BATTLESCROLLS_ULT_BASE_GENERATION", "Base Generation")
ZO_CreateStringId("BATTLESCROLLS_ULT_HEROISM_LINE", "Includes <<C:1>>: <<2>>% uptime, est. <<3>>")
ZO_CreateStringId("BATTLESCROLLS_HEADER_ULT_CASTS", "Ultimates Used")

-- Arcanist Crux tracking (Activity tab)
ZO_CreateStringId("BATTLESCROLLS_HEADER_CRUX", "Crux")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_GENERATORS", "Generator Casts")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_AT_FULL", "Cast at Full Crux")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_SPENDERS", "Spender Casts")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_UNDER", "Cast Under 3 Crux")
ZO_CreateStringId("BATTLESCROLLS_CRUX_AT_N", "At <<1>> Crux: <<2>>")
ZO_CreateStringId("BATTLESCROLLS_HEADER_CRUX_BY_ABILITY", "Crux Usage by Ability")

-- Z'en / DoT stacking (Activity tab)
ZO_CreateStringId("BATTLESCROLLS_HEADER_ZEN", "DoT Stacking (Z'en)")
ZO_CreateStringId("BATTLESCROLLS_ZEN_AVG_DOTS", "Average DoTs")
ZO_CreateStringId("BATTLESCROLLS_ZEN_UPTIME", "Your Z'en uptime")
ZO_CreateStringId("BATTLESCROLLS_ZEN_PEAK_TIME", "Time at <<1>>")
ZO_CreateStringId("BATTLESCROLLS_ZEN_DOTS_LABEL", "<<1>> DoTs")
ZO_CreateStringId("BATTLESCROLLS_ZEN_SHARE_LINE", "avg <<1>> — <<2>> at 5 DoTs")
ZO_CreateStringId("BATTLESCROLLS_ZEN_SHORT", "Z'en")
ZO_CreateStringId("BATTLESCROLLS_ZEN_NOTE", "Your DoTs are tracked even when you aren't wearing Z'en. They show the bonus you could support if your Z'en debuff were active. Time without your Z'en represents potential only.")
ZO_CreateStringId("BATTLESCROLLS_ZEN_DISTRIBUTION_NOTE", "Each DoT row shows its share of tracked time. The Z'en percentage is the portion of that row's time when your own debuff was active.")

-- Support (Activity tab)
ZO_CreateStringId("BATTLESCROLLS_HEADER_SUPPORT", "Support")
ZO_CreateStringId("BATTLESCROLLS_STAT_RESURRECTIONS", "Resurrections")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_PASSIVE", "Lost Outside Casts")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_PASSIVE_TT", "Crux that faded on its own, with no spender cast or death nearby. Crux expires after 30 seconds.")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_DEATH", "Lost to Death")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_PROC_WASTED", "Passive Gains at Full Crux")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_PROC_WASTED_TT", "Passive gains that fired while you already had 3 Crux, so they gave nothing. <<1>> and its morphs and <<2>> only grant Crux when you have none, so they are never counted here.")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_CONDITIONAL_TT", "Crux this source generated passively, without a cast.")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_OTHER", "Other Crux Gains")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRUX_OTHER_TT", "Crux gained with no tracked source firing at the time.")
ZO_CreateStringId("BATTLESCROLLS_HEADER_CRUX_GAINED", "Crux Gained by Ability")

-- Activity overview panel: column legends and extra rows
ZO_CreateStringId("BATTLESCROLLS_STAT_DOWNTIME", "Downtime")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_DOWNTIME_DESC", "Gaps of 3 seconds or more between casts, such as mechanics, resurrecting or being dead. Not counted in the cast delay.")
ZO_CreateStringId("BATTLESCROLLS_STAT_PER_MINUTE", "<<1>>/min")
ZO_CreateStringId("BATTLESCROLLS_DETAIL_MEDIAN", "median <<1>>")
ZO_CreateStringId("BATTLESCROLLS_DETAIL_DELAY", "<<1>> delay")
ZO_CreateStringId("BATTLESCROLLS_DETAIL_AT_FULL", "<<1>> at full")
ZO_CreateStringId("BATTLESCROLLS_DETAIL_LOST", "<<1>> lost")
ZO_CreateStringId("BATTLESCROLLS_DETAIL_AVG_DOTS", "avg <<1>> DoTs")
ZO_CreateStringId("BATTLESCROLLS_DETAIL_AT_DOTS", "<<1>> at <<2>>")

-- Release history (full notes, also available from the Journal).
ZO_CreateStringId("BATTLESCROLLS_WHATS_NEW", "What's New")
ZO_CreateStringId("BATTLESCROLLS_WHATS_NEW_DESC", "Read what changed in Battle Scrolls, from the latest update back to the first public release.")
ZO_CreateStringId("BATTLESCROLLS_RELEASE_6_0_1", [=[
|cD4AF37Bugfixes:|r

- Your server histories were merged automatically on login and are now visible together in the Journal. History from other servers has always used memory and storage, even when it wasn't visible in the Journal.

- Storage and settings are shared across servers. The larger of your previous storage limits was kept; other settings were taken from the server you first logged into after updating. Favorites, saved Aggregate queries, locked runs, custom names and personal build snapshots are preserved.

- Automatic cleanup now considers runs from all servers together.

- PlayStation shares now use smaller parts to help with fights that would not open in the browser. Larger fights may take more steps; you can experiment with Share Part Size in Settings.
]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_6_0_0", [=[
|cD4AF37New features:|r

- |cD4AF37Your scrolls can leave Tamriel now!|r Share a fight or a whole run from the Journal and open it in a browser. Scan the QR code on your TV to get the link on your phone. From there, explore the fight yourself or share it wherever you want

- Explore the same combat and build data as in the add-on, with |cFFFFFFCSV and JSON|r export for your own analysis

- Activity now tracks |cFFFFFFUltimate generation and spending|r, |cFFFFFFArcanist Crux usage|r, Z'en DoT stacking and resurrections. DoT counts show the potential Z'en bonus even without wearing the set. Weaving separates short cast delays from longer downtime

- Your death recaps now show |cFFFFFFattacker names|r when available

- |cFFFFFFGroup Damage|r shows all damage your client observed, including players without Battle Scrolls. ESO doesn't identify those other sources, so they share one "|cFFFFFFOthers|r" pool

- Pick your own |cFFFFFFbar color|r for everyone's |cFFFFFFBars meter|r, and rename runs and fights in your history

- |cFFFFFFWhat's New|r is now in the Journal, with dated release notes in all seven languages. In case you missed a few scrolls

|cD4AF37Major changes:|r

- Reworked combat history storage fits substantially |cFFFFFFmore fights|r in the same space. The new format should also mean |cFFFFFFfewer stutters|r after big encounters and |cFFFFFFmuch faster loading|r when opening fights in the Journal. Existing history upgrades |cFFFFFFautomatically|r in the background after login; expect brief stutters during this one-time process. Each fight is checked against its original before being replaced

|cD4AF37Bugfixes:|r

- Fights should be |cFFFFFFmuch less likely to end early|r when you die while your group keeps fighting, especially in Lucent Citadel's final encounter

- Fixed |cFFFFFFhealing calculations|r ignoring some filters, missing poisons in other group members’ builds, and several group sharing and history cleanup edge cases

- |cFFFFFFMore reliable|r group fight summaries and builds, with fewer missing details after door transitions and loading screens

|cE6B566Known issues:|r

- ESO's Add-On Memory gauge may need a |cFFFFFFUI reload|r to reflect the space freed by the storage upgrade

- Poison effect names in builds may be missing or incorrect with |cFFFFFFUpdate 51's alchemy changes|r. Crafted poison effects are not shown in the web viewer

- Web sharing has not been tested on |cFFFFFFPlayStation|r. Please report any problems, including if it does not work at all for you]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_5_3_1", [=[
|cD4AF37Bugfixes:|r

- Other players' class masteries and skill lines are now correctly displayed in their builds on the |cFFFFFFGroup tab|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_5_3_0", [=[
|cD4AF37New features:|r

- |cFFFFFFClass Mastery|r passives are now supported and shown instead of the skill line list when there's at least one purchased

- First-class support for |cFFFFFFVengeance|r, with custom Build overview hiding irrelevant parts and showing vengeance-specific details (Loadout and Perks)

|cD4AF37Small changes:|r

- Trash is now called basepop in English to match the language devs are using]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_5_2_0", [=[
|cD4AF37New features:|r

- |cFFFFFFHealth Recovery|r is now tracked as healing. It contributes raw healing based on your in-combat |cFFFFFFHealth Recovery|r stat, and the effective vs overheal split is estimated from actual health movement during the fight. It is considered a separate delivery type

- |cFFFFFFHeal Absorption|r applied to the player is now tracked as damage taken as a separate delivery type

- Outgoing and incoming shielded damage is now included in total damage / damage taken and derivatives such as DPS/DTPS, but not in ability/type breakdowns

- Outgoing and incoming absorbed healing is now included in healing out / self-healing / healing in and derivatives such as HPS

|cD4AF37Minor changes:|r

- Detailed lists always show up to 50 abilities and 20 targets/sources instead of 25/15/10 depending on the context

|cD4AF37Bugfixes:|r

- |cFFFFFFHealing Out|r delivery aggregations now include self-healing consistently with other |cFFFFFFHealing Out|r aggregation views

|cE6B566Known issues:|r

- |cFFFFFFHealth Recovery|r raw healing is estimated from elapsed alive time without knowing ESO's hidden tick phase. Effective vs overheal split is best effort and may undercount effective recovery when health recovery is hidden inside a net-negative health change]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_5_1_0", [=[
|cD4AF37New features:|r

- Damage shields applied on you and your group members are now tracked as healing. Shield applications count as raw healing, and shield value that actually absorbs damage is counted as effective healing

- Healing breakdowns now include |cFFFFFFDamage Shields|r as their own healing type, next to Direct and HoT healing. This shows up in healing tabs, overview panels, and |cFFFFFFHealing Out|r aggregations

|cE6B566Known issues:|r

- In rare cases, shield ticks may be attributed to a wrong ability. This only happens when there are multiple shields applied on the same target within 50 ms of each other

|cD4AF37Minor changes:|r

- Ability tooltips now show the actual ESO ability ID in damage, healing, effects, proc, weaving, and setup views

- Fixed several wrong or generic ability icons caused by ESO reporting hidden/helper ability IDs, including Pragmatic Fatecarver, Radiant Glory, Cephaliarch's Flail, potions, Essence Drain, Undaunted Command, Purify/Blood Feast synergies, Runeguard of Still Waters, Purifying Light, Practiced Incantation, and Harmony trait

- It takes more HPS now to fill the personal meter bar

- Healing composition labels now say "Healing by Type" and hide insignificant one-sided breakdowns

|cD4AF37Bugfixes:|r

- Weaving stats should produce fewer false missed and double light attacks

- Enemies are more reliably classified as bosses when effect tracking is disabled

- Some healing ability tooltips no longer have average tick lower than min tick]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_5_0_0", [=[
|cD4AF37New features:|r

- |cFFFFFFWeaving tracking is here!|r Tracks average and total |cFFFFFFtime lost|r between casts, counts missed light attacks/skills. With overall aggregated data and a per skill breakdown

- Added a new |cFFFFFFActivity tab|r where weaving data lives now

- Weaving data is also accessible for aggregations, but only with Overview domain selected

|cD4AF37Minor changes:|r

- |cFFFFFFProc tracking|r moved from |cFFFFFFOverview tab|r (have you noticed it was there the whole time?) to the new Activity tab

- Memory usage and performance should be a bit better in and out of combat, especially with effect tracking disabled partially or completely

|cD4AF37Bugfixes:|r

- Players that have effect tracking disabled in their settings now show proper alive time % on group tab instead of always 100%]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_4_0_0", [=[
|cD4AF37New features:|r

- Have you ever thought "I wish my fantasy MMORPG had |cFFFFFFspreadsheets built-in|r"? Probably not, but it's there now. Aggregate over any amount of past encounters, extracting the data you want to see, with |cFFFFFFpivot tables|r support.

|cD4AF37Minor changes:|r

- Current patch version (such as 11.3.5) is now displayed in each encounter

- Other players will see you reading a scroll (what else would it be?) while you're in Battle Scrolls UI

- Instance name is now displayed as list header in encounter list

|cD4AF37Bugfixes:|r

- Prismatic reduce cost enchantment is now correctly displayed when someone in your group is using it

- Layout of build screen is now consistent between Group and Build tabs]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_3_1_0", [=[
|cD4AF37New features:|r

- Added |cFFFFFFsearch|r to the |cFFFFFFEffects tab|r. Works similarly to how you would search your inventory

|cD4AF37Bugfixes:|r

- Arcanists are no longer missing Race/Class/Mundus line on the Setup screen when looking at other players on |cFFFFFFGroup tab|r

- Reduces |cFFFFFFflickering|r happening in Group menu (again)]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_3_0_2", [=[
|cFFFFFFReduces flickering happening in Group menu|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_3_0_1", [=[
|cD4AF37Bugfixes:|r

- |cFFFFFFChampion points|r of group members shouldn't be reported in wrong constellations when you have empty slots (sender-side fix, so requires your groupmate to be on the new version)

- No longer tries to display build information when it's unavailable for a group member when navigating the list from an entry that did have it available]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_3_0_0", [=[
|cD4AF37Build tracking|r

- Each fight now records the build and displays it on the new |cFFFFFFBuild tab|r, so you can go back and see exactly what you were running

- |cFFFFFFOverview tab|r now also displays most of your build for easier parse bragging

- |cFFFFFFCharacter menu|r now includes high-level overview of your build at a glance

- |cFFFFFFGroup tab|r has been also updated to record setups of other players who use Battle Scrolls in your group]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_2_1_2", [=[
|cFFFFFFNo visible changes, preparation for v3 release|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_2_1_1", [=[
|cFFFFFFUpdates AoE vs single target calculations to work on the updated Dragonknight. This change is retroactive.|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_2_1_0", [=[
- Introduced an additional level of navigation: |cFFFFFFsubcategories|r. Similar contexts are now a part of the same tab and can be switched between with left/right on a d-pad or left stick
	- |cFFFFFFDamage Done|r and |cFFFFFFBoss Damage Done|r are now just Damage, with old tabs presented as subcategories
	- |cFFFFFFHealing Out|r, |cFFFFFFSelf Healing|r, and Healing In are now just Healing, with old tabs presented as subcategories
	- Effects now has separate |cFFFFFFsubcategories|r for effects on you, bosses and group members, instead of having one long list for everything

- "Attempt to read past end of buffer" UI errors are now suppressed. Group data may still be incorrect when going through a loading screen after the fight ends, but at least you aren't getting that information right in your face as soon as you do that]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_2_0_1", [=[
|cD4AF37Group Journal|r

The Journal now has a |cFFFFFFGroup tab|r for encounters where group members participated and had Battle Scrolls installed

|cD4AF37Overview:|r

- Sortable comparison table with columns for each boss, DPS, Crit%, DTPS, HPS, Alive%, and Deaths

|cD4AF37Per-player detail:|r

- Damage output: DPS, total, crit%, max hit, direct%, AoE%, damage by type, DPS rank and comparison vs DD average

- Survivability: DTPS, alive time, death count, top incoming damage abilities, death recaps

- Healing output: raw HPS, effective HPS, overheal, self-healing

- Per-boss damage bars with damage composition stats and damage taken

|cD4AF37Group context tooltips on the existing tabs when the data is available:|r

- Boss targets on |cFFFFFFDamage Done|r show per-member DPS and contribution %

- DPS and Boss DPS rows show per-member DPS breakdown

- DTPS and damage sources on |cFFFFFFDamage Taken|r show per-member DTPS

- Damage composition stats show DD average for comparison

- |cFFFFFFHealing Out|r/|cFFFFFFSelf Healing|r: raw HPS and overheal show per-member breakdown

|cD4AF37Death Tracking|r

|cD4AF37Death recaps are now saved with encounters and displayed in:|r

- |cFFFFFFOverview tab|r: death count in the damage taken section

- |cFFFFFFDamage Taken|r tab: deaths listed with timestamps, recap viewable in tooltip

- |cFFFFFFGroup tab|r: first and last death per player with full attack details

|cD4AF37Minor changes:|r

- Overview panel now shows Direct % instead of DoT %

- |cFFFFFFNight Market|r option to record all fights there regardless of zone filters

- DPS meters now appear behind other UI elements such as loot history

- "Overview" item is always selected by default on all tabs. This increases |cFFFFFFmemory usage|r a bit, but you didn't want to have free memory anyway, did you?

- Gamertags displayed without @ symbol

- "Hodor" and "Bars" group meters show current fight duration in the header

- Changed sounds for opening and closing filter/instance dialogs

|cD4AF37Localization:|r

- Fixed minor pluralization issues

- Made "stacks" terminology consistent with item sets wording in Russian (стак -> заряд) and German (Stapel -> Kumulation)]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_3_6", [=[
|cFFFFFFFix UI error that appears when loading into the game with LibGroupBroadcast absent|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_3_5", [=[
|cFFFFFFTemporarily make LibGroupBroadcast optional to work around console add-on apocalypse happening|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_3_4", [=[
|cFFFFFFNo visible changes, preparing for viewing group members' DPS in Journal|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_3_3", [=[
|cFFFFFFNo visible changes, preparing for viewing group members' DPS in Journal|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_3_2", [=[
|cD4AF37Bugfixes:|r

- No longer tries to send DPS data to group while not actually grouped (by DakJaniels)]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_3_1", [=[
|cD4AF37Bugfixes:|r

- Boss detection should be more reliable in the last Lucent Citadel encounter and some other boss fights when you get separated from the boss for some time (e.g. when going to do portals)

- "|cFFFFFF1000ms limit hit|r" UI error should no longer sometimes happen after complex encounters (last Lucent Citadel encounter, first Ossein Cage encounter)]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_3_0", [=[
|cD4AF37New features:|r

- You can now mark effects as |cFFFFFFfavorite|r, which will |cFFFFFFpin them|r at the top of every list they appear in

|cD4AF37Bugfixes:|r

- New group members joining mid-fight now have |cFFFFFFuptimes|r calculated only for the time they were present

- Fixed some group DPS tracker designs displaying empty elements in the top left corner of the screen briefly when entering combat for the first time

|cD4AF37Minor changes:|r

- Total DPS row in group tracker is now displayed even if there is only 1 person in DPS section]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_2_0", [=[
|cD4AF37New features:|r

- |cFFFFFFZone locking|r: Press |cFFFFFFX/Square|r on any zone in the instance list to lock it. Locked zones are protected from automatic cleanup when you exceed your storage limit. The most recent zone is also always protected

|cD4AF37Localization:|r

- German: Improved terminology consistency ("Zonen" -> "Gebiete")

- Russian: Improved terminology consistency ("зоны" -> "области")

|cD4AF37Bugfixes:|r

- Smooth preset no longer gets UI stuck on "Loading" or prevents encounters from appearing in Journal. Due to it being adjusted, you'll be reset to default "Performance" mode upon updating if you had it selected]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_1_0", [=[
|cD4AF37New features:|r

- You can now |cFFFFFFdelete individual|r instances and encounters from history

|cD4AF37Bugfixes:|r

- Fixed an infinite load or Battle Scrolls not appearing in the menu at all when having Smooth performance mode and Fidelity graphics mode. You may need to |cFFFFFF/reloadui|r one extra time after updating to this version if you're affected before it works again

- Fixed multiple game dialogs (such as item destruction) failing with UI errors after using filters in Battle Scrolls

- Fixed animation sometimes playing in the wrong direction when exiting from Battle Scrolls back to Journal]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_0_3", [=[
|cFFFFFFA blind attempt to fix PS5 corrupted save data issue|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_0_2", [=[
|cD4AF37Storage and effect tracking improvements|r

|cD4AF37Storage|r

- Optimized |cFFFFFFencoding/decoding|r for faster Journal loading

- Reduced |cFFFFFFmemory usage|r during encounter processing

|cD4AF37Effect Tracking|r

- Fixed buff/debuff |cFFFFFFuptimes|r when group members go offline during combat

- Improved handling of group members reconnecting mid-fight]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_0_1", [=[
|cFFFFFFA bugfix|r]=])

ZO_CreateStringId("BATTLESCROLLS_RELEASE_1_0_0", [=[
|cD4AF37Initial public release|r

|cD4AF37DPS Meter|r

- Real-time combat damage display

- Personal mode with multiple designs (default, minimal, bar)

- Group mode with multiple designs (text, Hodor-style, bars)

- Configurable position, scale, and linger time

|cD4AF37Combat Journal|r

- Browse past encounters with three-level navigation

- Instance > Encounter > Metrics breakdown

- Filter by zone type and fight type

- Memory management with configurable storage limits

|cD4AF37Damage Tracking|r

- Per-target and per-ability breakdown

- Direct vs DoT damage separation

- Critical hit tracking

- Single-target vs AoE categorization

|cD4AF37Healing Tracking|r

- Healing done and received

- Source and target breakdown

|cD4AF37Effect Tracking|r

- Buff/debuff |cFFFFFFuptimes|r on player

- Group member buff tracking

- Boss debuff tracking

- Proc monitoring

|cD4AF37Group DPS Sharing|r

- Share data with group via |cFFFFFFLibGroupBroadcast|r

|cD4AF37Supported Languages:|r English, German, French, Spanish, Russian, Japanese, Chinese]=])

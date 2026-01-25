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
ZO_CreateStringId("BATTLESCROLLS_TAB_EFFECTS", "Effects")

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
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT", "Members of your group will still be able to see your DPS if they have the addon installed.")
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
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS", "Record Trash Fights")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS_TEXT", "Fights against non-boss, non-player enemies.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS", "Record Player Fights")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS_TEXT", "PvP fights against other players.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_RECORD_DUMMY_FIGHTS", "Record Target Dummy Fights")
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
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE", "This limit applies to saved history only. The addon also uses memory for tracking the current combat and rendering the UI, so total usage will be higher than what's shown here.")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT", "History: <<1>> MB of <<2>> MB (<<3>>%)")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS", "Presets (trial ~0.5-1 MB, dungeon ~0.25-0.5 MB):")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_XS", "  Extra Small: 5 MB - a handful of recent runs")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL", "  Small: 8 MB - a night of prog")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM", "  Medium: 12 MB - a week of casual play")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE", "  Large: 18 MB - a couple weeks")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_XL", "  Extra Large: 25 MB - a month of memories")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION", "  Be Careful: 40 MB - you really like data")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO", "  What Could Go Wrong?: 60 MB - living dangerously")
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING", "About ESO memory limits: all addons share a 100 MB pool. At 70 MB, ESO shows a warning popup. At 100 MB, the UI reloads and disables everything. If you run many addons, pick a smaller preset. Tip: type /addonmemdisplay in chat to see a real-time memory tracker.")

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
ZO_CreateStringId("BATTLESCROLLS_STAT_TOTAL_PROCS", "procs")
ZO_CreateStringId("BATTLESCROLLS_STAT_MEDIAN_INTERVAL", "median")

-------------------------
-- Damage Stats Details
-------------------------
ZO_CreateStringId("BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE", "Total Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_BOSS_DPS", "Boss DPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_SHARE", "Group Share")
ZO_CreateStringId("BATTLESCROLLS_STAT_TOTAL_DAMAGE", "Total Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_DPS", "DPS")

ZO_CreateStringId("BATTLESCROLLS_HEADER_BY_ABILITY", "By Ability")
ZO_CreateStringId("BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE", "By Damage Type")
ZO_CreateStringId("BATTLESCROLLS_HEADER_DIRECT_VS_DOT", "Direct vs DoT")
ZO_CreateStringId("BATTLESCROLLS_HEADER_AOE_VS_SINGLE", "AOE vs Single Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_BY_TARGET", "By Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_BY_SOURCE", "By Source")

ZO_CreateStringId("BATTLESCROLLS_STAT_DIRECT_DAMAGE", "Direct Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_DAMAGE_OVER_TIME", "Damage over Time")
ZO_CreateStringId("BATTLESCROLLS_STAT_AOE_DAMAGE", "AOE Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE", "Single Target Damage")

-------------------------
-- Healing Stats Details
-------------------------
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_HEALING", "Raw Healing")
ZO_CreateStringId("BATTLESCROLLS_STAT_RAW_HPS", "Raw HPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_HEALING", "Effective Healing")
ZO_CreateStringId("BATTLESCROLLS_STAT_EFFECTIVE_HPS", "Effective HPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_OVERHEAL", "Overheal")

ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT", "Raw HoT vs Direct")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT", "Effective HoT vs Direct")
ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_BY_TARGET", "Raw Healing By Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_BY_ABILITY", "Raw Healing By Ability")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_BY_TARGET", "Effective Healing By Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_BY_ABILITY", "Effective Healing By Ability")
ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_BY_SOURCE", "Raw Healing By Source")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_BY_SOURCE", "Effective Healing By Source")
ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET", "Raw Healing By Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY", "Raw Healing By Ability")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET", "Effective Healing By Target")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY", "Effective Healing By Ability")
ZO_CreateStringId("BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE", "Raw Healing By Source")
ZO_CreateStringId("BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE", "Effective Healing By Source")

ZO_CreateStringId("BATTLESCROLLS_STAT_DIRECT_HEALING", "Direct Healing")
ZO_CreateStringId("BATTLESCROLLS_STAT_HEALING_OVER_TIME", "Healing over Time")

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
ZO_CreateStringId("BATTLESCROLLS_EFFECT_MEMBERS", "members")

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

ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_BY_TARGET", "By Target")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL", "Mean interval")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL", "Median interval")

ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_ABILITY", "Ability")

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

-------------------------
-- Filter Dialog
-------------------------
ZO_CreateStringId("BATTLESCROLLS_FILTER_DAMAGE_DONE", "Filter Damage Done")
ZO_CreateStringId("BATTLESCROLLS_FILTER_BOSS_DAMAGE", "Filter Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_FILTER_BY_SOURCE", "Filter by Source")
ZO_CreateStringId("BATTLESCROLLS_FILTER_BY_TARGET", "Filter by Target")
ZO_CreateStringId("BATTLESCROLLS_FILTER_BY_GROUP_MEMBER", "Filter by Group Member")
ZO_CreateStringId("BATTLESCROLLS_FILTER", "Filter")
ZO_CreateStringId("BATTLESCROLLS_FILTER_ACTIVE", "Filter (Active)")
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
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_EFFICIENCY", "Efficiency")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_KEY_BUFFS", "Your Buffs")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_KEY_DEBUFFS", "Key Debuffs")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_UPTIMES", "Uptimes")
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
ZO_CreateStringId("BATTLESCROLLS_AOE", "AOE")
ZO_CreateStringId("BATTLESCROLLS_SINGLE_TARGET", "Single Target")
ZO_CreateStringId("BATTLESCROLLS_HEALING_RAW_HPS", "Raw HPS")
ZO_CreateStringId("BATTLESCROLLS_HEALING_EFFECTIVE_HPS", "Effective HPS")
ZO_CreateStringId("BATTLESCROLLS_HEALING_OVERHEAL", "Overheal")
ZO_CreateStringId("BATTLESCROLLS_TOOLTIP_DURATION", "Duration")

-------------------------
-- Group Stats
-------------------------
ZO_CreateStringId("BATTLESCROLLS_GROUP_DAMAGE", "Group Damage")
ZO_CreateStringId("BATTLESCROLLS_GROUP_BOSS_DAMAGE", "Group Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_GROUP_DPS", "Group DPS")
ZO_CreateStringId("BATTLESCROLLS_GROUP_BOSS_DPS", "Group Boss DPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_DAMAGE", "Group Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_DPS", "Group DPS")
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE", "Group Boss Damage")
ZO_CreateStringId("BATTLESCROLLS_STAT_GROUP_BOSS_DPS", "Group Boss DPS")

-------------------------
-- Overview Panel - Ability Stats
-------------------------
ZO_CreateStringId("BATTLESCROLLS_STAT_MAX_PREFIX", "Max: <<1>>")
ZO_CreateStringId("BATTLESCROLLS_STAT_CRIT_PERCENT", "<<1>>% crit")
ZO_CreateStringId("BATTLESCROLLS_STAT_PER_SECOND", "<<1>>/s")

-------------------------
-- Overview Panel - Effect Stats
-------------------------
ZO_CreateStringId("BATTLESCROLLS_EFFECT_APPS_COUNT", "<<1>> apps")
ZO_CreateStringId("BATTLESCROLLS_EFFECT_YOURS_PERCENT", "<<1>>% yours")
ZO_CreateStringId("BATTLESCROLLS_EFFECT_STACKS_COUNT", "×<<1>> stacks")

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
ZO_CreateStringId("BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT", "Controls how quickly background tasks are processed. This mostly affects the Journal UI and the time between combat ending and the encounter appearing in the list.\n\nPerformance: Fastest processing. May cause brief stutters in large content.\nSmooth: Smoother gameplay, slower processing. May cause encounters to get stuck loading or fail to appear in Journal.\n\nThis setting affects ALL addons using LibAsync.")

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
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC", "About 6 trials worth")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE", "Moderate (12 MB)")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC", "About 16 trials worth")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS", "Generous (25 MB)")
ZO_CreateStringId("BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC", "About 36 trials worth")
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
-- Dynamic Overview Panel
-------------------------
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN", "Damage Taken")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_TOP_HEALING", "Top Healing")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_TOP_INCOMING", "Top Incoming")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_HEALING_TARGETS", "Healing Targets")
ZO_CreateStringId("BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES", "Damage Sources")

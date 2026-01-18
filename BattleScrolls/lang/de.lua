-- Battle Scrolls Localization - German (Deutsch)
-- Translations use ESO's official German terminology

local strings = {
    -------------------------
    -- Core UI Labels
    -------------------------
    [BATTLESCROLLS_UI_NAME] = "Battle Scrolls",
    [BATTLESCROLLS_UI_SETTINGS] = "Einstellungen",
    [BATTLESCROLLS_UI_FILTER] = "Filter",
    [BATTLESCROLLS_UI_FILTER_ACTIVE] = "Filter (Aktiv)",
    [BATTLESCROLLS_STAT_HPS] = "HPS",

    -------------------------
    -- Zone/Instance Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ZONES] = "Alle Zonen",
    [BATTLESCROLLS_TAB_INSTANCED] = "Instanzen",
    [BATTLESCROLLS_TAB_OVERLAND] = "Oberwelt",
    [BATTLESCROLLS_TAB_HOUSES] = "Häuser",
    [BATTLESCROLLS_TAB_PVP] = "PvP",

    -------------------------
    -- Encounter Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ENCOUNTERS] = "Alle Kämpfe",
    [BATTLESCROLLS_TAB_BOSS_ENCOUNTERS] = "Bosskämpfe",
    [BATTLESCROLLS_TAB_OTHER_ENCOUNTERS] = "Andere Kämpfe",
    [BATTLESCROLLS_TAB_PLAYER_ENCOUNTERS] = "Spielerkämpfe",
    [BATTLESCROLLS_TAB_TARGET_DUMMY] = "Übungspuppe",

    -------------------------
    -- Stats Tabs
    -------------------------
    [BATTLESCROLLS_TAB_OVERVIEW] = "Übersicht",
    [BATTLESCROLLS_TAB_BOSS_DAMAGE_DONE] = "Boss-Schaden",
    [BATTLESCROLLS_TAB_DAMAGE_DONE] = "Zugefügter Schaden",
    [BATTLESCROLLS_TAB_DAMAGE_TAKEN] = "Erlittener Schaden",
    [BATTLESCROLLS_TAB_HEALING_OUT] = "Ausgehende Heilung",
    [BATTLESCROLLS_TAB_SELF_HEALING] = "Selbstheilung",
    [BATTLESCROLLS_TAB_HEALING_IN] = "Erhaltene Heilung",
    [BATTLESCROLLS_TAB_EFFECTS] = "Effekte",

    -------------------------
    -- Time Headers
    -------------------------
    [BATTLESCROLLS_TIME_TODAY] = "Heute",
    [BATTLESCROLLS_TIME_YESTERDAY] = "Gestern",

    -------------------------
    -- DPS Meter Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_DPS_METER] = "DPS-Anzeige",
    [BATTLESCROLLS_SETTINGS_KEEP_AFTER_COMBAT] = "Nach Kampf behalten",
    [BATTLESCROLLS_SETTINGS_HIDE_IMMEDIATELY] = "Sofort ausblenden",
    [BATTLESCROLLS_SETTINGS_10_SECONDS] = "10 Sekunden",
    [BATTLESCROLLS_SETTINGS_30_SECONDS] = "30 Sekunden",
    [BATTLESCROLLS_SETTINGS_2_MINUTES] = "2 Minuten",
    [BATTLESCROLLS_SETTINGS_5_MINUTES] = "5 Minuten",
    [BATTLESCROLLS_SETTINGS_UNTIL_RELOAD] = "Bis Neuladen",

    [BATTLESCROLLS_SETTINGS_PERSONAL_METER] = "Persönliche Anzeige",
    [BATTLESCROLLS_SETTINGS_GROUP_METER] = "Gruppenanzeige",
    [BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT] = "Gruppenmitglieder können dein DPS weiterhin sehen, wenn sie das Addon installiert haben.",
    [BATTLESCROLLS_SETTINGS_ENABLED] = "Aktiviert",
    [BATTLESCROLLS_SETTINGS_MODE] = "Modus",
    [BATTLESCROLLS_SETTINGS_DESIGN] = "Design",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_LEFT] = "Abstand von links",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_TOP] = "Abstand von oben",
    [BATTLESCROLLS_SETTINGS_SIZE] = "Größe",
    [BATTLESCROLLS_SETTINGS_RESET_POSITION] = "Position zurücksetzen",
    [BATTLESCROLLS_SETTINGS_POSITION] = "Position",

    -- Meter modes
    [BATTLESCROLLS_SETTINGS_MODE_AUTO] = "Automatisch",
    [BATTLESCROLLS_SETTINGS_MODE_DAMAGE] = "Schaden",
    [BATTLESCROLLS_SETTINGS_MODE_HEALING] = "Heilung",

    -- Meter size options
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_SMALL] = "Sehr klein",
    [BATTLESCROLLS_SETTINGS_SIZE_SMALL] = "Klein",
    [BATTLESCROLLS_SETTINGS_SIZE_MEDIUM] = "Mittel",
    [BATTLESCROLLS_SETTINGS_SIZE_LARGE] = "Groß",
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_LARGE] = "Sehr groß",

    -- Meter position options
    [BATTLESCROLLS_SETTINGS_POSITION_BELOW] = "Darunter",
    [BATTLESCROLLS_SETTINGS_POSITION_ABOVE] = "Darüber",
    [BATTLESCROLLS_SETTINGS_POSITION_SEPARATE] = "Separat",

    -- Auto mode tooltip
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TITLE] = "Automatischer Modus",
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TEXT] = "Zeigt den höheren Wert - DPS oder HPS.",

    -- Group tracker tooltips
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA] = "Ohne Gruppendaten anzeigen",
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA_TEXT] = "Wenn aktiviert, wird die Gruppenanzeige auch angezeigt, wenn keine anderen Gruppenmitglieder ihre DPS-Daten teilen. Du siehst nur deine eigenen Werte.",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_DESIGN] = "Gruppenanzeige-Design",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION] = "Gruppenanzeige-Position",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION_TEXT] = "Unter/Über: Befestigt die Gruppenanzeige an deiner persönlichen Anzeige.\nSeparat: Platziert die Gruppenanzeige unabhängig mit eigener Positionierung.",

    -------------------------
    -- Recording Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_RECORDING] = "Aufnahme",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED] = "In Instanzen aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED_TEXT] = "Instanzzonen umfassen Verliese, Prüfungen, Arenen und das Endlose Archiv.",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_OVERLAND] = "In Oberwelt aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_HOUSES] = "In Häusern aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_PVP] = "In PvP-Zonen aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_BOSS_FIGHTS] = "Bosskämpfe aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS] = "Trash-Kämpfe aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS_TEXT] = "Kämpfe gegen normale Gegner (keine Bosse, keine Spieler).",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS] = "Spielerkämpfe aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS_TEXT] = "PvP-Kämpfe gegen andere Spieler.",
    [BATTLESCROLLS_SETTINGS_RECORD_DUMMY_FIGHTS] = "Übungspuppen-Kämpfe aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE] = "Aufnahmefilter",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT] = "Zonen- und Kampftyp-Filter werden kombiniert: Ein Kampf muss mindestens eine Zone UND einen Kampftyp erfüllen, um aufgenommen zu werden.",

    -- Storage/History settings
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT] = "Verlaufsgrenze",
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT_TITLE] = "Verlaufsgrenze",
    -- Storage size preset labels (dropdown options)
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XS] = "Extra Klein",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_SMALL] = "Klein",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_MEDIUM] = "Mittel",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_LARGE] = "Groß",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XL] = "Extra Groß",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_CAUTION] = "Vorsicht",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_YOLO] = "Was kann schon schiefgehen?",
    -- Storage tooltip
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC] = "Wie viel Kampfverlauf gespeichert werden soll. Wenn das Limit erreicht wird, werden die ältesten Instanzen automatisch entfernt.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE] = "Dieses Limit gilt nur für gespeicherten Verlauf. Das Addon verwendet zusätzlich Speicher für den aktuellen Kampf und die Benutzeroberfläche, daher wird der Gesamtverbrauch höher sein.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT] = "Verlauf: <<1>> MB von <<2>> MB (<<3>>%)",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS] = "Voreinstellungen (Prüfung ~0,5-1 MB, Verlies ~0,25-0,5 MB):",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XS] = "  Extra Klein: 5 MB - ein paar letzte Runs",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL] = "  Klein: 8 MB - ein Abend Progging",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM] = "  Mittel: 12 MB - eine Woche Casual-Spielen",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE] = "  Groß: 18 MB - ein paar Wochen",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XL] = "  Extra Groß: 25 MB - ein Monat Erinnerungen",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION] = "  Vorsicht: 40 MB - du magst Daten wirklich",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO] = "  Was kann schon schiefgehen?: 60 MB - lebe gefährlich",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING] = "Zu ESO-Speicherlimits: Alle Addons teilen sich 100 MB. Bei 70 MB zeigt ESO eine Warnung. Bei 100 MB lädt die UI neu und deaktiviert alles. Bei vielen Addons eine kleinere Einstellung wählen. Tipp: /addonmemdisplay im Chat eingeben für Echtzeit-Speicheranzeige.",

    -------------------------
    -- Effect Tracking Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_EFFECT_TRACKING] = "Effekt-Verfolgung",
    [BATTLESCROLLS_SETTINGS_PLAYER_BUFFS] = "Buffs auf dir",
    [BATTLESCROLLS_SETTINGS_PLAYER_DEBUFFS] = "Debuffs auf dir",
    [BATTLESCROLLS_SETTINGS_GROUP_BUFFS] = "Buffs auf der Gruppe",
    [BATTLESCROLLS_SETTINGS_BOSS_DEBUFFS] = "Debuffs auf dem Boss",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION] = "Abgleich",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION_TOOLTIP] = "Wie oft die Effektverfolgung mit dem Spielzustand abgeglichen wird. Höhere Präzision erfasst mehr verpasste Ereignisse, verbraucht aber mehr Speicher. Der Speicher wird erst beim UI-Neuladen freigegeben.",
    [BATTLESCROLLS_SETTINGS_RECON_MAX] = "Maximum",
    [BATTLESCROLLS_SETTINGS_RECON_HIGH] = "Hoch",
    [BATTLESCROLLS_SETTINGS_RECON_NORMAL] = "Normal",
    [BATTLESCROLLS_SETTINGS_RECON_LOW] = "Niedrig",
    [BATTLESCROLLS_SETTINGS_RECON_OFF] = "Aus",

    -------------------------
    -- Slider keybinds
    -------------------------
    [BATTLESCROLLS_SETTINGS_SLIDER_HOLD_FAST] = "Halten für schnell",
    [BATTLESCROLLS_SETTINGS_SLIDER_RELEASE_PRECISION] = "Loslassen für Präzision",

    -------------------------
    -- Overview Stats
    -------------------------
    [BATTLESCROLLS_STAT_DURATION] = "Dauer",
    [BATTLESCROLLS_STAT_SUMMARY] = "Zusammenfassung",

    -- Boss Damage
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE] = "Persönlicher Boss-Schaden",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DPS] = "Persönlicher Boss-DPS",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE_SHARE] = "Persönlicher Boss-Anteil",
    [BATTLESCROLLS_HEADER_BOSS_DAMAGE_DONE] = "Boss-Schaden",

    -- Total Damage
    [BATTLESCROLLS_STAT_PERSONAL_DAMAGE] = "Persönlicher Schaden",
    [BATTLESCROLLS_STAT_PERSONAL_DPS] = "Persönlicher DPS",
    [BATTLESCROLLS_STAT_PERSONAL_SHARE] = "Persönlicher Anteil",
    [BATTLESCROLLS_HEADER_TOTAL_DAMAGE_DONE] = "Gesamtschaden",

    -- Damage Taken
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN] = "Erlittener Schaden gesamt",
    [BATTLESCROLLS_STAT_DTPS] = "DTPS",
    [BATTLESCROLLS_HEADER_DAMAGE_TAKEN] = "Erlittener Schaden",

    -- Healing Overview
    [BATTLESCROLLS_STAT_RAW_SELF_HEALING] = "Gesamte Selbstheilung",
    [BATTLESCROLLS_STAT_RAW_SELF_HPS] = "Gesamt-HPS Selbstheilung",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HEALING] = "Effektive Selbstheilung",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HPS] = "Effektive HPS Selbstheilung",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT] = "Gesamte ausgehende Heilung",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT_HPS] = "Gesamt-HPS ausgehend",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT] = "Effektive ausgehende Heilung",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT_HPS] = "Effektive HPS ausgehend",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN] = "Gesamte erhaltene Heilung",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN_HPS] = "Gesamt-HPS erhalten",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN] = "Effektive erhaltene Heilung",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN_HPS] = "Effektive HPS erhalten",
    [BATTLESCROLLS_HEADER_HEALING] = "Heilung",

    -- Proc Tracking
    [BATTLESCROLLS_HEADER_PROC_TRACKING] = "Proc-Verfolgung",
    [BATTLESCROLLS_STAT_TOTAL_PROCS] = "Procs",
    [BATTLESCROLLS_STAT_MEDIAN_INTERVAL] = "Median",

    -------------------------
    -- Damage Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE] = "Boss-Schaden gesamt",
    [BATTLESCROLLS_STAT_BOSS_DPS] = "Boss-DPS",
    [BATTLESCROLLS_STAT_GROUP_SHARE] = "Beitrag",
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE] = "Gesamtschaden",
    [BATTLESCROLLS_STAT_DPS] = "DPS",

    [BATTLESCROLLS_HEADER_BY_ABILITY] = "Nach Fähigkeit",
    [BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE] = "Nach Schadenstyp",
    [BATTLESCROLLS_HEADER_DIRECT_VS_DOT] = "Direkt vs. DoT",
    [BATTLESCROLLS_HEADER_AOE_VS_SINGLE] = "Fläche vs. Einzelziel",
    [BATTLESCROLLS_HEADER_BY_TARGET] = "Nach Ziel",
    [BATTLESCROLLS_HEADER_BY_SOURCE] = "Nach Quelle",

    [BATTLESCROLLS_STAT_DIRECT_DAMAGE] = "Direkter Schaden",
    [BATTLESCROLLS_STAT_DAMAGE_OVER_TIME] = "Schaden über Zeit",
    [BATTLESCROLLS_STAT_AOE_DAMAGE] = "Flächenschaden",
    [BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE] = "Einzelzielschaden",

    -------------------------
    -- Healing Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_RAW_HEALING] = "Gesamte Heilung",
    [BATTLESCROLLS_STAT_RAW_HPS] = "Gesamt-HPS",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING] = "Effektive Heilung",
    [BATTLESCROLLS_STAT_EFFECTIVE_HPS] = "Effektive HPS",
    [BATTLESCROLLS_STAT_OVERHEAL] = "Überheilung",

    [BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT] = "Gesamt: HoT vs. Direkt",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT] = "Effektiv: HoT vs. Direkt",
    [BATTLESCROLLS_HEADER_RAW_BY_TARGET] = "Gesamte Heilung nach Ziel",
    [BATTLESCROLLS_HEADER_RAW_BY_ABILITY] = "Gesamte Heilung nach Fähigkeit",
    [BATTLESCROLLS_HEADER_EFFECTIVE_BY_TARGET] = "Effektive Heilung nach Ziel",
    [BATTLESCROLLS_HEADER_EFFECTIVE_BY_ABILITY] = "Effektive Heilung nach Fähigkeit",
    [BATTLESCROLLS_HEADER_RAW_BY_SOURCE] = "Gesamte Heilung nach Quelle",
    [BATTLESCROLLS_HEADER_EFFECTIVE_BY_SOURCE] = "Effektive Heilung nach Quelle",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET] = "Gesamte Heilung nach Ziel",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY] = "Gesamte Heilung nach Fähigkeit",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET] = "Effektive Heilung nach Ziel",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY] = "Effektive Heilung nach Fähigkeit",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE] = "Gesamte Heilung nach Quelle",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE] = "Effektive Heilung nach Quelle",

    [BATTLESCROLLS_STAT_DIRECT_HEALING] = "Direkte Heilung",
    [BATTLESCROLLS_STAT_HEALING_OVER_TIME] = "Heilung über Zeit",

    -------------------------
    -- Effects Stats
    -------------------------
    [BATTLESCROLLS_HEADER_YOUR_BUFFS] = "Deine Buffs",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON_YOU] = "Debuffs auf dir",
    [BATTLESCROLLS_HEADER_BUFFS_ON_GROUP] = "Buffs auf der Gruppe",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON] = "Debuffs auf <<1>>",

    [BATTLESCROLLS_EFFECT_UPTIME] = "Aktivzeit",
    [BATTLESCROLLS_EFFECT_YOURS] = "deine",
    [BATTLESCROLLS_EFFECT_AVG] = "Durchschnitt",
    [BATTLESCROLLS_EFFECT_MEMBERS] = "Mitglieder",

    -------------------------
    -- Effect Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL_UPTIME] = "Gesamte Aktivzeit",
    [BATTLESCROLLS_TOOLTIP_TOTAL_APPLICATIONS] = "Gesamte Anwendungen",
    [BATTLESCROLLS_TOOLTIP_YOUR_CONTRIBUTION] = "Dein Beitrag",
    [BATTLESCROLLS_TOOLTIP_YOUR_UPTIME] = "Aktivzeit",
    [BATTLESCROLLS_TOOLTIP_YOUR_APPLICATIONS] = "Anwendungen",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS] = "Max. Stapel",
    [BATTLESCROLLS_TOOLTIP_TIME_AT_MAX_STACKS] = "Zeit bei max. Stapel",
    [BATTLESCROLLS_TOOLTIP_YOUR_TIME_AT_MAX] = "Deine Zeit bei max.",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_MEMBER] = "Durchschnittliche Aktivzeit pro Mitglied",
    [BATTLESCROLLS_TOOLTIP_MEMBERS_AFFECTED] = "Betroffene Mitglieder",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME] = "Durchschnittliche Aktivzeit",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS_OBSERVED] = "Max. beobachtete Stapel",
    [BATTLESCROLLS_TOOLTIP_AVG_TIME_AT_MAX] = "Durchschnittliche Zeit bei max. Stapel",
    [BATTLESCROLLS_TOOLTIP_YOUR_AVG_TIME_AT_MAX] = "Deine durchschnittliche Zeit bei max.",
    [BATTLESCROLLS_TOOLTIP_PEAK_INSTANCES] = "Max. gleichzeitige Quellen",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_INSTANCE] = "Durchschn. Aktivzeit pro Quelle",
    [BATTLESCROLLS_TOOLTIP_PER_MEMBER] = "Pro Mitglied",
    [BATTLESCROLLS_TOOLTIP_YOU] = "Du",

    -------------------------
    -- Ability Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL] = "Gesamt",
    [BATTLESCROLLS_TOOLTIP_TYPE] = "Typ",
    [BATTLESCROLLS_TOOLTIP_DELIVERY] = "Art",
    [BATTLESCROLLS_TOOLTIP_CRIT] = "Krit",
    [BATTLESCROLLS_TOOLTIP_AVG_TICK] = "Durchschnittlicher Tick",
    [BATTLESCROLLS_TOOLTIP_MIN_TICK] = "Min. Tick",
    [BATTLESCROLLS_TOOLTIP_MAX_TICK] = "Max. Tick",

    [BATTLESCROLLS_TOOLTIP_BY_TARGET] = "Nach Ziel",
    [BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL] = "Durchschnittl. Intervall",
    [BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL] = "Median-Intervall",

    [BATTLESCROLLS_TOOLTIP_ABILITY] = "Fähigkeit",

    -------------------------
    -- Damage Types
    -------------------------
    [BATTLESCROLLS_DAMAGE_TYPE_NONE] = "Keine",
    [BATTLESCROLLS_DAMAGE_TYPE_GENERIC] = "Generisch",
    [BATTLESCROLLS_DAMAGE_TYPE_PHYSICAL] = "Physisch",
    [BATTLESCROLLS_DAMAGE_TYPE_FIRE] = "Flammen",
    [BATTLESCROLLS_DAMAGE_TYPE_SHOCK] = "Schock",
    [BATTLESCROLLS_DAMAGE_TYPE_OBLIVION] = "Daedrisch",
    [BATTLESCROLLS_DAMAGE_TYPE_FROST] = "Frost",
    [BATTLESCROLLS_DAMAGE_TYPE_EARTH] = "Erde",
    [BATTLESCROLLS_DAMAGE_TYPE_MAGIC] = "Magie",
    [BATTLESCROLLS_DAMAGE_TYPE_DROWN] = "Ertrinken",
    [BATTLESCROLLS_DAMAGE_TYPE_DISEASE] = "Seuche",
    [BATTLESCROLLS_DAMAGE_TYPE_POISON] = "Gift",
    [BATTLESCROLLS_DAMAGE_TYPE_BLEED] = "Blutung",

    -------------------------
    -- Over Time/Direct Descriptions
    -------------------------
    [BATTLESCROLLS_DELIVERY_MIXED] = "Gemischt",
    [BATTLESCROLLS_DELIVERY_DOT] = "DoT",
    [BATTLESCROLLS_DELIVERY_DIRECT] = "Direkt",
    [BATTLESCROLLS_DELIVERY_HOT] = "HoT",

    -------------------------
    -- Filter Dialog
    -------------------------
    [BATTLESCROLLS_FILTER_DAMAGE_DONE] = "Schaden filtern",
    [BATTLESCROLLS_FILTER_BOSS_DAMAGE] = "Boss-Schaden filtern",
    [BATTLESCROLLS_FILTER_BY_SOURCE] = "Nach Quelle filtern",
    [BATTLESCROLLS_FILTER_BY_TARGET] = "Nach Ziel filtern",
    [BATTLESCROLLS_FILTER_BY_GROUP_MEMBER] = "Nach Gruppenmitglied filtern",
    [BATTLESCROLLS_FILTER] = "Filter",
    [BATTLESCROLLS_FILTER_ACTIVE] = "Filter (Aktiv)",
    [BATTLESCROLLS_FILTER_RESET] = "Zurücksetzen",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_BY] = "Schaden von",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_TO] = "Schaden an",
    [BATTLESCROLLS_FILTER_BOSS_TARGET] = "Bossziel",

    -------------------------
    -- Encounter Display
    -------------------------
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN_WITH] = "Kampf <<l:1>> mit <<2>>",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_WITH] = "Kampf mit <<1>>",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN] = "Kampf <<l:1>>",
    [BATTLESCROLLS_ENCOUNTER_COMBAT] = "Kampf",
    [BATTLESCROLLS_ENCOUNTER_INTO_INSTANCE] = "seit Start",
    [BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX] = "(Selbst)",

    -------------------------
    -- List States
    -------------------------
    [BATTLESCROLLS_LIST_LOADING] = "Wird geladen...",
    [BATTLESCROLLS_LIST_NO_DATA] = "Keine Kampfdaten aufgezeichnet",
    [BATTLESCROLLS_LIST_NO_ENCOUNTERS] = "Keine Kämpfe",
    [BATTLESCROLLS_LIST_NO_STATS] = "Keine Statistiken verfügbar",
    [BATTLESCROLLS_LIST_NO_SETTINGS] = "Keine Einstellungen verfügbar",

    -------------------------
    -- LibHarvensAddonSettings Integration
    -------------------------
    [BATTLESCROLLS_LIBHARVENS_OPEN_BUTTON] = "Battle Scrolls öffnen",
    [BATTLESCROLLS_LIBHARVENS_TOOLTIP] = "Battle Scrolls ist auch über das <<1>>-Menü erreichbar.",

    -------------------------
    -- Misc
    -------------------------
    [BATTLESCROLLS_UNKNOWN] = "Unbekannt",
    [BATTLESCROLLS_UNKNOWN_BOSS] = "Unbekannter Boss",

    -------------------------
    -- Personal Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_PERSONAL_DEFAULT] = "Standard",
    [BATTLESCROLLS_DESIGN_PERSONAL_MINIMAL] = "Minimal",
    [BATTLESCROLLS_DESIGN_PERSONAL_BAR] = "Balken",

    -- Bar design settings
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION] = "Balkenrichtung",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_RIGHT] = "Rechts",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_LEFT] = "Links",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_CENTER] = "Bidirektional",

    -------------------------
    -- Group Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_GROUP_TEXT] = "Text",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR] = "Hodor",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR_DESC] = "Sehr nah an Hodor Reflexes von @andy.s und @m00nyONE.",
    [BATTLESCROLLS_DESIGN_GROUP_BARS] = "Balken",
    [BATTLESCROLLS_DESIGN_GROUP_BARS_DESC] = "Lose inspiriert von Hodor Restyle von Hyperioxes.",

    -- Text design settings
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS] = "Spalten",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TITLE] = "Spaltenanordnung",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TEXT] = "Gruppen mit 4 oder weniger Mitgliedern verwenden immer 1 Spalte.",

    -------------------------
    -- DPS Meter Display Strings
    -- Note: DPS/HPS are universal gaming terms, hardcoded in code
    -------------------------
    [BATTLESCROLLS_METER_EFFECTIVE] = "effektiv",
    [BATTLESCROLLS_METER_EFF] = "eff.",
    [BATTLESCROLLS_METER_BOSS] = "Boss",
    [BATTLESCROLLS_METER_ALL] = "Gesamt",
    [BATTLESCROLLS_METER_ALL_DAMAGE] = "Gesamtschaden",
    [BATTLESCROLLS_METER_TOTAL] = "Summe",
    [BATTLESCROLLS_METER_BOSS_ALL_DAMAGE] = "Boss-Schaden / Gesamtschaden",
    [BATTLESCROLLS_METER_EFFECTIVE_RAW_HEALING] = "Effektiv / Gesamt",

    -- Overview Panel Q3/Q4 Headers
    [BATTLESCROLLS_OVERVIEW_TOP_ABILITIES] = "Top-Fähigkeiten",
    [BATTLESCROLLS_OVERVIEW_BOSSES] = "Bosse",
    [BATTLESCROLLS_OVERVIEW_TARGETS] = "Ziele",
    [BATTLESCROLLS_OVERVIEW_SOURCES] = "Quellen",
    [BATTLESCROLLS_OVERVIEW_TARGETS_HEALED] = "Geheilte Ziele",
    [BATTLESCROLLS_OVERVIEW_HEALERS] = "Heiler",
    [BATTLESCROLLS_OVERVIEW_GROUP_BUFFS] = "Gruppen-Buffs",
    [BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS] = "Boss-Debuffs",

    -- Group Stats
    [BATTLESCROLLS_GROUP_DAMAGE] = "Gruppenschaden",
    [BATTLESCROLLS_GROUP_BOSS_DAMAGE] = "Gruppen-Boss-Schaden",
    [BATTLESCROLLS_GROUP_DPS] = "Gruppen-DPS",
    [BATTLESCROLLS_GROUP_BOSS_DPS] = "Gruppen-Boss-DPS",
    [BATTLESCROLLS_STAT_GROUP_DAMAGE] = "Gruppenschaden",
    [BATTLESCROLLS_STAT_GROUP_DPS] = "Gruppen-DPS",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE] = "Gruppen-Boss-Schaden",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DPS] = "Gruppen-Boss-DPS",

    -- Overview Panel - Ability Stats
    [BATTLESCROLLS_STAT_MAX_PREFIX] = "Max: <<1>>",
    [BATTLESCROLLS_STAT_CRIT_PERCENT] = "<<1>>% Krit",
    [BATTLESCROLLS_STAT_PER_SECOND] = "<<1>>/s",

    -- Overview Panel - Effect Stats
    [BATTLESCROLLS_EFFECT_APPS_COUNT] = "<<1>> Anw.",
    [BATTLESCROLLS_EFFECT_YOURS_PERCENT] = "<<1>>% dein",
    [BATTLESCROLLS_EFFECT_STACKS_COUNT] = "×<<1>> Stapel",

    -- Overview Panel Summary
    [BATTLESCROLLS_OVERVIEW_ENCOUNTER] = "Begegnung",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT] = "Schadensausgabe",
    [BATTLESCROLLS_OVERVIEW_SUMMARY] = "Zusammenfassung",
    [BATTLESCROLLS_OVERVIEW_TOTAL] = "Gesamt",
    [BATTLESCROLLS_OVERVIEW_SHARE] = "Anteil",
    [BATTLESCROLLS_OVERVIEW_COMPOSITION] = "Zusammensetzung",
    [BATTLESCROLLS_OVERVIEW_QUALITY] = "Qualität",
    [BATTLESCROLLS_OVERVIEW_CRIT_RATE] = "Krit-Rate",
    [BATTLESCROLLS_OVERVIEW_MAX_HIT] = "Maximaler Treffer",
    [BATTLESCROLLS_OVERVIEW_MAX_HEAL] = "Maximale Heilung",
    [BATTLESCROLLS_OVERVIEW_EFFICIENCY] = "Effizienz",
    [BATTLESCROLLS_OVERVIEW_KEY_BUFFS] = "Deine Buffs",
    [BATTLESCROLLS_OVERVIEW_KEY_DEBUFFS] = "Wichtige Debuffs",
    [BATTLESCROLLS_OVERVIEW_UPTIMES] = "Aktivzeiten",
    [BATTLESCROLLS_OVERVIEW_NO_EFFECTS] = "Keine Effekte aufgezeichnet",

    -- Overview Panel Short Labels
    [BATTLESCROLLS_BOSS_DAMAGE] = "Boss-Schaden",
    [BATTLESCROLLS_DAMAGE_DONE] = "Zugefügter Schaden",
    [BATTLESCROLLS_HEALING_OUT] = "Ausgehende Heilung",
    [BATTLESCROLLS_SELF_HEALING] = "Selbstheilung",
    [BATTLESCROLLS_HEALING_IN] = "Eingehende Heilung",
    [BATTLESCROLLS_AOE] = "Flächenschaden",
    [BATTLESCROLLS_SINGLE_TARGET] = "Einzelziel",
    [BATTLESCROLLS_HEALING_RAW_HPS] = "Gesamt-HPS",
    [BATTLESCROLLS_HEALING_EFFECTIVE_HPS] = "Effektive HPS",
    [BATTLESCROLLS_HEALING_OVERHEAL] = "Überheilung",
    [BATTLESCROLLS_TOOLTIP_DURATION] = "Dauer",

    -------------------------
    -- LibAsync Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_PERFORMANCE] = "Leistung",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED] = "Verarbeitungsgeschwindigkeit",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_PERFORMANCE] = "Leistung",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_BALANCED] = "Ausgewogen",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_SMOOTH] = "Flüssig",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM] = "Benutzerdefiniert (<<1>> FPS)",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE] = "Verarbeitungsgeschwindigkeit",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "Steuert, wie schnell Hintergrundaufgaben verarbeitet werden. Betrifft hauptsächlich die Journal-Oberfläche und die Zeit zwischen Kampfende und dem Erscheinen des Eintrags in der Liste.\n\nLeistung: Schnellste Verarbeitung. Kann kurze Ruckler verursachen.\nAusgewogen: Gute Mischung aus Geschwindigkeit und Flüssigkeit.\nFlüssig: Flüssigstes Gameplay, langsamere Verarbeitung.\n\nDiese Einstellung betrifft ALLE Addons, die LibAsync verwenden.",

    -------------------------
    -- Onboarding
    -------------------------
    [BATTLESCROLLS_ONBOARDING_WELCOME_TITLE] = "Willkommen bei Battle Scrolls",
    [BATTLESCROLLS_ONBOARDING_WELCOME_TEXT] = "Battle Scrolls zeichnet deine Kampfbegegnungen auf und lässt dich sie später im Journal ansehen.\n\nFunktionen:\n- Echtzeit DPS/HPS-Meter\n- Detaillierte Schadens- und Heilungsaufschlüsselung\n- Buff/Debuff-Aktivzeitverfolgung\n- Boss-Debuff-Überwachung\n\nLass uns ein paar Dinge konfigurieren.",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED] = "Loslegen",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED_DESC] = "Führe mich durch die Einstellungen",
    [BATTLESCROLLS_ONBOARDING_SKIP] = "Überspringen",
    [BATTLESCROLLS_ONBOARDING_SKIP_DESC] = "Ich finde es selbst heraus. Empfohlene Einstellungen verwenden.",
    [BATTLESCROLLS_ONBOARDING_METER_QUESTION] = "Wähle deinen DPS-Meter-Stil:",
    -- Meter presets
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL] = "Minimal",
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL_DESC] = "Kompakter persönlicher Meter in der Ecke",
    [BATTLESCROLLS_PRESET_FULL_STACKED] = "Persönlich + Gruppe",
    [BATTLESCROLLS_PRESET_FULL_STACKED_DESC] = "Persönlicher Meter mit Gruppenrangliste darunter",
    [BATTLESCROLLS_PRESET_HODOR] = "Hodor-Stil",
    [BATTLESCROLLS_PRESET_HODOR_DESC] = "Nur Gruppenmeter, sehr nah an Hodor Reflexes (@andy.s, @m00nyONE)",
    [BATTLESCROLLS_PRESET_BAR] = "Fortschrittsbalken",
    [BATTLESCROLLS_PRESET_BAR_DESC] = "Fortschrittsbalken für persönlichen DPS",
    [BATTLESCROLLS_PRESET_COLORFUL] = "Bunte Balken",
    [BATTLESCROLLS_PRESET_COLORFUL_DESC] = "Bunte Balken für persönlichen und Gruppen-DPS, Gruppe lose inspiriert von Hodor Restyle (Hyperioxes)",
    [BATTLESCROLLS_PRESET_DISABLED] = "Deaktiviert",
    [BATTLESCROLLS_PRESET_DISABLED_DESC] = "Keine Meter, nur Aufzeichnung",
    -- Storage options
    [BATTLESCROLLS_ONBOARDING_STORAGE_QUESTION] = "Wie viel Verlauf sollen wir speichern?",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL] = "Minimal (5 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC] = "Etwa 6 Prüfungen",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE] = "Moderat (12 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC] = "Etwa 16 Prüfungen",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS] = "Großzügig (25 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC] = "Etwa 36 Prüfungen",
    -- Effects tracking
    [BATTLESCROLLS_ONBOARDING_EFFECTS_QUESTION] = "Wie viel Buff/Debuff-Tracking möchtest du?",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL] = "Vollständiges Tracking",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL_DESC] = "Deine Buffs, Boss-Debuffs UND Gruppen-Buff-Aktivzeiten (z.B. Major Courage-Aktivzeit aller Gruppenmitglieder)",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL] = "Nur Wichtiges",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL_DESC] = "Nur deine Buffs und Boss-Debuffs. Überspringt Gruppentracking für weniger Speicherverbrauch.",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED] = "Deaktiviert",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED_DESC] = "Kein Buff/Debuff-Tracking. Geringster Speicherverbrauch, aber keine Aktivzeitdaten in Berichten.",
    -- Completion
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TITLE] = "Alles bereit!",
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TEXT] = "Battle Scrolls ist bereit, deinen Kampf zu verfolgen.\n\nJetzt geh kämpfen!\n\nDeine Begegnungen erscheinen hier im Journal. Du kannst diese Einstellungen jederzeit im Einstellungen-Tab ändern.",
    [BATTLESCROLLS_ONBOARDING_CHAT_MESSAGE] = "[Battle Scrolls] Danke für die Installation! Öffne Journal > Battle Scrolls zum Einrichten und Aktivieren.",
    [BATTLESCROLLS_ONBOARDING_CONTINUE] = "Weiter",
    [BATTLESCROLLS_ONBOARDING_FINISH] = "Einrichtung beenden",
    [BATTLESCROLLS_ONBOARDING_LETS_GO] = "Los geht's!",
    [BATTLESCROLLS_ONBOARDING_STEP_FORMAT] = "Schritt <<1>> von <<2>>",

    -------------------------
    -- Dynamic Overview Panel
    -------------------------
    [BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN] = "Erlittener Schaden",
    [BATTLESCROLLS_OVERVIEW_TOP_HEALING] = "Top-Heilung",
    [BATTLESCROLLS_OVERVIEW_TOP_INCOMING] = "Top eingehender Schaden",
    [BATTLESCROLLS_OVERVIEW_HEALING_TARGETS] = "Heilungsziele",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES] = "Schadensquellen",
}

-- Register translations
for stringId, stringValue in pairs(strings) do
    SafeAddString(stringId, stringValue, 1)
end

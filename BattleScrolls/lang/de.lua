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
    [BATTLESCROLLS_UI_SWITCH_TO] = "Zeige <<1>>",
    [BATTLESCROLLS_STAT_HPS] = "HPS",

    -------------------------
    -- Zone/Instance Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ZONES] = "Alle Gebiete",
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
    [BATTLESCROLLS_TAB_DAMAGE] = "Schaden",
    [BATTLESCROLLS_TAB_HEALING] = "Heilung",
    [BATTLESCROLLS_TAB_EFFECTS] = "Effekte",
    [BATTLESCROLLS_TAB_EFFECTS_PLAYER] = "Deine Effekte",
    [BATTLESCROLLS_TAB_EFFECTS_BOSS] = "Bosseffekte",
    [BATTLESCROLLS_TAB_EFFECTS_GROUP] = "Gruppeneffekte",
    [BATTLESCROLLS_TAB_GROUP] = "Gruppe",

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
    [BATTLESCROLLS_SETTINGS_RECORD_IN_PVP] = "In PvP-Gebieten aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_BOSS_FIGHTS] = "Bosskämpfe aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS] = "Trash-Kämpfe aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS_TEXT] = "Kämpfe gegen normale Gegner (keine Bosse, keine Spieler).",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS] = "Spielerkämpfe aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS_TEXT] = "PvP-Kämpfe gegen andere Spieler.",
    [BATTLESCROLLS_SETTINGS_RECORD_DUMMY_FIGHTS] = "Übungspuppen-Kämpfe aufnehmen",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_ADVENTURE_ZONE_TEXT] = "Wenn aktiviert, werden die Einstellungen für Oberwelt und Instanzen überschrieben und alle Kämpfe <<l:1>> aufgenommen. Wenn deaktiviert, hat dies keine Auswirkung.",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE] = "Aufnahmefilter",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT] = "Gebiets- und Kampftyp-Filter werden kombiniert: Ein Kampf muss mindestens ein Gebiet UND einen Kampftyp erfüllen, um aufgenommen zu werden.",

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
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC] = "Wie viel Kampfverlauf gespeichert werden soll. Wenn das Limit erreicht wird, werden die ältesten nicht gesperrten Gebiete automatisch entfernt. Du kannst einzelne Gebiete sperren, um sie vor der Bereinigung zu schützen.",
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
    [BATTLESCROLLS_STAT_PATCH] = "Update",
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
    [BATTLESCROLLS_STAT_TOTAL_PROCS] = "<<1[$d Proc/$d Procs]>>",
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
    [BATTLESCROLLS_EFFECT_MEMBERS] = "<<1[$d Mitglied/$d Mitglieder]>>",

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
    [BATTLESCROLLS_OVERVIEW_BOSS_DAMAGE] = "Boss-Schaden",
    [BATTLESCROLLS_STAT_GROUP_DAMAGE] = "Gruppenschaden",
    [BATTLESCROLLS_STAT_GROUP_DPS] = "Gruppen-DPS",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE] = "Gruppen-Boss-Schaden",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DPS] = "Gruppen-Boss-DPS",

    -- Overview Panel - Ability Stats
    [BATTLESCROLLS_STAT_MAX_PREFIX] = "Max: <<1>>",
    [BATTLESCROLLS_STAT_CRIT_PERCENT] = "<<1>>% Krit",
    [BATTLESCROLLS_STAT_PER_SECOND] = "<<1>>/s",

    -- Overview Panel - Effect Stats
    [BATTLESCROLLS_EFFECT_APPS_COUNT] = "<<1[$d Anwendung/$d Anwendungen]>>",
    [BATTLESCROLLS_EFFECT_YOURS_PERCENT] = "<<1>>% dein",
    [BATTLESCROLLS_EFFECT_STACKS_COUNT] = "×<<1[$d Kumulation/$d Kumulationen]>>",

    -- Overview Panel Summary
    [BATTLESCROLLS_OVERVIEW_ENCOUNTER] = "Begegnung",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT] = "Schadensleistung",
    [BATTLESCROLLS_OVERVIEW_SUMMARY] = "Zusammenfassung",
    [BATTLESCROLLS_OVERVIEW_TOTAL] = "Gesamt",
    [BATTLESCROLLS_OVERVIEW_SHARE] = "Anteil",
    [BATTLESCROLLS_OVERVIEW_COMPOSITION] = "Zusammensetzung",
    [BATTLESCROLLS_OVERVIEW_QUALITY] = "Qualität",
    [BATTLESCROLLS_OVERVIEW_CRIT_RATE] = "Krit-Rate",
    [BATTLESCROLLS_OVERVIEW_MAX_HIT] = "Maximaler Treffer",
    [BATTLESCROLLS_OVERVIEW_MAX_HEAL] = "Maximale Heilung",
    [BATTLESCROLLS_OVERVIEW_KEY_BUFFS] = "Deine Buffs",
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
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_SMOOTH] = "Flüssig",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM] = "Benutzerdefiniert (<<1>> FPS)",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE] = "Verarbeitungsgeschwindigkeit",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "Steuert, wie schnell Hintergrundaufgaben verarbeitet werden. Betrifft hauptsächlich die Journal-Oberfläche und die Zeit zwischen Kampfende und dem Erscheinen des Eintrags in der Liste.\n\nLeistung: Schnellste Verarbeitung. Kann kurze Ruckler verursachen.\nFlüssig: Flüssigeres Gameplay, langsamere Verarbeitung. Kann dazu führen, dass Einträge beim Laden hängen bleiben oder nicht im Journal erscheinen.\n\nDiese Einstellung betrifft ALLE Addons, die LibAsync verwenden.",

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
    -- Delete Functionality
    -------------------------
    [BATTLESCROLLS_DELETE] = "Löschen",
    [BATTLESCROLLS_DELETE_INSTANCE_TITLE] = "Gebiet löschen",
    [BATTLESCROLLS_DELETE_INSTANCE_TEXT] = "<<1>> und alle zugehörigen Kämpfe löschen?",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TITLE] = "Kampf löschen",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TEXT] = "<<1>> löschen?",
    [BATTLESCROLLS_DELETE_WARNING] = "Diese Aktion kann nicht rückgängig gemacht werden.",
    [BATTLESCROLLS_DELETE_MEMORY_FREE] = "Gibt ungefähr <<1>> frei",
    [BATTLESCROLLS_DELETE_MEMORY_STATUS] = "Speicher: <<1>> von <<2>> (<<3>>%)",

    -------------------------
    -- Dynamic Overview Panel
    -------------------------
    [BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN] = "Erlittener Schaden",
    [BATTLESCROLLS_OVERVIEW_TOP_HEALING] = "Top-Heilung",
    [BATTLESCROLLS_OVERVIEW_TOP_INCOMING] = "Top eingehender Schaden",
    [BATTLESCROLLS_OVERVIEW_HEALING_TARGETS] = "Heilungsziele",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES] = "Schadensquellen",

    -------------------------
    -- Instance Locking
    -------------------------
    [BATTLESCROLLS_LOCK_ERROR_TITLE] = "Sperren nicht möglich",
    [BATTLESCROLLS_LOCK_ERROR_TEXT] = "Das Sperren dieses Gebiets würde dein Speicherlimit überschreiten. Gesperrte Gebiete und das neueste Gebiet sind vor der Bereinigung geschützt.\n\nUm Speicher freizugeben, entsperre oder lösche einige gesperrte Gebiete, oder erhöhe dein Speicherlimit in den Einstellungen.",
    [BATTLESCROLLS_LOCK_LOCKED_SIZE] = "Derzeit gesperrt: <<1>>",
    [BATTLESCROLLS_LOCK_INSTANCE_SIZE] = "Dieses Gebiet: <<1>>",
    [BATTLESCROLLS_LOCK_LIMIT] = "Speicherlimit: <<1>>",

    -------------------------
    -- Favorite Effects
    -------------------------
    [BATTLESCROLLS_FAVORITE_EFFECT] = "Favorisieren",
    [BATTLESCROLLS_UNFAVORITE_EFFECT] = "Favorit entfernen",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES] = "Alle Favoriten löschen",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES_TOOLTIP] = "Alle favorisierten Effekte entfernen. Favorisierte Effekte werden oben in jeder Effektliste angezeigt.",

    -------------------------
    -- Group Tab Enhancements
    -------------------------
    [BATTLESCROLLS_STAT_SURVIVABILITY] = "Überlebensfähigkeit",
    [BATTLESCROLLS_BOSS_DAMAGE_TAKEN] = "Erlittener Boss-Schaden",

    -- Group Member Card Strings
    [BATTLESCROLLS_GROUP_CARD_OF_GROUP] = "der Gruppe",
    [BATTLESCROLLS_GROUP_CARD_ALIVE] = "Überlebt",

    -- Group Tab Redesign
    [BATTLESCROLLS_GROUP_DAMAGE_BY_TYPE] = "Schaden nach Typ",
    [BATTLESCROLLS_GROUP_VS_AVERAGE] = "vs DD-Durchschnitt",
    [BATTLESCROLLS_GROUP_DD_COUNTED] = "Gezählte DDs",
    [BATTLESCROLLS_GROUP_DAMAGE_OUTPUT] = "Schadensleistung",
    [BATTLESCROLLS_GROUP_HEALING_OUTPUT] = "Heilungsleistung",
    [BATTLESCROLLS_GROUP_RANK] = "Rang",
    [BATTLESCROLLS_GROUP_MAGICAL] = "Magisch",
    [BATTLESCROLLS_GROUP_DEATH] = "Tod",
    [BATTLESCROLLS_GROUP_FIRST_DEATH] = "Erster Tod",
    [BATTLESCROLLS_GROUP_LAST_DEATH] = "Letzter Tod",
    [BATTLESCROLLS_GROUP_DEATHS] = "Tode",
    [BATTLESCROLLS_GROUP_COL_DEATHS] = "Tode",
    [BATTLESCROLLS_GROUP_DEATH_COUNT] = "<<1[$d Tod/$d Tode]>>",
    [BATTLESCROLLS_GROUP_METRIC_DPS] = "<<1>> DPS",
    [BATTLESCROLLS_GROUP_METRIC_HPS] = "<<1>> HPS",
    [BATTLESCROLLS_GROUP_METRIC_DTPS] = "<<1>> DTPS",
    [BATTLESCROLLS_GROUP_METRIC_CRIT] = "<<1>>% Krit",
    [BATTLESCROLLS_GROUP_METRIC_OVERHEAL] = "<<1>>% Überheilung",
    [BATTLESCROLLS_GROUP_TOP_INCOMING_DAMAGE] = "Top eingehender Schaden",
    [BATTLESCROLLS_GROUP_DEATH_AT] = "bei <<1>>",
    [BATTLESCROLLS_HEADER_DEATHS] = "Tode",
    [BATTLESCROLLS_STAT_DEATH_COUNT] = "Todesanzahl",
    [BATTLESCROLLS_DEATH_N] = "Tod <<1>>",

    -- Group Context Tooltips
    [BATTLESCROLLS_TOOLTIP_GROUP_TOTAL] = "Gruppensumme",
    [BATTLESCROLLS_TOOLTIP_GROUP_DPS] = "Gruppen-DPS",
    [BATTLESCROLLS_TOOLTIP_GROUP_AVG] = "DD-Durchschnitt",
    [BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN] = "Gruppenübersicht",
    [BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_TAKEN] = "Erlittener Gruppenschaden",

    -- Group Table
    [BATTLESCROLLS_GROUP_COL_NAME] = "Name",
    [BATTLESCROLLS_GROUP_COL_TOTAL] = "Gesamt",
    [BATTLESCROLLS_GROUP_COL_CRIT] = "Krit",
    [BATTLESCROLLS_GROUP_COL_ALIVE] = "Über\nlebt",

    -------------------------
    -- Setup Tab
    -------------------------
    [BATTLESCROLLS_TAB_BUILD] = "Zusammenstellung",
    [BATTLESCROLLS_SETUP_ABILITIES] = "Fähigkeiten",
    [BATTLESCROLLS_SETUP_FRONT_BAR] = "Primärleiste",
    [BATTLESCROLLS_SETUP_BACK_BAR] = "Reserveleiste",
    [BATTLESCROLLS_SETUP_GEAR_SETS] = "Ausrüstungssets",
    [BATTLESCROLLS_SETUP_EQUIPMENT] = "Ausrüstung",
    [BATTLESCROLLS_SETUP_POISONS] = "Gifte",
    [BATTLESCROLLS_SETUP_CHARACTER] = "Charakter",
    [BATTLESCROLLS_SETUP_CLASS_SKILLS] = "Klassen-Fertigkeitslinien",
    [BATTLESCROLLS_SETUP_MUNDUS] = "Mundus",
    [BATTLESCROLLS_SETUP_FOOD] = "Nahrung",
    [BATTLESCROLLS_WEAPON_GREATSWORD] = "Großschwert",
    [BATTLESCROLLS_WEAPON_BATTLE_AXE] = "Streitaxt",
    [BATTLESCROLLS_WEAPON_MAUL] = "Streitkolben",

    -------------------------
    -- Food Buff Descriptions
    -------------------------
    [BATTLESCROLLS_FOOD_MAX_HEALTH] = "Maximale Gesundheit",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA] = "Maximale Magicka",
    [BATTLESCROLLS_FOOD_MAX_STAMINA] = "Maximale Ausdauer",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_MAGICKA] = "Maximale Gesundheit und Magicka",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_STAMINA] = "Maximale Gesundheit und Ausdauer",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA_STAMINA] = "Maximale Magicka und Ausdauer",
    [BATTLESCROLLS_FOOD_MAX_TRISTAT] = "Maximale Gesundheit, Magicka und Ausdauer",
    [BATTLESCROLLS_FOOD_HEALTH_RECOVERY] = "Gesundheitsregeneration",
    [BATTLESCROLLS_FOOD_MAGICKA_RECOVERY] = "Magickaregeneration",
    [BATTLESCROLLS_FOOD_STAMINA_RECOVERY] = "Ausdauerregeneration",
    [BATTLESCROLLS_FOOD_HEALTH_MAGICKA_RECOVERY] = "Gesundheits- und Magickaregeneration",
    [BATTLESCROLLS_FOOD_HEALTH_STAMINA_RECOVERY] = "Gesundheits- und Ausdauerregeneration",
    [BATTLESCROLLS_FOOD_MAGICKA_STAMINA_RECOVERY] = "Magicka- und Ausdauerregeneration",
    [BATTLESCROLLS_FOOD_RECOVERY_TRISTAT] = "Gesundheits-, Magicka- und Ausdauerregeneration",

    -------------------------
    -- Alchemy Traits
    -------------------------
    [BATTLESCROLLS_ALCHEMY_TRAIT1] = "Leben wiederherstellen",
    [BATTLESCROLLS_ALCHEMY_TRAIT2] = "Lebensverwüstung",
    [BATTLESCROLLS_ALCHEMY_TRAIT3] = "Magicka wiederherstellen",
    [BATTLESCROLLS_ALCHEMY_TRAIT4] = "Magickaverwüstung",
    [BATTLESCROLLS_ALCHEMY_TRAIT5] = "Ausdauer wiederherstellen",
    [BATTLESCROLLS_ALCHEMY_TRAIT6] = "Ausdauerverwüstung",
    [BATTLESCROLLS_ALCHEMY_TRAIT7] = "Erhöht Magieresistenz",
    [BATTLESCROLLS_ALCHEMY_TRAIT8] = "Bruch",
    [BATTLESCROLLS_ALCHEMY_TRAIT9] = "Erhöht Rüstung",
    [BATTLESCROLLS_ALCHEMY_TRAIT10] = "Fraktur",
    [BATTLESCROLLS_ALCHEMY_TRAIT11] = "Erhöht Magiekraft",
    [BATTLESCROLLS_ALCHEMY_TRAIT12] = "Feigheit",
    [BATTLESCROLLS_ALCHEMY_TRAIT13] = "Erhöht Waffenkraft",
    [BATTLESCROLLS_ALCHEMY_TRAIT14] = "Versehren",
    [BATTLESCROLLS_ALCHEMY_TRAIT15] = "Kritische Magietreffer",
    [BATTLESCROLLS_ALCHEMY_TRAIT16] = "Ungewissheit",
    [BATTLESCROLLS_ALCHEMY_TRAIT17] = "Kritische Waffentreffer",
    [BATTLESCROLLS_ALCHEMY_TRAIT18] = "Schwäche",
    [BATTLESCROLLS_ALCHEMY_TRAIT19] = "Sicherer Stand",
    [BATTLESCROLLS_ALCHEMY_TRAIT20] = "Einfangen",
    [BATTLESCROLLS_ALCHEMY_TRAIT21] = "Detektion",
    [BATTLESCROLLS_ALCHEMY_TRAIT22] = "Unsichtbarkeit",
    [BATTLESCROLLS_ALCHEMY_TRAIT23] = "Tempo",
    [BATTLESCROLLS_ALCHEMY_TRAIT24] = "Einschränken",
    [BATTLESCROLLS_ALCHEMY_TRAIT25] = "Schutz",
    [BATTLESCROLLS_ALCHEMY_TRAIT26] = "Verwundbarkeit",
    [BATTLESCROLLS_ALCHEMY_TRAIT27] = "Beständige Heilung",
    [BATTLESCROLLS_ALCHEMY_TRAIT28] = "Langsame Lebensverwüstung",
    [BATTLESCROLLS_ALCHEMY_TRAIT29] = "Vitalität",
    [BATTLESCROLLS_ALCHEMY_TRAIT30] = "Schänden",
    [BATTLESCROLLS_ALCHEMY_TRAIT31] = "Heldentum",
    [BATTLESCROLLS_ALCHEMY_TRAIT32] = "Scheu",

    -------------------------
    -- Aggregate
    -------------------------
    -- Navigation
    [BATTLESCROLLS_PIVOT_TITLE] = "Auswertung",
    [BATTLESCROLLS_PIVOT_ENTRY] = "Auswertung",
    [BATTLESCROLLS_PIVOT_ENTRY_DESC] = "Eigene Auswertungen über Kämpfe und Instanzen erstellen",
    [BATTLESCROLLS_PIVOT_ENTRY_DESC_ENCOUNTER] = "Kampfdaten dieser Instanz übergreifend auswerten",

    -- Scope section
    [BATTLESCROLLS_PIVOT_SCOPE] = "Umfang",
    [BATTLESCROLLS_PIVOT_INSTANCE_SCOPE] = "Instanzbereich",
    [BATTLESCROLLS_PIVOT_TIME_FILTER] = "Zeit",
    [BATTLESCROLLS_PIVOT_ENCOUNTER_FILTER] = "Kampffilter",

    -- Instance scope options
    [BATTLESCROLLS_PIVOT_SCOPE_EVERYTHING] = "Alles",
    [BATTLESCROLLS_PIVOT_SCOPE_INSTANCED] = "Alle Instanzen",
    [BATTLESCROLLS_PIVOT_SCOPE_OVERLAND] = "Alle Oberweltgebiete",
    [BATTLESCROLLS_PIVOT_SCOPE_HOUSES] = "Alle Häuser",
    [BATTLESCROLLS_PIVOT_SCOPE_PVP] = "Alle PvP-Gebiete",
    [BATTLESCROLLS_PIVOT_SCOPE_ZONES] = "Nach Gebietsname",
    [BATTLESCROLLS_PIVOT_SCOPE_SPECIFIC] = "Bestimmte Instanzen",

    -- Time filter options
    [BATTLESCROLLS_PIVOT_TIME_ALL] = "Gesamter Zeitraum",
    [BATTLESCROLLS_PIVOT_TIME_TODAY] = "Heute",
    [BATTLESCROLLS_PIVOT_TIME_24H] = "Letzte 24 Stunden",
    [BATTLESCROLLS_PIVOT_TIME_3D] = "Letzte 3 Tage",
    [BATTLESCROLLS_PIVOT_TIME_7D] = "Letzte 7 Tage",
    [BATTLESCROLLS_PIVOT_TIME_14D] = "Letzte 14 Tage",
    [BATTLESCROLLS_PIVOT_TIME_30D] = "Letzte 30 Tage",
    [BATTLESCROLLS_PIVOT_TIME_90D] = "Letzte 90 Tage",
    [BATTLESCROLLS_PIVOT_TIME_CUSTOM] = "Benutzerdefiniert...",

    -- Encounter category options
    [BATTLESCROLLS_PIVOT_ENC_ALL] = "Alle Kämpfe",
    [BATTLESCROLLS_PIVOT_ENC_BOSS] = "Bosskämpfe",
    [BATTLESCROLLS_PIVOT_ENC_TRASH] = "Trash-Kämpfe",
    [BATTLESCROLLS_PIVOT_ENC_PLAYER] = "Spielerkämpfe",
    [BATTLESCROLLS_PIVOT_ENC_DUMMY] = "Übungspuppe",
    [BATTLESCROLLS_PIVOT_ENC_SPECIFIC] = "Bestimmte Kämpfe",

    -- Query section
    [BATTLESCROLLS_PIVOT_QUERY] = "Abfrage",
    [BATTLESCROLLS_PIVOT_DOMAIN] = "Datenbereich",
    [BATTLESCROLLS_PIVOT_ROWS] = "Zeilen",
    [BATTLESCROLLS_PIVOT_COLUMNS] = "Spalten",
    [BATTLESCROLLS_PIVOT_VALUES] = "Werte",
    [BATTLESCROLLS_PIVOT_AGGREGATION] = "Aggregation",
    [BATTLESCROLLS_PIVOT_FILTERS] = "Filter",

    -- Target filter
    [BATTLESCROLLS_PIVOT_TARGETS] = "Ziele",
    [BATTLESCROLLS_PIVOT_TARGETS_ALL] = "Alle Ziele",
    [BATTLESCROLLS_PIVOT_TARGETS_BOSSES] = "Nur Bosse",

    -- Domain names
    [BATTLESCROLLS_PIVOT_DOMAIN_DAMAGE] = "Schaden",
    [BATTLESCROLLS_PIVOT_DOMAIN_HEALING_OUT] = "Heilung ausgehend",
    [BATTLESCROLLS_PIVOT_DOMAIN_HEALING_IN] = "Heilung eingehend",
    -- Effects domain labels reuse BATTLESCROLLS_TAB_EFFECTS_* strings
    [BATTLESCROLLS_PIVOT_DOMAIN_GROUP] = "Gruppe",
    [BATTLESCROLLS_PIVOT_DOMAIN_OVERVIEW] = "Übersicht",

    -- Dimension names
    [BATTLESCROLLS_PIVOT_DIM_ABILITY] = "Fähigkeit",
    [BATTLESCROLLS_PIVOT_DIM_TARGET] = "Ziel",
    [BATTLESCROLLS_PIVOT_DIM_SOURCE] = "Quelle",
    [BATTLESCROLLS_PIVOT_DIM_BOSS] = "Boss",
    [BATTLESCROLLS_PIVOT_DIM_DAMAGE_TYPE] = "Schadensart",
    [BATTLESCROLLS_PIVOT_DIM_DELIVERY] = "Wirkungsart",
    [BATTLESCROLLS_PIVOT_DIM_AOE_ST] = "AoE / Einzelziel",
    [BATTLESCROLLS_PIVOT_DIM_BUFF_DEBUFF] = "Buff / Debuff",
    [BATTLESCROLLS_PIVOT_DIM_GROUP_MEMBER] = "Gruppenmitglied",
    [BATTLESCROLLS_PIVOT_DIM_ROLE] = "Rolle",
    [BATTLESCROLLS_PIVOT_DIM_ENCOUNTER] = "Kampf",
    [BATTLESCROLLS_PIVOT_DIM_INSTANCE] = "Instanz",
    [BATTLESCROLLS_PIVOT_COL_METRICS] = "Metriken",

    -- Metric names
    [BATTLESCROLLS_PIVOT_METRIC_TOTAL_DAMAGE] = "Gesamtschaden",
    [BATTLESCROLLS_PIVOT_METRIC_DPS] = "DPS",
    [BATTLESCROLLS_PIVOT_METRIC_CRIT_PERCENT] = "Krit %",
    [BATTLESCROLLS_PIVOT_METRIC_HIT_COUNT] = "Treffer",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_HIT] = "Max. Treffer",
    [BATTLESCROLLS_PIVOT_METRIC_MIN_HIT] = "Min. Treffer",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_HIT] = "Durchschn. Treffer",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HEALING] = "Effektive Heilung",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HEALING] = "Gesamte Heilung",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS] = "Gesamt-HPS",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS] = "Effektive HPS",
    [BATTLESCROLLS_PIVOT_METRIC_OVERHEAL_PERCENT] = "Überheilung %",
    [BATTLESCROLLS_PIVOT_METRIC_HEAL_CRIT_PERCENT] = "Heil-Krit %",
    [BATTLESCROLLS_PIVOT_METRIC_HEAL_HIT_COUNT] = "Heilungstreffer",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_HEAL] = "Max. Heilung",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_HEAL] = "Durchschn. Heilung",
    [BATTLESCROLLS_PIVOT_METRIC_UPTIME_PERCENT] = "Aktivzeit %",
    [BATTLESCROLLS_PIVOT_METRIC_PLAYER_UPTIME_PERCENT] = "Deine Aktivzeit %",
    [BATTLESCROLLS_PIVOT_METRIC_APPLICATIONS] = "Anwendungen",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_STACKS_TIME] = "Max. Stapel-Zeit %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DPS] = "DPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_BOSS_DPS] = "Boss-DPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_TOTAL_DAMAGE] = "Gesamtschaden",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_CRIT_PERCENT] = "Krit %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DOT_PERCENT] = "DoT %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_AOE_PERCENT] = "AoE %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_MAX_HIT] = "Max. Treffer",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DTPS] = "DTPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_RAW_HPS] = "Gesamt-HPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_EFFECTIVE_HPS] = "Effektive HPS",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_OUT] = "Effektive HPS (ausg.)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_OUT] = "Gesamt-HPS (ausg.)",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_IN] = "Effektive HPS (eing.)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_IN] = "Gesamt-HPS (eing.)",
    [BATTLESCROLLS_PIVOT_METRIC_BOSS_DPS] = "Boss-DPS",
    [BATTLESCROLLS_PIVOT_METRIC_BOSS_DAMAGE] = "Boss-Schaden",
    [BATTLESCROLLS_PIVOT_METRIC_DTPS] = "DTPS",
    [BATTLESCROLLS_PIVOT_METRIC_DAMAGE_TAKEN] = "Erlittener Schaden",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_ALIVE_PERCENT] = "Überlebt %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DEATH_COUNT] = "Tode",
    [BATTLESCROLLS_PIVOT_METRIC_DURATION] = "Dauer",
    [BATTLESCROLLS_PIVOT_METRIC_DEATH_COUNT] = "Tode",

    -- Aggregation options
    [BATTLESCROLLS_PIVOT_AGG_SUM] = "Summe",
    [BATTLESCROLLS_PIVOT_AGG_AVG] = "Durchschnitt",
    [BATTLESCROLLS_PIVOT_AGG_MAX] = "Max",
    [BATTLESCROLLS_PIVOT_AGG_MIN] = "Min",

    -- Actions
    [BATTLESCROLLS_PIVOT_RUN] = "Abfrage starten",
    [BATTLESCROLLS_PIVOT_SAVE] = "Abfrage speichern",
    [BATTLESCROLLS_PIVOT_LOAD] = "Abfrage laden",
    [BATTLESCROLLS_PIVOT_DELETE_QUERY] = "Abfrage löschen",

    -- Loading / Results
    [BATTLESCROLLS_PIVOT_LOADING] = "Lade Kämpfe... <<1>> / <<2>>",
    [BATTLESCROLLS_PIVOT_NO_RESULTS] = "Keine Daten entsprechen deiner Abfrage",
    [BATTLESCROLLS_PIVOT_NO_ENCOUNTERS] = "Keine Kämpfe entsprechen deinen Filtern",
    [BATTLESCROLLS_PIVOT_NO_BOSSES] = "Keine Bosskämpfe entsprechen deinen Filtern",
    [BATTLESCROLLS_PIVOT_ENCOUNTERS_PROCESSED] = "<<1[$d Kampf/$d Kämpfe]>> verarbeitet",
    [BATTLESCROLLS_PIVOT_ROWS_CAPPED] = "Ergebnisse auf <<1>> Zeilen begrenzt",
    [BATTLESCROLLS_PIVOT_COLUMNS_CAPPED] = "Ergebnisse auf <<1>> Spalten begrenzt",
    [BATTLESCROLLS_PIVOT_TIP_DOMAIN_OVERVIEW] = "Zusammenfassung über alle Schadens-, Heilungs- und Effektdomänen. Zeigt kombinierte Gesamtwerte statt einzelner Aufschlüsselungen.",
    [BATTLESCROLLS_PIVOT_TIP_ENC_BOSS_NAMES] = "Filtert auf Begegnungen mit den ausgewählten Bossen. Bossnamen werden im nächsten Schritt ausgewählt.",
    [BATTLESCROLLS_PIVOT_TIP_DIM_DELIVERY] = "Teilt Daten nach Wirkungsart auf: Direkt, DoT (Schaden über Zeit), HoT (Heilung über Zeit) oder Gemischt.",
    [BATTLESCROLLS_PIVOT_TIP_DIM_DAMAGE_TYPE] = "Teilt Daten nach Schadensart auf: Physisch, Feuer, Schock, Frost, Magie, Gift, Seuche, Blutung, Oblivion und andere.",
    [BATTLESCROLLS_PIVOT_TIP_DOMAIN_GROUP] = "Kampfwerte pro Gruppenmitglied wie DPS, Gesamtschaden und Krit-Rate. Für Buff-/Debuff-Wirkzeiten bei Gruppenmitgliedern verwende Gruppeneffekte.",
    [BATTLESCROLLS_PIVOT_TIP_AGGREGATION] = "Wie Werte kombiniert werden, wenn mehrere Begegnungen in dieselbe Zelle einfließen. Zum Beispiel zeigt Durchschnitt-DPS den Mittelwert über Begegnungen, während Max den besten Einzelkampf zeigt.",

    -- Save dialog
    [BATTLESCROLLS_PIVOT_SAVE_TITLE] = "Abfrage speichern",
    [BATTLESCROLLS_PIVOT_SAVE_PROMPT] = "Name für diese Abfrage eingeben:",
    [BATTLESCROLLS_PIVOT_SAVE_OVERWRITE] = "Eine Abfrage mit dem Namen \"<<1>>\" existiert bereits. Überschreiben?",

    -- Load/delete dialog
    [BATTLESCROLLS_PIVOT_QUERY_SAVED] = "Abfrage als \"<<1>>\" gespeichert",
    [BATTLESCROLLS_PIVOT_LOAD_TITLE] = "Abfrage laden",
    [BATTLESCROLLS_PIVOT_DELETE_CONFIRM] = "Abfrage \"<<1>>\" löschen?",

    -- Selector dialogs
    [BATTLESCROLLS_PIVOT_SELECT_ZONES] = "Gebiete auswählen",
    [BATTLESCROLLS_PIVOT_SELECT_INSTANCES] = "Instanzen auswählen",
    [BATTLESCROLLS_PIVOT_SELECT_ENCOUNTERS] = "Kämpfe auswählen",
    [BATTLESCROLLS_PIVOT_SELECT_BOSSES] = "Bossnamen auswählen",
    [BATTLESCROLLS_PIVOT_SELECT_METRICS] = "Metriken auswählen",
    [BATTLESCROLLS_PIVOT_SELECTED_COUNT] = "<<1>> ausgewählt",
    [BATTLESCROLLS_PIVOT_SELECT_ALL] = "Alle auswählen",
    [BATTLESCROLLS_PIVOT_DESELECT_ALL] = "Alle abwählen",
    [BATTLESCROLLS_PIVOT_NONE_SELECTED] = "Keine Auswahl",

    -- Filter/range
    [BATTLESCROLLS_PIVOT_ENC_BOSS_NAMES] = "Nach Bossname",
    [BATTLESCROLLS_PIVOT_CUSTOM_DAYS] = "Letzte <<1>> Tage",
    [BATTLESCROLLS_PIVOT_CUSTOM_DAYS_PROMPT] = "Anzahl der Tage zurück",
    [BATTLESCROLLS_PIVOT_CUSTOM_RANGE_TITLE] = "Benutzerdefinierter Zeitraum",

    -- Query description
    [BATTLESCROLLS_PIVOT_DESC_BY] = "<<1>> nach <<2>>",
    [BATTLESCROLLS_PIVOT_DESC_CROSS] = "× <<1>>",
    [BATTLESCROLLS_PIVOT_DESC_N_METRICS] = "<<1[$d Metrik/$d Metriken]>>",
}

-- Register translations
for stringId, stringValue in pairs(strings) do
    SafeAddString(stringId, stringValue, 1)
end

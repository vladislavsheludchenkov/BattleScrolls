-- Battle Scrolls Localization - Spanish (Español)
-- Translations use ESO's official Spanish terminology

local strings = {
    -------------------------
    -- Core UI Labels
    -------------------------
    [BATTLESCROLLS_UI_NAME] = "Pergaminos de Batalla",
    [BATTLESCROLLS_UI_SETTINGS] = "Ajustes",
    [BATTLESCROLLS_UI_FILTER] = "Filtro",
    [BATTLESCROLLS_UI_FILTER_ACTIVE] = "Filtro (Activo)",
    [BATTLESCROLLS_UI_SWITCH_TO] = "Cambiar a <<1>>",
    [BATTLESCROLLS_STAT_HPS] = "HPS",

    -------------------------
    -- Zone/Instance Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ZONES] = "Todas las zonas",
    [BATTLESCROLLS_TAB_INSTANCED] = "Instancias",
    [BATTLESCROLLS_TAB_OVERLAND] = "Mundo abierto",
    [BATTLESCROLLS_TAB_HOUSES] = "Casas",
    [BATTLESCROLLS_TAB_PVP] = "JcJ",

    -------------------------
    -- Encounter Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ENCOUNTERS] = "Todos los combates",
    [BATTLESCROLLS_TAB_BOSS_ENCOUNTERS] = "Combates de jefe",
    [BATTLESCROLLS_TAB_OTHER_ENCOUNTERS] = "Otros combates",
    [BATTLESCROLLS_TAB_PLAYER_ENCOUNTERS] = "Combates JcJ",
    [BATTLESCROLLS_TAB_TARGET_DUMMY] = "Muñeco de entrenamiento",

    -------------------------
    -- Stats Tabs
    -------------------------
    [BATTLESCROLLS_TAB_OVERVIEW] = "Resumen",
    [BATTLESCROLLS_TAB_BOSS_DAMAGE_DONE] = "Daño al jefe",
    [BATTLESCROLLS_TAB_DAMAGE_DONE] = "Daño infligido",
    [BATTLESCROLLS_TAB_DAMAGE_TAKEN] = "Daño recibido",
    [BATTLESCROLLS_TAB_HEALING_OUT] = "Curación otorgada",
    [BATTLESCROLLS_TAB_SELF_HEALING] = "Autocuración",
    [BATTLESCROLLS_TAB_HEALING_IN] = "Curación recibida",
    [BATTLESCROLLS_TAB_DAMAGE] = "Daño",
    [BATTLESCROLLS_TAB_HEALING] = "Curación",
    [BATTLESCROLLS_TAB_EFFECTS] = "Efectos",
    [BATTLESCROLLS_TAB_EFFECTS_PLAYER] = "Tus efectos",
    [BATTLESCROLLS_TAB_EFFECTS_BOSS] = "Efectos de jefes",
    [BATTLESCROLLS_TAB_EFFECTS_GROUP] = "Efectos del grupo",
    [BATTLESCROLLS_TAB_GROUP] = "Grupo",
    [BATTLESCROLLS_TAB_ACTIVITY] = "Actividad",

    -------------------------
    -- Weaving Stats
    -------------------------
    [BATTLESCROLLS_HEADER_WEAVING] = "Weaving",
    [BATTLESCROLLS_HEADER_WEAVING_BY_ABILITY] = "Weaving por habilidad",
    [BATTLESCROLLS_STAT_AVG_WEAVE_TIME] = "Retraso medio de lanzamiento",
    [BATTLESCROLLS_STAT_WEAVE_TIME_BEFORE] = "Tiempo de weaving antes",
    [BATTLESCROLLS_STAT_TIME_LOST] = "Tiempo perdido",
    [BATTLESCROLLS_STAT_LIGHT_ATTACKS] = "Ataques ligeros",
    [BATTLESCROLLS_STAT_HEAVY_ATTACKS] = "Ataques pesados",
    [BATTLESCROLLS_STAT_SKILL_ACTIVATIONS] = "Habilidades",
    [BATTLESCROLLS_STAT_CASTS] = "Lanzamientos",
    [BATTLESCROLLS_STAT_WEAVING_ERRORS] = "Errores de weaving",
    [BATTLESCROLLS_STAT_MISSED_LA] = "Ligeros perdidos",
    [BATTLESCROLLS_STAT_DOUBLE_LA] = "Ligeros dobles",
    [BATTLESCROLLS_TOOLTIP_DELAY_AFTER] = "Retraso tras lanzar",
    [BATTLESCROLLS_TOOLTIP_DELAY_BEFORE] = "Retraso antes de lanzar",
    [BATTLESCROLLS_FORMAT_SECONDS] = "<<1>>s",
    [BATTLESCROLLS_FORMAT_MILLISECONDS] = "<<1>>ms",
    [BATTLESCROLLS_TOOLTIP_INTER_CAST_DESC] = "Retraso medio entre lanzamientos. Se mide desde que termina el GCD o el tiempo de lanzamiento de una habilidad hasta que comienza la siguiente acción. También conocido como Weaving Average en CMX.",
    [BATTLESCROLLS_TOOLTIP_TIME_LOST_DESC] = "Tiempo total entre lanzamientos durante el encuentro. También conocido como Weaving Total en CMX.",
    [BATTLESCROLLS_TOOLTIP_MISSED_LA_DESC] = "Habilidad lanzada directamente tras otra habilidad, sin un ataque ligero entre medias.",
    [BATTLESCROLLS_TOOLTIP_DOUBLE_LA_DESC] = "Dos ataques ligeros seguidos, sin una habilidad entre medias.",

    -------------------------
    -- Time Headers
    -------------------------
    [BATTLESCROLLS_TIME_TODAY] = "Hoy",
    [BATTLESCROLLS_TIME_YESTERDAY] = "Ayer",

    -------------------------
    -- DPS Meter Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_DPS_METER] = "Medidor de DPS",
    [BATTLESCROLLS_SETTINGS_KEEP_AFTER_COMBAT] = "Mantener tras combate",
    [BATTLESCROLLS_SETTINGS_HIDE_IMMEDIATELY] = "Ocultar inmediatamente",
    [BATTLESCROLLS_SETTINGS_10_SECONDS] = "10 segundos",
    [BATTLESCROLLS_SETTINGS_30_SECONDS] = "30 segundos",
    [BATTLESCROLLS_SETTINGS_2_MINUTES] = "2 minutos",
    [BATTLESCROLLS_SETTINGS_5_MINUTES] = "5 minutos",
    [BATTLESCROLLS_SETTINGS_UNTIL_RELOAD] = "Hasta recargar",

    [BATTLESCROLLS_SETTINGS_PERSONAL_METER] = "Medidor personal",
    [BATTLESCROLLS_SETTINGS_GROUP_METER] = "Medidor de grupo",
    [BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT] = "Los miembros de tu grupo aún podrán ver tu DPS si tienen el addon instalado.",
    [BATTLESCROLLS_SETTINGS_ENABLED] = "Activado",
    [BATTLESCROLLS_SETTINGS_MODE] = "Modo",
    [BATTLESCROLLS_SETTINGS_DESIGN] = "Diseño",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_LEFT] = "Distancia desde la izquierda",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_TOP] = "Distancia desde arriba",
    [BATTLESCROLLS_SETTINGS_SIZE] = "Tamaño",
    [BATTLESCROLLS_SETTINGS_RESET_POSITION] = "Restablecer posición",
    [BATTLESCROLLS_SETTINGS_POSITION] = "Posición",

    -- Meter modes
    [BATTLESCROLLS_SETTINGS_MODE_AUTO] = "Auto",
    [BATTLESCROLLS_SETTINGS_MODE_DAMAGE] = "Daño",
    [BATTLESCROLLS_SETTINGS_MODE_HEALING] = "Curación",

    -- Meter size options
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_SMALL] = "Muy pequeño",
    [BATTLESCROLLS_SETTINGS_SIZE_SMALL] = "Pequeño",
    [BATTLESCROLLS_SETTINGS_SIZE_MEDIUM] = "Mediano",
    [BATTLESCROLLS_SETTINGS_SIZE_LARGE] = "Grande",
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_LARGE] = "Muy grande",

    -- Meter position options
    [BATTLESCROLLS_SETTINGS_POSITION_BELOW] = "Debajo del tuyo",
    [BATTLESCROLLS_SETTINGS_POSITION_ABOVE] = "Encima del tuyo",
    [BATTLESCROLLS_SETTINGS_POSITION_SEPARATE] = "Separado",

    -- Auto mode tooltip
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TITLE] = "Modo automático",
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TEXT] = "Muestra el valor más alto - DPS o HPS.",

    -- Group tracker tooltips
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA] = "Mostrar sin datos de grupo",
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA_TEXT] = "Cuando está activado, el medidor de grupo se muestra incluso si ningún otro miembro comparte sus datos de DPS. Solo verás tus propias estadísticas.",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_DESIGN] = "Diseño del medidor de grupo",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION] = "Posición del medidor de grupo",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION_TEXT] = "Debajo/Encima: Adjunta el medidor de grupo a tu medidor personal.\nSeparado: Coloca el medidor de grupo independientemente con posicionamiento personalizado.",

    -------------------------
    -- Recording Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_RECORDING] = "Grabación",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED] = "Grabar en instancias",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED_TEXT] = "Las zonas instanciadas incluyen Mazmorras, Pruebas, Arenas y el Archivo Infinito.",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_OVERLAND] = "Grabar en mundo abierto",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_HOUSES] = "Grabar en casas",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_PVP] = "Grabar en JcJ",
    [BATTLESCROLLS_SETTINGS_RECORD_BOSS_FIGHTS] = "Grabar combates de jefe",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS] = "Grabar combates de adds",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS_TEXT] = "Combates contra enemigos normales (no jefes, no jugadores).",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS] = "Grabar combates JcJ",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS_TEXT] = "Combates JcJ contra otros jugadores.",
    [BATTLESCROLLS_SETTINGS_RECORD_DUMMY_FIGHTS] = "Grabar combates con muñeco",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_ADVENTURE_ZONE_TEXT] = "Cuando está activado, anula los ajustes de Mundo abierto e Instancias y graba todos los combates en esta zona. Cuando está desactivado, no tiene efecto.",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE] = "Filtros de grabación",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT] = "Los filtros de zona y tipo de combate se combinan: un combate debe coincidir con al menos una zona Y un tipo para ser grabado.",

    -- Storage/History settings
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT] = "Límite del historial",
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT_TITLE] = "Límite del historial",
    -- Storage size preset labels (dropdown options)
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XS] = "Extra pequeño",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_SMALL] = "Pequeño",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_MEDIUM] = "Medio",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_LARGE] = "Grande",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XL] = "Extra grande",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_CAUTION] = "Ten cuidado",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_YOLO] = "¿Qué podría salir mal?",
    -- Storage tooltip
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC] = "Cuánto historial de combate guardar. Cuando se supera el límite, las zonas más antiguas no bloqueadas se eliminan automáticamente. Puedes bloquear zonas individuales para protegerlas de la limpieza.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE] = "Este límite se aplica solo al historial guardado. El addon también usa memoria para el combate actual y la interfaz, por lo que el uso total será mayor.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT] = "Historial: <<1>> MB de <<2>> MB (<<3>>%)",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS] = "Presets (prueba ~0.5-1 MB, mazmorra ~0.25-0.5 MB):",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XS] = "  Extra pequeño: 5 MB - unas pocas partidas recientes",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL] = "  Pequeño: 8 MB - una noche de prog",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM] = "  Medio: 12 MB - una semana de juego casual",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE] = "  Grande: 18 MB - un par de semanas",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XL] = "  Extra grande: 25 MB - un mes de recuerdos",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION] = "  Ten cuidado: 40 MB - te gustan mucho los datos",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO] = "  ¿Qué podría salir mal?: 60 MB - viviendo peligrosamente",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING] = "Sobre los límites de memoria de ESO: todos los addons comparten 100 MB. A 70 MB, ESO muestra una advertencia. A 100 MB, la interfaz se reinicia y todo se desactiva. Si usas muchos addons, elige un preset más pequeño. Consejo: escribe /addonmemdisplay en el chat para ver un monitor en tiempo real.",

    -------------------------
    -- Effect Tracking Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_EFFECT_TRACKING] = "Seguimiento de efectos",
    [BATTLESCROLLS_SETTINGS_PLAYER_BUFFS] = "Ventajas sobre ti",
    [BATTLESCROLLS_SETTINGS_PLAYER_DEBUFFS] = "Desventajas sobre ti",
    [BATTLESCROLLS_SETTINGS_GROUP_BUFFS] = "Ventajas sobre el grupo",
    [BATTLESCROLLS_SETTINGS_BOSS_DEBUFFS] = "Desventajas sobre el jefe",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION] = "Reconciliación",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION_TOOLTIP] = "Frecuencia de verificación del seguimiento de efectos. Mayor precisión captura más eventos perdidos pero usa más memoria. La memoria solo se libera al recargar la interfaz.",
    [BATTLESCROLLS_SETTINGS_RECON_MAX] = "Máximo",
    [BATTLESCROLLS_SETTINGS_RECON_HIGH] = "Alto",
    [BATTLESCROLLS_SETTINGS_RECON_NORMAL] = "Normal",
    [BATTLESCROLLS_SETTINGS_RECON_LOW] = "Bajo",
    [BATTLESCROLLS_SETTINGS_RECON_OFF] = "Desactivado",

    -------------------------
    -- Slider keybinds
    -------------------------
    [BATTLESCROLLS_SETTINGS_SLIDER_HOLD_FAST] = "Mantener para ir rápido",
    [BATTLESCROLLS_SETTINGS_SLIDER_RELEASE_PRECISION] = "Soltar para precisión",

    -------------------------
    -- Overview Stats
    -------------------------
    [BATTLESCROLLS_STAT_DURATION] = "Duración",
    [BATTLESCROLLS_STAT_PATCH] = "Parche",
    [BATTLESCROLLS_STAT_SUMMARY] = "Resumen",

    -- Boss Damage
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE] = "Daño personal al jefe",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DPS] = "DPS personal al jefe",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE_SHARE] = "Contribución daño al jefe",
    [BATTLESCROLLS_HEADER_BOSS_DAMAGE_DONE] = "Daño al jefe",

    -- Total Damage
    [BATTLESCROLLS_STAT_PERSONAL_DAMAGE] = "Daño personal",
    [BATTLESCROLLS_STAT_PERSONAL_DPS] = "DPS personal",
    [BATTLESCROLLS_STAT_PERSONAL_SHARE] = "Contribución personal",
    [BATTLESCROLLS_HEADER_TOTAL_DAMAGE_DONE] = "Daño total",

    -- Damage Taken
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN] = "Daño recibido total",
    [BATTLESCROLLS_STAT_DTPS] = "DTPS",
    [BATTLESCROLLS_HEADER_DAMAGE_TAKEN] = "Daño recibido",

    -- Healing Overview
    [BATTLESCROLLS_STAT_RAW_SELF_HEALING] = "Autocuración bruta",
    [BATTLESCROLLS_STAT_RAW_SELF_HPS] = "HPS de autocuración bruto",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HEALING] = "Autocuración efectiva",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HPS] = "HPS de autocuración efectivo",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT] = "Curación otorgada bruta",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT_HPS] = "HPS otorgado bruto",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT] = "Curación otorgada efectiva",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT_HPS] = "HPS otorgado efectivo",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN] = "Curación recibida bruta",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN_HPS] = "HPS recibido bruto",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN] = "Curación recibida efectiva",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN_HPS] = "HPS recibido efectivo",
    [BATTLESCROLLS_HEADER_HEALING] = "Curación",

    -- Proc Tracking
    [BATTLESCROLLS_HEADER_PROC_TRACKING] = "Seguimiento de procs",
    [BATTLESCROLLS_STAT_TOTAL_PROCS] = "<<1[$d proc/$d procs]>>",
    [BATTLESCROLLS_STAT_MEDIAN_INTERVAL] = "mediana",

    -------------------------
    -- Damage Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE] = "Daño total al jefe",
    [BATTLESCROLLS_STAT_BOSS_DPS] = "DPS al jefe",
    [BATTLESCROLLS_STAT_GROUP_SHARE] = "Contribución",
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE] = "Daño total",
    [BATTLESCROLLS_STAT_DPS] = "DPS",

    [BATTLESCROLLS_HEADER_BY_ABILITY] = "Por habilidad",
    [BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE] = "Por tipo de daño",
    [BATTLESCROLLS_HEADER_DIRECT_VS_DOT] = "Directo vs DoT",
    [BATTLESCROLLS_HEADER_AOE_VS_SINGLE] = "Área vs Objetivo único",
    [BATTLESCROLLS_HEADER_BY_TARGET] = "Por objetivo",
    [BATTLESCROLLS_HEADER_BY_SOURCE] = "Por fuente",

    [BATTLESCROLLS_STAT_DIRECT_DAMAGE] = "Daño directo",
    [BATTLESCROLLS_STAT_DAMAGE_OVER_TIME] = "Daño prolongado",
    [BATTLESCROLLS_STAT_AOE_DAMAGE] = "Área de efecto",
    [BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE] = "Objetivo único",

    -------------------------
    -- Healing Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_RAW_HEALING] = "Curación bruta",
    [BATTLESCROLLS_STAT_RAW_HPS] = "HPS bruto",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING] = "Curación efectiva",
    [BATTLESCROLLS_STAT_EFFECTIVE_HPS] = "HPS efectivo",
    [BATTLESCROLLS_STAT_OVERHEAL] = "Sobrecuración",

    [BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT] = "Bruto: HoT vs Directo",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT] = "Efectivo: HoT vs Directo",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET] = "Curación bruta por objetivo",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY] = "Curación bruta por habilidad",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET] = "Curación efectiva por objetivo",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY] = "Curación efectiva por habilidad",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE] = "Curación bruta por fuente",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE] = "Curación efectiva por fuente",

    [BATTLESCROLLS_STAT_DIRECT_HEALING] = "Curación directa",
    [BATTLESCROLLS_STAT_HEALING_OVER_TIME] = "Curación prolongada",

    -------------------------
    -- Effects Stats
    -------------------------
    [BATTLESCROLLS_HEADER_YOUR_BUFFS] = "Tus ventajas",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON_YOU] = "Desventajas sobre ti",
    [BATTLESCROLLS_HEADER_BUFFS_ON_GROUP] = "Ventajas sobre el grupo",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON] = "Desventajas sobre <<1>>",

    [BATTLESCROLLS_EFFECT_UPTIME] = "tiempo activo",
    [BATTLESCROLLS_EFFECT_YOURS] = "tuyo",
    [BATTLESCROLLS_EFFECT_AVG] = "prom",
    [BATTLESCROLLS_EFFECT_MEMBERS] = "<<1[$d miembro/$d miembros]>>",

    -------------------------
    -- Effect Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL_UPTIME] = "Tiempo activo total",
    [BATTLESCROLLS_TOOLTIP_TOTAL_APPLICATIONS] = "Aplicaciones totales",
    [BATTLESCROLLS_TOOLTIP_YOUR_CONTRIBUTION] = "Tu contribución",
    [BATTLESCROLLS_TOOLTIP_YOUR_UPTIME] = "Tiempo activo",
    [BATTLESCROLLS_TOOLTIP_YOUR_APPLICATIONS] = "Aplicaciones",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS] = "Acumulaciones máx",
    [BATTLESCROLLS_TOOLTIP_TIME_AT_MAX_STACKS] = "Tiempo en acumulaciones máx",
    [BATTLESCROLLS_TOOLTIP_YOUR_TIME_AT_MAX] = "Tu tiempo en máx",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_MEMBER] = "Tiempo activo prom. por miembro",
    [BATTLESCROLLS_TOOLTIP_MEMBERS_AFFECTED] = "Miembros afectados",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME] = "Tiempo activo promedio",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS_OBSERVED] = "Acumulaciones máx observadas",
    [BATTLESCROLLS_TOOLTIP_AVG_TIME_AT_MAX] = "Tiempo prom. en acumulaciones máx",
    [BATTLESCROLLS_TOOLTIP_YOUR_AVG_TIME_AT_MAX] = "Tu tiempo prom. en máx",
    [BATTLESCROLLS_TOOLTIP_PEAK_INSTANCES] = "Fuentes simultáneas máx",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_INSTANCE] = "Tiempo activo prom. por fuente",
    [BATTLESCROLLS_TOOLTIP_PER_MEMBER] = "Por miembro",
    [BATTLESCROLLS_TOOLTIP_YOU] = "Tú",

    -------------------------
    -- Ability Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL] = "Total",
    [BATTLESCROLLS_TOOLTIP_TYPE] = "Tipo",
    [BATTLESCROLLS_TOOLTIP_DELIVERY] = "Aplicación",
    [BATTLESCROLLS_TOOLTIP_CRIT] = "Crítico",
    [BATTLESCROLLS_TOOLTIP_AVG_TICK] = "Tick promedio",
    [BATTLESCROLLS_TOOLTIP_MIN_TICK] = "Tick mín",
    [BATTLESCROLLS_TOOLTIP_MAX_TICK] = "Tick máx",

    [BATTLESCROLLS_TOOLTIP_BY_TARGET] = "Por objetivo",
    [BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL] = "Intervalo promedio",
    [BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL] = "Intervalo mediano",

    [BATTLESCROLLS_TOOLTIP_ABILITY] = "Habilidad",

    -------------------------
    -- Damage Types
    -------------------------
    [BATTLESCROLLS_DAMAGE_TYPE_NONE] = "Ninguno",
    [BATTLESCROLLS_DAMAGE_TYPE_GENERIC] = "Genérico",
    [BATTLESCROLLS_DAMAGE_TYPE_PHYSICAL] = "Físico",
    [BATTLESCROLLS_DAMAGE_TYPE_FIRE] = "Fuego",
    [BATTLESCROLLS_DAMAGE_TYPE_SHOCK] = "Descarga",
    [BATTLESCROLLS_DAMAGE_TYPE_OBLIVION] = "Oblivion",
    [BATTLESCROLLS_DAMAGE_TYPE_FROST] = "Escarcha",
    [BATTLESCROLLS_DAMAGE_TYPE_EARTH] = "Tierra",
    [BATTLESCROLLS_DAMAGE_TYPE_MAGIC] = "Magia",
    [BATTLESCROLLS_DAMAGE_TYPE_DROWN] = "Ahogamiento",
    [BATTLESCROLLS_DAMAGE_TYPE_DISEASE] = "Enfermedad",
    [BATTLESCROLLS_DAMAGE_TYPE_POISON] = "Veneno",
    [BATTLESCROLLS_DAMAGE_TYPE_BLEED] = "Sangrado",

    -------------------------
    -- Over Time/Direct Descriptions
    -------------------------
    [BATTLESCROLLS_DELIVERY_MIXED] = "Mixto",
    [BATTLESCROLLS_DELIVERY_DOT] = "DoT",
    [BATTLESCROLLS_DELIVERY_DIRECT] = "Directo",
    [BATTLESCROLLS_DELIVERY_HOT] = "HoT",

    -------------------------
    -- Filter Dialog
    -------------------------
    [BATTLESCROLLS_FILTER_DAMAGE_DONE] = "Filtrar daño",
    [BATTLESCROLLS_FILTER_BOSS_DAMAGE] = "Filtrar daño al jefe",
    [BATTLESCROLLS_FILTER_BY_SOURCE] = "Filtrar por fuente",
    [BATTLESCROLLS_FILTER_BY_TARGET] = "Filtrar por objetivo",
    [BATTLESCROLLS_FILTER_BY_GROUP_MEMBER] = "Filtrar por miembro",
    [BATTLESCROLLS_FILTER] = "Filtro",
    [BATTLESCROLLS_FILTER_RESET] = "Restablecer",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_BY] = "Daño infligido por",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_TO] = "Daño infligido a",
    [BATTLESCROLLS_FILTER_BOSS_TARGET] = "Objetivo jefe",

    -------------------------
    -- Encounter Display
    -------------------------
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN_WITH] = "Combate <<l:1>> contra <<2>>",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_WITH] = "Combate contra <<1>>",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN] = "Combate <<l:1>>",
    [BATTLESCROLLS_ENCOUNTER_COMBAT] = "Combate",
    [BATTLESCROLLS_ENCOUNTER_INTO_INSTANCE] = "desde el inicio",
    [BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX] = "(Propio)",

    -------------------------
    -- List States
    -------------------------
    [BATTLESCROLLS_LIST_LOADING] = "Cargando",
    [BATTLESCROLLS_LIST_NO_DATA] = "Sin datos de combate grabados",
    [BATTLESCROLLS_LIST_NO_ENCOUNTERS] = "Sin combates",
    [BATTLESCROLLS_LIST_NO_STATS] = "Sin estadísticas disponibles",
    [BATTLESCROLLS_LIST_NO_SETTINGS] = "Sin ajustes disponibles",

    -------------------------
    -- LibHarvensAddonSettings Integration
    -------------------------
    [BATTLESCROLLS_LIBHARVENS_OPEN_BUTTON] = "Abrir Battle Scrolls",
    [BATTLESCROLLS_LIBHARVENS_TOOLTIP] = "Battle Scrolls también es accesible desde el menú <<1>>.",

    -------------------------
    -- Misc
    -------------------------
    [BATTLESCROLLS_UNKNOWN] = "Desconocido",
    [BATTLESCROLLS_UNKNOWN_BOSS] = "Jefe desconocido",

    -------------------------
    -- Personal Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_PERSONAL_DEFAULT] = "Predeterminado",
    [BATTLESCROLLS_DESIGN_PERSONAL_MINIMAL] = "Mínimo",
    [BATTLESCROLLS_DESIGN_PERSONAL_BAR] = "Barra",

    -- Bar design settings
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION] = "Dirección de barra",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_RIGHT] = "Derecha",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_LEFT] = "Izquierda",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_CENTER] = "Bidireccional",

    -------------------------
    -- Group Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_GROUP_TEXT] = "Texto",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR] = "Hodor",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR_DESC] = "Muy similar a Hodor Reflexes de @andy.s y @m00nyONE.",
    [BATTLESCROLLS_DESIGN_GROUP_BARS] = "Barras",
    [BATTLESCROLLS_DESIGN_GROUP_BARS_DESC] = "Vagamente inspirado en Hodor Restyle de Hyperioxes.",

    -- Text design settings
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS] = "Columnas",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TITLE] = "Disposición de columnas",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TEXT] = "Los grupos de 4 o menos siempre usan 1 columna.",

    -------------------------
    -- DPS Meter Display Strings
    -- Note: DPS/HPS are universal gaming terms, hardcoded in code
    -------------------------
    [BATTLESCROLLS_METER_EFFECTIVE] = "efectivo",
    [BATTLESCROLLS_METER_EFF] = "efec.",
    [BATTLESCROLLS_METER_BOSS] = "Jefe",
    [BATTLESCROLLS_METER_ALL] = "Total",
    [BATTLESCROLLS_METER_ALL_DAMAGE] = "Todo el daño",
    [BATTLESCROLLS_METER_TOTAL] = "Total",
    [BATTLESCROLLS_METER_BOSS_ALL_DAMAGE] = "Daño al jefe / Todo el daño",
    [BATTLESCROLLS_METER_EFFECTIVE_RAW_HEALING] = "Efectiva / Curación bruta",

    -- Overview Panel Q3/Q4 Headers
    [BATTLESCROLLS_OVERVIEW_TOP_ABILITIES] = "Mejores habilidades",
    [BATTLESCROLLS_OVERVIEW_BOSSES] = "Jefes",
    [BATTLESCROLLS_OVERVIEW_TARGETS] = "Objetivos",
    [BATTLESCROLLS_OVERVIEW_SOURCES] = "Fuentes",
    [BATTLESCROLLS_OVERVIEW_TARGETS_HEALED] = "Objetivos curados",
    [BATTLESCROLLS_OVERVIEW_HEALERS] = "Curadores",
    [BATTLESCROLLS_OVERVIEW_GROUP_BUFFS] = "Ventajas de grupo",
    [BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS] = "Desventajas del jefe",

    -- Group Stats
    [BATTLESCROLLS_OVERVIEW_BOSS_DAMAGE] = "Daño al jefe",
    [BATTLESCROLLS_STAT_GROUP_DAMAGE] = "Daño de grupo",
    [BATTLESCROLLS_STAT_GROUP_DPS] = "DPS de grupo",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE] = "Daño al jefe del grupo",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DPS] = "DPS al jefe del grupo",

    -- Overview Panel - Ability Stats
    [BATTLESCROLLS_STAT_MAX_PREFIX] = "Máx: <<1>>",
    [BATTLESCROLLS_STAT_CRIT_PERCENT] = "<<1>>% crít",
    [BATTLESCROLLS_STAT_PER_SECOND] = "<<1>>/s",

    -- Overview Panel - Effect Stats
    [BATTLESCROLLS_EFFECT_APPS_COUNT] = "<<1[$d aplicación/$d aplicaciones]>>",
    [BATTLESCROLLS_EFFECT_YOURS_PERCENT] = "<<1>>% tuyo",
    [BATTLESCROLLS_EFFECT_STACKS_COUNT] = "×<<1[$d acumulación/$d acumulaciones]>>",

    -- Overview Panel Summary
    [BATTLESCROLLS_OVERVIEW_ENCOUNTER] = "Encuentro",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT] = "Daño Realizado",
    [BATTLESCROLLS_OVERVIEW_SUMMARY] = "Resumen",
    [BATTLESCROLLS_OVERVIEW_TOTAL] = "Total",
    [BATTLESCROLLS_OVERVIEW_SHARE] = "Contribución",
    [BATTLESCROLLS_OVERVIEW_COMPOSITION] = "Composición",
    [BATTLESCROLLS_OVERVIEW_QUALITY] = "Calidad",
    [BATTLESCROLLS_OVERVIEW_CRIT_RATE] = "Tasa de crítico",
    [BATTLESCROLLS_OVERVIEW_MAX_HIT] = "Golpe máx",
    [BATTLESCROLLS_OVERVIEW_MAX_HEAL] = "Curación máx",
    [BATTLESCROLLS_OVERVIEW_KEY_BUFFS] = "Tus ventajas",
    [BATTLESCROLLS_OVERVIEW_NO_EFFECTS] = "Sin efectos registrados",

    -- Overview Panel Short Labels
    [BATTLESCROLLS_BOSS_DAMAGE] = "Daño al jefe",
    [BATTLESCROLLS_DAMAGE_DONE] = "Daño infligido",
    [BATTLESCROLLS_HEALING_OUT] = "Curación otorgada",
    [BATTLESCROLLS_SELF_HEALING] = "Autocuración",
    [BATTLESCROLLS_HEALING_IN] = "Curación recibida",
    [BATTLESCROLLS_AOE] = "Área",
    [BATTLESCROLLS_SINGLE_TARGET] = "Objetivo único",
    [BATTLESCROLLS_HEALING_RAW_HPS] = "HPS bruto",
    [BATTLESCROLLS_HEALING_EFFECTIVE_HPS] = "HPS efectivo",
    [BATTLESCROLLS_HEALING_OVERHEAL] = "Sobrecuración",
    [BATTLESCROLLS_TOOLTIP_DURATION] = "Duración",

    -------------------------
    -- LibAsync Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_PERFORMANCE] = "Rendimiento",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED] = "Velocidad de procesamiento",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_PERFORMANCE] = "Rendimiento",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_SMOOTH] = "Fluido",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM] = "Personalizado (<<1>> FPS)",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE] = "Velocidad de procesamiento",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "Controla la velocidad de procesamiento de tareas en segundo plano. Afecta principalmente la interfaz del Diario y el tiempo entre el fin del combate y la aparición del encuentro en la lista.\n\nRendimiento: Procesamiento más rápido. Puede causar breves tirones.\nFluido: Gameplay más fluido, procesamiento más lento. Puede causar que los encuentros se queden cargando o no aparezcan en el Diario.\n\nEsta configuración afecta a TODOS los addons que usan LibAsync.",

    -------------------------
    -- Onboarding
    -------------------------
    [BATTLESCROLLS_ONBOARDING_WELCOME_TITLE] = "Bienvenido a Battle Scrolls",
    [BATTLESCROLLS_ONBOARDING_WELCOME_TEXT] = "Battle Scrolls graba tus encuentros de combate y te permite revisarlos después en el Diario.\n\nCaracterísticas:\n- Medidores DPS/HPS en tiempo real\n- Desglose detallado de daño y curación\n- Seguimiento de tiempo activo de buffs/debuffs\n- Monitoreo de debuffs en jefes\n\nVamos a configurar algunas cosas.",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED] = "Empezar",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED_DESC] = "Guíame por las opciones de configuración",
    [BATTLESCROLLS_ONBOARDING_SKIP] = "Saltar",
    [BATTLESCROLLS_ONBOARDING_SKIP_DESC] = "Ya lo descubriré. Usar configuración recomendada.",
    [BATTLESCROLLS_ONBOARDING_METER_QUESTION] = "Elige tu estilo de medidor DPS:",
    -- Meter presets
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL] = "Mínimo",
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL_DESC] = "Medidor personal compacto en la esquina",
    [BATTLESCROLLS_PRESET_FULL_STACKED] = "Personal + Grupo",
    [BATTLESCROLLS_PRESET_FULL_STACKED_DESC] = "Medidor personal con clasificación de grupo debajo",
    [BATTLESCROLLS_PRESET_HODOR] = "Estilo Hodor",
    [BATTLESCROLLS_PRESET_HODOR_DESC] = "Solo medidor de grupo, muy similar a Hodor Reflexes (@andy.s, @m00nyONE)",
    [BATTLESCROLLS_PRESET_BAR] = "Barra de progreso",
    [BATTLESCROLLS_PRESET_BAR_DESC] = "Barra de progreso para DPS personal",
    [BATTLESCROLLS_PRESET_COLORFUL] = "Barras coloridas",
    [BATTLESCROLLS_PRESET_COLORFUL_DESC] = "Barras coloridas para DPS personal y de grupo, grupo vagamente inspirado en Hodor Restyle (Hyperioxes)",
    [BATTLESCROLLS_PRESET_DISABLED] = "Desactivado",
    [BATTLESCROLLS_PRESET_DISABLED_DESC] = "Sin medidores, solo grabación",
    -- Storage options
    [BATTLESCROLLS_ONBOARDING_STORAGE_QUESTION] = "¿Cuánto historial guardar?",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL] = "Mínimo (5 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC] = "Aproximadamente 6 pruebas",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE] = "Moderado (12 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC] = "Aproximadamente 16 pruebas",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS] = "Generoso (25 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC] = "Aproximadamente 36 pruebas",
    -- Effects tracking
    [BATTLESCROLLS_ONBOARDING_EFFECTS_QUESTION] = "¿Cuánto seguimiento de buff/debuff quieres?",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL] = "Seguimiento completo",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL_DESC] = "Tus buffs, debuffs de jefe Y tiempos de buffs de grupo (p.ej. tiempos de Coraje mayor en todos los miembros del grupo)",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL] = "Solo esencial",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL_DESC] = "Solo tus buffs y debuffs de jefe. Omite seguimiento de grupo para reducir el uso de memoria.",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED] = "Desactivado",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED_DESC] = "Sin seguimiento de buff/debuff. Menor uso de memoria, pero sin datos de tiempo activo en informes.",
    -- Completion
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TITLE] = "¡Todo listo!",
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TEXT] = "Battle Scrolls está listo para rastrear tu combate.\n\n¡Ahora ve a luchar!\n\nTus encuentros aparecerán aquí en el Diario. Puedes ajustar estos ajustes en cualquier momento desde la pestaña de Ajustes.",
    [BATTLESCROLLS_ONBOARDING_CHAT_MESSAGE] = "[Battle Scrolls] ¡Gracias por instalar! Abre Diario > Battle Scrolls para configurar y activar.",
    [BATTLESCROLLS_ONBOARDING_CONTINUE] = "Continuar",
    [BATTLESCROLLS_ONBOARDING_FINISH] = "Finalizar configuración",
    [BATTLESCROLLS_ONBOARDING_LETS_GO] = "¡Vamos!",
    [BATTLESCROLLS_ONBOARDING_STEP_FORMAT] = "Paso <<1>> de <<2>>",

    -------------------------
    -- Delete Functionality
    -------------------------
    [BATTLESCROLLS_DELETE] = "Eliminar",
    [BATTLESCROLLS_DELETE_INSTANCE_TITLE] = "Eliminar zona",
    [BATTLESCROLLS_DELETE_INSTANCE_TEXT] = "¿Eliminar <<1>> y todos sus combates?",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TITLE] = "Eliminar combate",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TEXT] = "¿Eliminar <<1>>?",
    [BATTLESCROLLS_DELETE_WARNING] = "Esta acción no se puede deshacer.",
    [BATTLESCROLLS_DELETE_MEMORY_FREE] = "Libera aproximadamente <<1>>",
    [BATTLESCROLLS_DELETE_MEMORY_STATUS] = "Memoria: <<1>> de <<2>> (<<3>>%)",

    -------------------------
    -- Dynamic Overview Panel
    -------------------------
    [BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN] = "Daño recibido",
    [BATTLESCROLLS_OVERVIEW_TOP_HEALING] = "Mejor curación",
    [BATTLESCROLLS_OVERVIEW_TOP_INCOMING] = "Mayor daño recibido",
    [BATTLESCROLLS_OVERVIEW_HEALING_TARGETS] = "Objetivos de curación",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES] = "Fuentes de daño",

    -------------------------
    -- Instance Locking
    -------------------------
    [BATTLESCROLLS_LOCK_ERROR_TITLE] = "No se puede bloquear",
    [BATTLESCROLLS_LOCK_ERROR_TEXT] = "Bloquear esta zona excedería tu límite de memoria. Las zonas bloqueadas y la más reciente están protegidas de la limpieza.\n\nPara liberar espacio, desbloquea o elimina algunas zonas bloqueadas, o aumenta tu límite de memoria en Configuración.",
    [BATTLESCROLLS_LOCK_LOCKED_SIZE] = "Actualmente bloqueado: <<1>>",
    [BATTLESCROLLS_LOCK_INSTANCE_SIZE] = "Esta zona: <<1>>",
    [BATTLESCROLLS_LOCK_LIMIT] = "Límite de memoria: <<1>>",

    -------------------------
    -- Favorite Effects
    -------------------------
    [BATTLESCROLLS_FAVORITE_EFFECT] = "Favorito",
    [BATTLESCROLLS_UNFAVORITE_EFFECT] = "Quitar favorito",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES] = "Borrar todos los favoritos",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES_TOOLTIP] = "Eliminar todos los efectos favoritos. Los efectos favoritos se muestran en la parte superior de cada lista de efectos.",

    -------------------------
    -- Group Tab Enhancements
    -------------------------
    [BATTLESCROLLS_STAT_SURVIVABILITY] = "Supervivencia",
    [BATTLESCROLLS_BOSS_DAMAGE_TAKEN] = "Daño recibido del jefe",

    -- Group Member Card Strings
    [BATTLESCROLLS_GROUP_CARD_OF_GROUP] = "del grupo",
    [BATTLESCROLLS_GROUP_CARD_ALIVE] = "Vivo",

    -- Group Tab Redesign
    [BATTLESCROLLS_GROUP_DAMAGE_BY_TYPE] = "Daño por tipo",
    [BATTLESCROLLS_GROUP_VS_AVERAGE] = "vs Media DD",
    [BATTLESCROLLS_GROUP_DD_COUNTED] = "DDs contados",
    [BATTLESCROLLS_GROUP_DAMAGE_OUTPUT] = "Daño realizado",
    [BATTLESCROLLS_GROUP_HEALING_OUTPUT] = "Curación realizada",
    [BATTLESCROLLS_GROUP_RANK] = "Rango",
    [BATTLESCROLLS_GROUP_MAGICAL] = "Mágico",
    [BATTLESCROLLS_GROUP_DEATH] = "Muerte",
    [BATTLESCROLLS_GROUP_FIRST_DEATH] = "Primera Muerte",
    [BATTLESCROLLS_GROUP_LAST_DEATH] = "Última Muerte",
    [BATTLESCROLLS_GROUP_DEATHS] = "Muertes",
    [BATTLESCROLLS_GROUP_COL_DEATHS] = "Muer\ntes",
    [BATTLESCROLLS_GROUP_DEATH_COUNT] = "<<1[$d Muerte/$d Muertes]>>",
    [BATTLESCROLLS_GROUP_METRIC_DPS] = "<<1>> DPS",
    [BATTLESCROLLS_GROUP_METRIC_HPS] = "<<1>> HPS",
    [BATTLESCROLLS_GROUP_METRIC_DTPS] = "<<1>> DTPS",
    [BATTLESCROLLS_GROUP_METRIC_CRIT] = "<<1>>% Crit",
    [BATTLESCROLLS_GROUP_METRIC_OVERHEAL] = "<<1>>% Sobrecuración",
    [BATTLESCROLLS_GROUP_TOP_INCOMING_DAMAGE] = "Top Daño Recibido",
    [BATTLESCROLLS_GROUP_DEATH_AT] = "a <<1>>",
    [BATTLESCROLLS_HEADER_DEATHS] = "Muertes",
    [BATTLESCROLLS_STAT_DEATH_COUNT] = "Número de Muertes",
    [BATTLESCROLLS_DEATH_N] = "Muerte <<1>>",

    -- Group Context Tooltips
    [BATTLESCROLLS_TOOLTIP_GROUP_TOTAL] = "Total del Grupo",
    [BATTLESCROLLS_TOOLTIP_GROUP_DPS] = "DPS del Grupo",
    [BATTLESCROLLS_TOOLTIP_GROUP_AVG] = "Media DD",
    [BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN] = "Desglose del Grupo",
    [BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_TAKEN] = "Daño Recibido del Grupo",

    -- Group Table
    [BATTLESCROLLS_GROUP_COL_NAME] = "Nombre",
    [BATTLESCROLLS_GROUP_COL_TOTAL] = "Total",
    [BATTLESCROLLS_GROUP_COL_CRIT] = "Crit",
    [BATTLESCROLLS_GROUP_COL_ALIVE] = "Vivo",

    -------------------------
    -- Setup Tab
    -------------------------
    [BATTLESCROLLS_TAB_BUILD] = "Arquetipo",
    [BATTLESCROLLS_SETUP_ABILITIES] = "Habilidades",
    [BATTLESCROLLS_SETUP_FRONT_BAR] = "Barra primaria",
    [BATTLESCROLLS_SETUP_BACK_BAR] = "Barra secundaria",
    [BATTLESCROLLS_SETUP_GEAR_SETS] = "Conjuntos de equipo",
    [BATTLESCROLLS_SETUP_EQUIPMENT] = "Equipo",
    [BATTLESCROLLS_SETUP_POISONS] = "Venenos",
    [BATTLESCROLLS_SETUP_CHARACTER] = "Personaje",
    [BATTLESCROLLS_SETUP_CLASS_SKILLS] = "Líneas de habilidades de clase",
    [BATTLESCROLLS_SETUP_MUNDUS] = "Mundus",
    [BATTLESCROLLS_SETUP_FOOD] = "Comida",
    [BATTLESCROLLS_WEAPON_GREATSWORD] = "Mandoble",
    [BATTLESCROLLS_WEAPON_BATTLE_AXE] = "Hacha de batalla",
    [BATTLESCROLLS_WEAPON_MAUL] = "Maza",

    -------------------------
    -- Food Buff Descriptions
    -------------------------
    [BATTLESCROLLS_FOOD_MAX_HEALTH] = "Salud máxima",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA] = "Magia máxima",
    [BATTLESCROLLS_FOOD_MAX_STAMINA] = "Aguante máximo",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_MAGICKA] = "Salud y magia máximas",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_STAMINA] = "Salud y aguante máximos",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA_STAMINA] = "Magia y aguante máximos",
    [BATTLESCROLLS_FOOD_MAX_TRISTAT] = "Salud, magia y aguante máximos",
    [BATTLESCROLLS_FOOD_HEALTH_RECOVERY] = "Recuperación de salud",
    [BATTLESCROLLS_FOOD_MAGICKA_RECOVERY] = "Recuperación de magia",
    [BATTLESCROLLS_FOOD_STAMINA_RECOVERY] = "Recuperación de aguante",
    [BATTLESCROLLS_FOOD_HEALTH_MAGICKA_RECOVERY] = "Recuperación de salud y magia",
    [BATTLESCROLLS_FOOD_HEALTH_STAMINA_RECOVERY] = "Recuperación de salud y aguante",
    [BATTLESCROLLS_FOOD_MAGICKA_STAMINA_RECOVERY] = "Recuperación de magia y aguante",
    [BATTLESCROLLS_FOOD_RECOVERY_TRISTAT] = "Recuperación de salud, magia y aguante",

    -------------------------
    -- Alchemy Traits
    -------------------------
    [BATTLESCROLLS_ALCHEMY_TRAIT1] = "Restauración de salud",
    [BATTLESCROLLS_ALCHEMY_TRAIT2] = "Reducción de salud",
    [BATTLESCROLLS_ALCHEMY_TRAIT3] = "Restauración de magia",
    [BATTLESCROLLS_ALCHEMY_TRAIT4] = "Reducción de magia",
    [BATTLESCROLLS_ALCHEMY_TRAIT5] = "Restauración de aguante",
    [BATTLESCROLLS_ALCHEMY_TRAIT6] = "Reducción de aguante",
    [BATTLESCROLLS_ALCHEMY_TRAIT7] = "Aumento de resistencia mágica",
    [BATTLESCROLLS_ALCHEMY_TRAIT8] = "Fisura",
    [BATTLESCROLLS_ALCHEMY_TRAIT9] = "Aumento de armadura",
    [BATTLESCROLLS_ALCHEMY_TRAIT10] = "Fractura",
    [BATTLESCROLLS_ALCHEMY_TRAIT11] = "Aumento de poder mágico",
    [BATTLESCROLLS_ALCHEMY_TRAIT12] = "Cobardía",
    [BATTLESCROLLS_ALCHEMY_TRAIT13] = "Aumento del poder físico",
    [BATTLESCROLLS_ALCHEMY_TRAIT14] = "Mutilación",
    [BATTLESCROLLS_ALCHEMY_TRAIT15] = "Crítico mágico",
    [BATTLESCROLLS_ALCHEMY_TRAIT16] = "Incertidumbre",
    [BATTLESCROLLS_ALCHEMY_TRAIT17] = "Crítico físico",
    [BATTLESCROLLS_ALCHEMY_TRAIT18] = "Debilitación",
    [BATTLESCROLLS_ALCHEMY_TRAIT19] = "Imparable",
    [BATTLESCROLLS_ALCHEMY_TRAIT20] = "Captura",
    [BATTLESCROLLS_ALCHEMY_TRAIT21] = "Detección",
    [BATTLESCROLLS_ALCHEMY_TRAIT22] = "Invisible",
    [BATTLESCROLLS_ALCHEMY_TRAIT23] = "Velocidad",
    [BATTLESCROLLS_ALCHEMY_TRAIT24] = "Impedimento",
    [BATTLESCROLLS_ALCHEMY_TRAIT25] = "Protección",
    [BATTLESCROLLS_ALCHEMY_TRAIT26] = "Vulnerabilidad",
    [BATTLESCROLLS_ALCHEMY_TRAIT27] = "Salud prolongada",
    [BATTLESCROLLS_ALCHEMY_TRAIT28] = "Reducción de salud insidiosa",
    [BATTLESCROLLS_ALCHEMY_TRAIT29] = "Vitalidad",
    [BATTLESCROLLS_ALCHEMY_TRAIT30] = "Profanación",
    [BATTLESCROLLS_ALCHEMY_TRAIT31] = "Heroísmo",
    [BATTLESCROLLS_ALCHEMY_TRAIT32] = "Timidez",

    -------------------------
    -- Aggregate
    -------------------------
    -- Navigation
    [BATTLESCROLLS_PIVOT_TITLE] = "Análisis",
    [BATTLESCROLLS_PIVOT_ENTRY] = "Análisis",
    [BATTLESCROLLS_PIVOT_ENTRY_DESC] = "Analiza datos de múltiples combates e instancias",
    [BATTLESCROLLS_PIVOT_ENTRY_DESC_ENCOUNTER] = "Analiza datos de los combates en esta instancia",

    -- Scope section
    [BATTLESCROLLS_PIVOT_SCOPE] = "Alcance",
    [BATTLESCROLLS_PIVOT_INSTANCE_SCOPE] = "Alcance de instancias",
    [BATTLESCROLLS_PIVOT_TIME_FILTER] = "Tiempo",
    [BATTLESCROLLS_PIVOT_ENCOUNTER_FILTER] = "Filtro de combate",

    -- Instance scope options
    [BATTLESCROLLS_PIVOT_SCOPE_EVERYTHING] = "Todo",
    [BATTLESCROLLS_PIVOT_SCOPE_INSTANCED] = "Todas las instancias",
    [BATTLESCROLLS_PIVOT_SCOPE_OVERLAND] = "Todo mundo abierto",
    [BATTLESCROLLS_PIVOT_SCOPE_HOUSES] = "Todas las casas",
    [BATTLESCROLLS_PIVOT_SCOPE_PVP] = "Todo JcJ",
    [BATTLESCROLLS_PIVOT_SCOPE_ZONES] = "Por nombre de zona",
    [BATTLESCROLLS_PIVOT_SCOPE_SPECIFIC] = "Instancias específicas",

    -- Time filter options
    [BATTLESCROLLS_PIVOT_TIME_ALL] = "Todo el tiempo",
    [BATTLESCROLLS_PIVOT_TIME_TODAY] = "Hoy",
    [BATTLESCROLLS_PIVOT_TIME_24H] = "Últimas 24 horas",
    [BATTLESCROLLS_PIVOT_TIME_3D] = "Últimos 3 días",
    [BATTLESCROLLS_PIVOT_TIME_7D] = "Últimos 7 días",
    [BATTLESCROLLS_PIVOT_TIME_14D] = "Últimos 14 días",
    [BATTLESCROLLS_PIVOT_TIME_30D] = "Últimos 30 días",
    [BATTLESCROLLS_PIVOT_TIME_90D] = "Últimos 90 días",
    [BATTLESCROLLS_PIVOT_TIME_CUSTOM] = "Personalizado...",

    -- Encounter category options
    [BATTLESCROLLS_PIVOT_ENC_ALL] = "Todos los combates",
    [BATTLESCROLLS_PIVOT_ENC_BOSS] = "Combates de jefe",
    [BATTLESCROLLS_PIVOT_ENC_TRASH] = "Combates de adds",
    [BATTLESCROLLS_PIVOT_ENC_PLAYER] = "Combates JcJ",
    [BATTLESCROLLS_PIVOT_ENC_DUMMY] = "Combates con muñeco",
    [BATTLESCROLLS_PIVOT_ENC_SPECIFIC] = "Combates específicos",

    -- Query section
    [BATTLESCROLLS_PIVOT_QUERY] = "Consulta",
    [BATTLESCROLLS_PIVOT_DOMAIN] = "Dominio",
    [BATTLESCROLLS_PIVOT_ROWS] = "Filas",
    [BATTLESCROLLS_PIVOT_COLUMNS] = "Columnas",
    [BATTLESCROLLS_PIVOT_VALUES] = "Valores",
    [BATTLESCROLLS_PIVOT_AGGREGATION] = "Agregación",
    [BATTLESCROLLS_PIVOT_FILTERS] = "Filtros",

    -- Target filter
    [BATTLESCROLLS_PIVOT_TARGETS] = "Objetivos",
    [BATTLESCROLLS_PIVOT_TARGETS_ALL] = "Todos los objetivos",
    [BATTLESCROLLS_PIVOT_TARGETS_BOSSES] = "Solo jefes",

    -- Domain names
    [BATTLESCROLLS_PIVOT_DOMAIN_DAMAGE] = "Daño",
    [BATTLESCROLLS_PIVOT_DOMAIN_HEALING_OUT] = "Curación otorgada",
    [BATTLESCROLLS_PIVOT_DOMAIN_HEALING_IN] = "Curación recibida",
    -- Effects domain labels reuse BATTLESCROLLS_TAB_EFFECTS_* strings
    [BATTLESCROLLS_PIVOT_DOMAIN_GROUP] = "Grupo",
    [BATTLESCROLLS_PIVOT_DOMAIN_OVERVIEW] = "Resumen",

    -- Dimension names
    [BATTLESCROLLS_PIVOT_DIM_ABILITY] = "Habilidad",
    [BATTLESCROLLS_PIVOT_DIM_TARGET] = "Objetivo",
    [BATTLESCROLLS_PIVOT_DIM_SOURCE] = "Fuente",
    [BATTLESCROLLS_PIVOT_DIM_BOSS] = "Jefe",
    [BATTLESCROLLS_PIVOT_DIM_DAMAGE_TYPE] = "Tipo de daño",
    [BATTLESCROLLS_PIVOT_DIM_DELIVERY] = "Aplicación",
    [BATTLESCROLLS_PIVOT_DIM_AOE_ST] = "AoE / Objetivo único",
    [BATTLESCROLLS_PIVOT_DIM_BUFF_DEBUFF] = "Buff / Debuff",
    [BATTLESCROLLS_PIVOT_DIM_GROUP_MEMBER] = "Miembro del grupo",
    [BATTLESCROLLS_PIVOT_DIM_ROLE] = "Rol",
    [BATTLESCROLLS_PIVOT_DIM_ENCOUNTER] = "Combate",
    [BATTLESCROLLS_PIVOT_DIM_INSTANCE] = "Instancia",
    [BATTLESCROLLS_PIVOT_COL_METRICS] = "Métricas",

    -- Metric names
    [BATTLESCROLLS_PIVOT_METRIC_TOTAL_DAMAGE] = "Daño total",
    [BATTLESCROLLS_PIVOT_METRIC_DPS] = "DPS",
    [BATTLESCROLLS_PIVOT_METRIC_CRIT_PERCENT] = "Crít %",
    [BATTLESCROLLS_PIVOT_METRIC_HIT_COUNT] = "Golpes",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_HIT] = "Golpe máx.",
    [BATTLESCROLLS_PIVOT_METRIC_MIN_HIT] = "Golpe mín.",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_HIT] = "Golpe prom.",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HEALING] = "Curación efectiva",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HEALING] = "Curación bruta",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS] = "HPS bruto",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS] = "HPS efectivo",
    [BATTLESCROLLS_PIVOT_METRIC_OVERHEAL_PERCENT] = "Sobrecuración %",
    [BATTLESCROLLS_PIVOT_METRIC_HEAL_CRIT_PERCENT] = "Crít curación %",
    [BATTLESCROLLS_PIVOT_METRIC_HEAL_HIT_COUNT] = "Golpes de curación",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_HEAL] = "Curación máx.",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_HEAL] = "Curación prom.",
    [BATTLESCROLLS_PIVOT_METRIC_UPTIME_PERCENT] = "Tiempo activo %",
    [BATTLESCROLLS_PIVOT_METRIC_PLAYER_UPTIME_PERCENT] = "Tu tiempo activo %",
    [BATTLESCROLLS_PIVOT_METRIC_APPLICATIONS] = "Aplicaciones",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_STACKS_TIME] = "Acumulaciones máx. %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DPS] = "DPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_BOSS_DPS] = "DPS al jefe",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_TOTAL_DAMAGE] = "Daño total",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_CRIT_PERCENT] = "Crít %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DOT_PERCENT] = "DoT %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_AOE_PERCENT] = "AoE %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_MAX_HIT] = "Golpe máx.",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DTPS] = "DTPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_RAW_HPS] = "HPS bruto",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_EFFECTIVE_HPS] = "HPS efectivo",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_OUT] = "HPS efectivo (sal.)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_OUT] = "HPS bruto (sal.)",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_IN] = "HPS efectivo (ent.)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_IN] = "HPS bruto (ent.)",
    [BATTLESCROLLS_PIVOT_METRIC_BOSS_DPS] = "DPS al jefe",
    [BATTLESCROLLS_PIVOT_METRIC_BOSS_DAMAGE] = "Daño al jefe",
    [BATTLESCROLLS_PIVOT_METRIC_DTPS] = "DTPS",
    [BATTLESCROLLS_PIVOT_METRIC_DAMAGE_TAKEN] = "Daño recibido",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_ALIVE_PERCENT] = "Vivo %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DEATH_COUNT] = "Muertes",
    [BATTLESCROLLS_PIVOT_METRIC_DURATION] = "Duración",
    [BATTLESCROLLS_PIVOT_METRIC_DEATH_COUNT] = "Muertes",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_WEAVE_TIME] = "Retraso medio",
    [BATTLESCROLLS_PIVOT_METRIC_TIME_LOST] = "Tiempo perdido",
    [BATTLESCROLLS_PIVOT_METRIC_LIGHT_ATTACKS_PER_SEC] = "LA/s",
    [BATTLESCROLLS_PIVOT_METRIC_WEAVING_ERRORS] = "LA perdidos",
    [BATTLESCROLLS_PIVOT_METRIC_DOUBLE_LA_ERRORS] = "LA dobles",

    -- Aggregation options
    [BATTLESCROLLS_PIVOT_AGG_SUM] = "Suma",
    [BATTLESCROLLS_PIVOT_AGG_AVG] = "Promedio",
    [BATTLESCROLLS_PIVOT_AGG_MAX] = "Máx",
    [BATTLESCROLLS_PIVOT_AGG_MIN] = "Mín",

    -- Actions
    [BATTLESCROLLS_PIVOT_RUN] = "Ejecutar consulta",
    [BATTLESCROLLS_PIVOT_SAVE] = "Guardar consulta",
    [BATTLESCROLLS_PIVOT_LOAD] = "Cargar consulta",
    [BATTLESCROLLS_PIVOT_DELETE_QUERY] = "Eliminar consulta",

    -- Loading / Results
    [BATTLESCROLLS_PIVOT_LOADING] = "Cargando combates... <<1>> / <<2>>",
    [BATTLESCROLLS_PIVOT_NO_RESULTS] = "No hay datos que coincidan con tu consulta",
    [BATTLESCROLLS_PIVOT_NO_ENCOUNTERS] = "Ningún combate coincide con tus filtros",
    [BATTLESCROLLS_PIVOT_NO_BOSSES] = "Ningún combate de jefe coincide con tus filtros",
    [BATTLESCROLLS_PIVOT_ENCOUNTERS_PROCESSED] = "<<1[$d combate procesado/$d combates procesados]>>",
    [BATTLESCROLLS_PIVOT_ROWS_CAPPED] = "Resultados limitados a <<1>> filas",
    [BATTLESCROLLS_PIVOT_COLUMNS_CAPPED] = "Resultados limitados a <<1>> columnas",
    [BATTLESCROLLS_PIVOT_TIP_DOMAIN_OVERVIEW] = "Resumen agregado de todos los dominios de daño, sanación y efectos. Muestra totales combinados en lugar de desgloses individuales.",
    [BATTLESCROLLS_PIVOT_TIP_ENC_BOSS_NAMES] = "Filtra a encuentros con los jefes seleccionados. Selecciona los nombres de jefe en el siguiente paso.",
    [BATTLESCROLLS_PIVOT_TIP_DIM_DELIVERY] = "Divide los datos por método de aplicación: Directo, DoT (daño con el tiempo), HoT (sanación con el tiempo) o Mixto.",
    [BATTLESCROLLS_PIVOT_TIP_DIM_DAMAGE_TYPE] = "Divide los datos por tipo de daño: Físico, Fuego, Descarga, Escarcha, Magia, Veneno, Enfermedad, Sangrado, Oblivion y otros.",
    [BATTLESCROLLS_PIVOT_TIP_DOMAIN_GROUP] = "Estadísticas de combate por miembro: DPS, daño total y tasa de crítico. Para tiempos de buffs/debuffs en miembros del grupo, usa Efectos de grupo.",
    [BATTLESCROLLS_PIVOT_TIP_AGGREGATION] = "Cómo se combinan los valores cuando múltiples encuentros contribuyen a la misma celda. Por ejemplo, DPS promedio muestra la media entre encuentros, mientras que Máx muestra el mejor encuentro.",

    -- Save dialog
    [BATTLESCROLLS_PIVOT_SAVE_TITLE] = "Guardar consulta",
    [BATTLESCROLLS_PIVOT_SAVE_PROMPT] = "Introduce un nombre para esta consulta:",
    [BATTLESCROLLS_PIVOT_SAVE_OVERWRITE] = "Ya existe una consulta llamada \"<<1>>\". ¿Sobrescribir?",

    -- Load/delete dialog
    [BATTLESCROLLS_PIVOT_QUERY_SAVED] = "Consulta guardada como \"<<1>>\"",
    [BATTLESCROLLS_PIVOT_LOAD_TITLE] = "Cargar consulta",
    [BATTLESCROLLS_PIVOT_DELETE_CONFIRM] = "¿Eliminar consulta \"<<1>>\"?",

    -- Selector dialogs
    [BATTLESCROLLS_PIVOT_SELECT_ZONES] = "Seleccionar zonas",
    [BATTLESCROLLS_PIVOT_SELECT_INSTANCES] = "Seleccionar instancias",
    [BATTLESCROLLS_PIVOT_SELECT_ENCOUNTERS] = "Seleccionar combates",
    [BATTLESCROLLS_PIVOT_SELECT_BOSSES] = "Seleccionar nombres de jefe",
    [BATTLESCROLLS_PIVOT_SELECT_METRICS] = "Seleccionar métricas",
    [BATTLESCROLLS_PIVOT_SELECTED_COUNT] = "<<1>> seleccionados",
    [BATTLESCROLLS_PIVOT_SELECT_ALL] = "Seleccionar todo",
    [BATTLESCROLLS_PIVOT_DESELECT_ALL] = "Deseleccionar todo",
    [BATTLESCROLLS_PIVOT_NONE_SELECTED] = "Ninguno seleccionado",

    -- Filter/range
    [BATTLESCROLLS_PIVOT_ENC_BOSS_NAMES] = "Por nombre de jefe",
    [BATTLESCROLLS_PIVOT_CUSTOM_DAYS] = "Últimos <<1>> días",
    [BATTLESCROLLS_PIVOT_CUSTOM_DAYS_PROMPT] = "Número de días atrás",
    [BATTLESCROLLS_PIVOT_CUSTOM_RANGE_TITLE] = "Rango de tiempo personalizado",

    -- Query description
    [BATTLESCROLLS_PIVOT_DESC_BY] = "<<1>> por <<2>>",
    [BATTLESCROLLS_PIVOT_DESC_CROSS] = "× <<1>>",
    [BATTLESCROLLS_PIVOT_DESC_N_METRICS] = "<<1[$d métrica/$d métricas]>>",
}

-- Register translations
for stringId, stringValue in pairs(strings) do
    SafeAddString(stringId, stringValue, 1)
end

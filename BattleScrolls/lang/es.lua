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
    [BATTLESCROLLS_STAT_SKILL_ACTIVATIONS] = "Habilidades lanzadas",
    [BATTLESCROLLS_STAT_CASTS] = "Lanzamientos",
    [BATTLESCROLLS_STAT_WEAVING_ERRORS] = "Errores de weaving",
    [BATTLESCROLLS_STAT_MISSED_LA] = "Ligeros perdidos",
    [BATTLESCROLLS_STAT_DOUBLE_LA] = "Ligeros dobles",
    [BATTLESCROLLS_TOOLTIP_DELAY_AFTER] = "Retraso tras lanzar",
    [BATTLESCROLLS_TOOLTIP_DELAY_BEFORE] = "Retraso antes de lanzar",
    [BATTLESCROLLS_FORMAT_SECONDS] = "<<1>>s",
    [BATTLESCROLLS_FORMAT_MILLISECONDS] = "<<1>>ms",
    [BATTLESCROLLS_TOOLTIP_INTER_CAST_DESC] = "Hueco medio entre lanzamientos, medido desde que acaba el tiempo de reutilización global o el tiempo de lanzamiento de una habilidad hasta tu siguiente acción. En Combat Metrics se llama Weaving Average.",
    [BATTLESCROLLS_TOOLTIP_TIME_LOST_DESC] = "La suma de los retrasos cortos de lanzamiento, sin pausas de 3 segundos o más (tiempo inactivo). En Combat Metrics se llama Weaving Total.",
    [BATTLESCROLLS_TOOLTIP_MISSED_LA_DESC] = "Habilidades lanzadas justo después de otra habilidad, sin un ataque ligero entre medias.",
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
    [BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT] = "Los miembros de tu grupo aún podrán ver tu DPS si tienen el complemento instalado.",
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
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE] = "Este límite se aplica solo a los datos guardados: combates, arquetipos y ajustes. El complemento también usa memoria para el combate actual y la interfaz, por lo que el uso total será mayor.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT] = "Historial: <<1>> MB de <<2>> MB (<<3>>%)",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PROTECTED] = "Solo los combates bloqueados, los arquetipos y los ajustes ya superan el límite: la limpieza no puede bajar de él.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS] = "Presets (prueba completa ~0.3 MB, mazmorra ~0.15 MB, una noche de prog ~1 MB):",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XS] = "  Extra pequeño: 5 MB - solo los pergaminos más recientes",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL] = "  Pequeño: 8 MB - una buena pila de pergaminos",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM] = "  Medio: 12 MB - un diario bien llevado",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE] = "  Grande: 18 MB - una biblioteca personal",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XL] = "  Extra grande: 25 MB - un gran archivo",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION] = "  Ten cuidado: 35 MB - te gustan mucho los datos",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO] = "  ¿Qué podría salir mal?: 50 MB - tú te lo has buscado",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING] = "Sobre los límites de memoria de ESO: todos los complementos comparten 100 MB. A 70 MB, ESO muestra una advertencia. A 100 MB, la interfaz se reinicia y todo se desactiva. Si usas muchos complementos, elige un preset más pequeño. Consejo: escribe /addonmemdisplay en el chat para ver un monitor en tiempo real.",

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

    -------------------------
    -- Damage Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE] = "Daño total al jefe",
    [BATTLESCROLLS_STAT_BOSS_DPS] = "DPS al jefe",
    [BATTLESCROLLS_STAT_GROUP_SHARE] = "Contribución",
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE] = "Daño total",
    [BATTLESCROLLS_STAT_DPS] = "DPS",

    [BATTLESCROLLS_HEADER_BY_ABILITY] = "Por habilidad",

    [BATTLESCROLLS_HEADER_CASTS] = "Lanzamientos",
    [BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE] = "Por tipo de daño",
    [BATTLESCROLLS_HEADER_DIRECT_VS_DOT] = "Directo vs DoT",
    [BATTLESCROLLS_HEADER_DAMAGE_DELIVERY] = "Aplicación de daño",
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

    [BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT] = "Curación bruta por tipo",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT] = "Curación efectiva por tipo",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET] = "Curación bruta por objetivo",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY] = "Curación bruta por habilidad",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET] = "Curación efectiva por objetivo",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY] = "Curación efectiva por habilidad",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE] = "Curación bruta por fuente",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE] = "Curación efectiva por fuente",

    [BATTLESCROLLS_STAT_DIRECT_HEALING] = "Curación directa",
    [BATTLESCROLLS_STAT_HEALING_OVER_TIME] = "Curación prolongada",
    [BATTLESCROLLS_STAT_SHIELD_HEALING] = "Escudos de daño",
    [BATTLESCROLLS_STAT_REGEN_HEALING] = "Recuperación de salud",
    [BATTLESCROLLS_DAMAGE_UNKNOWN_SHIELDED] = "Desconocido (Escudado)",
    [BATTLESCROLLS_HEALING_UNKNOWN_ABSORBED] = "Desconocido (Absorbido)",
    [BATTLESCROLLS_HEALING_HEALTH_RECOVERY] = "Recuperación de salud",

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
    [BATTLESCROLLS_TOOLTIP_TICKS] = "Ticks",

    [BATTLESCROLLS_TOOLTIP_BY_TARGET] = "Por objetivo",
    [BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL] = "Intervalo promedio",
    [BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL] = "Intervalo mediano",

    [BATTLESCROLLS_TOOLTIP_ABILITY] = "Habilidad",
    [BATTLESCROLLS_TOOLTIP_ABILITY_ID] = "ID de habilidad",

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
    [BATTLESCROLLS_DELIVERY_SHIELD] = "Escudo",
    [BATTLESCROLLS_DELIVERY_REGEN] = "Regeneración",
    [BATTLESCROLLS_DELIVERY_HEAL_ABSORPTION] = "Absorción de curación",

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
    [BATTLESCROLLS_LIBHARVENS_OPEN_BUTTON] = "Abrir Pergaminos de Batalla",
    [BATTLESCROLLS_LIBHARVENS_TOOLTIP] = "También puedes abrir Pergaminos de Batalla desde el menú <<1>>.",

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
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "Controla la velocidad de procesamiento de tareas en segundo plano. Afecta principalmente la interfaz del Diario y el tiempo entre el fin del combate y la aparición del encuentro en la lista.\n\nRendimiento: Procesamiento más rápido. Puede causar breves tirones.\nFluido: Gameplay más fluido, procesamiento más lento. Puede causar que los encuentros se queden cargando o no aparezcan en el Diario.\n\nEsta configuración afecta a TODOS los complementos que usan LibAsync.",

    -------------------------
    -- Onboarding
    -------------------------
    [BATTLESCROLLS_ONBOARDING_WELCOME_TITLE] = "Bienvenido a Pergaminos de Batalla",
    [BATTLESCROLLS_ONBOARDING_WELCOME_TEXT] = "Con Pergaminos de Batalla puedes registrar tus combates y revisarlos después en el Diario.\n\nCaracterísticas:\n- Medidores DPS/HPS en tiempo real\n- Desglose detallado de daño y curación\n- Seguimiento de tiempo activo de buffs/debuffs\n- Monitoreo de debuffs en jefes\n\nVamos a configurar algunas cosas.",
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
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC] = "Aproximadamente 15 pruebas",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE] = "Moderado (12 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC] = "Aproximadamente 40 pruebas",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS] = "Generoso (25 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC] = "Aproximadamente 80 pruebas",
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
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TEXT] = "Todo listo para registrar tus combates con Pergaminos de Batalla.\n\n¡Ahora ve a luchar!\n\nTus encuentros aparecerán aquí en el Diario. Puedes ajustar estos ajustes en cualquier momento desde la pestaña de Ajustes.",
    [BATTLESCROLLS_ONBOARDING_CHAT_MESSAGE] = "[Pergaminos de Batalla] ¡Gracias por instalar! Abre Diario > Pergaminos de Batalla para configurar y activar.",
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
    [BATTLESCROLLS_SETUP_CLASS_MASTERY] = "Maestría de clase",
    [BATTLESCROLLS_SETUP_LOADOUT] = "Configuración",
    [BATTLESCROLLS_SETUP_PERKS] = "Ventajas",
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
    [BATTLESCROLLS_PIVOT_TIP_DIM_DELIVERY] = "Divide los datos por método de aplicación: Directo, DoT (daño con el tiempo), Absorción de curación, HoT (sanación con el tiempo), Regeneración, Escudo o Mixto.",
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

-- v17 storage migration
local migrationStrings = {
    [BATTLESCROLLS_MIGRATION_START] = "Actualización única de almacenamiento en curso - puede haber tirones durante unos minutos",
    [BATTLESCROLLS_MIGRATION_DONE] = "¡Actualización de almacenamiento completada! <<1>> combates recodificados, <<2>> MB liberados",
    [BATTLESCROLLS_MIGRATION_TIP] = "Ya puedes bajar el preset de memoria en los ajustes; el nuevo formato guarda mucho más historial en cada MB.",
}
for stringId, stringValue in pairs(migrationStrings) do
    SafeAddString(stringId, stringValue, 1)
end

-- Online sharing
local shareStrings = {
    [BATTLESCROLLS_SETTINGS_SHARE_PART_SIZE] = "Tamaño de las partes al compartir",
    [BATTLESCROLLS_SETTINGS_SHARE_PART_SIZE_TEXT] = "Cuántos caracteres de datos de combate se envían cada vez que se abre el navegador. Las partes más pequeñas pueden ayudar si el navegador no se abre al confirmar. Las más grandes requieren menos confirmaciones, pero pueden impedir que se abra. Valor predeterminado: 7000. Para usar otro tamaño, cancela el envío actual y vuelve a compartir.",
    [BATTLESCROLLS_SHARE_FIGHT] = "Compartir combate",
    [BATTLESCROLLS_SHARE_INSTANCE] = "Subir todos los combates",
    [BATTLESCROLLS_SHARE_PREPARING] = "Preparando el enlace...",
    [BATTLESCROLLS_SHARE_TITLE] = "Compartir",
    [BATTLESCROLLS_SHARE_PROGRESS_HEADER] = "Partes",
    [BATTLESCROLLS_SHARE_PART_SENT] = "Parte <<1>> — enviada",
    [BATTLESCROLLS_SHARE_PART_READY] = "Parte <<1>> — lista para enviar",
    [BATTLESCROLLS_SHARE_PART_PENDING] = "Parte <<1>>",
    [BATTLESCROLLS_SHARE_SEND_PART] = "Enviar parte <<1>> de <<2>>",
    [BATTLESCROLLS_SHARE_HINT_HEADER] = "Cómo funciona",
    [BATTLESCROLLS_SHARE_PRIVACY_TITLE] = "Los nombres y datos de combate se guardarán en línea",
    [BATTLESCROLLS_SHARE_PRIVACY_NOTICE] = "La subida incluye tu nombre y los de otros jugadores, plataforma, servidor, estadísticas de combate y configuraciones. Los informes no caducan automáticamente y cualquiera con el enlace puede verlos o descargarlos. Informa a los jugadores afectados antes de compartir. Privacidad y solicitudes de eliminación: <<1>>",
    [BATTLESCROLLS_SHARE_TT_READY] = "Confirma el aviso del juego: la página del navegador que se abre envía esta parte de los datos de combate al sitio, y después puedes cerrar el navegador. Vuelve al juego y envía la siguiente parte; el progreso se conserva aunque salgas de esta pantalla. Cuando lleguen todas las partes, la página mostrará tu enlace no listado y un código QR.",
    [BATTLESCROLLS_SHARE_TT_SENT] = "Esta parte ya se entregó al navegador. Si la página del navegador indica que falta (una pestaña que se cierra inesperadamente pierde su parte), selecciona esta fila y pulsa la tecla de reenvío.",
    [BATTLESCROLLS_SHARE_TT_PENDING] = "Las partes se envían una a una, en orden: esta se desbloqueará cuando le toque.",
    [BATTLESCROLLS_SHARE_TT_DONE] = "La página del navegador muestra ahora el enlace no listado y el código QR: solo quien tenga el enlace puede abrirlo. Si la página indica partes que faltan, selecciónalas arriba y reenvíalas. «Terminar el envío» descarta la subida en el juego.",
    [BATTLESCROLLS_SHARE_CHOICE_HEADER] = "Qué enviar",
    [BATTLESCROLLS_SHARE_CHOICE_FULL] = "Todos los combates (<<1>>)",
    [BATTLESCROLLS_SHARE_CHOICE_BOSSES] = "Solo jefes (<<1>>)",
    [BATTLESCROLLS_SHARE_CHOICE_PARTS] = "Partes a enviar: <<1>>",
    [BATTLESCROLLS_SHARE_TT_CHOICE_FULL] = "Todos los combates registrados de esta instancia, incluida la morralla. Más datos: más partes que enviar por el navegador.",
    [BATTLESCROLLS_SHARE_TT_CHOICE_BOSSES] = "Solo los combates contra jefes. La morralla suele ocupar la mayor parte del tamaño, así que habrá bastantes menos partes.",
    [BATTLESCROLLS_SHARE_DONE_HEADER] = "Todas las partes enviadas",
    [BATTLESCROLLS_SHARE_DONE_HINT] = "El enlace y el código QR están en la página del navegador.",
    [BATTLESCROLLS_SHARE_CONTINUE] = "Seguir compartiendo",
    [BATTLESCROLLS_SHARE_CANCEL] = "Cancelar envío",
    [BATTLESCROLLS_SHARE_FAILED] = "No se pudo preparar el enlace.",
    [BATTLESCROLLS_SHARE_RESEND_PART] = "Reenviar parte <<1>>",
    [BATTLESCROLLS_SHARE_PART_RESENDING] = "Parte <<1>> — reenviando…",
    [BATTLESCROLLS_SHARE_FINISH] = "Terminar de compartir",
}
for id, str in pairs(shareStrings) do
    SafeAddString(id, str, 1)
end

-- Nuevas funciones: renombrar, daño de banda, resurrecciones, color de barra, habilidad máxima, Crux, Z'en
local featureStrings = {
    [BATTLESCROLLS_RENAME] = "Renombrar",
    [BATTLESCROLLS_RENAME_TEXT] = "Introduce un nombre nuevo. Introduce el nombre original (<<1>>) para restablecerlo.",

    [BATTLESCROLLS_TAB_GROUP_DAMAGE] = "Daño del grupo",
    [BATTLESCROLLS_FILTER_GROUP_DAMAGE] = "Filtrar daño del grupo",
    [BATTLESCROLLS_FILTER_OTHERS] = "Otros",
    [BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_SCOPE] = "Todo el daño que ha registrado tu cliente del juego: el tuyo, incluidas mascotas y compañeros, y el de otros jugadores cercanos. ESO no identifica a esos otros jugadores, por lo que su daño se agrupa en «Otros».",

    [BATTLESCROLLS_GROUP_COL_RES] = "Res",

    [BATTLESCROLLS_SETTINGS_BAR_COLOR] = "Color de tu barra",
    [BATTLESCROLLS_SETTINGS_BAR_COLOR_TEXT] = "Los miembros del grupo que usan Pergaminos de Batalla con el diseño «Barras» ven tu barra de este color, aunque uses otro diseño o desactives tu propio medidor de grupo.",
    [BATTLESCROLLS_COLOR_DEFAULT] = "Predeterminado",
    [BATTLESCROLLS_COLOR_WHEEL] = "Tono y saturación",
    [BATTLESCROLLS_COLOR_BRIGHTNESS] = "Brillo",
    [BATTLESCROLLS_COLOR_HEX] = "Código hex",
    [BATTLESCROLLS_COLOR_HEX_INVALID] = "Introduce seis dígitos hex, por ejemplo #3EB6FF.",
    [BATTLESCROLLS_COLOR_SAVE] = "Guardar",
    [BATTLESCROLLS_COLOR_SAVE_HINT] = "Tu barra tendrá este color en Pergaminos de Batalla para quienes usen «Barras», sea cual sea tu diseño.",

    [BATTLESCROLLS_HEADER_ULTIMATE] = "Habilidad máxima",
    [BATTLESCROLLS_STAT_ULT_AT_ENTRY] = "Máxima al entrar en combate",
    [BATTLESCROLLS_STAT_ULT_GENERATED] = "Máxima generada",
    [BATTLESCROLLS_STAT_ULT_SPENT_DRAINED] = "Máxima gastada y drenada",
    [BATTLESCROLLS_STAT_ULT_SPENT] = "Máxima gastada",
    [BATTLESCROLLS_STAT_ULT_LOST] = "Perdida al lanzar",
    [BATTLESCROLLS_STAT_ULT_LOST_TT] = "Lanzar una habilidad máxima vacía toda la reserva, así que se pierde todo lo que supere su coste.",
    [BATTLESCROLLS_STAT_ULT_DRAINED] = "Máxima drenada",
    [BATTLESCROLLS_HEADER_ULT_SOURCES] = "Generación de máxima por fuente",
    [BATTLESCROLLS_ULT_BASE_GENERATION] = "Generación base",
    [BATTLESCROLLS_ULT_HEROISM_LINE] = "Incluye <<C:1>>: <<2>>% de tiempo activo, aprox. <<3>>",
    [BATTLESCROLLS_HEADER_ULT_CASTS] = "Máximas usadas",

    [BATTLESCROLLS_HEADER_CRUX] = "Crux",
    [BATTLESCROLLS_STAT_CRUX_GENERATORS] = "Lanzamientos generadores",
    [BATTLESCROLLS_STAT_CRUX_AT_FULL] = "Lanzados con Crux lleno",
    [BATTLESCROLLS_STAT_CRUX_SPENDERS] = "Lanzamientos consumidores",
    [BATTLESCROLLS_STAT_CRUX_UNDER] = "Lanzados con menos de 3 Crux",
    [BATTLESCROLLS_CRUX_AT_N] = "Con <<1>> Crux: <<2>>",
    [BATTLESCROLLS_HEADER_CRUX_BY_ABILITY] = "Uso de Crux por habilidad",

    [BATTLESCROLLS_HEADER_ZEN] = "Acumulación de DoT (Z'en)",
    [BATTLESCROLLS_ZEN_AVG_DOTS] = "DoTs medios",
    [BATTLESCROLLS_ZEN_UPTIME] = "Tu tiempo activo de Z'en",
    [BATTLESCROLLS_ZEN_PEAK_TIME] = "Tiempo en <<1>>",
    [BATTLESCROLLS_ZEN_DOTS_LABEL] = "<<1>> DoTs",
    [BATTLESCROLLS_ZEN_SHARE_LINE] = "media <<1>> — <<2>> con 5 DoTs",
    [BATTLESCROLLS_ZEN_SHORT] = "Z'en",
    [BATTLESCROLLS_ZEN_NOTE] = "Tus DoTs se registran aunque no lleves Z'en. Muestran la bonificación que podrías aportar si tu perjuicio de Z'en estuviera activo. El tiempo sin tu Z'en solo representa ese potencial.",
    [BATTLESCROLLS_ZEN_DISTRIBUTION_NOTE] = "Cada fila de DoTs muestra su proporción del tiempo registrado. El porcentaje de Z'en indica durante qué parte del tiempo de esa fila estuvo activo tu propio perjuicio.",

    [BATTLESCROLLS_HEADER_SUPPORT] = "Apoyo",
    [BATTLESCROLLS_STAT_RESURRECTIONS] = "Resurrecciones",
}
for id, str in pairs(featureStrings) do
    SafeAddString(id, str, 1)
end

local cruxPassiveStrings = {
    [BATTLESCROLLS_STAT_CRUX_PASSIVE] = "Perdidos fuera de lanzamientos",
    [BATTLESCROLLS_STAT_CRUX_PASSIVE_TT] = "Crux que se desvanecieron solos, sin ningún lanzamiento consumidor ni muerte cerca. Los Crux caducan a los 30 segundos.",
    [BATTLESCROLLS_STAT_CRUX_DEATH] = "Perdidos por muerte",
    [BATTLESCROLLS_STAT_CRUX_PROC_WASTED] = "Ganancias pasivas con Crux lleno",
    [BATTLESCROLLS_STAT_CRUX_PROC_WASTED_TT] = "Ganancias pasivas que se activaron cuando ya tenías 3 Crux, así que no dieron nada. «<<1>>» y sus variantes y <<2>> solo dan Crux cuando no tienes ninguno, por eso nunca se cuentan aquí.",
    [BATTLESCROLLS_STAT_CRUX_CONDITIONAL_TT] = "Crux que esta fuente generó de forma pasiva, sin ningún lanzamiento.",
    [BATTLESCROLLS_STAT_CRUX_OTHER] = "Otras ganancias de crux",
    [BATTLESCROLLS_STAT_CRUX_OTHER_TT] = "Crux obtenidos sin que ninguna fuente registrada aquí se activara en ese momento.",
    [BATTLESCROLLS_HEADER_CRUX_GAINED] = "Crux obtenidos por habilidad",
}
for id, str in pairs(cruxPassiveStrings) do
    SafeAddString(id, str, 1)
end

local activityOverviewStrings = {
    [BATTLESCROLLS_STAT_DOWNTIME] = "Tiempo inactivo",
    [BATTLESCROLLS_TOOLTIP_DOWNTIME_DESC] = "Huecos de 3 segundos o más entre lanzamientos, por ejemplo mecánicas, resucitar o estar muerto. No cuentan en el retraso de lanzamiento.",
    [BATTLESCROLLS_STAT_PER_MINUTE] = "<<1>>/min",
    [BATTLESCROLLS_DETAIL_MEDIAN] = "mediana <<1>>",
    [BATTLESCROLLS_DETAIL_DELAY] = "<<1>> de retraso",
    [BATTLESCROLLS_DETAIL_AT_FULL] = "<<1>> al máximo",
    [BATTLESCROLLS_DETAIL_LOST] = "<<1>> perdidos",
    [BATTLESCROLLS_DETAIL_AVG_DOTS] = "media <<1>> DoTs",
    [BATTLESCROLLS_DETAIL_AT_DOTS] = "<<1>> con <<2>>",
}
for id, str in pairs(activityOverviewStrings) do
    SafeAddString(id, str, 1)
end

-- Release history
SafeAddString(BATTLESCROLLS_WHATS_NEW, "Novedades", 1)
SafeAddString(BATTLESCROLLS_WHATS_NEW_DESC, "Consulta los cambios de Pergaminos de Batalla, desde la última actualización hasta el primer lanzamiento público.", 1)

SafeAddString(BATTLESCROLLS_RELEASE_6_0_1, [=[
|cD4AF37Correcciones:|r

- Los historiales de los distintos servidores se combinaron automáticamente al iniciar sesión y ahora se muestran juntos en el Diario. El historial de otros servidores siempre ha ocupado memoria y espacio de almacenamiento, incluso cuando no aparecía en el Diario.

- El límite de almacenamiento y los ajustes se comparten entre servidores. Se conservó el mayor de tus límites anteriores; los demás ajustes se tomaron del primer servidor en el que iniciaste sesión tras actualizar. Se conservan los favoritos, las consultas guardadas de Análisis, los recorridos bloqueados, los nombres personalizados y los arquetipos personales guardados.

- La limpieza automática ahora tiene en cuenta los recorridos de todos los servidores en conjunto.

- Al compartir en PlayStation, ahora se envían partes más pequeñas para ayudar con los combates que no se abrían en el navegador. Los combates más grandes pueden requerir más pasos; puedes experimentar con el Tamaño de las partes al compartir en Ajustes.
]=], 1)

SafeAddString(BATTLESCROLLS_RELEASE_6_0_0, [=[
|cD4AF37Nuevas funciones:|r

- |cD4AF37¡Tus pergaminos ya pueden salir de Tamriel!|r Comparte un combate o una sesión completa desde el diario y abre el enlace en el navegador. Escanea el código QR de tu televisor para obtener el enlace en el móvil. Desde ahí, explora el combate o compártelo donde quieras

- Explora los mismos datos de combate y de |cFFFFFFarquetipo|r que en el complemento, con exportación a |cFFFFFFCSV y JSON|r para tus propios análisis

- |cFFFFFFActividad|r registra la generación y el gasto de puntos de habilidad máxima, el uso de |cFFFFFFCrux|r del arcanista, la acumulación de efectos de daño prolongado para Z'en y las resurrecciones. El número de DoTs muestra la bonificación potencial de Z'en, incluso sin llevar el conjunto. Las estadísticas de weaving distinguen los pequeños retrasos entre lanzamientos del tiempo inactivo prolongado

- Los resúmenes de tus muertes ahora muestran los |cFFFFFFnombres de los atacantes|r cuando están disponibles

- |cFFFFFFDaño del grupo|r muestra todo el daño observado por tu cliente, incluso de jugadores sin Pergaminos de Batalla. ESO no identifica esas otras fuentes, por lo que se agrupan en «|cFFFFFFOtros|r»

- Elige el |cFFFFFFcolor de tu barra|r en el medidor Barras de todos los miembros del grupo y cambia el nombre de las sesiones y combates del historial

- El diario tiene una sección |cFFFFFFNovedades|r con fechas y notas de versiones en los siete idiomas. Por si se te escapó algún pergamino

|cD4AF37Cambios importantes:|r

- El nuevo almacenamiento permite guardar muchos |cFFFFFFmás combates|r en el mismo espacio. El nuevo formato también debería reducir los |cFFFFFFtirones|r tras combates grandes y permitir abrirlos |cFFFFFFmucho más rápido|r en el diario. El historial existente se convierte |cFFFFFFautomáticamente|r en segundo plano tras iniciar sesión; puede haber pequeños tirones durante este proceso único. Cada combate se compara con el original antes de sustituirlo

|cD4AF37Correcciones:|r

- Los combates deberían |cFFFFFFterminar antes de tiempo con mucha menos frecuencia|r al morir mientras el grupo sigue luchando, especialmente en el último combate de la Ciudadela Luciente

- Corregidos cálculos de |cFFFFFFcuración|r que ignoraban filtros, venenos ausentes en los arquetipos de otros miembros del grupo y varios casos de intercambio de datos y limpieza del historial

- Resúmenes de combate y arquetipos del grupo |cFFFFFFmás fiables|r, con menos datos ausentes tras cruzar puertas o pasar por pantallas de carga

|cE6B566Problemas conocidos:|r

- Puede ser necesario recargar la interfaz para que el indicador de |cFFFFFFmemoria|r de ESO refleje el espacio liberado por la conversión

- Con los |cFFFFFFcambios de alquimia de la actualización 51|r, los nombres de los efectos de los venenos en los arquetipos pueden faltar o ser incorrectos. Los efectos de los venenos creados no se muestran en el visor web

- La función de compartir en la web no se ha probado en |cFFFFFFPlayStation|r. Por favor, informa de cualquier problema, incluso si no te funciona en absoluto]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_3_1, [=[|cD4AF37Correcciones:|r

- La |cFFFFFFmaestría de clase|r y las líneas de habilidades de otros jugadores se muestran correctamente al consultar sus arquetipos en la pestaña |cFFFFFFGrupo|r]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_3_0, [=[|cD4AF37Nuevas funciones:|r

- Compatibilidad con pasivas de |cFFFFFFmaestría de clase|r: sustituyen la lista de líneas de habilidades cuando se ha comprado al menos una

- Compatibilidad con |cFFFFFFVengeance|r: el |cFFFFFFresumen|r del arquetipo muestra la configuración y las ventajas elegidas, y oculta los datos que no se aplican a este modo

|cD4AF37Cambios menores:|r

- En inglés, los enemigos comunes pasan de «trash» a «basepop», siguiendo la terminología de los desarrolladores]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_2_0, [=[|cD4AF37Nuevas funciones:|r

- La |cFFFFFFrecuperación de salud|r se registra como una categoría de |cFFFFFFcuración|r. La cantidad bruta se estima con tu recuperación en combate; la efectiva y la sobrecuración, con los cambios reales de salud

- La |cFFFFFFabsorción de curación|r aplicada al jugador cuenta como un tipo de daño recibido

- El daño saliente y entrante absorbido por |cFFFFFFescudos|r cuenta en los totales y DPS/DTPS, pero no en los desgloses por habilidad o tipo

- La |cFFFFFFcuración|r absorbida se incluye en los totales de |cFFFFFFcuración|r a otros, autocuración y curación recibida, así como en sus HPS

|cD4AF37Cambios menores:|r

- Las listas detalladas muestran siempre hasta 50 habilidades y 20 objetivos/fuentes, frente a los anteriores 25/15/10 según el contexto

|cD4AF37Correcciones:|r

- Las agregaciones de |cFFFFFFcuración|r saliente por modalidad incluyen la autocuración, como las demás vistas

|cE6B566Problemas conocidos:|r

- La |cFFFFFFcuración|r bruta de la |cFFFFFFrecuperación de salud|r se estima a partir del tiempo con vida, porque ESO no indica el momento exacto de cada pulso. Si estás perdiendo salud a la vez, puede que parte de la curación efectiva no se detecte]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_1_0, [=[|cD4AF37Nuevas funciones:|r

- Los |cFFFFFFescudos|r aplicados a ti y a tu grupo se registran como |cFFFFFFcuración|r: su aplicación cuenta como curación bruta y el daño que absorben como efectiva

- Los |cFFFFFFescudos|r tienen su propia categoría junto a |cFFFFFFcuración|r directa y prolongada en pestañas, resúmenes y agregaciones de curación saliente

|cE6B566Problemas conocidos:|r

- Si se aplican varios |cFFFFFFescudos|r al mismo objetivo en menos de 50 ms, algún pulso puede atribuirse a la habilidad equivocada

|cD4AF37Cambios menores:|r

- Las descripciones muestran el ID real de habilidad de ESO en daño, |cFFFFFFcuración|r, efectos, activaciones, |cFFFFFFweaving|r y arquetipo

- Corregidos iconos erróneos o genéricos de Forjador del destino pragmático, Gloria radiante, Flagelo del Cefaliarca, pociones, Absorción de esencia, Autoridad intrépida, las sinergias Purificar y Festín de sangre, Protección rúnica de aguas calmadas, Luz purificadora, Conjuro experto y el rasgo Armonía

- Hace falta más HPS para llenar la barra del medidor personal

- La composición pasa a llamarse «Curación por tipo» y oculta desgloses de una sola categoría que no aportan información

|cD4AF37Correcciones:|r

- Se reducen los casos en los que el |cFFFFFFweaving|r detectaba por error ataques ligeros omitidos o dobles

- Mejor identificación de jefes sin seguimiento de efectos

- La |cFFFFFFcuración|r media por pulso ya no aparece por debajo del mínimo en algunas descripciones]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_0_0, [=[|cD4AF37Nuevas funciones:|r

- ¡Seguimiento del |cFFFFFFweaving|r! Tiempo medio y total perdido entre lanzamientos, ataques ligeros y habilidades omitidos, en conjunto y por habilidad

- Nueva pestaña |cFFFFFFActividad|r para estos datos

- Datos de |cFFFFFFweaving|r disponibles en agregaciones con el dominio Resumen

|cD4AF37Cambios menores:|r

- Las activaciones pasan de Resumen a |cFFFFFFActividad|r. ¿Te habías dado cuenta de que estaban ahí?

- Mejor rendimiento y uso de |cFFFFFFmemoria|r dentro y fuera del combate, especialmente con el seguimiento de efectos desactivado total o parcialmente

|cD4AF37Correcciones:|r

- El grupo muestra el porcentaje real de tiempo con vida al desactivar los efectos, en lugar de un 100% fijo]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_4_0_0, [=[|cD4AF37Nuevas funciones:|r

- ¿Has pensado alguna vez que a tu MMORPG de fantasía le faltaban |cFFFFFFhojas de cálculo|r? Probablemente no, pero aquí están. Agrega los datos que quieras de cualquier cantidad de combates, con |cFFFFFFtablas dinámicas|r

|cD4AF37Cambios menores:|r

- Cada combate muestra la versión del juego, por ejemplo 11.3.5

- Los demás te ven leyendo un pergamino mientras usas Pergaminos de Batalla. ¿Qué otra cosa iba a ser?

- El nombre de la zona encabeza la lista de combates

|cD4AF37Correcciones:|r

- El encantamiento prismático de reducción de coste se muestra correctamente en los arquetipos del grupo

- Los arquetipos se presentan de la misma forma en las pestañas |cFFFFFFGrupo|r y Arquetipo]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_1_0, [=[|cD4AF37Nuevas funciones:|r

- |cFFFFFFBúsqueda|r en |cFFFFFFEfectos|r, similar a la del inventario

|cD4AF37Correcciones:|r

- Al consultar el |cFFFFFFarquetipo|r de otros miembros del grupo que juegan como arcanistas, ya no falta la línea de raza, clase y piedra de Mundus

- Menos |cFFFFFFparpadeos|r en el menú de grupo, otra vez]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_0_2, "|cFFFFFFReduce los parpadeos del menú de grupo|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_0_1, [=[|cD4AF37Correcciones:|r

- Los |cFFFFFFpuntos de campeón|r del grupo no se asignan a constelaciones incorrectas cuando hay espacios vacíos. Es un arreglo del emisor: tu compañero también debe actualizar

- Al pasar de un jugador con |cFFFFFFarquetipo|r a otro sin él, ya no se intenta mostrar información inexistente]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_0_0, [=[|cD4AF37Registro de arquetipos|r

- Cada combate guarda tu |cFFFFFFarquetipo|r y lo muestra en una nueva pestaña, para recordar exactamente qué llevabas

- El |cFFFFFFresumen|r también muestra buena parte de él, para presumir de tus resultados más fácilmente

- El menú de |cFFFFFFpersonaje|r incluye un |cFFFFFFresumen|r rápido del arquetipo

- |cFFFFFFGrupo|r registra los arquetipos de otros miembros del grupo que usan Pergaminos de Batalla]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_1_2, "|cFFFFFFSin cambios visibles; preparación para la versión 3|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_1_1, "|cFFFFFFCálculos de daño de área y a un objetivo adaptados al caballero dragón actualizado. El cambio es retroactivo.|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_1_0, [=[- Nueva navegación por |cFFFFFFsubcategorías|r: las vistas relacionadas comparten pestaña y se cambian con izquierda/derecha de la cruceta o del stick izquierdo
  - Daño causado y daño a jefes pasan a ser |cFFFFFFsubcategorías|r de Daño
  - Curación a otros, propia y recibida se agrupan en Curación
  - |cFFFFFFEfectos|r sobre ti, jefes y grupo tienen |cFFFFFFsubcategorías|r independientes en vez de una lista larga

- Se ocultan los errores «Attempt to read past end of buffer». Tras una pantalla de carga al terminar el combate los datos de grupo pueden seguir siendo incorrectos, pero al menos el error no te salta a la cara]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_0_1, [=[|cD4AF37Diario del grupo|r

Nueva pestaña para combates con compañeros que tienen Pergaminos de Batalla.

|cD4AF37Resumen:|r

- Tabla ordenable: cada jefe, DPS, críticos, DTPS, HPS, tiempo con vida y muertes

|cD4AF37Por jugador:|r

- Daño: DPS, total, críticos, golpe máximo, directo, área, tipos de daño, puesto por DPS y comparación con la media de los DD

- Supervivencia: DTPS, tiempo con vida, muertes, principales habilidades recibidas y recapitulaciones de muerte

- Curación: HPS bruto y efectivo, sobrecuración y autocuración

- Barras por jefe con composición del daño y daño recibido

|cD4AF37Contexto del grupo en las descripciones existentes cuando hay datos:|r

- Objetivos jefe: DPS y contribución de cada miembro; filas de DPS y DPS a jefes: desglose por miembro

- DTPS y fuentes de daño recibido: DTPS por miembro

- Composición del daño: comparación con la media de los DD

- HPS bruto y sobrecuración en |cFFFFFFcuración|r saliente y propia: desglose por miembro

|cD4AF37Muertes:|r

- Las recapitulaciones se guardan con el combate

- Resumen: recuento en daño recibido

- Daño recibido: marcas de tiempo y detalles en la descripción

- |cFFFFFFGrupo|r: primera y última muerte con todas las habilidades

|cD4AF37Cambios menores:|r

- El |cFFFFFFresumen|r muestra daño directo en lugar de periódico

- Nueva opción para grabar todos los combates del |cFFFFFFMercado Nocturno|r, independientemente de los filtros de zona habituales

- Los medidores DPS se sitúan detrás de otros elementos, como el historial de botín

- Resumen se selecciona por defecto en todas las pestañas. Usa algo más de |cFFFFFFmemoria|r, pero no la querías libre, ¿verdad?

- Nombres sin @

- Los medidores Hodor y Barras muestran la duración del combate en la cabecera

- Nuevos sonidos para diálogos de filtros y zonas

|cD4AF37Localización:|r

- Corregidos plurales

- En ruso y alemán, el término para las acumulaciones coincide ahora con el de las descripciones de los conjuntos de equipo]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_6, "|cFFFFFFCorrige un error de interfaz al entrar sin LibGroupBroadcast|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_5, "|cFFFFFFLibGroupBroadcast pasa a ser opcional temporalmente para sortear el apocalipsis de complementos en consola|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_4, "|cFFFFFFSin cambios visibles; preparando la consulta del DPS del grupo en el diario|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_3, "|cFFFFFFSin cambios visibles; preparando la consulta del DPS del grupo en el diario|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_2, [=[|cD4AF37Correcciones:|r

- Ya no intenta enviar datos DPS al grupo cuando no estás en uno. Gracias a DakJaniels]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_1, [=[|cD4AF37Correcciones:|r

- Detección de jefes más fiable en el último combate de la Ciudadela Luciente y al alejarse del jefe, por ejemplo para entrar en portales

- Ya no debería aparecer «|cFFFFFF1000ms limit hit|r» tras combates complejos, como el último de la Ciudadela Luciente o el primero de la Jaula de Oseína]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_0, [=[|cD4AF37Nuevas funciones:|r

- Marca efectos como |cFFFFFFfavoritos|r para fijarlos arriba en todas sus listas

|cD4AF37Correcciones:|r

- La duración de efectos de quienes se incorporan a mitad del combate usa solo el tiempo que estuvieron presentes

- Eliminados elementos vacíos que aparecían arriba a la izquierda al entrar en combate por primera vez con ciertos medidores de grupo

|cD4AF37Cambios menores:|r

- La fila de DPS total aparece aunque solo haya una persona en la sección de DD]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_2_0, [=[|cD4AF37Nuevas funciones:|r

- Bloquea zonas con |cFFFFFFX/cuadrado|r en la lista para protegerlas de la limpieza automática al superar el límite. La zona más reciente también está siempre protegida

|cD4AF37Localización:|r

- Terminología de zonas más coherente en alemán y ruso

|cD4AF37Correcciones:|r

- El modo Fluido ya no queda atascado cargando ni impide añadir combates al diario. Tras actualizar, sus usuarios vuelven al modo Rendimiento predeterminado]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_1_0, [=[|cD4AF37Nuevas funciones:|r

- Elimina zonas y combates individuales del historial

|cD4AF37Correcciones:|r

- Corregida la carga infinita o ausencia del menú al combinar el modo Fluido del complemento con el modo gráfico Fidelidad. Quienes ya estuvieran afectados quizá necesiten otro |cFFFFFF/reloadui|r tras actualizar

- Los diálogos del juego, como destruir objetos, ya no fallan después de usar filtros

- Corregida la animación inversa al salir de Pergaminos de Batalla al diario]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_3, "|cFFFFFFUn intento a ciegas de corregir los datos guardados corruptos en PS5|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_2, [=[|cD4AF37Mejoras de almacenamiento y efectos|r

|cD4AF37Almacenamiento:|r

- Codificación y descodificación optimizadas para cargar el diario más rápido

- Menor consumo de |cFFFFFFmemoria|r al procesar combates

|cD4AF37Efectos:|r

- Duraciones corregidas cuando miembros del grupo se desconectan durante el combate

- Mejor gestión de quienes se reconectan a mitad del combate]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_1, "|cFFFFFFUna corrección|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_0, [=[|cD4AF37Primer lanzamiento público|r

|cD4AF37Medidor DPS:|r

- Daño en tiempo real

- Diseños personales: predeterminado, mínimo y barra

- Diseños de grupo: texto, estilo Hodor y barras

- Posición, escala y persistencia tras el combate configurables

|cD4AF37Diario:|r

- Zona -> combate -> estadísticas

- Filtros por tipo de zona y combate

- Límites de almacenamiento configurables

|cD4AF37Daño:|r

- Desglose por objetivo y habilidad

- Daño directo y periódico, críticos

- Daño de área y a un objetivo

|cD4AF37Curación:|r

- Causada y recibida, por fuente y objetivo

|cD4AF37Efectos:|r

- Duración de beneficios y perjuicios del jugador y grupo, perjuicios en jefes y activaciones

DPS compartido mediante |cFFFFFFLibGroupBroadcast|r

|cD4AF37Idiomas:|r inglés, alemán, francés, español, ruso, japonés y chino]=], 1)

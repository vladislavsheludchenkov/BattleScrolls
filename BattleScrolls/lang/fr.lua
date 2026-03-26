-- Battle Scrolls Localization - French (Français)
-- Translations use ESO's official French terminology

local strings = {
    -------------------------
    -- Core UI Labels
    -------------------------
    [BATTLESCROLLS_UI_NAME] = "Parchemins de Bataille",
    [BATTLESCROLLS_UI_SETTINGS] = "Paramètres",
    [BATTLESCROLLS_UI_FILTER] = "Filtre",
    [BATTLESCROLLS_UI_FILTER_ACTIVE] = "Filtre (Actif)",
    [BATTLESCROLLS_UI_SWITCH_TO] = "Passer à <<1>>",
    [BATTLESCROLLS_STAT_HPS] = "HPS",

    -------------------------
    -- Zone/Instance Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ZONES] = "Toutes les zones",
    [BATTLESCROLLS_TAB_INSTANCED] = "Instances",
    [BATTLESCROLLS_TAB_OVERLAND] = "Extérieur",
    [BATTLESCROLLS_TAB_HOUSES] = "Maisons",
    [BATTLESCROLLS_TAB_PVP] = "JcJ",

    -------------------------
    -- Encounter Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ENCOUNTERS] = "Tous les combats",
    [BATTLESCROLLS_TAB_BOSS_ENCOUNTERS] = "Combats de boss",
    [BATTLESCROLLS_TAB_OTHER_ENCOUNTERS] = "Autres combats",
    [BATTLESCROLLS_TAB_PLAYER_ENCOUNTERS] = "Combats JcJ",
    [BATTLESCROLLS_TAB_TARGET_DUMMY] = "Mannequin d'entraînement",

    -------------------------
    -- Stats Tabs
    -------------------------
    [BATTLESCROLLS_TAB_OVERVIEW] = "Aperçu",
    [BATTLESCROLLS_TAB_BOSS_DAMAGE_DONE] = "Dégâts aux boss",
    [BATTLESCROLLS_TAB_DAMAGE_DONE] = "Dégâts infligés",
    [BATTLESCROLLS_TAB_DAMAGE_TAKEN] = "Dégâts subis",
    [BATTLESCROLLS_TAB_HEALING_OUT] = "Soins prodigués",
    [BATTLESCROLLS_TAB_SELF_HEALING] = "Auto-soins",
    [BATTLESCROLLS_TAB_HEALING_IN] = "Soins reçus",
    [BATTLESCROLLS_TAB_DAMAGE] = "Dégâts",
    [BATTLESCROLLS_TAB_HEALING] = "Soins",
    [BATTLESCROLLS_TAB_EFFECTS] = "Effets",
    [BATTLESCROLLS_TAB_EFFECTS_PLAYER] = "Vos effets",
    [BATTLESCROLLS_TAB_EFFECTS_BOSS] = "Effets de boss",
    [BATTLESCROLLS_TAB_EFFECTS_GROUP] = "Effets du groupe",
    [BATTLESCROLLS_TAB_GROUP] = "Groupe",

    -------------------------
    -- Time Headers
    -------------------------
    [BATTLESCROLLS_TIME_TODAY] = "Aujourd'hui",
    [BATTLESCROLLS_TIME_YESTERDAY] = "Hier",

    -------------------------
    -- DPS Meter Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_DPS_METER] = "Compteur DPS",
    [BATTLESCROLLS_SETTINGS_KEEP_AFTER_COMBAT] = "Garder après combat",
    [BATTLESCROLLS_SETTINGS_HIDE_IMMEDIATELY] = "Masquer immédiatement",
    [BATTLESCROLLS_SETTINGS_10_SECONDS] = "10 secondes",
    [BATTLESCROLLS_SETTINGS_30_SECONDS] = "30 secondes",
    [BATTLESCROLLS_SETTINGS_2_MINUTES] = "2 minutes",
    [BATTLESCROLLS_SETTINGS_5_MINUTES] = "5 minutes",
    [BATTLESCROLLS_SETTINGS_UNTIL_RELOAD] = "Jusqu'au rechargement",

    [BATTLESCROLLS_SETTINGS_PERSONAL_METER] = "Compteur personnel",
    [BATTLESCROLLS_SETTINGS_GROUP_METER] = "Compteur de groupe",
    [BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT] = "Les membres de votre groupe pourront toujours voir vos DPS s'ils ont l'addon installé.",
    [BATTLESCROLLS_SETTINGS_ENABLED] = "Activé",
    [BATTLESCROLLS_SETTINGS_MODE] = "Mode",
    [BATTLESCROLLS_SETTINGS_DESIGN] = "Design",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_LEFT] = "Distance depuis la gauche",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_TOP] = "Distance depuis le haut",
    [BATTLESCROLLS_SETTINGS_SIZE] = "Taille",
    [BATTLESCROLLS_SETTINGS_RESET_POSITION] = "Réinitialiser la position",
    [BATTLESCROLLS_SETTINGS_POSITION] = "Position",

    -- Meter modes
    [BATTLESCROLLS_SETTINGS_MODE_AUTO] = "Auto",
    [BATTLESCROLLS_SETTINGS_MODE_DAMAGE] = "Dégâts",
    [BATTLESCROLLS_SETTINGS_MODE_HEALING] = "Soins",

    -- Meter size options
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_SMALL] = "Très petit",
    [BATTLESCROLLS_SETTINGS_SIZE_SMALL] = "Petit",
    [BATTLESCROLLS_SETTINGS_SIZE_MEDIUM] = "Moyen",
    [BATTLESCROLLS_SETTINGS_SIZE_LARGE] = "Grand",
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_LARGE] = "Très grand",

    -- Meter position options
    [BATTLESCROLLS_SETTINGS_POSITION_BELOW] = "Sous le personnel",
    [BATTLESCROLLS_SETTINGS_POSITION_ABOVE] = "Au-dessus du personnel",
    [BATTLESCROLLS_SETTINGS_POSITION_SEPARATE] = "Séparé",

    -- Auto mode tooltip
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TITLE] = "Mode automatique",
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TEXT] = "Affiche la valeur la plus élevée - DPS ou HPS.",

    -- Group tracker tooltips
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA] = "Afficher sans données de groupe",
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA_TEXT] = "Lorsqu'activé, le compteur de groupe s'affiche même si aucun autre membre ne partage ses données DPS. Vous ne verrez que vos propres statistiques.",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_DESIGN] = "Design du compteur de groupe",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION] = "Position du compteur de groupe",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION_TEXT] = "Dessous/Dessus: Attache le compteur de groupe à votre compteur personnel.\nSéparé: Place le compteur de groupe indépendamment avec un positionnement personnalisé.",

    -------------------------
    -- Recording Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_RECORDING] = "Enregistrement",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED] = "Enregistrer en instance",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED_TEXT] = "Les zones instanciées comprennent les Donjons, Épreuves, Arènes et l'Archive Infinie.",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_OVERLAND] = "Enregistrer en extérieur",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_HOUSES] = "Enregistrer dans les maisons",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_PVP] = "Enregistrer en JcJ",
    [BATTLESCROLLS_SETTINGS_RECORD_BOSS_FIGHTS] = "Enregistrer les combats de boss",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS] = "Enregistrer les combats d'adds",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS_TEXT] = "Combats contre des ennemis normaux (pas de boss, pas de joueurs).",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS] = "Enregistrer les combats JcJ",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS_TEXT] = "Combats JcJ contre d'autres joueurs.",
    [BATTLESCROLLS_SETTINGS_RECORD_DUMMY_FIGHTS] = "Enregistrer les combats de mannequin",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_ADVENTURE_ZONE_TEXT] = "Lorsqu'activé, remplace les réglages Extérieur et Instances et enregistre tous les combats dans cette zone. Lorsque désactivé, n'a aucun effet.",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE] = "Filtres d'enregistrement",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT] = "Les filtres de zone et de type de combat sont combinés: un combat doit correspondre à au moins une zone ET un type pour être enregistré.",

    -- Storage/History settings
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT] = "Limite de l'historique",
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT_TITLE] = "Limite de l'historique",
    -- Storage size preset labels (dropdown options)
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XS] = "Très petit",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_SMALL] = "Petit",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_MEDIUM] = "Moyen",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_LARGE] = "Grand",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XL] = "Très grand",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_CAUTION] = "Attention",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_YOLO] = "Qu'est-ce qui pourrait mal tourner?",
    -- Storage tooltip
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC] = "Combien d'historique de combat garder. Quand la limite est atteinte, les zones les plus anciennes non verrouillées sont automatiquement supprimées. Vous pouvez verrouiller des zones individuelles pour les protéger du nettoyage.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE] = "Cette limite s'applique uniquement à l'historique sauvegardé. L'addon utilise aussi de la mémoire pour le combat en cours et l'interface, donc l'utilisation totale sera plus élevée.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT] = "Historique: <<1>> Mo sur <<2>> Mo (<<3>>%)",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS] = "Préréglages (épreuve ~0,5-1 Mo, donjon ~0,25-0,5 Mo):",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XS] = "  Très petit: 5 Mo - quelques runs récents",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL] = "  Petit: 8 Mo - une soirée de prog",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM] = "  Moyen: 12 Mo - une semaine de jeu décontracté",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE] = "  Grand: 18 Mo - quelques semaines",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XL] = "  Très grand: 25 Mo - un mois de souvenirs",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION] = "  Attention: 40 Mo - vous aimez vraiment les données",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO] = "  Qu'est-ce qui pourrait mal tourner?: 60 Mo - vivre dangereusement",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING] = "À propos des limites de mémoire ESO: tous les addons partagent 100 Mo. À 70 Mo, ESO affiche un avertissement. À 100 Mo, l'interface redémarre et tout est désactivé. Si vous utilisez beaucoup d'addons, choisissez un préréglage plus petit. Astuce: tapez /addonmemdisplay dans le chat pour voir un suivi en temps réel.",

    -------------------------
    -- Effect Tracking Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_EFFECT_TRACKING] = "Suivi des effets",
    [BATTLESCROLLS_SETTINGS_PLAYER_BUFFS] = "Bonus sur vous",
    [BATTLESCROLLS_SETTINGS_PLAYER_DEBUFFS] = "Malus sur vous",
    [BATTLESCROLLS_SETTINGS_GROUP_BUFFS] = "Bonus sur le groupe",
    [BATTLESCROLLS_SETTINGS_BOSS_DEBUFFS] = "Malus sur le boss",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION] = "Réconciliation",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION_TOOLTIP] = "Fréquence de vérification du suivi des effets. Une précision plus élevée capture plus d'événements manqués mais utilise plus de mémoire. La mémoire n'est libérée qu'au rechargement de l'UI.",
    [BATTLESCROLLS_SETTINGS_RECON_MAX] = "Maximum",
    [BATTLESCROLLS_SETTINGS_RECON_HIGH] = "Élevé",
    [BATTLESCROLLS_SETTINGS_RECON_NORMAL] = "Normal",
    [BATTLESCROLLS_SETTINGS_RECON_LOW] = "Faible",
    [BATTLESCROLLS_SETTINGS_RECON_OFF] = "Désactivé",

    -------------------------
    -- Slider keybinds
    -------------------------
    [BATTLESCROLLS_SETTINGS_SLIDER_HOLD_FAST] = "Maintenir pour aller vite",
    [BATTLESCROLLS_SETTINGS_SLIDER_RELEASE_PRECISION] = "Relâcher pour précision",

    -------------------------
    -- Overview Stats
    -------------------------
    [BATTLESCROLLS_STAT_DURATION] = "Durée",
    [BATTLESCROLLS_STAT_SUMMARY] = "Résumé",

    -- Boss Damage
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE] = "Dégâts boss personnels",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DPS] = "DPS boss personnel",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE_SHARE] = "Part dégâts boss",
    [BATTLESCROLLS_HEADER_BOSS_DAMAGE_DONE] = "Dégâts aux boss",

    -- Total Damage
    [BATTLESCROLLS_STAT_PERSONAL_DAMAGE] = "Dégâts personnels",
    [BATTLESCROLLS_STAT_PERSONAL_DPS] = "DPS personnel",
    [BATTLESCROLLS_STAT_PERSONAL_SHARE] = "Part personnelle",
    [BATTLESCROLLS_HEADER_TOTAL_DAMAGE_DONE] = "Dégâts totaux",

    -- Damage Taken
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN] = "Dégâts subis totaux",
    [BATTLESCROLLS_STAT_DTPS] = "DTPS",
    [BATTLESCROLLS_HEADER_DAMAGE_TAKEN] = "Dégâts subis",

    -- Healing Overview
    [BATTLESCROLLS_STAT_RAW_SELF_HEALING] = "Auto-soins bruts",
    [BATTLESCROLLS_STAT_RAW_SELF_HPS] = "HPS d'auto-soins brut",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HEALING] = "Auto-soins effectifs",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HPS] = "HPS d'auto-soins effectif",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT] = "Soins prodigués bruts",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT_HPS] = "HPS prodigué brut",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT] = "Soins prodigués effectifs",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT_HPS] = "HPS prodigué effectif",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN] = "Soins reçus bruts",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN_HPS] = "HPS reçu brut",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN] = "Soins reçus effectifs",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN_HPS] = "HPS reçu effectif",
    [BATTLESCROLLS_HEADER_HEALING] = "Soins",

    -- Proc Tracking
    [BATTLESCROLLS_HEADER_PROC_TRACKING] = "Suivi des procs",
    [BATTLESCROLLS_STAT_TOTAL_PROCS] = "<<1[$d proc/$d procs]>>",
    [BATTLESCROLLS_STAT_MEDIAN_INTERVAL] = "médiane",

    -------------------------
    -- Damage Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE] = "Dégâts boss totaux",
    [BATTLESCROLLS_STAT_BOSS_DPS] = "DPS boss",
    [BATTLESCROLLS_STAT_GROUP_SHARE] = "Contribution",
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE] = "Dégâts totaux",
    [BATTLESCROLLS_STAT_DPS] = "DPS",

    [BATTLESCROLLS_HEADER_BY_ABILITY] = "Par compétence",
    [BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE] = "Par type de dégâts",
    [BATTLESCROLLS_HEADER_DIRECT_VS_DOT] = "Direct vs DoT",
    [BATTLESCROLLS_HEADER_AOE_VS_SINGLE] = "Zone vs Cible unique",
    [BATTLESCROLLS_HEADER_BY_TARGET] = "Par cible",
    [BATTLESCROLLS_HEADER_BY_SOURCE] = "Par source",

    [BATTLESCROLLS_STAT_DIRECT_DAMAGE] = "Dégâts directs",
    [BATTLESCROLLS_STAT_DAMAGE_OVER_TIME] = "Dégâts persistants",
    [BATTLESCROLLS_STAT_AOE_DAMAGE] = "Dégâts de zone",
    [BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE] = "Dégâts cible unique",

    -------------------------
    -- Healing Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_RAW_HEALING] = "Soins bruts",
    [BATTLESCROLLS_STAT_RAW_HPS] = "HPS brut",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING] = "Soins effectifs",
    [BATTLESCROLLS_STAT_EFFECTIVE_HPS] = "HPS effectif",
    [BATTLESCROLLS_STAT_OVERHEAL] = "Sur-soins",

    [BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT] = "Brut: HoT vs Direct",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT] = "Effectif: HoT vs Direct",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET] = "Soins bruts par cible",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY] = "Soins bruts par compétence",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET] = "Soins effectifs par cible",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY] = "Soins effectifs par compétence",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE] = "Soins bruts par source",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE] = "Soins effectifs par source",

    [BATTLESCROLLS_STAT_DIRECT_HEALING] = "Soins directs",
    [BATTLESCROLLS_STAT_HEALING_OVER_TIME] = "Soins persistants",

    -------------------------
    -- Effects Stats
    -------------------------
    [BATTLESCROLLS_HEADER_YOUR_BUFFS] = "Vos bonus",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON_YOU] = "Malus sur vous",
    [BATTLESCROLLS_HEADER_BUFFS_ON_GROUP] = "Bonus sur le groupe",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON] = "Malus sur <<1>>",

    [BATTLESCROLLS_EFFECT_UPTIME] = "temps actif",
    [BATTLESCROLLS_EFFECT_YOURS] = "les vôtres",
    [BATTLESCROLLS_EFFECT_AVG] = "moy",
    [BATTLESCROLLS_EFFECT_MEMBERS] = "<<1[$d membre/$d membres]>>",

    -------------------------
    -- Effect Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL_UPTIME] = "Temps actif total",
    [BATTLESCROLLS_TOOLTIP_TOTAL_APPLICATIONS] = "Applications totales",
    [BATTLESCROLLS_TOOLTIP_YOUR_CONTRIBUTION] = "Votre contribution",
    [BATTLESCROLLS_TOOLTIP_YOUR_UPTIME] = "Temps actif",
    [BATTLESCROLLS_TOOLTIP_YOUR_APPLICATIONS] = "Applications",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS] = "Cumuls max",
    [BATTLESCROLLS_TOOLTIP_TIME_AT_MAX_STACKS] = "Temps aux cumuls max",
    [BATTLESCROLLS_TOOLTIP_YOUR_TIME_AT_MAX] = "Votre temps au max",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_MEMBER] = "Temps actif moy. par membre",
    [BATTLESCROLLS_TOOLTIP_MEMBERS_AFFECTED] = "Membres affectés",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME] = "Temps actif moyen",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS_OBSERVED] = "Cumuls max observés",
    [BATTLESCROLLS_TOOLTIP_AVG_TIME_AT_MAX] = "Temps moy. aux cumuls max",
    [BATTLESCROLLS_TOOLTIP_YOUR_AVG_TIME_AT_MAX] = "Votre temps moy. au max",
    [BATTLESCROLLS_TOOLTIP_PEAK_INSTANCES] = "Sources simultanées max",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_INSTANCE] = "Temps actif moy. par source",
    [BATTLESCROLLS_TOOLTIP_PER_MEMBER] = "Par membre",
    [BATTLESCROLLS_TOOLTIP_YOU] = "Vous",

    -------------------------
    -- Ability Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL] = "Total",
    [BATTLESCROLLS_TOOLTIP_TYPE] = "Type",
    [BATTLESCROLLS_TOOLTIP_DELIVERY] = "Mode",
    [BATTLESCROLLS_TOOLTIP_CRIT] = "Crit",
    [BATTLESCROLLS_TOOLTIP_AVG_TICK] = "Tick moyen",
    [BATTLESCROLLS_TOOLTIP_MIN_TICK] = "Tick min",
    [BATTLESCROLLS_TOOLTIP_MAX_TICK] = "Tick max",

    [BATTLESCROLLS_TOOLTIP_BY_TARGET] = "Par cible",
    [BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL] = "Intervalle moyen",
    [BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL] = "Intervalle médian",

    [BATTLESCROLLS_TOOLTIP_ABILITY] = "Compétence",

    -------------------------
    -- Damage Types
    -------------------------
    [BATTLESCROLLS_DAMAGE_TYPE_NONE] = "Aucun",
    [BATTLESCROLLS_DAMAGE_TYPE_GENERIC] = "Générique",
    [BATTLESCROLLS_DAMAGE_TYPE_PHYSICAL] = "Physique",
    [BATTLESCROLLS_DAMAGE_TYPE_FIRE] = "Feu",
    [BATTLESCROLLS_DAMAGE_TYPE_SHOCK] = "Foudre",
    [BATTLESCROLLS_DAMAGE_TYPE_OBLIVION] = "Oblivion",
    [BATTLESCROLLS_DAMAGE_TYPE_FROST] = "Froid",
    [BATTLESCROLLS_DAMAGE_TYPE_EARTH] = "Terre",
    [BATTLESCROLLS_DAMAGE_TYPE_MAGIC] = "Magie",
    [BATTLESCROLLS_DAMAGE_TYPE_DROWN] = "Noyade",
    [BATTLESCROLLS_DAMAGE_TYPE_DISEASE] = "Maladie",
    [BATTLESCROLLS_DAMAGE_TYPE_POISON] = "Poison",
    [BATTLESCROLLS_DAMAGE_TYPE_BLEED] = "Saignement",

    -------------------------
    -- Over Time/Direct Descriptions
    -------------------------
    [BATTLESCROLLS_DELIVERY_MIXED] = "Mixte",
    [BATTLESCROLLS_DELIVERY_DOT] = "DoT",
    [BATTLESCROLLS_DELIVERY_DIRECT] = "Direct",
    [BATTLESCROLLS_DELIVERY_HOT] = "HoT",

    -------------------------
    -- Filter Dialog
    -------------------------
    [BATTLESCROLLS_FILTER_DAMAGE_DONE] = "Filtrer les dégâts",
    [BATTLESCROLLS_FILTER_BOSS_DAMAGE] = "Filtrer les dégâts boss",
    [BATTLESCROLLS_FILTER_BY_SOURCE] = "Filtrer par source",
    [BATTLESCROLLS_FILTER_BY_TARGET] = "Filtrer par cible",
    [BATTLESCROLLS_FILTER_BY_GROUP_MEMBER] = "Filtrer par membre",
    [BATTLESCROLLS_FILTER] = "Filtre",
    [BATTLESCROLLS_FILTER_RESET] = "Réinitialiser",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_BY] = "Dégâts infligés par",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_TO] = "Dégâts infligés à",
    [BATTLESCROLLS_FILTER_BOSS_TARGET] = "Cible boss",

    -------------------------
    -- Encounter Display
    -------------------------
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN_WITH] = "Combat <<l:1>> contre <<2>>",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_WITH] = "Combat contre <<1>>",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN] = "Combat <<l:1>>",
    [BATTLESCROLLS_ENCOUNTER_COMBAT] = "Combat",
    [BATTLESCROLLS_ENCOUNTER_INTO_INSTANCE] = "depuis le début",
    [BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX] = "(Soi-même)",

    -------------------------
    -- List States
    -------------------------
    [BATTLESCROLLS_LIST_LOADING] = "Chargement",
    [BATTLESCROLLS_LIST_NO_DATA] = "Aucune donnée de combat enregistrée",
    [BATTLESCROLLS_LIST_NO_ENCOUNTERS] = "Aucun combat",
    [BATTLESCROLLS_LIST_NO_STATS] = "Aucune statistique disponible",
    [BATTLESCROLLS_LIST_NO_SETTINGS] = "Aucun paramètre disponible",

    -------------------------
    -- LibHarvensAddonSettings Integration
    -------------------------
    [BATTLESCROLLS_LIBHARVENS_OPEN_BUTTON] = "Ouvrir Battle Scrolls",
    [BATTLESCROLLS_LIBHARVENS_TOOLTIP] = "Battle Scrolls est également accessible depuis le menu <<1>>.",

    -------------------------
    -- Misc
    -------------------------
    [BATTLESCROLLS_UNKNOWN] = "Inconnu",
    [BATTLESCROLLS_UNKNOWN_BOSS] = "Boss inconnu",

    -------------------------
    -- Personal Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_PERSONAL_DEFAULT] = "Par défaut",
    [BATTLESCROLLS_DESIGN_PERSONAL_MINIMAL] = "Minimal",
    [BATTLESCROLLS_DESIGN_PERSONAL_BAR] = "Barre",

    -- Bar design settings
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION] = "Direction de la barre",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_RIGHT] = "Droite",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_LEFT] = "Gauche",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_CENTER] = "Bidirectionnel",

    -------------------------
    -- Group Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_GROUP_TEXT] = "Texte",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR] = "Hodor",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR_DESC] = "Très proche de Hodor Reflexes par @andy.s et @m00nyONE.",
    [BATTLESCROLLS_DESIGN_GROUP_BARS] = "Barres",
    [BATTLESCROLLS_DESIGN_GROUP_BARS_DESC] = "Vaguement inspiré de Hodor Restyle par Hyperioxes.",

    -- Text design settings
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS] = "Colonnes",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TITLE] = "Disposition des colonnes",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TEXT] = "Les groupes de 4 ou moins utilisent toujours 1 colonne.",

    -------------------------
    -- DPS Meter Display Strings
    -- Note: DPS/HPS are universal gaming terms, hardcoded in code
    -------------------------
    [BATTLESCROLLS_METER_EFFECTIVE] = "effectif",
    [BATTLESCROLLS_METER_EFF] = "eff.",
    [BATTLESCROLLS_METER_BOSS] = "Boss",
    [BATTLESCROLLS_METER_ALL] = "Total",
    [BATTLESCROLLS_METER_ALL_DAMAGE] = "Tous les dégâts",
    [BATTLESCROLLS_METER_TOTAL] = "Total",
    [BATTLESCROLLS_METER_BOSS_ALL_DAMAGE] = "Dégâts au boss / Tous les dégâts",
    [BATTLESCROLLS_METER_EFFECTIVE_RAW_HEALING] = "Effectif / Soin brut",

    -- Overview Panel Q3/Q4 Headers
    [BATTLESCROLLS_OVERVIEW_TOP_ABILITIES] = "Meilleures compétences",
    [BATTLESCROLLS_OVERVIEW_BOSSES] = "Boss",
    [BATTLESCROLLS_OVERVIEW_TARGETS] = "Cibles",
    [BATTLESCROLLS_OVERVIEW_SOURCES] = "Sources",
    [BATTLESCROLLS_OVERVIEW_TARGETS_HEALED] = "Cibles soignées",
    [BATTLESCROLLS_OVERVIEW_HEALERS] = "Soigneurs",
    [BATTLESCROLLS_OVERVIEW_GROUP_BUFFS] = "Bonus de groupe",
    [BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS] = "Malus sur le boss",

    -- Group Stats
    [BATTLESCROLLS_OVERVIEW_BOSS_DAMAGE] = "Dégâts au boss",
    [BATTLESCROLLS_STAT_GROUP_DAMAGE] = "Dégâts de groupe",
    [BATTLESCROLLS_STAT_GROUP_DPS] = "DPS de groupe",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE] = "Dégâts au boss du groupe",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DPS] = "DPS au boss du groupe",

    -- Overview Panel - Ability Stats
    [BATTLESCROLLS_STAT_MAX_PREFIX] = "Max: <<1>>",
    [BATTLESCROLLS_STAT_CRIT_PERCENT] = "<<1>>% crit",
    [BATTLESCROLLS_STAT_PER_SECOND] = "<<1>>/s",

    -- Overview Panel - Effect Stats
    [BATTLESCROLLS_EFFECT_APPS_COUNT] = "<<1[$d application/$d applications]>>",
    [BATTLESCROLLS_EFFECT_YOURS_PERCENT] = "<<1>>% à vous",
    [BATTLESCROLLS_EFFECT_STACKS_COUNT] = "×<<1[$d charge/$d charges]>>",

    -- Overview Panel Summary
    [BATTLESCROLLS_OVERVIEW_ENCOUNTER] = "Rencontre",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT] = "Dégâts Infligés",
    [BATTLESCROLLS_OVERVIEW_SUMMARY] = "Résumé",
    [BATTLESCROLLS_OVERVIEW_TOTAL] = "Total",
    [BATTLESCROLLS_OVERVIEW_SHARE] = "Part",
    [BATTLESCROLLS_OVERVIEW_COMPOSITION] = "Composition",
    [BATTLESCROLLS_OVERVIEW_QUALITY] = "Qualité",
    [BATTLESCROLLS_OVERVIEW_CRIT_RATE] = "Taux critique",
    [BATTLESCROLLS_OVERVIEW_MAX_HIT] = "Coup max",
    [BATTLESCROLLS_OVERVIEW_MAX_HEAL] = "Soin max",
    [BATTLESCROLLS_OVERVIEW_KEY_BUFFS] = "Vos bonus",
    [BATTLESCROLLS_OVERVIEW_NO_EFFECTS] = "Aucun effet enregistré",

    -- Overview Panel Short Labels
    [BATTLESCROLLS_BOSS_DAMAGE] = "Dégâts au boss",
    [BATTLESCROLLS_DAMAGE_DONE] = "Dégâts infligés",
    [BATTLESCROLLS_HEALING_OUT] = "Soins prodigués",
    [BATTLESCROLLS_SELF_HEALING] = "Auto-soins",
    [BATTLESCROLLS_HEALING_IN] = "Soins reçus",
    [BATTLESCROLLS_AOE] = "Zone",
    [BATTLESCROLLS_SINGLE_TARGET] = "Cible unique",
    [BATTLESCROLLS_HEALING_RAW_HPS] = "HPS brut",
    [BATTLESCROLLS_HEALING_EFFECTIVE_HPS] = "HPS effectif",
    [BATTLESCROLLS_HEALING_OVERHEAL] = "Sur-soins",
    [BATTLESCROLLS_TOOLTIP_DURATION] = "Durée",

    -------------------------
    -- LibAsync Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_PERFORMANCE] = "Performance",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED] = "Vitesse de traitement",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_PERFORMANCE] = "Performance",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_SMOOTH] = "Fluide",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM] = "Personnalisé (<<1>> FPS)",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE] = "Vitesse de traitement",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "Contrôle la vitesse de traitement des tâches en arrière-plan. Affecte principalement l'interface du Journal et le délai entre la fin du combat et l'apparition de la rencontre dans la liste.\n\nPerformance: Traitement le plus rapide. Peut causer de brèves saccades.\nFluide: Gameplay plus fluide, traitement plus lent. Peut faire que les rencontres restent bloquées en chargement ou n'apparaissent pas dans le Journal.\n\nCe paramètre affecte TOUS les addons utilisant LibAsync.",

    -------------------------
    -- Onboarding
    -------------------------
    [BATTLESCROLLS_ONBOARDING_WELCOME_TITLE] = "Bienvenue dans Battle Scrolls",
    [BATTLESCROLLS_ONBOARDING_WELCOME_TEXT] = "Battle Scrolls enregistre vos combats et vous permet de les revoir plus tard dans le Journal.\n\nFonctionnalités:\n- Compteurs DPS/HPS en temps réel\n- Détails des dégâts et soins\n- Suivi du temps d'activité des buffs/débuffs\n- Surveillance des débuffs sur les boss\n\nConfigurons quelques paramètres.",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED] = "Commencer",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED_DESC] = "Me guider à travers les options",
    [BATTLESCROLLS_ONBOARDING_SKIP] = "Passer",
    [BATTLESCROLLS_ONBOARDING_SKIP_DESC] = "Je me débrouillerai. Utiliser les paramètres recommandés.",
    [BATTLESCROLLS_ONBOARDING_METER_QUESTION] = "Choisissez votre style de compteur DPS:",
    -- Meter presets
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL] = "Minimal",
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL_DESC] = "Compteur personnel compact dans le coin",
    [BATTLESCROLLS_PRESET_FULL_STACKED] = "Personnel + Groupe",
    [BATTLESCROLLS_PRESET_FULL_STACKED_DESC] = "Compteur personnel avec classement de groupe en dessous",
    [BATTLESCROLLS_PRESET_HODOR] = "Style Hodor",
    [BATTLESCROLLS_PRESET_HODOR_DESC] = "Compteur de groupe uniquement, très proche de Hodor Reflexes (@andy.s, @m00nyONE)",
    [BATTLESCROLLS_PRESET_BAR] = "Barre de progression",
    [BATTLESCROLLS_PRESET_BAR_DESC] = "Barre de progression pour le DPS personnel",
    [BATTLESCROLLS_PRESET_COLORFUL] = "Barres colorées",
    [BATTLESCROLLS_PRESET_COLORFUL_DESC] = "Barres colorées pour le DPS personnel et de groupe, groupe vaguement inspiré de Hodor Restyle (Hyperioxes)",
    [BATTLESCROLLS_PRESET_DISABLED] = "Désactivé",
    [BATTLESCROLLS_PRESET_DISABLED_DESC] = "Pas de compteurs, enregistrement uniquement",
    -- Storage options
    [BATTLESCROLLS_ONBOARDING_STORAGE_QUESTION] = "Combien d'historique garder?",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL] = "Minimal (5 Mo)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC] = "Environ 6 épreuves",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE] = "Modéré (12 Mo)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC] = "Environ 16 épreuves",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS] = "Généreux (25 Mo)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC] = "Environ 36 épreuves",
    -- Effects tracking
    [BATTLESCROLLS_ONBOARDING_EFFECTS_QUESTION] = "Quel niveau de suivi buff/débuff voulez-vous?",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL] = "Suivi complet",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL_DESC] = "Vos buffs, débuffs de boss ET temps d'activité des buffs de groupe (p.ex. temps d'activité de Courage majeur pour tous les membres du groupe)",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL] = "Essentiel uniquement",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL_DESC] = "Vos buffs et débuffs de boss uniquement. Ignore le suivi de groupe pour réduire l'utilisation mémoire.",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED] = "Désactivé",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED_DESC] = "Pas de suivi buff/débuff. Utilisation mémoire minimale, mais pas de données d'activité dans les rapports.",
    -- Completion
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TITLE] = "Tout est prêt!",
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TEXT] = "Battle Scrolls est prêt à suivre vos combats.\n\nMaintenant, allez vous battre!\n\nVos rencontres apparaîtront ici dans le Journal. Vous pouvez modifier ces paramètres à tout moment depuis l'onglet Paramètres.",
    [BATTLESCROLLS_ONBOARDING_CHAT_MESSAGE] = "[Battle Scrolls] Merci d'avoir installé! Ouvrez Journal > Battle Scrolls pour configurer et activer.",
    [BATTLESCROLLS_ONBOARDING_CONTINUE] = "Continuer",
    [BATTLESCROLLS_ONBOARDING_FINISH] = "Terminer la configuration",
    [BATTLESCROLLS_ONBOARDING_LETS_GO] = "C'est parti!",
    [BATTLESCROLLS_ONBOARDING_STEP_FORMAT] = "Étape <<1>> sur <<2>>",

    -------------------------
    -- Delete Functionality
    -------------------------
    [BATTLESCROLLS_DELETE] = "Supprimer",
    [BATTLESCROLLS_DELETE_INSTANCE_TITLE] = "Supprimer la zone",
    [BATTLESCROLLS_DELETE_INSTANCE_TEXT] = "Supprimer <<1>> et tous ses combats?",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TITLE] = "Supprimer le combat",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TEXT] = "Supprimer <<1>>?",
    [BATTLESCROLLS_DELETE_WARNING] = "Cette action est irréversible.",
    [BATTLESCROLLS_DELETE_MEMORY_FREE] = "Libère environ <<1>>",
    [BATTLESCROLLS_DELETE_MEMORY_STATUS] = "Mémoire: <<1>> sur <<2>> (<<3>>%)",

    -------------------------
    -- Dynamic Overview Panel
    -------------------------
    [BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN] = "Dégâts subis",
    [BATTLESCROLLS_OVERVIEW_TOP_HEALING] = "Meilleurs soins",
    [BATTLESCROLLS_OVERVIEW_TOP_INCOMING] = "Top dégâts entrants",
    [BATTLESCROLLS_OVERVIEW_HEALING_TARGETS] = "Cibles de soins",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES] = "Sources de dégâts",

    -------------------------
    -- Instance Locking
    -------------------------
    [BATTLESCROLLS_LOCK_ERROR_TITLE] = "Impossible de verrouiller",
    [BATTLESCROLLS_LOCK_ERROR_TEXT] = "Verrouiller cette zone dépasserait votre limite de mémoire. Les zones verrouillées et la plus récente sont protégées du nettoyage.\n\nPour libérer de l'espace, déverrouillez ou supprimez des zones verrouillées, ou augmentez votre limite de mémoire dans les Paramètres.",
    [BATTLESCROLLS_LOCK_LOCKED_SIZE] = "Actuellement verrouillé: <<1>>",
    [BATTLESCROLLS_LOCK_INSTANCE_SIZE] = "Cette zone: <<1>>",
    [BATTLESCROLLS_LOCK_LIMIT] = "Limite de mémoire: <<1>>",

    -------------------------
    -- Favorite Effects
    -------------------------
    [BATTLESCROLLS_FAVORITE_EFFECT] = "Favori",
    [BATTLESCROLLS_UNFAVORITE_EFFECT] = "Retirer des favoris",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES] = "Effacer tous les favoris",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES_TOOLTIP] = "Supprimer tous les effets favoris. Les effets favoris sont affichés en haut de chaque liste d'effets.",

    -------------------------
    -- Group Tab Enhancements
    -------------------------
    [BATTLESCROLLS_STAT_SURVIVABILITY] = "Survie",
    [BATTLESCROLLS_BOSS_DAMAGE_TAKEN] = "Dégâts subis du boss",

    -- Group Member Card Strings
    [BATTLESCROLLS_GROUP_CARD_OF_GROUP] = "du groupe",
    [BATTLESCROLLS_GROUP_CARD_ALIVE] = "Vivant",

    -- Group Tab Redesign
    [BATTLESCROLLS_GROUP_DAMAGE_BY_TYPE] = "Dégâts par type",
    [BATTLESCROLLS_GROUP_VS_AVERAGE] = "vs Moyenne DD",
    [BATTLESCROLLS_GROUP_DD_COUNTED] = "DDs comptés",
    [BATTLESCROLLS_GROUP_DAMAGE_OUTPUT] = "Dégâts infligés",
    [BATTLESCROLLS_GROUP_HEALING_OUTPUT] = "Soins prodigués",
    [BATTLESCROLLS_GROUP_RANK] = "Rang",
    [BATTLESCROLLS_GROUP_MAGICAL] = "Magique",
    [BATTLESCROLLS_GROUP_DEATH] = "Mort",
    [BATTLESCROLLS_GROUP_FIRST_DEATH] = "Première Mort",
    [BATTLESCROLLS_GROUP_LAST_DEATH] = "Dernière Mort",
    [BATTLESCROLLS_GROUP_DEATHS] = "Morts",
    [BATTLESCROLLS_GROUP_COL_DEATHS] = "Morts",
    [BATTLESCROLLS_GROUP_DEATH_COUNT] = "<<1[$d Mort/$d Morts]>>",
    [BATTLESCROLLS_GROUP_METRIC_DPS] = "<<1>> DPS",
    [BATTLESCROLLS_GROUP_METRIC_HPS] = "<<1>> HPS",
    [BATTLESCROLLS_GROUP_METRIC_DTPS] = "<<1>> DTPS",
    [BATTLESCROLLS_GROUP_METRIC_CRIT] = "<<1>>% Crit",
    [BATTLESCROLLS_GROUP_METRIC_OVERHEAL] = "<<1>>% Sur-soins",
    [BATTLESCROLLS_GROUP_TOP_INCOMING_DAMAGE] = "Top Dégâts Reçus",
    [BATTLESCROLLS_GROUP_DEATH_AT] = "à <<1>>",
    [BATTLESCROLLS_HEADER_DEATHS] = "Morts",
    [BATTLESCROLLS_STAT_DEATH_COUNT] = "Nombre de Morts",
    [BATTLESCROLLS_DEATH_N] = "Mort <<1>>",

    -- Group Context Tooltips
    [BATTLESCROLLS_TOOLTIP_GROUP_TOTAL] = "Total du Groupe",
    [BATTLESCROLLS_TOOLTIP_GROUP_DPS] = "DPS du Groupe",
    [BATTLESCROLLS_TOOLTIP_GROUP_AVG] = "Moyenne DD",
    [BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN] = "Répartition du Groupe",
    [BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_TAKEN] = "Dégâts Subis du Groupe",

    -- Group Table
    [BATTLESCROLLS_GROUP_COL_NAME] = "Nom",
    [BATTLESCROLLS_GROUP_COL_TOTAL] = "Total",
    [BATTLESCROLLS_GROUP_COL_CRIT] = "Crit",
    [BATTLESCROLLS_GROUP_COL_ALIVE] = "Vivant",

    -------------------------
    -- Setup Tab
    -------------------------
    [BATTLESCROLLS_TAB_BUILD] = "Archétype",
    [BATTLESCROLLS_SETUP_ABILITIES] = "Compétences",
    [BATTLESCROLLS_SETUP_FRONT_BAR] = "Barre primaire",
    [BATTLESCROLLS_SETUP_BACK_BAR] = "Barre secondaire",
    [BATTLESCROLLS_SETUP_GEAR_SETS] = "Ensembles d'équipement",
    [BATTLESCROLLS_SETUP_EQUIPMENT] = "Équipement",
    [BATTLESCROLLS_SETUP_POISONS] = "Poisons",
    [BATTLESCROLLS_SETUP_CHARACTER] = "Personnage",
    [BATTLESCROLLS_SETUP_CLASS_SKILLS] = "Lignes de compétences de classe",
    [BATTLESCROLLS_SETUP_MUNDUS] = "Mundus",
    [BATTLESCROLLS_SETUP_FOOD] = "Nourriture",
    [BATTLESCROLLS_WEAPON_GREATSWORD] = "Espadon",
    [BATTLESCROLLS_WEAPON_BATTLE_AXE] = "Hache de guerre",
    [BATTLESCROLLS_WEAPON_MAUL] = "Masse",

    -------------------------
    -- Food Buff Descriptions
    -------------------------
    [BATTLESCROLLS_FOOD_MAX_HEALTH] = "Santé maximale",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA] = "Magie maximale",
    [BATTLESCROLLS_FOOD_MAX_STAMINA] = "Endurance maximale",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_MAGICKA] = "Santé et magie maximales",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_STAMINA] = "Santé et endurance maximales",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA_STAMINA] = "Magie et endurance maximales",
    [BATTLESCROLLS_FOOD_MAX_TRISTAT] = "Santé, magie et endurance maximales",
    [BATTLESCROLLS_FOOD_HEALTH_RECOVERY] = "Récupération de santé",
    [BATTLESCROLLS_FOOD_MAGICKA_RECOVERY] = "Récupération de magie",
    [BATTLESCROLLS_FOOD_STAMINA_RECOVERY] = "Récupération d'endurance",
    [BATTLESCROLLS_FOOD_HEALTH_MAGICKA_RECOVERY] = "Récupération de santé et de magie",
    [BATTLESCROLLS_FOOD_HEALTH_STAMINA_RECOVERY] = "Récupération de santé et d'endurance",
    [BATTLESCROLLS_FOOD_MAGICKA_STAMINA_RECOVERY] = "Récupération de magie et d'endurance",
    [BATTLESCROLLS_FOOD_RECOVERY_TRISTAT] = "Récupération de santé, de magie et d'endurance",

    -------------------------
    -- Alchemy Traits
    -------------------------
    [BATTLESCROLLS_ALCHEMY_TRAIT1] = "Rend de la Santé",
    [BATTLESCROLLS_ALCHEMY_TRAIT2] = "Réduit la Santé",
    [BATTLESCROLLS_ALCHEMY_TRAIT3] = "Rend de la Magie",
    [BATTLESCROLLS_ALCHEMY_TRAIT4] = "Réduit la Magie",
    [BATTLESCROLLS_ALCHEMY_TRAIT5] = "Rend de la Vigueur",
    [BATTLESCROLLS_ALCHEMY_TRAIT6] = "Ravage de Vigueur",
    [BATTLESCROLLS_ALCHEMY_TRAIT7] = "Augmente la résistance aux sorts",
    [BATTLESCROLLS_ALCHEMY_TRAIT8] = "Brèche",
    [BATTLESCROLLS_ALCHEMY_TRAIT9] = "Augmente l'armure",
    [BATTLESCROLLS_ALCHEMY_TRAIT10] = "Fracture",
    [BATTLESCROLLS_ALCHEMY_TRAIT11] = "Augmente la puissance des sorts",
    [BATTLESCROLLS_ALCHEMY_TRAIT12] = "Couardise",
    [BATTLESCROLLS_ALCHEMY_TRAIT13] = "Augmente la puissance de l'arme",
    [BATTLESCROLLS_ALCHEMY_TRAIT14] = "Mutilation",
    [BATTLESCROLLS_ALCHEMY_TRAIT15] = "Critique de sorts",
    [BATTLESCROLLS_ALCHEMY_TRAIT16] = "Incertitude",
    [BATTLESCROLLS_ALCHEMY_TRAIT17] = "Critique d'armes",
    [BATTLESCROLLS_ALCHEMY_TRAIT18] = "Affaiblissement",
    [BATTLESCROLLS_ALCHEMY_TRAIT19] = "Implacable",
    [BATTLESCROLLS_ALCHEMY_TRAIT20] = "Capture",
    [BATTLESCROLLS_ALCHEMY_TRAIT21] = "Détection",
    [BATTLESCROLLS_ALCHEMY_TRAIT22] = "Invisible",
    [BATTLESCROLLS_ALCHEMY_TRAIT23] = "Vitesse",
    [BATTLESCROLLS_ALCHEMY_TRAIT24] = "Entrave",
    [BATTLESCROLLS_ALCHEMY_TRAIT25] = "Protection",
    [BATTLESCROLLS_ALCHEMY_TRAIT26] = "Vulnérabilité",
    [BATTLESCROLLS_ALCHEMY_TRAIT27] = "Santé persistante",
    [BATTLESCROLLS_ALCHEMY_TRAIT28] = "Ravage de Santé graduel",
    [BATTLESCROLLS_ALCHEMY_TRAIT29] = "Vitalité",
    [BATTLESCROLLS_ALCHEMY_TRAIT30] = "Profanation",
    [BATTLESCROLLS_ALCHEMY_TRAIT31] = "Héroïsme",
    [BATTLESCROLLS_ALCHEMY_TRAIT32] = "Timidité",
}

-- Register translations
for stringId, stringValue in pairs(strings) do
    SafeAddString(stringId, stringValue, 1)
end

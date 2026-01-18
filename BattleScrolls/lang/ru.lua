-- Battle Scrolls Localization - Russian (Русский)
-- Translations use ESO's official Russian terminology
-- Note: Using official ESO terms (e.g., "Испытание" not "Триал")

local strings = {
    -------------------------
    -- Core UI Labels
    -------------------------
    [BATTLESCROLLS_UI_NAME] = "Боевые Свитки",
    [BATTLESCROLLS_UI_SETTINGS] = "Настройки",
    [BATTLESCROLLS_UI_FILTER] = "Фильтр",
    [BATTLESCROLLS_UI_FILTER_ACTIVE] = "Фильтр (Активен)",
    [BATTLESCROLLS_STAT_HPS] = "HPS",

    -------------------------
    -- Zone/Instance Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ZONES] = "Все зоны",
    [BATTLESCROLLS_TAB_INSTANCED] = "Инстансы",
    [BATTLESCROLLS_TAB_OVERLAND] = "Открытый мир",
    [BATTLESCROLLS_TAB_HOUSES] = "Дома",
    [BATTLESCROLLS_TAB_PVP] = "PvP",

    -------------------------
    -- Encounter Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ENCOUNTERS] = "Все сражения",
    [BATTLESCROLLS_TAB_BOSS_ENCOUNTERS] = "Сражения с боссами",
    [BATTLESCROLLS_TAB_OTHER_ENCOUNTERS] = "Прочие сражения",
    [BATTLESCROLLS_TAB_PLAYER_ENCOUNTERS] = "PvP-сражения",
    [BATTLESCROLLS_TAB_TARGET_DUMMY] = "Тренировочный манекен",

    -------------------------
    -- Stats Tabs
    -------------------------
    [BATTLESCROLLS_TAB_OVERVIEW] = "Обзор",
    [BATTLESCROLLS_TAB_BOSS_DAMAGE_DONE] = "Урон боссу",
    [BATTLESCROLLS_TAB_DAMAGE_DONE] = "Нанесённый урон",
    [BATTLESCROLLS_TAB_DAMAGE_TAKEN] = "Полученный урон",
    [BATTLESCROLLS_TAB_HEALING_OUT] = "Исходящее исцеление",
    [BATTLESCROLLS_TAB_SELF_HEALING] = "Самоисцеление",
    [BATTLESCROLLS_TAB_HEALING_IN] = "Полученное исцеление",
    [BATTLESCROLLS_TAB_EFFECTS] = "Эффекты",

    -------------------------
    -- Time Headers
    -------------------------
    [BATTLESCROLLS_TIME_TODAY] = "Сегодня",
    [BATTLESCROLLS_TIME_YESTERDAY] = "Вчера",

    -------------------------
    -- DPS Meter Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_DPS_METER] = "Счётчик урона",
    [BATTLESCROLLS_SETTINGS_KEEP_AFTER_COMBAT] = "Показывать после сражения",
    [BATTLESCROLLS_SETTINGS_HIDE_IMMEDIATELY] = "Скрыть сразу",
    [BATTLESCROLLS_SETTINGS_10_SECONDS] = "10 секунд",
    [BATTLESCROLLS_SETTINGS_30_SECONDS] = "30 секунд",
    [BATTLESCROLLS_SETTINGS_2_MINUTES] = "2 минуты",
    [BATTLESCROLLS_SETTINGS_5_MINUTES] = "5 минут",
    [BATTLESCROLLS_SETTINGS_UNTIL_RELOAD] = "До перезагрузки",

    [BATTLESCROLLS_SETTINGS_PERSONAL_METER] = "Личный счётчик",
    [BATTLESCROLLS_SETTINGS_GROUP_METER] = "Групповой счётчик",
    [BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT] = "Даже если выключено, участники группы всё равно смогут видеть ваш DPS, если у них установлен аддон.",
    [BATTLESCROLLS_SETTINGS_ENABLED] = "Включено",
    [BATTLESCROLLS_SETTINGS_MODE] = "Режим",
    [BATTLESCROLLS_SETTINGS_DESIGN] = "Оформление",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_LEFT] = "Расстояние слева",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_TOP] = "Расстояние сверху",
    [BATTLESCROLLS_SETTINGS_SIZE] = "Размер",
    [BATTLESCROLLS_SETTINGS_RESET_POSITION] = "Сбросить позицию",
    [BATTLESCROLLS_SETTINGS_POSITION] = "Позиция",

    -- Meter modes
    [BATTLESCROLLS_SETTINGS_MODE_AUTO] = "Авто",
    [BATTLESCROLLS_SETTINGS_MODE_DAMAGE] = "Урон",
    [BATTLESCROLLS_SETTINGS_MODE_HEALING] = "Исцеление",

    -- Meter size options
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_SMALL] = "Очень маленький",
    [BATTLESCROLLS_SETTINGS_SIZE_SMALL] = "Маленький",
    [BATTLESCROLLS_SETTINGS_SIZE_MEDIUM] = "Средний",
    [BATTLESCROLLS_SETTINGS_SIZE_LARGE] = "Большой",
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_LARGE] = "Очень большой",

    -- Meter position options
    [BATTLESCROLLS_SETTINGS_POSITION_BELOW] = "Под личным",
    [BATTLESCROLLS_SETTINGS_POSITION_ABOVE] = "Над личным",
    [BATTLESCROLLS_SETTINGS_POSITION_SEPARATE] = "Отдельно",

    -- Auto mode tooltip
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TITLE] = "Автоматический режим",
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TEXT] = "Показывает большее значение — урон в секунду или исцеление в секунду.",

    -- Group tracker tooltips
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA] = "Показывать без данных группы",
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA_TEXT] = "Если включено, групповой счётчик отображается даже когда другие участники не делятся данными. Вы увидите только свою статистику.",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_DESIGN] = "Оформление группового счётчика",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION] = "Позиция группового счётчика",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION_TEXT] = "Под/Над: Прикрепляет групповой счётчик к личному.\nОтдельно: Размещает групповой счётчик независимо с настраиваемой позицией.",

    -------------------------
    -- Recording Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_RECORDING] = "Запись",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED] = "Записывать в инстансах",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED_TEXT] = "Инстансы включают подземелья, испытания, арены и Бесконечный архив.",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_OVERLAND] = "Записывать в открытом мире",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_HOUSES] = "Записывать в домах",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_PVP] = "Записывать в PvP",
    [BATTLESCROLLS_SETTINGS_RECORD_BOSS_FIGHTS] = "Записывать сражения с боссами",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS] = "Записывать сражения с мобами",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS_TEXT] = "Сражения с обычными врагами (не боссы, не игроки).",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS] = "Записывать PvP-сражения",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS_TEXT] = "PvP-сражения против других игроков.",
    [BATTLESCROLLS_SETTINGS_RECORD_DUMMY_FIGHTS] = "Записывать сражения с манекеном",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE] = "Фильтры записи",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT] = "Фильтры зон и типов сражений комбинируются: сражение должно соответствовать хотя бы одной зоне И одному типу для записи.",

    -- Storage/History settings
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT] = "Лимит истории",
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT_TITLE] = "Лимит истории",
    -- Storage size preset labels (dropdown options)
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XS] = "Минимум",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_SMALL] = "Мало",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_MEDIUM] = "Средне",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_LARGE] = "Много",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XL] = "Очень много",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_CAUTION] = "Осторожно",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_YOLO] = "Что может пойти не так?",
    -- Storage tooltip
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC] = "Сколько истории боёв хранить. При превышении лимита старые инстансы удаляются автоматически.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE] = "Этот лимит относится только к сохранённой истории. Аддон также использует память для отслеживания текущего боя и отрисовки интерфейса, поэтому общее потребление будет выше.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT] = "История: <<1>> МБ из <<2>> МБ (<<3>>%)",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS] = "Пресеты (испытание ~0.5-1 МБ, подземелье ~0.25-0.5 МБ):",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XS] = "  Минимум: 5 МБ - несколько последних забегов",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL] = "  Мало: 8 МБ - вечер прогресса",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM] = "  Средне: 12 МБ - неделя казуальной игры",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE] = "  Много: 18 МБ - пара недель",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XL] = "  Очень много: 25 МБ - месяц воспоминаний",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION] = "  Осторожно: 40 МБ - вы правда любите данные",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO] = "  Что может пойти не так?: 60 МБ - живём опасно",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING] = "О лимитах памяти ESO: все аддоны делят пул в 100 МБ. При 70 МБ ESO показывает предупреждение. При 100 МБ интерфейс перезагружается и всё отключается. Если у вас много аддонов, выберите меньший пресет. Совет: введите /addonmemdisplay в чат для отслеживания памяти в реальном времени.",

    -------------------------
    -- Effect Tracking Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_EFFECT_TRACKING] = "Отслеживание эффектов",
    [BATTLESCROLLS_SETTINGS_PLAYER_BUFFS] = "Баффы на вас",
    [BATTLESCROLLS_SETTINGS_PLAYER_DEBUFFS] = "Дебаффы на вас",
    [BATTLESCROLLS_SETTINGS_GROUP_BUFFS] = "Баффы на группе",
    [BATTLESCROLLS_SETTINGS_BOSS_DEBUFFS] = "Дебаффы на боссе",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION] = "Сверка",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION_TOOLTIP] = "Как часто проверять отслеживание эффектов на соответствие состоянию игры. Более высокая точность ловит больше пропущенных событий, но расходует больше памяти. Память освобождается только при перезагрузке интерфейса.",
    [BATTLESCROLLS_SETTINGS_RECON_MAX] = "Макс",
    [BATTLESCROLLS_SETTINGS_RECON_HIGH] = "Высокая",
    [BATTLESCROLLS_SETTINGS_RECON_NORMAL] = "Обычная",
    [BATTLESCROLLS_SETTINGS_RECON_LOW] = "Низкая",
    [BATTLESCROLLS_SETTINGS_RECON_OFF] = "Выкл",

    -------------------------
    -- Slider keybinds
    -------------------------
    [BATTLESCROLLS_SETTINGS_SLIDER_HOLD_FAST] = "Удерживать: быстро",
    [BATTLESCROLLS_SETTINGS_SLIDER_RELEASE_PRECISION] = "Отпустить: точно",

    -------------------------
    -- Overview Stats
    -------------------------
    [BATTLESCROLLS_STAT_DURATION] = "Длительность",
    [BATTLESCROLLS_STAT_SUMMARY] = "Сводка",

    -- Boss Damage
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE] = "Личный урон боссу",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DPS] = "Личный DPS по боссу",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE_SHARE] = "Доля урона боссу",
    [BATTLESCROLLS_HEADER_BOSS_DAMAGE_DONE] = "Урон боссу",

    -- Total Damage
    [BATTLESCROLLS_STAT_PERSONAL_DAMAGE] = "Личный урон",
    [BATTLESCROLLS_STAT_PERSONAL_DPS] = "Личный DPS",
    [BATTLESCROLLS_STAT_PERSONAL_SHARE] = "Доля урона",
    [BATTLESCROLLS_HEADER_TOTAL_DAMAGE_DONE] = "Общий урон",

    -- Damage Taken
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN] = "Полученный урон",
    [BATTLESCROLLS_STAT_DTPS] = "DTPS",
    [BATTLESCROLLS_HEADER_DAMAGE_TAKEN] = "Полученный урон",

    -- Healing Overview
    [BATTLESCROLLS_STAT_RAW_SELF_HEALING] = "Полное самоисцеление",
    [BATTLESCROLLS_STAT_RAW_SELF_HPS] = "Полный HPS самоисцеления",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HEALING] = "Эфф. самоисцеление",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HPS] = "Эфф. HPS самоисцеления",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT] = "Полное исход. исцеление",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT_HPS] = "Полный исход. HPS",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT] = "Эфф. исход. исцеление",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT_HPS] = "Эфф. исход. HPS",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN] = "Полное получ. исцеление",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN_HPS] = "Полный получ. HPS",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN] = "Эфф. получ. исцеление",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN_HPS] = "Эфф. получ. HPS",
    [BATTLESCROLLS_HEADER_HEALING] = "Исцеление",

    -- Proc Tracking
    [BATTLESCROLLS_HEADER_PROC_TRACKING] = "Отслеживание активаций",
    [BATTLESCROLLS_STAT_TOTAL_PROCS] = "активаций",
    [BATTLESCROLLS_STAT_MEDIAN_INTERVAL] = "медиана",

    -------------------------
    -- Damage Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE] = "Общий урон боссу",
    [BATTLESCROLLS_STAT_BOSS_DPS] = "DPS по боссу",
    [BATTLESCROLLS_STAT_GROUP_SHARE] = "Вклад в группе",
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE] = "Общий урон",
    [BATTLESCROLLS_STAT_DPS] = "DPS",

    [BATTLESCROLLS_HEADER_BY_ABILITY] = "По способности",
    [BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE] = "По типу урона",
    [BATTLESCROLLS_HEADER_DIRECT_VS_DOT] = "Прямой / Периодический",
    [BATTLESCROLLS_HEADER_AOE_VS_SINGLE] = "По площади / По одиночной цели",
    [BATTLESCROLLS_HEADER_BY_TARGET] = "По цели",
    [BATTLESCROLLS_HEADER_BY_SOURCE] = "По источнику",

    [BATTLESCROLLS_STAT_DIRECT_DAMAGE] = "Прямой урон",
    [BATTLESCROLLS_STAT_DAMAGE_OVER_TIME] = "Периодический урон",
    [BATTLESCROLLS_STAT_AOE_DAMAGE] = "Урон по площади",
    [BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE] = "Урон по одиночной цели",

    -------------------------
    -- Healing Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_RAW_HEALING] = "Полное исцеление",
    [BATTLESCROLLS_STAT_RAW_HPS] = "Полный HPS",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING] = "Эфф. исцеление",
    [BATTLESCROLLS_STAT_EFFECTIVE_HPS] = "Эфф. HPS",
    [BATTLESCROLLS_STAT_OVERHEAL] = "Переисцеление",

    [BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT] = "Полное: HoT / Прямое",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT] = "Эфф.: HoT / Прямое",
    [BATTLESCROLLS_HEADER_RAW_BY_TARGET] = "Полное по цели",
    [BATTLESCROLLS_HEADER_RAW_BY_ABILITY] = "Полное по способности",
    [BATTLESCROLLS_HEADER_EFFECTIVE_BY_TARGET] = "Эфф. по цели",
    [BATTLESCROLLS_HEADER_EFFECTIVE_BY_ABILITY] = "Эфф. по способности",
    [BATTLESCROLLS_HEADER_RAW_BY_SOURCE] = "Полное по источнику",
    [BATTLESCROLLS_HEADER_EFFECTIVE_BY_SOURCE] = "Эфф. по источнику",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET] = "Полное по цели",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY] = "Полное по способности",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET] = "Эфф. по цели",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY] = "Эфф. по способности",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE] = "Полное по источнику",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE] = "Эфф. по источнику",

    [BATTLESCROLLS_STAT_DIRECT_HEALING] = "Прямое исцеление",
    [BATTLESCROLLS_STAT_HEALING_OVER_TIME] = "Периодическое исцеление",

    -------------------------
    -- Effects Stats
    -------------------------
    [BATTLESCROLLS_HEADER_YOUR_BUFFS] = "Ваши баффы",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON_YOU] = "Дебаффы на вас",
    [BATTLESCROLLS_HEADER_BUFFS_ON_GROUP] = "Баффы на группе",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON] = "Дебаффы на <<1>>",

    [BATTLESCROLLS_EFFECT_UPTIME] = "активность",
    [BATTLESCROLLS_EFFECT_YOURS] = "ваш",
    [BATTLESCROLLS_EFFECT_AVG] = "средн.",
    [BATTLESCROLLS_EFFECT_MEMBERS] = "участников",

    -------------------------
    -- Effect Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL_UPTIME] = "Общая активность",
    [BATTLESCROLLS_TOOLTIP_TOTAL_APPLICATIONS] = "Всего применений",
    [BATTLESCROLLS_TOOLTIP_YOUR_CONTRIBUTION] = "Ваш вклад",
    [BATTLESCROLLS_TOOLTIP_YOUR_UPTIME] = "Активность",
    [BATTLESCROLLS_TOOLTIP_YOUR_APPLICATIONS] = "Применений",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS] = "Максимум зарядов",
    [BATTLESCROLLS_TOOLTIP_TIME_AT_MAX_STACKS] = "Время на максимальных зарядах",
    [BATTLESCROLLS_TOOLTIP_YOUR_TIME_AT_MAX] = "Ваше время на максимальных зарядах",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_MEMBER] = "Средняя активность на участника",
    [BATTLESCROLLS_TOOLTIP_MEMBERS_AFFECTED] = "Затронуто участников",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME] = "Средняя активность",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS_OBSERVED] = "Максимум наблюдаемых зарядов",
    [BATTLESCROLLS_TOOLTIP_AVG_TIME_AT_MAX] = "Среднее время на максимальных зарядах",
    [BATTLESCROLLS_TOOLTIP_YOUR_AVG_TIME_AT_MAX] = "Ваше среднее время на максимальных зарядах",
    [BATTLESCROLLS_TOOLTIP_PEAK_INSTANCES] = "Максимум одновременных источников",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_INSTANCE] = "Средняя активность на источник",
    [BATTLESCROLLS_TOOLTIP_PER_MEMBER] = "По участникам",
    [BATTLESCROLLS_TOOLTIP_YOU] = "Вы",

    -------------------------
    -- Ability Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL] = "Всего",
    [BATTLESCROLLS_TOOLTIP_TYPE] = "Тип",
    [BATTLESCROLLS_TOOLTIP_DELIVERY] = "Способ",
    [BATTLESCROLLS_TOOLTIP_CRIT] = "Крит",
    [BATTLESCROLLS_TOOLTIP_AVG_TICK] = "Средний тик",
    [BATTLESCROLLS_TOOLTIP_MIN_TICK] = "Минимальный тик",
    [BATTLESCROLLS_TOOLTIP_MAX_TICK] = "Максимальный тик",

    [BATTLESCROLLS_TOOLTIP_BY_TARGET] = "По цели",
    [BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL] = "Средний интервал",
    [BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL] = "Медианный интервал",

    [BATTLESCROLLS_TOOLTIP_ABILITY] = "Способность",

    -------------------------
    -- Damage Types
    -------------------------
    [BATTLESCROLLS_DAMAGE_TYPE_NONE] = "Нет",
    [BATTLESCROLLS_DAMAGE_TYPE_GENERIC] = "Обычный",
    [BATTLESCROLLS_DAMAGE_TYPE_PHYSICAL] = "Физический",
    [BATTLESCROLLS_DAMAGE_TYPE_FIRE] = "Огненный",
    [BATTLESCROLLS_DAMAGE_TYPE_SHOCK] = "Электрический",
    [BATTLESCROLLS_DAMAGE_TYPE_OBLIVION] = "Обливион",
    [BATTLESCROLLS_DAMAGE_TYPE_FROST] = "Морозный",
    [BATTLESCROLLS_DAMAGE_TYPE_EARTH] = "Земляной",
    [BATTLESCROLLS_DAMAGE_TYPE_MAGIC] = "Магический",
    [BATTLESCROLLS_DAMAGE_TYPE_DROWN] = "Утопление",
    [BATTLESCROLLS_DAMAGE_TYPE_DISEASE] = "Болезнетворный",
    [BATTLESCROLLS_DAMAGE_TYPE_POISON] = "Ядовитый",
    [BATTLESCROLLS_DAMAGE_TYPE_BLEED] = "Кровотечение",

    -------------------------
    -- Over Time/Direct Descriptions
    -------------------------
    [BATTLESCROLLS_DELIVERY_MIXED] = "Смешанный",
    [BATTLESCROLLS_DELIVERY_DOT] = "Периодический",
    [BATTLESCROLLS_DELIVERY_DIRECT] = "Прямой",
    [BATTLESCROLLS_DELIVERY_HOT] = "Периодическое",

    -------------------------
    -- Filter Dialog
    -------------------------
    [BATTLESCROLLS_FILTER_DAMAGE_DONE] = "Фильтр урона",
    [BATTLESCROLLS_FILTER_BOSS_DAMAGE] = "Фильтр урона боссу",
    [BATTLESCROLLS_FILTER_BY_SOURCE] = "Фильтр по источнику",
    [BATTLESCROLLS_FILTER_BY_TARGET] = "Фильтр по цели",
    [BATTLESCROLLS_FILTER_BY_GROUP_MEMBER] = "Фильтр по группе",
    [BATTLESCROLLS_FILTER] = "Фильтр",
    [BATTLESCROLLS_FILTER_ACTIVE] = "Фильтр (Активен)",
    [BATTLESCROLLS_FILTER_RESET] = "Сбросить",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_BY] = "Урон от",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_TO] = "Урон по",
    [BATTLESCROLLS_FILTER_BOSS_TARGET] = "Босс",

    -------------------------
    -- Encounter Display
    -------------------------
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN_WITH] = "<<Cl:1>>: <<2>>",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_WITH] = "<<1>>",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN] = "<<Cl:1>>",
    [BATTLESCROLLS_ENCOUNTER_COMBAT] = "Сражение",
    [BATTLESCROLLS_ENCOUNTER_MULTIPLE_ENEMIES] = "<<1>> (x<<2>>)",
    [BATTLESCROLLS_ENCOUNTER_INTO_INSTANCE] = "с начала",
    [BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX] = "(Вы)",

    -------------------------
    -- List States
    -------------------------
    [BATTLESCROLLS_LIST_LOADING] = "Загрузка",
    [BATTLESCROLLS_LIST_NO_DATA] = "Нет записанных сражений",
    [BATTLESCROLLS_LIST_NO_ENCOUNTERS] = "Нет сражений",
    [BATTLESCROLLS_LIST_NO_STATS] = "Нет доступной статистики",
    [BATTLESCROLLS_LIST_NO_SETTINGS] = "Нет доступных настроек",

    -------------------------
    -- LibHarvensAddonSettings Integration
    -------------------------
    [BATTLESCROLLS_LIBHARVENS_OPEN_BUTTON] = "Открыть Боевые Свитки",
    [BATTLESCROLLS_LIBHARVENS_TOOLTIP] = "Боевые Свитки также доступны из меню «<<1>>».",

    -------------------------
    -- Misc
    -------------------------
    [BATTLESCROLLS_UNKNOWN] = "Неизвестно",
    [BATTLESCROLLS_UNKNOWN_BOSS] = "Неизвестный босс",

    -------------------------
    -- Personal Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_PERSONAL_DEFAULT] = "Стандартный",
    [BATTLESCROLLS_DESIGN_PERSONAL_MINIMAL] = "Минималистичный",
    [BATTLESCROLLS_DESIGN_PERSONAL_BAR] = "Шкала",

    -- Bar design settings
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION] = "Направление шкалы",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_RIGHT] = "Вправо",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_LEFT] = "Влево",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_CENTER] = "Двустороннее",

    -------------------------
    -- Group Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_GROUP_TEXT] = "Текст",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR] = "Hodor",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR_DESC] = "Почти как Hodor Reflexes от @andy.s и @m00nyONE.",
    [BATTLESCROLLS_DESIGN_GROUP_BARS] = "Шкалы",
    [BATTLESCROLLS_DESIGN_GROUP_BARS_DESC] = "Слегка напоминает Hodor Restyle от Hyperioxes.",

    -- Text design settings
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS] = "Столбцы",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TITLE] = "Расположение столбцов",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TEXT] = "Группы из 4 или менее участников всегда используют 1 столбец.",

    -------------------------
    -- DPS Meter Display Strings
    -- Note: DPS/HPS are universal gaming terms, hardcoded in code
    -------------------------
    [BATTLESCROLLS_METER_EFFECTIVE] = "эффект.",
    [BATTLESCROLLS_METER_EFF] = "эфф.",
    [BATTLESCROLLS_METER_BOSS] = "Босс",
    [BATTLESCROLLS_METER_ALL] = "Всего",
    [BATTLESCROLLS_METER_ALL_DAMAGE] = "Весь урон",
    [BATTLESCROLLS_METER_TOTAL] = "Итого",
    [BATTLESCROLLS_METER_BOSS_ALL_DAMAGE] = "Урон боссу / Весь урон",
    [BATTLESCROLLS_METER_EFFECTIVE_RAW_HEALING] = "Эффект. / Полное исцеление",

    -- Overview Panel Q3/Q4 Headers
    [BATTLESCROLLS_OVERVIEW_TOP_ABILITIES] = "Топ способности",
    [BATTLESCROLLS_OVERVIEW_BOSSES] = "Боссы",
    [BATTLESCROLLS_OVERVIEW_TARGETS] = "Цели",
    [BATTLESCROLLS_OVERVIEW_SOURCES] = "Источники",
    [BATTLESCROLLS_OVERVIEW_TARGETS_HEALED] = "Исцелённые",
    [BATTLESCROLLS_OVERVIEW_HEALERS] = "Целители",
    [BATTLESCROLLS_OVERVIEW_GROUP_BUFFS] = "Баффы группы",
    [BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS] = "Дебаффы на боссе",

    -- Group Stats
    [BATTLESCROLLS_GROUP_DAMAGE] = "Урон группы",
    [BATTLESCROLLS_GROUP_BOSS_DAMAGE] = "Урон группы боссу",
    [BATTLESCROLLS_GROUP_DPS] = "DPS группы",
    [BATTLESCROLLS_GROUP_BOSS_DPS] = "DPS группы по боссу",
    [BATTLESCROLLS_STAT_GROUP_DAMAGE] = "Урон группы",
    [BATTLESCROLLS_STAT_GROUP_DPS] = "DPS группы",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE] = "Урон группы боссу",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DPS] = "DPS группы по боссу",

    -- Overview Panel - Ability Stats
    [BATTLESCROLLS_STAT_MAX_PREFIX] = "Макс: <<1>>",
    [BATTLESCROLLS_STAT_CRIT_PERCENT] = "<<1>>% крит",
    [BATTLESCROLLS_STAT_PER_SECOND] = "<<1>>/с",

    -- Overview Panel - Effect Stats
    [BATTLESCROLLS_EFFECT_APPS_COUNT] = "<<1>> прим.",
    [BATTLESCROLLS_EFFECT_YOURS_PERCENT] = "<<1>>% ваш",
    [BATTLESCROLLS_EFFECT_STACKS_COUNT] = "×<<1>> ст.",

    -- Overview Panel Summary
    [BATTLESCROLLS_OVERVIEW_ENCOUNTER] = "Бой",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT] = "Нанесённый урон",
    [BATTLESCROLLS_OVERVIEW_SUMMARY] = "Сводка",
    [BATTLESCROLLS_OVERVIEW_TOTAL] = "Всего",
    [BATTLESCROLLS_OVERVIEW_SHARE] = "Доля",
    [BATTLESCROLLS_OVERVIEW_COMPOSITION] = "Состав",
    [BATTLESCROLLS_OVERVIEW_QUALITY] = "Качество",
    [BATTLESCROLLS_OVERVIEW_CRIT_RATE] = "Шанс крита",
    [BATTLESCROLLS_OVERVIEW_MAX_HIT] = "Макс. удар",
    [BATTLESCROLLS_OVERVIEW_MAX_HEAL] = "Макс. исцеление",
    [BATTLESCROLLS_OVERVIEW_EFFICIENCY] = "Эффективность",
    [BATTLESCROLLS_OVERVIEW_KEY_BUFFS] = "Ваши баффы",
    [BATTLESCROLLS_OVERVIEW_KEY_DEBUFFS] = "Ключевые дебаффы",
    [BATTLESCROLLS_OVERVIEW_UPTIMES] = "Время действия",
    [BATTLESCROLLS_OVERVIEW_NO_EFFECTS] = "Нет записанных эффектов",

    -- Overview Panel Short Labels
    [BATTLESCROLLS_BOSS_DAMAGE] = "Урон боссу",
    [BATTLESCROLLS_DAMAGE_DONE] = "Нанесённый урон",
    [BATTLESCROLLS_HEALING_OUT] = "Исходящее исцеление",
    [BATTLESCROLLS_SELF_HEALING] = "Самоисцеление",
    [BATTLESCROLLS_HEALING_IN] = "Входящее исцеление",
    [BATTLESCROLLS_AOE] = "По площади",
    [BATTLESCROLLS_SINGLE_TARGET] = "Одиночная цель",
    [BATTLESCROLLS_HEALING_RAW_HPS] = "Полный HPS",
    [BATTLESCROLLS_HEALING_EFFECTIVE_HPS] = "Эффективный HPS",
    [BATTLESCROLLS_HEALING_OVERHEAL] = "Переисцеление",
    [BATTLESCROLLS_TOOLTIP_DURATION] = "Длительность",

    -------------------------
    -- LibAsync Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_PERFORMANCE] = "Производительность",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED] = "Скорость обработки",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_PERFORMANCE] = "Производительность",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_BALANCED] = "Сбалансировано",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_SMOOTH] = "Плавность",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM] = "Другое (<<1>> FPS)",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE] = "Скорость обработки",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "Настройка скорости обработки фоновых задач. Влияет в основном на интерфейс Журнала и время между окончанием боя и появлением записи в списке.\n\nПроизводительность: Быстрая обработка. Возможны кратковременные подлагивания.\nСбалансировано: Хороший баланс скорости и плавности.\nПлавность: Плавный геймплей, медленная обработка.\n\nВлияет на ВСЕ аддоны, использующие LibAsync.",

    -------------------------
    -- Onboarding
    -------------------------
    [BATTLESCROLLS_ONBOARDING_WELCOME_TITLE] = "Добро пожаловать в Боевые Свитки",
    [BATTLESCROLLS_ONBOARDING_WELCOME_TEXT] = "Боевые Свитки записывают ваши бои и позволяют просматривать их позже в Журнале.\n\nВозможности:\n- Счётчики DPS/HPS в реальном времени\n- Детальная разбивка урона и исцеления\n- Отслеживание аптайма баффов/дебаффов\n- Мониторинг дебаффов на боссах\n\nДавайте настроим несколько параметров.",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED] = "Начать",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED_DESC] = "Пройти все шаги настройки",
    [BATTLESCROLLS_ONBOARDING_SKIP] = "Пропустить",
    [BATTLESCROLLS_ONBOARDING_SKIP_DESC] = "Разберёмся. Использовать рекомендуемые настройки.",
    [BATTLESCROLLS_ONBOARDING_METER_QUESTION] = "Выберите стиль счётчика:",
    -- Meter presets
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL] = "Минималистичный",
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL_DESC] = "Компактный личный счётчик в углу экрана",
    [BATTLESCROLLS_PRESET_FULL_STACKED] = "Личный + Группа",
    [BATTLESCROLLS_PRESET_FULL_STACKED_DESC] = "Личный счётчик с рейтингом группы снизу",
    [BATTLESCROLLS_PRESET_HODOR] = "Стиль Hodor",
    [BATTLESCROLLS_PRESET_HODOR_DESC] = "Только групповой, почти как Hodor Reflexes (@andy.s, @m00nyONE)",
    [BATTLESCROLLS_PRESET_BAR] = "Шкала",
    [BATTLESCROLLS_PRESET_BAR_DESC] = "Шкала прогресса для личного DPS",
    [BATTLESCROLLS_PRESET_COLORFUL] = "Цветные шкалы",
    [BATTLESCROLLS_PRESET_COLORFUL_DESC] = "Цветные шкалы для личного и группового DPS, групповой слегка напоминает Hodor Restyle (Hyperioxes)",
    [BATTLESCROLLS_PRESET_DISABLED] = "Отключено",
    [BATTLESCROLLS_PRESET_DISABLED_DESC] = "Счётчики отключены, только запись боёв",
    -- Storage options
    [BATTLESCROLLS_ONBOARDING_STORAGE_QUESTION] = "Сколько истории сохранять?",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL] = "Минимум (5 МБ)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC] = "Примерно 6 испытаний",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE] = "Умеренно (12 МБ)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC] = "Примерно 16 испытаний",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS] = "Много (25 МБ)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC] = "Примерно 36 испытаний",
    -- Effects tracking
    [BATTLESCROLLS_ONBOARDING_EFFECTS_QUESTION] = "Сколько баффов/дебаффов отслеживать?",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL] = "Полное отслеживание",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL_DESC] = "Ваши баффы, дебаффы на боссах И аптайм баффов группы (напр. аптайм Великой храбрости у всех участников группы)",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL] = "Только основное",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL_DESC] = "Только ваши баффы и дебаффы на боссах. Без групповых для снижения потребления памяти.",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED] = "Отключено",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED_DESC] = "Без отслеживания баффов/дебаффов. Минимальное потребление памяти, но нет данных об аптайме в отчётах.",
    -- Completion
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TITLE] = "Всё готово!",
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TEXT] = "Боевые Свитки готовы отслеживать ваш бой.\n\nТеперь идите сражаться!\n\nВаши сражения появятся здесь в Журнале. Вы можете изменить настройки в любое время на вкладке Настройки.",
    [BATTLESCROLLS_ONBOARDING_CHAT_MESSAGE] = "[Боевые Свитки] Спасибо за установку! Откройте Журнал > Боевые Свитки для настройки и активации.",
    [BATTLESCROLLS_ONBOARDING_CONTINUE] = "Продолжить",
    [BATTLESCROLLS_ONBOARDING_FINISH] = "Завершить настройку",
    [BATTLESCROLLS_ONBOARDING_LETS_GO] = "Поехали!",
    [BATTLESCROLLS_ONBOARDING_STEP_FORMAT] = "Шаг <<1>> из <<2>>",

    -------------------------
    -- Dynamic Overview Panel
    -------------------------
    [BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN] = "Полученный урон",
    [BATTLESCROLLS_OVERVIEW_TOP_HEALING] = "Топ исцеление",
    [BATTLESCROLLS_OVERVIEW_TOP_INCOMING] = "Топ входящий урон",
    [BATTLESCROLLS_OVERVIEW_HEALING_TARGETS] = "Цели исцеления",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES] = "Источники урона",
}

BS_STRINGS = strings

-- Register translations
for stringId, stringValue in pairs(strings) do
    SafeAddString(stringId, stringValue, 1)
end

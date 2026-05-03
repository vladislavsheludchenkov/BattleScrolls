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
    [BATTLESCROLLS_UI_SWITCH_TO] = "Показать <<1>>",
    [BATTLESCROLLS_STAT_HPS] = "HPS",

    -------------------------
    -- Zone/Instance Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ZONES] = "Все области",
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
    [BATTLESCROLLS_TAB_DAMAGE] = "Урон",
    [BATTLESCROLLS_TAB_HEALING] = "Исцеление",
    [BATTLESCROLLS_TAB_EFFECTS] = "Эффекты",
    [BATTLESCROLLS_TAB_EFFECTS_PLAYER] = "Ваши эффекты",
    [BATTLESCROLLS_TAB_EFFECTS_BOSS] = "Эффекты боссов",
    [BATTLESCROLLS_TAB_EFFECTS_GROUP] = "Эффекты группы",
    [BATTLESCROLLS_TAB_GROUP] = "Группа",
    [BATTLESCROLLS_TAB_ACTIVITY] = "Активность",

    -------------------------
    -- Weaving Stats
    -------------------------
    [BATTLESCROLLS_HEADER_WEAVING] = "Вивинг",
    [BATTLESCROLLS_HEADER_WEAVING_BY_ABILITY] = "Вивинг по способности",
    [BATTLESCROLLS_STAT_AVG_WEAVE_TIME] = "Средняя задержка каста",
    [BATTLESCROLLS_STAT_WEAVE_TIME_BEFORE] = "Время вива до",
    [BATTLESCROLLS_STAT_TIME_LOST] = "Потерянное время",
    [BATTLESCROLLS_STAT_LIGHT_ATTACKS] = "Обычные атаки",
    [BATTLESCROLLS_STAT_HEAVY_ATTACKS] = "Силовые атаки",
    [BATTLESCROLLS_STAT_SKILL_ACTIVATIONS] = "Навыки",
    [BATTLESCROLLS_STAT_CASTS] = "Касты",
    [BATTLESCROLLS_STAT_WEAVING_ERRORS] = "Ошибки вивинга",
    [BATTLESCROLLS_STAT_MISSED_LA] = "Пропущенные обычные атаки",
    [BATTLESCROLLS_STAT_DOUBLE_LA] = "Двойные обычные атаки",
    [BATTLESCROLLS_TOOLTIP_DELAY_AFTER] = "Задержка после каста",
    [BATTLESCROLLS_TOOLTIP_DELAY_BEFORE] = "Задержка до каста",
    [BATTLESCROLLS_FORMAT_SECONDS] = "<<1>>с",
    [BATTLESCROLLS_FORMAT_MILLISECONDS] = "<<1>>мс",
    [BATTLESCROLLS_TOOLTIP_INTER_CAST_DESC] = "Средняя задержка между кастами. Измеряется от окончания ГКД или времени каста навыка до начала следующего действия. Также известна как Weaving Average в CMX.",
    [BATTLESCROLLS_TOOLTIP_TIME_LOST_DESC] = "Суммарное время простоя между кастами за бой. Также известно как Weaving Total в CMX.",
    [BATTLESCROLLS_TOOLTIP_MISSED_LA_DESC] = "Навык активирован сразу после другого навыка, без обычной атаки между ними.",
    [BATTLESCROLLS_TOOLTIP_DOUBLE_LA_DESC] = "Две обычные атаки подряд, без навыка между ними.",

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
    [BATTLESCROLLS_SETTINGS_RECORD_IN_ADVENTURE_ZONE_TEXT] = "Если включено, игнорирует настройки для открытого мира и инстансов и записывает все сражения в этой зоне. Если выключено, ни на что не влияет.",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE] = "Фильтры записи",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT] = "Фильтры областей и типов сражений комбинируются: сражение должно соответствовать хотя бы одной области И одному типу для записи.",

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
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC] = "Сколько истории боёв хранить. При превышении лимита старые незаблокированные области удаляются автоматически. Вы можете заблокировать отдельные области, чтобы защитить их от очистки.",
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
    [BATTLESCROLLS_STAT_PATCH] = "Обновление",
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
    [BATTLESCROLLS_STAT_TOTAL_PROCS] = "<<1[$d активация/$d активации/$d активаций]>>",
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

    [BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT] = "Полное по типу",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT] = "Эфф. по типу",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET] = "Полное по цели",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY] = "Полное по способности",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET] = "Эфф. по цели",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY] = "Эфф. по способности",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE] = "Полное по источнику",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE] = "Эфф. по источнику",

    [BATTLESCROLLS_STAT_DIRECT_HEALING] = "Прямое исцеление",
    [BATTLESCROLLS_STAT_HEALING_OVER_TIME] = "Периодическое исцеление",
    [BATTLESCROLLS_STAT_SHIELD_HEALING] = "Щиты урона",

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
    [BATTLESCROLLS_EFFECT_MEMBERS] = "<<1[$d участник/$d участника/$d участников]>>",

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
    [BATTLESCROLLS_TOOLTIP_ABILITY_ID] = "ID способности",

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
    [BATTLESCROLLS_DELIVERY_SHIELD] = "Щит",

    -------------------------
    -- Filter Dialog
    -------------------------
    [BATTLESCROLLS_FILTER_DAMAGE_DONE] = "Фильтр урона",
    [BATTLESCROLLS_FILTER_BOSS_DAMAGE] = "Фильтр урона боссу",
    [BATTLESCROLLS_FILTER_BY_SOURCE] = "Фильтр по источнику",
    [BATTLESCROLLS_FILTER_BY_TARGET] = "Фильтр по цели",
    [BATTLESCROLLS_FILTER_BY_GROUP_MEMBER] = "Фильтр по группе",
    [BATTLESCROLLS_FILTER] = "Фильтр",
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
    [BATTLESCROLLS_OVERVIEW_BOSS_DAMAGE] = "Урон по боссу",
    [BATTLESCROLLS_STAT_GROUP_DAMAGE] = "Урон группы",
    [BATTLESCROLLS_STAT_GROUP_DPS] = "DPS группы",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE] = "Урон группы боссу",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DPS] = "DPS группы по боссу",

    -- Overview Panel - Ability Stats
    [BATTLESCROLLS_STAT_MAX_PREFIX] = "Макс: <<1>>",
    [BATTLESCROLLS_STAT_CRIT_PERCENT] = "<<1>>% крит",
    [BATTLESCROLLS_STAT_PER_SECOND] = "<<1>>/с",

    -- Overview Panel - Effect Stats
    [BATTLESCROLLS_EFFECT_APPS_COUNT] = "<<1[$d применение/$d применения/$d применений]>>",
    [BATTLESCROLLS_EFFECT_YOURS_PERCENT] = "<<1>>% ваш",
    [BATTLESCROLLS_EFFECT_STACKS_COUNT] = "×<<1[$d заряд/$d заряда/$d зарядов]>>",

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
    [BATTLESCROLLS_OVERVIEW_KEY_BUFFS] = "Ваши баффы",
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
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_SMOOTH] = "Плавность",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM] = "Другое (<<1>> FPS)",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE] = "Скорость обработки",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "Настройка скорости обработки фоновых задач. Влияет в основном на интерфейс Журнала и время между окончанием боя и появлением записи в списке.\n\nПроизводительность: Быстрая обработка. Возможны кратковременные подлагивания.\nПлавность: Более плавный геймплей, медленная обработка. Записи могут зависать при загрузке или не появляться в Журнале.\n\nВлияет на ВСЕ аддоны, использующие LibAsync.",

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
    -- Delete Functionality
    -------------------------
    [BATTLESCROLLS_DELETE] = "Удалить",
    [BATTLESCROLLS_DELETE_INSTANCE_TITLE] = "Удалить область",
    [BATTLESCROLLS_DELETE_INSTANCE_TEXT] = "Удалить <<1>> и все её сражения?",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TITLE] = "Удалить сражение",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TEXT] = "Удалить <<1>>?",
    [BATTLESCROLLS_DELETE_WARNING] = "Это действие нельзя отменить.",
    [BATTLESCROLLS_DELETE_MEMORY_FREE] = "Освободится примерно <<1>>",
    [BATTLESCROLLS_DELETE_MEMORY_STATUS] = "Память: <<1>> из <<2>> (<<3>>%)",

    -------------------------
    -- Dynamic Overview Panel
    -------------------------
    [BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN] = "Полученный урон",
    [BATTLESCROLLS_OVERVIEW_TOP_HEALING] = "Топ исцеление",
    [BATTLESCROLLS_OVERVIEW_TOP_INCOMING] = "Топ входящий урон",
    [BATTLESCROLLS_OVERVIEW_HEALING_TARGETS] = "Цели исцеления",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES] = "Источники урона",

    -------------------------
    -- Instance Locking
    -------------------------
    [BATTLESCROLLS_LOCK_ERROR_TITLE] = "Невозможно заблокировать",
    [BATTLESCROLLS_LOCK_ERROR_TEXT] = "Блокировка этой области превысит лимит памяти. Заблокированные области и последняя область защищены от очистки.\n\nЧтобы освободить место, разблокируйте или удалите некоторые заблокированные области, или увеличьте лимит памяти в настройках.",
    [BATTLESCROLLS_LOCK_LOCKED_SIZE] = "Заблокировано: <<1>>",
    [BATTLESCROLLS_LOCK_INSTANCE_SIZE] = "Эта область: <<1>>",
    [BATTLESCROLLS_LOCK_LIMIT] = "Лимит памяти: <<1>>",

    -------------------------
    -- Favorite Effects
    -------------------------
    [BATTLESCROLLS_FAVORITE_EFFECT] = "В избранное",
    [BATTLESCROLLS_UNFAVORITE_EFFECT] = "Убрать из избранного",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES] = "Очистить все избранное",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES_TOOLTIP] = "Удалить все избранные эффекты. Избранные эффекты отображаются в верхней части каждого списка эффектов.",

    -------------------------
    -- Group Tab Enhancements
    -------------------------
    [BATTLESCROLLS_STAT_SURVIVABILITY] = "Выживаемость",
    [BATTLESCROLLS_BOSS_DAMAGE_TAKEN] = "Урон от босса",

    -- Group Member Card Strings
    [BATTLESCROLLS_GROUP_CARD_OF_GROUP] = "от группы",
    [BATTLESCROLLS_GROUP_CARD_ALIVE] = "Живой",

    -- Group Tab Redesign
    [BATTLESCROLLS_GROUP_DAMAGE_BY_TYPE] = "Урон по типу",
    [BATTLESCROLLS_GROUP_VS_AVERAGE] = "от среднего DD",
    [BATTLESCROLLS_GROUP_DD_COUNTED] = "DD учтено",
    [BATTLESCROLLS_GROUP_DAMAGE_OUTPUT] = "Нанесённый урон",
    [BATTLESCROLLS_GROUP_HEALING_OUTPUT] = "Исцеление",
    [BATTLESCROLLS_GROUP_RANK] = "Место",
    [BATTLESCROLLS_GROUP_MAGICAL] = "Магический",
    [BATTLESCROLLS_GROUP_DEATH] = "Смерть",
    [BATTLESCROLLS_GROUP_FIRST_DEATH] = "Первая смерть",
    [BATTLESCROLLS_GROUP_LAST_DEATH] = "Последняя смерть",
    [BATTLESCROLLS_GROUP_DEATHS] = "Смерти",
    [BATTLESCROLLS_GROUP_COL_DEATHS] = "Смерти",
    [BATTLESCROLLS_GROUP_DEATH_COUNT] = "<<1[$d смерть/$d смерти/$d смертей]>>",
    [BATTLESCROLLS_GROUP_METRIC_DPS] = "<<1>> DPS",
    [BATTLESCROLLS_GROUP_METRIC_HPS] = "<<1>> HPS",
    [BATTLESCROLLS_GROUP_METRIC_DTPS] = "<<1>> DTPS",
    [BATTLESCROLLS_GROUP_METRIC_CRIT] = "<<1>>% крит",
    [BATTLESCROLLS_GROUP_METRIC_OVERHEAL] = "<<1>>% переисцеление",
    [BATTLESCROLLS_GROUP_TOP_INCOMING_DAMAGE] = "Топ входящего урона",
    [BATTLESCROLLS_GROUP_DEATH_AT] = "на <<1>>",
    [BATTLESCROLLS_HEADER_DEATHS] = "Смерти",
    [BATTLESCROLLS_STAT_DEATH_COUNT] = "Число смертей",
    [BATTLESCROLLS_DEATH_N] = "Смерть <<1>>",

    -- Group Context Tooltips
    [BATTLESCROLLS_TOOLTIP_GROUP_TOTAL] = "Итого по группе",
    [BATTLESCROLLS_TOOLTIP_GROUP_DPS] = "DPS группы",
    [BATTLESCROLLS_TOOLTIP_GROUP_AVG] = "Среднее DD",
    [BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN] = "Разбивка по группе",
    [BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_TAKEN] = "Полученный урон группы",

    -- Group Table
    [BATTLESCROLLS_GROUP_COL_NAME] = "Имя",
    [BATTLESCROLLS_GROUP_COL_TOTAL] = "Всего",
    [BATTLESCROLLS_GROUP_COL_CRIT] = "Крит",
    [BATTLESCROLLS_GROUP_COL_ALIVE] = "Жив",

    -------------------------
    -- Setup Tab
    -------------------------
    [BATTLESCROLLS_TAB_BUILD] = "Сборка",
    [BATTLESCROLLS_SETUP_ABILITIES] = "Способности",
    [BATTLESCROLLS_SETUP_FRONT_BAR] = "Основная панель",
    [BATTLESCROLLS_SETUP_BACK_BAR] = "Вторая панель",
    [BATTLESCROLLS_SETUP_GEAR_SETS] = "Наборы снаряжения",
    [BATTLESCROLLS_SETUP_EQUIPMENT] = "Снаряжение",
    [BATTLESCROLLS_SETUP_POISONS] = "Яды",
    [BATTLESCROLLS_SETUP_CHARACTER] = "Персонаж",
    [BATTLESCROLLS_SETUP_CLASS_SKILLS] = "Классовые навыки",
    [BATTLESCROLLS_SETUP_MUNDUS] = "Мундус",
    [BATTLESCROLLS_SETUP_FOOD] = "Еда",
    [BATTLESCROLLS_WEAPON_GREATSWORD] = "Двуручный меч",
    [BATTLESCROLLS_WEAPON_BATTLE_AXE] = "Секира",
    [BATTLESCROLLS_WEAPON_MAUL] = "Палица",

    -------------------------
    -- Food Buff Descriptions
    -------------------------
    [BATTLESCROLLS_FOOD_MAX_HEALTH] = "Максимальное здоровье",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA] = "Максимальная магия",
    [BATTLESCROLLS_FOOD_MAX_STAMINA] = "Максимальный запас сил",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_MAGICKA] = "Максимальные здоровье и магия",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_STAMINA] = "Максимальные здоровье и запас сил",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA_STAMINA] = "Максимальные магия и запас сил",
    [BATTLESCROLLS_FOOD_MAX_TRISTAT] = "Максимальные здоровье, магия и запас сил",
    [BATTLESCROLLS_FOOD_HEALTH_RECOVERY] = "Восстановление здоровья",
    [BATTLESCROLLS_FOOD_MAGICKA_RECOVERY] = "Восстановление магии",
    [BATTLESCROLLS_FOOD_STAMINA_RECOVERY] = "Восстановление запаса сил",
    [BATTLESCROLLS_FOOD_HEALTH_MAGICKA_RECOVERY] = "Восстановление здоровья и магии",
    [BATTLESCROLLS_FOOD_HEALTH_STAMINA_RECOVERY] = "Восстановление здоровья и запаса сил",
    [BATTLESCROLLS_FOOD_MAGICKA_STAMINA_RECOVERY] = "Восстановление магии и запаса сил",
    [BATTLESCROLLS_FOOD_RECOVERY_TRISTAT] = "Восстановление здоровья, магии и запаса сил",

    -------------------------
    -- Alchemy Traits
    -------------------------
    [BATTLESCROLLS_ALCHEMY_TRAIT1] = "Восстановление здоровья",
    [BATTLESCROLLS_ALCHEMY_TRAIT2] = "Опустошение здоровья",
    [BATTLESCROLLS_ALCHEMY_TRAIT3] = "Восстановление магии",
    [BATTLESCROLLS_ALCHEMY_TRAIT4] = "Опустошение магии",
    [BATTLESCROLLS_ALCHEMY_TRAIT5] = "Восстановление запаса сил",
    [BATTLESCROLLS_ALCHEMY_TRAIT6] = "Опустошение запаса сил",
    [BATTLESCROLLS_ALCHEMY_TRAIT7] = "Увеличение магической сопротивляемости",
    [BATTLESCROLLS_ALCHEMY_TRAIT8] = "Прорыв",
    [BATTLESCROLLS_ALCHEMY_TRAIT9] = "Увеличение показателя брони",
    [BATTLESCROLLS_ALCHEMY_TRAIT10] = "Перелом",
    [BATTLESCROLLS_ALCHEMY_TRAIT11] = "Увеличение силы заклинаний",
    [BATTLESCROLLS_ALCHEMY_TRAIT12] = "Трусость",
    [BATTLESCROLLS_ALCHEMY_TRAIT13] = "Увеличение силы оружия",
    [BATTLESCROLLS_ALCHEMY_TRAIT14] = "Травма",
    [BATTLESCROLLS_ALCHEMY_TRAIT15] = "Крит. рейтинг заклинаний",
    [BATTLESCROLLS_ALCHEMY_TRAIT16] = "Неуверенность",
    [BATTLESCROLLS_ALCHEMY_TRAIT17] = "Крит. рейтинг оружия",
    [BATTLESCROLLS_ALCHEMY_TRAIT18] = "Бессилие",
    [BATTLESCROLLS_ALCHEMY_TRAIT19] = "Неудержимость",
    [BATTLESCROLLS_ALCHEMY_TRAIT20] = "Захват",
    [BATTLESCROLLS_ALCHEMY_TRAIT21] = "Обнаружение",
    [BATTLESCROLLS_ALCHEMY_TRAIT22] = "Невидимость",
    [BATTLESCROLLS_ALCHEMY_TRAIT23] = "Скорость",
    [BATTLESCROLLS_ALCHEMY_TRAIT24] = "Замедление",
    [BATTLESCROLLS_ALCHEMY_TRAIT25] = "Защита",
    [BATTLESCROLLS_ALCHEMY_TRAIT26] = "Уязвимость",
    [BATTLESCROLLS_ALCHEMY_TRAIT27] = "Длительное исцеление",
    [BATTLESCROLLS_ALCHEMY_TRAIT28] = "Постепенное опустошение здоровья",
    [BATTLESCROLLS_ALCHEMY_TRAIT29] = "Живучесть",
    [BATTLESCROLLS_ALCHEMY_TRAIT30] = "Осквернение",
    [BATTLESCROLLS_ALCHEMY_TRAIT31] = "Героизм",
    [BATTLESCROLLS_ALCHEMY_TRAIT32] = "Трусливость",

    -------------------------
    -- Aggregate
    -------------------------
    -- Navigation
    [BATTLESCROLLS_PIVOT_TITLE] = "Аналитика",
    [BATTLESCROLLS_PIVOT_ENTRY] = "Аналитика",
    [BATTLESCROLLS_PIVOT_ENTRY_DESC] = "Анализ данных по нескольким сражениям и инстансам",
    [BATTLESCROLLS_PIVOT_ENTRY_DESC_ENCOUNTER] = "Анализ данных по сражениям в этом инстансе",

    -- Scope section
    [BATTLESCROLLS_PIVOT_SCOPE] = "Выборка",
    [BATTLESCROLLS_PIVOT_INSTANCE_SCOPE] = "Тип контента",
    [BATTLESCROLLS_PIVOT_TIME_FILTER] = "Время",
    [BATTLESCROLLS_PIVOT_ENCOUNTER_FILTER] = "Фильтр сражений",

    -- Instance scope options
    [BATTLESCROLLS_PIVOT_SCOPE_EVERYTHING] = "Всё",
    [BATTLESCROLLS_PIVOT_SCOPE_INSTANCED] = "Все инстансы",
    [BATTLESCROLLS_PIVOT_SCOPE_OVERLAND] = "Весь открытый мир",
    [BATTLESCROLLS_PIVOT_SCOPE_HOUSES] = "Все дома",
    [BATTLESCROLLS_PIVOT_SCOPE_PVP] = "Весь PvP",
    [BATTLESCROLLS_PIVOT_SCOPE_ZONES] = "По названию зоны",
    [BATTLESCROLLS_PIVOT_SCOPE_SPECIFIC] = "Конкретные инстансы",

    -- Time filter options
    [BATTLESCROLLS_PIVOT_TIME_ALL] = "Всё время",
    [BATTLESCROLLS_PIVOT_TIME_TODAY] = "Сегодня",
    [BATTLESCROLLS_PIVOT_TIME_24H] = "Последние 24 часа",
    [BATTLESCROLLS_PIVOT_TIME_3D] = "Последние 3 дня",
    [BATTLESCROLLS_PIVOT_TIME_7D] = "Последние 7 дней",
    [BATTLESCROLLS_PIVOT_TIME_14D] = "Последние 14 дней",
    [BATTLESCROLLS_PIVOT_TIME_30D] = "Последние 30 дней",
    [BATTLESCROLLS_PIVOT_TIME_90D] = "Последние 90 дней",
    [BATTLESCROLLS_PIVOT_TIME_CUSTOM] = "Другое...",

    -- Encounter category options
    [BATTLESCROLLS_PIVOT_ENC_ALL] = "Все сражения",
    [BATTLESCROLLS_PIVOT_ENC_BOSS] = "Сражения с боссами",
    [BATTLESCROLLS_PIVOT_ENC_TRASH] = "Сражения с мобами",
    [BATTLESCROLLS_PIVOT_ENC_PLAYER] = "PvP-сражения",
    [BATTLESCROLLS_PIVOT_ENC_DUMMY] = "Сражения с манекеном",
    [BATTLESCROLLS_PIVOT_ENC_SPECIFIC] = "Конкретные сражения",

    -- Query section
    [BATTLESCROLLS_PIVOT_QUERY] = "Запрос",
    [BATTLESCROLLS_PIVOT_DOMAIN] = "Тип данных",
    [BATTLESCROLLS_PIVOT_ROWS] = "Строки",
    [BATTLESCROLLS_PIVOT_COLUMNS] = "Столбцы",
    [BATTLESCROLLS_PIVOT_VALUES] = "Значения",
    [BATTLESCROLLS_PIVOT_AGGREGATION] = "Агрегация",
    [BATTLESCROLLS_PIVOT_FILTERS] = "Фильтры",

    -- Target filter
    [BATTLESCROLLS_PIVOT_TARGETS] = "Цели",
    [BATTLESCROLLS_PIVOT_TARGETS_ALL] = "Все цели",
    [BATTLESCROLLS_PIVOT_TARGETS_BOSSES] = "Только боссы",

    -- Domain names
    [BATTLESCROLLS_PIVOT_DOMAIN_DAMAGE] = "Урон",
    [BATTLESCROLLS_PIVOT_DOMAIN_HEALING_OUT] = "Исходящее исцеление",
    [BATTLESCROLLS_PIVOT_DOMAIN_HEALING_IN] = "Входящее исцеление",
    -- Effects domain labels reuse BATTLESCROLLS_TAB_EFFECTS_* strings
    [BATTLESCROLLS_PIVOT_DOMAIN_GROUP] = "Группа",
    [BATTLESCROLLS_PIVOT_DOMAIN_OVERVIEW] = "Обзор",

    -- Dimension names
    [BATTLESCROLLS_PIVOT_DIM_ABILITY] = "Способность",
    [BATTLESCROLLS_PIVOT_DIM_TARGET] = "Цель",
    [BATTLESCROLLS_PIVOT_DIM_SOURCE] = "Источник",
    [BATTLESCROLLS_PIVOT_DIM_BOSS] = "Босс",
    [BATTLESCROLLS_PIVOT_DIM_DAMAGE_TYPE] = "Тип урона",
    [BATTLESCROLLS_PIVOT_DIM_DELIVERY] = "Способ нанесения",
    [BATTLESCROLLS_PIVOT_DIM_AOE_ST] = "По площади / По цели",
    [BATTLESCROLLS_PIVOT_DIM_BUFF_DEBUFF] = "Бафф / Дебафф",
    [BATTLESCROLLS_PIVOT_DIM_GROUP_MEMBER] = "Участник группы",
    [BATTLESCROLLS_PIVOT_DIM_ROLE] = "Роль",
    [BATTLESCROLLS_PIVOT_DIM_ENCOUNTER] = "Сражение",
    [BATTLESCROLLS_PIVOT_DIM_INSTANCE] = "Инстанс",
    [BATTLESCROLLS_PIVOT_COL_METRICS] = "Метрики",

    -- Metric names
    [BATTLESCROLLS_PIVOT_METRIC_TOTAL_DAMAGE] = "Общий урон",
    [BATTLESCROLLS_PIVOT_METRIC_DPS] = "DPS",
    [BATTLESCROLLS_PIVOT_METRIC_CRIT_PERCENT] = "Крит %",
    [BATTLESCROLLS_PIVOT_METRIC_HIT_COUNT] = "Попадания",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_HIT] = "Макс. удар",
    [BATTLESCROLLS_PIVOT_METRIC_MIN_HIT] = "Мин. удар",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_HIT] = "Средн. удар",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HEALING] = "Эфф. исцеление",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HEALING] = "Полное исцеление",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS] = "Полный HPS",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS] = "Эфф. HPS",
    [BATTLESCROLLS_PIVOT_METRIC_OVERHEAL_PERCENT] = "Переисцеление %",
    [BATTLESCROLLS_PIVOT_METRIC_HEAL_CRIT_PERCENT] = "Крит исцеления %",
    [BATTLESCROLLS_PIVOT_METRIC_HEAL_HIT_COUNT] = "Исцелений",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_HEAL] = "Макс. исцеление",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_HEAL] = "Средн. исцеление",
    [BATTLESCROLLS_PIVOT_METRIC_UPTIME_PERCENT] = "Покрытие %",
    [BATTLESCROLLS_PIVOT_METRIC_PLAYER_UPTIME_PERCENT] = "Ваше покрытие %",
    [BATTLESCROLLS_PIVOT_METRIC_APPLICATIONS] = "Применения",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_STACKS_TIME] = "Время на макс. зарядах %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DPS] = "DPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_BOSS_DPS] = "DPS по боссу",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_TOTAL_DAMAGE] = "Общий урон",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_CRIT_PERCENT] = "Крит %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DOT_PERCENT] = "DoT %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_AOE_PERCENT] = "AoE %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_MAX_HIT] = "Макс. удар",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DTPS] = "DTPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_RAW_HPS] = "Общий HPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_EFFECTIVE_HPS] = "Эффективный HPS",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_OUT] = "Эффективный HPS (исх.)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_OUT] = "Общий HPS (исх.)",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_IN] = "Эффективный HPS (вх.)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_IN] = "Общий HPS (вх.)",
    [BATTLESCROLLS_PIVOT_METRIC_BOSS_DPS] = "DPS по боссу",
    [BATTLESCROLLS_PIVOT_METRIC_BOSS_DAMAGE] = "Урон по боссу",
    [BATTLESCROLLS_PIVOT_METRIC_DTPS] = "DTPS",
    [BATTLESCROLLS_PIVOT_METRIC_DAMAGE_TAKEN] = "Полученный урон",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_ALIVE_PERCENT] = "Жив %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DEATH_COUNT] = "Смерти",
    [BATTLESCROLLS_PIVOT_METRIC_DURATION] = "Длительность",
    [BATTLESCROLLS_PIVOT_METRIC_DEATH_COUNT] = "Смерти",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_WEAVE_TIME] = "Задержка каста",
    [BATTLESCROLLS_PIVOT_METRIC_TIME_LOST] = "Потерянное время",
    [BATTLESCROLLS_PIVOT_METRIC_LIGHT_ATTACKS_PER_SEC] = "ЛА/с",
    [BATTLESCROLLS_PIVOT_METRIC_WEAVING_ERRORS] = "Пропущенные ОА",
    [BATTLESCROLLS_PIVOT_METRIC_DOUBLE_LA_ERRORS] = "Двойные ОА",

    -- Aggregation options
    [BATTLESCROLLS_PIVOT_AGG_SUM] = "Сумма",
    [BATTLESCROLLS_PIVOT_AGG_AVG] = "Среднее",
    [BATTLESCROLLS_PIVOT_AGG_MAX] = "Макс",
    [BATTLESCROLLS_PIVOT_AGG_MIN] = "Мин",

    -- Actions
    [BATTLESCROLLS_PIVOT_RUN] = "Выполнить запрос",
    [BATTLESCROLLS_PIVOT_SAVE] = "Сохранить запрос",
    [BATTLESCROLLS_PIVOT_LOAD] = "Загрузить запрос",
    [BATTLESCROLLS_PIVOT_DELETE_QUERY] = "Удалить запрос",

    -- Loading / Results
    [BATTLESCROLLS_PIVOT_LOADING] = "Загрузка сражений... <<1>> / <<2>>",
    [BATTLESCROLLS_PIVOT_NO_RESULTS] = "Нет данных по вашему запросу",
    [BATTLESCROLLS_PIVOT_NO_ENCOUNTERS] = "Нет сражений, подходящих под фильтры",
    [BATTLESCROLLS_PIVOT_NO_BOSSES] = "Нет боссов, подходящих под фильтры",
    [BATTLESCROLLS_PIVOT_ENCOUNTERS_PROCESSED] = "<<1[$d сражение/$d сражения/$d сражений]>> обработано",
    [BATTLESCROLLS_PIVOT_ROWS_CAPPED] = "Результаты ограничены <<1>> строками",
    [BATTLESCROLLS_PIVOT_COLUMNS_CAPPED] = "Результаты ограничены <<1>> столбцами",
    [BATTLESCROLLS_PIVOT_TIP_DOMAIN_OVERVIEW] = "Сводка по всем данным: урон, исцеление и эффекты. Показывает общие итоги вместо отдельных разбивок.",
    [BATTLESCROLLS_PIVOT_TIP_ENC_BOSS_NAMES] = "Показывает только сражения с выбранными боссами. Имена боссов выбираются на следующем шаге.",
    [BATTLESCROLLS_PIVOT_TIP_DIM_DELIVERY] = "Разделяет данные по способу нанесения: Прямой, DoT (урон с течением времени), HoT (исцеление с течением времени) или Смешанный.",
    [BATTLESCROLLS_PIVOT_TIP_DIM_DAMAGE_TYPE] = "Разделяет данные по типу урона: физический, огонь, молния, лёд, магия, яд, болезнь, кровотечение, Обливион и другие.",
    [BATTLESCROLLS_PIVOT_TIP_DOMAIN_GROUP] = "Боевые показатели каждого участника группы: DPS, общий урон, процент критов. Для времени действия баффов/дебаффов используйте Эффекты группы.",
    [BATTLESCROLLS_PIVOT_TIP_AGGREGATION] = "Как объединяются значения, когда несколько сражений попадают в одну ячейку. Например, средний DPS показывает среднее значение по сражениям, а максимум — лучший бой.",

    -- Save dialog
    [BATTLESCROLLS_PIVOT_SAVE_TITLE] = "Сохранить запрос",
    [BATTLESCROLLS_PIVOT_SAVE_PROMPT] = "Введите название для запроса:",
    [BATTLESCROLLS_PIVOT_SAVE_OVERWRITE] = "Запрос с именем \"<<1>>\" уже существует. Перезаписать?",

    -- Load/delete dialog
    [BATTLESCROLLS_PIVOT_QUERY_SAVED] = "Запрос сохранён как \"<<1>>\"",
    [BATTLESCROLLS_PIVOT_LOAD_TITLE] = "Загрузить запрос",
    [BATTLESCROLLS_PIVOT_DELETE_CONFIRM] = "Удалить запрос \"<<1>>\"?",

    -- Selector dialogs
    [BATTLESCROLLS_PIVOT_SELECT_ZONES] = "Выбрать зоны",
    [BATTLESCROLLS_PIVOT_SELECT_INSTANCES] = "Выбрать инстансы",
    [BATTLESCROLLS_PIVOT_SELECT_ENCOUNTERS] = "Выбрать сражения",
    [BATTLESCROLLS_PIVOT_SELECT_BOSSES] = "Выбрать имена боссов",
    [BATTLESCROLLS_PIVOT_SELECT_METRICS] = "Выбрать метрики",
    [BATTLESCROLLS_PIVOT_SELECTED_COUNT] = "<<1>> выбрано",
    [BATTLESCROLLS_PIVOT_SELECT_ALL] = "Выбрать все",
    [BATTLESCROLLS_PIVOT_DESELECT_ALL] = "Снять все",
    [BATTLESCROLLS_PIVOT_NONE_SELECTED] = "Ничего не выбрано",

    -- Filter/range
    [BATTLESCROLLS_PIVOT_ENC_BOSS_NAMES] = "По имени босса",
    [BATTLESCROLLS_PIVOT_CUSTOM_DAYS] = "За <<1[$d день/$d дня/$d дней]>>",
    [BATTLESCROLLS_PIVOT_CUSTOM_DAYS_PROMPT] = "Количество дней назад",
    [BATTLESCROLLS_PIVOT_CUSTOM_RANGE_TITLE] = "Произвольный период",

    -- Query description
    [BATTLESCROLLS_PIVOT_DESC_BY] = "<<1>> — <<2>>",
    [BATTLESCROLLS_PIVOT_DESC_CROSS] = "× <<1>>",
    [BATTLESCROLLS_PIVOT_DESC_N_METRICS] = "<<1[$d метрика/$d метрики/$d метрик]>>",
}

BS_STRINGS = strings

-- Register translations
for stringId, stringValue in pairs(strings) do
    SafeAddString(stringId, stringValue, 1)
end

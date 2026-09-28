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
    [BATTLESCROLLS_STAT_SKILL_ACTIVATIONS] = "Касты навыков",
    [BATTLESCROLLS_STAT_CASTS] = "Касты",
    [BATTLESCROLLS_STAT_WEAVING_ERRORS] = "Ошибки вивинга",
    [BATTLESCROLLS_STAT_MISSED_LA] = "Пропущенные обычные атаки",
    [BATTLESCROLLS_STAT_DOUBLE_LA] = "Двойные обычные атаки",
    [BATTLESCROLLS_TOOLTIP_DELAY_AFTER] = "Задержка после каста",
    [BATTLESCROLLS_TOOLTIP_DELAY_BEFORE] = "Задержка до каста",
    [BATTLESCROLLS_FORMAT_SECONDS] = "<<1>>с",
    [BATTLESCROLLS_FORMAT_MILLISECONDS] = "<<1>>мс",
    [BATTLESCROLLS_TOOLTIP_INTER_CAST_DESC] = "Средний промежуток между кастами: от конца глобального отката или времени каста навыка до вашего следующего действия. В Combat Metrics это называется Weaving Average.",
    [BATTLESCROLLS_TOOLTIP_TIME_LOST_DESC] = "Сумма коротких задержек между умениями за бой, без пауз от 3 секунд (простой). В Combat Metrics это Weaving Total.",
    [BATTLESCROLLS_TOOLTIP_MISSED_LA_DESC] = "Навыки, применённые сразу после другого навыка, без обычной атаки между ними.",
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
    [BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT] = "Даже если выключено, члены группы всё равно смогут видеть ваш DPS, если у них установлена модификация.",
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
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA_TEXT] = "Если включено, групповой счётчик отображается даже когда другие члены группы не делятся данными. Вы увидите только свою статистику.",
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
    [BATTLESCROLLS_SETTINGS_RECORD_IN_ADVENTURE_ZONE_TEXT] = "Если включено, записывает все сражения в этой области независимо от настроек записи в открытом мире и инстансах. Если выключено, действуют обычные настройки.",
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
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE] = "Этот лимит относится только к сохранённым данным: боям, сборкам и настройкам. Модификация также использует память для отслеживания текущего боя и отрисовки интерфейса, поэтому общее потребление будет выше.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT] = "История: <<1>> МБ из <<2>> МБ (<<3>>%)",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PROTECTED] = "Одни только закреплённые бои, сборки и настройки превышают лимит: очистка не сможет опуститься ниже него.",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS] = "Пресеты (полное испытание ~0.3 МБ, подземелье ~0.15 МБ, вечер прогресса ~1 МБ):",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XS] = "  Минимум: 5 МБ - только свежие свитки",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL] = "  Мало: 8 МБ - добрая стопка свитков",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM] = "  Средне: 12 МБ - аккуратный журнал",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE] = "  Много: 18 МБ - личная библиотека",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XL] = "  Очень много: 25 МБ - целый архив",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION] = "  Осторожно: 35 МБ - вы правда любите данные",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO] = "  Что может пойти не так?: 50 МБ - вы сами себе это устроили",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING] = "О лимитах памяти ESO: все модификации делят пул в 100 МБ. При 70 МБ ESO показывает предупреждение. При 100 МБ интерфейс перезагружается и всё отключается. Если у вас много модификаций, выберите меньший пресет. Совет: введите /addonmemdisplay в чат для отслеживания памяти в реальном времени.",

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

    -------------------------
    -- Damage Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE] = "Общий урон боссу",
    [BATTLESCROLLS_STAT_BOSS_DPS] = "DPS по боссу",
    [BATTLESCROLLS_STAT_GROUP_SHARE] = "Вклад в группе",
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE] = "Общий урон",
    [BATTLESCROLLS_STAT_DPS] = "DPS",

    [BATTLESCROLLS_HEADER_BY_ABILITY] = "По способности",

    [BATTLESCROLLS_HEADER_CASTS] = "Касты",
    [BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE] = "По типу урона",
    [BATTLESCROLLS_HEADER_DIRECT_VS_DOT] = "Прямой / Периодический",
    [BATTLESCROLLS_HEADER_DAMAGE_DELIVERY] = "Способ урона",
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
    [BATTLESCROLLS_STAT_SHIELD_HEALING] = "Защитные щиты",
    [BATTLESCROLLS_STAT_REGEN_HEALING] = "Восстановление здоровья",
    [BATTLESCROLLS_DAMAGE_UNKNOWN_SHIELDED] = "Неизвестно (поглощено щитом)",
    [BATTLESCROLLS_HEALING_UNKNOWN_ABSORBED] = "Неизвестно (поглощено)",
    [BATTLESCROLLS_HEALING_HEALTH_RECOVERY] = "Восстановление здоровья",

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
    [BATTLESCROLLS_EFFECT_MEMBERS] = "<<1[$d член группы/$d члена группы/$d членов группы]>>",

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
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_MEMBER] = "Среднее время действия на члена группы",
    [BATTLESCROLLS_TOOLTIP_MEMBERS_AFFECTED] = "Затронуто членов группы",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME] = "Средняя активность",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS_OBSERVED] = "Максимум наблюдаемых зарядов",
    [BATTLESCROLLS_TOOLTIP_AVG_TIME_AT_MAX] = "Среднее время на максимальных зарядах",
    [BATTLESCROLLS_TOOLTIP_YOUR_AVG_TIME_AT_MAX] = "Ваше среднее время на максимальных зарядах",
    [BATTLESCROLLS_TOOLTIP_PEAK_INSTANCES] = "Максимум одновременных источников",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_INSTANCE] = "Средняя активность на источник",
    [BATTLESCROLLS_TOOLTIP_PER_MEMBER] = "По членам группы",
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
    [BATTLESCROLLS_TOOLTIP_TICKS] = "Тиков",

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
    [BATTLESCROLLS_DELIVERY_REGEN] = "Регенерация",
    [BATTLESCROLLS_DELIVERY_HEAL_ABSORPTION] = "Поглощение исцеления",

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
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TEXT] = "Для групп из 4 или менее игроков всегда используется 1 столбец.",

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
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "Настройка скорости обработки фоновых задач. Влияет в основном на интерфейс Журнала и время между окончанием боя и появлением записи в списке.\n\nПроизводительность: Быстрая обработка. Возможны кратковременные подлагивания.\nПлавность: Более плавный геймплей, медленная обработка. Записи могут зависать при загрузке или не появляться в Журнале.\n\nВлияет на ВСЕ модификации, использующие LibAsync.",

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
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC] = "Примерно 15 испытаний",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE] = "Умеренно (12 МБ)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC] = "Примерно 40 испытаний",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS] = "Много (25 МБ)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC] = "Примерно 80 испытаний",
    -- Effects tracking
    [BATTLESCROLLS_ONBOARDING_EFFECTS_QUESTION] = "Сколько баффов/дебаффов отслеживать?",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL] = "Полное отслеживание",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL_DESC] = "Ваши баффы, дебаффы на боссах И аптайм баффов группы (напр. аптайм Великой храбрости у всех членов группы)",
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
    [BATTLESCROLLS_SETUP_CLASS_MASTERY] = "Мастерство класса",
    [BATTLESCROLLS_SETUP_LOADOUT] = "Комплект",
    [BATTLESCROLLS_SETUP_PERKS] = "Умения",
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
    [BATTLESCROLLS_PIVOT_SCOPE_ZONES] = "По названию области",
    [BATTLESCROLLS_PIVOT_SCOPE_SPECIFIC] = "Конкретные области",

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
    [BATTLESCROLLS_PIVOT_DOMAIN_HEALING_IN] = "Полученное исцеление",
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
    [BATTLESCROLLS_PIVOT_DIM_GROUP_MEMBER] = "Член группы",
    [BATTLESCROLLS_PIVOT_DIM_ROLE] = "Роль",
    [BATTLESCROLLS_PIVOT_DIM_ENCOUNTER] = "Сражение",
    [BATTLESCROLLS_PIVOT_DIM_INSTANCE] = "Область",
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
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_RAW_HPS] = "Полный HPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_EFFECTIVE_HPS] = "Эффективный HPS",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_OUT] = "Эффективный HPS (исх.)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_OUT] = "Полный HPS (исх.)",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_IN] = "Эффективный HPS (вх.)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_IN] = "Полный HPS (вх.)",
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
    [BATTLESCROLLS_PIVOT_TIP_DIM_DELIVERY] = "Разделяет данные по типу: прямой урон, периодический урон (DoT), поглощение исцеления, периодическое исцеление (HoT), восстановление здоровья, щит или смешанный тип.",
    [BATTLESCROLLS_PIVOT_TIP_DIM_DAMAGE_TYPE] = "Разделяет данные по типу урона: физический, огонь, молния, лёд, магия, яд, болезнь, кровотечение, Обливион и другие.",
    [BATTLESCROLLS_PIVOT_TIP_DOMAIN_GROUP] = "Боевые показатели каждого члена группы: DPS, общий урон, процент критов. Для времени действия баффов/дебаффов используйте Эффекты группы.",
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
    [BATTLESCROLLS_PIVOT_SELECT_ZONES] = "Выбрать области",
    [BATTLESCROLLS_PIVOT_SELECT_INSTANCES] = "Выбрать области",
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

-- v17 storage migration
local migrationStrings = {
    [BATTLESCROLLS_MIGRATION_START] = "Идёт разовое обновление хранилища - в ближайшие минуты возможны подтормаживания",
    [BATTLESCROLLS_MIGRATION_DONE] = "Обновление хранилища завершено! Перекодировано боёв: <<1>>, освобождено <<2>> МБ",
    [BATTLESCROLLS_MIGRATION_TIP] = "Теперь можно уменьшить пресет памяти в настройках - новый формат вмещает куда больше истории в каждый МБ.",
}
for stringId, stringValue in pairs(migrationStrings) do
    SafeAddString(stringId, stringValue, 1)
end

-- Online sharing
local shareStrings = {
    [BATTLESCROLLS_SHARE_FIGHT] = "Поделиться боем",
    [BATTLESCROLLS_SHARE_INSTANCE] = "Загрузить все бои",
    [BATTLESCROLLS_SHARE_PREPARING] = "Подготовка к отправке...",
    [BATTLESCROLLS_SHARE_TITLE] = "Отправка",
    [BATTLESCROLLS_SHARE_PROGRESS_HEADER] = "Части",
    [BATTLESCROLLS_SHARE_PART_SENT] = "Часть <<1>> — отправлена",
    [BATTLESCROLLS_SHARE_PART_READY] = "Часть <<1>> — готова к отправке",
    [BATTLESCROLLS_SHARE_PART_PENDING] = "Часть <<1>>",
    [BATTLESCROLLS_SHARE_SEND_PART] = "Отправить часть <<1>> из <<2>>",
    [BATTLESCROLLS_SHARE_HINT_HEADER] = "Как это работает",
    [BATTLESCROLLS_SHARE_PRIVACY_TITLE] = "Имена игроков и данные боя будут храниться на сайте",
    [BATTLESCROLLS_SHARE_PRIVACY_NOTICE] = "Будут загружены ваши и чужие игровые имена, платформа, сервер, боевая статистика и сборки. Отчёты не удаляются автоматически; любой получивший ссылку сможет открыть или скачать их. Перед загрузкой сообщите об этом затронутым игрокам. Конфиденциальность и запросы на удаление: <<1>>",
    [BATTLESCROLLS_SHARE_TT_READY] = "Подтвердите запрос игры на открытие сайта — открывшаяся страница браузера передаст эту часть боевых данных на сайт, после чего браузер можно закрыть. Вернитесь в игру и отправьте следующую часть; прогресс сохранится, даже если выйти с этого экрана. Когда дойдут все части, страница покажет непубличную ссылку на ваш бой и QR-код.",
    [BATTLESCROLLS_SHARE_TT_SENT] = "Эта часть уже передана браузеру. Если страница в браузере сообщит, что её не хватает (упавшая вкладка теряет свою часть), выберите эту строку и нажмите кнопку повторной отправки.",
    [BATTLESCROLLS_SHARE_TT_PENDING] = "Части отправляются по одной, по порядку — эта станет доступна, когда придёт её черёд.",
    [BATTLESCROLLS_SHARE_TT_DONE] = "Страница в браузере теперь показывает непубличную ссылку и QR-код — открыть бой смогут только те, у кого есть ссылка. Если страница сообщает о недостающих частях, выберите их выше и отправьте ещё раз. «Завершить отправку» — забыть эту загрузку на стороне игры.",
    [BATTLESCROLLS_SHARE_CHOICE_HEADER] = "Что отправить",
    [BATTLESCROLLS_SHARE_CHOICE_FULL] = "Все бои (<<1>>)",
    [BATTLESCROLLS_SHARE_CHOICE_BOSSES] = "Только боссы (<<1>>)",
    [BATTLESCROLLS_SHARE_CHOICE_PARTS] = "Частей к отправке: <<1>>",
    [BATTLESCROLLS_SHARE_TT_CHOICE_FULL] = "Все записанные бои этой вылазки, включая трэш. Больше данных — больше частей для отправки через браузер.",
    [BATTLESCROLLS_SHARE_TT_CHOICE_BOSSES] = "Только бои с боссами. Обычно именно трэш занимает большую часть объёма, поэтому частей будет заметно меньше.",
    [BATTLESCROLLS_SHARE_DONE_HEADER] = "Все части отправлены",
    [BATTLESCROLLS_SHARE_DONE_HINT] = "Ссылка и QR-код ждут на странице браузера.",
    [BATTLESCROLLS_SHARE_CONTINUE] = "Продолжить отправку",
    [BATTLESCROLLS_SHARE_CANCEL] = "Отменить отправку",
    [BATTLESCROLLS_SHARE_FAILED] = "Не удалось подготовить отправку.",
    [BATTLESCROLLS_SHARE_RESEND_PART] = "Отправить часть <<1>> ещё раз",
    [BATTLESCROLLS_SHARE_PART_RESENDING] = "Часть <<1>> — повторная отправка…",
    [BATTLESCROLLS_SHARE_FINISH] = "Завершить отправку",
}
for id, str in pairs(shareStrings) do
    SafeAddString(id, str, 1)
end

-- Новые функции: переименование, урон группы, воскрешения, цвет шкалы, суперспособность, Знаки, З'ен
local featureStrings = {
    [BATTLESCROLLS_RENAME] = "Переименовать",
    [BATTLESCROLLS_RENAME_TEXT] = "Введите новое имя. Чтобы сбросить, введите исходное имя (<<1>>).",

    [BATTLESCROLLS_TAB_GROUP_DAMAGE] = "Урон группы",
    [BATTLESCROLLS_FILTER_GROUP_DAMAGE] = "Фильтр урона группы",
    [BATTLESCROLLS_FILTER_OTHERS] = "Остальные",
    [BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_SCOPE] = "Весь урон, который зарегистрировала ваша игра: ваш собственный, включая питомцев и спутников, и урон других игроков поблизости. ESO не сообщает, кто из них нанёс этот урон, поэтому он объединён в категорию «Остальные».",

    [BATTLESCROLLS_GROUP_COL_RES] = "Воскр",

    [BATTLESCROLLS_SETTINGS_BAR_COLOR] = "Цвет вашей шкалы",
    [BATTLESCROLLS_SETTINGS_BAR_COLOR_TEXT] = "Члены группы с дизайном «Шкалы» в «Боевых Свитках» видят вашу шкалу в этом цвете, даже если вы используете другой дизайн или отключили свой групповой счётчик.",
    [BATTLESCROLLS_COLOR_DEFAULT] = "По умолчанию",
    [BATTLESCROLLS_COLOR_WHEEL] = "Тон и насыщенность",
    [BATTLESCROLLS_COLOR_BRIGHTNESS] = "Яркость",
    [BATTLESCROLLS_COLOR_HEX] = "HEX-код",
    [BATTLESCROLLS_COLOR_HEX_INVALID] = "Введите шесть HEX-цифр, например #3EB6FF.",
    [BATTLESCROLLS_COLOR_SAVE] = "Сохранить",
    [BATTLESCROLLS_COLOR_SAVE_HINT] = "Ваша шкала будет этого цвета у всех, кто использует «Шкалы» в «Боевых Свитках», независимо от вашего дизайна.",

    [BATTLESCROLLS_HEADER_ULTIMATE] = "Суперспособность",
    [BATTLESCROLLS_STAT_ULT_AT_ENTRY] = "Заряд при входе в бой",
    [BATTLESCROLLS_STAT_ULT_GENERATED] = "Накоплено заряда",
    [BATTLESCROLLS_STAT_ULT_SPENT_DRAINED] = "Потрачено и поглощено",
    [BATTLESCROLLS_STAT_ULT_SPENT] = "Потрачено заряда",
    [BATTLESCROLLS_STAT_ULT_LOST] = "Потеряно при касте",
    [BATTLESCROLLS_STAT_ULT_LOST_TT] = "Применение суперспособности опустошает всю шкалу, поэтому всё сверх её стоимости теряется.",
    [BATTLESCROLLS_STAT_ULT_DRAINED] = "Поглощено заряда",
    [BATTLESCROLLS_HEADER_ULT_SOURCES] = "Источники накопления",
    [BATTLESCROLLS_ULT_BASE_GENERATION] = "Базовое накопление",
    [BATTLESCROLLS_ULT_HEROISM_LINE] = "Включая <<C:1>>: аптайм <<2>>%, примерно <<3>>",
    [BATTLESCROLLS_HEADER_ULT_CASTS] = "Применённые суперспособности",

    [BATTLESCROLLS_HEADER_CRUX] = "Знаки",
    [BATTLESCROLLS_STAT_CRUX_GENERATORS] = "Касты, дающие Знаки",
    [BATTLESCROLLS_STAT_CRUX_AT_FULL] = "Касты при 3 Знаках",
    [BATTLESCROLLS_STAT_CRUX_SPENDERS] = "Касты, тратящие Знаки",
    [BATTLESCROLLS_STAT_CRUX_UNDER] = "Касты при неполных Знаках",
    [BATTLESCROLLS_CRUX_AT_N] = "Знаков: <<1>> — <<2>>",
    [BATTLESCROLLS_HEADER_CRUX_BY_ABILITY] = "Использование Знаков по способностям",

    [BATTLESCROLLS_HEADER_ZEN] = "Наложение DoT (З'ен)",
    [BATTLESCROLLS_ZEN_AVG_DOTS] = "Среднее число DoT",
    [BATTLESCROLLS_ZEN_UPTIME] = "Время действия вашего З’ена",
    [BATTLESCROLLS_ZEN_PEAK_TIME] = "Время при <<1>>",
    [BATTLESCROLLS_ZEN_DOTS_LABEL] = "<<1>> DoT",
    [BATTLESCROLLS_ZEN_SHARE_LINE] = "в среднем <<1>> — <<2>> с 5 DoT",
    [BATTLESCROLLS_ZEN_SHORT] = "З'ен",
    [BATTLESCROLLS_ZEN_NOTE] = "Ваши DoT отслеживаются, даже если вы не носите набор З’ена. Они показывают, какой бонус вы могли бы давать, если бы на цели действовал ваш дебафф З’ена. Время без вашего З’ена показывает лишь этот потенциал.",
    [BATTLESCROLLS_ZEN_DISTRIBUTION_NOTE] = "Каждая строка DoT показывает долю отслеживаемого времени. Процент З’ена — это доля времени этой строки, когда действовал именно ваш дебафф.",

    [BATTLESCROLLS_HEADER_SUPPORT] = "Поддержка",
    [BATTLESCROLLS_STAT_RESURRECTIONS] = "Воскрешения",
}
for id, str in pairs(featureStrings) do
    SafeAddString(id, str, 1)
end

local cruxPassiveStrings = {
    [BATTLESCROLLS_STAT_CRUX_PASSIVE] = "Потеряно вне кастов",
    [BATTLESCROLLS_STAT_CRUX_PASSIVE_TT] = "Знаки, пропавшие сами по себе, без траты и без смерти рядом. Знак истекает через 30 секунд.",
    [BATTLESCROLLS_STAT_CRUX_DEATH] = "Потеряно из-за смерти",
    [BATTLESCROLLS_STAT_CRUX_PROC_WASTED] = "Пассивные приросты при 3 Знаках",
    [BATTLESCROLLS_STAT_CRUX_PROC_WASTED_TT] = "Пассивные приросты, сработавшие, когда у вас уже было 3 Знака, — они ничего не дали. «<<1>>» и его морфы, а также <<2>> дают Знак только когда у вас нет ни одного, поэтому здесь они не учитываются.",
    [BATTLESCROLLS_STAT_CRUX_CONDITIONAL_TT] = "Знаки, которые этот источник создал пассивно, без каста.",
    [BATTLESCROLLS_STAT_CRUX_OTHER] = "Прочие приросты Знаков",
    [BATTLESCROLLS_STAT_CRUX_OTHER_TT] = "Знаки, полученные без срабатывания какого-либо отслеживаемого источника в этот момент.",
    [BATTLESCROLLS_HEADER_CRUX_GAINED] = "Получено Знаков по способностям",
}
for id, str in pairs(cruxPassiveStrings) do
    SafeAddString(id, str, 1)
end

local activityOverviewStrings = {
    [BATTLESCROLLS_STAT_DOWNTIME] = "Простой",
    [BATTLESCROLLS_TOOLTIP_DOWNTIME_DESC] = "Промежутки в 3 секунды и больше между кастами — например, механики, воскрешение или смерть. В задержку каста не входят.",
    [BATTLESCROLLS_STAT_PER_MINUTE] = "<<1>>/мин",
    [BATTLESCROLLS_DETAIL_MEDIAN] = "медиана <<1>>",
    [BATTLESCROLLS_DETAIL_DELAY] = "задержка <<1>>",
    [BATTLESCROLLS_DETAIL_AT_FULL] = "<<1>> при полных",
    [BATTLESCROLLS_DETAIL_LOST] = "<<1>> потеряно",
    [BATTLESCROLLS_DETAIL_AVG_DOTS] = "в средн. <<1>> DoT",
    [BATTLESCROLLS_DETAIL_AT_DOTS] = "<<1>> при <<2>>",
}
for id, str in pairs(activityOverviewStrings) do
    SafeAddString(id, str, 1)
end

-- Release history
SafeAddString(BATTLESCROLLS_WHATS_NEW, "Что нового", 1)
SafeAddString(BATTLESCROLLS_WHATS_NEW_DESC, "История изменений «Боевых Свитков»: от последнего обновления до первого публичного выпуска.", 1)
SafeAddString(BATTLESCROLLS_RELEASE_6_0_0, [=[
|cD4AF37Новые возможности:|r

- |cD4AF37Теперь свитки могут покинуть Тамриэль!|r Создайте в журнале ссылку на бой или целое прохождение и откройте её в браузере. Отсканируйте QR-код с телевизора, чтобы получить ссылку на телефоне. Затем изучите бой сами или поделитесь им где угодно

- Изучайте те же данные о бое и сборке, что и в модификации, и экспортируйте их в |cFFFFFFCSV или JSON|r для собственного анализа

- На вкладке «|cFFFFFFАктивность|r» появились накопление и расход |cFFFFFFзаряда суперспособности|r, использование Знаков мастера рун, число одновременно действующих DoT для «Касания З’ена» и воскрешения. Число DoT помогает оценить возможный бонус З’ена, даже если вы не носите этот набор. Короткие задержки между применениями способностей отделены от длительного простоя

- В причинах вашей смерти теперь указаны |cFFFFFFимена нападавших|r, если они известны

- «|cFFFFFFУрон группы|r» показывает весь урон, замеченный вашим клиентом, включая игроков без «Боевых Свитков». Игра не сообщает, кто нанёс чужой урон, поэтому он объединён в категорию «|cFFFFFFОстальные|r»

- Задайте |cFFFFFFцвет своей шкалы|r — его увидят все члены группы с индикатором «Шкалы». Прохождения и бои в истории теперь можно переименовывать

- В журнале появился раздел «|cFFFFFFЧто нового|r» с датами и описаниями всех выпусков на семи языках. На случай, если пара свитков прошла мимо

|cD4AF37Основные изменения:|r

- Новый формат истории вмещает гораздо |cFFFFFFбольше боёв|r в тот же объём памяти. Он также должен уменьшить |cFFFFFFподтормаживания|r после крупных сражений и |cFFFFFFзначительно ускорить|r открытие боёв в журнале. После входа история |cFFFFFFавтоматически|r обновляется в фоне; во время однократного переноса возможны краткие подтормаживания. Перед заменой каждый бой сверяется с оригиналом

|cD4AF37Исправления:|r

- Запись боя должна |cFFFFFFгораздо реже завершаться раньше времени|r, если вы погибаете, а группа продолжает сражаться. Особенно часто это происходило в последнем бою в Цитадели Люцентов

- |cFFFFFFРасчёты исцеления|r теперь учитывают все фильтры, а в сборках других членов группы отображаются яды. Исправлен ряд ошибок обмена данными и очистки истории

- Данные о боях и сборках |cFFFFFFнадёжнее передаются|r между членами группы: меньше пропусков после переходов через двери и экранов загрузки

|cE6B566Известные проблемы:|r

- Чтобы индикатор памяти дополнений ESO отразил место, освобождённое при обновлении истории, может потребоваться |cFFFFFFперезагрузка интерфейса|r

- После |cFFFFFFизменений алхимии в обновлении 51|r названия эффектов ядов в сборках могут отсутствовать или отображаться неверно. В веб-версии эффекты созданных ядов не отображаются

- Возможность делиться боями через браузер не тестировалась на |cFFFFFFPlayStation|r. Пожалуйста, сообщайте о любых проблемах, в том числе если функция у вас совсем не работает]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_3_1, [=[|cD4AF37Исправления:|r

- Пассивные способности |cFFFFFFмастерства класса|r и классовые навыки других игроков теперь правильно отображаются в их сборках на вкладке «|cFFFFFFГруппа|r»]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_3_0, [=[|cD4AF37Новые возможности:|r

- Добавлена поддержка |cFFFFFFмастерства класса|r: если изучена хотя бы одна такая пассивная способность, этот раздел появляется вместо списка классовых навыков

- Добавлена поддержка «|cFFFFFFМести|r»: в обзоре |cFFFFFFсборки|r видны выбранный комплект и умения, а сведения, которые не действуют в этом режиме, скрыты

|cD4AF37Небольшие изменения:|r

- В английской версии обычные группы врагов теперь называются basepop вместо trash, как у разработчиков]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_2_0, [=[|cD4AF37Новые возможности:|r

- |cFFFFFFВосстановление здоровья|r учитывается как отдельный вид исцеления. Полное исцеление оценивается по боевому показателю восстановления, эффективное исцеление и переисцеление — по фактическим изменениям здоровья

- |cFFFFFFПоглощение исцеления|r, наложенное на игрока, учитывается как отдельный вид полученного урона

- Урон, поглощённый щитами, учитывается в суммарном нанесённом и полученном уроне, а также в DPS и DTPS, но не в разбивках по способностям и типам урона

- |cFFFFFFПоглощённое исцеление|r теперь входит в итоговые значения исцеления других, самоисцеления и полученного исцеления, а также в HPS

|cD4AF37Небольшие изменения:|r

- Подробные списки всегда показывают до 50 способностей и 20 целей/источников вместо прежних 25/15/10 в зависимости от раздела

|cD4AF37Исправления:|r

- Агрегация исходящего исцеления по типу теперь включает самоисцеление, как и остальные представления

|cE6B566Известные проблемы:|r

- Полное исцеление от |cFFFFFFвосстановления здоровья|r оценивается по времени жизни: ESO не сообщает точное время каждого тика. Если одновременно с восстановлением вы теряете здоровье, часть эффективного исцеления может остаться неучтённой]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_1_0, [=[|cD4AF37Новые возможности:|r

- |cFFFFFFЩиты|r, наложенные на вас и членов группы, учитываются как исцеление. Наложение щита — полное исцеление, реально поглощённый урон — эффективное

- |cFFFFFFЩиты|r выделены в отдельный вид исцеления рядом с прямым и периодическим на вкладках, в обзорах и агрегациях исходящего исцеления

|cE6B566Известные проблемы:|r

- Если несколько щитов накладываются на одну цель с интервалом менее 50 мс, тик щита изредка может быть приписан не той способности

|cD4AF37Небольшие изменения:|r

- Подсказки показывают ID способностей ESO в разделах урона, исцеления, эффектов, активаций, |cFFFFFFвивинга|r и |cFFFFFFсборки|r

- Исправлены неверные и общие значки: «Прагматичный резчик судеб», «Блистательная слава», «Бич цефалиарха», зелья, «Поглощение сущности», «Сила Неустрашимых», синергии «Искупление» и «Кровавый пир», «Защитная руна тихих вод», «Очищающий свет», «Испытанный ритуал» и особенность «Гармония»

- Для заполнения шкалы личного индикатора теперь нужно больше HPS

- Состав исцеления подписан «Исцеление по типу»; разбивки, в которых есть лишь одна категория, скрыты

|cD4AF37Исправления:|r

- Меньше ложных пропущенных и двойных обычных атак при вивинге

- Враги надёжнее определяются как боссы при отключённом отслеживании эффектов

- Средний тик в подсказках исцеления больше не бывает ниже минимального]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_0_0, [=[|cD4AF37Новые возможности:|r

- Появилась |cFFFFFFстатистика вивинга|r: среднее и суммарное потерянное время между применениями способностей, пропущенные обычные атаки и способности — как в целом, так и по каждой способности

- Новая вкладка «|cFFFFFFАктивность|r» для этих данных

- Данные |cFFFFFFвивинга|r доступны в агрегациях с выбранной областью «|cFFFFFFОбзор|r»

|cD4AF37Небольшие изменения:|r

- Отслеживание активаций переехало из «Обзора» в «|cFFFFFFАктивность|r». Вы ведь знали, что оно там было?

- Улучшены производительность и расход памяти в бою и вне его, особенно при частично или полностью отключённых эффектах

|cD4AF37Исправления:|r

- При отключённом отслеживании эффектов процент времени жизни на вкладке «|cFFFFFFГруппа|r» больше не всегда равен 100%]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_4_0_0, [=[|cD4AF37Новые возможности:|r

- Хотелось |cFFFFFFэлектронных таблиц|r прямо в фэнтезийной MMORPG? Наверное, нет. Но теперь можно агрегировать нужные данные по любому количеству боёв, в том числе в |cFFFFFFсводных таблицах|r

|cD4AF37Небольшие изменения:|r

- Для каждого боя показывается версия игры, например 11.3.5

- Другие игроки видят, как вы читаете свиток, пока открыты «Боевые Свитки». А что ещё?

- Название области отображается в заголовке списка боёв

|cD4AF37Исправления:|r

- Призматическое зачарование, снижающее стоимость способностей, теперь правильно отображается в сборках других членов группы

- Расположение элементов |cFFFFFFсборки|r согласовано между вкладками «|cFFFFFFГруппа|r» и «Сборка»]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_1_0, [=[|cD4AF37Новые возможности:|r

- |cFFFFFFПоиск|r на вкладке «|cFFFFFFЭффекты|r», работающий подобно поиску в инвентаре

|cD4AF37Исправления:|r

- В сборках других членов группы, играющих мастерами рун, больше не пропадает строка с расой, классом и камнем Мундуса

- Снова уменьшено |cFFFFFFмерцание|r меню группы]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_0_2, "|cFFFFFFУменьшено мерцание в меню группы|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_0_1, [=[|cD4AF37Исправления:|r

- При наличии пустых ячеек |cFFFFFFочки героя|r других членов группы больше не отображаются в неверных созвездиях. Исправление на стороне отправителя: ему тоже нужна новая версия

- При переходе от игрока с доступной сборкой к игроку без неё интерфейс больше не пытается показать отсутствующие данные]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_0_0, [=[|cD4AF37Запись сборок|r

- Каждый бой сохраняет |cFFFFFFсборку|r и показывает её на новой вкладке, чтобы вы могли точно узнать, в чём сражались

- Большая часть |cFFFFFFсборки|r отображается и в «Обзоре», чтобы хвастаться результатом было проще

- Краткий обзор |cFFFFFFсборки|r появился в меню |cFFFFFFперсонажа|r

- На вкладке «|cFFFFFFГруппа|r» записываются |cFFFFFFсборки|r других членов группы с «Боевыми Свитками»]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_1_2, "|cFFFFFFБез видимых изменений: подготовка к версии 3|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_1_1, "|cFFFFFFРасчёты урона по площади и по одной цели обновлены для изменений рыцаря-дракона. Применяется и к старым боям.|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_1_0, [=[- Добавлены |cFFFFFFподразделы|r: связанные представления объединены на одной вкладке, переключение — влево/вправо на крестовине или левом стике
  - Исходящий урон и урон боссам объединены во вкладку «Урон»
  - Исцеление других, себя и полученное исцеление объединены во вкладку «Исцеление»
  - |cFFFFFFЭффекты|r на игроке, боссах и группе разделены на |cFFFFFFподразделы|r вместо единого длинного списка

- Подавлены ошибки «Attempt to read past end of buffer». После экрана загрузки в конце боя данные группы всё ещё могут быть неверны, но хотя бы ошибка не выскакивает прямо в лицо]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_0_1, [=[|cD4AF37Группа в журнале|r

Новая вкладка для боёв с другими членами группы, у которых установлены «Боевые Свитки».

|cD4AF37Обзор:|r

- Сортируемая таблица: каждый босс, DPS, критические удары, DTPS, HPS, доля времени в живых и число смертей

|cD4AF37Подробности игрока:|r

- Урон: DPS, общий урон, критические удары, максимальный удар, прямой урон, урон по площади, типы урона, место по DPS и сравнение со средним у бойцов

- Выживаемость: DTPS, время жизни, смерти, способности, нанёсшие больше всего урона и причины смерти

- Исцеление: полный и эффективный HPS, переисцеление, самоисцеление

- Урон каждому боссу, его состав и полученный урон

|cD4AF37Групповые сведения в подсказках существующих вкладок, когда доступны:|r

- Цели-боссы: DPS и доля каждого игрока; строки DPS и DPS боссам: вклад членов группы

- DTPS и источники входящего урона: DTPS членов группы

- Состав урона: средние значения бойцов

- Полный HPS и переисцеление в исцелении других и себя: разбивка по членам группы

|cD4AF37Смерти|r

|cD4AF37Причины смерти сохраняются с боем:|r

- «|cFFFFFFОбзор|r»: число смертей в разделе входящего урона

- «Полученный урон»: время смертей с подробностями в подсказке

- «|cFFFFFFГруппа|r»: первая и последняя смерть с полным списком атак

|cD4AF37Небольшие изменения:|r

- В обзоре показывается доля прямого урона вместо периодического

- В настройках можно включить запись всех боёв на |cFFFFFFНочном рынке|r независимо от обычных фильтров областей

- Индикаторы DPS располагаются за прочими элементами, например историей добычи

- «|cFFFFFFОбзор|r» выбран по умолчанию на всех вкладках. Это стоит немного памяти, но ведь она вам всё равно не нужна?

- Имена игроков без символа @

- Индикаторы Hodor и «Шкалы» показывают длительность боя в заголовке

- Изменены звуки диалогов фильтров и областей

|cD4AF37Локализация:|r

- Исправлены формы множественного числа

- Термин «стаки» согласован с описаниями наборов снаряжения: «заряды» по-русски и Kumulation по-немецки]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_6, "|cFFFFFFИсправлена ошибка интерфейса при входе без LibGroupBroadcast|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_5, "|cFFFFFFLibGroupBroadcast временно сделан необязательным на время консольного апокалипсиса дополнений|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_4, "|cFFFFFFБез видимых изменений: подготовка к просмотру DPS членов группы в журнале|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_3, "|cFFFFFFБез видимых изменений: подготовка к просмотру DPS членов группы в журнале|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_2, [=[|cD4AF37Исправления:|r

- Дополнение больше не пытается отправлять DPS группе, когда вы не в группе. Спасибо DakJaniels]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_1, [=[|cD4AF37Исправления:|r

- Надёжнее определяются боссы в последнем бою Цитадели Люцентов и боях, где вы временно отдаляетесь от босса, например уходя в портал

- После сложных боёв, например последнего в Цитадели Люцентов или первого в Костяной Клетке, больше не должна появляться ошибка «|cFFFFFF1000ms limit hit|r»]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_0, [=[|cD4AF37Новые возможности:|r

- Избранные |cFFFFFFэффекты закрепляются|r вверху всех списков, где встречаются

|cD4AF37Исправления:|r

- Для членов группы, присоединившихся в середине боя, |cFFFFFFвремя действия|r эффектов считается только за время присутствия

- Убраны пустые элементы некоторых групповых индикаторов в левом верхнем углу при первом входе в бой

|cD4AF37Небольшие изменения:|r

- Строка общего DPS показывается, даже если в разделе бойцов только один игрок]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_2_0, [=[|cD4AF37Новые возможности:|r

- Закрепляйте области кнопкой |cFFFFFFX/квадрат|r в списке: они |cFFFFFFзащищены|r от автоматической очистки при превышении лимита памяти. Последняя область тоже всегда защищена

|cD4AF37Локализация:|r

- Согласованы названия областей в немецком и русском переводах

|cD4AF37Исправления:|r

- Режим «Плавность» больше не застревает на загрузке и не мешает новым боям появляться в журнале. После обновления пользователи этого режима будут возвращены к стандартному режиму «Производительность»]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_1_0, [=[|cD4AF37Новые возможности:|r

- |cFFFFFFУдаление|r отдельных областей и боёв из истории

|cD4AF37Исправления:|r

- Устранены бесконечная загрузка и отсутствие «Боевых Свитков» в меню при сочетании режима «Плавность» с графическим режимом «Качество». Если ошибка уже возникла, после обновления может потребоваться ещё один |cFFFFFF/reloadui|r

- Игровые диалоги, например уничтожение предметов, больше не ломаются после использования фильтров

- Исправлено обратное направление анимации при выходе из «Боевых Свитков» в Журнал]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_3, "|cFFFFFFПопытка вслепую исправить повреждение сохранений на PS5|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_2, [=[|cD4AF37Улучшения хранения и отслеживания эффектов|r

|cD4AF37Хранение:|r

- Ускорены кодирование и декодирование для загрузки журнала

- Снижен расход памяти при обработке боёв

|cD4AF37Эффекты:|r

- Исправлено |cFFFFFFвремя действия|r эффектов при отключении членов группы во время боя

- Улучшена обработка возвращения членов группы в середине боя]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_1, "|cFFFFFFИсправление ошибки|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_0, [=[|cD4AF37Первый публичный выпуск|r

|cD4AF37Индикатор DPS:|r

- Урон в реальном времени

- Личные варианты: стандартный, минимальный, «Шкала»

- Групповые варианты: текст, стиль Hodor, «Шкалы»

- Настройка позиции, масштаба и времени показа после боя

|cD4AF37Боевой журнал:|r

- История: область -> бой -> показатели

- Фильтры по типам областей и боёв

- Настраиваемые лимиты хранения

|cD4AF37Урон:|r

- Разбивки по целям и способностям

- Прямой и периодический урон, критические удары

- Урон по одной цели и по площади

|cD4AF37Исцеление:|r

- Исходящее и входящее, по источникам и целям

|cD4AF37Эффекты:|r

- Время действия усилений и ослаблений на игроке и группе, ослаблений на боссах

- Отслеживание срабатываний

Обмен DPS в группе через |cFFFFFFLibGroupBroadcast|r

|cD4AF37Языки:|r английский, немецкий, французский, испанский, русский, японский, китайский]=], 1)

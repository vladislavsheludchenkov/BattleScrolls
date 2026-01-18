-- Battle Scrolls Localization - Japanese (日本語)
-- Translations use ESO's official Japanese terminology

local strings = {
    -------------------------
    -- Core UI Labels
    -------------------------
    [BATTLESCROLLS_UI_NAME] = "Battle Scrolls",
    [BATTLESCROLLS_UI_SETTINGS] = "設定",
    [BATTLESCROLLS_UI_FILTER] = "フィルター",
    [BATTLESCROLLS_UI_FILTER_ACTIVE] = "フィルター（有効）",
    [BATTLESCROLLS_STAT_HPS] = "HPS",

    -------------------------
    -- Zone/Instance Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ZONES] = "全ゾーン",
    [BATTLESCROLLS_TAB_INSTANCED] = "インスタンス",
    [BATTLESCROLLS_TAB_OVERLAND] = "フィールド",
    [BATTLESCROLLS_TAB_HOUSES] = "ハウジング",
    [BATTLESCROLLS_TAB_PVP] = "PvP",

    -------------------------
    -- Encounter Tabs
    -------------------------
    [BATTLESCROLLS_TAB_ALL_ENCOUNTERS] = "全戦闘",
    [BATTLESCROLLS_TAB_BOSS_ENCOUNTERS] = "ボス戦",
    [BATTLESCROLLS_TAB_OTHER_ENCOUNTERS] = "その他の戦闘",
    [BATTLESCROLLS_TAB_PLAYER_ENCOUNTERS] = "PvP戦",
    [BATTLESCROLLS_TAB_TARGET_DUMMY] = "標的ダミー",

    -------------------------
    -- Stats Tabs
    -------------------------
    [BATTLESCROLLS_TAB_OVERVIEW] = "概要",
    [BATTLESCROLLS_TAB_BOSS_DAMAGE_DONE] = "ボスダメージ",
    [BATTLESCROLLS_TAB_DAMAGE_DONE] = "与ダメージ",
    [BATTLESCROLLS_TAB_DAMAGE_TAKEN] = "被ダメージ",
    [BATTLESCROLLS_TAB_HEALING_OUT] = "与回復",
    [BATTLESCROLLS_TAB_SELF_HEALING] = "自己回復",
    [BATTLESCROLLS_TAB_HEALING_IN] = "被回復",
    [BATTLESCROLLS_TAB_EFFECTS] = "効果",

    -------------------------
    -- Time Headers
    -------------------------
    [BATTLESCROLLS_TIME_TODAY] = "今日",
    [BATTLESCROLLS_TIME_YESTERDAY] = "昨日",

    -------------------------
    -- DPS Meter Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_DPS_METER] = "DPSメーター",
    [BATTLESCROLLS_SETTINGS_KEEP_AFTER_COMBAT] = "戦闘後の表示",
    [BATTLESCROLLS_SETTINGS_HIDE_IMMEDIATELY] = "すぐに隠す",
    [BATTLESCROLLS_SETTINGS_10_SECONDS] = "10秒",
    [BATTLESCROLLS_SETTINGS_30_SECONDS] = "30秒",
    [BATTLESCROLLS_SETTINGS_2_MINUTES] = "2分",
    [BATTLESCROLLS_SETTINGS_5_MINUTES] = "5分",
    [BATTLESCROLLS_SETTINGS_UNTIL_RELOAD] = "リロードまで",

    [BATTLESCROLLS_SETTINGS_PERSONAL_METER] = "個人メーター",
    [BATTLESCROLLS_SETTINGS_GROUP_METER] = "グループメーター",
    [BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT] = "この設定をオフにしても、アドオンをインストールしているグループメンバーはあなたのDPSを見ることができます。",
    [BATTLESCROLLS_SETTINGS_ENABLED] = "有効",
    [BATTLESCROLLS_SETTINGS_MODE] = "モード",
    [BATTLESCROLLS_SETTINGS_DESIGN] = "デザイン",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_LEFT] = "左からの距離",
    [BATTLESCROLLS_SETTINGS_OFFSET_FROM_TOP] = "上からの距離",
    [BATTLESCROLLS_SETTINGS_SIZE] = "サイズ",
    [BATTLESCROLLS_SETTINGS_RESET_POSITION] = "位置をリセット",
    [BATTLESCROLLS_SETTINGS_POSITION] = "位置",

    -- Meter modes
    [BATTLESCROLLS_SETTINGS_MODE_AUTO] = "自動",
    [BATTLESCROLLS_SETTINGS_MODE_DAMAGE] = "ダメージ",
    [BATTLESCROLLS_SETTINGS_MODE_HEALING] = "回復",

    -- Meter size options
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_SMALL] = "極小",
    [BATTLESCROLLS_SETTINGS_SIZE_SMALL] = "小",
    [BATTLESCROLLS_SETTINGS_SIZE_MEDIUM] = "中",
    [BATTLESCROLLS_SETTINGS_SIZE_LARGE] = "大",
    [BATTLESCROLLS_SETTINGS_SIZE_EXTRA_LARGE] = "極大",

    -- Meter position options
    [BATTLESCROLLS_SETTINGS_POSITION_BELOW] = "個人の下",
    [BATTLESCROLLS_SETTINGS_POSITION_ABOVE] = "個人の上",
    [BATTLESCROLLS_SETTINGS_POSITION_SEPARATE] = "別々",

    -- Auto mode tooltip
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TITLE] = "自動モード",
    [BATTLESCROLLS_SETTINGS_AUTO_MODE_TEXT] = "DPSとHPSのうち高い方を表示します。",

    -- Group tracker tooltips
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA] = "グループデータなしで表示",
    [BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA_TEXT] = "有効にすると、他のグループメンバーがDPSデータを共有していなくてもグループメーターが表示されます。自分のデータのみ表示されます。",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_DESIGN] = "グループメーターのデザイン",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION] = "グループメーターの位置",
    [BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION_TEXT] = "下/上: グループメーターを個人メーターに連結します。\n別々: グループメーターを独立して配置し、カスタム位置を設定できます。",

    -------------------------
    -- Recording Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_RECORDING] = "記録",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED] = "インスタンスで記録",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED_TEXT] = "インスタンスゾーンにはダンジョン、試練、アリーナ、無限アーカイブが含まれます。",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_OVERLAND] = "フィールドで記録",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_HOUSES] = "ハウジングで記録",
    [BATTLESCROLLS_SETTINGS_RECORD_IN_PVP] = "PvPで記録",
    [BATTLESCROLLS_SETTINGS_RECORD_BOSS_FIGHTS] = "ボス戦を記録",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS] = "雑魚戦を記録",
    [BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS_TEXT] = "通常の敵との戦闘（ボス、プレイヤー以外）。",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS] = "PvP戦を記録",
    [BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS_TEXT] = "他のプレイヤーとのPvP戦闘。",
    [BATTLESCROLLS_SETTINGS_RECORD_DUMMY_FIGHTS] = "標的ダミー戦を記録",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE] = "記録フィルター",
    [BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT] = "ゾーンと戦闘タイプのフィルターは組み合わされます：記録されるには、少なくとも1つのゾーンと1つのタイプに一致する必要があります。",

    -- Storage/History settings
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT] = "履歴サイズ制限",
    [BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT_TITLE] = "履歴サイズ制限",
    -- Storage size preset labels (dropdown options)
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XS] = "極小",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_SMALL] = "小",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_MEDIUM] = "中",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_LARGE] = "大",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_XL] = "極大",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_CAUTION] = "注意",
    [BATTLESCROLLS_SETTINGS_STORAGE_SIZE_YOLO] = "まあ大丈夫でしょ",
    -- Storage tooltip
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC] = "戦闘履歴の保存量を設定します。制限を超えると、古いインスタンスが自動的に削除されます。",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE] = "この制限は保存された履歴のみに適用されます。アドオンは現在の戦闘の追跡やUIの描画にもメモリを使用するため、実際の使用量はここに表示されているより高くなります。",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT] = "履歴: <<1>> MB / <<2>> MB (<<3>>%)",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS] = "プリセット (トライアル ~0.5-1 MB、ダンジョン ~0.25-0.5 MB):",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XS] = "  極小: 5 MB - 最近の数回分",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL] = "  小: 8 MB - 一晩のプログ分",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM] = "  中: 12 MB - 1週間のカジュアルプレイ分",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE] = "  大: 18 MB - 2週間分",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XL] = "  極大: 25 MB - 1ヶ月の思い出",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION] = "  注意: 40 MB - データ好きですね",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO] = "  まあ大丈夫でしょ: 60 MB - 危険を恐れない",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING] = "ESOのメモリ制限について: 全アドオンで100 MBを共有します。70 MBで警告が表示されます。100 MBでUIがリロードされ、全て無効化されます。多くのアドオンを使用している場合は、小さいプリセットを選択してください。ヒント: チャットで /addonmemdisplay と入力するとリアルタイムでメモリ使用量を確認できます。",

    -------------------------
    -- Effect Tracking Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_EFFECT_TRACKING] = "効果追跡",
    [BATTLESCROLLS_SETTINGS_PLAYER_BUFFS] = "自分へのバフ",
    [BATTLESCROLLS_SETTINGS_PLAYER_DEBUFFS] = "自分へのデバフ",
    [BATTLESCROLLS_SETTINGS_GROUP_BUFFS] = "グループへのバフ",
    [BATTLESCROLLS_SETTINGS_BOSS_DEBUFFS] = "ボスへのデバフ",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION] = "照合精度",
    [BATTLESCROLLS_SETTINGS_RECON_PRECISION_TOOLTIP] = "エフェクト追跡をゲーム状態と照合する頻度。高精度は見逃しを減らしますが、メモリを多く消費します。メモリはUIリロード時にのみ解放されます。",
    [BATTLESCROLLS_SETTINGS_RECON_MAX] = "最大",
    [BATTLESCROLLS_SETTINGS_RECON_HIGH] = "高",
    [BATTLESCROLLS_SETTINGS_RECON_NORMAL] = "通常",
    [BATTLESCROLLS_SETTINGS_RECON_LOW] = "低",
    [BATTLESCROLLS_SETTINGS_RECON_OFF] = "オフ",

    -------------------------
    -- Slider keybinds
    -------------------------
    [BATTLESCROLLS_SETTINGS_SLIDER_HOLD_FAST] = "長押しで高速",
    [BATTLESCROLLS_SETTINGS_SLIDER_RELEASE_PRECISION] = "離して精密",

    -------------------------
    -- Overview Stats
    -------------------------
    [BATTLESCROLLS_STAT_DURATION] = "持続時間",
    [BATTLESCROLLS_STAT_SUMMARY] = "サマリー",

    -- Boss Damage
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE] = "個人ボスダメージ",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DPS] = "個人ボスDPS",
    [BATTLESCROLLS_STAT_PERSONAL_BOSS_DAMAGE_SHARE] = "個人ボスダメージシェア",
    [BATTLESCROLLS_HEADER_BOSS_DAMAGE_DONE] = "ボスダメージ",

    -- Total Damage
    [BATTLESCROLLS_STAT_PERSONAL_DAMAGE] = "個人ダメージ",
    [BATTLESCROLLS_STAT_PERSONAL_DPS] = "個人DPS",
    [BATTLESCROLLS_STAT_PERSONAL_SHARE] = "個人シェア",
    [BATTLESCROLLS_HEADER_TOTAL_DAMAGE_DONE] = "合計ダメージ",

    -- Damage Taken
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE_TAKEN] = "合計被ダメージ",
    [BATTLESCROLLS_STAT_DTPS] = "DTPS",
    [BATTLESCROLLS_HEADER_DAMAGE_TAKEN] = "被ダメージ",

    -- Healing Overview
    [BATTLESCROLLS_STAT_RAW_SELF_HEALING] = "総自己回復",
    [BATTLESCROLLS_STAT_RAW_SELF_HPS] = "総自己回復HPS",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HEALING] = "実効自己回復",
    [BATTLESCROLLS_STAT_EFFECTIVE_SELF_HPS] = "実効自己回復HPS",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT] = "総与回復",
    [BATTLESCROLLS_STAT_RAW_HEALING_OUT_HPS] = "総与回復HPS",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT] = "実効与回復",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_OUT_HPS] = "実効与回復HPS",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN] = "総被回復",
    [BATTLESCROLLS_STAT_RAW_HEALING_IN_HPS] = "総被回復HPS",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN] = "実効被回復",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING_IN_HPS] = "実効被回復HPS",
    [BATTLESCROLLS_HEADER_HEALING] = "回復",

    -- Proc Tracking
    [BATTLESCROLLS_HEADER_PROC_TRACKING] = "プロック追跡",
    [BATTLESCROLLS_STAT_TOTAL_PROCS] = "発動",
    [BATTLESCROLLS_STAT_MEDIAN_INTERVAL] = "中央値",

    -------------------------
    -- Damage Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE] = "合計ボスダメージ",
    [BATTLESCROLLS_STAT_BOSS_DPS] = "ボスDPS",
    [BATTLESCROLLS_STAT_GROUP_SHARE] = "貢献度",
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE] = "合計ダメージ",
    [BATTLESCROLLS_STAT_DPS] = "DPS",

    [BATTLESCROLLS_HEADER_BY_ABILITY] = "スキル別",
    [BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE] = "ダメージタイプ別",
    [BATTLESCROLLS_HEADER_DIRECT_VS_DOT] = "直接攻撃 vs 継続",
    [BATTLESCROLLS_HEADER_AOE_VS_SINGLE] = "範囲攻撃 vs 単体攻撃",
    [BATTLESCROLLS_HEADER_BY_TARGET] = "ターゲット別",
    [BATTLESCROLLS_HEADER_BY_SOURCE] = "ソース別",

    [BATTLESCROLLS_STAT_DIRECT_DAMAGE] = "直接攻撃",
    [BATTLESCROLLS_STAT_DAMAGE_OVER_TIME] = "継続ダメージ",
    [BATTLESCROLLS_STAT_AOE_DAMAGE] = "範囲攻撃",
    [BATTLESCROLLS_STAT_SINGLE_TARGET_DAMAGE] = "単体攻撃",

    -------------------------
    -- Healing Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_RAW_HEALING] = "総回復",
    [BATTLESCROLLS_STAT_RAW_HPS] = "総HPS",
    [BATTLESCROLLS_STAT_EFFECTIVE_HEALING] = "実効回復",
    [BATTLESCROLLS_STAT_EFFECTIVE_HPS] = "実効HPS",
    [BATTLESCROLLS_STAT_OVERHEAL] = "過剰回復",

    [BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT] = "総: HoT vs 直接",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT] = "実効: HoT vs 直接",
    [BATTLESCROLLS_HEADER_RAW_BY_TARGET] = "総回復（ターゲット別）",
    [BATTLESCROLLS_HEADER_RAW_BY_ABILITY] = "総回復（スキル別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_BY_TARGET] = "実効回復（ターゲット別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_BY_ABILITY] = "実効回復（スキル別）",
    [BATTLESCROLLS_HEADER_RAW_BY_SOURCE] = "総回復（ソース別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_BY_SOURCE] = "実効回復（ソース別）",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET] = "総回復（ターゲット別）",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY] = "総回復（スキル別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET] = "実効回復（ターゲット別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY] = "実効回復（スキル別）",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE] = "総回復（ソース別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE] = "実効回復（ソース別）",

    [BATTLESCROLLS_STAT_DIRECT_HEALING] = "直接回復",
    [BATTLESCROLLS_STAT_HEALING_OVER_TIME] = "継続回復",

    -------------------------
    -- Effects Stats
    -------------------------
    [BATTLESCROLLS_HEADER_YOUR_BUFFS] = "あなたのバフ",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON_YOU] = "あなたへのデバフ",
    [BATTLESCROLLS_HEADER_BUFFS_ON_GROUP] = "グループへのバフ",
    [BATTLESCROLLS_HEADER_DEBUFFS_ON] = "<<1>>へのデバフ",

    [BATTLESCROLLS_EFFECT_UPTIME] = "稼働率",
    [BATTLESCROLLS_EFFECT_YOURS] = "あなた",
    [BATTLESCROLLS_EFFECT_AVG] = "平均",
    [BATTLESCROLLS_EFFECT_MEMBERS] = "メンバー",

    -------------------------
    -- Effect Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL_UPTIME] = "合計稼働率",
    [BATTLESCROLLS_TOOLTIP_TOTAL_APPLICATIONS] = "合計適用回数",
    [BATTLESCROLLS_TOOLTIP_YOUR_CONTRIBUTION] = "あなたの貢献",
    [BATTLESCROLLS_TOOLTIP_YOUR_UPTIME] = "稼働率",
    [BATTLESCROLLS_TOOLTIP_YOUR_APPLICATIONS] = "適用回数",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS] = "最大スタック",
    [BATTLESCROLLS_TOOLTIP_TIME_AT_MAX_STACKS] = "最大スタック時間",
    [BATTLESCROLLS_TOOLTIP_YOUR_TIME_AT_MAX] = "あなたの最大時間",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_MEMBER] = "メンバー平均稼働率",
    [BATTLESCROLLS_TOOLTIP_MEMBERS_AFFECTED] = "影響メンバー数",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME] = "平均稼働率",
    [BATTLESCROLLS_TOOLTIP_MAX_STACKS_OBSERVED] = "観測最大スタック",
    [BATTLESCROLLS_TOOLTIP_AVG_TIME_AT_MAX] = "平均最大スタック時間",
    [BATTLESCROLLS_TOOLTIP_YOUR_AVG_TIME_AT_MAX] = "あなたの平均最大時間",
    [BATTLESCROLLS_TOOLTIP_PEAK_INSTANCES] = "最大同時ソース数",
    [BATTLESCROLLS_TOOLTIP_AVG_UPTIME_PER_INSTANCE] = "ソース平均稼働率",
    [BATTLESCROLLS_TOOLTIP_PER_MEMBER] = "メンバー別",
    [BATTLESCROLLS_TOOLTIP_YOU] = "あなた",

    -------------------------
    -- Ability Tooltips
    -------------------------
    [BATTLESCROLLS_TOOLTIP_TOTAL] = "合計",
    [BATTLESCROLLS_TOOLTIP_TYPE] = "タイプ",
    [BATTLESCROLLS_TOOLTIP_DELIVERY] = "方式",
    [BATTLESCROLLS_TOOLTIP_CRIT] = "クリティカル",
    [BATTLESCROLLS_TOOLTIP_AVG_TICK] = "平均ティック",
    [BATTLESCROLLS_TOOLTIP_MIN_TICK] = "最小ティック",
    [BATTLESCROLLS_TOOLTIP_MAX_TICK] = "最大ティック",

    [BATTLESCROLLS_TOOLTIP_BY_TARGET] = "ターゲット別",
    [BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL] = "平均間隔",
    [BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL] = "中央値間隔",

    [BATTLESCROLLS_TOOLTIP_ABILITY] = "スキル",

    -------------------------
    -- Damage Types
    -------------------------
    [BATTLESCROLLS_DAMAGE_TYPE_NONE] = "なし",
    [BATTLESCROLLS_DAMAGE_TYPE_GENERIC] = "汎用",
    [BATTLESCROLLS_DAMAGE_TYPE_PHYSICAL] = "物理",
    [BATTLESCROLLS_DAMAGE_TYPE_FIRE] = "炎",
    [BATTLESCROLLS_DAMAGE_TYPE_SHOCK] = "雷撃",
    [BATTLESCROLLS_DAMAGE_TYPE_OBLIVION] = "オブリビオン",
    [BATTLESCROLLS_DAMAGE_TYPE_FROST] = "氷結",
    [BATTLESCROLLS_DAMAGE_TYPE_EARTH] = "大地",
    [BATTLESCROLLS_DAMAGE_TYPE_MAGIC] = "魔法",
    [BATTLESCROLLS_DAMAGE_TYPE_DROWN] = "溺死",
    [BATTLESCROLLS_DAMAGE_TYPE_DISEASE] = "病気",
    [BATTLESCROLLS_DAMAGE_TYPE_POISON] = "毒",
    [BATTLESCROLLS_DAMAGE_TYPE_BLEED] = "出血",

    -------------------------
    -- Over Time/Direct Descriptions
    -------------------------
    [BATTLESCROLLS_DELIVERY_MIXED] = "混合",
    [BATTLESCROLLS_DELIVERY_DOT] = "継続",
    [BATTLESCROLLS_DELIVERY_DIRECT] = "直接",
    [BATTLESCROLLS_DELIVERY_HOT] = "継続回復",

    -------------------------
    -- Filter Dialog
    -------------------------
    [BATTLESCROLLS_FILTER_DAMAGE_DONE] = "ダメージフィルター",
    [BATTLESCROLLS_FILTER_BOSS_DAMAGE] = "ボスダメージフィルター",
    [BATTLESCROLLS_FILTER_BY_SOURCE] = "ソースでフィルター",
    [BATTLESCROLLS_FILTER_BY_TARGET] = "ターゲットでフィルター",
    [BATTLESCROLLS_FILTER_BY_GROUP_MEMBER] = "メンバーでフィルター",
    [BATTLESCROLLS_FILTER] = "フィルター",
    [BATTLESCROLLS_FILTER_ACTIVE] = "フィルター（有効）",
    [BATTLESCROLLS_FILTER_RESET] = "リセット",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_BY] = "ダメージ元",
    [BATTLESCROLLS_FILTER_DAMAGE_DONE_TO] = "ダメージ先",
    [BATTLESCROLLS_FILTER_BOSS_TARGET] = "ボスターゲット",

    -------------------------
    -- Encounter Display
    -------------------------
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN_WITH] = "<<l:1>><<2>>との戦闘",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_WITH] = "<<1>>との戦闘",
    [BATTLESCROLLS_ENCOUNTER_FIGHT_IN] = "<<l:1>>の戦闘",
    [BATTLESCROLLS_ENCOUNTER_COMBAT] = "戦闘",
    [BATTLESCROLLS_ENCOUNTER_INTO_INSTANCE] = "開始から",
    [BATTLESCROLLS_ENCOUNTER_SELF_SUFFIX] = "（自分）",

    -------------------------
    -- List States
    -------------------------
    [BATTLESCROLLS_LIST_LOADING] = "読み込み中",
    [BATTLESCROLLS_LIST_NO_DATA] = "戦闘データがありません",
    [BATTLESCROLLS_LIST_NO_ENCOUNTERS] = "戦闘がありません",
    [BATTLESCROLLS_LIST_NO_STATS] = "統計がありません",
    [BATTLESCROLLS_LIST_NO_SETTINGS] = "設定がありません",

    -------------------------
    -- LibHarvensAddonSettings Integration
    -------------------------
    [BATTLESCROLLS_LIBHARVENS_OPEN_BUTTON] = "Battle Scrollsを開く",
    [BATTLESCROLLS_LIBHARVENS_TOOLTIP] = "Battle Scrollsは<<1>>メニューからもアクセスできます。",

    -------------------------
    -- Misc
    -------------------------
    [BATTLESCROLLS_UNKNOWN] = "不明",
    [BATTLESCROLLS_UNKNOWN_BOSS] = "不明なボス",

    -------------------------
    -- Personal Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_PERSONAL_DEFAULT] = "デフォルト",
    [BATTLESCROLLS_DESIGN_PERSONAL_MINIMAL] = "ミニマル",
    [BATTLESCROLLS_DESIGN_PERSONAL_BAR] = "バー",

    -- Bar design settings
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION] = "バーの方向",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_RIGHT] = "右",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_LEFT] = "左",
    [BATTLESCROLLS_DESIGN_BAR_DIRECTION_CENTER] = "双方向",

    -------------------------
    -- Group Meter Designs
    -------------------------
    [BATTLESCROLLS_DESIGN_GROUP_TEXT] = "テキスト",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR] = "Hodor",
    [BATTLESCROLLS_DESIGN_GROUP_HODOR_DESC] = "Hodor Reflexes (@andy.s、@m00nyONE) にとても近い。",
    [BATTLESCROLLS_DESIGN_GROUP_BARS] = "バー",
    [BATTLESCROLLS_DESIGN_GROUP_BARS_DESC] = "Hodor Restyle (Hyperioxes) を参考に。",

    -- Text design settings
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS] = "列",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TITLE] = "列のレイアウト",
    [BATTLESCROLLS_DESIGN_TEXT_COLUMNS_TEXT] = "4人以下のグループは常に1列を使用します。",

    -------------------------
    -- DPS Meter Display Strings
    -- Note: DPS/HPS are universal gaming terms, hardcoded in code
    -------------------------
    [BATTLESCROLLS_METER_EFFECTIVE] = "実効",
    [BATTLESCROLLS_METER_EFF] = "実効",
    [BATTLESCROLLS_METER_BOSS] = "ボス",
    [BATTLESCROLLS_METER_ALL] = "全体",
    [BATTLESCROLLS_METER_ALL_DAMAGE] = "全ダメージ",
    [BATTLESCROLLS_METER_TOTAL] = "合計",
    [BATTLESCROLLS_METER_BOSS_ALL_DAMAGE] = "ボスダメージ / 全ダメージ",
    [BATTLESCROLLS_METER_EFFECTIVE_RAW_HEALING] = "実効 / 総回復",

    -- Overview Panel Q3/Q4 Headers
    [BATTLESCROLLS_OVERVIEW_TOP_ABILITIES] = "トップスキル",
    [BATTLESCROLLS_OVERVIEW_BOSSES] = "ボス",
    [BATTLESCROLLS_OVERVIEW_TARGETS] = "ターゲット",
    [BATTLESCROLLS_OVERVIEW_SOURCES] = "ソース",
    [BATTLESCROLLS_OVERVIEW_TARGETS_HEALED] = "回復対象",
    [BATTLESCROLLS_OVERVIEW_HEALERS] = "ヒーラー",
    [BATTLESCROLLS_OVERVIEW_GROUP_BUFFS] = "グループバフ",
    [BATTLESCROLLS_OVERVIEW_BOSS_DEBUFFS] = "ボスデバフ",

    -- Group Stats
    [BATTLESCROLLS_GROUP_DAMAGE] = "グループダメージ",
    [BATTLESCROLLS_GROUP_BOSS_DAMAGE] = "グループボスダメージ",
    [BATTLESCROLLS_GROUP_DPS] = "グループDPS",
    [BATTLESCROLLS_GROUP_BOSS_DPS] = "グループボスDPS",
    [BATTLESCROLLS_STAT_GROUP_DAMAGE] = "グループダメージ",
    [BATTLESCROLLS_STAT_GROUP_DPS] = "グループDPS",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DAMAGE] = "グループボスダメージ",
    [BATTLESCROLLS_STAT_GROUP_BOSS_DPS] = "グループボスDPS",

    -- Overview Panel - Ability Stats
    [BATTLESCROLLS_STAT_MAX_PREFIX] = "最大: <<1>>",
    [BATTLESCROLLS_STAT_CRIT_PERCENT] = "<<1>>%クリ",
    [BATTLESCROLLS_STAT_PER_SECOND] = "<<1>>/秒",

    -- Overview Panel - Effect Stats
    [BATTLESCROLLS_EFFECT_APPS_COUNT] = "<<1>>回適用",
    [BATTLESCROLLS_EFFECT_YOURS_PERCENT] = "<<1>>%自分",
    [BATTLESCROLLS_EFFECT_STACKS_COUNT] = "×<<1>>スタック",

    -- Overview Panel Summary
    [BATTLESCROLLS_OVERVIEW_ENCOUNTER] = "エンカウンター",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT] = "ダメージ出力",
    [BATTLESCROLLS_OVERVIEW_SUMMARY] = "サマリー",
    [BATTLESCROLLS_OVERVIEW_TOTAL] = "合計",
    [BATTLESCROLLS_OVERVIEW_SHARE] = "シェア",
    [BATTLESCROLLS_OVERVIEW_COMPOSITION] = "構成",
    [BATTLESCROLLS_OVERVIEW_QUALITY] = "品質",
    [BATTLESCROLLS_OVERVIEW_CRIT_RATE] = "クリティカル率",
    [BATTLESCROLLS_OVERVIEW_MAX_HIT] = "最大ヒット",
    [BATTLESCROLLS_OVERVIEW_MAX_HEAL] = "最大ヒール",
    [BATTLESCROLLS_OVERVIEW_EFFICIENCY] = "効率",
    [BATTLESCROLLS_OVERVIEW_KEY_BUFFS] = "あなたのバフ",
    [BATTLESCROLLS_OVERVIEW_KEY_DEBUFFS] = "主要デバフ",
    [BATTLESCROLLS_OVERVIEW_UPTIMES] = "稼働率",
    [BATTLESCROLLS_OVERVIEW_NO_EFFECTS] = "効果の記録なし",

    -- Overview Panel Short Labels
    [BATTLESCROLLS_BOSS_DAMAGE] = "ボスダメージ",
    [BATTLESCROLLS_DAMAGE_DONE] = "与ダメージ",
    [BATTLESCROLLS_HEALING_OUT] = "与回復",
    [BATTLESCROLLS_SELF_HEALING] = "自己回復",
    [BATTLESCROLLS_HEALING_IN] = "被回復",
    [BATTLESCROLLS_AOE] = "範囲攻撃",
    [BATTLESCROLLS_SINGLE_TARGET] = "単体攻撃",
    [BATTLESCROLLS_HEALING_RAW_HPS] = "総HPS",
    [BATTLESCROLLS_HEALING_EFFECTIVE_HPS] = "実効HPS",
    [BATTLESCROLLS_HEALING_OVERHEAL] = "過剰回復",
    [BATTLESCROLLS_TOOLTIP_DURATION] = "持続時間",

    -------------------------
    -- LibAsync Settings
    -------------------------
    [BATTLESCROLLS_SETTINGS_PERFORMANCE] = "パフォーマンス",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED] = "処理速度",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_PERFORMANCE] = "パフォーマンス重視",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_BALANCED] = "バランス",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_SMOOTH] = "滑らか",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM] = "カスタム (<<1>> FPS)",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE] = "処理速度",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "バックグラウンドタスクの処理速度を制御します。主にジャーナルUIと、戦闘終了から記録がリストに表示されるまでの時間に影響します。\n\nパフォーマンス重視: 最速処理。一時的なカクつきの可能性あり。\nバランス: 速度と滑らかさの良いバランス。\n滑らか: 最も滑らかなゲームプレイ、処理は遅め。\n\nこの設定はLibAsyncを使用するすべてのアドオンに影響します。",

    -------------------------
    -- Onboarding
    -------------------------
    [BATTLESCROLLS_ONBOARDING_WELCOME_TITLE] = "Battle Scrollsへようこそ",
    [BATTLESCROLLS_ONBOARDING_WELCOME_TEXT] = "Battle Scrollsは戦闘の記録を保存し、後でジャーナルで確認できます。\n\n機能：\n- リアルタイムDPS/HPSメーター\n- ダメージと回復の詳細な内訳\n- バフ/デバフ稼働率の追跡\n- ボスデバフの監視\n\nいくつかの設定を行いましょう。",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED] = "始める",
    [BATTLESCROLLS_ONBOARDING_GET_STARTED_DESC] = "設定オプションを案内してもらう",
    [BATTLESCROLLS_ONBOARDING_SKIP] = "スキップ",
    [BATTLESCROLLS_ONBOARDING_SKIP_DESC] = "自分で設定する。推奨設定を使用。",
    [BATTLESCROLLS_ONBOARDING_METER_QUESTION] = "DPSメーターのスタイルを選択：",
    -- Meter presets
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL] = "ミニマル",
    [BATTLESCROLLS_PRESET_PERSONAL_MINIMAL_DESC] = "画面の隅にコンパクトな個人メーター",
    [BATTLESCROLLS_PRESET_FULL_STACKED] = "個人 + グループ",
    [BATTLESCROLLS_PRESET_FULL_STACKED_DESC] = "個人メーターとその下にグループランキング",
    [BATTLESCROLLS_PRESET_HODOR] = "Hodorスタイル",
    [BATTLESCROLLS_PRESET_HODOR_DESC] = "グループのみ、Hodor Reflexesにとても近い (@andy.s, @m00nyONE)",
    [BATTLESCROLLS_PRESET_BAR] = "プログレスバー",
    [BATTLESCROLLS_PRESET_BAR_DESC] = "個人DPS用プログレスバー",
    [BATTLESCROLLS_PRESET_COLORFUL] = "カラフルバー",
    [BATTLESCROLLS_PRESET_COLORFUL_DESC] = "個人・グループDPS用カラフルバー、グループはHodor Restyleを参考に (Hyperioxes)",
    [BATTLESCROLLS_PRESET_DISABLED] = "無効",
    [BATTLESCROLLS_PRESET_DISABLED_DESC] = "メーターなし、記録のみ",
    -- Storage options
    [BATTLESCROLLS_ONBOARDING_STORAGE_QUESTION] = "履歴をどのくらい保持しますか？",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL] = "最小 (5 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC] = "約6回のトライアル分",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE] = "中程度 (12 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC] = "約16回のトライアル分",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS] = "多め (25 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC] = "約36回のトライアル分",
    -- Effects tracking
    [BATTLESCROLLS_ONBOARDING_EFFECTS_QUESTION] = "バフ/デバフ追跡のレベルは？",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL] = "フル追跡",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_FULL_DESC] = "自分のバフ、ボスデバフ、グループバフの稼働率（例：全グループメンバーのメジャーカレッジ稼働率）",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL] = "必須のみ",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_ESSENTIAL_DESC] = "自分のバフとボスデバフのみ。グループ追跡をスキップしてメモリ使用量を削減。",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED] = "無効",
    [BATTLESCROLLS_ONBOARDING_EFFECTS_DISABLED_DESC] = "バフ/デバフ追跡なし。メモリ使用量最小、レポートに稼働率データなし。",
    -- Completion
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TITLE] = "準備完了！",
    [BATTLESCROLLS_ONBOARDING_COMPLETE_TEXT] = "Battle Scrollsが戦闘を追跡する準備ができました。\n\nさあ、戦いに行こう！\n\n遭遇はここのジャーナルに表示されます。設定タブからいつでも設定を変更できます。",
    [BATTLESCROLLS_ONBOARDING_CHAT_MESSAGE] = "[Battle Scrolls] インストールありがとうございます！ジャーナル > Battle Scrollsを開いて設定と有効化を行ってください。",
    [BATTLESCROLLS_ONBOARDING_CONTINUE] = "続ける",
    [BATTLESCROLLS_ONBOARDING_FINISH] = "設定を完了",
    [BATTLESCROLLS_ONBOARDING_LETS_GO] = "行こう！",
    [BATTLESCROLLS_ONBOARDING_STEP_FORMAT] = "ステップ <<1>>/<<2>>",

    -------------------------
    -- Dynamic Overview Panel
    -------------------------
    [BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN] = "被ダメージ",
    [BATTLESCROLLS_OVERVIEW_TOP_HEALING] = "トップ回復",
    [BATTLESCROLLS_OVERVIEW_TOP_INCOMING] = "トップ被ダメージ",
    [BATTLESCROLLS_OVERVIEW_HEALING_TARGETS] = "回復対象",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES] = "ダメージ源",
}

-- Register translations
for stringId, stringValue in pairs(strings) do
    SafeAddString(stringId, stringValue, 1)
end

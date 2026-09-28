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
    [BATTLESCROLLS_UI_SWITCH_TO] = "<<1>>に切り替え",
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
    [BATTLESCROLLS_TAB_DAMAGE] = "ダメージ",
    [BATTLESCROLLS_TAB_HEALING] = "回復",
    [BATTLESCROLLS_TAB_EFFECTS] = "効果",
    [BATTLESCROLLS_TAB_EFFECTS_PLAYER] = "自分の効果",
    [BATTLESCROLLS_TAB_EFFECTS_BOSS] = "ボス効果",
    [BATTLESCROLLS_TAB_EFFECTS_GROUP] = "グループ効果",
    [BATTLESCROLLS_TAB_GROUP] = "グループ",
    [BATTLESCROLLS_TAB_ACTIVITY] = "アクティビティ",

    -------------------------
    -- Weaving Stats
    -------------------------
    [BATTLESCROLLS_HEADER_WEAVING] = "ウィービング",
    [BATTLESCROLLS_HEADER_WEAVING_BY_ABILITY] = "スキル別ウィービング",
    [BATTLESCROLLS_STAT_AVG_WEAVE_TIME] = "平均キャスト遅延時間",
    [BATTLESCROLLS_STAT_WEAVE_TIME_BEFORE] = "ウィーブ時間（前）",
    [BATTLESCROLLS_STAT_TIME_LOST] = "ロスタイム",
    [BATTLESCROLLS_STAT_LIGHT_ATTACKS] = "軽攻撃",
    [BATTLESCROLLS_STAT_HEAVY_ATTACKS] = "重攻撃",
    [BATTLESCROLLS_STAT_SKILL_ACTIVATIONS] = "スキル発動",
    [BATTLESCROLLS_STAT_CASTS] = "発動回数",
    [BATTLESCROLLS_STAT_WEAVING_ERRORS] = "ウィービングエラー",
    [BATTLESCROLLS_STAT_MISSED_LA] = "軽攻撃抜け",
    [BATTLESCROLLS_STAT_DOUBLE_LA] = "二重軽攻撃",
    [BATTLESCROLLS_TOOLTIP_DELAY_AFTER] = "キャスト後の遅延",
    [BATTLESCROLLS_TOOLTIP_DELAY_BEFORE] = "キャスト前の遅延",
    [BATTLESCROLLS_FORMAT_SECONDS] = "<<1>>秒",
    [BATTLESCROLLS_FORMAT_MILLISECONDS] = "<<1>>ミリ秒",
    [BATTLESCROLLS_TOOLTIP_INTER_CAST_DESC] = "キャスト間の平均の空き時間。スキルのグローバルクールダウンまたはキャスト時間が終わってから、次の行動までを計測します。Combat Metricsでは Weaving Average と呼ばれます。",
    [BATTLESCROLLS_TOOLTIP_TIME_LOST_DESC] = "戦闘中の短いキャスト遅延の合計。3秒以上の間隔（空白時間）は除きます。Combat MetricsではWeaving Totalです。",
    [BATTLESCROLLS_TOOLTIP_MISSED_LA_DESC] = "軽攻撃を挟まずにスキルを連続で使用した回数。",
    [BATTLESCROLLS_TOOLTIP_DOUBLE_LA_DESC] = "スキルを挟まずに軽攻撃を2回続けた回数。",

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
    [BATTLESCROLLS_SETTINGS_RECORD_IN_ADVENTURE_ZONE_TEXT] = "有効にすると、フィールドとインスタンスの設定を上書きし、<<1>>のすべての戦闘を記録します。無効の場合、効果はありません。",
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
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC] = "戦闘履歴の保存量を設定します。制限を超えると、ロックされていない古いゾーンが自動的に削除されます。個別のゾーンをロックして保護することができます。",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE] = "この制限は保存データ（戦闘、ビルド、設定）のみに適用されます。アドオンは現在の戦闘の追跡やUIの描画にもメモリを使用するため、実際の使用量はここに表示されているより高くなります。",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT] = "履歴: <<1>> MB / <<2>> MB (<<3>>%)",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PROTECTED] = "ロック済みの戦闘、ビルド、設定だけで上限を超えています。クリーンアップでは上限内に収まりません。",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS] = "プリセット (トライアル1周 ~0.3 MB、ダンジョン ~0.15 MB、プログ一晩 ~1 MB):",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XS] = "  極小: 5 MB - 最新の巻物だけ",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL] = "  小: 8 MB - 巻物ひと山",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM] = "  中: 12 MB - しっかりした戦闘日誌",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE] = "  大: 18 MB - 個人書庫",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_XL] = "  極大: 25 MB - 大書庫",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION] = "  注意: 35 MB - データ好きですね",
    [BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO] = "  まあ大丈夫でしょ: 50 MB - 自業自得です",
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
    [BATTLESCROLLS_STAT_PATCH] = "パッチ",
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
    [BATTLESCROLLS_STAT_TOTAL_PROCS] = "<<1>>発動",

    -------------------------
    -- Damage Stats Details
    -------------------------
    [BATTLESCROLLS_STAT_TOTAL_BOSS_DAMAGE] = "合計ボスダメージ",
    [BATTLESCROLLS_STAT_BOSS_DPS] = "ボスDPS",
    [BATTLESCROLLS_STAT_GROUP_SHARE] = "貢献度",
    [BATTLESCROLLS_STAT_TOTAL_DAMAGE] = "合計ダメージ",
    [BATTLESCROLLS_STAT_DPS] = "DPS",

    [BATTLESCROLLS_HEADER_BY_ABILITY] = "スキル別",

    [BATTLESCROLLS_HEADER_CASTS] = "発動",
    [BATTLESCROLLS_HEADER_BY_DAMAGE_TYPE] = "ダメージタイプ別",
    [BATTLESCROLLS_HEADER_DIRECT_VS_DOT] = "直接攻撃 vs 継続",
    [BATTLESCROLLS_HEADER_DAMAGE_DELIVERY] = "ダメージ方式",
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

    [BATTLESCROLLS_HEADER_RAW_HOT_VS_DIRECT] = "総回復（タイプ別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HOT_VS_DIRECT] = "実効回復（タイプ別）",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_TARGET] = "総回復（ターゲット別）",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_ABILITY] = "総回復（スキル別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_TARGET] = "実効回復（ターゲット別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_ABILITY] = "実効回復（スキル別）",
    [BATTLESCROLLS_HEADER_RAW_HEALING_BY_SOURCE] = "総回復（ソース別）",
    [BATTLESCROLLS_HEADER_EFFECTIVE_HEALING_BY_SOURCE] = "実効回復（ソース別）",

    [BATTLESCROLLS_STAT_DIRECT_HEALING] = "直接回復",
    [BATTLESCROLLS_STAT_HEALING_OVER_TIME] = "継続回復",
    [BATTLESCROLLS_STAT_SHIELD_HEALING] = "ダメージシールド",
    [BATTLESCROLLS_STAT_REGEN_HEALING] = "体力回復",
    [BATTLESCROLLS_DAMAGE_UNKNOWN_SHIELDED] = "不明 (シールド吸収)",
    [BATTLESCROLLS_HEALING_UNKNOWN_ABSORBED] = "不明 (吸収)",
    [BATTLESCROLLS_HEALING_HEALTH_RECOVERY] = "体力回復",

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
    [BATTLESCROLLS_EFFECT_MEMBERS] = "<<1>> メンバー",

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
    [BATTLESCROLLS_TOOLTIP_TICKS] = "ティック数",

    [BATTLESCROLLS_TOOLTIP_BY_TARGET] = "ターゲット別",
    [BATTLESCROLLS_TOOLTIP_MEAN_INTERVAL] = "平均間隔",
    [BATTLESCROLLS_TOOLTIP_MEDIAN_INTERVAL] = "中央値間隔",

    [BATTLESCROLLS_TOOLTIP_ABILITY] = "スキル",
    [BATTLESCROLLS_TOOLTIP_ABILITY_ID] = "スキルID",

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
    [BATTLESCROLLS_DELIVERY_SHIELD] = "シールド",
    [BATTLESCROLLS_DELIVERY_REGEN] = "回復",
    [BATTLESCROLLS_DELIVERY_HEAL_ABSORPTION] = "回復吸収",

    -------------------------
    -- Filter Dialog
    -------------------------
    [BATTLESCROLLS_FILTER_DAMAGE_DONE] = "ダメージフィルター",
    [BATTLESCROLLS_FILTER_BOSS_DAMAGE] = "ボスダメージフィルター",
    [BATTLESCROLLS_FILTER_BY_SOURCE] = "ソースでフィルター",
    [BATTLESCROLLS_FILTER_BY_TARGET] = "ターゲットでフィルター",
    [BATTLESCROLLS_FILTER_BY_GROUP_MEMBER] = "メンバーでフィルター",
    [BATTLESCROLLS_FILTER] = "フィルター",
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
    [BATTLESCROLLS_OVERVIEW_BOSS_DAMAGE] = "ボスダメージ",
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
    [BATTLESCROLLS_OVERVIEW_KEY_BUFFS] = "あなたのバフ",
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
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_SMOOTH] = "滑らか",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM] = "カスタム (<<1>> FPS)",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE] = "処理速度",
    [BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT] = "バックグラウンドタスクの処理速度を制御します。主にジャーナルUIと、戦闘終了から記録がリストに表示されるまでの時間に影響します。\n\nパフォーマンス重視: 最速処理。一時的なカクつきの可能性あり。\n滑らか: より滑らかなゲームプレイ、処理は遅め。記録がロード中のまま止まったり、ジャーナルに表示されない場合があります。\n\nこの設定はLibAsyncを使用するすべてのアドオンに影響します。",

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
    [BATTLESCROLLS_ONBOARDING_STORAGE_MINIMAL_DESC] = "約15回のトライアル分",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE] = "中程度 (12 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_MODERATE_DESC] = "約40回のトライアル分",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS] = "多め (25 MB)",
    [BATTLESCROLLS_ONBOARDING_STORAGE_GENEROUS_DESC] = "約80回のトライアル分",
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
    -- Delete Functionality
    -------------------------
    [BATTLESCROLLS_DELETE] = "削除",
    [BATTLESCROLLS_DELETE_INSTANCE_TITLE] = "ゾーンを削除",
    [BATTLESCROLLS_DELETE_INSTANCE_TEXT] = "<<1>>とすべての戦闘を削除しますか？",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TITLE] = "戦闘を削除",
    [BATTLESCROLLS_DELETE_ENCOUNTER_TEXT] = "<<1>>を削除しますか？",
    [BATTLESCROLLS_DELETE_WARNING] = "この操作は取り消せません。",
    [BATTLESCROLLS_DELETE_MEMORY_FREE] = "約<<1>>を解放",
    [BATTLESCROLLS_DELETE_MEMORY_STATUS] = "メモリ: <<1>> / <<2>> (<<3>>%)",

    -------------------------
    -- Dynamic Overview Panel
    -------------------------
    [BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN] = "被ダメージ",
    [BATTLESCROLLS_OVERVIEW_TOP_HEALING] = "トップ回復",
    [BATTLESCROLLS_OVERVIEW_TOP_INCOMING] = "トップ被ダメージ",
    [BATTLESCROLLS_OVERVIEW_HEALING_TARGETS] = "回復対象",
    [BATTLESCROLLS_OVERVIEW_DAMAGE_SOURCES] = "ダメージ源",

    -------------------------
    -- Instance Locking
    -------------------------
    [BATTLESCROLLS_LOCK_ERROR_TITLE] = "ロックできません",
    [BATTLESCROLLS_LOCK_ERROR_TEXT] = "このゾーンをロックするとメモリ制限を超えます。ロックされたゾーンと最新のゾーンはクリーンアップから保護されます。\n\n空き容量を確保するには、ロックされたゾーンのロックを解除または削除するか、設定でメモリ制限を増やしてください。",
    [BATTLESCROLLS_LOCK_LOCKED_SIZE] = "現在ロック中: <<1>>",
    [BATTLESCROLLS_LOCK_INSTANCE_SIZE] = "このゾーン: <<1>>",
    [BATTLESCROLLS_LOCK_LIMIT] = "メモリ制限: <<1>>",

    -------------------------
    -- Favorite Effects
    -------------------------
    [BATTLESCROLLS_FAVORITE_EFFECT] = "お気に入り",
    [BATTLESCROLLS_UNFAVORITE_EFFECT] = "お気に入り解除",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES] = "すべてのお気に入りをクリア",
    [BATTLESCROLLS_CLEAR_ALL_FAVORITES_TOOLTIP] = "すべてのお気に入りエフェクトを削除します。お気に入りのエフェクトは各エフェクトリストの上部に表示されます。",

    -------------------------
    -- Group Tab Enhancements
    -------------------------
    [BATTLESCROLLS_STAT_SURVIVABILITY] = "生存性",
    [BATTLESCROLLS_BOSS_DAMAGE_TAKEN] = "ボスからの被ダメージ",

    -- Group Member Card Strings
    [BATTLESCROLLS_GROUP_CARD_OF_GROUP] = "グループ比",
    [BATTLESCROLLS_GROUP_CARD_ALIVE] = "生存",

    -- Group Tab Redesign
    [BATTLESCROLLS_GROUP_DAMAGE_BY_TYPE] = "タイプ別ダメージ",
    [BATTLESCROLLS_GROUP_VS_AVERAGE] = "DD平均比",
    [BATTLESCROLLS_GROUP_DD_COUNTED] = "対象DD数",
    [BATTLESCROLLS_GROUP_DAMAGE_OUTPUT] = "ダメージ出力",
    [BATTLESCROLLS_GROUP_HEALING_OUTPUT] = "ヒール出力",
    [BATTLESCROLLS_GROUP_RANK] = "順位",
    [BATTLESCROLLS_GROUP_MAGICAL] = "魔法",
    [BATTLESCROLLS_GROUP_DEATH] = "死亡",
    [BATTLESCROLLS_GROUP_FIRST_DEATH] = "最初の死亡",
    [BATTLESCROLLS_GROUP_LAST_DEATH] = "最後の死亡",
    [BATTLESCROLLS_GROUP_DEATHS] = "死亡",
    [BATTLESCROLLS_GROUP_COL_DEATHS] = "死亡",
    [BATTLESCROLLS_GROUP_DEATH_COUNT] = "死亡 <<1>>回",
    [BATTLESCROLLS_GROUP_METRIC_DPS] = "<<1>> DPS",
    [BATTLESCROLLS_GROUP_METRIC_HPS] = "<<1>> HPS",
    [BATTLESCROLLS_GROUP_METRIC_DTPS] = "<<1>> DTPS",
    [BATTLESCROLLS_GROUP_METRIC_CRIT] = "クリ <<1>>%",
    [BATTLESCROLLS_GROUP_METRIC_OVERHEAL] = "過剰回復 <<1>>%",
    [BATTLESCROLLS_GROUP_TOP_INCOMING_DAMAGE] = "被ダメージ上位",
    [BATTLESCROLLS_GROUP_DEATH_AT] = "<<1>>時点",
    [BATTLESCROLLS_HEADER_DEATHS] = "死亡",
    [BATTLESCROLLS_STAT_DEATH_COUNT] = "死亡回数",
    [BATTLESCROLLS_DEATH_N] = "死亡 <<1>>",

    -- Group Context Tooltips
    [BATTLESCROLLS_TOOLTIP_GROUP_TOTAL] = "グループ合計",
    [BATTLESCROLLS_TOOLTIP_GROUP_DPS] = "グループDPS",
    [BATTLESCROLLS_TOOLTIP_GROUP_AVG] = "DD平均",
    [BATTLESCROLLS_TOOLTIP_GROUP_BREAKDOWN] = "グループ内訳",
    [BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_TAKEN] = "グループ被ダメージ",

    -- Group Table
    [BATTLESCROLLS_GROUP_COL_NAME] = "名前",
    [BATTLESCROLLS_GROUP_COL_TOTAL] = "合計",
    [BATTLESCROLLS_GROUP_COL_CRIT] = "クリ",
    [BATTLESCROLLS_GROUP_COL_ALIVE] = "生存",

    -------------------------
    -- Setup Tab
    -------------------------
    [BATTLESCROLLS_TAB_BUILD] = "ビルド",
    [BATTLESCROLLS_SETUP_ABILITIES] = "アビリティ",
    [BATTLESCROLLS_SETUP_FRONT_BAR] = "主要バー",
    [BATTLESCROLLS_SETUP_BACK_BAR] = "予備バー",
    [BATTLESCROLLS_SETUP_GEAR_SETS] = "装備セット",
    [BATTLESCROLLS_SETUP_EQUIPMENT] = "装備",
    [BATTLESCROLLS_SETUP_POISONS] = "毒",
    [BATTLESCROLLS_SETUP_CHARACTER] = "キャラクター",
    [BATTLESCROLLS_SETUP_CLASS_SKILLS] = "クラススキルライン",
    [BATTLESCROLLS_SETUP_CLASS_MASTERY] = "クラスマスタリー",
    [BATTLESCROLLS_SETUP_LOADOUT] = "兵装",
    [BATTLESCROLLS_SETUP_PERKS] = "スキル",
    [BATTLESCROLLS_SETUP_MUNDUS] = "ムンダス",
    [BATTLESCROLLS_SETUP_FOOD] = "料理",
    [BATTLESCROLLS_WEAPON_GREATSWORD] = "両手剣",
    [BATTLESCROLLS_WEAPON_BATTLE_AXE] = "両手斧",
    [BATTLESCROLLS_WEAPON_MAUL] = "両手槌",

    -------------------------
    -- Food Buff Descriptions
    -------------------------
    [BATTLESCROLLS_FOOD_MAX_HEALTH] = "最大体力",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA] = "最大マジカ",
    [BATTLESCROLLS_FOOD_MAX_STAMINA] = "最大スタミナ",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_MAGICKA] = "最大体力・マジカ",
    [BATTLESCROLLS_FOOD_MAX_HEALTH_STAMINA] = "最大体力・スタミナ",
    [BATTLESCROLLS_FOOD_MAX_MAGICKA_STAMINA] = "最大マジカ・スタミナ",
    [BATTLESCROLLS_FOOD_MAX_TRISTAT] = "最大体力・マジカ・スタミナ",
    [BATTLESCROLLS_FOOD_HEALTH_RECOVERY] = "体力回復",
    [BATTLESCROLLS_FOOD_MAGICKA_RECOVERY] = "マジカ回復",
    [BATTLESCROLLS_FOOD_STAMINA_RECOVERY] = "スタミナ回復",
    [BATTLESCROLLS_FOOD_HEALTH_MAGICKA_RECOVERY] = "体力・マジカ回復",
    [BATTLESCROLLS_FOOD_HEALTH_STAMINA_RECOVERY] = "体力・スタミナ回復",
    [BATTLESCROLLS_FOOD_MAGICKA_STAMINA_RECOVERY] = "マジカ・スタミナ回復",
    [BATTLESCROLLS_FOOD_RECOVERY_TRISTAT] = "体力・マジカ・スタミナ回復",

    -------------------------
    -- Alchemy Traits
    -------------------------
    [BATTLESCROLLS_ALCHEMY_TRAIT1] = "体力回復",
    [BATTLESCROLLS_ALCHEMY_TRAIT2] = "体力減少",
    [BATTLESCROLLS_ALCHEMY_TRAIT3] = "マジカ回復",
    [BATTLESCROLLS_ALCHEMY_TRAIT4] = "マジカ減少",
    [BATTLESCROLLS_ALCHEMY_TRAIT5] = "スタミナ回復",
    [BATTLESCROLLS_ALCHEMY_TRAIT6] = "スタミナ減少",
    [BATTLESCROLLS_ALCHEMY_TRAIT7] = "呪文耐性増大",
    [BATTLESCROLLS_ALCHEMY_TRAIT8] = "侵害",
    [BATTLESCROLLS_ALCHEMY_TRAIT9] = "防御力増大",
    [BATTLESCROLLS_ALCHEMY_TRAIT10] = "破砕",
    [BATTLESCROLLS_ALCHEMY_TRAIT11] = "呪文攻撃力上昇",
    [BATTLESCROLLS_ALCHEMY_TRAIT12] = "臆病",
    [BATTLESCROLLS_ALCHEMY_TRAIT13] = "武器攻撃力上昇",
    [BATTLESCROLLS_ALCHEMY_TRAIT14] = "不自由",
    [BATTLESCROLLS_ALCHEMY_TRAIT15] = "呪文クリティカル",
    [BATTLESCROLLS_ALCHEMY_TRAIT16] = "不信",
    [BATTLESCROLLS_ALCHEMY_TRAIT17] = "武器クリティカル",
    [BATTLESCROLLS_ALCHEMY_TRAIT18] = "弱体化",
    [BATTLESCROLLS_ALCHEMY_TRAIT19] = "猪突猛進",
    [BATTLESCROLLS_ALCHEMY_TRAIT20] = "罠",
    [BATTLESCROLLS_ALCHEMY_TRAIT21] = "探知",
    [BATTLESCROLLS_ALCHEMY_TRAIT22] = "透明化",
    [BATTLESCROLLS_ALCHEMY_TRAIT23] = "加速",
    [BATTLESCROLLS_ALCHEMY_TRAIT24] = "妨害",
    [BATTLESCROLLS_ALCHEMY_TRAIT25] = "防護",
    [BATTLESCROLLS_ALCHEMY_TRAIT26] = "脆弱",
    [BATTLESCROLLS_ALCHEMY_TRAIT27] = "体力継続",
    [BATTLESCROLLS_ALCHEMY_TRAIT28] = "体力漸減",
    [BATTLESCROLLS_ALCHEMY_TRAIT29] = "生命力",
    [BATTLESCROLLS_ALCHEMY_TRAIT30] = "汚染",
    [BATTLESCROLLS_ALCHEMY_TRAIT31] = "Heroism",
    [BATTLESCROLLS_ALCHEMY_TRAIT32] = "Timidity",

    -------------------------
    -- Aggregate
    -------------------------
    -- Navigation
    [BATTLESCROLLS_PIVOT_TITLE] = "集計",
    [BATTLESCROLLS_PIVOT_ENTRY] = "集計",
    [BATTLESCROLLS_PIVOT_ENTRY_DESC] = "戦闘やインスタンスを横断してデータを分析",
    [BATTLESCROLLS_PIVOT_ENTRY_DESC_ENCOUNTER] = "このインスタンスの戦闘を横断して集計",

    -- Scope section
    [BATTLESCROLLS_PIVOT_SCOPE] = "範囲",
    [BATTLESCROLLS_PIVOT_INSTANCE_SCOPE] = "インスタンス範囲",
    [BATTLESCROLLS_PIVOT_TIME_FILTER] = "期間",
    [BATTLESCROLLS_PIVOT_ENCOUNTER_FILTER] = "戦闘フィルター",

    -- Instance scope options
    [BATTLESCROLLS_PIVOT_SCOPE_EVERYTHING] = "すべて",
    [BATTLESCROLLS_PIVOT_SCOPE_INSTANCED] = "全インスタンス",
    [BATTLESCROLLS_PIVOT_SCOPE_OVERLAND] = "全フィールド",
    [BATTLESCROLLS_PIVOT_SCOPE_HOUSES] = "全ハウジング",
    [BATTLESCROLLS_PIVOT_SCOPE_PVP] = "全PvP",
    [BATTLESCROLLS_PIVOT_SCOPE_ZONES] = "ゾーン名で選択",
    [BATTLESCROLLS_PIVOT_SCOPE_SPECIFIC] = "特定のインスタンス",

    -- Time filter options
    [BATTLESCROLLS_PIVOT_TIME_ALL] = "全期間",
    [BATTLESCROLLS_PIVOT_TIME_TODAY] = "今日",
    [BATTLESCROLLS_PIVOT_TIME_24H] = "過去24時間",
    [BATTLESCROLLS_PIVOT_TIME_3D] = "過去3日間",
    [BATTLESCROLLS_PIVOT_TIME_7D] = "過去7日間",
    [BATTLESCROLLS_PIVOT_TIME_14D] = "過去14日間",
    [BATTLESCROLLS_PIVOT_TIME_30D] = "過去30日間",
    [BATTLESCROLLS_PIVOT_TIME_90D] = "過去90日間",
    [BATTLESCROLLS_PIVOT_TIME_CUSTOM] = "カスタム...",

    -- Encounter category options
    [BATTLESCROLLS_PIVOT_ENC_ALL] = "全戦闘",
    [BATTLESCROLLS_PIVOT_ENC_BOSS] = "ボス戦",
    [BATTLESCROLLS_PIVOT_ENC_TRASH] = "雑魚戦",
    [BATTLESCROLLS_PIVOT_ENC_PLAYER] = "PvP戦",
    [BATTLESCROLLS_PIVOT_ENC_DUMMY] = "ダミー戦",
    [BATTLESCROLLS_PIVOT_ENC_SPECIFIC] = "特定の戦闘",

    -- Query section
    [BATTLESCROLLS_PIVOT_QUERY] = "クエリ",
    [BATTLESCROLLS_PIVOT_DOMAIN] = "データ種別",
    [BATTLESCROLLS_PIVOT_ROWS] = "行",
    [BATTLESCROLLS_PIVOT_COLUMNS] = "列",
    [BATTLESCROLLS_PIVOT_VALUES] = "値",
    [BATTLESCROLLS_PIVOT_AGGREGATION] = "集計方法",
    [BATTLESCROLLS_PIVOT_FILTERS] = "フィルター",

    -- Target filter
    [BATTLESCROLLS_PIVOT_TARGETS] = "ターゲット",
    [BATTLESCROLLS_PIVOT_TARGETS_ALL] = "全ターゲット",
    [BATTLESCROLLS_PIVOT_TARGETS_BOSSES] = "ボスのみ",

    -- Domain names
    [BATTLESCROLLS_PIVOT_DOMAIN_DAMAGE] = "ダメージ",
    [BATTLESCROLLS_PIVOT_DOMAIN_HEALING_OUT] = "与回復",
    [BATTLESCROLLS_PIVOT_DOMAIN_HEALING_IN] = "被回復",
    -- Effects domain labels reuse BATTLESCROLLS_TAB_EFFECTS_* strings
    [BATTLESCROLLS_PIVOT_DOMAIN_GROUP] = "グループ",
    [BATTLESCROLLS_PIVOT_DOMAIN_OVERVIEW] = "概要",

    -- Dimension names
    [BATTLESCROLLS_PIVOT_DIM_ABILITY] = "アビリティ",
    [BATTLESCROLLS_PIVOT_DIM_TARGET] = "ターゲット",
    [BATTLESCROLLS_PIVOT_DIM_SOURCE] = "ソース",
    [BATTLESCROLLS_PIVOT_DIM_BOSS] = "ボス",
    [BATTLESCROLLS_PIVOT_DIM_DAMAGE_TYPE] = "ダメージタイプ",
    [BATTLESCROLLS_PIVOT_DIM_DELIVERY] = "方式",
    [BATTLESCROLLS_PIVOT_DIM_AOE_ST] = "AoE / 単体",
    [BATTLESCROLLS_PIVOT_DIM_BUFF_DEBUFF] = "バフ / デバフ",
    [BATTLESCROLLS_PIVOT_DIM_GROUP_MEMBER] = "グループメンバー",
    [BATTLESCROLLS_PIVOT_DIM_ROLE] = "ロール",
    [BATTLESCROLLS_PIVOT_DIM_ENCOUNTER] = "戦闘",
    [BATTLESCROLLS_PIVOT_DIM_INSTANCE] = "インスタンス",
    [BATTLESCROLLS_PIVOT_COL_METRICS] = "指標",

    -- Metric names
    [BATTLESCROLLS_PIVOT_METRIC_TOTAL_DAMAGE] = "合計ダメージ",
    [BATTLESCROLLS_PIVOT_METRIC_DPS] = "DPS",
    [BATTLESCROLLS_PIVOT_METRIC_CRIT_PERCENT] = "クリ %",
    [BATTLESCROLLS_PIVOT_METRIC_HIT_COUNT] = "ヒット数",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_HIT] = "最大ヒット",
    [BATTLESCROLLS_PIVOT_METRIC_MIN_HIT] = "最小ヒット",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_HIT] = "平均ヒット",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HEALING] = "実効回復",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HEALING] = "総回復",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS] = "総HPS",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS] = "実効HPS",
    [BATTLESCROLLS_PIVOT_METRIC_OVERHEAL_PERCENT] = "過剰回復 %",
    [BATTLESCROLLS_PIVOT_METRIC_HEAL_CRIT_PERCENT] = "回復クリ %",
    [BATTLESCROLLS_PIVOT_METRIC_HEAL_HIT_COUNT] = "回復ヒット数",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_HEAL] = "最大回復",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_HEAL] = "平均回復",
    [BATTLESCROLLS_PIVOT_METRIC_UPTIME_PERCENT] = "稼働率 %",
    [BATTLESCROLLS_PIVOT_METRIC_PLAYER_UPTIME_PERCENT] = "自分の稼働率 %",
    [BATTLESCROLLS_PIVOT_METRIC_APPLICATIONS] = "適用回数",
    [BATTLESCROLLS_PIVOT_METRIC_MAX_STACKS_TIME] = "最大スタック時間 %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DPS] = "DPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_BOSS_DPS] = "ボスDPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_TOTAL_DAMAGE] = "合計ダメージ",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_CRIT_PERCENT] = "クリ %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DOT_PERCENT] = "DoT %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_AOE_PERCENT] = "AoE %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_MAX_HIT] = "最大ヒット",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DTPS] = "DTPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_RAW_HPS] = "総HPS",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_EFFECTIVE_HPS] = "実効HPS",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_OUT] = "実効HPS (与)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_OUT] = "総HPS (与)",
    [BATTLESCROLLS_PIVOT_METRIC_EFFECTIVE_HPS_IN] = "実効HPS (被)",
    [BATTLESCROLLS_PIVOT_METRIC_RAW_HPS_IN] = "総HPS (被)",
    [BATTLESCROLLS_PIVOT_METRIC_BOSS_DPS] = "ボスDPS",
    [BATTLESCROLLS_PIVOT_METRIC_BOSS_DAMAGE] = "ボスダメージ",
    [BATTLESCROLLS_PIVOT_METRIC_DTPS] = "DTPS",
    [BATTLESCROLLS_PIVOT_METRIC_DAMAGE_TAKEN] = "被ダメージ",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_ALIVE_PERCENT] = "生存 %",
    [BATTLESCROLLS_PIVOT_METRIC_GROUP_DEATH_COUNT] = "死亡",
    [BATTLESCROLLS_PIVOT_METRIC_DURATION] = "持続時間",
    [BATTLESCROLLS_PIVOT_METRIC_DEATH_COUNT] = "死亡",
    [BATTLESCROLLS_PIVOT_METRIC_AVG_WEAVE_TIME] = "キャスト遅延",
    [BATTLESCROLLS_PIVOT_METRIC_TIME_LOST] = "ロスタイム",
    [BATTLESCROLLS_PIVOT_METRIC_LIGHT_ATTACKS_PER_SEC] = "LA/s",
    [BATTLESCROLLS_PIVOT_METRIC_WEAVING_ERRORS] = "軽攻撃抜け",
    [BATTLESCROLLS_PIVOT_METRIC_DOUBLE_LA_ERRORS] = "二重軽攻撃",

    -- Aggregation options
    [BATTLESCROLLS_PIVOT_AGG_SUM] = "合計",
    [BATTLESCROLLS_PIVOT_AGG_AVG] = "平均",
    [BATTLESCROLLS_PIVOT_AGG_MAX] = "最大",
    [BATTLESCROLLS_PIVOT_AGG_MIN] = "最小",

    -- Actions
    [BATTLESCROLLS_PIVOT_RUN] = "クエリ実行",
    [BATTLESCROLLS_PIVOT_SAVE] = "クエリ保存",
    [BATTLESCROLLS_PIVOT_LOAD] = "クエリ読込",
    [BATTLESCROLLS_PIVOT_DELETE_QUERY] = "クエリ削除",

    -- Loading / Results
    [BATTLESCROLLS_PIVOT_LOADING] = "戦闘を読み込み中... <<1>> / <<2>>",
    [BATTLESCROLLS_PIVOT_NO_RESULTS] = "クエリに一致するデータがありません",
    [BATTLESCROLLS_PIVOT_NO_ENCOUNTERS] = "フィルターに一致する戦闘がありません",
    [BATTLESCROLLS_PIVOT_NO_BOSSES] = "フィルターに一致するボス戦がありません",
    [BATTLESCROLLS_PIVOT_ENCOUNTERS_PROCESSED] = "<<1>>件の戦闘を処理済み",
    [BATTLESCROLLS_PIVOT_ROWS_CAPPED] = "結果は<<1>>行に制限されました",
    [BATTLESCROLLS_PIVOT_COLUMNS_CAPPED] = "結果は<<1>>列に制限されました",
    [BATTLESCROLLS_PIVOT_TIP_DOMAIN_OVERVIEW] = "ダメージ、回復、エフェクト全ドメインの集約サマリー。個別の内訳ではなく、合計値を表示します。",
    [BATTLESCROLLS_PIVOT_TIP_ENC_BOSS_NAMES] = "選択したボスが登場する戦闘のみ表示します。次のステップでボス名を選択してください。",
    [BATTLESCROLLS_PIVOT_TIP_DIM_DELIVERY] = "適用方法でデータを分割：直接、DoT（継続ダメージ）、回復吸収、HoT（継続回復）、回復、シールド、または混合。",
    [BATTLESCROLLS_PIVOT_TIP_DIM_DAMAGE_TYPE] = "ダメージタイプでデータを分割：物理、炎、雷、氷、魔法、毒、疫病、出血、オブリビオンなど。",
    [BATTLESCROLLS_PIVOT_TIP_DOMAIN_GROUP] = "メンバーごとの戦闘データ（DPS、合計ダメージ、クリティカル率など）。グループメンバーのバフ/デバフ持続時間はグループエフェクトを使用してください。",
    [BATTLESCROLLS_PIVOT_TIP_AGGREGATION] = "複数の戦闘が同じセルに集約される際の計算方法。例えば、平均DPSは戦闘間の平均値を、最大は最も高い単一戦闘の値を表示します。",

    -- Save dialog
    [BATTLESCROLLS_PIVOT_SAVE_TITLE] = "クエリ保存",
    [BATTLESCROLLS_PIVOT_SAVE_PROMPT] = "このクエリの名前を入力してください:",
    [BATTLESCROLLS_PIVOT_SAVE_OVERWRITE] = "「<<1>>」という名前のクエリが既に存在します。上書きしますか？",

    -- Load/delete dialog
    [BATTLESCROLLS_PIVOT_QUERY_SAVED] = "クエリを「<<1>>」として保存しました",
    [BATTLESCROLLS_PIVOT_LOAD_TITLE] = "クエリ読込",
    [BATTLESCROLLS_PIVOT_DELETE_CONFIRM] = "クエリ「<<1>>」を削除しますか？",

    -- Selector dialogs
    [BATTLESCROLLS_PIVOT_SELECT_ZONES] = "ゾーンを選択",
    [BATTLESCROLLS_PIVOT_SELECT_INSTANCES] = "インスタンスを選択",
    [BATTLESCROLLS_PIVOT_SELECT_ENCOUNTERS] = "戦闘を選択",
    [BATTLESCROLLS_PIVOT_SELECT_BOSSES] = "ボス名を選択",
    [BATTLESCROLLS_PIVOT_SELECT_METRICS] = "指標を選択",
    [BATTLESCROLLS_PIVOT_SELECTED_COUNT] = "<<1>>件選択中",
    [BATTLESCROLLS_PIVOT_SELECT_ALL] = "すべて選択",
    [BATTLESCROLLS_PIVOT_DESELECT_ALL] = "すべて解除",
    [BATTLESCROLLS_PIVOT_NONE_SELECTED] = "未選択",

    -- Filter/range
    [BATTLESCROLLS_PIVOT_ENC_BOSS_NAMES] = "ボス名で選択",
    [BATTLESCROLLS_PIVOT_CUSTOM_DAYS] = "過去<<1>>日間",
    [BATTLESCROLLS_PIVOT_CUSTOM_DAYS_PROMPT] = "遡る日数",
    [BATTLESCROLLS_PIVOT_CUSTOM_RANGE_TITLE] = "カスタム期間",

    -- Query description
    [BATTLESCROLLS_PIVOT_DESC_BY] = "<<2>>別 <<1>>",
    [BATTLESCROLLS_PIVOT_DESC_CROSS] = "× <<1>>",
    [BATTLESCROLLS_PIVOT_DESC_N_METRICS] = "指標<<1>>件",
}

-- Register translations
for stringId, stringValue in pairs(strings) do
    SafeAddString(stringId, stringValue, 1)
end

BATTLESCROLLS_KEYBIND_ICON_SCALE = 109  -- CJK: 180 * 17/28

-- v17 storage migration
local migrationStrings = {
    [BATTLESCROLLS_MIGRATION_START] = "一回限りのストレージアップグレードを実行中 - 数分間カクつく場合があります",
    [BATTLESCROLLS_MIGRATION_DONE] = "ストレージのアップグレード完了！<<1>>件の戦闘を再エンコードし、<<2>> MBを解放しました",
    [BATTLESCROLLS_MIGRATION_TIP] = "設定でメモリプリセットを下げられるようになりました。新形式では1MBあたりに保存できる履歴が大幅に増えています。",
}
for stringId, stringValue in pairs(migrationStrings) do
    SafeAddString(stringId, stringValue, 1)
end

-- Online sharing
local shareStrings = {
    [BATTLESCROLLS_SHARE_FIGHT] = "戦闘を共有",
    [BATTLESCROLLS_SHARE_INSTANCE] = "全戦闘をアップロード",
    [BATTLESCROLLS_SHARE_PREPARING] = "共有の準備中...",
    [BATTLESCROLLS_SHARE_TITLE] = "共有",
    [BATTLESCROLLS_SHARE_PROGRESS_HEADER] = "パート",
    [BATTLESCROLLS_SHARE_PART_SENT] = "パート<<1>> — 送信済み",
    [BATTLESCROLLS_SHARE_PART_READY] = "パート<<1>> — 送信可能",
    [BATTLESCROLLS_SHARE_PART_PENDING] = "パート<<1>>",
    [BATTLESCROLLS_SHARE_SEND_PART] = "パート<<1>>/<<2>>を送信",
    [BATTLESCROLLS_SHARE_HINT_HEADER] = "使い方",
    [BATTLESCROLLS_SHARE_PRIVACY_TITLE] = "プレイヤー名と戦闘データがオンラインに保存されます",
    [BATTLESCROLLS_SHARE_PRIVACY_NOTICE] = "自分や他のプレイヤーの名前、プラットフォーム、ゲームサーバー、戦闘統計、ビルドが送信されます。レポートに自動の保存期限はなく、リンクを知っている人は誰でも閲覧・ダウンロードできます。共有前に対象プレイヤーに知らせてください。プライバシーと削除請求：<<1>>",
    [BATTLESCROLLS_SHARE_TT_READY] = "ゲームの確認ダイアログを承認してください。開いたブラウザページが戦闘データのこのパートを共有サイトへ転送します。その後ブラウザは閉じて構いません。ゲームに戻って次のパートを送信してください。この画面を離れても進行状況は保持されます。すべてのパートが届くと、ページに非公開の共有リンクとQRコードが表示されます。",
    [BATTLESCROLLS_SHARE_TT_SENT] = "このパートはすでにブラウザへ渡されています。ブラウザのページで不足と表示された場合（クラッシュしたタブはそのパートを失います）、この行を選択して再送信キーを押してください。",
    [BATTLESCROLLS_SHARE_TT_PENDING] = "パートは順番に1つずつ送信されます。このパートは順番が来ると送信できるようになります。",
    [BATTLESCROLLS_SHARE_TT_DONE] = "ブラウザのページに非公開の共有リンクとQRコードが表示されています。リンクを知っている人だけが開けます。不足しているパートが表示された場合は、上で選択して再送信してください。「送信を完了」でゲーム側のアップロード情報を破棄します。",
    [BATTLESCROLLS_SHARE_CHOICE_HEADER] = "送信内容の選択",
    [BATTLESCROLLS_SHARE_CHOICE_FULL] = "すべての戦闘（<<1>>）",
    [BATTLESCROLLS_SHARE_CHOICE_BOSSES] = "ボスのみ（<<1>>）",
    [BATTLESCROLLS_SHARE_CHOICE_PARTS] = "送信パート数: <<1>>",
    [BATTLESCROLLS_SHARE_TT_CHOICE_FULL] = "このインスタンスで記録したすべての戦闘（雑魚戦を含む）。データが多いほど、ブラウザで送るパート数も増えます。",
    [BATTLESCROLLS_SHARE_TT_CHOICE_BOSSES] = "ボス戦のみ。通常は雑魚戦が容量の大半を占めるため、送信パート数が大幅に減ります。",
    [BATTLESCROLLS_SHARE_DONE_HEADER] = "すべてのパートを送信しました",
    [BATTLESCROLLS_SHARE_DONE_HINT] = "リンクとQRコードはブラウザのページにあります。",
    [BATTLESCROLLS_SHARE_CONTINUE] = "共有を続ける",
    [BATTLESCROLLS_SHARE_CANCEL] = "共有を中止",
    [BATTLESCROLLS_SHARE_FAILED] = "共有を準備できませんでした。",
    [BATTLESCROLLS_SHARE_RESEND_PART] = "パート<<1>>を再送",
    [BATTLESCROLLS_SHARE_PART_RESENDING] = "パート<<1>> — 再送中…",
    [BATTLESCROLLS_SHARE_FINISH] = "共有を完了",
}
for id, str in pairs(shareStrings) do
    SafeAddString(id, str, 1)
end

-- 新機能：名前変更、レイドダメージ、蘇生、バーの色、アルティメット、クルックス、ズェン
local featureStrings = {
    [BATTLESCROLLS_RENAME] = "名前を変更",
    [BATTLESCROLLS_RENAME_TEXT] = "新しい名前を入力してください。元の名前（<<1>>）を入力するとリセットされます。",

    [BATTLESCROLLS_TAB_GROUP_DAMAGE] = "グループダメージ",
    [BATTLESCROLLS_FILTER_GROUP_DAMAGE] = "グループダメージのフィルター",
    [BATTLESCROLLS_FILTER_OTHERS] = "その他",
    [BATTLESCROLLS_TOOLTIP_GROUP_DAMAGE_SCOPE] = "ゲームクライアントが確認したすべてのダメージです。自分のダメージ（ペットとコンパニオンを含む）と、周囲の他プレイヤーのダメージが含まれます。ESOは他プレイヤーを個別に識別しないため、そのダメージは「その他」にまとめて表示します。",

    [BATTLESCROLLS_GROUP_COL_RES] = "蘇生",

    [BATTLESCROLLS_SETTINGS_BAR_COLOR] = "自分のバーの色",
    [BATTLESCROLLS_SETTINGS_BAR_COLOR_TEXT] = "Battle Scrollsの「バー」デザインを使うグループメンバーには、あなたのバーがこの色で表示されます。自分が別のデザインを使っていても、グループメーターを無効にしていても適用されます。",
    [BATTLESCROLLS_COLOR_DEFAULT] = "デフォルト",
    [BATTLESCROLLS_COLOR_WHEEL] = "色相と彩度",
    [BATTLESCROLLS_COLOR_BRIGHTNESS] = "明るさ",
    [BATTLESCROLLS_COLOR_HEX] = "16進数コード",
    [BATTLESCROLLS_COLOR_HEX_INVALID] = "6桁の16進数を入力してください（例：#3EB6FF）。",
    [BATTLESCROLLS_COLOR_SAVE] = "保存",
    [BATTLESCROLLS_COLOR_SAVE_HINT] = "自分のデザインに関係なく、Battle Scrollsの「バー」を使う全員にあなたのバーがこの色で表示されます。",

    [BATTLESCROLLS_HEADER_ULTIMATE] = "アルティメット",
    [BATTLESCROLLS_STAT_ULT_AT_ENTRY] = "戦闘開始時のアルティメット",
    [BATTLESCROLLS_STAT_ULT_GENERATED] = "獲得したアルティメット",
    [BATTLESCROLLS_STAT_ULT_SPENT_DRAINED] = "消費・喪失したアルティメット",
    [BATTLESCROLLS_STAT_ULT_SPENT] = "消費したアルティメット",
    [BATTLESCROLLS_STAT_ULT_LOST] = "使用時の損失",
    [BATTLESCROLLS_STAT_ULT_LOST_TT] = "アルティメットを使うとゲージ全体が空になるため、そのコストを超えた分はすべて失われます。",
    [BATTLESCROLLS_STAT_ULT_DRAINED] = "喪失したアルティメット",
    [BATTLESCROLLS_HEADER_ULT_SOURCES] = "アルティメット獲得源",
    [BATTLESCROLLS_ULT_BASE_GENERATION] = "基本獲得",
    [BATTLESCROLLS_ULT_HEROISM_LINE] = "<<C:1>>を含む：維持率<<2>>%、約<<3>>",
    [BATTLESCROLLS_HEADER_ULT_CASTS] = "使用したアルティメット",

    [BATTLESCROLLS_HEADER_CRUX] = "クラッツ",
    [BATTLESCROLLS_STAT_CRUX_GENERATORS] = "生成スキル使用回数",
    [BATTLESCROLLS_STAT_CRUX_AT_FULL] = "クラッツ満杯時の使用",
    [BATTLESCROLLS_STAT_CRUX_SPENDERS] = "消費スキル使用回数",
    [BATTLESCROLLS_STAT_CRUX_UNDER] = "クラッツ3未満での使用",
    [BATTLESCROLLS_CRUX_AT_N] = "クラッツ<<1>>時：<<2>>",
    [BATTLESCROLLS_HEADER_CRUX_BY_ABILITY] = "スキル別クラッツ使用状況",

    [BATTLESCROLLS_HEADER_ZEN] = "継続ダメージの重ね掛け（ズェン）",
    [BATTLESCROLLS_ZEN_AVG_DOTS] = "平均DoT数",
    [BATTLESCROLLS_ZEN_UPTIME] = "自分のズェンの維持率",
    [BATTLESCROLLS_ZEN_PEAK_TIME] = "<<1>>の時間",
    [BATTLESCROLLS_ZEN_DOTS_LABEL] = "DoT <<1>>個",
    [BATTLESCROLLS_ZEN_SHARE_LINE] = "平均<<1>> — DoT5個で<<2>>",
    [BATTLESCROLLS_ZEN_SHORT] = "ズェン",
    [BATTLESCROLLS_ZEN_NOTE] = "ズェンのセットを装備していなくても、自分のDoTを記録します。自分のズェンのデバフが有効なら、どの程度のボーナスを与えられるかが分かります。自分のズェンが付与されていない時間は、あくまで可能性を示します。",
    [BATTLESCROLLS_ZEN_DISTRIBUTION_NOTE] = "各DoT行は、記録時間に占めるそのDoT数の時間の割合を示します。ズェンの割合は、その行の時間のうち自分のデバフが有効だった割合です。",

    [BATTLESCROLLS_HEADER_SUPPORT] = "サポート",
    [BATTLESCROLLS_STAT_RESURRECTIONS] = "蘇生",
}
for id, str in pairs(featureStrings) do
    SafeAddString(id, str, 1)
end

local cruxPassiveStrings = {
    [BATTLESCROLLS_STAT_CRUX_PASSIVE] = "スキル外での喪失",
    [BATTLESCROLLS_STAT_CRUX_PASSIVE_TT] = "消費スキルの使用も死亡もないまま、自然に消えたクラッツ。クラッツは30秒で消滅します。",
    [BATTLESCROLLS_STAT_CRUX_DEATH] = "死亡による喪失",
    [BATTLESCROLLS_STAT_CRUX_PROC_WASTED] = "クラッツ満杯時のパッシブ獲得",
    [BATTLESCROLLS_STAT_CRUX_PROC_WASTED_TT] = "すでにクラッツが3つある状態で発動し、何も得られなかったパッシブ獲得。「<<1>>」とその派生、および<<2>>はクラッツが0のときにしか付与しないため、ここには含まれません。",
    [BATTLESCROLLS_STAT_CRUX_CONDITIONAL_TT] = "この発生源がスキルの使用なしに、受動的に生成したクラッツ。",
    [BATTLESCROLLS_STAT_CRUX_OTHER] = "その他のクラッツ増加",
    [BATTLESCROLLS_STAT_CRUX_OTHER_TT] = "その時点で追跡中の発生源が何も発動していないのに得たクラッツ。",
    [BATTLESCROLLS_HEADER_CRUX_GAINED] = "スキル別クラッツ獲得",
}
for id, str in pairs(cruxPassiveStrings) do
    SafeAddString(id, str, 1)
end

local activityOverviewStrings = {
    [BATTLESCROLLS_STAT_DOWNTIME] = "空白時間",
    [BATTLESCROLLS_TOOLTIP_DOWNTIME_DESC] = "キャスト間の3秒以上の空白。ギミック処理、蘇生、死亡中などです。キャスト遅延には含まれません。",
    [BATTLESCROLLS_STAT_PER_MINUTE] = "<<1>>/分",
    [BATTLESCROLLS_DETAIL_MEDIAN] = "中央値 <<1>>",
    [BATTLESCROLLS_DETAIL_DELAY] = "遅延 <<1>>",
    [BATTLESCROLLS_DETAIL_AT_FULL] = "満杯時 <<1>>",
    [BATTLESCROLLS_DETAIL_LOST] = "損失 <<1>>",
    [BATTLESCROLLS_DETAIL_AVG_DOTS] = "平均<<1>>DoT",
    [BATTLESCROLLS_DETAIL_AT_DOTS] = "<<2>>で<<1>>",
}
for id, str in pairs(activityOverviewStrings) do
    SafeAddString(id, str, 1)
end

-- Release history
SafeAddString(BATTLESCROLLS_WHATS_NEW, "更新情報", 1)
SafeAddString(BATTLESCROLLS_WHATS_NEW_DESC, "最新の更新から最初の公開版まで、Battle Scrollsの変更履歴を確認できます。", 1)
SafeAddString(BATTLESCROLLS_RELEASE_6_0_0, [=[
|cD4AF37新機能：|r

- |cD4AF37巻物がタムリエルの外へ！|r ジャーナルから戦闘単体や攻略全体を共有し、ブラウザで開けます。テレビのQRコードを読み取って、スマートフォンでリンクを開きましょう。そこから自分で戦闘を詳しく確認したり、好きな場所で共有したりできます

- アドオンと同じ戦闘・|cFFFFFFビルド|rデータを確認でき、|cFFFFFFCSVやJSON|rに出力して自分で分析することもできます

- |cFFFFFFアクティビティ|rに|cFFFFFFアルティメット|rの獲得と消費、アルカニストのクラッツ使用、ズェンの接触に必要な継続ダメージの重なり、蘇生を追加。DoT数から、セットを装備していなくてもズェンで与えられるボーナスの目安が分かります。ウィービングでは短い発動の遅れと長い空白時間を分けて確認できます

- 自分の死亡時の詳細情報に、取得できた|cFFFFFF攻撃者の名前|rが表示されるようになりました

- |cFFFFFFグループダメージ|rには、Battle Scrollsを使っていないプレイヤーも含め、クライアントが観測したすべてのダメージを表示。ESOは他者の発生源を特定しないため、「|cFFFFFFその他|r」にまとめます

- 全員の「バー」メーターに表示される自分の|cFFFFFFバーの色|rを選択でき、履歴の攻略や戦闘の名前も変更できます

- ジャーナルに日付付きの|cFFFFFF更新情報|rを追加。過去の履歴も全7言語で読めます。読み逃した巻物がある方へ

|cD4AF37大きな変更：|r

- 保存形式を改良し、同じ容量でより|cFFFFFF多くの戦闘|rを保存できるようになりました。新しい形式では、大規模な戦闘後の|cFFFFFFカクつきが減り|r、ジャーナルで戦闘を開く際の|cFFFFFF読み込みも大幅に速くなる|rはずです。既存の履歴はログイン後にバックグラウンドで|cFFFFFF自動変換|rします。一度限りの処理中は一時的に動作が重くなる場合があります。置き換える前に各戦闘を元データと照合します

|cD4AF37不具合修正：|r

- 死亡時にグループがまだ戦っているのに戦闘記録が早く終了する問題は、|cFFFFFF大幅に起こりにくくなるはずです|r。特にルーセント要塞の最終戦で目立っていた問題です

- |cFFFFFF回復計算|rで一部のフィルターが無視される問題、他のグループメンバーの|cFFFFFFビルド|rで毒が表示されない問題、グループ共有と履歴整理の一部の問題を修正

- グループの戦闘|cFFFFFF概要|rと|cFFFFFFビルド|rの共有を改善し、扉を通った後やロード画面の後にデータが欠ける問題を軽減しました

|cE6B566既知の問題：|r

- 保存形式の更新で空いた容量がESOのアドオン|cFFFFFFメモリー|r表示に反映されるまで、UIのリロードが必要な場合があります

- |cFFFFFFアップデート51の錬金術の変更|rにより、ビルド内の毒の効果名が表示されない、または誤って表示される場合があります。作成した毒の効果はウェブ版には表示されません

- |cFFFFFFPlayStation|rではウェブ共有をテストしていません。まったく動作しない場合も含め、問題があればぜひご報告ください]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_3_1, [=[|cD4AF37不具合修正：|r

- グループの|cFFFFFFビルド|rで、他のプレイヤーの|cFFFFFFクラスマスタリー|rとスキルラインが正しく表示されるようになりました]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_3_0, [=[|cD4AF37新機能：|r

- |cFFFFFFクラスマスタリー|rのパッシブに対応。1つ以上購入していれば、スキルラインの一覧の代わりに表示します

- |cFFFFFF復讐|rに対応。専用の|cFFFFFFビルド|r概要で不要な情報を隠し、兵装と固有のスキルを表示します

|cD4AF37小さな変更：|r

- 英語では通常の敵集団を開発者の表現に合わせてtrashからbasepopに変更]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_2_0, [=[|cD4AF37新機能：|r

- |cFFFFFF体力回復|rを独立した回復タイプとして記録。総回復量は戦闘中の|cFFFFFF体力回復|r値から、実効回復と過剰回復は実際の体力変化から推定します

- プレイヤーに付与された|cFFFFFF回復吸収|rを、独立した被ダメージタイプとして記録

- シールドに吸収された与ダメージと被ダメージを、合計とDPS/DTPSに含めます。ただしスキル別・タイプ別内訳には含めません

- 吸収された与回復と被回復を、他者への回復、自己回復、被回復およびHPSに含めます

|cD4AF37小さな変更：|r

- 詳細一覧は常に最大50スキル、20対象/発生源を表示。以前は状況により25/15/10でした

|cD4AF37不具合修正：|r

- 与回復の方式別集計でも、他の集計と同様に自己回復を含めます

|cE6B566既知の問題：|r

- ESOは|cFFFFFF体力回復|rの正確なタイミングを通知しないため、生存時間から総回復量を推定します。同時にダメージを受けて体力が減っている場合、実効回復の一部を検出できないことがあります]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_1_0, [=[|cD4AF37新機能：|r

- 自分とグループに付与したシールドを回復として記録。付与量が総回復量、実際に吸収したダメージが実効回復です

- シールドを直接回復・継続回復と並ぶ独立したタイプとして、各タブ、|cFFFFFF概要|r、与回復の集計に表示

|cE6B566既知の問題：|r

- 同じ対象に50ミリ秒以内に複数のシールドが付与されると、まれに別スキルの回復として記録されることがあります

|cD4AF37小さな変更：|r

- ダメージ、回復、効果、発動、|cFFFFFFウィービング|r、|cFFFFFFビルド|rの各画面で、ツールチップにESOのスキルIDを表示

- 一部のスキルで誤ったアイコンや汎用アイコンが表示される問題を修正。対象は「実用的な運命の彫刻家」「輝く栄光」「セファリアークのフレイル」、薬、「エッセンスドレイン」「統率力」、シナジー「浄化」「血の宴」、「静かな海のルーンガード」「浄化の光」「熟練の魔術」、特性「信頼」などです

- 個人メーターを満たすために必要なHPSを引き上げ

- 回復構成を「タイプ別回復」と表示し、意味のない単一タイプの内訳を省略

|cD4AF37不具合修正：|r

- |cFFFFFFウィービング|rで軽攻撃の欠落・連続入力の誤判定を軽減

- 効果追跡を無効にした場合のボス判定を改善

- 一部の回復説明で平均値が最小値を下回る問題を修正]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_5_0_0, [=[|cD4AF37新機能：|r

- |cFFFFFFウィービング|r追跡を追加！ 発動間の平均・合計ロス時間と、抜けた軽攻撃やスキルを全体・スキル別に表示

- データを確認する新しい「|cFFFFFFアクティビティ|r」タブ

- 集計でも、対象領域が「|cFFFFFF概要|r」の場合に|cFFFFFFウィービング|rデータを利用できます

|cD4AF37小さな変更：|r

- 発動追跡を|cFFFFFF概要|rから|cFFFFFFアクティビティ|rへ移動。ずっとあったことに気づいていましたか？

- 戦闘中・戦闘外の|cFFFFFFメモリー|r使用量と性能を改善。特に効果追跡を一部または全部無効にしている場合に有効です

|cD4AF37不具合修正：|r

- 効果追跡を無効にしたプレイヤーの生存率が常に100%になる問題を修正]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_4_0_0, [=[|cD4AF37新機能：|r

- 「ファンタジーMMORPGにも|cFFFFFF表計算|rがほしい」と思ったことはありますか？ たぶんないでしょうが、実装しました。任意の数の過去の戦闘から必要なデータを集計し、|cFFFFFFピボットテーブル|rにもできます

|cD4AF37小さな変更：|r

- 各戦闘に11.3.5などのゲームバージョンを表示

- Battle Scrollsを開いている間、他のプレイヤーには巻物を読んでいるように見えます。やはり巻物ですよね

- 戦闘一覧の見出しにエリア名を表示

|cD4AF37不具合修正：|r

- グループのプリズム消費低減付呪を正しく表示

- グループと|cFFFFFFビルド|rのタブで|cFFFFFFビルド|rのレイアウトを統一]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_1_0, [=[|cD4AF37新機能：|r

- 所持品と同様に使える|cFFFFFF検索|rを|cFFFFFF効果タブ|rに追加

|cD4AF37不具合修正：|r

- 他のグループメンバーが使うアルカニストの|cFFFFFFビルド|rで、種族・クラス・ムンダスの行が欠ける問題を修正

- グループメニューの|cFFFFFFちらつき|rを再び軽減]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_0_2, "|cFFFFFFグループメニューのちらつきを軽減|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_0_1, [=[|cD4AF37不具合修正：|r

- 空きスロットがある場合にグループメンバーの|cFFFFFFチャンピオンポイント|rが別の星座に入る問題を修正。送信側の修正なので、相手も更新する必要があります

- |cFFFFFFビルド|rがあるプレイヤーから、データがないプレイヤーへ移動した際に、存在しない情報を表示しようとする問題を修正]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_3_0_0, [=[|cD4AF37ビルド記録|r

- 各戦闘で|cFFFFFFビルド|rを保存し、新しい|cFFFFFFビルド|rタブに表示。何を使って戦っていたか正確に振り返れます

- |cFFFFFF概要|rにも|cFFFFFFビルド|rの大部分を表示し、結果を披露しやすくしました

- |cFFFFFFキャラクターメニュー|rに簡潔な|cFFFFFFビルド|r概要を追加

- |cFFFFFFグループタブ|rでもBattle Scrollsを使う他のグループメンバーの|cFFFFFFビルド|rを記録します]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_1_2, "|cFFFFFF見た目の変更なし。バージョン3への準備です|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_1_1, "|cFFFFFF更新されたドラゴンナイトに合わせて範囲・単体ダメージの計算を変更。過去の戦闘にも適用されます。|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_1_0, [=[- 新しいナビゲーション階層「|cFFFFFFサブカテゴリ|r」を追加。関連する表示を同じタブにまとめ、方向パッドか左スティックの左右で切り替えます
  - 与ダメージとボスへのダメージを「ダメージ」に統合
  - 他者への回復、自己回復、被回復を「回復」に統合
  - 自分、ボス、グループの効果を、長い一覧ではなく別々の|cFFFFFFサブカテゴリ|rに分割

- 「Attempt to read past end of buffer」エラーを抑制。戦闘終了後にロード画面を通るとグループデータが不正確になる場合は残りますが、少なくともエラーが突然画面を塞ぐことはありません]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_2_0_1, [=[|cD4AF37グループジャーナル|r

Battle Scrollsを使うグループメンバーが参加した戦闘に、新しい|cFFFFFFグループタブ|rを追加。

|cD4AF37概要：|r

- 各ボス、DPS、クリティカル率、DTPS、HPS、生存率、死亡数で並べ替え可能な比較表

|cD4AF37プレイヤー別詳細：|r

- ダメージ：DPS、合計、クリティカル率、最大ヒット、直接・範囲ダメージ、タイプ別内訳、DPS順位とDD平均との比較

- 生存：DTPS、生存時間、死亡数、主な被ダメージスキル、死亡状況

- 回復：総HPS、実効HPS、過剰回復、自己回復

- ボス別の与ダメージ、構成、被ダメージ

|cD4AF37データがある場合、既存の説明にもグループ情報を表示：|r

- ボス対象にメンバー別DPSと貢献率。DPS・ボスDPS行にもメンバー別内訳

- DTPSと被ダメージの発生源にメンバー別DTPS

- ダメージ構成にDD平均との比較

- 与回復・自己回復の総HPSと過剰回復にメンバー別内訳

|cD4AF37死亡追跡：|r

- 死亡状況を戦闘と一緒に保存

- |cFFFFFF概要|r：被ダメージ欄に死亡数

- 被ダメージ：死亡時刻と説明内の詳細

- グループ：最初と最後の死亡について全攻撃を表示

|cD4AF37小さな変更：|r

- |cFFFFFF概要|rは継続ダメージ率ではなく直接ダメージ率を表示

- |cFFFFFF夜の市場|rの戦闘を、通常のエリアフィルターに関係なくすべて記録する設定を追加

- DPSメーターを戦利品履歴など他のUIの背面に配置

- すべてのタブで|cFFFFFF概要|rを初期選択。少し|cFFFFFFメモリー|rが増えますが、空きメモリーなんて必要ありませんよね？

- プレイヤー名の@を省略

- Hodorと「バー」の見出しに戦闘時間

- フィルター・エリアのダイアログ音を変更

|cD4AF37翻訳：|r

- 複数形の修正

- ロシア語とドイツ語で、スタックを表す用語を装備セットの説明に合わせました]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_6, "|cFFFFFFLibGroupBroadcastがない状態でログインすると発生するUIエラーを修正|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_5, "|cFFFFFFコンソール版アドオンの混乱への暫定対応として、LibGroupBroadcastを任意依存に変更|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_4, "|cFFFFFF見た目の変更なし。ジャーナルでグループのDPSを表示するための準備です|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_3, "|cFFFFFF見た目の変更なし。ジャーナルでグループのDPSを表示するための準備です|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_2, [=[|cD4AF37不具合修正：|r

- グループにいないときにDPSデータを送信しなくなりました。DakJanielsによる修正です]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_1, [=[|cD4AF37不具合修正：|r

- ルーセント要塞の最終戦や、ポータルなどで一時的にボスから離れる戦闘でボス判定を改善

- ルーセント要塞の最終戦やオセインの檻の初戦など、複雑な戦闘後に発生する「|cFFFFFF1000ms limit hit|r」エラーを修正]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_3_0, [=[|cD4AF37新機能：|r

- 効果を|cFFFFFFお気に入り|rにすると、登場するすべての一覧の先頭に固定されます

|cD4AF37不具合修正：|r

- 途中参加したグループメンバーの効果時間は、実際に参加していた時間だけで計算

- 一部のグループメーターで、最初の戦闘開始時に左上へ空の要素が一瞬出る問題を修正

|cD4AF37小さな変更：|r

- DD欄が1人でも合計DPS行を表示]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_2_0, [=[|cD4AF37新機能：|r

- エリア一覧で|cFFFFFFX/四角|rを押すとロックできます。保存容量を超えても自動|cFFFFFF削除|rされません。最新エリアも常に保護されます

|cD4AF37翻訳：|r

- ドイツ語とロシア語のエリア表現を統一

|cD4AF37不具合修正：|r

- スムーズ設定で読み込みが止まる、または戦闘がジャーナルに追加されない問題を修正。更新時、この設定を使っていた方は標準のパフォーマンス設定に戻ります]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_1_0, [=[|cD4AF37新機能：|r

- 履歴から個別のエリアや戦闘を|cFFFFFF削除|rできます

|cD4AF37不具合修正：|r

- アドオンのスムーズ設定と画質モード「フィデリティ」の組み合わせで読み込みが終わらない、またはメニューに表示されない問題を修正。すでに影響を受けた場合、更新後に追加で|cFFFFFF/reloadui|rが必要なことがあります

- フィルター使用後にアイテム破壊などのゲーム内ダイアログでエラーになる問題を修正

- Battle Scrollsからジャーナルに戻る際のアニメーション方向を修正]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_3, "|cFFFFFFPS5のセーブデータ破損に対する、手探りでの修正の試み|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_2, [=[|cD4AF37保存と効果追跡の改善|r

|cD4AF37保存：|r

- エンコード・デコードを最適化し、ジャーナル読み込みを高速化

- 戦闘処理時の|cFFFFFFメモリー|r使用量を削減

|cD4AF37効果：|r

- 戦闘中にメンバーが切断した場合の効果時間を修正

- 戦闘途中の再接続への対応を改善]=], 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_1, "|cFFFFFF不具合修正|r", 1)
SafeAddString(BATTLESCROLLS_RELEASE_1_0_0, [=[|cD4AF37最初の公開版|r

|cD4AF37DPSメーター：|r

- 戦闘ダメージをリアルタイム表示

- 個人向け：標準、最小、バー

- グループ向け：テキスト、Hodor風、バー

- 位置、倍率、戦闘後の表示時間を設定可能

|cD4AF37戦闘ジャーナル：|r

- エリア -> 戦闘 -> 指標の3段階ナビゲーション

- エリア・戦闘タイプ別フィルター

- 保存容量の上限を設定可能

|cD4AF37ダメージ：|r

- 対象・スキル別内訳

- 直接ダメージ、継続ダメージ、クリティカル

- 単体・範囲ダメージ

|cD4AF37回復：|r

- 与回復と被回復を発生源・対象別に表示

|cD4AF37効果：|r

- 自分とグループのバフ・デバフ時間、ボスのデバフ、発動追跡

|cFFFFFFLibGroupBroadcast|rによるグループDPS共有

|cD4AF37対応言語：|r英語、ドイツ語、フランス語、スペイン語、ロシア語、日本語、中国語]=], 1)

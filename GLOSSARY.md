# Battle Scrolls glossary

Shared terminology for the addon, web viewer, and release notes. Language codes
match the repository (`jp` means Japanese; web locale `ja`).

## Choosing a term

1. Prefer the language players see in skill descriptions, item descriptions and
   the relevant game UI. Check `esoui/esoui/lang/*_client.lua` and our own mined
   data by **stable ID**, not by translating an English name. A hidden effect's
   name can disagree with the description of the player-facing skill.
2. When the game has no established term, prefer the older, reviewed strings in
   `BattleScrolls/lang/` and the public BattleScrolls release history. New web
   strings and new release-note translations are not stronger evidence.
3. If sources disagree, make a contextual choice and record it below. Do not
   change an established term merely to make the translation more literal.

Read the whole sentence after editing. Inflect names, adjust articles and word
order, and rewrite awkward prose freely while preserving what the feature does.
The tables give citation forms, not strings to paste into every grammatical
context. Plurals, natural abbreviations and sentence case are allowed. Navigation
references must match the actual tab or setting; informal prose need not repeat
an entire UI label. Keep placeholders, ESO grammar tokens and literal error
messages intact. Do not translate API names, CSV/JSON, library names, or player
names. Historical before/after quotations are intentional exceptions.

## Game names: use the database

Keep individual ability, buff, item, set, trait and script names in the versioned
metadata database, not duplicated as a translation list here. This glossary
covers shared concepts and editorial decisions. For release notes, resolve the
exact morph, synergy or script by ID, then read its description to confirm the
context. Use the verified localized name rather than leaving English in a
translation. Inflect it naturally in prose.

## Product and add-ons

| English | Deutsch | Español | Français | 日本語 | Русский | 简体中文 | Comment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| add-on | Erweiterung | complemento | extension | アドオン | модификация | 插件 | Follow `SI_GAME_MENU_ADDONS`, `SI_WINDOW_TITLE_ADDON_MANAGER` and their descriptions. These game terms take precedence over older Addon/addon/аддон wording. Inflect naturally; EN plural add-ons. Preserve API/library names, filenames and `/addonmemdisplay`. |
| Battle Scrolls | Battle Scrolls | Pergaminos de Batalla | Parchemins de Bataille | Battle Scrolls | Боевые Свитки | Battle Scrolls | Match the established `BATTLESCROLLS_UI_NAME` in navigation, onboarding, web headers and release notes. RU prose inflects the name: в «Боевых Свитках», история «Боевых Свитков»; both words stay capitalized. FR uses les/des where grammar requires. ZH keeps the original English Journal name; do not alternate with 战斗卷轴. Technical identifiers, URLs and English metadata remain unchanged. |

## Navigation labels

| English | Deutsch | Español | Français | 日本語 | Русский | 简体中文 | Comment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Overview | Übersicht | Resumen | Aperçu | 概要 | Обзор | 概览 | Navigation labels follow `TAB_*`; keep references to tabs consistent with the UI. |
| Damage | Schaden | Daño | Dégâts | ダメージ | Урон | 伤害 | — |
| Damage Done | Zugefügter Schaden | Daño infligido | Dégâts infligés | 与ダメージ | Нанесённый урон | 造成伤害 | — |
| Damage Taken | Erlittener Schaden | Daño recibido | Dégâts subis | 被ダメージ | Полученный урон | 受到伤害 | — |
| Boss Damage Done | Boss-Schaden | Daño al jefe | Dégâts aux boss | ボスダメージ | Урон боссу | 首领伤害 | — |
| Group Damage | Gruppenschaden | Daño del grupo | Dégâts du groupe | グループダメージ | Урон группы | 团队伤害 | All damage observed by the client, including players without the addon. See Others for the unidentified pool. |
| Healing | Heilung | Curación | Soins | 回復 | Исцеление | 治疗 | — |
| Healing Out | Ausgehende Heilung | Curación otorgada | Soins prodigués | 与回復 | Исходящее исцеление | 治疗输出 | — |
| Self Healing | Selbstheilung | Autocuración | Auto-soins | 自己回復 | Самоисцеление | 自我治疗 | — |
| Healing In | Erhaltene Heilung | Curación recibida | Soins reçus | 被回復 | Полученное исцеление | 受到治疗 | — |
| Effects | Effekte | Efectos | Effets | 効果 | Эффекты | 效果 | — |
| Group | Gruppe | Grupo | Groupe | グループ | Группа | 团队 | — |
| Group Member | Gruppenmitglied | Miembro del grupo | Membre du groupe | グループメンバー | Член группы | 团队成员 | A player in the group; see `SI_GROUP_LIST_PANEL_GROUP_MEMBERS_LABEL`. RU always includes группы: члены группы, других членов группы, по членам группы; avoid участники and never shorten to bare члены, including compact labels. |
| Build | Zusammenstellung | Arquetipo | Archétype | ビルド | Сборка | 方案 | A saved character setup: equipment, abilities and other choices. Distinct from a Vengeance loadout (FR archétype / configuration; RU сборка / комплект; ZH 方案 / 配装). |
| Activity | Aktivität | Actividad | Activité | アクティビティ | Активность | 活动 | — |
| Aggregate | Auswertung | Análisis | Analyse | 集計 | Аналитика | 汇总 | Cross-encounter analysis (`PIVOT_TITLE`), not an encounter. |
| Settings | Einstellungen | Ajustes | Paramètres | 設定 | Настройки | 设置 | — |
| What's New | Was gibt's Neues? | Novedades | Nouveautés | 更新情報 | Что нового | 更新内容 | Dated release history in the Journal (`WHATS_NEW`). |
| Journal | Journal | Diario | Journal | ジャーナル | Журнал | 日志 | Established addon vocabulary; `UI_SETTINGS` supplies Settings. |
| Zone / recorded visit | Gebiet | Zona | Zone | エリア | Область | 区域 | An instance record is one visit/run in an area, not necessarily an instanced dungeon. The zone is the location; use “run” naturally for sharing the whole visit. |
| Encounter | Kampf | Combate | Combat | 戦闘 | Сражение | 战斗 | One fight within a recorded visit. |
| Others | Andere | Otros | Autres | その他 | Остальные | 其他人 | Unnamed damage pool from other nearby players, including people outside the group. ESO does not identify the individual sources. |

## Damage, healing and effects

| English | Deutsch | Español | Français | 日本語 | Русский | 简体中文 | Comment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DPS | DPS | DPS | DPS | DPS | DPS | DPS | — |
| HPS | HPS | HPS | HPS | HPS | HPS | HPS | — |
| DTPS | DTPS | DTPS | DTPS | DTPS | DTPS | DTPS | — |
| Raw Healing | Gesamte Heilung | Curación bruta | Soins bruts | 総回復 | Полное исцеление | 总治疗 | Includes overheal; the default measure of healing output. Neither effective healing nor an unspecified total. Follow `STAT_*` labels. |
| Raw HPS | Gesamt-HPS | HPS bruto | HPS brut | 総HPS | Полный HPS | 总HPS | Raw healing per second, including overheal. |
| Effective Healing | Effektive Heilung | Curación efectiva | Soins effectifs | 実効回復 | Эфф. исцеление | 有效治疗 | The useful portion of healing. RU Эфф. is an allowed compact prefix; JA/ZH 量 may be added when the quantity needs to be explicit. |
| Effective HPS | Effektive HPS | HPS efectivo | HPS effectif | 実効HPS | Эфф. HPS | 有效HPS | Effective healing per second; the same abbreviation rules as Effective Healing apply. |
| Overheal | Überheilung | Sobrecuración | Sur-soins | 過剰回復 | Переисцеление | 过量治疗 | Healing in excess of what was needed; distinct from effective healing. |
| Direct Damage | Direkter Schaden | Daño directo | Dégâts directs | 直接攻撃 | Прямой урон | 直接伤害 | Delivery category (`DELIVERY_*`). Keep the player-facing damage type Oblivion distinct from the internal enum name “Daedric”. |
| Damage over Time | Schaden über Zeit | Daño prolongado | Dégâts persistants | 継続ダメージ | Периодический урон | 持续伤害 | — |
| Single Target Damage | Einzelzielschaden | Objetivo único | Dégâts cible unique | 単体攻撃 | Урон по одиночной цели | 单体伤害 | — |
| AoE Damage | Flächenschaden | Área de efecto | Dégâts de zone | 範囲攻撃 | Урон по площади | 范围伤害 | — |
| Direct Healing | Direkte Heilung | Curación directa | Soins directs | 直接回復 | Прямое исцеление | 直接治疗 | — |
| Healing over Time | Heilung über Zeit | Curación prolongada | Soins persistants | 継続回復 | Периодическое исцеление | 持续治疗 | — |
| Health Recovery | Gesundheitsregeneration | Recuperación de salud | Récupération de santé | 体力回復 | Восстановление здоровья | 生命恢复 | A separate recorded category from healing abilities, shields and heal absorption. |
| Damage Shields | Schadensschilde | Escudos de daño | Boucliers | ダメージシールド | Защитные щиты | 伤害护盾 | Absorb incoming damage; do not call them healing absorption. |
| Heal Absorption | Heilungsabsorption | Absorción de curación | Absorption de soins | 回復吸収 | Поглощение исцеления | 治疗吸收 | Absorbs healing, not damage. A separate recorded category. |
| Ability | Fähigkeit | Habilidad | Compétence | アビリティ | Способность | 技能 | — |
| Source | Quelle | Fuente | Source | ソース | Источник | 来源 | — |
| Target | Ziel | Objetivo | Cible | ターゲット | Цель | 目标 | — |
| Group Share | Beitrag | Contribución | Contribution | 貢献度 | Вклад в группе | 团队占比 | Statistical contribution: a fraction of the total. Not the action of uploading or broadcasting data. |
| Survivability | Überlebensfähigkeit | Supervivencia | Survie | 生存性 | Выживаемость | 生存能力 | — |
| Death Count | Todesanzahl | Número de Muertes | Nombre de Morts | 死亡回数 | Число смертей | 死亡次数 | — |
| Death Recap | Todesrückblick | Resumen de la muerte | Récapitulatif de mort | 死亡時の詳細情報 | Причины смерти | 死亡回顾 | Follow `SI_DEATH_RECAP_TITLE`; FR expands the game's abbreviated “Récap. mort” in prose. ES uses the game term rather than the older recapitulación de muerte. |
| Duration | Dauer | Duración | Durée | 持続時間 | Длительность | 持续时间 | — |
| Uptime | Aktivzeit | Tiempo activo | Temps actif | 稼働時間 | Время действия | 覆盖率 | Duration or a percentage of the relevant unit’s alive time; not effect strength, proc count or casts. |
| Stack | Kumulation | Acumulación | Charge | スタック | Заряд | 层 | Charge/layer of one effect. DE Stapel is still correct for a literal pile of scrolls. FR cumul de DoT describes overlapping separate DoTs, not charges of one effect. |
| Critical hit | Kritischer Treffer | Golpe crítico | Coup critique | クリティカルヒット | Критический удар | 暴击 | — |
| Buff | Buff | Beneficio | Bonus | バフ | Бафф | 增益 | — |
| Debuff | Debuff | Perjuicio | Malus | デバフ | Дебафф | 减益 | — |

## Activity

| English | Deutsch | Español | Français | 日本語 | Русский | 简体中文 | Comment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Weaving | Weaving | Weaving | Weaving | ウィービング | Вивинг | 卡轻击 | Established addon usage: RU вивинг, ZH 卡轻击; do not translate literally as плетение or 编织. |
| Light Attacks | Leichte Angriffe | Ataques ligeros | Attaques légères | 軽攻撃 | Обычные атаки | 轻攻击 | RU обычные атаки, not лёгкие атаки. |
| Heavy Attacks | Schwere Angriffe | Ataques pesados | Attaques lourdes | 重攻撃 | Силовые атаки | 重攻击 | — |
| Skill Casts | Gewirkte Fähigkeiten | Habilidades lanzadas | Compétences lancées | スキル発動 | Касты навыков | 技能释放 | Intentional uses of a skill; distinct from passive procs. |
| Average Cast Delay | Durchschnittliche Wirkverzögerung | Retraso medio de lanzamiento | Délai moyen d'incantation | 平均キャスト遅延時間 | Средняя задержка каста | 平均施法延迟时间 | Gap after the previous skill’s global cooldown or cast time. Activity labels follow `HEADER_*` / `STAT_*`. |
| Time Lost | Verlorene Zeit | Tiempo perdido | Temps perdu | ロスタイム | Потерянное время | 浪费时间 | Sum of short cast delays across the fight; distinct from downtime. |
| Downtime | Leerlauf | Tiempo inactivo | Temps mort | 空白時間 | Простой | 空档时间 | Gaps of at least three seconds; distinct from time lost. |
| Missed Light Attacks | Verpasste leichte Angriffe | Ligeros perdidos | Attaques légères manquées | 軽攻撃抜け | Пропущенные обычные атаки | 遗漏轻攻击 | — |
| Double Light Attacks | Doppelte leichte Angriffe | Ligeros dobles | Attaques légères doublées | 二重軽攻撃 | Двойные обычные атаки | 重复轻攻击 | — |
| Proc Tracking | Proc-Verfolgung | Seguimiento de procs | Suivi des procs | プロック追跡 | Отслеживание активаций | 触发追踪 | Tracks triggered effects; a passive proc and an intentional cast are different events. |
| Ultimate | Ultimative Fähigkeit | Habilidad máxima | Compétence ultime | アルティメット | Суперспособность | 终极技能 | Can mean an ability or its resource. Use the full ability label in navigation and resource wording for amounts (RU заряд суперспособности, ZH 终极值). |
| Ultimate at Combat Start | Ultimative zu Kampfbeginn | Máxima al entrar en combate | Ultime en début de combat | 戦闘開始時のアルティメット | Заряд при входе в бой | 进入战斗时的终极值 | — |
| Ultimate Generated | Ultimative erzeugt | Máxima generada | Ultime générée | 獲得したアルティメット | Накоплено заряда | 获得的终极值 | Minor and Major Heroism are included in base generation; their estimates must not be added again. Resolve their localized names from the database. |
| Ultimate Spent | Ultimative verbraucht | Máxima gastada | Ultime dépensée | 消費したアルティメット | Потрачено заряда | 消耗的终极值 | Charge used by recorded Ultimate casts; distinct from excess lost on cast and drain outside casts. |
| Ultimate Drained | Ultimative entzogen | Máxima drenada | Ultime drainée | 喪失したアルティメット | Поглощено заряда | 流失的终极值 | Charge removed outside recorded casts, including ongoing consumption and effects that reduce the resource. RU Поглощено заряда is the chosen readable label; it does not imply transfer to another player. “Расход по времени” would be too narrow. The other locales already use neutral drain/loss wording; do not mechanically change them to “absorbed”. |
| Lost on Cast | Beim Einsatz verloren | Perdida al lanzar | Perdue à l'utilisation | 使用時の損失 | Потеряно при касте | 施放时浪费 | Excess charge lost when a cast empties the resource pool, beyond what the ability uses. |
| Resurrections | Wiederbelebungen | Resurrecciones | Résurrections | 蘇生 | Воскрешения | 复活次数 | — |
| Crux | Crux | Crux | Interprétation | クラッツ | Знак | 魔核 | JA クラッツ follows player-facing skill descriptions (185805, 183537) and older reviewed strings, not buff 184220’s 十字架; explicitly confirmed by the user. FR Interprétations / RU Знаки are valid plurals; never RU Крукс. A spender cast below three Crux may be intentional: state the count rather than declaring every such cast an error. |

### Hidden ability names

Use the canonical localized skill name for confirmed mislabeled Ultimate
components: Soul Harvest `36519 → 36514` (RU **Жатва душ**), Deaden Pain
`124166 → 118623`, Devout Guardian `263621 → 263586`, and Bastion of Light
`267069 → 263585`. Soul Harvest's component incorrectly names Rapid Stroke in
all seven languages in build `eso.rc.12.1.4.3294972`.

For Crypt Transfer `195031`, Russian metadata still says `U38 Mythic 1`. Use
its owning set effect `196775`'s established name **Одеяние могильного каноника**
in Russian, including the slotted ability. Other languages retain their
active-skill name. This is a deliberate display fallback to an existing game
name, not a newly coined translation of Crypt Transfer.

## Classes

| English | Deutsch | Español | Français | 日本語 | Русский | 简体中文 | Comment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Dragonknight | Drachenritter | Caballero dragón | Chevalier-dragon | ドラゴンナイト | Рыцарь-дракон | 龙骑士 | Class ID 1. Keep the hyphen in FR and RU. RU prose: рыцаря-дракона, рыцари-драконы. Official class references: [EN][classes-en], [DE][classes-de], [ES][classes-es], [FR][classes-fr], [JA][classes-ja], [ZH][classes-zh]; prefer in-game text when a marketing page differs. |
| Sorcerer | Zauberer | Brujo | Sorcier | ソーサラー | Чародей | 术士 | Class ID 2. FR Sorcier, not Ensorceleur: confirmed by mined ability descriptions 31425, 45195 and 263873, and the [official class page][classes-fr]. |
| Nightblade | Nachtklinge | Hoja de la noche | Lame noire | ナイトブレイド | Клинок ночи | 夜刃 | Class ID 3. Keep the full localized class name rather than literal translations or player abbreviations. RU prose: клинка ночи, клинки ночи. |
| Warden | Hüter | Custodio | Gardien | ウォーデン | Хранитель | 守望者 | Class ID 4. ES Custodio follows the existing reviewed label and [official update history][updates-es]; the general Spanish class page still uses Guardián. Do not replace the class name with the name of its summoned bear. |
| Necromancer | Nekromant | Nigromante | Nécromancien | ネクロマンサー | Некромант | 死灵法师 | Class ID 5. Preserve the accents in FR Nécromancien. |
| Templar | Templer | Templario | Templier | テンプラー | Храмовник | 圣殿骑士 | Class ID 6. RU храмовник, not тамплиер. |
| Arcanist | Arkanist | Arcanista | Arcaniste | アルカニスト | Мастер рун | 奥术师 | Class ID 117. RU мастер рун, not арканист (user correction and `SI_ACCESSIBILITY_OPTIONS_ARCANIST`); inflect naturally: Знаки мастера рун, играющие мастерами рун. Use the localized class name in release notes and web build labels. |

## Builds and game systems

| English | Deutsch | Español | Français | 日本語 | Русский | 简体中文 | Comment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Character | Charakter | Personaje | Personnage | キャラクター | Персонаж | 角色 | — |
| Class Mastery | Klassenmeisterschaft | Maestría de clase | Maîtrise de classe | クラスマスタリー | Мастерство класса | 职业精通 | Only the class passives (`SETUP_CLASS_MASTERY`). The signature script is now Class Flourish (script ID 31); resolve its localized name from the database. Do not use Class Mastery as a current script name. |
| Class Skill Lines | Klassen-Fertigkeitslinien | Líneas de habilidades de clase | Lignes de compétences de classe | クラススキルライン | Классовые навыки | 职业技能线 | Shown for builds without selected Class Mastery passives; use `SETUP_*` labels. |
| Front Bar | Primärleiste | Barra primaria | Barre primaire | 主要バー | Основная панель | 主要栏 | — |
| Back Bar | Reserveleiste | Barra secundaria | Barre secondaire | 予備バー | Вторая панель | 后备栏 | — |
| Equipment | Ausrüstung | Equipo | Équipement | 装備 | Снаряжение | 装备 | Resolve weapon, armor, item quality, trait, class and race names from game metadata/enum IDs. Explicit Greatsword/Battle Axe/Maul labels distinguish two-handed weapons when a raw enum says only Sword/Axe/Mace. |
| Item Sets / Gear Sets | Ausrüstungssets | Conjuntos de equipo | Ensembles d'équipement | 装備セット | Наборы снаряжения | 套装 | Items sharing set bonuses (`SETUP_GEAR_SETS`), not a character build or Vengeance loadout. RU набор снаряжения / наборы снаряжения; never комплект for an item set. When discussing terminology from set tooltips, say описания наборов снаряжения. Resolve individual set names from the database. |
| Food | Nahrung | Comida | Nourriture | 料理 | Еда | 食物 | — |
| Mundus | Mundus | Mundus | Mundus | ムンダス | Мундус | 梦达思 | `SI_ARMORY_MUNDUS_STONE_LABEL`; ZH 梦达思. |
| Poisons | Gifte | Venenos | Poisons | 毒 | Яды | 毒药 | — |
| Loadout | Ausstattung | Configuración | Configuration | 兵装 | Комплект | 配装 | Vengeance’s mode-specific preset; distinct from a saved Build. Source: `SI_CAMPAIGN_VENGEANCE_*`. |
| Perks | Signa | Ventajas | Atouts | スキル | Умения | 辅助能力 | Use the names in the game’s Vengeance loadout editor, not a literal translation of “advantages”. |
| Champion Points | Championpunkte | Puntos de campeón | Points de Champion | チャンピオンポイント | Очки героя | 勇士点数 | `SI_GAMEPAD_TRADING_HOUSE_BROWSE_CHAMPION_POINTS`; RU очки героя, ZH 勇士点数. Keep CP where it is an established compact label. |
| Scribing | Schriftlehre | Escribanía | Écriture | 書記 | Чаропись | 篆刻 | `SI_SCRIBING_GAMEPAD_SCRIBING_TITLE`; use script slot names and the crafted ability’s own name/icon, not a grimoire item’s name/icon. |
| Grimoire | Grimoire | Grimorio | Grimoire | グリモア | Гримуар | 魔典 | `SI_SCRIBING_CRAFTED_ABILITY_SLOT_NAME`; a grimoire and its resulting ability are distinct. |
| Script | Skriptur | Escritura | Inscription | スクリプト | Запись | 脚本 | FR Inscription follows all three player-facing slots, although `SI_ITEMTYPE73` says Script. |
| Focus Script | Fokus-Skriptur | Escritura focal | Inscription de focalisation | フォーカススクリプト | Основная запись | 焦点脚本 | `SI_SCRIBINGSLOT1`. |
| Signature Script | Effekt-Skriptur | Escritura distintiva | Inscription de signature | シグネチャースクリプト | Уточняющая запись | 标志脚本 | `SI_SCRIBINGSLOT2`. Class Flourish is a particular signature script, not the Class Mastery passive system; look up script names by ID in the database. |
| Affix Script | Affix-Skriptur | Escritura complementaria | Inscription de commentaire | アフィックススクリプト | Дополнительная запись | 附属脚本 | `SI_SCRIBINGSLOT3`. |
| Vengeance | Vergeltung | Vengeance | Vengeance | 復讐 | Месть | 复仇 | ES campaign title is Vengeance, with vengativo/a as an adjective; do not invent the title Venganza. Source: `SI_CAMPAIGN_VENGEANCE_*`. |
| Bars | Balken | Barras | Barres | バー | Шкалы | 进度条 | The meter design name (`DESIGN_GROUP_BARS`); prose and color settings must match it. RU singular шкала (цвет вашей шкалы), plural шкалы, not полоса/полосы. ZH 进度条, not 条形. These also apply to the personal Bar design (`DESIGN_PERSONAL_BAR`). |

## Locations mentioned in release notes

| English | Deutsch | Español | Français | 日本語 | Русский | 简体中文 | Comment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Lucent Citadel | Luminit-Zitadelle | Ciudadela Luciente | Citadelle lumineuse | ルーセント要塞 | Цитадель Люцентов | 卢晶堡垒 | Use the full name in release notes. RU explicitly confirmed by the user; inflect as в Цитадели Люцентов. Sources: [DE][trials-de], [ES][trials-es], [FR][lucent-fr], [JA][lucent-ja], [ZH][trials-zh]. |
| Ossein Cage | Gebeinkäfig | Jaula de Oseína | Cage d’Ossein | オセインの檻 | Костяная Клетка | 骨笼 | Both Russian words are capitalized, including inflected forms: в Костяной Клетке (user correction). Do not shorten to “Ossein” without context. Sources: [DE][trials-de], [ES][trials-es], [FR][ossein-fr], [JA][ossein-ja], [ZH][trials-zh]. |
| Night Market | Nachtmarkt | Mercado Nocturno | Marché nocturne | 夜の市場 | Ночной рынок | 夜市 | RU на Ночном рынке. The recording option records all fights there regardless of usual zone filters; explain this behavior instead of “event zone override”. Sources: [DE][night-de], [ES][night-es], [FR][night-fr], [JA][night-ja], [ZH][night-zh], [RU in-game book title][night-ru]. |

## Editorial checks

- Keep translated ability names, instance names and UI labels recognizable.
  Source names by ID and inspect the player-facing description when sources conflict.
- A translated release note should read naturally on its own. Do not preserve
  English noun chains, articles or sentence structure at the cost of clarity.
- Keep historical meaning and dates. Explain a feature as it arrived in that
  release; do not list internal iterations as separate user-facing changes.
- The publishing text has a **2,000-character limit**. Keep some room below it;
  v2.0.1 was shortened for this limit. In-addon translations may be longer.
- Check all seven locale files and the viewer when changing a concept. Keep the
  English in-addon note consistent with its `release-assets/release-notes/`
  source; the publishing edition may condense wording to fit its limit while
  the in-addon edition retains full detail. Do not alter literal error messages
  or names in historical quotations.

[classes-en]: https://www.elderscrollsonline.com/en-us/classes
[classes-de]: https://www.elderscrollsonline.com/de/classes
[classes-es]: https://www.elderscrollsonline.com/es/classes
[classes-fr]: https://www.elderscrollsonline.com/fr/classes
[classes-ja]: https://www.elderscrollsonline.com/ja/classes
[classes-zh]: https://www.elderscrollsonline.com/cn/classes
[updates-es]: https://www.elderscrollsonline.com/es/updates
[trials-de]: https://forums.elderscrollsonline.com/de/discussion/comment/8486174
[trials-es]: https://eso-hub.com/es/achievements
[lucent-fr]: https://forums.elderscrollsonline.com/fr/discussion/comment/8198484
[ossein-fr]: https://forums.elderscrollsonline.com/fr/discussion/comment/8323203
[lucent-ja]: https://eso.dmm.com/news/detail/13091
[ossein-ja]: https://eso.dmm.com/news/detail/14476?page=23
[trials-zh]: https://help-zh-cn.elderscrollsonline.com/app/answers/detail/a_id/62197/
[night-de]: https://forums.elderscrollsonline.com/de/discussion/691719/offizielle-diskussion-zu-waehlt-eure-nachtmarkt-fraktion
[night-es]: https://www.elderscrollsonline.com/es/guides
[night-fr]: https://www.elderscrollsonline.com/fr/seasonzero
[night-ja]: https://eso.dmm.com/news/detail/15561
[night-zh]: https://www.elderscrollsonline.com/cn/events/2461
[night-ru]: https://elderscrolls.fandom.com/ru/wiki/Отчёт_о_Ночном_рынке

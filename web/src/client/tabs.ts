// Navigation groups and renderers for the encounter view. Each sub-tab
// render(ctx) returns { html, csv, title }; html is the full content area
// (stat strip + body) below the sub-tab pills.
import * as M from "./metrics";
import {
  fmtNumber, fmtExact, fmtPercent, fmtDuration, fmtDps, fmtRate,
  escapeHtml, cleanName,
} from "./format";
import { ICON_DONORS, NAME_DONORS, LOCALIZED_NAME_DONORS } from "../shared/icon_overrides";
import { isScribedRecipe, scribingKey } from "../shared/scribing";
import type { ScribedAbility } from "../shared/scribing";
import { t, tm, currentLocale } from "./strings";
import type { StringKey } from "./strings";
import type { AbilityRow, DamageMaps, DamageTakenRow, HealingBasis, HealingDelivery, HealingRow } from "./metrics";
import type {
  AbilityFacts, CruxData, DamageMap, DeathRecap, DecodedEncounter, DecodedSharedEntry, EffectStats, ExportStream,
  HealingBreakdown, HealingDone, HealingDoneDiffSource, HealingTotals, MemberGroupedCount, MemberSetup, UltimateData,
  WireBarSlot, WireEncounter, WireEquipSlot, WireSharedEntry,
} from "../shared/decoder";

// ============================================================================
// VIEW MODEL TYPES
// ============================================================================

/**
 * Ability mechanics as rendered here: the language-neutral DB fields joined
 * onto the name lookup, plus the share's recorded classification flags.
 */
export interface AbilityMech extends AbilityFacts {
  aoe?: number;
  durationMs?: number;
  tickMs?: number;
  castMs?: number;
  channelMs?: number;
  buffType?: number;
  ultimate?: number;
  passive?: number;
}

/** /api/abilities/lookup row (+ the client-side iconUrl and merged mech). */
export interface AbilityInfo {
  name?: string;
  icon?: string;
  iconUrl?: string | null;
  tooltip?: string;
  craftedAbilityId?: number;
  /** Set when the worker filled `tooltip` from a same-name donor ability. */
  approxTooltip?: true;
  /** The donor's own ability id, whenever the text was borrowed. */
  tooltipDonorId?: number;
  mech?: AbilityMech;
}

/** /api/items/lookup row (+ the client-side iconUrl). */
export interface ItemInfo {
  name: string;
  icon?: string;
  iconUrl?: string | null;
  setName?: string;
  /** Set id for the defs lookup; null until the item DB carries a dump. */
  setId: number | null;
  trait?: number;
  armorType?: number;
  weaponType?: number;
  equipType?: number;
  tooltip?: string;
}

/** /api/champion/lookup row. */
export interface ChampionInfo {
  name?: string;
  disciplineId?: number;
  tooltip?: string;
}

/** One /api/defs/lookup row (set, scribing script, perk, skill line). */
export interface DefValue {
  name: string;
  tooltip?: string;
  icon?: string;
  iconUrl?: string | null;
}

/** The definition lookups keyed by kind, as app.ts fills them. */
export interface DefsStore {
  set: Record<number, DefValue>;
  script: Record<number, DefValue>;
  perk: Record<number, DefValue>;
  skillline: Record<number, DefValue>;
  /** Keyed by ITEM_TRAIT_TYPE — the same ids the wire carries per slot. */
  trait: Record<number, DefValue>;
  enchant: Record<number, DefValue>;
}

/** Everything a renderer may read; built per encounter by app.ts. */
export interface RenderCtx {
  wireEnc: WireEncounter;
  decoded: DecodedEncounter;
  names: Record<number, AbilityInfo>;
  /** Every ability id this share contains, across all lookup batches. */
  knownAbilityIds: ReadonlySet<number>;
  itemNames: Record<number, ItemInfo>;
  championNames: Record<number, ChampionInfo>;
  defs: DefsStore;
  scribing?: Record<string, ScribedAbility>;
  durationMs: number;
  bossUnits: Set<number>;
  sharedDecoded: Map<WireSharedEntry, DecodedSharedEntry>;
  share: ExportStream;
  pins: Set<number>;
}

export interface TabResult {
  html: string;
  csv: (string | number)[][];
  title: string;
}

export interface NavSub {
  id: string;
  labelKey: StringKey;
  render: (ctx: RenderCtx) => TabResult;
  show?: (ctx: RenderCtx) => boolean;
  always?: boolean;
}

export interface NavGroup {
  id: string;
  labelKey: StringKey;
  menuSub?: (ctx: RenderCtx) => string;
  subs: NavSub[];
}

// ============================================================================
// UI STORES (mutated by app.ts's delegated events, read while rendering)
// ============================================================================

/** Sub-tab id -> free-text filter typed into that sub's `.fx-filter` input. */
export const tabFilters = new Map<string, string>();

/** Healing tab -> ranking/share measure. Raw is the default on every tab. */
export const healingBases = new Map<string, HealingBasis>();

// ---- per-tab unit filters (journal parity, ui/journal/filters.lua) ----

/** One checkbox in a filter panel; several unit ids can share a name. */
export interface FilterGroup {
  /** Stable identity across re-renders: the display name, or SELF_KEY. */
  key: string;
  label: string;
  ids: Array<number | string>;
  isSelf: boolean;
}

/** Which axis a filter panel section filters on. */
export type FilterAxis = "main" | "source";

/**
 * Deselected group keys per "<subId>|<axis>". The journal's rule is that a
 * filter exists only while something is *un*checked (filters.lua applyPending
 * hands back nil when everything is selected), so an empty set means no
 * filter, and keys that vanish with a different encounter simply stop
 * matching.
 */
export const unitFilters = new Map<string, Set<string>>();

/** Sub ids whose filter panel is currently expanded. */
export const openFilterPanels = new Set<string>();

export function filterStateKey(subId: string, axis: FilterAxis): string {
  return `${subId}|${axis}`;
}

/** Drops every filter; called when the viewer moves to another encounter. */
export function clearUnitFilters(): void {
  unitFilters.clear();
  openFilterPanels.clear();
  tabFilters.clear();
}

/**
 * A checkbox toggle starts from what the viewer sees checked, which for a tab
 * with a narrower default (group damage opens on bosses only) is the default
 * set rather than "everything".
 */
export function toggleFilterGroup(ctx: RenderCtx, subId: string, axis: FilterAxis, key: string): void {
  const groups = filterGroups(ctx, subId, axis);
  const off = new Set(effectiveOff(ctx, subId, axis, groups));
  if (off.has(key)) off.delete(key);
  else off.add(key);
  unitFilters.set(filterStateKey(subId, axis), off);
}

/** Back to the tab's default selection (filters.lua resetPending). */
export function resetFilters(subId: string): void {
  unitFilters.delete(filterStateKey(subId, "main"));
  unitFilters.delete(filterStateKey(subId, "source"));
  tabFilters.delete(subId);
}

/**
 * Narrows the tab to one group — what clicking a row in a breakdown table
 * does. Clicking the row that is already the whole filter clears it again, so
 * the same click both drills in and backs out.
 */
export function applyFilterOnly(
  ctx: RenderCtx, subId: string, axis: FilterAxis, key: string,
): void {
  const groups = filterGroups(ctx, subId, axis);
  if (!groups.some((g) => g.key === key)) return;
  const stateKey = filterStateKey(subId, axis);
  const current = effectiveOff(ctx, subId, axis, groups);
  const isOnlyThis = current.size === groups.length - 1 && !current.has(key);
  if (isOnlyThis) {
    unitFilters.delete(stateKey);
    return;
  }
  unitFilters.set(stateKey, new Set(groups.filter((g) => g.key !== key).map((g) => g.key)));
}

/**
 * Drops one chip. Removing the last included group would leave an empty tab,
 * so that clears the filter instead of stranding the viewer on nothing.
 */
export function removeFilterKey(
  ctx: RenderCtx, subId: string, axis: FilterAxis, key: string,
): void {
  const groups = filterGroups(ctx, subId, axis);
  const stateKey = filterStateKey(subId, axis);
  const off = new Set(effectiveOff(ctx, subId, axis, groups));
  off.add(key);
  if (groups.every((g) => off.has(g.key))) unitFilters.delete(stateKey);
  else unitFilters.set(stateKey, off);
}

/** Active group-table sort: a column key from GROUP_SORT_KEYS, dir -1 = desc. */
/** Default sort matches the journal's: DPS, descending (group_table.lua). */
export const groupSortState: { col: string; dir: 1 | -1 } = { col: "dps", dir: -1 };

// ============================================================================
// INLINE DETAILS
// ============================================================================

type DetailStat = [string, string | number | null | undefined];

/** Shared disclosure: the summary stays in place while detail content opens. */
function disclosure(summary: string, body: string, className = ""): string {
  return body ? `<details class="disclosure ${className}"><summary>${summary}</summary><div class="detail-body">${body}</div></details>` : summary;
}

function detailRow(summary: string, body: string, grid: string, className = ""): string {
  return `<details class="disclosure row-detail"><summary class="dt-row ${className}" style="${grid}">${summary}</summary><div class="detail-body">${body}</div></details>`;
}

function detailStats(stats: DetailStat[]): string {
  return `<dl class="detail-stats">${stats.filter(([, value]) => value !== "" && value != null).map(([label, value]) =>
    `<div><dt>${escapeHtml(label)}</dt><dd>${escapeHtml(String(value))}</dd></div>`).join("")}</dl>`;
}

function detailParagraphs(text: string): string {
  return text.split(/[\r\n]+/).map((line) => line.trim()).filter(Boolean)
    .map((paragraph) => `<p>${escapeHtml(paragraph)}</p>`).join("");
}

/** A ruled sub-section of a card: a headed block of text (enchant, set, ...). */
interface DetailBlock {
  head: string;
  desc?: string;
  /** Body rendered one row per entry (set bonuses, one line each). */
  lines?: string[];
  /** Muted caveat under the block's text (data honesty, not game data). */
  note?: string;
}

interface DetailCardSpec {
  iconHtml?: string;
  name: string;
  nameColor?: string;
  tag?: string;
  desc?: string;
  /** Muted caveat lines under `desc`, same voice as a block's note. */
  notes?: string[];
  stats?: DetailStat[];
  /** Secondary stats (an ability's mechanics vs what was measured), set
   *  apart from `stats` by a rule so the card is not one flat run of pairs. */
  stats2?: DetailStat[];
  blocks?: DetailBlock[];
}

function detailCard({ iconHtml: icon, name, nameColor, tag, desc, notes, stats, stats2, blocks }: DetailCardSpec): string {
  const pairs = (list: DetailStat[] | undefined): string =>
    (list || []).filter((p) => p[1] !== "" && p[1] != null).map(([k, v]) =>
      `<div class="p"><span class="k">${escapeHtml(k)}</span><span class="v">${escapeHtml(String(v))}</span></div>`
    ).join("");
  const statHtml = pairs(stats);
  const stat2Html = pairs(stats2);
  const noteHtml = (notes || []).filter(Boolean)
    .map((n) => `<div class="detail-note">${escapeHtml(n)}</div>`).join("");
  const blockHtml = (blocks || []).filter((b) => b.head || b.desc || b.lines?.length).map((b) => `
    <div class="detail-rule"></div>
    <div class="detail-block">
      ${b.head ? `<div class="detail-bhead">${escapeHtml(b.head)}</div>` : ""}
      ${b.desc ? `<div class="detail-bdesc">${detailParagraphs(b.desc)}</div>` : ""}
      ${(b.lines || []).map((l) => `<div class="detail-bline">${escapeHtml(l)}</div>`).join("")}
      ${b.note ? `<div class="detail-note">${escapeHtml(b.note)}</div>` : ""}
    </div>`).join("");
  return `
    <div class="detail-head">${icon || ""}<span class="detail-name"${nameColor ? ` style="color:${nameColor}"` : ""}>${escapeHtml(name)}</span>${tag ? `<span class="detail-tag">${escapeHtml(tag)}</span>` : ""}</div>
    ${desc ? `<div class="detail-desc">${detailParagraphs(desc)}</div>` : ""}
    ${noteHtml}
    ${statHtml ? `<div class="detail-rule"></div><div class="detail-grid">${statHtml}</div>` : ""}
    ${stat2Html ? `<div class="detail-grid detail-grid-sub">${stat2Html}</div>` : ""}
    ${blockHtml}`;
}

// ============================================================================
// SMALL SHARED PIECES
// ============================================================================

// The addon reports some things under synthetic ids at the top of the
// 20-bit range: natural health recovery and shielded/absorbed amounts
const SYNTHETIC_ABILITIES: Record<number, { key: StringKey; icon: string }> = {
  1048575: { key: "syn_health_recovery", icon: "/icons/esoui/art/icons/ability_buff_major_fortitude.png" },
  1048574: { key: "syn_shielded", icon: "/icons/esoui/art/icons/scribing_primary_damageshield.png" },
  1048573: { key: "syn_absorbed", icon: "/icons/esoui/art/icons/scribing_primary_trauma.png" },
};

// Shield/absorb rows are "supplemental" in the journal: they are real damage
// and real healing, but they carry no ability of their own, so the addon keeps
// them out of every percentage denominator, out of crit rate and max hit, and
// sorts them last with no share printed (renderers/damage.lua
// isDamagePercentExcludedAbility, renderers/healing.lua the heal-absorbed
// twin). Natural health recovery is NOT supplemental - it counts normally.
const SUPPLEMENTAL_ABILITIES = new Set([1048574, 1048573]);

function isSupplemental(abilityId: number): boolean {
  return SUPPLEMENTAL_ABILITIES.has(abilityId);
}

/** Drops the supplemental rows, for denominators and quality stats. */
function realRows<T extends { abilityId: number }>(rows: T[]): T[] {
  return rows.filter((r) => !isSupplemental(r.abilityId));
}

/**
 * The uploader's own unit id, used only to decide which ability rows carry a
 * "(Source)" suffix. The wire carries the recorder's own id in the encounter
 * meta (the exact key personal rows use, possibly the addon's synthetic
 * inferred id) — trust it when present. Recordings older than the stamping
 * scribe ship 0, so fall back to reading it off the data: a lone damage
 * source is the player, and
 * otherwise the player is the personal unit that took the most damage (the
 * taken map holds the player, their pets and companions, and pets take a
 * fraction of what the player does). Falls back to the biggest source.
 */
function playerUnitId(ctx: RenderCtx): number | undefined {
  if (ctx.wireEnc.playerUnitId > 0) return ctx.wireEnc.playerUnitId;
  const sources = Object.keys(ctx.decoded.damageByUnitId || {}).map(Number);
  if (sources.length === 0) return undefined;
  if (sources.length === 1) return sources[0];
  const sourceSet = new Set(sources);
  let best: number | undefined;
  let bestTaken = 0;
  for (const byTarget of Object.values(ctx.decoded.damageTakenByUnitId || {})) {
    for (const [victimId, byAbility] of Object.entries(byTarget)) {
      const id = Number(victimId);
      if (!sourceSet.has(id)) continue;
      const taken = M.sumBreakdowns(byAbility);
      if (taken > bestTaken) {
        best = id;
        bestTaken = taken;
      }
    }
  }
  if (best !== undefined) return best;
  let biggest = sources[0];
  let biggestTotal = -1;
  for (const id of sources) {
    const total = M.nestedTotal({ [id]: ctx.decoded.damageByUnitId[id]! }, null);
    if (total > biggestTotal) {
      biggest = id;
      biggestTotal = total;
    }
  }
  return biggest;
}

/**
 * When several ability ids merged into one named row, the journal lists the
 * split inside the tooltip. Same here: one line per contributing id with its
 * damage and its share of the row.
 */
function damageComponents(ctx: RenderCtx, row: AbilityRow): string {
  if (row.variants.length < 2) return "";
  const labels = componentLabels(ctx, row.variants.map((v) => v.abilityId));
  return sectHead(t("heal_components")) + row.variants.map((v, i) => disclosure(
    `${escapeHtml(labels[i]!)} <span class="component-value">${fmtNumber(v.total)} · ${fmtPercent(row.total > 0 ? v.total / row.total : 0)}</span>`,
    detailStats([
      [t("tt_total"), fmtExact(v.total)], [t("th_dps"), fmtDps(v.total, ctx.durationMs)],
      [t("tt_hits"), v.ticks], [t("heal_crit_ticks"), v.critTicks],
      [t("tt_crit"), fmtPercent(M.critPercent(v))], [t("tt_avg_hit"), fmtNumber(M.averageTick(v))],
      [t("tt_minmax"), `${fmtNumber(v.minTick)} – ${fmtNumber(v.maxTick)}`],
    ]), "component-detail",
  )).join("");
}

/** Naming rules for merged ability rows, as the journal builds them. */
function abilityNaming(ctx: RenderCtx): M.AbilityNaming {
  return {
    name: (id) => abilityName(ctx, id),
    unitName: (id) => {
      const raw = ctx.decoded.unitNames?.[id];
      return raw ? cleanName(raw) : undefined;
    },
    playerUnitId: playerUnitId(ctx),
    neverSuffixed: isSupplemental,
  };
}

/** Supplemental rows sorted last, as the journal orders them. */
function supplementalLast<T extends { abilityId: number }>(rows: T[]): T[] {
  return rows.filter((r) => !isSupplemental(r.abilityId))
    .concat(rows.filter((r) => isSupplemental(r.abilityId)));
}

/** Sources that only generate at zero Crux (Tome-Bearer's Inspiration, Banner Bearer); named in the wasted-procs tooltip. */
const BANNER_BEARER_ID = 217699;
export const CRUX_ZERO_ONLY_SOURCES = [186452, BANNER_BEARER_ID];

function abilityName(ctx: RenderCtx, abilityId: number): string {
  if (abilityId === 0) return t("all_abilities");
  const syn = SYNTHETIC_ABILITIES[abilityId];
  if (syn) return t(syn.key);
  const donorId = LOCALIZED_NAME_DONORS[abilityId]?.[currentLocale()] ?? NAME_DONORS[abilityId];
  const donor = donorId == null ? undefined : ctx.names[donorId];
  const info = donor?.name ? donor : ctx.names[abilityId];
  // cleanName strips grammar-flag suffixes (^F etc.) that pre-fix miner
  // dumps left in the database
  return info?.name ? cleanName(info.name) : `#${abilityId}`;
}

/** Recorded delivery/type labels for one component, before name grouping. */
function componentParts(ctx: RenderCtx, abilityId: number, healing = false): string[] {
  const mech = ctx.names[abilityId]?.mech;
  if (!mech) return [];
  const parts: string[] = [];
  if (mech.direct) parts.push(t("tag_direct"));
  if (mech.overTime) parts.push(t(healing ? "tag_hot" : "tag_dot"));
  if (mech.shield) parts.push(t("tag_shield"));
  if (mech.regen) parts.push(t("tag_regen"));
  if (mech.healAbsorption) parts.push(t("comp_absorbed"));
  if (!healing) {
    for (const dtype of mech.damageTypes || []) parts.push(tm("dmgtype", dtype, `#${dtype}`));
  }
  return parts;
}

/** Keep identical classifications distinguishable using the recorded ids. */
function componentLabels(ctx: RenderCtx, abilityIds: number[], healing = false): string[] {
  const labels = abilityIds.map((id) => componentParts(ctx, id, healing).join(" · "));
  return labels.map((label, i) => {
    if (!label) return `#${abilityIds[i]}`;
    return labels.indexOf(label) !== labels.lastIndexOf(label) ? `${label} (#${abilityIds[i]})` : label;
  });
}

// Mechanics tags for an ability, including all recorded damage types.
function mechParts(ctx: RenderCtx, abilityId: number, healing = false): string[] {
  const mech = ctx.names[abilityId]?.mech;
  if (!mech) return [];
  const parts = componentParts(ctx, abilityId, healing);
  if (mech.aoe === 1) parts.push(t("tag_aoe"));
  if (mech.buffType === 1) parts.push(t("buff"));
  else if (mech.buffType === 2) parts.push(t("debuff"));
  if (mech.durationMs) parts.push(`${Math.round(mech.durationMs / 100) / 10}s`);
  return parts.filter(Boolean);
}

function mechChip(ctx: RenderCtx, abilityIds: number[]): string {
  const mechs = abilityIds.map((id) => ctx.names[id]?.mech);
  const bits: string[] = [];
  if (mechs.some((mech) => mech?.overTime)) {
    if (mechs.some((mech) => mech?.direct)) bits.push(t("tag_direct"));
    bits.push(t("tag_dot"));
  }
  if (mechs.some((mech) => mech?.aoe === 1)) bits.push(t("tag_aoe"));
  if (bits.length === 0) return "";
  return `<span class="tag m-hide">${escapeHtml(bits.join(" · "))}</span>`;
}

// Deterministic placeholder gradient so unresolved abilities still get a
// stable colored tile (the design's letter-tile look)
function phGradient(abilityId: number): string {
  const hue = (abilityId * 137) % 360;
  return `linear-gradient(135deg, hsl(${hue}, 42%, 30%), hsl(${hue}, 50%, 52%))`;
}

// NOTE: the inline onerror= handlers below are CSP-hostile (they need
// 'unsafe-inline' for script attributes); kept verbatim from the .mjs.
function iconHtml(ctx: RenderCtx, abilityId: number, cls = "icon"): string {
  const syn = SYNTHETIC_ABILITIES[abilityId];
  if (syn) {
    return `<img class="${cls}" src="${syn.icon}" alt="" loading="lazy" onerror="this.classList.add('broken')">`;
  }
  const donorId = ICON_DONORS[abilityId];
  const donor = donorId != null ? ctx.names[donorId] : undefined;
  const info = donor?.iconUrl ? donor : ctx.names[abilityId];
  const name = abilityName(ctx, abilityId);
  if (info?.iconUrl) {
    return `<img class="${cls}" src="${escapeHtml(info.iconUrl)}" alt="" loading="lazy" onerror="this.classList.add('broken')">`;
  }
  return `<span class="${cls} ph" style="background:${phGradient(abilityId)}">${escapeHtml(name.charAt(0).toUpperCase())}</span>`;
}

/** Short durations the way the mech tags render them: "1.4s" (0 -> ""). */
function fmtSeconds(ms: number | undefined): string {
  if (!ms || ms <= 0) return "";
  return `${(ms / 1000).toFixed(1)}s`;
}

// Cast/channel/duration/tick from the miner data, appended to every ability
// tooltip that has them (each line drops out when the DB has no value).
function mechStats(ctx: RenderCtx, abilityId: number): DetailStat[] {
  const mech = ctx.names[abilityId]?.mech;
  if (!mech) return [];
  return ([
    [t("tt_cast"), fmtSeconds(mech.castMs)],
    [t("tt_channel"), fmtSeconds(mech.channelMs)],
    [t("tt_duration"), fmtSeconds(mech.durationMs)],
    [t("tt_tick"), fmtSeconds(mech.tickMs)],
  ] as DetailStat[]).filter((p) => p[1] !== "");
}

/**
 * Caveats an ability card must carry. Combat-event ids often have no text of
 * their own, so the worker lends them a same-name ability's description and
 * flags it — a borrowed line can describe a different morph or rank entirely.
 * It counts as exact when the donor is itself part of this share (the event
 * matched a skill someone actually slotted); with the donor unknown, the
 * disclaimer stays — never hide it on missing data.
 */
function abilityNotes(ctx: RenderCtx, abilityId: number): string[] {
  const info = ctx.names[abilityId];
  if (!info?.approxTooltip) return [];
  const donorId = info.tooltipDonorId;
  if (donorId !== undefined && ctx.knownAbilityIds.has(donorId)) return [];
  return [t("tt_approx")];
}

interface AbilityDetailOptions {
  name?: string;
  abilityIds?: number[];
  healing?: boolean;
  visibleStats?: string[];
}

function abilityDetails(
  ctx: RenderCtx, abilityId: number, stats: DetailStat[], foot?: string, options: AbilityDetailOptions = {},
): string {
  const ids = options.abilityIds || [abilityId];
  const referenceId = ctx.names[abilityId]?.tooltip ? abilityId : ids.find((id) => ctx.names[id]?.tooltip) ?? abilityId;
  const info = ctx.names[referenceId];
  const tags = [...new Set(ids.flatMap((id) => mechParts(ctx, id, options.healing)))];
  if (ids.length === 1) tags.push(`#${abilityId}`);
  const reference = detailCard({
    iconHtml: iconHtml(ctx, abilityId),
    name: options.name || abilityName(ctx, abilityId),
    tag: tags.join(" · "),
    desc: info?.tooltip || "",
    notes: abilityNotes(ctx, referenceId),
    stats2: mechStats(ctx, referenceId),
  });
  const additional = stats.filter(([label]) => !options.visibleStats?.includes(label));
  return (additional.length ? detailStats(additional) : "")
    + (foot ? `<p class="note">${escapeHtml(foot)}</p>` : "")
    + (SYNTHETIC_ABILITIES[abilityId] ? "" : `<section class="ability-reference">${sectHead(t("detail_ability"))}${reference}</section>`);
}

function unitName(ctx: RenderCtx, unitId: number | string): string {
  const raw = ctx.decoded.unitNames?.[Number(unitId)];
  return raw ? cleanName(raw) : `Unit #${unitId}`;
}

/** A definition name from the defs store, falling back to "#id". */
function defName(ctx: RenderCtx, kind: keyof DefsStore, id: number): string {
  return ctx.defs?.[kind]?.[id]?.name || `#${id}`;
}

/**
 * The enchantment section of an item card. The miner reads each enchant's
 * description from the FIRST item link it meets carrying that enchant, so the
 * baked numbers belong to that arbitrary slot: real potency scales with item
 * type (one-hand weapons and the small armor pieces are reduced) and trait
 * (Infused raises it). Mirroring ZOS's multiplier tables for approximate
 * gains would be a standing maintenance liability, so the card says so.
 */
function enchantBlock(ctx: RenderCtx, enchantId: number): DetailBlock[] {
  if (!enchantId) return [];
  return [{
    head: defName(ctx, "enchant", enchantId),
    desc: ctx.defs?.enchant?.[enchantId]?.tooltip || "",
    note: t("tt_enchant_base"),
  }];
}

/**
 * The set section of an item card: one row per bonus step. The miner joins
 * every GetItemSetBonusInfo line with \n into the def's tooltip. Absent when
 * the item carries no set id (an item row from before the set_id column) or
 * when its def has not loaded yet - no placeholder either way.
 */
function setBonusBlock(ctx: RenderCtx, setId: number | null | undefined): DetailBlock[] {
  if (!setId) return [];
  const def = ctx.defs?.set?.[setId];
  if (!def) return [];
  const lines = (def.tooltip || "").split("\n").map((l) => l.trim()).filter(Boolean);
  // A name-only def adds nothing the stats grid does not already say
  return lines.length ? [{ head: def.name, lines }] : [];
}

/** A standalone enchant card, for enchant mentions outside an item row. */
function enchantDetails(ctx: RenderCtx, enchantId: number): string {
  return detailCard({
    name: defName(ctx, "enchant", enchantId),
    desc: ctx.defs?.enchant?.[enchantId]?.tooltip || "",
    notes: [t("tt_enchant_base")],
  });
}

/** Grouped "<enchant> ×<count>" pieces, each hovering its own enchant card. */
function enchantCountBits(ctx: RenderCtx, counts: MemberGroupedCount[] | undefined): string {
  return (counts || []).filter((g) => g.id > 0)
    .map((g) => disclosure(escapeHtml(`${defName(ctx, "enchant", g.id)} ×${g.count}`), enchantDetails(ctx, g.id), "reference-detail"))
    .join("");
}

/**
 * The trait section of an item card: the localized trait name (the same one
 * the stats grid shows) over the mined gold-quality description. `note` is
 * the Heartland caveat, which stands on its own when the description has not
 * been mined yet.
 */
function traitBlock(ctx: RenderCtx, traitType: number, note?: string): DetailBlock[] {
  if (!traitType || traitType <= 0) return [];
  const desc = ctx.defs?.trait?.[traitType]?.tooltip || "";
  return desc || note ? [{ head: tm("traits", traitType, `#${traitType}`), desc, note: [desc ? t("trait_reference_note") : "", note].filter(Boolean).join(" ") }] : [];
}

/** A standalone trait card, for trait mentions outside an item row. */
function traitDetails(ctx: RenderCtx, traitType: number): string {
  const desc = ctx.defs?.trait?.[traitType]?.tooltip;
  return desc ? detailCard({ name: tm("traits", traitType, `#${traitType}`), desc, notes: [t("trait_reference_note")] }) : "";
}

/**
 * Grouped "<trait> ×<count>" pieces, each hovering its own trait card. Traits
 * are a game enum keyed defs kind, and armor/weapon/jewelry ids share one
 * numbering — so a category's counts must never be concatenated with
 * another's before they are named.
 */
function traitCountBits(ctx: RenderCtx, counts: MemberGroupedCount[] | undefined): string {
  return (counts || []).filter((g) => g.id > 0)
    .map((g) => disclosure(escapeHtml(`${tm("traits", g.id, `#${g.id}`)} ×${g.count}`), traitDetails(ctx, g.id), "reference-detail"))
    .join("");
}

// Heartland Conqueror doubles WEAPON trait effectiveness on the bar wearing 5
// pieces (id verified against UESP; 131 "Bastion of the Heartland" is a
// different set). Armor and jewelry count toward both bars, weapons only
// toward their own, and a two-hander counts as two - the same split
// computeSetData applies in game.
const HEARTLAND_SET_ID = 583;
const HEARTLAND_PIECES = 5;
const TWO_HANDED_WEAPON_TYPES = new Set([4, 5, 6, 8, 9, 12, 13, 15]);

interface BarFlags {
  front: boolean;
  back: boolean;
}

/** Heartland per bar from a member's broadcast set counts. */
function memberHeartlandBars(setup: MemberSetup): BarFlags {
  const set = (setup.sets || []).find((s) => s.setId === HEARTLAND_SET_ID);
  return {
    front: (set?.frontCount || 0) >= HEARTLAND_PIECES,
    back: (set?.backCount || 0) >= HEARTLAND_PIECES,
  };
}

/** Heartland per bar from the uploader's own slots (needs mined set ids). */
function selfHeartlandBars(ctx: RenderCtx, slots: WireEquipSlot[]): BarFlags {
  let shared = 0;
  let front = 0;
  let back = 0;
  for (const slot of slots) {
    const info = ctx.itemNames[slot.itemId];
    if (info?.setId !== HEARTLAND_SET_ID) continue;
    const pieces = TWO_HANDED_WEAPON_TYPES.has(info.weaponType || 0) ? 2 : 1;
    if (slot.slotIndex === 5 || slot.slotIndex === 6) front += pieces;
    else if (slot.slotIndex === 13 || slot.slotIndex === 14) back += pieces;
    else shared += pieces;
  }
  return { front: shared + front >= HEARTLAND_PIECES, back: shared + back >= HEARTLAND_PIECES };
}

function chip(label: string, attrs = ""): string {
  return `<span class="badge-alt"${attrs}>${escapeHtml(label)}</span>`;
}

function sectHead(label: string): string {
  return `<div class="sect-head"><span class="dmd sm"></span><span class="lab">${escapeHtml(label)}</span><span class="rule"></span></div>`;
}

interface KvOptions {
  sub?: string;
  bad?: boolean;
}

function kv(k: string, v: string, { sub = "", bad = false }: KvOptions = {}): string {
  return `<div class="kv"><span class="kv-k">${escapeHtml(k)}${sub ? `<span class="sub">${escapeHtml(sub)}</span>` : ""}</span><span class="kv-v${bad ? " bad" : ""}">${escapeHtml(v)}</span></div>`;
}

/**
 * A labelled cluster of kv rows. The journal splits these stats into headed
 * sections (Damage Delivery / AoE vs Single Target / By Damage Type, Quality);
 * one flat run of identical rows reads as a wall of numbers instead.
 * `label` empty keeps the group unlabelled but still spaced apart.
 */
function kvGroup(label: string, rows: string[]): string {
  const body = rows.filter(Boolean).join("");
  if (!body) return "";
  return `<div class="kv-group">${label ? `<div class="kv-sub">${escapeHtml(label)}</div>` : ""}${body}</div>`;
}

// ---- compact, grouped metrics ----

function summarySection(groups: string[]): string {
  return `<div class="metric-summary">${groups.filter(Boolean).join("")}</div>`;
}

function metricGroup(label: string, rows: string[]): string {
  const body = rows.filter(Boolean).join("");
  if (!body) return "";
  return `<section class="metric-group"><h2>${escapeHtml(label)}</h2><div class="metric-rows">${body}</div></section>`;
}

function keyMetric(label: string, value: string, sub?: string): string {
  return `<div class="metric primary"><span class="metric-label">${escapeHtml(label)}</span><span class="metric-value">${value}</span>${sub ? `<div class="metric-note">${sub}</div>` : ""}</div>`;
}

function metric(label: string, value: string, extraHtml = "", sub = ""): string {
  return `<div class="metric"><span class="metric-label">${escapeHtml(label)}</span><span class="metric-value">${value}</span>${extraHtml ? `<div class="metric-extra">${extraHtml}</div>` : ""}${sub ? `<div class="metric-note">${sub}</div>` : ""}</div>`;
}

function meterHtml(frac: number, deadFrac?: number): string {
  const pct = Math.max(0, Math.min(100, frac * 100));
  const dead = deadFrac ? Math.max(0, Math.min(100 - pct, deadFrac * 100)) : 0;
  return `<div class="meter"><span class="fill" style="width:${pct.toFixed(1)}%"></span>${dead ? `<span class="dead" style="width:${dead.toFixed(1)}%"></span>` : ""}</div>`;
}

// ---- group model (personal + shared members) ----

export interface GroupMember {
  me: boolean;
  wireSelf: boolean;
  name: string;
  sub: string;
  role: number;
  total: number;
  /** Every rate below is over the member's OWN duration, as group_table.lua
   * computes them - members can carry different durations, which is why the
   * journal compares rates and not totals. */
  dps: number;
  crit: number;
  taken: number;
  dtps: number;
  /** Raw healing out per second; the journal's HPS column is rawOut. */
  hps: number | null;
  effectiveHps: number | null;
  overheal: number | null;
  healingOut: number | null;
  /** Fraction of the member's fight spent alive; 1 when not reported. */
  alive: number;
  deaths: number;
  /** Successful resurrection casts; 0 when the sender's payload predates v19 */
  res: number;
  entry: DecodedSharedEntry;
  /** The member's broadcast build summary, when they shared one */
  setup: MemberSetup | null;
}

export interface GroupModel {
  members: GroupMember[];
  hasShared: boolean;
  hasObserved: boolean;
  personalTotal: number;
  groupTotal: number;
  personalShare: number;
}

/**
 * `targetFilter` scopes the group denominator the way the addon does: on the
 * boss tab, group total, group DPS and your share are all boss-only, so the
 * share sits over the same denominator as the personal number beside it
 * (arithmancer.lua groupTotalDamage applies the target filter to both maps and
 * deliberately applies no source filter). Member entries stay whole-fight —
 * they feed the group table, which the journal likewise leaves unfiltered.
 */
function groupModel(ctx: RenderCtx, targetFilter?: Set<number> | null): GroupModel {
  const filter = targetFilter && targetFilter.size ? targetFilter : null;
  const personalTotal = M.nestedTotal(ctx.decoded.damageByUnitId, filter);
  const observedTotal = M.nestedTotal(ctx.decoded.damageByUnitIdGroup, filter);
  const shared = ctx.wireEnc.shared || [];

  // Members come from the shared entries alone - the sharer broadcasts
  // their own entry too, so a synthesized "You" row would double them up.
  // Self is the entry the uploader's own client flagged on the wire
  // (entryFlags bit0), not a guess from the numbers.
  const members: GroupMember[] = [];
  for (const wireEntry of shared) {
    const entry = ctx.sharedDecoded.get(wireEntry);
    if (!entry) continue;
    const d = entry.data;
    const dur = (d.durationMs || ctx.durationMs) / 1000 || 1;
    members.push({
      me: false,
      wireSelf: wireEntry.isSelf === true,
      name: entry.displayName,
      sub: tm("roles", entry.role, ""),
      role: entry.role || 0,
      total: d.totalDamage,
      dps: d.totalDamage / dur,
      crit: d.critPercent,
      taken: d.totalDamageTaken,
      dtps: (d.totalDamageTaken || 0) / dur,
      hps: d.healing ? d.healing.rawOut / dur : null,
      effectiveHps: d.healing ? d.healing.effectiveOut / dur : null,
      overheal: d.healing ? (d.healing.rawOut > 0 ? Math.max(0, d.healing.rawOut - d.healing.effectiveOut) / d.healing.rawOut : 0) : null,
      healingOut: d.healing?.effectiveOut ?? null,
      alive: d.aliveTimeMs != null && d.durationMs > 0 ? d.aliveTimeMs / d.durationMs : 1,
      deaths: d.deaths?.deathCount || 0,
      res: d.resurrections || 0,
      entry,
      setup: wireEntry.memberSetup ?? null,
    });
  }
  members.sort((a, b) => b.total - a.total);
  const self = members.find((m) => m.wireSelf);
  if (self) self.me = true;

  const groupTotal = personalTotal + observedTotal;
  return {
    members,
    hasShared: shared.length > 0,
    hasObserved: observedTotal > 0,
    personalTotal,
    groupTotal,
    personalShare: groupTotal > 0 ? personalTotal / groupTotal : 1,
  };
}

function bandHtml(model: GroupModel, tall?: boolean): string {
  const sum = model.members.reduce((s, m) => s + m.total, 0) || 1;
  const segs = model.members.map((m) =>
    `<span class="${m.me ? "me" : "other"}" style="width:${(m.total / sum * 100).toFixed(1)}%"></span>`
  ).join("");
  return `<div class="band${tall ? " tall" : ""}">${segs}</div>`;
}

const ROLE_ICONS: Record<number, string> = { 1: "lfg_icon_dps", 2: "lfg_icon_tank", 4: "lfg_icon_healer" };

// NOTE: the inline onerror= handler below is CSP-hostile; kept verbatim.
function roleBox(role: number): string {
  const icon = ROLE_ICONS[role];
  const img = icon
    ? `<img src="/icons/esoui/art/lfg/${icon}.png" alt="" loading="lazy" onerror="this.style.display='none'">`
    : "";
  return `<span class="role-box" role="img" aria-label="${escapeHtml(tm("roles", role, ""))}">${img}</span>`;
}

function memberDamageDetails(ctx: RenderCtx, m: GroupMember): string {
  const d = m.entry.data;
  const typedTotal = d.damageByType.reduce((sum, row) => sum + row.damage, 0);
  return detailStats([
    [t("tt_total"), fmtExact(d.totalDamage)], [t("tt_crit"), fmtPercent(d.critPercent)],
    [t("st_max_hit"), fmtNumber(d.maxHit)],
  ]) + kvGroup(t("h_damage_delivery"), [
    kv(t("tag_direct"), fmtPercent(1 - d.dotPercent)), kv(t("tag_dot"), fmtPercent(d.dotPercent)),
  ]) + kvGroup(t("h_aoe_vs_st"), [
    kv(t("tag_aoe"), fmtPercent(d.aoePercent)), kv(t("comp_st"), fmtPercent(1 - d.aoePercent)),
  ]) + kvGroup(t("h_by_damage_type"), [...d.damageByType].sort((a, b) => b.damage - a.damage).map((r) =>
    kv(tm("dmgtype", r.type, `#${r.type}`), `${fmtNumber(r.damage)} · ${fmtPercent(typedTotal > 0 ? r.damage / typedTotal : 0)}`)));
}

/** Full broadcast data belongs on the dedicated Group page. */
function memberDetails(ctx: RenderCtx, m: GroupMember): string {
  const d = m.entry.data;
  const duration = d.durationMs || ctx.durationMs;
  const bossBlock = (name: string, stats: DetailStat[]): string =>
    `<div class="boss-stats"><h3>${escapeHtml(name)}</h3>${detailStats(stats)}</div>`;
  const bosses = d.bossDamage.map((b) => bossBlock(
    zenBossName(ctx, `${b.bossTag}:${b.tagSeq}`), [
      [t("tt_total"), fmtExact(b.damage)], [t("tt_dps"), fmtDps(b.damage, duration)],
      [t("tt_crit"), fmtPercent(b.critPercent)], [t("tag_dot"), fmtPercent(b.dotPercent)],
      [t("tag_aoe"), fmtPercent(b.aoePercent)], [t("comp_magical"), fmtPercent(b.magicalPercent)],
    ])).join("");
  const taken = detailStats([[t("k_damage_taken"), fmtExact(d.totalDamageTaken)], [t("th_dtps"), rateCell(m.dtps)]])
    + d.bossDamageTaken.map((b) => bossBlock(zenBossName(ctx, `${b.bossTag}:${b.tagSeq}`), [
      [t("tt_total"), fmtExact(b.damage)], [t("th_dtps"), fmtDps(b.damage, duration)],
      [t("th_share"), fmtPercent(d.totalDamageTaken > 0 ? b.damage / d.totalDamageTaken : 0)],
    ])).join("")
    + (d.topDamageTakenAbilities.length ? sectHead(t("h_taken_top")) + d.topDamageTakenAbilities.map((a) =>
      disclosure(escapeHtml(abilityName(ctx, a.abilityId)) + ` · ${fmtPercent(a.damagePercent)}`,
        abilityDetails(ctx, a.abilityId, []), "reference-detail")).join("") : "");
  const h = d.healing;
  const healing = h ? detailStats([
    [t("heal_raw_total"), fmtExact(h.rawOut)], [t("heal_effective_total"), fmtExact(h.effectiveOut)],
    [t("tt_overheal"), fmtExact(Math.max(0, h.rawOut - h.effectiveOut))],
    [t("group_raw_self"), fmtExact(h.rawSelf)], [t("tt_self_heal"), fmtExact(h.effectiveSelf)],
    [t("st_self_hps"), fmtDps(h.rawSelf, duration)],
    [t("group_effective_self_hps"), fmtDps(h.effectiveSelf, duration)],
    [t("group_self_overheal"), `${fmtExact(Math.max(0, h.rawSelf - h.effectiveSelf))} · ${fmtPercent(h.rawSelf > 0 ? Math.max(0, h.rawSelf - h.effectiveSelf) / h.rawSelf : 0)}`],
  ]) : "";
  const encounter = detailStats([
    [t("group_recorded_duration"), fmtDuration(duration)],
    [t("st_time_alive"), fmtDuration(d.aliveTimeMs ?? duration)],
    [t("k_resurrections"), m.res],
  ]);
  const zen = (d.zenByBoss || []).map((b) => kv(zenBossName(ctx, `${b.bossTag}:${b.tagSeq}`),
    t("zen_share_line", (b.avgStacksTenths / 10).toFixed(1), fmtDuration(b.timeAt5Ms)))).join("");
  return `<div class="member-overview">${
    contentSection(t("k_boss_damage"), bosses)
    + contentSection(t("nav_damage"), memberDamageDetails(ctx, m))
    + contentSection(t("tab_damage_taken"), taken)
    + contentSection(t("nav_healing"), healing)
    + contentSection(t("summary_encounter"), encounter)
    + contentSection(t("zen_short"), zen)}</div>`;
}

function groupRail(ctx: RenderCtx, model: GroupModel): string {
  if (model.members.length <= 1) return "";
  const sharedTotal = model.members.reduce((sum, m) => sum + m.total, 0);
  const rows = model.members.map((m) => disclosure(`
    <span class="mem-row">
      ${roleBox(m.role)}
      <span style="min-width:0"><span class="mem-name${m.me ? " me" : ""}">${escapeHtml(m.name)}</span><span class="mem-cls">${escapeHtml(m.sub)}</span></span>
      <span><span class="mem-dps">${fmtNumber(m.dps)}</span><span class="mem-sh">${fmtPercent(sharedTotal ? m.total / sharedTotal : 0)}</span></span>
    </span>`, memberDamageDetails(ctx, m), "member-reference")).join("");
  return sectHead(t("h_group")) + `<p class="note">${escapeHtml(t("group_scope_note"))}</p>` + rows;
}

// Per-boss personal DPS list for the damage rail
function bossRail(ctx: RenderCtx): string {
  const keys = Object.keys(ctx.wireEnc.bossSeqNames || {});
  if (keys.length === 0) return "";
  const byBossPersonal: Record<string, number> = {};
  for (const byTarget of Object.values(ctx.decoded.damageByUnitId || {})) {
    for (const [targetId, byAbility] of Object.entries(byTarget)) {
      const key = ctx.wireEnc.bossTagSeqByUnitId?.[Number(targetId)];
      if (!key) continue;
      byBossPersonal[key] = (byBossPersonal[key] || 0) + M.sumBreakdowns(byAbility);
    }
  }
  const rows = keys.map((key) => {
    const name = cleanName(ctx.wireEnc.bossSeqNames[key] || key);
    const dps = fmtDps(byBossPersonal[key] || 0, ctx.durationMs);
    return `<div class="kv"><span class="kv-k" style="font-size:15px;color:var(--ink)">${escapeHtml(name)}</span><span class="kv-v" style="color:var(--gold);font-size:17px">${dps} DPS</span></div>`;
  }).join("");
  return sectHead(t("h_boss")) + rows;
}

// ---- data tables ----

interface DtCol {
  label?: string;
  r?: boolean;
}

function dtHead(cols: DtCol[], gridStyle: string): string {
  return `<div class="dt-head" style="${gridStyle}">${cols.map((c) =>
    `<span${c.r ? ' class="r"' : ""}>${escapeHtml(c.label || "")}</span>`).join("")}</div>`;
}

// ============================================================================
// OVERVIEW
// ============================================================================

function overviewEncounter(ctx: RenderCtx): string {
  const d = ctx.decoded;
  // The recorder omits alive time when it equals the entire encounter.
  const alive = d.playerAliveTimeMs ?? ctx.durationMs;
  const bossTotals = M.groupDamageByBoss(d, ctx.wireEnc.bossTagSeqByUnitId || {});
  return sectHead(t("summary_encounter"))
    + kv(t("tt_duration"), fmtDuration(ctx.durationMs))
    + kv(t("st_time_alive"), `${fmtDuration(alive)} · ${fmtPercent(ctx.durationMs > 0 ? alive / ctx.durationMs : 0)}`)
    + kv(t("st_deaths"), String(d.deaths?.deathCount || 0))
    + Object.entries(bossTotals).map(([key, total]) => kv(`${zenBossName(ctx, key)} · ${t("tab_group_damage")}`, fmtNumber(total),
      { sub: `${t("st_time_alive")}: ${d.unitAliveTimeMs?.[key.split(":")[0]!] != null ? fmtDuration(d.unitAliveTimeMs[key.split(":")[0]!]!) : "—"}` })).join("");
}

// Small meta line above the overview: the patch the fight was recorded
// on, plus the fight kinds the encounter flags mark.
function metaChips(ctx: RenderCtx): string {
  const chips: string[] = [];
  const version = (ctx.wireEnc.gameVersion || "").trim();
  if (version) chips.push(chip(/^v/i.test(version) ? version : `v${version}`));
  if (ctx.wireEnc.isPlayerFight) chips.push(chip(t("badge_duel")));
  if (ctx.wireEnc.isDummyFight) chips.push(chip(t("badge_dummy")));
  return chips.length ? `<div class="meta-chips">${chips.join("")}</div>` : "";
}

/**
 * Resurrections the uploader landed: the count, who was picked up, and the
 * full timeline (mm:ss + name) in the expanded count. The log only exists on
 * recordings that captured it; the bare count always does.
 */
function supportSection(ctx: RenderCtx): string {
  const count = ctx.decoded.resurrections;
  if (!count) return "";
  const log = ctx.decoded.resurrectionLog;
  const byName = new Map<string, number>();
  for (const event of log || []) {
    byName.set(event.displayName, (byName.get(event.displayName) || 0) + 1);
  }
  const targets = [...byName.entries()].sort((a, b) => (b[1] - a[1]) || a[0].localeCompare(b[0]));
  const tt = log
    ? detailCard({
      name: t("k_resurrections"),
      stats: log.map((e) => [fmtDuration(e.timeMs), e.displayName] as DetailStat),
    })
    : "";
  return sectHead(t("h_support"))
    + disclosure(kv(t("k_resurrections"), fmtExact(count)), tt)
    + targets.map(([name, n]) => kv(name, `${n}×`)).join("");
}

function overviewTab(ctx: RenderCtx): TabResult {
  const d = ctx.decoded;
  const model = groupModel(ctx);
  const rows = M.abilityRows(d.damageByUnitId, null, abilityNaming(ctx));
  const quality = realRows(rows);
  const hits = quality.reduce((s, r) => s + r.ticks, 0);
  const maxHit = quality.reduce((s, r) => Math.max(s, r.maxTick), 0);
  const personalBoss = M.nestedTotal(d.damageByUnitId, ctx.bossUnits.size ? ctx.bossUnits : null);
  const takenRows = M.damageTakenRows(d.damageTakenByUnitId);
  const takenTotal = takenRows.reduce((s, r) => s + r.total, 0);
  const selfHeal = d.healingStats?.selfHealing?.total;

  const totals: Array<[string, string]> = [
    [t("st_personal_dps"), fmtDps(model.personalTotal, ctx.durationMs)],
    ...(model.groupTotal > model.personalTotal ? [[t("st_group_dps"), fmtDps(model.groupTotal, ctx.durationMs)] as [string, string]] : []),
    [t("k_damage_done"), fmtExact(model.personalTotal)],
    ...(ctx.bossUnits.size ? [[t("k_boss_damage"), fmtExact(personalBoss)] as [string, string]] : []),
    [t("k_damage_taken"), fmtExact(takenTotal)],
    ...(selfHeal?.raw ? [[t("k_self_healing"), fmtExact(selfHeal.raw)] as [string, string]] : []),
    [t("k_max_hit"), fmtExact(maxHit)],
    [t("k_hits_landed"), fmtExact(hits)],
  ];
  // Sums first, then the journal's "Quality" pair - six identical rows in one
  // run gave the eye nothing to hold on to
  const totalsHtml = sectHead(t("h_totals"))
    + kvGroup("", totals.slice(0, -2).map(([k, v]) => kv(k, v)))
    + kvGroup(t("h_quality"), totals.slice(-2).map(([k, v]) => kv(k, v)));

  const takenTopHtml = takenRows.length
    ? sectHead(t("h_taken_top")) + takenRows.slice(0, 3).map((r) =>
        kv(abilityName(ctx, r.abilityId), fmtNumber(r.total),
          { sub: t("sub_recap_hits", r.ticks, fmtNumber(r.maxTick)) })).join("")
    : "";

  // Healing across both directions the player produced: self heals
  // and heals landed on the group.
  const h = d.healingStats;
  const selfTotals = h?.selfHealing?.total;
  let outReal = 0, outRaw = 0, outOver = 0;
  for (const out of Object.values(h?.healingOutToGroup || {})) {
    outReal += out.total?.real || 0;
    outRaw += out.total?.raw || 0;
    outOver += out.total?.overheal || 0;
  }
  const healRaw = (selfTotals?.raw || 0) + outRaw;
  const healOver = (selfTotals?.overheal || 0) + outOver;
  const healingHtml = (selfTotals?.real || 0) + outReal + healRaw > 0
    ? sectHead(t("h_healing"))
      + kv(t("heal_raw_hps"), fmtDps(healRaw, ctx.durationMs))
      + kv(t("heal_effective_hps"), fmtDps((selfTotals?.real || 0) + outReal, ctx.durationMs))
      + kv(t("st_self_hps"), fmtDps(selfTotals?.raw || 0, ctx.durationMs))
      + kv(t("th_healing_out"), fmtExact(outRaw))
      + kv(t("st_overheal"), fmtPercent(healRaw > 0 ? healOver / healRaw : 0, 0))
    : "";

  const w = d.weaving;
  let weavingHtml = "";
  if (w) {
    const timing = weavingTiming(w);
    weavingHtml = sectHead(t("h_weaving"))
      + kv(t("weave_average"), weaveAvg(timing.lost, timing.count))
      + kv(t("weave_time_lost"), `${(timing.lost / 1000).toFixed(1)}s · ${fmtPercent(ctx.durationMs > 0 ? timing.lost / ctx.durationMs : 0)}`)
      + kv(t("k_light"), [String(w.lightAttackHits), perMinute(w.lightAttackHits, ctx.durationMs)].filter(Boolean).join(" · "))
      + kv(t("k_heavy"), [String(w.heavyAttackHits), perMinute(w.heavyAttackHits, ctx.durationMs)].filter(Boolean).join(" · "))
      + kv(t("k_skill_casts"), String(w.skillActivations))
      + (w.downtimeGaps > 0
        ? kv(t("k_downtime"), `${(w.downtimeMs / 1000).toFixed(1)}s · ${fmtPercent(ctx.durationMs > 0 ? w.downtimeMs / ctx.durationMs : 0)}`)
        : "")
      + kv(t("k_weaving_errors"), String(w.totalWeavingErrors), { bad: w.totalWeavingErrors > 0 })
      + kv(t("k_double_lights"), String(w.doubleLaErrors), { bad: w.doubleLaErrors > 0 })
      + `<div class="note">${escapeHtml(t("note_weaving"))}</div>`;
  }

  const supportHtml = supportSection(ctx);
  const column = (sections: string[]) => `<div class="section-stack">${sections.filter(Boolean).map((body) => `<section>${body}</section>`).join("")}</div>`;

  const html = metaChips(ctx) + `
    <div class="cols-3">
      ${column([totalsHtml, takenTopHtml])}
      ${column([healingHtml, weavingHtml, supportHtml])}
      ${column([overviewEncounter(ctx), groupRail(ctx, model)])}
    </div>`;

  const csv: (string | number)[][] = [["Metric", "Value"],
    ["Duration", fmtDuration(ctx.durationMs)],
    ["DPS", Math.round(model.personalTotal / (ctx.durationMs / 1000 || 1))],
    ...totals,
    ...(d.resurrections ? [["Resurrections", d.resurrections] as (string | number)[]] : []),
    ...(w ? [
      ["Time lost ms", weavingTiming(w).lost],
      ["Average cast delay ms", weavingTiming(w).count ? weavingTiming(w).lost / weavingTiming(w).count : ""],
      ["Light attacks", w.lightAttackHits], ["Heavy attacks", w.heavyAttackHits],
      ["Skill casts", w.skillActivations], ["Downtime ms", w.downtimeMs],
      ["Weaving errors", w.totalWeavingErrors], ["Double lights", w.doubleLaErrors],
    ] : []),
  ];
  return { html, csv, title: "Overview" };
}

// ============================================================================
// TAB FILTERS
// ============================================================================
// Data semantics mirror ui/journal/filters.lua: units are grouped by display
// name (one checkbox can carry several unit ids), "self" is never grouped and
// always sorts first, and a filter only exists while something is unchecked.
// The panel itself is a web affordance - the journal uses a gamepad dialog.

/** filters.lua FilterConstants.SELF_DISPLAY_NAME. */
const SELF_KEY = "__SELF__";

/** The group damage tab's "everyone else" side; the game reports it as one pool. */
const OTHERS_KEY = "__OTHERS__";

const GROUP_DAMAGE_SUB = "group-damage";

/** Sub ids that carry a filter, and the axis their main list filters on. */
const FILTERABLE: Record<string, { title: StringKey; mainHeader: StringKey; sources?: boolean }> = {
  "damage-done": { title: "f_dmg_done", mainHeader: "f_done_to", sources: true },
  "boss-damage": { title: "f_boss_dmg", mainHeader: "f_boss_target", sources: true },
  [GROUP_DAMAGE_SUB]: { title: "f_group_dmg", mainHeader: "f_done_to", sources: true },
  "damage-taken": { title: "f_by_source", mainHeader: "f_by_source" },
  "healing-out": { title: "f_by_target", mainHeader: "f_by_target" },
  "healing-in": { title: "f_by_source", mainHeader: "f_by_source" },
  "effects-group": { title: "f_by_member", mainHeader: "f_by_member" },
};

/** Groups by display name, self first, then alphabetical (groupUnitsByName). */
function groupByName(entries: Array<[number | string, string]>, self?: FilterGroup): FilterGroup[] {
  const byName = new Map<string, Array<number | string>>();
  for (const [id, name] of entries) {
    const list = byName.get(name);
    if (list) list.push(id);
    else byName.set(name, [id]);
  }
  const groups = [...byName.entries()].map(([name, ids]) => ({
    key: name, label: name, ids, isSelf: false,
  }));
  groups.sort((a, b) => a.label.localeCompare(b.label, currentLocale()));
  return self ? [self, ...groups] : groups;
}

/** The self checkbox, when the tab's data has a self side to filter. */
function selfGroup(ctx: RenderCtx, id: number | string): FilterGroup {
  return { key: SELF_KEY, label: selfLabel(ctx), ids: [id], isSelf: true };
}

function mainFilterGroups(ctx: RenderCtx, subId: string): FilterGroup[] {
  const d = ctx.decoded;
  const named = (id: number | string): string => unitName(ctx, id);
  if (subId === "damage-done") {
    const targets = new Set<number>();
    for (const byTarget of Object.values(d.damageByUnitId || {})) {
      for (const targetId of Object.keys(byTarget)) targets.add(Number(targetId));
    }
    return groupByName([...targets].map((id) => [id, named(id)]));
  }
  if (subId === "boss-damage") {
    return groupByName((ctx.wireEnc.bossesUnits || []).map((id) => [id, named(id)]));
  }
  if (subId === GROUP_DAMAGE_SUB) {
    // Targets of both maps, bosses first: they are the default selection
    const targets = new Set<number>();
    for (const map of [d.damageByUnitId, d.damageByUnitIdGroup]) {
      for (const byTarget of Object.values(map || {})) {
        for (const targetId of Object.keys(byTarget)) targets.add(Number(targetId));
      }
    }
    const groups = groupByName([...targets].map((id) => [id, named(id)]));
    const isBoss = (g: FilterGroup): boolean => groupHasBoss(ctx, g);
    return groups.filter(isBoss).concat(groups.filter((g) => !isBoss(g)));
  }
  if (subId === "damage-taken") {
    return groupByName(Object.keys(d.damageTakenByUnitId || {}).map((id) => [Number(id), named(id)]));
  }
  if (subId === "healing-out" || subId === "healing-in") {
    const map = subId === "healing-out"
      ? d.healingStats?.healingOutToGroup : d.healingStats?.healingInFromGroup;
    const hasSelf = (d.healingStats?.selfHealing?.total?.raw || 0) > 0;
    return groupByName(Object.keys(map || {}).map((id) => [Number(id), named(id)]),
      hasSelf ? selfGroup(ctx, SELF_UNIT_ID) : undefined);
  }
  if (subId === "effects-group") {
    const hasSelf = Object.keys(d.effectsOnPlayer || {}).length > 0;
    return groupByName(Object.keys(d.effectsOnGroup || {}).map((name) => [name, name]),
      hasSelf ? selfGroup(ctx, SELF_KEY) : undefined);
  }
  return [];
}

/**
 * Damage Done also filters by source - the player, their pets and companions
 * (filters.lua getFilterableSources). The journal hides this list when there
 * is only one source, since one checkbox filters nothing.
 */
function sourceFilterGroups(ctx: RenderCtx): FilterGroup[] {
  const sources = Object.keys(ctx.decoded.damageByUnitId || {}).map(Number);
  if (sources.length <= 1) return [];
  const me = playerUnitId(ctx);
  const others = sources.filter((id) => id !== me);
  const self = me != null && sources.includes(me) ? selfGroup(ctx, me) : undefined;
  return groupByName(others.map((id) => [id, unitName(ctx, id)]), self);
}

/**
 * The two sides of the group damage tab: the personal map (the player, their
 * pets and companions) and everything the client observed from the rest of
 * the group, which the game reports with no source at all. Both are on by
 * default; neither is a unit id, so this never goes through groupByName.
 */
function sideFilterGroups(ctx: RenderCtx): FilterGroup[] {
  return [
    { key: SELF_KEY, label: selfLabel(ctx), ids: [SELF_KEY], isSelf: true },
    { key: OTHERS_KEY, label: t("f_others"), ids: [OTHERS_KEY], isSelf: false },
  ];
}

function filterGroups(ctx: RenderCtx, subId: string, axis: FilterAxis): FilterGroup[] {
  if (axis === "source") {
    return subId === GROUP_DAMAGE_SUB ? sideFilterGroups(ctx) : sourceFilterGroups(ctx);
  }
  return mainFilterGroups(ctx, subId);
}

function groupHasBoss(ctx: RenderCtx, group: FilterGroup): boolean {
  return group.ids.some((id) => ctx.bossUnits.has(Number(id)));
}

/**
 * What is unchecked before the viewer touches anything. Every tab starts on
 * "everything" except group damage, which opens on the bosses alone when the
 * fight has any (filters.lua initializePending for the group damage tab).
 */
function defaultOff(ctx: RenderCtx, subId: string, axis: FilterAxis, groups: FilterGroup[]): Set<string> {
  if (subId !== GROUP_DAMAGE_SUB || axis !== "main") return new Set();
  if (!groups.some((g) => groupHasBoss(ctx, g))) return new Set();
  return new Set(groups.filter((g) => !groupHasBoss(ctx, g)).map((g) => g.key));
}

/** The unchecked keys in force: the viewer's own set, else the tab's default. */
function effectiveOff(ctx: RenderCtx, subId: string, axis: FilterAxis, groups: FilterGroup[]): Set<string> {
  return unitFilters.get(filterStateKey(subId, axis)) ?? defaultOff(ctx, subId, axis, groups);
}

/** The ids still selected, or null when nothing is unchecked (= no filter). */
function resolveFilter(ctx: RenderCtx, groups: FilterGroup[], subId: string, axis: FilterAxis): Set<string> | null {
  const off = effectiveOff(ctx, subId, axis, groups);
  if (off.size === 0 || groups.length === 0) return null;
  if (!groups.some((g) => off.has(g.key))) return null;
  const selected = new Set<string>();
  for (const g of groups) {
    if (off.has(g.key)) continue;
    for (const id of g.ids) selected.add(String(id));
  }
  return selected;
}

/** Numeric unit-id filter for the damage and healing tabs. */
function unitFilterFor(ctx: RenderCtx, subId: string, axis: FilterAxis = "main"): Set<number> | null {
  const selected = resolveFilter(ctx, filterGroups(ctx, subId, axis), subId, axis);
  if (!selected) return null;
  const ids = new Set<number>();
  for (const id of selected) ids.add(Number(id));
  return ids;
}

/** Display-name filter for the group effects tab. */
function memberFilterFor(ctx: RenderCtx, subId: string): Set<string> | null {
  return resolveFilter(ctx, filterGroups(ctx, subId, "main"), subId, "main");
}

/** Which sides the group damage tab shows; both when nothing is unchecked. */
function damageSidesFor(ctx: RenderCtx, subId: string): { self: boolean; others: boolean } {
  const selected = resolveFilter(ctx, filterGroups(ctx, subId, "source"), subId, "source");
  if (!selected) return { self: true, others: true };
  return { self: selected.has(SELF_KEY), others: selected.has(OTHERS_KEY) };
}

/**
 * True when an axis of this tab is off its default, for the button's label
 * and the Reset button. Keys that no longer name a group (another encounter's
 * units) don't count.
 */
function filterActive(ctx: RenderCtx, subId: string): boolean {
  return !!tabFilters.get(subId) || (["main", "source"] as FilterAxis[]).some((axis) => {
    const groups = filterGroups(ctx, subId, axis);
    const stored = unitFilters.get(filterStateKey(subId, axis));
    if (!stored) return false;
    const live = new Set([...stored].filter((key) => groups.some((g) => g.key === key)));
    const dflt = defaultOff(ctx, subId, axis, groups);
    return live.size !== dflt.size || [...live].some((key) => !dflt.has(key));
  });
}

function filterCheckboxes(
  ctx: RenderCtx, subId: string, axis: FilterAxis, header: StringKey,
): string {
  const groups = filterGroups(ctx, subId, axis);
  if (groups.length === 0) return "";
  const off = effectiveOff(ctx, subId, axis, groups);
  const rows = groups.map((g) => {
    const on = !off?.has(g.key);
    return `<label class="filt-row">
      <input type="checkbox" data-filt-group="${escapeHtml(subId)}" data-filt-axis="${axis}" data-filt-key="${escapeHtml(g.key)}"${on ? " checked" : ""}>
      <span class="filt-lab${g.isSelf ? " self" : ""}">${escapeHtml(g.label)}</span>
    </label>`;
  }).join("");
  return `<div class="filt-sect"><div class="filt-head">${escapeHtml(t(header))}</div>${rows}</div>`;
}

/**
 * What the filter currently keeps, as removable chips. This is the web's
 * standing answer to "what am I looking at" — the journal only has room for a
 * "(Active)" suffix on its keybind, where a browser can name the scope and
 * let you drop parts of it.
 */
function filterChips(ctx: RenderCtx, subId: string): string {
  const chips: string[] = [];
  for (const axis of ["main", "source"] as FilterAxis[]) {
    const groups = filterGroups(ctx, subId, axis);
    const selected = resolveFilter(ctx, groups, subId, axis);
    if (!selected) continue;
    for (const g of groups) {
      if (!g.ids.some((id) => selected.has(String(id)))) continue;
      chips.push(`<button type="button" class="filt-chip" data-filt-chip="${escapeHtml(subId)}" data-filt-axis="${axis}" data-filt-key="${escapeHtml(g.key)}">
        ${escapeHtml(g.label)}<span class="fc-x" aria-hidden="true">×</span>
      </button>`);
    }
  }
  return chips.join("");
}

/**
 * The filter control for one tab: a button that reports whether a filter is
 * live (the journal's "Filter (Active)" keybind label), the active scope as
 * chips, and, when open, the game's multi-select list. Rendered above the tab
 * body; the breakdown tables below double as the click-to-filter surface.
 */
function filterBar(ctx: RenderCtx, subId: string): string {
  const spec = FILTERABLE[subId];
  if (!spec) return "";
  const groups = filterGroups(ctx, subId, "main");
  const sources = spec.sources ? filterGroups(ctx, subId, "source") : [];
  const active = filterActive(ctx, subId);
  if (groups.length <= 1 && sources.length === 0 && !active) return "";
  const open = openFilterPanels.has(subId);
  const panel = open
    ? `<div class="filt-panel">
        <div class="filt-title">${escapeHtml(t(spec.title))}</div>
        ${filterCheckboxes(ctx, subId, "main", spec.mainHeader)}
        ${spec.sources ? filterCheckboxes(ctx, subId, "source", "f_done_by") : ""}
      </div>`
    : "";
  return `<div class="filt">
    <button type="button" class="filt-btn${active ? " on" : ""}" data-filt-open="${escapeHtml(subId)}" aria-expanded="${open}">
      ${escapeHtml(t(active ? "filter_active" : "filter"))}<span class="rb-arr" aria-hidden="true">${open ? "⌄" : "›"}</span>
    </button>
    ${filterChips(ctx, subId)}
    ${filterResetButton(subId, active)}
    ${panel}
  </div>`;
}

function filterResetButton(subId: string, active: boolean): string {
  return `<button type="button" class="filt-btn ghost" data-filt-reset="${escapeHtml(subId)}"${active ? "" : " disabled"}>${escapeHtml(t("filter_reset"))}</button>`;
}

/** Makes a breakdown row a filter entry point for the unit it stands for. */
function filterRowAttrs(link: FilterLink | undefined, key: string): string {
  if (!link) return "";
  return ` data-filt-only="${escapeHtml(link.subId)}"`
    + ` data-filt-axis="${link.axis}" data-filt-key="${escapeHtml(key)}"`;
}

/** The extra row class, kept in the row's own class attribute. */
function filterAction(link: FilterLink | undefined, key: string): string {
  return link ? `<button type="button" class="detail-action"${filterRowAttrs(link, key)}>${escapeHtml(t("filter_to", key === SELF_KEY ? t("filter_self") : key))}</button>` : "";
}

/** Which filter a breakdown table's rows drive when clicked. */
interface FilterLink {
  subId: string;
  axis: FilterAxis;
}

// ============================================================================
// DAMAGE
// ============================================================================

const DMG_GRID = "grid-template-columns: 36px minmax(0,1fr) 90px 70px 90px 70px;";

function damageSummary(ctx: RenderCtx, model: GroupModel, rows: AbilityRow[], scopeTotal: number): string {
  const durS = ctx.durationMs / 1000 || 1;
  // Crit rate and max hit are measured over real abilities only - a shield
  // absorption has no crit and would otherwise dilute the denominator
  // (arithmancer.lua getDamageQuality skips the same id).
  const quality = realRows(rows);
  const ticks = quality.reduce((s, r) => s + r.ticks, 0);
  const crits = quality.reduce((s, r) => s + r.critTicks, 0);
  const critFrac = ticks > 0 ? crits / ticks : 0;
  let maxRow: AbilityRow | null = null;
  for (const r of quality) if (!maxRow || r.maxTick > maxRow.maxTick) maxRow = r;

  const blocks = [
    keyMetric(t("st_personal_dps"), fmtExact(scopeTotal / durS),
      t("sub_damage_hits", fmtExact(scopeTotal), fmtExact(ticks), fmtDuration(ctx.durationMs))),
  ];
  if (model.groupTotal > model.personalTotal) {
    blocks.push(metric(t("st_group_dps"), fmtExact(model.groupTotal / durS),
      model.hasShared ? bandHtml(model) : "",
      model.hasShared ? t("sub_slice", fmtPercent(model.personalShare)) : t("sub_share", fmtPercent(model.personalShare))));
  }
  blocks.push(metric(t("st_crit"), fmtPercent(critFrac), meterHtml(critFrac),
    t("sub_crit", fmtExact(crits), fmtExact(ticks))));
  if (maxRow) {
    blocks.push(metric(t("st_max_hit"), fmtNumber(maxRow.maxTick), "",
      escapeHtml(maxRow.label || abilityName(ctx, maxRow.abilityId))));
  }
  const outputCount = model.groupTotal > model.personalTotal ? 2 : 1;
  return summarySection([
    metricGroup(t("summary_output"), blocks.slice(0, outputCount)),
    metricGroup(t("summary_damage_quality"), blocks.slice(outputCount)),
  ]);
}

function damageTable(
  ctx: RenderCtx, rows: AbilityRow[], total: number, shareKey: StringKey = "tt_share_dmg",
): string {
  const durS = ctx.durationMs / 1000 || 1;
  // Shares are over the eligible total and supplemental rows sink to the
  // bottom with no percentage, so shield absorptions can't dilute every
  // real ability's share (renderers/damage.lua eligibleTotalDamage).
  const ordered = supplementalLast(rows);
  const eligible = realRows(rows).reduce((s, r) => s + r.total, 0) || total;
  const topShare = ordered[0] && !isSupplemental(ordered[0].abilityId) ? ordered[0].total / eligible : 1;
  const head = dtHead([
    {}, { label: t("th_ability") }, { label: t("th_dps"), r: true }, { label: t("th_crit"), r: true },
    { label: t("th_max_hit"), r: true }, { label: t("th_share"), r: true },
  ], DMG_GRID);
  const body = ordered.map((r) => {
    const supp = isSupplemental(r.abilityId);
    const share = !supp && eligible > 0 ? r.total / eligible : 0;
    const shareCell = supp ? "—" : fmtPercent(share);
    const crit = fmtPercent(M.critPercent(r));
    const tt = abilityDetails(ctx, r.abilityId, [
      [t("tt_total"), fmtExact(r.total)],
      [t("tt_dps"), fmtNumber(r.total / durS)],
      [t("tt_hits"), fmtExact(r.ticks)],
      [t("tt_crit"), crit],
      [t("tt_avg_hit"), fmtNumber(M.averageTick(r))],
      [t("tt_minmax"), `${fmtNumber(r.minTick)} – ${fmtNumber(r.maxTick)}`],
    ], supp ? undefined : t(shareKey, fmtPercent(share)), {
      name: r.label, abilityIds: r.variants.map((v) => v.abilityId),
      visibleStats: [t("tt_dps"), t("tt_crit")],
    });
    return detailRow(`
      ${iconHtml(ctx, r.abilityId)}
      <span class="cell-name">${escapeHtml(r.label || abilityName(ctx, r.abilityId))}${mechChip(ctx, r.variants.map((v) => v.abilityId))}</span>
      <span class="num m-hide">${fmtNumber(r.total / durS)}</span>
      <span class="num m-hide">${crit}</span>
      <span class="num m-hide">${fmtNumber(r.maxTick)}</span>
      <span class="big">${shareCell}</span>
      <span class="dt-meta">${fmtNumber(r.total / durS)}/s · ${escapeHtml(t("tt_crit"))} ${crit} · ${escapeHtml(t("th_max_hit"))} ${fmtNumber(r.maxTick)}</span>
      <span class="dt-bar" style="width:${(topShare > 0 ? share / topShare * 100 : 0).toFixed(1)}%"></span>
    `, damageComponents(ctx, r) + tt, DMG_GRID);
  }).join("");
  return `<div class="dt">${head}${body}</div>`;
}

function damageCsv(ctx: RenderCtx, rows: AbilityRow[], total: number): (string | number)[][] {
  // same eligible denominator the table prints, so exports and screen agree
  const eligible = realRows(rows).reduce((s, r) => s + r.total, 0) || total;
  return ([["Ability", "Total", "Share", "DPS", "Hits", "Crit hits", "Min", "Avg", "Max"]] as (string | number)[][])
    .concat(supplementalLast(rows).map((r) => [
      r.label || abilityName(ctx, r.abilityId), r.total,
      isSupplemental(r.abilityId) || !eligible ? "" : (r.total / eligible).toFixed(4),
      (r.total / (ctx.durationMs / 1000 || 1)).toFixed(1), r.ticks, r.critTicks,
      r.minTick, Math.round(M.averageTick(r)), r.maxTick,
    ]));
}

// ---- per-unit rollups (by target / by source) ----

const UNIT_GRID = "grid-template-columns: minmax(0,1fr) 100px 90px 80px;";

interface UnitRollup {
  unitId: number;
  total: number;
  byAbility: Map<number, number>;
}

/**
 * Collapses a nested damage map to one row per unit. `dim` picks which axis
 * names the row: "target" keys on the inner unit (who was hit), "source" on
 * the outer one (who hit). Rows are sorted by total desc.
 */
function unitRollups(
  damageMaps: DamageMaps,
  dim: "target" | "source",
  targetFilter: Set<number> | null,
  sourceFilter?: Set<number> | null,
): UnitRollup[] {
  const rows = new Map<number, UnitRollup>();
  const maps = Array.isArray(damageMaps) ? damageMaps : damageMaps ? [damageMaps] : [];
  for (const damageMap of maps) {
    for (const [outerId, byInner] of Object.entries(damageMap)) {
      if (sourceFilter && !sourceFilter.has(Number(outerId))) continue;
      for (const [innerId, byAbility] of Object.entries(byInner)) {
        if (targetFilter && !targetFilter.has(Number(innerId))) continue;
        const unitId = Number(dim === "target" ? innerId : outerId);
        let row = rows.get(unitId);
        if (!row) {
          row = { unitId, total: 0, byAbility: new Map() };
          rows.set(unitId, row);
        }
        for (const [abilityId, b] of Object.entries(byAbility)) {
          const amount = b.total || 0;
          row.total += amount;
          const id = Number(abilityId);
          row.byAbility.set(id, (row.byAbility.get(id) || 0) + amount);
        }
      }
    }
  }
  return [...rows.values()].filter((r) => r.total > 0).sort((a, b) => b.total - a.total);
}

function unitDamageSection(
  ctx: RenderCtx, rows: UnitRollup[], total: number, label: string, link?: FilterLink,
): string {
  // A single unit restates the table above it; the section only earns its
  // space once the damage is actually split across units. When the tab has a
  // filter, each row is also the way into it: click a unit, see only it.
  if (rows.length <= 1) return "";
  const top = rows[0]?.total || 1;
  const head = dtHead([
    {}, { label: t("th_total"), r: true },
    { label: t("th_share"), r: true }, { label: t("th_dps"), r: true },
  ], UNIT_GRID);
  const body = rows.map((r) => {
    const share = total > 0 ? r.total / total : 0;
    const abilities = [...r.byAbility.entries()].sort((a, b) => b[1] - a[1]);
    const tt = detailCard({
      name: unitName(ctx, r.unitId),
      tag: ctx.bossUnits.has(r.unitId) ? t("badge_boss") : "",
      stats: [
        [t("tt_total"), fmtExact(r.total)],
        [t("tt_dps"), fmtNumber(r.total / (ctx.durationMs / 1000 || 1))],
        ...abilities.map(([id, amount]) => [abilityName(ctx, id), fmtNumber(amount)] as DetailStat),
      ],
    });
    return detailRow(`
      <span class="cell-name">${escapeHtml(unitName(ctx, r.unitId))}${ctx.bossUnits.has(r.unitId) ? `<span class="badge-boss">${escapeHtml(t("badge_boss"))}</span>` : ""}</span>
      <span class="num m-hide">${fmtNumber(r.total)}</span>
      <span class="big">${fmtPercent(share)}</span>
      <span class="num m-hide">${fmtDps(r.total, ctx.durationMs)}</span>
      <span class="dt-meta">${fmtNumber(r.total)} · ${fmtDps(r.total, ctx.durationMs)}/s</span>
      <span class="dt-bar" style="width:${(r.total / top * 100).toFixed(1)}%"></span>
    `, tt + filterAction(link, unitName(ctx, r.unitId)), UNIT_GRID, "unit-row");
  }).join("");
  return contentSection(label, `<div class="dt">${head}${body}</div>`);
}

function unitCsvRows(ctx: RenderCtx, rows: UnitRollup[], total: number, scope: string): (string | number)[][] {
  if (rows.length <= 1) return [];
  return ([[scope, "Total", "Share", "DPS"]] as (string | number)[][]).concat(rows.map((r) => [
    unitName(ctx, r.unitId), r.total, total ? (r.total / total).toFixed(4) : 0,
    (r.total / (ctx.durationMs / 1000 || 1)).toFixed(1),
  ]));
}

/** Appends a secondary block to a tab's CSV, blank-line separated. */
function appendCsv(csv: (string | number)[][], rows: (string | number)[][]): void {
  if (rows.length === 0) return;
  csv.push([]);
  csv.push(...rows);
}

// Damage composition from the share-scoped facts (dot/direct, damage type)
// and the DB's AoE table. Mirrors arithmancer.lua ComputeByDotOrDirect: an
// exclusive chain (shielded -> heal absorption -> over time -> direct ->
// unclassified), so an id carrying both delivery flags counts wholly as DoT,
// and each share is over the classified sum with unclassified left out.
// Damage type is the exception - ComputeByDamageType adds an ability's full
// total under every type it was seen dealing, and the denominator is the sum
// of the buckets, so multi-type abilities are counted once per bucket.
// Shielded/absorbed damage sits outside every bucket in game: it has no
// delivery, no type, and is not single-target by default.
function compositionRail(ctx: RenderCtx, rows: AbilityRow[], total: number): string {
  if (total <= 0) return "";
  let direct = 0, dot = 0, absorb = 0, classified = 0, aoe = 0, singleTarget = 0, typedTotal = 0;
  const byType = new Map<number, number>();
  let shielded = 0;
  // Classify each component's amount, never the whole name-group using its
  // largest id. Filters have already been applied to these component totals.
  for (const r of rows.flatMap((row) => row.variants)) {
    if (isSupplemental(r.abilityId)) {
      shielded += r.total;
      continue;
    }
    const mech = ctx.names[r.abilityId]?.mech;
    if (mech?.healAbsorption) absorb += r.total;
    else if (mech?.overTime) dot += r.total;
    else if (mech?.direct) direct += r.total;
    if (mech?.healAbsorption || mech?.overTime || mech?.direct) classified += r.total;
    if (mech?.aoe === 1) aoe += r.total;
    else singleTarget += r.total;
    for (const dtype of mech?.damageTypes || []) {
      byType.set(dtype, (byType.get(dtype) || 0) + r.total);
      typedTotal += r.total;
    }
  }
  if (classified <= 0 && byType.size === 0) return "";
  // Three groups, the same split the journal's damage list uses
  let groups = "";
  if (classified > 0) {
    const unclassified = total - shielded - classified;
    groups += kvGroup(t("h_damage_delivery"), [
      kv(t("tag_direct"), fmtPercent(direct / classified)),
      kv(t("tag_dot"), fmtPercent(dot / classified)),
      absorb > 0 ? kv(t("comp_absorbed"), fmtPercent(absorb / classified)) : "",
      unclassified / total > 0.005 ? kv(t("comp_unknown"), fmtPercent(unclassified / total)) : "",
    ]);
  }
  const aoeTotal = aoe + singleTarget;
  if (aoeTotal > 0) {
    groups += kvGroup(t("h_aoe_vs_st"), [
      kv(t("tag_aoe"), fmtPercent(aoe / aoeTotal)),
      kv(t("comp_st"), fmtPercent(singleTarget / aoeTotal)),
    ]);
  }
  const types = [...byType.entries()].sort((a, b) => b[1] - a[1]);
  groups += kvGroup(t("h_by_damage_type"),
    types.map(([dtype, amount]) => kv(tm("dmgtype", dtype, `#${dtype}`), fmtPercent(amount / typedTotal)))
      .concat(shielded > 0 ? [kv(t("syn_shielded"), fmtNumber(shielded))] : []));
  return contentSection(t("h_composition"), groups);
}

function damageTab(
  ctx: RenderCtx, scopeFilter: Set<number> | null, title: string, subId: string,
): TabResult {
  // The tab's own scope (bosses, on the boss tab) narrowed further by the
  // user's target filter, exactly as the journal composes them: its boss tab
  // offers only boss targets to begin with.
  const targetFilter = intersectFilters(scopeFilter, unitFilterFor(ctx, subId));
  const sourceFilter = unitFilterFor(ctx, subId, "source");
  const rows = M.abilityRows(ctx.decoded.damageByUnitId, targetFilter, abilityNaming(ctx), sourceFilter);
  const total = rows.reduce((s, r) => s + r.total, 0);
  // The group denominator takes the target filter but never the source one:
  // the share is the player's slice of what the whole group did to those
  // targets (arithmancer.lua groupTotalDamage).
  const model = groupModel(ctx, targetFilter);
  const targets = unitRollups(ctx.decoded.damageByUnitId, "target", targetFilter, sourceFilter);
  const bar = filterBar(ctx, subId);
  const html = rows.length === 0
    ? bar + `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_damage"))}</p></div>`
    : bar + damageSummary(ctx, model, rows, total) + `
      <div class="body-grid">
        <div>${damageTable(ctx, rows, total)}${unitDamageSection(ctx, targets, total, t("h_by_target"), { subId, axis: "main" })}</div>
        <div>${compositionRail(ctx, rows, total)}${groupRail(ctx, model)}${bossRail(ctx)}</div>
      </div>`;
  const csv = damageCsv(ctx, rows, total);
  appendCsv(csv, unitCsvRows(ctx, targets, total, "Target"));
  return { html, csv, title };
}

/** Both filters applied: null means "no restriction" on either side. */
function intersectFilters(a: Set<number> | null, b: Set<number> | null): Set<number> | null {
  if (!a) return b;
  if (!b) return a;
  const out = new Set<number>();
  for (const id of a) if (b.has(id)) out.add(id);
  return out;
}

/**
 * Ability naming with no source suffix: the group damage tab pools every
 * source - the player, their pets and companions, the rest of the group - into
 * one row per ability, since the game names none of the others anyway.
 */
function bareNaming(ctx: RenderCtx): M.AbilityNaming {
  return { ...abilityNaming(ctx), unitName: () => undefined, playerUnitId: undefined };
}

/** bossRail's markup over the group's damage to each boss, not the player's. */
function groupBossRail(ctx: RenderCtx): string {
  const keys = Object.keys(ctx.wireEnc.bossSeqNames || {});
  if (keys.length === 0) return "";
  const totals = M.groupDamageByBoss(ctx.decoded, ctx.wireEnc.bossTagSeqByUnitId || {});
  const rows = keys.map((key) => {
    const name = cleanName(ctx.wireEnc.bossSeqNames[key] || key);
    const dps = fmtDps(totals[key] || 0, ctx.durationMs);
    return `<div class="kv"><span class="kv-k" style="font-size:15px;color:var(--ink)">${escapeHtml(name)}</span><span class="kv-v" style="color:var(--gold);font-size:17px">${dps} DPS</span></div>`;
  }).join("");
  return sectHead(t("h_group_by_boss")) + rows;
}

/**
 * Group Damage (renderers/damage.lua renderGroupDamage): everything the
 * client saw land on enemies - the personal map (the player, their pets and
 * companions) and the observed group map, which the game keys to source 0 and
 * so can only ever be one "Others" pool. Rows carry bare ability names for
 * both sides; the Self/Others checkboxes and the target filter (bosses by
 * default) scope every number on the tab.
 */
function groupDamageTab(ctx: RenderCtx): TabResult {
  const subId = GROUP_DAMAGE_SUB;
  const d = ctx.decoded;
  const sides = damageSidesFor(ctx, subId);
  const maps: DamageMap[] = [];
  if (sides.self && d.damageByUnitId) maps.push(d.damageByUnitId);
  if (sides.others && d.damageByUnitIdGroup) maps.push(d.damageByUnitIdGroup);
  const targetFilter = unitFilterFor(ctx, subId);
  const rows = M.abilityRows(maps, targetFilter, bareNaming(ctx));
  const total = rows.reduce((s, r) => s + r.total, 0);
  const targets = unitRollups(maps, "target", targetFilter);
  const bar = filterBar(ctx, subId);
  const title = "Group Damage";
  if (rows.length === 0) {
    return { html: bar + `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_damage"))}</p></div>`, csv: [["No damage recorded"]], title };
  }

  const durS = ctx.durationMs / 1000 || 1;
  // Crit rate and max hit over real abilities only, as damageSummary measures them
  const quality = realRows(rows);
  const ticks = quality.reduce((s, r) => s + r.ticks, 0);
  const crits = quality.reduce((s, r) => s + r.critTicks, 0);
  const critFrac = ticks > 0 ? crits / ticks : 0;
  let maxRow: AbilityRow | null = null;
  for (const r of quality) if (!maxRow || r.maxTick > maxRow.maxTick) maxRow = r;

  const blocks = [
    keyMetric(t("st_group_dps"), fmtExact(total / durS),
      t("sub_damage_hits", fmtExact(total), fmtExact(ticks), fmtDuration(ctx.durationMs))),
  ];
  if (sides.self && sides.others && total > 0) {
    // The player's slice of the same scope, over the same targets
    const personal = M.nestedTotal(d.damageByUnitId, targetFilter);
    const share = personal / total;
    blocks.push(metric(t("st_group_share"), fmtPercent(share), meterHtml(share),
      t("sub_damage_over", fmtExact(personal), fmtDuration(ctx.durationMs))));
  }
  blocks.push(metric(t("st_crit"), fmtPercent(critFrac), meterHtml(critFrac),
    t("sub_crit", fmtExact(crits), fmtExact(ticks))));
  if (maxRow) {
    blocks.push(metric(t("st_max_hit"), fmtNumber(maxRow.maxTick), "",
      escapeHtml(maxRow.label || abilityName(ctx, maxRow.abilityId))));
  }

  const html = bar + summarySection([metricGroup(t("summary_output"), blocks.slice(0, sides.self && sides.others && total > 0 ? 2 : 1)), metricGroup(t("summary_damage_quality"), blocks.slice(sides.self && sides.others && total > 0 ? 2 : 1))]) + `
    <div class="body-grid">
      <div>${damageTable(ctx, rows, total, "tt_share_group")}${unitDamageSection(ctx, targets, total, t("h_by_target"), { subId, axis: "main" })}</div>
      <div>${groupBossRail(ctx)}<div class="note">${escapeHtml(t("note_group_damage"))}</div></div>
    </div>`;
  const csv = damageCsv(ctx, rows, total);
  appendCsv(csv, unitCsvRows(ctx, targets, total, "Target"));
  return { html, csv, title };
}

const TAKEN_GRID = "grid-template-columns: 36px minmax(0,1fr) 70px 90px 110px 70px;";

function damageTakenTab(ctx: RenderCtx, subId: string): TabResult {
  const sourceFilter = unitFilterFor(ctx, subId);
  const bar = filterBar(ctx, subId);
  const rows = M.damageTakenRows(ctx.decoded.damageTakenByUnitId, sourceFilter);
  const total = rows.reduce((s, r) => s + r.total, 0);
  if (rows.length === 0) {
    return { html: bar + `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_taken"))}</p></div>`, csv: [["No damage taken"]], title: "Damage Taken" };
  }
  const hits = rows.reduce((s, r) => s + r.ticks, 0);
  let maxRow: DamageTakenRow = rows[0]!;
  for (const r of rows) if (r.maxTick > maxRow.maxTick) maxRow = r;

  const summaryHtml = summarySection([metricGroup(t("summary_incoming"), [
    keyMetric(t("st_damage_taken"), fmtNumber(total),
      t("sub_taken_hits", fmtExact(total), fmtDuration(ctx.durationMs), fmtExact(hits))),
    metric(t("st_max_hit"), fmtNumber(maxRow.maxTick), "", escapeHtml(abilityName(ctx, maxRow.abilityId))),
    metric(t("st_per_second"), fmtDps(total, ctx.durationMs), "", t("sub_avg_incoming")),
  ])]);

  const topShare = rows[0] ? rows[0].total / total : 1;
  const head = dtHead([
    {}, { label: t("th_ability") }, { label: t("th_hits"), r: true }, { label: t("th_max_hit"), r: true },
    { label: t("th_total"), r: true }, { label: t("th_share"), r: true },
  ], TAKEN_GRID);
  const body = rows.map((r) => {
    const share = total > 0 ? r.total / total : 0;
    const attackers = [...r.attackers].slice(0, 3).map((id) => unitName(ctx, id)).join(", ");
    const tt = abilityDetails(ctx, r.abilityId, [
      [t("tt_total"), fmtExact(r.total)],
      [t("tt_hits"), fmtExact(r.ticks)],
      [t("tt_crit"), fmtPercent(M.critPercent(r))],
      [t("tt_avg_hit"), fmtNumber(M.averageTick(r))],
      [t("tt_minmax"), `${fmtNumber(r.minTick)} – ${fmtNumber(r.maxTick)}`],
      [t("tt_from"), attackers],
    ], t("tt_share_taken", fmtPercent(share)));
    return detailRow(`
      ${iconHtml(ctx, r.abilityId)}
      <span class="cell-name">${escapeHtml(abilityName(ctx, r.abilityId))}<span class="tag m-hide">${escapeHtml(attackers)}</span></span>
      <span class="num m-hide">${fmtExact(r.ticks)}</span>
      <span class="num m-hide">${fmtNumber(r.maxTick)}</span>
      <span class="num m-hide">${fmtNumber(r.total)}</span>
      <span class="big">${fmtPercent(share)}</span>
      <span class="dt-meta">${fmtNumber(r.total)} · ${escapeHtml(t("th_hits"))} ${r.ticks} · ${escapeHtml(t("th_max_hit"))} ${fmtNumber(r.maxTick)}</span>
      <span class="dt-bar" style="width:${(topShare > 0 ? share / topShare * 100 : 0).toFixed(1)}%"></span>
    `, tt, TAKEN_GRID);
  }).join("");

  const csv: (string | number)[][] = ([["Ability", "Total", "Share", "Hits", "Max hit", "Attackers"]] as (string | number)[][])
    .concat(rows.map((r) => [
      abilityName(ctx, r.abilityId), r.total, total ? (r.total / total).toFixed(4) : 0,
      r.ticks, r.maxTick, [...r.attackers].map((id) => unitName(ctx, id)).join("; "),
    ]));
  const sources = unitRollups(ctx.decoded.damageTakenByUnitId, "source", null, sourceFilter);
  appendCsv(csv, unitCsvRows(ctx, sources, total, "Source"));
  return {
    html: bar + summaryHtml + `<div class="body-grid wide"><div><div class="dt">${head}${body}</div>${unitDamageSection(ctx, sources, total, t("h_by_source"), { subId, axis: "main" })}</div></div>`,
    csv,
    title: "Damage Taken",
  };
}

// ============================================================================
// HEALING
// ============================================================================

const HEAL_GRID = "grid-template-columns: 36px minmax(150px,1fr) 90px 80px 100px 80px 60px 80px;";
const HEAL_UNIT_GRID = "grid-template-columns: minmax(110px,1fr) 80px 100px 80px 80px;";
const SELF_UNIT_ID = -1;

interface HealingUnitSummary extends HealingTotals {
  key: string;
  name: string;
}

interface HealingSection extends HealingUnitSummary {
  byAbility: Record<number, HealingBreakdown>;
}

type HealingSubId = "healing-out" | "self-healing" | "healing-in";

/** Self keeps its own filter identity even when a group unit has the same name. */
function selfLabel(ctx: RenderCtx): string {
  const me = (ctx.wireEnc.shared || []).find((s) => s.isSelf === true);
  return me ? `${me.displayName} ${t("self_suffix")}` : `${t("you")} ${t("self_suffix")}`;
}

function healingTotals(values: Iterable<HealingTotals>): HealingTotals {
  const total = { raw: 0, real: 0, overheal: 0 };
  for (const v of values) {
    total.raw += v.raw;
    total.real += v.real;
    total.overheal += v.overheal;
  }
  return total;
}

/** One filtered model supplies the headline, abilities, units, delivery and CSV. */
function healingSections(ctx: RenderCtx, subId: HealingSubId): HealingSection[] {
  const stats = ctx.decoded.healingStats;
  const filter = unitFilterFor(ctx, subId);
  const sections = new Map<string, HealingSection>();
  const add = (id: number, healing: HealingDone | HealingDoneDiffSource): void => {
    if (filter && !filter.has(id)) return;
    const byAbility = "bySourceUnitIdByAbilityId" in healing
      ? M.mergeSources(healing.bySourceUnitIdByAbilityId) : healing.byAbilityId;
    const total = healing.total ?? healingTotals(Object.values(byAbility));
    if (total.raw <= 0 && total.real <= 0 && Object.keys(byAbility).length === 0) return;
    const key = id === SELF_UNIT_ID ? SELF_KEY : unitName(ctx, id);
    const name = id === SELF_UNIT_ID ? selfLabel(ctx) : unitName(ctx, id);
    const existing = sections.get(key);
    sections.set(key, existing ? {
      key, name, ...healingTotals([existing, total]),
      byAbility: M.mergeSources({ 0: existing.byAbility, 1: byAbility }),
    } : { key, name, ...total, byAbility });
  };
  if (stats?.selfHealing) add(SELF_UNIT_ID, stats.selfHealing);
  if (subId !== "self-healing") {
    const map = subId === "healing-out" ? stats?.healingOutToGroup : stats?.healingInFromGroup;
    for (const [id, healing] of Object.entries(map || {})) add(Number(id), healing);
  }
  return [...sections.values()];
}

function healingShareLabel(basis: HealingBasis): string {
  return t(basis === "raw" ? "heal_raw_share" : "heal_effective_share");
}

function healingStats(ctx: RenderCtx, row: HealingBreakdown): DetailStat[] {
  return [
    [t("heal_raw_total"), fmtExact(row.raw)],
    [t("heal_raw_hps"), fmtDps(row.raw, ctx.durationMs)],
    [t("heal_effective_total"), fmtExact(row.real)],
    [t("heal_effective_hps"), fmtDps(row.real, ctx.durationMs)],
    [t("tt_overheal"), `${fmtExact(row.overheal)} (${fmtPercent(row.raw > 0 ? row.overheal / row.raw : 0)})`],
    [t("tt_ticks"), fmtExact(row.ticks)],
    [t("heal_crit_ticks"), fmtExact(row.critTicks)],
    [t("tt_crit"), fmtPercent(M.critPercent(row))],
    [t("heal_avg_raw"), fmtNumber(row.ticks > 0 ? row.raw / row.ticks : 0)],
    [t("heal_minmax_raw"), `${fmtNumber(row.minTick)} – ${fmtNumber(row.maxTick)}`],
  ];
}

/** Full tick statistics follow the same disclosure pattern on every device. */
function healingStatDetails(ctx: RenderCtx, row: HealingBreakdown, full = true): string {
  const shown = [t("heal_raw_hps"), t("heal_effective_hps"), t("tt_crit")];
  return detailStats(healingStats(ctx, row).filter(([label]) => full || !shown.includes(label)));
}

function healingUnitTable(
  ctx: RenderCtx, units: HealingUnitSummary[], basis: HealingBasis, link?: FilterLink,
): string {
  if (units.length === 0) return "";
  const ordered = [...units].sort((a, b) => b[basis] - a[basis] || b.raw - a.raw);
  const grand = units.reduce((s, u) => s + u[basis], 0);
  const top = ordered[0]?.[basis] || 0;
  const head = dtHead([
    {}, { label: t("heal_raw_hps"), r: true }, { label: t("heal_effective_hps"), r: true },
    { label: t("th_overheal"), r: true }, { label: healingShareLabel(basis), r: true },
  ], HEAL_UNIT_GRID);
  const body = ordered.map((u) => {
    const over = u.raw > 0 ? u.overheal / u.raw : 0;
    const share = grand > 0 ? u[basis] / grand : 0;
    const tt = detailStats([
      [t("heal_raw_total"), fmtExact(u.raw)], [t("heal_effective_total"), fmtExact(u.real)],
      [t("tt_overheal"), fmtExact(u.overheal)],
    ]);
    return detailRow(`
      <span class="cell-name">${escapeHtml(u.name)}</span>
      <span class="num m-hide${basis === "raw" ? " heal-ranked" : ""}">${fmtDps(u.raw, ctx.durationMs)}</span>
      <span class="num m-hide${basis === "real" ? " heal-ranked" : ""}">${fmtDps(u.real, ctx.durationMs)}</span>
      <span class="num m-hide">${fmtPercent(over)}</span>
      <span class="big">${fmtPercent(share)}</span>
      <span class="dt-meta">${escapeHtml(t("heal_raw_hps"))} ${fmtDps(u.raw, ctx.durationMs)} · ${escapeHtml(t("heal_effective_hps"))} ${fmtDps(u.real, ctx.durationMs)}<br>${escapeHtml(t("heal_raw_total"))} ${fmtNumber(u.raw)} · ${escapeHtml(t("th_overheal"))} ${fmtPercent(over)}</span>
      <span class="dt-bar" style="width:${(top > 0 ? u[basis] / top * 100 : 0).toFixed(1)}%"></span>
    `, tt + filterAction(link, u.key), HEAL_UNIT_GRID, "unit-row");
  }).join("");
  return `<div class="dt-scroll"><div class="dt heal-units">${head}${body}</div></div>`;
}

function healingAbilityDetails(
  ctx: RenderCtx, row: HealingRow, sections: HealingSection[], basis: HealingBasis, subId: HealingSubId,
): string {
  const ids = new Set(row.variants.map((v) => v.abilityId));
  const units = sections.map((s) => ({
    key: s.key, name: s.name,
    ...healingTotals(Object.entries(s.byAbility).filter(([id]) => ids.has(Number(id))).map(([, b]) => b)),
  })).filter((s) => s.raw > 0 || s.real > 0);
  const labels = componentLabels(ctx, row.variants.map((v) => v.abilityId), true);
  const components = row.variants.length > 1 ? sectHead(t("heal_components"))
    + row.variants.map((v, i) => disclosure(
      `${escapeHtml(labels[i]!)} <span class="component-value">${fmtNumber(v[basis])} · ${fmtPercent(row[basis] > 0 ? v[basis] / row[basis] : 0)}</span>`,
      healingStatDetails(ctx, v), "component-detail")).join("") : "";
  const unitLabel = t(subId === "healing-in" ? "h_by_source" : "h_by_target");
  return `<div class="detail-body">${healingStatDetails(ctx, row, false)}${components}
    ${subId !== "self-healing" ? sectHead(unitLabel) + healingUnitTable(ctx, units, basis, { subId, axis: "main" }) : ""}
  </div>`;
}

function healingTable(
  ctx: RenderCtx, rows: HealingRow[], sections: HealingSection[], basis: HealingBasis, subId: HealingSubId,
): string {
  const eligible = realRows(rows);
  const total = eligible.reduce((s, r) => s + r[basis], 0);
  const top = eligible.reduce((max, r) => Math.max(max, r[basis]), 0);
  const head = dtHead([
    {}, { label: t("th_ability") }, { label: t("heal_raw_total"), r: true },
    { label: t("heal_raw_hps"), r: true }, { label: t("heal_effective_hps"), r: true },
    { label: t("th_overheal"), r: true }, { label: t("th_crit"), r: true },
    { label: healingShareLabel(basis), r: true },
  ], HEAL_GRID);
  const body = supplementalLast(rows).map((r) => {
    const supp = isSupplemental(r.abilityId);
    const share = !supp && total > 0 ? r[basis] / total : 0;
    const over = r.raw > 0 ? r.overheal / r.raw : 0;
    const reference = abilityDetails(ctx, r.abilityId, [], undefined, {
        name: r.label, abilityIds: r.variants.map((v) => v.abilityId), healing: true,
      });
    return `<details class="disclosure row-detail heal-ability">
      <summary class="dt-row" style="${HEAL_GRID}">
        ${iconHtml(ctx, r.abilityId)}
        <span class="cell-name heal-name">${escapeHtml(r.label)}</span>
        <span class="num m-hide">${fmtNumber(r.raw)}</span>
        <span class="num m-hide${basis === "raw" ? " heal-ranked" : ""}">${fmtDps(r.raw, ctx.durationMs)}</span>
        <span class="num m-hide${basis === "real" ? " heal-ranked" : ""}">${fmtDps(r.real, ctx.durationMs)}</span>
        <span class="num m-hide">${fmtPercent(over)}</span>
        <span class="num m-hide">${fmtPercent(M.critPercent(r))}</span>
        <span class="big">${supp ? "—" : fmtPercent(share)}</span>
        <span class="dt-meta">${escapeHtml(t("heal_raw_hps"))} ${fmtDps(r.raw, ctx.durationMs)} · ${escapeHtml(t("heal_effective_hps"))} ${fmtDps(r.real, ctx.durationMs)}<br>${escapeHtml(t("heal_raw_total"))} ${fmtNumber(r.raw)} · ${escapeHtml(t("th_overheal"))} ${fmtPercent(over)} · ${escapeHtml(t("th_crit"))} ${fmtPercent(M.critPercent(r))}</span>
        <span class="dt-bar" style="width:${(!supp && top > 0 ? r[basis] / top * 100 : 0).toFixed(1)}%"></span>
      </summary>${healingAbilityDetails(ctx, r, sections, basis, subId)}<div class="detail-body">${reference}</div>
    </details>`;
  }).join("");
  return `<div class="dt-scroll"><div class="dt heal-table">${head}${body}</div></div>`;
}

interface HealingDeliveryRow extends HealingTotals {
  delivery: HealingDelivery;
}

const HEAL_DELIVERY_LABELS: Record<HealingDelivery, StringKey> = {
  direct: "tag_direct", hot: "tag_hot", shield: "tag_shield", regen: "tag_regen", absorbed: "syn_absorbed",
};

function healingDeliveryRows(ctx: RenderCtx, rows: HealingRow[], basis: HealingBasis): HealingDeliveryRow[] {
  const groups = new Map<HealingDelivery, HealingDeliveryRow>();
  for (const row of rows) {
    for (const v of row.variants) {
      const delivery = M.healingDelivery(v.abilityId, ctx.names[v.abilityId]?.mech);
      const previous = groups.get(delivery);
      groups.set(delivery, { delivery, ...healingTotals(previous ? [previous, v] : [v]) });
    }
  }
  return [...groups.values()].sort((a, b) =>
    Number(a.delivery === "absorbed") - Number(b.delivery === "absorbed") || b[basis] - a[basis]);
}

function healingComposition(rows: HealingDeliveryRow[], basis: HealingBasis): string {
  const total = rows.filter((r) => r.delivery !== "absorbed").reduce((s, r) => s + r[basis], 0);
  return sectHead(`${t("heal_delivery")} · ${t(basis === "raw" ? "tt_raw" : "tt_effective")}`)
    + rows.map((r) => {
      const label = t(HEAL_DELIVERY_LABELS[r.delivery]);
      const percent = r.delivery === "absorbed" ? "—" : fmtPercent(total > 0 ? r[basis] / total : 0);
      return kv(label, `${fmtNumber(r[basis])} · ${percent}`);
    }).join("");
}

const HEALING_CSV_HEAD = ["Scope", "Ability", "Raw", "Effective", "Overheal", "Raw HPS", "Effective HPS",
  "Overheal %", "Ticks", "Crit ticks", "Crit %", "Raw average", "Raw min", "Raw max", "Share basis", "Share %"];

function healingCsvRows(ctx: RenderCtx, scope: string, rows: HealingRow[], basis: HealingBasis): (string | number)[][] {
  const total = realRows(rows).reduce((s, r) => s + r[basis], 0);
  const durS = ctx.durationMs / 1000;
  return supplementalLast(rows).map((r) => [
    scope, r.label, r.raw, r.real, r.overheal,
    durS > 0 ? r.raw / durS : 0, durS > 0 ? r.real / durS : 0,
    r.raw > 0 ? r.overheal / r.raw * 100 : 0, r.ticks, r.critTicks, M.critPercent(r) * 100,
    r.ticks > 0 ? r.raw / r.ticks : 0, r.minTick, r.maxTick, basis === "raw" ? "Raw" : "Effective",
    isSupplemental(r.abilityId) ? "" : total > 0 ? r[basis] / total * 100 : 0,
  ]);
}

function healingTab(ctx: RenderCtx, subId: HealingSubId, emptyMsg: string, title: string): TabResult {
  const basis = healingBases.get(subId) || "raw";
  const sections = healingSections(ctx, subId);
  const bar = filterBar(ctx, subId);
  if (sections.length === 0) {
    return { html: bar + `<div class="body-grid wide"><p class="empty">${escapeHtml(emptyMsg)}</p></div>`, csv: [[emptyMsg]], title };
  }
  const totals = healingTotals(sections);
  const merged = M.mergeSources(Object.fromEntries(sections.map((s, i) => [i, s.byAbility])));
  const rows = M.healingRows(merged, (id) => abilityName(ctx, id), basis);
  const quality = realRows(rows);
  const ticks = quality.reduce((s, r) => s + r.ticks, 0);
  const crits = quality.reduce((s, r) => s + r.critTicks, 0);
  const max = quality.reduce((v, r) => Math.max(v, r.maxTick), 0);
  const over = totals.raw > 0 ? totals.overheal / totals.raw : 0;
  const summary = summarySection([
    metricGroup(t("summary_output"), [
      (basis === "raw" ? keyMetric : metric)(t("heal_raw_hps"), fmtDps(totals.raw, ctx.durationMs)),
      (basis === "real" ? keyMetric : metric)(t("heal_effective_hps"), fmtDps(totals.real, ctx.durationMs)),
      metric(t("st_overheal"), fmtPercent(over)),
    ]),
    metricGroup(t("h_totals"), [
      metric(t("heal_raw_total"), fmtExact(totals.raw)),
      metric(t("heal_effective_total"), fmtExact(totals.real)),
      metric(t("tt_overheal"), fmtExact(totals.overheal)),
    ]),
    metricGroup(t("summary_healing_quality"), [
      metric(t("st_crit"), fmtPercent(ticks > 0 ? crits / ticks : 0)),
      metric(t("heal_max_raw"), fmtNumber(max)),
      metric(t("tt_ticks"), fmtExact(ticks)),
    ]),
  ]);
  const toggle = `<div class="heal-toolbar">${sectHead(t("all_abilities"))}<div class="heal-basis" role="group" aria-label="${escapeHtml(t("heal_rank_by"))}">
    ${(["raw", "real"] as HealingBasis[]).map((value) => `<button type="button" data-heal-basis="${value}" data-heal-tab="${subId}" aria-pressed="${basis === value}">${escapeHtml(t(value === "raw" ? "tt_raw" : "tt_effective"))}</button>`).join("")}
  </div></div>`;
  const delivery = healingDeliveryRows(ctx, rows, basis);
  const unitLabel = t(subId === "healing-in" ? "h_by_source" : "h_by_target");
  const unitsHtml = subId === "self-healing" ? "" : `<section>${sectHead(unitLabel)}${healingUnitTable(ctx, sections, basis, { subId, axis: "main" })}</section>`;
  const csv: (string | number)[][] = [HEALING_CSV_HEAD, ...healingCsvRows(ctx, "All", rows, basis)];
  for (const section of sections) {
    const unitRows = M.healingRows(section.byAbility, (id) => abilityName(ctx, id), basis);
    csv.push(...healingCsvRows(ctx, section.name, unitRows, basis));
  }
  appendCsv(csv, [["Component ID", ...HEALING_CSV_HEAD], ...rows.flatMap((r) => {
    const variants = supplementalLast(r.variants.map((v) => ({ ...v, label: r.label, variants: [v] })));
    return healingCsvRows(ctx, `Components: ${r.label}`, variants, basis)
      .map((values, i) => [variants[i]!.abilityId, ...values]);
  })]);
  const shareTotal = totals[basis];
  appendCsv(csv, [["Unit", "Raw", "Effective", "Overheal", "Raw HPS", "Effective HPS", "Share basis", "Share %"],
    ...[...sections].sort((a, b) => b[basis] - a[basis] || b.raw - a.raw).map((s) => [
      s.name, s.raw, s.real, s.overheal,
      ctx.durationMs > 0 ? s.raw / (ctx.durationMs / 1000) : 0,
      ctx.durationMs > 0 ? s.real / (ctx.durationMs / 1000) : 0,
      basis === "raw" ? "Raw" : "Effective", shareTotal > 0 ? s[basis] / shareTotal * 100 : 0,
    ])]);
  appendCsv(csv, [["Delivery", "Raw", "Effective", "Overheal", "Share basis", "Share %"],
    ...delivery.map((r) => {
      const total = delivery.filter((d) => d.delivery !== "absorbed").reduce((s, d) => s + d[basis], 0);
      return [r.delivery, r.raw, r.real, r.overheal, basis === "raw" ? "Raw" : "Effective",
        r.delivery === "absorbed" ? "" : total > 0 ? r[basis] / total * 100 : 0];
    })]);
  appendCsv(csv, [["Summary", "Raw", "Effective", "Overheal", "Raw HPS", "Effective HPS", "Overheal %", "Ticks", "Crit ticks", "Crit %", "Max raw heal"],
    [title, totals.raw, totals.real, totals.overheal,
      ctx.durationMs > 0 ? totals.raw / (ctx.durationMs / 1000) : 0,
      ctx.durationMs > 0 ? totals.real / (ctx.durationMs / 1000) : 0,
      over * 100, ticks, crits, ticks > 0 ? crits / ticks * 100 : 0, max]]);
  return {
    html: bar + summary + `<div class="body-grid wide healing-body"><div>${toggle}
      ${healingTable(ctx, rows, sections, basis, subId)}
      <div class="heal-breakdowns">${unitsHtml}<section>${healingComposition(delivery, basis)}</section></div>
    </div></div>`, csv, title,
  };
}

// ============================================================================
// EFFECTS
// ============================================================================

const FX_GRID = "grid-template-columns: 36px minmax(0,1fr) 90px 80px 110px 26px;";

/**
 * One effect row. Mirrors metrics.effectRows but keeps the player-side
 * application count (the tables surface "from you" for both time and casts)
 * and, for the aggregated group table, the per-member uptimes behind the mean.
 */
interface FxRow {
  abilityId: number;
  effectType: number;
  uptime: number;
  playerUptime: number;
  timeAtMax: number;
  applications: number;
  playerApplications: number;
  maxStacks: number;
  peak: number;
  /** [display name, uptime] per member, only on aggregated group rows */
  members?: Array<[string, number]>;
}

/**
 * Uptimes are fractions of `aliveMs` — the unit's alive time, not fight
 * length. When an effect ran as several concurrent instances the active time
 * is the sum over all of them, so the denominator scales with the peak count
 * and the result is an average per instance — otherwise two stacked instances
 * of one DoT read as a flat 100% (renderers/effects.lua formatEffectValueBrief).
 * Player uptime is a single timeline, so it keeps the plain denominator.
 */
function fxRows(effects: Record<number, EffectStats> | undefined, aliveMs: number): FxRow[] {
  const alive = aliveMs > 0 ? aliveMs : 1;
  const list: FxRow[] = Object.values(effects || {}).map((e) => {
    const peak = e.peakConcurrentInstances || 1;
    const denom = alive * peak;
    return {
      abilityId: e.abilityId,
      effectType: e.effectType,
      uptime: Math.min(1, (e.totalActiveTimeMs || 0) / denom),
      playerUptime: Math.min(1, (e.playerActiveTimeMs || 0) / alive),
      timeAtMax: Math.min(1, (e.timeAtMaxStacksMs || 0) / denom),
      applications: e.applications || 0,
      playerApplications: e.playerApplications || 0,
      maxStacks: e.maxStacks || 0,
      peak,
    };
  });
  list.sort((a, b) => b.uptime - a.uptime);
  return list;
}

/**
 * Group effects collapsed to one row per (ability, effect type): the value is
 * the mean uptime over the members that tracked it, each measured against its
 * own alive time. Applications stay a sum — that column is a count of casts,
 * not a time share (tooltips.lua reports total applications + members).
 *
 * The uploader is not in `effectsOnGroup` — combat/effects.lua keeps the
 * player out of it deliberately — so their own buffs are folded in as one
 * more member, exactly as aggregateGroupBuffs does. Debuffs on the player are
 * not group coverage, so only buffs join.
 */
function fxGroupRows(ctx: RenderCtx, memberFilter?: Set<string> | null): FxRow[] {
  const acc = new Map<string, { row: FxRow; uptime: number; playerUptime: number; timeAtMax: number; apps: number; playerApps: number; n: number }>();
  const members: Array<[string, Record<number, EffectStats> | undefined, number]> =
    Object.entries(ctx.decoded.effectsOnGroup || {})
      .filter(([name]) => !memberFilter || memberFilter.has(name))
      .map(([name, byAbility]) => [name, byAbility, ctx.decoded.unitAliveTimeMs?.[name] ?? ctx.durationMs]);
  const selfBuffs = (!memberFilter || memberFilter.has(SELF_KEY)) ? playerBuffs(ctx) : undefined;
  if (selfBuffs) {
    members.push([t("you"), selfBuffs, ctx.decoded.playerAliveTimeMs || ctx.durationMs]);
  }
  for (const [displayName, byAbility, aliveMs] of members) {
    for (const r of fxRows(byAbility, aliveMs)) {
      const key = `${r.abilityId}:${r.effectType}`;
      let entry = acc.get(key);
      if (!entry) {
        entry = {
          row: { ...r, members: [] },
          uptime: 0, playerUptime: 0, timeAtMax: 0, apps: 0, playerApps: 0, n: 0,
        };
        acc.set(key, entry);
      }
      entry.uptime += r.uptime;
      entry.playerUptime += r.playerUptime;
      entry.timeAtMax += r.timeAtMax;
      entry.apps += r.applications;
      entry.playerApps += r.playerApplications;
      entry.n += 1;
      entry.row.maxStacks = Math.max(entry.row.maxStacks, r.maxStacks);
      entry.row.peak = Math.max(entry.row.peak, r.peak);
      entry.row.members!.push([displayName, r.uptime]);
    }
  }
  const rows = [...acc.values()].map((e) => {
    const n = e.n || 1;
    e.row.uptime = e.uptime / n;
    e.row.playerUptime = e.playerUptime / n;
    e.row.timeAtMax = e.timeAtMax / n;
    e.row.applications = e.apps;
    e.row.playerApplications = e.playerApps;
    e.row.members!.sort((a, b) => b[1] - a[1]);
    return e.row;
  });
  rows.sort((a, b) => b.uptime - a.uptime);
  return rows;
}

/** The sub's live filter text, as app.ts recorded it from the input. */
function filterText(subId: string): string {
  return tabFilters.get(subId) || "";
}

function fxFilterInput(subId: string): string {
  return `<div class="fx-filter-controls"><input class="fx-filter" data-filter="${escapeHtml(subId)}" value="${escapeHtml(filterText(subId))}" placeholder="${escapeHtml(t("filter_fx"))}" aria-label="${escapeHtml(t("filter_fx"))}">${filterResetButton(subId, !!filterText(subId))}</div>`;
}

function fxFilterRows(ctx: RenderCtx, rows: FxRow[], subId: string): FxRow[] {
  const needle = filterText(subId).trim().toLowerCase();
  if (!needle) return rows;
  return rows.filter((r) => abilityName(ctx, r.abilityId).toLowerCase().includes(needle));
}

function effectTable(ctx: RenderCtx, rows: FxRow[]): string {
  const head = dtHead([
    {}, { label: t("th_effect") }, { label: t("th_uptime"), r: true }, { label: t("th_applied"), r: true },
    { label: t("th_at_max"), r: true }, {},
  ], FX_GRID);
  const body = rows.map((r) => {
    const stacksTag = r.maxStacks > 1 ? t("tag_stacks", r.maxStacks) : "";
    const peakTag = r.peak > 1 ? t("eff_peak", r.peak) : "";
    const fromYouTime = r.playerUptime > 0 && Math.abs(r.playerUptime - r.uptime) > 0.001;
    const fromYouApps = r.playerApplications > 0 && r.playerApplications !== r.applications;
    const members = r.members || [];
    const tt = abilityDetails(ctx, r.abilityId, [
      [t("tt_uptime"), fmtPercent(r.uptime)],
      [t("tt_applied"), `${r.applications}×`],
      ...(r.maxStacks > 1 ? [[t("tt_at_stacks", r.maxStacks), fmtPercent(r.timeAtMax)] as DetailStat] : []),
      ...(fromYouTime ? [[t("tt_from_you"), fmtPercent(r.playerUptime)] as DetailStat] : []),
      ...(fromYouApps ? [[`${t("tt_from_you")} · ${t("tt_applied")}`, `${r.playerApplications}×`] as DetailStat] : []),
      ...members.map(([name, uptime]) => [name, fmtPercent(uptime)] as DetailStat),
    ], members.length ? t("h_fx_group_avg", members.length) : undefined, { visibleStats: [t("tt_uptime"), t("tt_applied")] });
    const pinned = ctx.pins.has(r.abilityId);
    const tags = [stacksTag, peakTag].filter(Boolean).join(" · ");
    return detailRow(`
      ${iconHtml(ctx, r.abilityId)}
      <span class="cell-name">${escapeHtml(abilityName(ctx, r.abilityId))}${pinned ? `<span class="pin-mark" aria-label="${escapeHtml(t("h_pinned"))}">◆ ${escapeHtml(t("h_pinned"))}</span>` : ""}${tags ? `<span class="tag m-hide">${escapeHtml(tags)}</span>` : ""}</span>
      <span class="big">${fmtPercent(r.uptime)}</span>
      <span class="num m-hide">${r.applications}×</span>
      <span class="num m-hide">${r.maxStacks > 1 ? fmtPercent(r.timeAtMax) : "—"}</span>
      <span class="m-hide"></span>
      <span class="dt-meta">${t("applied_n", r.applications)}${tags ? ` · ${escapeHtml(tags)}` : ""}</span>
      <span class="dt-bar" style="width:${(r.uptime * 100).toFixed(1)}%"></span>
    `, `<button type="button" class="detail-action" data-pin="${r.abilityId}" aria-pressed="${pinned}">${escapeHtml(t(pinned ? "unpin_effect" : "pin_effect"))}</button>` + tt, FX_GRID);
  }).join("");
  return `<div class="dt">${head}${body}</div>`;
}

function effectsCsvRows(rows: FxRow[], scope: string, nameOf: (id: number) => string): (string | number)[][] {
  return rows.map((r) => [
    scope, nameOf(r.abilityId), r.uptime.toFixed(4), r.applications,
    r.maxStacks, r.timeAtMax.toFixed(4),
  ]);
}

const FX_CSV_HEAD = ["Unit", "Effect", "Uptime", "Applications", "Max stacks", "Time at max"];

interface EffectSection {
  label: string;
  scope: string;
  rows: FxRow[];
}

function effectsSectionsTab(
  ctx: RenderCtx, subId: string, sections: EffectSection[], emptyMsg: string, title: string,
): TabResult {
  const parts: string[] = [];
  const csv: (string | number)[][] = [FX_CSV_HEAD];
  let anyRows = false;
  for (const s of sections) {
    if (s.rows.length === 0) continue;
    anyRows = true;
    const shown = fxFilterRows(ctx, s.rows, subId).sort((a, b) => Number(ctx.pins.has(b.abilityId)) - Number(ctx.pins.has(a.abilityId)));
    parts.push(`<section>${sectHead(s.label)}${shown.length ? effectTable(ctx, shown) : `<p class="empty">${escapeHtml(t("empty_no_fx"))}</p>`}</section>`);
    csv.push(...effectsCsvRows(shown, s.scope, (id) => abilityName(ctx, id)));
  }
  if (!anyRows) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(emptyMsg)}</p></div>`, csv: [[emptyMsg]], title };
  }
  return {
    html: `<div class="body-grid wide"><div>${fxFilterInput(subId)}<div class="section-stack">${parts.join("")}</div>
      <div class="note">${escapeHtml(t("note_uptime"))} ${escapeHtml(t("note_pins"))}</div></div></div>`,
    csv,
    title,
  };
}

const BUFF_EFFECT_TYPE = 1;

/** The player's own buffs, for folding into the group coverage average. */
function playerBuffs(ctx: RenderCtx): Record<number, EffectStats> | undefined {
  const all = ctx.decoded.effectsOnPlayer;
  if (!all) return undefined;
  const buffs: Record<number, EffectStats> = {};
  let any = false;
  for (const [id, e] of Object.entries(all)) {
    if (e.effectType === BUFF_EFFECT_TYPE) {
      buffs[Number(id)] = e;
      any = true;
    }
  }
  return any ? buffs : undefined;
}

function effectsPlayerTab(ctx: RenderCtx, subId: string): TabResult {
  const aliveMs = ctx.decoded.playerAliveTimeMs || ctx.durationMs;
  const rows = fxRows(ctx.decoded.effectsOnPlayer, aliveMs);
  // Buffs and debuffs are two headed lists in the journal, not one run - a
  // handful of debuffs is otherwise lost among thirty buffs
  const buffs = rows.filter((r) => r.effectType === BUFF_EFFECT_TYPE);
  const debuffs = rows.filter((r) => r.effectType !== BUFF_EFFECT_TYPE);
  const sections: EffectSection[] = [];
  if (buffs.length) sections.push({ label: t("h_your_buffs", fmtDuration(aliveMs)), scope: "Player buffs", rows: buffs });
  if (debuffs.length) sections.push({ label: t("h_debuffs_on_you"), scope: "Player debuffs", rows: debuffs });
  return effectsSectionsTab(ctx, subId, sections, t("empty_no_fx"), "Effects On You");
}

function effectsBossTab(ctx: RenderCtx, subId: string): TabResult {
  const effects = ctx.decoded.effectsOnBosses || {};
  const sections = Object.entries(effects).map(([tag, byAbility]) => {
    const aliveMs = ctx.decoded.unitAliveTimeMs?.[tag] || ctx.durationMs;
    const name = cleanName(ctx.decoded.bossNames?.[tag] || tag);
    return {
      label: `${name} · ${t("alive_for", fmtDuration(aliveMs))}`,
      scope: name,
      rows: fxRows(byAbility, aliveMs),
    };
  });
  // Busiest boss first, as the journal orders them
  sections.sort((a, b) =>
    b.rows.reduce((s, r) => s + r.uptime, 0) - a.rows.reduce((s, r) => s + r.uptime, 0));
  return effectsSectionsTab(ctx, subId, sections, t("empty_no_boss_fx"), "Effects On Bosses");
}

// One aggregated table, not one per member: the interesting question across a
// group is "how well is this buff covered", which is the mean of the members
// that ran with it.
function effectsGroupTab(ctx: RenderCtx, subId: string): TabResult {
  const memberFilter = memberFilterFor(ctx, subId);
  const rows = fxGroupRows(ctx, memberFilter);
  // The header counts who the average actually covers: the filtered members
  // plus the uploader, whom fxGroupRows folds in from their own buff list
  const memberCount = Object.keys(ctx.decoded.effectsOnGroup || {})
    .filter((name) => !memberFilter || memberFilter.has(name)).length
    + ((!memberFilter || memberFilter.has(SELF_KEY)) && playerBuffs(ctx) ? 1 : 0);
  const result = effectsSectionsTab(ctx, subId,
    [{ label: t("h_fx_group_avg", memberCount), scope: "Group", rows }],
    t("empty_no_group_fx"), "Effects On Group");
  return { ...result, html: filterBar(ctx, subId) + result.html };
}

// ============================================================================
// ACTIVITY (procs + weaving)
// ============================================================================

const PROC_GRID = "grid-template-columns: 36px minmax(0,1fr) 80px 110px 100px;";

function procsTab(ctx: RenderCtx): TabResult {
  const procs = [...(ctx.decoded.procs || [])].sort((a, b) => b.totalProcs - a.totalProcs);
  if (procs.length === 0) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_procs"))}</p></div>`, csv: [[t("empty_no_procs")]], title: "Procs" };
  }
  const total = procs.reduce((s, p) => s + p.totalProcs, 0);
  const summaryHtml = summarySection([metricGroup(t("tab_procs"), [
    keyMetric(t("tab_procs"), fmtExact(total), t("m_tracked", procs.length)),
  ])]);

  const head = dtHead([
    {}, { label: t("th_ability") }, { label: t("th_procs"), r: true },
    { label: t("th_interval"), r: true }, { label: t("th_interval_med"), r: true },
  ], PROC_GRID);
  const top = procs[0]?.totalProcs || 1;
  const body = procs.map((p) => {
    const enemies = [...p.procsByEnemy].sort((a, b) => b.procCount - a.procCount);
    const tt = abilityDetails(ctx, p.abilityId, [
      [t("th_procs"), fmtExact(p.totalProcs)],
      [t("th_interval"), fmtSeconds(p.meanIntervalMs)],
      [t("th_interval_med"), fmtSeconds(p.medianIntervalMs)],
      ...enemies.map((e) => [unitName(ctx, e.unitId), `${e.procCount}×`] as DetailStat),
    ], enemies.length ? t("tt_procs_by_enemy") : undefined);
    return detailRow(`
      ${iconHtml(ctx, p.abilityId)}
      <span class="cell-name">${escapeHtml(abilityName(ctx, p.abilityId))}${mechChip(ctx, [p.abilityId])}</span>
      <span class="big">${fmtExact(p.totalProcs)}</span>
      <span class="num m-hide">${fmtSeconds(p.meanIntervalMs) || "—"}</span>
      <span class="num m-hide">${fmtSeconds(p.medianIntervalMs) || "—"}</span>
      <span class="dt-meta">${escapeHtml(t("th_interval"))} ${fmtSeconds(p.meanIntervalMs) || "—"} · ${escapeHtml(t("th_interval_med"))} ${fmtSeconds(p.medianIntervalMs) || "—"}</span>
      <span class="dt-bar" style="width:${(p.totalProcs / top * 100).toFixed(1)}%"></span>
    `, tt, PROC_GRID);
  }).join("");

  const csv: (string | number)[][] = ([["Ability", "Procs", "Mean interval ms", "Median interval ms", "By enemy"]] as (string | number)[][])
    .concat(procs.map((p) => [
      abilityName(ctx, p.abilityId), p.totalProcs, p.meanIntervalMs, p.medianIntervalMs,
      p.procsByEnemy.map((e) => `${unitName(ctx, e.unitId)}: ${e.procCount}`).join("; "),
    ]));
  return {
    html: summaryHtml + `<div class="body-grid wide"><div class="dt">${head}${body}</div></div>`,
    csv,
    title: "Procs",
  };
}

const WEAVE_GRID = "grid-template-columns: 36px minmax(0,1fr) 80px 100px 100px 80px;";

/** Weave gaps are stored as ms sums with their own counts; 0 counts render "—". */
function weaveAvg(sum: number, count: number): string {
  if (!count) return "—";
  return `${Math.round(sum / count)} ms`;
}

/** activity.lua formatPerMinute; "" when the fight has no length to divide by. */
function perMinute(count: number, durationMs: number): string {
  if (durationMs <= 0) return "";
  return t("st_per_minute", (count / (durationMs / 60000)).toFixed(1));
}

/**
 * Gaps of 3s or more between casts, held out of the weave delays. Empty when
 * the fight had none (or the recording predates the split).
 */
function downtimeStat(downtimeMs: number, gaps: number, durationMs: number): string {
  if (gaps <= 0) return "";
  const seconds = downtimeMs / 1000;
  return metric(t("k_downtime"), `${seconds.toFixed(1)}s`, "",
    `${fmtPercent(durationMs > 0 ? downtimeMs / durationMs : 0)} · ${gaps}× · ${escapeHtml(t("tt_downtime_desc"))}`);
}

function weavingTiming(w: NonNullable<DecodedEncounter["weaving"]>): { lost: number; count: number } {
  return w.byAbility.reduce((sum, row) => ({ lost: sum.lost + row.afterSum, count: sum.count + row.afterCount }), { lost: 0, count: 0 });
}

function weavingTab(ctx: RenderCtx): TabResult {
  const w = ctx.decoded.weaving;
  if (!w) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_damage"))}</p></div>`, csv: [["No weaving data"]], title: "Weaving" };
  }
  const timing = weavingTiming(w);
  const summaryHtml = summarySection([
    metricGroup(t("summary_activity"), [
      metric(t("weave_average"), weaveAvg(timing.lost, timing.count), "", escapeHtml(t("weave_average_note"))),
      metric(t("weave_time_lost"), `${(timing.lost / 1000).toFixed(1)}s`, "", `${fmtPercent(ctx.durationMs > 0 ? timing.lost / ctx.durationMs : 0)} · ${escapeHtml(t("weave_lost_note"))}`),
      keyMetric(t("k_skill_casts"), fmtExact(w.skillActivations)),
      metric(t("k_light"), fmtExact(w.lightAttackHits), "", perMinute(w.lightAttackHits, ctx.durationMs)),
      metric(t("k_heavy"), fmtExact(w.heavyAttackHits), "", perMinute(w.heavyAttackHits, ctx.durationMs)),
    ]),
    metricGroup(t("summary_errors"), [
      downtimeStat(w.downtimeMs, w.downtimeGaps, ctx.durationMs),
      metric(t("k_weaving_errors"), fmtExact(w.totalWeavingErrors), "",
        w.skillActivations > 0 ? fmtPercent(w.totalWeavingErrors / w.skillActivations, 0) : ""),
      metric(t("k_double_lights"), fmtExact(w.doubleLaErrors), "",
        w.lightAttackHits > 0 ? fmtPercent(w.doubleLaErrors / w.lightAttackHits, 0) : ""),
    ]),
  ]);

  const rows = [...(w.byAbility || [])].sort((a, b) => b.activations - a.activations);
  const head = dtHead([
    {}, { label: t("th_ability") }, { label: t("th_activations"), r: true },
    { label: t("th_avg_before"), r: true }, { label: t("th_avg_after"), r: true },
    { label: t("th_errors"), r: true },
  ], WEAVE_GRID);
  const top = rows[0]?.activations || 1;
  const body = rows.map((r) => {
    const tt = abilityDetails(ctx, r.abilityId, [
      [t("th_activations"), fmtExact(r.activations)],
      [t("th_avg_before"), `${weaveAvg(r.beforeSum, r.beforeCount)} · ${r.beforeCount}×`],
      [t("th_avg_after"), `${weaveAvg(r.afterSum, r.afterCount)} · ${r.afterCount}×`],
      [t("th_errors"), r.weavingErrors ? fmtExact(r.weavingErrors) : ""],
    ], w.skillActivations > 0
      ? t("weave_cast_share", fmtPercent(r.activations / w.skillActivations, 0))
      : undefined);
    return detailRow(`
      ${iconHtml(ctx, r.abilityId)}
      <span class="cell-name">${escapeHtml(abilityName(ctx, r.abilityId))}${mechChip(ctx, [r.abilityId])}</span>
      <span class="big">${fmtExact(r.activations)}</span>
      <span class="num m-hide">${weaveAvg(r.beforeSum, r.beforeCount)}</span>
      <span class="num m-hide">${weaveAvg(r.afterSum, r.afterCount)}</span>
      <span class="num m-hide">${r.weavingErrors || "—"}</span>
      <span class="dt-meta">${escapeHtml(t("th_avg_after"))} ${weaveAvg(r.afterSum, r.afterCount)} · ${escapeHtml(t("th_errors"))} ${r.weavingErrors || 0}</span>
      <span class="dt-bar" style="width:${(r.activations / top * 100).toFixed(1)}%"></span>
    `, tt, WEAVE_GRID);
  }).join("");

  const table = rows.length
    ? `<div class="dt">${head}${body}</div>`
    : "";
  const csv: (string | number)[][] = [["Metric", "Value"],
    ["Time lost ms", timing.lost],
    ["Average cast delay ms", timing.count ? timing.lost / timing.count : ""],
    [t("k_light"), w.lightAttackHits],
    [t("k_heavy"), w.heavyAttackHits],
    [t("k_skill_casts"), w.skillActivations],
    [t("k_downtime"), w.downtimeMs],
    [t("k_weaving_errors"), w.totalWeavingErrors],
    [t("k_double_lights"), w.doubleLaErrors],
  ];
  appendCsv(csv, ([["Ability", "Casts", "Gap before ms", "Gap after ms", "Errors", "Before samples", "After samples", "Time lost ms"]] as (string | number)[][])
    .concat(rows.map((r) => [
      abilityName(ctx, r.abilityId), r.activations,
      r.beforeCount ? Math.round(r.beforeSum / r.beforeCount) : "",
      r.afterCount ? Math.round(r.afterSum / r.afterCount) : "",
      r.weavingErrors, r.beforeCount, r.afterCount, r.afterSum,
    ])));
  return {
    html: summaryHtml + `<div class="body-grid wide"><div>${table}<div class="note">${escapeHtml(t("note_weaving"))}</div></div></div>`,
    csv,
    title: "Weaving",
  };
}

// ============================================================================
// ULTIMATE / CRUX / Z'EN (journal Activity-tab parity)
// ============================================================================

const ULT_GRID = "grid-template-columns: 36px minmax(0,1fr) 90px 80px 100px;";

/** Icon for the base-generation bucket (gain source id 0, not an ability). */
function ultBaseIcon(): string {
  return `<img class="icon" src="/icons/esoui/art/icons/scribing_tertiary_heroism.png" alt="" loading="lazy">`;
}

interface UltSpend {
  /** True once every cast carries its pool value and slot cost */
  known: boolean;
  spent: number;
  /** Pool consumed above the costs: a cast empties the whole pool */
  lost: number;
  /** Pool decreases outside casts */
  drained: number;
}

// Crypt Transfer spends the entire pool on its group effect despite a slot cost of 1.
const CRYPT_TRANSFER_ABILITY_ID = 195031;

/** activity.lua computeUltSpend. */
function ultSpend(ult: UltimateData): UltSpend {
  let spent = 0;
  let poolSum = 0;
  for (const cast of ult.casts) {
    if (cast.cost == null || cast.poolBefore == null) {
      return { known: false, spent: 0, lost: 0, drained: ult.totalDrained };
    }
    spent += cast.abilityId === CRYPT_TRANSFER_ABILITY_ID ? cast.poolBefore : cast.cost;
    poolSum += cast.poolBefore;
  }
  return {
    known: ult.casts.length > 0,
    spent,
    lost: Math.max(0, poolSum - spent),
    drained: Math.max(0, ult.totalDrained - poolSum),
  };
}

function silentUltimateDetails(ctx: RenderCtx, rates: Array<[number, number]>): string {
  const stats: DetailStat[] = [];
  for (const [id, rate] of rates) {
    const active = ctx.decoded.effectsOnPlayer?.[id]?.totalActiveTimeMs || 0;
    if (!active) continue;
    stats.push([abilityName(ctx, id), t("ult_estimate", fmtExact(Math.ceil(active / 1500) * rate), fmtPercent(ctx.durationMs > 0 ? active / ctx.durationMs : 0))]);
  }
  return stats.length ? detailStats(stats) : "";
}

function ultimateTab(ctx: RenderCtx): TabResult {
  const ult = ctx.decoded.ultimate;
  if (!ult) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_damage"))}</p></div>`, csv: [["No ultimate data"]], title: "Ultimate" };
  }
  const durS = ctx.durationMs / 1000 || 1;
  const spend = ultSpend(ult);

  const generation = [keyMetric(t("ult_at_entry"), `${fmtExact(ult.startUlt)} / ${fmtExact(ult.maxUlt)}`)];
  if (ult.totalGained > 0) {
    generation.push(metric(t("ult_generated"), fmtExact(ult.totalGained), "", `${fmtRate(ult.totalGained / durS)}/s`));
  }
  const spending: string[] = [];
  if (spend.known) {
    spending.push(metric(t("ult_spent"), fmtExact(spend.spent)));
    if (spend.lost > 0) {
      spending.push(metric(t("ult_lost"), fmtExact(spend.lost), "", escapeHtml(t("ult_lost_tt"))));
    }
  }
  if (spend.drained > 0) {
    spending.push(metric(t(spend.known ? "ult_drained" : "ult_spent_drained"), fmtExact(spend.drained), silentUltimateDetails(ctx, [[140699, 1]])));
  }

  const sources = Object.entries(ult.gainByAbilityId)
    .map(([id, gain]) => ({ abilityId: Number(id), gain }))
    .sort((a, b) => b.gain.total - a.gain.total);
  const gainTotal = sources.reduce((s, e) => s + e.gain.total, 0);
  const topGain = sources[0]?.gain.total || 1;

  let sourcesHtml = "";
  if (sources.length) {
    const head = dtHead([
      {}, { label: t("th_ability") }, { label: t("th_gained"), r: true },
      { label: t("th_share"), r: true }, { label: t("st_per_second"), r: true },
    ], ULT_GRID);
    const body = sources.map((s) => {
      const isBase = s.abilityId === 0;
      const name = isBase ? t("ult_base_generation") : abilityName(ctx, s.abilityId);
      const pct = gainTotal > 0 ? s.gain.total / gainTotal : 0;
      const stats: DetailStat[] = [
        [t("tt_total"), `${fmtExact(s.gain.total)} (${fmtPercent(pct)})`],
        [t("st_per_second"), fmtRate(s.gain.total / durS)],
        ...(s.gain.ticks > 0 ? [
          [t("tt_ticks"), String(s.gain.ticks)] as DetailStat,
          [t("th_avg_tick"), (s.gain.total / s.gain.ticks).toFixed(1)] as DetailStat,
          [t("th_minmax"), `${fmtExact(s.gain.minTick)} – ${fmtExact(s.gain.maxTick)}`] as DetailStat,
        ] : []),
      ];
      const tt = isBase ? `<p>${escapeHtml(t("ult_base_note"))}</p>` + detailStats(stats) + silentUltimateDetails(ctx, [[61708, 1], [61709, 3]]) : abilityDetails(ctx, s.abilityId, stats);
      return detailRow(`
        ${isBase ? ultBaseIcon() : iconHtml(ctx, s.abilityId)}
        <span class="cell-name">${escapeHtml(name)}</span>
        <span class="big">${fmtExact(s.gain.total)}</span>
        <span class="num m-hide">${fmtPercent(pct)}</span>
        <span class="num m-hide">${fmtRate(s.gain.total / durS)}/s</span>
        <span class="dt-meta">${fmtPercent(pct)} · ${fmtRate(s.gain.total / durS)}/s</span>
        <span class="dt-bar" style="width:${(s.gain.total / topGain * 100).toFixed(1)}%"></span>
      `, tt, ULT_GRID);
    }).join("");
    sourcesHtml = sectHead(t("h_ult_sources")) + `<div class="dt">${head}${body}</div>`;
  }

  // Casts grouped per ultimate, preserving first-cast order
  const castGroups: Array<{ abilityId: number; times: number[]; lost: number }> = [];
  const castsByAbility = new Map<number, { abilityId: number; times: number[]; lost: number }>();
  for (const cast of ult.casts) {
    let group = castsByAbility.get(cast.abilityId);
    if (!group) {
      group = { abilityId: cast.abilityId, times: [], lost: 0 };
      castsByAbility.set(cast.abilityId, group);
      castGroups.push(group);
    }
    group.times.push(cast.timeMs);
    if (cast.cost != null && cast.poolBefore != null && cast.abilityId !== CRYPT_TRANSFER_ABILITY_ID) {
      group.lost += Math.max(0, cast.poolBefore - cast.cost);
    }
  }
  const CAST_GRID = "grid-template-columns: 36px minmax(0,1fr) auto";
  let castsHtml = "";
  if (castGroups.length) {
    const head = dtHead([
      {}, { label: t("th_ability") },
      { label: spend.known ? t("legend_ult_casts") : t("th_activations"), r: true },
    ], CAST_GRID);
    const rows = castGroups.map((g) => {
      const timeText = g.times.map((ms) => fmtDuration(ms)).join(", ");
      const tt = abilityDetails(ctx, g.abilityId, [
        [t("th_activations"), String(g.times.length)],
        ...(spend.known ? [[t("ult_lost"), fmtExact(g.lost)] as DetailStat] : []),
        [t("ult_cast_times"), timeText],
      ]);
      return detailRow(`
        ${iconHtml(ctx, g.abilityId)}
        <span class="cell-name">${escapeHtml(abilityName(ctx, g.abilityId))}</span>
        <span class="num">${g.times.length}×<span class="m-hide">${spend.known ? ` · ${fmtExact(g.lost)}` : ""}</span> <span class="tag m-hide">${escapeHtml(timeText)}</span></span>
        <span class="dt-meta">${spend.known ? `${escapeHtml(t("ult_lost"))} ${fmtExact(g.lost)}` : escapeHtml(timeText)}</span>
    `, tt, CAST_GRID);
    }).join("");
    castsHtml = sectHead(t("h_ult_casts")) + `<div class="dt" style="max-width:640px">${head}${rows}</div>`;
  }

  const csv: (string | number)[][] = [["Metric", "Value"],
    [t("ult_at_entry"), `${ult.startUlt} / ${ult.maxUlt}`],
    [t("ult_generated"), ult.totalGained],
    ...(spend.known
      ? [[t("ult_spent"), spend.spent] as (string | number)[], [t("ult_lost"), spend.lost] as (string | number)[]]
      : []),
    [t(spend.known ? "ult_drained" : "ult_spent_drained"), spend.drained],
  ];
  appendCsv(csv, ([["Source", "Gained", "Ticks", "Min", "Max"]] as (string | number)[][])
    .concat(sources.map((s) => [
      s.abilityId === 0 ? t("ult_base_generation") : abilityName(ctx, s.abilityId),
      s.gain.total, s.gain.ticks, s.gain.minTick, s.gain.maxTick,
    ])));
  appendCsv(csv, ([["Ultimate", "Casts", "Lost on cast", "Times"]] as (string | number)[][])
    .concat(castGroups.map((g) => [
      abilityName(ctx, g.abilityId), g.times.length, spend.known ? g.lost : "",
      g.times.map((ms) => fmtDuration(ms)).join("; "),
    ])));

  return {
    html: summarySection([metricGroup(t("summary_resources"), generation), ...(spending.length ? [metricGroup(t("summary_spending"), spending)] : [])]) + `<div class="body-grid wide"><div class="section-stack">${[sourcesHtml, castsHtml].filter(Boolean).map((html) => `<section>${html}</section>`).join("")}</div></div>`,
    csv,
    title: "Ultimate",
  };
}

/** combat/crux.lua CRUX_SPENDERS: casts of these consume Crux, never grant it. */
const CRUX_SPENDERS = new Set([
  185805, 193331, 183122, 193397, 186366, 193398, 185823, // Fatecarver family + Tentacular Dread
  185894, 185901, 183241, 186477, // wards
  183537, 198309, 186193, 198330, 186200, 198537, 186209, 198567, // runeforms
  238174, 238249, 238482, // Vengeance variants
]);

const CRUX_GRID = "grid-template-columns: 36px minmax(0,1fr) 80px 90px;";

/** activity.lua formatCountShare: no share printed when there is none to take. */
function countShare(count: number, total: number): string {
  return count === 0 || total === 0 ? "" : fmtPercent(count / total);
}

interface CruxGainRow {
  abilityId: number;
  gained: number;
  /** Procs that found Crux already full; conditional sources only */
  wasted: number;
  /** Cast count; generators only */
  casts?: number;
}

/**
 * activity.lua collectCruxGains: generators contribute their observed stack
 * gains (not their cast count), conditional sources their paired procs.
 */
function cruxGainRows(crux: CruxData): CruxGainRow[] {
  const rows: CruxGainRow[] = [];
  for (const [id, activity] of Object.entries(crux.byAbility)) {
    const abilityId = Number(id);
    if (CRUX_SPENDERS.has(abilityId) || activity.gained <= 0) continue;
    rows.push({ abilityId, gained: activity.gained, wasted: 0, casts: activity.casts });
  }
  for (const [id, count] of Object.entries(crux.conditionalGains)) {
    const abilityId = Number(id);
    const wasted = crux.conditionalWasted[abilityId] || 0;
    if (count > 0 || wasted > 0) rows.push({ abilityId, gained: count, wasted });
  }
  for (const [id, count] of Object.entries(crux.conditionalWasted)) {
    const abilityId = Number(id);
    if (count > 0 && !(crux.conditionalGains[abilityId] || 0)) {
      rows.push({ abilityId, gained: 0, wasted: count });
    }
  }
  rows.sort((a, b) => (b.gained - a.gained) || (b.wasted - a.wasted));
  return rows;
}

function cruxTab(ctx: RenderCtx): TabResult {
  const crux = ctx.decoded.crux;
  if (!crux) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_damage"))}</p></div>`, csv: [["No crux data"]], title: "Crux" };
  }
  const underTotal = crux.spenderUnder[0] + crux.spenderUnder[1] + crux.spenderUnder[2];
  const gains = cruxGainRows(crux);
  const procWasted = Object.values(crux.conditionalWasted).reduce((sum, n) => sum + n, 0);

  const generators: string[] = [];
  const spenders: string[] = [];
  const losses: string[] = [];
  if (crux.generatorCasts > 0) {
    generators.push(keyMetric(t("crux_generators"), fmtExact(crux.generatorCasts)));
    generators.push(metric(t("crux_at_full"), fmtExact(crux.generatorAtFull), "",
      countShare(crux.generatorAtFull, crux.generatorCasts)));
  }
  if (crux.spenderCasts > 0) {
    spenders.push(metric(t("crux_spenders"), fmtExact(crux.spenderCasts)));
    spenders.push(metric(t("crux_under"), fmtExact(underTotal), "",
      countShare(underTotal, crux.spenderCasts)));
    for (const n of [0, 1, 2]) spenders.push(metric(t("crux_cast_at", n), fmtExact(crux.spenderUnder[n] ?? 0)));
  }
  if (procWasted > 0) {
    const tt = detailCard({
      name: t("crux_proc_wasted"),
      desc: t("crux_proc_wasted_tt", ...CRUX_ZERO_ONLY_SOURCES.map((id) => abilityName(ctx, id))),
      stats: gains.filter((g) => g.wasted > 0)
        .map((g) => [abilityName(ctx, g.abilityId), fmtExact(g.wasted)] as DetailStat),
    });
    losses.push(disclosure(metric(t("crux_proc_wasted"), fmtExact(procWasted)), tt, "metric-explanation"));
  }
  if (crux.deathEvents > 0) {
    losses.push(metric(t("crux_death"), fmtExact(crux.deathStacks), "", `${crux.deathEvents}×`));
  }
  if (crux.passiveEvents > 0) {
    losses.push(metric(t("crux_passive"), fmtExact(crux.passiveStacks), "", `${crux.passiveEvents}× · ${escapeHtml(t("crux_passive_tt"))}`));
  }

  let gainsHtml = "";
  if (gains.length || crux.unattributedGains > 0) {
    const head = dtHead([
      {}, { label: t("th_ability") }, { label: t("th_gained"), r: true },
      { label: procWasted > 0 ? t("th_at_full") : "", r: true },
    ], CRUX_GRID);
    const rows = gains.map((g) => {
      const isProc = g.casts == null;
      const stats: DetailStat[] = [
        ...(isProc ? [] : [[t("th_activations"), String(g.casts)] as DetailStat]),
        ...(g.wasted > 0 ? [[t("crux_proc_wasted"), fmtExact(g.wasted)] as DetailStat] : []),
      ];
      const tt = abilityDetails(ctx, g.abilityId, stats, isProc ? t("crux_conditional_tt") : undefined);
      const atFull = g.wasted > 0 ? fmtExact(g.wasted) : "";
      return detailRow(`
        ${iconHtml(ctx, g.abilityId)}
        <span class="cell-name">${escapeHtml(abilityName(ctx, g.abilityId))}</span>
        <span class="big">+${fmtExact(g.gained)}</span>
        <span class="num m-hide">${atFull}</span>
        <span class="dt-meta">${atFull ? `${escapeHtml(t("th_at_full"))} ${atFull}` : ""}</span>
    `, tt, CRUX_GRID);
    }).join("");
    const otherRow = crux.unattributedGains > 0
      ? detailRow(`
          <span class="icon ph" style="background:${phGradient(217699)}">?</span>
          <span class="cell-name">${escapeHtml(t("crux_other"))}</span>
          <span class="big">+${fmtExact(crux.unattributedGains)}</span>
          <span class="num m-hide"></span>
        `, `<p>${escapeHtml(t("crux_other_tt"))}</p>`, CRUX_GRID)
      : "";
    gainsHtml = sectHead(t("h_crux_gained")) + `<div class="dt" style="max-width:640px">${head}${rows}${otherRow}</div>`;
  }

  const badRows = Object.entries(crux.byAbility)
    .map(([id, activity]) => ({ abilityId: Number(id), casts: activity.casts, bad: activity.bad, spender: CRUX_SPENDERS.has(Number(id)) }))
    .filter((r) => r.bad > 0)
    .sort((a, b) => b.bad - a.bad);
  let badHtml = "";
  if (badRows.length) {
    const head = dtHead([
      {}, { label: t("th_ability") }, { label: t("crux_flagged_casts"), r: true },
      { label: t("th_share"), r: true },
    ], CRUX_GRID);
    const rows = badRows.map((r) => {
      const pct = r.casts > 0 ? r.bad / r.casts : 0;
      const condition = t(r.spender ? "crux_under" : "crux_at_full");
      const tt = abilityDetails(ctx, r.abilityId, [
        [t("th_activations"), String(r.casts)],
        [condition, `${r.bad} (${fmtPercent(pct)})`],
      ]);
      return detailRow(`
        ${iconHtml(ctx, r.abilityId)}
        <span class="cell-name">${escapeHtml(abilityName(ctx, r.abilityId))}<span class="tag m-hide">${escapeHtml(condition)}</span></span>
        <span class="big">${r.bad} <span class="u">/ ${r.casts}</span></span>
        <span class="num m-hide">${fmtPercent(pct)}</span>
        <span class="dt-meta">${escapeHtml(condition)} · ${fmtPercent(pct)}</span>
    `, tt, CRUX_GRID);
    }).join("");
    badHtml = sectHead(t("h_crux_by_ability")) + `<p class="note">${escapeHtml(t("crux_casts_note"))}</p>` + `<div class="dt" style="max-width:640px">${head}${rows}</div>`;
  }

  const csv: (string | number)[][] = [["Metric", "Value"],
    [t("crux_generators"), crux.generatorCasts],
    [t("crux_at_full"), crux.generatorAtFull],
    [t("crux_spenders"), crux.spenderCasts],
    [t("crux_under"), underTotal],
    ...[0, 1, 2].map((n) => [t("crux_cast_at", n), crux.spenderUnder[n] ?? 0]),
    [t("crux_proc_wasted"), procWasted],
    [t("crux_death"), crux.deathStacks],
    [t("crux_passive"), crux.passiveStacks],
  ];
  appendCsv(csv, ([["Source", "Crux gained", "At full", "Casts"]] as (string | number)[][])
    .concat(gains.map((g) => [abilityName(ctx, g.abilityId), g.gained, g.wasted, g.casts ?? ""]))
    .concat(crux.unattributedGains > 0 ? [[t("crux_other"), crux.unattributedGains, "", ""]] : []));
  appendCsv(csv, ([["Ability", "Condition", "Casts matching condition", "All casts"]] as (string | number)[][])
    .concat(badRows.map((r) => [abilityName(ctx, r.abilityId), t(r.spender ? "crux_under" : "crux_at_full"), r.bad, r.casts])));

  return {
    html: summarySection([metricGroup(t("summary_resources"), generators), metricGroup(t("summary_spending"), spenders), metricGroup(t("summary_losses"), losses)]) + `<div class="body-grid wide"><div class="section-stack">${[gainsHtml, badHtml].filter(Boolean).map((html) => `<section>${html}</section>`).join("")}</div></div>`,
    csv,
    title: "Crux",
  };
}

interface ZenSummary {
  totalMs: number;
  avgDots: number;
  /** Z'en debuff uptime, 0-1 */
  zenFrac: number;
  /** Whether the player's Z'en debuff was ever up on this boss */
  hasZen: boolean;
  /** Highest DoT count that occurred (5 = the tracking cap, i.e. 5+) */
  peakDots: number;
  /** Time share at that DoT count, 0-1 */
  peakFrac: number;
}

/** activity.lua computeZenSummary over one boss's 12 time buckets. */
function zenSummary(buckets: number[]): ZenSummary {
  let totalMs = 0;
  let dotWeightedMs = 0;
  let zenMs = 0;
  const bucketMs: number[] = [];
  for (let dots = 0; dots <= 5; dots++) {
    const noZen = buckets[dots * 2] || 0;
    const withZen = buckets[dots * 2 + 1] || 0;
    bucketMs[dots] = noZen + withZen;
    totalMs += noZen + withZen;
    dotWeightedMs += dots * (noZen + withZen);
    zenMs += withZen;
  }
  if (totalMs === 0) {
    return { totalMs: 0, avgDots: 0, zenFrac: 0, hasZen: false, peakDots: 0, peakFrac: 0 };
  }
  let peakDots = 0;
  for (let dots = 5; dots >= 1; dots--) {
    if ((bucketMs[dots] || 0) > 0) {
      peakDots = dots;
      break;
    }
  }
  return {
    totalMs,
    avgDots: dotWeightedMs / totalMs,
    zenFrac: zenMs / totalMs,
    hasZen: zenMs > 0,
    peakDots,
    peakFrac: (bucketMs[peakDots] || 0) / totalMs,
  };
}

/** The top bucket absorbs everything above the tracking cap: 5 renders "5+". */
function zenDotsLabel(dots: number): string {
  return t("zen_dots_label", dots === 5 ? "5+" : String(dots));
}

/** Zen keys are "bossTag:tagSeq" — the same shape bossSeqNames uses. */
function zenBossName(ctx: RenderCtx, key: string): string {
  return cleanName(ctx.wireEnc.bossSeqNames?.[key] || key.replace(/:\d+$/, ""));
}

const ZEN_GRID = "grid-template-columns: minmax(0,1fr) 70px 120px;";

function zenTab(ctx: RenderCtx): TabResult {
  const zen = ctx.decoded.zen;
  if (!zen) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_damage"))}</p></div>`, csv: [["No Z'en data"]], title: "Z'en" };
  }
  const tags = Object.keys(zen).sort();
  const parts: string[] = [];
  const csv: (string | number)[][] = [["Boss", "Avg DoTs", "Z'en uptime", "Peak", "Time at peak"]];
  for (const key of tags) {
    const buckets = zen[key] || [];
    const s = zenSummary(buckets);
    if (s.totalMs === 0) continue;
    const name = zenBossName(ctx, key);
    const summary = sectHead(name)
      + kv(t("zen_avg_dots"), s.avgDots.toFixed(1))
      + (s.hasZen ? kv(t("zen_uptime"), fmtPercent(s.zenFrac)) : "")
      + kv(t("zen_peak_time", zenDotsLabel(s.peakDots)), fmtPercent(s.peakFrac));
    const head = dtHead([
      {}, { label: t("zen_time_share"), r: true }, { label: t("zen_active"), r: true },
    ], ZEN_GRID);
    const distRows: string[] = [];
    for (let dots = 0; dots <= 5; dots++) {
      const noZen = buckets[dots * 2] || 0;
      const withZen = buckets[dots * 2 + 1] || 0;
      const bucketTotal = noZen + withZen;
      if (bucketTotal === 0) continue;
      const bucketFrac = bucketTotal / s.totalMs;
      distRows.push(`<div class="dt-row" style="${ZEN_GRID}">
        <span class="cell-name">${escapeHtml(zenDotsLabel(dots))}</span>
        <span class="big">${fmtPercent(bucketFrac)}</span>
        <span class="num">${withZen > 0 ? fmtPercent(withZen / bucketTotal, 0) : "—"}</span>
        <span class="dt-bar" style="width:${(bucketFrac * 100).toFixed(1)}%"></span>
      </div>`);
    }
    parts.push(`<div style="max-width:640px">${summary}<div class="dt zen-table" style="margin-top:12px">${head}${distRows.join("")}</div></div>`);
    csv.push([name, s.avgDots.toFixed(2), s.zenFrac.toFixed(4), zenDotsLabel(s.peakDots), s.peakFrac.toFixed(4)]);
  }
  if (parts.length === 0) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_damage"))}</p></div>`, csv: [["No Z'en data"]], title: "Z'en" };
  }
  return {
    html: `<div class="body-grid wide"><div class="section-stack">
      <div style="max-width:640px">
        <p class="rail-text">${escapeHtml(t("zen_note"))}</p>
        <p class="rail-text">${escapeHtml(t("zen_distribution_note"))}</p>
      </div>${parts.join("")}</div></div>`,
    csv,
    title: "Z'en",
  };
}

// ============================================================================
// GROUP
// ============================================================================

/** Boss column keys are "<bossTag>:<tagSeq>", as the addon writes them. */
function bossKeyOf(bossTag: string, tagSeq: number): string {
  return `${bossTag}:${tagSeq}`;
}

function memberBossDamage(m: GroupMember, key: string): number | null {
  for (const bd of m.entry.data.bossDamage || []) {
    if (bossKeyOf(bd.bossTag, bd.tagSeq) === key) return bd.damage;
  }
  return null;
}

/** Per-boss DPS over the member's own duration, as the journal's columns are. */
function memberBossDps(m: GroupMember, key: string, fallbackMs: number): number | null {
  const damage = memberBossDamage(m, key);
  if (damage == null) return null;
  const dur = (m.entry.data.durationMs || fallbackMs) / 1000 || 1;
  return damage / dur;
}

/**
 * The boss columns the journal shows: every boss any member dealt damage to,
 * ranked by the group's summed damage, capped at four (group_table.lua
 * MAX_BOSSES).
 */
const MAX_BOSS_COLUMNS = 4;

function groupBossKeys(members: GroupMember[]): string[] {
  const totals = new Map<string, number>();
  for (const m of members) {
    for (const bd of m.entry.data.bossDamage || []) {
      const key = bossKeyOf(bd.bossTag, bd.tagSeq);
      totals.set(key, (totals.get(key) || 0) + bd.damage);
    }
  }
  return [...totals.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, MAX_BOSS_COLUMNS)
    .map(([key]) => key);
}

/** The journal prints "-" for a zero rate rather than a bare 0. */
function rateCell(value: number | null | undefined): string {
  return value != null && value > 0 ? fmtRate(value) : "-";
}

// Sort values: strings compare by locale, numbers descending by default.
// Missing numbers sort below every real value in both directions.
function groupSortValue(m: GroupMember, col: string, durationMs: number): number | string {
  if (col === "name") return m.name;
  if (col === "dps") return m.dps;
  if (col === "crit") return m.crit ?? -1;
  if (col === "dtps") return m.dtps ?? -1;
  if (col === "hps") return m.hps ?? -1;
  if (col === "effectiveHps") return m.effectiveHps ?? -1;
  if (col === "overheal") return m.overheal ?? -1;
  if (col === "alive") return m.alive;
  if (col === "deaths") return m.deaths;
  if (col === "res") return m.res;
  if (col.startsWith("boss:")) return memberBossDps(m, col.slice(5), durationMs) ?? -1;
  return m.total;
}

/**
 * Sorted as the journal sorts: the chosen column, then DPS as the tiebreaker
 * for every numeric column, then the (unique) name (group_table.lua SORT_KEYS).
 */
function sortedMembers(members: GroupMember[], durationMs: number): GroupMember[] {
  const { col, dir } = groupSortState;
  return [...members].sort((a, b) => {
    const av = groupSortValue(a, col, durationMs);
    const bv = groupSortValue(b, col, durationMs);
    if (typeof av === "string" || typeof bv === "string") {
      return String(av).localeCompare(String(bv), currentLocale()) * dir;
    }
    if ((av < 0) !== (bv < 0)) return av < 0 ? 1 : -1;
    if (av !== bv) return (av - bv) * dir;
    if (col !== "dps" && a.dps !== b.dps) return (a.dps - b.dps) * dir;
    return a.name.localeCompare(b.name, currentLocale());
  });
}

interface GrpCol {
  label?: string;
  r?: boolean;
  sort?: string;
}

function grpHead(cols: GrpCol[], gridStyle: string): string {
  const cells = cols.map((c) => {
    const label = escapeHtml(c.label || "");
    if (!c.sort) return `<span${c.r ? ' class="r"' : ""}>${label}</span>`;
    const active = groupSortState.col === c.sort;
    const ind = active
      ? `<span class="sort-ind">${groupSortState.dir === 1 ? "▲" : "▼"}</span>` : "";
    return `<button type="button" class="sort-h${c.r ? " r" : ""}${active ? " on" : ""}" data-sort="${escapeHtml(c.sort)}">${label}${ind}</button>`;
  }).join("");
  return `<div class="dt-head" style="${gridStyle}">${cells}</div>`;
}

// ---- member build panel (from the broadcast CompactSetup) ----

function contentSection(label: string, body: string): string {
  return body ? `<section class="content-section">${sectHead(label)}${body}</section>` : "";
}

function bpLine(k: string, v: string): string {
  return v ? `<div class="bp-row"><span class="bp-k">${escapeHtml(k)}</span><span class="bp-v">${escapeHtml(v)}</span></div>` : "";
}

function bpChips(labels: string[]): string {
  return labels.length
    ? `<div class="bp-chips">${labels.map((l) => `<span class="cp-chip">${escapeHtml(l)}</span>`).join("")}</div>`
    : "";
}

/**
 * Weapon type, trait and enchant for one bar's two hands, each expanding the
 * same combined card an item row gets. weaponTypes, weaponTraits and
 * weaponEnchants are all positional over the same four slots:
 * [front main, front off, back main, back off]. Returns escaped HTML.
 */
function weaponLine(ctx: RenderCtx, setup: MemberSetup, slots: [number, number]): string {
  // Positions are [front main, front off, back main, back off], so 0-1 is the
  // front bar and 2-3 the back - which decides whose Heartland count applies
  const heartland = memberHeartlandBars(setup);
  const parts: string[] = [];
  for (const i of slots) {
    const type = setup.weaponTypes?.[i] || 0;
    if (!type) continue;
    const traitId = setup.weaponTraits?.[i] || 0;
    const enchantId = setup.weaponEnchants?.[i] || 0;
    const typeName = tm("weapons", type, `#${type}`);
    const detail = [
      tm("traits", traitId, ""),
      enchantId ? defName(ctx, "enchant", enchantId) : "",
    ].filter(Boolean).join(" · ");
    const note = (i <= 1 ? heartland.front : heartland.back) ? t("tt_heartland") : undefined;
    const tt = detailCard({
      name: typeName,
      tag: t("h_weapons"),
      stats: [[t("tt_trait"), tm("traits", traitId, "")]],
      blocks: [...traitBlock(ctx, traitId, note), ...enchantBlock(ctx, enchantId)],
    });
    parts.push(disclosure(escapeHtml(typeName + (detail ? ` (${detail})` : "")), tt, "reference-detail"));
  }
  return parts.join("");
}

function memberBarSection(ctx: RenderCtx, label: string, ids: number[] | undefined, weapons: string, classId: number, scribed: MemberSetup["scribedAbilities"] = []): string {
  if (!(ids || []).some((id) => id > 0)) return "";
  const slots: WireBarSlot[] = (ids || []).map((id) => ({ abilityId: id, scriptIds: scribed.find((row) => row.abilityId === id)?.scriptIds }));
  // weapons is pre-escaped HTML (each hand carries its own details)
  return `<div class="content-section">${sectHead(label)}${
    weapons ? `<div class="bp-weapons">${weapons}</div>` : ""}${skillBarHtml(ctx, slots, classId)}</div>`;
}

// Champion is 12 positional slots, 4 per discipline in the game's own
// discipline order (setupshare.lua writes offset = (disciplineIndex-1)*4).
// The DB's disciplineId wins when the star resolved; the block index is the
// fallback, which matches the addon's GetChampionDisciplineId(ceil(i/4)).
function memberChampionHtml(ctx: RenderCtx, setup: MemberSetup): string {
  const rows: string[] = [];
  for (let block = 1; block <= 3; block++) {
    const ids = setup.champion.slice((block - 1) * 4, block * 4).filter((id) => id > 0);
    if (ids.length === 0) continue;
    const first = ids[0];
    const disciplineId = (first !== undefined ? ctx.championNames[first]?.disciplineId : undefined) ?? block;
    const chips = ids.map((id) => {
      const info = ctx.championNames[id];
      const description = info?.tooltip ? detailParagraphs(info.tooltip) : "";
      return disclosure(escapeHtml(info?.name || `#${id}`), description, "reference-detail");
    }).join("");
    rows.push(`<div class="cp-row"><span class="cp-disc ${DISCIPLINE_CSS[disciplineId] || ""}">${escapeHtml(tm("disciplines", disciplineId, `#${disciplineId}`))}</span>${chips}</div>`);
  }
  return rows.join("");
}

/**
 * A set's piece count the way the journal writes it: body pieces sit on both
 * bars, so front + back would double every armor set. Equal counts print once,
 * a bar-only set names its bar, and a split set prints both.
 */
function setCountLabel(name: string, frontCount: number, backCount: number): string {
  if (frontCount === backCount) return `${frontCount}× ${name}`;
  if (frontCount === 0) return `${backCount}× ${name} (${t("h_back_bar")})`;
  if (backCount === 0) return `${frontCount}× ${name} (${t("h_front_bar")})`;
  return `${frontCount}×/${backCount}× ${name}`;
}

function memberSetsHtml(ctx: RenderCtx, sets: MemberSetup["sets"]): string {
  const chips = sets.map((s) => {
    const front = s.frontCount || 0;
    const back = s.backCount || 0;
    const label = setCountLabel(defName(ctx, "set", s.setId), front, back);
    // The same set reference appears in both builds and item details.
    const blocks = setBonusBlock(ctx, s.setId);
    const tag = front !== back ? t("tt_frontback", front, back) : "";
    const tt = blocks.length || tag ? detailCard({ name: defName(ctx, "set", s.setId), tag,
      blocks: blocks.map((block) => ({ ...block, head: "" })) }) : "";
    return disclosure(escapeHtml(label), tt, "reference-detail");
  }).join("");
  return chips ? `<div class="bp-chips">${chips}</div>` : "";
}

/** A category of the equipment summary; `lines` are complete, escaped rows. */
function bpCategory(label: string, lines: string[]): string {
  const body = lines.filter(Boolean).join("");
  return body ? `<div class="bp-cat">${escapeHtml(label)}</div>${body}` : "";
}

function memberEquipHtml(ctx: RenderCtx, setup: MemberSetup): string {
  const weights = (setup.armorWeights || []).map((n, i) => n > 0 ? `${n}× ${tm("armor", i + 1, "")}` : "")
    .filter(Boolean).join(" · ");
  const dim = (html: string): string => html ? `<div class="bp-v dim">${html}</div>` : "";
  // Apparel and accessories stay apart, as the journal sections them: their
  // trait ids come from different ranges and their counts describe 7 vs 3 slots
  const apparel = bpCategory(t("h_apparel"), [
    weights ? `<div class="bp-v">${escapeHtml(weights)}</div>` : "",
    dim(traitCountBits(ctx, setup.armorTraits)),
    dim(enchantCountBits(ctx, setup.armorEnchants)),
  ]);
  const accessories = bpCategory(t("h_accessories"), [
    dim(traitCountBits(ctx, setup.jewelryTraits)),
    dim(enchantCountBits(ctx, setup.jewelryEnchants)),
  ]);
  const poison = ([
    [t("front_poison"), setup.frontPoisonItemId],
    [t("back_poison"), setup.backPoisonItemId],
  ] as Array<[string, number | undefined]>)
    .filter((e): e is [string, number] => Boolean(e[1]))
    .map(([label, id]) => {
      const info = ctx.itemNames[id];
      return bpLine(label, info ? cleanName(info.name) : `Item #${id}`);
    }).join("");
  return apparel + accessories + poison;
}

function abilityChips(ctx: RenderCtx, ids: number[] | undefined): string {
  const list = (ids || []).filter((id) => id > 0);
  return bpChips(list.map((id) => abilityName(ctx, id)));
}

/**
 * Class Mastery passives, each carrying its own ability tooltip. The journal
 * shows these instead of the class skill lines whenever the build has them —
 * the lines are inferable from the passives, the passives are not.
 */
function masteryChips(ctx: RenderCtx, ids: number[]): string {
  const chips = ids.map((id) =>
    disclosure(`${iconHtml(ctx, id)}<span>${escapeHtml(abilityName(ctx, id))}</span>`,
      abilityDetails(ctx, id, []), "reference-detail icon-reference")).join("");
  return chips ? `<div class="bp-chips">${chips}</div>` : "";
}

/** The mastery passives when the build has any; the skill lines otherwise. */
function classSection(ctx: RenderCtx, mastery: number[], skillLineIds: number[] | undefined): string {
  if (mastery.length) return contentSection(t("h_class_mastery"), masteryChips(ctx, mastery));
  const lines = (skillLineIds || []).filter((id) => id > 0).map((id) => {
    const def = ctx.defs?.skillline?.[id];
    const name = defName(ctx, "skillline", id);
    const icon = def?.iconUrl
      ? `<img class="icon" src="${escapeHtml(def.iconUrl)}" alt="" loading="lazy">`
      : `<span class="icon ph" style="background:${phGradient(id)}">${escapeHtml(name.charAt(0))}</span>`;
    return `<div class="reference-label">${icon}<span>${escapeHtml(name)}</span></div>`;
  }).join("");
  return contentSection(t("h_class_lines"), lines);
}

function memberBuildPanel(ctx: RenderCtx, m: GroupMember): string {
  const setup = m.setup;
  if (!setup) return "";
  const raceClass = `${tm("races", setup.raceId, `#${setup.raceId}`)} ${tm("classes", setup.classId, `#${setup.classId}`)}`.trim();
  const head = `<div class="bp-head">
    <span class="bp-title">${escapeHtml(raceClass)}</span>
    <span class="bp-sub">${escapeHtml(m.sub)}</span>
    ${setup.isVengeance ? chip(t("mode_vengeance")) : ""}
  </div>`;

  const bars = classSection(ctx, (setup.classMasteryAbilityIds || []).filter((id) => id > 0), setup.classSkillLineIds)
    + memberBarSection(ctx, t("h_front_bar"), setup.frontAbilities, weaponLine(ctx, setup, [0, 1]), setup.classId, setup.scribedAbilities)
    + memberBarSection(ctx, t("h_back_bar"), setup.backAbilities, weaponLine(ctx, setup, [2, 3]), setup.classId, setup.scribedAbilities)
    + memberBarSection(ctx, t("h_ww_bar"), setup.werewolfAbilities, "", setup.classId, setup.scribedAbilities);

  const details = contentSection(t("h_sets"), memberSetsHtml(ctx, setup.sets))
    + contentSection(t("h_equipment"), memberEquipHtml(ctx, setup))
    + contentSection(t("h_champion"), memberChampionHtml(ctx, setup))
    + contentSection(t("h_food"), abilityChips(ctx, setup.foodAbilityIds))
    + contentSection(t("h_mundus"), abilityChips(ctx, setup.mundusAbilityIds))
    + contentSection(t("h_vengeance_perks"), bpChips((setup.vengeancePerkDefIds || [])
        .filter((id) => id > 0).map((id) => defName(ctx, "perk", id))));

  return `<div class="build-panel">${head}<div class="bp-cols"><div class="section-stack">${bars}</div><div class="section-stack">${details}</div></div></div>`;
}

// ---- member death recaps (the two the broadcast carries) ----

function deathAttackRows(ctx: RenderCtx, attacks: DeathRecap["attacks"]): string {
  return (attacks || []).map((a, j) => {
    const isFinal = j === attacks.length - 1;
    const tt = abilityDetails(ctx, a.abilityId, [
      [t("tt_damage"), fmtExact(a.damage)],
      ...(a.attackerName ? [[t("tt_from"), a.attackerName] as DetailStat] : []),
    ]);
    // v19 encounter recaps name the attacker (pre-formatted by the in-game
    // recap at capture time); shared-entry recaps never carry names
    const attacker = a.attackerName
      ? `<span class="tag m-hide">${escapeHtml(a.attackerName)}</span>` : "";
    return detailRow(`
      ${iconHtml(ctx, a.abilityId)}
      <span class="cell-name">${escapeHtml(abilityName(ctx, a.abilityId))}${attacker}</span>
      ${isFinal ? `<span class="badge-final">${escapeHtml(t("tag_final"))}</span>` : "<span></span>"}
      <span class="rec-dmg">${fmtNumber(a.damage)}</span>
    `, tt, "grid-template-columns: 36px minmax(0,1fr) auto auto", "recap-row");
  }).join("");
}

function memberDeathsPanel(ctx: RenderCtx, m: GroupMember): string {
  const deaths = m.entry.data.deaths;
  if (!deaths) return "";
  const blocks: Array<[string, DeathRecap | undefined]> = [
    [t("deaths_first"), deaths.first],
    [t("deaths_last"), deaths.last],
  ];
  const parts = blocks.filter((b): b is [string, DeathRecap] => Boolean(b[1])).map(([label, recap]) => {
    const attacks = recap.attacks || [];
    const final = attacks.length ? attacks[attacks.length - 1] : null;
    const head = `${label} · ${final
      ? t("sub_final_hit", fmtDuration(recap.timeOffsetMs), abilityName(ctx, final.abilityId))
      : fmtDuration(recap.timeOffsetMs)}`;
    // Capped width: in the full-width group panel an uncapped 1fr name
    // column pushes the damage value to the far edge, where it reads as
    // missing entirely
    return `<div class="content-section" style="max-width:640px">${sectHead(head)}${
      deathAttackRows(ctx, attacks) || `<p class="empty">${escapeHtml(t("empty_no_attacks"))}</p>`}</div>`;
  }).join("");
  if (!parts) return "";
  return `<div class="build-panel">${parts}<div class="note">${escapeHtml(t("note_recap"))}</div></div>`;
}

function memberContent(ctx: RenderCtx, m: GroupMember, index: number): string {
  const build = m.me && ctx.wireEnc.setup ? setupTab(ctx).html : memberBuildPanel(ctx, m);
  const overview = `<div class="section-stack">${memberDetails(ctx, m)}${contentSection(t("th_deaths"), memberDeathsPanel(ctx, m))}</div>`;
  if (!build) return overview;
  const id = `member-${index}`;
  return `<div data-member-key="${escapeHtml(encodeURIComponent(m.name))}">
    <div class="member-switch" role="group" aria-label="${escapeHtml(t("th_member"))}">
      <button type="button" data-member-view="overview" aria-pressed="true" aria-controls="${id}-overview">${escapeHtml(t("nav_overview"))}</button>
      <button type="button" data-member-view="build" aria-pressed="false" aria-controls="${id}-build">${escapeHtml(t("nav_setup"))}</button>
    </div>
    <div id="${id}-overview" data-member-panel="overview">${overview}</div>
    <div id="${id}-build" data-member-panel="build" hidden>${build}</div>
  </div>`;
}

function groupTab(ctx: RenderCtx): TabResult {
  const model = groupModel(ctx);
  const d = ctx.decoded;
  const bossTotals = M.groupDamageByBoss(d, ctx.wireEnc.bossTagSeqByUnitId || {});

  if (!model.hasShared && !model.hasObserved) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_group"))}</p></div>`, csv: [["No group data"]], title: "Group" };
  }

  const totalDeaths = model.members.reduce((s, m) => s + (m.deaths || 0), 0);
  const namesLine = model.members.map((m) =>
    m.me ? `<span style="color:var(--gold)">${escapeHtml(m.name)}</span>` : escapeHtml(m.name)).join(" · ");

  const blocks = [
    keyMetric(t("st_group_dps"), fmtExact(model.groupTotal / (ctx.durationMs / 1000 || 1)),
      t("sub_damage_over", fmtExact(model.groupTotal), fmtDuration(ctx.durationMs))),
  ];
  if (model.hasShared) {
    blocks.push(metric(t("st_damage_split"), "", bandHtml(model), namesLine));
    blocks.push(metric(t("st_sharing"), String(model.members.length - 1), "", t("sub_members_shared")));
  }
  blocks.push(metric(t("st_deaths"), String(totalDeaths), "", totalDeaths === 0 ? t("sub_well_fought") : t("sub_across_group")));

  let table = "";
  if (model.hasShared) {
    const topTotal = model.members[0]?.total || 1;
    // Rates use each member's own duration, matching group_table.lua.
    // Per-boss damage and secondary statistics live in the expanded row.
    const grid = "grid-template-columns: 28px 24px minmax(150px,1fr) 82px 82px 94px 76px 68px 52px;";
    const head = grpHead([
      {}, {}, { label: t("th_member"), sort: "name" },
      { label: t("th_dps"), r: true, sort: "dps" },
      { label: t("heal_raw_hps"), r: true, sort: "hps" },
      { label: t("heal_effective_hps"), r: true, sort: "effectiveHps" },
      { label: t("th_overheal"), r: true, sort: "overheal" },
      { label: t("th_alive"), r: true, sort: "alive" },
      { label: t("th_deaths"), r: true, sort: "deaths" },
    ], grid);
    const sortOptions: Array<[string, string]> = [
      ["dps", t("th_dps")], ["hps", t("heal_raw_hps")], ["effectiveHps", t("heal_effective_hps")],
      ["overheal", t("th_overheal")], ["alive", t("th_alive")], ["deaths", t("th_deaths")], ["name", t("th_member")],
    ];
    const sortControl = `<label class="mobile-sort">${escapeHtml(t("sort_by"))}<select data-group-sort>${sortOptions.map(([value, label]) =>
      `<option value="${value}"${groupSortState.col === value ? " selected" : ""}>${escapeHtml(label)}</option>`).join("")}</select></label>`;
    const body = sortedMembers(model.members, ctx.durationMs).map((m, i) => {
      const healingRate = (value: number | null) => value == null ? "—" : fmtRate(value);
      const over = m.overheal == null ? "—" : fmtPercent(m.overheal);
      return detailRow(`
        ${roleBox(m.role)}<span class="cell-rank">${i + 1}</span>
        <span class="cell-name cell-stack"><span class="cn-name"${m.me ? ` style="color:var(--gold)"` : ""}>${escapeHtml(m.name)}</span><span class="tag">${escapeHtml(m.sub)}</span></span>
        <span class="big">${rateCell(m.dps)}</span>
        <span class="num m-hide">${healingRate(m.hps)}</span>
        <span class="num m-hide">${healingRate(m.effectiveHps)}</span>
        <span class="num m-hide">${over}</span>
        <span class="num m-hide">${fmtPercent(m.alive, 0)}</span>
        <span class="num m-hide">${m.deaths}</span>
        <span class="dt-meta">${escapeHtml(t("heal_raw_hps"))} ${healingRate(m.hps)} · ${escapeHtml(t("heal_effective_hps"))} ${healingRate(m.effectiveHps)}<br>${escapeHtml(t("th_overheal"))} ${over} · ${escapeHtml(t("th_alive"))} ${fmtPercent(m.alive, 0)} · ${escapeHtml(t("th_deaths"))} ${m.deaths}</span>
        <span class="dt-bar" style="width:${(m.total / topTotal * 100).toFixed(1)}%"></span>
      `, memberContent(ctx, m, i), grid, "member-row");
    }).join("");
    table = sortControl + `<div class="dt-scroll"><div class="dt group-table">${head}${body}</div></div>`;
  }

  const bossKeys = Object.keys(bossTotals);
  const bossPanel = bossKeys.length
    ? `<div>${sectHead(t("h_group_by_boss"))}${bossKeys.map((key) =>
        kv(cleanName(ctx.wireEnc.bossSeqNames?.[key] || key), fmtExact(bossTotals[key] || 0))).join("")}</div>`
    : "";

  const panels = bossPanel ? `<section>${bossPanel}</section>` : "";

  const csvBossKeys = groupBossKeys(model.members);
  const csv: (string | number)[][] = ([[
    "Rank", "Member", "Role",
    ...csvBossKeys.map((key) => cleanName(ctx.wireEnc.bossSeqNames?.[key] || key) + " DPS"),
    "DPS", "Damage", "CritPct", "DTPS", "RawHPS", "EffectiveHPS", "OverhealPct", "EffectiveHealingOut", "AlivePct", "Deaths", "Res",
    "RawHealingOut", "RawSelfHealing", "EffectiveSelfHealing", "DurationMs", "AliveTimeMs", "DamageTaken", "MaxHit", "DoTPct", "AoEPct",
  ]] as (string | number)[][])
    .concat(sortedMembers(model.members, ctx.durationMs).map((m, i) => [
      i + 1, m.name, m.sub,
      ...csvBossKeys.map((key) => {
        const dps = memberBossDps(m, key, ctx.durationMs);
        return dps != null ? Math.floor(dps) : "";
      }),
      Math.floor(m.dps), m.total, m.crit != null ? m.crit.toFixed(4) : "",
      Math.floor(m.dtps), m.hps != null ? Math.floor(m.hps) : "",
      m.effectiveHps ?? "", m.overheal != null ? m.overheal * 100 : "",
      m.healingOut ?? "", m.alive.toFixed(4), m.deaths, m.res,
      m.entry.data.healing?.rawOut ?? "", m.entry.data.healing?.rawSelf ?? "", m.entry.data.healing?.effectiveSelf ?? "",
      m.entry.data.durationMs, m.entry.data.aliveTimeMs ?? "", m.taken, m.entry.data.maxHit,
      m.entry.data.dotPercent, m.entry.data.aoePercent,
    ]));

  return {
    html: summarySection([metricGroup(t("summary_output"), blocks.slice(0, 1)), metricGroup(t("summary_group"), blocks.slice(1))]) + `<div class="body-grid wide"><div class="section-stack">${table ? `<div>${table}</div>` : ""}${panels}</div></div>`,
    csv,
    title: "Group",
  };
}

// ============================================================================
// SETUP
// ============================================================================

// ESO display-quality palette; 6 is the Mythic override (legendary-but-orange)
const QUALITY_COLORS: Record<number, string> = {
  0: "#c5c29e", 1: "#ffffff", 2: "#2dc50e", 3: "#3a92ff",
  4: "#a02ef7", 5: "#eeca2a", 6: "#ff8000",
};
const DISCIPLINE_CSS: Record<number, string> = { 1: "warfare", 2: "fitness", 3: "craft" };

function scribedInfo(ctx: RenderCtx, slot: WireBarSlot, classId: number): ScribedAbility | undefined {
  const recipe = { craftedAbilityId: slot.craftedAbilityId || ctx.names[slot.abilityId]?.craftedAbilityId,
    scriptIds: slot.scriptIds, classId };
  return isScribedRecipe(recipe) ? ctx.scribing?.[scribingKey(recipe)] : undefined;
}

function skillName(ctx: RenderCtx, slot: WireBarSlot, classId: number): string {
  return scribedInfo(ctx, slot, classId)?.name || abilityName(ctx, slot.abilityId);
}

function skillBarHtml(ctx: RenderCtx, bar: WireBarSlot[] | undefined, classId: number): string {
  const slots = (bar || []).map((slot, i, arr) => {
    if (!slot || !slot.abilityId) return "";
    const isUlt = i === (arr.length - 1);
    const combined = scribedInfo(ctx, slot, classId);
    const name = skillName(ctx, slot, classId);
    const info = ctx.names[slot.abilityId];
    const icon = (cls = "icon"): string => combined?.icon?.startsWith("/esoui/")
      ? `<img class="${cls}" src="${escapeHtml("/icons" + combined.icon.replace(/\.dds$/, ".png"))}" alt="" loading="lazy">`
      : iconHtml(ctx, slot.abilityId, cls);
    // Scribed slots carry their three scripts; they name what the skill
    // actually does, so they ride along with the slot itself
    const scripts = (slot.scriptIds || []).filter((id) => id > 0)
      .map((id) => defName(ctx, "script", id));
    const tt = combined?.tooltip || info?.tooltip || scripts.length
      ? detailCard({
          iconHtml: icon(),
          name,
          tag: isUlt ? t("tag_ultimate") : "",
          desc: combined?.tooltip || (scripts.length ? "" : info?.tooltip || ""),
          notes: scripts.length ? [] : abilityNotes(ctx, slot.abilityId),
          blocks: combined?.tooltip ? [] : (slot.scriptIds || []).filter((id) => id > 0).map((id) => ({
            head: defName(ctx, "script", id), desc: ctx.defs?.script?.[id]?.tooltip || "",
          })),
        })
      : "";
    return disclosure(`<span class="sk-slot${isUlt ? " ult" : ""}">
      ${icon("sk-icon")}
      <span class="sk-name">${escapeHtml(name)}</span>
      ${scripts.length ? `<span class="sk-scripts">${escapeHtml(scripts.join(" · "))}</span>` : ""}
    </span>`, tt, "skill-detail");
  }).join("");
  return `<div class="sk-bar">${slots}</div>`;
}

/**
 * WireEquipSlot.slotIndex is the addon's capture position (setup.lua's
 * EQUIP_SLOTS, 1-based), not an ESO equip slot — hands sit between waist and
 * legs there. Every label goes through this map, or the whole list shifts.
 */
const EQUIP_SLOT_BY_INDEX: Record<number, number> = {
  1: 0, 2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 6, 8: 16, 9: 8, 10: 9, 11: 11, 12: 12, 13: 20, 14: 21,
};

/** Capture indices per visual category, in the journal's GEAR_DISPLAY_ORDER. */
const GEAR_CATEGORIES: Array<{ labelKey: StringKey; indices: number[] }> = [
  { labelKey: "h_weapons", indices: [5, 6, 13, 14] },
  { labelKey: "h_apparel", indices: [1, 3, 4, 7, 8, 9, 10] },
  { labelKey: "h_accessories", indices: [2, 11, 12] },
];

function slotLabel(slotIndex: number): string {
  return tm("slots", EQUIP_SLOT_BY_INDEX[slotIndex], `#${slotIndex}`);
}

/**
 * One item card the way the game lays an item tooltip out: quality-colored
 * name, weight (or weapon type) and slot, the item's own text, then set /
 * trait / quality, then the enchantment with its description - instead of a
 * hover per fragment. Blocks follow the game's own tooltip order: trait right
 * under the item info, then the enchantment, then the set's bonus steps.
 */
function itemDetails(ctx: RenderCtx, slot: WireEquipSlot, heartland?: BarFlags): string {
  const info = ctx.itemNames[slot.itemId];
  const kind = tm("armor", info?.armorType, "") || tm("weapons", info?.weaponType, "");
  const frontWeapon = slot.slotIndex === 5 || slot.slotIndex === 6;
  const backWeapon = slot.slotIndex === 13 || slot.slotIndex === 14;
  const doubled = heartland !== undefined
    && ((frontWeapon && heartland.front) || (backWeapon && heartland.back));
  return detailCard({
    name: info ? cleanName(info.name) : `Item #${slot.itemId}`,
    nameColor: QUALITY_COLORS[slot.quality] || "var(--ink)",
    tag: [kind, slotLabel(slot.slotIndex)].filter(Boolean).join(" · "),
    desc: info?.tooltip || "",
    stats: [
      [t("tt_set"), info?.setName || ""],
      [t("tt_trait"), tm("traits", slot.traitType, "")],
      [t("tt_quality"), tm("quality", slot.quality, "")],
    ],
    blocks: [
      ...traitBlock(ctx, slot.traitType, doubled ? t("tt_heartland") : undefined),
      ...enchantBlock(ctx, slot.enchantId),
      ...setBonusBlock(ctx, info?.setId),
    ],
  });
}

function selfSets(ctx: RenderCtx): MemberSetup["sets"] {
  const sets = new Map<number, { setId: number; frontCount: number; backCount: number }>();
  for (const slot of ctx.wireEnc.setup?.equipSlots || []) {
    const info = ctx.itemNames[slot.itemId];
    if (!info?.setId) continue;
    const row = sets.get(info.setId) || { setId: info.setId, frontCount: 0, backCount: 0 };
    const weapon = [5, 6, 13, 14].includes(slot.slotIndex);
    const count = weapon && TWO_HANDED_WEAPON_TYPES.has(info.weaponType || 0) ? 2 : 1;
    if (slot.slotIndex !== 13 && slot.slotIndex !== 14) row.frontCount += count;
    if (slot.slotIndex !== 5 && slot.slotIndex !== 6) row.backCount += count;
    sets.set(info.setId, row);
  }
  return [...sets.values()];
}

function setupTab(ctx: RenderCtx): TabResult {
  const setup = ctx.wireEnc.setup;
  if (!setup) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_setup"))}</p></div>`, csv: [["No setup"]], title: "Setup" };
  }
  const raceClass = `${tm("races", setup.raceId, `#${setup.raceId}`)} ${tm("classes", setup.classId, `#${setup.classId}`)}`;
  const subBits: string[] = [];
  for (const id of setup.mundusAbilityIds || []) subBits.push(abilityName(ctx, id));
  for (const f of setup.foods || []) {
    subBits.push(abilityName(ctx, f.abilityId) + (f.uptimeMs != null
      ? ` (${t("uptime_pct", fmtPercent(Math.min(1, f.uptimeMs / ctx.durationMs), 0))})` : ""));
  }
  if (setup.isVengeance) subBits.push(t("mode_vengeance"));

  const left: string[] = [];
  const charHead = `<div class="char-line"><span class="char-title">${escapeHtml(raceClass)}</span><span class="char-sub">${escapeHtml(subBits.join(" · "))}</span></div>`;

  const classLineIds = [...(setup.classSkillLineIds || []), ...(setup.loadoutSkillLineId ? [setup.loadoutSkillLineId] : [])].filter((id) => id > 0);
  const classLines = classLineIds.map((id) => defName(ctx, "skillline", id));
  const mastery = (setup.classMasteryAbilityIds || []).filter((id) => id > 0);
  left.push(classSection(ctx, mastery, classLineIds));

  // Like the in-game UI, bars with nothing slotted are hidden entirely
  // (e.g. front/back when the whole fight was spent in werewolf form)
  const barHasAbilities = (bar: WireBarSlot[] | undefined): boolean => (bar || []).some((slot) => Boolean(slot?.abilityId));
  const selfWeapons = (indices: number[]): string => (setup.equipSlots || [])
    .filter((slot) => indices.includes(slot.slotIndex))
    .sort((a, b) => a.slotIndex - b.slotIndex)
    .map((slot) => {
      const info = ctx.itemNames[slot.itemId];
      const label = [tm("weapons", info?.weaponType, ""), tm("traits", slot.traitType, ""),
        slot.enchantId ? defName(ctx, "enchant", slot.enchantId) : ""].filter(Boolean).join(" · ");
      return label ? disclosure(escapeHtml(label), itemDetails(ctx, slot, selfHeartlandBars(ctx, setup.equipSlots || [])), "reference-detail") : "";
    }).join("");
  const barSection = (label: string, bar: WireBarSlot[] | undefined, weapons = ""): string =>
    contentSection(label, `${weapons ? `<div class="bp-weapons">${weapons}</div>` : ""}${skillBarHtml(ctx, bar, setup.classId)}`);
  if (barHasAbilities(setup.abilities?.front)) {
    left.push(barSection(t("h_front_bar") + (setup.frontBarDisabled ? " " + t("bar_disabled") : ""), setup.abilities?.front, selfWeapons([5, 6])));
  }
  if (barHasAbilities(setup.abilities?.back)) {
    left.push(barSection(t("h_back_bar") + (setup.backBarDisabled ? " " + t("bar_disabled") : ""), setup.abilities?.back, selfWeapons([13, 14])));
  }
  if (barHasAbilities(setup.werewolfAbilities)) {
    left.push(barSection(t("h_ww_bar") + (setup.werewolfEntireFight ? " " + t("bar_entire_fight") : ""), setup.werewolfAbilities));
  }

  if (setup.champion?.length) {
    const byDiscipline = new Map<number, typeof setup.champion>();
    for (const c of setup.champion) {
      if (!byDiscipline.has(c.disciplineId)) byDiscipline.set(c.disciplineId, []);
      byDiscipline.get(c.disciplineId)!.push(c);
    }
    const rows = [...byDiscipline.entries()].map(([disciplineId, skills]) => {
      const meta = { name: tm("disciplines", disciplineId, `#${disciplineId}`), cls: DISCIPLINE_CSS[disciplineId] || "" };
      const chips = skills.map((c) => {
        const info = ctx.championNames[c.skillId];
        const description = info?.tooltip ? detailParagraphs(info.tooltip) : "";
        return disclosure(escapeHtml(info?.name || `#${c.skillId}`), description, "reference-detail");
      }).join("");
      return `<div class="cp-row"><span class="cp-disc ${meta.cls}">${escapeHtml(meta.name)}</span>${chips}</div>`;
    }).join("");
    left.push(contentSection(t("h_champion"), rows));
  }

  const perks = (setup.vengeancePerkDefIds || []).filter((id) => id > 0)
    .map((id) => defName(ctx, "perk", id));
  if (perks.length) {
    left.push(contentSection(t("h_vengeance_perks"), bpChips(perks)));
  }

  const heartland = selfHeartlandBars(ctx, setup.equipSlots || []);
  const equipRow = (slot: WireEquipSlot): string => {
    const info = ctx.itemNames[slot.itemId];
    const label = info ? cleanName(info.name) : `Item #${slot.itemId}`;
    // One combined card per row carries set/trait/enchant detail, so the
    // detail line itself is plain text - no nested per-fragment hovers
    const bits = [
      tm("armor", info?.armorType, ""),
      tm("traits", slot.traitType, ""),
      slot.enchantId > 0 ? defName(ctx, "enchant", slot.enchantId) : "",
      slot.quality === 6 ? tm("quality", 6, "") : "",
    ].filter(Boolean).join(" · ");
    const color = QUALITY_COLORS[slot.quality] || "var(--ink)";
    return disclosure(`<span class="eq-row">
      <span class="eq-slot">${escapeHtml(slotLabel(slot.slotIndex))}</span>
      <span class="eq-item" style="color:${color}">${escapeHtml(label)}</span>
      <span class="eq-det">${escapeHtml(bits)}</span>
    </span>`, itemDetails(ctx, slot, heartland), "equipment-detail");
  };

  // Weapons / apparel / accessories, the journal's order; the wire lists the
  // slots in capture order, which is neither.
  const bySlotIndex = new Map<number, WireEquipSlot>();
  for (const slot of setup.equipSlots || []) bySlotIndex.set(slot.slotIndex, slot);
  const placed = new Set(GEAR_CATEGORIES.flatMap((cat) => cat.indices));
  const equipHtml = GEAR_CATEGORIES.map(({ labelKey, indices }) => {
    const rows = indices.map((i) => bySlotIndex.get(i)).filter((s): s is WireEquipSlot => Boolean(s))
      .map(equipRow).join("");
    return contentSection(t(labelKey), rows);
  }).join("")
    + (setup.equipSlots || []).filter((s) => !placed.has(s.slotIndex)).map(equipRow).join("");

  const poisonRows = ([
    [t("front_poison"), setup.frontPoisonItemId],
    [t("back_poison"), setup.backPoisonItemId],
  ] as Array<[string, number | undefined]>)
    .filter((entry): entry is [string, number] => Boolean(entry[1]))
    .map(([label, id]) => {
      const info = ctx.itemNames[id];
      return `<div class="eq-row"><span class="eq-slot">${label}</span><span class="eq-item">${escapeHtml(info ? cleanName(info.name) : `Item #${id}`)}</span><span class="eq-det"></span></div>`;
    }).join("");

  const setRows = memberSetsHtml(ctx, selfSets(ctx));
  const right = contentSection(t("h_sets"), setRows) + equipHtml + contentSection(t("h_poisons"), poisonRows);

  const html = `<div class="setup-grid">${charHead}<div class="section-stack">${left.filter(Boolean).join("")}</div><div class="section-stack">${right}</div></div>`;

  const csv: (string | number)[][] = [["Field", "Value", "Set", "Trait", "Quality", "Enchant"],
    ["Race/Class", raceClass, "", "", "", ""],
    ...(setup.abilities?.front || []).map((s, i) => [`Front ${i + 1}`, s.abilityId ? skillName(ctx, s, setup.classId) : "", "", "", "", ""]),
    ...(setup.abilities?.back || []).map((s, i) => [`Back ${i + 1}`, s.abilityId ? skillName(ctx, s, setup.classId) : "", "", "", "", ""]),
    ...(setup.werewolfAbilities || []).map((s, i) => [`Werewolf ${i + 1}`, s.abilityId ? skillName(ctx, s, setup.classId) : "", "", "", "", ""]),
    ...(setup.equipSlots || []).map((slot) => {
      const info = ctx.itemNames[slot.itemId];
      return [slotLabel(slot.slotIndex),
        info ? cleanName(info.name) : `Item #${slot.itemId}`,
        info?.setName || "", tm("traits", slot.traitType, ""), slot.quality,
        slot.enchantId > 0 ? defName(ctx, "enchant", slot.enchantId) : ""];
    }),
    ...(setup.champion || []).map((c) => [
      tm("disciplines", c.disciplineId, `#${c.disciplineId}`),
      ctx.championNames[c.skillId]?.name || `#${c.skillId}`, "", "", "", ""]),
    ...(mastery.length
      ? mastery.map((id) => [t("h_class_mastery"), abilityName(ctx, id), "", "", "", ""])
      : classLines.map((name) => [t("h_class_lines"), name, "", "", "", ""])),
    ...perks.map((name) => [t("h_vengeance_perks"), name, "", "", "", ""]),
  ];
  return { html, csv, title: "Setup" };
}

// ============================================================================
// DEATHS
// ============================================================================

function deathsTab(ctx: RenderCtx): TabResult {
  const deaths = ctx.decoded.deaths;
  const d = ctx.decoded;
  if (!deaths) {
    return { html: `<div class="body-grid wide"><p class="empty">${escapeHtml(t("empty_no_deaths"))}</p></div>`, csv: [["Deaths", 0]], title: "Deaths" };
  }
  const recaps = deaths.recaps || [];
  const aliveFrac = d.playerAliveTimeMs != null ? Math.min(1, d.playerAliveTimeMs / ctx.durationMs) : 1;
  const deadMs = d.playerAliveTimeMs != null ? Math.max(0, ctx.durationMs - d.playerAliveTimeMs) : 0;

  let recapTaken = 0, recapHits = 0, recapMax = 0;
  for (const recap of recaps) {
    for (const a of recap.attacks || []) {
      recapTaken += a.damage || 0;
      recapHits += 1;
      if ((a.damage || 0) > recapMax) recapMax = a.damage;
    }
  }
  const first = recaps[0];
  const firstFinal = first?.attacks?.length ? first.attacks[first.attacks.length - 1] : null;

  const blocks = [
    keyMetric(t("st_deaths"), String(deaths.deathCount),
      first
        ? (firstFinal
          ? t("sub_final_hit", fmtDuration(first.timeOffsetMs), escapeHtml(abilityName(ctx, firstFinal.abilityId)))
          : fmtDuration(first.timeOffsetMs))
        : t("sub_no_recap")),
    metric(t("st_time_alive"), fmtPercent(aliveFrac), meterHtml(aliveFrac, 1 - aliveFrac),
      d.playerAliveTimeMs != null
        ? t("sub_alive_detail", fmtDuration(d.playerAliveTimeMs), fmtDuration(ctx.durationMs))
          + (deadMs ? ` · ${t("sub_dead", fmtDuration(deadMs))}` : "")
        : ""),
  ];
  if (recapHits > 0) {
    blocks.push(metric(t("st_recap"), `${fmtNumber(recapTaken)} <span class="u">${escapeHtml(t("taken_word"))}</span>`, "",
      t("sub_recap_hits", recapHits, fmtNumber(recapMax))));
  }

  const parts: string[] = [];
  const csv: (string | number)[][] = [["Recap", "Time", "Ability", "Attacker", "Damage", "Final hit"]];
  recaps.forEach((recap, i) => {
    const attacks = recap.attacks || [];
    const rows = deathAttackRows(ctx, attacks);
    parts.push(`<div style="max-width:640px">${sectHead(t("h_death_n", i + 1, fmtDuration(recap.timeOffsetMs)))}${rows || `<p class="empty">${escapeHtml(t("empty_no_attacks"))}</p>`}</div>`);
    attacks.forEach((a, j) => {
      csv.push([i + 1, fmtDuration(recap.timeOffsetMs), abilityName(ctx, a.abilityId),
        a.attackerName || "", a.damage, j === attacks.length - 1 ? "yes" : ""]);
    });
  });
  if (recaps.length === 0) {
    parts.push(`<p class="empty">${escapeHtml(t("empty_deaths_norecap", deaths.deathCount))}</p>`);
  } else {
    parts.push(`<div class="note">${escapeHtml(t("note_recap"))}</div>`);
  }

  return {
    html: summarySection([metricGroup(t("summary_survival"), blocks)]) + `<div class="body-grid wide"><div class="section-stack">${parts.join("")}</div></div>`,
    csv,
    title: "Deaths",
  };
}

// ============================================================================
// NAVIGATION GROUPS
// ============================================================================

function personalDps(ctx: RenderCtx): string {
  const total = M.nestedTotal(ctx.decoded.damageByUnitId, null);
  return fmtDps(total, ctx.durationMs);
}

export const NAV_GROUPS: NavGroup[] = [
  {
    id: "overview", labelKey: "nav_overview",
    menuSub: (ctx) => t("m_dps_deaths", personalDps(ctx), ctx.decoded.deaths?.deathCount || 0),
    subs: [{ id: "overview", labelKey: "nav_overview", render: overviewTab, always: true }],
  },
  {
    id: "damage", labelKey: "nav_damage",
    menuSub: (ctx) => {
      const rows = M.abilityRows(ctx.decoded.damageByUnitId, null, abilityNaming(ctx));
      const total = rows.reduce((s, r) => s + r.total, 0);
      return t("m_abilities", fmtNumber(total), rows.length);
    },
    subs: [
      { id: "boss-damage", labelKey: "tab_boss_damage",
        render: (ctx) => damageTab(ctx, ctx.bossUnits, "Boss Damage", "boss-damage"),
        show: (ctx) => ctx.bossUnits.size > 0 },
      { id: "damage-done", labelKey: "tab_damage_done",
        render: (ctx) => damageTab(ctx, null, "Damage Done", "damage-done"), always: true },
      { id: GROUP_DAMAGE_SUB, labelKey: "tab_group_damage", render: groupDamageTab,
        show: (ctx) => Object.keys(ctx.decoded.damageByUnitIdGroup || {}).length > 0 },
      { id: "damage-taken", labelKey: "tab_damage_taken",
        render: (ctx) => damageTakenTab(ctx, "damage-taken"),
        show: (ctx) => Object.keys(ctx.decoded.damageTakenByUnitId || {}).length > 0 },
    ],
  },
  {
    id: "healing", labelKey: "nav_healing",
    menuSub: (ctx) => {
      const h = ctx.decoded.healingStats;
      let total = h?.selfHealing?.total?.raw || 0;
      for (const out of Object.values(h?.healingOutToGroup || {})) total += out.total?.raw || 0;
      return t("m_raw", fmtNumber(total));
    },
    subs: [
      { id: "healing-out", labelKey: "tab_healing_out",
        render: (ctx) => healingTab(ctx, "healing-out", t("empty_no_group_heal"), "Healing Out"),
        show: (ctx) => Object.keys(ctx.decoded.healingStats?.healingOutToGroup || {}).length > 0 },
      { id: "self-healing", labelKey: "tab_self_healing", render: (ctx) => healingTab(ctx, "self-healing", t("empty_no_self_heal"), "Self Healing"),
        show: (ctx) => (ctx.decoded.healingStats?.selfHealing?.total?.raw || 0) > 0 },
      { id: "healing-in", labelKey: "tab_healing_in",
        render: (ctx) => healingTab(ctx, "healing-in", t("empty_no_in_heal"), "Healing In"),
        show: (ctx) => Object.keys(ctx.decoded.healingStats?.healingInFromGroup || {}).length > 0 },
    ],
  },
  {
    id: "activity", labelKey: "nav_activity",
    menuSub: (ctx) => {
      const w = ctx.decoded.weaving;
      const bits: string[] = [];
      if (w && w.skillActivations > 0) {
        bits.push(`${fmtExact(w.skillActivations)} ${t("k_skill_casts").toLowerCase()}`);
        bits.push(`${fmtExact(w.totalWeavingErrors)} ${t("th_errors").toLowerCase()}`);
      }
      const procs = ctx.decoded.procs?.length || 0;
      if (procs > 0) bits.push(`${procs} ${t("tab_procs").toLowerCase()}`);
      return bits.join(" · ");
    },
    subs: [
      { id: "procs", labelKey: "tab_procs", render: procsTab,
        show: (ctx) => (ctx.decoded.procs?.length || 0) > 0 },
      { id: "ultimate", labelKey: "tab_ultimate", render: ultimateTab,
        show: (ctx) => !!ctx.decoded.ultimate },
      { id: "crux", labelKey: "tab_crux", render: cruxTab,
        show: (ctx) => !!ctx.decoded.crux },
      { id: "support", labelKey: "h_support", render: (ctx) => ({
        html: `<div class="body-grid wide"><div>${supportSection(ctx)}</div></div>`,
        csv: [["Resurrections", ctx.decoded.resurrections || 0], ["Time", "Member"], ...(ctx.decoded.resurrectionLog || []).map((e) => [fmtDuration(e.timeMs), e.displayName])], title: "Support",
      }), show: (ctx) => (ctx.decoded.resurrections || 0) > 0 },
      { id: "zen", labelKey: "tab_zen", render: zenTab,
        show: (ctx) => !!ctx.decoded.zen },
      { id: "weaving", labelKey: "tab_weaving", render: weavingTab,
        show: (ctx) => {
          const w = ctx.decoded.weaving;
          return !!w && (w.lightAttackHits + w.heavyAttackHits + w.skillActivations) > 0;
        } },
    ],
  },
  {
    id: "effects", labelKey: "nav_effects",
    menuSub: (ctx) => {
      const count = Object.keys(ctx.decoded.effectsOnPlayer || {}).length
        + Object.values(ctx.decoded.effectsOnBosses || {}).reduce((s, m) => s + Object.keys(m).length, 0)
        + Object.values(ctx.decoded.effectsOnGroup || {}).reduce((s, m) => s + Object.keys(m).length, 0);
      return t("m_tracked", count);
    },
    subs: [
      { id: "effects-player", labelKey: "fx_on_you",
        render: (ctx) => effectsPlayerTab(ctx, "effects-player"),
        show: (ctx) => Object.keys(ctx.decoded.effectsOnPlayer || {}).length > 0 },
      { id: "effects-boss", labelKey: "fx_on_bosses",
        render: (ctx) => effectsBossTab(ctx, "effects-boss"),
        show: (ctx) => Object.keys(ctx.decoded.effectsOnBosses || {}).length > 0 },
      { id: "effects-group", labelKey: "fx_on_group",
        render: (ctx) => effectsGroupTab(ctx, "effects-group"),
        show: (ctx) => Object.keys(ctx.decoded.effectsOnGroup || {}).length > 0 },
    ],
  },
  {
    id: "group", labelKey: "nav_group",
    menuSub: (ctx) => {
      const model = groupModel(ctx);
      return t("m_group", model.members.length, fmtNumber(model.groupTotal / (ctx.durationMs / 1000 || 1)));
    },
    subs: [{
      id: "group", labelKey: "nav_group", render: groupTab,
      show: (ctx) => (ctx.wireEnc.shared?.length || 0) > 0
        || Object.keys(ctx.decoded.damageByUnitIdGroup || {}).length > 0,
    }],
  },
  {
    id: "setup", labelKey: "nav_setup",
    menuSub: (ctx) => {
      const s = ctx.wireEnc.setup;
      if (!s) return "";
      return `${tm("races", s.raceId, "")} ${tm("classes", s.classId, "")}`.trim();
    },
    subs: [{ id: "setup", labelKey: "nav_setup", render: setupTab, show: (ctx) => !!ctx.wireEnc.setup }],
  },
  {
    id: "deaths", labelKey: "nav_deaths",
    menuSub: (ctx) => {
      const n = ctx.decoded.deaths?.deathCount || 0;
      return n === 0 ? t("m_none") : String(n);
    },
    subs: [{ id: "deaths", labelKey: "nav_deaths", render: deathsTab, show: (ctx) => !!ctx.decoded.deaths }],
  },
];

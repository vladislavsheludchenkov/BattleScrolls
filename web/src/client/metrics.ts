// Arithmancer-lite: the metric computations the viewer needs, mirroring
// combat/arithmancer.lua semantics on decoded export data.
import type {
  AbilityFacts,
  DamageBreakdown,
  DamageMap,
  DecodedEncounter,
  HealingBreakdown,
} from "../shared/decoder";

/** ability id -> breakdown, the innermost level of a damage map. */
export type AbilityDamageMap = Record<number, DamageBreakdown>;
/** source unit id -> ability id -> breakdown (healing done, before merging). */
export type SourceHealingMap = Record<number, Record<number, HealingBreakdown>>;

/** One ability's damage, summed across every target that passed the filter. */
export interface AbilityRow {
  /** The biggest contributing id — supplies the icon and description. */
  abilityId: number;
  /** Merged display name, with the source appended for non-player sources. */
  label: string;
  /** Contributing ids with their totals, biggest first; >1 when morphs merged. */
  variants: AbilityVariant[];
  total: number;
  /** Overkill-inclusive total; the average tick is measured against it. */
  rawTotal: number;
  ticks: number;
  critTicks: number;
  minTick: number;
  maxTick: number;
  /** Unit ids this ability landed on. */
  targets: Set<number>;
}

/** One ability id folded into a merged row. */
export interface AbilityVariant extends DamageBreakdown {
  abilityId: number;
}

/** What `abilityRows` needs to name a row the way the journal names it. */
export interface AbilityNaming {
  /** Display name for an ability id. */
  name: (abilityId: number) => string;
  /** Unit name for a source unit id, when one was recorded. */
  unitName: (unitId: number) => string | undefined;
  /** The uploader's own unit id; every other source is suffixed. */
  playerUnitId: number | undefined;
  /** Ids the journal never suffixes (its synthetic shield/absorb rows). */
  neverSuffixed?: (abilityId: number) => boolean;
}

/** One incoming ability, summed across every attacker that used it. */
export interface DamageTakenRow {
  abilityId: number;
  total: number;
  ticks: number;
  critTicks: number;
  minTick: number;
  maxTick: number;
  /** Unit ids that dealt this damage. */
  attackers: Set<number>;
}

/** One healing component before grouping by display name. */
export interface HealingVariant extends HealingBreakdown {
  abilityId: number;
}

/** Same-name healing components, with their individual stats retained. */
export interface HealingRow extends HealingVariant {
  label: string;
  variants: HealingVariant[];
}

/** The measure used consistently for healing rankings, bars and shares. */
export type HealingBasis = "raw" | "real";
export type HealingDelivery = "direct" | "hot" | "shield" | "regen" | "absorbed";

/** Same exclusive precedence as arithmancer.lua getHealingDeliveryKey. */
export function healingDelivery(abilityId: number, facts?: AbilityFacts): HealingDelivery {
  if (abilityId === 1048573 || facts?.healAbsorption) return "absorbed";
  if (abilityId === 1048575 || facts?.regen) return "regen";
  if (facts?.shield) return "shield";
  if (facts?.overTime) return "hot";
  return "direct";
}

/** The tick counters `critPercent` reads (damage, taken and healing rows all fit). */
export interface CritCountable {
  ticks: number;
  critTicks: number;
}

/** The counters `averageTick` reads. */
export interface TickTotals {
  ticks: number;
  total: number;
  /** Overkill-inclusive total; preferred when present, as the journal does. */
  rawTotal?: number;
}

/** Sums a breakdown row set (abilityId -> DamageBreakdown). */
export function sumBreakdowns(byAbility: AbilityDamageMap | undefined): number {
  let total = 0;
  for (const b of Object.values(byAbility || {})) {
    total += b.total || 0;
  }
  return total;
}

/**
 * One damage map or several read as one: the group damage tab sums the
 * personal map (self, pets, companions) with the observed group map, whose
 * only source key is 0, so the two never share a source id.
 */
export type DamageMaps = DamageMap | DamageMap[] | undefined;

function damageMapList(maps: DamageMaps): DamageMap[] {
  if (!maps) return [];
  return Array.isArray(maps) ? maps : [maps];
}

/** Total over a nested damage map (source -> target -> ability -> breakdown). */
export function nestedTotal(
  damageMap: DamageMap | undefined,
  targetFilter: Set<number> | null | undefined,
): number {
  let total = 0;
  for (const byTarget of Object.values(damageMap || {})) {
    for (const [targetId, byAbility] of Object.entries(byTarget)) {
      if (targetFilter && !targetFilter.has(Number(targetId))) continue;
      total += sumBreakdowns(byAbility);
    }
  }
  return total;
}

/**
 * Flattens a damage map into per-ability rows, optionally filtered by target.
 *
 * Rows are merged the way the journal merges them
 * (renderers/damage.lua displayAbilityBreakdownAsync): first per
 * (source unit, ability id), then by *display name* — so morphs and variants
 * that read as one skill in game land in one row instead of several, and each
 * row keeps its contributing ids for the breakdown in its tooltip. A source
 * that is not the uploader gets its name appended ("Crystal Weapon (Winged
 * Twilight)"), which is what stops a pet's copy of an ability from being
 * summed into the player's own row.
 *
 * Without `naming` the rows are still merged per ability id, but by id alone.
 */
export function abilityRows(
  damageMaps: DamageMaps,
  targetFilter: Set<number> | null | undefined,
  naming?: AbilityNaming,
  sourceFilter?: Set<number> | null,
): AbilityRow[] {
  // Pass 1: one entry per (source unit, ability), summed over targets
  interface Entry extends AbilityRow { sourceUnitId: number }
  const entries = new Map<string, Entry>();
  for (const damageMap of damageMapList(damageMaps)) {
    for (const [sourceId, byTarget] of Object.entries(damageMap)) {
      if (sourceFilter && !sourceFilter.has(Number(sourceId))) continue;
      for (const [targetId, byAbility] of Object.entries(byTarget)) {
        if (targetFilter && !targetFilter.has(Number(targetId))) continue;
        for (const [abilityId, b] of Object.entries(byAbility)) {
          const key = `${sourceId}:${abilityId}`;
          let row = entries.get(key);
          if (!row) {
            row = { abilityId: Number(abilityId), label: "", variants: [],
                    sourceUnitId: Number(sourceId), total: 0, rawTotal: 0, ticks: 0,
                    critTicks: 0, minTick: Infinity, maxTick: 0, targets: new Set() };
            entries.set(key, row);
          }
          row.total += b.total || 0;
          row.rawTotal += b.rawTotal || b.total || 0;
          row.ticks += b.ticks || 0;
          row.critTicks += b.critTicks || 0;
          if ((b.minTick || 0) > 0 && b.minTick < row.minTick) row.minTick = b.minTick;
          if ((b.maxTick || 0) > row.maxTick) row.maxTick = b.maxTick;
          row.targets.add(Number(targetId));
        }
      }
    }
  }

  // Pass 2: merge by display name (or by id when no naming is available)
  const groups = new Map<string, AbilityRow>();
  const contributors = new Map<string, AbilityRow[]>();
  for (const entry of entries.values()) {
    const label = naming ? rowLabel(entry.abilityId, entry.sourceUnitId, naming) : "";
    const key = naming ? label : String(entry.abilityId);
    let row = groups.get(key);
    if (!row) {
      row = { abilityId: entry.abilityId, label, variants: [], total: 0, rawTotal: 0,
              ticks: 0, critTicks: 0, minTick: Infinity, maxTick: 0, targets: new Set() };
      groups.set(key, row);
      contributors.set(key, []);
    }
    contributors.get(key)!.push(entry);
    row.total += entry.total;
    row.rawTotal += entry.rawTotal;
    row.ticks += entry.ticks;
    row.critTicks += entry.critTicks;
    if (entry.minTick < row.minTick) row.minTick = entry.minTick;
    if (entry.maxTick > row.maxTick) row.maxTick = entry.maxTick;
    for (const target of entry.targets) row.targets.add(target);
  }

  const list = [...groups.entries()].map(([key, row]) => {
    // Biggest contributor names the row and supplies its icon, as in game
    const parts = contributors.get(key)!.sort((a, b) => b.total - a.total);
    row.abilityId = parts[0]!.abilityId;
    // Source pools are not ability components: self and observed group hits
    // can use the same id. Merge their statistics before presenting variants.
    const variants = new Map<number, AbilityVariant>();
    for (const p of parts) {
      let variant = variants.get(p.abilityId);
      if (!variant) {
        variant = { abilityId: p.abilityId, total: 0, rawTotal: 0, ticks: 0,
          critTicks: 0, minTick: Infinity, maxTick: 0 };
        variants.set(p.abilityId, variant);
      }
      variant.total += p.total;
      variant.rawTotal += p.rawTotal;
      variant.ticks += p.ticks;
      variant.critTicks += p.critTicks;
      variant.minTick = Math.min(variant.minTick, p.minTick);
      variant.maxTick = Math.max(variant.maxTick, p.maxTick);
    }
    row.variants = [...variants.values()].sort((a, b) => b.total - a.total);
    for (const variant of row.variants) if (variant.minTick === Infinity) variant.minTick = 0;
    row.abilityId = row.variants[0]!.abilityId;
    if (row.minTick === Infinity) row.minTick = 0;
    return row;
  });
  list.sort((a, b) => b.total - a.total);
  return list;
}

/** "Ability" for the uploader's own sources, "Ability (Pet)" for anything else. */
function rowLabel(abilityId: number, sourceUnitId: number, naming: AbilityNaming): string {
  const name = naming.name(abilityId);
  if (naming.neverSuffixed?.(abilityId)) return name;
  if (naming.playerUnitId != null && sourceUnitId === naming.playerUnitId) return name;
  const source = naming.unitName(sourceUnitId);
  return source ? `${name} (${source})` : name;
}

/**
 * Damage-taken rows: attacker -> victim -> ability. Groups by ability and
 * keeps the attacker unit ids for name resolution.
 */
export function damageTakenRows(
  damageTakenMap: DamageMap | undefined,
  sourceFilter?: Set<number> | null,
): DamageTakenRow[] {
  const rows = new Map<string, DamageTakenRow>();
  for (const [attackerId, byVictim] of Object.entries(damageTakenMap || {})) {
    if (sourceFilter && !sourceFilter.has(Number(attackerId))) continue;
    for (const byAbility of Object.values(byVictim)) {
      for (const [abilityId, b] of Object.entries(byAbility)) {
        let row = rows.get(abilityId);
        if (!row) {
          row = { abilityId: Number(abilityId), total: 0, ticks: 0, critTicks: 0,
                  minTick: Infinity, maxTick: 0, attackers: new Set() };
          rows.set(abilityId, row);
        }
        row.total += b.total || 0;
        row.ticks += b.ticks || 0;
        row.critTicks += b.critTicks || 0;
        if ((b.minTick || 0) > 0 && b.minTick < row.minTick) row.minTick = b.minTick;
        if ((b.maxTick || 0) > row.maxTick) row.maxTick = b.maxTick;
        row.attackers.add(Number(attackerId));
      }
    }
  }
  const list = [...rows.values()];
  for (const row of list) {
    if (row.minTick === Infinity) row.minTick = 0;
  }
  list.sort((a, b) => b.total - a.total);
  return list;
}

/** Per-boss group damage keyed by "tag:seq" (mirrors groupDamageByBoss). */
export function groupDamageByBoss(
  encounterData: DecodedEncounter,
  bossTagSeqByUnitId: Record<number, string>,
): Record<string, number> {
  const result: Record<string, number> = {};
  const add = (damageMap: DamageMap | undefined): void => {
    for (const byTarget of Object.values(damageMap || {})) {
      for (const [targetId, byAbility] of Object.entries(byTarget)) {
        const key = bossTagSeqByUnitId[Number(targetId)];
        if (!key) continue;
        result[key] = (result[key] || 0) + sumBreakdowns(byAbility);
      }
    }
  };
  add(encounterData.damageByUnitId);
  add(encounterData.damageByUnitIdGroup);
  return result;
}

/** Healing rows grouped by display name, keeping the component breakdown. */
export function healingRows(
  byAbility: Record<number, HealingBreakdown> | undefined,
  name: (abilityId: number) => string,
  basis: HealingBasis = "raw",
): HealingRow[] {
  const groups = new Map<string, HealingRow>();
  for (const [abilityId, b] of Object.entries(byAbility || {})) {
    const variant: HealingVariant = { ...b, abilityId: Number(abilityId) };
    const label = name(variant.abilityId);
    let row = groups.get(label);
    if (!row) {
      row = { ...variant, label, variants: [variant] };
      groups.set(label, row);
      continue;
    }
    row.variants.push(variant);
    row.raw += variant.raw;
    row.real += variant.real;
    row.overheal += variant.overheal;
    row.ticks += variant.ticks;
    row.critTicks += variant.critTicks;
    if (variant.minTick > 0 && (row.minTick === 0 || variant.minTick < row.minTick)) row.minTick = variant.minTick;
    row.maxTick = Math.max(row.maxTick, variant.maxTick);
  }
  const list = [...groups.values()];
  for (const row of list) {
    row.variants.sort((a, b) => b[basis] - a[basis] || b.raw - a.raw || a.abilityId - b.abilityId);
    row.abilityId = row.variants[0]!.abilityId;
  }
  list.sort((a, b) => b[basis] - a[basis] || b.raw - a.raw || a.abilityId - b.abilityId);
  return list;
}

/** Merges unit/ability healing maps to plain byAbilityId without mutating input. */
export function mergeSources(
  bySourceByAbility: SourceHealingMap | undefined,
): Record<number, HealingBreakdown> {
  const merged: Record<number, HealingBreakdown> = {};
  for (const byAbility of Object.values(bySourceByAbility || {})) {
    for (const [abilityId, b] of Object.entries(byAbility)) {
      const id = Number(abilityId);
      const m = merged[id];
      if (!m) {
        merged[id] = { ...b };
      } else {
        m.raw += b.raw || 0;
        m.real += b.real || 0;
        m.overheal += b.overheal || 0;
        m.ticks += b.ticks || 0;
        m.critTicks += b.critTicks || 0;
        if ((b.minTick || 0) > 0 && (m.minTick === 0 || b.minTick < m.minTick)) m.minTick = b.minTick;
        if ((b.maxTick || 0) > m.maxTick) m.maxTick = b.maxTick;
      }
    }
  }
  return merged;
}

export function critPercent(row: CritCountable): number {
  return row.ticks > 0 ? row.critTicks / row.ticks : 0;
}

/** Overkill-inclusive, matching tooltips.lua appendTickStats (rawTotal first). */
export function averageTick(row: TickTotals): number {
  const total = row.rawTotal || row.total;
  return row.ticks > 0 ? total / row.ticks : 0;
}

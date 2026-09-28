// BattleScrolls export-stream decoder.
// Mirrors the wire framing of BattleScrolls/network/export.lua and the wire
// blob writers of BattleScrolls/storage/binary.lua. Only wire v8 exists —
// every earlier generation was retired before it reached the public addon,
// so there is deliberately no legacy branching. v8 frames storage v20 blobs
// with the exporting device platform and raw game world:
// a 24-bit section mask, first-class ULTIMATE / RESURRECTIONS / CRUX / ZEN
// sections, an attacker-name ref on every stored death-recap attack,
// resurrections + zen metrics appended to shared payloads, plus weaving
// downtime, per-cast ultimate pool/cost, observed Crux generator gains,
// Crux proc waste and death split, and the resurrection log.
//
// Bit semantics (must match bitcodec.lua exactly): bits fill bytes LSB-first,
// multi-byte values are little-endian, varints are LEB128. All arithmetic uses
// number math (not JS 32-bit bitwise ops) so values are exact to 2^53, same
// contract as the Lua side.

const WIRE_VERSION = 8;
// Storage version of the addon build that writes wire v8; shared-entry
// payloads default to it unless the entry carries an explicit version
const STORAGE_VERSION = 20;
const FLAG_DEFLATE = 1;
const FLAG_ARCHIVE = 2;

// Bound both the transported stream and its expanded body in the Worker and
// browser. A compressed share must not bypass the upload's memory budget.
export const MAX_EXPORT_BYTES = 8 * 1024 * 1024;

const SECTION = {
  DAMAGE: 1,
  DAMAGE_GROUP: 2,
  DAMAGE_TAKEN: 3,
  HEALING: 4,
  PROCS: 5,
  EFFECTS_PLAYER: 6,
  EFFECTS_BOSSES: 7,
  EFFECTS_GROUP: 8,
  BOSS_NAMES: 9,
  PLAYER_ALIVE_TIME: 10,
  UNIT_ALIVE_TIMES: 11,
  UNIT_NAMES: 12,
  DEATHS: 13,
  SETUP: 14,
  WEAVING: 15,
  ULTIMATE: 16,
  RESURRECTIONS: 17,
  CRUX: 18,
  ZEN: 19,
} as const;

const BITS = {
  ABILITY_ID: 20,
  DEATH_ATTACK_COUNT: 3,
} as const;

const MAX_MAP_COUNT = 65535;
const PERCENT_MAX = 4095;
const BOSS_TAGS = ["boss1", "boss2", "boss3", "boss4", "boss5", "boss6"] as const;

const utf8 = new TextDecoder("utf-8");

// ============================================================================
// DECODED SHAPES
// ============================================================================

export interface DamageBreakdown {
  total: number;
  /** Includes overkill; equals total unless overkill was recorded */
  rawTotal: number;
  ticks: number;
  critTicks: number;
  minTick: number;
  maxTick: number;
}

/** source unit id -> target unit id -> ability id -> breakdown */
export type DamageMap = Record<number, Record<number, Record<number, DamageBreakdown>>>;

export interface HealingTotals {
  raw: number;
  real: number;
  overheal: number;
}

export interface HealingBreakdown extends HealingTotals {
  ticks: number;
  critTicks: number;
  minTick: number;
  maxTick: number;
}

export interface HealingDoneDiffSource {
  total: HealingTotals;
  bySourceUnitIdByAbilityId: Record<number, Record<number, HealingBreakdown>>;
}

export interface HealingDone {
  total: HealingTotals;
  byAbilityId: Record<number, HealingBreakdown>;
}

export interface HealingStats {
  selfHealing: HealingDoneDiffSource;
  healingOutToGroup: Record<number, HealingDoneDiffSource>;
  healingInFromGroup: Record<number, HealingDone>;
}

export interface ProcEnemy {
  unitId: number;
  procCount: number;
}

export interface ProcData {
  abilityId: number;
  totalProcs: number;
  meanIntervalMs: number;
  medianIntervalMs: number;
  procsByEnemy: ProcEnemy[];
}

export interface EffectStats {
  abilityId: number;
  effectType: number;
  totalActiveTimeMs: number;
  timeAtMaxStacksMs: number;
  applications: number;
  maxStacks: number;
  playerActiveTimeMs: number;
  playerTimeAtMaxStacksMs: number;
  playerApplications: number;
  peakConcurrentInstances: number;
}

export interface DeathAttack {
  abilityId: number;
  damage: number;
  /** Enemy name as the in-game recap captured it; encounter recaps only —
   * shared-entry recaps never carry names */
  attackerName?: string;
}

export interface DeathRecap {
  timeOffsetMs: number;
  attacks: DeathAttack[];
}

export interface EncounterDeaths {
  deathCount: number;
  recaps: DeathRecap[];
}

export interface WeavingAbility {
  abilityId: number;
  activations: number;
  afterSum: number;
  afterCount: number;
  beforeSum: number;
  beforeCount: number;
  weavingErrors: number;
}

export interface WeavingData {
  lightAttackHits: number;
  heavyAttackHits: number;
  skillActivations: number;
  totalWeavingErrors: number;
  doubleLaErrors: number;
  /** Summed gaps of 3s or more between casts, held out of the cast delays */
  downtimeMs: number;
  downtimeGaps: number;
  byAbility: WeavingAbility[];
}

export interface UltGainBreakdown {
  total: number;
  /** 0 = the base-generation bucket (no discrete ticks) */
  ticks: number;
  minTick: number;
  maxTick: number;
}

export interface UltCastEvent {
  timeMs: number;
  abilityId: number;
  /** Slot cost at press; both fields absent when the cast carries no pool data */
  cost?: number;
  poolBefore?: number;
}

export interface UltimateData {
  startUlt: number;
  maxUlt: number;
  totalGained: number;
  totalDrained: number;
  /** Ability id 0 = base generation */
  gainByAbilityId: Record<number, UltGainBreakdown>;
  casts: UltCastEvent[];
}

export interface CruxAbilityActivity {
  casts: number;
  /** Wasted-generation casts (generators) or under-3 spends (spenders) */
  bad: number;
  /** Observed stack gains paired with this generator's casts */
  gained: number;
}

export interface CruxData {
  generatorCasts: number;
  generatorAtFull: number;
  spenderCasts: number;
  /** Spender casts by pre-cast Crux count: [0]=at 0, [1]=at 1, [2]=at 2 */
  spenderUnder: [number, number, number];
  /** Stack drops with neither a spender cast nor a death nearby */
  passiveEvents: number;
  passiveStacks: number;
  /** Stack drops that fell inside a death window */
  deathEvents: number;
  deathStacks: number;
  byAbility: Record<number, CruxAbilityActivity>;
  /** Canonical source ability id (raw, not a registry ref) -> Crux from its procs */
  conditionalGains: Record<number, number>;
  /** Same keys -> procs that found Crux already full */
  conditionalWasted: Record<number, number>;
  unattributedGains: number;
}

/**
 * Per-boss Z'en delivery buckets, keyed "bossTag:tagSeq". 12 time values in
 * ms: index dots*2 = time at `dots` DoTs without the Z'en debuff,
 * dots*2+1 = with it, for dots 0..5 (5 = the tracking cap, i.e. 5+).
 */
export type ZenData = Record<string, number[]>;

export interface ResurrectionEvent {
  displayName: string;
  /** Offset from fight start */
  timeMs: number;
}

export interface DecodedEncounter {
  damageByUnitId: DamageMap;
  damageByUnitIdGroup: DamageMap;
  damageTakenByUnitId: DamageMap;
  healingStats: HealingStats;
  procs: ProcData[];
  effectsOnPlayer?: Record<number, EffectStats>;
  effectsOnBosses?: Record<string, Record<number, EffectStats>>;
  effectsOnGroup?: Record<string, Record<number, EffectStats>>;
  bossNames?: Record<string, string>;
  playerAliveTimeMs?: number;
  unitAliveTimeMs?: Record<string, number>;
  unitNames: Record<number, string>;
  deaths?: EncounterDeaths;
  weaving?: WeavingData;
  ultimate?: UltimateData;
  /** Successful resurrection casts; section omitted when 0 */
  resurrections?: number;
  /** Who was resurrected and when; absent when the log was empty */
  resurrectionLog?: ResurrectionEvent[];
  crux?: CruxData;
  zen?: ZenData;
}

// --- Shared entry payload (group member broadcast data) ---

export interface SharedDamageByType {
  type: number;
  damage: number;
}

export interface SharedBossDamage {
  bossTag: string;
  tagSeq: number;
  damage: number;
  critPercent: number;
  dotPercent: number;
  aoePercent: number;
  magicalPercent: number;
}

export interface SharedBossDamageTaken {
  bossTag: string;
  tagSeq: number;
  damage: number;
}

export interface SharedHealing {
  rawOut: number;
  effectiveOut: number;
  rawSelf: number;
  effectiveSelf: number;
}

export interface SharedTopTakenAbility {
  abilityId: number;
  damagePercent: number;
}

export interface SharedDeaths {
  deathCount: number;
  first: DeathRecap;
  last?: DeathRecap;
}

export interface SharedZenBoss {
  bossTag: string;
  tagSeq: number;
  /** Average DoT stacks in tenths (0-50) */
  avgStacksTenths: number;
  /** Time spent at 5 (the cap) stacks, ms */
  timeAt5Ms: number;
}

export interface SharedEncounterData {
  totalDamage: number;
  critPercent: number;
  dotPercent: number;
  aoePercent: number;
  maxHit: number;
  totalDamageTaken: number;
  damageByType: SharedDamageByType[];
  bossDamage: SharedBossDamage[];
  bossDamageTaken: SharedBossDamageTaken[];
  healing?: SharedHealing;
  aliveTimeMs?: number;
  topDamageTakenAbilities: SharedTopTakenAbility[];
  deaths?: SharedDeaths;
  /** v19+ payloads only; absent when the sender's build predates it or the count was 0 */
  resurrections?: number;
  /** v19+ payloads only; only bosses the sender's Z'en debuff touched */
  zenByBoss?: SharedZenBoss[];
  timestampS: number;
  durationMs: number;
}

export interface DecodedSharedEntry {
  displayName: string;
  role: number | undefined;
  data: SharedEncounterData;
}

// --- Wire setup (the uploader's own build, full fidelity) ---

export interface WireBarSlot {
  abilityId: number;
  craftedAbilityId?: number;
  scriptIds?: [number, number, number];
}

export interface WireEquipSlot {
  slotIndex: number;
  itemId: number;
  /** GetItemLinkTraitType result; -1 unknown */
  traitType: number;
  enchantId: number;
  quality: number;
}

export interface WireFood {
  abilityId: number;
  uptimeMs?: number;
}

export interface WireChampionSkill {
  skillId: number;
  disciplineId: number;
}

export interface WireSetup {
  isVengeance?: true;
  werewolfEntireFight?: true;
  frontBarDisabled: boolean;
  backBarDisabled: boolean;
  raceId: number;
  classId: number;
  abilities: { front?: WireBarSlot[]; back?: WireBarSlot[] };
  werewolfAbilities?: WireBarSlot[];
  champion: WireChampionSkill[];
  mundusAbilityIds?: number[];
  foods?: WireFood[];
  classSkillLineIds: number[];
  classMasteryAbilityIds?: number[];
  equipSlots: WireEquipSlot[];
  frontPoisonItemId?: number;
  backPoisonItemId?: number;
  weaponTypes?: [number, number, number, number];
  loadoutSkillLineId?: number;
  vengeancePerkDefIds?: [number, number, number];
}

// --- Member setup (lossy group-broadcast build summary, CompactSetup mirror) ---

export interface MemberSetupSet {
  setId: number;
  frontCount: number;
  backCount: number;
}

export interface MemberGroupedCount {
  id: number;
  count: number;
}

export interface MemberScribedAbility {
  abilityId: number;
  scriptIds: [number, number, number];
}

export interface MemberSetup {
  isVengeance: boolean;
  raceId: number;
  classId: number;
  frontAbilities?: number[];
  backAbilities?: number[];
  werewolfAbilities?: number[];
  sets: MemberSetupSet[];
  armorWeights: [number, number, number];
  weaponTypes: [number, number, number, number];
  armorTraits: MemberGroupedCount[];
  armorEnchants: MemberGroupedCount[];
  jewelryTraits: MemberGroupedCount[];
  jewelryEnchants: MemberGroupedCount[];
  weaponTraits: [number, number, number, number];
  weaponEnchants: [number, number, number, number];
  /** 12 positional skill ids, 4 per discipline; 0 = empty */
  champion: number[];
  foodAbilityIds: number[];
  mundusAbilityIds: number[];
  classSkillLineIds: number[];
  classMasteryAbilityIds?: number[];
  scribedAbilities: MemberScribedAbility[];
  frontPoisonItemId?: number;
  backPoisonItemId?: number;
  frontPoisonEffect?: number;
  backPoisonEffect?: number;
  loadoutSkillLineId?: number;
  vengeancePerkDefIds?: [number, number, number];
}

// --- Stream level ---

/** Per-ability empirical classification recorded by the sharer's own client */
export interface AbilityFacts {
  direct?: boolean;
  overTime?: boolean;
  shield?: boolean;
  regen?: boolean;
  healAbsorption?: boolean;
  /** DAMAGE_TYPE values recorded for this ability, ascending */
  damageTypes?: number[];
}

export interface WireRegistry {
  abilityIds: number[];
  names: string[];
  facts: Record<number, AbilityFacts>;
}

export interface WireSharedEntry {
  isSelf: boolean;
  displayName: string;
  role: number;
  payloadVersion: number;
  timestampS: number;
  durationMs: number;
  /** Resolved from the stream's member-setup pool; undefined when not shared */
  memberSetup?: MemberSetup;
  payloadBytes: Uint8Array;
}

export interface WireEncounter {
  isBoss: boolean;
  isPlayerFight: boolean;
  isDummyFight: boolean;
  displayName: string;
  /** Game patch at recording time; "" when unknown */
  gameVersion: string;
  timestampS: number;
  durationMs: number;
  /**
   * Unit id the recorder attributed personal rows to (may be the addon's
   * synthetic inferred id, which is still the key the damage maps use).
   * 0 = unknown (recordings older than the stamping scribe).
   */
  playerUnitId: number;
  bossesUnits: number[];
  bossTagSeqByUnitId: Record<number, string>;
  bossSeqNames: Record<string, string>;
  dataBytes: Uint8Array;
  shared: WireSharedEntry[];
  setup: WireSetup | null;
}

export interface ExportStream {
  profile: "view" | "archive";
  createdAtS: number;
  /** Device running the exporting client, independent of the account service. */
  platform: "pc" | "xbox" | "playstation";
  /** Game server, not the uploader's residence or IP-derived location. */
  worldName: string;
  instanceName: string;
  /** When the recorded run started (createdAtS is the export moment) */
  instanceTimestampS: number;
  isOverland: boolean;
  isHouse: boolean;
  isPvP: boolean;
  isAdventureZone: boolean;
  registry: WireRegistry;
  memberSetups: MemberSetup[];
  encounters: WireEncounter[];
}

// ============================================================================
// BIT READER (mirror of bitcodec.lua BitDecoder over a flat byte array)
// ============================================================================

export class BitReader {
  private readonly bytes: Uint8Array;
  private bitPos = 0; // absolute bit position, LSB-first within each byte

  constructor(bytes: Uint8Array) {
    this.bytes = bytes;
  }

  get bitLength(): number {
    return this.bytes.length * 8;
  }

  readUInt(bits: number): number {
    if (this.bitPos + bits > this.bitLength) {
      throw new Error("BitReader: read past end of stream");
    }
    let value = 0;
    let outBit = 0;

    // Fast path: byte-aligned whole bytes
    if ((this.bitPos & 7) === 0) {
      let byteIdx = this.bitPos >> 3;
      while (bits >= 8) {
        value += (this.bytes[byteIdx] as number) * 2 ** outBit;
        byteIdx += 1;
        outBit += 8;
        bits -= 8;
      }
      this.bitPos = byteIdx * 8;
    }

    while (bits > 0) {
      const byteIdx = this.bitPos >> 3;
      const bitIdx = this.bitPos & 7;
      const bit = ((this.bytes[byteIdx] as number) >> bitIdx) & 1;
      value += bit * 2 ** outBit;
      this.bitPos += 1;
      outBit += 1;
      bits -= 1;
    }
    return value;
  }

  readBit(): boolean {
    return this.readUInt(1) === 1;
  }

  alignToByte(): void {
    const off = this.bitPos & 7;
    if (off > 0) {
      this.readUInt(8 - off);
    }
  }

  readVarUInt(): number {
    let result = 0;
    let multiplier = 1;
    for (;;) {
      const group = this.readUInt(8);
      if (group < 128) {
        return result + group * multiplier;
      }
      result += (group - 128) * multiplier;
      multiplier *= 128;
    }
  }

  readZigZag(): number {
    const n = this.readVarUInt();
    return n % 2 === 0 ? n / 2 : -(n + 1) / 2;
  }

  /** u8-length-prefixed string (bitcodec readString) */
  readString(): string {
    const len = this.readUInt(8);
    if (len === 0) return "";
    const buf = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      buf[i] = this.readUInt(8);
    }
    return utf8.decode(buf);
  }
}

// ============================================================================
// WIRE-LEVEL BYTE READER (export.lua framing: byte-aligned only)
// ============================================================================

class ByteReader {
  private readonly bytes: Uint8Array;
  private pos = 0;

  constructor(bytes: Uint8Array) {
    this.bytes = bytes;
  }

  u8(): number {
    const b = this.bytes[this.pos];
    if (b === undefined) {
      throw new Error("wire: read past end");
    }
    this.pos += 1;
    return b;
  }

  varint(): number {
    let result = 0;
    let multiplier = 1;
    for (;;) {
      const group = this.u8();
      if (group < 128) return result + group * multiplier;
      result += (group - 128) * multiplier;
      multiplier *= 128;
    }
  }

  slice(n: number): Uint8Array {
    if (this.pos + n > this.bytes.length) {
      throw new Error("wire: slice past end");
    }
    const out = this.bytes.subarray(this.pos, this.pos + n);
    this.pos += n;
    return out;
  }

  /** varint-length-prefixed string (wire-level strings) */
  string(): string {
    return utf8.decode(this.slice(this.varint()));
  }

  zigzag(): number {
    const n = this.varint();
    return n % 2 === 0 ? n / 2 : -(n + 1) / 2;
  }

  get atEnd(): boolean {
    return this.pos === this.bytes.length;
  }
}

// ============================================================================
// SECTION READERS (wire v8: v20 semantics in the columnar wire layout)
// ============================================================================

function readMapCount(r: BitReader): number {
  const count = r.readVarUInt();
  return count > MAX_MAP_COUNT ? MAX_MAP_COUNT : count;
}

function readAbilityRef(r: BitReader, registry: WireRegistry): number {
  const index = r.readVarUInt();
  const abilityId = registry.abilityIds[index];
  if (abilityId === undefined) {
    throw new Error(`Corrupt ability registry reference: ${index + 1}`);
  }
  return abilityId;
}

/**
 * v18 sorted-map ref: refs are gap-encoded (first as its absolute 0-based
 * index, then distance-1 to the previous). prevIndex is 1-based, 0 before
 * the first entry; returns the resolved id and the new prevIndex.
 */
function readDeltaAbilityRef(r: BitReader, registry: WireRegistry, prevIndex: number): [number, number] {
  const index = prevIndex + 1 + r.readVarUInt();
  const abilityId = registry.abilityIds[index - 1];
  if (abilityId === undefined) {
    throw new Error(`Corrupt ability registry reference: ${index}`);
  }
  return [abilityId, index];
}

function readNameRef(r: BitReader, registry: WireRegistry): string {
  const index = r.readVarUInt();
  const name = registry.names[index];
  if (name === undefined) {
    throw new Error(`Corrupt name registry reference: ${index + 1}`);
  }
  return name;
}

/**
 * Damage map: the source/target/ref skeleton first, then every breakdown
 * field as a column across the whole map. totalPacked carries the
 * rawTotal-differs flag in bit 0; ticksPacked carries single-tick elision
 * (minTick == maxTick == total) in bit 0.
 */
function readDamageMapWire(r: BitReader, registry: WireRegistry): DamageMap {
  const result: DamageMap = {};
  const slots: { byAbility: Record<number, DamageBreakdown>; abilityId: number }[] = [];
  const sourceCount = readMapCount(r);
  for (let s = 0; s < sourceCount; s++) {
    const sourceId = r.readVarUInt();
    const byTarget: Record<number, Record<number, DamageBreakdown>> = {};
    result[sourceId] = byTarget;
    const targetCount = readMapCount(r);
    for (let t = 0; t < targetCount; t++) {
      const targetId = r.readVarUInt();
      const byAbility: Record<number, DamageBreakdown> = {};
      byTarget[targetId] = byAbility;
      const abilityCount = readMapCount(r);
      let prevIndex = 0;
      for (let a = 0; a < abilityCount; a++) {
        let abilityId: number;
        [abilityId, prevIndex] = readDeltaAbilityRef(r, registry, prevIndex);
        slots.push({ byAbility, abilityId });
      }
    }
  }

  const n = slots.length;
  const totals = new Array<number>(n);
  const rawTotals = new Array<number>(n);
  const rawDiffers = new Array<boolean>(n);
  for (let i = 0; i < n; i++) {
    const packed = r.readVarUInt();
    totals[i] = Math.floor(packed / 2);
    rawDiffers[i] = packed % 2 === 1;
    rawTotals[i] = totals[i] as number;
  }
  for (let i = 0; i < n; i++) {
    if (rawDiffers[i]) rawTotals[i] = (totals[i] as number) + r.readVarUInt();
  }
  const ticks = new Array<number>(n);
  const ticksSame = new Array<boolean>(n);
  for (let i = 0; i < n; i++) {
    const packed = r.readVarUInt();
    ticks[i] = Math.floor(packed / 2);
    ticksSame[i] = packed % 2 === 1;
  }
  const critTicks = new Array<number>(n);
  for (let i = 0; i < n; i++) critTicks[i] = r.readVarUInt();
  const minTicks = new Array<number>(n);
  for (let i = 0; i < n; i++) {
    minTicks[i] = ticksSame[i] ? (totals[i] as number) : r.readVarUInt();
  }
  const maxTicks = new Array<number>(n);
  for (let i = 0; i < n; i++) {
    maxTicks[i] = ticksSame[i] ? (totals[i] as number) : (minTicks[i] as number) + r.readVarUInt();
  }

  for (let i = 0; i < n; i++) {
    const slot = slots[i]!;
    slot.byAbility[slot.abilityId] = {
      total: totals[i] as number,
      rawTotal: rawTotals[i] as number,
      ticks: ticks[i] as number,
      critTicks: critTicks[i] as number,
      minTick: minTicks[i] as number,
      maxTick: maxTicks[i] as number,
    };
  }
  return result;
}

function readHealingTotals(r: BitReader): HealingTotals {
  const real = r.readVarUInt();
  const overheal = r.readVarUInt();
  return { raw: real + overheal, real, overheal };
}

// Healing stays interleaved on the wire (sorted gap refs + breakdown rows);
// bit 0 of the ticks varint flags minTick == maxTick == raw
function readHealingBreakdown(r: BitReader): HealingBreakdown {
  const real = r.readVarUInt();
  const overheal = r.readVarUInt();
  const ticksPacked = r.readVarUInt();
  const ticks = Math.floor(ticksPacked / 2);
  const ticksSame = ticksPacked % 2 === 1;
  const critTicks = r.readVarUInt();
  let minTick: number;
  let maxTick: number;
  if (ticksSame) {
    minTick = real + overheal;
    maxTick = real + overheal;
  } else {
    minTick = r.readVarUInt();
    maxTick = minTick + r.readVarUInt();
  }
  return { raw: real + overheal, real, overheal, ticks, critTicks, minTick, maxTick };
}

function readHealingDoneDiffSource(r: BitReader, registry: WireRegistry): HealingDoneDiffSource {
  const result: HealingDoneDiffSource = {
    total: readHealingTotals(r),
    bySourceUnitIdByAbilityId: {},
  };
  const sourceCount = readMapCount(r);
  for (let s = 0; s < sourceCount; s++) {
    const sourceId = r.readVarUInt();
    const byAbility: Record<number, HealingBreakdown> = {};
    result.bySourceUnitIdByAbilityId[sourceId] = byAbility;
    const abilityCount = readMapCount(r);
    let prevIndex = 0;
    for (let a = 0; a < abilityCount; a++) {
      let abilityId: number;
      [abilityId, prevIndex] = readDeltaAbilityRef(r, registry, prevIndex);
      byAbility[abilityId] = readHealingBreakdown(r);
    }
  }
  return result;
}

function readHealingDone(r: BitReader, registry: WireRegistry): HealingDone {
  const result: HealingDone = { total: readHealingTotals(r), byAbilityId: {} };
  const abilityCount = readMapCount(r);
  let prevIndex = 0;
  for (let a = 0; a < abilityCount; a++) {
    let abilityId: number;
    [abilityId, prevIndex] = readDeltaAbilityRef(r, registry, prevIndex);
    result.byAbilityId[abilityId] = readHealingBreakdown(r);
  }
  return result;
}

function readHealingStats(r: BitReader, registry: WireRegistry): HealingStats {
  const result: HealingStats = {
    selfHealing: readHealingDoneDiffSource(r, registry),
    healingOutToGroup: {},
    healingInFromGroup: {},
  };
  const outCount = readMapCount(r);
  for (let i = 0; i < outCount; i++) {
    const targetId = r.readVarUInt();
    result.healingOutToGroup[targetId] = readHealingDoneDiffSource(r, registry);
  }
  const inCount = readMapCount(r);
  for (let i = 0; i < inCount; i++) {
    const sourceId = r.readVarUInt();
    result.healingInFromGroup[sourceId] = readHealingDone(r, registry);
  }
  return result;
}

function makeEmptyHealingStats(): HealingStats {
  return {
    selfHealing: {
      total: { raw: 0, real: 0, overheal: 0 },
      bySourceUnitIdByAbilityId: {},
    },
    healingOutToGroup: {},
    healingInFromGroup: {},
  };
}

function readProcs(r: BitReader, registry: WireRegistry): ProcData[] {
  const result: ProcData[] = [];
  const procCount = readMapCount(r);
  for (let i = 0; i < procCount; i++) {
    const proc: ProcData = {
      abilityId: readAbilityRef(r, registry),
      totalProcs: r.readVarUInt(),
      meanIntervalMs: r.readVarUInt(),
      medianIntervalMs: r.readVarUInt(),
      procsByEnemy: [],
    };
    const enemyCount = readMapCount(r);
    for (let j = 0; j < enemyCount; j++) {
      proc.procsByEnemy.push({
        unitId: r.readVarUInt(),
        procCount: r.readVarUInt(),
      });
    }
    result.push(proc);
  }
  return result;
}

/**
 * Effect columns: after a section's ref skeleton, every record field arrives
 * as a column spanning the whole section. Times are permille of the
 * encounter duration; playerTimeAtMaxStacksMs is not shipped (reconstructed
 * as timeAtMax for playerSame rows, 0 otherwise - the viewer never reads it).
 */
function readWireEffectColumns(
  r: BitReader,
  slots: { byAbility: Record<number, EffectStats>; abilityId: number }[],
  durationMs: number,
): void {
  const n = slots.length;
  const toMs = (p: number): number => Math.round((p * durationMs) / 1000);

  const flags = new Array<number>(n);
  for (let i = 0; i < n; i++) flags[i] = r.readUInt(8);
  const timeAtMaxSame = (i: number): boolean => (flags[i] as number) % 16 >= 8;
  const playerSame = (i: number): boolean => (flags[i] as number) % 8 >= 4;
  const peakOne = (i: number): boolean => (flags[i] as number) % 4 >= 2;
  const playerZero = (i: number): boolean => (flags[i] as number) % 2 >= 1;
  const playerExplicit = (i: number): boolean => !playerSame(i) && !playerZero(i);

  const totalActive = new Array<number>(n);
  for (let i = 0; i < n; i++) totalActive[i] = r.readVarUInt();
  const appsPacked = new Array<number>(n);
  for (let i = 0; i < n; i++) appsPacked[i] = r.readVarUInt();
  const timeAtMax = new Array<number>(n);
  for (let i = 0; i < n; i++) {
    timeAtMax[i] = timeAtMaxSame(i) ? (totalActive[i] as number) : r.readVarUInt();
  }
  const playerActive = new Array<number>(n);
  for (let i = 0; i < n; i++) {
    playerActive[i] = playerExplicit(i) ? r.readVarUInt()
      : playerSame(i) ? (totalActive[i] as number) : 0;
  }
  const playerApplications = new Array<number>(n);
  for (let i = 0; i < n; i++) {
    playerApplications[i] = playerExplicit(i) ? r.readVarUInt()
      : playerSame(i) ? Math.floor((appsPacked[i] as number) / 16) : 0;
  }
  const peak = new Array<number>(n);
  for (let i = 0; i < n; i++) {
    peak[i] = peakOne(i) ? 1 : r.readVarUInt();
  }

  for (let i = 0; i < n; i++) {
    const slot = slots[i]!;
    const totalActiveTimeMs = toMs(totalActive[i] as number);
    const timeAtMaxStacksMs = toMs(timeAtMax[i] as number);
    slot.byAbility[slot.abilityId] = {
      abilityId: slot.abilityId,
      effectType: Math.floor((flags[i] as number) / 16),
      totalActiveTimeMs,
      timeAtMaxStacksMs,
      applications: Math.floor((appsPacked[i] as number) / 16),
      maxStacks: (appsPacked[i] as number) % 16,
      playerActiveTimeMs: toMs(playerActive[i] as number),
      playerTimeAtMaxStacksMs: playerSame(i) ? timeAtMaxStacksMs : 0,
      playerApplications: playerApplications[i] as number,
      peakConcurrentInstances: peak[i] as number,
    };
  }
}

function readEffectsOnPlayerWire(
  r: BitReader,
  registry: WireRegistry,
  durationMs: number,
): Record<number, EffectStats> | undefined {
  const count = readMapCount(r);
  if (count === 0) return undefined;
  const result: Record<number, EffectStats> = {};
  const slots: { byAbility: Record<number, EffectStats>; abilityId: number }[] = [];
  let prevIndex = 0;
  for (let i = 0; i < count; i++) {
    let abilityId: number;
    [abilityId, prevIndex] = readDeltaAbilityRef(r, registry, prevIndex);
    slots.push({ byAbility: result, abilityId });
  }
  readWireEffectColumns(r, slots, durationMs);
  return result;
}

function readEffectsByNameWire(
  r: BitReader,
  registry: WireRegistry,
  durationMs: number,
): Record<string, Record<number, EffectStats>> | undefined {
  const outerCount = readMapCount(r);
  if (outerCount === 0) return undefined;
  const result: Record<string, Record<number, EffectStats>> = {};
  const slots: { byAbility: Record<number, EffectStats>; abilityId: number }[] = [];
  for (let i = 0; i < outerCount; i++) {
    const key = readNameRef(r, registry);
    const byAbility: Record<number, EffectStats> = {};
    result[key] = byAbility;
    const abilityCount = readMapCount(r);
    let prevIndex = 0;
    for (let a = 0; a < abilityCount; a++) {
      let abilityId: number;
      [abilityId, prevIndex] = readDeltaAbilityRef(r, registry, prevIndex);
      slots.push({ byAbility, abilityId });
    }
  }
  readWireEffectColumns(r, slots, durationMs);
  return result;
}

function readBossNames(r: BitReader, registry: WireRegistry): Record<string, string> | undefined {
  const count = readMapCount(r);
  if (count === 0) return undefined;
  const result: Record<string, string> = {};
  for (let i = 0; i < count; i++) {
    const unitTag = readNameRef(r, registry);
    result[unitTag] = readNameRef(r, registry);
  }
  return result;
}

function readUnitAliveTimes(r: BitReader, registry: WireRegistry): Record<string, number> | undefined {
  const count = readMapCount(r);
  if (count === 0) return undefined;
  const result: Record<string, number> = {};
  for (let i = 0; i < count; i++) {
    const unitKey = readNameRef(r, registry);
    result[unitKey] = r.readVarUInt();
  }
  return result;
}

function readUnitNames(r: BitReader, registry: WireRegistry): Record<number, string> {
  const result: Record<number, string> = {};
  const count = readMapCount(r);
  for (let i = 0; i < count; i++) {
    const unitId = r.readVarUInt();
    result[unitId] = readNameRef(r, registry);
  }
  return result;
}

/**
 * Encounter path: attack count packed into the time varint, ability refs.
 * v19: every attack carries an attacker-name varint — the raw 1-based intern
 * index into the name pool (0 = unknown), unlike the 0-based readNameRef form.
 */
function readDeathRecap(r: BitReader, registry: WireRegistry): DeathRecap {
  const packed = r.readVarUInt();
  const timeOffsetMs = Math.floor(packed / 8);
  const attackCount = packed % 8;
  const attacks: DeathAttack[] = [];
  for (let i = 0; i < attackCount; i++) {
    const attack: DeathAttack = {
      abilityId: readAbilityRef(r, registry),
      damage: r.readVarUInt(),
    };
    const nameIndex = r.readVarUInt();
    if (nameIndex > 0) {
      const name = registry.names[nameIndex - 1];
      if (name === undefined) {
        throw new Error(`Corrupt attacker name reference: ${nameIndex}`);
      }
      attack.attackerName = name;
    }
    attacks.push(attack);
  }
  return { timeOffsetMs, attacks };
}

/** Registry-less path (shared entries): raw 20-bit ability ids, 3-bit count */
function readSharedDeathRecap(r: BitReader): DeathRecap {
  const timeOffsetMs = r.readVarUInt();
  const attackCount = r.readUInt(BITS.DEATH_ATTACK_COUNT);
  const attacks: DeathAttack[] = [];
  for (let i = 0; i < attackCount; i++) {
    attacks.push({
      abilityId: r.readUInt(BITS.ABILITY_ID),
      damage: r.readVarUInt(),
    });
  }
  return { timeOffsetMs, attacks };
}

function readDeaths(r: BitReader, registry: WireRegistry): EncounterDeaths {
  const deathCount = readMapCount(r);
  const recapCount = readMapCount(r);
  const recaps: DeathRecap[] = [];
  for (let i = 0; i < recapCount; i++) {
    recaps.push(readDeathRecap(r, registry));
  }
  return { deathCount, recaps };
}

// ============================================================================
// ULTIMATE / CRUX / ZEN SECTIONS
// (RESURRECTIONS is read inline in decodeEncounter)
// ============================================================================

function readUltimate(r: BitReader, registry: WireRegistry): UltimateData {
  const ult: UltimateData = {
    startUlt: r.readVarUInt(),
    maxUlt: r.readVarUInt(),
    totalGained: r.readVarUInt(),
    totalDrained: r.readVarUInt(),
    gainByAbilityId: {},
    casts: [],
  };

  const gainCount = readMapCount(r);
  let prevIndex = 0;
  for (let i = 0; i < gainCount; i++) {
    let abilityId: number;
    [abilityId, prevIndex] = readDeltaAbilityRef(r, registry, prevIndex);
    const total = r.readVarUInt();
    const ticks = r.readVarUInt();
    // ticks == 0 (base bucket) has no tick stats; ticks == 1 implies
    // minTick == maxTick == total; only 2+ ticks carry explicit bounds
    let minTick = 0;
    let maxTick = 0;
    if (ticks === 1) {
      minTick = total;
      maxTick = total;
    } else if (ticks >= 2) {
      minTick = r.readVarUInt();
      maxTick = r.readVarUInt();
    }
    ult.gainByAbilityId[abilityId] = { total, ticks, minTick, maxTick };
  }

  const castCount = readMapCount(r);
  let prevTimeMs = 0;
  for (let i = 0; i < castCount; i++) {
    prevTimeMs += r.readVarUInt();
    const cast: UltCastEvent = { timeMs: prevTimeMs, abilityId: readAbilityRef(r, registry) };
    // cost 0 = the recording carried no pool/cost for this press; poolBefore
    // only follows a nonzero cost
    const cost = r.readVarUInt();
    if (cost > 0) {
      cast.cost = cost;
      cast.poolBefore = r.readVarUInt();
    }
    ult.casts.push(cast);
  }
  return ult;
}

/** Sparse raw-ability-id -> count map, sorted ascending (binary.lua readRawIdMap) */
function readRawIdMap(r: BitReader): Record<number, number> {
  const map: Record<number, number> = {};
  const count = readMapCount(r);
  for (let i = 0; i < count; i++) {
    const abilityId = r.readVarUInt();
    map[abilityId] = r.readVarUInt();
  }
  return map;
}

function readCrux(r: BitReader, registry: WireRegistry): CruxData {
  const crux: CruxData = {
    generatorCasts: r.readVarUInt(),
    generatorAtFull: r.readVarUInt(),
    spenderCasts: r.readVarUInt(),
    spenderUnder: [r.readVarUInt(), r.readVarUInt(), r.readVarUInt()],
    passiveEvents: r.readVarUInt(),
    passiveStacks: r.readVarUInt(),
    deathEvents: r.readVarUInt(),
    deathStacks: r.readVarUInt(),
    byAbility: {},
    conditionalGains: {},
    conditionalWasted: {},
    unattributedGains: 0,
  };

  const count = readMapCount(r);
  let prevIndex = 0;
  for (let i = 0; i < count; i++) {
    let abilityId: number;
    [abilityId, prevIndex] = readDeltaAbilityRef(r, registry, prevIndex);
    crux.byAbility[abilityId] = {
      casts: r.readVarUInt(), bad: r.readVarUInt(), gained: r.readVarUInt(),
    };
  }

  // Conditional-generation sources ship raw display ids, not registry refs
  crux.conditionalGains = readRawIdMap(r);
  crux.conditionalWasted = readRawIdMap(r);
  crux.unattributedGains = r.readVarUInt();
  return crux;
}

function readZen(r: BitReader, registry: WireRegistry): ZenData {
  const zen: ZenData = {};
  const count = readMapCount(r);
  for (let i = 0; i < count; i++) {
    const unitTag = readNameRef(r, registry);
    const buckets: number[] = [];
    for (let b = 0; b < 12; b++) {
      buckets.push(r.readVarUInt());
    }
    zen[unitTag] = buckets;
  }
  return zen;
}

// ============================================================================
// SHARED ENTRY PAYLOAD
// ============================================================================

function readPercent(r: BitReader): number {
  return r.readUInt(12) / PERCENT_MAX;
}

function readBossTag(r: BitReader): string {
  const index = r.readUInt(3);
  if (index >= 1 && index <= 6) return BOSS_TAGS[index - 1] as string;
  if (index === 7) return r.readString();
  return "";
}

export interface SharedEntryMeta {
  displayName: string;
  role: number;
  /** Storage version the payload was encoded at; gates the v19 tail fields */
  payloadVersion: number;
  timestampS: number;
  durationMs: number;
}

/** Decodes one shared entry payload (binary SharedEncounterData). */
export function decodeSharedEntry(payload: Uint8Array, meta: SharedEntryMeta): DecodedSharedEntry {
  const r = new BitReader(payload);

  const totalDamage = r.readVarUInt();
  const critPercent = readPercent(r);
  const dotPercent = readPercent(r);
  const aoePercent = readPercent(r);
  const maxHit = r.readVarUInt();
  const totalDamageTaken = r.readVarUInt();

  const damageByType: SharedDamageByType[] = [];
  const typeCount = readMapCount(r);
  for (let i = 0; i < typeCount; i++) {
    damageByType.push({
      type: r.readUInt(6),
      damage: r.readVarUInt(),
    });
  }

  const bossDamage: SharedBossDamage[] = [];
  const bossCount = readMapCount(r);
  for (let i = 0; i < bossCount; i++) {
    bossDamage.push({
      bossTag: readBossTag(r),
      tagSeq: r.readVarUInt(),
      damage: r.readVarUInt(),
      critPercent: readPercent(r),
      dotPercent: readPercent(r),
      aoePercent: readPercent(r),
      magicalPercent: readPercent(r),
    });
  }

  const bossDamageTaken: SharedBossDamageTaken[] = [];
  const takenCount = readMapCount(r);
  for (let i = 0; i < takenCount; i++) {
    bossDamageTaken.push({
      bossTag: readBossTag(r),
      tagSeq: r.readVarUInt(),
      damage: r.readVarUInt(),
    });
  }

  let healing: SharedHealing | undefined;
  if (r.readBit()) {
    healing = {
      rawOut: r.readVarUInt(),
      effectiveOut: r.readVarUInt(),
      rawSelf: r.readVarUInt(),
      effectiveSelf: r.readVarUInt(),
    };
  }

  let aliveTimeMs: number | undefined;
  if (r.readBit()) {
    aliveTimeMs = r.readVarUInt();
  }

  const topDamageTakenAbilities: SharedTopTakenAbility[] = [];
  const topCount = readMapCount(r);
  for (let i = 0; i < topCount; i++) {
    topDamageTakenAbilities.push({
      abilityId: r.readUInt(BITS.ABILITY_ID),
      damagePercent: readPercent(r),
    });
  }

  let deaths: SharedDeaths | undefined;
  if (r.readBit()) {
    const deathCount = r.readUInt(4);
    const first = readSharedDeathRecap(r);
    let last: DeathRecap | undefined;
    if (r.readBit()) {
      last = readSharedDeathRecap(r);
    }
    deaths = last === undefined ? { deathCount, first } : { deathCount, first, last };
  }

  // v19 appends the resurrection count and the per-boss zen metrics; older
  // payloads (an explicit payloadVersion on the wire) simply end here
  let resurrections: number | undefined;
  let zenByBoss: SharedZenBoss[] | undefined;
  if (meta.payloadVersion >= 19) {
    if (r.readBit()) {
      resurrections = r.readVarUInt();
    }
    if (r.readBit()) {
      zenByBoss = [];
      const zenCount = readMapCount(r);
      for (let i = 0; i < zenCount; i++) {
        zenByBoss.push({
          bossTag: readBossTag(r),
          tagSeq: r.readVarUInt(),
          avgStacksTenths: r.readVarUInt(),
          timeAt5Ms: r.readVarUInt(),
        });
      }
    }
  }

  const data: SharedEncounterData = {
    totalDamage, critPercent, dotPercent, aoePercent, maxHit, totalDamageTaken,
    damageByType, bossDamage, bossDamageTaken, topDamageTakenAbilities,
    // Wire encodes "compact.t or 0" — absent and genuine 0 are one value
    timestampS: meta.timestampS,
    durationMs: meta.durationMs,
  };
  if (healing) data.healing = healing;
  if (aliveTimeMs !== undefined) data.aliveTimeMs = aliveTimeMs;
  if (deaths) data.deaths = deaths;
  if (resurrections !== undefined) data.resurrections = resurrections;
  if (zenByBoss) data.zenByBoss = zenByBoss;

  return {
    displayName: meta.displayName,
    role: meta.role || undefined,
    data,
  };
}

// ============================================================================
// ENCOUNTER DECODE (v20 _data blob against the export registry)
// ============================================================================

function hasSection(mask: number, sectionBit: number): boolean {
  return Math.floor(mask / 2 ** (sectionBit - 1)) % 2 === 1;
}

/**
 * Decodes one encounter's _data blob. durationMs is the encounter duration
 * from the wire meta — the permille time base for the effect sections.
 */
export function decodeEncounter(
  dataBytes: Uint8Array,
  registry: WireRegistry,
  durationMs: number,
): DecodedEncounter {
  const r = new BitReader(dataBytes);

  const mask = r.readUInt(24);
  const align = (): void => r.alignToByte();

  const result: DecodedEncounter = {
    damageByUnitId: {},
    damageByUnitIdGroup: {},
    damageTakenByUnitId: {},
    healingStats: makeEmptyHealingStats(),
    procs: [],
    unitNames: {},
  };

  if (hasSection(mask, SECTION.DAMAGE)) {
    result.damageByUnitId = readDamageMapWire(r, registry);
    align();
  }

  if (hasSection(mask, SECTION.DAMAGE_GROUP)) {
    result.damageByUnitIdGroup = readDamageMapWire(r, registry);
    align();
  }

  if (hasSection(mask, SECTION.DAMAGE_TAKEN)) {
    result.damageTakenByUnitId = readDamageMapWire(r, registry);
    align();
  }

  if (hasSection(mask, SECTION.HEALING)) {
    result.healingStats = readHealingStats(r, registry);
    align();
  }

  if (hasSection(mask, SECTION.PROCS)) {
    result.procs = readProcs(r, registry);
    align();
  }

  if (hasSection(mask, SECTION.EFFECTS_PLAYER)) {
    const effects = readEffectsOnPlayerWire(r, registry, durationMs);
    if (effects) result.effectsOnPlayer = effects;
    align();
  }
  if (hasSection(mask, SECTION.EFFECTS_BOSSES)) {
    const effects = readEffectsByNameWire(r, registry, durationMs);
    if (effects) result.effectsOnBosses = effects;
    align();
  }
  if (hasSection(mask, SECTION.EFFECTS_GROUP)) {
    const effects = readEffectsByNameWire(r, registry, durationMs);
    if (effects) result.effectsOnGroup = effects;
    align();
  }
  if (hasSection(mask, SECTION.BOSS_NAMES)) {
    const names = readBossNames(r, registry);
    if (names) result.bossNames = names;
    align();
  }

  if (hasSection(mask, SECTION.PLAYER_ALIVE_TIME)) {
    result.playerAliveTimeMs = r.readVarUInt();
  }

  if (hasSection(mask, SECTION.UNIT_ALIVE_TIMES)) {
    const times = readUnitAliveTimes(r, registry);
    if (times) result.unitAliveTimeMs = times;
    align();
  }

  if (hasSection(mask, SECTION.UNIT_NAMES)) {
    result.unitNames = readUnitNames(r, registry);
    align();
  }

  if (hasSection(mask, SECTION.DEATHS)) {
    result.deaths = readDeaths(r, registry);
    align();
  }

  if (hasSection(mask, SECTION.SETUP)) {
    // Export streams strip the setup section (the build travels as the
    // wire-level compact struct); a present section means a broken stream
    throw new Error("export stream contains an in-blob setup section");
  }

  if (hasSection(mask, SECTION.WEAVING)) {
    const weaving: WeavingData = {
      lightAttackHits: r.readVarUInt(),
      heavyAttackHits: r.readVarUInt(),
      skillActivations: r.readVarUInt(),
      totalWeavingErrors: r.readVarUInt(),
      doubleLaErrors: r.readVarUInt(),
      downtimeMs: r.readVarUInt(),
      downtimeGaps: r.readVarUInt(),
      byAbility: [],
    };
    const abilityCount = readMapCount(r);
    for (let i = 0; i < abilityCount; i++) {
      weaving.byAbility.push({
        abilityId: readAbilityRef(r, registry),
        activations: r.readVarUInt(),
        afterSum: r.readZigZag(),
        afterCount: r.readVarUInt(),
        beforeSum: r.readZigZag(),
        beforeCount: r.readVarUInt(),
        weavingErrors: r.readVarUInt(),
      });
    }
    result.weaving = weaving;
    align();
  }

  if (hasSection(mask, SECTION.ULTIMATE)) {
    result.ultimate = readUltimate(r, registry);
    align();
  }

  if (hasSection(mask, SECTION.RESURRECTIONS)) {
    result.resurrections = r.readVarUInt();
    const logCount = readMapCount(r);
    if (logCount > 0) {
      const log: ResurrectionEvent[] = [];
      let prevTimeMs = 0;
      for (let i = 0; i < logCount; i++) {
        const displayName = readNameRef(r, registry);
        prevTimeMs += r.readVarUInt();
        log.push({ displayName, timeMs: prevTimeMs });
      }
      result.resurrectionLog = log;
    }
    align();
  }

  if (hasSection(mask, SECTION.CRUX)) {
    result.crux = readCrux(r, registry);
    align();
  }

  if (hasSection(mask, SECTION.ZEN)) {
    result.zen = readZen(r, registry);
    align();
  }

  return result;
}

// ============================================================================
// WIRE SETUP (compact struct replacing the bit-packed setup blob)
// ============================================================================

function readWireBar(r: ByteReader): WireBarSlot[] {
  const bar: WireBarSlot[] = [];
  for (let i = 0; i < 6; i++) {
    const abilityId = r.varint();
    if (r.u8() === 1) {
      const craftedAbilityId = r.varint();
      const scriptIds: [number, number, number] = [r.varint(), r.varint(), r.varint()];
      bar.push({ abilityId, craftedAbilityId, scriptIds });
    } else {
      bar.push({ abilityId });
    }
  }
  return bar;
}

function readWireSetup(r: ByteReader): WireSetup | null {
  if (r.u8() !== 1) return null;
  const flags = r.u8();
  const setup: WireSetup = {
    frontBarDisabled: (flags & 4) === 4,
    backBarDisabled: (flags & 8) === 8,
    raceId: r.varint(),
    classId: r.varint(),
    abilities: {},
    champion: [],
    classSkillLineIds: [],
    equipSlots: [],
  };
  if ((flags & 1) === 1) setup.isVengeance = true;
  if ((flags & 2) === 2) setup.werewolfEntireFight = true;

  const barMask = r.u8();
  if (barMask & 1) setup.abilities.front = readWireBar(r);
  if (barMask & 2) setup.abilities.back = readWireBar(r);
  if (barMask & 4) setup.werewolfAbilities = readWireBar(r);

  const championCount = r.varint();
  for (let i = 0; i < championCount; i++) {
    setup.champion.push({ skillId: r.varint(), disciplineId: r.varint() });
  }

  const mundusCount = r.varint();
  if (mundusCount > 0) {
    setup.mundusAbilityIds = [];
    for (let i = 0; i < mundusCount; i++) setup.mundusAbilityIds.push(r.varint());
  }

  const foodCount = r.varint();
  if (foodCount > 0) {
    setup.foods = [];
    for (let i = 0; i < foodCount; i++) {
      const abilityId = r.varint();
      const packed = r.varint();
      const food: WireFood = { abilityId };
      if (packed > 0) food.uptimeMs = packed - 1;
      setup.foods.push(food);
    }
  }

  const lineCount = r.varint();
  for (let i = 0; i < lineCount; i++) setup.classSkillLineIds.push(r.varint());

  const masteryCount = r.varint();
  if (masteryCount > 0) {
    setup.classMasteryAbilityIds = [];
    for (let i = 0; i < masteryCount; i++) setup.classMasteryAbilityIds.push(r.varint());
  }

  const equipCount = r.varint();
  for (let i = 0; i < equipCount; i++) {
    setup.equipSlots.push({
      slotIndex: r.u8(),
      itemId: r.varint(),
      traitType: r.varint() - 1,
      enchantId: r.varint(),
      quality: r.varint(),
    });
  }

  const poisonMask = r.u8();
  if (poisonMask & 1) setup.frontPoisonItemId = r.varint();
  if (poisonMask & 2) setup.backPoisonItemId = r.varint();

  if (setup.isVengeance) {
    setup.weaponTypes = [r.varint(), r.varint(), r.varint(), r.varint()];
    const loadout = r.varint();
    if (loadout > 0) setup.loadoutSkillLineId = loadout;
    setup.vengeancePerkDefIds = [r.varint(), r.varint(), r.varint()];
  }

  return setup;
}

// ============================================================================
// MEMBER SETUP (CompactSetup mirror; see export.lua header for the layout)
// ============================================================================

function readGroupedCounts(r: ByteReader): MemberGroupedCount[] {
  const result: MemberGroupedCount[] = [];
  const count = r.varint();
  for (let i = 0; i < count; i++) {
    result.push({ id: r.varint(), count: r.varint() });
  }
  return result;
}

function readIdList(r: ByteReader): number[] {
  const result: number[] = [];
  const count = r.varint();
  for (let i = 0; i < count; i++) {
    result.push(r.varint());
  }
  return result;
}

function readMemberBar(r: ByteReader): number[] {
  const bar: number[] = [];
  for (let i = 0; i < 6; i++) {
    bar.push(r.varint());
  }
  return bar;
}

function readMemberSetup(r: ByteReader): MemberSetup {
  const flags = r.u8();
  const setup: MemberSetup = {
    isVengeance: (flags & 1) === 1,
    raceId: r.varint(),
    classId: r.varint(),
    sets: [],
    armorWeights: [0, 0, 0],
    weaponTypes: [0, 0, 0, 0],
    armorTraits: [],
    armorEnchants: [],
    jewelryTraits: [],
    jewelryEnchants: [],
    weaponTraits: [0, 0, 0, 0],
    weaponEnchants: [0, 0, 0, 0],
    champion: [],
    foodAbilityIds: [],
    mundusAbilityIds: [],
    classSkillLineIds: [],
    scribedAbilities: [],
  };
  if (flags & 2) setup.frontAbilities = readMemberBar(r);
  if (flags & 4) setup.backAbilities = readMemberBar(r);
  if (flags & 8) setup.werewolfAbilities = readMemberBar(r);

  const setCount = r.varint();
  for (let i = 0; i < setCount; i++) {
    setup.sets.push({ setId: r.varint(), frontCount: r.varint(), backCount: r.varint() });
  }
  setup.armorWeights = [r.varint(), r.varint(), r.varint()];
  setup.weaponTypes = [r.varint(), r.varint(), r.varint(), r.varint()];
  setup.armorTraits = readGroupedCounts(r);
  setup.armorEnchants = readGroupedCounts(r);
  setup.jewelryTraits = readGroupedCounts(r);
  setup.jewelryEnchants = readGroupedCounts(r);
  setup.weaponTraits = [r.varint(), r.varint(), r.varint(), r.varint()];
  setup.weaponEnchants = [r.varint(), r.varint(), r.varint(), r.varint()];
  for (let i = 0; i < 12; i++) {
    setup.champion.push(r.varint());
  }
  setup.foodAbilityIds = readIdList(r);
  setup.mundusAbilityIds = readIdList(r);
  setup.classSkillLineIds = readIdList(r);
  if (flags & 16) setup.classMasteryAbilityIds = readIdList(r);

  const scribedCount = r.varint();
  for (let i = 0; i < scribedCount; i++) {
    setup.scribedAbilities.push({
      abilityId: r.varint(),
      scriptIds: [r.varint(), r.varint(), r.varint()],
    });
  }

  const poisonMask = r.u8();
  if (poisonMask & 1) setup.frontPoisonItemId = r.varint();
  if (poisonMask & 2) setup.backPoisonItemId = r.varint();
  if (poisonMask & 4) setup.frontPoisonEffect = r.varint();
  if (poisonMask & 8) setup.backPoisonEffect = r.varint();

  if (setup.isVengeance) {
    setup.loadoutSkillLineId = r.varint();
    setup.vengeancePerkDefIds = [r.varint(), r.varint(), r.varint()];
  }
  return setup;
}

// ============================================================================
// WIRE STREAM
// ============================================================================

async function inflateRaw(bytes: Uint8Array): Promise<Uint8Array> {
  const ds = new DecompressionStream("deflate-raw");
  // Two libs type Blob here (DOM for the client bundle, @cloudflare/workers-types
  // for the worker); a non-shared ArrayBufferView is the blob part both accept.
  const stream = new Blob([bytes as ArrayBufferView<ArrayBuffer>]).stream().pipeThrough(ds);
  const reader = stream.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > MAX_EXPORT_BYTES) {
        await reader.cancel();
        throw new Error("payload too large");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const body = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return body;
}

/**
 * Parses an export stream (the bytes carried by the share URL / stored blob).
 * Encounter payloads stay as raw bytes; call decodeEncounter/decodeSharedEntry
 * per encounter (the viewer decodes lazily).
 */
export async function parseExportStream(bytes: Uint8Array): Promise<ExportStream> {
  if (bytes.length > MAX_EXPORT_BYTES) {
    throw new Error("payload too large");
  }
  if (bytes.length < 2) {
    throw new Error("export stream too short");
  }
  const version = bytes[0] as number;
  if (version !== WIRE_VERSION) {
    throw new Error(`Unsupported wire version: ${version}`);
  }
  const flags = bytes[1] as number;
  let body = bytes.subarray(2);
  if (flags & FLAG_DEFLATE) {
    body = await inflateRaw(body);
  }

  const r = new ByteReader(body);
  const createdAtS = r.varint();
  const platformCode = r.u8();
  const platform = ({ 1: "pc", 2: "xbox", 3: "playstation" } as const)[platformCode as 1 | 2 | 3];
  if (!platform) throw new Error("invalid share platform");
  const worldName = r.string();
  if (!worldName || worldName.length > 100) throw new Error("invalid share world");
  const instanceName = r.string();
  const instanceTimestampS = r.varint();
  const instanceFlags = r.u8();

  const abilityIds: number[] = [];
  const abilityCount = r.varint();
  for (let i = 0; i < abilityCount; i++) {
    abilityIds.push(r.varint());
  }
  // Per-ability empirical facts, scoped to this share: a delivery-flags byte
  // plus a 16-bit mask of every damage type recorded in combat. Sparse:
  // only the nonzero rows ship, delta-indexed (first row absolute, then gaps).
  const facts: Record<number, AbilityFacts> = {};
  const presentCount = r.varint();
  let factIndex = 0;
  for (let i = 0; i < presentCount; i++) {
    factIndex += r.varint();
    const delivery = r.u8();
    const mask = r.u8() + r.u8() * 256;
    if (delivery === 0 && mask === 0) continue;
    const f: AbilityFacts = {};
    if (delivery & 1) f.direct = true;
    if (delivery & 2) f.overTime = true;
    if (delivery & 4) f.shield = true;
    if (delivery & 8) f.regen = true;
    if (delivery & 16) f.healAbsorption = true;
    if (mask !== 0) {
      const types: number[] = [];
      for (let t = 0; t <= 15; t++) {
        if (mask & (1 << t)) types.push(t);
      }
      f.damageTypes = types;
    }
    const abilityId = abilityIds[factIndex];
    if (abilityId === undefined) {
      throw new Error(`Corrupt facts registry reference: ${factIndex}`);
    }
    facts[abilityId] = f;
  }
  const names: string[] = [];
  const nameCount = r.varint();
  for (let i = 0; i < nameCount; i++) {
    names.push(r.string());
  }
  const registry: WireRegistry = { abilityIds, names, facts };

  const memberSetups: MemberSetup[] = [];
  const memberSetupCount = r.varint();
  for (let i = 0; i < memberSetupCount; i++) {
    memberSetups.push(readMemberSetup(r));
  }

  const encounters: WireEncounter[] = [];
  const encounterCount = r.varint();
  for (let i = 0; i < encounterCount; i++) {
    const metaFlags = r.u8();
    const encounter: WireEncounter = {
      isBoss: (metaFlags & 1) === 1,
      isPlayerFight: (metaFlags & 2) === 2,
      isDummyFight: (metaFlags & 4) === 4,
      displayName: r.string(),
      gameVersion: r.string(),
      timestampS: r.varint(),
      durationMs: r.varint(),
      playerUnitId: 0,
      bossesUnits: [],
      bossTagSeqByUnitId: {},
      bossSeqNames: {},
      dataBytes: new Uint8Array(0),
      shared: [],
      setup: null,
    };
    encounter.playerUnitId = r.varint();
    const bossUnitCount = r.varint();
    for (let b = 0; b < bossUnitCount; b++) {
      encounter.bossesUnits.push(r.varint());
    }
    const tagSeqCount = r.varint();
    for (let b = 0; b < tagSeqCount; b++) {
      const unitId = r.varint();
      encounter.bossTagSeqByUnitId[unitId] = r.string();
    }
    const seqNameCount = r.varint();
    for (let b = 0; b < seqNameCount; b++) {
      const key = r.string();
      encounter.bossSeqNames[key] = r.string();
    }
    encounter.dataBytes = r.slice(r.varint());
    const sharedCount = r.varint();
    for (let j = 0; j < sharedCount; j++) {
      // Entry flags: bit0 = the uploader's own entry; bit1 = an explicit
      // payloadVersion varint follows (absent = the build's storage version)
      const entryFlags = r.u8();
      const nameIndex = r.varint();
      const displayName = names[nameIndex];
      if (displayName === undefined) {
        throw new Error(`Corrupt shared name reference: ${nameIndex}`);
      }
      const role = r.varint();
      const payloadVersion = (entryFlags & 2) === 2 ? r.varint() : STORAGE_VERSION;
      const entry: WireSharedEntry = {
        isSelf: (entryFlags & 1) === 1,
        displayName,
        role,
        payloadVersion,
        timestampS: encounter.timestampS + r.zigzag(),
        durationMs: encounter.durationMs + r.zigzag(),
        payloadBytes: new Uint8Array(0),
      };
      const setupRef = r.varint();
      if (setupRef > 0) {
        const memberSetup = memberSetups[setupRef - 1];
        if (memberSetup === undefined) {
          throw new Error(`Corrupt member setup reference: ${setupRef}`);
        }
        entry.memberSetup = memberSetup;
      }
      entry.payloadBytes = r.slice(r.varint());
      encounter.shared.push(entry);
    }
    encounter.setup = readWireSetup(r);
    encounters.push(encounter);
  }

  if (!r.atEnd) {
    throw new Error("export stream has trailing bytes");
  }

  return {
    profile: flags & FLAG_ARCHIVE ? "archive" : "view",
    createdAtS,
    platform,
    worldName,
    instanceName,
    instanceTimestampS,
    isOverland: (instanceFlags & 1) === 1,
    isHouse: (instanceFlags & 2) === 2,
    isPvP: (instanceFlags & 4) === 4,
    isAdventureZone: (instanceFlags & 8) === 8,
    registry,
    memberSetups,
    encounters,
  };
}

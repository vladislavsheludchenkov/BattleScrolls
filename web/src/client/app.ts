// Viewer application shell: share loading, navigation state (desktop sidebar +
// mobile drill-in), inline details, QR overlay, pinned effects.
import qrcode from "qrcode-generator";
import { parseExportStream, decodeEncounter, decodeSharedEntry } from "../shared/decoder";
import { privacyLink } from "./privacy-link";
import { iconCredit } from "./icon-credit";
import { ICON_DONORS, NAME_DONORS, LOCALIZED_NAME_DONORS } from "../shared/icon_overrides";
import { isScribedRecipe, scribingKey } from "../shared/scribing";
import type { ScribedAbility, ScribedRecipe } from "../shared/scribing";
import type {
  DecodedEncounter, DecodedSharedEntry, ExportStream,
  WireEncounter, WireSharedEntry,
} from "../shared/decoder";
import {
  NAV_GROUPS, tabFilters, groupSortState,
  openFilterPanels, toggleFilterGroup, resetFilters, applyFilterOnly, removeFilterKey,
  clearUnitFilters, healingBases, CRUX_ZERO_ONLY_SOURCES,
} from "./tabs";
import type {
  AbilityInfo, ChampionInfo, DefsStore, DefValue, FilterAxis, ItemInfo,
  NavGroup, NavSub, RenderCtx, TabResult,
} from "./tabs";
import {
  fmtDuration, fmtDay, fmtTime, fmtNumber,
  escapeHtml, csvCell, downloadFile,
} from "./format";
import { t, setLang } from "./strings";
import { buildRoute, currentHash, navigate, onRouteChange } from "./router";
import type { RouteState } from "./router";

const root = document.getElementById("app")!;
const shareId = location.pathname.split("/").pop()!;
const mobileQuery = window.matchMedia("(max-width: 820px)");

// ESO's Language.2 codes; anything unmapped falls back to English server-side
const ESO_LANGS: Record<string, string> = { en: "en", de: "de", fr: "fr", ru: "ru", es: "es", zh: "zh", ja: "jp" };
const LANG_NAMES: Record<string, string> = {
  en: "English", de: "Deutsch", es: "Español", fr: "Français",
  jp: "日本語", ru: "Русский", zh: "中文",
};
const LANG_KEY = "bs-lang";
const PINS_KEY = "bs-pins";
// An explicit choice (stored) beats the link's ?l= (the sharer's game
// language), which beats the system language
const linkLang = new URLSearchParams(location.search).get("l");
const storedLang = localStorage.getItem(LANG_KEY);
let LANG = storedLang && LANG_NAMES[storedLang]
  ? storedLang
  : (linkLang && LANG_NAMES[linkLang] ? linkLang
    : ESO_LANGS[(navigator.language || "en").slice(0, 2)] || "en");
setLang(LANG);
document.title = t("app_name");

let namesGeneration = 0;

function setLanguage(lang: string): void {
  if (!LANG_NAMES[lang] || lang === LANG) return;
  namesGeneration++;
  localStorage.setItem(LANG_KEY, lang);
  LANG = lang;
  setLang(lang);
  document.title = t("app_name");
  syncLangParam();
  state.names = {};
  state.itemNames = {};
  state.championNames = {};
  state.scribing = {};
  requestedScribing.clear();
  state.defs = { set: {}, script: {}, perk: {}, skillline: {}, enchant: {}, trait: {} };
  requestedItemIds.clear();
  requestedChampionIds.clear();
  requestedAbilityIds.clear();
  knownAbilityIds.clear();
  for (const set of Object.values(requestedDefIds)) set.clear();
  loadRegistryNames();
  loadViewData();
  render();
}

// Keep ?l= in the address bar equal to what's displayed, so a copied URL or
// QR reproduces the exact view, language included. replaceState never reloads.
function syncLangParam(): void {
  const url = new URL(location.href);
  if (url.searchParams.get("l") === LANG) return;
  url.searchParams.set("l", LANG);
  history.replaceState(null, "", url);
}

function loadPins(): Set<number> {
  try {
    const stored: unknown = JSON.parse(localStorage.getItem(PINS_KEY) || "[]");
    return new Set<number>(Array.isArray(stored) ? (stored as unknown[]).map(Number) : []);
  } catch {
    return new Set<number>();
  }
}

interface AppState {
  /** null only until boot() has parsed the share; every consumer runs after */
  wire: ExportStream | null;
  names: Record<number, AbilityInfo>;
  itemNames: Record<number, ItemInfo>;
  championNames: Record<number, ChampionInfo>;
  view: "list" | "menu" | "enc";
  encounterIdx: number | null;
  groupId: string;
  subIds: Record<string, string>;
  decodedCache: Map<WireEncounter, DecodedEncounter>;
  sharedCache: Map<WireSharedEntry, DecodedSharedEntry>;
  listDps: Map<WireEncounter, number>;
  pins: Set<number>;
  defs: DefsStore;
  scribing: Record<string, ScribedAbility>;
}

const state: AppState = {
  wire: null,
  names: {},           // abilityId -> {name, icon, iconUrl, tooltip}
  itemNames: {},       // itemId -> {name, icon, iconUrl, ...}
  championNames: {},   // champion skillId -> {name, disciplineId, tooltip}
  view: "list",        // "list" | "menu" (mobile drill-in) | "enc"
  encounterIdx: null,
  groupId: "overview",
  subIds: {},          // groupId -> last active sub id
  decodedCache: new Map(),  // wireEnc -> decoded
  sharedCache: new Map(),   // wire shared entry -> decoded entry
  listDps: new Map(),       // wireEnc -> personal dps (encounter list column)
  pins: loadPins(),
  defs: { set: {}, script: {}, perk: {}, skillline: {}, enchant: {}, trait: {} },
  scribing: {},
};

function decodedFor(wireEnc: WireEncounter): DecodedEncounter {
  let d = state.decodedCache.get(wireEnc);
  if (!d) {
    d = decodeEncounter(wireEnc.dataBytes, state.wire!.registry, wireEnc.durationMs);
    state.decodedCache.set(wireEnc, d);
    for (const s of wireEnc.shared) {
      state.sharedCache.set(s, decodeSharedEntry(s.payloadBytes, s));
    }
  }
  return d;
}

function buildCtx(wireEnc: WireEncounter): RenderCtx {
  const decoded = decodedFor(wireEnc);
  return {
    wireEnc,
    decoded,
    names: state.names,
    knownAbilityIds,
    itemNames: state.itemNames,
    championNames: state.championNames,
    durationMs: wireEnc.durationMs,
    bossUnits: new Set(wireEnc.bossesUnits || []),
    sharedDecoded: state.sharedCache,
    share: state.wire!,
    pins: state.pins,
    defs: state.defs,
    scribing: state.scribing,
  };
}

// Item/champion/ability names referenced only by setups (bars, mundus, food —
// the sharer's own full setup AND group members' broadcast build summaries)
// load lazily when navigating to an encounter: setups ship raw ids outside the
// combat registry, so slotted-but-never-cast abilities aren't covered by the
// registry lookup. Sets/scripts/perks/skill lines resolve via the defs store.
async function loadSetupNames(wireEnc: WireEncounter): Promise<void> {
  const generation = namesGeneration;
  const itemIds: number[] = [];
  const championIds: number[] = [];
  const abilityIds: number[] = [];
  const defIds: Record<keyof DefsStore, number[]> = {
    set: [], script: [], perk: [], skillline: [], enchant: [], trait: [],
  };

  const setup = wireEnc.setup;
  if (setup) {
    itemIds.push(...(setup.equipSlots || []).map((slot) => slot.itemId).filter((id) => id > 0));
    defIds.enchant.push(...(setup.equipSlots || []).map((slot) => slot.enchantId));
    defIds.trait.push(...(setup.equipSlots || []).map((slot) => slot.traitType));
    if (setup.frontPoisonItemId) itemIds.push(setup.frontPoisonItemId);
    if (setup.backPoisonItemId) itemIds.push(setup.backPoisonItemId);
    championIds.push(...(setup.champion || []).map((c) => c.skillId));
    for (const bar of [setup.abilities?.front, setup.abilities?.back, setup.werewolfAbilities]) {
      for (const slot of bar || []) {
        if (slot?.abilityId) abilityIds.push(slot.abilityId);
        for (const scriptId of slot?.scriptIds || []) defIds.script.push(scriptId);
      }
    }
    abilityIds.push(...(setup.mundusAbilityIds || []));
    for (const food of setup.foods || []) {
      if (food.abilityId) abilityIds.push(food.abilityId);
    }
    defIds.skillline.push(...(setup.classSkillLineIds || []));
    if (setup.loadoutSkillLineId) defIds.skillline.push(setup.loadoutSkillLineId);
    // Class Mastery passives are plain abilities; the setup tab shows them
    // instead of the skill lines whenever the build has any
    abilityIds.push(...(setup.classMasteryAbilityIds || []));
    defIds.perk.push(...(setup.vengeancePerkDefIds || []));
  }

  // Crux conditional sources are display ids shipped raw, outside the combat
  // registry - without them those rows render as "#id".
  const crux = decodedFor(wireEnc).crux;
  if (crux) {
    abilityIds.push(
      ...Object.keys(crux.conditionalGains).map(Number),
      ...Object.keys(crux.conditionalWasted).map(Number),
      ...CRUX_ZERO_ONLY_SOURCES,
    );
  }

  // Shared combat payloads carry raw ability ids outside the combat
  // registry: a member's top incoming abilities and death-recap attacks may
  // never appear in the uploader's own recording. decodedFor above also
  // decodes every shared entry.
  for (const entry of wireEnc.shared) {
    const dec = state.sharedCache.get(entry);
    if (!dec) continue;
    abilityIds.push(...dec.data.topDamageTakenAbilities.map((a) => a.abilityId));
    const deaths = dec.data.deaths;
    for (const recap of [deaths?.first, deaths?.last]) {
      if (recap) abilityIds.push(...recap.attacks.map((a) => a.abilityId));
    }
  }

  for (const entry of wireEnc.shared) {
    const m = entry.memberSetup;
    if (!m) continue;
    for (const bar of [m.frontAbilities, m.backAbilities, m.werewolfAbilities]) {
      abilityIds.push(...(bar || []));
    }
    abilityIds.push(...m.foodAbilityIds, ...m.mundusAbilityIds);
    championIds.push(...m.champion.filter((id) => id > 0));
    if (m.frontPoisonItemId) itemIds.push(m.frontPoisonItemId);
    if (m.backPoisonItemId) itemIds.push(m.backPoisonItemId);
    defIds.set.push(...m.sets.map((s) => s.setId));
    defIds.enchant.push(
      ...m.armorEnchants.map((e) => e.id),
      ...m.jewelryEnchants.map((e) => e.id),
      ...m.weaponEnchants,
    );
    defIds.trait.push(
      ...m.armorTraits.map((e) => e.id),
      ...m.jewelryTraits.map((e) => e.id),
      ...m.weaponTraits,
    );
    for (const scribed of m.scribedAbilities) {
      abilityIds.push(scribed.abilityId);
      defIds.script.push(...scribed.scriptIds);
    }
    defIds.skillline.push(...m.classSkillLineIds);
    abilityIds.push(...(m.classMasteryAbilityIds || []));
    if (m.loadoutSkillLineId) defIds.skillline.push(m.loadoutSkillLineId);
    defIds.perk.push(...(m.vengeancePerkDefIds || []));
  }

  const results = await Promise.all([
    loadItemNames(itemIds),
    loadChampionNames(championIds),
    loadAbilityNames(abilityIds.filter((id) => id > 0)),
    ...(Object.keys(defIds) as Array<keyof DefsStore>).map((kind) => loadDefs(kind, defIds[kind])),
  ]);
  if (generation !== namesGeneration) return;
  if (results.some(Boolean)) render();
  // Set ids come from item rows; scribing recipes may need an ability's
  // craftedAbilityId. The first phase awaits shared in-flight lookups too.
  const changed = await Promise.all([loadItemSetDefs(), loadScribing(wireEnc)]);
  if (generation === namesGeneration && changed.some(Boolean)) render();
}

function loadRegistryNames(): void {
  const generation = namesGeneration;
  const registry = state.wire!.registry;
  for (const id of Object.keys(registry.facts || {})) {
    state.names[Number(id)] = applyShareFacts(Number(id), {});
  }
  void loadAbilityNames(registry.abilityIds).then((changed) => {
    if (generation === namesGeneration && changed) render();
  });
}

// Called by navigation and language changes, never by a data-arrival repaint.
function loadViewData(): void {
  if (state.view === "list" || state.encounterIdx === null) {
    ensureListDps();
  } else {
    void loadSetupNames(state.wire!.encounters[state.encounterIdx]!);
  }
}

// The share's own empirical facts (wire) override the DB's global
// classification: they're scoped to exactly this export's combat data.
function applyShareFacts(id: number, info: AbilityInfo): AbilityInfo {
  const f = state.wire?.registry?.facts?.[id];
  if (f) info.mech = { ...(info.mech || {}), ...f };
  return info;
}

function iconUrlFor(iconPath: string | undefined): string | null {
  if (typeof iconPath !== "string" || !iconPath.startsWith("/esoui/")) return null;
  return "/icons" + iconPath.replace(/\.dds$/, ".png");
}

/** Include the localized skill metadata used by static display overrides. */
function withAbilityDonors(ids: number[]): number[] {
  const out = new Set(ids);
  for (const id of ids) {
    const iconDonor = ICON_DONORS[id];
    const nameDonor = LOCALIZED_NAME_DONORS[id]?.[LANG] ?? NAME_DONORS[id];
    if (iconDonor != null) out.add(iconDonor);
    if (nameDonor != null) out.add(nameDonor);
  }
  return [...out];
}

// Dependent loads must wait for a lookup already started by another encounter
// (or the combat registry). null marks a completed attempt, including failures.
const requestedItemIds = new Map<number, Promise<boolean> | null>();
const requestedChampionIds = new Set<number>();
const requestedAbilityIds = new Map<number, Promise<boolean> | null>();
const requestedScribing = new Set<string>();

async function loadOnce(
  ids: number[], requests: Map<number, Promise<boolean> | null>,
  load: (fresh: number[]) => Promise<boolean>,
): Promise<boolean> {
  const unique = [...new Set(ids)];
  const pending = new Set(unique.map((id) => requests.get(id))
    .filter((request): request is Promise<boolean> => request != null));
  const fresh = unique.filter((id) => !requests.has(id));
  if (fresh.length > 0) {
    const request = load(fresh).finally(() => {
      for (const id of fresh) {
        // A language change may have replaced this id's request meanwhile.
        if (requests.get(id) === request) requests.set(id, null);
      }
    });
    fresh.forEach((id) => requests.set(id, request));
    pending.add(request);
  }
  return (await Promise.all(pending)).some(Boolean);
}

async function loadScribing(wireEnc: WireEncounter): Promise<boolean> {
  const generation = namesGeneration;
  const recipes = new Map<string, ScribedRecipe>();
  const add = (abilityId: number, scriptIds: number[] | undefined, classId: number, craftedAbilityId?: number): void => {
    const recipe = { craftedAbilityId: craftedAbilityId || state.names[abilityId]?.craftedAbilityId, scriptIds, classId };
    if (isScribedRecipe(recipe)) recipes.set(scribingKey(recipe), recipe);
  };
  const setup = wireEnc.setup;
  if (setup) {
    for (const bar of [setup.abilities?.front, setup.abilities?.back, setup.werewolfAbilities]) {
      for (const slot of bar || []) add(slot.abilityId, slot.scriptIds, setup.classId, slot.craftedAbilityId);
    }
  }
  for (const entry of wireEnc.shared) {
    if (entry.memberSetup) for (const slot of entry.memberSetup.scribedAbilities) {
      add(slot.abilityId, slot.scriptIds, entry.memberSetup.classId);
    }
  }
  const fresh = [...recipes.entries()].filter(([key]) => !requestedScribing.has(key));
  if (!fresh.length) return false;
  fresh.forEach(([key]) => requestedScribing.add(key));
  const lang = LANG;
  let changed = false;
  for (let i = 0; i < fresh.length; i += 50) {
    if (generation !== namesGeneration) return false;
    try {
      const res = await fetch("/api/scribing/lookup", { method: "POST", headers: { "content-type": "application/json" },
        body: JSON.stringify({ lang, recipes: fresh.slice(i, i + 50).map(([, recipe]) => recipe) }) });
      if (res.ok) {
        const body = await res.json() as { abilities: Record<string, ScribedAbility> };
        if (generation !== namesGeneration) return false;
        Object.assign(state.scribing, body.abilities);
        changed = true;
      }
    } catch {
      // Names and individual scripts remain usable without recipe metadata.
    }
  }
  return changed;
}
/**
 * Every ability id this share is known to contain: the combat registry plus
 * every id the setup/member collectors look up (bars, scribed, mastery,
 * mundus, food). The renderers read it to decide whether a name-borrowed
 * tooltip is exact - a donor that appears in this very share describes the
 * same skill someone slotted - so it must span all batches, which arrive
 * separately, and it is cleared with the other caches.
 */
const knownAbilityIds = new Set<number>();
const requestedDefIds: Record<keyof DefsStore, Set<number>> = {
  set: new Set(), script: new Set(), perk: new Set(), skillline: new Set(), enchant: new Set(),
  trait: new Set(),
};

// Set / scribing-script / Vengeance-perk / skill-line names (generic defs store)
async function loadDefs(kind: keyof DefsStore, ids: number[]): Promise<boolean> {
  const generation = namesGeneration;
  const fresh = ids.filter((id) => id > 0 && !requestedDefIds[kind].has(id));
  if (fresh.length === 0) return false;
  fresh.forEach((id) => requestedDefIds[kind].add(id));
  try {
    const res = await fetch("/api/defs/lookup", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ kind, ids: fresh, lang: LANG }),
    });
    if (res.ok) {
      const body = (await res.json()) as { defs: Record<string, DefValue> };
      if (generation !== namesGeneration) return false;
      for (const [id, def] of Object.entries(body.defs)) {
        def.iconUrl = iconUrlFor(def.icon);
        state.defs[kind][Number(id)] = def;
      }
      return true;
    }
  } catch {
    // best effort
  }
  return false;
}

// One lookup cache for combat-registry and supplemental (setup etc.) abilities.
function loadAbilityNames(ids: number[]): Promise<boolean> {
  // Known-set membership is about the share's contents, not about who still
  // needs fetching: record every id, including the ones already cached
  ids.forEach((id) => knownAbilityIds.add(id));
  return loadOnce(ids, requestedAbilityIds, async (fresh) => {
    const generation = namesGeneration;
    try {
      const res = await fetch("/api/abilities/lookup", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ ids: withAbilityDonors(fresh), lang: LANG }),
      });
      if (res.ok) {
        const map = (await res.json()) as Record<string, AbilityInfo>;
        if (generation !== namesGeneration) return false;
        for (const [id, info] of Object.entries(map)) {
          info.iconUrl = iconUrlFor(info.icon);
          state.names[Number(id)] = applyShareFacts(Number(id), info);
        }
        return true;
      }
    } catch {
      // best effort
    }
    return false;
  });
}

async function loadChampionNames(ids: number[]): Promise<boolean> {
  const generation = namesGeneration;
  const fresh = ids.filter((id) => !requestedChampionIds.has(id));
  if (fresh.length === 0) return false;
  fresh.forEach((id) => requestedChampionIds.add(id));
  try {
    const res = await fetch("/api/champion/lookup", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ ids: fresh, lang: LANG }),
    });
    if (res.ok) {
      const map = (await res.json()) as Record<string, ChampionInfo>;
      if (generation !== namesGeneration) return false;
      for (const [id, info] of Object.entries(map)) {
        state.championNames[Number(id)] = info;
      }
      return true;
    }
  } catch {
    // best effort
  }
  return false;
}

function loadItemNames(ids: number[]): Promise<boolean> {
  return loadOnce(ids, requestedItemIds, async (fresh) => {
    const generation = namesGeneration;
    try {
      const res = await fetch("/api/items/lookup", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ ids: fresh, lang: LANG }),
      });
      if (res.ok) {
        const map = (await res.json()) as Record<string, ItemInfo>;
        if (generation !== namesGeneration) return false;
        for (const [id, info] of Object.entries(map)) {
          info.iconUrl = iconUrlFor(info.icon);
          state.itemNames[Number(id)] = info;
        }
        return true;
      }
    } catch {
      // best effort
    }
    return false;
  });
}

/**
 * Set ids ride on the item rows, so set defs can only be asked for once the
 * item lookup has resolved - a second phase after the first paint. Items whose
 * row predates the set_id column carry null and simply contribute nothing.
 */
async function loadItemSetDefs(): Promise<boolean> {
  const setIds = [...new Set(Object.values(state.itemNames)
    .map((info) => info.setId)
    .filter((id): id is number => typeof id === "number" && id > 0))];
  return setIds.length > 0 ? loadDefs("set", setIds) : false;
}

// ============================================================================
// NAVIGATION MODEL
// ============================================================================

function visibleGroups(ctx: RenderCtx): NavGroup[] {
  return NAV_GROUPS.filter((g) => visibleSubs(g, ctx).length > 0);
}

function visibleSubs(group: NavGroup, ctx: RenderCtx): NavSub[] {
  return group.subs.filter((s) => s.always || (s.show && s.show(ctx)));
}

function activeSub(group: NavGroup, ctx: RenderCtx): NavSub {
  const subs = visibleSubs(group, ctx);
  return subs.find((s) => s.id === state.subIds[group.id]) || subs[0]!;
}

// ============================================================================
// RENDERING
// ============================================================================

function renderBrand(): string {
  return `<span class="brand"><span class="dmd"></span><span class="brand-name">${escapeHtml(t("app_name"))}</span></span>`;
}

interface TopbarOptions {
  exports?: boolean;
}

function renderTopbar(crumbHtml: string, { exports: showExports = false }: TopbarOptions = {}): string {
  const uploader = state.wire?.encounters.flatMap(enc => enc.shared)
    .find(entry => entry.isSelf && entry.displayName !== "")?.displayName;
  const langOptions = Object.entries(LANG_NAMES).map(([code, label]) =>
    `<option value="${code}"${code === LANG ? " selected" : ""}>${label}</option>`
  ).join("");
  const exportChips = showExports
    ? `<button class="chip" data-action="csv">CSV</button>
       <button class="chip" data-action="json">JSON</button>`
    : "";
  return `<div class="topbar">
    <div class="brand-block">
      <button data-action="home" style="display:inline-flex">${renderBrand()}</button>
      ${uploader ? `<span class="uploader">${escapeHtml(t("uploaded_by", uploader))}</span>` : ""}
    </div>
    ${crumbHtml || ""}
    <span class="topbar-actions">
      ${exportChips}
      <button class="chip" data-action="qr">QR</button>
      <select class="chip lang-select" aria-label="Language">${langOptions}</select>
    </span>
  </div>`;
}

function renderFoot(): string {
  return `<div class="foot">
    <span>${escapeHtml(t("footer_share", shareId.toUpperCase(), fmtDay(state.wire?.createdAtS)))}</span>
    ${iconCredit(LANG)}
    ${privacyLink(LANG)}
  </div>`;
}

// ---- encounter list (zone screen) ----

function groupInfo(enc: WireEncounter): string {
  return enc.shared.length ? t("sharing_n", enc.shared.length + 1) : t("solo_data");
}

// "+MM:SS" offset from the run's start; empty when the wire predates the info
function intoRunHtml(enc: WireEncounter): string {
  const start = state.wire!.instanceTimestampS;
  if (!start || enc.timestampS < start) return "";
  return ` · <span>${escapeHtml(t("into_run_tt"))}: ${fmtDuration((enc.timestampS - start) * 1000)}</span>`;
}

function encBadges(enc: WireEncounter): string {
  return (enc.isBoss ? `<span class="badge-boss">${escapeHtml(t("badge_boss"))}</span>` : "")
    + (enc.isPlayerFight ? `<span class="badge-alt">${escapeHtml(t("badge_duel"))}</span>` : "")
    + (enc.isDummyFight ? `<span class="badge-alt">${escapeHtml(t("badge_dummy"))}</span>` : "");
}

function renderList(): string {
  const wire = state.wire!;
  const totalCombatMin = Math.round(wire.encounters.reduce((s, e) => s + e.durationMs, 0) / 60000);
  const meta = [
    wire.profile === "archive" ? t("archive") : t("fight_share"),
    wire.isOverland ? t("inst_overland") : null,
    wire.isHouse ? t("inst_house") : null,
    wire.isPvP ? t("inst_pvp") : null,
    wire.isAdventureZone ? t("inst_adventure") : null,
    t("n_encounters", wire.encounters.length),
    totalCombatMin >= 1 ? t("min_combat", totalCombatMin) : null,
    t("uploaded", fmtDay(wire.createdAtS)),
  ].filter(Boolean).join(" · ");
  const rows = wire.encounters.map((enc, i) => {
    const dps = state.listDps.get(enc);
    const dpsTxt = dps == null ? "…" : fmtNumber(dps);
    return `<button class="tl-row${enc.isBoss ? " boss" : ""}" data-enc="${i}">
      <span class="tl-time">${escapeHtml(fmtTime(enc.timestampS))}</span>
      <span class="tl-node"><span class="tl-mark"></span></span>
      <span style="min-width:0">
        <span class="tl-name">${escapeHtml(enc.displayName)}${encBadges(enc)}</span>
        <span class="tl-sub">${escapeHtml(fmtTime(enc.timestampS))}${intoRunHtml(enc)} · ${fmtDuration(enc.durationMs)} · ${escapeHtml(groupInfo(enc))}</span>
      </span>
      <span class="tl-dps">${dpsTxt}<span class="u">DPS</span></span>
      <span class="tl-dur">${fmtDuration(enc.durationMs)}</span>
      <span class="tl-grp">${escapeHtml(groupInfo(enc))}</span>
    </button>`;
  }).join("");
  return `
    <div class="zone-head">
      <div class="zone-title">${escapeHtml(wire.instanceName || wire.encounters[0]?.displayName || "Shared combat data")}</div>
      <div class="zone-meta"><span class="lab">${escapeHtml(meta)}</span><span class="tail"></span></div>
    </div>
    <div class="timeline">${rows}</div>`;
}

// Fills the per-row DPS column: decodes encounters in small chunks so a large
// archive doesn't block the first paint.
let listStatsRunning = false;
function ensureListDps(): void {
  if (listStatsRunning) return;
  const pending = state.wire!.encounters.filter((e) => !state.listDps.has(e));
  if (pending.length === 0) return;
  listStatsRunning = true;
  const step = (): void => {
    const slice = pending.splice(0, 4);
    for (const enc of slice) {
      let total = 0;
      try {
        const d = decodedFor(enc);
        for (const byTarget of Object.values(d.damageByUnitId || {})) {
          for (const byAbility of Object.values(byTarget)) {
            for (const b of Object.values(byAbility)) total += b.total || 0;
          }
        }
      } catch {
        // corrupt encounter: leave the column empty
      }
      state.listDps.set(enc, enc.durationMs > 0 ? total / (enc.durationMs / 1000) : 0);
    }
    if (pending.length > 0) {
      setTimeout(step, 0);
    } else {
      listStatsRunning = false;
      if (state.view === "list") render();
    }
  };
  setTimeout(step, 0);
}

// ---- mobile drill-in menu ----

function renderMenu(wireEnc: WireEncounter, ctx: RenderCtx): string {
  const groups = visibleGroups(ctx);
  const back = state.wire!.encounters.length > 1
    ? `<button class="m-back" data-action="back" style="display:block;font-family:var(--cond);font-size:12px;letter-spacing:.12em;color:var(--ink-dim);text-transform:uppercase;">${escapeHtml(state.wire!.instanceName ? "‹ " + state.wire!.instanceName : t("back_all"))}</button>`
    : "";
  const rows = groups.map((g) => `
    <button class="menu-row" data-group="${g.id}">
      <span class="n">${escapeHtml(t(g.labelKey))}</span>
      <span class="sub">${escapeHtml(g.menuSub ? g.menuSub(ctx) : "")}</span>
      <span class="arr">›</span>
    </button>`).join("");
  return `
    <div class="zone-head" style="padding-bottom:0">
      ${back}
      <div class="zone-title" style="margin-top:10px">${escapeHtml(wireEnc.displayName)}${encBadges(wireEnc)}</div>
      <div class="zone-meta"><span class="lab">${fmtDuration(wireEnc.durationMs)} · ${escapeHtml(fmtDay(wireEnc.timestampS))}${intoRunHtml(wireEnc)} · ${escapeHtml(groupInfo(wireEnc))}</span></div>
    </div>
    <div class="menu-rows" style="display:block">${rows}</div>`;
}

// ---- encounter view (sidebar + content) ----

function renderEncounter(wireEnc: WireEncounter, ctx: RenderCtx): string {
  const groups = visibleGroups(ctx);
  const group = groups.find((g) => g.id === state.groupId) || groups[0]!;
  state.groupId = group.id;
  const subs = visibleSubs(group, ctx);
  const sub = activeSub(group, ctx);
  state.subIds[group.id] = sub.id;

  const navItems = groups.map((g, i) => `
    <button class="nav-item${g.id === group.id ? " active" : ""}" data-group="${g.id}">
      <span class="nav-key">${i + 1}</span>${escapeHtml(t(g.labelKey))}
    </button>`).join("");
  const backLabel = state.wire!.encounters.length > 1 ? t("back_all") : "";

  const pills = subs.length > 1
    ? `<div class="subtabs">${subs.map((s) =>
        `<button class="pill${s.id === sub.id ? " active" : ""}" data-sub="${s.id}">${escapeHtml(t(s.labelKey))}</button>`
      ).join("")}</div>`
    : "";

  const result = sub.render(ctx);

  const mobileHead = `<div class="m-head">
    <button class="m-back" data-action="back">‹ ${escapeHtml(wireEnc.displayName)}</button>
    <span class="m-title">${escapeHtml(t(group.labelKey))}</span>
  </div>`;

  return `
    ${mobileHead}
    <div class="layout">
      <div class="side">
        ${backLabel ? `<button class="side-back" data-action="back">${escapeHtml(backLabel)}</button>` : ""}
        ${navItems}
      </div>
      <div class="content" style="min-width:0">
        ${pills}
        ${result.html}
      </div>
    </div>`;
}

function crumbFor(wireEnc: WireEncounter): string {
  const zone = state.wire!.instanceName;
  const zonePart = zone && zone !== wireEnc.displayName
    ? `${escapeHtml(zone)} <span class="sep">/</span> ` : "";
  return `<span class="crumb">${zonePart}${escapeHtml(wireEnc.displayName)}
    <span class="sep">·</span> ${fmtDuration(wireEnc.durationMs)}
    <span class="sep">·</span> ${escapeHtml(fmtDay(wireEnc.timestampS))}${intoRunHtml(wireEnc)}</span>`;
}

const disclosureStates = new Map<string, boolean>();
const memberViews = new Map<string, string>();
let renderedScope = "";

function selectMemberView(member: HTMLElement, view: string): void {
  for (const button of member.querySelectorAll<HTMLElement>("[data-member-view]")) {
    button.setAttribute("aria-pressed", String(button.dataset.memberView === view));
  }
  for (const panel of member.querySelectorAll<HTMLElement>("[data-member-panel]")) {
    panel.hidden = panel.dataset.memberPanel !== view;
  }
}

function disclosureKey(node: HTMLDetailsElement): string {
  const summary = node.querySelector(":scope > summary");
  const label = summary?.querySelector(".cell-name")?.textContent || summary?.textContent || "";
  const parent = node.parentElement?.closest<HTMLDetailsElement>("details");
  return (parent ? disclosureKey(parent) + "/" : "") + label.trim();
}

function rememberDisclosures(): void {
  for (const node of root.querySelectorAll<HTMLDetailsElement>("details")) {
    disclosureStates.set(`${renderedScope}|${disclosureKey(node)}`, node.open);
  }
}

function restoreDisclosures(): void {
  renderedScope = `${state.encounterIdx}/${state.groupId}/${state.subIds[state.groupId] || ""}`;
  for (const node of root.querySelectorAll<HTMLDetailsElement>("details")) {
    const remembered = disclosureStates.get(`${renderedScope}|${disclosureKey(node)}`);
    if (remembered !== undefined) node.open = remembered;

  }
  for (const member of root.querySelectorAll<HTMLElement>("[data-member-key]")) {
    selectMemberView(member, memberViews.get(`${renderedScope}|${member.dataset.memberKey}`) || "overview");
  }
}


function render(): void {
  rememberDisclosures();
  const parts: string[] = [];
  let mainHtml = "";
  if (state.view === "list" || state.encounterIdx === null) {
    parts.push(renderTopbar(""));
    mainHtml = renderList();
  } else {
    const wireEnc = state.wire!.encounters[state.encounterIdx]!;
    const ctx = buildCtx(wireEnc);
    if (state.view === "menu") {
      parts.push(renderTopbar(crumbFor(wireEnc)));
      mainHtml = renderMenu(wireEnc, ctx);
    } else {
      parts.push(renderTopbar(crumbFor(wireEnc), { exports: true }));
      mainHtml = renderEncounter(wireEnc, ctx);
    }
  }
  parts.push(`<div class="app-main">${mainHtml}</div>`);
  parts.push(renderFoot());
  root.innerHTML = parts.join("");
  restoreDisclosures();
}

// ============================================================================
// EXPORTS (CSV / JSON)
// ============================================================================

function currentSubResult(): { result: TabResult; wireEnc: WireEncounter } {
  const wireEnc = state.wire!.encounters[state.encounterIdx ?? 0]!;
  const ctx = buildCtx(wireEnc);
  const groups = visibleGroups(ctx);
  const group = groups.find((g) => g.id === state.groupId) || groups[0]!;
  const sub = activeSub(group, ctx);
  return { result: sub.render(ctx), wireEnc };
}

function downloadCsv(): void {
  const { result, wireEnc } = currentSubResult();
  const csv = result.csv.map((row) => row.map(csvCell).join(",")).join("\n");
  const name = `${wireEnc.displayName} - ${result.title}.csv`.replace(/[\\/:]/g, "_");
  downloadFile(name, "text/csv", csv);
}

function downloadJson(): void {
  const wire = state.wire!;
  const wireEnc = wire.encounters[state.encounterIdx ?? 0]!;
  const decoded = decodedFor(wireEnc);
  const payload = {
    displayName: wireEnc.displayName,
    timestampS: wireEnc.timestampS,
    durationMs: wireEnc.durationMs,
    gameVersion: wireEnc.gameVersion,
    isBoss: wireEnc.isBoss,
    isPlayerFight: wireEnc.isPlayerFight,
    isDummyFight: wireEnc.isDummyFight,
    instance: {
      name: wire.instanceName,
      timestampS: wire.instanceTimestampS,
      isOverland: wire.isOverland,
      isHouse: wire.isHouse,
      isPvP: wire.isPvP,
      isAdventureZone: wire.isAdventureZone,
    },
    bossesUnits: wireEnc.bossesUnits,
    bossTagSeqByUnitId: wireEnc.bossTagSeqByUnitId,
    bossSeqNames: wireEnc.bossSeqNames,
    setup: wireEnc.setup,
    data: decoded,
    shared: wireEnc.shared.map((s) => ({
      ...state.sharedCache.get(s),
      memberSetup: s.memberSetup ?? null,
    })),
  };
  const name = `${wireEnc.displayName}.json`.replace(/[\\/:]/g, "_");
  downloadFile(name, "application/json", JSON.stringify(payload, null, 1));
}

// ============================================================================
// QR OVERLAY
// ============================================================================

function showQr(): void {
  // Full href: path + ?l= + hash route — the scan lands on this exact view
  const url = location.href;
  let qrHtml = "";
  try {
    const qr = qrcode(0, "M");
    qr.addData(url);
    qr.make();
    qrHtml = qr.createSvgTag({ cellSize: 5, margin: 0 });
  } catch {
    qrHtml = `<span style="color:#000;font-size:12px">QR unavailable</span>`;
  }
  const overlay = document.createElement("div");
  overlay.className = "overlay";
  overlay.innerHTML = `<div class="overlay-card">
    <div class="sect-head" style="justify-content:center"><span class="dmd sm"></span><span class="lab gold">${escapeHtml(t("qr_scan"))}</span></div>
    <div class="qr-box">${qrHtml}</div>
    <div style="margin-top:16px"><a href="${escapeHtml(url)}">${escapeHtml(url.replace(/^https?:\/\//, ""))}</a></div>
  </div>`;
  overlay.addEventListener("click", () => overlay.remove());
  document.body.appendChild(overlay);
}

// ============================================================================
// EVENTS
// ============================================================================

root.addEventListener("change", (ev) => {
  const target = ev.target as HTMLElement;
  if (target.classList.contains("lang-select")) {
    setLanguage((target as HTMLSelectElement).value);
  }
});

const LIST_ROUTE: RouteState = { view: "list", encounterIdx: 0, groupId: null, subId: null };

function goBack(): void {
  if (state.view === "enc" && mobileQuery.matches && state.encounterIdx !== null) {
    navigate({ view: "menu", encounterIdx: state.encounterIdx, groupId: null, subId: null });
  } else if (state.encounterIdx !== null && state.wire!.encounters.length > 1) {
    navigate(LIST_ROUTE);
  }
  // single-encounter share on desktop: nowhere to go
}

root.addEventListener("click", (ev) => {
  const target = ev.target as Element;
  const memberView = target.closest<HTMLElement>("[data-member-view]");
  if (memberView) {
    const member = memberView.closest<HTMLElement>("[data-member-key]");
    const view = memberView.dataset.memberView;
    if (member && (view === "overview" || view === "build")) {
      memberViews.set(`${renderedScope}|${member.dataset.memberKey}`, view);
      selectMemberView(member, view);
    }
    return;
  }
  const healingBasisBtn = target.closest<HTMLElement>("[data-heal-basis]");
  if (healingBasisBtn) {
    const basis = healingBasisBtn.dataset.healBasis;
    const subId = healingBasisBtn.dataset.healTab;
    if (subId && (basis === "raw" || basis === "real")) {
      healingBases.set(subId, basis);
      render();
      root.querySelector<HTMLElement>(`[data-heal-tab="${subId}"][data-heal-basis="${basis}"]`)?.focus();
    }
    return;
  }
  const encBtn = target.closest<HTMLElement>("[data-enc]");
  if (encBtn) {
    const idx = Number(encBtn.dataset.enc);
    navigate(mobileQuery.matches
      ? { view: "menu", encounterIdx: idx, groupId: null, subId: null }
      : { view: "enc", encounterIdx: idx, groupId: "overview", subId: null });
    return;
  }
  const groupBtn = target.closest<HTMLElement>("[data-group]");
  if (groupBtn) {
    navigate({
      view: "enc", encounterIdx: state.encounterIdx ?? 0,
      groupId: groupBtn.dataset.group!, subId: null,
    });
    return;
  }
  const subBtn = target.closest<HTMLElement>("[data-sub]");
  if (subBtn) {
    navigate({
      view: "enc", encounterIdx: state.encounterIdx ?? 0,
      groupId: state.groupId, subId: subBtn.dataset.sub!,
    });
    return;
  }
  const pinBtn = target.closest<HTMLElement>("[data-pin]");
  if (pinBtn) {
    const id = Number(pinBtn.dataset.pin);
    if (state.pins.has(id)) state.pins.delete(id);
    else state.pins.add(id);
    localStorage.setItem(PINS_KEY, JSON.stringify([...state.pins]));
    render();
    return;
  }
  const sortBtn = target.closest<HTMLElement>("[data-sort]");
  if (sortBtn) {
    const col = sortBtn.dataset.sort!;
    if (groupSortState.col === col) {
      groupSortState.dir = groupSortState.dir === 1 ? -1 : 1;
    } else {
      groupSortState.col = col;
      groupSortState.dir = col === "name" ? 1 : -1;
    }
    render();
    return;
  }
  if (handleFilterClick(target)) return;
  const action = target.closest<HTMLElement>("[data-action]");
  if (action) {
    const act = action.dataset.action;
    if (act === "back") goBack();
    else if (act === "home") {
      if (state.wire!.encounters.length > 1) navigate(LIST_ROUTE);
    }
    else if (act === "csv") downloadCsv();
    else if (act === "json") downloadJson();
    else if (act === "qr") showQr();
  }
});

// Per-tab unit filters (journal parity). Every entry point - the panel's
// checkboxes, a breakdown row, a chip's ×, Reset - mutates the store in
// tabs.ts and re-renders; the filter is read back during render, so the whole
// tab re-scopes at once.
function currentCtx(): RenderCtx | null {
  if (state.view !== "enc" || state.encounterIdx === null || !state.wire) return null;
  const enc = state.wire.encounters[state.encounterIdx];
  return enc ? buildCtx(enc) : null;
}

function filterTarget(el: Element): { subId: string; axis: FilterAxis; key: string } | null {
  const node = el as HTMLElement;
  const subId = node.dataset.filtOnly || node.dataset.filtChip || node.dataset.filtGroup;
  const axis = node.dataset.filtAxis as FilterAxis | undefined;
  const key = node.dataset.filtKey;
  if (!subId || !axis || key === undefined) return null;
  return { subId, axis, key };
}

function handleFilterClick(target: Element): boolean {
  const openBtn = target.closest<HTMLElement>("[data-filt-open]");
  if (openBtn) {
    const subId = openBtn.dataset.filtOpen!;
    if (openFilterPanels.has(subId)) openFilterPanels.delete(subId);
    else openFilterPanels.add(subId);
    render();
    return true;
  }
  const resetBtn = target.closest<HTMLElement>("[data-filt-reset]");
  if (resetBtn) {
    const subId = resetBtn.dataset.filtReset!;
    resetFilters(subId);
    render();
    (root.querySelector<HTMLElement>(`[data-filt-open="${subId}"]`)
      || root.querySelector<HTMLElement>(`[data-filter="${subId}"]`))?.focus();
    return true;
  }
  const ctx = currentCtx();
  if (!ctx) return false;
  const chip = target.closest<HTMLElement>("[data-filt-chip]");
  if (chip) {
    const hit = filterTarget(chip);
    if (hit) {
      removeFilterKey(ctx, hit.subId, hit.axis, hit.key);
      render();
    }
    return true;
  }
  const row = target.closest<HTMLElement>("[data-filt-only]");
  if (row) {
    const hit = filterTarget(row);
    if (hit) {
      applyFilterOnly(ctx, hit.subId, hit.axis, hit.key);
      render();
    }
    return true;
  }
  return false;
}

root.addEventListener("change", (ev) => {
  const select = (ev.target as Element)?.closest<HTMLSelectElement>("[data-group-sort]");
  if (!select) return;
  groupSortState.col = select.value;
  groupSortState.dir = select.value === "name" ? 1 : -1;
  render();
  root.querySelector<HTMLSelectElement>("[data-group-sort]")?.focus();
});

root.addEventListener("change", (ev) => {
  const box = (ev.target as Element | null)?.closest?.("[data-filt-group]");
  if (!box) return;
  const hit = filterTarget(box);
  if (!hit) return;
  const ctx = currentCtx();
  if (!ctx) return;
  toggleFilterGroup(ctx, hit.subId, hit.axis, hit.key);
  render();
});

// Tab-content text filters: tabs.ts renders <input data-filter="<subId>">,
// the store lives in tabs.ts; re-rendering replaces the input node, so focus
// and caret are restored onto its successor.
root.addEventListener("input", (ev) => {
  const el = (ev.target as Element | null)?.closest?.("[data-filter]") as HTMLInputElement | null | undefined;
  if (!el) return;
  const key = el.dataset.filter!;
  tabFilters.set(key, el.value);
  render();
  const restored = root.querySelector<HTMLInputElement>(`[data-filter="${key}"]`);
  if (restored) {
    restored.focus();
    const end = restored.value.length;
    restored.setSelectionRange(end, end);
  }
});

document.addEventListener("keydown", (ev) => {
  const target = ev.target as HTMLElement | null;
  // Filtering has its own native button; row activation opens details.
  if (target?.tagName === "SELECT" || target?.tagName === "INPUT" || target?.tagName === "BUTTON" || target?.tagName === "SUMMARY" || ev.metaKey || ev.ctrlKey || ev.altKey) return;
  if (ev.key === "Escape") {
    goBack();
    return;
  }
  if (state.view !== "enc" || state.encounterIdx === null) return;
  const digit = Number(ev.key);
  if (!Number.isInteger(digit) || digit < 1) return;
  const ctx = buildCtx(state.wire!.encounters[state.encounterIdx]!);
  const groups = visibleGroups(ctx);
  if (digit <= groups.length) {
    navigate({
      view: "enc", encounterIdx: state.encounterIdx,
      groupId: groups[digit - 1]!.id, subId: null,
    });
  }
});

// ============================================================================
// ROUTE -> STATE
// ============================================================================
// The hash is the single navigation source: clicks/keys call navigate(), the
// hashchange handler funnels every change (including back/forward and manual
// edits) through applyRoute, which validates against the loaded wire, commits
// to state, and re-renders. Invalid or partial routes are rewritten in place
// (replace, no history entry) to the canonical form of what actually shows.

let lastRoute: RouteState | null = null;

function applyRoute(route: RouteState): void {
  const wire = state.wire;
  if (!wire) return;
  const hadHash = location.hash !== "";
  const prev = lastRoute;
  lastRoute = route;

  if (route.view === "list") {
    if (wire.encounters.length === 1) {
      // single-encounter shares skip the list entirely
      const target: RouteState = mobileQuery.matches
        ? { view: "menu", encounterIdx: 0, groupId: null, subId: null }
        : { view: "enc", encounterIdx: 0, groupId: state.groupId, subId: null };
      if (hadHash) {
        navigate(target, { replace: true });
        return;
      }
      // pristine URL: show the default view without writing a hash
      state.encounterIdx = 0;
      state.view = target.view;
      loadViewData();
      render();
      return;
    }
    state.view = "list";
    state.encounterIdx = null;
    loadViewData();
    render();
    window.scrollTo(0, 0);
    return;
  }

  if (route.encounterIdx < 0 || route.encounterIdx >= wire.encounters.length) {
    navigate(LIST_ROUTE, { replace: true });
    return;
  }
  // Filters name units of one encounter, so they don't survive a move to
  // another one - the journal likewise rebuilds tab filters per encounter.
  if (state.encounterIdx !== route.encounterIdx) clearUnitFilters();
  state.encounterIdx = route.encounterIdx;

  if (route.view === "menu") {
    // the menu is the mobile drill-in; on desktop the same URL shows the
    // encounter directly (sidebar already exposes every group)
    state.view = mobileQuery.matches ? "menu" : "enc";
    loadViewData();
    render();
    window.scrollTo(0, 0);
    return;
  }

  const wireEnc = wire.encounters[route.encounterIdx]!;
  const ctx = buildCtx(wireEnc);
  const groups = visibleGroups(ctx);
  const group = groups.find((g) => g.id === route.groupId) || groups[0]!;
  const subs = visibleSubs(group, ctx);
  if (route.subId !== null && subs.some((s) => s.id === route.subId)) {
    state.subIds[group.id] = route.subId;
  }
  state.groupId = group.id;
  state.view = "enc";

  // Canonical URL = exactly what renders (fallback group, remembered sub).
  // Rewriting before render keeps this a single-render fixed point.
  const sub = activeSub(group, ctx);
  const canonical: RouteState = {
    view: "enc", encounterIdx: route.encounterIdx, groupId: group.id,
    subId: subs.length > 1 ? sub.id : null,
  };
  if (hadHash && buildRoute(canonical) !== currentHash()) {
    navigate(canonical, { replace: true });
    return;
  }
  loadViewData();
  render();
  const subOnlyChange = prev !== null && prev.view === "enc"
    && prev.encounterIdx === route.encounterIdx && prev.groupId === group.id;
  if (!subOnlyChange) window.scrollTo(0, 0);
}

// ============================================================================
// BOOT
// ============================================================================

async function boot(): Promise<void> {
  try {
    const res = await fetch(`/api/share/${shareId}`);
    if (!res.ok) throw new Error(t("err_missing"));
    const bytes = new Uint8Array(await res.arrayBuffer());
    state.wire = await parseExportStream(bytes);
    syncLangParam();
    loadRegistryNames();
    // Initial render + all subsequent navigation flow through the route
    onRouteChange(applyRoute);
  } catch (e) {
    root.innerHTML = `
      <div class="topbar">${renderBrand()}</div>
      <div class="app-main"><div class="center-page">
        <div class="hero-title">${escapeHtml(t("err_title"))}</div>
        <div class="hero-sub load-error">${escapeHtml((e as Error).message)}</div>
      </div></div>
      <div class="foot">${iconCredit(LANG)}${privacyLink(LANG)}</div>`;
  }
}

boot();

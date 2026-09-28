import { linkedItemIds, plainEsoText } from "./shared/eso_text";
import { isScribedRecipe, scribingKey } from "./shared/scribing";
import type { ScribedAbility, ScribedRecipe } from "./shared/scribing";
// BattleScrolls share worker: receives export streams from the in-game URL
// transport, stores them in D1, and serves the viewer.
import { parseExportStream } from "./shared/decoder";

export interface Env {
  DB: D1Database;
  ICONS: R2Bucket;
  ASSETS: Fetcher;
  IMPORT_TOKEN: string;
}

const MAX_CHUNK_BYTES = 40 * 1024;
const MAX_CHUNKS = 256;
const SESSION_TTL_S = 3600;

const ID_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

// ============================================================================
// D1 ROW SHAPES
// ============================================================================

/** D1 hands BLOB columns back as an ArrayBuffer (older rows: a byte array). */
type D1Blob = ArrayBuffer | number[];

/** Every per-language metadata table is keyed by these two columns. */
interface LangKeyedRow {
  id: number;
  lang: string;
}

interface AbilityRow extends LangKeyedRow {
  name: string;
  icon: string | null;
  tooltip: string | null;
  crafted_ability_id: number | null;
}

/** Rows of the by-name tooltip donor query (which filters tooltip IS NOT NULL). */
interface TooltipDonorRow extends LangKeyedRow {
  name: string;
  tooltip: string;
}

interface ItemRow extends LangKeyedRow {
  name: string;
  icon: string | null;
  set_name: string | null;
  trait: number | null;
  armor_type: number | null;
  weapon_type: number | null;
  equip_type: number | null;
  set_id: number | null;
}

interface ChampionRow extends LangKeyedRow {
  name: string;
  discipline_id: number | null;
  tooltip: string | null;
}

interface DefRow extends LangKeyedRow {
  name: string | null;
  tooltip: string | null;
  icon: string | null;
}

/** `SELECT *` over ability_mechanics (language-neutral, no lang column). */
interface AbilityMechanicsRow {
  id: number;
  duration_ms: number | null;
  tick_ms: number | null;
  cast_ms: number | null;
  channel_ms: number | null;
  channeled: number | null;
  passive: number | null;
  ultimate: number | null;
  buff_type: number | null;
  roles: number | null;
  radius_cm: number | null;
  range_cm: number | null;
  aoe: number | null;
}

interface ChunkRow {
  idx: number;
  data: D1Blob;
}

interface SharePayloadRow {
  payload: D1Blob | null; // NULL for the header-only existence query
}

// ============================================================================
// RESPONSE SHAPES
// ============================================================================

interface AbilityMech {
  aoe?: number;
  durationMs?: number;
  tickMs?: number;
  castMs?: number;
  channelMs?: number;
  buffType?: number;
  ultimate?: number;
  passive?: number;
}

interface AbilityValue {
  name: string;
  icon: string | null;
  tooltip: string | null;
  craftedAbilityId?: number;
  /** Tooltip came from the same-name donor heuristic, not this id's own row
   * — the client shows an accuracy disclaimer on it. Absent when the donor
   * is corroborated (present in the same lookup batch). */
  approxTooltip?: true;
  /** The same-name donor's own id (set on every borrow). Lets the client
   * clear the disclaimer when the donor shows up elsewhere in the share
   * (e.g. slotted on a bar) via a later lookup batch. */
  tooltipDonorId?: number;
  mech?: AbilityMech;
}

interface ItemValue {
  name: string;
  icon: string | null;
  setName: string | null;
  trait: number | null;
  armorType: number | null;
  weaponType: number | null;
  equipType: number | null;
  /** Joins the defs store's set entry (bonus text); null until an in-game
   * item dump has run (UESP sync carries no numeric set id). */
  setId: number | null;
}

interface ChampionValue {
  name: string;
  disciplineId: number | null;
  tooltip: string | null;
}

interface DefValue {
  name: string;
  tooltip?: string;
  icon?: string;
}

// ============================================================================
// REQUEST BODY SHAPES
// ============================================================================

/** Request bodies are untrusted JSON: every field is narrowed where it is used. */
type JsonBody = Record<string, unknown>;

interface AbilityImportRow {
  id?: unknown;
  name?: unknown;
  icon?: unknown;
  tooltip?: unknown;
  craftedAbilityId?: unknown;
}

interface ItemImportRow {
  id?: unknown;
  name?: unknown;
  icon?: unknown;
  setName?: unknown;
  trait?: unknown;
  armorType?: unknown;
  weaponType?: unknown;
  equipType?: unknown;
  setId?: unknown;
}

interface ChampionImportRow {
  id?: unknown;
  name?: unknown;
  disciplineId?: unknown;
  tooltip?: unknown;
}

interface MechanicsImportRow {
  id?: unknown;
  durationMs?: unknown;
  tickMs?: unknown;
  castMs?: unknown;
  channelMs?: unknown;
  channeled?: unknown;
  passive?: unknown;
  ultimate?: unknown;
  buffType?: unknown;
  roles?: unknown;
  radiusCm?: unknown;
  rangeCm?: unknown;
  aoe?: unknown;
}

interface DefImportRow {
  id?: unknown;
  name?: unknown;
  tooltip?: unknown;
  icon?: unknown;
}

// ============================================================================
// HELPERS
// ============================================================================

function newShareId(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(10));
  let id = "";
  for (const b of bytes) {
    id += ID_ALPHABET[b % ID_ALPHABET.length] as string;
  }
  return id;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function badRequest(message: string): Response {
  return json({ error: message }, 400);
}

function errorMessage(e: unknown): string {
  return e instanceof Error ? e.message : String(e);
}

function b64decode(s: string): Uint8Array {
  const bin = atob(s);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) {
    out[i] = bin.charCodeAt(i);
  }
  return out;
}

const VALID_LANG = /^[a-z]{2}$/;

function requestedLang(body: JsonBody): string {
  return typeof body.lang === "string" && VALID_LANG.test(body.lang) ? body.lang : "en";
}

interface MetadataVersion {
  gameVersion: string;
  apiVersion: number;
  versionOrder: string;
}

// Preserve the complete client string as identity; compare numeric release/build
// components so importing 12.0.9 after 12.0.10 cannot replace the current tooltip.
function metadataVersion(body: unknown): MetadataVersion | null {
  if (!body || typeof body !== "object") return null;
  const { gameVersion, apiVersion } = body as JsonBody;
  if (typeof gameVersion !== "string" || gameVersion.length > 256
      || /[\x00-\x1f\x7f]/.test(gameVersion)
      || !Number.isSafeInteger(apiVersion) || Number(apiVersion) <= 0) return null;
  const match = gameVersion.match(/(?:^|[^\d])(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?(?![\d.])/);
  if (!match) return null;
  const parts = match.slice(1).map(part => Number(part ?? 0));
  if (parts.some(part => !Number.isSafeInteger(part) || part > 999999999)) return null;
  return { gameVersion, apiVersion: Number(apiVersion),
    versionOrder: parts.map(part => String(part).padStart(12, "0")).join(".") };
}

/** The integer ids of a lookup body, ignoring anything that is not one. */
function integerIds(value: unknown): number[] {
  if (!Array.isArray(value)) return [];
  return (value as unknown[]).filter((x): x is number => Number.isInteger(x));
}

function blobLength(data: D1Blob): number {
  return data instanceof ArrayBuffer ? data.byteLength : data.length;
}

/** An extra AND-clause; its binds count against the 100-parameter cap. */
interface LookupFilter {
  clause: string;
  binds: unknown[];
}

// Runs an (id, lang) lookup with per-row English fallback.
async function lookupWithFallback<TRow extends LangKeyedRow, TValue>(
  env: Env,
  table: string,
  columns: string,
  ids: number[],
  lang: string,
  mapRow: (row: TRow) => TValue,
  filter?: LookupFilter,
): Promise<Record<number, TValue>> {
  const out: Record<number, TValue> = {};
  const langs = lang === "en" ? ["en"] : [lang, "en"];
  const extraClause = filter ? ` AND ${filter.clause}` : "";
  const extraBinds = filter ? filter.binds : [];
  // D1 caps bound parameters at 100 per statement, and the langs (plus any
  // filter binds) come on top of the id slice
  const SLICE = 100 - langs.length - extraBinds.length;
  for (let i = 0; i < ids.length; i += SLICE) {
    const slice = ids.slice(i, i + SLICE);
    const idPh = slice.map(() => "?").join(",");
    const langPh = langs.map(() => "?").join(",");
    const rows = await env.DB.prepare(
      `SELECT id, lang, ${columns} FROM ${table}_current WHERE id IN (${idPh}) AND lang IN (${langPh})${extraClause}`
    ).bind(...slice, ...langs, ...extraBinds).all<TRow>();
    for (const row of rows.results) {
      // requested language wins; English only fills gaps
      if (row.lang === lang || out[row.id] === undefined) {
        out[row.id] = mapRow(row);
      }
    }
  }
  return out;
}

// D1 stores BLOBs correctly only when bound as ArrayBuffer; a Uint8Array
// bind silently stores an empty value.
function toArrayBuffer(bytes: Uint8Array): ArrayBufferLike {
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
}

// Validates an assembled stream and atomically stores it with a private name
// index. This finds candidate reports for manual review, not proof of identity.
async function createShare(env: Env, payload: Uint8Array): Promise<string> {
  const wire = await parseExportStream(payload);
  const first = wire.encounters[0];
  const title = wire.profile === "view" && wire.encounters.length === 1 && first
    ? first.displayName
    : wire.instanceName || first?.displayName || "Battle Scrolls share";

  const id = newShareId();
  const names = [...new Set(wire.registry.names)].filter(name => name.length > 0)
    .map(name => [name, name.normalize("NFC").replace(/^@/, "").toLowerCase()]);
  await env.DB.batch([env.DB.prepare(
    `INSERT INTO shares (id, created_at, profile, title, encounter_count, payload, platform, world_name)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(
    id,
    Math.floor(Date.now() / 1000),
    wire.profile === "archive" ? 2 : 1,
    title,
    wire.encounters.length,
    toArrayBuffer(payload),
    wire.platform,
    wire.worldName
  ), env.DB.prepare(
    `INSERT INTO share_names (share_id, display_name, name_key)
     SELECT ?, json_extract(value, '$[0]'), json_extract(value, '$[1]') FROM json_each(?)`
  ).bind(id, JSON.stringify(names))]);
  return id;
}

async function handleChunk(env: Env, request: Request): Promise<Response> {
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const { session, index, count, data } = body;
  if (typeof data !== "string" || !data) {
    return badRequest("missing chunk data");
  }
  const total = Number(count);
  const idx = Number(index);
  if (!Number.isInteger(total) || total < 1 || total > MAX_CHUNKS) {
    return badRequest("invalid chunk count");
  }
  if (!Number.isInteger(idx) || idx < 1 || idx > total) {
    return badRequest("invalid chunk index");
  }

  let bytes: Uint8Array;
  try {
    bytes = b64decode(data);
  } catch {
    return badRequest("chunk is not valid base64");
  }
  if (bytes.length === 0 || bytes.length > MAX_CHUNK_BYTES) {
    return badRequest("chunk size out of bounds");
  }

  // Single-URL share: no session bookkeeping at all
  if (total === 1) {
    try {
      const shareId = await createShare(env, bytes);
      return json({ complete: true, shareId });
    } catch (e) {
      return badRequest(`stream rejected: ${errorMessage(e)}`);
    }
  }

  if (typeof session !== "string" || !/^[A-Za-z0-9]{4,32}$/.test(session)) {
    return badRequest("invalid session id");
  }

  const now = Math.floor(Date.now() / 1000);

  // A chunk re-sent after the session already assembled (the in-game
  // stepper allows resends until explicitly finished) must answer with the
  // existing share, not restart the session: the idx=0 marker row stores
  // the share id (client chunk indices are 1-based, so 0 is never real)
  const doneMarker = await env.DB.prepare(
    "SELECT idx, data FROM upload_chunks WHERE session_id = ? AND idx = 0"
  ).bind(session).first<ChunkRow>();
  if (doneMarker) {
    const shareId = new TextDecoder().decode(new Uint8Array(doneMarker.data));
    return json({ complete: true, shareId });
  }

  await env.DB.prepare(
    "INSERT OR REPLACE INTO upload_chunks (session_id, idx, total, created_at, data) VALUES (?, ?, ?, ?, ?)"
  ).bind(session, idx, total, now, toArrayBuffer(bytes)).run();

  const rows = await env.DB.prepare(
    "SELECT idx, data FROM upload_chunks WHERE session_id = ? ORDER BY idx"
  ).bind(session).all<ChunkRow>();

  const received = rows.results.length;
  if (received < total) {
    const have = new Set(rows.results.map((r) => r.idx));
    const missing: number[] = [];
    for (let i = 1; i <= total; i++) {
      if (!have.has(i)) missing.push(i);
    }
    return json({ complete: false, received, total, missing });
  }

  let size = 0;
  for (const row of rows.results) {
    size += blobLength(row.data);
  }
  const payload = new Uint8Array(size);
  let offset = 0;
  for (const row of rows.results) {
    const part = new Uint8Array(row.data);
    payload.set(part, offset);
    offset += part.length;
  }

  try {
    const shareId = await createShare(env, payload);
    await env.DB.prepare("DELETE FROM upload_chunks WHERE session_id = ?")
      .bind(session).run();
    await env.DB.prepare(
      "INSERT OR REPLACE INTO upload_chunks (session_id, idx, total, created_at, data) VALUES (?, 0, ?, ?, ?)"
    ).bind(session, total, now, toArrayBuffer(new TextEncoder().encode(shareId))).run();
    return json({ complete: true, shareId });
  } catch (e) {
    // Keep the chunks: a re-send of any chunk retries assembly
    return badRequest(`stream rejected: ${errorMessage(e)}`);
  }
}

async function handleSharePayload(env: Env, id: string, headOnly: boolean): Promise<Response> {
  const row = await env.DB.prepare(
    // HEAD checks existence using the primary key without loading the BLOB.
    headOnly ? "SELECT NULL AS payload FROM shares WHERE id = ?"
      : "SELECT payload FROM shares WHERE id = ?"
  ).bind(id).first<SharePayloadRow>();
  if (!row) {
    return headOnly ? new Response(null, { status: 404 }) : json({ error: "share not found" }, 404);
  }
  // D1 returns BLOB columns as a plain Array of byte values, which is not a
  // valid Response body (it yields an empty response) - wrap it.
  return new Response(row.payload === null ? null : new Uint8Array(row.payload), {
    headers: {
      "content-type": "application/octet-stream",
      "cache-control": "private, max-age=604800, must-revalidate",
    },
  });
}

/** Resolve embedded ESO item links for every kind of reference description. */
async function resolveDescriptionLinks(env: Env, values: Array<{ tooltip?: string | null }>, lang: string): Promise<void> {
  const ids = [...new Set(values.flatMap((value) => linkedItemIds(value.tooltip || "")))];
  const names = ids.length ? await lookupWithFallback<ItemRow, string>(env, "items", "name", ids, lang,
    (row) => row.name.split("^")[0]!) : {};
  for (const value of values) if (value.tooltip) value.tooltip = plainEsoText(value.tooltip, names);
}

async function handleAbilityLookup(env: Env, request: Request): Promise<Response> {
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const ids = integerIds(body.ids);
  if (ids.length === 0) {
    return json({});
  }
  if (ids.length > 4000) {
    return badRequest("too many ids");
  }
  const lang = requestedLang(body);
  const out = await lookupWithFallback<AbilityRow, AbilityValue>(env, "abilities",
    "name, icon, tooltip, crafted_ability_id",
    ids, lang,
    (row) => ({ name: row.name, icon: row.icon, tooltip: row.tooltip,
      ...(row.crafted_ability_id ? { craftedAbilityId: row.crafted_ability_id } : {}) }));
  await borrowTooltipsByName(env, out, lang);
  await attachMechanics(env, out, ids);
  await resolveDescriptionLinks(env, Object.values(out), lang);
  return json(out, 200);
}

// Joins language-neutral ability_mechanics rows onto a lookup result as a
// `mech` sub-object (only fields with signal are included).
async function attachMechanics(
  env: Env,
  out: Record<number, AbilityValue>,
  ids: number[],
): Promise<void> {
  const present = ids.filter((id) => out[id] !== undefined);
  for (let i = 0; i < present.length; i += 100) {
    const slice = present.slice(i, i + 100);
    const ph = slice.map(() => "?").join(",");
    const rows = await env.DB.prepare(
      `SELECT * FROM ability_mechanics_current WHERE id IN (${ph})`
    ).bind(...slice).all<AbilityMechanicsRow>();
    for (const row of rows.results) {
      const mech: AbilityMech = {};
      if (row.aoe != null) mech.aoe = row.aoe;
      if (row.duration_ms) mech.durationMs = row.duration_ms;
      if (row.tick_ms) mech.tickMs = row.tick_ms;
      if (row.cast_ms) mech.castMs = row.cast_ms;
      if (row.channeled) mech.channelMs = row.channel_ms || 0;
      if (row.buff_type) mech.buffType = row.buff_type;
      if (row.ultimate) mech.ultimate = 1;
      if (row.passive) mech.passive = 1;
      const target = out[row.id];
      if (target && Object.keys(mech).length > 0) target.mech = mech;
    }
  }
}

async function handleMechanicsImport(env: Env, request: Request): Promise<Response> {
  const auth = request.headers.get("authorization") || "";
  if (!env.IMPORT_TOKEN || auth !== `Bearer ${env.IMPORT_TOKEN}`) {
    return json({ error: "unauthorized" }, 403);
  }
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const version = metadataVersion(body);
  if (!version) return badRequest("valid gameVersion and apiVersion are required");
  const rows: MechanicsImportRow[] = Array.isArray(body.mechanics)
    ? (body.mechanics as MechanicsImportRow[])
    : [];
  const valid = rows.filter((r) => Number.isInteger(r.id));
  const int = (v: unknown): number | null => (Number.isInteger(v) ? (v as number) : null);
  // Partial metadata imports preserve fields the importer did not supply.
  const stmts = valid.map((r) =>
    env.DB.prepare(
      `INSERT INTO ability_mechanics
         (id, duration_ms, tick_ms, cast_ms, channel_ms, channeled, passive,
          ultimate, buff_type, roles, radius_cm, range_cm, aoe, game_version, api_version, version_order)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(id, game_version) DO UPDATE SET api_version = excluded.api_version, version_order = excluded.version_order,
         duration_ms = COALESCE(excluded.duration_ms, ability_mechanics.duration_ms),
         tick_ms = COALESCE(excluded.tick_ms, ability_mechanics.tick_ms),
         cast_ms = COALESCE(excluded.cast_ms, ability_mechanics.cast_ms),
         channel_ms = COALESCE(excluded.channel_ms, ability_mechanics.channel_ms),
         channeled = COALESCE(excluded.channeled, ability_mechanics.channeled),
         passive = COALESCE(excluded.passive, ability_mechanics.passive),
         ultimate = COALESCE(excluded.ultimate, ability_mechanics.ultimate),
         buff_type = COALESCE(excluded.buff_type, ability_mechanics.buff_type),
         roles = COALESCE(excluded.roles, ability_mechanics.roles),
         radius_cm = COALESCE(excluded.radius_cm, ability_mechanics.radius_cm),
         range_cm = COALESCE(excluded.range_cm, ability_mechanics.range_cm),
         aoe = COALESCE(excluded.aoe, ability_mechanics.aoe)`)
      .bind(r.id, int(r.durationMs), int(r.tickMs), int(r.castMs), int(r.channelMs),
        int(r.channeled), int(r.passive), int(r.ultimate), int(r.buffType),
        int(r.roles), int(r.radiusCm), int(r.rangeCm), int(r.aoe), version.gameVersion, version.apiVersion, version.versionOrder)
  );
  for (let i = 0; i < stmts.length; i += 50) {
    await env.DB.batch(stmts.slice(i, i + 50));
  }
  return json({ imported: valid.length });
}

// Combat-event ids (damage components, procs) usually have no description of
// their own while the same-named castable skill does — borrow its text for
// entries the id lookup left without one.
async function borrowTooltipsByName(
  env: Env,
  out: Record<number, AbilityValue>,
  lang: string,
): Promise<void> {
  const bare = Object.values(out).filter((v) => !v.tooltip);
  const names = [...new Set(bare.map((v) => v.name))];
  if (names.length === 0) return;
  const langs = lang === "en" ? ["en"] : [lang, "en"];
  const byName: Record<string, TooltipDonorRow> = {};
  const SLICE = 100 - langs.length;
  for (let i = 0; i < names.length; i += SLICE) {
    const slice = names.slice(i, i + SLICE);
    const namePh = slice.map(() => "?").join(",");
    const langPh = langs.map(() => "?").join(",");
    const rows = await env.DB.prepare(
      `SELECT id, lang, name, tooltip FROM abilities_current
       WHERE name IN (${namePh}) AND lang IN (${langPh}) AND tooltip IS NOT NULL`
    ).bind(...slice, ...langs).all<TooltipDonorRow>();
    // requested language wins; then a donor that is itself present in this
    // lookup (the share contains it - e.g. the cast skill behind a combat
    // event) beats the generic lowest-id base skill: it is both the right
    // rank/morph and evidence the name match is exact
    const pri = (l: string): number => (l === lang ? 0 : 1);
    const inShare = (id: number): number => (out[id] !== undefined ? 0 : 1);
    rows.results.sort((a, b) =>
      pri(a.lang) - pri(b.lang) || inShare(a.id) - inShare(b.id) || a.id - b.id);
    for (const row of rows.results) {
      if (byName[row.name] === undefined) byName[row.name] = row;
    }
  }
  for (const v of bare) {
    const donor = byName[v.name];
    if (donor) {
      v.tooltip = donor.tooltip;
      v.tooltipDonorId = donor.id;
      // Name matching is a heuristic and sometimes lands on an unrelated
      // same-named skill - the client discloses that on the tooltip card.
      // A donor corroborated by the share itself counts as exact; batches
      // split, so the client re-checks donor ids against its full universe.
      if (out[donor.id] === undefined) {
        v.approxTooltip = true;
      }
    }
  }
}

async function handleAbilityImport(env: Env, request: Request): Promise<Response> {
  const auth = request.headers.get("authorization") || "";
  if (!env.IMPORT_TOKEN || auth !== `Bearer ${env.IMPORT_TOKEN}`) {
    return json({ error: "unauthorized" }, 403);
  }
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const version = metadataVersion(body);
  if (!version) return badRequest("valid gameVersion and apiVersion are required");
  const rows: AbilityImportRow[] = Array.isArray(body.abilities)
    ? (body.abilities as AbilityImportRow[])
    : [];
  const lang = requestedLang(body);
  let imported = 0;
  const BATCH = 50;
  for (let i = 0; i < rows.length; i += BATCH) {
    const slice = rows.slice(i, i + BATCH).filter(
      (r) => Number.isInteger(r.id) && typeof r.name === "string" && r.name.length > 0
    );
    if (slice.length === 0) continue;
    // Partial passes can supplement the same version without erasing fields.
    const stmts = slice.map((r) =>
      env.DB.prepare(
        `INSERT INTO abilities (id, lang, name, icon, tooltip, crafted_ability_id, game_version, api_version, version_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(id, lang, game_version) DO UPDATE SET api_version = excluded.api_version, version_order = excluded.version_order,
           name = excluded.name,
           icon = COALESCE(excluded.icon, abilities.icon),
           tooltip = COALESCE(excluded.tooltip, abilities.tooltip),
           crafted_ability_id = COALESCE(excluded.crafted_ability_id, abilities.crafted_ability_id)`)
        .bind(r.id, lang, r.name,
          typeof r.icon === "string" && r.icon.length > 0 ? r.icon : null,
          typeof r.tooltip === "string" && r.tooltip.length > 0 ? r.tooltip : null,
          Number.isInteger(r.craftedAbilityId) && Number(r.craftedAbilityId) >= 0 ? r.craftedAbilityId : null, version.gameVersion, version.apiVersion, version.versionOrder)
    );
    await env.DB.batch(stmts);
    imported += slice.length;
  }
  return json({ imported });
}

async function handleItemLookup(env: Env, request: Request): Promise<Response> {
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const ids = integerIds(body.ids);
  if (ids.length === 0) return json({});
  if (ids.length > 500) return badRequest("too many ids");
  const out = await lookupWithFallback<ItemRow, ItemValue>(env, "items",
    "name, icon, set_name, trait, armor_type, weapon_type, equip_type, set_id",
    ids, requestedLang(body),
    (row) => ({
      name: row.name, icon: row.icon, setName: row.set_name,
      trait: row.trait, armorType: row.armor_type,
      weaponType: row.weapon_type, equipType: row.equip_type,
      setId: row.set_id,
    }));
  return json(out);
}

async function handleItemImport(env: Env, request: Request): Promise<Response> {
  const auth = request.headers.get("authorization") || "";
  if (!env.IMPORT_TOKEN || auth !== `Bearer ${env.IMPORT_TOKEN}`) {
    return json({ error: "unauthorized" }, 403);
  }
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const version = metadataVersion(body);
  if (!version) return badRequest("valid gameVersion and apiVersion are required");
  const rows: ItemImportRow[] = Array.isArray(body.items)
    ? (body.items as ItemImportRow[])
    : [];
  const lang = requestedLang(body);
  let imported = 0;
  const BATCH = 50;
  for (let i = 0; i < rows.length; i += BATCH) {
    const slice = rows.slice(i, i + BATCH).filter(
      (r) => Number.isInteger(r.id) && typeof r.name === "string" && r.name.length > 0
    );
    if (slice.length === 0) continue;
    // Preserve set ids when a partial pass omits them within the same version.
    const stmts = slice.map((r) =>
      env.DB.prepare(
        `INSERT INTO items (id, lang, name, icon, set_name, trait, armor_type, weapon_type, equip_type, set_id, game_version, api_version, version_order)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(id, lang, game_version) DO UPDATE SET api_version = excluded.api_version, version_order = excluded.version_order,
           name = excluded.name,
           icon = excluded.icon,
           set_name = excluded.set_name,
           trait = excluded.trait,
           armor_type = excluded.armor_type,
           weapon_type = excluded.weapon_type,
           equip_type = excluded.equip_type,
           set_id = COALESCE(excluded.set_id, items.set_id)`)
        .bind(r.id, lang, r.name,
          typeof r.icon === "string" ? r.icon : null,
          typeof r.setName === "string" && r.setName ? r.setName : null,
          Number.isInteger(r.trait) ? r.trait : null,
          Number.isInteger(r.armorType) ? r.armorType : null,
          Number.isInteger(r.weaponType) ? r.weaponType : null,
          Number.isInteger(r.equipType) ? r.equipType : null,
          Number.isInteger(r.setId) && (r.setId as number) > 0 ? r.setId : null, version.gameVersion, version.apiVersion, version.versionOrder)
    );
    await env.DB.batch(stmts);
    imported += slice.length;
  }
  return json({ imported });
}

async function handleChampionLookup(env: Env, request: Request): Promise<Response> {
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const ids = integerIds(body.ids);
  if (ids.length === 0) return json({});
  if (ids.length > 200) return badRequest("too many ids");
  const out = await lookupWithFallback<ChampionRow, ChampionValue>(env, "champion_skills",
    "name, discipline_id, tooltip", ids, requestedLang(body),
    (row) => ({ name: row.name, disciplineId: row.discipline_id, tooltip: row.tooltip }));
  await resolveDescriptionLinks(env, Object.values(out), requestedLang(body));
  return json(out);
}

async function handleChampionImport(env: Env, request: Request): Promise<Response> {
  const auth = request.headers.get("authorization") || "";
  if (!env.IMPORT_TOKEN || auth !== `Bearer ${env.IMPORT_TOKEN}`) {
    return json({ error: "unauthorized" }, 403);
  }
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const version = metadataVersion(body);
  if (!version) return badRequest("valid gameVersion and apiVersion are required");
  const rows: ChampionImportRow[] = Array.isArray(body.champion)
    ? (body.champion as ChampionImportRow[])
    : [];
  const lang = requestedLang(body);
  const valid = rows.filter(
    (r) => Number.isInteger(r.id) && typeof r.name === "string" && r.name.length > 0
  );
  const stmts = valid.map((r) =>
    env.DB.prepare(
      `INSERT INTO champion_skills (id, lang, name, discipline_id, tooltip, game_version, api_version, version_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(id, lang, game_version) DO UPDATE SET api_version = excluded.api_version, version_order = excluded.version_order,
         name = excluded.name,
         discipline_id = COALESCE(excluded.discipline_id, champion_skills.discipline_id),
         tooltip = COALESCE(excluded.tooltip, champion_skills.tooltip)`)
      .bind(r.id, lang, r.name,
        Number.isInteger(r.disciplineId) ? r.disciplineId : null,
        typeof r.tooltip === "string" && r.tooltip ? r.tooltip : null, version.gameVersion, version.apiVersion, version.versionOrder)
  );
  for (let i = 0; i < stmts.length; i += 50) {
    await env.DB.batch(stmts.slice(i, i + 50));
  }
  return json({ imported: valid.length });
}

async function handleScribingLookup(env: Env, request: Request): Promise<Response> {
  let body: JsonBody;
  try { body = (await request.json()) as JsonBody; }
  catch { return badRequest("invalid JSON body"); }
  if (!body || !Array.isArray(body.recipes) || body.recipes.length > 50
    || !body.recipes.every(isScribedRecipe)) return badRequest("invalid recipes");
  const recipes = body.recipes.filter(isScribedRecipe);
  const lang = requestedLang(body);
  const out: Record<string, ScribedAbility> = {};
  if (recipes.length) {
    const results = await env.DB.batch<{ name: string; icon: string | null; tooltip: string | null; class_id: number }>(
      recipes.map((recipe) => env.DB.prepare(
        `SELECT name, icon, tooltip, class_id FROM scribed_abilities_current
         WHERE crafted_ability_id = ? AND primary_script_id = ? AND secondary_script_id = ? AND tertiary_script_id = ?
           AND lang IN (?, 'en')
         ORDER BY CASE WHEN class_id IN (0, ?) THEN 0 ELSE 1 END,
           CASE WHEN lang = ? THEN 0 ELSE 1 END, class_id LIMIT 1`
      ).bind(recipe.craftedAbilityId, ...recipe.scriptIds, lang, recipe.classId, lang))
    );
    results.forEach((result, index) => {
      const row = result.results[0], recipe = recipes[index]!;
      if (!row) return;
      // Class Flourish's name/icon are shared, but never borrow another
      // class's effect text. The viewer can still show the generic scripts.
      out[scribingKey(recipe)] = { name: row.name,
        ...(row.icon ? { icon: row.icon } : {}),
        ...(row.tooltip && (row.class_id === 0 || row.class_id === recipe.classId) ? { tooltip: row.tooltip } : {}) };
    });
  }
  await resolveDescriptionLinks(env, Object.values(out), lang);
  return json({ abilities: out });
}

async function handleScribingImport(env: Env, request: Request): Promise<Response> {
  if (!env.IMPORT_TOKEN || request.headers.get("authorization") !== `Bearer ${env.IMPORT_TOKEN}`) {
    return json({ error: "unauthorized" }, 403);
  }
  let body: JsonBody;
  try { body = (await request.json()) as JsonBody; }
  catch { return badRequest("invalid JSON body"); }
  const version = metadataVersion(body);
  if (!version) return badRequest("valid gameVersion and apiVersion are required");
  if (!body || !Array.isArray(body.scribing) || body.scribing.length > 4000) return badRequest("invalid scribing rows");
  const rows = body.scribing as unknown[];
  const valid = rows.filter((row): row is ScribedRecipe & ScribedAbility => {
    if (!isScribedRecipe(row)) return false;
    const value = row as ScribedRecipe & { name?: unknown; icon?: unknown; tooltip?: unknown };
    return typeof value.name === "string" && value.name.length > 0 && value.name.length <= 500
      && (value.icon == null || typeof value.icon === "string" && value.icon.length <= 500)
      && (value.tooltip == null || typeof value.tooltip === "string" && value.tooltip.length <= 32768);
  });
  if (valid.length !== rows.length) return badRequest("invalid scribing row");
  const lang = requestedLang(body);
  for (let i = 0; i < valid.length; i += 50) {
    await env.DB.batch(valid.slice(i, i + 50).map((row) => env.DB.prepare(
      `INSERT INTO scribed_abilities (crafted_ability_id, primary_script_id, secondary_script_id, tertiary_script_id, class_id, lang, name, icon, tooltip, game_version, api_version, version_order)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(crafted_ability_id, primary_script_id, secondary_script_id, tertiary_script_id, class_id, lang, game_version)
       DO UPDATE SET api_version = excluded.api_version, version_order = excluded.version_order, name = excluded.name, icon = excluded.icon, tooltip = excluded.tooltip`
    ).bind(row.craftedAbilityId, ...row.scriptIds, row.classId, lang, row.name, row.icon || null, row.tooltip || null, version.gameVersion, version.apiVersion, version.versionOrder)));
  }
  return json({ imported: valid.length });
}

// Generic (kind, id) definitions: scribing scripts, Vengeance perks, skill
// lines — names the client cannot derive from the ability or item DBs.
async function handleDefsLookup(env: Env, request: Request): Promise<Response> {
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const kind = typeof body.kind === "string" ? body.kind : "";
  if (kind.length === 0) return badRequest("missing kind");
  const ids = integerIds(body.ids);
  if (ids.length === 0) return json({ defs: {} });
  if (ids.length > 500) return badRequest("too many ids");
  const defs = await lookupWithFallback<DefRow, DefValue>(env, "defs",
    "name, tooltip, icon", ids, requestedLang(body),
    (row) => {
      // Empty columns are omitted rather than sent as nulls
      const def: DefValue = { name: row.name ?? "" };
      if (row.tooltip) def.tooltip = row.tooltip;
      if (row.icon) def.icon = row.icon;
      return def;
    },
    { clause: "kind = ?", binds: [kind] });
  await resolveDescriptionLinks(env, Object.values(defs), requestedLang(body));
  return json({ defs });
}

async function handleDefsImport(env: Env, request: Request): Promise<Response> {
  const auth = request.headers.get("authorization") || "";
  if (!env.IMPORT_TOKEN || auth !== `Bearer ${env.IMPORT_TOKEN}`) {
    return json({ error: "unauthorized" }, 403);
  }
  let body: JsonBody;
  try {
    body = (await request.json()) as JsonBody;
  } catch {
    return badRequest("invalid JSON body");
  }
  const version = metadataVersion(body);
  if (!version) return badRequest("valid gameVersion and apiVersion are required");
  const kind = typeof body.kind === "string" ? body.kind : "";
  if (kind.length === 0) return badRequest("missing kind");
  const rows: DefImportRow[] = Array.isArray(body.defs)
    ? (body.defs as DefImportRow[])
    : [];
  const lang = requestedLang(body);
  const valid = rows.filter((r) => Number.isInteger(r.id));
  const text = (v: unknown): string | null =>
    (typeof v === "string" && v.length > 0 ? v : null);
  // Kinds are filled by several partial dumps (a name-only pass, an icon-only
  // pass): a missing field must not erase what an earlier import provided
  const stmts = valid.map((r) =>
    env.DB.prepare(
      `INSERT INTO defs (kind, id, lang, name, tooltip, icon, game_version, api_version, version_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(kind, id, lang, game_version) DO UPDATE SET api_version = excluded.api_version, version_order = excluded.version_order,
         name = COALESCE(excluded.name, defs.name),
         tooltip = COALESCE(excluded.tooltip, defs.tooltip),
         icon = COALESCE(excluded.icon, defs.icon)`)
      .bind(kind, r.id, lang, text(r.name), text(r.tooltip), text(r.icon), version.gameVersion, version.apiVersion, version.versionOrder)
  );
  for (let i = 0; i < stmts.length; i += 50) {
    await env.DB.batch(stmts.slice(i, i + 50));
  }
  return json({ imported: valid.length });
}

// Pull-through icon cache: our R2 copy is authoritative; a miss is fetched
// from UESP's icon mirror exactly once, stored, and served from R2 forever.
const ICON_SOURCE = "https://esoicons.uesp.net/";
const ICON_CACHE_HEADERS = {
  "content-type": "image/png",
  "cache-control": "public, max-age=31536000, immutable",
};

async function handleIcon(env: Env, ctx: ExecutionContext, key: string): Promise<Response> {
  const stored = await env.ICONS.get(key);
  if (stored) {
    return new Response(stored.body, { headers: ICON_CACHE_HEADERS });
  }
  const upstream = await fetch(ICON_SOURCE + key, {
    headers: {
      "user-agent": "Mozilla/5.0 (compatible; BattleScrollsShare/1.0; +https://bs.sheludchenkov.com)",
    },
  });
  if (!upstream.ok || !(upstream.headers.get("content-type") || "").includes("image")) {
    return new Response("icon not found", {
      status: 404,
      headers: { "cache-control": "public, max-age=86400" },
    });
  }
  const bytes = await upstream.arrayBuffer();
  ctx.waitUntil(env.ICONS.put(key, bytes, {
    httpMetadata: { contentType: "image/png" },
  }));
  return new Response(bytes, { headers: ICON_CACHE_HEADERS });
}

export default {
  async scheduled(_event, env): Promise<void> {
    await env.DB.prepare("DELETE FROM upload_chunks WHERE created_at < ?")
      .bind(Math.floor(Date.now() / 1000) - SESSION_TTL_S).run();
  },
  async fetch(request, env, ctx): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;

    if (pathname === "/api/chunk" && request.method === "POST") {
      return handleChunk(env, request);
    }
    const payloadMatch = pathname.match(/^\/api\/share\/([A-Za-z0-9]{6,32})$/);
    if (payloadMatch && (request.method === "GET" || request.method === "HEAD")) {
      return handleSharePayload(env, payloadMatch[1] as string, request.method === "HEAD");
    }
    if (pathname === "/api/abilities/lookup" && request.method === "POST") {
      return handleAbilityLookup(env, request);
    }
    if (pathname === "/api/abilities/import" && request.method === "POST") {
      return handleAbilityImport(env, request);
    }
    if (pathname === "/api/items/lookup" && request.method === "POST") {
      return handleItemLookup(env, request);
    }
    if (pathname === "/api/items/import" && request.method === "POST") {
      return handleItemImport(env, request);
    }
    if (pathname === "/api/champion/lookup" && request.method === "POST") {
      return handleChampionLookup(env, request);
    }
    if (pathname === "/api/champion/import" && request.method === "POST") {
      return handleChampionImport(env, request);
    }
    if (pathname === "/api/mechanics/import" && request.method === "POST") {
      return handleMechanicsImport(env, request);
    }
    if (pathname === "/api/defs/lookup" && request.method === "POST") {
      return handleDefsLookup(env, request);
    }
    if (pathname === "/api/defs/import" && request.method === "POST") {
      return handleDefsImport(env, request);
    }
    if (pathname === "/api/scribing/lookup" && request.method === "POST") {
      return handleScribingLookup(env, request);
    }
    if (pathname === "/api/scribing/import" && request.method === "POST") {
      return handleScribingImport(env, request);
    }
    const iconMatch = pathname.match(/^\/icons\/(esoui\/[a-z0-9_\/.-]+\.png)$/);
    if (iconMatch && request.method === "GET") {
      return handleIcon(env, ctx, iconMatch[1] as string);
    }

    // The asset binding applies public/_headers, including on direct .html
    // requests that Cloudflare serves without invoking this Worker.
    if (pathname === "/privacy" || pathname === "/privacy/") {
      return env.ASSETS.fetch(new Request(new URL("/privacy.html", url), request));
    }
    if (pathname === "/u" || pathname === "/u/") {
      return env.ASSETS.fetch(new Request(new URL("/upload.html", url), request));
    }
    if (/^\/s\/[A-Za-z0-9]{6,32}$/.test(pathname)) {
      return env.ASSETS.fetch(new Request(new URL("/viewer.html", url), request));
    }

    return env.ASSETS.fetch(request);
  },
} satisfies ExportedHandler<Env>;

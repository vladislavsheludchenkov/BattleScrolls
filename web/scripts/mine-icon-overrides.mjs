// Generate static icon donors from observed ultimate sources, not a scan of
// same-name NPC abilities. Runtime code in both clients stays a table lookup.
//
// From web/, using the project's Node version:
//   npx wrangler d1 execute bs-share --remote --json --command \
//     "SELECT id, name, icon, crafted_ability_id AS craftedAbilityId, CASE WHEN tooltip IS NOT NULL AND tooltip != '' THEN 1 ELSE 0 END AS described FROM abilities_current WHERE lang='en' ORDER BY id" > /tmp/ability-icons.json
//   curl -fsS https://bs.sheludchenkov.com/api/share/SHARE_ID -o /tmp/share.bin
//   node scripts/mine-icon-overrides.mjs /tmp/ability-icons.json /tmp/share.bin [...]
//   npm run gen
//
// Review and commit the resulting Lua/TS tables. No uploads or names from
// encounters are written into the repository. Earlier generated source IDs
// are rechecked on each run, so supplying a new share retains prior coverage.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { build } from "esbuild";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const begin = "    -- BEGIN GENERATED ULTIMATE ICON DONORS (web/scripts/mine-icon-overrides.mjs)";
const end = "    -- END GENERATED ULTIMATE ICON DONORS";

function isPlaceholder(icon) {
  if (!icon) return true;
  const path = icon.toLowerCase().replace(/^\//, "");
  return path === "esoui/art/icons/ability_mage_065.dds"
    || path === "esoui/art/icons/icon_missing.dds";
}

/** Prefer the exact grimoire relationship, then unambiguous described names. */
export function resolveIconDonors(rows, sourceIds) {
  const byId = new Map();
  const byName = new Map();
  const byGrimoire = new Map();
  const add = (map, key, row) => map.set(key, [...(map.get(key) || []), row]);
  for (const row of rows) {
    if (!Number.isInteger(row.id) || typeof row.name !== "string") throw new Error("Invalid ability metadata row");
    if (byId.has(row.id)) throw new Error(`Duplicate metadata for ${row.id}; export one current language`);
    byId.set(row.id, row);
    if (isPlaceholder(row.icon)) continue;
    if (row.described) add(byName, row.name, row);
    if (row.craftedAbilityId > 0 && /^\/esoui\/art\/icons\/ability_grimoire_.*\.dds$/.test(row.icon)) {
      add(byGrimoire, row.craftedAbilityId, row);
    }
  }
  const overrides = [];
  const unresolved = [];
  for (const id of [...new Set(sourceIds)].filter(id => id > 0).sort((a, b) => a - b)) {
    const source = byId.get(id);
    if (!source) {
      unresolved.push({ id, reason: "missing metadata" });
      continue;
    }
    if (!isPlaceholder(source.icon)) continue;
    // A crafted ID is stronger evidence than a script's potentially shared
    // name. If its own grimoire has no donor, leave it for a later data mine.
    const candidates = (source.craftedAbilityId > 0
      ? byGrimoire.get(source.craftedAbilityId) : byName.get(source.name)) || [];
    if (new Set(candidates.map(row => row.icon)).size !== 1) {
      unresolved.push({ id, name: source.name, reason: candidates.length ? "conflicting icons" : "no donor" });
      continue;
    }
    const donor = candidates.reduce((a, b) => a.id < b.id ? a : b);
    overrides.push({ id, donorId: donor.id, name: source.name, donorName: donor.name });
  }
  return { overrides, unresolved };
}

async function main() {
  const [metadataPath, ...sharePaths] = process.argv.slice(2);
  if (!metadataPath || !sharePaths.length) throw new Error("Usage: node scripts/mine-icon-overrides.mjs metadata.json share.bin [...]");
  const result = JSON.parse(readFileSync(metadataPath, "utf8"));
  if (result.length !== 1 || !result[0].success || !Array.isArray(result[0].results)) throw new Error("Expected one successful Wrangler JSON query");
  const target = resolve(root, "../BattleScrolls/ui/journal/utils.lua");
  const lua = readFileSync(target, "utf8");
  const start = lua.indexOf(begin);
  const stop = lua.indexOf(end, start);
  if (start < 0 || stop < start) throw new Error("Generated donor markers not found");
  const ids = new Set([...lua.slice(start, stop).matchAll(/\[(\d+)\]\s*=/g)].map(match => Number(match[1])));
  const manual = new Set([...lua.slice(0, start).matchAll(/\[(\d+)\]\s*=\s*\d+/g)].map(match => Number(match[1])));
  const bundle = await build({ entryPoints: [resolve(root, "src/shared/decoder.ts")], bundle: true, write: false, format: "esm", platform: "node" });
  const { parseExportStream, decodeEncounter } = await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString("base64")}`);
  for (const file of sharePaths) {
    let wire;
    try { wire = await parseExportStream(new Uint8Array(readFileSync(file))); }
    catch (error) { throw new Error(`${file}: ${error.message}`); }
    for (const encounter of wire.encounters) {
      const decoded = decodeEncounter(encounter.dataBytes, wire.registry, encounter.durationMs);
      for (const id of Object.keys(decoded.ultimate?.gainByAbilityId || {})) ids.add(Number(id));
    }
  }
  const { overrides, unresolved } = resolveIconDonors(result[0].results, [...ids].filter(id => !manual.has(id)));
  // Do not silently remove established mappings when a partial mine is used.
  if (unresolved.some(row => row.reason === "missing metadata")) throw new Error(`Missing source metadata: ${JSON.stringify(unresolved)}`);
  const comment = text => text.replace(/[\r\n\u2028\u2029]/g, " ");
  const entries = overrides.map(row => `    [${row.id}] = ${row.donorId}, -- ${comment(row.name)} -> ${comment(row.donorName)}`);
  writeFileSync(target, lua.slice(0, start) + [begin, ...entries, ""].join("\n") + lua.slice(stop));
  console.log(`Generated ${entries.length} ultimate icon overrides. Unresolved: ${JSON.stringify(unresolved)}`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(error => { console.error(error.message); process.exitCode = 1; });
}

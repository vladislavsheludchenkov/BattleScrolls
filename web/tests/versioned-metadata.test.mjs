import assert from "node:assert/strict";
import { test } from "node:test";
import { readFileSync, readdirSync, mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { api } from "./worker-api.mjs";

const versions = [
  { gameVersion: "eso.live.12.0.9.100", apiVersion: 101048 },
  { gameVersion: "eso.live.12.0.10.101", apiVersion: 101049 },
];
const recipe = { craftedAbilityId: 5, scriptIds: [11, 31, 41], classId: 117 };
const stores = [
  ["abilities", "abilities", { id: 100, name: "Skill" }],
  ["items", "items", { id: 100, name: "Gear" }],
  ["champion", "champion_skills", { id: 100, name: "Star" }],
  ["mechanics", "ability_mechanics", { id: 100, durationMs: 5000 }],
  ["defs", "defs", { id: 100, name: "Trait" }],
  ["scribing", "scribed_abilities", { ...recipe, name: "Recipe" }],
];

for (const [endpoint, table, row] of stores) {
  test(`${endpoint}: every row is versioned, retries update only that version, and lookups stay current`, async () => {
    const request = api();
    try {
      for (const version of versions.toReversed()) {
        const payload = { ...version, lang: "en", kind: "trait", [endpoint]: [{ ...row, tooltip: version.gameVersion }] };
        assert.equal((await request(`${endpoint}/import`, payload)).body.imported, 1);
        assert.equal((await request(`${endpoint}/import`, payload)).body.imported, 1);
      }
      const rows = request.db.prepare(`SELECT game_version, api_version FROM ${table} ORDER BY version_order`).all();
      assert.deepEqual(rows.map(r => ({ ...r })), versions.map(v => ({ game_version: v.gameVersion, api_version: v.apiVersion })));
      assert.equal(request.db.prepare(`SELECT game_version FROM ${table}_current`).get().game_version, versions[1].gameVersion);
      if (endpoint === "mechanics") {
        await request("abilities/import", { ...versions[1], abilities: [{ id: 100, name: "Skill" }] });
        await request("mechanics/import", { ...versions[1], mechanics: [{ id: 100, durationMs: 0 }] });
        const result = await request("abilities/lookup", { ids: [100] });
        assert.equal(result.body[100].mech?.durationMs, undefined);
        assert.equal(request.db.prepare("SELECT duration_ms FROM ability_mechanics WHERE game_version = ?").get(versions[0].gameVersion).duration_ms, 5000);
      } else {
        const result = await request(`${endpoint}/lookup`, { ids: [100], kind: "trait", recipes: [recipe] });
        const value = endpoint === "scribing" ? result.body.abilities["5:11:31:41:117"] : endpoint === "defs" ? result.body.defs[100] : result.body[100];
        assert.equal(value.name, row.name);
        if (endpoint !== "items") assert.equal(value.tooltip, versions[1].gameVersion);
      }
      const plan = request.db.prepare(`EXPLAIN QUERY PLAN SELECT * FROM ${table}_current WHERE ${endpoint === "scribing" ? "crafted_ability_id = 5" : "id = 100"}${endpoint === "defs" ? " AND kind = 'trait'" : ""}`).all();
      assert.ok(plan.every(step => !/SCAN (row|newer)\b/.test(step.detail)), JSON.stringify(plan));
    } finally { request.db.close(); }
  });

  test(`${endpoint}: missing or invalid version metadata cannot write rows`, async () => {
    const request = api();
    try {
      for (const metadata of [{}, { gameVersion: versions[0].gameVersion }, { apiVersion: 101048 },
        { ...versions[0], apiVersion: 0 }, { ...versions[0], apiVersion: 1.5 },
        { ...versions[0], gameVersion: "unknown" }, { ...versions[0], gameVersion: "12.0.9\n" }]) {
        const result = await request(`${endpoint}/import`, { ...metadata, kind: "trait", [endpoint]: [row] });
        assert.equal(result.status, 400);
      }
      assert.equal((await request(`${endpoint}/import`, null)).status, 400);
      assert.equal(request.db.prepare(`SELECT COUNT(*) n FROM ${table}`).get().n, 0);
    } finally { request.db.close(); }
  });
}

test("one import emits every language and version without overwriting batches, including zero mechanics", async () => {
  const script = readFileSync(new URL("../../scripts/import-abilities.sh", import.meta.url), "utf8").split("<<'LUA'\n")[1].split("\nLUA\n")[0];
  const dir = mkdtempSync(join(tmpdir(), "bs-version-import-"));
  const request = api();
  try {
    const file = join(dir, "dump.lua");
    writeFileSync(file, `BattleScrollsAbilityDumpSV = { formatVersion=2, datasets={} }
      for _, v in ipairs({'eso.live.12.0.9.100','eso.live.12.0.10.101'}) do
        for _, lang in ipairs({'en','de'}) do
          table.insert(BattleScrollsAbilityDumpSV.datasets, {gameVersion=v,apiVersion=101048,language=lang,
            abilities={['100']='100\tSkill '..lang..'\t\tDescription\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t5'},
            traits={['1']='1\tTrait '..lang..'\t\tText'},
            combinations={['recipe']='5\t11\t31\t41\t117\tRecipe '..lang..'\t\tText'} })
        end
      end`);
    const run = spawnSync("lua5.4", ["-", file, dir], { input: script, encoding: "utf8" });
    assert.equal(run.status, 0, run.stderr);
    const files = readdirSync(dir).filter(f => f.endsWith(".json"));
    assert.equal(files.length, 14);
    for (const file of files) {
      const payload = JSON.parse(readFileSync(join(dir, file), "utf8"));
      const endpoint = file.startsWith("defs-") ? "defs" : file.split("_")[0];
      assert.equal((await request(`${endpoint}/import`, payload)).body.imported, 1);
    }
    assert.equal(request.db.prepare("SELECT COUNT(*) n FROM abilities").get().n, 4);
    assert.equal(request.db.prepare("SELECT COUNT(*) n FROM ability_mechanics").get().n, 2);
    assert.equal(request.db.prepare("SELECT COUNT(*) n FROM defs").get().n, 4);
    assert.equal(request.db.prepare("SELECT COUNT(*) n FROM scribed_abilities").get().n, 4);
  } finally { request.db.close(); rmSync(dir, { recursive: true, force: true }); }
});

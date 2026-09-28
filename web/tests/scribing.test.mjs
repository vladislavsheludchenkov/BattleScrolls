import assert from "node:assert/strict";
import { test } from "node:test";
import { readFileSync, mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

import { api } from "./worker-api.mjs";
const version = { gameVersion: "eso.live.12.0.5.123456", apiVersion: 101048 };

const recipe = { craftedAbilityId: 5, scriptIds: [11, 21, 41], classId: 0 };

test("recipe import and lookup use ordered scripts, language fallback and exact class text", async () => {
  const request = api();
  assert.equal((await request("scribing/import", { ...version, lang: "en", scribing: [{ ...recipe, name: "Magic Soul", tooltip: "English combined text" }] })).body.imported, 1);
  await request("scribing/import", { ...version, lang: "de", scribing: [{ ...recipe, name: "Magieseelen", tooltip: "Deutscher Text" }] });
  let result = await request("scribing/lookup", { lang: "de", recipes: [{ ...recipe, classId: 117 }, { ...recipe, scriptIds: [21, 11, 41] }] });
  assert.deepEqual(result.body.abilities, { "5:11:21:41:117": { name: "Magieseelen", tooltip: "Deutscher Text" } });
  result = await request("scribing/lookup", { lang: "fr", recipes: [recipe] });
  assert.equal(result.body.abilities["5:11:21:41:0"].tooltip, "English combined text");
  const flourish = { ...recipe, scriptIds: [11, 31, 41], classId: 117 };
  await request("scribing/import", { ...version, lang: "en", scribing: [{ ...flourish, name: "Magic Soul", tooltip: "Generate Crux" }] });
  result = await request("scribing/lookup", { lang: "en", recipes: [flourish, { ...flourish, classId: 1 }] });
  assert.equal(result.body.abilities["5:11:31:41:117"].tooltip, "Generate Crux");
  assert.deepEqual(result.body.abilities["5:11:31:41:1"], { name: "Magic Soul" });
});

test("scribing rejects malformed or unbounded requests and requires the import token", async () => {
  const request = api();
  assert.equal((await request("scribing/import", { ...version, scribing: [] }, "wrong")).status, 403);
  for (const body of [null, {}, { recipes: Array(51).fill(recipe) }, { recipes: [{ ...recipe, scriptIds: [11, 21] }] }, { recipes: [{ ...recipe, classId: -1 }] }, { recipes: [{ ...recipe, classId: 256 }] }]) {
    assert.equal((await request("scribing/lookup", body)).status, 400);
  }
  assert.equal((await request("scribing/import", { ...version, scribing: [{ ...recipe, name: "" }] })).status, 400);
});

test("ability imports retain the grimoire mapping across partial passes of the same version", async () => {
  const request = api();
  await request("abilities/import", { ...version, lang: "en", abilities: [{ id: 100, name: "Soul", craftedAbilityId: 5 }] });
  await request("abilities/import", { ...version, lang: "en", abilities: [{ id: 100, name: "Soul" }] });
  const result = await request("abilities/lookup", { lang: "en", ids: [100] });
  assert.equal(result.body[100].craftedAbilityId, 5);
});

test("SavedVariables importer preserves recipe order, class and multi-paragraph tooltip", () => {
  const script = readFileSync(new URL("../../scripts/import-abilities.sh", import.meta.url), "utf8").split("<<'LUA'\n")[1].split("\nLUA\n")[0];
  const dir = mkdtempSync(join(tmpdir(), "bs-scribing-import-"));
  try {
    const file = join(dir, "dump.lua");
    writeFileSync(file, `BattleScrollsAbilityDumpSV = { formatVersion=2, datasets={ { language="en", gameVersion="eso.live.12.0.5.123456", apiVersion=101048,
      abilities={["100"]="100\\tSoul\\t\\tDescription\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t5"},
      combinations={["5:11:31:41:117"]="5\\t11\\t31\\t41\\t117\\tMagic Soul\\t/esoui/soul.dds\\t|cffffffDamage|r\\nGenerate Crux"} } } }`);
    const run = spawnSync("lua5.4", ["-", file, dir], { input: script, encoding: "utf8" });
    assert.equal(run.status, 0, run.stderr);
    const payload = JSON.parse(readFileSync(join(dir, "scribing_001_001.json"), "utf8"));
    assert.deepEqual(payload, { ...version, lang: "en", scribing: [{ craftedAbilityId: 5, scriptIds: [11, 31, 41], classId: 117, name: "Magic Soul", icon: "/esoui/soul.dds", tooltip: "Damage\nGenerate Crux" }] });
    assert.equal(JSON.parse(readFileSync(join(dir, "abilities_001_001.json"), "utf8")).abilities[0].craftedAbilityId, 5);
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

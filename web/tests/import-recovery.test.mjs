import assert from "node:assert/strict";
import { test } from "node:test";
import { chmodSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";

test("import retries a dropped connection and resumes without repeating completed batches", () => {
  const dir = mkdtempSync(join(tmpdir(), "bs-import-recovery-"));
  let batches;
  try {
    writeFileSync(join(dir, ".bs-share-import-token"), "test-token");
    const dump = join(dir, "dump.lua");
    writeFileSync(dump, `BattleScrollsAbilityDumpSV={formatVersion=2,datasets={{
      gameVersion='eso.live.12.0.1.10',apiVersion=101048,language='en',
      abilities={['100']='100\\tSkill\\t\\tDescription\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t5'},
      items={['10']='10\\tItem'}, combinations={['recipe']='5\\t11\\t31\\t41\\t117\\tRecipe'},
      traits={['1']='1\\tTrait'} }}}`);
    const curl = join(dir, "curl");
    writeFileSync(curl, `#!/bin/bash
while [ "$#" -gt 0 ]; do
  case "$1" in
    --data-binary) file="\${2#@}"; shift ;;
    -o) response="$2"; shift ;;
  esac
  shift
done
name=$(basename "$file")
echo "$name" >> "$BS_IMPORT_TEST_DIR/calls"
if [[ "$name" = abilities* ]] && [ ! -f "$BS_IMPORT_TEST_DIR/retried" ]; then
  touch "$BS_IMPORT_TEST_DIR/retried"
  printf 'error code: 1101' > "$response"
  printf '500'
elif [[ "$name" = items* ]] && [ ! -f "$BS_IMPORT_TEST_DIR/repaired" ]; then
  printf '{"error":"invalid row"}' > "$response"
  printf '400'
else
  printf '{"imported":1}' > "$response"
  printf '200'
fi
`);
    chmodSync(curl, 0o755);
    const env = { ...process.env, BS_IMPORT_TEST_DIR: dir,
      BS_IMPORT_TOKEN_FILE: join(dir, ".bs-share-import-token"), PATH: `${dir}:${process.env.PATH}` };
    const importer = resolve(import.meta.dirname, "../../scripts/import-abilities.sh");
    let run = spawnSync("bash", [importer, dump], { env, encoding: "utf8" });
    assert.equal(run.status, 1, run.stdout + run.stderr);
    batches = run.stderr.match(/--resume (\S+)\n/)?.[1];
    assert.ok(batches, run.stderr);
    assert.equal(existsSync(join(batches, "auth.header")), false);
    assert.equal(existsSync(join(batches, "abilities_001_001.json.done")), true);
    assert.equal(existsSync(join(batches, "items_001_001.json.done")), false);
    writeFileSync(join(dir, "repaired"), "");
    run = spawnSync("bash", [importer, "--resume", batches], { env, encoding: "utf8" });
    assert.equal(run.status, 0, run.stdout + run.stderr);
    const calls = readFileSync(join(dir, "calls"), "utf8").trim().split("\n");
    assert.equal(calls.filter(v => v === "abilities_001_001.json").length, 2);
    assert.equal(calls.filter(v => v === "items_001_001.json").length, 2);
    assert.equal(calls.filter(v => v === "scribing_001_001.json").length, 1);
    assert.equal(calls.filter(v => v === "mechanics_001_001.json").length, 1);
    assert.equal(calls.filter(v => v === "defs-trait_001_001.json").length, 1);
    assert.equal(existsSync(batches), false);
  } finally {
    rmSync(dir, { recursive: true, force: true });
    if (batches) rmSync(batches, { recursive: true, force: true });
  }
});

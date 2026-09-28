import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { build } from "esbuild";
import { api } from "./worker-api.mjs";

const root = fileURLToPath(new URL("../../", import.meta.url));
const bundle = await build({ entryPoints: [new URL("../src/shared/decoder.ts", import.meta.url).pathname], bundle: true, write: false, format: "esm", platform: "node" });
const { parseExportStream, decodeEncounter } = await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString("base64")}`);
function fixture(uiPlatform = 2, world = "EU Megaserver", service = 0) {
  const result = spawnSync("lua", ["tests/fixtures/share_export.lua", String(uiPlatform), world, String(service)], { cwd: root, encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout;
}
const upload = (request, data, options = {}) => request("chunk", { data, index: 1, count: 1, ...options });

test("actual Lua exports identify the device independently of the account service and preserve the raw world", async t => {
  const request = api();
  t.after(() => request.db.close());
  const ids = [];
  for (const [uiPlatform, service, world, platform] of [
    [2, 0, "EU Megaserver", "pc"],
    [0, 2, "XB1live-eu", "xbox"],
    [2, 2, "XB1live-eu", "pc"], // Play Anywhere: Xbox service/server, PC device.
    [1, 1, "PS4live", "playstation"],
    [4, 1, "PS4live-eu", "playstation"],
    [2, 0, "PTS", "pc"],
    [2, 0, "Future server", "pc"],
  ]) {
    const payload = fixture(uiPlatform, world, service);
    const bytes = Buffer.from(payload, "base64");
    assert.equal(bytes[0], 8);
    const wire = await parseExportStream(bytes);
    assert.equal(wire.platform, platform);
    assert.equal(wire.worldName, world);
    assert.equal(wire.encounters[0].shared[0].displayName, "SharedMember");
    const decoded = decodeEncounter(wire.encounters[0].dataBytes, wire.registry, wire.encounters[0].durationMs);
    assert.equal(decoded.unitNames[1], "Recorder");
    assert.equal(decoded.resurrectionLog[0].displayName, "Resurrected");
    const result = await upload(request, payload);
    assert.equal(result.status, 200, JSON.stringify(result.body));
    const id = result.body.shareId;
    ids.push(id);
    const row = request.db.prepare("SELECT platform, world_name FROM shares WHERE id = ?").get(id);
    assert.deepEqual({ ...row }, { platform, world_name: world });
    const names = request.db.prepare("SELECT display_name, name_key FROM share_names WHERE share_id = ? ORDER BY display_name").all(id);
    assert.deepEqual(names.map(n => n.display_name), ["Healer", "NPC", "Recorder", "Resurrected", "SharedMember", "Éowyn"]);
    assert.equal(names.find(n => n.display_name === "Éowyn").name_key, "éowyn");
    const response = await request.fetch(`/api/share/${id}`);
    assert.equal(response.headers.get("cache-control"), "private, max-age=604800, must-revalidate");
    assert.deepEqual(Buffer.from(await response.arrayBuffer()), Buffer.from(payload, "base64"));
    const head = await request.fetch(`/api/share/${id}`, { method: "HEAD" });
    assert.equal(head.status, 200);
    assert.equal(head.headers.get("cache-control"), response.headers.get("cache-control"));
    assert.equal((await head.arrayBuffer()).byteLength, 0);
  }
  assert.ok(request.db.prepare("PRAGMA table_info(shares)").all().every(column => column.name !== "region"));
  const matches = request.db.prepare(`SELECT s.id FROM shares s JOIN share_names n ON n.share_id = s.id
    WHERE s.world_name = ? AND n.name_key = ?`).all("XB1live-eu", "recorder");
  assert.deepEqual(new Set(matches.map(r => r.id)), new Set([ids[1], ids[2]]));
  request.db.prepare("DELETE FROM shares WHERE id = ?").run(ids[1]);
  assert.equal(request.db.prepare("SELECT count(*) AS n FROM share_names WHERE share_id = ?").get(ids[1]).n, 0);
  assert.equal((await request.fetch(`/api/share/${ids[1]}`)).status, 404);
  const removedHead = await request.fetch(`/api/share/${ids[1]}`, { method: "HEAD" });
  assert.equal(removedHead.status, 404);
  assert.equal((await removedHead.arrayBuffer()).byteLength, 0);
  assert.equal((await request.fetch(`/api/share/${ids[0]}`)).status, 200);
});

test("a failed index write rolls back the report and malformed platform/version never creates a share", async t => {
  const request = api();
  t.after(() => request.db.close());
  const bytes = Buffer.from(fixture(), "base64");
  for (const version of [7, 9]) {
    const invalid = Buffer.from(bytes);
    invalid[0] = version;
    assert.equal((await upload(request, invalid.toString("base64"))).status, 400);
  }
  const bad = Buffer.from(bytes);
  // Skip the export timestamp varint after the two-byte framing header.
  let offset = 2;
  while (bad[offset++] & 128) {}
  bad[offset] = 255;
  assert.equal((await upload(request, bad.toString("base64"))).status, 400);
  request.db.exec("CREATE TRIGGER reject_index BEFORE INSERT ON share_names BEGIN SELECT RAISE(ABORT, 'test index failure'); END;");
  assert.equal((await upload(request, bytes.toString("base64"))).status, 400);
  assert.equal(request.db.prepare("SELECT count(*) AS n FROM shares").get().n, 0);
  assert.equal(request.db.prepare("SELECT count(*) AS n FROM share_names").get().n, 0);
});

test("multipart assembly indexes only complete reports and cron cleans expired chunks even without traffic", async t => {
  const request = api();
  t.after(() => request.db.close());
  const bytes = Buffer.from(fixture(0, "XB1live", 2), "base64");
  const split = Math.floor(bytes.length / 2);
  await upload(request, bytes.subarray(0, split).toString("base64"), { session: "fixture", count: 2 });
  assert.equal(request.db.prepare("SELECT count(*) AS n FROM share_names").get().n, 0);
  const result = await upload(request, bytes.subarray(split).toString("base64"), { session: "fixture", count: 2, index: 2 });
  assert.equal(result.status, 200, JSON.stringify(result.body));
  assert.ok(result.body.shareId);
  assert.deepEqual({ ...request.db.prepare("SELECT platform, world_name FROM shares").get() }, {
    platform: "xbox", world_name: "XB1live",
  });
  const repeated = await upload(request, bytes.subarray(0, split).toString("base64"), { session: "fixture", count: 2 });
  assert.equal(repeated.body.shareId, result.body.shareId);
  const now = Math.floor(Date.now() / 1000);
  request.db.prepare("UPDATE upload_chunks SET created_at = ?").run(now - 7200);
  request.db.prepare("INSERT INTO upload_chunks VALUES (?, 1, 2, ?, ?)").run("fresh", now, bytes);
  await request.scheduled();
  assert.deepEqual(request.db.prepare("SELECT session_id FROM upload_chunks").all().map(r => r.session_id), ["fresh"]);
  assert.equal(request.db.prepare("SELECT count(*) AS n FROM shares").get().n, 1);
});

test("privacy routes are accessible without a report", async t => {
  const request = api();
  t.after(() => request.db.close());
  for (const path of ["/privacy", "/privacy/?l=ru"]) {
    const response = await request.fetch(path);
    assert.equal(await response.text(), "/privacy.html");
  }
});

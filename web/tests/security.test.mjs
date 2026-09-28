import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { deflateRawSync } from "node:zlib";
import { test } from "node:test";
import { build } from "esbuild";
import { api } from "./worker-api.mjs";

const root = fileURLToPath(new URL("../../", import.meta.url));
const bundle = await build({
  stdin: { contents: `export * from "./src/shared/decoder";
    export * from "./src/client/format"; export * from "./src/client/tabs";`,
  resolveDir: fileURLToPath(new URL("../", import.meta.url)) },
  bundle: true, write: false, format: "esm", platform: "node",
});
const { parseExportStream, MAX_EXPORT_BYTES, csvCell, decodeEncounter, decodeSharedEntry, NAV_GROUPS } =
  await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString("base64")}`);

function fixture(memberName = "SharedMember") {
  const lua = readFileSync(new URL("../../tests/fixtures/share_export.lua", import.meta.url), "utf8")
    .replace('"SharedMember"', JSON.stringify(memberName));
  const run = spawnSync("lua", ["-"], { cwd: root, input: lua, encoding: "utf8" });
  assert.equal(run.status, 0, run.stderr);
  return Buffer.from(run.stdout, "base64");
}

function compress(bytes) {
  return Buffer.concat([Buffer.from([bytes[0], bytes[1] | 1]), deflateRawSync(bytes.subarray(2))]);
}

// Valid wire framing with a large opaque encounter body, as accepted in the
// original reproducer. No arbitrary parsing failure can hide the missing cap.
function largeExport(bodySize) {
  const parts = [];
  const byte = value => parts.push(Buffer.from([value]));
  const uint = value => {
    do {
      const digit = value % 128;
      value = Math.floor(value / 128);
      byte(digit + (value ? 128 : 0));
    } while (value);
  };
  const str = text => { const bytes = Buffer.from(text); uint(bytes.length); parts.push(bytes); };
  uint(0); byte(1); str("EU"); str("Audit"); uint(0); byte(0);
  uint(0); uint(0); uint(0); uint(0); uint(1);
  byte(0); str("Audit"); str(""); uint(0); uint(10000); uint(1);
  uint(0); uint(0); uint(0);
  // Reserve the 4-byte length prefix and two trailing zero counts.
  const payloadSize = bodySize - Buffer.concat(parts).length - 6;
  assert.ok(payloadSize >= 2 ** 21 && payloadSize < 2 ** 28);
  uint(payloadSize); parts.push(Buffer.alloc(payloadSize)); uint(0); byte(0);
  const body = Buffer.concat(parts);
  assert.equal(body.length, bodySize);
  return Buffer.concat([Buffer.from([8, 0]), body]);
}

test("compressed reports round-trip through the shared decoder and upload API", async t => {
  const request = api();
  t.after(() => request.db.close());
  const raw = fixture();
  const compressed = compress(raw);
  assert.deepEqual(await parseExportStream(compressed), await parseExportStream(new Uint8Array(raw)));
  const result = await request("chunk", { index: 1, count: 1, data: compressed.toString("base64") }, "");
  assert.equal(result.status, 200);
  const response = await request.fetch(`/api/share/${result.body.shareId}`);
  assert.deepEqual(Buffer.from(await response.arrayBuffer()), compressed);
});

test("the expanded-body limit accepts its boundary and rejects one byte more", async () => {
  const boundary = compress(largeExport(MAX_EXPORT_BYTES));
  assert.equal((await parseExportStream(boundary)).encounters.length, 1);
  await assert.rejects(parseExportStream(compress(largeExport(MAX_EXPORT_BYTES + 1))), /payload too large/);
  await assert.rejects(parseExportStream(largeExport(MAX_EXPORT_BYTES)), /payload too large/);
});

test("a small compression bomb cannot create a share or name index, including multipart uploads", async t => {
  const request = api();
  t.after(() => request.db.close());
  const compressed = compress(largeExport(16 * 1024 * 1024));
  assert.ok(compressed.length < 40 * 1024);
  const upload = body => request("chunk", body, "");
  const single = await upload({ index: 1, count: 1, data: compressed.toString("base64") });
  assert.equal(single.status, 400);
  assert.match(single.body.error, /payload too large/);
  const split = Math.floor(compressed.length / 2);
  assert.equal((await upload({ session: "bomb", index: 1, count: 2,
    data: compressed.subarray(0, split).toString("base64") })).status, 200);
  const last = await upload({ session: "bomb", index: 2, count: 2,
    data: compressed.subarray(split).toString("base64") });
  assert.equal(last.status, 400);
  assert.match(last.body.error, /payload too large/);
  assert.equal(request.db.prepare("SELECT count(*) AS n FROM shares").get().n, 0);
  assert.equal(request.db.prepare("SELECT count(*) AS n FROM share_names").get().n, 0);
});

test("oversized decompression cancels its producer before buffering the entire output", async t => {
  let produced = 0;
  let cancelled = false;
  const chunk = new Uint8Array(1024 * 1024);
  t.mock.method(globalThis, "DecompressionStream", class {
    writable = new WritableStream();
    readable = new ReadableStream({
      pull(controller) {
        if (produced === 16) controller.close();
        else { produced++; controller.enqueue(chunk); }
      },
      cancel() { cancelled = true; },
    });
  });
  await assert.rejects(parseExportStream(new Uint8Array([8, 1, 0])), /payload too large/);
  assert.equal(cancelled, true);
  // Nine consumed chunks cross the limit; the stream may prefetch one more.
  assert.ok(produced <= 10, `produced ${produced} MiB`);
});

test("truncated compressed input is rejected", async () => {
  const compressed = compress(fixture());
  await assert.rejects(parseExportStream(compressed.subarray(0, compressed.length - 3)));
});

test("CSV text formulas are quoted and made inert without changing numeric cells", () => {
  for (const input of ["=1+1", "+1+1", "-1+1", "@SUM(A1)", "\t=1+1", "\r=1+1", "\n=1+1",
    " =1+1", "\u0000=1+1", "\ufeff=1+1", "＝1+1", "＋1+1", "－1+1", "＠SUM(A1)",
    '=HYPERLINK("https://example.invalid","click")']) {
    assert.equal(csvCell(input), '"\t' + input.replace(/"/g, '""') + '"', JSON.stringify(input));
  }
  for (const input of [0, 1, -1, -1.25, 1234.5]) assert.equal(csvCell(input), String(input));
  assert.equal(csvCell("Éowyn"), "Éowyn");
  assert.equal(csvCell('Name,"quoted"'), '"Name,""quoted"""');
  assert.equal(csvCell("Name\r=1+1"), '"Name\r=1+1"');
  assert.equal(csvCell("Name\n=1+1"), '"Name\n=1+1"');
});

test("an uploaded formula in a group member name stays inert in exported CSV", async t => {
  const request = api();
  t.after(() => request.db.close());
  const bytes = fixture("=1+1");
  const result = await request("chunk", { index: 1, count: 1, data: bytes.toString("base64") }, "");
  assert.equal(result.status, 200);
  const response = await request.fetch(`/api/share/${result.body.shareId}`);
  const share = await parseExportStream(new Uint8Array(await response.arrayBuffer()));
  const wireEnc = share.encounters[0];
  const ctx = { wireEnc, share, durationMs: wireEnc.durationMs,
    decoded: decodeEncounter(wireEnc.dataBytes, share.registry, wireEnc.durationMs),
    sharedDecoded: new Map(wireEnc.shared.map(s => [s, decodeSharedEntry(s.payloadBytes, s)])),
    names: {}, knownAbilityIds: new Set(), itemNames: {}, championNames: {},
    bossUnits: new Set(), pins: new Set(), defs: {}, scribing: {} };
  const group = NAV_GROUPS.flatMap(g => g.subs).find(sub => sub.id === "group").render(ctx);
  const row = group.csv.find(row => row[1] === "=1+1");
  assert.ok(row);
  assert.match(row.map(csvCell).join(","), /^1,"\t=1\+1",/);
});

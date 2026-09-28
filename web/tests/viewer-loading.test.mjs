import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { createContext, runInContext } from "node:vm";
import { build } from "esbuild";

// Run the real shell, router and renderers with controlled network timing.
// Only binary decoding is replaced by fixtures; test exports stay out of the app.
const source = readFileSync(new URL("../src/client/app.ts", import.meta.url), "utf8");
const bundle = await build({
  stdin: { contents: source + "\nexport { state, render };", loader: "ts",
    resolveDir: fileURLToPath(new URL("../src/client/", import.meta.url)) },
  bundle: true, write: false, format: "iife", globalName: "viewer",
  plugins: [{ name: "decoded-fixture", setup(build) {
    build.onLoad({ filter: /shared\/decoder\.ts$/ }, () => ({ contents: `
      export async function parseExportStream() { return globalThis.fixture; }
      export function decodeEncounter() { return globalThis.decoded; }
      export function decodeSharedEntry() { throw new Error("Unexpected shared fixture"); }
    ` }));
  } }],
});

const flush = () => new Promise(resolve => setImmediate(resolve));

function encounter(classId) {
  return {
    displayName: `Encounter ${classId}`, timestampS: 1, durationMs: 10000,
    playerUnitId: 1, bossesUnits: [], bossTagSeqByUnitId: {}, bossSeqNames: {},
    shared: [], dataBytes: new Uint8Array(),
    setup: { classId, raceId: 1, equipSlots: [{ itemId: 201, enchantId: 301, traitType: 1 }],
      champion: [{ skillId: 401 }], abilities: { front: [
        { abilityId: 100, scriptIds: [11, 21, 41] },
        { abilityId: 101, scriptIds: [11, 21, 41] },
      ] } },
  };
}

function payload(request, label = request.body.lang) {
  const { ids, kind, recipes } = request.body;
  if (recipes) return { abilities: Object.fromEntries(recipes.map(recipe => [
    [recipe.craftedAbilityId, ...recipe.scriptIds, recipe.classId].join(":"), { name: label },
  ])) };
  const values = Object.fromEntries(ids.map(id => [id, {
    name: label, icon: "/esoui/test.dds",
    ...(request.path.includes("abilities") ? { craftedAbilityId: id - 95 } : {}),
    ...(request.path.includes("items") ? { setId: 501 } : {}),
  }]));
  return kind ? { defs: values } : values;
}

async function app({ hash = "#/0/overview", count = 2, mobile = false } = {}) {
  const requests = [];
  const events = new Map();
  const rootEvents = new Map();
  const listen = map => (type, callback) => {
    if (!map.has(type)) map.set(type, []);
    map.get(type).push(callback);
  };
  const emit = (map, type, event) => map.get(type)?.forEach(callback => callback(event));
  const root = { innerHTML: "", querySelectorAll: () => [], querySelector: () => null,
    addEventListener: listen(rootEvents) };
  const location = new URL(`https://test/s/example${hash}`);
  location.replace = href => {
    location.href = href;
    queueMicrotask(() => emit(events, "hashchange"));
  };
  const context = createContext({
    URL, URLSearchParams, setTimeout,
    location, history: { replaceState: (_state, _unused, url) => { location.href = url.href; } },
    navigator: { language: "en" }, localStorage: { getItem: () => null, setItem() {} },
    document: { getElementById: () => root, addEventListener() {} },
    window: { matchMedia: () => ({ matches: mobile }), addEventListener: listen(events), scrollTo() {} },
    fixture: { registry: { abilityIds: [100], facts: { 100: { direct: true } } },
      encounters: Array.from({ length: count }, (_, i) => encounter(i + 1)),
      instanceName: "Test", createdAtS: 1 },
    decoded: { damageByUnitId: {}, damageByUnitIdGroup: {}, damageTakenByUnitId: {},
      healingStats: {}, unitNames: {}, procs: [] },
    fetch: (path, options) => {
      if (path.startsWith("/api/share/")) return Promise.resolve({ ok: true, arrayBuffer: async () => new ArrayBuffer(0) });
      return new Promise((resolve, reject) => {
        const request = { path, body: JSON.parse(options.body), done: false,
          respond(value = payload(request)) {
            assert.equal(request.done, false);
            request.done = true;
            resolve({ ok: true, json: async () => value });
          },
          fail() { request.done = true; reject(new Error("Offline")); },
        };
        requests.push(request);
      });
    },
  });
  runInContext(bundle.outputFiles[0].text, context);
  await flush();
  assert.ok(context.viewer.state.wire, root.innerHTML);
  assert.match(root.innerHTML, /class="topbar"/);
  return {
    ...context.viewer, root, requests, location,
    language(lang) {
      emit(rootEvents, "change", { target: {
        value: lang, classList: { contains: name => name === "lang-select" }, closest: () => null,
      } });
    },
    navigate(hash) { location.hash = hash; emit(events, "hashchange"); },
    async settle(start = 0) {
      for (let i = 0; i < 10; i++) {
        await flush();
        const pending = requests.slice(start).filter(request => !request.done);
        if (!pending.length) return;
        pending.forEach(request => request.respond());
        await flush();
      }
      assert.fail("Loads did not settle");
    },
  };
}

test("boot and navigation start lazy loads; repainting alone never starts them", async () => {
  const viewer = await app({ hash: "" });
  assert.equal(viewer.state.view, "list");
  assert.equal(viewer.requests.length, 1); // only the combat registry
  viewer.state.encounterIdx = 0;
  viewer.state.view = "enc";
  viewer.render();
  await flush();
  assert.equal(viewer.requests.length, 1);
  viewer.navigate("#/0/overview");
  assert.ok(viewer.requests.some(request => request.path.includes("items")));
  await viewer.settle();
  assert.equal(viewer.state.names[100].name, "en");
  assert.equal(viewer.state.defs.set[501].name, "en");
  assert.equal(viewer.state.scribing["5:11:21:41:1"].name, "en");
  const count = viewer.requests.length;
  viewer.render();
  viewer.navigate("#/1/overview");
  await viewer.settle();
  assert.equal(viewer.state.encounterIdx, 1);
  // Same metadata, but this encounter's class creates different recipes.
  assert.equal(viewer.requests.length, count + 1);
  assert.equal(viewer.state.scribing["5:11:21:41:2"].name, "en");
});

test("navigation awaits shared in-flight abilities and items before dependent lookups", async () => {
  const viewer = await app();
  const initial = [...viewer.requests];
  viewer.navigate("#/1/overview");
  await flush();
  assert.equal(viewer.requests.length, initial.length);
  const registry = initial.find(request => request.path.includes("abilities") && request.body.ids.includes(100));
  const items = initial.find(request => request.path.includes("items"));
  for (const request of initial) if (request !== registry && request !== items) request.respond();
  await flush();
  assert.equal(viewer.requests.length, initial.length);
  registry.respond();
  items.respond();
  await viewer.settle();
  assert.equal(viewer.state.encounterIdx, 1);
  assert.equal(viewer.state.scribing["5:11:21:41:2"].name, "en");
  assert.equal(viewer.state.defs.set[501].name, "en");
  assert.equal(viewer.requests.filter(request => request.body.kind === "set").length, 1);
});

test("rapid language changes reject stale responses, including delayed JSON and a return to the original language", async () => {
  const viewer = await app();
  const old = [...viewer.requests];
  let finishJson;
  const delayed = new Promise(resolve => { finishJson = resolve; });
  old[0].respond(delayed);
  await flush(); // headers arrived, body is still being read
  viewer.language("de");
  assert.match(viewer.root.innerHTML, /value="de" selected/);
  const german = viewer.requests.slice(old.length);
  const currentStart = viewer.requests.length;
  viewer.language("en");
  assert.match(viewer.root.innerHTML, /value="en" selected/);
  assert.equal(viewer.state.names[100].mech.direct, true);
  finishJson(payload(old[0], "obsolete"));
  for (const request of [...old.slice(1), ...german]) request.respond(payload(request, "obsolete"));
  await flush();
  assert.equal(viewer.state.names[100].name, undefined);
  assert.equal(Object.keys(viewer.state.itemNames).length, 0);
  assert.equal(Object.keys(viewer.state.championNames).length, 0);
  assert.equal(Object.keys(viewer.state.defs.script).length, 0);
  // An obsolete completion must also leave the current request cache intact.
  const count = viewer.requests.length;
  viewer.navigate("#/1/overview");
  await flush();
  assert.equal(viewer.requests.length, count);
  await viewer.settle(currentStart);
  for (const value of [viewer.state.names[100], viewer.state.names[101], viewer.state.itemNames[201],
    viewer.state.championNames[401], viewer.state.defs.script[11], viewer.state.defs.set[501],
    viewer.state.scribing["5:11:21:41:2"]]) assert.equal(value.name, "en");
  assert.equal(viewer.state.names[100].mech.direct, true);
});

test("obsolete scribing and set-definition responses cannot overwrite a newer language generation", async () => {
  const viewer = await app();
  viewer.requests.forEach(request => request.respond());
  await flush();
  const old = viewer.requests.filter(request => !request.done);
  assert.ok(old.some(request => request.path.includes("scribing")));
  assert.ok(old.some(request => request.body.kind === "set"));
  viewer.language("de");
  const currentStart = viewer.requests.length;
  viewer.language("en");
  await viewer.settle(currentStart);
  for (const request of viewer.requests.slice(0, currentStart).filter(request => !request.done)) {
    request.respond(payload(request, "obsolete"));
  }
  await flush();
  assert.equal(viewer.state.scribing["5:11:21:41:1"].name, "en");
  assert.equal(viewer.state.defs.set[501].name, "en");
});

test("a failed lookup remains best effort without a render-driven retry loop", async () => {
  const viewer = await app({ count: 1, hash: "", mobile: true });
  assert.equal(viewer.state.view, "menu");
  viewer.requests.forEach(request => request.fail());
  await flush();
  const count = viewer.requests.length;
  viewer.render();
  viewer.navigate("#/0/overview");
  await flush();
  assert.equal(viewer.requests.length, count);
  assert.equal(viewer.state.names[100].mech.direct, true);
  assert.match(viewer.root.innerHTML, /Encounter 1/);
});

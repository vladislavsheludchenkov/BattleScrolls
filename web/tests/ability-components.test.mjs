import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";
import { fileURLToPath } from "node:url";
import { build } from "esbuild";

// Exercise the actual tab renderers and their shared stores, without a DOM
// or a second implementation of the aggregation logic.
const bundle = await build({
  stdin: {
    contents: `export * from "./src/client/metrics";
      export * from "./src/client/tabs";
      export * from "./src/shared/eso_text";
      export * from "./src/client/strings";`,
    resolveDir: fileURLToPath(new URL("../", import.meta.url)),
  },
  bundle: true, write: false, format: "esm", platform: "node",
});
const viewer = await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString("base64")}`);
const { NAV_GROUPS, setLang, healingRows, mergeSources, clearUnitFilters, applyFilterOnly,
  healingBases, resetFilters, toggleFilterGroup, openFilterPanels, unitFilters, tabFilters } = viewer;

beforeEach(() => {
  setLang("en");
  clearUnitFilters();
  healingBases.clear();
  viewer.groupSortState.col = "dps";
  viewer.groupSortState.dir = -1;
});

function damage(total) {
  return { total, rawTotal: total, ticks: 10, critTicks: 2, minTick: total / 20, maxTick: total / 5 };
}

function healing(real, overheal = 0, ticks = 10, critTicks = 2, minTick = 10, maxTick = 100) {
  return { real, raw: real + overheal, overheal, ticks, critTicks, minTick, maxTick };
}

function context() {
  return {
    durationMs: 10000,
    wireEnc: { playerUnitId: 1, shared: [], bossSeqNames: {}, bossTagSeqByUnitId: {} },
    decoded: {
      damageByUnitId: { 1: { 9: { 101: damage(30000), 102: damage(70000) } } },
      damageByUnitIdGroup: {}, damageTakenByUnitId: {},
      unitNames: { 1: "Player", 2: "Pet", 9: "Boss", 10: "Add", 11: "Ally" },
      healingStats: {
        selfHealing: { total: { real: 1000, raw: 1400, overheal: 400 }, bySourceUnitIdByAbilityId: {
          1: { 201: healing(300, 100), 202: healing(700, 300) },
        } },
        healingOutToGroup: {}, healingInFromGroup: {},
      },
    },
    names: {
      101: { name: "Mixed Skill", mech: { direct: true, damageTypes: [6], aoe: 0 } },
      102: { name: "Mixed Skill", mech: { overTime: true, damageTypes: [8], aoe: 1 } },
      201: { name: "Mixed Heal", mech: { direct: true } },
      202: { name: "Mixed Heal", mech: { overTime: true } },
    },
    knownAbilityIds: new Set([101, 102, 201, 202]), bossUnits: new Set([9]),
    itemNames: {}, championNames: {}, defs: {}, sharedDecoded: new Map(), pins: new Set(), share: {},
  };
}

  const effect = id => ({ abilityId: id, effectType: 1, totalActiveTimeMs: 5000,
    playerActiveTimeMs: 2000, timeAtMaxStacksMs: 1000, applications: 5,
    playerApplications: 2, maxStacks: 2, peakConcurrentInstances: 1 });

let renderedHtml = "";
function render(ctx, id) {
  const result = NAV_GROUPS.flatMap((g) => g.subs).find((s) => s.id === id).render(ctx);
  renderedHtml = result.html;
  return result;
}

function detailsFor(name) {
  const stack = [];
  for (const match of renderedHtml.matchAll(/<details\b[^>]*>|<\/details>/g)) {
    if (match[0].startsWith("<details")) stack.push(match.index);
    else {
      const start = stack.pop();
      const html = renderedHtml.slice(start, match.index + match[0].length);
      const summary = html.match(/<summary\b[^>]*>([\s\S]*?)<\/summary>/)?.[1];
      // Match the row's text, not a substring of another row's metric label
      // (for example, "Raw Heal" must not match the label "Raw Healing").
      if (summary?.split(/<[^>]*>/).some(text => text.trim() === name)) return html;
    }
  }
  assert.fail(`No disclosure for ${name}`);
}

function assertPair(html, label, value) {
  const candidates = [
    `>${label}</dt><dd>${value}</dd>`,
    `>${label}</span><span class="v">${value}</span>`,
    `${label} <span class="component-value">${value.replace(/ \((.+)\)$/, " · $1")}</span>`,
  ];
  assert.ok(candidates.some(text => html.includes(text)), `${label}: ${value}`);
}

function assertComposition(html, label, value) {
  assert.ok(html.includes(`class="kv-k">${label}</span><span class="kv-v">${value}</span>`), `${label}: ${value}`);
}

test("same-name damage components retain their labels, amounts, and composition", () => {
  const result = render(context(), "damage-done");
  assert.equal(result.csv.length, 2);
  assert.equal(result.csv[1][1], 100000);
  const details = detailsFor("Mixed Skill");
  assertPair(details, "Direct · Frost", "30.0K (30.0%)");
  assertPair(details, "DoT · Magic", "70.0K (70.0%)");
  const direct = detailsFor("Direct · Frost");
  assertPair(direct, "Hits", "10");
  assertPair(direct, "Crit", "20.0%");
  assertPair(direct, "Min – max", "1.5K – 6.0K");
  assert.match(result.html, /Direct · DoT · AoE/);
  for (const label of ["Direct", "Frost", "Single target"]) assertComposition(result.html, label, "30.0%");
  for (const label of ["DoT", "Magic", "AoE"]) assertComposition(result.html, label, "70.0%");
});

test("component composition respects source and target filters", () => {
  const ctx = context();
  ctx.decoded.damageByUnitId[1][10] = { 101: damage(100000) };
  ctx.decoded.damageByUnitId[2] = { 9: { 101: damage(500000) } };
  applyFilterOnly(ctx, "damage-done", "main", "Boss");
  applyFilterOnly(ctx, "damage-done", "source", "__SELF__");
  const result = render(ctx, "damage-done");
  assert.equal(result.csv[1][1], 100000);
  assertComposition(result.html, "Frost", "30.0%");
  assertComposition(result.html, "Magic", "70.0%");
});

test("healing grouping preserves weighted stats, components, and the input", () => {
  const source = {
    1: { 201: healing(300, 100, 2, 1, 80, 320) },
    2: { 202: healing(700, 300, 8, 2, 20, 200) },
  };
  const before = structuredClone(source);
  const [row] = healingRows(mergeSources(source), () => "Mixed Heal");
  assert.deepEqual([row.real, row.raw, row.overheal, row.ticks, row.critTicks, row.minTick, row.maxTick],
    [1000, 1400, 400, 10, 3, 20, 320]);
  assert.deepEqual(row.variants.map((v) => [v.abilityId, v.real]), [[202, 700], [201, 300]]);
  assert.deepEqual(source, before);
});

test("all healing tabs merge names and label direct/HoT components", () => {
  for (const tab of ["self-healing", "healing-out", "healing-in"]) {
    const ctx = context();
    const self = ctx.decoded.healingStats.selfHealing;
    ctx.decoded.healingStats.healingOutToGroup[11] = structuredClone(self);
    ctx.decoded.healingStats.healingInFromGroup[11] = {
      total: self.total, byAbilityId: self.bySourceUnitIdByAbilityId[1],
    };
    const result = render(ctx, tab);
    const rows = result.csv.filter((r) => r[0] === "All" && r[1] === "Mixed Heal");
    assert.equal(rows.length, 1);
    const multiplier = tab === "self-healing" ? 1 : 2;
    assert.deepEqual(rows[0].slice(2, 7), [1400, 1000, 400, 140, 100].map((n) => n * multiplier));
    assert.deepEqual(rows[0].slice(8, 10), [20 * multiplier, 4 * multiplier]);
      render(ctx, tab);
    const details = detailsFor("Mixed Heal");
    assertPair(details, "Direct", `${400 * multiplier} (28.6%)`);
    assertPair(details, "HoT", `${multiplier === 1 ? "1.0K" : "2.0K"} (71.4%)`);
    assert.doesNotMatch(details, /DoT/);
  }
});

test("pure overhealing uses raw component shares and retains shield/regen labels in all locales", () => {
  const ctx = context();
  const self = ctx.decoded.healingStats.selfHealing;
  self.total = { real: 0, raw: 1000, overheal: 1000 };
  self.bySourceUnitIdByAbilityId = { 1: { 201: healing(0, 300), 202: healing(0, 700) } };
  ctx.names[201].mech = { shield: true };
  ctx.names[202].mech = { regen: true };
  for (const lang of ["en", "de", "es", "fr", "jp", "ru", "zh"]) {
    setLang(lang);
      render(ctx, "self-healing");
    const details = detailsFor("Mixed Heal");
    assertPair(details, viewer.t("tag_shield"), "300 (30.0%)");
    assertPair(details, viewer.t("tag_regen"), "700 (70.0%)");
  }
});

test("duplicate or missing component classifications remain distinguishable", () => {
  const ctx = context();
  ctx.names[102].mech = { ...ctx.names[101].mech };
  render(ctx, "damage-done");
  assertPair(detailsFor("Mixed Skill"), "Direct · Frost (#101)", "30.0K (30.0%)");
  assertPair(detailsFor("Mixed Skill"), "Direct · Frost (#102)", "70.0K (70.0%)");
  delete ctx.names[101].mech;
  const result = render(ctx, "damage-done");
  assertPair(detailsFor("Mixed Skill"), "#101", "30.0K (30.0%)");
  assertComposition(result.html, "Unclassified", "30.0%");
});

test("supplemental amounts stay outside damage classification denominators", () => {
  const ctx = context();
  ctx.decoded.damageByUnitId[1][9][1048574] = damage(50000);
  const result = render(ctx, "damage-done");
  assertComposition(result.html, "Frost", "30.0%");
  assertComposition(result.html, "Magic", "70.0%");
  assertComposition(result.html, "Unknown (Shielded)", "50.0K");
});

function healingFixture() {
  const ctx = context();
  ctx.names[201].name = "Raw Heal";
  ctx.names[202].name = "Effective Heal";
  const self = ctx.decoded.healingStats.selfHealing;
  self.total = { raw: 1000, real: 190, overheal: 810 };
  self.bySourceUnitIdByAbilityId = { 1: {
    201: healing(100, 800, 10, 5, 10, 200),
    202: healing(90, 10, 2, 1, 20, 80),
  } };
  const ally = { total: { raw: 500, real: 320, overheal: 180 }, bySourceUnitIdByAbilityId: { 1: {
    201: healing(20, 80, 2, 0, 20, 80),
    202: healing(300, 100, 4, 2, 40, 200),
  } } };
  ctx.decoded.healingStats.healingOutToGroup[11] = ally;
  ctx.decoded.healingStats.healingInFromGroup[11] = {
    total: ally.total, byAbilityId: ally.bySourceUnitIdByAbilityId[1],
  };
  return ctx;
}

function allHealingRows(result) { return result.csv.filter((r) => r[0] === "All"); }
function summary(result, title) { return result.csv.find((r) => r[0] === title)?.slice(0, 6); }

test("healing ranks by raw output by default; effective mode changes every share without changing totals", () => {
  const ctx = healingFixture();
  const result = render(ctx, "healing-out");
  const rows = allHealingRows(result);
  assert.deepEqual(rows.map(r => r[1]), ["Raw Heal", "Effective Heal"]);
  assert.deepEqual(summary(result, "Healing Out"), ["Healing Out", 1500, 510, 990, 150, 51]);
  assert.deepEqual(rows.map(r => r[14]), ["Raw", "Raw"]);
  assert.equal(rows[0][15], 1000 / 1500 * 100);
  assertPair(detailsFor("Raw Heal"), "Avg raw heal", "83.3");
  assert.match(result.html, /<details class="disclosure row-detail heal-ability">/);
  assert.match(result.html, /Raw HPS/);
  assert.match(result.html, /Effective HPS/);
  assert.match(result.html, /Healing delivery · Raw/);
  healingBases.set("healing-out", "real");
  const effective = render(ctx, "healing-out");
  assert.deepEqual(allHealingRows(effective).map(r => r[1]), ["Effective Heal", "Raw Heal"]);
  assert.equal(allHealingRows(effective)[0][15], 390 / 510 * 100);
  assert.match(effective.html, /Healing delivery · Effective/);
  assert.deepEqual(summary(effective, "Healing Out"), summary(result, "Healing Out"));
});

test("both healing directions use the selected self and group units throughout the view and CSV", () => {
  const ctx = healingFixture();
  for (const [tab, title] of [["healing-out", "Healing Out"], ["healing-in", "Healing In"]]) {
    applyFilterOnly(ctx, tab, "main", "Ally");
    const group = render(ctx, tab);
    assert.deepEqual(summary(group, title), [title, 500, 320, 180, 50, 32]);
    assert.deepEqual(allHealingRows(group).map(r => r[2]), [400, 100]);
    assert.equal(group.csv.some(r => r[0] === "You (Self)"), false);
    assertComposition(group.html, "HoT", "400 · 80.0%");
    applyFilterOnly(ctx, tab, "main", "__SELF__");
    const self = render(ctx, tab);
    assert.deepEqual(summary(self, title), [title, 1000, 190, 810, 100, 19]);
    assert.equal(self.csv.some(r => r[0] === "Ally"), false);
    resetFilters(tab);
    assert.deepEqual(summary(render(ctx, tab), title), [title, 1500, 510, 990, 150, 51]);
  }
});

test("raw/effective component and delivery shares use individual variants after same-name merging", () => {
  const ctx = context();
  const result = render(ctx, "self-healing");
  assertComposition(result.html, "Direct", "400 · 28.6%");
  assertComposition(result.html, "HoT", "1.0K · 71.4%");
  const components = result.csv.filter(r => typeof r[0] === "number");
  assert.deepEqual(components.map(r => r[0]), [202, 201]);
  assert.equal(components[0][16], 1000 / 1400 * 100);
  assert.match(result.html, /Critical ticks/);
  assert.match(result.html, /Min – max raw heal/);
  healingBases.set("self-healing", "real");
  const effective = render(ctx, "self-healing");
  assertComposition(effective.html, "Direct", "300 · 30.0%");
  assertPair(detailsFor("Mixed Heal"), "HoT", "700 (70.0%)");
});

test("pure overheal retains raw output while effective shares and bars stay zero", () => {
  const ctx = context();
  ctx.decoded.healingStats.selfHealing = {
    total: { raw: 1000, real: 0, overheal: 1000 },
    bySourceUnitIdByAbilityId: { 1: { 201: healing(0, 1000) } },
  };
  assert.equal(allHealingRows(render(ctx, "self-healing"))[0][15], 100);
  healingBases.set("self-healing", "real");
  const effective = render(ctx, "self-healing");
  assert.equal(allHealingRows(effective)[0][15], 0);
  assert.match(effective.html, /class="dt-bar" style="width:0.0%"/);
  assert.doesNotMatch(effective.html, /NaN|Infinity/);
});

test("absorbed healing is last and excluded from ability shares, crit rate, max heal and delivery shares", () => {
  const ctx = healingFixture();
  const self = ctx.decoded.healingStats.selfHealing;
  self.bySourceUnitIdByAbilityId[1][1048573] = healing(10000, 0, 100, 0, 10000, 10000);
  self.total = { raw: 11000, real: 10190, overheal: 810 };
  const result = render(ctx, "self-healing");
  const rows = allHealingRows(result);
  assert.equal(rows.at(-1)[1], "Unknown (Absorbed)");
  assert.equal(rows.at(-1)[15], "");
  assert.deepEqual(rows.slice(0, 2).map(r => r[15]), [90, 10]);
  assert.match(result.html, /Crit rate<\/span><span class="metric-value">50.0%/);
  assert.match(result.html, /Max raw heal<\/span><span class="metric-value">200/);
  assertComposition(result.html, "Direct", "900 · 90.0%");
  assertComposition(result.html, "Unknown (Absorbed)", "10.0K · —");
});

test("delivery precedence matches the addon and health recovery stays regen without metadata", () => {
  assert.equal(viewer.healingDelivery(1, { overTime: true, direct: true }), "hot");
  assert.equal(viewer.healingDelivery(1, { shield: true, overTime: true }), "shield");
  assert.equal(viewer.healingDelivery(1, { regen: true, shield: true }), "regen");
  assert.equal(viewer.healingDelivery(1, { healAbsorption: true, regen: true }), "absorbed");
  assert.equal(viewer.healingDelivery(1048575), "regen");
  assert.equal(viewer.healingDelivery(2), "direct");
});

test("same-name recipients combine into one filtered unit and retain both unit IDs", () => {
  const ctx = healingFixture();
  ctx.decoded.unitNames[12] = "Ally";
  ctx.decoded.healingStats.healingOutToGroup[12] = structuredClone(ctx.decoded.healingStats.healingOutToGroup[11]);
  applyFilterOnly(ctx, "healing-out", "main", "Ally");
  const result = render(ctx, "healing-out");
  assert.deepEqual(summary(result, "Healing Out"), ["Healing Out", 1000, 640, 360, 100, 64]);
  const unitRows = result.csv.filter(r => r[0] === "Ally" && typeof r[1] === "number");
  assert.deepEqual(unitRows, [["Ally", 1000, 640, 360, 100, 64, "Raw", 100]]);
});

test("empty selection remains recoverable and reset only affects its own tab", () => {
  const ctx = healingFixture();
  applyFilterOnly(ctx, "healing-in", "main", "Ally");
  toggleFilterGroup(ctx, "healing-out", "main", "__SELF__");
  toggleFilterGroup(ctx, "healing-out", "main", "Ally");
  const empty = render(ctx, "healing-out");
  assert.match(empty.html, /data-filt-reset="healing-out">Reset/);
  assert.equal(allHealingRows(empty).length, 0);
  resetFilters("healing-out");
  assert.equal(summary(render(ctx, "healing-out"), "Healing Out")[1], 1500);
  assert.equal(summary(render(ctx, "healing-in"), "Healing In")[1], 500);
});

test("reset is visible across unit filters and restores both axes and the group-damage boss default", () => {
  const ctx = context();
  ctx.wireEnc.bossesUnits = [9];
  ctx.decoded.damageByUnitId[1][10] = { 101: damage(100000) };
  ctx.decoded.damageByUnitId[2] = { 9: { 101: damage(500000) } };
  applyFilterOnly(ctx, "damage-done", "main", "Add");
  applyFilterOnly(ctx, "damage-done", "source", "__SELF__");
  assert.match(render(ctx, "damage-done").html, /data-filt-reset="damage-done">Reset/);
  resetFilters("damage-done");
  assert.equal(unitFilters.size, 0);
  assert.match(render(ctx, "damage-done").html, /data-filt-reset="damage-done" disabled/);
  applyFilterOnly(ctx, "group-damage", "main", "Add");
  resetFilters("group-damage");
  openFilterPanels.add("group-damage");
  const result = render(ctx, "group-damage");
  assert.match(result.html, /data-filt-key="Boss" checked/);
  assert.match(result.html, /data-filt-key="Add">/);
});

test("effect-name reset clears search and the group's unit selection together", () => {
  const ctx = context();
  ctx.decoded.effectsOnPlayer = { 101: { abilityId: 101, effectType: 1, totalActiveTimeMs: 1000,
    playerActiveTimeMs: 1000, timeAtMaxStacksMs: 1000, applications: 1, playerApplications: 1,
    maxStacks: 1, peakConcurrentInstances: 1 } };
  tabFilters.set("effects-player", "missing");
  assert.match(render(ctx, "effects-player").html, /data-filt-reset="effects-player">Reset/);
  resetFilters("effects-player");
  assert.equal(tabFilters.has("effects-player"), false);
  assert.match(render(ctx, "effects-player").html, /Mixed Skill/);
  ctx.decoded.effectsOnGroup = { Ally: structuredClone(ctx.decoded.effectsOnPlayer) };
  applyFilterOnly(ctx, "effects-group", "main", "Ally");
  tabFilters.set("effects-group", "missing");
  resetFilters("effects-group");
  assert.equal(tabFilters.has("effects-group"), false);
  assert.equal(unitFilters.has("effects-group|main"), false);
  assert.match(render(ctx, "effects-group").html, /Average across 2 members/);
});

test("healing handles zero duration and all seven locales without invalid numbers", () => {
  const ctx = healingFixture();
  ctx.durationMs = 0;
  for (const lang of ["en", "de", "es", "fr", "jp", "ru", "zh"]) {
    setLang(lang);
    const result = render(ctx, "healing-out");
    assert.doesNotMatch(result.html, /NaN|Infinity|wasted|heal_raw_hps/);
    assert.match(result.html, new RegExp(viewer.t("heal_raw_hps")));
    assert.deepEqual(summary(result, "Healing Out").slice(4), [0, 0]);
  }
});

test("damage and incoming damage expose statistics and ability references inline", () => {
  const ctx = context();
  ctx.names[101] = { ...ctx.names[101], tooltip: "A reference description.", approxTooltip: true,
    tooltipDonorId: 999, mech: { ...ctx.names[101].mech, durationMs: 6000, tickMs: 1000 } };
  for (const tab of ["damage-done", "damage-taken"]) {
    ctx.decoded.damageTakenByUnitId = { 9: { 1: { 101: damage(30000) } } };
    const result = render(ctx, tab);
    const details = detailsFor("Mixed Skill");
    assert.match(details, /<dt>Hits<\/dt>/);
    assert.match(details, /About this ability/);
    assert.match(details, /A reference description/);
    assert.match(details, /Duration/);
    assert.ok(details.includes(viewer.t("tt_approx")));
    assert.doesNotMatch(result.html, /data-tti|title=|stat-hero|class="strip"/);
  }
});

test("unit rows expand and filtering is a separate native button", () => {
  const ctx = healingFixture();
  const result = render(ctx, "healing-out");
  assert.match(result.html, /<button type="button" class="detail-action" data-filt-only="healing-out"[^>]*>Filter to Ally<\/button>/);
  assert.doesNotMatch(result.html, /<summary[^>]*data-filt-only|role="button"/);
});

test("effect search scopes the rows, pins and CSV, including an empty match", () => {
  const ctx = context();

  ctx.names[101].name = "Cold Ward";
  ctx.names[201].name = "Warm Ward";
  ctx.decoded.playerAliveTimeMs = 10000;
  ctx.decoded.effectsOnPlayer = { 101: effect(101), 201: effect(201) };
  ctx.decoded.effectsOnGroup = { Ally: { 101: effect(101), 201: effect(201) } };
  ctx.decoded.effectsOnBosses = { boss1: { 101: effect(101), 201: effect(201) } };
  ctx.pins = new Set([101, 201]);
  for (const tab of ["effects-player", "effects-boss", "effects-group"]) {
    tabFilters.set(tab, "warm");
    const result = render(ctx, tab);
    assert.ok(result.csv.slice(1).length > 0);
    assert.ok(result.csv.slice(1).every(row => row[1] === "Warm Ward"));
    assert.doesNotMatch(result.html, /Cold Ward/);
    assert.match(result.html, /Warm Ward/);
    assert.match(result.html, /Unpin effect/);
    tabFilters.set(tab, "missing");
    const empty = render(ctx, tab);
    assert.equal(empty.csv.length, 1);
    assert.match(empty.html, /No effects tracked/);
    assert.match(empty.html, new RegExp(`data-filt-reset="${tab}"`));
  }
});

function groupFixture() {
  const ctx = context();
  const members = [
    ["Short fight", 10000, { rawOut: 1000, effectiveOut: 500, rawSelf: 0, effectiveSelf: 0 }],
    ["Long fight", 20000, { rawOut: 3000, effectiveOut: 1000, rawSelf: 0, effectiveSelf: 0 }],
    ["Zero healing", 10000, { rawOut: 0, effectiveOut: 0, rawSelf: 0, effectiveSelf: 0 }],
    ["Missing healing", 10000, undefined],
  ];
  for (const [displayName, durationMs, healing] of members) {
    const wire = {};
    ctx.wireEnc.shared.push(wire);
    ctx.sharedDecoded.set(wire, { displayName, role: 4, data: {
      durationMs, aliveTimeMs: durationMs / 2, totalDamage: 1000, totalDamageTaken: 100,
      critPercent: .2, maxHit: 50, dotPercent: .1, aoePercent: .2,
      bossDamage: [], damageByType: [], bossDamageTaken: [], topDamageTakenAbilities: [], healing,
    } });
  }
  return ctx;
}

test("group healing rates use each member's duration and distinguish zero from missing data", () => {
  const result = render(groupFixture(), "group");
  const head = result.csv[0];
  const value = (name, col) => result.csv.find(row => row[1] === name)[head.indexOf(col)];
  assert.equal(value("Long fight", "RawHPS"), 150);
  assert.equal(value("Long fight", "EffectiveHPS"), 50);
  assert.equal(value("Long fight", "OverhealPct"), 2000 / 3000 * 100);
  assert.equal(value("Short fight", "EffectiveHPS"), 50);
  assert.equal(value("Zero healing", "EffectiveHPS"), 0);
  assert.equal(value("Zero healing", "OverhealPct"), 0);
  assert.equal(value("Missing healing", "EffectiveHPS"), "");
  assert.equal(value("Missing healing", "OverhealPct"), "");
  assert.match(result.html, /data-group-sort/);
  assert.match(detailsFor("Long fight"), /50%/);
});

test("group sorting keeps missing healing after recorded values in both directions", () => {
  for (const col of ["hps", "effectiveHps", "overheal"]) {
    for (const dir of [-1, 1]) {
      Object.assign(viewer.groupSortState, { col, dir });
      const rows = render(groupFixture(), "group").csv.slice(1).filter(row => row.length);
      assert.equal(rows.at(-1)[1], "Missing healing");
      if (dir === 1) assert.equal(rows[0][1], "Zero healing");
    }
  }
});

test("build references preserve skill text, set bonuses, traits and enchantment caveats", () => {
  const ctx = context();
  ctx.names[101].tooltip = "Skill reference text.";
  ctx.itemNames[700] = { name: "Test Robe", setId: 900, setName: "Test Set", armorType: 1, tooltip: "Item reference text." };
  ctx.defs = {
    set: { 900: { name: "Test Set", tooltip: "Two pieces: bonus.\nFive pieces: larger bonus." } },
    trait: { 1: { name: "Trait", tooltip: "Trait reference text." } },
    enchant: { 500: { name: "Test Enchant", tooltip: "Enchant reference text." } },
    script: {}, perk: {}, skillline: {},
  };
  ctx.wireEnc.setup = { raceId: 1, classId: 1, abilities: { front: [{ abilityId: 101 }] },
    equipSlots: [{ slotIndex: 1, itemId: 700, traitType: 1, enchantId: 500, quality: 5 }] };
  const result = render(ctx, "setup");
  for (const text of ["Skill reference text.", "Item reference text.", "Trait reference text.",
    "Enchant reference text.", "Two pieces: bonus.", "Five pieces: larger bonus.", viewer.t("tt_enchant_base")]) {
    assert.ok(result.html.includes(text), text);
  }
  assert.match(detailsFor("Test Robe"), /Test Enchant/);
  assert.doesNotMatch(result.html, /data-tti|title=/);
});

test("group damage merges the same ability across contributors but keeps source filters intact", () => {
  const ctx = context();
  ctx.decoded.damageByUnitId = { 1: { 9: { 101: damage(30000) } } };
  ctx.decoded.damageByUnitIdGroup = { 0: { 9: { 101: damage(70000) } } };
  render(ctx, "group-damage");
  const combined = detailsFor("Mixed Skill");
  assert.doesNotMatch(combined, /Components/);
  assertPair(combined, "Total", "100,000");
  assertPair(combined, "Hits", "20");
  assertPair(combined, "Min – max", "1.5K – 14.0K");
  applyFilterOnly(ctx, "group-damage", "source", "__SELF__");
  render(ctx, "group-damage");
  assertPair(detailsFor("Mixed Skill"), "Total", "30,000");
  applyFilterOnly(ctx, "group-damage", "source", "__OTHERS__");
  render(ctx, "group-damage");
  assertPair(detailsFor("Mixed Skill"), "Total", "70,000");
});

test("metric sections and ability references need no second expansion; synthetic rows have no reference", () => {
  const ctx = context();
  const damage = render(ctx, "damage-done").html;
  assert.match(damage, /<section class="metric-group">/);
  assert.doesNotMatch(damage, /<details[^>]*metric-group|Hit \/ heal statistics/);
  assert.match(damage, /Hit statistics/);
  assert.match(detailsFor("Mixed Skill"), /<section class="ability-reference">/);
  assert.doesNotMatch(damage, /<summary[^>]*>About this ability/);
  ctx.decoded.healingStats.selfHealing.bySourceUnitIdByAbilityId[1][1048573] = healing(50);
  render(ctx, "self-healing");
  assert.doesNotMatch(detailsFor("Unknown (Absorbed)"), /About this ability/);
  assert.match(renderedHtml, /Healing ticks/);
});

test("the damage sidebar is damage-only, with full member details on Group", () => {
  const ctx = groupFixture();
  const entry = ctx.sharedDecoded.values().next().value;
  entry.data.damageByType = [{ type: 6, damage: 400 }, { type: 8, damage: 600 }];
  entry.data.healing.rawSelf = 900;
  entry.data.healing.effectiveSelf = 450;
  entry.data.bossDamage = [{ bossTag: "boss1", tagSeq: 1, damage: 600, critPercent: .25, dotPercent: .3, aoePercent: .4, magicalPercent: 1 }];
  entry.data.bossDamageTaken = [{ bossTag: "boss1", tagSeq: 1, damage: 50 }];
  entry.data.topDamageTakenAbilities = [{ abilityId: 101, damagePercent: .5 }];
  render(ctx, "damage-done");
  const rail = detailsFor("Short fight");
  assert.doesNotMatch(rail, /healing|Healing|Resurrections/);
  assertComposition(rail, "Frost", "400 · 40.0%");
  assertComposition(rail, "Magic", "600 · 60.0%");
  assert.match(rail, /25.0%/); // Shares among the four members, not a filtered damage denominator.
  render(ctx, "group");
  const full = detailsFor("Short fight");
  assertPair(full, viewer.t("group_raw_self"), "900");
  assertPair(full, viewer.t("group_effective_self_hps"), "45");
  assert.match(full, /Damage Taken/);
  assert.match(full, /Mixed Skill/);
  assert.equal((full.match(/Short fight/g) || []).length, 1);
});

test("weaving time lost sums post-cast delays and weights their samples, excluding downtime", () => {
  const ctx = context();
  ctx.decoded.weaving = { lightAttackHits: 10, heavyAttackHits: 2, skillActivations: 12,
    totalWeavingErrors: 2, doubleLaErrors: 1, downtimeMs: 3500, downtimeGaps: 1,
    byAbility: [
      { abilityId: 101, activations: 2, afterSum: 100, afterCount: 1, beforeSum: 500, beforeCount: 2, weavingErrors: 0 },
      { abilityId: 102, activations: 10, afterSum: 1500, afterCount: 3, beforeSum: 400, beforeCount: 2, weavingErrors: 2 },
    ] };
  for (const id of ["weaving", "overview"]) {
    const result = render(ctx, id);
    assert.equal(result.csv.find(r => r[0] === "Time lost ms")[1], 1600);
    assert.equal(result.csv.find(r => r[0] === "Average cast delay ms")[1], 400);
    assert.match(result.html, /1.6s/);
    assert.match(result.html, /400 ms/);
  }
  const result = render(ctx, "weaving");
  assert.match(result.html, /500 ms · 3×/);
  assert.ok(result.csv.some(r => r.at(-1) === 1500 && r.at(-2) === 3));
  ctx.decoded.weaving.byAbility = [];
  assert.equal(render(ctx, "weaving").csv.find(r => r[0] === "Average cast delay ms")[1], "");
});

test("base ultimate explains Heroism estimates without adding them again to generation", () => {
  const ctx = context();
  ctx.names[61708] = { name: "Minor Heroism" };
  ctx.names[61709] = { name: "Major Heroism" };
  ctx.decoded.effectsOnPlayer = { 61708: { totalActiveTimeMs: 3000 }, 61709: { totalActiveTimeMs: 1501 } };
  ctx.decoded.ultimate = { startUlt: 10, maxUlt: 500, totalGained: 30, totalDrained: 0,
    gainByAbilityId: { 0: { total: 30, ticks: 0, minTick: 0, maxTick: 0 } }, casts: [] };
  const result = render(ctx, "ultimate");
  assertPair(detailsFor("Base Generation"), "Minor Heroism", "Est. 2 Ultimate · 30.0% uptime");
  assertPair(detailsFor("Base Generation"), "Major Heroism", "Est. 6 Ultimate · 15.0% uptime");
  assert.match(result.html, /scribing_tertiary_heroism.png/);
  assert.equal(result.csv.find(r => r[0] === viewer.t("ult_generated"))[1], 30);
  assert.doesNotMatch(result.html, /%%/);
});

test("Soul Harvest's hidden generator uses the localized skill name and icon without changing its event", () => {
  const localized = { en: "Soul Harvest", de: "Seelenernte", es: "cosecha de almas", fr: "Moisson d'âmes",
    jp: "魂の収穫者", ru: "Жатва душ", zh: "灵魂收割" };
  for (const [lang, name] of Object.entries(localized)) {
    setLang(lang);
    const ctx = context();
    ctx.names[36519] = { name: "Rapid Stroke Passive", iconUrl: "/icons/placeholder.png" };
    ctx.names[36514] = { name, iconUrl: "/icons/soul-harvest.png" };
    ctx.decoded.ultimate = { startUlt: 0, maxUlt: 500, totalGained: 20, totalDrained: 0,
      gainByAbilityId: { 36519: { total: 20, ticks: 2, minTick: 10, maxTick: 10 } }, casts: [] };
    const before = structuredClone(ctx.decoded.ultimate);
    const result = render(ctx, "ultimate");
    assert.ok(result.csv.some(r => r[0] === name && r[1] === 20));
    assert.match(result.html, /soul-harvest\.png/);
    assert.doesNotMatch(result.html, /Rapid Stroke Passive|placeholder\.png/);
    assert.deepEqual(ctx.decoded.ultimate, before);
    delete ctx.names[36514];
    assert.ok(render(ctx, "ultimate").csv.some(r => r[0] === "Rapid Stroke Passive"));
  }
});

test("Russian Crypt Transfer borrows the set name in slotted abilities and casts only in that locale", () => {
  const ctx = context();
  ctx.names[195031] = { name: "U38 Mythic 1" };
  ctx.names[196775] = { name: "Одеяние могильного каноника" };
  ctx.wireEnc.setup = { raceId: 1, classId: 1, abilities: { front: [{ abilityId: 195031 }] } };
  ctx.decoded.ultimate = { startUlt: 500, maxUlt: 500, totalGained: 0, totalDrained: 500,
    gainByAbilityId: {}, casts: [{ abilityId: 195031, timeMs: 1000, poolBefore: 500, cost: 1 }] };
  setLang("ru");
  for (const tab of ["setup", "ultimate"]) {
    const result = render(ctx, tab);
    assert.match(result.html, /Одеяние могильного каноника/);
    assert.doesNotMatch(result.html, /U38 Mythic 1/);
  }
  setLang("en");
  ctx.names[195031].name = "Crypt Transfer";
  ctx.names[196775].name = "Cryptcanon Vestments";
  for (const tab of ["setup", "ultimate"]) {
    assert.match(render(ctx, tab).html, /Crypt Transfer/);
    assert.doesNotMatch(renderedHtml, /Cryptcanon Vestments/);
  }
});

test("Crypt Transfer uses its donated pool; only ordinary cast excess is lost", () => {
  const ctx = context();
  ctx.names[195031] = { name: "Crypt Transfer" };
  ctx.decoded.ultimate = { startUlt: 500, maxUlt: 500, totalGained: 200, totalDrained: 750,
    gainByAbilityId: {}, casts: [
      { abilityId: 195031, timeMs: 1000, poolBefore: 500, cost: 1 },
      { abilityId: 101, timeMs: 9000, poolBefore: 200, cost: 150 },
    ] };
  const result = render(ctx, "ultimate");
  assert.equal(result.csv.find(r => r[0] === viewer.t("ult_spent"))[1], 650);
  assert.equal(result.csv.find(r => r[0] === viewer.t("ult_lost"))[1], 50);
  assert.equal(result.csv.find(r => r[0] === viewer.t("ult_drained"))[1], 50);
  assertPair(detailsFor("Crypt Transfer"), viewer.t("ult_lost"), "0");
  delete ctx.decoded.ultimate.casts[0].cost;
  const legacy = render(ctx, "ultimate");
  assert.ok(!legacy.csv.some(r => r[0] === viewer.t("ult_spent")));
  assert.equal(legacy.csv.find(r => r[0] === viewer.t("ult_spent_drained"))[1], 750);
});

test("Crux distinguishes generators at full stacks from spenders below three, including CSV", () => {
  const ctx = context();
  ctx.names[185805] = { name: "Fatecarver" };
  ctx.decoded.crux = { generatorCasts: 10, generatorAtFull: 2, spenderCasts: 5, spenderUnder: [1, 1, 1],
    passiveEvents: 0, passiveStacks: 0, deathEvents: 0, deathStacks: 0,
    byAbility: { 101: { casts: 10, bad: 2, gained: 8 }, 185805: { casts: 5, bad: 3, gained: 0 } },
    conditionalGains: {}, conditionalWasted: {}, unattributedGains: 0 };
  const result = render(ctx, "crux");
  assert.match(detailsFor("Fatecarver"), new RegExp(viewer.t("crux_under")));
  for (const n of [0, 1, 2]) {
    assert.ok(result.html.includes(`Cast at ${n} Crux`));
    assert.equal(result.csv.find(r => r[0] === `Cast at ${n} Crux`)[1], 1);
  }
  assert.ok(result.csv.some(r => r[0] === "Mixed Skill" && r[1] === viewer.t("crux_at_full") && r[2] === 2));
  assert.ok(result.csv.some(r => r[0] === "Fatecarver" && r[1] === viewer.t("crux_under") && r[2] === 3));
  assert.doesNotMatch(result.html, /Mistimed|Wasted/);
});

test("pinned effects move to the top and retain expandable statistics", () => {
  const ctx = context();
  ctx.names[101].name = "Ordinary Effect";
  ctx.names[201].name = "Pinned Effect";
  ctx.decoded.effectsOnPlayer = { 101: effect(101), 201: effect(201) };
  ctx.pins.add(201);
  const result = render(ctx, "effects-player");
  assert.ok(result.html.indexOf("Pinned Effect") < result.html.indexOf("Ordinary Effect"));
  assertPair(detailsFor("Pinned Effect"), "From you", "20.0%");
  assert.equal(result.csv.slice(1).filter(r => r[1] === "Pinned Effect").length, 1);
});

test("self build counts two-handed sets per bar and puts weapon references before abilities", () => {
  const ctx = context();
  ctx.itemNames = { 700: { name: "Staff", weaponType: 12, setId: 900 }, 701: { name: "Robe", setId: 900 } };
  ctx.defs.set = { 900: { name: "Test Set", tooltip: "Set bonus description." } };
  ctx.wireEnc.setup = { raceId: 1, classId: 1, abilities: { front: [{ abilityId: 101 }] }, equipSlots: [
    { slotIndex: 5, itemId: 700, traitType: 1, enchantId: 0, quality: 5 },
    { slotIndex: 3, itemId: 701, traitType: 0, enchantId: 0, quality: 5 },
  ] };
  const result = render(ctx, "setup");
  assert.ok(result.html.indexOf("bp-weapons") < result.html.indexOf("Mixed Skill"));
  assert.match(detailsFor("3×/1× Test Set"), /Set bonus description/);
  assert.doesNotMatch(result.html, /not been mined|Description.*missing/);
});

test("build slots show recorded scripts rather than an incorrect generic combined tooltip", () => {
  const ctx = groupFixture();
  ctx.names[101].tooltip = "Generic tooltip that omits the selected scripts.";
  ctx.defs.script = { 11: { name: "Focus", tooltip: "Focus details" }, 12: { name: "Signature", tooltip: "Signature details" }, 13: { name: "Affix", tooltip: "Affix details" } };
  ctx.wireEnc.shared[0].memberSetup = { raceId: 1, classId: 1, sets: [], champion: [], frontAbilities: [101],
    scribedAbilities: [{ abilityId: 101, scriptIds: [11, 12, 13] }] };
  render(ctx, "group");
  const slot = detailsFor("Mixed Skill");
  for (const text of ["Focus details", "Signature details", "Affix details"]) assert.ok(slot.includes(text), text);
  assert.doesNotMatch(slot, /Generic tooltip that omits/);
});

test("own and group builds resolve the exact scribed recipe, including names in CSV", () => {
  const ctx = groupFixture();
  ctx.names[101].craftedAbilityId = 5;
  ctx.names[101].tooltip = "Generic grimoire description";
  ctx.defs.script = { 11: { name: "Focus", tooltip: "Generic focus" }, 21: { name: "Signature" }, 41: { name: "Affix" } };
  ctx.scribing = {
    "5:11:21:41:117": { name: "Magic Soul", icon: "/esoui/art/icons/ability_grimoire_soulmagic1.dds", tooltip: "Combined effect\nWith the selected scripts" },
    "5:11:21:42:117": { name: "Other combination", tooltip: "Wrong affix" },
  };
  ctx.wireEnc.setup = { classId: 117, raceId: 1, abilities: { front: [{ abilityId: 101, craftedAbilityId: 5, scriptIds: [11, 21, 41] }] } };
  const own = render(ctx, "setup");
  assert.equal(own.csv.find(r => r[0] === "Front 1")[1], "Magic Soul");
  assert.match(detailsFor("Magic Soul"), /<p>Combined effect<\/p><p>With the selected scripts<\/p>/);
  assert.match(own.html, /class="sk-icon" src="\/icons\/esoui\/art\/icons\/ability_grimoire_soulmagic1.png"/);
  assert.match(detailsFor("Magic Soul"), /ability_grimoire_soulmagic1.png/);
  assert.match(detailsFor("Magic Soul").split("</summary>")[0], /Focus · Signature · Affix/);
  assert.doesNotMatch(own.html, /Generic grimoire|Generic focus|Wrong affix/);
  ctx.wireEnc.shared[0].memberSetup = { classId: 117, raceId: 1, sets: [], champion: [], frontAbilities: [101],
    scribedAbilities: [{ abilityId: 101, scriptIds: [11, 21, 41] }] };
  const group = render(ctx, "group");
  assert.match(detailsFor("Magic Soul"), /Combined effect/);
  assert.match(group.html, /class="sk-icon" src="\/icons\/esoui\/art\/icons\/ability_grimoire_soulmagic1.png"/);
  assert.match(detailsFor("Magic Soul").split("</summary>")[0], /Focus · Signature · Affix/);
  ctx.wireEnc.shared[0].memberSetup.classId = 1;
  const otherClass = render(ctx, "group");
  assert.doesNotMatch(otherClass.html, /Combined effect|Wrong affix/);
});

test("class mastery and skill-line icons lead personal and shared ability bars", () => {
  const ctx = groupFixture();
  ctx.names[301] = { name: "Class passive", iconUrl: "/icons/passive.png", tooltip: "Passive details" };
  ctx.defs.skillline = { 401: { name: "Class line", iconUrl: "/icons/line.png" } };
  ctx.wireEnc.setup = { raceId: 1, classId: 117, classMasteryAbilityIds: [301], abilities: { front: [{ abilityId: 101 }] } };
  ctx.wireEnc.shared[0].memberSetup = { raceId: 1, classId: 117, classMasteryAbilityIds: [301], frontAbilities: [101], sets: [], champion: [] };
  for (const tab of ["setup", "group"]) {
    const result = render(ctx, tab);
    assert.ok(result.html.indexOf("Class passive") < result.html.indexOf("Mixed Skill"));
    assert.match(detailsFor("Class passive").split("</summary>")[0], /src="\/icons\/passive.png"/);
  }
  for (const setup of [ctx.wireEnc.setup, ctx.wireEnc.shared[0].memberSetup]) {
    setup.classMasteryAbilityIds = [];
    setup.classSkillLineIds = [401];
  }
  for (const tab of ["setup", "group"]) {
    const result = render(ctx, tab);
    assert.ok(result.html.indexOf("Class line") < result.html.indexOf("Mixed Skill"));
    assert.match(result.html, /src="\/icons\/line.png"/);
  }
});

test("members expose boss statistics inline and put overview/build controls first", () => {
  const ctx = groupFixture();
  ctx.wireEnc.bossSeqNames = { "boss1:1": "Test boss" };
  ctx.wireEnc.shared[0].memberSetup = { raceId: 1, classId: 117, frontAbilities: [101], sets: [], champion: [] };
  const entry = ctx.sharedDecoded.get(ctx.wireEnc.shared[0]);
  entry.data.bossDamage = [{ bossTag: "boss1", tagSeq: 1, damage: 600, critPercent: .25, dotPercent: .3, aoePercent: .4, magicalPercent: 1 }];
  render(ctx, "group");
  const member = detailsFor("Short fight");
  assert.match(member, /data-member-view="overview" aria-pressed="true"/);
  assert.match(member, /data-member-view="build" aria-pressed="false"/);
  assert.ok(member.indexOf("data-member-view") < member.indexOf("Test boss"));
  assert.match(member, /<h3>Test boss<\/h3><dl/);
  assert.doesNotMatch(member, /<summary[^>]*>Test boss/);
  assertPair(member, "DPS", "60");
  assert.match(member, /data-member-panel="build" hidden/);
  assert.match(member, /Mixed Skill/);
  assert.doesNotMatch(detailsFor("Missing healing"), /data-member-view/);

  ctx.wireEnc.shared[0].isSelf = true;
  ctx.wireEnc.setup = { raceId: 1, classId: 117, abilities: { front: [{ abilityId: 201 }] } };
  render(ctx, "group");
  assert.match(detailsFor("Short fight"), /Mixed Heal/);
  assert.doesNotMatch(detailsFor("Short fight"), /data-group="setup"/);
});

test("pinned buffs and debuffs stay in their original sections with a visible pin mark", () => {
  const ctx = context();
  ctx.names = { 101: { name: "Ordinary buff" }, 102: { name: "Pinned buff" }, 201: { name: "Pinned debuff" } };
  ctx.decoded.effectsOnPlayer = { 101: effect(101), 102: effect(102), 201: { ...effect(201), effectType: 2 } };
  ctx.pins = new Set([102, 201]);
  const result = render(ctx, "effects-player");
  const debuffs = result.html.indexOf(viewer.t("h_debuffs_on_you"));
  assert.ok(result.html.indexOf("Pinned buff") < result.html.indexOf("Ordinary buff"));
  assert.ok(result.html.indexOf("Ordinary buff") < debuffs);
  assert.ok(debuffs < result.html.indexOf("Pinned debuff"));
  assert.equal((result.html.match(/class="pin-mark"/g) || []).length, 2);
  assertPair(detailsFor("Pinned debuff"), "From you", "20.0%");
});

test("Support exposes resurrection counts and the captured timeline", () => {
  const ctx = context();
  ctx.decoded.resurrections = 2;
  ctx.decoded.resurrectionLog = [{ timeMs: 2000, displayName: "Ally" }, { timeMs: 9000, displayName: "Ally" }];
  const result = render(ctx, "support");
  assert.deepEqual(result.csv, [["Resurrections", 2], ["Time", "Member"], ["0:02", "Ally"], ["0:09", "Ally"]]);
  assert.match(result.html, /2×/);
});

test("overview interprets omitted alive time as the full fight while preserving recorded zero", () => {
  const ctx = context();
  assertComposition(render(ctx, "overview").html, "Time alive", "0:10 · 100.0%");
  ctx.decoded.playerAliveTimeMs = 0;
  assertComposition(render(ctx, "overview").html, "Time alive", "0:00 · 0.0%");
});

test("ESO text resolves empty item links, honors labels, strips colors, and never emits link payloads", () => {
  const link = "|H0:item:194509:364:50:0:0:0:0:0:0:0:0:0:0:0:1:0:0:1:0:10000:0|h|h";
  assert.deepEqual(viewer.linkedItemIds(link + link), [194509]);
  assert.equal(viewer.plainEsoText(`From ${link}.`, { 194509: "Cryptcanon Vestments" }), "From Cryptcanon Vestments.");
  assert.equal(viewer.plainEsoText(link), "#194509");
  assert.equal(viewer.plainEsoText("|cAAbbCC|H1:item:12:0|hNamed item|h|r", { 12: "Fallback" }), "Named item");
  assert.equal(viewer.plainEsoText("|H1:ability:42|hAbility name|h"), "Ability name");
  assert.equal(viewer.plainEsoText("|H0:item:42|h<script>alert(1)</script>|h"), "<script>alert(1)</script>");
  const ctx = context();
  ctx.names[101].tooltip = viewer.plainEsoText("|H0:item:42|h<script>alert(1)</script>|h");
  assert.doesNotMatch(render(ctx, "damage-done").html, /<script>/);
});

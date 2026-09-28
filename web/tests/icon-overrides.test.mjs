import assert from "node:assert/strict";
import { test } from "node:test";
import { readFileSync } from "node:fs";
import { resolveIconDonors } from "../scripts/mine-icon-overrides.mjs";

const placeholder = "/esoui/art/icons/ability_mage_065.dds";
const passiveIcon = "/esoui/art/icons/passive_arcanist_08.dds";
const row = (id, name, icon = placeholder, described = 0, craftedAbilityId = 0) => ({ id, name, icon, described, craftedAbilityId });

test("recorded ultimate components borrow artwork across ranks, preserving real icons and excluding unobserved NPCs", () => {
  const rows = [row(185070, "Implacable Outcome"), row(185058, "Implacable Outcome", passiveIcon, 1),
    row(185050, "Implacable Outcome", passiveIcon, 1), row(1, "Implacable Outcome"),
    row(118186, "Stalwart", "/esoui/art/icons/ability_sorcerer_018.dds")];
  assert.deepEqual(resolveIconDonors(rows, [0, 185070, 185070, 118186]), {
    overrides: [{ id: 185070, donorId: 185050, name: "Implacable Outcome", donorName: "Implacable Outcome" }], unresolved: [],
  });
});

test("scribed components use the grimoire relationship even when script names differ", () => {
  const rows = [row(217512, "Potent Burst", placeholder, 0, 8),
    row(217459, "Magical Burst", "/esoui/art/icons/ability_grimoire_soulmagic2.dds", 1, 8),
    row(12, "Potent Burst", passiveIcon, 1),
    row(13, "Grimoire", "/esoui/art/icons/grimoire_soulmagic2.dds", 1, 8)];
  assert.equal(resolveIconDonors(rows, [217512]).overrides[0].donorId, 217459);
  assert.equal(resolveIconDonors(rows.filter(r => r.id !== 217459), [217512]).overrides.length, 0);
});

test("ambiguous, undescribed, and placeholder donors cannot supply a guess", () => {
  const rows = [row(1, "Shared"), row(2, "Shared", passiveIcon, 1), row(3, "Shared", "/esoui/art/icons/other.dds", 1),
    row(4, "Bare"), row(5, "Bare", passiveIcon), row(6, "Bare", placeholder, 1)];
  const result = resolveIconDonors(rows, [1, 4, 99]);
  assert.deepEqual(result.overrides, []);
  assert.deepEqual(result.unresolved.map(r => r.reason), ["conflicting icons", "no donor", "missing metadata"]);
});

test("missing icon variants are recognized and candidate ordering is deterministic", () => {
  const rows = [row(1, "Skill", null), row(2, "Skill", ""), row(3, "Skill", "EsoUI/Art/Icons/icon_missing.dds"),
    row(4, "Skill", "EsoUI/Art/Icons/ability_mage_065.dds"), row(9, "Skill", passiveIcon, 1)];
  assert.deepEqual(resolveIconDonors(rows, [4, 2, 3, 1]).overrides.map(r => [r.id, r.donorId]), [[1, 9], [2, 9], [3, 9], [4, 9]]);
  assert.deepEqual(resolveIconDonors(rows, [1, 2]), resolveIconDonors(rows.toReversed(), [2, 1]));
  assert.throws(() => resolveIconDonors([...rows, rows[0]], [1]), /Duplicate metadata/);
});

test("addon and web static donors agree, including the latest Earthen Root Enclave sources", () => {
  const lua = readFileSync(new URL("../../BattleScrolls/ui/journal/utils.lua", import.meta.url), "utf8")
    .match(/local abilityIconAbilityIdOverrides = \{\n([\s\S]*?)\n\}/)[1];
  const ts = readFileSync(new URL("../src/shared/icon_overrides.ts", import.meta.url), "utf8")
    .match(/export const ICON_DONORS[^=]*= \{\n([\s\S]*?)\n\}/)[1];
  const addon = Object.fromEntries([...lua.matchAll(/\[(\d+)\]\s*=\s*(\d+)/g)].map(m => [m[1], +m[2]]));
  const web = Object.fromEntries([...ts.matchAll(/^\s*(\d+):\s*(\d+)/gm)].map(m => [m[1], +m[2]]));
  assert.deepEqual(web, addon);
  assert.equal(addon[185070], 185050);
  assert.equal(addon[263415], 263412);
  assert.equal(addon[217512], 217459);
  assert.equal(addon[118186], undefined); // Stalwart already has its real art.
});

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { createGameRegistry } from "../dist/index.js";
import {
  createDefaultBrowserShellProfile,
  createPrebattleViewModel,
  createWorldMapViewModel,
  difficultyForEncounter,
  highestUnlockedEncounterLevel,
  sanitizeBrowserShellProfile,
} from "../dist/browser-shell.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..");

function loadPayload(relativePath) {
  return JSON.parse(fs.readFileSync(path.join(repoRoot, relativePath), "utf8")).payload;
}

function createRegistry() {
  return createGameRegistry({
    encounters: loadPayload("web/data/encounters.json"),
    allies: loadPayload("web/data/allies.json"),
    enemies: loadPayload("web/data/enemies.json"),
    spells: loadPayload("web/data/spells.json"),
    shop: loadPayload("web/data/shop.json"),
    lootRules: loadPayload("web/data/loot-rules.json"),
    equipmentSchema: loadPayload("web/data/equipment-schema.json"),
    progression: loadPayload("web/data/progression-schema.json"),
  });
}

test("fresh browser shell profiles only unlock the first encounter", () => {
  const registry = createRegistry();
  const profile = createDefaultBrowserShellProfile();
  const unlockedLevels = createWorldMapViewModel(registry, profile)
    .filter((entry) => entry.unlocked)
    .map((entry) => entry.level);

  assert.equal(profile.highestLevelCompleted, 0);
  assert.equal(highestUnlockedEncounterLevel(profile), 1);
  assert.deepEqual(unlockedLevels, [1]);
});

test("world map view model follows the native linear unlock rule", () => {
  const registry = createRegistry();
  const profile = createDefaultBrowserShellProfile();
  profile.highestLevelCompleted = 3;

  const entries = createWorldMapViewModel(registry, profile);
  const unlockedLevels = entries.filter((entry) => entry.unlocked).map((entry) => entry.level);

  assert.equal(highestUnlockedEncounterLevel(profile), 4);
  assert.deepEqual(unlockedLevels, [1, 2, 3, 4]);
  assert.equal(entries.length, registry.encounters.length);
});

test("prebattle view model reuses deterministic bootstrap data for the selected encounter", () => {
  const registry = createRegistry();
  const profile = createDefaultBrowserShellProfile();
  profile.selectedSpellIds = ["Purify", "Heal", "GreaterHeal", "Barrier"];
  profile.lastUsedSpellIds = profile.selectedSpellIds.slice();

  const preview = createPrebattleViewModel(registry, profile, 6);

  assert.equal(preview.bootstrap.encounter.level, 6);
  assert.equal(preview.bootstrap.encounter.title, "Fungal Ravagers");
  assert.equal(preview.bootstrap.replay.seed, 1323874544);
  assert.deepEqual(
    preview.selectedSpells.map((spell) => spell.id),
    ["Purify", "Heal", "GreaterHeal"],
  );
  assert.ok(preview.allySummary.some((ally) => ally.title === "Guardian"));
  assert.equal(preview.bootstrap.enemies[0].title, "Fungal Ravagers");
});

test("profile sanitization discards malformed persisted fields and invalid difficulties", () => {
  const registry = createRegistry();
  const fallback = createDefaultBrowserShellProfile();
  const profile = sanitizeBrowserShellProfile({
    name: 17,
    highestLevelCompleted: "3",
    selectedSpellIds: ["Heal", 7],
    lastUsedSpellIds: [null, "Purify"],
    ownedSpellIds: ["Heal", false, "Barrier"],
    equippedItems: [
      null,
      { id: "starter", healing: 5, spellId: "Heal" },
      { speed: "fast" },
      9,
    ],
    hasMainGameExpansion: "true",
    difficultyByLevel: {
      2: 4,
      3: "hard",
      foo: 2,
    },
  }, fallback);

  assert.equal(profile.name, fallback.name);
  assert.equal(profile.highestLevelCompleted, fallback.highestLevelCompleted);
  assert.deepEqual(profile.selectedSpellIds, ["Heal"]);
  assert.deepEqual(profile.lastUsedSpellIds, ["Purify"]);
  assert.deepEqual(profile.ownedSpellIds, ["Heal", "Barrier"]);
  assert.deepEqual(profile.equippedItems, [{ id: "starter", healing: 5, spellId: "Heal" }]);
  assert.equal(profile.hasMainGameExpansion, fallback.hasMainGameExpansion);
  assert.deepEqual(profile.difficultyByLevel, { 2: 4 });
  assert.equal(difficultyForEncounter(registry, profile, 3), registry.progression.progressionRules.difficultyDefaultValue);
});

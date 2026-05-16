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
  highestUnlockedEncounterLevel,
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

test("world map view model follows the native linear unlock rule", () => {
  const registry = createRegistry();
  const profile = createDefaultBrowserShellProfile();
  profile.highestLevelCompleted = 3;

  const entries = createWorldMapViewModel(registry, profile);
  const unlockedLevels = entries.filter((entry) => entry.unlocked).map((entry) => entry.level);

  assert.equal(highestUnlockedEncounterLevel(profile), 4);
  assert.deepEqual(unlockedLevels, [1, 2, 3, 4]);
  assert.equal(entries.length, 21);
});

test("prebattle view model reuses deterministic bootstrap data for the selected encounter", () => {
  const registry = createRegistry();
  const profile = createDefaultBrowserShellProfile();
  profile.selectedSpellIds = ["Purify", "Heal", "GreaterHeal", "Barrier"];
  profile.lastUsedSpellIds = profile.selectedSpellIds.slice();

  const preview = createPrebattleViewModel(registry, profile, 6);

  assert.equal(preview.bootstrap.encounter.level, 6);
  assert.equal(preview.bootstrap.encounter.title, "Fungal Ravagers");
  assert.equal(preview.bootstrap.replay.seed, 1882156998);
  assert.deepEqual(
    preview.selectedSpells.map((spell) => spell.id),
    ["Purify", "Heal", "GreaterHeal"],
  );
  assert.ok(preview.allySummary.some((ally) => ally.title === "Guardian"));
  assert.equal(preview.bootstrap.enemies[0].title, "Fungal Ravagers");
});

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { createEncounterBootstrap, createGameRegistry } from "../dist/index.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..");

function loadPayload(relativePath) {
  const filePath = path.join(repoRoot, relativePath);
  return JSON.parse(fs.readFileSync(filePath, "utf8")).payload;
}

function createRegistry() {
  return createGameRegistry({
    encounters: loadPayload("web/data/encounters.json"),
    allies: loadPayload("web/data/allies.json"),
    enemies: loadPayload("web/data/enemies.json"),
    spells: loadPayload("web/data/spells.json"),
    shop: loadPayload("web/data/shop.json"),
    progression: loadPayload("web/data/progression-schema.json"),
  });
}

test("all ally archetypes are available for phase-2 encounter assembly", () => {
  const registry = createRegistry();

  assert.equal(registry.alliesById.size, 6);
  for (const allyId of ["Guardian", "Berserker", "Archer", "Champion", "Wizard", "Warlock"]) {
    assert.ok(registry.alliesById.has(allyId));
  }
});

test("encounter bootstrap assembles raid, enemies, rewards, and replay metadata", () => {
  const registry = createRegistry();
  const snapshot = createEncounterBootstrap(registry, {
    level: 6,
    difficulty: 5,
    multiplayer: true,
    seed: "phase-2-vertical-slice",
    player: {
      name: "Ayla",
      ownedSpellIds: ["Heal", "GreaterHeal", "ForkedHeal", "Purify"],
      lastUsedSpellIds: ["Purify"],
      equippedItems: [{ id: "starter-tome", health: 25, healing: 2, regen: 1, crit: 0.5, speed: 1.5, spellId: "Purify" }],
    },
  });

  assert.equal(snapshot.encounter.level, 6);
  assert.equal(snapshot.encounter.difficulty, 5);
  assert.equal(snapshot.encounter.multiplayer, true);
  assert.equal(snapshot.allies.length, 7);
  assert.deepEqual(snapshot.player.activeSpellIds, ["Purify", "Heal", "GreaterHeal"]);
  assert.deepEqual(snapshot.player.equippedItemSpellIds, ["Purify"]);
  assert.equal(snapshot.player.maximumHealth, 1425);
  assert.equal(snapshot.rewards.gold, 150);
  assert.equal(snapshot.replay.version, 1);
  assert.ok(Number.isInteger(snapshot.replay.seed));
  assert.equal(snapshot.warnings.length, 0);

  const boss = snapshot.enemies[0];
  assert.equal(boss.className, "FinalRavager");
  assert.equal(boss.maximumHealth, Math.round(boss.baseHealth * 1.4));
  assert.equal(boss.damagePerAttack, Math.round(boss.baseDamage * 1.25));

  const serialized = JSON.parse(JSON.stringify(snapshot));
  assert.deepEqual(serialized.player.activeSpellIds, snapshot.player.activeSpellIds);
});

test("selected spells override other loadout sources and encounter snapshots are deterministic", () => {
  const registry = createRegistry();
  const options = {
    level: 5,
    difficulty: 3,
    seed: 12345,
    player: {
      ownedSpellIds: ["Heal", "GreaterHeal", "ForkedHeal", "Purify"],
      selectedSpellIds: ["ForkedHeal", "Heal"],
      lastUsedSpellIds: ["Purify"],
    },
  };

  const first = createEncounterBootstrap(registry, options);
  const second = createEncounterBootstrap(registry, options);

  assert.deepEqual(first.player.activeSpellIds, ["ForkedHeal", "Heal", "GreaterHeal"]);
  assert.deepEqual(first, second);
});

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  advanceCombatState,
  beginPlayerCast,
  createCombatState,
  createEncounterBootstrap,
  createGameRegistry,
} from "../dist/index.js";

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

function createBootstrap() {
  const registry = createRegistry();
  return createEncounterBootstrap(registry, {
    level: 6,
    difficulty: 5,
    multiplayer: true,
    seed: "phase-2-combat-runtime",
    player: {
      name: "Ayla",
      ownedSpellIds: ["Heal", "GreaterHeal", "ForkedHeal", "Purify"],
      lastUsedSpellIds: ["Purify"],
      equippedItems: [
        { id: "starter-tome", health: 25, healing: 2, regen: 1, crit: 0.5, speed: 1.5, spellId: "Purify" },
        { id: "ember-relic", spellId: "Barrier" },
      ],
    },
  });
}

function assertClose(actual, expected, epsilon = 1e-9) {
  assert.ok(Math.abs(actual - expected) <= epsilon, `expected ${actual} to be within ${epsilon} of ${expected}`);
}

test("combat state derives runtime spell timing from the bootstrap snapshot", () => {
  const bootstrap = createBootstrap();
  const state = createCombatState(bootstrap);

  assert.equal(state.time, 0);
  assert.equal(state.player.castTimeAdjustment, 0.985);
  assert.equal(state.player.activeSpells[0].id, "Purify");
  assertClose(state.player.activeSpells[0].cooldown, 5.075);
  assert.equal(state.player.activeSpells[1].id, "Heal");
  assertClose(state.player.activeSpells[1].castTime, 1.97);
  assert.equal(state.player.activeSpells[3].id, "Barrier");
  assertClose(state.player.activeSpells[3].cooldown, 4.06);
});

test("instant spells spend energy immediately and start cooldown tracking", () => {
  const state = createCombatState(createBootstrap());
  const result = beginPlayerCast(state, { spellId: "Purify", targetIds: ["ally-guardian-1"] });

  assert.deepEqual(result.events, [{
    type: "player_cast_completed",
    at: 0,
    spellId: "Purify",
    targetIds: ["ally-guardian-1"],
  }]);
  assert.equal(result.state.player.energy, 952);
  assert.equal(result.state.player.casting, null);
  assertClose(result.state.player.activeSpells[0].cooldownRemaining, 5.075);
});

test("timed casts regenerate energy while casting and resolve when their cast finishes", () => {
  const initial = createCombatState(createBootstrap());
  const started = beginPlayerCast(initial, { spellId: "Heal", targetIds: ["ally-guardian-1"] });

  assert.deepEqual(started.events, [{
    type: "player_cast_started",
    at: 0,
    spellId: "Heal",
    targetIds: ["ally-guardian-1"],
  }]);
  assert.equal(started.state.player.casting?.remainingCastTime, 1.97);

  const advanced = advanceCombatState(started.state, 2);

  assert.deepEqual(advanced.events, [{
    type: "player_cast_completed",
    at: 1.97,
    spellId: "Heal",
    targetIds: ["ally-guardian-1"],
  }]);
  assertClose(advanced.state.time, 2);
  assert.equal(advanced.state.player.casting, null);
  assertClose(advanced.state.player.energy, 988.303);
  assert.equal(advanced.state.player.activeSpells[1].cooldownRemaining, 0);
});

test("cast requests are rejected when the player is already casting or lacks energy", () => {
  const initial = createCombatState(createBootstrap());
  const started = beginPlayerCast(initial, { spellId: "Heal", targetIds: ["ally-guardian-1"] });
  const secondRequest = beginPlayerCast(started.state, { spellId: "GreaterHeal", targetIds: ["ally-guardian-2"] });

  assert.equal(secondRequest.events[0].reason, "already_casting");

  const drained = {
    ...initial,
    player: {
      ...initial.player,
      activeSpells: initial.player.activeSpells.map((spell) => ({ ...spell })),
      casting: null,
      energy: 40,
    },
  };
  const notEnoughEnergy = beginPlayerCast(drained, { spellId: "GreaterHeal", targetIds: ["ally-guardian-2"] });
  assert.equal(notEnoughEnergy.events[0].reason, "not_enough_energy");
});

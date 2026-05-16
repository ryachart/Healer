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

function createBootstrap(overrides = {}) {
  const registry = createRegistry();
  const basePlayer = {
    name: "Ayla",
    ownedSpellIds: ["Heal", "GreaterHeal", "ForkedHeal", "Purify"],
    lastUsedSpellIds: ["Purify"],
    equippedItems: [
      { id: "starter-tome", health: 25, healing: 2, regen: 1, crit: 0.5, speed: 1.5, spellId: "Purify" },
      { id: "ember-relic", spellId: "Barrier" },
    ],
  };
  return createEncounterBootstrap(registry, {
    level: 6,
    difficulty: 5,
    multiplayer: true,
    seed: "phase-2-combat-runtime",
    ...overrides,
    player: {
      ...basePlayer,
      ...(overrides.player ?? {}),
    },
  });
}

function assertClose(actual, expected, epsilon = 1e-9) {
  assert.ok(Math.abs(actual - expected) <= epsilon, `expected ${actual} to be within ${epsilon} of ${expected}`);
}

function freezeNpcCombat(state) {
  return {
    ...state,
    allies: state.allies.map((ally) => ({
      ...ally,
      attackTimer: Number.POSITIVE_INFINITY,
    })),
    enemies: state.enemies.map((enemy) => ({
      ...enemy,
      attackTimer: Number.POSITIVE_INFINITY,
      abilities: enemy.abilities.map((ability) => ({
        ...ability,
        remainingCooldown: Number.POSITIVE_INFINITY,
      })),
      casting: null,
    })),
  };
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
  const initial = freezeNpcCombat(createCombatState(createBootstrap()));
  const started = beginPlayerCast(initial, { spellId: "Heal", targetIds: ["ally-guardian-1"] });

  assert.deepEqual(started.events, [{
    type: "player_cast_started",
    at: 0,
    spellId: "Heal",
    targetIds: ["ally-guardian-1"],
  }]);
  assert.equal(started.state.player.casting?.remainingCastTime, 1.97);
  assert.equal(started.state.player.casting?.committedEnergyCost, 12);

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

test("cast requests are rejected when the player is already casting, lack energy, or request unknown spells", () => {
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

  const unknownSpell = beginPlayerCast(initial, { spellId: "UnknownSpell", targetIds: ["ally-guardian-2"] });
  assert.equal(unknownSpell.events[0].reason, "unknown_spell");
});

test("cast requests are rejected while a spell is still on cooldown", () => {
  const initial = createCombatState(createBootstrap());
  const completed = beginPlayerCast(initial, { spellId: "Purify", targetIds: ["ally-guardian-1"] });
  const repeated = beginPlayerCast(completed.state, { spellId: "Purify", targetIds: ["ally-guardian-1"] });

  assert.equal(completed.events[0].type, "player_cast_completed");
  assert.equal(repeated.events[0].reason, "spell_on_cooldown");
});

test("timed healing spells restore injured allies when casts complete", () => {
  const initial = freezeNpcCombat(createCombatState(createBootstrap()));
  const heal = initial.player.activeSpells.find((spell) => spell.id === "Heal");
  assert.ok(heal);

  const injured = {
    ...initial,
    player: {
      ...initial.player,
      activeSpells: initial.player.activeSpells.map((spell) => ({ ...spell })),
      casting: null,
    },
    allies: initial.allies.map((ally) => (
      ally.id === "ally-guardian-1"
        ? { ...ally, health: ally.health - 400 }
        : { ...ally }
    )),
    effects: [],
  };

  const started = beginPlayerCast(injured, { spellId: "Heal", targetIds: ["ally-guardian-1"] });
  const resolved = advanceCombatState(started.state, heal.castTime);
  const healedTarget = resolved.state.allies.find((ally) => ally.id === "ally-guardian-1");
  const injuredTarget = injured.allies.find((ally) => ally.id === "ally-guardian-1");
  const expectedHealing = Math.round(heal.healingAmount * initial.player.healingDoneMultiplier);

  assert.equal(resolved.events[0].type, "player_cast_completed");
  assert.deepEqual(resolved.events[1], {
    type: "health_changed",
    at: heal.castTime,
    spellId: "Heal",
    targetId: "ally-guardian-1",
    amount: expectedHealing,
  });
  assert.equal(healedTarget.health, injuredTarget.health + expectedHealing);
});

test("repeated healing effects tick deterministically and expire", () => {
  const initial = freezeNpcCombat(createCombatState(createBootstrap({
    player: {
      ownedSpellIds: ["Regrow"],
      selectedSpellIds: ["Regrow"],
      lastUsedSpellIds: ["Regrow"],
      equippedItems: [],
    },
  })));

  const regrow = initial.player.activeSpells.find((spell) => spell.id === "Regrow");
  assert.ok(regrow);

  const injured = {
    ...initial,
    player: {
      ...initial.player,
      activeSpells: initial.player.activeSpells.map((spell) => ({ ...spell })),
      casting: null,
    },
    allies: initial.allies.map((ally) => (
      ally.id === "ally-guardian-1"
        ? { ...ally, health: ally.health - 500 }
        : { ...ally }
    )),
    effects: [],
  };

  const applied = beginPlayerCast(injured, { spellId: "Regrow", targetIds: ["ally-guardian-1"] });
  assert.deepEqual(applied.events, [
    {
      type: "player_cast_completed",
      at: 0,
      spellId: "Regrow",
      targetIds: ["ally-guardian-1"],
    },
    {
      type: "effect_applied",
      at: 0,
      spellId: "Regrow",
      targetId: "ally-guardian-1",
      effectId: "regrow-effect",
    },
  ]);

  const tickAmount = Math.round(applied.state.effects[0].currentValuePerTick);
  const advanced = advanceCombatState(applied.state, 12);
  const healthEvents = advanced.events.filter((event) => event.type === "health_changed");
  const healedTarget = advanced.state.allies.find((ally) => ally.id === "ally-guardian-1");
  const injuredTarget = injured.allies.find((ally) => ally.id === "ally-guardian-1");

  assert.equal(healthEvents.length, 4);
  assert.ok(healthEvents.every((event) => event.amount === tickAmount));
  assert.deepEqual(advanced.events.at(-1), {
    type: "effect_expired",
    at: 12,
    spellId: "Regrow",
    targetId: "ally-guardian-1",
    effectId: "regrow-effect",
  });
  assert.equal(advanced.state.effects.length, 0);
  assert.equal(healedTarget.health, injuredTarget.health + (tickAmount * 4));
});

test("delayed healing effects resolve when the applied effect expires", () => {
  const initial = freezeNpcCombat(createCombatState(createBootstrap({
    player: {
      ownedSpellIds: ["BlessedArmor"],
      selectedSpellIds: ["BlessedArmor"],
      lastUsedSpellIds: ["BlessedArmor"],
      equippedItems: [],
    },
  })));

  const injured = {
    ...initial,
    player: {
      ...initial.player,
      activeSpells: initial.player.activeSpells.map((spell) => ({ ...spell })),
      casting: null,
    },
    allies: initial.allies.map((ally) => (
      ally.id === "ally-guardian-1"
        ? { ...ally, health: ally.health - 700 }
        : { ...ally }
    )),
    effects: [],
  };

  const applied = beginPlayerCast(injured, { spellId: "BlessedArmor", targetIds: ["ally-guardian-1"] });
  const delayedValue = Math.round(applied.state.effects[0].value);
  const resolved = advanceCombatState(applied.state, 5);
  const healedTarget = resolved.state.allies.find((ally) => ally.id === "ally-guardian-1");
  const injuredTarget = injured.allies.find((ally) => ally.id === "ally-guardian-1");

  assert.deepEqual(applied.events, [
    {
      type: "player_cast_completed",
      at: 0,
      spellId: "BlessedArmor",
      targetIds: ["ally-guardian-1"],
    },
    {
      type: "effect_applied",
      at: 0,
      spellId: "BlessedArmor",
      targetId: "ally-guardian-1",
      effectId: "blessed-armor-eff",
    },
  ]);
  assert.deepEqual(resolved.events, [
    {
      type: "health_changed",
      at: 5,
      spellId: "BlessedArmor",
      targetId: "ally-guardian-1",
      effectId: "blessed-armor-eff",
      amount: delayedValue,
    },
    {
      type: "effect_expired",
      at: 5,
      spellId: "BlessedArmor",
      targetId: "ally-guardian-1",
      effectId: "blessed-armor-eff",
    },
  ]);
  assert.equal(healedTarget.health, injuredTarget.health + delayedValue);
});

test("ally auto-attacks can finish the encounter and mark victory", () => {
  const initial = createCombatState(createBootstrap({
    level: 5,
    difficulty: 3,
    multiplayer: false,
  }));

  const tuned = {
    ...initial,
    allies: initial.allies.map((ally, index) => (
      index === 0
        ? { ...ally, damageDealt: 60, damageFrequency: 1, attackTimer: 1 }
        : { ...ally, damageDealt: 0, attackTimer: Number.POSITIVE_INFINITY }
    )),
    enemies: initial.enemies.map((enemy) => ({
      ...enemy,
      health: 100,
      maximumHealth: 100,
      attackTimer: Number.POSITIVE_INFINITY,
      abilities: [],
      casting: null,
    })),
  };

  const resolved = advanceCombatState(tuned, 2);

  assert.equal(resolved.state.result.status, "victory");
  assert.equal(resolved.state.result.reason, "all_enemies_defeated");
  assert.equal(resolved.state.result.finishedAt, 2);
  assert.equal(resolved.state.enemies[0].health, 0);
  assert.deepEqual(
    resolved.events.map((event) => event.type),
    ["ally_attack", "health_changed", "ally_attack", "health_changed", "combatant_defeated", "encounter_completed"],
  );
});

test("enemy abilities start on cooldown expiry and resolve after their activation time", () => {
  const initial = createCombatState(createBootstrap({
    level: 15,
    difficulty: 3,
    multiplayer: false,
  }));

  const tuned = {
    ...initial,
    allies: initial.allies.map((ally, index) => (
      index === 0
        ? { ...ally, health: 500, maximumHealth: 500, damageDealt: 0, attackTimer: Number.POSITIVE_INFINITY }
        : { ...ally, damageDealt: 0, attackTimer: Number.POSITIVE_INFINITY }
    )),
    enemies: initial.enemies.map((enemy, index) => (
      index === 0
        ? {
            ...enemy,
            attackTimer: Number.POSITIVE_INFINITY,
            abilities: enemy.abilities.map((ability) => (
              ability.id === "BoneThrow"
                ? { ...ability, remainingCooldown: 1 }
                : { ...ability, remainingCooldown: Number.POSITIVE_INFINITY }
            )),
            casting: null,
          }
        : { ...enemy, attackTimer: Number.POSITIVE_INFINITY, abilities: [], casting: null }
    )),
  };

  const resolved = advanceCombatState(tuned, 2.5);
  const targetId = tuned.allies[0].id;
  const target = resolved.state.allies.find((ally) => ally.id === targetId);

  assert.deepEqual(resolved.events, [
    {
      type: "enemy_ability_started",
      at: 1,
      actorId: "enemy-colossusofbone-1",
      abilityId: "BoneThrow",
      targetIds: [targetId],
    },
    {
      type: "enemy_ability_completed",
      at: 2.5,
      actorId: "enemy-colossusofbone-1",
      abilityId: "BoneThrow",
      targetIds: [targetId],
    },
    {
      type: "health_changed",
      at: 2.5,
      actorId: "enemy-colossusofbone-1",
      abilityId: "BoneThrow",
      targetId,
      amount: -240,
    },
  ]);
  assert.equal(target.health, 260);
});

test("enemy auto-attacks can defeat the raid and resolved encounters reject further casts", () => {
  const initial = createCombatState(createBootstrap({
    difficulty: 3,
    multiplayer: false,
  }));

  const tuned = {
    ...initial,
    player: {
      ...initial.player,
      activeSpells: initial.player.activeSpells.map((spell) => ({ ...spell })),
      casting: null,
    },
    allies: initial.allies.map((ally, index) => (
      index === 0
        ? { ...ally, health: 50, maximumHealth: 50, damageDealt: 0, attackTimer: Number.POSITIVE_INFINITY }
        : { ...ally, health: 0, damageDealt: 0, attackTimer: Number.POSITIVE_INFINITY }
    )),
    enemies: initial.enemies.map((enemy, index) => (
      index === 0
        ? { ...enemy, damagePerAttack: 80, attackFrequency: 1, attackTimer: 1, abilities: [], casting: null }
        : { ...enemy, attackTimer: Number.POSITIVE_INFINITY, abilities: [], casting: null }
    )),
  };

  const resolved = advanceCombatState(tuned, 1);

  assert.equal(resolved.state.result.status, "defeat");
  assert.equal(resolved.state.result.reason, "all_allies_defeated");
  assert.deepEqual(
    resolved.events.map((event) => event.type),
    ["enemy_auto_attack", "health_changed", "combatant_defeated", "encounter_completed"],
  );

  const rejected = beginPlayerCast(resolved.state, {
    spellId: "Heal",
    targetIds: ["ally-guardian-1"],
  });
  assert.equal(rejected.events[0].reason, "encounter_resolved");
});

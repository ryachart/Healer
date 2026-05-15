import { createRandomSource } from "./random.js";
import type {
  AllyRecord,
  AllySnapshot,
  EncounterBootstrapOptions,
  EncounterBootstrapSnapshot,
  EncounterRecord,
  EnemyRecord,
  EnemySnapshot,
  EquippedItemInput,
  NumericExpression,
  PlayerProfileInput,
  PlayerSnapshot,
} from "./types.js";
import type { GameRegistry } from "./registry.js";

const PLAYER_BASE_HEALTH = 1400;
const PLAYER_BASE_ENERGY = 1000;
const PLAYER_BASE_ENERGY_REGEN = 10;
const DEFAULT_CRITICAL_CHANCE = 0.05;
const PLAYER_BASE_COOLDOWN_ADJUSTMENT = 1;
const PLAYER_BASE_HEALING_MULTIPLIER = 1;

const ENEMY_HEALTH_MULTIPLIER: Record<number, number> = {
  1: 0.6,
  2: 0.8,
  3: 1,
  4: 1.15,
  5: 1.4,
};

const ENEMY_DAMAGE_MODIFIER: Record<number, number> = {
  1: -0.4,
  2: -0.2,
  3: 0,
  4: 0.125,
  5: 0.25,
};

function clampDifficulty(value: number, fallback: number): number {
  return Math.min(5, Math.max(1, Number.isFinite(value) ? value : fallback));
}

function numericValue(value: NumericExpression | number | null | undefined, context?: Record<string, number | null>): number | null {
  if (typeof value === "number") {
    return value;
  }
  if (!value) {
    return null;
  }
  if (value.value !== null) {
    return value.value;
  }
  if (context && Object.prototype.hasOwnProperty.call(context, value.expression)) {
    return context[value.expression] ?? null;
  }
  const parsed = Number(value.expression);
  return Number.isFinite(parsed) ? parsed : null;
}

function roundIfNumber(value: number | null): number | null {
  return value === null ? null : Math.round(value);
}

function buildOwnedSpellIds(registry: GameRegistry, encounter: EncounterRecord, player: PlayerProfileInput): string[] {
  if (player.ownedSpellIds && player.ownedSpellIds.length > 0) {
    return Array.from(new Set(player.ownedSpellIds.filter((spellId) => registry.spellsById.has(spellId))));
  }

  const owned = new Set<string>();
  for (const recommendedId of encounter.recommendedSpellIds) {
    if (registry.spellsById.has(recommendedId)) {
      owned.add(recommendedId);
    }
  }
  for (const [spellId, shopItem] of registry.shopItemsBySpellId.entries()) {
      if (shopItem.goldCost === 0) {
        owned.add(spellId);
      }
  }
  return Array.from(owned);
}

function buildActiveSpellIds(
  registry: GameRegistry,
  encounter: EncounterRecord,
  ownedSpellIds: string[],
  player: PlayerProfileInput,
  maximumStandardSpellSlots: number,
): string[] {
  const active: string[] = [];
  const owned = new Set(ownedSpellIds);

  let sourceOrder = encounter.recommendedSpellIds;
  if (player.selectedSpellIds && player.selectedSpellIds.length > 0) {
    sourceOrder = player.selectedSpellIds;
  } else if (player.lastUsedSpellIds && player.lastUsedSpellIds.length > 0) {
    sourceOrder = player.lastUsedSpellIds;
  }

  for (const spellId of sourceOrder) {
    if (owned.has(spellId) && !active.includes(spellId) && active.length < maximumStandardSpellSlots) {
      active.push(spellId);
    }
  }

  for (const spellId of ownedSpellIds) {
    if (!active.includes(spellId) && active.length < maximumStandardSpellSlots) {
      active.push(spellId);
    }
  }

  return active;
}

function buildPlayerSnapshot(registry: GameRegistry, encounter: EncounterRecord, player: PlayerProfileInput): PlayerSnapshot {
  const equippedItems = player.equippedItems ?? [];
  const maximumStandardSpellSlots = registry.progression.progressionRules.maximumStandardSpellSlots.base
    + (player.hasMainGameExpansion ? registry.progression.progressionRules.maximumStandardSpellSlots.mainGameExpansionBonus : 0);

  const ownedSpellIds = buildOwnedSpellIds(registry, encounter, player);
  const equippedItemSpellIds = Array.from(
    new Set(
      equippedItems
        .map((item) => item.spellId ?? null)
        .filter((spellId): spellId is string => typeof spellId === "string" && registry.spellsById.has(spellId)),
    ),
  );

  let healthBonus = 0;
  let healingBonus = 0;
  let regenBonus = 0;
  let critBonus = 0;
  let speedBonus = 0;
  for (const item of equippedItems) {
    healthBonus += item.health ?? 0;
    healingBonus += item.healing ?? 0;
    regenBonus += item.regen ?? 0;
    critBonus += item.crit ?? 0;
    speedBonus += item.speed ?? 0;
  }

  return {
    id: "player",
    title: "Healer",
    name: player.name ?? "Healer",
    health: PLAYER_BASE_HEALTH + healthBonus,
    maximumHealth: PLAYER_BASE_HEALTH + healthBonus,
    energy: PLAYER_BASE_ENERGY,
    maximumEnergy: PLAYER_BASE_ENERGY,
    energyRegenPerSecond: PLAYER_BASE_ENERGY_REGEN * (1 + regenBonus / 100),
    healingDoneMultiplier: PLAYER_BASE_HEALING_MULTIPLIER + healingBonus / 100,
    spellCriticalChance: DEFAULT_CRITICAL_CHANCE + critBonus / 100,
    cooldownAdjustment: PLAYER_BASE_COOLDOWN_ADJUSTMENT + speedBonus / 100,
    equippedItemSpellIds,
    ownedSpellIds,
    activeSpellIds: buildActiveSpellIds(registry, encounter, ownedSpellIds, player, maximumStandardSpellSlots),
  };
}

function buildAllyInstances(registry: GameRegistry, encounter: EncounterRecord, multiplayer: boolean, warnings: string[]): AllySnapshot[] {
  const snapshots: AllySnapshot[] = [];
  const composition = new Map<string, number>();

  for (const [allyId, count] of Object.entries(encounter.allyComposition)) {
    composition.set(allyId, count);
  }

  if (multiplayer) {
    for (const [allyId, delta] of Object.entries(encounter.multiplayerAdjustments ?? {})) {
      composition.set(allyId, Math.max(0, (composition.get(allyId) ?? 0) + delta));
    }
  }

  for (const [allyId, count] of composition.entries()) {
    const ally = registry.alliesByNormalizedId.get(allyId.toLowerCase());
    if (!ally) {
      warnings.push(`Missing ally archetype for '${allyId}'.`);
      continue;
    }
    for (let instance = 0; instance < count; instance += 1) {
      snapshots.push(createAllySnapshot(ally, instance + 1));
    }
  }

  return snapshots;
}

function createAllySnapshot(ally: AllyRecord, index: number): AllySnapshot {
  return {
    id: `ally-${ally.id.toLowerCase()}-${index}`,
    archetypeId: ally.id,
    title: ally.title,
    info: ally.info,
    positioning: ally.positioning,
    health: roundIfNumber(numericValue(ally.health)) ?? 0,
    maximumHealth: roundIfNumber(numericValue(ally.health)) ?? 0,
    damageDealt: roundIfNumber(numericValue(ally.damageDealt)) ?? 0,
    damageFrequency: numericValue(ally.damageFrequency) ?? 0,
    dodgeChance: numericValue(ally.dodgeChance) ?? 0,
    criticalChance: numericValue(ally.criticalChance) ?? DEFAULT_CRITICAL_CHANCE,
  };
}

function mergeEnemyRecord(baseEnemy: EnemyRecord | undefined, rosterEnemy: EnemyRecord): EnemyRecord {
  return {
    ...(baseEnemy ?? {}),
    ...rosterEnemy,
    className: rosterEnemy.className,
  };
}

function createEnemySnapshot(
  enemy: EnemyRecord,
  index: number,
  difficulty: number,
  primaryBossBaseHealth: number | null,
  warnings: string[],
): EnemySnapshot {
  const baseHealth = numericValue(enemy.health, { "boss.health": primaryBossBaseHealth });
  const baseDamage = numericValue(enemy.damage);
  const healthMultiplier = ENEMY_HEALTH_MULTIPLIER[difficulty];
  const damageModifier = ENEMY_DAMAGE_MODIFIER[difficulty];
  const maximumHealth = baseHealth === null ? null : Math.round(baseHealth * healthMultiplier);
  const damagePerAttack = baseDamage === null ? null : Math.round(baseDamage * (1 + damageModifier));
  const attackFrequency = numericValue(enemy.attackFrequency ?? null);
  const targets = numericValue(enemy.targets ?? null);
  const threatPriority = numericValue(enemy.threatPriority ?? null);

  if (baseHealth === null && enemy.health) {
    warnings.push(`Could not resolve health for enemy '${enemy.className}' (${enemy.health.expression}).`);
  }

  return {
    id: `enemy-${enemy.className.toLowerCase()}-${index}`,
    className: enemy.className,
    title: typeof enemy.title === "string" ? enemy.title : enemy.className,
    spriteName: typeof enemy.spriteName === "string" ? enemy.spriteName : null,
    health: maximumHealth,
    maximumHealth,
    baseHealth,
    baseDamage,
    damagePerAttack,
    damageDoneMultiplier: 1 + damageModifier,
    attackFrequency,
    targets,
    choosesMainTarget: enemy.choosesMainTarget !== false,
    threatPriority,
    source: typeof enemy.source === "string" ? enemy.source : "registry",
  };
}

function buildEnemyInstances(registry: GameRegistry, encounter: EncounterRecord, difficulty: number, warnings: string[]): EnemySnapshot[] {
  const roster = encounter.enemyRoster.map((enemy) => mergeEnemyRecord(registry.enemiesByClassName.get(enemy.className), enemy));
  const primaryBossBaseHealth = numericValue(roster[0]?.health ?? null);
  return roster.map((enemy, index) => createEnemySnapshot(enemy, index + 1, difficulty, primaryBossBaseHealth, warnings));
}

export function createEncounterBootstrap(registry: GameRegistry, options: EncounterBootstrapOptions): EncounterBootstrapSnapshot {
  const encounter = registry.encountersByLevel.get(options.level);
  if (!encounter) {
    throw new Error(`Unknown encounter level '${options.level}'.`);
  }

  const warnings: string[] = [];
  const random = createRandomSource(options.seed);
  const difficulty = clampDifficulty(
    options.difficulty ?? registry.progression.progressionRules.difficultyDefaultValue,
    registry.progression.progressionRules.difficultyDefaultValue,
  );
  const player = buildPlayerSnapshot(registry, encounter, options.player ?? {});
  const multiplayer = options.multiplayer ?? false;

  return {
    schemaVersion: 1,
    replay: {
      seed: random.seed,
      version: 1,
    },
    encounter: {
      level: encounter.level,
      title: encounter.title,
      info: encounter.info,
      bossKey: encounter.bossKey,
      difficulty,
      multiplayer,
      backgroundKey: encounter.backgroundKey,
      battleTrackTitle: encounter.battleTrackTitle,
      recommendedSpellIds: encounter.recommendedSpellIds.slice(),
      requiredSpellIds: encounter.requiredSpellIds?.slice() ?? [],
    },
    player,
    allies: buildAllyInstances(registry, encounter, multiplayer, warnings),
    enemies: buildEnemyInstances(registry, encounter, difficulty, warnings),
    rewards: {
      gold: encounter.baseRewardGold + (difficulty - 1) * 25,
      lootRuleId: encounter.lootRuleId ?? null,
    },
    warnings,
  };
}

import { createRandomSource } from "./random.js";
import type { GameRegistry } from "./registry.js";
import type {
  CombatStateSnapshot,
  EncounterLootSnapshot,
  EncounterProgressionInput,
  EncounterResolutionSnapshot,
  EquipmentSchemaPayload,
  LootRuleItemRecord,
} from "./types.js";

const FIRST_LEVEL_VICTORY_GOLD = 25;
const DIFFICULTY_REWARD_STEP_GOLD = 25;
const RATING_IMPROVEMENT_GOLD_BONUS = 25;
const UNCOMMON_CHEST_BONUS_STATS = 1;
const UNCOMMON_CHEST_MINIMUM_QUALITY = 2;
const EARLY_GAME_LEVEL_MAX = 7;
const MID_GAME_LEVEL_MAX = 13;
const EARLY_GAME_QUALITY_BONUS = 0;
const MID_GAME_QUALITY_BONUS = 2;
const LATE_GAME_QUALITY_BONUS = 4;
const EARLY_GAME_QUALITY_CAP = 4;
const MID_GAME_QUALITY_CAP = 6;
const LATE_GAME_QUALITY_CAP = 8;

function normalizeLevelMap(values: Record<string, number> | undefined): Record<string, number> {
  const normalized: Record<string, number> = {};
  if (!values) {
    return normalized;
  }
  for (const [key, value] of Object.entries(values)) {
    const parsed = Number.parseInt(key, 10);
    normalized[Number.isNaN(parsed) ? key : String(parsed)] = Math.max(0, Math.trunc(value));
  }
  return normalized;
}

function getLevelValue(values: Record<string, number>, level: number): number {
  return values[String(level)] ?? 0;
}

function totalRatingForProgression(registry: GameRegistry, ratingsByLevel: Record<string, number>): number {
  const startLevel = registry.progression.progressionRules.totalRatingStartsAtLevel;
  return Object.entries(ratingsByLevel).reduce((total, [key, value]) => {
    const level = Number.parseInt(key, 10);
    if (!Number.isFinite(level) || level < startLevel) {
      return total;
    }
    return total + value;
  }, 0);
}

function unlockedTalentTiers(registry: GameRegistry, totalRating: number): number[] {
  return registry.progression.progressionRules.talentTierUnlocks
    .filter((rule) => totalRating >= rule.requiredRating)
    .map((rule) => rule.tier);
}

function randomIndex(random: { next(): number }, length: number): number {
  return Math.min(length - 1, Math.floor(random.next() * length));
}

function rarityValueForId(equipmentSchema: EquipmentSchemaPayload, rarityId: string): number {
  return equipmentSchema.rarities.find((rarity) => rarity.id === rarityId)?.value ?? 1;
}

function salePriceForItem(equipmentSchema: EquipmentSchemaPayload, rarityId: string, quality: number): number {
  return 5 * (quality + (rarityValueForId(equipmentSchema, rarityId) * 2));
}

function normalizeRarityId(value: string): string {
  return value.replace(/^ItemRarity/, "").toLowerCase();
}

function resolveLootQuality(registry: GameRegistry, level: number, difficulty: number): number {
  const qualityByLevel = registry.lootRules.qualityRules.evaluatedLevelTable.find((entry) => entry.level === level);
  const resolved = qualityByLevel?.qualityByDifficulty[String(difficulty)] ?? null;
  if (resolved !== null) {
    return resolved;
  }
  const qualityBonus = level <= EARLY_GAME_LEVEL_MAX
    ? EARLY_GAME_QUALITY_BONUS
    : level <= MID_GAME_LEVEL_MAX
      ? MID_GAME_QUALITY_BONUS
      : LATE_GAME_QUALITY_BONUS;
  const qualityCap = level <= EARLY_GAME_LEVEL_MAX
    ? EARLY_GAME_QUALITY_CAP
    : level <= MID_GAME_LEVEL_MAX
      ? MID_GAME_QUALITY_CAP
      : LATE_GAME_QUALITY_CAP;
  return Math.min(difficulty + qualityBonus, qualityCap);
}

function createProceduralLootItem(
  registry: GameRegistry,
  rarityId: string,
  quality: number,
  random: { next(): number },
): EncounterLootSnapshot {
  const { equipmentSchema } = registry;
  const slotIds = equipmentSchema.slotTypes
    .slice()
    .sort((left, right) => left.value - right.value)
    .map((slot) => slot.id);
  const slot = slotIds[randomIndex(random, slotIds.length)];
  const rarityValue = rarityValueForId(equipmentSchema, rarityId);
  let totalStats = rarityValue;
  let adjustedQuality = quality;
  if (rarityId === "uncommon" && slot === "chest") {
    totalStats += UNCOMMON_CHEST_BONUS_STATS;
    if (adjustedQuality === 1) {
      adjustedQuality = UNCOMMON_CHEST_MINIMUM_QUALITY;
    }
  }

  const statIds = equipmentSchema.statTypes
    .slice()
    .sort((left, right) => left.value - right.value)
    .map((stat) => stat.id);
  const selectedStatIds = statIds.slice();
  while (selectedStatIds.length > Math.max(1, totalStats)) {
    selectedStatIds.splice(randomIndex(random, selectedStatIds.length), 1);
  }
  if (slot === "chest" && !selectedStatIds.includes("health")) {
    selectedStatIds.splice(randomIndex(random, selectedStatIds.length), 1, "health");
  }

  const slotModifier = equipmentSchema.proceduralGenerationRules.slotModifiers[slot] ?? 1;
  let totalAtoms = Math.max(0, Math.floor(adjustedQuality * slotModifier * rarityValue));
  const stats = Object.fromEntries(equipmentSchema.statTypes.map((stat) => [stat.id, 0])) as Record<string, number>;
  for (const statId of selectedStatIds) {
    const atom = equipmentSchema.statTypes.find((stat) => stat.id === statId)?.atom ?? 0;
    stats[statId] += atom;
    totalAtoms -= 1;
  }
  while (totalAtoms > 0) {
    const statId = selectedStatIds[randomIndex(random, selectedStatIds.length)];
    const atom = equipmentSchema.statTypes.find((stat) => stat.id === statId)?.atom ?? 0;
    stats[statId] += atom;
    totalAtoms -= 1;
  }

  const prefixes = equipmentSchema.proceduralGenerationRules.namePools.prefixesBySlot[slot] ?? [slot];
  const suffixes = equipmentSchema.proceduralGenerationRules.namePools.suffixes;
  const name = `${prefixes[randomIndex(random, prefixes.length)]} of ${suffixes[randomIndex(random, suffixes.length)]}`;
  let specialKey: string | null = null;
  const { weaponSpecials } = equipmentSchema.proceduralGenerationRules;
  if (slot === "weapon" && adjustedQuality >= weaponSpecials.minimumQualityForSpecialKey && weaponSpecials.candidateSpecialKeys.length > 0) {
    specialKey = weaponSpecials.candidateSpecialKeys[randomIndex(random, weaponSpecials.candidateSpecialKeys.length)] ?? null;
  }

  return {
    id: null,
    name,
    source: "procedural",
    rarity: rarityId,
    quality: adjustedQuality,
    slot,
    health: stats.health,
    healing: stats.healing,
    regen: stats.regen,
    crit: stats.crit,
    speed: stats.speed,
    specialKey,
    salePrice: salePriceForItem(equipmentSchema, rarityId, adjustedQuality),
  };
}

function toLootSnapshot(registry: GameRegistry, item: LootRuleItemRecord): EncounterLootSnapshot {
  const rarityId = normalizeRarityId(item.rarity);
  return {
    id: item.id,
    name: item.name,
    source: "encounter_specific",
    rarity: rarityId,
    quality: item.quality,
    slot: item.slot.replace(/^SlotType/, "").toLowerCase(),
    health: item.health,
    healing: item.healing,
    regen: item.regen,
    crit: item.crit,
    speed: item.speed,
    specialKey: item.specialKey,
    salePrice: salePriceForItem(registry.equipmentSchema, rarityId, item.quality),
  };
}

function pickWeightedLoot(
  registry: GameRegistry,
  level: number,
  difficulty: number,
  seed: number,
  totalItemsEarned: number,
): EncounterLootSnapshot | null {
  const random = createRandomSource(`${seed}:loot:${level}:${difficulty}:${totalItemsEarned}`);
  const rarityOrder = registry.lootRules.rarityOrder;
  const weights = registry.lootRules.rarityRollWeightsByDifficulty[String(difficulty)] ?? [];
  const totalWeight = weights.reduce((sum, weight) => sum + Math.max(0, weight), 0);
  if (!(totalWeight > 0)) {
    return null;
  }

  const quality = resolveLootQuality(registry, level, difficulty);
  const encounterEpics = registry.lootRules.encounterSpecificDrops.epic.filter((item) => item.dropLevels.includes(level));
  const encounterLegendaries = registry.lootRules.encounterSpecificDrops.legendary.filter((item) => item.dropLevels.includes(level));
  const lootByRarity = new Map<string, EncounterLootSnapshot>([
    ["uncommon", createProceduralLootItem(registry, "uncommon", quality, random)],
    ["rare", createProceduralLootItem(registry, "rare", quality, random)],
    ["epic", encounterEpics.length > 0
      ? toLootSnapshot(registry, encounterEpics[randomIndex(random, encounterEpics.length)])
      : createProceduralLootItem(registry, "rare", quality, random)],
    ["legendary", encounterLegendaries.length > 0
      ? toLootSnapshot(registry, encounterLegendaries[randomIndex(random, encounterLegendaries.length)])
      : encounterEpics.length > 0
        ? toLootSnapshot(registry, encounterEpics[randomIndex(random, encounterEpics.length)])
        : createProceduralLootItem(registry, "rare", quality, random)],
  ]);

  let roll = random.next() * totalWeight;
  for (let index = 0; index < rarityOrder.length; index += 1) {
    const weight = Math.max(0, weights[index] ?? 0);
    if (weight <= 0) {
      continue;
    }
    if (roll < weight) {
      return lootByRarity.get(rarityOrder[index]) ?? null;
    }
    roll -= weight;
  }

  return lootByRarity.get(rarityOrder[rarityOrder.length - 1]) ?? null;
}

function calculateGoldReward(
  registry: GameRegistry,
  state: CombatStateSnapshot,
  highestLevelCompleted: number,
): number {
  if (state.result.status !== "victory") {
    return 0;
  }
  if (state.encounter.level === 1 && highestLevelCompleted === 0) {
    return FIRST_LEVEL_VICTORY_GOLD;
  }
  return Math.max(0, registry.encountersByLevel.get(state.encounter.level)?.baseRewardGold ?? 0)
    + ((state.encounter.difficulty - 1) * DIFFICULTY_REWARD_STEP_GOLD);
}

export function resolveEncounterOutcome(
  registry: GameRegistry,
  state: CombatStateSnapshot,
  progressionInput: EncounterProgressionInput = {},
): EncounterResolutionSnapshot {
  if (state.result.status === "in_progress" || state.result.finishedAt === null) {
    throw new Error("Cannot resolve rewards or progression before the encounter is complete.");
  }

  const level = state.encounter.level;
  const ratingsByLevel = normalizeLevelMap(progressionInput.ratingsByLevel);
  const scoresByLevel = normalizeLevelMap(progressionInput.scoresByLevel);
  const failureCountsByLevel = normalizeLevelMap(progressionInput.failureCountsByLevel);
  let highestLevelCompleted = Math.max(0, progressionInput.highestLevelCompleted ?? 0);
  let gold = Math.max(0, progressionInput.gold ?? 0);
  let inventoryCount = Math.max(0, progressionInput.inventoryCount ?? 0);
  let totalItemsEarned = Math.max(0, progressionInput.totalItemsEarned ?? 0);

  const duration = Math.max(state.result.finishedAt, state.time, 0);
  const score = duration > 0
    ? Math.trunc(((state.metrics.scoreTally * 1000) + (200 * state.encounter.difficulty)) / duration)
    : 0;
  const previousBestScore = getLevelValue(scoresByLevel, level);
  const previousRating = getLevelValue(ratingsByLevel, level);

  let goldAwarded = 0;
  let updatedRating = previousRating;
  let ratingImproved = false;
  let newBestScore = false;

  if (state.result.status === "victory") {
    goldAwarded = calculateGoldReward(registry, state, highestLevelCompleted);

    if (!state.encounter.multiplayer) {
      highestLevelCompleted = Math.max(highestLevelCompleted, level);
      if (state.encounter.difficulty > previousRating) {
        updatedRating = state.encounter.difficulty;
        ratingsByLevel[String(level)] = updatedRating;
        ratingImproved = true;
        if (state.encounter.difficulty > 1 && level !== 1) {
          goldAwarded += RATING_IMPROVEMENT_GOLD_BONUS;
        }
      }

      if (score > previousBestScore) {
        scoresByLevel[String(level)] = score;
        newBestScore = true;
      }
    }
  } else {
    failureCountsByLevel[String(level)] = getLevelValue(failureCountsByLevel, level) + 1;
  }

  gold += goldAwarded;

  let lootBlockedReason: EncounterResolutionSnapshot["rewards"]["lootBlockedReason"] = null;
  let lootEligible = false;
  let loot: EncounterLootSnapshot | null = null;
  if (state.result.status !== "victory") {
    lootBlockedReason = "not_victory";
  } else if (level <= 1) {
    lootBlockedReason = "tutorial_level";
  } else if (inventoryCount >= registry.progression.progressionRules.maximumInventorySize) {
    lootBlockedReason = "inventory_full";
  } else {
    lootEligible = true;
    loot = pickWeightedLoot(registry, level, state.encounter.difficulty, state.replay.seed, totalItemsEarned);
    if (loot) {
      inventoryCount += 1;
      totalItemsEarned += 1;
    }
  }

  const totalRating = totalRatingForProgression(registry, ratingsByLevel);
  const unlockedTiers = unlockedTalentTiers(registry, totalRating);

  return {
    schemaVersion: 1,
    encounter: {
      level,
      title: state.encounter.title,
      difficulty: state.encounter.difficulty,
      multiplayer: state.encounter.multiplayer,
    },
    result: { ...state.result },
    metrics: {
      ...state.metrics,
      duration,
      score,
    },
    rewards: {
      goldAwarded,
      previousBestScore,
      newBestScore,
      previousRating,
      updatedRating,
      ratingImproved,
      lootEligible,
      lootBlockedReason,
      loot,
    },
    progression: {
      gold,
      highestLevelCompleted,
      ratingsByLevel,
      scoresByLevel,
      failureCountsByLevel,
      inventoryCount,
      totalItemsEarned,
      totalRating,
      unlockedTalentTiers: unlockedTiers,
      multiplayerUnlocked: highestLevelCompleted >= registry.progression.progressionRules.multiplayerUnlockAtHighestLevelCompleted,
      talentsUnlocked: unlockedTiers.length > 0,
    },
    warnings: state.warnings.slice(),
  };
}

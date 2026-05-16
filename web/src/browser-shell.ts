import { createEncounterBootstrap } from "./engine/bootstrap.js";
import type { GameRegistry } from "./engine/registry.js";
import type {
  EncounterBootstrapSnapshot,
  EncounterProgressionInput,
  EncounterResolutionSnapshot,
  EquippedItemInput,
  PlayerProfileInput,
} from "./engine/types.js";

export interface BrowserShellProfile {
  name: string;
  highestLevelCompleted: number;
  selectedSpellIds: string[];
  lastUsedSpellIds: string[];
  ownedSpellIds: string[];
  equippedItems: EquippedItemInput[];
  hasMainGameExpansion: boolean;
  difficultyByLevel: Record<number, number>;
  gold: number;
  ratingsByLevel: Record<string, number>;
  scoresByLevel: Record<string, number>;
  failureCountsByLevel: Record<string, number>;
  inventoryCount: number;
  totalItemsEarned: number;
  unlockedTalentTiers: number[];
}

export interface WorldMapEncounterViewModel {
  level: number;
  title: string;
  bossKey: string;
  backgroundKey: string;
  rewardGold: number;
  recommendedSpellIds: string[];
  unlocked: boolean;
}

export interface PrebattleViewModel {
  bootstrap: EncounterBootstrapSnapshot;
  selectedSpells: Array<{
    id: string;
    title: string;
    spellType: string | null;
  }>;
  allySummary: Array<{
    title: string;
    count: number;
  }>;
}

const DEFAULT_OWNED_SPELL_IDS = [
  "Heal",
  "GreaterHeal",
  "ForkedHeal",
  "Purify",
  "Regrow",
  "Barrier",
];

const DEFAULT_SELECTED_SPELL_IDS = [
  "Heal",
  "GreaterHeal",
  "Purify",
  "Barrier",
];

const MIN_ENCOUNTER_LEVEL = 1;
const MIN_DIFFICULTY = 1;
const MAX_DIFFICULTY = 5;
const FALLBACK_DIFFICULTY = 2;

function isFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

function sanitizeStringArray(value: unknown): string[] | null {
  if (!Array.isArray(value)) {
    return null;
  }
  return value.filter((entry): entry is string => typeof entry === "string");
}

function sanitizeNumberArray(value: unknown): number[] | null {
  if (!Array.isArray(value)) {
    return null;
  }
  return value
    .filter((entry): entry is number => isFiniteNumber(entry))
    .map((entry) => Math.max(0, Math.floor(entry)));
}

function sanitizeEquippedItem(item: unknown): EquippedItemInput | null {
  if (!item || typeof item !== "object" || Array.isArray(item)) {
    return null;
  }

  const source = item as Record<string, unknown>;
  const sanitized: EquippedItemInput = {};

  if (typeof source.id === "string") {
    sanitized.id = source.id;
  }
  if (isFiniteNumber(source.health)) {
    sanitized.health = source.health;
  }
  if (isFiniteNumber(source.healing)) {
    sanitized.healing = source.healing;
  }
  if (isFiniteNumber(source.regen)) {
    sanitized.regen = source.regen;
  }
  if (isFiniteNumber(source.crit)) {
    sanitized.crit = source.crit;
  }
  if (isFiniteNumber(source.speed)) {
    sanitized.speed = source.speed;
  }
  if (typeof source.spellId === "string" || source.spellId === null) {
    sanitized.spellId = source.spellId;
  }

  return Object.keys(sanitized).length > 0 ? sanitized : null;
}

function sanitizeDifficultyByLevel(value: unknown): Record<number, number> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }

  const entries: Array<[number, number]> = [];
  for (const [key, difficulty] of Object.entries(value)) {
    const level = Number(key);
    if (!Number.isInteger(level) || level < MIN_ENCOUNTER_LEVEL) {
      continue;
    }
    if (!isFiniteNumber(difficulty)) {
      continue;
    }
    entries.push([level, difficulty]);
  }

  return Object.fromEntries(entries);
}

function sanitizeProgressionMap(value: unknown): Record<string, number> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }

  const entries: Array<[string, number]> = [];
  for (const [key, amount] of Object.entries(value)) {
    const level = Number.parseInt(key, 10);
    if (!Number.isFinite(level) || level < MIN_ENCOUNTER_LEVEL || !isFiniteNumber(amount)) {
      continue;
    }
    entries.push([String(level), Math.max(0, Math.floor(amount))]);
  }

  return Object.fromEntries(entries);
}

function sanitizeHighestLevelCompleted(value: unknown, fallback: number): number {
  if (!isFiniteNumber(value)) {
    return fallback;
  }
  return Math.max(0, Math.floor(value));
}

function sanitizeDifficulty(value: unknown, fallback: number): number {
  if (!isFiniteNumber(value)) {
    return fallback;
  }
  return Math.max(MIN_DIFFICULTY, Math.min(MAX_DIFFICULTY, Math.round(value)));
}

function sanitizeNonNegativeNumber(value: unknown, fallback: number): number {
  if (!isFiniteNumber(value)) {
    return fallback;
  }
  return Math.max(0, Math.floor(value));
}

export function createDefaultBrowserShellProfile(): BrowserShellProfile {
  return {
    name: "Ayla",
    highestLevelCompleted: 0,
    selectedSpellIds: DEFAULT_SELECTED_SPELL_IDS.slice(),
    lastUsedSpellIds: DEFAULT_SELECTED_SPELL_IDS.slice(),
    ownedSpellIds: DEFAULT_OWNED_SPELL_IDS.slice(),
    equippedItems: [],
    hasMainGameExpansion: false,
    difficultyByLevel: {},
    gold: 0,
    ratingsByLevel: {},
    scoresByLevel: {},
    failureCountsByLevel: {},
    inventoryCount: 0,
    totalItemsEarned: 0,
    unlockedTalentTiers: [],
  };
}

export function createPlayerProfileInput(profile: BrowserShellProfile): PlayerProfileInput {
  return {
    name: profile.name,
    ownedSpellIds: profile.ownedSpellIds.slice(),
    selectedSpellIds: profile.selectedSpellIds.slice(),
    lastUsedSpellIds: profile.lastUsedSpellIds.slice(),
    equippedItems: profile.equippedItems.map((item) => ({ ...item })),
    hasMainGameExpansion: profile.hasMainGameExpansion,
  };
}

export function createEncounterProgressionInput(profile: BrowserShellProfile): EncounterProgressionInput {
  return {
    gold: profile.gold,
    highestLevelCompleted: profile.highestLevelCompleted,
    ratingsByLevel: { ...profile.ratingsByLevel },
    scoresByLevel: { ...profile.scoresByLevel },
    failureCountsByLevel: { ...profile.failureCountsByLevel },
    inventoryCount: profile.inventoryCount,
    totalItemsEarned: profile.totalItemsEarned,
  };
}

export function applyEncounterResolutionToProfile(
  profile: BrowserShellProfile,
  resolution: EncounterResolutionSnapshot,
): BrowserShellProfile {
  return {
    ...profile,
    gold: resolution.progression.gold,
    highestLevelCompleted: resolution.progression.highestLevelCompleted,
    ratingsByLevel: { ...resolution.progression.ratingsByLevel },
    scoresByLevel: { ...resolution.progression.scoresByLevel },
    failureCountsByLevel: { ...resolution.progression.failureCountsByLevel },
    inventoryCount: resolution.progression.inventoryCount,
    totalItemsEarned: resolution.progression.totalItemsEarned,
    unlockedTalentTiers: resolution.progression.unlockedTalentTiers.slice(),
  };
}

export function highestUnlockedEncounterLevel(profile: BrowserShellProfile): number {
  return sanitizeHighestLevelCompleted(profile.highestLevelCompleted, 0) + MIN_ENCOUNTER_LEVEL;
}

export function createWorldMapViewModel(
  registry: GameRegistry,
  profile: BrowserShellProfile,
): WorldMapEncounterViewModel[] {
  const highestUnlockedLevel = highestUnlockedEncounterLevel(profile);
  return registry.encounters.map((encounter) => ({
    level: encounter.level,
    title: encounter.title,
    bossKey: encounter.bossKey,
    backgroundKey: encounter.backgroundKey,
    rewardGold: encounter.baseRewardGold,
    recommendedSpellIds: encounter.recommendedSpellIds.slice(),
    unlocked: encounter.level <= highestUnlockedLevel,
  }));
}

export function difficultyForEncounter(registry: GameRegistry, profile: BrowserShellProfile, level: number): number {
  const configuredDifficulty = profile.difficultyByLevel[level];
  const defaultDifficulty = registry.progression.progressionRules.difficultyDefaultValue;
  const sanitizedDefaultDifficulty = sanitizeDifficulty(defaultDifficulty, FALLBACK_DIFFICULTY);
  return sanitizeDifficulty(configuredDifficulty, sanitizedDefaultDifficulty);
}

export function sanitizeBrowserShellProfile(
  value: unknown,
  fallback: BrowserShellProfile = createDefaultBrowserShellProfile(),
): BrowserShellProfile {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return fallback;
  }

  const source = value as Record<string, unknown>;
  return {
    name: typeof source.name === "string" ? source.name : fallback.name,
    highestLevelCompleted: sanitizeHighestLevelCompleted(source.highestLevelCompleted, fallback.highestLevelCompleted),
    selectedSpellIds: sanitizeStringArray(source.selectedSpellIds) ?? fallback.selectedSpellIds.slice(),
    lastUsedSpellIds: sanitizeStringArray(source.lastUsedSpellIds) ?? fallback.lastUsedSpellIds.slice(),
    ownedSpellIds: sanitizeStringArray(source.ownedSpellIds) ?? fallback.ownedSpellIds.slice(),
    equippedItems: Array.isArray(source.equippedItems)
      ? source.equippedItems.map(sanitizeEquippedItem).filter((item): item is EquippedItemInput => item !== null)
      : fallback.equippedItems.map((item) => ({ ...item })),
    hasMainGameExpansion: typeof source.hasMainGameExpansion === "boolean"
      ? source.hasMainGameExpansion
      : fallback.hasMainGameExpansion,
    difficultyByLevel: sanitizeDifficultyByLevel(source.difficultyByLevel)
      ?? { ...fallback.difficultyByLevel },
    gold: sanitizeNonNegativeNumber(source.gold, fallback.gold),
    ratingsByLevel: sanitizeProgressionMap(source.ratingsByLevel) ?? { ...fallback.ratingsByLevel },
    scoresByLevel: sanitizeProgressionMap(source.scoresByLevel) ?? { ...fallback.scoresByLevel },
    failureCountsByLevel: sanitizeProgressionMap(source.failureCountsByLevel) ?? { ...fallback.failureCountsByLevel },
    inventoryCount: sanitizeNonNegativeNumber(source.inventoryCount, fallback.inventoryCount),
    totalItemsEarned: sanitizeNonNegativeNumber(source.totalItemsEarned, fallback.totalItemsEarned),
    unlockedTalentTiers: sanitizeNumberArray(source.unlockedTalentTiers) ?? fallback.unlockedTalentTiers.slice(),
  };
}

export function createPrebattleViewModel(
  registry: GameRegistry,
  profile: BrowserShellProfile,
  level: number,
): PrebattleViewModel {
  const bootstrap = createEncounterBootstrap(registry, {
    level,
    difficulty: difficultyForEncounter(registry, profile, level),
    seed: `browser-shell-level-${level}`,
    player: createPlayerProfileInput(profile),
  });

  const allyCounts = new Map<string, number>();
  for (const ally of bootstrap.allies) {
    allyCounts.set(ally.title, (allyCounts.get(ally.title) ?? 0) + 1);
  }

  return {
    bootstrap,
    selectedSpells: bootstrap.player.activeSpells.map((spell) => ({
      id: spell.id,
      title: spell.title,
      spellType: spell.spellType,
    })),
    allySummary: Array.from(allyCounts.entries())
      .map(([title, count]) => ({ title, count }))
      .sort((left, right) => left.title.localeCompare(right.title)),
  };
}

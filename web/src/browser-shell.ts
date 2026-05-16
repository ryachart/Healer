import { createEncounterBootstrap } from "./engine/bootstrap.js";
import type { GameRegistry } from "./engine/registry.js";
import type { EncounterBootstrapSnapshot, EquippedItemInput, PlayerProfileInput } from "./engine/types.js";

export interface BrowserShellProfile {
  name: string;
  highestLevelCompleted: number;
  selectedSpellIds: string[];
  lastUsedSpellIds: string[];
  ownedSpellIds: string[];
  equippedItems: EquippedItemInput[];
  hasMainGameExpansion: boolean;
  difficultyByLevel: Record<number, number>;
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

export function createDefaultBrowserShellProfile(): BrowserShellProfile {
  return {
    name: "Ayla",
    highestLevelCompleted: 1,
    selectedSpellIds: DEFAULT_SELECTED_SPELL_IDS.slice(),
    lastUsedSpellIds: DEFAULT_SELECTED_SPELL_IDS.slice(),
    ownedSpellIds: DEFAULT_OWNED_SPELL_IDS.slice(),
    equippedItems: [],
    hasMainGameExpansion: false,
    difficultyByLevel: {},
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

export function highestUnlockedEncounterLevel(profile: BrowserShellProfile): number {
  return Math.max(1, profile.highestLevelCompleted + 1);
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
  return Math.max(1, Math.min(5, configuredDifficulty ?? defaultDifficulty));
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

import { createEncounterBootstrap } from "./engine/bootstrap.js";
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
export function createDefaultBrowserShellProfile() {
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
export function createPlayerProfileInput(profile) {
    return {
        name: profile.name,
        ownedSpellIds: profile.ownedSpellIds.slice(),
        selectedSpellIds: profile.selectedSpellIds.slice(),
        lastUsedSpellIds: profile.lastUsedSpellIds.slice(),
        equippedItems: profile.equippedItems.map((item) => ({ ...item })),
        hasMainGameExpansion: profile.hasMainGameExpansion,
    };
}
export function highestUnlockedEncounterLevel(profile) {
    return Math.max(1, profile.highestLevelCompleted + 1);
}
export function createWorldMapViewModel(registry, profile) {
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
export function difficultyForEncounter(registry, profile, level) {
    const configuredDifficulty = profile.difficultyByLevel[level];
    const defaultDifficulty = registry.progression.progressionRules.difficultyDefaultValue;
    return Math.max(1, Math.min(5, configuredDifficulty ?? defaultDifficulty));
}
export function createPrebattleViewModel(registry, profile, level) {
    const bootstrap = createEncounterBootstrap(registry, {
        level,
        difficulty: difficultyForEncounter(registry, profile, level),
        seed: `browser-shell-level-${level}`,
        player: createPlayerProfileInput(profile),
    });
    const allyCounts = new Map();
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
//# sourceMappingURL=browser-shell.js.map
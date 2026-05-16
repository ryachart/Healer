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
const MIN_ENCOUNTER_LEVEL = 1;
const MIN_DIFFICULTY = 1;
const MAX_DIFFICULTY = 5;
const FALLBACK_DIFFICULTY = 2;
function isFiniteNumber(value) {
    return typeof value === "number" && Number.isFinite(value);
}
function sanitizeStringArray(value) {
    if (!Array.isArray(value)) {
        return null;
    }
    return value.filter((entry) => typeof entry === "string");
}
function sanitizeNumberArray(value) {
    if (!Array.isArray(value)) {
        return null;
    }
    return value
        .filter((entry) => isFiniteNumber(entry))
        .map((entry) => Math.max(0, Math.floor(entry)));
}
function sanitizeEquippedItem(item) {
    if (!item || typeof item !== "object" || Array.isArray(item)) {
        return null;
    }
    const source = item;
    const sanitized = {};
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
function sanitizeDifficultyByLevel(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        return null;
    }
    const entries = [];
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
function sanitizeProgressionMap(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        return null;
    }
    const entries = [];
    for (const [key, amount] of Object.entries(value)) {
        const level = Number.parseInt(key, 10);
        if (!Number.isFinite(level) || level < MIN_ENCOUNTER_LEVEL || !isFiniteNumber(amount)) {
            continue;
        }
        entries.push([String(level), Math.max(0, Math.floor(amount))]);
    }
    return Object.fromEntries(entries);
}
function sanitizeHighestLevelCompleted(value, fallback) {
    if (!isFiniteNumber(value)) {
        return fallback;
    }
    return Math.max(0, Math.floor(value));
}
function sanitizeDifficulty(value, fallback) {
    if (!isFiniteNumber(value)) {
        return fallback;
    }
    return Math.max(MIN_DIFFICULTY, Math.min(MAX_DIFFICULTY, Math.round(value)));
}
function sanitizeNonNegativeNumber(value, fallback) {
    if (!isFiniteNumber(value)) {
        return fallback;
    }
    return Math.max(0, Math.floor(value));
}
export function createDefaultBrowserShellProfile() {
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
export function createEncounterProgressionInput(profile) {
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
export function applyEncounterResolutionToProfile(profile, resolution) {
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
export function highestUnlockedEncounterLevel(profile) {
    return sanitizeHighestLevelCompleted(profile.highestLevelCompleted, 0) + MIN_ENCOUNTER_LEVEL;
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
    const sanitizedDefaultDifficulty = sanitizeDifficulty(defaultDifficulty, FALLBACK_DIFFICULTY);
    return sanitizeDifficulty(configuredDifficulty, sanitizedDefaultDifficulty);
}
export function sanitizeBrowserShellProfile(value, fallback = createDefaultBrowserShellProfile()) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        return fallback;
    }
    const source = value;
    return {
        name: typeof source.name === "string" ? source.name : fallback.name,
        highestLevelCompleted: sanitizeHighestLevelCompleted(source.highestLevelCompleted, fallback.highestLevelCompleted),
        selectedSpellIds: sanitizeStringArray(source.selectedSpellIds) ?? fallback.selectedSpellIds.slice(),
        lastUsedSpellIds: sanitizeStringArray(source.lastUsedSpellIds) ?? fallback.lastUsedSpellIds.slice(),
        ownedSpellIds: sanitizeStringArray(source.ownedSpellIds) ?? fallback.ownedSpellIds.slice(),
        equippedItems: Array.isArray(source.equippedItems)
            ? source.equippedItems.map(sanitizeEquippedItem).filter((item) => item !== null)
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
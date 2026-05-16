import { createRandomSource } from "./random.js";
const PLAYER_BASE_HEALTH = 1400;
const PLAYER_BASE_ENERGY = 1000;
const PLAYER_BASE_ENERGY_REGEN = 10;
const DEFAULT_CRITICAL_CHANCE = 0.05;
const PLAYER_BASE_COOLDOWN_ADJUSTMENT = 1;
const PLAYER_BASE_HEALING_MULTIPLIER = 1;
const ENEMY_HEALTH_MULTIPLIER = {
    1: 0.6,
    2: 0.8,
    3: 1,
    4: 1.15,
    5: 1.4,
};
const ENEMY_DAMAGE_MODIFIER = {
    1: -0.4,
    2: -0.2,
    3: 0,
    4: 0.125,
    5: 0.25,
};
// These classes are the current canonical raid-wide damage abilities emitted by the native extractor payload.
const RAID_WIDE_ABILITY_CLASSES = new Set(["BaraghastRoar", "Breath", "Earthquake", "RaidDamage", "RaidDamagePulse"]);
function clampDifficulty(value, fallback) {
    const normalized = Math.round(Number.isFinite(value) ? value : fallback);
    return Math.min(5, Math.max(1, normalized));
}
function numericValue(value, context) {
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
function roundIfNumber(value) {
    return value === null ? null : Math.round(value);
}
function buildOwnedSpellIds(registry, encounter, player) {
    if (player.ownedSpellIds && player.ownedSpellIds.length > 0) {
        return Array.from(new Set(player.ownedSpellIds.filter((spellId) => registry.spellsById.has(spellId))));
    }
    const owned = new Set();
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
function buildActiveSpellIds(registry, encounter, ownedSpellIds, player, maximumStandardSpellSlots) {
    const active = [];
    const owned = new Set(ownedSpellIds);
    let sourceOrder = encounter.recommendedSpellIds;
    if (player.selectedSpellIds && player.selectedSpellIds.length > 0) {
        sourceOrder = player.selectedSpellIds;
    }
    else if (player.lastUsedSpellIds && player.lastUsedSpellIds.length > 0) {
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
function buildPlayerSnapshot(registry, encounter, player) {
    const equippedItems = player.equippedItems ?? [];
    const maximumStandardSpellSlots = registry.progression.progressionRules.maximumStandardSpellSlots.base
        + (player.hasMainGameExpansion ? registry.progression.progressionRules.maximumStandardSpellSlots.mainGameExpansionBonus : 0);
    const ownedSpellIds = buildOwnedSpellIds(registry, encounter, player);
    const equippedItemSpellIds = Array.from(new Set(equippedItems
        .map((item) => item.spellId ?? null)
        .filter((spellId) => typeof spellId === "string" && registry.spellsById.has(spellId))));
    const activeSpellIds = buildActiveSpellIds(registry, encounter, ownedSpellIds, player, maximumStandardSpellSlots);
    const activeSpells = buildActiveSpells(registry, activeSpellIds, equippedItemSpellIds);
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
        castTimeAdjustment: Math.max(0.5, 1 - speedBonus / 100),
        // Matches native Player.cooldownAdjustment, which treats positive speed as a multiplicative cooldown penalty.
        cooldownAdjustment: PLAYER_BASE_COOLDOWN_ADJUSTMENT + speedBonus / 100,
        equippedItemSpellIds,
        ownedSpellIds,
        activeSpellIds,
        activeSpells,
    };
}
function buildActiveSpells(registry, activeSpellIds, equippedItemSpellIds) {
    const activeSpellIdSet = new Set(activeSpellIds);
    const equippedItemExclusiveSpellIds = equippedItemSpellIds.filter((spellId) => !activeSpellIdSet.has(spellId));
    const snapshots = [];
    for (const spellId of activeSpellIds) {
        const spell = registry.spellsById.get(spellId);
        if (!spell) {
            continue;
        }
        snapshots.push(createSpellSnapshot(spell, "loadout"));
    }
    for (const spellId of equippedItemExclusiveSpellIds) {
        const spell = registry.spellsById.get(spellId);
        if (!spell) {
            continue;
        }
        snapshots.push(createSpellSnapshot(spell, "equipped_item"));
    }
    return snapshots;
}
function createSpellSnapshot(spell, source) {
    return {
        id: spell.id,
        title: spell.title,
        spellType: spell.spellType ?? null,
        targeting: spell.targeting ?? null,
        targetCount: typeof spell.targetCount === "number" || typeof spell.targetCount === "string" ? spell.targetCount : null,
        healingAmount: numericValue(spell.healingAmount ?? null),
        energyCost: numericValue(spell.energyCost ?? null),
        castTime: numericValue(spell.castTime ?? null),
        cooldown: numericValue(spell.cooldown ?? null),
        source,
        appliedEffectId: spell.appliedEffectId ?? null,
        appliedEffect: spell.appliedEffect ?? null,
    };
}
function buildAllyInstances(registry, encounter, multiplayer, warnings) {
    const snapshots = [];
    const composition = new Map();
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
function createAllySnapshot(ally, index) {
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
function mergeEnemyRecord(baseEnemy, rosterEnemy) {
    return {
        ...(baseEnemy ?? {}),
        ...rosterEnemy,
        className: rosterEnemy.className,
    };
}
function createEnemyAbilitySnapshots(abilities) {
    return (abilities ?? []).map((ability, index) => ({
        id: ability.id ?? `${ability.className}-${index + 1}`,
        title: typeof ability.title === "string" ? ability.title : ability.id ?? ability.className,
        className: ability.className,
        isRaidWide: RAID_WIDE_ABILITY_CLASSES.has(ability.className),
        cooldown: numericValue(ability.cooldown ?? null),
        activationTime: numericValue(ability.activationTime ?? null) ?? 0,
        abilityValue: numericValue(ability.abilityValue ?? null),
        targetCount: numericValue(ability.numTargets ?? null),
        appliedEffectId: ability.appliedEffectId ?? null,
        appliedEffect: ability.appliedEffect ?? null,
    }));
}
function createEnemySnapshot(enemy, index, difficulty, primaryBossBaseHealth, warnings) {
    const baseHealth = numericValue(enemy.health, { "boss.health": primaryBossBaseHealth });
    const baseDamage = numericValue(enemy.damage);
    const healthMultiplier = ENEMY_HEALTH_MULTIPLIER[difficulty];
    const damageModifier = ENEMY_DAMAGE_MODIFIER[difficulty];
    const maximumHealth = baseHealth === null ? null : Math.round(baseHealth * healthMultiplier);
    const damagePerAttack = baseDamage === null ? null : Math.round(baseDamage * (1 + damageModifier));
    const attackFrequency = numericValue(enemy.attackFrequency ?? enemy.frequency ?? null);
    const targets = numericValue(enemy.targets ?? null);
    const threatPriority = numericValue(enemy.threatPriority ?? null);
    const autoAttackFailureChance = numericValue(enemy.autoAttackAdjustments?.failureChance ?? null) ?? 0;
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
        autoAttackFailureChance,
        abilities: createEnemyAbilitySnapshots(enemy.abilities),
        source: typeof enemy.source === "string" ? enemy.source : "registry",
    };
}
function buildEnemyInstances(registry, encounter, difficulty, warnings) {
    const roster = encounter.enemyRoster.map((enemy) => mergeEnemyRecord(registry.enemiesByClassName.get(enemy.className), enemy));
    const primaryBossBaseHealth = numericValue(roster[0]?.health ?? null);
    return roster.map((enemy, index) => createEnemySnapshot(enemy, index + 1, difficulty, primaryBossBaseHealth, warnings));
}
export function createEncounterBootstrap(registry, options) {
    const encounter = registry.encountersByLevel.get(options.level);
    if (!encounter) {
        throw new Error(`Unknown encounter level '${options.level}'.`);
    }
    const warnings = [];
    const random = createRandomSource(options.seed);
    const difficulty = clampDifficulty(options.difficulty ?? registry.progression.progressionRules.difficultyDefaultValue, registry.progression.progressionRules.difficultyDefaultValue);
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
//# sourceMappingURL=bootstrap.js.map
function mapByKey(items, getKey) {
    const result = new Map();
    for (const item of items) {
        result.set(getKey(item), item);
    }
    return result;
}
export function createGameRegistry(input) {
    return {
        encounters: input.encounters.slice().sort((left, right) => left.level - right.level),
        encountersByLevel: mapByKey(input.encounters, (encounter) => encounter.level),
        alliesById: mapByKey(input.allies, (ally) => ally.id),
        alliesByNormalizedId: mapByKey(input.allies, (ally) => ally.id.toLowerCase()),
        enemiesByClassName: mapByKey(input.enemies, (enemy) => enemy.className),
        spellsById: mapByKey(input.spells, (spell) => spell.id),
        shopItemsBySpellId: mapByKey(input.shop.items, (item) => item.spellId),
        progression: input.progression,
    };
}
//# sourceMappingURL=registry.js.map
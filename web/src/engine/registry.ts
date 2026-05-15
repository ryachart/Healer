import type {
  AllyRecord,
  EncounterRecord,
  EnemyRecord,
  ProgressionSchemaPayload,
  RegistryInput,
  ShopItemRecord,
  SpellRecord,
} from "./types.js";

function mapByKey<T>(items: T[], getKey: (item: T) => string | number): Map<string | number, T> {
  const result = new Map<string | number, T>();
  for (const item of items) {
    result.set(getKey(item), item);
  }
  return result;
}

export interface GameRegistry {
  encounters: EncounterRecord[];
  encountersByLevel: Map<number, EncounterRecord>;
  alliesById: Map<string, AllyRecord>;
  alliesByNormalizedId: Map<string, AllyRecord>;
  enemiesByClassName: Map<string, EnemyRecord>;
  spellsById: Map<string, SpellRecord>;
  shopItemsBySpellId: Map<string, ShopItemRecord>;
  progression: ProgressionSchemaPayload;
}

export function createGameRegistry(input: RegistryInput): GameRegistry {
  return {
    encounters: input.encounters.slice().sort((left, right) => left.level - right.level),
    encountersByLevel: mapByKey(input.encounters, (encounter) => encounter.level) as Map<number, EncounterRecord>,
    alliesById: mapByKey(input.allies, (ally) => ally.id) as Map<string, AllyRecord>,
    alliesByNormalizedId: mapByKey(input.allies, (ally) => ally.id.toLowerCase()) as Map<string, AllyRecord>,
    enemiesByClassName: mapByKey(input.enemies, (enemy) => enemy.className) as Map<string, EnemyRecord>,
    spellsById: mapByKey(input.spells, (spell) => spell.id) as Map<string, SpellRecord>,
    shopItemsBySpellId: mapByKey(input.shop.items, (item) => item.spellId) as Map<string, ShopItemRecord>,
    progression: input.progression,
  };
}

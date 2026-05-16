import type { AllyRecord, EquipmentSchemaPayload, EncounterRecord, EnemyRecord, LootRulesPayload, ProgressionSchemaPayload, RegistryInput, ShopItemRecord, SpellRecord } from "./types.js";
export interface GameRegistry {
    encounters: EncounterRecord[];
    encountersByLevel: Map<number, EncounterRecord>;
    alliesById: Map<string, AllyRecord>;
    alliesByNormalizedId: Map<string, AllyRecord>;
    enemiesByClassName: Map<string, EnemyRecord>;
    spellsById: Map<string, SpellRecord>;
    shopItemsBySpellId: Map<string, ShopItemRecord>;
    lootRules: LootRulesPayload;
    equipmentSchema: EquipmentSchemaPayload;
    progression: ProgressionSchemaPayload;
}
export declare function createGameRegistry(input: RegistryInput): GameRegistry;

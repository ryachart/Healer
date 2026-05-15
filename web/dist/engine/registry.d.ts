import type { AllyRecord, EncounterRecord, EnemyRecord, ProgressionSchemaPayload, RegistryInput, ShopItemRecord, SpellRecord } from "./types.js";
export interface GameRegistry {
    encounters: EncounterRecord[];
    encountersByLevel: Map<number, EncounterRecord>;
    alliesById: Map<string, AllyRecord>;
    enemiesByClassName: Map<string, EnemyRecord>;
    spellsById: Map<string, SpellRecord>;
    shopItemsBySpellId: Map<string, ShopItemRecord>;
    progression: ProgressionSchemaPayload;
}
export declare function createGameRegistry(input: RegistryInput): GameRegistry;

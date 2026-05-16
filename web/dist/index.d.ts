export { createEncounterBootstrap } from "./engine/bootstrap.js";
export { advanceCombatState, beginPlayerCast, createCombatState } from "./engine/combat.js";
export { resolveEncounterOutcome } from "./engine/resolution.js";
export { createGameRegistry } from "./engine/registry.js";
export { applySelectedSpellIds, applyEncounterResolutionToProfile, createEncounterProgressionInput, createDefaultBrowserShellProfile, createPrebattleViewModel, createWorldMapViewModel, difficultyForEncounter, highestUnlockedEncounterLevel, maximumStandardSpellSlots, normalizeSelectedSpellIds, } from "./browser-shell.js";
export type { CombatStateSnapshot, CombatUpdateResult, EncounterProgressionInput, EncounterResolutionSnapshot, EncounterBootstrapOptions, EncounterBootstrapSnapshot, EquipmentSchemaPayload, LootRulesPayload, PlayerCastRequest, ProgressionSchemaPayload, RegistryInput, } from "./engine/types.js";
export type { BrowserShellProfile, PrebattleViewModel, WorldMapEncounterViewModel, } from "./browser-shell.js";

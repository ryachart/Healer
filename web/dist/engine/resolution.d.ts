import type { GameRegistry } from "./registry.js";
import type { CombatStateSnapshot, EncounterProgressionInput, EncounterResolutionSnapshot } from "./types.js";
export declare function resolveEncounterOutcome(registry: GameRegistry, state: CombatStateSnapshot, progressionInput?: EncounterProgressionInput): EncounterResolutionSnapshot;

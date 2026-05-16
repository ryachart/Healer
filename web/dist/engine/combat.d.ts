import type { CombatStateSnapshot, CombatUpdateResult, EncounterBootstrapSnapshot, PlayerCastRequest } from "./types.js";
export declare function createCombatState(snapshot: EncounterBootstrapSnapshot): CombatStateSnapshot;
export declare function beginPlayerCast(state: CombatStateSnapshot, request: PlayerCastRequest): CombatUpdateResult;
export declare function advanceCombatState(state: CombatStateSnapshot, elapsedSeconds: number): CombatUpdateResult;

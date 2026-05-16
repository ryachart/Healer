import type { GameRegistry } from "./engine/registry.js";
import type { EncounterBootstrapSnapshot, EquippedItemInput, PlayerProfileInput } from "./engine/types.js";
export interface BrowserShellProfile {
    name: string;
    highestLevelCompleted: number;
    selectedSpellIds: string[];
    lastUsedSpellIds: string[];
    ownedSpellIds: string[];
    equippedItems: EquippedItemInput[];
    hasMainGameExpansion: boolean;
    difficultyByLevel: Record<number, number>;
}
export interface WorldMapEncounterViewModel {
    level: number;
    title: string;
    bossKey: string;
    backgroundKey: string;
    rewardGold: number;
    recommendedSpellIds: string[];
    unlocked: boolean;
}
export interface PrebattleViewModel {
    bootstrap: EncounterBootstrapSnapshot;
    selectedSpells: Array<{
        id: string;
        title: string;
        spellType: string | null;
    }>;
    allySummary: Array<{
        title: string;
        count: number;
    }>;
}
export declare function createDefaultBrowserShellProfile(): BrowserShellProfile;
export declare function createPlayerProfileInput(profile: BrowserShellProfile): PlayerProfileInput;
export declare function highestUnlockedEncounterLevel(profile: BrowserShellProfile): number;
export declare function createWorldMapViewModel(registry: GameRegistry, profile: BrowserShellProfile): WorldMapEncounterViewModel[];
export declare function difficultyForEncounter(registry: GameRegistry, profile: BrowserShellProfile, level: number): number;
export declare function createPrebattleViewModel(registry: GameRegistry, profile: BrowserShellProfile, level: number): PrebattleViewModel;

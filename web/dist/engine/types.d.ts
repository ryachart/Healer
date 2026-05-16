export interface NumericExpression {
    expression: string;
    value: number | null;
}
export interface AllyRecord {
    id: string;
    title: string;
    info: string | null;
    health: NumericExpression;
    damageDealt: NumericExpression;
    damageFrequency: NumericExpression;
    positioning: string;
    dodgeChance: NumericExpression | null;
    criticalChance: NumericExpression | null;
}
export interface EnemyRecord {
    id?: string;
    className: string;
    title?: string;
    spriteName?: string;
    health?: NumericExpression;
    damage?: NumericExpression;
    targets?: NumericExpression;
    attackFrequency?: NumericExpression;
    frequency?: NumericExpression;
    choosesMainTarget?: boolean;
    threatPriority?: NumericExpression;
    [key: string]: unknown;
}
export interface EncounterRecord {
    level: number;
    title: string;
    info: string;
    bossKey: string;
    backgroundKey: string;
    battleTrackTitle: string;
    baseRewardGold: number;
    recommendedSpellIds: string[];
    requiredSpellIds?: string[];
    allyComposition: Record<string, number>;
    multiplayerAdjustments?: Record<string, number>;
    enemyRoster: EnemyRecord[];
    lootRuleId?: string;
}
export interface SpellRecord {
    id: string;
    title: string;
    energyCost?: NumericExpression | null;
    castTime?: NumericExpression | null;
    cooldown?: NumericExpression | null;
    targeting?: string;
    targetCount?: number | string;
    spellType?: string;
    itemSpriteName?: string | null;
}
export interface ShopItemRecord {
    spellId: string;
    title: string;
    goldCost: number;
    category: string;
}
export interface ShopPayload {
    items: ShopItemRecord[];
    unlockThresholdsByCategory: Record<string, number>;
}
export interface ProgressionSchemaPayload {
    progressionRules: {
        difficultyDefaultValue: number;
        maximumStandardSpellSlots: {
            base: number;
            mainGameExpansionBonus: number;
        };
    };
}
export interface RegistryInput {
    encounters: EncounterRecord[];
    allies: AllyRecord[];
    enemies: EnemyRecord[];
    spells: SpellRecord[];
    shop: ShopPayload;
    progression: ProgressionSchemaPayload;
}
export interface EquippedItemInput {
    id?: string;
    health?: number;
    healing?: number;
    regen?: number;
    crit?: number;
    speed?: number;
    spellId?: string | null;
}
export interface PlayerProfileInput {
    name?: string;
    ownedSpellIds?: string[];
    lastUsedSpellIds?: string[];
    selectedSpellIds?: string[];
    equippedItems?: EquippedItemInput[];
    hasMainGameExpansion?: boolean;
}
export interface EncounterBootstrapOptions {
    level: number;
    difficulty?: number;
    multiplayer?: boolean;
    seed?: number | string;
    player?: PlayerProfileInput;
}
export interface ReplayDescriptor {
    seed: number;
    version: 1;
}
export interface PlayerSnapshot {
    id: string;
    title: string;
    name: string;
    health: number;
    maximumHealth: number;
    energy: number;
    maximumEnergy: number;
    energyRegenPerSecond: number;
    healingDoneMultiplier: number;
    spellCriticalChance: number;
    castTimeAdjustment: number;
    cooldownAdjustment: number;
    equippedItemSpellIds: string[];
    ownedSpellIds: string[];
    activeSpellIds: string[];
    activeSpells: PlayerSpellSnapshot[];
}
export interface PlayerSpellSnapshot {
    id: string;
    title: string;
    spellType: string | null;
    targeting: string | null;
    targetCount: number | string | null;
    energyCost: number | null;
    castTime: number | null;
    cooldown: number | null;
    source: "loadout" | "equipped_item";
}
export interface AllySnapshot {
    id: string;
    archetypeId: string;
    title: string;
    info: string | null;
    positioning: string;
    health: number;
    maximumHealth: number;
    damageDealt: number;
    damageFrequency: number;
    dodgeChance: number;
    criticalChance: number;
}
export interface EnemySnapshot {
    id: string;
    className: string;
    title: string;
    spriteName: string | null;
    health: number | null;
    maximumHealth: number | null;
    baseHealth: number | null;
    damagePerAttack: number | null;
    baseDamage: number | null;
    damageDoneMultiplier: number;
    attackFrequency: number | null;
    targets: number | null;
    choosesMainTarget: boolean;
    threatPriority: number | null;
    source: string;
}
export interface RewardPreview {
    gold: number;
    lootRuleId: string | null;
}
export interface EncounterBootstrapSnapshot {
    schemaVersion: 1;
    replay: ReplayDescriptor;
    encounter: {
        level: number;
        title: string;
        info: string;
        bossKey: string;
        difficulty: number;
        multiplayer: boolean;
        backgroundKey: string;
        battleTrackTitle: string;
        recommendedSpellIds: string[];
        requiredSpellIds: string[];
    };
    player: PlayerSnapshot;
    allies: AllySnapshot[];
    enemies: EnemySnapshot[];
    rewards: RewardPreview;
    warnings: string[];
}
export interface CombatPlayerSpellSnapshot extends PlayerSpellSnapshot {
    baseCastTime: number | null;
    baseCooldown: number | null;
    energyCost: number | null;
    castTime: number | null;
    cooldown: number | null;
    cooldownRemaining: number;
}
export interface PlayerCastSnapshot {
    spellId: string;
    startedAt: number;
    totalCastTime: number;
    remainingCastTime: number;
    committedEnergyCost: number | null;
    targetIds: string[];
}
export interface CombatPlayerSnapshot {
    id: string;
    title: string;
    name: string;
    health: number;
    maximumHealth: number;
    energy: number;
    maximumEnergy: number;
    energyRegenPerSecond: number;
    castTimeAdjustment: number;
    cooldownAdjustment: number;
    activeSpells: CombatPlayerSpellSnapshot[];
    casting: PlayerCastSnapshot | null;
}
export interface CombatStateSnapshot {
    schemaVersion: 1;
    replay: ReplayDescriptor;
    encounter: EncounterBootstrapSnapshot["encounter"];
    time: number;
    player: CombatPlayerSnapshot;
    allies: AllySnapshot[];
    enemies: EnemySnapshot[];
    warnings: string[];
}
export interface PlayerCastRequest {
    spellId: string;
    targetIds?: string[];
}
export interface CombatEvent {
    type: "player_cast_started" | "player_cast_completed" | "player_cast_rejected";
    at: number;
    spellId: string;
    targetIds: string[];
    reason?: "already_casting" | "not_enough_energy" | "spell_on_cooldown" | "unknown_spell";
}
export interface CombatUpdateResult {
    state: CombatStateSnapshot;
    events: CombatEvent[];
}

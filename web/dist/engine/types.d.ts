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
    healingAmount?: NumericExpression | null;
    energyCost?: NumericExpression | null;
    castTime?: NumericExpression | null;
    cooldown?: NumericExpression | null;
    targeting?: string;
    targetCount?: number | string;
    spellType?: string;
    itemSpriteName?: string | null;
    appliedEffectId?: string | null;
    appliedEffect?: EffectRecord | null;
}
export interface EffectRecord {
    id: string;
    title: string;
    className: string;
    declaredType?: string;
    effectType?: string;
    duration?: NumericExpression | null;
    numOfTicks?: NumericExpression | null;
    value?: NumericExpression | null;
    valuePerTick?: NumericExpression | null;
    amountPerReaction?: NumericExpression | null;
    effectCooldown?: NumericExpression | null;
    increasePerTick?: NumericExpression | null;
    damageTakenMultiplierAdjustment?: NumericExpression | null;
    healingDoneMultiplierAdjustment?: NumericExpression | null;
    castTimeAdjustment?: NumericExpression | null;
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
    healingAmount: number | null;
    energyCost: number | null;
    castTime: number | null;
    cooldown: number | null;
    source: "loadout" | "equipped_item";
    appliedEffectId: string | null;
    appliedEffect: EffectRecord | null;
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
    healingDoneMultiplier: number;
    castTimeAdjustment: number;
    cooldownAdjustment: number;
    activeSpells: CombatPlayerSpellSnapshot[];
    casting: PlayerCastSnapshot | null;
}
export interface CombatEffectSnapshot {
    effectId: string;
    title: string;
    className: string;
    effectType: string | null;
    targetId: string;
    sourceSpellId: string;
    totalDuration: number;
    remainingDuration: number;
    tickInterval: number | null;
    remainingUntilNextTick: number | null;
    totalTicks: number | null;
    ticksApplied: number;
    value: number | null;
    currentValuePerTick: number | null;
    increasePerTick: number;
}
export interface CombatStateSnapshot {
    schemaVersion: 1;
    replay: ReplayDescriptor;
    encounter: EncounterBootstrapSnapshot["encounter"];
    time: number;
    player: CombatPlayerSnapshot;
    allies: AllySnapshot[];
    enemies: EnemySnapshot[];
    effects: CombatEffectSnapshot[];
    warnings: string[];
}
export interface PlayerCastRequest {
    spellId: string;
    targetIds?: string[];
}
export interface CombatEvent {
    type: "player_cast_started" | "player_cast_completed" | "player_cast_rejected" | "effect_applied" | "effect_expired" | "health_changed";
    at: number;
    spellId?: string;
    targetIds?: string[];
    targetId?: string;
    effectId?: string;
    amount?: number;
    reason?: "already_casting" | "not_enough_energy" | "spell_on_cooldown" | "unknown_spell" | "invalid_target";
}
export interface CombatUpdateResult {
    state: CombatStateSnapshot;
    events: CombatEvent[];
}

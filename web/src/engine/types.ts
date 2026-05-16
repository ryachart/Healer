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
  autoAttackAdjustments?: {
    failureChance?: NumericExpression | null;
  };
  abilities?: AbilityRecord[];
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

export interface AbilityRecord {
  id: string;
  title?: string;
  className: string;
  cooldown?: NumericExpression | null;
  activationTime?: NumericExpression | null;
  abilityValue?: NumericExpression | null;
  numTargets?: NumericExpression | null;
  appliedEffectId?: string | null;
  appliedEffect?: EffectRecord | null;
  [key: string]: unknown;
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

export interface LootRuleItemRecord {
  id: string;
  name: string;
  slot: string;
  rarity: string;
  quality: number;
  health: number;
  healing: number;
  regen: number;
  speed: number;
  crit: number;
  specialKey: string | null;
  dropLevels: number[];
}

export interface LootRulesPayload {
  rarityRollWeightsByDifficulty: Record<string, number[]>;
  rarityOrder: string[];
  qualityRules: {
    evaluatedLevelTable: Array<{
      level: number;
      qualityByDifficulty: Record<string, number | null>;
    }>;
    expressionRules: Array<{
      condition: string;
      expression: string;
    }>;
  };
  selectionBehavior: {
    lootTableImplementation: string;
    selectionSource: string;
    zeroWeightEntriesNeverDrop: string;
    fallbackRules: Record<string, string>;
  };
  encounterSpecificDrops: {
    epic: LootRuleItemRecord[];
    legendary: LootRuleItemRecord[];
  };
  lootTableSource: {
    itemsField: boolean;
    weightsField: boolean;
  };
}

export interface EquipmentSchemaPayload {
  proceduralGenerationRules: {
    namePools: {
      prefixesBySlot: Record<string, string[]>;
      suffixes: string[];
    };
    salePrice: {
      expression: string;
    };
    slotModifiers: Record<string, number>;
    weaponSpecials: {
      candidateSpecialKeys: string[];
      minimumQualityForSpecialKey: number;
    };
  };
  rarities: Array<{
    enum: string;
    id: string;
    value: number;
  }>;
  slotTypes: Array<{
    enum: string;
    id: string;
    value: number;
  }>;
  statTypes: Array<{
    enum: string;
    id: string;
    value: number;
    atom: number;
  }>;
}

export interface ProgressionSchemaPayload {
  contentGate: {
    endFreeEncounterLevel: number;
    endFreeUpsellText: string;
    mainGameContentKey: string;
  };
  progressionRules: {
    allyUpgradeCost: {
      base: number;
      maximumHealthUpgrades: number;
      step: number;
    };
    difficultyDefaultValue: number;
    difficultyTrackedLevelSlots: number;
    maximumInventorySize: number;
    maximumStandardSpellSlots: {
      base: number;
      mainGameExpansionBonus: number;
    };
    multiplayerUnlockAtHighestLevelCompleted: number;
    talentTierUnlocks: Array<{
      tier: number;
      requiredRating: number;
    }>;
    totalRatingStartsAtLevel: number;
    tutorialLevelHasNoRating: boolean;
  };
}

export interface RegistryInput {
  encounters: EncounterRecord[];
  allies: AllyRecord[];
  enemies: EnemyRecord[];
  spells: SpellRecord[];
  shop: ShopPayload;
  lootRules: LootRulesPayload;
  equipmentSchema: EquipmentSchemaPayload;
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
  /** Exported for future native-parity miss handling; the current deterministic combat runtime does not consume this yet. */
  autoAttackFailureChance: number;
  abilities: EnemyAbilitySnapshot[];
  source: string;
}

export interface EnemyAbilitySnapshot {
  id: string;
  title: string;
  className: string;
  isRaidWide: boolean;
  cooldown: number | null;
  activationTime: number;
  abilityValue: number | null;
  targetCount: number | null;
  appliedEffectId: string | null;
  appliedEffect: EffectRecord | null;
}

export interface RewardPreview {
  gold: number;
  lootRuleId: string | null;
}

export interface CombatMetricsSnapshot {
  scoreTally: number;
  healingDone: number;
  overhealingDone: number;
  damageTaken: number;
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
  /** Explicit discriminator for friendly-combatant union narrowing in the runtime. */
  combatantType: "player";
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

export interface CombatAllySnapshot extends AllySnapshot {
  combatantType: "ally";
  attackTimer: number;
}

export interface CombatEnemyAbilitySnapshot extends EnemyAbilitySnapshot {
  remainingCooldown: number;
}

export interface EnemyCastSnapshot {
  abilityId: string;
  startedAt: number;
  totalCastTime: number;
  remainingCastTime: number;
  targetIds: string[];
}

export interface CombatEnemySnapshot extends Omit<EnemySnapshot, "abilities"> {
  attackTimer: number;
  abilities: CombatEnemyAbilitySnapshot[];
  casting: EnemyCastSnapshot | null;
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
  allies: CombatAllySnapshot[];
  enemies: CombatEnemySnapshot[];
  effects: CombatEffectSnapshot[];
  metrics: CombatMetricsSnapshot;
  result: CombatResultSnapshot;
  warnings: string[];
}

export interface CombatResultSnapshot {
  status: "in_progress" | "victory" | "defeat";
  reason: "all_enemies_defeated" | "all_allies_defeated" | "player_defeated" | null;
  finishedAt: number | null;
}

export interface PlayerCastRequest {
  spellId: string;
  targetIds?: string[];
}

export interface CombatEvent {
  type:
    | "player_cast_started"
    | "player_cast_completed"
    | "player_cast_rejected"
    | "effect_applied"
    | "effect_expired"
    | "health_changed"
    | "ally_attack"
    | "enemy_auto_attack"
    | "enemy_ability_started"
    | "enemy_ability_completed"
    | "combatant_defeated"
    | "encounter_completed";
  at: number;
  spellId?: string;
  abilityId?: string;
  actorId?: string;
  targetIds?: string[];
  targetId?: string;
  effectId?: string;
  amount?: number;
  reason?:
    | "already_casting"
    | "not_enough_energy"
    | "spell_on_cooldown"
    | "unknown_spell"
    | "invalid_target"
    | "encounter_resolved";
  result?: CombatResultSnapshot["status"];
  resultReason?: CombatResultSnapshot["reason"];
}

export interface CombatUpdateResult {
  state: CombatStateSnapshot;
  events: CombatEvent[];
}

export interface EncounterProgressionInput {
  gold?: number;
  highestLevelCompleted?: number;
  ratingsByLevel?: Record<string, number>;
  scoresByLevel?: Record<string, number>;
  failureCountsByLevel?: Record<string, number>;
  inventoryCount?: number;
  totalItemsEarned?: number;
}

export interface EncounterLootSnapshot {
  id: string | null;
  name: string;
  source: "encounter_specific" | "procedural";
  rarity: string;
  quality: number;
  slot: string;
  health: number;
  healing: number;
  regen: number;
  crit: number;
  speed: number;
  specialKey: string | null;
  salePrice: number;
}

export interface EncounterResolutionSnapshot {
  schemaVersion: 1;
  encounter: {
    level: number;
    title: string;
    difficulty: number;
    multiplayer: boolean;
  };
  result: CombatResultSnapshot;
  metrics: CombatMetricsSnapshot & {
    duration: number;
    score: number;
  };
  rewards: {
    goldAwarded: number;
    previousBestScore: number;
    newBestScore: boolean;
    previousRating: number;
    updatedRating: number;
    ratingImproved: boolean;
    lootEligible: boolean;
    lootBlockedReason: "not_victory" | "tutorial_level" | "inventory_full" | null;
    loot: EncounterLootSnapshot | null;
  };
  progression: {
    gold: number;
    highestLevelCompleted: number;
    ratingsByLevel: Record<string, number>;
    scoresByLevel: Record<string, number>;
    failureCountsByLevel: Record<string, number>;
    inventoryCount: number;
    totalItemsEarned: number;
    totalRating: number;
    unlockedTalentTiers: number[];
    multiplayerUnlocked: boolean;
    talentsUnlocked: boolean;
  };
  warnings: string[];
}

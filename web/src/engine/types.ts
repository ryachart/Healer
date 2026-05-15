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
  cooldownAdjustment: number;
  equippedItemSpellIds: string[];
  ownedSpellIds: string[];
  activeSpellIds: string[];
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

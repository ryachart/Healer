//
//  Effect.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Boss;
@class Raid;
@class Player;
@class HealableTarget;
@class Agent;
@class Ability;
@class Spell;

typedef enum {
	EffectTypeNeutral,
	EffectTypePositive,
	EffectTypeNegative, 
    EffectTypePositiveInvisible,
    EffectTypeNegativeInvisible, 
    EffectTypeDivinity
} EffectType;

typedef enum {
    AilmentNone,
    AilmentTrauma,
    AilmentPoison,
    AilmentCurse
} AilmentType;

@interface Effect : NSObject {
	NSTimeInterval duration;
	EffectType effectType;
	BOOL isExpired;
}
@property (nonatomic, retain) NSString* spriteName;
@property (nonatomic, retain) NSString* title; //Should be unique
@property (nonatomic, readwrite) AilmentType ailmentType;
@property (nonatomic, assign) Agent *owner;
@property NSTimeInterval duration;
@property (readwrite) NSInteger maxStacks;
@property (readwrite) float timeApplied;
@property (nonatomic, retain) HealableTarget *target;
@property (readonly) EffectType effectType;
@property (readwrite) float failureChance;
@property (readonly) BOOL shouldFail;
@property (readwrite) float healingDoneMultiplierAdjustment;
@property (readwrite) float damageDoneMultiplierAdjustment;
@property (nonatomic, readwrite) float castTimeAdjustment;
@property (nonatomic, readwrite) float spellCostAdjustment;
@property (readwrite) BOOL isIndependent; //Max Stacks doesnt apply and other effects are never the same as this effect

- (void)reset;
- (BOOL)isKindOfEffect:(Effect*)effect;
//Weird fucking hacky solution for figuring out the owner in network play
@property (nonatomic, retain) NSString* ownerNetworkID;
@property (nonatomic, readwrite) BOOL needsOwnershipResolution;


@property BOOL isExpired;
- (id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type;

- (void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta;
- (void)expire;
- (void)effectWillBeDispelled:(Raid*)raid player:(Player*)player;
- (void)targetDidCastSpell:(Spell*)spell;

//Multiplayer
-(NSString*)asNetworkMessage;
-(id)initWithNetworkMessage:(NSString*)message;
@end

@protocol HealthAdjustmentModifier

@required
-(void)willChangeHealthFrom:(NSInteger*)currentHealth toNewHealth:(NSInteger*)newHealth;
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth;

@end

#pragma mark - Divinity Effects

@interface DivinityEffect : Effect
@property (nonatomic, retain) NSString* divinityKey;
- (id)initWithDivinityKey:(NSString*)divinityKey;
@end

#pragma mark - Shipping Spell Effects
@interface RepeatedHealthEffect : Effect
{
	float lastTick;
}
@property (readwrite) NSInteger numHasTicked;
@property (readwrite) NSInteger numOfTicks;
@property (readwrite) NSInteger valuePerTick;
-(void)tick;
@end

@interface SwirlingLightEffect : RepeatedHealthEffect
@end

@interface ShieldEffect : Effect <HealthAdjustmentModifier>
@property (readwrite) NSInteger amountToShield;
@end

@interface HealingDoneAdjustmentEffect : Effect <HealthAdjustmentModifier>
@property (readwrite) float percentageHealingReceived;
@end

@interface ReactiveHealEffect : Effect <HealthAdjustmentModifier>
@property (readwrite) float triggerCooldown;
@property (nonatomic, readwrite) float effectCooldown;
@property NSInteger amountPerReaction;
@end

@interface DelayedHealthEffect : Effect
@property NSInteger value;
@property (nonatomic, retain) Effect *appliedEffect;
@end

@interface TouchOfHopeEffect : RepeatedHealthEffect
@end

#pragma mark - Shipping Boss Effects
@interface TrulzarPoison : RepeatedHealthEffect
@end

@interface CouncilPoison : RepeatedHealthEffect <HealthAdjustmentModifier>
@end

@interface CouncilPoisonball : DelayedHealthEffect 
@end

@interface ExpiresAtFullHealthRHE: RepeatedHealthEffect
@end

@interface ImpLightningBottle : DelayedHealthEffect
@end

@interface RothPoison : RepeatedHealthEffect
@property (nonatomic, readwrite) NSInteger dispelDamageValue;
@property (nonatomic, readwrite) NSInteger baseValue;
@end

@interface DarkCloudEffect : RepeatedHealthEffect <HealthAdjustmentModifier>
@property (nonatomic, readwrite) NSInteger baseValue;
@end

@interface BulwarkEffect : ShieldEffect
+(id)defaultEffect;
@end

@interface DamageTakenIncreasedEffect : Effect <HealthAdjustmentModifier>
@property (nonatomic, readwrite) float percentage;
@end

@interface DamageTakenDecreasedEffect : Effect <HealthAdjustmentModifier>
@property (nonatomic, readwrite) float percentage;
@end

@interface ExecutionEffect : DelayedHealthEffect
@property (nonatomic, readwrite) float effectivePercentage;
@end

@interface IntensifyingRepeatedHealthEffect : RepeatedHealthEffect
@property (nonatomic, readwrite) float increasePerTick;
@end

@interface WanderingSpiritEffect : RepeatedHealthEffect 
@property (nonatomic, assign) Raid *raid;
@end

@interface BreakOffEffect : RepeatedHealthEffect
@property (nonatomic, retain) Ability *reenableAbility;
@end

@interface DebilitateEffect : ExpiresAtFullHealthRHE 
@end

@interface InvertedHealingEffect : Effect <HealthAdjustmentModifier>
@property (nonatomic, readwrite) float percentageConvertedToDamage;
@end

@interface SoulBurnEffect : RepeatedHealthEffect <HealthAdjustmentModifier>
@property (nonatomic, readwrite) NSInteger energyToBurn;
@property (nonatomic, readwrite) BOOL needsToBurnEnergy;
@end

@interface GripEffect : RepeatedHealthEffect <HealthAdjustmentModifier>
@end

@interface FallenDownEffect : Effect
/* Reduces all damage dealt until the targets health passes the getUpThreshold */
@property (nonatomic, readwrite) float getUpThreshold; //Defaults to .6
+ (id)defaultEffect;
@end

@interface EnergyAdjustmentPerCastEffect : Effect
@property (nonatomic, readwrite) NSInteger energyChangePerCast;
@end

@interface EngulfingSlimeEffect : RepeatedHealthEffect <HealthAdjustmentModifier>
+ (id)defaultEffect;
@end

@interface BlessedArmorEffect : DelayedHealthEffect <HealthAdjustmentModifier>
@end

@protocol RedemptionDelegate <NSObject>
- (void)redemptionDidTriggerOnTarget:(HealableTarget*)target;
- (BOOL)canRedemptionTrigger;
@end

@interface RedemptionEffect : Effect <HealthAdjustmentModifier>
@property (nonatomic, assign) id <RedemptionDelegate> redemptionDelegate;
@end

@interface AvatarEffect : Effect
@property (nonatomic, readwrite) NSTimeInterval raidWidePulseCooldown;
@property (nonatomic, readwrite) NSTimeInterval healingSpellCooldown;
@end

#pragma mark - DEPRECATED EFFECTS
@interface BigFireball : Effect {
	NSInteger lastPosition;
}
@property NSInteger lastPosition;
@end

/////SHAMAN EFFECTS/////
@interface RoarOfLifeEffect : RepeatedHealthEffect 
+(id)defaultEffect;
@end

@interface WoundWeavingEffect : RepeatedHealthEffect
+(id)defaultEffect;
@end

@interface SurgingGrowthEffect: RepeatedHealthEffect
+(id)defaultEffect;
@end

@interface FieryAdrenalineEffect : RepeatedHealthEffect <HealthAdjustmentModifier>
+(id)defaultEffect;
@end

@interface TwoWindsEffect : RepeatedHealthEffect
+(id)defaultEffect;
@end

@interface SymbioticConnectionEffect : RepeatedHealthEffect
+(id)defaultEffect;
@end

@interface UnleashedNatureEffect: RepeatedHealthEffect
+(id)defaultEffect;
@end

/////SEER EFFECTS/////
@interface ShiningAegisEffect : ShieldEffect
+(id)defaultEffect;
@end



@interface EtherealArmorEffect : Effect <HealthAdjustmentModifier>
+(id)defaultEffect;
@end
/////RITUALIST EFFECTS/////
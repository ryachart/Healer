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

typedef enum {
	EffectTypeNeutral,
	EffectTypePositive,
	EffectTypeNegative, 
    EffectTypePositiveInvisible,
    EffectTypeNegativeInvisible
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
	HealableTarget *target;
	
	NSMutableArray *audioTitles;
}
@property (nonatomic, retain) NSString* spriteName;
@property (nonatomic, retain) NSString* title; //Should be unique
@property (nonatomic, readwrite) AilmentType ailmentType;
@property (nonatomic, assign) Agent *owner;
@property NSTimeInterval duration;
@property (readwrite) NSInteger maxStacks;
@property (readwrite) float timeApplied;
@property (readwrite, retain) HealableTarget *target;
@property (readonly) EffectType effectType;

-(void)reset;

//Weird fucking hacky solution for figuring out the owner in network play
@property (nonatomic, retain) NSString* ownerNetworkID;
@property (nonatomic, readwrite) BOOL needsOwnershipResolution;


@property BOOL isExpired;
-(id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type;

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta;
-(void)expire;
-(void)effectWillBeDispelled:(Raid*)raid player:(Player*)player;

//Multiplayer
-(NSString*)asNetworkMessage;
-(id)initWithNetworkMessage:(NSString*)message;
@end

@protocol HealthAdjustmentModifier

@required
-(void)willChangeHealthFrom:(NSInteger*)currentHealth toNewHealth:(NSInteger*)newHealth;
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth;

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


@interface ReactiveHealEffect : Effect <HealthAdjustmentModifier>
@property (readwrite) float triggerCooldown;
@property (nonatomic, readwrite) float effectCooldown;
@property NSInteger amountPerReaction;
@end

@interface DelayedHealthEffect : Effect
@property NSInteger value;
@property (nonatomic, retain) Effect *appliedEffect;
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
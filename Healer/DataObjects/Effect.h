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

typedef enum {
	EffectTypeNeutral,
	EffectTypePositive,
	EffectTypeNegative
} EffectType;

@interface Effect : NSObject {
	NSTimeInterval duration;
	EffectType effectType;
	BOOL isExpired;
	HealableTarget *target;
	
	NSMutableArray *audioTitles;
}
@property NSTimeInterval duration;
@property (readwrite) NSInteger maxStacks;
@property (readwrite) float timeApplied;
@property (readwrite, retain) HealableTarget *target;
@property (readonly) EffectType effectType;
@property BOOL isExpired;
-(id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type;

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta;
-(void)expire;
@end

@protocol HealthAdjustmentModifier

@required
-(void)willChangeHealthFrom:(NSInteger*)currentHealth toNewHealth:(NSInteger*)newHealth;
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth;

@end


#pragma mark - Shipping Spell Effects
@interface RepeatedHealthEffect : Effect
{
	NSInteger numOfTicks;
	NSInteger valuePerTick;
	float lastTick;
}
@property (readwrite) NSInteger numOfTicks;
@property (readwrite) NSInteger valuePerTick;
-(void)tick;
@end

@interface SwirlingLightEffect : RepeatedHealthEffect
@end

@interface ShieldEffect : Effect <HealthAdjustmentModifier>
{
	NSInteger amountToShield;
}
@property (readwrite) NSInteger amountToShield;
@end


@interface ReactiveHealEffect : Effect <HealthAdjustmentModifier>
@property NSInteger amountPerReaction;
@end



#pragma mark - Shipping Boss Effects
@interface TrulzarPoison : RepeatedHealthEffect
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

@interface BulwarkEffect : ShieldEffect
+(id)defaultEffect;
@end

@interface EtherealArmorEffect : Effect <HealthAdjustmentModifier>
+(id)defaultEffect;
@end
/////RITUALIST EFFECTS/////
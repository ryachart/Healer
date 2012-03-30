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

@interface HealOverTimeEffect : Effect
{
	NSInteger numOfTicks;
	NSInteger healingPerTick;
	float lastTick;
}
@property (readwrite) NSInteger numOfTicks;
@property (readwrite) NSInteger healingPerTick;
-(void)tick;
@end

@interface SwirlingLightEffect : HealOverTimeEffect
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

@interface BigFireball : Effect {
	NSInteger lastPosition;
}
@property NSInteger lastPosition;
@end

/////SHAMAN EFFECTS/////
@interface RoarOfLifeEffect : HealOverTimeEffect 
+(id)defaultEffect;
@end

@interface WoundWeavingEffect : HealOverTimeEffect
+(id)defaultEffect;
@end

@interface SurgingGrowthEffect: HealOverTimeEffect
+(id)defaultEffect;
@end

@interface FieryAdrenalineEffect : HealOverTimeEffect <HealthAdjustmentModifier>
+(id)defaultEffect;
@end

@interface TwoWindsEffect : HealOverTimeEffect
+(id)defaultEffect;
@end

@interface SymbioticConnectionEffect : HealOverTimeEffect
+(id)defaultEffect;
@end

@interface UnleashedNatureEffect: HealOverTimeEffect
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
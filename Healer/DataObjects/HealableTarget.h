//
//  HealableTarget.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CombatEvent.h"
#import "Agent.h"

#define MAXIMUM_STATUS_EFFECTS 25
@class Effect;
@class HealthAdjustmentModifier;
@interface HealableTarget : Agent {
	NSInteger health; //All HealableTargets must have health
	NSInteger maximumHealth;
	
	NSMutableArray *activeEffects;
}
@property (nonatomic, retain) NSMutableArray *healthAdjustmentModifiers;
@property (nonatomic, retain) NSString* battleID;
@property (nonatomic, readwrite) BOOL hasDied;
@property (nonatomic, setter=setHealth:) NSInteger health;
@property NSInteger maximumHealth;
@property (readonly) NSMutableArray *activeEffects;
@property (nonatomic, readwrite) BOOL isFocused;
@property (nonatomic, readonly) float healthPercentage;
- (void)setHealth:(NSInteger)newHealth;
- (BOOL)isDead;
- (void)addEffect:(Effect*)theEffect;
- (void)removeEffect:(Effect*)theEffect;
- (void)addHealthAdjustmentModifier:(HealthAdjustmentModifier*)hamod;
@end

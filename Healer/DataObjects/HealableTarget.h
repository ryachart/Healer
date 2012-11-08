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
#import "Effect.h"
#define MAXIMUM_STATUS_EFFECTS 25
@class HealthAdjustmentModifier;

@interface HealableTarget : Agent {
	NSInteger health; //All HealableTargets must have health
}
@property (nonatomic, readwrite) NSInteger maximumHealth;
@property (nonatomic, retain) NSMutableArray *healthAdjustmentModifiers;
@property (nonatomic, retain) NSString* battleID;
@property (nonatomic, readwrite) BOOL hasDied;
@property (nonatomic, setter=setHealth:) NSInteger health;
@property (nonatomic, retain) NSMutableArray *activeEffects;
@property (nonatomic, readwrite) BOOL isFocused;
@property (nonatomic, readonly) float healthPercentage;
@property (nonatomic, readonly) NSInteger maximumAbsorbtion;
@property (nonatomic, readwrite) NSInteger absorb;

- (NSInteger)effectCountOfType:(EffectType)type;
- (void)didReceiveHealing:(NSInteger)amount andOverhealing:(NSInteger)amount;
- (void)setHealth:(NSInteger)newHealth;
- (BOOL)isDead;
- (void)addEffect:(Effect*)theEffect;
- (void)removeEffect:(Effect*)theEffect;
- (void)addHealthAdjustmentModifier:(HealthAdjustmentModifier*)hamod;
- (BOOL)hasEffectWithTitle:(NSString*)title;
@end

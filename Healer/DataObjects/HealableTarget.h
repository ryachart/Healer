//
//  HealableTarget.h
//  Healer
//
//  Created by Ryan Hart on 4/26/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CombatEvent.h"
#import "Agent.h"
#import "Effect.h"

#define MAXIMUM_STATUS_EFFECTS 25
@class HealthAdjustmentModifier;

@interface HealableTarget : Agent
@property (nonatomic, readwrite) NSInteger maximumHealth;
@property (nonatomic, retain) NSMutableArray *healthAdjustmentModifiers;
@property (nonatomic, retain) NSString* networkId;
@property (nonatomic, readwrite) BOOL hasDied;
@property (nonatomic, readwrite) NSInteger health;
@property (nonatomic, retain) NSMutableArray *activeEffects;
@property (nonatomic, readonly) float healthPercentage;
@property (nonatomic, readonly) NSInteger maximumAbsorbtion;
@property (nonatomic, readwrite) NSInteger absorb;
@property (nonatomic, readonly) NSInteger healingAbsorb;
@property (nonatomic, readonly) float damageTakenMultiplierAdjustment;
@property (nonatomic, readonly) float healingReceivedMultiplierAdjustment;

- (void)passiveHealForAmount:(NSInteger)amount; //For healing that doesn't behave like normal healing
- (NSInteger)effectCountOfType:(EffectType)type;
- (void)didReceiveHealing:(NSInteger)amount andOverhealing:(NSInteger)amount;
- (void)setHealth:(NSInteger)newHealth;
- (BOOL)isDead;
- (void)addEffect:(Effect*)theEffect;
- (void)removeEffect:(Effect*)theEffect;
- (void)removeEffectsWithTitle:(NSString *)effectTitle;
- (void)addHealthAdjustmentModifier:(HealthAdjustmentModifier*)hamod;
- (BOOL)hasEffectWithTitle:(NSString*)title;
- (Effect*)effectWithTitle:(NSString *)effect;
- (void)updateEffects:(NSArray*)enemies raid:(Raid*)theRaid players:(NSArray*)players time:(float)timeDelta;
- (void)targetWasSelectedByPlayer:(Player*)player;
@end

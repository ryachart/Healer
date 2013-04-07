//
//  HealableTarget.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HealableTarget.h"
#import "GameObjects.h"
#import "Effect.h"

@implementation HealableTarget

-(void)dealloc{
    [_battleID release]; _battleID = nil;
    [_activeEffects release]; _activeEffects = nil;
    [_healthAdjustmentModifiers release]; _healthAdjustmentModifiers = nil;
    [super dealloc];
}

-(id)init{
    if (self = [super init]){
        self.battleID = nil;
        _activeEffects = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_STATUS_EFFECTS];
    }
    return self;
}

- (NSInteger)maximumHealth {
    float multiplier = 1.0;
    
    for (Effect *eff in self.activeEffects){
        multiplier += [eff maximumHealthMultiplierAdjustment];
    }
    return _maximumHealth * multiplier;
}

- (float)healingReceivedMultiplierAdjustment
{
    float multiplier = 1.0;
    
    for (Effect *eff in self.activeEffects) {
        multiplier += [eff healingReceivedMultiplierAdjustment];
    }
    return multiplier;
}

- (float)damageTakenMultiplierAdjustment
{
    float multiplier = 1.0;
    
    if (self.absorb > 0) {
        multiplier -= .05;
    }
    
    for (Effect *eff in self.activeEffects) {
        multiplier += [eff damageTakenMultiplierAdjustment];
    }
    return MAX(0,multiplier);
}

-(float)healingDoneMultiplier{
    float base = [super healingDoneMultiplier];
    
    for (Effect *eff in self.activeEffects){
        base += [eff healingDoneMultiplierAdjustment];
    }
    
    return base;
}

-(float)damageDoneMultiplier{
    float base = [super damageDoneMultiplier];
    
    for (Effect *eff in self.activeEffects){
        base += [eff damageDoneMultiplierAdjustment];
    }
    return base;
}

-(float)healthPercentage{
    return (float)self.health/(float)self.maximumHealth;
}

-(NSInteger)maximumAbsorbtion
{
    NSInteger baseAbsorbtion = 0;
    for (Effect *eff in self.activeEffects){
        baseAbsorbtion += [eff maximumAbsorbtionAdjustment];
    }
    NSInteger finalMaxAbsorb = MIN(self.maximumHealth, baseAbsorbtion);
    if (self.absorb > finalMaxAbsorb) {
        _absorb = finalMaxAbsorb;
    }
    return finalMaxAbsorb;
}

- (void)setAbsorb:(NSInteger)absorb
{
    if (absorb > self.maximumAbsorbtion) {
        absorb = self.maximumAbsorbtion;
    }
    if (absorb < 0){
        absorb = 0;
    }
    _absorb = absorb;
    
}

-(void)setHealth:(NSInteger)newHealth
{
    NSInteger overHealing = 0;
    NSInteger totalHealing = 0;
    NSInteger healingFromAbsorbtion = 0;
    if (self.hasDied){
        return;
    }
    
    NSInteger healthDelta = _health - newHealth;
    if (healthDelta > 0) { //If we are taking damage
        NSInteger damage = healthDelta;
        damage *= self.damageTakenMultiplierAdjustment;
        
        if (self.absorb > 0) {
            if (damage >= self.absorb){
                healingFromAbsorbtion = self.absorb;
                damage -= self.absorb;
                self.absorb = 0;
            }
            else if (damage < self.absorb){
                healingFromAbsorbtion = damage;
                self.absorb -= damage;
                damage = 0;
            }
        }
        newHealth = _health - damage;
    } else {
        //We are being healed
        NSInteger incomingHealing = newHealth - _health;
        incomingHealing *= self.healingReceivedMultiplierAdjustment;
        newHealth = _health + incomingHealing;
    }


	for (HealthAdjustmentModifier* ham in self.healthAdjustmentModifiers){
		[ham willChangeHealthFrom:&_health toNewHealth:&newHealth];
	}
	NSInteger prevHealth = _health;
	_health = newHealth;
	for (HealthAdjustmentModifier* ham in self.healthAdjustmentModifiers){
		[ham didChangeHealthFrom:prevHealth toNewHealth:newHealth];
	}
    
	if (_health < 0) _health = 0;
	if (_health > self.maximumHealth) {
        overHealing = _health - self.maximumHealth;
		_health = self.maximumHealth;
	}
    if (prevHealth < _health){
        totalHealing = _health - prevHealth;
    }
    if (healthDelta < 0) {
        [self didReceiveHealing:totalHealing andOverhealing:overHealing];
    }
    if (_health == 0){
        self.hasDied = YES;
        [self.logger logEvent:[CombatEvent eventWithSource:self target:self value:nil andEventType:CombatEventTypeMemberDied]];
    }
    
    if (healingFromAbsorbtion) {
        [self.logger logEvent:[CombatEvent eventWithSource:nil target:self value:[NSNumber numberWithInt:healingFromAbsorbtion] andEventType:CombatEventTypeShielding]];
    }
}

- (void)passiveHealForAmount:(NSInteger)amount
{
    _health = MAX(0,MIN(self.maximumHealth,_health + amount));
}

- (void)didReceiveHealing:(NSInteger)amount andOverhealing:(NSInteger)overAmount{
    
}

- (NSInteger)effectCountOfType:(EffectType)type {
    if (self.isDead){
        return 0;
    }
    NSInteger count = 0;
    for (Effect *eff in self.activeEffects){
        if (eff.effectType == type){
            count+= eff.stacks;
        }
    }
    return count;
}

-(void)addEffect:(Effect*)theEffect
{
	if (self.activeEffects){
        BOOL didUpdateSimilarEffect = NO;
		for (Effect *effectFA in self.activeEffects){
			if ([effectFA isKindOfEffect:theEffect] && effectFA.owner == theEffect.owner && !effectFA.isIndependent){
                effectFA.stacks++;
                [effectFA reset];
                didUpdateSimilarEffect = YES;
			}
		}
        
		if (!didUpdateSimilarEffect) {
            [theEffect reset];
            if ([theEffect conformsToProtocol:@protocol(HealthAdjustmentModifier)]){
                [self addHealthAdjustmentModifier:(HealthAdjustmentModifier*)theEffect];
            }
            [theEffect setTarget:self];
            [self.activeEffects addObject:theEffect];
        }
	}
}

- (void)removeEffect:(Effect *)theEffect{
    if (self.activeEffects){
        [theEffect setTarget:nil];
        if ([self.healthAdjustmentModifiers containsObject:theEffect]){
            [self.healthAdjustmentModifiers removeObject:theEffect];
        }
        [self.activeEffects removeObject:theEffect];
    }
}

- (void)updateEffects:(NSArray*)enemies raid:(Raid*)theRaid players:(NSArray*)players time:(float)timeDelta {
    NSMutableArray *effectsToRemove = [NSMutableArray arrayWithCapacity:5];
	for (int i = 0; i < [self.activeEffects count]; i++){
		Effect *effect = [self.activeEffects objectAtIndex:i];
        [effect combatUpdateForPlayers:players enemies:enemies theRaid:theRaid gameTime:timeDelta];
		if ([effect isExpired]){
			[effect expireForPlayers:players enemies:enemies theRaid:theRaid gameTime:timeDelta];
            [effectsToRemove addObject:effect];
		}
	}
    
    for (Effect *effect in effectsToRemove){
        [self.healthAdjustmentModifiers removeObject:effect];
        [self.activeEffects removeObject:effect];
    }
}

- (void)removeEffectsWithTitle:(NSString *)effectTitle {
    NSMutableArray *toRemove = [NSMutableArray arrayWithCapacity:self.activeEffects.count];
    for (Effect *eff in self.activeEffects) {
        if ([eff.title isEqualToString:effectTitle]) {
            [toRemove addObject:eff];
        }
    }
    
    for (Effect *eff in toRemove) {
        [self removeEffect:eff];
    }
}

-(void)addHealthAdjustmentModifier:(HealthAdjustmentModifier*)hamod{
	if (self.healthAdjustmentModifiers == nil){
		self.healthAdjustmentModifiers = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
	}
	
	[self.healthAdjustmentModifiers addObject:hamod];
}

-(BOOL)isDead
{
	return self.health <= 0;
}

-(NSString*)sourceName{
    return [[self class] description];
}
-(NSString*)targetName{
    return [[self class] description];
}

- (BOOL)hasEffectWithTitle:(NSString*)title {
    BOOL hasEffect = NO;
    
    for (Effect *eff in self.activeEffects){
        if ([eff.title isEqualToString:title]){
            hasEffect = YES; break;
        }
    }
    return hasEffect;
}
@end

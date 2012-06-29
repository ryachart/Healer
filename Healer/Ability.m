//
//  Ability.m
//  Healer
//
//  Created by Ryan Hart on 5/10/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "Ability.h"
#import "Raid.h"
#import "Agent.h"
#import "HealableTarget.h"
#import "Player.h"
#import "RaidMember.h"
#import "Boss.h"
#import "Effect.h"
#import "Spell.h"
#import "CombatEvent.h"

@interface Ability ()
@end

@implementation Ability
@synthesize failureChance, cooldown, title, owner, abilityValue;
@synthesize timeApplied, isDisabled;
- (void)dealloc{
    [owner release];
    [title release];
    [super dealloc];
}

- (BOOL)checkFailed{
    BOOL failed = arc4random() % 100 < (100 * self.failureChance);
    if (failed){
        return YES;
    }
    return NO;
}

- (Boss*)bossOwner{
    NSAssert([self.owner isKindOfClass:[Boss class]], @"boss owner is not a boss!");
    return (Boss*)self.owner;
}


- (void)combatActions:(Raid*)theRaid boss:(Boss*)theBoss players:(NSArray*)players gameTime:(float)timeDelta{
    self.timeApplied += timeDelta;
    if (self.cooldown != 9999 && self.timeApplied >= self.cooldown){
        if (!self.isDisabled){
            [self triggerAbilityForRaid:theRaid andPlayers:players];
        }else {
            NSLog(@"Ability was disabled.  Ignoring the trigger.");
        }
        self.timeApplied = 0.0;
    }
    
}
- (void)triggerAbilityForRaid:(Raid*)theRaid andPlayers:(NSArray*)players{

}

@end

@implementation Attack
- (id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd{
    if (self = [super init]){
        self.abilityValue = dmg;
        self.cooldown = cd;
        self.failureChance = .05;
    }
    return self;
}
- (RaidMember*)targetFromRaid:(Raid*)raid{
    return [raid randomLivingMember];
}



- (int)damageDealt{
    float multiplyModifier = self.owner.damageDoneMultiplier;
    int additiveModifier = 0;
    
    if ([[self bossOwner] isMultiplayer]){
        multiplyModifier += 1.5;
    }
    
    float criticalChance = [self bossOwner].criticalChance;
    if (criticalChance != 0.0 && arc4random() % 100 < (criticalChance * 100)){
        multiplyModifier += 1.5;
    }
    
    return (int)round((float)self.abilityValue * multiplyModifier) + additiveModifier;
}

-(void)damageTarget:(RaidMember*)target{
    if (![target raidMemberShouldDodgeAttack:0.0]){
        int thisDamage = [self damageDealt];
        
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:[NSNumber numberWithInt:thisDamage] andEventType:CombatEventTypeDamage]];
        [target setHealth:[target health] - thisDamage];
        if (thisDamage > 0){
            [[self bossOwner].announcer displayParticleSystemWithName:@"blood_spurt.plist" onTarget:target];
        }
        
    }else{
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:0 andEventType:CombatEventTypeDodge]];
    }
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    if ([self checkFailed]){
        return;
    }
    RaidMember *target = [self targetFromRaid:theRaid];
    [self damageTarget:target];
}

@end

@implementation FocusedAttack
@synthesize focusTarget;

- (void)dealloc{
    [focusTarget release];
    [super dealloc];
}

- (RaidMember*)mainTankFromRaid:(Raid*)raid{
    RaidMember *mainTank = nil;
    
    //Find an Unfocused guardian
    for (RaidMember *member in raid.getAliveMembers){
        if ([member isKindOfClass:[Guardian class]] && !member.isFocused){
            mainTank = member;
            break;
        }
    }
    //Otherwise find a focused guardian
    if (!mainTank){
        for (RaidMember *member in raid.getAliveMembers){
            if ([member isKindOfClass:[Guardian class]]){
                mainTank = member;
                break;
            }
        }
    }
    
    //Otherwise pick a random target
    if (!mainTank){
        mainTank = [raid randomLivingMember];
    }
    return mainTank;
}

- (RaidMember*)targetFromRaid:(Raid *)raid{
    if (self.focusTarget && !self.focusTarget.isDead){
        return self.focusTarget;
    }
    return [super targetFromRaid:raid];
}

- (void)combatActions:(Raid *)theRaid boss:(Boss *)theBoss players:(NSArray *)players gameTime:(float)timeDelta{
    if (!self.focusTarget){
        self.focusTarget = [self mainTankFromRaid:theRaid];
        [self.focusTarget setIsFocused:YES];
    }
    [super combatActions:theRaid boss:theBoss players:players gameTime:timeDelta];
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    if ([self checkFailed]){
        return;
    }
    RaidMember *target = [self targetFromRaid:theRaid];
    [self damageTarget:target];
    if (self.focusTarget == target && self.focusTarget.isDead){
        Effect *enrageEffect = [[Effect alloc] initWithDuration:600 andEffectType:EffectTypePositiveInvisible];
        [enrageEffect setOwner:self.owner];
        [enrageEffect setTitle:@"Enraged"];
        [enrageEffect setTarget:[self bossOwner]];
        [enrageEffect setDamageDoneMultiplierAdjustment:2.0];
        [[self bossOwner] addEffect:[enrageEffect autorelease]];
        [[self bossOwner].announcer announce:[NSString stringWithFormat:@"%@ glows with power after defeating its focused target.", [self bossOwner].title]];
    }
    
}
@end

@implementation  StackingDamage

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    Effect *damageBooster = [[Effect alloc] initWithDuration:99999 andEffectType:EffectTypePositiveInvisible];
    [damageBooster setTarget:[self bossOwner]];
    [damageBooster setOwner:self.owner];
    [damageBooster setDamageDoneMultiplierAdjustment:(self.abilityValue / 100.0)];
    [[self bossOwner] addEffect:damageBooster];
    [damageBooster release];
}
@end

@implementation BaraghastBreakOff
@synthesize ownerAutoAttack;
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    BreakOffEffect *breakoff = [[BreakOffEffect alloc] initWithDuration:5 andEffectType:EffectTypeNegativeInvisible];
    [breakoff setOwner:self.owner];
    [breakoff setValuePerTick:-25];
    [breakoff setNumOfTicks:5];
    [breakoff setReenableAbility:self.ownerAutoAttack];
    [self.ownerAutoAttack setIsDisabled:YES];
    
    RaidMember *selectTarget = nil;
    
    NSArray *aliveMembers = theRaid.getAliveMembers;
    if (aliveMembers.count == 1 && [aliveMembers objectAtIndex:0] == self.ownerAutoAttack.focusTarget){
        selectTarget = self.ownerAutoAttack.focusTarget;
    }else {
        while (!selectTarget || selectTarget == self.ownerAutoAttack.focusTarget){
            selectTarget = [theRaid randomLivingMember];
        }
    }
    [breakoff setTarget:selectTarget];
    [selectTarget addEffect:breakoff];
    [breakoff release];
    
    self.cooldown = arc4random() % 20 + 25;
}
@end

@implementation BaraghastRoar 
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [[(Boss*)self.owner announcer] displayScreenShakeForDuration:.4];
    for (Player *player in players) {
        if ([player spellBeingCast]){
            [[player spellBeingCast] applyTemporaryCooldown:2.0];
        }
        [player interrupt];
    }
    for (RaidMember *member in theRaid.raidMembers ){
        [member setHealth:member.health - (15.0 * self.owner.damageDoneMultiplier)];
        for (Effect *effect in member.activeEffects){
            if (effect.effectType == EffectTypePositive){
                [effect setIsExpired:YES];
            }
        }
    }
    
    self.cooldown = arc4random() % 12 + 12;
}
@end

@implementation Debilitate 
@synthesize numTargets;

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    for (int i = 0; i < self.numTargets; i++){
        RaidMember *target = [theRaid randomLivingMember];
        DebilitateEffect *debilitateEffect = [[DebilitateEffect alloc] initWithDuration:999 andEffectType:EffectTypeNegative];
        [debilitateEffect setOwner:self.owner];
        [debilitateEffect setTitle:@"baraghast-debilitate"];
        [debilitateEffect setSpriteName:@"bleeding.png"];
        [debilitateEffect setValuePerTick:0];
        [debilitateEffect setNumOfTicks:1];
        [target addEffect:debilitateEffect];
        [debilitateEffect release];
        [target setHealth:target.health * (self.abilityValue * self.owner.damageDoneMultiplier)];
    }
}
@end

@implementation Crush 
@synthesize target;

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    if (self.target){
        [[(Boss*)self.owner announcer] announce:[NSString stringWithFormat:@"%@ prepares to land a massive strike!", [(Boss*)self.owner title]]];
        DelayedHealthEffect *crushEffect = [[DelayedHealthEffect alloc] initWithDuration:5 andEffectType:EffectTypeNegative];
        [crushEffect setOwner:self.owner];
        [crushEffect setTitle:@"crush"];
        [crushEffect setSpriteName:@"crush.png"];
        [crushEffect setValue:-110];
        [target addEffect:crushEffect];
        [crushEffect release];
    }
}
@end

@implementation Deathwave 
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [[(Boss*)self.owner announcer] displayScreenShakeForDuration:1.0];
    NSInteger livingMemberCount = theRaid.getAliveMembers.count;
    NSInteger deathWaveDamage = (int)round(1200.0 / livingMemberCount);
    for (RaidMember *member in theRaid.getAliveMembers){
        [member setHealth:member.health - (deathWaveDamage * self.owner.damageDoneMultiplier)];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:[NSNumber numberWithInt:(deathWaveDamage * self.owner.damageDoneMultiplier)] andEventType:CombatEventTypeDamage]]; 
    }
    [(Boss*)self.owner ownerDidExecuteAbility:self];
}
@end
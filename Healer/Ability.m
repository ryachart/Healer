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
#import "ProjectileEffect.h"

@interface Ability ()
@end

@implementation Ability
@synthesize failureChance, cooldown, title, owner, abilityValue;
@synthesize timeApplied, isDisabled;

- (id)copy {
    Ability *ab = [[[self class] alloc] init];
    [ab setFailureChance:self.failureChance];
    [ab setCooldown:self.cooldown];
    [ab setTitle:self.title];
    [ab setOwner:self.owner];
    [ab setAbilityValue:self.abilityValue];
    return ab;
}
- (void)dealloc{
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

- (id)copy {
    FocusedAttack *copy = [super copy];
    [copy setFocusTarget:self.focusTarget];
    return copy;
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

@implementation Fireball 
@synthesize spriteName;

- (void)dealloc {
    [spriteName release];
    [super dealloc];
}

- (id)copy {
    Fireball *fbCopy = [super copy];
    [fbCopy setSpriteName:self.spriteName];
    return fbCopy;
}

- (void) triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    RaidMember *target = [theRaid randomLivingMember];
    NSTimeInterval colTime = 1.75;
    DelayedHealthEffect *fireball = [[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
    
    ProjectileEffect *fireballVisual = [[ProjectileEffect alloc] initWithSpriteName:self.spriteName target:target andCollisionTime:colTime];
    [fireballVisual setCollisionParticleName:@"fire_explosion.plist"];
    [[(Boss*)self.owner announcer] displayProjectileEffect:fireballVisual];
    [fireballVisual release];
    [fireball setOwner:self.owner];
    [fireball setFailureChance:.15];
    [fireball setTitle:@"fireball-dhe"];
    [fireball setMaxStacks:10];
    NSInteger damage = (arc4random() % ABS(self.abilityValue) + ABS((self.abilityValue / 2)));
    [fireball setValue:-damage];
    [target addEffect:fireball];
    [fireball release];
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
- (void)dealloc {
    [ownerAutoAttack release];
    [super dealloc];
}
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
        int safety = 0;
        while (!selectTarget || selectTarget == self.ownerAutoAttack.focusTarget){
            selectTarget = [theRaid randomLivingMember];
            safety++;
            if (safety > 25){
                break;
            }
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

- (id)copy {
    Debilitate *copy = [super copy];
    [copy setNumTargets:self.numTargets];
    return copy;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    for (int i = 0; i < self.numTargets; i++){
        RaidMember *target = [theRaid randomLivingMember];
        DebilitateEffect *debilitateEffect = [[DebilitateEffect alloc] initWithDuration:999 andEffectType:EffectTypeNegative];
        [debilitateEffect setOwner:self.owner];
        [debilitateEffect setTitle:@"baraghast-debilitate"];
        [debilitateEffect setSpriteName:@"bleeding.png"];
        [target addEffect:debilitateEffect];
        [debilitateEffect release];
        [target setHealth:target.health * (self.abilityValue * self.owner.damageDoneMultiplier)];
    }
}
@end

@implementation Crush 
@synthesize target;

- (id)copy {
    Crush *copy = [super copy];
    [copy setTarget:self.target];
    return copy;
}

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

@implementation RandomAbilityGenerator

+ (NSArray*)allAbilities {
    NSMutableArray *allAbilities = [NSMutableArray arrayWithCapacity:10];
    
    Deathwave *dwAbility = [[Deathwave alloc] init];
    [dwAbility setTitle:@"random-deathweave"];
    [dwAbility setCooldown:32.0];
    [dwAbility setFailureChance:.05];
    [allAbilities addObject:[dwAbility autorelease]];
    
    BaraghastRoar *roar = [[BaraghastRoar alloc] init];
    [roar setTitle:@"random-roar"];
    [roar setCooldown:24.0];
    [roar setFailureChance:.05];
    [allAbilities addObject:[roar autorelease]];
    
    Fireball *fbAbility = [[Fireball alloc] init];
    [fbAbility setTitle:@"random-fireball"];
    [fbAbility setSpriteName:@"fireball.png"];
    [fbAbility setAbilityValue:50];
    [fbAbility setCooldown:12.0];
    [fbAbility setFailureChance:.05];
    [allAbilities addObject:[fbAbility autorelease]];
    
    Fireball *quickFireball = [[Fireball alloc] init];
    [quickFireball setSpriteName:@"fireball.png"];
    [quickFireball setTitle:@"random-quickfirebal"];
    [quickFireball setAbilityValue:10];
    [quickFireball setCooldown:3.0];
    [quickFireball setFailureChance:.1];
    [allAbilities addObject:[quickFireball autorelease]];
    
    //Trulzar Poison
    
    //Mortal Strike Cloud
    
    //Highly Lethal Bleed
    
    //Crush
    
    //Focus Target Enrage
    
    //Dispel-Explosion
    
    //Dot everyone
    
    //EXPLODES IF YOU HEAL THEM
    return allAbilities;
}
@end

@implementation InvertedHealing
@synthesize numTargets;
- (id)copy {
    InvertedHealing *copy = [super copy];
    [copy setNumTargets:self.numTargets];
    return copy;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    for (int i = 0; i < self.numTargets; i++){
        RaidMember *target = [theRaid randomLivingMember];
        InvertedHealingEffect *effect = [[InvertedHealingEffect alloc] initWithDuration:6.0 andEffectType:EffectTypeNegative];
        [effect setAilmentType:AilmentCurse];
        [effect setSpriteName:@"healing_inverted.png"];
        [effect setTitle:@"inverted-healing"];
        [effect setPercentageConvertedToDamage:.5];
        [effect setOwner:self.owner];
        [target addEffect:effect];
        [effect release];
    }
}
@end

@implementation SoulBurn 
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    RaidMember *target = [theRaid randomLivingMember];
    SoulBurnEffect *sbe = [[SoulBurnEffect alloc] initWithDuration:12 andEffectType:EffectTypeNegative];
    [sbe setSpriteName:@"soul_burn.png"];
    [sbe setTitle:@"soul-burn"];
    [sbe setValuePerTick:-20];
    [sbe setNumOfTicks:6];
    [sbe setOwner:self.owner];
    [sbe setEnergyToBurn:75];
    [target addEffect:sbe];
    [sbe release];
}
@end

@implementation GainAbility
@synthesize abilityToGain;
- (void)dealloc {
    [abilityToGain release];
    [super dealloc];
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    Ability *newAbility = [self.abilityToGain copy];
    [(Boss*)self.owner addAbility:newAbility];
    [newAbility release];
}
@end

@implementation RaidDamage

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    NSArray *livingMembers = theRaid.getAliveMembers;
    
    for (RaidMember *member in livingMembers){
        NSInteger damage = self.abilityValue * self.owner.damageDoneMultiplier;
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member  value:[NSNumber numberWithInt:damage] andEventType:CombatEventTypeDamage]];
        [member setHealth:member.health - damage];
    }
}
@end

@implementation Grip

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    RaidMember *target = [theRaid randomLivingMember];
    int i = 0;
    while (target.isFocused && i < 20) {
        i++; //If the only thing left is the tank, dont infinite loop
        target = [theRaid randomLivingMember];
    }
    
    GripEffect *gripEff = [[GripEffect alloc] initWithDuration:10 andEffectType:EffectTypeNegative];
    [gripEff setAilmentType:AilmentCurse];
    [gripEff setSpriteName:@"grip.png"];
    [gripEff setOwner:self.owner];
    [gripEff setValuePerTick:-17];
    [gripEff setNumOfTicks:5];
    [gripEff setTitle:@"gatekeeper-grip"];
    [target addEffect:gripEff];
    [gripEff release];
}
@end

@implementation Impale 
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    DelayedHealthEffect *finishHimEffect = [[DelayedHealthEffect alloc] initWithDuration:5 andEffectType:EffectTypeNegative];
    [finishHimEffect setSpriteName:@"bleeding.png"];
    
    RaidMember *target = [theRaid randomLivingMember];
    
    NSInteger damage = self.abilityValue * self.owner.damageDoneMultiplier;
    [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target  value:[NSNumber numberWithInt:damage] andEventType:CombatEventTypeDamage]];
    [target setHealth:target.health - damage];
    [finishHimEffect setAilmentType:AilmentTrauma];
    [finishHimEffect setValue: -1 * damage * .4];
    [finishHimEffect setOwner:self.owner];
    [finishHimEffect setTitle:@"impale-finisher"];
    [target addEffect:finishHimEffect];
    [finishHimEffect release];
    
}
@end

@implementation BloodDrinker 
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    if ([self checkFailed]){
        return;
    }
    RaidMember *target = [self targetFromRaid:theRaid];
    [self damageTarget:target];
    if (self.focusTarget == target && self.focusTarget.isDead){
        self.focusTarget = nil;
        Boss *theBoss = (Boss*)self.owner;
        [theBoss setHealth:theBoss.health + theBoss.maximumHealth * .1];
        [theBoss.announcer announce:[NSString stringWithFormat:@"A Blood Drinker heals %@ upon defeating its foe.", theBoss.title]];
    }
}
@end
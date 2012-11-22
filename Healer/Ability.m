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
#import "Boss.h"
#import "Effect.h"
#import "Spell.h"
#import "CombatEvent.h"
#import "AbilityDescriptor.h"

@interface Ability ()
@end

@implementation Ability
@synthesize failureChance, title, owner, abilityValue;
@synthesize timeApplied, isDisabled;

- (id)init {
    if (self = [super init]){
        self.attackParticleEffectName = @"blood_spurt.plist";
        self.isActivating = NO;
    }
    return self;
}

- (id)copy {
    Ability *ab = [[[self class] alloc] init];
    [ab setFailureChance:self.failureChance];
    [ab setCooldown:self.cooldown];
    [ab setTitle:self.title];
    [ab setOwner:self.owner];
    [ab setAbilityValue:self.abilityValue];
    [ab setDescriptor:self.descriptor];
    return ab;
}
- (void)dealloc{
    [title release];
    [_descriptor release];
    [_attackParticleEffectName release];
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
    if (self.cooldown != kAbilityRequiresTrigger && self.timeApplied >= self.cooldown){
        if (!self.isDisabled){
            [self triggerAbilityForRaid:theRaid andPlayers:players];
            [(Boss*)self.owner ownerDidExecuteAbility:self];
        }
        self.timeApplied = 0.0;
        self.isActivating = NO;
    }
    if (self.activationTime > 0 && !self.isActivating && self.cooldown - self.activationTime <= self.timeApplied) {
        self.isActivating = YES;
        [self.owner ownerDidBeginAbility:self];
    }
    
}

- (NSTimeInterval)remainingActivationTime
{
    if (self.isActivating) {
        return  (self.cooldown - self.timeApplied);
    }
    return 0.0; //Not activating
}

- (float)remainingActivationPercentage
{
    if (self.isActivating) {
        return self.remainingActivationTime / self.activationTime;
    }
    return 0.0; //Not activating
}

- (RaidMember*)targetWithoutEffectWithTitle:(NSString*)ttle inRaid:(Raid*)theRaid{
    return [self targetWithoutEffectsTitled:[NSArray arrayWithObject:ttle] inRaid:theRaid];
}

- (RaidMember*)targetWithoutEffectsTitled:(NSArray*)effects inRaid:(Raid*)theRaid {
    RaidMember *target = nil;
    int safety = 0;
    BOOL isInvalidTarget = NO;
    do {
        isInvalidTarget = NO;
        target = [theRaid randomLivingMember];
        if (safety >= 25){
            break;
        }
        safety++;
        for (NSString *effTitle in effects){
            if ([target hasEffectWithTitle:effTitle]){
                isInvalidTarget = YES;
                break;
            }
        }
    } while (isInvalidTarget);
    return target;
}

- (void)triggerAbilityForRaid:(Raid*)theRaid andPlayers:(NSArray*)players{

}

- (int)damageDealt{
    float multiplyModifier = self.owner.damageDoneMultiplier;
    int additiveModifier = 0;
    
    float criticalChance = [self bossOwner].criticalChance;
    if (criticalChance != 0.0 && arc4random() % 100 < (criticalChance * 100)){
        multiplyModifier += 1.5;
    }
    
    NSInteger finalDamageValue = (int)round((float)self.abilityValue * multiplyModifier) + additiveModifier;
    
    return FUZZ(finalDamageValue, 30.0);
}

- (void)damageTarget:(RaidMember *)target forDamage:(NSInteger)damage
{
    if (![target raidMemberShouldDodgeAttack:0.0]){
        [self willDamageTarget:target];
        int thisDamage = damage;
        
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:[NSNumber numberWithInt:thisDamage] andEventType:CombatEventTypeDamage]];
        [target setHealth:[target health] - thisDamage];
        if (thisDamage > 0){
            [[self bossOwner].announcer displayParticleSystemWithName:self.attackParticleEffectName onTarget:target];
        }
        
    }else{
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:0 andEventType:CombatEventTypeDodge]];
    }
}

-(void)damageTarget:(RaidMember*)target{
    [self damageTarget:target forDamage:[self damageDealt]];
}

- (void)willDamageTarget:(RaidMember*)target {
    //Override
}
@end

@implementation Attack
- (void)dealloc {
    [_appliedEffect release];
    [super dealloc];
}

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

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    if ([self checkFailed]){
        return;
    }
    RaidMember *target = [self targetFromRaid:theRaid];
    if (target.isFocused){
        return; //We fail when trying to hit tanks with attacks
    }
    [self damageTarget:target];
    if (self.appliedEffect){
        Effect *applyThis = [self.appliedEffect copy];
        [applyThis setOwner:self.owner];
        [target addEffect:applyThis];
        [applyThis release];
    }
}

@end

@implementation SustainedAttack
- (void)dealloc {
    [_currentTarget release];
    [super dealloc];
}

- (id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd
{
    if (self = [super initWithDamage:dmg andCooldown:cd]) {
        self.currentAttacksRemaining = arc4random() % 3 + 2;
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    self.currentAttacksRemaining--;
    if ([self checkFailed]) {
        return;
    }
    [self damageTarget:[self targetFromRaid:theRaid]];
}

- (RaidMember*)targetFromRaid:(Raid *)raid
{
    if (self.currentAttacksRemaining <= 0){
        self.currentAttacksRemaining = arc4random() % 3 + 2;
        [self.currentTarget setIsFocused:NO];
        self.currentTarget = nil;
    }
    if (!self.currentTarget) {
        self.currentTarget = [super targetFromRaid:raid];
        [self.currentTarget setIsFocused:YES];
    }
    
    return self.currentTarget;
}

@end

@implementation FocusedAttack
@synthesize focusTarget;
@synthesize enrageApplied;

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

- (void)setIsDisabled:(BOOL)newIsDisabled {
    [super setIsDisabled:newIsDisabled];
    if (self.focusTarget){
        [self.focusTarget setIsFocused:!newIsDisabled];
    }
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
    if (self.appliedEffect){
        [target addEffect:self.appliedEffect];
    }
    if (self.focusTarget.isDead){
        self.focusTarget = target;
        if (!self.enrageApplied){
            self.abilityValue *= 3;
            [[self bossOwner].announcer announce:[NSString stringWithFormat:@"%@ glows with power after defeating its focused target.", [self bossOwner].title]];
            
            AbilityDescriptor *glowingPower = [[[AbilityDescriptor alloc] init] autorelease];
            [glowingPower setAbilityDescription:@"After defeating a Focused target, this enemy becomes unstoppable and will deal vastly increased damage."];
            [glowingPower setAbilityName:@"Glowing with Power"];
            [glowingPower setIconName:@"unknown_ability.png"];
            [[self bossOwner] addAbilityDescriptor:glowingPower];
            self.enrageApplied = YES;
        }
    }
}
@end

@implementation ProjectileAttack

- (id)init
{
    if (self = [super init]){
        self.explosionParticleName = @"fire_explosion.plist";
    }
    return self;
}

- (void)dealloc {
    [_spriteName release];
    [_explosionParticleName release];
    [_appliedEffect release];
    [super dealloc];
}

- (id)copy {
    ProjectileAttack *fbCopy = [super copy];
    [fbCopy setSpriteName:self.spriteName];
    [fbCopy setExplosionParticleName:self.explosionParticleName];
    [fbCopy setAppliedEffect:self.appliedEffect];
    [fbCopy setEffectType:self.effectType];
    return fbCopy;
}

- (void) triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    
    BOOL didFail = self.checkFailed;
    RaidMember *target = [theRaid randomLivingMember];
    NSTimeInterval colTime = 1.75;
    
    ProjectileEffect *fireballVisual = [[ProjectileEffect alloc] initWithSpriteName:self.spriteName target:target andCollisionTime:colTime];
    [fireballVisual setCollisionParticleName:self.explosionParticleName];
    [fireballVisual setIsFailed:didFail];
    fireballVisual.type = self.effectType;
    [[(Boss*)self.owner announcer] displayProjectileEffect:fireballVisual];
    [fireballVisual release];
    
    DelayedHealthEffect *fireball = [[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
    if (didFail){
        [fireball setFailureChance:100];
    }
    [fireball setOwner:self.owner];
    [fireball setIsIndependent:YES];
    [fireball setAppliedEffect:self.appliedEffect];
    [fireball setTitle:[NSString stringWithFormat:@"projectile-dhe%i", arc4random() % 200]];
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
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"Baraghast ignores his focused target temporarily and attempts to slay a random ally instead."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Disengage"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    BreakOffEffect *breakoff = [[BreakOffEffect alloc] initWithDuration:5 andEffectType:EffectTypeNegativeInvisible];
    [breakoff setOwner:self.owner];
    [breakoff setValuePerTick:-250];
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
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"Interrupts spell casting, dispels all positive spell effects, and deals moderate damage to all allies."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Warlord's Roar"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [[(Boss*)self.owner announcer] displayScreenShakeForDuration:.4];
    for (Player *player in players) {
        if ([player spellBeingCast]){
            [[player spellBeingCast] applyTemporaryCooldown:2.0];
        }
        [player interrupt];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:player value:[NSNumber numberWithFloat:2.0]  andEventType:CombatEventTypePlayerInterrupted]];
    }
    for (RaidMember *member in theRaid.raidMembers ){
        [member setHealth:member.health - (150.0 * self.owner.damageDoneMultiplier)];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:[NSNumber numberWithInt:(15.0 * self.owner.damageDoneMultiplier)]  andEventType:CombatEventTypeDamage]];
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
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"Deals moderate damage to affected targets and prevents them from dealing any damage until they are healed to full health."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Debilitate"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
}

- (id)copy {
    Debilitate *copy = [super copy];
    [copy setNumTargets:self.numTargets];
    return copy;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    for (int i = 0; i < self.numTargets; i++){
        RaidMember *target = [theRaid randomLivingMember];
        DebilitateEffect *debilitateEffect = [[DebilitateEffect alloc] initWithDuration:-1 andEffectType:EffectTypeNegative];
        [debilitateEffect setOwner:self.owner];
        [debilitateEffect setTitle:@"baraghast-debilitate"];
        [debilitateEffect setSpriteName:@"bleeding.png"];
        [target addEffect:debilitateEffect];
        [debilitateEffect release];
        [target setHealth:target.health * (self.abilityValue * self.owner.damageDoneMultiplier)];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:[NSNumber numberWithInt:(self.abilityValue * self.owner.damageDoneMultiplier)] andEventType:CombatEventTypeDamage]]; 
    }
}
@end

@implementation Crush 
@synthesize target;
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"After 5 seconds a massive strike lands on the affected target dealing very high damage."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Crush"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
}

- (id)copy {
    Crush *copy = [super copy];
    [copy setTarget:self.target];
    return copy;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    if (self.target && !self.target.isDead){
        [[(Boss*)self.owner announcer] announce:[NSString stringWithFormat:@"%@ prepares to land a massive strike!", [(Boss*)self.owner title]]];
        DelayedHealthEffect *crushEffect = [[DelayedHealthEffect alloc] initWithDuration:5 andEffectType:EffectTypeNegative];
        [crushEffect setOwner:self.owner];
        [crushEffect setTitle:@"crush"];
        [crushEffect setSpriteName:@"crush.png"];
        [crushEffect setValue:-950];
        [target addEffect:crushEffect];
        [crushEffect release];
    }
}
@end

@implementation Deathwave
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"Deals extremely high damage to all living allies.  The damage is divided by the number of living allies."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Deathwave"];
        [self setDescriptor:desc];
        [desc release];
        self.abilityValue = 10000;
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [[(Boss*)self.owner announcer] displayScreenShakeForDuration:1.0];
    [[(Boss*)self.owner announcer] displayParticleSystemOnRaidWithName:@"death_ring.plist" forDuration:2.0];

    NSInteger livingMemberCount = theRaid.getAliveMembers.count;
    for (RaidMember *member in theRaid.getAliveMembers){
        NSInteger deathWaveDamage = (int)round((float)self.abilityValue / livingMemberCount);
        deathWaveDamage *= (arc4random() % 50 + 50) / 100.0;
        [member setHealth:member.health - (deathWaveDamage * self.owner.damageDoneMultiplier)];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:[NSNumber numberWithInt:(deathWaveDamage * self.owner.damageDoneMultiplier)] andEventType:CombatEventTypeDamage]]; 
    }
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
    
    ProjectileAttack *fbAbility = [[ProjectileAttack alloc] init];
    [fbAbility setTitle:@"random-fireball"];
    [fbAbility setSpriteName:@"fireball.png"];
    [fbAbility setAbilityValue:500];
    [fbAbility setCooldown:12.0];
    [fbAbility setFailureChance:.05];
    [allAbilities addObject:[fbAbility autorelease]];
    
    ProjectileAttack *quickFireball = [[ProjectileAttack alloc] init];
    [quickFireball setSpriteName:@"fireball.png"];
    [quickFireball setTitle:@"random-quickfirebal"];
    [quickFireball setAbilityValue:100];
    [quickFireball setCooldown:3.0];
    [quickFireball setFailureChance:.1];
    [allAbilities addObject:[quickFireball autorelease]];
    
    BloodMinion *bm = [[BloodMinion alloc] init];
    [bm setTitle:@"blood-minion"];
    [bm setCooldown:10.0];
    [bm setAbilityValue:100];
    [allAbilities addObject:bm];
    [bm release];
    
    FireMinion *fm = [[FireMinion alloc] init];
    [fm setTitle:@"fire-minion"];
    [fm setCooldown:15.0];
    [fm setAbilityValue:350];
    [allAbilities addObject:fm];
    [fm release];
    
    ShadowMinion *sm = [[ShadowMinion alloc] init];
    [sm setTitle:@"shadow-minion"];
    [sm setCooldown:12.0];
    [sm setAbilityValue:200];
    [allAbilities addObject:sm];
    [sm release];
    
    OverseerProjectiles* projectilesAbility = [[[OverseerProjectiles alloc] init] autorelease];
    [projectilesAbility setAbilityValue:560];
    [projectilesAbility setCooldown:4.5];
    [allAbilities addObject:projectilesAbility];
    
    FocusedAttack *tankAttack = [[FocusedAttack alloc] initWithDamage:620 andCooldown:2.45];
    [tankAttack setFailureChance:.4];
    [allAbilities addObject:tankAttack];
    [tankAttack release];
    
    TargetTypeFlameBreath *sweepingFlame = [[[TargetTypeFlameBreath alloc] init] autorelease];
    [sweepingFlame setCooldown:9.0];
    [sweepingFlame setAbilityValue:600];
    [sweepingFlame setNumTargets:5];
    [allAbilities addObject:sweepingFlame];
    
    Grip *gripAbility = [[Grip alloc] init];
    [gripAbility setTitle:@"grip-ability"];
    [gripAbility setCooldown:22];
    [gripAbility setAbilityValue:-140];
    [allAbilities addObject:gripAbility];
    [gripAbility release];
    
    Impale *impaleAbility = [[Impale alloc] init];
    [impaleAbility setTitle:@"gatekeeper-impale"];
    [impaleAbility setCooldown:16];
    [allAbilities addObject:impaleAbility];
    [impaleAbility setAbilityValue:820];
    [impaleAbility release];
    
    InvertedHealing *invHeal = [[InvertedHealing alloc] init];
    [invHeal setNumTargets:3];
    [invHeal setCooldown:6.0];
    [allAbilities addObject:invHeal];
    [invHeal release];
    
    SoulBurn *sb = [[SoulBurn alloc] init];
    [sb setCooldown:16.0];
    [allAbilities addObject:sb];
    [sb release];
    
    OozeTwoTargets *oozeTwo = [[OozeTwoTargets alloc] init];
    [oozeTwo setCooldown:10.0];
    [oozeTwo setTitle:@"ooze-two"];
    [allAbilities addObject:oozeTwo];
    [oozeTwo release];
    
    [allAbilities addObject:[Cleave normalCleave]];
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

- (id)init {
    if (self = [super init]){
        self.maxAbilities = 5;
        self.managedAbilities = [NSMutableArray arrayWithCapacity:self.maxAbilities];
    }
    return self;
}

- (void)addRandomAbility {
    Boss *bossOwner = (Boss*)self.owner;
    NSArray *allAbilities = [RandomAbilityGenerator allAbilities];
    Ability *randomAbility =  [allAbilities objectAtIndex:arc4random() % allAbilities.count];
    [self.managedAbilities addObject:randomAbility];
    [bossOwner addAbility:randomAbility];
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    Boss *bossOwner = (Boss*)self.owner;
    if (self.managedAbilities.count == self.maxAbilities){
        Ability *abilityToRemove = [self.managedAbilities objectAtIndex:(arc4random() % self.managedAbilities.count)];
        [bossOwner removeAbility:abilityToRemove];
        [self.managedAbilities removeObject:abilityToRemove];
    }
    
    [self addRandomAbility];
    
}
@end

@implementation InvertedHealing
@synthesize numTargets;
- (id)copy {
    InvertedHealing *copy = [super copy];
    [copy setNumTargets:self.numTargets];
    return copy;
}

- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"Any healing done is instead converted into damage to the affected target."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Spiritual Inversion"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
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
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"Deals moderate damage over time to its target and any healing done to an affected target will burn 75 energy from the Healer."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Soul Burn"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    RaidMember *target = [theRaid randomLivingMember];
    SoulBurnEffect *sbe = [[SoulBurnEffect alloc] initWithDuration:12 andEffectType:EffectTypeNegative];
    [sbe setSpriteName:@"soul_burn.png"];
    [sbe setTitle:@"soul-burn"];
    [sbe setValuePerTick:-200];
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
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member  value:[NSNumber numberWithInt:damage] andEventType:CombatEventTypeDamage]];
    }
}
@end

@implementation Grip
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"A random player will be strangled by dark magic reducing healing done by 98% and dealing damage over time."];
        [desc setIconName:@"grip_ability.png"];
        [desc setAbilityName:@"Grip of Delsarn"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    RaidMember *target = [self targetWithoutEffectWithTitle:@"impale-finisher" inRaid:theRaid];
    if (target.isFocused){
        return;
        //The effect fails if the target is focused
    }
    
    GripEffect *gripEff = [[GripEffect alloc] initWithDuration:10 andEffectType:EffectTypeNegative];
    [gripEff setAilmentType:AilmentCurse];
    [gripEff setSpriteName:@"grip.png"];
    [gripEff setOwner:self.owner];
    [gripEff setValuePerTick:self.abilityValue];
    [gripEff setNumOfTicks:5];
    [gripEff setTitle:@"gatekeeper-grip"];
    [target addEffect:gripEff];
    [gripEff release];
}
@end

@implementation Impale
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"Periodically a random player will be dealt high damage and begin bleeding severely for several seconds."];
        [desc setIconName:@"bleeding_ability.png"];
        [desc setAbilityName:@"Impale"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    RaidMember *target = [self targetWithoutEffectWithTitle:@"gatekeeper-grip" inRaid:theRaid];
    
    if (target.isFocused){
        //The ability fails if it chooses a focused target
        return;
    }
    DelayedHealthEffect *finishHimEffect = [[DelayedHealthEffect alloc] initWithDuration:3.5 andEffectType:EffectTypeNegative];
    [finishHimEffect setSpriteName:@"bleeding.png"];
    
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

- (id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd {
    if (self = [super initWithDamage:dmg andCooldown:cd]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"The Gatekeeper has summoned Blood Drinkers to its side.  These vicious beasts will attack a Guardian and heal the Gatekeeper for a substantial amount of they are successful in vanquishing their target."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Blood Drinker"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
}

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

@implementation TargetTypeAttack

- (NSArray *)targetsFromRaid:(Raid*)theRaid {
    return [theRaid randomTargets:self.numTargets withPositioning:self.targetPositioningType];
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    if ([self checkFailed]) {
        return;
    }
    NSArray *targets = [self targetsFromRaid:theRaid];
    for (RaidMember *target in targets) {
        [self damageTarget:target];
    }
}
@end

@implementation BoneThrow

- (id)init {
    if (self = [super init]){
        AbilityDescriptor *boneThrowDesc = [[AbilityDescriptor alloc] init];
        [boneThrowDesc setAbilityDescription:@"Hurls a bone at a target dealing moderate damage and causing the target to be knocked to the ground.  Targets knocked to the ground will deal no damage until they are healed."];
        [boneThrowDesc setIconName:@"bone_throw_ability.png"];
        [boneThrowDesc setAbilityName:@"Bone Throw"];
        [self setDescriptor:boneThrowDesc];
        [boneThrowDesc release];
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    float throwDuration = 2.0;
    RaidMember *target = [theRaid randomLivingMember];
    DelayedHealthEffect *boneThrowEffect = [[DelayedHealthEffect alloc] initWithDuration:throwDuration andEffectType:EffectTypeNegativeInvisible];
    [boneThrowEffect setIsIndependent:YES];
    [boneThrowEffect setOwner:self.owner];
    [boneThrowEffect setTitle:@"bonethrow-projectile"];
    [boneThrowEffect setValue:-400];
    [boneThrowEffect setMaxStacks:10];
    FallenDownEffect *fde = [FallenDownEffect defaultEffect];
    [fde setOwner:self.owner];
    [boneThrowEffect setAppliedEffect:fde];
    [target addEffect:boneThrowEffect];
    [boneThrowEffect release];
    
    ProjectileEffect *boneVisual = [[ProjectileEffect alloc] initWithSpriteName:@"bone_throw.png" target:target andCollisionTime:throwDuration];
    [boneVisual setType:ProjectileEffectTypeThrow];
    [[(Boss*)self.owner announcer] displayProjectileEffect:boneVisual];
    [boneVisual release];
}
@end

@implementation TargetTypeFlameBreath

- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"Deals heavy fire damage to targets positioned close together."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Breath of Flame"];
        [self setDescriptor:desc];
        [desc release];
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    self.targetPositioningType = arc4random() % 2;
    [super triggerAbilityForRaid:theRaid andPlayers:players];
}

- (void)willDamageTarget:(RaidMember *)target {
    [[(Boss*)self.owner announcer] displayParticleSystemWithName:@"fire_explosion.plist" onTarget:target];
}
@end

@implementation BoneQuake

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [super triggerAbilityForRaid:theRaid andPlayers:players];
    NSArray *members = theRaid.getAliveMembers;
    
    for (RaidMember *member in members) {
        RepeatedHealthEffect *bonequakeDot = [[RepeatedHealthEffect alloc] initWithDuration:3.0 andEffectType:EffectTypeNegative];
        [bonequakeDot setNumOfTicks:3];
        [bonequakeDot setValuePerTick:-(arc4random() % 50 + 10)];
        [bonequakeDot setTitle:@"bonequake-dot"];
        [bonequakeDot setSpriteName:@"bleeding.png"];
        [bonequakeDot setOwner:self.owner];
        [member addEffect:bonequakeDot];
        [bonequakeDot release];
    }
    
}
@end

@implementation OverseerProjectiles
- (void)dealloc {
    
    [super dealloc];
}

- (id)init {
    if (self = [super init]){
        [self setAllProjectileUsability:YES];
    }
    return self;
}

- (void)setAllProjectileUsability:(BOOL)isUsable {
    for (int i = 0; i < OverseerProjectileTypeAll; i++){
        usableProjectiles[i] = isUsable;
    }
}

- (void)setProjectileType:(OverseerProjectileType)type isUsable:(BOOL)isUsable {
    usableProjectiles[type] = isUsable;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    NSArray *spriteNames = @[@"fireball.png", @"purple_fireball.png", @"blood_ball.png"];
    NSArray *collisionParticleNames = @[@"fire_explosion.plist", @"shadow_burst.plist", @"blood_spurt.plist"];
    NSMutableArray *possibleBolts = [NSMutableArray arrayWithCapacity:OverseerProjectileTypeAll];
    for (int i = 0; i < OverseerProjectileTypeAll; i++){
        if (usableProjectiles[i]){
            [possibleBolts addObject:[NSNumber numberWithInt:i]];
        }
    }
    
    NSInteger boltTypeRoll = [[possibleBolts objectAtIndex:arc4random() % possibleBolts.count] intValue];
    RaidMember *target = [theRaid randomLivingMember];
    NSTimeInterval colTime = 1.75;
    
    DelayedHealthEffect *boltEffect = [[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
    [boltEffect setOwner:self.owner];
    [boltEffect setFailureChance:.15];
    [boltEffect setIsIndependent:YES];

    NSInteger damage = (arc4random() % ABS(self.abilityValue) + ABS((self.abilityValue / 2)));
    Effect *appliedEffect = nil;
    
    switch (boltTypeRoll) {
        case OverseerProjectileFire:
            [boltEffect setTitle:@"firebolt"];  
            break;
        case OverseerProjectileShadow:
            [boltEffect setTitle:@"shadowbolt"];
            appliedEffect = [[RepeatedHealthEffect alloc] initWithDuration:6.0 andEffectType:EffectTypeNegative];
            [appliedEffect setTitle:@"shadowbolt-dot"];
            [appliedEffect setSpriteName:@"shadow_curse.png"];
            [(RepeatedHealthEffect*)appliedEffect setNumOfTicks:6];
            [(RepeatedHealthEffect*)appliedEffect setValuePerTick:-damage * .15];
            [appliedEffect setOwner:self.owner];
            [appliedEffect setAilmentType:AilmentCurse];
            damage *= .45;
            break;
        case OverseerProjectileBlood:
            [boltEffect setTitle:@"bloodbolt"];
            appliedEffect = [[HealingDoneAdjustmentEffect alloc] initWithDuration:8.0 andEffectType:EffectTypeNegative];
            [appliedEffect setSpriteName:@"blood_curse.png"];
            [appliedEffect setTitle:@"blood-curse"];
            [appliedEffect setOwner:self.owner];
            [appliedEffect setAilmentType:AilmentCurse];
            [(HealingDoneAdjustmentEffect*)appliedEffect setPercentageHealingReceived:.25];
            damage *= .78;
            break;
        default:
            break;
    }
    [boltEffect setValue:-damage];
    if (appliedEffect){
        [boltEffect setAppliedEffect:appliedEffect];
        [appliedEffect release];
    }
    [target addEffect:boltEffect];
    [boltEffect release];

    
    ProjectileEffect *projVisual = [[ProjectileEffect alloc] initWithSpriteName:[spriteNames objectAtIndex:boltTypeRoll] target:target andCollisionTime:colTime];
    [projVisual setCollisionParticleName:[collisionParticleNames objectAtIndex:boltTypeRoll]];
    [[(Boss*)self.owner announcer] displayProjectileEffect:projVisual];
    [projVisual release];
}
@end

@implementation BloodMinion
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"A vile creature made of flowing blood.  This creature reduces all healing done to allies by 25% and causes random allies to hemorrhage their lifeforce away."];
        [desc setAbilityName:@"Minion of Blood"];
        [desc setIconName:@"blood_minion_ability.png"];
        self.descriptor = [desc autorelease];
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    
    for (RaidMember *member in theRaid.getAliveMembers){
        HealingDoneAdjustmentEffect *reducedHealingDone = [[HealingDoneAdjustmentEffect alloc] initWithDuration:(self.cooldown - .1) andEffectType:EffectTypeNegativeInvisible];
        [reducedHealingDone setOwner:self.owner];
        [reducedHealingDone setTitle:@"blood-minion-healing-debuff"];
        [reducedHealingDone setPercentageHealingReceived:.75];
        [member addEffect:reducedHealingDone];
        [reducedHealingDone release];
        
        if (arc4random() % 100 < 20){
            RepeatedHealthEffect *bleed = [[RepeatedHealthEffect alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative];
            [bleed setSpriteName:@"bleeding.png"];
            [bleed setValuePerTick:-self.abilityValue];
            [bleed setNumOfTicks:5];
            [bleed setOwner:self.owner];
            [bleed setTitle:@"blood-minion-bleed"];
            [member addEffect:bleed];
            [bleed autorelease];
        }
    }
    
}
@end

@implementation FireMinion
- (id)init {
    if (self = [super init]) {
        self.attackParticleEffectName = @"fire_explosion.plist";
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"A soulless tormentor of living flame.  The heat from this creature burns all allies while it occasionally blasts enemies with a burst of immolation."];
        [desc setAbilityName:@"Minion of Flame"];
        [desc setIconName:@"fire_minion_ability.png"];
        self.descriptor = [desc autorelease];
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    for (RaidMember *member in theRaid.getAliveMembers){
        RepeatedHealthEffect *burning = [[RepeatedHealthEffect alloc] initWithDuration:self.cooldown - .1 andEffectType:EffectTypeNegativeInvisible];
        [burning setValuePerTick:-20];
        [burning setNumOfTicks:8];
        [burning setOwner:self.owner];
        [burning setTitle:@"fire-minion-burn"];
        [member addEffect:burning];
        [burning autorelease];
    }
    
    //Blast
    RaidMember *blastTarget = [theRaid randomLivingMember];
    [self damageTarget:blastTarget];
}
@end

@implementation ShadowMinion

- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"A viscious being of pure darkness.  This creature drains energy from Healers each time they cast a spell and casts a viscious curse on random allies."];
        [desc setAbilityName:@"Minion of Shadow"];
        [desc setIconName:@"shadow_minion_ability.png"];
        self.descriptor = [desc autorelease];
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    for (Player *player in players) {
        EnergyAdjustmentPerCastEffect *shadowDrain = [[EnergyAdjustmentPerCastEffect alloc] initWithDuration:self.cooldown andEffectType:EffectTypeNegative];
        [shadowDrain setEnergyChangePerCast:10];
        [shadowDrain setOwner:self.owner];
        [shadowDrain setTitle:@"shadow-drain"];
        [player addEffect:shadowDrain];
        [shadowDrain release];
    }
    
    RaidMember *lowestHealthMember = [theRaid lowestHealthMember];
    [[(Boss*)self.owner announcer] displayParticleSystemWithName:@"shadow_burst.plist" onTarget:lowestHealthMember];
    RepeatedHealthEffect *shadowCurse = [[RepeatedHealthEffect alloc] initWithDuration:6.0 andEffectType:EffectTypeNegative];
    [shadowCurse setTitle:@"shadow-blast"];
    [shadowCurse setSpriteName:@"shadow_curse.png"];
    [shadowCurse setNumOfTicks:7];
    [shadowCurse setValuePerTick:-self.abilityValue];
    [shadowCurse setOwner:self.owner];
    [shadowCurse setAilmentType:AilmentCurse];
    [lowestHealthMember addEffect:shadowCurse];
    [shadowCurse release];
    
}
@end

@implementation RaidApplyEffect
- (void)dealloc {
    [_appliedEffect release];
    [super dealloc];
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    if ([self checkFailed]){
        return;
    }
    for (RaidMember *member in theRaid.getAliveMembers){
        Effect *appliedEffect = [[self.appliedEffect copy] autorelease];
        [appliedEffect setOwner:self.owner];
        [member addEffect:appliedEffect];
    }
}
@end

@implementation OozeRaid
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"As your allies hack their way through the filth beast they become covered in a disgusting slime.  If this slime builds to 5 stacks on any ally that ally will be instantly slain.  Whenever an ally receives healing from you the slime is removed."];
        [desc setAbilityName:@"Engulfing Slime"];
        [desc setIconName:@"engulfing_slime_ability.png"];
        self.descriptor = [desc autorelease];
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [super triggerAbilityForRaid:theRaid andPlayers:players];
    self.cooldown = self.originalCooldown * (theRaid.getAliveMembers.count / 20.0);
}
@end

@implementation OozeTwoTargets

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {    
    NSArray *targets = [theRaid lowestHealthTargets:2 withRequiredTarget:nil];
    NSInteger numApplications = arc4random() % 3 + 2;

    for (RaidMember *target in targets){
        for (int i = 0; i < numApplications; i++){
            NSTimeInterval delay = 0.25 + (i * 1.5);
            DelayedHealthEffect *delayedSlime = [[DelayedHealthEffect alloc] initWithDuration:delay andEffectType:EffectTypeNegativeInvisible];
            [delayedSlime setValue:-70];
            [delayedSlime setIsIndependent:YES];
            [delayedSlime setTitle:@"delayed-slime"];
            [delayedSlime setOwner:self.owner];
            [delayedSlime setAppliedEffect:[EngulfingSlimeEffect defaultEffect]];
            [target addEffect:delayedSlime];
            [delayedSlime release];
        }
    }
    
}
@end

@implementation GraspOfTheDamned
- (id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd {
    if (self = [super initWithDamage:dmg andCooldown:cd]){
        AbilityDescriptor *graspOfTheDamnedDesc = [[[AbilityDescriptor alloc] init] autorelease];
        [graspOfTheDamnedDesc setAbilityName:@"Grasp of the Damned"];
        [graspOfTheDamnedDesc setAbilityDescription:@"Periodically a curse is applied to an ally that deals damage over time and will explode if the ally receives any healing"];
        [self setDescriptor:graspOfTheDamnedDesc];
        [self setTitle:@"grasp-of-the-damned"];
    }
    return self;
}

- (RaidMember*)targetFromRaid:(Raid *)raid
{
    RaidMember *target = nil;
    for (int i = 0; i < 20; i++){
        target = [raid randomLivingMember];
        if (!target.isFocused && [target effectCountOfType:EffectTypePositive] == 0){
            break;
        }
    }
    return target;
}
@end

@implementation SoulPrison

- (id)init{
    if (self = [super init]){
        AbilityDescriptor *descriptor = [[[AbilityDescriptor alloc] init] autorelease];
        [descriptor setIconName:@"soul_prison_ability.png"];
        [descriptor setAbilityName:@"Soul Prison"];
        [descriptor setAbilityDescription:@"Emprisons an ally's soul in unimaginable torment reducing them to just shy of death but preventing all damage done to them.  When the effect expires the soul prison attempts to finish its prisoner with a small amount of damage."];
        [self setDescriptor:descriptor];
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    NSInteger numTargets = self.abilityValue + (arc4random() % 4 - 2);
    NSTimeInterval duration = numTargets * 2;

    for (int i = 0; i < numTargets; i++){
        
        SoulPrisonEffect *spe = [[[SoulPrisonEffect alloc] initWithDuration:duration andEffectType:EffectTypeNegative] autorelease];
        RaidMember *target = [theRaid randomLivingMember];
        
        NSMutableArray *effectsToRemove = [NSMutableArray arrayWithCapacity:3];
        for (Effect *effect in target.activeEffects){
            if (effect.effectType == EffectTypePositive){
                [effectsToRemove addObject:effect];
            }
        }
        for (Effect* effect in effectsToRemove){
            [effect effectWillBeDispelled:theRaid player:[players objectAtIndex:0]];
            [effect expire];
            [target removeEffect:effect];
        }
        
        Boss *bossOwner = (Boss*)self.owner;
        NSInteger targetHealth = target.health;
        [target setHealth:1];
        [bossOwner.logger logEvent:[CombatEvent eventWithSource:bossOwner target:target value:[NSNumber numberWithInt:targetHealth-1] andEventType:CombatEventTypeDamage]];
        
        [spe setOwner:self.owner];
        [target addEffect:spe];
    }
}

@end

@implementation DisruptionCloud

- (id)init{
    if (self = [super init]){
        AbilityDescriptor *descriptor = [[[AbilityDescriptor alloc] init] autorelease];
        [descriptor setAbilityName:@"Disruption Cloud"];
        [descriptor setAbilityDescription:@"A veil of noxious gas fills the realm causing spells to take 40% longer to cast and allies to take moderate damage."];
        [self setDescriptor:descriptor];
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    NSTimeInterval duration = 10.0;
    Boss *bossOwner = (Boss*)self.owner;
    [bossOwner.announcer displayParticleSystemOnRaidWithName:@"red_mist.plist" forDuration:duration];
    for (Player *player in players){
        Effect *disruptionCastTimeEffect = [[[Effect alloc] initWithDuration:duration andEffectType:EffectTypeNegative] autorelease];
        [disruptionCastTimeEffect setTitle:@"disruption-cast-time"];
        [disruptionCastTimeEffect setOwner:self.owner];
        [disruptionCastTimeEffect setCastTimeAdjustment:-.4];
        [player addEffect:disruptionCastTimeEffect];
    }
    
    NSArray *livingMembers = [theRaid getAliveMembers];
    for (RaidMember *member in livingMembers){
        RepeatedHealthEffect *disruptionEffect = [[[RepeatedHealthEffect alloc] initWithDuration:duration andEffectType:EffectTypeNegativeInvisible] autorelease];
        [disruptionEffect setTitle:@"disruption-dmg"];
        [disruptionEffect setValuePerTick:-self.abilityValue];
        [disruptionEffect setOwner:self.owner];
        [disruptionEffect setNumOfTicks:duration / 1];
        [member addEffect:disruptionEffect];
    }
    
}

@end

@implementation Confusion
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *descriptor = [[[AbilityDescriptor alloc] init] autorelease];
        [descriptor setAbilityName:@"Confusion"];
        [descriptor setAbilityDescription:@"You will suffer periodic confusion causing some allies to become lost to your senses from a short period of time."];
        [self setDescriptor:descriptor];
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    for (Player *player in players){
        Effect *confusionEffect = [[[Effect alloc] initWithDuration:self.abilityValue andEffectType:EffectTypeNegative] autorelease];
        [confusionEffect setTitle:@"confusion-eff"];
        [confusionEffect setCausesConfusion:YES];
        [confusionEffect setOwner:self.owner];
        [player addEffect:confusionEffect];        
    }
}
@end

@implementation DisorientingBoulder
- (id)init {
    if (self = [super init]){
        self.effectType = ProjectileEffectTypeThrow;
        self.spriteName = @"rock.png";
        self.explosionParticleName = nil;
        Effect *disorient = [[[Effect alloc] initWithDuration:8.0 andEffectType:EffectTypeNegative] autorelease];
        [disorient setTitle:@"disorient-effect"];
        [disorient setDamageTakenMultiplierAdjustment:.25];
        [disorient setSpriteName:@"fallen-down.png"];
        self.appliedEffect = disorient;
        
        AbilityDescriptor *abilityDescriptor = [[[AbilityDescriptor alloc] init] autorelease];
        [abilityDescriptor setAbilityName:@"Disorienting Boulder"];
        [abilityDescriptor setAbilityDescription:@"Throws a Boulder dealing moderate damage and causing the target to take 25% increased damage for a 8.0 seconds."];
        self.descriptor = abilityDescriptor;
        
        self.cooldown = 15.0;
        self.abilityValue = 300;
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    [super triggerAbilityForRaid:theRaid andPlayers:players];
    self.cooldown = arc4random() % 8 + 8;
}
@end

@implementation Cleave
+ (Cleave *)normalCleave {
    Cleave *cleave = [[[Cleave alloc] init] autorelease];
    [cleave setTitle:@"cleave"];
    [cleave setAbilityValue:600];
    [cleave setCooldown:12.5];
    [cleave setFailureChance:.4];
    return cleave;
}
+ (Cleave *)hardCleave {
    Cleave *cleave = [[[Cleave alloc] init] autorelease];
    [cleave setTitle:@"cleave"];
    [cleave setAbilityValue:800];
    [cleave setCooldown:11.5];
    [cleave setFailureChance:.35];
    return cleave;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    NSMutableArray *meleeTargets = [NSMutableArray arrayWithArray:[theRaid livingMembersWithPositioning:Melee]];
    Guardian *guardianTarget = nil;
    
    NSInteger additionalTargets = 0;
    NSInteger roll = arc4random() % 1000;
    if (roll < 10) {
        additionalTargets = meleeTargets.count;
    } else if (roll < 25) {
        additionalTargets = 5;
    } else if (roll < 75) {
        additionalTargets = 4;
    } else if (roll < 150) {
        additionalTargets = 3;
    } else if (roll < 250) {
        additionalTargets = 2;
    } else if (roll < 400) {
        additionalTargets = 1;
    }
    
    // 25% 1 target, 50% No Targets, 10% 2 targets, 10% 3 targets, 10% 4 targets, 4% 5 targets, 1% all targets 
    for (RaidMember *target in meleeTargets) {
        if (!guardianTarget && [target isKindOfClass:[Guardian class]]) {
            guardianTarget = (Guardian*)target;
            break;
        }
    }
    
    NSInteger guardianDamage = self.abilityValue * .25 * self.owner.damageDoneMultiplier;
    NSInteger normalDamage = self.abilityValue * self.owner.damageDoneMultiplier;
    
    [meleeTargets removeObject:guardianTarget];
    
    for (int i = 0; i < additionalTargets; i++) {
        if (meleeTargets.count == 0) {
            break;
        }
        RaidMember *target = [meleeTargets objectAtIndex:arc4random() % meleeTargets.count];
        if ([target isKindOfClass:[Guardian class]]) {
            [self damageTarget:target forDamage:guardianDamage];
        } else {
            [self damageTarget:target forDamage:normalDamage];
        }
        [meleeTargets removeObject:target];

    }
    
    [self damageTarget:guardianTarget forDamage:guardianDamage];
    
}
@end

@implementation RaidDamagePulse

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    NSArray *targets = [theRaid getAliveMembers];
    
    for (RaidMember *member in targets) {
        RepeatedHealthEffect *damage = [[[RepeatedHealthEffect alloc] initWithDuration:self.duration andEffectType:EffectTypeNegativeInvisible] autorelease];
        [damage setOwner:self.owner];
        [damage setTitle:[NSString stringWithFormat:@"%@-%i-pulse", self.owner.sourceName, arc4random() % 20]];
        [damage setNumOfTicks:self.numTicks];
        [damage setValuePerTick:-(self.abilityValue/self.numTicks)];
        [member addEffect:damage];
    }
}

@end
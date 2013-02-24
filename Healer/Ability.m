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
#import "Enemy.h"
#import "Effect.h"
#import "Spell.h"
#import "CombatEvent.h"
#import "AbilityDescriptor.h"

@interface Ability ()
@end

@implementation Ability

- (id)init {
    if (self = [super init]){
        self.attackParticleEffectName = @"blood_spurt.plist";
        self.isActivating = NO;
        self.iconName = @"unknown_ability.png";
    }
    return self;
}

- (id)copy {
    Ability *ab = [[[self class] alloc] init];
    [ab setFailureChance:self.failureChance];
    [ab setCooldown:self.cooldown];
    [ab setKey:self.key];
    [ab setOwner:self.owner];
    [ab setAbilityValue:self.abilityValue];
    [ab setCooldownVariance:self.cooldownVariance];
    [ab setChannelTimeRemaining:self.channelTimeRemaining];
    [ab setTitle:self.title];
    [ab setInfo:self.info];
    [ab setIconName:self.iconName];
    return ab;
}
- (void)dealloc{
    [_info release];
    [_title release];
    [_key release];
    [_iconName release];
    [_attackParticleEffectName release];
    [super dealloc];
}

- (AbilityDescriptor *)descriptor
{
    if (self.title && self.info) {
        AbilityDescriptor *ad = [[[AbilityDescriptor alloc] init] autorelease];
        [ad setAbilityName:self.title];
        [ad setAbilityDescription:self.info];
        [ad setIconName:self.iconName];
        return ad;
    }
    return nil;
}

- (BOOL)isChanneling
{
    return self.channelTimeRemaining > 0;
}

- (void)setChannelTimeRemaining:(float)channelTimeRemaining
{
    _channelTimeRemaining = MAX(0, channelTimeRemaining);
}

- (void)startChannel:(float)channel
{
    self.channelTimeRemaining = channel;
    self.maxChannelTime = channel;
}

- (BOOL)checkFailed{
    BOOL failed = arc4random() % 100 < (100 * self.failureChance);
    if (failed){
        return YES;
    }
    return NO;
}

- (NSTimeInterval)cooldown
{
    return self.activationTime + _cooldown;
}


- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    self.timeApplied += timeDelta;
    if (!self.owner.visibleAbility || self.owner.visibleAbility == self || self.ignoresBusy) {
        if ((_cooldown != kAbilityRequiresTrigger || self.isActivating) && self.timeApplied >= self.cooldown){
            if (!self.isDisabled){
                [self.owner ownerWillExecuteAbility:self];
                [self triggerAbilityForRaid:raid andPlayers:players];
                [self.owner ownerDidExecuteAbility:self];
            }
            self.timeApplied = 0.0 + self.cooldown * self.cooldownVariance * (arc4random() % 1000 / 1000.0);
            self.isActivating = NO;
        } else if (self.activationTime > 0 && !self.isActivating && self.cooldown - self.activationTime <= self.timeApplied) {
            [self activateAbility];
        }
    } else {
        //This ability is on hold because another ability is activating
        self.timeApplied = MIN(self.timeApplied,_cooldown);
        self.channelTimeRemaining = 0; //Channeled abilities are interrupted if another ability is activating.
    }
    self.channelTimeRemaining -= timeDelta;
}

- (void)activateAbility
{
    self.timeApplied = _cooldown;
    self.isActivating = YES;
    [self.owner ownerDidBeginAbility:self];
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
    
    float criticalChance = self.owner.criticalChance;
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
            [self.owner.announcer displayParticleSystemWithName:self.attackParticleEffectName onTarget:target];
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
        self.cooldownVariance = .1;
    }
    return self;
}

- (RaidMember*)targetFromRaid:(Raid*)raid{
    return self.ignoresGuardians ? raid.randomNonGuardianLivingMember : [raid randomLivingMember];
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    if ([self checkFailed]){
        return;
    }
    RaidMember *target = [self targetFromRaid:theRaid];
    if (target.isFocused){
        return; //We fail when trying to hit tanks with attacks
    }
    NSInteger preHealth = target.health;
    [self damageTarget:target];
    if (self.appliedEffect && (preHealth > target.health || !self.requiresDamageToApplyEffect) ){
        //Only apply the effect if we actually did damaww ge.
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
        RaidMember *candidate = nil;
        NSInteger safety = 0;
        while (!candidate && safety < 20) {
            candidate = [super targetFromRaid:raid];
            if (candidate.isFocused) {
                candidate = nil;
            }
            safety++;
        }
        self.currentTarget = candidate;
        [self.currentTarget setIsFocused:YES];
    }
    
    return self.currentTarget;
}

@end

@implementation FocusedAttack

- (void)dealloc{
    [_focusTarget release];
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
    for (RaidMember *member in raid.livingMembers){
        if ([member isKindOfClass:[Guardian class]] && !member.isFocused){
            mainTank = member;
            break;
        }
    }
    //Otherwise find a focused guardian
    if (!mainTank){
        for (RaidMember *member in raid.livingMembers){
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
    return [self mainTankFromRaid:raid];
}

- (void)setIsDisabled:(BOOL)newIsDisabled {
    [super setIsDisabled:newIsDisabled];
    if (self.focusTarget){
        [self.focusTarget setIsFocused:!newIsDisabled];
    }
}

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (!self.focusTarget){
        self.focusTarget = [self mainTankFromRaid:raid];
        [self.focusTarget setIsFocused:YES];
    }
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    if ([self checkFailed]){
        return;
    }
    RaidMember *target = [self targetFromRaid:theRaid];
    NSInteger preHealth = target.health + target.absorb;
    [self damageTarget:target];
    if (self.appliedEffect && preHealth > target.health + target.absorb){
        Effect *applyThis = [[self.appliedEffect copy] autorelease];
        [applyThis setOwner:self.owner];
        [target addEffect:applyThis];
    }
    if (self.focusTarget.isDead){
        self.focusTarget = [self targetFromRaid:theRaid];
        if (!self.enrageApplied && ![self.focusTarget isKindOfClass:[Guardian class]]){
            self.abilityValue *= 3;
            [self.owner.announcer announce:[NSString stringWithFormat:@"%@ glows with power after defeating all of your Guardians", self.owner.namePlateTitle]];
            
            AbilityDescriptor *glowingPower = [[[AbilityDescriptor alloc] init] autorelease];
            [glowingPower setAbilityDescription:@"After defeating all Guardians, this enemy becomes unstoppable and will deal vastly increased damage."];
            [glowingPower setAbilityName:@"Glowing with Power"];
            [glowingPower setIconName:@"unknown_ability.png"];
            [self.owner addAbilityDescriptor:glowingPower];
            self.enrageApplied = YES;
        }
    } else {
        if ([self.focusTarget isKindOfClass:[Guardian class]]) {
            [self.focusTarget setIsFocused:YES];
        }
    }
}
@end

@implementation ProjectileAttack

- (id)init
{
    if (self = [super init]){
        self.explosionParticleName = @"fire_explosion.plist";
        self.cooldownVariance = .1;
        self.projectileColor = ccWHITE;
        self.attacksPerTrigger = 1;
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
    [fbCopy setAttacksPerTrigger:self.attacksPerTrigger];
    [fbCopy setProjectileColor:self.projectileColor];
    return fbCopy;
}

- (void)fireAtTarget:(RaidMember*)target
{
    BOOL didFail = self.checkFailed;
    NSTimeInterval colTime = 1.75;
    
    ProjectileEffect *fireballVisual = [[ProjectileEffect alloc] initWithSpriteName:self.spriteName target:target andCollisionTime:colTime];
    [fireballVisual setCollisionParticleName:self.explosionParticleName];
    [fireballVisual setIsFailed:didFail];
    [fireballVisual setSpriteColor:self.projectileColor];
    fireballVisual.type = self.effectType;
    [[self.owner announcer] displayProjectileEffect:fireballVisual];
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

- (void) triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    for (int i = 0; i < self.attacksPerTrigger; i++) {
        RaidMember *target = self.ignoresGuardians ? theRaid.randomNonGuardianLivingMember : [theRaid randomLivingMember];
        [self fireAtTarget:target];
    }

}

- (void)fireAtRaid:(Raid*)raid
{
    for (RaidMember *member in raid.livingMembers) {
        [self fireAtTarget:member];
    }
}

@end

@implementation GroundSmash
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    NSInteger tickDamage = -self.abilityValue;
    NSInteger numberOfTicks = 6;
    
    numberOfTicks += arc4random() % 6;
    
    NSTimeInterval delayPerTick = .5;
    float effectDuration = numberOfTicks * delayPerTick;
    
    for (RaidMember *member in theRaid.livingMembers) {
        tickDamage = FUZZ(tickDamage, 25.0);
        
        RepeatedHealthEffect *caveInDoT = [[[RepeatedHealthEffect alloc] initWithDuration:effectDuration andEffectType:EffectTypeNegativeInvisible] autorelease];
        [caveInDoT setTitle:@"channeled-raid-damage"];
        [caveInDoT setValuePerTick:tickDamage];
        [caveInDoT setNumOfTicks:numberOfTicks];
        [caveInDoT setOwner:self.owner];
        [member addEffect:caveInDoT];
    }
        
    for (int i = 0; i < numberOfTicks; i++) {
        [self.owner.announcer displayParticleSystemOnRaidWithName:@"ground_dust.plist" delay:(i+1)*delayPerTick offset:CGPointMake(0, -200)];
        [self.owner.announcer displayScreenShakeForDuration:.33 afterDelay:(i+1)*delayPerTick];
    }
    [self startChannel:numberOfTicks * delayPerTick];
}
@end

@implementation  StackingDamage

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players{
    Effect *damageBooster = [[Effect alloc] initWithDuration:99999 andEffectType:EffectTypePositiveInvisible];
    [damageBooster setTarget:self.owner];
    [damageBooster setOwner:self.owner];
    [damageBooster setDamageDoneMultiplierAdjustment:(self.abilityValue / 100.0)];
    [self.owner addEffect:damageBooster];
    [damageBooster release];
}
@end

@implementation BaraghastBreakOff
- (void)dealloc {
    [_ownerAutoAttack release];
    [super dealloc];
}
- (id)init {
    if (self = [super init]){
        self.title = @"Disengage";
        self.info = @"Baraghast ignores his focused target and attacks a random ally instead.";
        self.iconName = @"unknown_ability.png";
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
    
    NSArray *aliveMembers = theRaid.livingMembers;
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
        self.info = @"Interrupts spell casting, dispels all positive spell effects, and deals moderate damage to all allies.";
        self.iconName = @"unknown_ability.png";
        self.title = @"Warlord's Roar";
        [self setActivationTime:1.0];
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [[self.owner announcer] displayScreenShakeForDuration:.4];
    for (Player *player in players) {
        if ([player spellBeingCast]){
            [[player spellBeingCast] applyTemporaryCooldown:2.0];
        }
        [player interrupt];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:player value:[NSNumber numberWithFloat:2.0]  andEventType:CombatEventTypePlayerInterrupted]];
    }
    for (RaidMember *member in theRaid.raidMembers ){
        [member setHealth:member.health - (125.0 * self.owner.damageDoneMultiplier)];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:[NSNumber numberWithInt:(150.0 * self.owner.damageDoneMultiplier)]  andEventType:CombatEventTypeDamage]];
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
- (id)init {
    if (self = [super init]){
        self.info = @"Deals moderate damage to affected targets and prevents them from dealing any damage until they are healed to full health.";
        self.title = @"Debilitate";
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
- (id)init {
    if (self = [super init]){
        self.info = @"After 5 seconds a massive strike lands on the affected target dealing very high damage.";
        self.title = @"Crush";
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
        [[self.owner announcer] announce:[NSString stringWithFormat:@"%@ prepares to land a massive strike!", [self.owner title]]];
        DelayedHealthEffect *crushEffect = [[DelayedHealthEffect alloc] initWithDuration:5 andEffectType:EffectTypeNegative];
        [crushEffect setOwner:self.owner];
        [crushEffect setTitle:@"crush"];
        [crushEffect setSpriteName:@"crush.png"];
        [crushEffect setValue:-950];
        [self.target addEffect:crushEffect];
        [crushEffect release];
    }
}
@end

@implementation Deathwave
- (id)init {
    if (self = [super init]){
        self.info = @"Deals extremely high damage to all living allies.  The damage is divided by the number of living allies.";
        self.title = @"Deathwave";
        self.abilityValue = 10000;
        [self setActivationTime:3.5];

    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [[self.owner announcer] displayScreenShakeForDuration:1.0];
    [[self.owner announcer] displayParticleSystemOnRaidWithName:@"death_ring.plist" forDuration:2.0];

    NSInteger livingMemberCount = theRaid.livingMembers.count;
    for (RaidMember *member in theRaid.livingMembers){
        NSInteger deathWaveDamage = (int)round((float)self.abilityValue / livingMemberCount);
        deathWaveDamage *= (arc4random() % 50 + 50) / 100.0;
        deathWaveDamage *= self.owner.damageDoneMultiplier;
        [member setHealth:member.health - deathWaveDamage];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:[NSNumber numberWithInt:deathWaveDamage] andEventType:CombatEventTypeDamage]];
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
    
    AlternatingFlame *sweepingFlame = [[[AlternatingFlame alloc] init] autorelease];
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
    NSArray *allAbilities = [RandomAbilityGenerator allAbilities];
    Ability *randomAbility =  [allAbilities objectAtIndex:arc4random() % allAbilities.count];
    [self.managedAbilities addObject:randomAbility];
    [self.owner addAbility:randomAbility];
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    if (self.managedAbilities.count == self.maxAbilities){
        Ability *abilityToRemove = [self.managedAbilities objectAtIndex:(arc4random() % self.managedAbilities.count)];
        [self.owner removeAbility:abilityToRemove];
        [self.managedAbilities removeObject:abilityToRemove];
    }
    
    [self addRandomAbility];
    
}
@end

@implementation InvertedHealing
- (id)copy {
    InvertedHealing *copy = [super copy];
    [copy setNumTargets:self.numTargets];
    return copy;
}

- (id)init {
    if (self = [super init]){
        self.info = @"Any healing done is instead converted into damage to the affected target.";
        self.title = @"Spiritual Inversion";
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
        self.info = @"Deals moderate damage over time to its target and any healing done to an affected target will burn 75 Mana from the Healer.";
        self.title = @"Soul Burn";
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
- (void)dealloc {
    [_abilityToGain release];
    [super dealloc];
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    Ability *newAbility = [self.abilityToGain copy];
    [self.owner addAbility:newAbility];
    [newAbility release];
}
@end

@implementation RaidDamage

- (void)dealloc
{
    [_appliedEffect release];
    [super dealloc];
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    NSArray *livingMembers = theRaid.livingMembers;
    
    for (RaidMember *member in livingMembers){
        NSInteger damage = self.abilityValue * self.owner.damageDoneMultiplier;
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member  value:[NSNumber numberWithInt:damage] andEventType:CombatEventTypeDamage]];
        [member setHealth:member.health - damage];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member  value:[NSNumber numberWithInt:damage] andEventType:CombatEventTypeDamage]];
        if (self.appliedEffect){
            Effect *applyThis = [[self.appliedEffect copy] autorelease];
            [applyThis setOwner:self.owner];
            [member addEffect:applyThis];
        }
    }
}
@end

@implementation Grip
- (id)init {
    if (self = [super init]){
        self.info = @"A random player will be strangled by dark magic reducing healing done by 98% and dealing damage over time.";
        self.iconName = @"grip_ability.png";
        self.title = @"Grip of Delsarn";
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
        self.info = @"Periodically a random player will be dealt high damage and begin bleeding severely for several seconds.";
        self.iconName = @"bleeding_ability.png";
        self.title = @"Impale";
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
        self.info = @"The Gatekeeper has summoned Blood Drinkers to its side.  These vicious beasts will attack a Guardian and heal the Gatekeeper for a substantial amount of they are successful in vanquishing their target.";
        self.title = @"Blood Drinker";
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
        [self.owner setHealth:self.owner.health + self.owner.maximumHealth * .1];
        [self.owner.announcer announce:[NSString stringWithFormat:@"A Blood Drinker heals %@ upon defeating its foe.", self.owner.title]];
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
        if (self.appliedEffect) {
            Effect *eff = [[self.appliedEffect copy] autorelease];
            [eff setOwner:self.owner];
            [target addEffect:eff];
        }
    }
}
@end

@implementation BoneThrow

- (id)init {
    if (self = [super init]){
        self.info = @"Hurls a bone at a target dealing moderate damage and causing the target to be knocked to the ground.  Targets knocked to the ground will deal no damage until they are healed.";
        self.iconName = @"bone_throw_ability.png";
        self.title = @"Bone Throw";
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
    [[self.owner announcer] displayProjectileEffect:boneVisual];
    [boneVisual release];
}
@end

@implementation AlternatingFlame

- (id)init {
    if (self = [super init]){
        self.info = @"Deals heavy fire damage to targets positioned close together.";
        self.iconName = @"unknown_ability.png";
        self.title = @"Breath of Flame";
        self.targetPositioningType = Melee;
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [super triggerAbilityForRaid:theRaid andPlayers:players];
    if (self.targetPositioningType == Ranged) {
        self.targetPositioningType = Melee;
    } else {
        self.targetPositioningType = Ranged;
    }
}

- (void)willDamageTarget:(RaidMember *)target {
    [[self.owner announcer] displayParticleSystemWithName:@"fire_explosion.plist" onTarget:target];
}
@end

@implementation BoneQuake

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [super triggerAbilityForRaid:theRaid andPlayers:players];
    NSArray *members = theRaid.livingMembers;
    
    NSTimeInterval quakeTime = 3.0;
    
    for (RaidMember *member in members) {
        RepeatedHealthEffect *bonequakeDot = [[RepeatedHealthEffect alloc] initWithDuration:quakeTime andEffectType:EffectTypeNegative];
        [bonequakeDot setNumOfTicks:3];
        [bonequakeDot setValuePerTick:-(arc4random() % 50 + 10)];
        [bonequakeDot setTitle:@"bonequake-dot"];
        [bonequakeDot setSpriteName:@"bleeding.png"];
        [bonequakeDot setOwner:self.owner];
        [member addEffect:bonequakeDot];
        [bonequakeDot release];
    }
    [self startChannel:quakeTime];
    
}
@end

@implementation OverseerProjectiles

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
    [[self.owner announcer] displayProjectileEffect:projVisual];
    [projVisual release];
}
@end

@implementation BloodMinion
- (id)init {
    if (self = [super init]){
        
        self.info = @"A vile creature made of flowing blood.  This creature reduces all healing done to allies by 25% and causes random allies to hemorrhage their lifeforce away.";
        self.title = @"Minion of Blood";
        self.iconName = @"blood_minion_ability.png";
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    
    for (RaidMember *member in theRaid.livingMembers){
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
        
        self.info = @"A soulless tormentor of living flame.  The heat from this creature burns all allies while it occasionally blasts enemies with a burst of immolation.";
        self.title = @"Minion of Flame";
        self.iconName = @"fire_minion_ability.png";
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    for (RaidMember *member in theRaid.livingMembers){
        RepeatedHealthEffect *burning = [[RepeatedHealthEffect alloc] initWithDuration:self.cooldown - .1 andEffectType:EffectTypeNegativeInvisible];
        [burning setValuePerTick:(self.abilityValue * -.05)];
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
        self.info = @"A viscious being of pure darkness.  This creature drains mana from Healers each time they cast a spell and casts a viscious curse on random allies.";
        self.title = @"Minion of Shadow";
        self.iconName = @"shadow_minion_ability.png";
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
    [[self.owner announcer] displayParticleSystemWithName:@"shadow_burst.plist" onTarget:lowestHealthMember];
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
    for (RaidMember *member in theRaid.livingMembers){
        Effect *appliedEffect = [[self.appliedEffect copy] autorelease];
        [appliedEffect setOwner:self.owner];
        [member addEffect:appliedEffect];
    }
}
@end

@implementation OozeRaid
- (id)init {
    if (self = [super init]){
        self.iconName = @"engulfing_slime_ability.png";
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [super triggerAbilityForRaid:theRaid andPlayers:players];
    self.cooldown = MAX(1.0, self.originalCooldown * (theRaid.livingMembers.count / 20.0));
}
@end

@implementation OozeTwoTargets

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {    
    NSArray *targets = [theRaid lowestHealthTargets:2 withRequiredTarget:nil];
    NSInteger numApplications = arc4random() % 3 + 2;
    
    numApplications = MIN(numApplications, self.difficulty + 1);

    for (RaidMember *target in targets){
        [self damageTarget:target];
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
    
    NSTimeInterval totalDelay = 0.25 + (numApplications - 1) * 1.5;
    [self startChannel:totalDelay];
    
}
@end

@implementation GraspOfTheDamned
- (id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd {
    if (self = [super initWithDamage:dmg andCooldown:cd]){
        self.title = @"Grasp of the Damned";
        self.info = @"Periodically a curse is applied to an ally that deals damage over time and will explode if the ally receives any healing";
        [self setKey:@"grasp-of-the-damned"];
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
        self.iconName = @"soul_prison_ability.png";
        self.title = @"Soul Prison";
        self.info = @"Emprisons an ally's soul in unimaginable torment reducing them to just shy of death but preventing all damage done to them.  When the effect expires the soul prison attempts to finish its prisoner with a small amount of damage.";
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
        
        NSInteger targetHealth = target.health;
        [target setHealth:1];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:[NSNumber numberWithInt:targetHealth-1] andEventType:CombatEventTypeDamage]];
        
        [spe setOwner:self.owner];
        [target addEffect:spe];
    }
}

@end

@implementation DisruptionCloud

- (id)init{
    if (self = [super init]){
        self.title = @"Disruption Cloud";
        self.info = @"A veil of noxious gas fills the realm causing spells to take 40% longer to cast and allies to take moderate damage.";
    }
    return self;
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    NSTimeInterval duration = 5.0;
    [self.owner.announcer displayParticleSystemOnRaidWithName:@"red_mist.plist" forDuration:duration];
    for (Player *player in players){
        Effect *disruptionCastTimeEffect = [[[Effect alloc] initWithDuration:duration andEffectType:EffectTypeNegative] autorelease];
        [disruptionCastTimeEffect setTitle:@"disruption-cast-time"];
        [disruptionCastTimeEffect setOwner:self.owner];
        [disruptionCastTimeEffect setCastTimeAdjustment:-.4];
        [player addEffect:disruptionCastTimeEffect];
    }
    
    NSArray *livingMembers = [theRaid livingMembers];
    for (RaidMember *member in livingMembers){
        RepeatedHealthEffect *disruptionEffect = [[[RepeatedHealthEffect alloc] initWithDuration:duration andEffectType:EffectTypeNegativeInvisible] autorelease];
        [disruptionEffect setOwner:self.owner];
        [disruptionEffect setTitle:@"disruption-dmg"];
        [disruptionEffect setValuePerTick:-self.abilityValue];
        [disruptionEffect setOwner:self.owner];
        [disruptionEffect setNumOfTicks:duration / 1];
        [member addEffect:disruptionEffect];
    }
    [self startChannel:duration];
}

@end

@implementation Confusion
- (id)init {
    if (self = [super init]){
        self.title = @"Confusion";
        self.info = @"You will suffer periodic confusion causing some allies to become lost to your senses from a short period of time.";
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
        
        self.title = @"Disorienting Boulder";
        self.info = @"Throws a Boulder dealing moderate damage and causing the target to take 25% increased damage for a 8.0 seconds.";
        
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
    [cleave setTitle:@"Wide Swing"];
    [cleave setInfo:@"Attacks with a chance to deal high damage to all melee range enemies."];
    [cleave setKey:@"cleave"];
    [cleave setActivationTime:1.0];
    [cleave setAbilityValue:400];
    [cleave setCooldown:12.0];
    [cleave setFailureChance:.4];
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
            NSInteger finalValue = FUZZ(guardianDamage, 50);
            [self damageTarget:target forDamage:finalValue];
        } else {
            NSInteger finalValue =FUZZ(normalDamage, 50);
            [self damageTarget:target forDamage:finalValue];
        }
        [meleeTargets removeObject:target];

    }
    
    [self damageTarget:guardianTarget forDamage:FUZZ(guardianDamage, 50)];
    
}
@end

@implementation RaidDamagePulse

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    NSArray *targets = [theRaid livingMembers];
    
    for (RaidMember *member in targets) {
        RepeatedHealthEffect *damage = [[[RepeatedHealthEffect alloc] initWithDuration:self.duration andEffectType:EffectTypeNegativeInvisible] autorelease];
        [damage setOwner:self.owner];
        [damage setTitle:[NSString stringWithFormat:@"%@-%i-pulse", self.owner.sourceName, arc4random() % 20]];
        [damage setNumOfTicks:self.numTicks];
        [damage setValuePerTick:-(self.abilityValue/self.numTicks)];
        [member addEffect:damage];
    }
    [self startChannel:self.duration];
}

@end

@implementation EnsureEffectActiveAbility
- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta;
{
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    if (!self.isDisabled) {
        BOOL hasEffect = NO;
        for (Effect* effect in self.victim.activeEffects){
            if ([effect.title isEqualToString:self.ensuredEffect.title]){
                hasEffect = YES;
                break;
            }
        }
        if (!hasEffect || self.victim.isDead){
            self.victim = [raid randomLivingMember];
            Effect *eff = [self.ensuredEffect copy];
            [eff setOwner:self.owner];
            [self.victim addEffect:[eff autorelease]];
            if (self.isChanneled) {
                [self startChannel:30.0];
            }
        }
    } else {
        if (self.isChanneled) {
            self.channelTimeRemaining = 0.0;
        }
    }
}
@end

@implementation WaveOfTorment
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    NSMutableArray *groups = [NSMutableArray arrayWithCapacity:4];
    for (int i = 0; i < 4; i++) {
        NSMutableArray *group = [NSMutableArray arrayWithCapacity:5];
        for (int j = 5 * i; j < 5 * (i + 1); j++) {
            [group addObject:[theRaid.raidMembers objectAtIndex:j]];
        }
        [groups addObject:group];
    }

    NSTimeInterval delay = 1.25;
    for (int i = 0; i < 4; i++) {
        NSMutableArray *groupToHurt = [groups objectAtIndex:arc4random() % groups.count];
        for (RaidMember *member in groupToHurt) {
            DelayedHealthEffect *wotEffect = [[[DelayedHealthEffect alloc] initWithDuration:0.01 + (delay * i) andEffectType:EffectTypeNegativeInvisible] autorelease];
            [wotEffect setOwner:self.owner];
            [wotEffect setTitle:@"wave-of-torment-dmg"];
            [wotEffect setValue:-self.abilityValue * (1.1 * (i+1))];
            [member addEffect:wotEffect];
            [self.owner.announcer displayParticleSystemWithName:@"shadow_burst.plist" onTarget:member withOffset:CGPointZero delay:0.01 + (delay * i)];
        }
        [groups removeObject:groupToHurt];
    }
    [self startChannel:delay * 4];
}
@end

@implementation StackingEnrage

- (void)setOwner:(Enemy *)owner
{
    [super setOwner:owner];
    
    self.enrageEffect = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible]  autorelease];
    [self.enrageEffect setOwner:owner];
    [self.enrageEffect setTitle:@"enraging"];
    [(HealableTarget*)owner addEffect:self.enrageEffect];
}

- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    self.enrageEffect.damageDoneMultiplierAdjustment += (self.abilityValue / 100.0);
}
@end

@implementation FlameBreath
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    float effectDuration = 5.0;
    NSInteger numberOfTicks = 5;
    [self.owner.announcer displayBreathEffectOnRaidForDuration:effectDuration];
    for (RaidMember *member in theRaid.livingMembers) {
        RepeatedHealthEffect *flameBreathEffect = [[[RepeatedHealthEffect alloc] initWithDuration:effectDuration andEffectType:EffectTypeNegativeInvisible] autorelease];
        [flameBreathEffect setNumOfTicks:numberOfTicks];
        [flameBreathEffect setValuePerTick:-(arc4random() % self.abilityValue/2 + self.abilityValue)];
        [flameBreathEffect setOwner:self.owner];
        [flameBreathEffect setTitle:@"flame-breath-eff"];
        [member addEffect:flameBreathEffect];
    }
    
    [self startChannel:effectDuration];
}
@end

@implementation Earthquake
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    NSInteger tickDamage = -self.abilityValue;
    NSInteger numberOfTicks = 4;
    NSTimeInterval effectDuration = 6.0;
    numberOfTicks += arc4random() % 3;
    
    for (RaidMember *member in theRaid.raidMembers){
        RepeatedHealthEffect *rootquake = [[RepeatedHealthEffect alloc] initWithDuration:effectDuration andEffectType:EffectTypeNegativeInvisible];
        [rootquake setOwner:self.owner];
        [rootquake setValuePerTick:tickDamage];
        [rootquake setNumOfTicks:numberOfTicks];
        [rootquake setTitle:@"rootquake"];
        [member addEffect:[rootquake autorelease]];
    }
    
    [self.owner.announcer displayScreenShakeForDuration:effectDuration afterDelay:0];
    [self startChannel:effectDuration];
}
@end

@implementation RandomPotionToss
- (void)triggerForTarget:(RaidMember*)target inRaid:(Raid*)theRaid
{
    NSInteger possiblePotions = 3;
    if (self.difficulty > 4) {
        possiblePotions = 4;
    }
    int potion = arc4random() % possiblePotions;
    float colTime = 1.5;
    
    if (potion == 0){
        //Liquid Fire
        NSInteger impactDamage = -150;
        NSInteger dotDamage = -200;
        
        DelayedHealthEffect* bottleEffect = [[[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible] autorelease];
        [bottleEffect setValue:impactDamage];
        [bottleEffect setIsIndependent:YES];
        [bottleEffect setOwner:self.owner];
        [target addEffect:bottleEffect];
        
        RepeatedHealthEffect *burnDoT = [[[RepeatedHealthEffect alloc] initWithDuration:12 andEffectType:EffectTypeNegative] autorelease];
        [burnDoT setOwner:self.owner];
        [burnDoT setTitle:@"imp-burn-dot"];
        [burnDoT setSpriteName:@"burning.png"];
        [burnDoT setValuePerTick:dotDamage];
        [burnDoT setNumOfTicks:4];
        [bottleEffect setAppliedEffect:burnDoT];
        
        ProjectileEffect *bottleVisual = [[[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime] autorelease];
        [bottleVisual setSpriteColor:ccc3(255, 0, 0 )];
        [bottleVisual setType:ProjectileEffectTypeThrow];
        [bottleVisual setCollisionParticleName:@"fire_explosion.plist"];
        [self.owner.announcer displayProjectileEffect:bottleVisual];
        
        
    }else if (potion == 1) {
        //Lightning In a Bottle
        DelayedHealthEffect *bottleEffect = [[[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible] autorelease];
        
        ProjectileEffect *bottleVisual = [[[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime] autorelease];
        [bottleVisual setSpriteColor:ccc3(0, 128, 128)];
        [bottleVisual setType:ProjectileEffectTypeThrow];
        [self.owner.announcer displayProjectileEffect:bottleVisual];
        [bottleEffect setIsIndependent:YES];
        [bottleEffect setOwner:self.owner];
        NSInteger damage = FUZZ(-550, 10);
        [bottleEffect setValue:damage];
        [target addEffect:bottleEffect];
    } else if (potion == 2) {
        //Poison explosion
        
        NSInteger impactDamage = FUZZ(-100, 20);
        
        for (RaidMember *member in theRaid.livingMembers) {
            DelayedHealthEffect* bottleEffect = [[[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible] autorelease];
            [bottleEffect setValue:impactDamage];
            [bottleEffect setIsIndependent:YES];
            [bottleEffect setOwner:self.owner];
            [member addEffect:bottleEffect];
        }
        
        ProjectileEffect *bottleVisual = [[[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime] autorelease];
        [bottleVisual setSpriteColor:ccc3(0, 128, 128)];
        [bottleVisual setType:ProjectileEffectTypeThrow];
        [bottleVisual setCollisionParticleName:@"gas_explosion.plist"];
        [self.owner.announcer displayProjectileEffect:bottleVisual];
        
    } else if (potion == 3) {
        //Angry Spirit
        NSInteger impactDamage = -150;
        NSInteger dotDamage = -200;
        
        DelayedHealthEffect* bottleEffect = [[[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible] autorelease];
        [bottleEffect setValue:impactDamage];
        [bottleEffect setIsIndependent:YES];
        [bottleEffect setOwner:self.owner];
        [target addEffect:bottleEffect];
        
        WanderingSpiritEffect *wse = [[[WanderingSpiritEffect alloc] initWithDuration:14.0 andEffectType:EffectTypeNegative] autorelease];
        [wse setAilmentType:AilmentCurse];
        [wse setTitle:@"angry-spirit-effect"];
        [wse setSpriteName:@"angry_spirit.png"];
        [wse setValuePerTick:dotDamage];
        [wse setNumOfTicks:8.0];
        [bottleEffect setAppliedEffect:wse];
        
        ProjectileEffect *bottleVisual = [[[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime] autorelease];
        [bottleVisual setSpriteColor:ccc3(255, 0, 0 )];
        [bottleVisual setType:ProjectileEffectTypeThrow];
        [self.owner.announcer displayProjectileEffect:bottleVisual];
    }

}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    [self triggerForTarget:theRaid.randomLivingMember inRaid:theRaid];
}

- (void)triggerAbilityAtRaid:(Raid*)raid
{
    for (RaidMember *member in raid.livingMembers) {
        [self triggerForTarget:member inRaid:raid];
    }
}
@end

@implementation PlaguebringerSicken
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    for (int i = 0; i < 2; i++) {
        RaidMember *target = theRaid.randomLivingMember;
        ExpiresAtFullHealthRHE *infectedWound = [[[ExpiresAtFullHealthRHE alloc] initWithDuration:30.0 andEffectType:EffectTypeNegative] autorelease];
        [infectedWound setOwner:self.owner];
        [infectedWound setTitle:@"pbc-infected-wound"];
        [infectedWound setAilmentType:AilmentTrauma];
        [infectedWound setValuePerTick:-self.abilityValue];
        [infectedWound setNumOfTicks:15];
        [infectedWound setSpriteName:self.iconName];
        if (target.health > target.maximumHealth * .58){
            // Spike the health for funsies!
            NSInteger preHealth = target.health;
            [target setHealth:target.health * .58];
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:[NSNumber numberWithInt:preHealth - target.health] andEventType:CombatEventTypeDamage]];
        }
        [target addEffect:infectedWound];
    }
}
@end

@implementation DarkCloud
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    for (RaidMember *member in theRaid.raidMembers){
        DarkCloudEffect *dcEffect = [[DarkCloudEffect alloc] initWithDuration:5 andEffectType:EffectTypeNegativeInvisible];
        [dcEffect setOwner:self.owner];
        [dcEffect setValuePerTick:-30];
        [dcEffect setNumOfTicks:3];
        [member addEffect:dcEffect];
        [dcEffect release];
    }
    [self.owner.announcer displayParticleSystemOnRaidWithName:@"purple_mist.plist" forDuration:-1.0];
    [self startChannel:5];
}
@end

@implementation RaidDamageSweep
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players
{
    NSInteger deadCount = [theRaid deadCount];
    for (int i = 0; i < theRaid.raidMembers.count/2; i++){
        NSInteger index = theRaid.raidMembers.count - i - 1;
        
        RaidMember *member = [theRaid.raidMembers objectAtIndex:index];
        RaidMember *member2 = [theRaid.raidMembers objectAtIndex:i];
        
        NSInteger axeSweepDamage = FUZZ(self.abilityValue, 40);
        
        DelayedHealthEffect *axeSweepEffect = [[[DelayedHealthEffect alloc] initWithDuration:i * .5 andEffectType:EffectTypeNegativeInvisible] autorelease];
        [axeSweepEffect setOwner:self.owner];
        [axeSweepEffect setTitle:@"raid-d-sweep"];
        [axeSweepEffect setValue:-axeSweepDamage * (1 + ((float)deadCount/(float)theRaid.raidMembers.count))];
        [axeSweepEffect setFailureChance:.1];
        DelayedHealthEffect *axeSweep2 = [[axeSweepEffect copy] autorelease];
        if (![member isDead]) {
            [member addEffect:axeSweepEffect];
        }
        if (![member isDead]) {
            [member2 addEffect:axeSweep2];
        }
    }
    [self startChannel:7.5];
}

@end
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
#import "ProjectileEffect.h"
#import "AbilityDescriptor.h"

@interface Ability ()
@end

@implementation Ability
@synthesize failureChance, title, owner, abilityValue;
@synthesize timeApplied, isDisabled;

- (id)init {
    if (self = [super init]){
        self.attackParticleEffectName = @"blood_spurt.plist";
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
    }
    
}
- (void)triggerAbilityForRaid:(Raid*)theRaid andPlayers:(NSArray*)players{

}

- (int)damageDealt{
    float multiplyModifier = self.owner.damageDoneMultiplier;
    int additiveModifier = 0;
    
    if ([[self bossOwner] isMultiplayer]){
        multiplyModifier += 1.2;
    }
    
    float criticalChance = [self bossOwner].criticalChance;
    if (criticalChance != 0.0 && arc4random() % 100 < (criticalChance * 100)){
        multiplyModifier += 1.5;
    }
    
    return (int)round((float)self.abilityValue * multiplyModifier) + additiveModifier;
}

-(void)damageTarget:(RaidMember*)target{
    if (![target raidMemberShouldDodgeAttack:0.0]){
        [self willDamageTarget:target];
        int thisDamage = [self damageDealt];
        
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:[NSNumber numberWithInt:thisDamage] andEventType:CombatEventTypeDamage]];
        [target setHealth:[target health] - thisDamage];
        if (thisDamage > 0){
            [[self bossOwner].announcer displayParticleSystemWithName:self.attackParticleEffectName onTarget:target];
        }
        
    }else{
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:0 andEventType:CombatEventTypeDodge]];
    }
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
            Effect *enrageEffect = [[Effect alloc] initWithDuration:600 andEffectType:EffectTypePositiveInvisible];
            [enrageEffect setOwner:self.owner];
            [enrageEffect setTitle:@"Enraged"];
            [enrageEffect setTarget:[self bossOwner]];
            [enrageEffect setDamageDoneMultiplierAdjustment:2.0];
            [[self bossOwner] addEffect:[enrageEffect autorelease]];
            [[self bossOwner].announcer announce:[NSString stringWithFormat:@"%@ glows with power after defeating its focused target.", [self bossOwner].title]];
            
            AbilityDescriptor *glowingPower = [[AbilityDescriptor alloc] init];
            [glowingPower setAbilityDescription:@"After defeating a Focused target, this enemy becomes unstoppable and will deal vastly increased damage."];
            [glowingPower setAbilityName:@"Glowing with Power"];
            [glowingPower setIconName:@"unknown_ability.png"];
            [[self bossOwner] addAbilityDescriptor:glowingPower];
            [glowingPower release];
            self.enrageApplied = YES;
        }
    }
}
@end

@implementation ProjectileAttack 
@synthesize spriteName;

- (void)dealloc {
    [spriteName release];
    [super dealloc];
}

- (id)copy {
    ProjectileAttack *fbCopy = [super copy];
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
    [fireball setIsIndependent:YES];
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
        [member setHealth:member.health - (15.0 * self.owner.damageDoneMultiplier)];
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
- (id)init {
    if (self = [super init]){
        AbilityDescriptor *desc = [[AbilityDescriptor alloc] init];
        [desc setAbilityDescription:@"Deals extremely high damage to all living allies.  The damage is divided by the number of living allies."];
        [desc setIconName:@"unknown_ability.png"];
        [desc setAbilityName:@"Deathwave"];
        [self setDescriptor:desc];
        [desc release];
        self.abilityValue = 1200;
    }
    return self;
}
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
    [[(Boss*)self.owner announcer] displayScreenShakeForDuration:1.0];
    [[(Boss*)self.owner announcer] displayPartcileSystemOnRaidWithName:@"death_ring.plist" forDuration:2.0];

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
    [fbAbility setAbilityValue:50];
    [fbAbility setCooldown:12.0];
    [fbAbility setFailureChance:.05];
    [allAbilities addObject:[fbAbility autorelease]];
    
    ProjectileAttack *quickFireball = [[ProjectileAttack alloc] init];
    [quickFireball setSpriteName:@"fireball.png"];
    [quickFireball setTitle:@"random-quickfirebal"];
    [quickFireball setAbilityValue:10];
    [quickFireball setCooldown:3.0];
    [quickFireball setFailureChance:.1];
    [allAbilities addObject:[quickFireball autorelease]];
    
    BloodMinion *bm = [[BloodMinion alloc] init];
    [bm setTitle:@"blood-minion"];
    [bm setCooldown:10.0];
    [bm setAbilityValue:10];
    [allAbilities addObject:bm];
    [bm release];
    
    FireMinion *fm = [[FireMinion alloc] init];
    [fm setTitle:@"fire-minion"];
    [fm setCooldown:15.0];
    [fm setAbilityValue:35];
    [allAbilities addObject:fm];
    [fm release];
    
    ShadowMinion *sm = [[ShadowMinion alloc] init];
    [sm setTitle:@"shadow-minion"];
    [sm setCooldown:12.0];
    [sm setAbilityValue:20];
    [allAbilities addObject:sm];
    [sm release];
    
    OverseerProjectiles* projectilesAbility = [[[OverseerProjectiles alloc] init] autorelease];
    [projectilesAbility setAbilityValue:56];
    [projectilesAbility setCooldown:4.5];
    [allAbilities addObject:projectilesAbility];
    
    FocusedAttack *tankAttack = [[FocusedAttack alloc] initWithDamage:62 andCooldown:2.45];
    [tankAttack setFailureChance:.4];
    [allAbilities addObject:tankAttack];
    [tankAttack release];
    
    TargetTypeFlameBreath *sweepingFlame = [[[TargetTypeFlameBreath alloc] init] autorelease];
    [sweepingFlame setCooldown:9.0];
    [sweepingFlame setAbilityValue:60];
    [sweepingFlame setNumTargets:5];
    [allAbilities addObject:sweepingFlame];
    
    Grip *gripAbility = [[Grip alloc] init];
    [gripAbility setTitle:@"grip-ability"];
    [gripAbility setCooldown:22];
    [gripAbility setAbilityValue:-14];
    [allAbilities addObject:gripAbility];
    [gripAbility release];
    
    Impale *impaleAbility = [[Impale alloc] init];
    [impaleAbility setTitle:@"gatekeeper-impale"];
    [impaleAbility setCooldown:16];
    [allAbilities addObject:impaleAbility];
    [impaleAbility setAbilityValue:82];
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
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:self.numTargets];
    int retry = 0;;
    for (int i = 0; i < self.numTargets; i++){
        RaidMember *candidate = [theRaid randomLivingMemberWithPositioning:self.targetPositioningType];
        if (![targets containsObject:candidate]){
            [targets addObject:candidate];
        }else if (retry < 10){
            i--;
            retry++;
        }
    }
    return (NSArray*)targets;
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
    [boneThrowEffect setValue:-40];
    [boneThrowEffect setMaxStacks:10];
    FallenDownEffect *fde = [FallenDownEffect defaultEffect];
    [fde setOwner:self.owner];
    [boneThrowEffect setAppliedEffect:fde];
    [target addEffect:boneThrowEffect];
    [boneThrowEffect release];
    
    ProjectileEffect *boneVisual = [[ProjectileEffect alloc] initWithSpriteName:@"bone_throw.png" target:target andCollisionTime:throwDuration];
    [[(Boss*)self.owner announcer] displayThrowEffect:boneVisual];
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
        [bonequakeDot setValuePerTick:-3];
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
            [(RepeatedHealthEffect*)appliedEffect setValuePerTick:-damage * .2];
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
        [burning setValuePerTick:-2];
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
- (void)triggerAbilityForRaid:(Raid *)theRaid andPlayers:(NSArray *)players {
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
        [desc setAbilityDescription:@"As your allies hack their way through the filth beast they become covered in a disgusting slime.  If this slime builds to 5 stacks on any ally that ally will be instantly slain.  Whenever an ally receives any healing the slime is removed."];
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
            [delayedSlime setValue:-7];
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
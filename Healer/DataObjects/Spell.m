//
//  Spell.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GameObjects.h"
#import	"AudioController.h"
#import "CombatEvent.h"
#import "Agent.h"
#import "Announcer.h"
#import "Player.h"
#import "ProjectileEffect.h"

@interface Spell ()
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *spellID;
@property (nonatomic, readwrite) NSTimeInterval tempCooldown;
@end

@implementation Spell

@synthesize title, healingAmount, energyCost, castTime, percentagesPerTarget, targets, description, spellAudioData, cooldownRemaining, cooldown, spellID, appliedEffect, owner, info, tempCooldown;

-(id)initWithTitle:(NSString*)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd
{
    if (self = [super init]){
        self.title = ttle;
        healingAmount = healAmnt;
        energyCost = nrgyCost;
        castTime = time;
        self.tempCooldown = 0.0;
        self.cooldown = cd;
        isMultitouch = NO;
        spellAudioData = [[SpellAudioData alloc] init];
        percentagesPerTarget = nil;
        self.spellID = NSStringFromClass([self class]);
    }
	return self;
}

-(void)dealloc{
    [spellAudioData release]; spellAudioData = nil;
    [title release]; title = nil;
    [percentagesPerTarget release];percentagesPerTarget = nil;
    [spellID release]; spellID = nil;
    [description release]; description = nil;
    [appliedEffect release]; appliedEffect = nil;
    [super dealloc];
    
}

- (NSInteger)energyCost {
    NSInteger baseEnergyCost = energyCost;
    if (!self.owner){
        return baseEnergyCost;
    }
    return baseEnergyCost * [self.owner spellCostAdjustmentForSpell:self];
}

- (NSString*)spellTypeDescription {
    switch (self.spellType) {
        case SpellTypeBasic:
            return @"Basic";
        case SpellTypePeriodic:
            return @"Periodic";
        case SpellTypeEmpowering:
            return @"Empower";
        case SpellTypeMulti:
            return @"Multi";
        case SpellTypeProtective:
            return @"Protective";
        default:
            return @"Basic";
    }
}

- (NSString*)spriteFrameName {
    NSString* path = [[[[self.title lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"-"] stringByAppendingString:@"-icon"] stringByAppendingPathExtension:@"png"];
    return path;
}

- (void)willHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
}

- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
}

- (float)cooldown {
    if (self.tempCooldown != 0.0){
        return self.tempCooldown;
    }
    return cooldown;
}

- (float)castTime {
    if (!self.owner){
        return castTime;
    }
    float finalCastTime = castTime * [self.owner castTimeAdjustmentForSpell:self];
    return finalCastTime;
}

- (void)applyTemporaryCooldown:(NSTimeInterval)tempCD {
    self.cooldownRemaining = tempCD;
    self.tempCooldown = tempCD;
    [[(Player*)self.owner spellsOnCooldown] addObject:self];
}

-(BOOL)isEqual:(id)object{
    Spell *spell = (Spell*)object;
    
    if ([self.title isEqualToString:spell.title]){
        return YES;
    }
    return NO;
}

-(NSUInteger)hash{
    return [self.title hash];
}

+(id)defaultSpell{
	Spell* def = [[[self class] alloc] initWithTitle:@"DefaultSpell" healAmnt:0 energyCost:0 castTime:0.0 andCooldown:0];
	return [def autorelease];
}

- (NSString*)info{
    return [NSString stringWithFormat:@"Energy Cost : %i \n %@", energyCost, description];
}

-(NSString*)spellDescription{
	return description;
	
}

-(NSInteger)healingAmount{
    int finalAmount = healingAmount;
    int fuzzRange = (int)round(healingAmount * .05);
    int fuzz = arc4random() % (fuzzRange + 1);
    
    finalAmount += fuzz * (arc4random() % 2 == 0 ? -1 : 1);
    return finalAmount * [self.owner healingDoneMultiplierForSpell:self];
}

-(BOOL)isInstant
{
	return castTime == 0.0;
}

-(BOOL)hasCastSounds
{
	return NO;
}

-(void)setTargets:(NSInteger)numOfTargets withPercentagesPerTarget:(NSArray*)percentages
{
	if (numOfTargets <= 1){
		targets = 1;
		isMultitouch = NO;
	}
	else if (numOfTargets > 1){
		targets = numOfTargets;
		percentagesPerTarget = [percentages retain];
		isMultitouch = YES;
	}
	
}

-(void)applyEffectToTarget:(RaidMember*)target inRaid:(Raid*)raid {
    if (self.appliedEffect){
        if (self.isExclusiveEffectTarget) {
            for (RaidMember *member in raid.livingMembers) {
                if (member == target) {
                    continue; //We can stack it up on the same target
                }
                NSIndexSet *similarEffectIndexes = [[member activeEffects] indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
                    Effect *eff = (Effect *)obj;
                    if (eff.title == self.appliedEffect.title && eff.owner == self.owner) {
                        return YES;
                    }
                    return NO;
                }];
                NSArray *objectsToRemove = [[member activeEffects] objectsAtIndexes:similarEffectIndexes];
                for (Effect *effToRemove in objectsToRemove) {
                    NSLog(@"Removing similar effect because");
                    [member removeEffect:effToRemove];
                }
            }
        }
        Effect *effectToApply = [[self.appliedEffect copy] autorelease];
        [effectToApply setOwner:self.owner];
        [target addEffect:effectToApply];
    }
}

- (void)checkDivinity {
    //For subclass overrides
}

- (BOOL)checkCritical
{
    if (!self.owner) {
        return NO;
    }
    return arc4random() % 100 < self.owner.spellCriticalChance * 100;
}

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
	if ([self targets] <= 1){
        int currentTargetHealth = [thePlayer spellTarget].health;
        NSInteger amount = [self healingAmount];
        BOOL critical = [self checkCritical];
        if (critical) {
            amount *= self.owner.criticalBonusMultiplier;
        }
        [self willHealTarget:[thePlayer spellTarget] inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:amount];
		[[thePlayer spellTarget] setHealth:[[thePlayer spellTarget] health] + amount];
        int newHealth = [thePlayer spellTarget].health;
        NSInteger finalAmount = newHealth - currentTargetHealth;
        [self didHealTarget:[thePlayer spellTarget] inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:finalAmount];
        NSInteger overheal = amount - finalAmount;
        [self.owner playerDidHealFor:finalAmount onTarget:thePlayer.spellTarget fromSpell:self withOverhealing:overheal asCritical:critical];
		[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
        [self applyEffectToTarget:thePlayer.spellTarget inRaid:theRaid];
	}
	else if ([self targets] > 1){
		int limit = [self targets];
		if ([[thePlayer additionalTargets] count] < limit) limit = [[thePlayer additionalTargets] count];
        BOOL critical = [self checkCritical];
		for (int i = 0; i < limit; i++){
			RaidMember *currentTarget = [[thePlayer additionalTargets] objectAtIndex:i];
			if ([currentTarget isDead]) continue;
			else{
				double PercentageThisTarget = [[[self percentagesPerTarget] objectAtIndex:i] doubleValue];
                int currentTargetHealth = currentTarget.health;
                NSInteger amount = ([self healingAmount]*PercentageThisTarget);
                if (critical) {
                    amount *= self.owner.criticalBonusMultiplier;
                }
                [self willHealTarget:currentTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:amount];
				[currentTarget setHealth:[[thePlayer spellTarget] health] + amount];
                int newTargetHealth = currentTarget.health;
                NSInteger finalAmount = newTargetHealth - currentTargetHealth;
                [self didHealTarget:currentTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:finalAmount];
                NSInteger overheal = amount - finalAmount;
                [self.owner playerDidHealFor:finalAmount onTarget:currentTarget fromSpell:self withOverhealing:overheal asCritical:critical];
                [self applyEffectToTarget:currentTarget inRaid:theRaid];
			}
			
		}
		[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
	}
    
    if (self.cooldown > 0.0){
        [[thePlayer spellsOnCooldown] addObject:self];
        self.cooldownRemaining = self.cooldown * self.owner.cooldownAdjustment;
    }
}
-(void)updateCooldowns:(float)theTime{
    self.cooldownRemaining -= theTime;
    
    if (self.cooldownRemaining < 0){
        self.cooldownRemaining = 0;
        self.tempCooldown = 0;
    }
}
-(void)spellBeganCasting{
	AudioController * ac = [AudioController sharedInstance];
	if ([spellAudioData beginTitle] != nil){
		[ac playTitle:[spellAudioData beginTitle]];
	}
}

-(void)spellEndedCasting{
	AudioController *ac = [AudioController sharedInstance];
	if ([spellAudioData beginTitle] != nil){
		[ac stopTitle:[spellAudioData beginTitle]];
	}
	if ([spellAudioData finishedTitle] != nil){
		[ac playTitle:[spellAudioData finishedTitle]];
	}
}

-(void)spellInterrupted{
	AudioController *ac = [AudioController sharedInstance];
	if ([spellAudioData beginTitle] != nil){
		[ac stopTitle:[spellAudioData beginTitle]];
	}
	if ([spellAudioData interruptedTitle] != nil){
		[ac playTitle:[spellAudioData interruptedTitle]];
	}
}
@end


#pragma mark - Simple Game Spells
@implementation Heal
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeBasic;
    }
    return self;
}
+(id)defaultSpell{
    Heal *heal = [[[Heal alloc] initWithTitle:@"Heal" healAmnt:250 energyCost:16 castTime:1.6 andCooldown:0.0] autorelease];
    [heal setDescription:@"Heals your target for a small amount."];
    return heal;
}

- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
    if (self.owner.isLocalPlayer){
        [self.owner.announcer displayParticleSystemWithName:@"restore_basic" onTarget:target withOffset:CGPointMake(4, -40)];
    }
}

@end

@implementation GreaterHeal
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeBasic;
    }
    return self;
}
+(id)defaultSpell{
    GreaterHeal *heal = [[GreaterHeal alloc] initWithTitle:@"Greater Heal" healAmnt:750 energyCost:60 castTime:2.0 andCooldown:0.0];
    [heal setDescription:@"Heals your target for a large amount."];
    return [heal autorelease];
}

- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
    if (self.owner.isLocalPlayer){
        [self.owner.announcer displayParticleSystemWithName:@"restore_greater" onTarget:target withOffset:CGPointMake(4, -40)];
    }
}
@end

@implementation HealingBurst
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeBasic;
    }
    return self;
}
+(id)defaultSpell{
    HealingBurst *heal = [[HealingBurst alloc] initWithTitle:@"Healing Burst" healAmnt:500 energyCost:70 castTime:1.0 andCooldown:0.0];
    [heal setDescription:@"Heals your target for a moderate amount very quickly."];
    return [heal autorelease];
}
- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
    if (self.owner.isLocalPlayer){
        [self.owner.announcer displayParticleSystemWithName:@"restore_basic" onTarget:target withOffset:CGPointMake(4, -40)];
    }
}

@end

@implementation ForkedHeal
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeMulti;
    }
    return self;
}
+(id)defaultSpell
{
	ForkedHeal *forkedHeal = [[ForkedHeal alloc] initWithTitle:@"Forked Heal" healAmnt:475 energyCost:100 castTime:1.85 andCooldown:0.0];//10h/erk
    [forkedHeal setDescription:@"Heals up to two targets simultaneously."];
	return [forkedHeal autorelease];
}

-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSInteger totalTargets = 2;
    
    NSArray *myTargets = [theRaid lowestHealthTargets:totalTargets withRequiredTarget:thePlayer.spellTarget];
    BOOL critical = [self checkCritical];
    int i = 0;
    for (RaidMember *healableTarget in myTargets){
        int currentTargetHealth = healableTarget.health;
        NSInteger amount = [self healingAmount];
        if (i != 0) {
            amount *= .66;
        }
        if (critical) {
            amount *= self.owner.criticalBonusMultiplier;
        }
        [self willHealTarget:healableTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:amount];
		[healableTarget setHealth:[healableTarget health] + amount];
        int newHealth = healableTarget.health;
        NSInteger finalAmount = newHealth - currentTargetHealth;
        [self didHealTarget:healableTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:finalAmount];
        NSInteger overheal = amount - finalAmount;
        [self.owner playerDidHealFor:finalAmount onTarget:healableTarget fromSpell:self withOverhealing:overheal asCritical:critical];
    }
    
    [thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
    
    
    if (self.cooldown > 0.0){
        [[thePlayer spellsOnCooldown] addObject:self];
        self.cooldownRemaining = self.cooldown;
    }
}
- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
    if (self.owner.isLocalPlayer){
        [self.owner.announcer displayParticleSystemWithName:@"restore_crossLR" onTarget:target withOffset:CGPointMake(30, -40)];
        [self.owner.announcer displayParticleSystemWithName:@"restore_crossRL" onTarget:target withOffset:CGPointMake(-30, -40)];
    }
}
@end

@implementation Regrow
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypePeriodic;
    }
    return self;
}

+(id)defaultSpell{
    Regrow *regrow = [[Regrow alloc] initWithTitle:@"Regrow" healAmnt:0 energyCost:50 castTime:0.0 andCooldown:1.0];
    [regrow setDescription:@"Heals for a moderate amount over 12 seconds."];
    
    RepeatedHealthEffect *hotEffect = [[RepeatedHealthEffect alloc] initWithDuration:12.0 andEffectType:EffectTypePositive];
    [hotEffect setSpriteName:@"regrow.png"];
    [hotEffect setTitle:@"regrow-effect"];
    [hotEffect setNumOfTicks:4];
    [hotEffect setValuePerTick:165];
    [regrow setAppliedEffect:hotEffect];
    [hotEffect release];
    return [regrow autorelease];
}

- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
    if (self.owner.isLocalPlayer){
        [self.owner.announcer displayParticleSystemWithName:@"regrow" onTarget:target withOffset:CGPointMake(0,0)];
    }
}
@end

@implementation  Barrier
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeProtective;
    }
    return self;
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime
{
    [(ShieldEffect*)self.appliedEffect setAmountToShield:400*self.owner.healingDoneMultiplier];
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
}

+(id)defaultSpell{
	Barrier *bulwark = [[Barrier alloc] initWithTitle:@"Barrier" healAmnt:0 energyCost:75 castTime:0.0 andCooldown:4.0];
	[bulwark setDescription:@"Shields the target absorbing moderate damage.  If the shield is fully consumed 50 energy is restored to the Healer."];
    
    BarrierEffect* appliedEffect = [[[BarrierEffect alloc] initWithDuration:10.0 andEffectType:EffectTypePositive] autorelease];
    [appliedEffect setTitle:@"barrier-eff"];
    [appliedEffect setSpriteName:@"blessed_armor.png"];
    [bulwark setAppliedEffect:appliedEffect];
	return [bulwark autorelease];
}
@end


@implementation Purify
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeProtective;
    }
    return self;
}

+(id)defaultSpell{
    Purify *purify = [[Purify alloc] initWithTitle:@"Purify" healAmnt:50 energyCost:40 castTime:0.0 andCooldown:5.0];
    [purify setDescription:@"Removes evil curses or poisons from your enemies.  If there are none to remove, Purify heals for a moderate amount."];
    return [purify autorelease];
}
-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSInteger initialHealAmount = self.healingAmount;
    Effect *effectToRemove = nil;
    for (Effect *effect in [thePlayer.spellTarget activeEffects]){
        if (effect.effectType == EffectTypeNegative && (effect.ailmentType == AilmentCurse || effect.ailmentType == AilmentPoison)){
            effectToRemove = effect;
            break;
        }
    }
    if (!effectToRemove) {
        self.healingAmount = initialHealAmount * 8;
    }
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    
    self.healingAmount = initialHealAmount;
    
    [effectToRemove effectWillBeDispelled:theRaid player:thePlayer];
    [effectToRemove expire];
    [thePlayer.spellTarget removeEffect:effectToRemove];
}

- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
    if (self.owner.isLocalPlayer){
        [self.owner.announcer displayParticleSystemWithName:@"purify" onTarget:target withOffset:CGPointMake(0, 0)];
    }
}
@end

@implementation  OrbsOfLight
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeProtective;
    }
    return self;
}

+(id)defaultSpell{
    OrbsOfLight *orbs = [[OrbsOfLight alloc] initWithTitle:@"Orbs of Light" healAmnt:0 energyCost:120 castTime:1.0 andCooldown:4.0];
    [orbs setDescription:@"Heals a target for a moderate amount each time it takes damage. Lasts 10 seconds."];
    ReactiveHealEffect *rhe = [[ReactiveHealEffect alloc] initWithDuration:20.0 andEffectType:EffectTypePositive];
    [rhe setTitle:@"orbs-of-light-effect"];
    [rhe setEffectCooldown:2.0];
    [rhe setMaxStacks:1];
    [rhe setSpriteName:@"regrow.png"];
    [rhe setAmountPerReaction:350];
    [orbs setAppliedEffect:rhe];
    [rhe     release];
    
    return [orbs autorelease];
}

@end

@implementation  SwirlingLight
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypePeriodic;
    }
    return self;
}
+(id)defaultSpell{
    SwirlingLight *swirl = [[SwirlingLight alloc] initWithTitle:@"Swirling Light" healAmnt:0 energyCost:20 castTime:0.0 andCooldown:1.0];
    [swirl setDescription:@"Heals a target over 10 seconds. Maximum 3 Stacks. At 3 stacks this increases healing received by 5%. Can only be applied to 1 ally."];
    [swirl setIsExclusiveEffectTarget:YES];
    SwirlingLightEffect *sle = [[SwirlingLightEffect alloc] initWithDuration:10 andEffectType:EffectTypePositive];
    [sle setMaxStacks:3];
    [sle setSpriteName:@"swirling_light.png"];
    [sle setTitle:@"swirling-light-effect"];
    [sle setNumOfTicks:15];
    [sle setValuePerTick:25];
    [swirl setAppliedEffect:sle];
    [sle release];
    return [swirl autorelease];
}
@end

@implementation  LightEternal
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeMulti;
    }
    return self;
}

+ (id)defaultSpell {
    LightEternal *le = [[LightEternal alloc] initWithTitle:@"Light Eternal" healAmnt:520 energyCost:220 castTime:2.25 andCooldown:0.0];
    [le setDescription:@"Heals up to 5 allies with the least health among allies for a moderate amount."];
    return [le autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    NSInteger totalTargets = 5;

    NSArray *myTargets = [theRaid lowestHealthTargets:totalTargets  withRequiredTarget:thePlayer.spellTarget];
    BOOL critical = [self checkCritical];

    for (RaidMember *healableTarget in myTargets){
        int currentTargetHealth = healableTarget.health;
        NSInteger amount = [self healingAmount];
        if (critical) {
            amount *= self.owner.criticalBonusMultiplier;
        }
        [self willHealTarget:healableTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:amount];
		[healableTarget setHealth:[healableTarget health] + amount];
        int newHealth = healableTarget.health;
        NSInteger finalAmount = newHealth - currentTargetHealth;
        [self didHealTarget:healableTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:finalAmount];
        NSInteger overheal = amount - finalAmount;
        [self.owner playerDidHealFor:finalAmount onTarget:healableTarget fromSpell:self withOverhealing:overheal asCritical:critical];
    }
    
    [thePlayer setEnergy:[thePlayer energy] - [self energyCost]];

    if (self.cooldown > 0.0){
        [[thePlayer spellsOnCooldown] addObject:self];
        self.cooldownRemaining = self.cooldown;
    }
}
- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
    if (self.owner.isLocalPlayer){
        [self.owner.announcer displayParticleSystemWithName:@"restore_greater" onTarget:target withOffset:CGPointMake(4, -40)];
    }
}

@end


@implementation Respite
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeEmpowering;
    }
    return self;
}
+ (id)defaultSpell{
    Respite *respite = [[Respite alloc] initWithTitle:@"Respite" healAmnt:0 energyCost:0 castTime:0.0 andCooldown:30.0];
    [respite setDescription:@"Restores 105 Energy to the caster."];
    return [respite autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSInteger energyReturned = 105;
    [thePlayer setEnergy:thePlayer.energy + energyReturned];
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];

}
@end

@implementation WanderingSpirit
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypePeriodic;
    }
    return self;
}
+ (id)defaultSpell {
    WanderingSpirit *ws = [[WanderingSpirit alloc] initWithTitle:@"Wandering Spirit" healAmnt:0 energyCost:200 castTime:0.0 andCooldown:15.0];
    WanderingSpiritEffect *wse = [[WanderingSpiritEffect alloc] initWithDuration:14.0 andEffectType:EffectTypePositive];
    [wse setTitle:@"wandering-spirit-effect"];
    [wse setSpriteName:@"wandering_spirit.png"];
    [wse setValuePerTick:240];
    [wse setNumOfTicks:8.0];
    [ws setAppliedEffect:wse];
    [wse release];
    [ws setDescription:@"For 14 seconds, a spirit will wander through your allies restoring a moderate amount of health to the injured."];
    return [ws autorelease];
}
@end

@implementation WardOfAncients
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeProtective;
    }
    return self;
}
+ (id)defaultSpell {
    WardOfAncients *woa = [[WardOfAncients alloc] initWithTitle:@"Ward of Ancients" healAmnt:0 energyCost:100 castTime:0.0 andCooldown:35.0];
    [woa setDescription:@"Covers all allies in a protective barrier that reduces incoming damage by 40% for 6 seconds."];
    return [woa autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSArray *aliveMembers = [theRaid livingMembers];
    [theBoss.announcer displaySprite:@"shield_bubble.png" overRaidForDuration:6.0];
    for (RaidMember*member in aliveMembers){
        Effect *dtde = [[[Effect alloc] initWithDuration:6 andEffectType:EffectTypePositiveInvisible] autorelease];
        [dtde setTitle:@"ward-of-ancients-effect"];
        [dtde setDamageTakenMultiplierAdjustment:-.4];
        [dtde setOwner:self.owner];
        [member addEffect:dtde];
    }
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    
}
@end

@implementation TouchOfHope
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeBasic;
    }
    return self;
}
+ (id)defaultSpell {
    TouchOfHope *tol = [[TouchOfHope alloc] initWithTitle:@"Touch of Hope" healAmnt:300 energyCost:50 castTime:0.0 andCooldown:4.0];
    [tol setDescription:@"Heals your target for a small amount and more over 4 seconds.  Each time the periodic effect heals it restores 12 energy to the Healer."];
    return [tol autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    
    TouchOfHopeEffect *tolEffect = [[TouchOfHopeEffect alloc] initWithDuration:4.0 andEffectType:EffectTypePositive];
    [tolEffect setTitle:@"toh-effect"];
    [tolEffect setSpriteName:@"touch_of_hope.png"];
    [tolEffect setValuePerTick:70];
    [tolEffect setNumOfTicks:4];
    [tolEffect setOwner:self.owner];
    [[self.owner spellTarget] addEffect:tolEffect];
    [tolEffect release];
    
}
- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
    if (self.owner.isLocalPlayer){
        [self.owner.announcer displayParticleSystemWithName:@"touch_of_hope" onTarget:target withOffset:CGPointMake(10, 0)];
    }
}
@end

@implementation SoaringSpirit
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeEmpowering;
    }
    return self;
}
+ (id)defaultSpell {
    SoaringSpirit *ss = [[SoaringSpirit alloc] initWithTitle:@"Soaring Spirit" healAmnt:0 energyCost:30 castTime:0 andCooldown:35.0];
    [ss setDescription:@"Releases your inner light increasing healing done and reducing cast times by 50% for 7.5 seconds."];
    return [ss autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    [self.owner.announcer announce:@"You are filled with spiritual power."];
    Effect *soaringSpiritEffect = [[Effect alloc] initWithDuration:7.5 andEffectType:EffectTypePositive];
    [soaringSpiritEffect setOwner:self.owner];
    [soaringSpiritEffect setHealingDoneMultiplierAdjustment:.5];
    [soaringSpiritEffect setCastTimeAdjustment:.5];
    [self.owner addEffect:soaringSpiritEffect];
    [soaringSpiritEffect release];
}
@end

@implementation FadingLight
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypePeriodic;
    }
    return self;
}
+ (id)defaultSpell {
    FadingLight *fl = [[FadingLight alloc] initWithTitle:@"Fading Light" healAmnt:0 energyCost:90 castTime:0.0 andCooldown:2.0];
    [fl setDescription:@"Heals for a large amount over 10 seconds.  The healing done starts high but decreases each tick."];
    
    IntensifyingRepeatedHealthEffect *fadingLightEffect = [[IntensifyingRepeatedHealthEffect alloc] initWithDuration:10.0 andEffectType:EffectTypePositive];
    [fadingLightEffect setTitle:@"fading-light-effect"];
    [fadingLightEffect setSpriteName:@"fading_light.png"];
    [fadingLightEffect setNumOfTicks:5];
    [fadingLightEffect setIncreasePerTick:-0.5];
    [fadingLightEffect setValuePerTick:400];
    [fl setAppliedEffect:fadingLightEffect];
    [fadingLightEffect release];
    return [fl autorelease];
}

@end

@implementation Sunburst
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeMulti;
    }
    return self;
}
+ (id)defaultSpell {
    Sunburst *sb = [[Sunburst alloc] initWithTitle:@"Sunburst" healAmnt:0 energyCost:320 castTime:0.0 andCooldown:10.0];
    [sb setDescription:@"Heals up to 7 injured allies for a small amount over 5 seconds."];
    return [sb autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    NSInteger totalTargets = 7;
    
    NSArray *sunburstTargets = [theRaid lowestHealthTargets:totalTargets withRequiredTarget:thePlayer.spellTarget];
    
    for (RaidMember *target in sunburstTargets){
        if (target != self.owner.spellTarget) {
            [self willHealTarget:target inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:0];
            [self didHealTarget:target inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:0];
            [self.owner playerDidHealFor:0 onTarget:target fromSpell:self withOverhealing:0 asCritical:NO];
        }
        
        RepeatedHealthEffect *sunburstEffect = [[RepeatedHealthEffect alloc] initWithDuration:5.0 andEffectType:EffectTypePositive];
        [sunburstEffect setTitle:@"sunburst-hot"];
        [sunburstEffect setSpriteName:@"sunburst.png"];
        [sunburstEffect setNumOfTicks:5];
        [sunburstEffect setValuePerTick:60];
        [sunburstEffect setOwner:self.owner];
        [target addEffect:sunburstEffect];
        [sunburstEffect release];
    }
    
}
- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withBoss:(Boss*)boss andPlayers:(NSArray*)players forAmount:(NSInteger)amount{
    //Override with a subclass
    if (self.owner.isLocalPlayer){
        [self.owner.announcer displayParticleSystemWithName:@"touch_of_hope" onTarget:target withOffset:CGPointMake(10, 0)];
    }
}
@end

@implementation StarsOfAravon
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeMulti;
    }
    return self;
}

+ (id)defaultSpell {
    StarsOfAravon *spell = [[StarsOfAravon alloc] initWithTitle:@"Stars of Aravon" healAmnt:0 energyCost:66 castTime:1.75 andCooldown:0.0];
    [spell setDescription:@"Summon 4 Stars of Aravon from the heavens.  The Stars travel for 1.75 seconds before healing their target for a small amount."];
    return [spell autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    NSInteger totalTargets = 4;
    
    NSArray *starTargets = [theRaid randomTargets:totalTargets withPositioning:Any];
    
    NSTimeInterval healDelay = 1.75;
    NSTimeInterval preDelay = .33;
    healDelay -= preDelay;
    for (RaidMember *starTarget in starTargets){
        if (starTarget != self.owner.spellTarget) {
            [self willHealTarget:starTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:0];
            [self didHealTarget:starTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:0];
            [self.owner playerDidHealFor:0 onTarget:starTarget fromSpell:self withOverhealing:0 asCritical:NO];
        }
        ProjectileEffect *starProjectile = [[ProjectileEffect alloc] initWithSpriteName:@"star.png" target:starTarget andCollisionTime:healDelay];
        [starProjectile setCollisionParticleName:@"star_explosion.plist"];
        [starProjectile setDelay:preDelay];
        [theBoss.announcer displayProjectileEffect:starProjectile fromOrigin:CGPointMake(400 - (arc4random() % 300 - 150), 800)];
        DelayedHealthEffect *starDelayedHealthEff = [[DelayedHealthEffect alloc] initWithDuration:healDelay andEffectType:EffectTypePositiveInvisible];
        [starDelayedHealthEff setIsIndependent:YES];
        [starDelayedHealthEff setOwner:self.owner];
        [starDelayedHealthEff setValue:190];
        [starDelayedHealthEff setTitle:@"star-of-aravon-eff"];
        [starTarget addEffect:starDelayedHealthEff];
        [starProjectile release];
        [starDelayedHealthEff release];
    }
}

@end

@implementation BlessedArmor
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeProtective;
    }
    return self;
}
+ (id)defaultSpell {
    BlessedArmor *defaultSpell = [[BlessedArmor alloc] initWithTitle:@"Blessed Armor" healAmnt:0 energyCost:70 castTime:0.0 andCooldown:9.0];
    
    [defaultSpell setDescription:@"Reduces damage done to a target by 25% for 5 seconds.  When the effect ends it heals for a moderate amount."];
    DelayedHealthEffect *bae = [[DelayedHealthEffect alloc] initWithDuration:5.0 andEffectType:EffectTypePositive];
    [bae setSpriteName:@"blessed_armor.png"];
    [bae setTitle:@"blessed-armor-eff"];
    [bae setValue:500];
    [bae setDamageTakenMultiplierAdjustment:-.25];
    [defaultSpell setAppliedEffect:bae];
    [bae release];
    return [defaultSpell autorelease];
}
@end

@implementation Attunement
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeProtective;
    }
    return self;
}
+ (id)defaultSpell {
    Attunement *defaultSpell = [[Attunement alloc] initWithTitle:@"Attunement" healAmnt:0 energyCost:100 castTime:0.0 andCooldown:35.0];
    [defaultSpell setDescription:@"Binds the souls of all allies redistributing health evenly and reducing damage taken for those allies by 15% for 6 seconds."];
    return [defaultSpell autorelease];
}
- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    NSArray *livingMembers = [theRaid livingMembers];
    
    NSInteger totalHealth = 0;
    NSInteger currentHealth = 0;
    for (RaidMember *member in livingMembers) {
        totalHealth += member.maximumHealth;
        currentHealth += member.health;
    }

    float healthPercentage = (float)currentHealth/(float)totalHealth;
    for (RaidMember *member in livingMembers) {
        [member setHealth:member.maximumHealth * healthPercentage];
        Effect *armorEffect = [[[Effect alloc] initWithDuration:6.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [armorEffect setDamageTakenMultiplierAdjustment:-.15];
        [armorEffect setTitle:@"attunement-armor"];
        [armorEffect setOwner:self.owner];
        [member addEffect:armorEffect];
    }
}
@end

#pragma mark -
#pragma mark Test Spells
@implementation HastyBrew
@synthesize chargeStart, chargeEnd;
+(id)defaultSpell{
	HastyBrew *hastyBrew = [[HastyBrew alloc] initWithTitle:@"Hasty Brew" healAmnt:10 energyCost:8 castTime:1.0 andCooldown:0.0];
	[hastyBrew setDescription:@"A spell that heals a small amount but can be charged to heal up to twice as much"];
	return [hastyBrew autorelease];
}

-(void)beginCharging:(NSDate*)startTime{
	chargeStart = [startTime copyWithZone:nil];
}
-(void)endCharging:(NSDate*)endTime{
	chargeEnd = [endTime copyWithZone:nil];
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime
{
	NSInteger additionalHealing = 0;
	NSTimeInterval timeDelta = [chargeEnd timeIntervalSinceDate:chargeStart];;
	NSLog(@"Charged for %1.2f seconds", timeDelta);
	chargeStart = nil;
	chargeEnd = nil;
	
	if (timeDelta >= 1){
		additionalHealing = healingAmount * 1.5;
	}
	
	[[thePlayer spellTarget] setHealth:[[thePlayer spellTarget] health] + [self healingAmount] + additionalHealing];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}
-(NSTimeInterval)maxChargeTime{
	return 1.0;
}
-(NSTimeInterval)currentChargeTime{
	if (chargeStart != nil && chargeEnd == nil)
		return [[NSDate date] timeIntervalSinceDate:chargeStart];
	else {
		return -1.0;
	}
	
}
@end



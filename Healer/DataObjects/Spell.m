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
    [spellID release];
    [description release];
    [appliedEffect release]; 
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

-(void)applyEffectToTarget:(RaidMember*)target{
    if (self.appliedEffect){
        Effect *effectToApply = [[self.appliedEffect copy] autorelease];
        [effectToApply setOwner:self.owner];
        [target addEffect:effectToApply];
    }
}

- (void)checkDivinity {
    //For subclass overrides
}

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
    
	if ([self targets] <= 1){
        int currentTargetHealth = [thePlayer spellTarget].health;
        NSInteger amount = [self healingAmount];
        [self willHealTarget:[thePlayer spellTarget] inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:amount];
		[[thePlayer spellTarget] setHealth:[[thePlayer spellTarget] health] + amount];
        int newHealth = [thePlayer spellTarget].health;
        NSInteger finalAmount = newHealth - currentTargetHealth;
        [self didHealTarget:[thePlayer spellTarget] inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:finalAmount];
        [self.owner playerDidHealFor:finalAmount onTarget:thePlayer.spellTarget fromSpell:self];
        NSInteger overheal = amount - finalAmount;
        if (overheal > 0){
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:[thePlayer spellTarget] value:[NSNumber numberWithInt:overheal] andEventType:CombatEventTypeOverheal]];
        }
		[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
        [self applyEffectToTarget:thePlayer.spellTarget];
        if (self.spellType == SpellTypePeriodic){
            if ([self.owner hasDivinityEffectWithTitle:@"sunlight"]){
                if (arc4random() % 100 < 10){
                    [self applyEffectToTarget:[theRaid randomLivingMember]];
                }
            }
        }
	}
	else if ([self targets] > 1){
		int limit = [self targets];
		if ([[thePlayer additionalTargets] count] < limit) limit = [[thePlayer additionalTargets] count];
		for (int i = 0; i < limit; i++){
			RaidMember *currentTarget = [[thePlayer additionalTargets] objectAtIndex:i];
			if ([currentTarget isDead]) continue;
			else{
				double PercentageThisTarget = [[[self percentagesPerTarget] objectAtIndex:i] doubleValue];
                int currentTargetHealth = currentTarget.health;
                NSInteger amount = ([self healingAmount]*PercentageThisTarget);
                [self willHealTarget:currentTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:amount];
				[currentTarget setHealth:[[thePlayer spellTarget] health] + amount];
                int newTargetHealth = currentTarget.health;
                NSInteger finalAmount = newTargetHealth - currentTargetHealth;
                [self didHealTarget:currentTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:finalAmount];
                [self.owner playerDidHealFor:finalAmount onTarget:currentTarget fromSpell:self];
                NSInteger overheal = amount - finalAmount;
                if (overheal > 0){
                    [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:[thePlayer spellTarget] value:[NSNumber numberWithInt:overheal] andEventType:CombatEventTypeOverheal]];
                }
                [self applyEffectToTarget:currentTarget];
			}
			
		}
		[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
	}
    
    if (self.cooldown > 0.0){
        [[thePlayer spellsOnCooldown] addObject:self];
        self.cooldownRemaining = self.cooldown;
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
    Heal *heal = [[Heal alloc] initWithTitle:@"Heal" healAmnt:35 energyCost:22 castTime:1.75 andCooldown:0.0];
    [heal setDescription:@"Heals your target for a small amount."];
    [[heal spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[heal spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[heal spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
    return [heal autorelease];
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
    GreaterHeal *heal = [[GreaterHeal alloc] initWithTitle:@"Greater Heal" healAmnt:100 energyCost:90 castTime:2.25 andCooldown:0.0];
    [heal setDescription:@"Heals your target for a large amount."];
    [[heal spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[heal spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[heal spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
    return [heal autorelease];
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
    HealingBurst *heal = [[HealingBurst alloc] initWithTitle:@"Healing Burst" healAmnt:50 energyCost:70 castTime:1.0 andCooldown:0.0];
    [heal setDescription:@"Heals your target for a moderate amount very quickly."];
    [[heal spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[heal spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[heal spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
    return [heal autorelease];
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
	ForkedHeal *forkedHeal = [[ForkedHeal alloc] initWithTitle:@"Forked Heal" healAmnt:55 energyCost:100 castTime:1.75 andCooldown:0.0];//10h/erk
    [forkedHeal setDescription:@"Heals up to two targets simultaneously."];
    [[forkedHeal spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[forkedHeal spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[forkedHeal spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
	return [forkedHeal autorelease];
}

-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSInteger totalTargets = 2;
    
    if ([self.owner hasDivinityEffectWithTitle:@"purity-of-soul"]){
        if (arc4random() % 100 < 10){
            totalTargets = 4;
        }
    }
    
    NSArray *myTargets = [theRaid lowestHealthTargets:totalTargets withRequiredTarget:thePlayer.spellTarget];
    
    int i = 0; 
    for (RaidMember *healableTarget in myTargets){
        int currentTargetHealth = healableTarget.health;
        NSInteger amount = [self healingAmount];
        if (i != 0) {
            amount *= .66;
        }
        [self willHealTarget:healableTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:amount];
		[healableTarget setHealth:[healableTarget health] + amount];
        int newHealth = healableTarget.health;
        NSInteger finalAmount = newHealth - currentTargetHealth;
        [self didHealTarget:healableTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:finalAmount];
        [self.owner playerDidHealFor:finalAmount onTarget:healableTarget fromSpell:self];
        NSInteger overheal = amount - finalAmount;
        if (overheal > 0){
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:[thePlayer spellTarget] value:[NSNumber numberWithInt:overheal] andEventType:CombatEventTypeOverheal]];
        }
    }
    
    [thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
    
    
    if (self.cooldown > 0.0){
        [[thePlayer spellsOnCooldown] addObject:self];
        self.cooldownRemaining = self.cooldown;
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
    Regrow *regrow = [[Regrow alloc] initWithTitle:@"Regrow" healAmnt:0 energyCost:90 castTime:0.0 andCooldown:1.0];
    [regrow setDescription:@"Heals for a large amount over 12 seconds."];
    [[regrow spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanInstantHoT" ofType:@"wav"]] andTitle:@"WWFinished"];
    
    RepeatedHealthEffect *hotEffect = [[RepeatedHealthEffect alloc] initWithDuration:12.0 andEffectType:EffectTypePositive];
    [hotEffect setSpriteName:@"regrow.png"];
    [hotEffect setTitle:@"regrow-effect"];
    [hotEffect setNumOfTicks:4];
    [hotEffect setValuePerTick:30];
    [regrow setAppliedEffect:hotEffect];
    [hotEffect release];
    return [regrow autorelease];
}
@end

@implementation  Barrier
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeProtective;
    }
    return self;
}
+(id)defaultSpell{
	Barrier *bulwark = [[Barrier alloc] initWithTitle:@"Barrier" healAmnt:0 energyCost:100 castTime:0.0 andCooldown:5.0];
	[bulwark setDescription:@"Sets a shield around a target that absorbs moderate damage."];
	[[bulwark spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerBasicCasting" ofType:@"wav"]] andTitle:@"BWStart"];
	[[bulwark spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerBasicFizzle" ofType:@"wav"]] andTitle:@"BWFizzle"];
	[[bulwark spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerInstantShield" ofType:@"wav"]] andTitle:@"BWFinish"];
    [bulwark setAppliedEffect:[BulwarkEffect defaultEffect]];
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
    Purify *purify = [[Purify alloc] initWithTitle:@"Purify" healAmnt:5 energyCost:40 castTime:0.0 andCooldown:5.0];
    [purify setDescription:@"Dispels negative poison and curse effects from allies."];
    [[purify spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanInstantHoT" ofType:@"wav"]] andTitle:@"WWFinished"];
    return [purify autorelease];
}
-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    Effect *effectToRemove = nil;
    for (Effect *effect in [thePlayer.spellTarget activeEffects]){
        if (effect.effectType == EffectTypeNegative && (effect.ailmentType == AilmentCurse || effect.ailmentType == AilmentPoison)){
            effectToRemove = effect;
            break;
        }
    }
    [effectToRemove effectWillBeDispelled:theRaid player:thePlayer];
    [effectToRemove expire];
    [thePlayer.spellTarget removeEffect:effectToRemove];
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
    OrbsOfLight *orbs = [[OrbsOfLight alloc] initWithTitle:@"Orbs of Light" healAmnt:0 energyCost:120 castTime:1.5 andCooldown:4.0];
    [orbs setDescription:@"Heals a target for a moderate amount each time it takes damage. Lasts 10 seconds."];
    [[orbs spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[orbs spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[orbs spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
    ReactiveHealEffect *rhe = [[ReactiveHealEffect alloc] initWithDuration:20.0 andEffectType:EffectTypePositive];
    [rhe setTitle:@"orbs-of-light-effect"];
    [rhe setEffectCooldown:2.0];
    [rhe setMaxStacks:1];
    [rhe setSpriteName:@"regrow.png"];
    [rhe setAmountPerReaction:35];
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
    SwirlingLight *swirl = [[SwirlingLight alloc] initWithTitle:@"Swirling Light" healAmnt:0 energyCost:40 castTime:0.0 andCooldown:2.0];
    [swirl setDescription:@"Heals a target over 10 seconds.  Each additional stack improves all the healing of all stacks. Maximum 4 Stacks."];
	[[swirl spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanInstantHoT" ofType:@"wav"]] andTitle:@"WWFinished"];
    SwirlingLightEffect *sle = [[SwirlingLightEffect alloc] initWithDuration:10 andEffectType:EffectTypePositive];
    [sle setMaxStacks:4];
    [sle setSpriteName:@"swirling_light.png"];
    [sle setTitle:@"swirling-light-effect"];
    [sle setNumOfTicks:10];
    [sle setValuePerTick:4];
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
    LightEternal *le = [[LightEternal alloc] initWithTitle:@"Light Eternal" healAmnt:66 energyCost:220 castTime:2.25 andCooldown:0.0];
    [le setDescription:@"Heals up to 5 allies with the least health among allies for a moderate amount."];
    [[le spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[le spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[le spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
    return [le autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    NSInteger totalTargets = 5;
    
    if ([self.owner hasDivinityEffectWithTitle:@"purity-of-soul"]){
        if (arc4random() % 100 < 10){
            totalTargets = 7;
        }
    }
    NSArray *myTargets = [theRaid lowestHealthTargets:totalTargets  withRequiredTarget:thePlayer.spellTarget];
    
    for (RaidMember *healableTarget in myTargets){
        int currentTargetHealth = healableTarget.health;
        NSInteger amount = [self healingAmount];
        [self willHealTarget:healableTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:amount];
		[healableTarget setHealth:[healableTarget health] + amount];
        int newHealth = healableTarget.health;
        NSInteger finalAmount = newHealth - currentTargetHealth;
        [self didHealTarget:healableTarget inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:finalAmount];
        [self.owner playerDidHealFor:finalAmount onTarget:healableTarget fromSpell:self];
        NSInteger overheal = amount - finalAmount;
        if (overheal > 0){
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:[thePlayer spellTarget] value:[NSNumber numberWithInt:overheal] andEventType:CombatEventTypeOverheal]];
        }
    }
    
    [thePlayer setEnergy:[thePlayer energy] - [self energyCost]];

    if (self.cooldown > 0.0){
        [[thePlayer spellsOnCooldown] addObject:self];
        self.cooldownRemaining = self.cooldown;
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
    Respite *respite = [[Respite alloc] initWithTitle:@"Respite" healAmnt:0 energyCost:0 castTime:0.0 andCooldown:60.0];
    [respite setDescription:@"Restores 360 Mana to the caster."];
    return [respite autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSInteger energyReturned = 360;
    if ([self.owner hasDivinityEffectWithTitle:@"torrent-of-faith"]){
        if (arc4random() % 100 < 10){
            energyReturned = 720;
        }
    }
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
    [wse setValuePerTick:24];
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
    WardOfAncients *woa = [[WardOfAncients alloc] initWithTitle:@"Ward of Ancients" healAmnt:0 energyCost:100 castTime:2.0 andCooldown:45.0];
    [woa setDescription:@"Covers your entire party in a protective barrier that reduces incoming damage by 40% for 6 seconds."];
    return [woa autorelease];
}
- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSArray *aliveMembers = [theRaid getAliveMembers];
    [theBoss.announcer displaySprite:@"shield_bubble.png" overRaidForDuration:6.0];
    for (RaidMember*member in aliveMembers){
        DamageTakenDecreasedEffect *dtde = [[DamageTakenDecreasedEffect alloc] initWithDuration:6 andEffectType:EffectTypePositiveInvisible];
        [dtde setTitle:@"ward-of-ancients-effect"];
        [dtde setPercentage:.4];
        [dtde setOwner:self.owner];
        [member addEffect:dtde];
        [dtde release];
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
    TouchOfHope *tol = [[TouchOfHope alloc] initWithTitle:@"Touch of Hope" healAmnt:30 energyCost:50 castTime:0.0 andCooldown:4.0];
    [tol setDescription:@"Instantly Heals your Target for a small amount and places an effect on the target that heals for a small amount over 4 seconds.  Each time the periodic effect heals it restores 12 energy."];
    return [tol autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    
    TouchOfHopeEffect *tolEffect = [[TouchOfHopeEffect alloc] initWithDuration:4.0 andEffectType:EffectTypePositive];
    [tolEffect setTitle:@"toh-effect"];
    [tolEffect setSpriteName:@"touch_of_hope.png"];
    [tolEffect setValuePerTick:7];
    [tolEffect setNumOfTicks:4];
    [tolEffect setOwner:self.owner];
    [[self.owner spellTarget] addEffect:tolEffect];
    [tolEffect release];
    
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
    [ss setDescription:@"Releases your inner light increasing your healing done and reduces cast times by 20% for 7.5 seconds."];
    return [ss autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    float modifier = 0.0;
    if ([self.owner hasDivinityEffectWithTitle:@"torrent-of-faith"]){
        if (arc4random() % 100 < 10){
            modifier = .2;
        }
    }
    [self.owner.announcer announce:@"You are filled with spiritual power."];
    Effect *soaringSpiritEffect = [[Effect alloc] initWithDuration:7.5 andEffectType:EffectTypePositive];
    [soaringSpiritEffect setOwner:self.owner];
    [soaringSpiritEffect setHealingDoneMultiplierAdjustment:.2 + modifier];
    [soaringSpiritEffect setCastTimeAdjustment:.2 + modifier];
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
    [fadingLightEffect setValuePerTick:40];
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
    Sunburst *sb = [[Sunburst alloc] initWithTitle:@"Sunburst" healAmnt:0 energyCost:200 castTime:0.0 andCooldown:10.0];
    [sb setDescription:@"Heals up to 7 injured allies for a small amount over 5 seconds."];
    return [sb autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    NSInteger totalTargets = 7;
    
    if ([self.owner hasDivinityEffectWithTitle:@"purity-of-soul"]){
        if (arc4random() % 100 < 10){
            totalTargets = 9;
        }
    }
    NSArray *sunburstTargets = [theRaid lowestHealthTargets:totalTargets withRequiredTarget:thePlayer.spellTarget];
    
    for (RaidMember *target in sunburstTargets){
        RepeatedHealthEffect *sunburstEffect = [[RepeatedHealthEffect alloc] initWithDuration:5.0 andEffectType:EffectTypePositive];
        [sunburstEffect setTitle:@"sunburst-hot"];
        [sunburstEffect setSpriteName:@"sunburst.png"];
        [sunburstEffect setNumOfTicks:5];
        [sunburstEffect setValuePerTick:4];
        [sunburstEffect setOwner:self.owner];
        [target addEffect:sunburstEffect];
        [sunburstEffect release];
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
    StarsOfAravon *spell = [[StarsOfAravon alloc] initWithTitle:@"Stars of Aravon" healAmnt:0 energyCost:49 castTime:1.75 andCooldown:0.0];
    [spell setDescription:@"Summon 4 Stars of Aravon from the heavens.  The Stars travel for 2.5 seconds before striking their target and healing them for a small amount.."];
    return [spell autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    NSInteger totalTargets = 4;
    
    if ([self.owner hasDivinityEffectWithTitle:@"purity-of-soul"]){
        if (arc4random() % 100 < 10){
            totalTargets = 6;
        }
    }
    NSArray *starTargets = [theRaid lowestHealthTargets:totalTargets withRequiredTarget:nil];
    
    NSTimeInterval healDelay = 1.75;
    for (RaidMember *starTarget in starTargets){
        ProjectileEffect *starProjectile = [[ProjectileEffect alloc] initWithSpriteName:@"star.png" target:starTarget andCollisionTime:healDelay];
        [starProjectile setCollisionParticleName:@"star_explosion.plist"];
        [theBoss.announcer displayProjectileEffect:starProjectile];
        DelayedHealthEffect *starDelayedHealthEff = [[DelayedHealthEffect alloc] initWithDuration:healDelay andEffectType:EffectTypePositiveInvisible];
        [starDelayedHealthEff setIsIndependent:YES];
        [starDelayedHealthEff setOwner:self.owner];
        [starDelayedHealthEff setValue:19];
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
    
    [defaultSpell setDescription:@"Reduces damage done to a target by 50%% for 5 seconds.  When the effect expires it heals the target for a moderate amount."];
    BlessedArmorEffect *bae = [[BlessedArmorEffect alloc] initWithDuration:5.0 andEffectType:EffectTypePositive];
    [bae setSpriteName:@"blessed_armor.png"];
    [bae setTitle:@"blessed-armor-eff"];
    [bae setValue:50];
    [defaultSpell setAppliedEffect:bae];
    [bae release];
    return [defaultSpell autorelease];
}
@end

@implementation Attunement
- (id)initWithTitle:(NSString *)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd {
    if (self = [super initWithTitle:ttle healAmnt:healAmnt energyCost:nrgyCost castTime:time andCooldown:cd]){
        self.spellType = SpellTypeEmpowering;
    }
    return self;
}
+ (id)defaultSpell {
    Attunement *defaultSpell = [[Attunement alloc] initWithTitle:@"Attunement" healAmnt:0 energyCost:20 castTime:0.0 andCooldown:40.0];
    
    [defaultSpell setDescription:@"For 12 Seconds, all spells you cast cost 50%% less."];
    return [defaultSpell autorelease];
}
- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    float adjustmentAdjustment = 0.0;
    if ([self.owner hasDivinityEffectWithTitle:@"torrent-of-faith"]){
        if (arc4random() % 100 < 10){
            adjustmentAdjustment = .5;
        }
    }
    Effect *costReductionEffect = [[Effect alloc] initWithDuration:12.0 andEffectType:EffectTypePositive];
    [costReductionEffect setTitle:@"attunement-effect"];
    [costReductionEffect setSpellCostAdjustment:.5 + adjustmentAdjustment];
    [thePlayer addEffect:costReductionEffect];
    [costReductionEffect release];

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



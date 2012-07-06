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

@interface Spell ()
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *spellID;
@property (nonatomic, readwrite) NSTimeInterval tempCooldown;
@end

@implementation Spell

@synthesize title, healingAmount, energyCost, castTime, percentagesPerTarget, targets, description, spellAudioData, cooldownRemaining, cooldown, spellID, appliedEffect, owner, info, tempCooldown, hasCheckedDivinity;

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
    Player *owningPlayer = (Player*)self.owner;
    float finalCastTime = castTime * owningPlayer.castTimeAdjustment;
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
    return finalAmount * self.owner.healingDoneMultiplier;
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
    self.hasCheckedDivinity = YES;
}

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
    if (!self.hasCheckedDivinity) {
        [self checkDivinity];
    }
    
	if ([self targets] <= 1){
        int currentTargetHealth = [thePlayer spellTarget].health;
        NSInteger amount = [self healingAmount];
        [self willHealTarget:[thePlayer spellTarget] inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:amount];
		[[thePlayer spellTarget] setHealth:[[thePlayer spellTarget] health] + amount];
        int newHealth = [thePlayer spellTarget].health;
        NSInteger finalAmount = newHealth - currentTargetHealth;
        [self didHealTarget:[thePlayer spellTarget] inRaid:theRaid withBoss:theBoss andPlayers:[NSArray arrayWithObject:thePlayer] forAmount:finalAmount];
        [thePlayer.logger logEvent:[CombatEvent eventWithSource:self.owner target:[thePlayer spellTarget] value:[NSNumber numberWithInt:finalAmount] andEventType:CombatEventTypeHeal]]; 
		[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
        [self applyEffectToTarget:thePlayer.spellTarget];
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
                [thePlayer.logger logEvent:[CombatEvent eventWithSource:self.owner target:currentTarget value:[NSNumber numberWithInt:finalAmount] andEventType:CombatEventTypeHeal]]; 
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
@synthesize hasBlessedPower, hasWardingTouch, hasHealingHands;
+(id)defaultSpell{
    Heal *heal = [[Heal alloc] initWithTitle:@"Heal" healAmnt:35 energyCost:22 castTime:1.75 andCooldown:0.0];
    [heal setDescription:@"Heals your target for a small amount."];
    [[heal spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[heal spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[heal spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
    return [heal autorelease];
}

- (void)checkDivinity {
    Player *owningPlayer = (Player*)self.owner;
    if (owningPlayer.divinityConfig){
        for (Effect *eff in owningPlayer.activeEffects){
            if (eff.effectType == EffectTypeDivinity){
                if ([[(DivinityEffect*)eff divinityKey] isEqualToString:@"Blessed Power"]){
                    self.hasBlessedPower = YES;
                    break;
                } else if ([[(DivinityEffect*)eff divinityKey] isEqualToString:@"Healing Hands"]){
                    self.hasHealingHands = YES;
                    break;
                } else if ([[(DivinityEffect*)eff divinityKey] isEqualToString:@"Warding Touch"]){
                    self.hasWardingTouch = YES;
                }
            }
        }
    } else {
        NSLog(@"Owning Player does not have a divinity config");
    }
    [super checkDivinity];
}

- (void)didHealTarget:(RaidMember *)target inRaid:(Raid *)raid withBoss:(Boss *)boss andPlayers:(NSArray *)players forAmount:(NSInteger)amount {
    if (self.hasHealingHands) {
        if (arc4random() % 100 < 10){
            NSInteger critBonus = (int)round(amount * .5);
            [target setHealth:target.health + critBonus]; //A Crit!
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:[NSNumber numberWithInt:critBonus] andEventType:CombatEventTypeHeal]]; 
        }
    }
    
    if (self.hasWardingTouch){
        DamageTakenDecreasedEffect *reduceDamage = [[DamageTakenDecreasedEffect alloc] initWithDuration:15 andEffectType:EffectTypeNegativeInvisible];
        [reduceDamage setTitle:@"heal-div-wardingtouch"];
        [reduceDamage setOwner:self.owner];
        [reduceDamage setPercentage:.05];
        [target addEffect:reduceDamage];
        [reduceDamage release];
    }
    
    if (self.hasBlessedPower) {
        if (arc4random() % 100 < 10){
            [[(Player*)self.owner announcer] announce:@"Your mind is filled with power."];
            Effect *castTimeReduction = [[Effect alloc] initWithDuration:5.0 andEffectType:EffectTypePositive];
            [castTimeReduction setTitle:@"blessed-power-haste"];
            [castTimeReduction setOwner:self.owner];
            [castTimeReduction setSpriteName:@"default_divinity.png"];
            [castTimeReduction setCastTimeAdjustment:.25];
            [(Player*)self.owner addEffect:castTimeReduction];
            [castTimeReduction release];
        }
    }
}

@end

@implementation GreaterHeal
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
+(id)defaultSpell
{
	ForkedHeal *forkedHeal = [[ForkedHeal alloc] initWithTitle:@"Forked Heal" healAmnt:55 energyCost:100 castTime:1.75 andCooldown:0.0];//10h/e
    [forkedHeal setDescription:@"Heals up to two targets simultaneously."];
    [[forkedHeal spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[forkedHeal spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[forkedHeal spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
	return [forkedHeal autorelease];
}

-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSArray *myTargets = [theRaid lowestHealthTargets:2 withRequiredTarget:thePlayer.spellTarget];
    
    int i = 0; 
    for (RaidMember *healableTarget in myTargets){
        if (i == 0){
            [healableTarget setHealth:healableTarget.health + self.healingAmount];
        }else{
            [healableTarget setHealth:healableTarget.health + (int)round(self.healingAmount * .66)];
        }
        i++;
    }
    
    [thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
    
    
    if (self.cooldown > 0.0){
        [[thePlayer spellsOnCooldown] addObject:self];
        self.cooldownRemaining = self.cooldown;
    }
}
@end

@implementation Regrow
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
    [thePlayer.spellTarget.activeEffects removeObject:effectToRemove];
    
}

@end

@implementation  OrbsOfLight
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
+(id)defaultSpell{
    LightEternal *le = [[LightEternal alloc] initWithTitle:@"Light Eternal" healAmnt:66 energyCost:220 castTime:2.25 andCooldown:0.0];
    [le setDescription:@"Heals up to 5 allies with the least health among allies for a moderate amount."];
    [[le spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[le spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[le spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
    return [le autorelease];
}
-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSArray *myTargets = [theRaid lowestHealthTargets:5  withRequiredTarget:thePlayer.spellTarget];
    
    for (RaidMember *healableTarget in myTargets){
        [healableTarget setHealth:healableTarget.health + self.healingAmount];
    }
    
    [thePlayer setEnergy:[thePlayer energy] - [self energyCost]];


    if (self.cooldown > 0.0){
        [[thePlayer spellsOnCooldown] addObject:self];
        self.cooldownRemaining = self.cooldown;
    }
}

@end


@implementation Respite
+ (id)defaultSpell{
    Respite *respite = [[Respite alloc] initWithTitle:@"Respite" healAmnt:0 energyCost:0 castTime:0.0 andCooldown:60.0];
    [respite setDescription:@"Restores 360 Mana to the caster."];
    return [respite autorelease];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    [thePlayer setEnergy:thePlayer.energy + 360];
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];

}
@end

@implementation WanderingSpirit
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
+ (id)defaultSpell {
    WardOfAncients *woa = [[WardOfAncients alloc] initWithTitle:@"Ward of Ancients" healAmnt:0 energyCost:100 castTime:2.0 andCooldown:45.0];
    [woa setDescription:@"Covers your entire party in a protective barrier that reduces incoming damage by 40% for 6 seconds."];
    return [woa autorelease];
}
- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)theTime{
    NSArray *aliveMembers = [theRaid getAliveMembers];
    [theBoss.announcer displaySprite:@"shield_bubble.png" overRaidForDuration:6.0];
    for (RaidMember*member in aliveMembers){
        DamageTakenDecreasedEffect *dtde = [[DamageTakenDecreasedEffect alloc] initWithDuration:6 andEffectType:EffectTypeNegativeInvisible];
        [dtde setTitle:@"ward-of-ancients-effect"];
        [dtde setPercentage:.4];
        [dtde setOwner:self.owner];
        [member addEffect:dtde];
        [dtde release];
    }
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
    
}
@end

#pragma mark -
#pragma mark Test Spells
@implementation QuickHeal
+(id)defaultSpell
{
	QuickHeal *quickHeal = [[QuickHeal alloc] initWithTitle:@"Quick Heal" healAmnt:25 energyCost:7 castTime:1.0 andCooldown:.5]; //3.5h/e
	
	return [quickHeal autorelease];
}
@end

@implementation SuperHeal
+(id)defaultSpell
{
	SuperHeal *bigHeal = [[SuperHeal alloc] initWithTitle:@"Super Heal" healAmnt:75 energyCost:10 castTime:2.0 andCooldown:.5];//7.5h/e

	return [bigHeal autorelease];
}
@end



@implementation SurgeOfLife
+(id)defaultSpell
{
	SurgeOfLife *surgeOfLife = [[SurgeOfLife alloc] initWithTitle:@"Surge of Life" healAmnt:150 energyCost:14 castTime:1.5 andCooldown:.5];//10.7h/e
	NSArray *surgePercentages = [NSArray arrayWithObjects:[[[NSNumber alloc] initWithDouble:.50] autorelease], [[[NSNumber alloc] initWithDouble:.25] autorelease], [[[NSNumber alloc] initWithDouble:.25] autorelease], nil];
	[surgeOfLife setTargets:3 withPercentagesPerTarget:surgePercentages];
	return [surgeOfLife autorelease];
}
@end

@implementation HealingBreath
+(id)defaultSpell
{
	HealingBreath *healBreath = [[HealingBreath alloc] initWithTitle:@"Healing Breath" healAmnt:20 energyCost:8 castTime:1.5 andCooldown:0.0];
	[healBreath setDescription:@"A spell that restores a small amount of health"];
	return [healBreath autorelease];
}
@end

@implementation GloriousBeam
+(id)defaultSpell
{
	GloriousBeam *gloryBeam = [[GloriousBeam alloc] initWithTitle:@"Glorious Beam" healAmnt:18 energyCost:9 castTime:0.0 andCooldown:0.1];
	[gloryBeam setDescription:@"A spell that instantly heals your target, but isn't very efficient."];
	return [gloryBeam autorelease];
}
-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)timeDelta{
	[super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
	ShieldEffect *shieldEffect = [[ShieldEffect alloc] initWithDuration:20 andEffectType:EffectTypePositive];
	[shieldEffect setAmountToShield:22];
	[[thePlayer spellTarget] addEffect:shieldEffect];
    [shieldEffect release];
}
@end

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

#pragma mark -
#pragma mark Shaman Spells
@implementation RoarOfLife
+(id)defaultSpell
{
	RoarOfLife *roarOfLife = [[RoarOfLife alloc] initWithTitle:@"Roar of Life" healAmnt:18 energyCost:8 castTime:1.0 andCooldown:0.0];
	[roarOfLife setDescription:@"A spell that heals a minor amount now and then more over time."];
	[[roarOfLife spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[roarOfLife spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[roarOfLife spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
	return [roarOfLife autorelease];
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime
{
	[[thePlayer spellTarget] setHealth:[[thePlayer spellTarget] health] + [self healingAmount]];
	[[thePlayer spellTarget] addEffect:[RoarOfLifeEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];

}
@end

@implementation WoundWeaving
+(id)defaultSpell{
	WoundWeaving *woundWeaving = [[WoundWeaving alloc] initWithTitle:@"Wound Weaving" healAmnt:0 energyCost:6 castTime:0.0 andCooldown:0.0];
	[woundWeaving setDescription:@"An extremely efficient effect that regenerates the health of a the target over time."];
	[[woundWeaving spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanInstantHoT" ofType:@"wav"]] andTitle:@"WWFinished"];
	return [woundWeaving autorelease];
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime{
	WoundWeavingEffect *wwEffect = [WoundWeavingEffect defaultEffect];
	[[thePlayer spellTarget] addEffect:wwEffect];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}

@end

@implementation SurgingGrowth
+(id)defaultSpell{
	SurgingGrowth *sg = [[SurgingGrowth alloc] initWithTitle:@"Surging Growth" healAmnt:0 energyCost:7 castTime:0.0 andCooldown:0.0];
	[sg setDescription:@"Heals increasing amounts for 5 seconds until it heals a moderate amount on expiration"];
	[[sg spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanInstantHoT" ofType:@"wav"]] andTitle:@"SGFinished"];
	return [sg autorelease];
	
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime{
	[[thePlayer spellTarget] addEffect:[SurgingGrowthEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}

@end

@implementation FieryAdrenaline
+(id)defaultSpell{
	FieryAdrenaline *fa = [[FieryAdrenaline alloc] initWithTitle:@"Fiery Adrenaline" healAmnt:0 energyCost:4 castTime:1.0 andCooldown:0.0];
	[fa setDescription:@"Heals a small amount over 10 seconds.  If the target is struck while under this effect, the duration refreshes."];
	[[fa spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"FAdrStart"];
	[[fa spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"FAdrFizzle"];
	[[fa spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanInstantHoT" ofType:@"wav"]] andTitle:@"FAdrFinish"];
	return [fa autorelease];
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime{
	[[thePlayer spellTarget] addEffect:[FieryAdrenalineEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}

@end

@implementation TwoWinds
+(id)defaultSpell{
	TwoWinds* twoWinds = [[TwoWinds alloc] initWithTitle:@"Two Winds" healAmnt:0 energyCost:15 castTime:1.0 andCooldown:0.0];
	[twoWinds setDescription:@"Heals 2 targets for a moderate amount over 12 seconds"];
	NSArray *twoWindsPercs = [NSArray arrayWithObjects:[[[NSNumber alloc] initWithDouble:0] autorelease], [[[NSNumber alloc] initWithDouble:0] autorelease], nil];
	[twoWinds setTargets:2 withPercentagesPerTarget:twoWindsPercs];
	[[twoWinds spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"2WindStart"];
	[[twoWinds spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"2WindFizzle"];
	[[twoWinds spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanInstantHoT" ofType:@"wav"]] andTitle:@"2WindFinish"];
	return [twoWinds autorelease];
	
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime{
	
	[[thePlayer spellTarget] addEffect:[TwoWindsEffect defaultEffect]];
	
	if ([[thePlayer additionalTargets] count] > 1){
		[[[thePlayer additionalTargets] objectAtIndex:1] addEffect:[TwoWindsEffect defaultEffect]];
	}
	
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}
@end

@implementation SymbioticConnection
+(id)defaultSpell{
	SymbioticConnection *symC = [[SymbioticConnection alloc] initWithTitle:@"Symbiotic Connection" healAmnt:20 energyCost:10 castTime:1.5 andCooldown:0];
	[symC setDescription:@"Heals your primary target immediately for a moderate amount and heals your second target for a moderate amount over 9 seconds"];
	NSArray *symbPercs = [NSArray arrayWithObjects:[[[NSNumber alloc] initWithDouble:1] autorelease], [[[NSNumber alloc] initWithDouble:0] autorelease], nil];
	[symC setTargets:2 withPercentagesPerTarget:symbPercs];
	[[symC spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"SymbStart"];
	[[symC spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"SymbFizzle"];
	[[symC spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCast" ofType:@"wav"]] andTitle:@"SymbFinish"];
	return [symC autorelease];
	
	
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime{
	[[thePlayer spellTarget] setHealth:[[thePlayer spellTarget] health] + [self healingAmount]];
	
	if ([[thePlayer additionalTargets] count] > 1){
		[[[thePlayer additionalTargets] objectAtIndex:1] addEffect:[SymbioticConnectionEffect defaultEffect]];
	}
	
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}

@end

@implementation UnleashedNature
+(id)defaultSpell{
	UnleashedNature *unlNature = [[UnleashedNature alloc] initWithTitle:@"Unleashed Nature" healAmnt:33 energyCost:20 castTime:1.5 andCooldown:0.0];
	[unlNature setDescription:@"Heals up to 3 targets for a moderate amount and continues to heal them for a small amount over 12 seconds"];
	NSArray *unlPercs = [NSArray arrayWithObjects:[[[NSNumber alloc] initWithDouble:.33] autorelease], [[[NSNumber alloc] initWithDouble:.33] autorelease], [[[NSNumber alloc] initWithDouble:.33] autorelease], nil];
	[[unlNature spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicCasting" ofType:@"wav"]] andTitle:@"UnlNatStart"];
	[[unlNature spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"UnlNatFizzle"];
	[[unlNature spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/ShamanBigHealCast" ofType:@"wav"]] andTitle:@"UnlNatFinish"];
	[unlNature setTargets:3 withPercentagesPerTarget:unlPercs];
	return [unlNature autorelease];
	
	
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime{
	
	if ([self targets] <= 1){
		[[thePlayer spellTarget] setHealth:[[thePlayer spellTarget] health] + [self healingAmount]];
		[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
	}
	else if ([self targets] > 1){
		int limit = [self targets];
		if ([[thePlayer additionalTargets] count] < limit) limit = [[thePlayer additionalTargets] count];
		for (int i = 0; i < limit; i++){
			RaidMember *currentTarget = [[thePlayer additionalTargets] objectAtIndex:i];
			if ([currentTarget isDead]) continue;
			else{
				double PercentageThisTarget = [[[self percentagesPerTarget] objectAtIndex:i] doubleValue];
				//NSLog(@"PercentageThisTarget: %1.3f", PercentageThisTarget);
				[currentTarget setHealth:[[thePlayer spellTarget] health] + ([self healingAmount]*PercentageThisTarget)];
				[currentTarget addEffect:[UnleashedNatureEffect defaultEffect]];
			}
			
		}
		[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
	}
}

@end

#pragma mark -
#pragma mark Seer Spells
@implementation ShiningAegis
+(id)defaultSpell{
	ShiningAegis *sa = [[ShiningAegis alloc] initWithTitle:@"Shining Aegis" healAmnt:18 energyCost:8 castTime:1.0 andCooldown:0.0];	
	[sa setDescription:@"Heals the target for a moderate amount and leaves a shield on that target to prevent some further damage"];
	[[sa spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerBasicCasting" ofType:@"wav"]] andTitle:@"SAStart"];
	[[sa spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerBasicFizzle" ofType:@"wav"]] andTitle:@"SAFizzle"];
	[[sa spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerBasicCast" ofType:@"wav"]] andTitle:@"SAFinish"];
	return [sa autorelease];
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime
{
	[[thePlayer spellTarget] setHealth:[[thePlayer spellTarget] health] + [self healingAmount]];
	[[thePlayer spellTarget] addEffect:[ShiningAegisEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
	
}
@end

@implementation Bulwark
+(id)defaultSpell{
	Bulwark *bulwark = [[Bulwark alloc] initWithTitle:@"Bulwark" healAmnt:0 energyCost:7 castTime:1.0 andCooldown:0.0];
	[bulwark setDescription:@"Sets a shield that absorbs a moderate amount of damage on the target"];
	[[bulwark spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerBasicCasting" ofType:@"wav"]] andTitle:@"BWStart"];
	[[bulwark spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerBasicFizzle" ofType:@"wav"]] andTitle:@"BWFizzle"];
	[[bulwark spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerInstantShield" ofType:@"wav"]] andTitle:@"BWFinish"];
	return [bulwark autorelease];
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime
{
	[[thePlayer spellTarget] addEffect:[BulwarkEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];	
}
@end

@implementation EtherealArmor
+(id)defaultSpell{
	EtherealArmor * eaSpell = [[EtherealArmor alloc] initWithTitle:@"Ethereal Armor" healAmnt:0 energyCost:5 castTime:0.0 andCooldown:0.0];
	[eaSpell setDescription:@"Puts a protective spell on the target that lowers incoming damage by 25% for 15 seconds"];
	[[eaSpell spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/SeerProtectiveCast" ofType:@"wav"]] andTitle:@"EAFinish"];
	return [eaSpell autorelease];
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime
{
	[[thePlayer spellTarget] addEffect:[EtherealArmorEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}
@end


#pragma mark -
#pragma mark Ritualist Spells





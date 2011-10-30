//
//  Spell.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GameObjects.h"
#import	"AudioController.h"

@implementation Spell

@synthesize title, healingAmount, energyCost, castTime, percentagesPerTarget, targets, description, spellAudioData;

-(id)initWithTitle:(NSString*)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd
{
	title = ttle;
	healingAmount = healAmnt;
	energyCost = nrgyCost;
	castTime = time;
	coolDown = cd;
	isMultitouch = NO;
	spellAudioData = [[SpellAudioData alloc] init];
	return self;
}
+(id)defaultSpell{
	Spell* def = [[[self class] alloc] initWithTitle:@"DefaultSpell" healAmnt:0 energyCost:0 castTime:0.0 andCooldown:0];
	return def;
}

-(NSString*)description{
	return [NSString stringWithFormat:@"Energy Cost : %i \n %@", energyCost, description];
	
}

-(SpellCardView*)spellCardView{
	
	
}

-(BOOL)isInstant
{
	return castTime == 0.0;
}

-(BOOL)hasCastSounds
{
	return NO;
	//return (castSoundFileURL != nil);
}

-(void)setTargets:(NSInteger)numOfTargets withPercentagesPerTarget:(NSArray*)percentages
{
	if (numOfTargets <= 1){
		targets = 1;
		isMultitouch = NO;
	}
	else if (numOfTargets > 1){
		targets = numOfTargets;
		percentagesPerTarget = [percentages copyWithZone:nil];
		isMultitouch = YES;
	}
	
}

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
{
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
			}
			
		}
		[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
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


+(Spell*)spellFromTitle:(NSString*)ttle
{
	//Shaman Spells
	if ([ttle isEqualToString:@"Roar of Life"]){
		return [RoarOfLife defaultSpell];
	}
	if ([ttle isEqualToString:@"Wound Weaving"]){
		return [WoundWeaving defaultSpell];
	}
	if ([ttle isEqualToString:@"Surging Growth"]){
		return [SurgingGrowth defaultSpell];
	}
	if ([ttle isEqualToString:@"Fiery Adrenaline"]){
		return [FieryAdrenaline defaultSpell];
	}
	if ([ttle isEqualToString:@"Two Winds"]){
		return [TwoWinds defaultSpell];
	}
	if ([ttle isEqualToString:@"Symbiotic Connection"]){
		return [SymbioticConnection defaultSpell];
	}
	if ([ttle isEqualToString:@"Unleashed Nature"]){
		return [UnleashedNature defaultSpell];
	}
	
	//Seer Spells
	if ([ttle isEqualToString:@"Shining Aegis"]){
		return [ShiningAegis defaultSpell];
	}
	if ([ttle isEqualToString:@"Bulwark"]){
		return [Bulwark defaultSpell];
	}
	if ([ttle isEqualToString:@"Ethereal Armor"]){
		return [EtherealArmor defaultSpell];
	}
	
	//TEST SPELLS
	if ([ttle isEqualToString:@"Quick Heal"]){
		return [QuickHeal defaultSpell];
	}
	if ([ttle isEqualToString:@"Super Heal"]){
		return [SuperHeal defaultSpell];
	}
	if ([ttle isEqualToString:@"Forked Heal"]){
		return [ForkedHeal defaultSpell];
	}
	if ([ttle isEqualToString:@"Surge of Life"]){
		return [SurgeOfLife defaultSpell];
	}
	
	if ([ttle isEqualToString:@"Healing Breath"]){
		return [HealingBreath defaultSpell];
	}
	if ([ttle isEqualToString:@"Glorious Beam"]){
		return [GloriousBeam defaultSpell];
	}
	
	if ([ttle isEqualToString:@"Hasty Brew"]){
		return [HastyBrew defaultSpell];
	}
	
	return nil;
}
@end

#pragma mark -
#pragma mark Test Spells
@implementation QuickHeal
+(id)defaultSpell
{
	QuickHeal *quickHeal = [[QuickHeal alloc] initWithTitle:@"Quick Heal" healAmnt:25 energyCost:7 castTime:1.0 andCooldown:.5]; //3.5h/e
	
	return quickHeal;
}
@end

@implementation SuperHeal
+(id)defaultSpell
{
	SuperHeal *bigHeal = [[SuperHeal alloc] initWithTitle:@"Super Heal" healAmnt:75 energyCost:10 castTime:2.0 andCooldown:.5];//7.5h/e

	return bigHeal;
}
@end

@implementation ForkedHeal
+(id)defaultSpell
{
	ForkedHeal *forkedHeal = [[ForkedHeal alloc] initWithTitle:@"Forked Heal" healAmnt:100 energyCost:10 castTime:1.75 andCooldown:.5];//10h/e
	NSArray *forkedPercentages = [NSArray arrayWithObjects:[[NSNumber alloc] initWithDouble:.50], [[NSNumber alloc] initWithDouble:.50], nil];
	[forkedHeal setTargets:2 withPercentagesPerTarget:forkedPercentages];
	return forkedHeal;
}
@end

@implementation SurgeOfLife
+(id)defaultSpell
{
	SurgeOfLife *surgeOfLife = [[SurgeOfLife alloc] initWithTitle:@"Surge of Life" healAmnt:150 energyCost:14 castTime:1.5 andCooldown:.5];//10.7h/e
	NSArray *surgePercentages = [NSArray arrayWithObjects:[[NSNumber alloc] initWithDouble:.50], [[NSNumber alloc] initWithDouble:.25], [[NSNumber alloc] initWithDouble:.25], nil];
	[surgeOfLife setTargets:3 withPercentagesPerTarget:surgePercentages];
	return surgeOfLife;
}
@end

@implementation HealingBreath
+(id)defaultSpell
{
	HealingBreath *healBreath = [[HealingBreath alloc] initWithTitle:@"Healing Breath" healAmnt:20 energyCost:8 castTime:1.5 andCooldown:0.0];
	[healBreath setDescription:@"A spell that restores a small amount of health"];
	return healBreath;
}
@end

@implementation GloriousBeam
+(id)defaultSpell
{
	GloriousBeam *gloryBeam = [[GloriousBeam alloc] initWithTitle:@"Glorious Beam" healAmnt:18 energyCost:9 castTime:0.0 andCooldown:0.1];
	[gloryBeam setDescription:@"A spell that instantly heals your target, but isn't very efficient."];
	return gloryBeam;
}
-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(NSDate *)theTime{
	[super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:theTime];
	ShieldEffect *shieldEffect = [[ShieldEffect alloc] initWithDuration:20 andEffectType:EffectTypePositive];
	[shieldEffect setAmountToShield:22];
	[[thePlayer spellTarget] addEffect:shieldEffect];
	NSLog(@"Added a shield to someone");
}
@end

@implementation HastyBrew
@synthesize chargeStart, chargeEnd;
+(id)defaultSpell{
	HastyBrew *hastyBrew = [[HastyBrew alloc] initWithTitle:@"Hasty Brew" healAmnt:10 energyCost:8 castTime:1.0 andCooldown:0.0];
	[hastyBrew setDescription:@"A spell that heals a small amount but can be charged to heal up to twice as much"];
	return hastyBrew;
}

-(void)beginCharging:(NSDate*)startTime{
	chargeStart = [startTime copyWithZone:nil];
}
-(void)endCharging:(NSDate*)endTime{
	chargeEnd = [endTime copyWithZone:nil];
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
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
	[[roarOfLife spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicCasting" ofType:@"wav"]] andTitle:@"ROLStart"];
	[[roarOfLife spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"ROLFizzle"];
	[[roarOfLife spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicCast" ofType:@"wav"]] andTitle:@"ROLFinish"];
	return roarOfLife;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
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
	[[woundWeaving spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanInstantHoT" ofType:@"wav"]] andTitle:@"WWFinished"];
	return woundWeaving;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime{
	WoundWeavingEffect *wwEffect = [WoundWeavingEffect defaultEffect];
	[[thePlayer spellTarget] addEffect:wwEffect];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
	[wwEffect release];
}

@end

@implementation SurgingGrowth
+(id)defaultSpell{
	SurgingGrowth *sg = [[SurgingGrowth alloc] initWithTitle:@"Surging Growth" healAmnt:0 energyCost:7 castTime:0.0 andCooldown:0.0];
	[sg setDescription:@"Heals increasing amounts for 5 seconds until it heals a moderate amount on expiration"];
	[[sg spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanInstantHoT" ofType:@"wav"]] andTitle:@"SGFinished"];
	return sg;
	
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime{
	[[thePlayer spellTarget] addEffect:[SurgingGrowthEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}

@end

@implementation FieryAdrenaline
+(id)defaultSpell{
	FieryAdrenaline *fa = [[FieryAdrenaline alloc] initWithTitle:@"Fiery Adrenaline" healAmnt:0 energyCost:4 castTime:1.0 andCooldown:0.0];
	[fa setDescription:@"Heals a small amount over 10 seconds.  If the target is struck while under this effect, the duration refreshes."];
	[[fa spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicCasting" ofType:@"wav"]] andTitle:@"FAdrStart"];
	[[fa spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"FAdrFizzle"];
	[[fa spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanInstantHoT" ofType:@"wav"]] andTitle:@"FAdrFinish"];
	return fa;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime{
	[[thePlayer spellTarget] addEffect:[FieryAdrenalineEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}

@end

@implementation TwoWinds
+(id)defaultSpell{
	TwoWinds* twoWinds = [[TwoWinds alloc] initWithTitle:@"Two Winds" healAmnt:0 energyCost:15 castTime:1.0 andCooldown:0.0];
	[twoWinds setDescription:@"Heals 2 targets for a moderate amount over 12 seconds"];
	NSArray *twoWindsPercs = [NSArray arrayWithObjects:[[NSNumber alloc] initWithDouble:0], [[NSNumber alloc] initWithDouble:0], nil];
	[twoWinds setTargets:2 withPercentagesPerTarget:twoWindsPercs];
	[[twoWinds spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicCasting" ofType:@"wav"]] andTitle:@"2WindStart"];
	[[twoWinds spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"2WindFizzle"];
	[[twoWinds spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanInstantHoT" ofType:@"wav"]] andTitle:@"2WindFinish"];
	return twoWinds;
	
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime{
	
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
	NSArray *symbPercs = [NSArray arrayWithObjects:[[NSNumber alloc] initWithDouble:1], [[NSNumber alloc] initWithDouble:0], nil];
	[symC setTargets:2 withPercentagesPerTarget:symbPercs];
	[[symC spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicCasting" ofType:@"wav"]] andTitle:@"SymbStart"];
	[[symC spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"SymbFizzle"];
	[[symC spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicCast" ofType:@"wav"]] andTitle:@"SymbFinish"];
	return symC;
	
	
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime{
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
	NSArray *unlPercs = [NSArray arrayWithObjects:[[NSNumber alloc] initWithDouble:.33], [[NSNumber alloc] initWithDouble:.33], [[NSNumber alloc] initWithDouble:.33], nil];
	[[unlNature spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicCasting" ofType:@"wav"]] andTitle:@"UnlNatStart"];
	[[unlNature spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBasicFizzle" ofType:@"wav"]] andTitle:@"UnlNatFizzle"];
	[[unlNature spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShamanBigHealCast" ofType:@"wav"]] andTitle:@"UnlNatFinish"];
	[unlNature setTargets:3 withPercentagesPerTarget:unlPercs];
	return unlNature;
	
	
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime{
	
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
	[[sa spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SeerBasicCasting" ofType:@"wav"]] andTitle:@"SAStart"];
	[[sa spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SeerBasicFizzle" ofType:@"wav"]] andTitle:@"SAFizzle"];
	[[sa spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SeerBasicCast" ofType:@"wav"]] andTitle:@"SAFinish"];
	return sa;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
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
	[[bulwark spellAudioData] setBeginSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SeerBasicCasting" ofType:@"wav"]] andTitle:@"BWStart"];
	[[bulwark spellAudioData] setInterruptedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SeerBasicFizzle" ofType:@"wav"]] andTitle:@"BWFizzle"];
	[[bulwark spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SeerInstantShield" ofType:@"wav"]] andTitle:@"BWFinish"];
	return bulwark;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
{
	[[thePlayer spellTarget] addEffect:[BulwarkEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];	
}
@end

@implementation EtherealArmor
+(id)defaultSpell{
	EtherealArmor * eaSpell = [[EtherealArmor alloc] initWithTitle:@"Ethereal Armor" healAmnt:0 energyCost:5 castTime:0.0 andCooldown:0.0];
	[eaSpell setDescription:@"Puts a protective spell on the target that lowers incoming damage by 25% for 15 seconds"];
	[[eaSpell spellAudioData] setFinishedSound:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SeerProtectiveCast" ofType:@"wav"]] andTitle:@"EAFinish"];
	return eaSpell;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
{
	[[thePlayer spellTarget] addEffect:[EtherealArmorEffect defaultEffect]];
	[thePlayer setEnergy:[thePlayer energy] - [self energyCost]];
}
@end


#pragma mark -
#pragma mark Ritualist Spells





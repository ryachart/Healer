//
//  Encounter.m
//  RaidLeader
//
//  Created by Ryan Hart on 5/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Encounter.h"
#import "PersistantDataManager.h"
#import "DataDefinitions.h"

@implementation Encounter

@synthesize title, description, numWitches, numTrolls, numOgres, theBoss, raidSize;

-(void)characterDidCompleteEncounter
{
	PersistantDataManager *dataMan = [PersistantDataManager sharedInstance];
	[[dataMan selectedCharacter] addNewEncounterCompleted:self];
	[self grantRewardToCharacter:[dataMan selectedCharacter]];
	[dataMan saveData];
}

-(void)grantRewardToCharacter:(Character*)charac{
	
}

-(id)initWithTitle:(NSString*)ttle RaidSize:(NSInteger)raidSze witches:(NSInteger)witch ogres:(NSInteger)ogre trolls:(NSInteger)troll andBoss:(Boss*)boss
{
	if (self = [super init]){
		title = ttle;
		raidSize = raidSze;
		numWitches = witch;
		numOgres = ogre;
		numTrolls = troll;
		theBoss = boss;
	
		description = @"No Description";
	}
	
	return self;
}

+(id)defaultEncounter{
	return [[[Encounter alloc] init] autorelease];
}

+(Encounter*)encounterForTitle:(NSString*)ttle
{
	if ([ttle isEqualToString:@"Ritualist Intro Encounter"]){
		return [RitualistIntroEncounter defaultEncounter];
	}
	
	if ([ttle isEqualToString:@"Seer Intro Encounter"]){
		return [SeerIntroEncounter defaultEncounter];
	}
	
	if ([ttle isEqualToString:@"Shaman Intro Encounter"]){
		return [ShamanIntroEncounter defaultEncounter];
	}
	
	if ([ttle isEqualToString:@"Fiery Demon Encounter"]){
		return [FieryDemonEncounter defaultEncounter];
	}
	
	if ([ttle isEqualToString:@"Bringer Of Evil Encounter"]){
		return [BringerOfEvilEncounter defaultEncounter];
	}
	
	return nil;
	
}

+(Encounter*)nextEncounterForRitualist:(NSString*)currentEncounterTitle
{
	NSArray *ritualistEncounterOrder = 
		[NSArray arrayWithObjects:[RitualistIntroEncounter defaultEncounter],[FieryDemonEncounter defaultEncounter], [BringerOfEvilEncounter defaultEncounter],nil];
	
	if ([currentEncounterTitle isEqualToString:@"VoidEnc"]){
		return [ritualistEncounterOrder objectAtIndex:0];
	}
	
	for (int i = 0; i < [ritualistEncounterOrder count]; i++){
		Encounter *encounter = [ritualistEncounterOrder objectAtIndex:i];
		if ([[encounter title] isEqualToString:currentEncounterTitle] && i != [ritualistEncounterOrder count]-1){
			return [ritualistEncounterOrder objectAtIndex:i+1];
		}
	}
	return nil;
	
}
+(Encounter*)nextEncounterForShaman:(NSString*)currentEncounterTitle
{
	NSArray *shamanEncounterOrder = 
	[NSArray arrayWithObjects:[ShamanIntroEncounter defaultEncounter], [FieryDemonEncounter defaultEncounter], [BringerOfEvilEncounter defaultEncounter], nil];
	
	if ([currentEncounterTitle isEqualToString:@"VoidEnc"]){
		return [shamanEncounterOrder objectAtIndex:0];
	}
	
	for (int i = 0; i < [shamanEncounterOrder count]; i++){
		Encounter *encounter = [shamanEncounterOrder objectAtIndex:i];
		if ([[encounter title] isEqualToString:currentEncounterTitle] && i != [shamanEncounterOrder count]-1){
			NSLog(@"returning %@", [[shamanEncounterOrder objectAtIndex:i+1] title]);
			return [shamanEncounterOrder objectAtIndex:i+1];
		}
	}
	return nil;
}
+(Encounter*)nextEncounterForSeer:(NSString*)currentEncounterTitle
{
	NSArray *seerEncounterOrder = 
	[NSArray arrayWithObjects:[SeerIntroEncounter defaultEncounter], [FieryDemonEncounter defaultEncounter], [BringerOfEvilEncounter defaultEncounter],nil];
	
	if ([currentEncounterTitle isEqualToString:@"VoidEnc"]){
		return [seerEncounterOrder objectAtIndex:0];
	}
	
	for (int i = 0; i < [seerEncounterOrder count]; i++){
		Encounter *encounter = [seerEncounterOrder objectAtIndex:i];
		if ([[encounter title] isEqualToString:currentEncounterTitle] && i != [seerEncounterOrder count]-1){
			return [seerEncounterOrder objectAtIndex:i+1];
		}
	}
	return nil;
}

+(Encounter*)nextEncounter:(NSArray*)completedEncounters andClass:(NSString*)characterClass
{
	NSString *furthestEncounter = [completedEncounters objectAtIndex:[completedEncounters count]-1];
	if ([characterClass isEqualToString:CharacterClassRitualist]){
		return [Encounter nextEncounterForRitualist:furthestEncounter];
	}
	if ([characterClass isEqualToString:CharacterClassSeer]){
		return [Encounter nextEncounterForSeer:furthestEncounter];
	}
	if ([characterClass isEqualToString:CharacterClassShaman]){
		return [Encounter nextEncounterForShaman:furthestEncounter];
	}
	return nil;
}


@end


@implementation RitualistIntroEncounter
+(id)defaultEncounter
{
	RitualistIntroEncounter *alchIntroEnc = [[RitualistIntroEncounter alloc] initWithTitle:@"Ritualist Intro Encounter" RaidSize:10 witches:4 ogres:4 trolls:4 andBoss:[MinorDemon defaultBoss]];
	[alchIntroEnc setDescription:@"For many weeks now, a Minor Demon has been terrorizing your encampment.  Finally, a small force has come together to annihilate this threat once and for all."];
	return [alchIntroEnc autorelease];
}
@end

@implementation SeerIntroEncounter
+(id)defaultEncounter
{
	SeerIntroEncounter *seerIntroEnc = [[SeerIntroEncounter alloc] initWithTitle:@"Seer Intro Encounter" RaidSize:10 witches:4 ogres:4 trolls:4 andBoss:[MinorDemon defaultBoss]];
	[seerIntroEnc setDescription:@"For many weeks now, a Minor Demon has been terrorizing your encampment.  Finally, a small force has come together to annihilate this threat once and for all."];
	return [seerIntroEnc autorelease];
}
-(void)grantRewardToCharacter:(Character*)charac{
	[charac addNewSpell:[Bulwark defaultSpell]];
}
@end

@implementation ShamanIntroEncounter
+(id)defaultEncounter
{
	ShamanIntroEncounter *shamanIntroEnc = [[ShamanIntroEncounter alloc] initWithTitle:@"Shaman Intro Encounter" RaidSize:10 witches:4 ogres:4 trolls:4 andBoss:[MinorDemon defaultBoss]];
	[shamanIntroEnc setDescription:@"For many weeks now, a Minor Demon has been terrorizing your encampment.  Finally, a small force has come together to annihilate this threat once and for all."];
	return [shamanIntroEnc autorelease];
}
-(void)grantRewardToCharacter:(Character*)charac{
	[charac	addNewSpell:[WoundWeaving defaultSpell]];
}
@end

@implementation FieryDemonEncounter
+(id)defaultEncounter
{
	FieryDemonEncounter *fieryDemonEnc = [[FieryDemonEncounter alloc] initWithTitle:@"Fiery Demon Encounter" RaidSize:15 witches:6 ogres:6 trolls:6 andBoss:[FieryDemon defaultBoss]];
	[fieryDemonEnc setDescription:@"After defeating the minor demom, a small flame began to grow until the demon was reborn in flames.  Additional reinforcements have rushed to your aid and a new power has ignited inside you."];
	return [fieryDemonEnc autorelease];
}
-(void)grantRewardToCharacter:(Character *)charac{
	if ([[charac characterClass] isEqualToString:CharacterClassShaman]){
		[charac addNewSpell:[SurgingGrowth defaultSpell]];
	}
	if ([[charac characterClass] isEqualToString:CharacterClassSeer]){
		[charac addNewSpell:[EtherealArmor defaultSpell]];
	}
}
@end

@implementation BringerOfEvilEncounter
+(id)defaultEncounter
{
	BringerOfEvilEncounter *boeEnc = [[BringerOfEvilEncounter alloc] initWithTitle:@"Bringer Of Evil Encounter" RaidSize:25 witches:10 ogres:10 trolls:10 andBoss:[BringerOfEvil defaultBoss]];
	[boeEnc setDescription:@"With a full army with you, you must engage the source of these demons....The Bringer of Evil himself"];
	return [boeEnc autorelease];
}
@end
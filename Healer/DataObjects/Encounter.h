//
//  Encounter.h
//  RaidLeader
//
//  Created by Ryan Hart on 5/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameObjects.h"
#import "Character.h"
@interface Encounter : NSObject {
	Boss *theBoss;
	NSInteger raidSize;
	NSInteger numWitches;
	NSInteger numOgres;
	NSInteger numTrolls;
	NSString *title;
	NSString *description;
}
@property (retain) NSString *title;
@property (retain) NSString *description;
@property (readwrite) NSInteger numWitches;
@property (readwrite) NSInteger numOgres;
@property (readwrite) NSInteger numTrolls;
@property (assign, readonly) NSInteger raidSize;
@property (retain) Boss *theBoss;
-(void)characterDidCompleteEncounter;
-(void)grantRewardToCharacter:(Character*)charac;
-(id)initWithTitle:(NSString*)ttle RaidSize:(NSInteger)raidSze witches:(NSInteger)witch ogres:(NSInteger)ogre trolls:(NSInteger)troll andBoss:(Boss*)boss;
+(id)defaultEncounter;
+(id)nextEncounter:(NSArray*)completedEncounters andClass:(NSString*)characterClass;

+(Encounter*)encounterForTitle:(NSString*)ttle;
+(Encounter*)nextEncounterForRitualist:(NSString*)currentEncounterTitle;
+(Encounter*)nextEncounterForShaman:(NSString*)currentEncounterTitle;
+(Encounter*)nextEncounterForSeer:(NSString*)currentEncounterTitle;


@end

@interface RitualistIntroEncounter : Encounter
@end

@interface SeerIntroEncounter : Encounter
@end

@interface ShamanIntroEncounter : Encounter
@end

@interface FieryDemonEncounter : Encounter
@end

@interface BringerOfEvilEncounter : Encounter
@end
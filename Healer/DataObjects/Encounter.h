//
//  Encounter.h
//  RaidLeader
//
//  Created by Ryan Hart on 5/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Raid;
@class Boss;
@class Player;

#define ENDLESS_VOID_ENCOUNTER_NUMBER 992342
@interface Encounter : NSObject
@property (nonatomic, retain) Raid *raid;
@property (nonatomic, retain) Boss *boss;
@property (nonatomic, retain) NSArray *requiredSpells;
@property (nonatomic, retain) NSArray *recommendedSpells;
@property (nonatomic, readonly) NSInteger levelNumber;
@property (nonatomic, readwrite) NSInteger difficulty;

@property (nonatomic, readonly) NSInteger reward;

- (id)initWithRaid:(Raid*)raid andBoss:(Boss*)boss andSpells:(NSArray*)spells;
- (void)encounterWillBegin;

+ (Encounter*)randomMultiplayerEncounter;
+ (Encounter*)survivalEncounterIsMultiplayer:(BOOL)multiplayer;
+ (Encounter*)encounterForLevel:(NSInteger)level isMultiplayer:(BOOL)multiplayer;
+ (NSInteger)goldForLevelNumber:(NSInteger)levelNumber;
+ (void)configurePlayer:(Player*)player forRecSpells:(NSArray*)spells;
+ (NSInteger)goldRewardForSurvivalEncounterWithDuration:(NSTimeInterval)duration;

+ (NSString *)backgroundPathForEncounter:(NSInteger)encounter;
@end

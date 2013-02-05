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
@property (nonatomic, retain) NSMutableArray *combatLog;

//PostBattle
@property (nonatomic, readonly) NSInteger reward;
@property (nonatomic, readonly) NSInteger score;
@property (nonatomic, readonly) NSInteger healingDone;
@property (nonatomic, readonly) NSInteger overhealingDone;
@property (nonatomic, readonly) NSInteger damageTaken;

//Data Loading
@property (nonatomic, retain) NSString *bossKey;

- (id)initWithRaid:(Raid*)raid andBoss:(Boss*)boss andSpells:(NSArray*)spells;
- (void)encounterWillBegin;

- (void)saveCombatLog;

+ (Encounter*)randomMultiplayerEncounter;
+ (Encounter*)survivalEncounterIsMultiplayer:(BOOL)multiplayer;
+ (Encounter*)encounterForLevel:(NSInteger)level isMultiplayer:(BOOL)multiplayer;
+ (NSInteger)goldForLevelNumber:(NSInteger)levelNumber;
+ (NSInteger)goldRewardForSurvivalEncounterWithDuration:(NSTimeInterval)duration;

+ (NSString *)backgroundPathForEncounter:(NSInteger)encounter;
@end

//
//  Encounter.h
//  Healer
//
//  Created by Ryan Hart on 5/1/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

@class Raid;
@class Enemy;
@class Player;
@class EquipmentItem;

#define ENDLESS_VOID_ENCOUNTER_NUMBER 992342
@interface Encounter : NSObject
@property (nonatomic, retain) Raid *raid;
@property (nonatomic, retain) NSArray *enemies;
@property (nonatomic, retain) NSArray *requiredSpells;
@property (nonatomic, retain) NSArray *recommendedSpells;
@property (nonatomic, readonly) NSInteger levelNumber;
@property (nonatomic, readwrite) NSInteger difficulty;
@property (nonatomic, retain) NSMutableArray *combatLog;
@property (nonatomic, retain) NSString *info;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, readwrite) NSTimeInterval duration;
@property (nonatomic, readonly) NSString *battleTrackTitle;

//PostBattle
@property (nonatomic, readonly) NSInteger reward;
@property (nonatomic, readonly) EquipmentItem *randomLootReward;
@property (nonatomic, readonly) NSInteger score;
@property (nonatomic, readonly) NSInteger healingDone;
@property (nonatomic, readonly) NSInteger overhealingDone;
@property (nonatomic, readonly) NSInteger damageTaken;

//Data Loading
@property (nonatomic, retain) NSString *bossKey;

- (id)initWithRaid:(Raid*)raid enemies:(NSArray*)enemies andSpells:(NSArray*)spells;
- (void)encounterWillBegin;
- (void)scoreTick:(float)deltaTime;

- (void)saveCombatLog;

+ (Encounter*)randomMultiplayerEncounter;
+ (Encounter*)survivalEncounterIsMultiplayer:(BOOL)multiplayer;
+ (Encounter*)encounterForLevel:(NSInteger)level isMultiplayer:(BOOL)multiplayer;
+ (NSInteger)goldForLevelNumber:(NSInteger)levelNumber;
+ (NSInteger)goldRewardForSurvivalEncounterWithDuration:(NSTimeInterval)duration;
+ (NSArray *)epicItemsForLevelNumber:(NSInteger)levelNumber;
+ (NSArray *)legendaryItemsForLevelNumber:(NSInteger)levelNumber;

+ (NSString *)backgroundPathForEncounter:(NSInteger)encounter;
@end

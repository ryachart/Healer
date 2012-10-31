//
//  PersistantDataManager.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#define MAX_CHARACTERS 5

#define CURRENT_MODE [PersistantDataManager currentMode]

extern NSString* const PlayerHighestLevelAttempted;
extern NSString* const PlayerHighestLevelCompleted;
extern NSString* const PlayerRemoteObjectIdKey;

typedef enum {
    DifficultyModeNormal = 0,
    DifficultyModeHard
} DifficultyMode;

@interface PersistantDataManager : NSObject

+ (DifficultyMode)currentMode;
+ (void)setDifficultyMode:(DifficultyMode)diffMode;

+ (BOOL)hasShownNormalModeCompleteScene;
+ (void)normalModeCompleteSceneShown;
+ (BOOL)hardModeUnlocked;

+ (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level withMode:(DifficultyMode)diffMode;
+ (NSInteger)levelRatingForLevel:(NSInteger)level withMode:(DifficultyMode)diffMode;
+ (NSInteger)highestLevelCompletedForMode:(DifficultyMode)diffMode;
+ (NSInteger)highestLevelAttemptedForMode:(DifficultyMode)diffMode;

+ (void)failLevelInCurrentMode:(NSInteger)level;
+ (void)completeLevelInCurrentMode:(NSInteger)level;

+ (BOOL)isMultiplayerUnlocked;

//Spells
+ (void)setUsedSpells:(NSArray*)spells;
+ (NSArray*)lastUsedSpells;

//Parse!
+ (void)saveRemotePlayer;

//DEBUG
+ (void)clearLevelRatings;

+ (void)setPlayerObjectInformation:(PFObject*)obj;

@end
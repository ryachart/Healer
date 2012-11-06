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

extern NSString* const PlayerHighestLevelAttempted;
extern NSString* const PlayerHighestLevelCompleted;
extern NSString* const PlayerRemoteObjectIdKey;

@interface PlayerDataManager : NSObject

+ (NSInteger)challengeForLevelNumber:(NSInteger)levelNum;
+ (void)challengeSelected:(NSInteger)challenge forLevelNumber:(NSInteger)levelNum;

+ (BOOL)hasShownNormalModeCompleteScene;
+ (void)normalModeCompleteSceneShown;

+ (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level;
+ (NSInteger)levelRatingForLevel:(NSInteger)level;
+ (NSInteger)highestLevelCompleted;
+ (NSInteger)highestLevelAttempted;

+ (void)failLevelInCurrentMode:(NSInteger)level;
+ (void)completeLevel:(NSInteger)level;

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
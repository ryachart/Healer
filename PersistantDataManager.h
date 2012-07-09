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
#define SAVE_FILE_NAME @"SavedCharacterData"

extern NSString* const PlayerHighestLevelAttempted;
extern NSString* const PlayerHighestLevelCompleted;
extern NSString* const PlayerRemoteObjectIdKey;

@interface PlayerDataManager 

+ (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level;
+ (NSInteger)levelRatingForLevel:(NSInteger)level;
+ (NSInteger)highestLevelCompleted;
+ (NSInteger)highestLevelAttempted;

//Parse!
+ (void)saveRemotePlayer;

//DEBUG
+ (void)clearLevelRatings;

+ (void)setPlayerObjectInformation:(PFObject*)obj;

@end
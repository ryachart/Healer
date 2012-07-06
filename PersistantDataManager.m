//
//  PersistantDataManager.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PersistantDataManager.h"

NSString* const PlayerHighestLevelAttempted = @"com.healer.playerHighestLevelAttempted";
NSString* const PlayerHighestLevelCompleted = @"com.healer.playerHighestLevelCompleted";
NSString* const PlayerLevelRatingKeyPrefix = @"com.healer.playerLevelRatingForLevel";

@implementation PlayerDataManager 

+ (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:rating] forKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", level]];
}

+ (NSInteger)levelRatingForLevel:(NSInteger)level {
    return [[NSUserDefaults standardUserDefaults] integerForKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", level]];
}

#pragma mark - Debug
+ (void)clearLevelRatings {
    for (int i = 0; i < 30; i++){
        [PlayerDataManager setLevelRating:0 forLevel:i];
    }
}
@end
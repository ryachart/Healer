//
//  PersistantDataManager.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PersistantDataManager.h"
#import "Shop.h"
#import "Spell.h"

static dispatch_queue_t parse_queue = nil;

NSString* const PlayerHighestLevelAttempted = @"com.healer.playerHighestLevelAttempted";
NSString* const PlayerHighestLevelCompleted = @"com.healer.playerHighestLevelCompleted";
NSString* const PLayerHighestLevelAttemptedHM = @"com.healer.playerHighestLevelAttemptedHM";
NSString* const PLayerHighestLevelCompletedHM = @"com.healer.playerHighestLevelCompletedHM";
NSString* const PlayerLevelRatingKeyPrefix = @"com.healer.playerLevelRatingForLevel";
NSString* const PlayerRemoteObjectIdKey = @"com.healer.playerRemoteObjectID3";
NSString* const PlayerDifficultySettingKey = @"com.healer.hardMode";

@implementation PlayerDataManager 

+ (dispatch_queue_t)parseQueue {
    if (!parse_queue){
        parse_queue = dispatch_queue_create("com.healer.parse-dispatch-queue", 0);
    }
    return parse_queue;
}

+ (BOOL)hardMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:PlayerDifficultySettingKey];
}

+ (void)setHardMode:(BOOL)isOn {
    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:PlayerDifficultySettingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:rating] forKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", level]];
}

+ (NSInteger)levelRatingForLevel:(NSInteger)level {
    return [[NSUserDefaults standardUserDefaults] integerForKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", level]];
}

+ (NSInteger)highestLevelCompleted {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue];
}

+ (NSInteger)highestLevelAttempted {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelAttempted] intValue];
}

+ (void)setPlayerObjectInformation:(PFObject*)obj {
    NSInteger numVisits = [[obj objectForKey:@"saves"] intValue];
    [obj setObject:[NSNumber numberWithInt:[PlayerDataManager highestLevelCompleted]] forKey:@"HLCompleted"];
    [obj setObject:[NSNumber numberWithInt:[Shop localPlayerGold]] forKey:@"Gold"];
    [obj setObject:[NSNumber numberWithInt:numVisits+1] forKey:@"saves"];
    [obj setObject:[UIDevice currentDevice].name forKey:@"deviceName"];
    
    NSInteger highestLevelCompleted = [PlayerDataManager highestLevelCompleted];
    if (highestLevelCompleted > 20){
        highestLevelCompleted = 20; //Because of debugging stuff..
    }
    
    NSMutableArray *levelRatings = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
    for (int i = 1; i <= highestLevelCompleted; i++){
        NSInteger rating =  [PlayerDataManager levelRatingForLevel:i];
        NSNumber *numberObj = [NSNumber numberWithInt:rating];
        [levelRatings addObject:numberObj];
    }
    
    [obj setObject:levelRatings forKey:@"levelRatings"];
    
    NSArray *allOwnedSpells = [Shop allOwnedSpells];
    NSMutableArray *ownedSpellTitles = [NSMutableArray arrayWithCapacity:10];
    for (Spell *spell in allOwnedSpells){
        [ownedSpellTitles addObject:spell.title];
    }
    
    [obj setObject:ownedSpellTitles forKey:@"Spells"];
    
}

+ (void)saveRemotePlayer {
    NSInteger backgroundExceptionIdentifer = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    dispatch_async([PlayerDataManager parseQueue], ^{ 
        NSString* playerObjectID = [[NSUserDefaults standardUserDefaults] objectForKey:PlayerRemoteObjectIdKey];
        NSLog(@"Fetching Player with id %@", playerObjectID);
        if (playerObjectID){
            PFQuery *playerObjectQuery = [PFQuery queryWithClassName:@"player"];
            PFObject *playerObject = [playerObjectQuery getObjectWithId:playerObjectID];
            [PlayerDataManager setPlayerObjectInformation:playerObject];
            [playerObject saveEventually];
        } else {
            PFObject *newPlayerObject = [PFObject objectWithClassName:@"player"];
            [PlayerDataManager setPlayerObjectInformation:newPlayerObject];
            if ([newPlayerObject save]) {
                if (newPlayerObject.objectId){
                    [[NSUserDefaults standardUserDefaults] setObject:newPlayerObject.objectId forKey:PlayerRemoteObjectIdKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
            
        }
        [[UIApplication sharedApplication] endBackgroundTask:backgroundExceptionIdentifer];
    });
}

#pragma mark - Debug
+ (void)clearLevelRatings {
    for (int i = 0; i < 30; i++){
        [PlayerDataManager setLevelRating:0 forLevel:i];
    }
}


@end
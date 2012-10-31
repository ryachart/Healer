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
NSString* const PlayerHighestLevelAttemptedHM = @"com.healer.playerHighestLevelAttemptedHM";
NSString* const PlayerHighestLevelCompletedHM = @"com.healer.playerHighestLevelCompletedHM";
NSString* const PlayerLevelFailed = @"com.healer.playerLevelFailed";
NSString* const PlayerLevelFailedHM = @"com.healer.playerLevelFailedHM";
NSString* const PlayerLevelRatingKeyPrefix = @"com.healer.playerLevelRatingForLevel";
NSString* const PlayerRemoteObjectIdKey = @"com.healer.playerRemoteObjectID3";
NSString* const PlayerDifficultySettingKey = @"com.healer.hardMode";
NSString* const PlayerLastUsedSpellsKey = @"com.healer.lastUsedSpells";
NSString* const PlayerNormalModeCompleteShown = @"com.healer.nmcs";

@implementation PersistantDataManager 

+ (dispatch_queue_t)parseQueue {
    if (!parse_queue){
        parse_queue = dispatch_queue_create("com.healer.parse-dispatch-queue", 0);
    }
    return parse_queue;
}

+ (BOOL)hardModeUnlocked {
    if ([PersistantDataManager highestLevelCompletedForMode:DifficultyModeNormal] >= 21){
        return YES;
    }
    return NO;
}

+ (DifficultyMode)currentMode {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PlayerDifficultySettingKey];
}

+ (void)setDifficultyMode:(DifficultyMode)diffMode {
    [[NSUserDefaults standardUserDefaults] setInteger:diffMode forKey:PlayerDifficultySettingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isMultiplayerUnlocked {
    return [PersistantDataManager highestLevelCompletedForMode:DifficultyModeNormal] >= 6;
}

+ (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level withMode:(DifficultyMode)diffMode {
    if (diffMode == DifficultyModeHard){
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:rating] forKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"-%i-%d",diffMode, level]];
    }else {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:rating] forKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", level]];
    }
}

+ (NSInteger)levelRatingForLevel:(NSInteger)level withMode:(DifficultyMode)diffMode{
    if (diffMode == DifficultyModeHard){
        return [[NSUserDefaults standardUserDefaults] integerForKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"-%i-%d", diffMode, level]];
    }
    return [[NSUserDefaults standardUserDefaults] integerForKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", level]];
}

+ (NSInteger)highestLevelCompletedForMode:(DifficultyMode)diffMode {
    if (diffMode == DifficultyModeHard) {
        NSInteger hlc = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompletedHM] intValue];
        return MAX(hlc, 1); //The first level is always skipped on hardmode
    }
    return [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue];
}

+ (NSInteger)highestLevelAttemptedForMode:(DifficultyMode)diffMode {
    if (diffMode == DifficultyModeHard){
        return [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelAttemptedHM] intValue];
    }
    return [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelAttempted] intValue];
}

+ (void)failLevelInCurrentMode:(NSInteger)level {
    if (CURRENT_MODE == DifficultyModeHard){
        NSString *failedKey = [PlayerLevelFailedHM stringByAppendingFormat:@"-%i", level];
        NSInteger failedTimes = [[NSUserDefaults standardUserDefaults] integerForKey:failedKey];
        
        [[NSUserDefaults standardUserDefaults] setInteger:failedTimes forKey:failedKey];
    }else {
        NSString *failedKey = [PlayerLevelFailed stringByAppendingFormat:@"-%i", level];
        NSInteger failedTimes = [[NSUserDefaults standardUserDefaults] integerForKey:failedKey];
        
        [[NSUserDefaults standardUserDefaults] setInteger:failedTimes forKey:failedKey];
    }
}

+ (void)completeLevelInCurrentMode:(NSInteger)level {
    if (CURRENT_MODE == DifficultyModeHard){
        BOOL isFirstWin = level > [PersistantDataManager highestLevelCompletedForMode:DifficultyModeHard];
        if (isFirstWin){
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:level] forKey:PlayerHighestLevelCompletedHM];
        }
    }else {
        BOOL isFirstWin = level > [PersistantDataManager highestLevelCompletedForMode:DifficultyModeNormal];
        if (isFirstWin){
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:level] forKey:PlayerHighestLevelCompleted];
        }
    }
}

+ (void)setPlayerObjectInformation:(PFObject*)obj {
    NSInteger numVisits = [[obj objectForKey:@"saves"] intValue];
    [obj setObject:[NSNumber numberWithInt:[PersistantDataManager highestLevelCompletedForMode:DifficultyModeNormal]] forKey:@"HLCompleted"];
    [obj setObject:[NSNumber numberWithInt:[Shop localPlayerGold]] forKey:@"Gold"];
    [obj setObject:[NSNumber numberWithInt:numVisits+1] forKey:@"saves"];
    [obj setObject:[UIDevice currentDevice].name forKey:@"deviceName"];
    if ([PersistantDataManager lastUsedSpellTitles]){
        [obj setObject:[PersistantDataManager lastUsedSpellTitles] forKey:@"lastUsedSpells"];
    }
    
    NSInteger highestLevelCompleted = [PersistantDataManager highestLevelCompletedForMode:DifficultyModeNormal];
    if (highestLevelCompleted > 20){
        highestLevelCompleted = 20; //Because of debugging stuff..
    }
    
    NSMutableArray *levelRatings = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
    for (int i = 1; i <= highestLevelCompleted; i++){
        NSInteger rating =  [PersistantDataManager levelRatingForLevel:i withMode:DifficultyModeNormal];
        NSNumber *numberObj = [NSNumber numberWithInt:rating];
        [levelRatings addObject:numberObj];
    }
    
    [obj setObject:levelRatings forKey:@"levelRatings"];
    
    if ([PersistantDataManager hardModeUnlocked]){
        NSMutableArray *hLevelRatings = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
        for (int i = 1; i <= highestLevelCompleted; i++){
            NSInteger rating =  [PersistantDataManager levelRatingForLevel:i withMode:DifficultyModeHard];
            NSNumber *numberObj = [NSNumber numberWithInt:rating];
            [hLevelRatings addObject:numberObj];
        }
        [obj setObject:hLevelRatings forKey:@"hLevelRatings"];
    }
    
    NSMutableArray *levelFails = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
    for (int i = 1; i <= highestLevelCompleted; i++){
        NSString *failedKey = [PlayerLevelFailed stringByAppendingFormat:@"-%i", i];
        NSInteger failedTimes = [[NSUserDefaults standardUserDefaults] integerForKey:failedKey];
        NSNumber *numberObj = [NSNumber numberWithInt:failedTimes];
        [levelFails addObject:numberObj];
    }
    
    [obj setObject:levelFails forKey:@"levelFails"];
    
    NSMutableArray *hlevelFails = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
    for (int i = 1; i <= highestLevelCompleted; i++){
        NSString *failedKey = [PlayerLevelFailedHM stringByAppendingFormat:@"-%i", i];
        NSInteger failedTimes = [[NSUserDefaults standardUserDefaults] integerForKey:failedKey];
        NSNumber *numberObj = [NSNumber numberWithInt:failedTimes];
        [hlevelFails addObject:numberObj];
    }
    
    [obj setObject:hlevelFails forKey:@"hLevelFails"];
    
    
    NSArray *allOwnedSpells = [Shop allOwnedSpells];
    NSMutableArray *ownedSpellTitles = [NSMutableArray arrayWithCapacity:10];
    for (Spell *spell in allOwnedSpells){
        [ownedSpellTitles addObject:spell.title];
    }
    
    [obj setObject:ownedSpellTitles forKey:@"Spells"];
    
}

+ (void)saveRemotePlayer {
    NSInteger backgroundExceptionIdentifer = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    dispatch_async([PersistantDataManager parseQueue], ^{ 
        NSString* playerObjectID = [[NSUserDefaults standardUserDefaults] objectForKey:PlayerRemoteObjectIdKey];
        NSLog(@"Fetching Player with id %@", playerObjectID);
        if (playerObjectID){
            PFQuery *playerObjectQuery = [PFQuery queryWithClassName:@"player"];
            PFObject *playerObject = [playerObjectQuery getObjectWithId:playerObjectID];
            [PersistantDataManager setPlayerObjectInformation:playerObject];
            [playerObject saveEventually];
        } else {
            PFObject *newPlayerObject = [PFObject objectWithClassName:@"player"];
            [PersistantDataManager setPlayerObjectInformation:newPlayerObject];
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

#pragma mark - Last Used Spells

+ (void)setUsedSpells:(NSArray*)spells{
    NSMutableArray *spellClassNames = [NSMutableArray arrayWithCapacity:spells.count];
    for (Spell *spell in spells){
        [spellClassNames addObject:NSStringFromClass(spell.class)];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:spellClassNames forKey:PlayerLastUsedSpellsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray*)lastUsedSpellTitles{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:PlayerLastUsedSpellsKey];
}

+ (NSArray*)lastUsedSpells {
    NSArray *spellTitles = [PersistantDataManager lastUsedSpellTitles];;
    NSMutableArray *spells = [NSMutableArray arrayWithCapacity:spellTitles.count];
    for (NSString *spellClassName in spellTitles){
        Class spellClass = NSClassFromString(spellClassName);
        Spell *spellFromClass = [spellClass defaultSpell];
        if (spellFromClass){
            [spells addObject:spellFromClass];
        }else {
            NSLog(@"ERR: No spell by that name: %@", spellClassName);
            return nil;
        }
    }
    return spells;
}

#pragma mark - Normal Mode Completion
+ (BOOL)hasShownNormalModeCompleteScene {
    return [[NSUserDefaults standardUserDefaults] boolForKey:PlayerNormalModeCompleteShown];
}
+ (void)normalModeCompleteSceneShown{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PlayerNormalModeCompleteShown];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Debug
+ (void)clearLevelRatings {
    for (int i = 0; i < 30; i++){
        [PersistantDataManager setLevelRating:0 forLevel:i withMode:DifficultyModeNormal];
    }
}


@end
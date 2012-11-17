//
//  PersistantDataManager.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerDataManager.h"
#import "Shop.h"
#import "Spell.h"
#import "Divinity.h"

static dispatch_queue_t parse_queue = nil;

NSString* const PlayerHighestLevelAttempted = @"com.healer.playerHighestLevelAttempted";
NSString* const PlayerHighestLevelCompleted = @"com.healer.playerHighestLevelCompleted";
NSString* const PlayerLevelFailed = @"com.healer.playerLevelFailed1";
NSString* const PlayerLevelRatingKeyPrefix = @"com.healer.playerLevelRatingForLevel1";
NSString* const PlayerRemoteObjectIdKey = @"com.healer.playerRemoteObjectID3";
NSString* const PlayerLastUsedSpellsKey = @"com.healer.lastUsedSpells";
NSString* const PlayerNormalModeCompleteShown = @"com.healer.nmcs";
NSString* const PlayerLevelDifficultyLevelsKey = @"com.healer.diffLevels";
NSString* const DivinityTiersUnlocked = @"com.healer.divTiers";


@implementation PlayerDataManager 

+ (dispatch_queue_t)parseQueue {
    if (!parse_queue){
        parse_queue = dispatch_queue_create("com.healer.parse-dispatch-queue", 0);
    }
    return parse_queue;
}

+ (NSMutableArray *)difficultyLevels
{
    NSMutableArray *difficultyLevels = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:PlayerLevelDifficultyLevelsKey]];
    if (difficultyLevels.count == 0) {
        difficultyLevels = [NSMutableArray arrayWithCapacity:25];
        for (int i = 0; i < 25; i++){
            [difficultyLevels addObject:@2];
        }
        [[NSUserDefaults standardUserDefaults] setObject:difficultyLevels forKey:PlayerLevelDifficultyLevelsKey];
    }
    return difficultyLevels;
}

+ (NSInteger)totalRating
{
    NSInteger highestLevelCompleted = [PlayerDataManager highestLevelCompleted];
    NSInteger totalScore = 0;
    for (int i = 2; i <= highestLevelCompleted; i++){
        NSInteger rating =  [PlayerDataManager levelRatingForLevel:i];
        totalScore += (rating / 2); //Rating is divided by 2 because we score on a 1 out of 10 scale but skulls are served as 1 to 5
    }
    return totalScore;
}

+ (NSInteger)difficultyForLevelNumber:(NSInteger)levelNum
{
    NSMutableArray *difficultyLevels = [PlayerDataManager difficultyLevels];
    return [[difficultyLevels objectAtIndex:levelNum] intValue];
}

+ (void)difficultySelected:(NSInteger)challenge forLevelNumber:(NSInteger)levelNum
{
    NSMutableArray *difficultyLevels = [PlayerDataManager difficultyLevels];
    [difficultyLevels replaceObjectAtIndex:levelNum withObject:[NSNumber numberWithInt:challenge]];
    [[NSUserDefaults standardUserDefaults] setObject:difficultyLevels forKey:PlayerLevelDifficultyLevelsKey];
}

+ (BOOL)isMultiplayerUnlocked {
    return NO;
    return [PlayerDataManager highestLevelCompleted] >= 6;
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

+ (NSInteger)highestLevelAttempted{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelAttempted] intValue];
}

+ (void)failLevelInCurrentMode:(NSInteger)level {
    NSString *failedKey = [PlayerLevelFailed stringByAppendingFormat:@"-%i", level];
    NSInteger failedTimes = [[NSUserDefaults standardUserDefaults] integerForKey:failedKey];
    failedTimes += 1;
    [[NSUserDefaults standardUserDefaults] setInteger:failedTimes forKey:failedKey];
}

+ (void)completeLevel:(NSInteger)level {
    BOOL isFirstWin = level > [PlayerDataManager highestLevelCompleted];
    if (isFirstWin){
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:level] forKey:PlayerHighestLevelCompleted];
    }
}

+ (void)setPlayerObjectInformation:(PFObject*)obj {
    NSInteger numVisits = [[obj objectForKey:@"saves"] intValue];
    [obj setObject:[NSNumber numberWithInt:[PlayerDataManager highestLevelCompleted]] forKey:@"HLCompleted"];
    [obj setObject:[NSNumber numberWithInt:[Shop localPlayerGold]] forKey:@"Gold"];
    [obj setObject:[NSNumber numberWithInt:numVisits+1] forKey:@"saves"];
    [obj setObject:[UIDevice currentDevice].name forKey:@"deviceName"];
    if ([PlayerDataManager lastUsedSpellTitles]){
        [obj setObject:[PlayerDataManager lastUsedSpellTitles] forKey:@"lastUsedSpells"];
    }
    
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
    
    NSMutableArray *levelFails = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
    for (int i = 1; i <= highestLevelCompleted; i++){
        NSString *failedKey = [PlayerLevelFailed stringByAppendingFormat:@"-%i", i];
        NSInteger failedTimes = [[NSUserDefaults standardUserDefaults] integerForKey:failedKey];
        NSNumber *numberObj = [NSNumber numberWithInt:failedTimes];
        [levelFails addObject:numberObj];
    }
    [obj setObject:levelFails forKey:@"levelFails"];
    
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
    NSArray *spellTitles = [PlayerDataManager lastUsedSpellTitles];;
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

#pragma mark - Divinity

+ (void)resetDivinity {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:DivinityTiersUnlocked];
    [Divinity resetConfig];
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
        [PlayerDataManager setLevelRating:0 forLevel:i];
    }
}


@end
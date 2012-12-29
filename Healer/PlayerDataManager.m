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
#import "ShopItem.h"

@interface PlayerDataManager ()
@property (nonatomic, retain) NSMutableDictionary *playerData;
@end

static dispatch_queue_t parse_queue = nil;
static dispatch_queue_t saving_queue = nil;
static PlayerDataManager *_localPlayer = nil;

NSString* const PlayerHighestLevelAttempted = @"com.healer.playerHighestLevelAttempted";
NSString* const PlayerHighestLevelCompleted = @"com.healer.playerHighestLevelCompleted";
NSString* const PlayerLevelFailed = @"com.healer.playerLevelFailed1";
NSString* const PlayerLevelRatingKeyPrefix = @"com.healer.playerLevelRatingForLevel1";
NSString* const PlayerLevelScoreKeyPrefix = @"com.healer.playerScoreForLevel";
NSString* const PlayerRemoteObjectIdKey = @"com.healer.playerRemoteObjectID3";
NSString* const PlayerLastUsedSpellsKey = @"com.healer.lastUsedSpells";
NSString* const PlayerNormalModeCompleteShown = @"com.healer.nmcs";
NSString* const PlayerLevelDifficultyLevelsKey = @"com.healer.diffLevels";
NSString* const PlayerGold = @"com.healer.playerId";
NSString* const PlayerGoldDidChangeNotification = @"com.healer.goldDidChangeNotif";
NSString* const DivinityConfig = @"com.healer.divinityConfig";
NSString* const DivinityTiersUnlocked = @"com.healer.divTiers";
NSString* const PlayerLastSelectedLevelKey = @"com.healer.plsl";
NSString* const ContentKeys = @"com.healer.contentKeys";

//Content Keys
NSString* const DelsarnContentKey = @"com.healer.content1Key";

@implementation PlayerDataManager

- (void)dealloc {
    [_playerData release];
    [super dealloc];
}

+ (PlayerDataManager *)localPlayer {
    if (!_localPlayer) {
        _localPlayer = [[PlayerDataManager alloc] initAsLocalPlayer];
    }
    return _localPlayer;
}

- (NSString *)localPlayerSavePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	if (!documentsDirectory) {
		NSLog(@"Documents directory not found!");
		return NO;
	}
    return [documentsDirectory stringByAppendingPathComponent:@"player.dat"];
}

- (void)saveLocalPlayer {
    NSInteger backgroundExceptionIdentifer = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    dispatch_async([PlayerDataManager savingQueue], ^{
        NSString *appFile = [self localPlayerSavePath];
        NSData *dataFromPlayerData = [NSPropertyListSerialization dataFromPropertyList:self.playerData format:NSPropertyListBinaryFormat_v1_0 errorDescription:nil];
        [dataFromPlayerData writeToFile:appFile atomically:YES];
        [self saveRemotePlayer];
        [[UIApplication sharedApplication] endBackgroundTask:backgroundExceptionIdentifer];
    });
}

- (void)saveRemotePlayer {
    NSInteger backgroundExceptionIdentifer = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    dispatch_async([PlayerDataManager parseQueue], ^{
        NSString* playerObjectID = [[NSUserDefaults standardUserDefaults] objectForKey:PlayerRemoteObjectIdKey];
        NSLog(@"Fetching Player with id %@", playerObjectID);
        if (playerObjectID){
            PFQuery *playerObjectQuery = [PFQuery queryWithClassName:@"player"];
            PFObject *playerObject = [playerObjectQuery getObjectWithId:playerObjectID];
            [self setPlayerObjectInformation:playerObject];
            [playerObject saveEventually];
        } else {
            PFObject *newPlayerObject = [PFObject objectWithClassName:@"player"];
            [self setPlayerObjectInformation:newPlayerObject];
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

- (void)attemptMigrationFromUserDefaults {
    @try {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults objectForKey:PlayerHighestLevelCompleted] && [[userDefaults objectForKey:PlayerHighestLevelCompleted] intValue] > 1) {
            self.playerData = [NSMutableDictionary dictionary];
            [self.playerData setObject:[NSNumber numberWithInt:[userDefaults integerForKey:PlayerHighestLevelCompleted]] forKey:PlayerHighestLevelCompleted];
            [self.playerData setObject:[NSNumber numberWithInt:[userDefaults integerForKey:PlayerGold]] forKey:PlayerGold];
            if ([self lastUsedSpellTitles]){
                [self.playerData setObject:[userDefaults objectForKey:PlayerLastUsedSpellsKey] forKey:PlayerLastUsedSpellsKey];
            }
            for (int i = 1; i <= [userDefaults integerForKey:PlayerHighestLevelCompleted]; i++){
                NSString *key = [PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", i];
                NSInteger rating =  [userDefaults integerForKey:key];
                NSNumber *numberObj = [NSNumber numberWithInt:rating];
                [self.playerData setObject:numberObj forKey:key];
            }
                        
            for (int i = 1; i <= [userDefaults integerForKey:PlayerHighestLevelCompleted]; i++){
                NSString *failedKey = [PlayerLevelFailed stringByAppendingFormat:@"-%i", i];
                NSInteger failedTimes = [[userDefaults objectForKey:failedKey] intValue];
                NSNumber *numberObj = [NSNumber numberWithInt:failedTimes];
                [self.playerData setObject:numberObj forKey:failedKey];
            }
            
            NSArray *allItems = [Shop allShopItems];
            for (ShopItem *item in allItems){
                if ([[userDefaults objectForKey:[item key]] boolValue]) {
                    [self.playerData setObject:[NSNumber numberWithBool:YES] forKey:[item key]];
                }
            }
        }
    } @catch (NSException *e) {
        NSLog(@"Migration failed for some reason");
    }
}

- (id)initAsLocalPlayer
{
    if (self = [super init]) {   
        
        self.playerData = [NSMutableDictionary dictionaryWithContentsOfFile:[self localPlayerSavePath]];
        if (!self.playerData) {
            //Remove this code before you ship lol
            [self attemptMigrationFromUserDefaults];
            [self saveLocalPlayer];
        }
        
        if (!self.playerData) {
            self.playerData = [NSMutableDictionary dictionary];
            [self saveLocalPlayer];
        }
    }
    return self;
}

+ (dispatch_queue_t)parseQueue {
    if (!parse_queue){
        parse_queue = dispatch_queue_create("com.healer.parse-dispatch-queue", 0);
    }
    return parse_queue;
}

+ (dispatch_queue_t)savingQueue {
    if (!saving_queue) {
        saving_queue = dispatch_queue_create("com.healer.saving-dispatch-queue", 0);
    }
    return saving_queue;
}

- (NSMutableArray *)difficultyLevels
{
    NSMutableArray *difficultyLevels = [NSMutableArray arrayWithArray:(NSArray*)[self.playerData objectForKey:PlayerLevelDifficultyLevelsKey]];
    if (difficultyLevels.count == 0) {
        difficultyLevels = [NSMutableArray arrayWithCapacity:25];
        for (int i = 0; i < 25; i++){
            [difficultyLevels addObject:@2];
        }
        [self.playerData setObject:difficultyLevels forKey:PlayerLevelDifficultyLevelsKey];
    }
    return difficultyLevels;
}

- (NSInteger)totalRating
{
    NSInteger highestLevelCompleted = [self highestLevelCompleted];
    NSInteger totalScore = 0;
    for (int i = 2; i <= highestLevelCompleted; i++){
        NSInteger rating =  [self levelRatingForLevel:i];
        totalScore += (rating / 2); //Rating is divided by 2 because we score on a 1 out of 10 scale but skulls are served as 1 to 5
    }
    return totalScore;
}

- (NSInteger)difficultyForLevelNumber:(NSInteger)levelNum
{
    NSMutableArray *difficultyLevels = [self difficultyLevels];
    return [[difficultyLevels objectAtIndex:levelNum] intValue];
}

- (void)difficultySelected:(NSInteger)challenge forLevelNumber:(NSInteger)levelNum
{
    NSMutableArray *difficultyLevels = [self difficultyLevels];
    [difficultyLevels replaceObjectAtIndex:levelNum withObject:[NSNumber numberWithInt:challenge]];
    [self.playerData setObject:difficultyLevels forKey:PlayerLevelDifficultyLevelsKey];
}

- (BOOL)isMultiplayerUnlocked {
    return NO;
    return [self highestLevelCompleted] >= 6;
}

- (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level {
    [self.playerData setValue:[NSNumber numberWithInt:rating] forKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", level]];
}

- (NSInteger)levelRatingForLevel:(NSInteger)level {
    NSInteger rating = [[self.playerData objectForKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", level]] intValue];
    if (rating > 5) { //Gross Migration code
        rating /= 2;
    }
    return rating;
}

- (void)setScore:(NSInteger)score forLevel:(NSInteger)level {
    [self.playerData setValue:[NSNumber numberWithInt:score] forKey:[PlayerLevelScoreKeyPrefix stringByAppendingFormat:@"%d", level]];
}

- (NSInteger)scoreForLevel:(NSInteger)level {
    return [[self.playerData objectForKey:[PlayerLevelScoreKeyPrefix stringByAppendingFormat:@"%d", level]] intValue];
}

- (NSInteger)highestLevelCompleted {
    return [[self.playerData objectForKey:PlayerHighestLevelCompleted] intValue];
}

- (NSInteger)highestLevelAttempted{
    return [[self.playerData objectForKey:PlayerHighestLevelAttempted] intValue];
}

- (void)failLevel:(NSInteger)level {
    NSString *failedKey = [PlayerLevelFailed stringByAppendingFormat:@"-%i", level];
    NSInteger failedTimes = [[self.playerData objectForKey:failedKey] intValue];
    failedTimes++;
    [self.playerData setObject:[NSNumber numberWithInt:failedTimes] forKey:failedKey];
}

- (void)completeLevel:(NSInteger)level {
    BOOL isFirstWin = level > [self highestLevelCompleted];
    if (isFirstWin){
        [self.playerData setValue:[NSNumber numberWithInt:level] forKey:PlayerHighestLevelCompleted ];
    }
}

- (void)setPlayerObjectInformation:(PFObject*)obj {
    NSInteger numVisits = [[obj objectForKey:@"saves"] intValue];
    [obj setObject:[NSNumber numberWithInt:[self highestLevelCompleted]] forKey:@"HLCompleted"];
    [obj setObject:[NSNumber numberWithInt:self.gold] forKey:@"Gold"];
    [obj setObject:[NSNumber numberWithInt:numVisits+1] forKey:@"saves"];
    [obj setObject:[UIDevice currentDevice].name forKey:@"deviceName"];
    if ([self lastUsedSpellTitles]){
        [obj setObject:[self lastUsedSpellTitles] forKey:@"lastUsedSpells"];
    }
    
    NSInteger highestLevelCompleted = [self highestLevelCompleted];
    if (highestLevelCompleted > 25){
        highestLevelCompleted = 25; //Because of debugging stuff..
    }
    
    NSMutableArray *levelRatings = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
    for (int i = 1; i <= highestLevelCompleted; i++){
        NSInteger rating =  [self levelRatingForLevel:i];
        NSNumber *numberObj = [NSNumber numberWithInt:rating];
        [levelRatings addObject:numberObj];
    }
    
    [obj setObject:levelRatings forKey:@"levelRatings"];
    
    NSMutableArray *levelScores = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
    for (int i = 1; i <= highestLevelCompleted; i++){
        NSInteger score =  [self scoreForLevel:i];
        NSNumber *numberObj = [NSNumber numberWithInt:score];
        [levelRatings addObject:numberObj];
    }
    
    [obj setObject:levelScores forKey:@"levelScores"];
    
    NSMutableArray *levelFails = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
    for (int i = 1; i <= highestLevelCompleted; i++){
        NSString *failedKey = [PlayerLevelFailed stringByAppendingFormat:@"-%i", i];
        NSInteger failedTimes = [[self.playerData objectForKey:failedKey] intValue];
        NSNumber *numberObj = [NSNumber numberWithInt:failedTimes];
        [levelFails addObject:numberObj];
    }
    [obj setObject:levelFails forKey:@"levelFails"];
    
    NSArray *allOwnedSpells = [self allOwnedSpells];
    NSMutableArray *ownedSpellTitles = [NSMutableArray arrayWithCapacity:10];
    for (Spell *spell in allOwnedSpells){
        [ownedSpellTitles addObject:spell.title];
    }
    
    [obj setObject:ownedSpellTitles forKey:@"Spells"];
    
}

#pragma mark - Last Used Spells

- (void)setUsedSpells:(NSArray*)spells{
    NSMutableArray *spellClassNames = [NSMutableArray arrayWithCapacity:spells.count];
    for (Spell *spell in spells){
        [spellClassNames addObject:NSStringFromClass(spell.class)];
    }
    
    [self.playerData setObject:spellClassNames forKey:PlayerLastUsedSpellsKey];
    [self saveLocalPlayer];
}

- (NSArray*)lastUsedSpellTitles{
    return (NSArray*)[self.playerData objectForKey:PlayerLastUsedSpellsKey];
}

- (NSArray*)lastUsedSpells {
    NSArray *spellTitles = [self lastUsedSpellTitles];;
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
- (BOOL)hasShownNormalModeCompleteScene {
    return [[self.playerData objectForKey:PlayerNormalModeCompleteShown] boolValue];
}
- (void)normalModeCompleteSceneShown{
    [self.playerData setObject:[NSNumber numberWithBool:YES] forKey:PlayerNormalModeCompleteShown];
    [self saveLocalPlayer];
}

#pragma mark - Shop

-(BOOL)canAffordShopItem:(ShopItem*)item{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return self.gold >= [item goldCost];
}

-(BOOL)hasShopItem:(ShopItem*)item{
    return [[self.playerData objectForKey:[item key]] boolValue];
}

-(BOOL)hasSpell:(Spell*)spell{
    if ([spell.title isEqualToString:@"Heal"]){
        return YES;
    }
    return [self hasShopItem:[[[ShopItem alloc] initWithSpell:spell] autorelease]];
}

-(NSInteger)gold{
    return [[self.playerData objectForKey:PlayerGold] intValue];
}

- (void)purchaseItem:(ShopItem*)item{
    if ([self canAffordShopItem:item] && ![self hasShopItem:item]){
        [self.playerData setObject:[NSNumber numberWithBool:YES] forKey:[item key]];
        [self playerLosesGold:item.goldCost]; //Causes a save
    }
}

-(NSArray*)purchasedItems{
    NSMutableArray *purchasedItems = [NSMutableArray arrayWithCapacity:20];
    for (ShopItem *item in [Shop allShopItems]){
        if ([self hasShopItem:item]){
            [purchasedItems addObject: item];
        }
    }
    return purchasedItems;
}

-(NSArray*)allOwnedSpells{
    NSMutableArray *allSpells = [NSMutableArray arrayWithCapacity:20];
    NSArray *allShopItems = [Shop allShopItems];
    NSArray *purchasedItems = [self purchasedItems];
    [allSpells addObject:[Heal defaultSpell]];
    for (ShopItem *item in allShopItems){
        if ([purchasedItems containsObject:item]){
            [allSpells addObject:[[[item purchasedSpell] class] defaultSpell]];
        }
    }
    return allSpells;
}

-(void)playerEarnsGold:(NSInteger)gold{
    if (gold < 0)
        return;
    NSInteger currentGold = [[self.playerData objectForKey:PlayerGold] intValue];
    currentGold+= gold;
    if (currentGold > 5000){
        currentGold = 5000; //MAX GOLD
    }
    [self.playerData setObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold];
    [self saveLocalPlayer];
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayerGoldDidChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold]];
}

-(void)playerLosesGold:(NSInteger)gold{
    if (gold < 0)
        return;
    NSInteger currentGold = [[self.playerData objectForKey:PlayerGold] intValue];
    currentGold-= gold;
    if (currentGold < 0){
        currentGold = 0; //MAX GOLD
    }
    [self.playerData setObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold];
    [self saveLocalPlayer];
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayerGoldDidChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold]];
}

#pragma mark - Divinity

- (NSString*)selectedChoiceForTier:(NSInteger)tier {
    NSDictionary *config =  (NSDictionary*)[self.playerData objectForKey:DivinityConfig];
    return [config objectForKey:[NSString stringWithFormat:@"tier-%i", tier]];
}

- (NSDictionary*)localDivinityConfig {
    return (NSDictionary*)[self.playerData objectForKey:DivinityConfig];
}

- (void)resetConfig {
    [self.playerData setObject:[NSDictionary dictionary] forKey:DivinityConfig];
}

- (void)selectChoice:(NSString*)choice forTier:(NSInteger)tier{
    NSDictionary *divinityConfig = (NSDictionary*)[self.playerData objectForKey:DivinityConfig];
    if (!divinityConfig){
        divinityConfig = [NSDictionary dictionary];
    }
    NSMutableDictionary *newConfig = [NSMutableDictionary dictionaryWithDictionary:divinityConfig];
    
    [newConfig setObject:choice forKey:[NSString stringWithFormat:@"tier-%i", tier]];
    [self.playerData setObject:newConfig forKey:DivinityConfig];
    [self saveLocalPlayer];
}

#pragma mark - Cached Selections

- (void)setLastSelectedLevel:(NSInteger)lastSelectedLevel {
    [self.playerData setObject:[NSNumber numberWithInt:lastSelectedLevel] forKey:PlayerLastSelectedLevelKey];
}

- (NSInteger)lastSelectedLevel {
    if ([self.playerData objectForKey:PlayerLastSelectedLevelKey]) {
        return [[self.playerData objectForKey:PlayerLastSelectedLevelKey] intValue];
    }
    return -1;
}

#pragma mark - Debug
- (void)clearLevelRatings {
    for (int i = 0; i < 30; i++){
        [self setLevelRating:0 forLevel:i];
    }
}

#pragma mark - Purchases

- (void)purchaseContentWithKey:(NSString*)key
{
    //Yay you made a purchase =D
    NSMutableArray *contentKeys = [NSMutableArray arrayWithArray:[self.playerData objectForKey:ContentKeys]];
    [contentKeys addObject:key];
    [self.playerData setObject:contentKeys forKey:ContentKeys];
    [self saveLocalPlayer];
}

- (BOOL)hasPurchasedContentWithKey:(NSString*)key
{
    NSMutableArray *contentKeys = [NSMutableArray arrayWithArray:[self.playerData objectForKey:ContentKeys]];
    if ([contentKeys containsObject:key]) {
        return YES;
    }
    return NO;
}

- (BOOL)isEncounterPurchased:(NSInteger)encounterNum {
    if (encounterNum < 14) {
        //The first 13 encounters are free
        return YES;
    }
    
    if (encounterNum >= 14 && encounterNum < 22) {
        return [self hasPurchasedContentWithKey:DelsarnContentKey];
    }
    return NO;
}

- (BOOL)isShopCategoryPurchased:(ShopCategory)category {
    switch (category) {
        case ShopCategoryEssentials:
            return YES;
        case ShopCategoryAdvanced:
            return YES;
        case ShopCategoryArchives:
            return YES;
        case ShopCategoryVault:
            return [self hasPurchasedContentWithKey:DelsarnContentKey];
    }
    return NO;
}

- (NSInteger)isDifficultyPurchased:(NSInteger)difficulty {
    if (difficulty < 4) {
        //Easy, Normal, and Tough are all free
        return YES;
    }
    
    return [self hasPurchasedContentWithKey:DelsarnContentKey];
}
- (void)offerCampaignUnlock {
    //TODO: Show that UI?
}

@end

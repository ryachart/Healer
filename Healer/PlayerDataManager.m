//
//  PlayerDataManager.m
//  Healer
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

#import "PlayerDataManager.h"
#import "Shop.h"
#import "Spell.h"
#import "Talents.h"
#import "ShopItem.h"

@interface PlayerDataManager ()
@property (nonatomic, retain) NSMutableDictionary *playerData;
@property (nonatomic, readwrite) NSInteger stamina;
@property (nonatomic, readwrite, retain) NSDate *nextStamina;
@property (nonatomic, readwrite) NSInteger maxStamina;
@property (nonatomic, readwrite) NSTimeInterval secondsPerStamina;
@end

static dispatch_queue_t parse_queue = nil;
static dispatch_queue_t saving_queue = nil;
static PlayerDataManager *_localPlayer = nil;
static BOOL app_store_requested_this_session = NO;

NSString* const PlayerHighestLevelAttempted = @"com.healer.playerHighestLevelAttempted";
NSString* const PlayerHighestLevelCompleted = @"com.healer.playerHighestLevelCompleted";
NSString* const PlayerLevelFailed = @"com.healer.playerLevelFailed1";
NSString* const PlayerLevelRatingKeyPrefix = @"com.healer.playerLevelRatingForLevel1";
NSString* const PlayerLevelScoreKeyPrefix = @"com.healer.playerScoreForLevel2";
NSString* const PlayerRemoteObjectIdKey = @"com.healer.playerRemoteObjectID3";
NSString* const PlayerLastUsedSpellsKey = @"com.healer.lastUsedSpells";
NSString* const PlayerNormalModeCompleteShown = @"com.healer.nmcs";
NSString* const PlayerLevelDifficultyLevelsKey = @"com.healer.diffLevels";
NSString* const PlayerGold = @"com.healer.playerId";
NSString* const TalentConfig = @"com.healer.divinityConfig";
NSString* const DivinityTiersUnlocked = @"com.healer.divTiers";
NSString* const PlayerLastSelectedLevelKey = @"com.healer.plsl";
NSString* const ContentKeys = @"com.healer.contentKeys";
NSString* const PlayerFTUEState = @"com.healer.ftueState";
NSString* const MusicDisabledKey = @"com.healer.musicDisabled";
NSString* const EffectsDisabledKey = @"com.healer.effectsDisabled";
NSString* const HasRequestedAppStoreReviewKey = @"com.healer.requestedAppStoreReview";
NSString* const GamePurchasedCheckedKey = @"com.healer.gpck";
NSString* const PlayerInventoryKey = @"com.healer.ou1";
NSString* const PlayerSlotKey = @"com.healer.eslot";
NSString* const PlayerAllyDamageUpgradesKey = @"com.healer.paduk";
NSString* const PlayerAllyHealthUpgradesKey = @"com.healer.pahuk";
NSString* const PlayerTotalItemsEarnedKey = @"com.healer.ptie";
NSString* const PlayerName = @"com.healer.playerName";

NSString* const PlayerStaminaDidChangeNotification = @"com.healer.staminaDidChangeNotif";
NSString* const PlayerGoldDidChangeNotification = @"com.healer.goldDidChangeNotif";
//Content Keys
NSString* const MainGameContentKey = @"com.healer.c1key";

@implementation PlayerDataManager

- (void)dealloc {
    [_playerData release];
    [_nextStamina release];
    [super dealloc];
}

+ (PlayerDataManager *)localPlayer {
    if (!_localPlayer) {
        _localPlayer = [[PlayerDataManager alloc] initAsLocalPlayer];
        _localPlayer.stamina = STAMINA_NOT_LOADED;
        _localPlayer.secondsPerStamina = STAMINA_NOT_LOADED;
    }
    return _localPlayer;
}

+ (Player *)playerFromData:(NSDictionary*)data
{
    PlayerDataManager *dataManager = [[[PlayerDataManager alloc] initWithPlayerData:data] autorelease];
    return [dataManager player];
}

- (id)initWithPlayerData:(NSDictionary *)data
{
    if (self = [super init]) {
        if (data)
            self.playerData = [NSMutableDictionary dictionaryWithDictionary:data];
        
        if (!self.playerData) {
            self.playerData = [NSMutableDictionary dictionary];
            self.ftueState = FTUEStateFresh;
            [self saveLocalPlayer];
        }
        
        if (self.ftueState < FTUEStateGreaterHealPurchased && [self hasSpell:[GreaterHeal defaultSpell]]) {
            self.ftueState = FTUEStateGreaterHealPurchased;
        }
    }
    return self;
}

- (id)initAsLocalPlayer
{
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithContentsOfFile:[PlayerDataManager localPlayerSavePath]];
    if (self = [self initWithPlayerData:dataDict]) {

    }
    return self;
}

- (Player *)player
{
    Player *basicPlayer = [[[Player alloc] initWithHealth:1400 energy:1000 energyRegen:10] autorelease];
    if ([self isTalentsUnlocked]){
        [basicPlayer setTalentConfig:[self talentConfig]];
    }
    if (self.equippedItems.count > 0) {
        [basicPlayer setEquippedItems:self.equippedItems];
        NSMutableArray *spellsFromItems = [NSMutableArray arrayWithCapacity:2];
        for (EquipmentItem *item in basicPlayer.equippedItems) {
            Spell *spell = item.spellFromItem;
            if (spell) {
                [spellsFromItems addObject:spell];
            }
        }
        [basicPlayer setSpellsFromEquipment:spellsFromItems];
    }
    [basicPlayer configureForRecommendedSpells:nil withLastUsedSpells:self.lastUsedSpells];
    return basicPlayer;
}

+ (Player *)playerFromLocalPlayer
{
    return [[PlayerDataManager localPlayer] player];
}

+ (NSString *)localPlayerSavePath
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
    if (_localPlayer != self) return;
    NSInteger backgroundExceptionIdentifer = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    dispatch_async([PlayerDataManager savingQueue], ^{
        NSString *appFile = [PlayerDataManager localPlayerSavePath];
        NSData *dataFromPlayerData = [NSPropertyListSerialization dataFromPropertyList:self.playerData format:NSPropertyListBinaryFormat_v1_0 errorDescription:nil];
        [dataFromPlayerData writeToFile:appFile atomically:YES];
        [[UIApplication sharedApplication] endBackgroundTask:backgroundExceptionIdentifer];
    });
}

- (NSData *)sharableData
{
    NSMutableDictionary *sharableDict = [NSMutableDictionary dictionary];
    [sharableDict setObject:[self.playerData objectForKey:TalentConfig] forKey:TalentConfig];
    for (int slotType = SlotTypeHead; slotType < SlotTypeMaximum; slotType++) {
        [sharableDict setObject:[self.playerData objectForKey:[self slotKeyForSlot:slotType]] forKey:[self slotKeyForSlot:slotType]];
    }
    if ([self.playerData objectForKey:PlayerLastUsedSpellsKey]) {
        [sharableDict setObject:[self.playerData objectForKey:PlayerLastUsedSpellsKey] forKey:PlayerLastUsedSpellsKey];
    }
    //TODO: Sharable keys
    NSData *dataFromPlayerData = [NSPropertyListSerialization dataFromPropertyList:sharableDict format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    return dataFromPlayerData;
}

- (NSString *)playerMessage
{
    NSString* playerMessage = [[NSString alloc] initWithData:[[PlayerDataManager localPlayer] sharableData] encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"PLAYER|%@", playerMessage];
}

+ (Player *)playerFromPlayerMessage:(NSString *)playerMessage
{
    NSString *playerMessageXML = [playerMessage substringFromIndex:7];
    NSData *playerData = [playerMessageXML dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *playerDataDict = [NSPropertyListSerialization propertyListWithData:playerData options:NSPropertyListImmutable format:NULL error:nil];
    return [PlayerDataManager playerFromData:playerDataDict];
}

- (NSString *)remoteObjectId
{
    if (_localPlayer != self) return nil;
    return [[NSUserDefaults standardUserDefaults] objectForKey:PlayerRemoteObjectIdKey];
}

- (void)saveRemotePlayer {
    if (_localPlayer != self) return;
#if ANDROID
#else
    NSString *className = @"player";
#if TARGET_IPHONE_SIMULATOR
    className = @"test_player";
#endif
#if DEBUG
    className = @"test_player";
#endif
    NSInteger backgroundExceptionIdentifer = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    dispatch_async([PlayerDataManager parseQueue], ^{
        NSString* playerObjectID = [self remoteObjectId];
        if (playerObjectID){
            PFQuery *playerObjectQuery = [PFQuery queryWithClassName:className];
            PFObject *playerObject = [playerObjectQuery getObjectWithId:playerObjectID];
            [self setPlayerObjectInformation:playerObject];
            [playerObject saveEventually];
        } else {
            @try {
                PFObject *newPlayerObject = [PFObject objectWithClassName:className];
                [self setPlayerObjectInformation:newPlayerObject];
                if ([newPlayerObject save]) {
                    if (newPlayerObject.objectId){
                        [[NSUserDefaults standardUserDefaults] setObject:newPlayerObject.objectId forKey:PlayerRemoteObjectIdKey];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    [self checkStamina];
                }
            } @catch (NSException *e) {
                NSLog(@"Failed to create a new player remote object");
            }
            
        }
        [[UIApplication sharedApplication] endBackgroundTask:backgroundExceptionIdentifer];
    });
#endif
}

+ (BOOL)isFreshInstall
{
    BOOL playerFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[PlayerDataManager localPlayerSavePath]];
    return !playerFileExists;
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

- (void)setFtueState:(FTUEState)ftueState
{
    [self.playerData setObject:[NSNumber numberWithInt:ftueState] forKey:PlayerFTUEState];
}

- (FTUEState)ftueState
{
    return [[self.playerData objectForKey:PlayerFTUEState] intValue];
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
        totalScore += rating;
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
    return [self highestLevelCompleted] >= 6;
}

- (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level {
    [self.playerData setValue:[NSNumber numberWithInt:rating] forKey:[PlayerLevelRatingKeyPrefix stringByAppendingFormat:@"%d", level]];
}

- (NSInteger)levelRatingForLevel:(NSInteger)level {
    if (level == 1) {
        return 0; //You can't get rating from the tutorial level
    }
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

- (NSString *)playerName {
    return [self.playerData objectForKey:PlayerName];
}

- (void)setPlayerName:(NSString *)playerName
{
    [self.playerData setObject:playerName forKey:PlayerName];
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
        [self.playerData setValue:[NSNumber numberWithInt:level] forKey:PlayerHighestLevelCompleted];
    }
}

- (void)setPlayerObjectInformation:(PFObject*)obj {
    NSInteger numVisits = [[obj objectForKey:@"saves"] intValue];
    [obj setObject:[NSNumber numberWithInt:[self highestLevelCompleted]] forKey:@"HLCompleted"];
    [obj setObject:[NSNumber numberWithInt:self.gold] forKey:@"Gold"];
    [obj setObject:[NSNumber numberWithInt:numVisits+1] forKey:@"saves"];
    if (self.playerName) {
        [obj setObject:self.playerName forKey:@"PlayerName"];
    }
    
    NSMutableArray *talents = [NSMutableArray arrayWithCapacity:5];
    
    for (int i = 0; i < 5; i++) {
        NSString *choice = [self selectedChoiceForTier:i];
        if (choice) {
            [talents addObject:choice];
        }
    }
    [obj setObject:talents forKey:@"talents"];
    
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
        [levelScores addObject:numberObj];
    }
    
    [obj setObject:levelScores forKey:@"levelScores"];
    
    NSMutableArray *levelFails = [NSMutableArray arrayWithCapacity:highestLevelCompleted];
    for (int i = 1; i <= highestLevelCompleted + 1; i++){
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

- (NSInteger)maximumStandardSpellSlots
{
    NSInteger totalSlots = 3; //Default is 3.
    
    if ([self hasPurchasedContentWithKey:MainGameContentKey]) {
        totalSlots ++;
    }
    return totalSlots;
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
    return [item.key isEqualToString:@"Heal"] || [[self.playerData objectForKey:[item key]] boolValue];
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
    for (ShopItem *item in allShopItems){
        if ([purchasedItems containsObject:item]){
            [allSpells addObject:[[[item purchasedSpell] class] defaultSpell]];
        }
    }
    return allSpells;
}

- (void)postGoldChangedNotification
{
    if (_localPlayer == self) {
        NSInteger currentGold = [[self.playerData objectForKey:PlayerGold] intValue];
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerGoldDidChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold]];
    }
}

- (void)playerEarnsGold:(NSInteger)gold{
    if (gold <= 0)
        return;
    NSInteger currentGold = [[self.playerData objectForKey:PlayerGold] intValue];
    currentGold += gold;
    [self.playerData setObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold];
    [self saveLocalPlayer];
    [self postGoldChangedNotification];
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
    [self postGoldChangedNotification];
}

#pragma mark - Talents

- (NSString*)selectedChoiceForTier:(NSInteger)tier {
    NSDictionary *config =  (NSDictionary*)[self.playerData objectForKey:TalentConfig];
    return [config objectForKey:[NSString stringWithFormat:@"tier-%i", tier]];
}

- (NSDictionary*)talentConfig {
    return (NSDictionary*)[self.playerData objectForKey:TalentConfig];
}

- (void)resetConfig {
    [self.playerData setObject:[NSDictionary dictionary] forKey:TalentConfig];
}

- (void)selectChoice:(NSString*)choice forTier:(NSInteger)tier{
    NSDictionary *divinityConfig = (NSDictionary*)[self.playerData objectForKey:TalentConfig];
    if (!divinityConfig){
        divinityConfig = [NSDictionary dictionary];
    }
    NSMutableDictionary *newConfig = [NSMutableDictionary dictionaryWithDictionary:divinityConfig];
    
    [newConfig setObject:choice forKey:[NSString stringWithFormat:@"tier-%i", tier]];
    [self.playerData setObject:newConfig forKey:TalentConfig];
    [self saveLocalPlayer];
}

- (NSInteger)numTalentTiersUnlocked
{
    NSInteger currentRating = [[PlayerDataManager localPlayer] totalRating];
    NSInteger totalTiers = 0;
    for (int i = 0; i < 5; i++){
        if (currentRating >= [Talents requiredRatingForTier:i]) {
            totalTiers++;
        }
    }
    return totalTiers;
}

- (NSInteger)numUnspentTalentChoices
{
    NSInteger unlockedTiers = [self numTalentTiersUnlocked];
    NSInteger total = 0;
    for (int i = 0; i < unlockedTiers; i++) {
        if (![self selectedChoiceForTier:i]) {
            total++;
        }
    }
    return total;
}

- (BOOL)isTalentsUnlocked {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return [[PlayerDataManager localPlayer] totalRating] >= [Talents requiredRatingForTier:0];
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

- (BOOL)hasPerformedGamePurchaseCheck
{
    return [[self.playerData objectForKey:GamePurchasedCheckedKey] boolValue];
}

- (void)performGamePurchaseCheckForFreshInstall:(BOOL)isFreshInstall
{
    if (!isFreshInstall) {
        [self purchaseContentWithKey:MainGameContentKey];
    }
    [self.playerData setObject:[NSNumber numberWithBool:YES] forKey:GamePurchasedCheckedKey];
    [self saveLocalPlayer];
}

- (void)purchaseContentWithKey:(NSString*)key
{
    //Yay you made a purchase =D
    NSMutableArray *contentKeys = [NSMutableArray array];
    if ([self.playerData objectForKey:ContentKeys]) {
        contentKeys = [NSMutableArray arrayWithArray:[self.playerData objectForKey:ContentKeys]];
    }
    [contentKeys addObject:key];
    [self.playerData setObject:contentKeys forKey:ContentKeys];
}

- (BOOL)hasPurchasedContentWithKey:(NSString*)key
{
    NSArray *contentKeys = [self.playerData objectForKey:ContentKeys];
    if (contentKeys && [contentKeys containsObject:key]) {
        return YES;
    }
    return NO;
}

#pragma mark - Settings 

- (void)setMusicDisabled:(BOOL)musicDisabled
{
    [self.playerData setObject:[NSNumber numberWithBool:musicDisabled] forKey:MusicDisabledKey];
    [self saveLocalPlayer];
}

- (BOOL)musicDisabled
{
    return [[self.playerData objectForKey:MusicDisabledKey] boolValue];
}

- (void)setEffectsDisabled:(BOOL)effectsDisabled
{
    [self.playerData setObject:[NSNumber numberWithBool:effectsDisabled] forKey:EffectsDisabledKey];
    [self saveLocalPlayer];
}

- (BOOL)effectsDisabled
{
    return [[self.playerData objectForKey:EffectsDisabledKey] boolValue];
}

- (void)resetPlayer
{
    [self resetConfig];
    NSArray *contentKeys = [[self.playerData objectForKey:ContentKeys] retain];
    self.playerData = [NSMutableDictionary dictionary];
    if (contentKeys) {
        [self.playerData setObject:contentKeys forKey:ContentKeys];
    }
    [contentKeys release];
    [self.playerData setObject:[NSNumber numberWithBool:YES] forKey:GamePurchasedCheckedKey];
    [self saveLocalPlayer];
}

- (void)unlockAll
{
    for (int i = 1; i <= 21; i++) {
        [self completeLevel:i];
        [self setLevelRating:5 forLevel:i];
    }
    [self purchaseContentWithKey:MainGameContentKey];
    [self saveLocalPlayer];
}

- (BOOL)isAppStoreReviewRequested
{
    return  [[self.playerData objectForKey:HasRequestedAppStoreReviewKey] boolValue];
}

- (void)appStoreReviewPerformed
{
    [self.playerData setObject:[NSNumber numberWithBool:YES] forKey:HasRequestedAppStoreReviewKey];
    [self saveLocalPlayer];
}

- (BOOL)shouldRequestAppStore
{
    if (!self.isAppStoreReviewRequested && !app_store_requested_this_session) {
        app_store_requested_this_session = YES;
        return YES;
    }
    return NO;
}

#pragma mark - Items

- (NSString *)slotKeyForSlot:(SlotType)slot
{
    return [NSString stringWithFormat:@"%@-%i",PlayerSlotKey, slot];
}

- (NSArray*)inventory
{
    NSArray *inventory = [self.playerData objectForKey:PlayerInventoryKey];
    if (!inventory) {
        return [NSArray array];
    }
    NSMutableArray *decodedInventory = [NSMutableArray arrayWithCapacity:inventory.count];
    for (NSString *cacheString in inventory) {
        EquipmentItem *item = [[[EquipmentItem alloc] initWithItemCacheString:cacheString] autorelease];
        if (item){
            [decodedInventory addObject:item];
        }
    }
    return decodedInventory;
}

- (NSInteger)maximumInventorySize
{
    return 15;
}

- (BOOL)isInventoryFull
{
    return self.inventory.count >= self.maximumInventorySize;
}

- (NSInteger)totalItemsEarned
{
    return [[self.playerData objectForKey:PlayerTotalItemsEarnedKey] integerValue];
}

- (void)playerEarnsItem:(EquipmentItem *)item
{
    NSInteger newTotal = self.totalItemsEarned + 1;
    [item itemEarnedWithId:newTotal];
    [self.playerData setObject:[NSNumber numberWithInt:newTotal] forKey:PlayerTotalItemsEarnedKey];
    
    NSArray *inventory = [self.playerData objectForKey:PlayerInventoryKey];
    if (!inventory) {
        inventory = [NSArray array];
    }
    NSArray *newInventory = [inventory arrayByAddingObject:item.cacheString];
    [self.playerData setObject:newInventory forKey:PlayerInventoryKey];
    [self saveLocalPlayer];
}

- (void)playerEquipsItem:(EquipmentItem*)item
{
    NSArray *inventory = [self inventory];
    EquipmentItem *thisItem = nil;
    
    for (EquipmentItem *inventoryItem in inventory) {
        if (inventoryItem.earnedItemId == item.earnedItemId) {
            thisItem = inventoryItem;
            break;
        }
    }
    if (thisItem) {
        [self playerRemovesItemFromInventory:thisItem];
        [self.playerData setObject:thisItem.cacheString forKey:[self slotKeyForSlot:thisItem.slot]];
    }
    
    [self saveLocalPlayer];
}

- (void)playerUnequipsItemInSlot:(SlotType)slot
{
    EquipmentItem *item = [[[EquipmentItem alloc] initWithItemCacheString:[self.playerData objectForKey:[self slotKeyForSlot:slot]]] autorelease];
    if (item) {
        [item retain];
        [self.playerData removeObjectForKey:[self slotKeyForSlot:slot]];
        [self playerEarnsItem:item];
        [item release];
    }
}

- (BOOL)playerCanEquipItem:(EquipmentItem*)item
{
    return [self itemForSlot:item.slot] == nil;
}

- (EquipmentItem*)itemForSlot:(SlotType)slotType
{
    NSString *cacheString = [self.playerData objectForKey:[self slotKeyForSlot:slotType]];
    if (cacheString) {
        return [[[EquipmentItem alloc] initWithItemCacheString:cacheString] autorelease];
    }
    return nil;
}

- (NSArray *)equippedItems
{
    if (self != _localPlayer) {
        NSLog(@"Derp");
    }
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:6];
    
    for (int i = 0; i < SlotTypeMaximum; i++) {
        if ([self itemForSlot:i]) {
            [items addObject:[self itemForSlot:i]];
        }
    }
    return [NSArray arrayWithArray:items];
}

- (void)playerSellsItem:(EquipmentItem *)item
{
    if ([[self itemForSlot:item.slot] isEarnedItem:item]) {
        [self playerUnequipsItemInSlot:item.slot];
    }
    NSInteger sellPrice = [item salePrice];
    [self playerRemovesItemFromInventory:item];
    [self playerEarnsGold:sellPrice];
}

- (void)playerRemovesItemFromInventory:(EquipmentItem *)item
{
    NSArray *inventory = [self inventory];
    EquipmentItem *thisItem = nil;
    
    //Find the item in the inventory if exists
    for (EquipmentItem *inventoryItem in inventory) {
        if ([item isEarnedItem:inventoryItem]) {
            thisItem = inventoryItem;
            break;
        }
    }
    
    if (thisItem) {
        [thisItem retain];
        NSMutableArray *newInventory = [NSMutableArray arrayWithArray:[self.playerData objectForKey:PlayerInventoryKey]];
        [newInventory removeObject:thisItem.cacheString];
        
        [self.playerData setObject:newInventory forKey:PlayerInventoryKey];
        [thisItem release];
    }
}

#pragma mark - Ally Upgrades
- (NSInteger)nextAllyDamageUpgradeCost
{
    return 200 + [self allyDamageUpgrades] * 50;
}

- (NSInteger)nextAllyHealthUpgradeCost
{
    if (self.allyHealthUpgrades >= 25) {
        return MAXIMUM_ALLY_UPGRADES;
    }
    return 200 + [self allyHealthUpgrades] * 50;
}

- (NSInteger)allyDamageUpgrades
{
    return [[self.playerData objectForKey:PlayerAllyDamageUpgradesKey] integerValue];
}

- (NSInteger)allyHealthUpgrades
{
    return [[self.playerData objectForKey:PlayerAllyHealthUpgradesKey] integerValue];
}

- (void)purchaseAllyDamageUpgrade
{
    NSInteger cost = self.nextAllyDamageUpgradeCost;
    if (self.gold >= cost) {
        NSInteger numUpgrades = [[self.playerData objectForKey:PlayerAllyDamageUpgradesKey] integerValue];
        numUpgrades++;
        [self.playerData setObject:[NSNumber numberWithInt:numUpgrades] forKey:PlayerAllyDamageUpgradesKey];
        [self playerLosesGold:cost];
    }
}

- (void)purchaseAllyHealthUpgrade
{
    NSInteger cost = self.nextAllyHealthUpgradeCost;
    if (self.gold >= cost) {
        NSInteger numUpgrades = [[self.playerData objectForKey:PlayerAllyHealthUpgradesKey] integerValue];
        numUpgrades++;
        [self.playerData setObject:[NSNumber numberWithInt:numUpgrades] forKey:PlayerAllyHealthUpgradesKey];
        [self playerLosesGold:cost];
    }
}

#pragma mark - Stamina

- (void)setStamina:(NSInteger)stamina
{
    BOOL willChange = stamina != _stamina;
    _stamina = stamina;
    if (willChange) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerStaminaDidChangeNotification object:nil userInfo:nil];
    }
}

- (void)checkStamina
{
#if ANDROID
#else
    NSString *remoteObjectId = [self remoteObjectId];
    if (remoteObjectId) {
        [PFCloud callFunctionInBackground:@"getStamina" withParameters:[NSDictionary dictionaryWithObject:remoteObjectId forKey:@"playerId"] block:^(id object, NSError *error) {
            NSDictionary *result = (NSDictionary*)object;
            NSInteger stamina = [[result objectForKey:@"stamina"] intValue];
            NSInteger maxStamina = [[result objectForKey:@"maxStamina"] intValue];
            NSInteger secondsUntil = [[result objectForKey:@"secondsUntilNextStamina"] intValue];
            NSTimeInterval secondsPerStamina = [[result objectForKey:@"secondsPerStamina"] intValue];
            self.secondsPerStamina = secondsPerStamina;
            self.maxStamina = maxStamina;
            self.nextStamina = [NSDate dateWithTimeIntervalSinceNow:secondsUntil];
            self.stamina = stamina; //Must be last for notification purposes
        }];
    }
#endif
}

#pragma mark - Score

- (void)submitScore:(NSInteger)score forLevel:(NSInteger)level onDifficulty:(NSInteger)difficulty andDuration:(NSTimeInterval)duration
{
    if (_localPlayer != self) return;
#if ANDROID
#else
    NSString *playerClassName = @"player";
    NSString *className = @"scoreboard";
#if TARGET_IPHONE_SIMULATOR
    className = @"test_scoreboard";
    playerClassName = @"test_player";
#endif
#if DEBUG
    className = @"test_scoreboard";
    playerClassName = @"test_player";
#endif
    NSInteger backgroundExceptionIdentifer = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    dispatch_async([PlayerDataManager parseQueue], ^{
        NSString* playerObjectID = [self remoteObjectId];
        if (playerObjectID){
            @try {
                PFQuery *playerObjectQuery = [PFQuery queryWithClassName:playerClassName];
                NSArray *objects = [playerObjectQuery findObjects];
                PFObject *playerObject;
                if (objects.count > 0) {
                    playerObject = [objects objectAtIndex:0];
                    PFObject *newScoreboardObject = [PFObject objectWithClassName:className];
                    [newScoreboardObject setObject:[NSNumber numberWithInteger:score] forKey:@"score"];
                    [newScoreboardObject setObject:playerObject forKey:@"playerId"];
                    [newScoreboardObject setObject:[NSNumber numberWithInteger:level] forKey:@"levelNumber"];
                    [newScoreboardObject setObject:[NSNumber numberWithInteger:difficulty] forKey:@"difficulty"];
                    [newScoreboardObject setObject:[NSNumber numberWithInteger:duration] forKey:@"duration"];
                    if (![newScoreboardObject save]) {
                        NSLog(@"Failed to submit score because the save failed");
                    }
                } else {
                    NSLog(@"Player object not found");
                }
            } @catch (NSException *e) {
                NSLog(@"Failed to submit score due to an exception: %@", e.description);
            }
        } else {

            
        }
        [[UIApplication sharedApplication] endBackgroundTask:backgroundExceptionIdentifer];
    });
#endif

}

- (void)staminaUsedWithCompletion:(SpendStaminaResultBlock)block
{
#if ANDROID
#else
    NSString *remoteObjectId = [self remoteObjectId];
    if (remoteObjectId) {
        [PFCloud callFunctionInBackground:@"spendStamina" withParameters:[NSDictionary dictionaryWithObject:remoteObjectId forKey:@"playerId"] block:^(id object, NSError *error) {
            if (error) {
                block(NO);
            } else {
                NSDictionary *result = (NSDictionary*)object;
                NSInteger newStamina = [[result objectForKey:@"stamina"] intValue];
                NSTimeInterval secondsPerStamina = [[result objectForKey:@"secondsPerStamina"] intValue];
                NSInteger secondsUntil = [[result objectForKey:@"secondsUntilNextStamina"] intValue];
                self.secondsPerStamina = secondsPerStamina;
                BOOL success = [[result objectForKey:@"success"] boolValue];
                self.stamina = newStamina;
                self.nextStamina = [NSDate dateWithTimeIntervalSinceNow:secondsUntil];
                block(success);
                if (success) {
                    [[PlayerDataManager localPlayer] checkStamina];
                }
            }
        }];
    }
#endif
}

- (NSTimeInterval)secondsUntilNextStamina
{
    if (!self.nextStamina) {
        return STAMINA_NOT_LOADED;
    }
    return self.nextStamina.timeIntervalSince1970 - [[NSDate date] timeIntervalSince1970];
}
@end

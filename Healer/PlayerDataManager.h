//
//  PersistantDataManager.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "Shop.h"

#define MAX_CHARACTERS 5

extern NSString* const PlayerHighestLevelAttempted;
extern NSString* const PlayerHighestLevelCompleted;
extern NSString* const PlayerRemoteObjectIdKey;
extern NSString* const PlayerGold;
extern NSString* const PlayerGoldDidChangeNotification;

@class ShopItem, Spell;

@interface PlayerDataManager : NSObject
@property (nonatomic, readonly) NSInteger gold;
@property (nonatomic, readonly) NSArray* allOwnedSpells;

+ (PlayerDataManager *)localPlayer;

#pragma mark - Shop And Gold
- (void)playerEarnsGold:(NSInteger)gold;
- (void)playerLosesGold:(NSInteger)gold;
- (void)purchaseItem:(ShopItem*)item;
- (BOOL)canAffordShopItem:(ShopItem*)item;
- (BOOL)hasShopItem:(ShopItem*)item;
- (BOOL)hasSpell:(Spell*)spell;

#pragma mark - Divinity
- (NSString*)selectedChoiceForTier:(NSInteger)tier;
- (NSDictionary*)localDivinityConfig;
- (void)resetConfig;
- (void)selectChoice:(NSString*)choice forTier:(NSInteger)tier;

#pragma mark - Saving
- (void)saveLocalPlayer;
- (void)saveRemotePlayer;

#pragma mark - Progress
@property (nonatomic, readwrite) NSInteger lastSelectedLevel;
- (NSInteger)totalRating;
- (NSInteger)difficultyForLevelNumber:(NSInteger)levelNum;
- (void)difficultySelected:(NSInteger)challenge forLevelNumber:(NSInteger)levelNum;

- (BOOL)hasShownNormalModeCompleteScene;
- (void)normalModeCompleteSceneShown;

- (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level;
- (NSInteger)levelRatingForLevel:(NSInteger)level;
- (void)setScore:(NSInteger)score forLevel:(NSInteger)level;
- (NSInteger)scoreForLevel:(NSInteger)level;
- (NSInteger)highestLevelCompleted;
- (NSInteger)highestLevelAttempted;

- (void)failLevel:(NSInteger)level;
- (void)completeLevel:(NSInteger)level;

#pragma mark - Purchasing Content
- (void)purchaseContentWithKey:(NSString*)key;
- (BOOL)hasPurchasedContentWithKey:(NSString*)key;
/* Painful and Brutal Difficulties, The final Campaign, and the final shop category require purchasing the third campaign to unlock */
- (BOOL)isEncounterPurchased:(NSInteger)encounterNum;
- (BOOL)isShopCategoryPurchased:(ShopCategory)category;
- (NSInteger)isDifficultyPurchased:(NSInteger)difficulty;
- (void)offerCampaignUnlock;

#pragma mark - Multiplayer

- (BOOL)isMultiplayerUnlocked;

//Spells
- (void)setUsedSpells:(NSArray*)spells;
- (NSArray*)lastUsedSpells;

//DEBUG
- (void)clearLevelRatings;

- (void)setPlayerObjectInformation:(PFObject*)obj;

@end

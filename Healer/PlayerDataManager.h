//
//  PlayerDataManager.h
//  Healer
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

#import <Foundation/Foundation.h>

#if ANDROID
#else
#import <Parse/Parse.h>
#endif
#import "Shop.h"
#import "Player.h"
#import "EquipmentItem.h"
#import "Encounter.h"

#define MAX_CHARACTERS 5

#define END_FREE_ENCOUNTER_LEVEL 7

#define STAMINA_NOT_LOADED -9999

#define MAXIMUM_ALLY_UPGRADES 50

typedef void (^SpendStaminaResultBlock)(BOOL success);

#define END_FREE_STRING @"Purchase The Legacy of Torment Expansion to unlock new bosses, an additional spell slot, the Cleric's Archives, and the Sage Vault!"

typedef enum {
    FTUEStateFresh = 1,
    FTUEStateTargetSelected,
    FTUEStateTargetHealed,
    FTUEStateAbilityIconSelected,
    FTUEStateBattle1Finished,
    FTUEStateGreaterHealPurchased
} FTUEState;

extern NSString* const PlayerHighestLevelAttempted;
extern NSString* const PlayerHighestLevelCompleted;
extern NSString* const PlayerRemoteObjectIdKey;
extern NSString* const PlayerGold;
extern NSString* const PlayerGoldDidChangeNotification;
extern NSString* const PlayerStaminaDidChangeNotification;

extern NSString* const MainGameContentKey;

@class ShopItem, Spell, Encounter;

#if ANDROID
@class PFObject;
#endif

@interface PlayerDataManager : NSObject
@property (nonatomic, readonly) NSInteger gold;
@property (nonatomic, readonly) NSInteger maximumStandardSpellSlots;
@property (nonatomic, readonly) NSArray* allOwnedSpells;
@property (nonatomic, readwrite) FTUEState ftueState;
@property (nonatomic, assign, readwrite) NSString *playerName;

+ (PlayerDataManager *)localPlayer;
+ (Player*)playerFromLocalPlayer;
+ (Player *)playerFromData:(NSDictionary*)data;

- (id)initWithPlayerData:(NSDictionary *)data;
- (NSString *)playerMessage;
+ (Player *)playerFromPlayerMessage:(NSString *)playerMessage;

- (BOOL)isAppStoreReviewRequested;
- (void)appStoreReviewPerformed;
- (BOOL)shouldRequestAppStore;

#pragma mark - Shop And Gold
- (void)playerEarnsGold:(NSInteger)gold;
- (void)playerLosesGold:(NSInteger)gold;
- (void)purchaseItem:(ShopItem*)item;
- (BOOL)canAffordShopItem:(ShopItem*)item;
- (BOOL)hasShopItem:(ShopItem*)item;
- (BOOL)hasSpell:(Spell*)spell;

#pragma mark - Talents
- (NSString*)selectedChoiceForTier:(NSInteger)tier;
- (NSDictionary*)talentConfig;
- (void)resetConfig;
- (void)selectChoice:(NSString*)choice forTier:(NSInteger)tier;
- (NSInteger)numUnspentTalentChoices;
- (BOOL)isTalentsUnlocked;
- (NSInteger)numTalentTiersUnlocked;

#pragma mark - Saving
+ (BOOL)isFreshInstall;
- (void)saveLocalPlayer;
- (void)saveRemotePlayer;
+ (NSString *)localPlayerSavePath;

#pragma mark - Progress
@property (nonatomic, readwrite) NSInteger lastSelectedLevel;
- (NSInteger)totalRating;
- (NSInteger)difficultyForLevelNumber:(NSInteger)levelNum encounterType:(EncounterType)encounterType;
- (void)difficultySelected:(NSInteger)challenge forLevelNumber:(NSInteger)levelNum encounterType:(EncounterType)encounterType;

- (BOOL)hasShownNormalModeCompleteScene;
- (void)normalModeCompleteSceneShown;

- (void)setLevelRating:(NSInteger)rating forLevel:(NSInteger)level encounterType:(EncounterType)encounterType;
- (NSInteger)levelRatingForLevel:(NSInteger)level encounterType:(EncounterType)encounterType;
- (void)setScore:(NSInteger)score forLevel:(NSInteger)level encounterType:(EncounterType)encounterType;
- (NSInteger)scoreForLevel:(NSInteger)level encounterType:(EncounterType)encounterType;
- (NSInteger)highestLevelCompleted;
- (NSInteger)highestLevelAttempted;

- (void)failLevel:(NSInteger)level encounterType:(EncounterType)encounterType;
- (void)completeLevel:(NSInteger)level encounterType:(EncounterType)encounterType;

#pragma mark - Purchasing Content
- (void)performGamePurchaseCheckForFreshInstall:(BOOL)isFreshInstall;
- (BOOL)hasPerformedGamePurchaseCheck;
- (void)purchaseContentWithKey:(NSString*)key;
- (BOOL)hasPurchasedContentWithKey:(NSString*)key;

#pragma mark - Multiplayer

- (BOOL)isMultiplayerUnlocked;

//Spells
- (void)setUsedSpells:(NSArray*)spells;
- (NSArray*)lastUsedSpells;

//DEBUG
- (void)clearLevelRatings;

- (void)setPlayerObjectInformation:(PFObject*)obj;

#pragma mark - Items
@property (nonatomic, readonly) NSArray *inventory;
@property (nonatomic, readonly) NSInteger maximumInventorySize;
@property (nonatomic, readonly) NSArray *equippedItems;
@property (nonatomic, readonly) NSInteger totalItemsEarned;

- (BOOL)isInventoryFull;
- (EquipmentItem*)itemForSlot:(SlotType)slotType;
- (void)playerEarnsItem:(EquipmentItem*)item;
- (BOOL)playerCanEquipItem:(EquipmentItem*)item;
- (void)playerEquipsItem:(EquipmentItem*)item;
- (void)playerUnequipsItemInSlot:(SlotType)slot;
- (void)playerSellsItem:(EquipmentItem*)item;

#pragma mark - Ally Upgrades
@property (nonatomic, readonly) NSInteger nextAllyDamageUpgradeCost;
@property (nonatomic, readonly) NSInteger nextAllyHealthUpgradeCost;
@property (nonatomic, readonly) NSInteger allyDamageUpgrades;
@property (nonatomic, readonly) NSInteger allyHealthUpgrades;

- (void)purchaseAllyDamageUpgrade;
- (void)purchaseAllyHealthUpgrade;

#pragma mark - Score
- (void)submitScore:(Encounter*)encounter player:(Player*)player;

#pragma mark - Settings
@property (nonatomic, readwrite) BOOL musicDisabled;
@property (nonatomic, readwrite) BOOL effectsDisabled;
//Settings Options
- (void)resetPlayer;
- (void)unlockAll;

#pragma mark - Stamina
@property (nonatomic, readonly) NSInteger stamina;
@property (nonatomic, readonly) NSInteger maxStamina;
@property (nonatomic, readonly, retain) NSDate *nextStamina;
@property (nonatomic, readonly) NSTimeInterval secondsUntilNextStamina;
@property (nonatomic, readonly) NSTimeInterval secondsPerStamina;
- (void)staminaUsedWithCompletion:(SpendStaminaResultBlock)block;
- (void)checkStamina;

@end

//
//  Shop.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "ShopItem.h"

extern NSString* const PlayerGold;
extern NSString* const PlayerGoldDidChangeNotification;

typedef enum {
    ShopCategoryEssentials,
    ShopCategoryAdvanced,
    ShopCategoryArchives,
    ShopCategoryVault
} ShopCategory;

@interface Shop : NSObject
+ (BOOL)playerCanAffordShopItem:(ShopItem*)item;
+ (BOOL)playerHasSpell:(Spell*)spell;
+ (BOOL)playerHasShopItem:(ShopItem*)item;
+ (void)purchaseItem:(ShopItem*)item;
+ (NSInteger)localPlayerGold;
+ (void)playerEarnsGold:(NSInteger)gold;
+ (void)playerLosesGold:(NSInteger)gold;
+ (NSArray*)allShopItems;
+ (NSArray*)purchasedItems;
+ (NSArray*)allOwnedSpells;

//Divinity
+ (void)resetDivinity; //Debug
+ (NSInteger)costForDivinityTier:(NSInteger)tier;
+ (NSInteger)costForNextDivinityTier;
+ (NSInteger)numDivinityTiersPurchased;
+ (void)purchaseNextDivinityTier;

//Shop Categories
+ (ShopCategory)highestCategoryUnlocked;
+ (NSInteger)numPurchasesUntilNextCategory;
+ (NSArray*)essentialsShopItems;
+ (NSArray*)advancedShopItems;
+ (NSArray*)archivesShopItems;
+ (NSArray*)vaultShopItems;
@end

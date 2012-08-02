//
//  Shop.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "ShopItem.h"

extern NSString* const PlayerGold;

typedef enum {
    ShopCategoryEssentials,
    ShopCategoryTopShelf,
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
+ (NSInteger)costForNextDivinityTier;
+ (NSInteger)numDivinityTiersPurchased;
+ (void)purchaseNextDivinityTier;

//Shop Categories
+ (ShopCategory)highestCategoryUnlocked;
+ (NSArray*)essentialsShopItems;
+ (NSArray*)topShelfShopItems;
+ (NSArray*)archivesShopItems;
+ (NSArray*)vaultShopItems;
@end

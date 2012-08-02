//
//  Shop.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "ShopItem.h"

extern NSString* const PlayerGold;

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
+ (NSArray*)essentialsShopItems;
+ (NSArray*)topShelfShopItems;
+ (NSArray*)archivesShopItems;
+ (NSArray*)vaultShopItems;
@end

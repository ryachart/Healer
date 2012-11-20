//
//  Shop.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "ShopItem.h"

typedef enum {
    ShopCategoryEssentials,
    ShopCategoryAdvanced,
    ShopCategoryArchives,
    ShopCategoryVault
} ShopCategory;

@interface Shop : NSObject
+ (NSArray*)allShopItems;

//Shop Categories
+ (ShopCategory)highestCategoryUnlocked;
+ (NSInteger)numPurchasesUntilNextCategory;
+ (NSArray*)essentialsShopItems;
+ (NSArray*)advancedShopItems;
+ (NSArray*)archivesShopItems;
+ (NSArray*)vaultShopItems;
@end

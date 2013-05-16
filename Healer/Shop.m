//
//  Shop.m
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "Shop.h"
#import "Spell.h"
#import "ShopItem.h"
#import "PlayerDataManager.h"
#import "Talents.h"

static NSArray *shopItems = nil;

@implementation Shop

+ (NSArray *)costSortedItemsArray:(NSMutableArray *)itemsArray
{
    return [itemsArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        ShopItem *item1 = (ShopItem*)obj1;
        ShopItem *item2 = (ShopItem*)obj2;
        
        if (item1.goldCost > item2.goldCost) {
            return NSOrderedDescending;
        } else if (item1.goldCost == item2.goldCost) {
            return NSOrderedSame;
        }
        
        return NSOrderedAscending;
    }];
}

+(NSArray*)allShopItems{
    if (!shopItems){
        NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
        
        [items addObjectsFromArray:[Shop essentialsShopItems]];
        [items addObjectsFromArray:[Shop advancedShopItems]];
        [items addObjectsFromArray:[Shop archivesShopItems]];
        [items addObjectsFromArray:[Shop vaultShopItems]];
        
        shopItems = [items retain];
    }
    return shopItems;
}

+ (NSInteger)purchasesForCategory:(ShopCategory)category {
    switch (category) {
        case ShopCategoryEssentials:
            return 0;
        case ShopCategoryAdvanced:
            return 4;
        case ShopCategoryArchives:
            return 8;
        case ShopCategoryVault:
            return 10;
    }
    return 0;
}

+ (ShopCategory)highestCategoryUnlocked {
    NSInteger totalPurchases = [[PlayerDataManager localPlayer] allOwnedSpells].count;
    ShopCategory category = ShopCategoryEssentials;
    if (totalPurchases >= [Shop purchasesForCategory:ShopCategoryAdvanced]){
        category = ShopCategoryAdvanced;
    }
    if (totalPurchases >= [Shop purchasesForCategory:ShopCategoryArchives]){
        category = ShopCategoryArchives;
    }
    if (totalPurchases > [Shop purchasesForCategory:ShopCategoryVault]){
        category = ShopCategoryVault;
    }
    return category;
}

+ (NSInteger)purchasesUntilCategory:(NSInteger)category
{
    NSInteger totalPurchases = [[PlayerDataManager localPlayer] allOwnedSpells].count;
    NSInteger requiredForCategory = [Shop purchasesForCategory:category];
    return requiredForCategory - totalPurchases;
}

+ (NSInteger)numPurchasesUntilNextCategory {
    NSInteger totalPurchases = [[PlayerDataManager localPlayer] allOwnedSpells].count;
    ShopCategory highestCategory = [Shop highestCategoryUnlocked];
    if (highestCategory == ShopCategoryVault){
        return 0;
    }
    return [Shop purchasesForCategory:highestCategory] - totalPurchases;
}

+ (NSArray*)essentialsShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];

    ShopItem *heal = [[ShopItem alloc] initWithSpell:[Heal defaultSpell]];
    [items addObject:[heal autorelease]];
    
    ShopItem *greaterHeal = [[ShopItem alloc] initWithSpell:[GreaterHeal defaultSpell]];
    [items addObject:[greaterHeal autorelease]];

    ShopItem *regrow = [[ShopItem alloc] initWithSpell:[Regrow defaultSpell]];
    [items addObject:[regrow autorelease]];

    ShopItem *forkedHeal = [[ShopItem alloc] initWithSpell:[ForkedHeal defaultSpell]];
    [items addObject:[forkedHeal autorelease]];


    return [Shop costSortedItemsArray:items];
}

+ (NSArray*)advancedShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
    ShopItem *purify = [[ShopItem alloc] initWithSpell:[Purify defaultSpell]];
    [items addObject:[purify autorelease]];
    
    ShopItem *touchOfLight = [[ShopItem alloc] initWithSpell:[TouchOfHope defaultSpell]];
    [items addObject:[touchOfLight autorelease]];
    
    ShopItem *healingBurst = [[ShopItem alloc] initWithSpell:[HealingBurst defaultSpell]];
    [items addObject:[healingBurst autorelease]];
    
    ShopItem *starsOfA = [[ShopItem alloc] initWithSpell:[StarsOfAravon defaultSpell]];
    [items addObject:[starsOfA autorelease]];
    
    ShopItem *barrier = [[ShopItem alloc] initWithSpell:[Barrier defaultSpell]];
    [items addObject:[barrier autorelease]];

    return [Shop costSortedItemsArray:items];
    
}
+ (NSArray*)archivesShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
    
    ShopItem *fadingLight = [[ShopItem alloc] initWithSpell:[FadingLight defaultSpell]];
    [items addObject:[fadingLight autorelease]];
    
    ShopItem *orbsOfLight = [[ShopItem alloc] initWithSpell:[OrbsOfLight defaultSpell]];
    [items addObject:[orbsOfLight autorelease]];
    
    ShopItem *swirlingLight = [[ShopItem alloc] initWithSpell:[SwirlingLight defaultSpell]];
    [items addObject:[swirlingLight autorelease]];
    
    ShopItem *blessedArmor = [[ShopItem alloc] initWithSpell:[BlessedArmor defaultSpell]];
    [items addObject:[blessedArmor autorelease]];
    
    ShopItem *lightEternal = [[ShopItem alloc] initWithSpell:[LightEternal defaultSpell]];
    [items addObject:[lightEternal autorelease]];
    
    ShopItem *sunburst = [[ShopItem alloc] initWithSpell:[Sunburst defaultSpell]];
    [items addObject:[sunburst autorelease]];

    return [Shop costSortedItemsArray:items];
}
+ (NSArray*)vaultShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
    
    ShopItem *soaringSpirit = [[ShopItem alloc] initWithSpell:[SoaringSpirit defaultSpell]];
    [items addObject:[soaringSpirit autorelease]];
    
    ShopItem *respite = [[ShopItem alloc] initWithSpell:[Respite defaultSpell]];
    [items addObject:[respite autorelease]];
    
    ShopItem *attunement = [[ShopItem alloc] initWithSpell:[Attunement defaultSpell]];
    [items addObject:[attunement autorelease]];

    ShopItem *wanderingSpirit = [[ShopItem alloc] initWithSpell:[WanderingSpirit defaultSpell]];
    [items addObject:[wanderingSpirit autorelease]];

    ShopItem *wardOfAncients = [[ShopItem alloc] initWithSpell:[WardOfAncients defaultSpell]];
    [items addObject:[wardOfAncients autorelease]];
    return [Shop costSortedItemsArray:items];
    
}


@end

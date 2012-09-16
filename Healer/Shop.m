//
//  Shop.m
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "Shop.h"
#import "Spell.h"
#import "ShopItem.h"
#import "PersistantDataManager.h"
#import "Divinity.h"

NSString* const PlayerGold = @"com.healer.playerId";
NSString* const DivinityTiersUnlocked = @"com.healer.divTiers";
NSString* const PlayerGoldDidChangeNotification = @"com.healer.goldDidChangeNotif";

static NSArray *shopItems = nil;

@implementation Shop

+(BOOL)playerCanAffordShopItem:(ShopItem*)item{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return [Shop localPlayerGold] >= [item goldCost];
}
+(BOOL)playerHasShopItem:(ShopItem*)item{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[item key]];
}
+(BOOL)playerHasSpell:(Spell*)spell{
    if ([spell.title isEqualToString:@"Heal"]){
        return YES;
    }
    return [Shop playerHasShopItem:[[[ShopItem alloc] initWithSpell:spell] autorelease]];
}
+(NSInteger)localPlayerGold{
    return [[NSUserDefaults standardUserDefaults] integerForKey:PlayerGold];
}

+(void)purchaseItem:(ShopItem*)item{
    if ([Shop playerCanAffordShopItem:item] && ![Shop playerHasShopItem:item]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[item key]];
        [Shop playerLosesGold:item.goldCost];
    }
}

+(void)playerEarnsGold:(NSInteger)gold{
    if (gold < 0)
        return;
    NSInteger currentGold = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerGold] intValue];
    currentGold+= gold;
    if (currentGold > 5000){
        currentGold = 5000; //MAX GOLD
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold];
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayerGoldDidChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold]];
}

+(void)playerLosesGold:(NSInteger)gold{
    if (gold < 0)
        return;
    NSInteger currentGold = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerGold] intValue];
    currentGold-= gold;
    if (currentGold < 0){
        currentGold = 0; //MAX GOLD
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold];
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayerGoldDidChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold]];
}

+(NSArray*)purchasedItems{
    NSMutableArray *purchasedItems = [NSMutableArray arrayWithCapacity:20];
    for (ShopItem *item in [Shop allShopItems]){
        if ([Shop playerHasShopItem:item]){
            [purchasedItems addObject: item];
        }
    }
    return purchasedItems;
}

+(NSArray*)allOwnedSpells{
    NSMutableArray *allSpells = [NSMutableArray arrayWithCapacity:20];
    NSArray *allShopItems = [Shop allShopItems];
    NSArray *purchasedItems = [Shop purchasedItems];
    [allSpells addObject:[Heal defaultSpell]];
    for (ShopItem *item in allShopItems){
        if ([purchasedItems containsObject:item]){
            [allSpells addObject:[[[item purchasedSpell] class] defaultSpell]];
        }
    }
    return allSpells;
}


+(NSArray*)allShopItems{
    
    
    if (!shopItems){
        NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
        
        [items addObjectsFromArray:[Shop essentialsShopItems]];
        [items addObjectsFromArray:[Shop topShelfShopItems]];
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
        case ShopCategoryTopShelf:
            return 3;
        case ShopCategoryArchives:
            return 5;
        case ShopCategoryVault:
            return 7;
    }
    return 0;
}

+ (ShopCategory)highestCategoryUnlocked {
    NSInteger totalPurchases = [Shop allOwnedSpells].count;
    ShopCategory category = ShopCategoryEssentials;
    if (totalPurchases >= [Shop purchasesForCategory:ShopCategoryTopShelf]){
        category = ShopCategoryTopShelf;
    }
    if (totalPurchases >= [Shop purchasesForCategory:ShopCategoryArchives]){
        category = ShopCategoryArchives;
    }
    if (totalPurchases > [Shop purchasesForCategory:ShopCategoryVault]){
        category = ShopCategoryVault;
    }
    return category;
}

+ (NSInteger)numPurchasesUntilNextCategory {
    NSInteger totalPurchases = [Shop allOwnedSpells].count;
    ShopCategory highestCategory = [Shop highestCategoryUnlocked];
    if (highestCategory == ShopCategoryVault){
        return 0;
    }
    return [Shop purchasesForCategory:highestCategory] - totalPurchases;
}

+ (NSArray*)essentialsShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];

    ShopItem *greaterHeal = [[ShopItem alloc] initWithSpell:[GreaterHeal defaultSpell]];
    [items addObject:[greaterHeal autorelease]];

    ShopItem *regrow = [[ShopItem alloc] initWithSpell:[Regrow defaultSpell]];
    [items addObject:[regrow autorelease]];

    ShopItem *forkedHeal = [[ShopItem alloc] initWithSpell:[ForkedHeal defaultSpell]];
    [items addObject:[forkedHeal autorelease]];


    return items;
}

+ (NSArray*)topShelfShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
    ShopItem *purify = [[ShopItem alloc] initWithSpell:[Purify defaultSpell]];
    [items addObject:[purify autorelease]];
    
    ShopItem *starsOfA = [[ShopItem alloc] initWithSpell:[StarsOfAravon defaultSpell]];
    [items addObject:[starsOfA autorelease]];
    
    ShopItem *healingBurst = [[ShopItem alloc] initWithSpell:[HealingBurst defaultSpell]];
    [items addObject:[healingBurst autorelease]];
    
    ShopItem *blessedArmor = [[ShopItem alloc] initWithSpell:[BlessedArmor defaultSpell]];
    [items addObject:[blessedArmor autorelease]];
    
    ShopItem *touchOfLight = [[ShopItem alloc] initWithSpell:[TouchOfHope defaultSpell]];
    [items addObject:[touchOfLight autorelease]];

    return items;
    
}
+ (NSArray*)archivesShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
    ShopItem *lightEternal = [[ShopItem alloc] initWithSpell:[LightEternal defaultSpell]];
    [items addObject:[lightEternal autorelease]];
    
    ShopItem *sunburst = [[ShopItem alloc] initWithSpell:[Sunburst defaultSpell]];
    [items addObject:[sunburst autorelease]];
    
    ShopItem *fadingLight = [[ShopItem alloc] initWithSpell:[FadingLight defaultSpell]];
    [items addObject:[fadingLight autorelease]];
    
    ShopItem *orbsOfLight = [[ShopItem alloc] initWithSpell:[OrbsOfLight defaultSpell]];
    [items addObject:[orbsOfLight autorelease]];
    
    ShopItem *swirlingLight = [[ShopItem alloc] initWithSpell:[SwirlingLight defaultSpell]];
    [items addObject:[swirlingLight autorelease]];
    
    ShopItem *barrier = [[ShopItem alloc] initWithSpell:[Barrier defaultSpell]];
    [items addObject:[barrier autorelease]];

    return items;
    
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
    return items;
    
}

+ (void)resetDivinity {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:DivinityTiersUnlocked];
    [Divinity resetConfig];
}

+ (NSInteger)costForDivinityTier:(NSInteger)tier {
    NSInteger val = -1;
    switch (tier) {
        case 0:
            val = 200;
            break;
        case 1:
            val = 1000;
            break;
        case 2:
            val = 1500;
            break;
        case 3:
            val = 2500;
            break;
        case 4:
            val = 4000;
            break;
    }
    return val;
}

+ (NSInteger)costForNextDivinityTier {
    return [Shop costForDivinityTier:[Shop numDivinityTiersPurchased]];
}

+ (NSInteger)numDivinityTiersPurchased {
    return [[NSUserDefaults standardUserDefaults] integerForKey:DivinityTiersUnlocked];
}

+ (void)purchaseNextDivinityTier {
    if ([Shop localPlayerGold] >= [Shop costForNextDivinityTier]){
        [Shop playerLosesGold:[Shop costForNextDivinityTier]];
    }else {
        return;
    }

    NSInteger currentTiers = [Shop numDivinityTiersPurchased];
    if (currentTiers == 5){
        return; //You have em all =D
    }
    currentTiers++;
    [[NSUserDefaults standardUserDefaults] setInteger:currentTiers forKey:DivinityTiersUnlocked];
    
}
@end

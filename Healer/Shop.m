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

NSString* const PlayerGold = @"com.healer.no-touch98741562234.gold";
NSString* const DivinityTiersUnlocked = @"com.healer.divTiers";

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
    if (currentGold > 2000){
        currentGold = 2000; //MAX GOLD
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:currentGold] forKey:PlayerGold];
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
    for (ShopItem *item in [Shop purchasedItems]){
        [allSpells addObject:[[[item purchasedSpell] class] defaultSpell]];
    }
    [allSpells addObject:[Heal defaultSpell]];
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

+ (ShopCategory)highestCategoryUnlocked {
    NSInteger highestLevelCompleted = [PlayerDataManager highestLevelCompleted];
    ShopCategory category = ShopCategoryEssentials;
    if (highestLevelCompleted > 3){
        category = ShopCategoryTopShelf;
    }
    if (highestLevelCompleted > 6){
        category = ShopCategoryArchives;
    }
    if (highestLevelCompleted > 9){
        category = ShopCategoryVault;
    }
    return category;
}

+ (NSArray*)essentialsShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];

    ShopItem *greaterHeal = [[ShopItem alloc] initWithSpell:[GreaterHeal defaultSpell]];
    ShopItem *regrow = [[ShopItem alloc] initWithSpell:[Regrow defaultSpell]];
    ShopItem *healingBurst = [[ShopItem alloc] initWithSpell:[HealingBurst defaultSpell]];

    [items addObject:[greaterHeal autorelease]];
    [items addObject:[regrow autorelease]];
    [items addObject:[healingBurst autorelease]];


    return items;
}

+ (NSArray*)topShelfShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
    ShopItem *purify = [[ShopItem alloc] initWithSpell:[Purify defaultSpell]];
    [items addObject:[purify autorelease]];
    ShopItem *forkedHeal = [[ShopItem alloc] initWithSpell:[ForkedHeal defaultSpell]];
    [items addObject:[forkedHeal autorelease]];
    ShopItem *barrier = [[ShopItem alloc] initWithSpell:[Barrier defaultSpell]];
    [items addObject:[barrier autorelease]];
    ShopItem *lightEternal = [[ShopItem alloc] initWithSpell:[LightEternal defaultSpell]];
    [items addObject:[lightEternal autorelease]];
    ShopItem *fadingLight = [[ShopItem alloc] initWithSpell:[FadingLight defaultSpell]];
    [items addObject:[fadingLight autorelease]];
    ShopItem *sunburst = [[ShopItem alloc] initWithSpell:[Sunburst defaultSpell]];
    [items addObject:[sunburst autorelease]];

    return items;
    
}
+ (NSArray*)archivesShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
    ShopItem *touchOfLight = [[ShopItem alloc] initWithSpell:[TouchOfHope defaultSpell]];
    ShopItem *orbsOfLight = [[ShopItem alloc] initWithSpell:[OrbsOfLight defaultSpell]];
    ShopItem *swirlingLight = [[ShopItem alloc] initWithSpell:[SwirlingLight defaultSpell]];
    ShopItem *soaringSpirit = [[ShopItem alloc] initWithSpell:[SoaringSpirit defaultSpell]];
    [items addObject:[soaringSpirit autorelease]];
    [items addObject:[orbsOfLight autorelease]];
    [items addObject:[swirlingLight autorelease]];
    [items addObject:[touchOfLight autorelease]];
    return items;
    
}
+ (NSArray*)vaultShopItems {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
    ShopItem *respite = [[ShopItem alloc] initWithSpell:[Respite defaultSpell]];
    ShopItem *wanderingSpirit = [[ShopItem alloc] initWithSpell:[WanderingSpirit defaultSpell]];
    ShopItem *wardOfAncients = [[ShopItem alloc] initWithSpell:[WardOfAncients defaultSpell]];
    
    
    [items addObject:[respite autorelease]];
    [items addObject:[wanderingSpirit autorelease]];
    [items addObject:[wardOfAncients autorelease]];
    return items;
    
}

+ (NSInteger)costForNextDivinityTier {
    NSInteger numPurchased = [Shop numDivinityTiersPurchased];
    NSInteger val = -1;
    switch (numPurchased) {
        case 0:
            val = 200;
            break;
        case 1:
            val = 1000;
            break;
        case 2:
            val = 5000;
            break;
        case 3:
            val = 10000;
            break;
        case 4:
            val = 20000;
            break;
        default:
            break;
    }
    return val;
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

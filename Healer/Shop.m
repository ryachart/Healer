//
//  Shop.m
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "Shop.h"
#import "Spell.h"
#import "ShopItem.h"
NSString* const PlayerGold = @"com.healer.no-touch98741562234.gold";

static NSArray *shopItems = nil;

@implementation Shop

+(BOOL)playerCanAffordShopItem:(ShopItem*)item{
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
        [allSpells addObject:[item purchasedSpell]];
    }
    [allSpells addObject:[Heal defaultSpell]];
    return allSpells;
}


+(NSArray*)allShopItems{
    if (!shopItems){
        NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
        
        ShopItem *greaterHeal = [[ShopItem alloc] initWithSpell:[GreaterHeal defaultSpell]];
        ShopItem *forkedHeal = [[ShopItem alloc] initWithSpell:[ForkedHeal defaultSpell]];
        ShopItem *purify = [[ShopItem alloc] initWithSpell:[Purify defaultSpell]];
        ShopItem *regrow = [[ShopItem alloc] initWithSpell:[Regrow defaultSpell]];
        ShopItem *healingBurst = [[ShopItem alloc] initWithSpell:[HealingBurst defaultSpell]];
        ShopItem *barrier = [[ShopItem alloc] initWithSpell:[Barrier defaultSpell]];
        ShopItem *orbsOfLight = [[ShopItem alloc] initWithSpell:[OrbsOfLight defaultSpell]];
        ShopItem *swirlingLight = [[ShopItem alloc] initWithSpell:[SwirlingLight defaultSpell]];
        ShopItem *lightEternal = [[ShopItem alloc] initWithSpell:[LightEternal defaultSpell]];
        
        [items addObject:[greaterHeal autorelease]];
        [items addObject:[purify autorelease]];
        [items addObject:[forkedHeal autorelease]];
        [items addObject:[regrow autorelease]];
        [items addObject:[lightEternal autorelease]];
        [items addObject:[healingBurst autorelease]];
        [items addObject:[barrier autorelease]];
        [items addObject:[orbsOfLight autorelease]];
        [items addObject:[swirlingLight autorelease]];
        shopItems = [items retain];
    }
    return shopItems;
}
@end

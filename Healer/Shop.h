//
//  Shop.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ShopItem.h"

extern NSString* const PlayerGold;

@interface Shop : NSObject
+(BOOL)playerCanAffordShopItem:(ShopItem*)item;
+(BOOL)playerHasSpell:(Spell*)spell;
+(BOOL)playerHasShopItem:(ShopItem*)item;
+(void)purchaseItem:(ShopItem*)item;
+(NSInteger)localPlayerGold;
+(void)playerEarnsGold:(NSInteger)gold;
+(void)playerLosesGold:(NSInteger)gold;
+(NSArray*)allShopItems;
+(NSArray*)purchasedItems;
+(NSArray*)allOwnedSpells;
@end

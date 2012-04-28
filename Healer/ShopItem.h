//
//  ShopItem.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//
#import "Spell.h"

@interface ShopItem : NSObject
@property (nonatomic, readonly) NSInteger goldCost;
@property (nonatomic, readonly) NSString* key;
@property (nonatomic, retain) NSString *shopDescription;
@property (nonatomic, readonly) NSString* shopSprite;
@property (nonatomic, readonly) NSString* title;
-(Spell*)purchasedSpell;

+(ShopItem*)shopItemWithSpell:(Spell*)spell;
-(id)initWithSpell:(Spell*)spell;
@end

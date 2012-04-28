//
//  ShopItemNode.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class ShopItem;

@interface ShopItemNode : CCMenu
@property (nonatomic, retain) ShopItem *item;
-(id)initWithShopItem:(ShopItem*)item target:(id)target selector:(SEL)selector;
-(void)checkPlayerHasItem;
@end

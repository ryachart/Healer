//
//  ShopItemExtendedNode.h
//  Healer
//
//  Created by Ryan Hart on 5/22/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
@class ShopItem;
@class ShopItemExtendedNode;

@protocol ShopItemExtendedNodeDelegate <NSObject>

-(void)extendedNodeDidCompleteForShopItem:(ShopItem*)item andNode:(ShopItemExtendedNode*)node;

@end

@interface ShopItemExtendedNode : CCSprite
@property (nonatomic, assign) id<ShopItemExtendedNodeDelegate> delegate;
-(id)initWithShopItem:(ShopItem*)item;
@end

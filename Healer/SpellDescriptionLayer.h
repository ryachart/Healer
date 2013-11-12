//
//  SpellDescriptionLayer.h
//  Healer
//
//  Created by Ryan Hart on 11/7/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class SpellDescriptionLayer, ShopItem;
@protocol SpellDescriptionLayerDelegate <NSObject>
- (void)spellDescriptionLayerDidComplete:(SpellDescriptionLayer *)layer;
@end

@interface SpellDescriptionLayer : CCLayer
@property (nonatomic, assign) id<SpellDescriptionLayerDelegate> delegate;
- (id)initWithShopItem:(ShopItem*)item;
@end

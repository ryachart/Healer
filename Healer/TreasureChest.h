//
//  TreasureChest.h
//  Healer
//
//  Created by Ryan Hart on 6/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class EquipmentItem;

@interface TreasureChest : CCSprite
- (void)open;
- (void)openWithItem:(EquipmentItem*)item;
@end

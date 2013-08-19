//
//  DraggableItemIcon.h
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class EquipmentItem;
@interface DraggableItemIcon : CCSprite
@property (nonatomic, retain) EquipmentItem *item;
- (id)initWithEquipmentItem:(EquipmentItem*)item;
@end

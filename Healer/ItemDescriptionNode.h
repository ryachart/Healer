//
//  ItemDescriptionNode.h
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "cocos2d.h"
#import "EquipmentItem.h"


@interface ItemDescriptionNode : CCNode
@property (nonatomic, retain) EquipmentItem *item;

+ (ccColor3B)colorForRarity:(ItemRarity)rarity;
- (void)configureForRandomWithRarity:(ItemRarity)rarity;
@end

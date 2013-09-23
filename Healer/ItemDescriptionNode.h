//
//  ItemDescriptionNode.h
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import "EquipmentItem.h"


@interface ItemDescriptionNode : CCSprite
@property (nonatomic, retain) EquipmentItem *item;

+ (ccColor3B)colorForRarity:(ItemRarity)rarity;
- (void)configureForRandomWithRarity:(ItemRarity)rarity;
@end

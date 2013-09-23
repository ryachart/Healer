//
//  DraggableItemIcon.m
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "DraggableItemIcon.h"
#import "EquipmentItem.h"

@implementation DraggableItemIcon

- (id)initWithEquipmentItem:(EquipmentItem *)item {
    if (self = [super init]){
        self.item = item;
        CCSpriteFrame *spellFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:self.item.itemSpriteName];
        if (!spellFrame){
            spellFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"unknown-icon.png"];
        }
        [self setDisplayFrame:spellFrame];
    }
    return self;
}

@end

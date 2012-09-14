//
//  DraggableSpellIcon.h
//  Healer
//
//  Created by Ryan Hart on 9/13/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class Spell;
@class Slot;

@interface DraggableSpellIcon : CCSprite
@property (nonatomic, retain) Slot *defaultSlot;
@property (nonatomic, retain) Slot *currentSlot;
- (id)initWithSpell:(Spell*)spell;
@end

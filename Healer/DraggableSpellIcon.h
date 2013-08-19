//
//  DraggableSpellIcon.h
//  Healer
//
//  Created by Ryan Hart on 9/13/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class Spell;
@class Slot;

@interface DraggableSpellIcon : CCSprite
@property (nonatomic, retain) Spell *spell;

- (id)initWithSpell:(Spell*)spell;

@end

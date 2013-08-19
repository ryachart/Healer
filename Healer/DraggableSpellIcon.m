//
//  DraggableSpellIcon.m
//  Healer
//
//  Created by Ryan Hart on 9/13/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "DraggableSpellIcon.h"
#import "Spell.h"
@implementation DraggableSpellIcon


- (id)initWithSpell:(Spell*)spell {
    if (self = [super init]){
        self.spell = spell;
        CCSpriteFrame *spellFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:self.spell.spriteFrameName];
        if (!spellFrame){
            spellFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"unknown-icon.png"];
        }
        [self setDisplayFrame:spellFrame];
    }
    return self;
}
@end

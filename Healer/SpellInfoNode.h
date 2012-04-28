//
//  SpellInfoNode.h
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class Spell;

@interface SpellInfoNode : CCNode
-(id)initWithSpell:(Spell*)spell;
@end

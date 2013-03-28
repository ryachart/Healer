//
//  SpellInfoNode.h
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//

#import "cocos2d.h"

@class Spell;

@interface SpellInfoNode : CCSprite
- (id)initWithSpell:(Spell*)spell;
- (id)initAsEmpty;
@end

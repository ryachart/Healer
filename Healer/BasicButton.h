//
//  BasicButton.h
//  Healer
//
//  Created by Ryan Hart on 7/1/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@interface BasicButton : CCMenuItemSprite

+ (CCMenuItemSprite*)basicButtonWithTarget:(id)target andSelector:(SEL)selector andTitle:(NSString*)title;
+ (CCMenu *)spriteButtonWithSpriteFrameName:(NSString*)frameName target:(id)target andSelector:(SEL)selector;
@end

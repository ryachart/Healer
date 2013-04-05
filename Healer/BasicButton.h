//
//  BasicButton.h
//  Healer
//
//  Created by Ryan Hart on 7/1/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@interface BasicButton : CCMenuItemSprite

+ (BasicButton*)basicButtonWithTarget:(id)target andSelector:(SEL)selector andTitle:(NSString*)title;
+ (BasicButton*)basicButtonWithTarget:(id)target andSelector:(SEL)selector andTitle:(NSString*)title andAlertPip:(BOOL)showsAlertPip;
+ (CCMenu *)spriteButtonWithSpriteFrameName:(NSString*)frameName target:(id)target andSelector:(SEL)selector;
+ (CCMenu *)defaultBackButtonWithTarget:(id)target andSelector:(SEL)selector;

- (void)setTitle:(NSString*)title;
@end

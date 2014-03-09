//
//  BasicButton.h
//  Healer
//
//  Created by Ryan Hart on 7/1/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@interface BasicButton : CCMenuItemSprite

+ (BasicButton*)basicButtonWithTarget:(id)target andSelector:(SEL)selector andTitle:(NSString*)title;
+ (BasicButton*)basicButtonWithTarget:(id)target andSelector:(SEL)selector andTitle:(NSString*)title andAlertPip:(BOOL)showsAlertPip;
+ (BasicButton*)basicButtonWithTarget:(id)target andSelector:(SEL)selector andTitle:(NSString*)title andAlertPip:(BOOL)showsAlertPip showsLockForDisabled:(BOOL)showsLock;
+ (CCMenu *)spriteButtonWithSpriteFrameName:(NSString*)frameName target:(id)target andSelector:(SEL)selector;
+ (CCMenu *)defaultBackButtonWithTarget:(id)target andSelector:(SEL)selector;
+ (CCMenu *)basicButtonMenuWithTarget:(id)target selector:(SEL)selector title:(NSString *)title scale:(float)scale;

- (void)setTitle:(NSString*)title;
@end

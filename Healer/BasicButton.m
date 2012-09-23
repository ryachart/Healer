//
//  BasicButton.m
//  Healer
//
//  Created by Ryan Hart on 7/1/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "BasicButton.h"

@implementation BasicButton

+ (BasicButton*)basicButtonWithTarget:(id)target andSelector:(SEL)selector andTitle:(NSString*)title {
    CCSprite *basicButton = [CCSprite spriteWithSpriteFrameName:@"button_home.png"];
    CCSprite *basicButtonSelected = [CCSprite spriteWithSpriteFrameName:@"button_home.png"];
    CCSprite *selectedMask = [CCSprite spriteWithSpriteFrameName:@"button_home_pressed.png"];
    [selectedMask setAnchorPoint:CGPointZero];
    CCSprite *basicButtonDisabled = [CCSprite spriteWithSpriteFrameName:@"button_home.png"];
    [basicButtonDisabled setOpacity:50];
    [basicButtonSelected setOpacity:200];
    
    title = [title uppercaseString];
    
    CGPoint labelPosition = CGPointMake(basicButton.contentSize.width /2 , 4 + basicButton.contentSize.height / 4);
    NSString *fontName = @"Futura";
    CGFloat fontSize = 30.0;
    CCLabelTTF *titleLabel = [CCLabelTTF labelWithString:title dimensions:basicButton.contentSize hAlignment:UITextAlignmentCenter fontName:fontName fontSize:fontSize];
    [titleLabel setColor:ccc3(240, 181, 123)];
    [titleLabel setPosition:labelPosition];
    CCLabelTTF *titleLabelSelected = [CCLabelTTF labelWithString:title dimensions:basicButton.contentSize hAlignment:UITextAlignmentCenter fontName:fontName fontSize:fontSize];
    [titleLabelSelected setColor:ccc3(240, 181, 123)];
    [titleLabelSelected setPosition:labelPosition];
    CCLabelTTF *titleLabelDisabled = [CCLabelTTF labelWithString:title dimensions:basicButton.contentSize hAlignment:UITextAlignmentCenter fontName:fontName fontSize:fontSize];
    [titleLabelDisabled setColor:ccc3(240, 181, 123)];
    [titleLabelDisabled setPosition:labelPosition];
    
    [basicButton addChild:titleLabel];
    [basicButtonSelected addChild:titleLabelSelected];
    [basicButtonSelected addChild:selectedMask z:5];
    [basicButtonDisabled addChild:titleLabelDisabled];
    
    return [BasicButton itemWithNormalSprite:basicButton selectedSprite:basicButtonSelected disabledSprite:basicButtonDisabled target:target selector:selector];
    
}

+ (CCMenu *)spriteButtonWithSpriteFrameName:(NSString*)frameName target:(id)target andSelector:(SEL)selector {
    CCSprite *basicButton = [CCSprite spriteWithSpriteFrameName:frameName];
    CCSprite *basicButtonSelected = [CCSprite spriteWithSpriteFrameName:frameName];
    CCSprite *basicButtonDisabled = [CCSprite spriteWithSpriteFrameName:frameName];
    [basicButtonDisabled setColor:ccBLACK];
    [basicButtonSelected setOpacity:200];
    
    CCMenuItemSprite *menuItem = [CCMenuItemSprite itemWithNormalSprite:basicButton selectedSprite:basicButtonSelected disabledSprite:basicButtonDisabled target:target selector:selector];
    
    return [CCMenu menuWithItems:menuItem, nil];
}

+ (CCMenu *)defaultBackButtonWithTarget:(id)target andSelector:(SEL)selector {
    return [BasicButton spriteButtonWithSpriteFrameName:@"button_back.png" target:target andSelector:selector];
}

- (void)setTitle:(NSString *)title {
    for (CCNode *node in self.disabledImage.children) {
        if ([node isKindOfClass:[CCLabelTTF class]]){
            [(CCLabelTTF*)node setString:title];
        }
    }
    
    for (CCNode *node in self.normalImage.children) {
        if ([node isKindOfClass:[CCLabelTTF class]]){
            [(CCLabelTTF*)node setString:title];
        }
    }
    
    for (CCNode *node in self.selectedImage.children) {
        if ([node isKindOfClass:[CCLabelTTF class]]){
            [(CCLabelTTF*)node setString:title];
        }
    }
}

@end

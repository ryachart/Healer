//
//  BasicButton.m
//  Healer
//
//  Created by Ryan Hart on 7/1/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "BasicButton.h"

@implementation BasicButton

+ (CCMenuItemSprite*)basicButtonWithTarget:(id)target andSelector:(SEL)selector andTitle:(NSString*)title {
    CCSprite *basicButton = [CCSprite spriteWithSpriteFrameName:@"rect_button.png"];
    CCSprite *basicButtonSelected = [CCSprite spriteWithSpriteFrameName:@"rect_button.png"];
    CCSprite *basicButtonDisabled = [CCSprite spriteWithSpriteFrameName:@"rect_button.png"];
    [basicButtonDisabled setOpacity:150];
    [basicButtonSelected setOpacity:200];
    
    CGPoint labelPosition = CGPointMake(basicButton.contentSize.width /2 , basicButton.contentSize.height / 4);
    
    CCLabelTTF *titleLabel = [CCLabelTTF labelWithString:title dimensions:basicButton.contentSize alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
    [titleLabel setPosition:labelPosition];
    CCLabelTTF *titleLabelSelected = [CCLabelTTF labelWithString:title dimensions:basicButton.contentSize alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
    [titleLabelSelected setPosition:labelPosition];
    CCLabelTTF *titleLabelDisabled = [CCLabelTTF labelWithString:title dimensions:basicButton.contentSize alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
    [titleLabelDisabled setPosition:labelPosition];
    
    [basicButton addChild:titleLabel];
    [basicButtonSelected addChild:titleLabelSelected];
    [basicButtonDisabled addChild:titleLabelDisabled];
    
    return [CCMenuItemSprite itemFromNormalSprite:basicButton selectedSprite:basicButtonSelected disabledSprite:basicButtonDisabled target:target selector:selector];
    
}

+ (CCMenu *)spriteButtonWithSpriteFrameName:(NSString*)frameName target:(id)target andSelector:(SEL)selector {
    CCSprite *basicButton = [CCSprite spriteWithSpriteFrameName:frameName];
    CCSprite *basicButtonSelected = [CCSprite spriteWithSpriteFrameName:frameName];
    CCSprite *basicButtonDisabled = [CCSprite spriteWithSpriteFrameName:frameName];
    [basicButtonDisabled setColor:ccBLACK];
    [basicButtonSelected setOpacity:200];
    
    CCMenuItemSprite *menuItem = [CCMenuItemSprite itemFromNormalSprite:basicButton selectedSprite:basicButtonSelected disabledSprite:basicButtonDisabled target:target selector:selector];
    
    return [CCMenu menuWithItems:menuItem, nil];
}

@end

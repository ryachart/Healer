//
//  AbilityDescriptionModalLayer.m
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "AbilityDescriptionModalLayer.h"
#import "AbilityDescriptor.h"

@implementation AbilityDescriptionModalLayer

- (id)initWithAbilityDescriptor:(AbilityDescriptor *)descriptor {
    if (self = [super initWithColor:ccc4(0, 0, 0, 150)]){
        CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:descriptor.abilityName dimensions:CGSizeMake(500, 100) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:48.0];
        [nameLabel setPosition:CGPointMake(512, 584)];
        [self addChild:nameLabel];
        
        CCLabelTTF *descLabel = [CCLabelTTF labelWithString:descriptor.abilityDescription dimensions:CGSizeMake(400, 300) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24.0];
        [descLabel setPosition:CGPointMake(512, 384)];
        [self addChild:descLabel];
        
        CCSprite *descImage = [CCSprite spriteWithSpriteFrameName:descriptor.iconName];
        [descImage setPosition:CGPointMake(250, 484)];
        [self addChild:descImage];
        
        CCLabelTTF *dismissLabel = [CCLabelTTF labelWithString:@"Dismiss" dimensions:CGSizeMake(300, 300) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:36.0];
        CCMenuItemLabel *dismissItem = [CCMenuItemLabel itemWithLabel:dismissLabel target:self selector:@selector(shouldDismiss)];
        
        CCMenu *dismissMenu = [CCMenu menuWithItems:dismissItem, nil];
        [dismissMenu setPosition:CGPointMake(512, 50)];
        [self addChild:dismissMenu];
        
        self.scale = 0.0;
        
    }
    return self;
}

- (void)onEnter {
    [super onEnter];
    
    [self runAction:[CCScaleTo actionWithDuration:.5 scale:1.0]];
}

- (void)shouldDismiss {
    [self.delegate abilityDescriptorModaldidComplete:self];
}
@end

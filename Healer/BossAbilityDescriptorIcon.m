//
//  BossAbilityDescriptorIcon.m
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "BossAbilityDescriptorIcon.h"
#import "AbilityDescriptor.h"

@interface BossAbilityDescriptorIcon ()
@property (nonatomic, assign) CCMenuItemSprite *iconSpriteMenuItem;
@property (nonatomic, assign) CCMenu *menu;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL selector;
@end

@implementation BossAbilityDescriptorIcon

- (void)dealloc {
    [_ability release];
    [super dealloc];
}

- (id)initWithAbility:(AbilityDescriptor*)newAbility target:(id)newTarget selector:(SEL)newSelector; {
    if (self = [super init]){
        self.ability = newAbility;
        self.target = newTarget;
        self.selector = newSelector;
        [self configureNode];
    }
    return self;
}

- (void)configureNode {
    [self.menu removeFromParentAndCleanup:YES];
    CCSprite *normalSprite = [CCSprite spriteWithSpriteFrameName:self.ability.iconName];
    CCSprite *selectedSprite = [CCSprite spriteWithSpriteFrameName:self.ability.iconName];
    [selectedSprite setColor:ccc3(122, 122, 122)];
    
    self.iconSpriteMenuItem = [CCMenuItemSprite itemWithNormalSprite:normalSprite selectedSprite:selectedSprite target:self.target selector:self.selector];
    [self.iconSpriteMenuItem setUserData:self.ability];
    
    self.menu = [CCMenu menuWithItems:self.iconSpriteMenuItem, nil];
    [self addChild:self.menu];
}

- (void)setAbility:(AbilityDescriptor *)newAbility {
    if (_ability == newAbility) return;
    [_ability release];
    _ability = [newAbility retain];
    [self configureNode];
}

@end

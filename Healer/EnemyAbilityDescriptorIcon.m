//
//  BossAbilityDescriptorIcon.m
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "EnemyAbilityDescriptorIcon.h"
#import "AbilityDescriptor.h"
#import "CCLabelTTFShadow.h"

@interface EnemyAbilityDescriptorIcon ()
@property (nonatomic, assign) CCMenuItemSprite *iconSpriteMenuItem;
@property (nonatomic, assign) CCMenu *menu;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) CCLabelTTFShadow *stacksLabel;
@end

@implementation EnemyAbilityDescriptorIcon

- (void)dealloc {
    [_ability release];
    [super dealloc];
}

- (id)initWithAbility:(AbilityDescriptor*)newAbility target:(id)newTarget selector:(SEL)newSelector; {
    if (self = [super init]){
        self.ability = newAbility;
        self.target = newTarget;
        self.selector = newSelector;
        self.scale = .5;
        CCSprite *backing = [CCSprite spriteWithSpriteFrameName:@"spell_icon_back.png"];
        [self addChild:backing];
        
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
    self.menu.position = CGPointMake(0, 0);
    [self addChild:self.menu];
    
    if (!self.stacksLabel) {
        self.stacksLabel = [CCLabelTTFShadow labelWithString:@"0" fontName:@"TrebuchetMS-Bold" fontSize:36.0];
        [self.stacksLabel setPosition:CGPointMake(0, normalSprite.contentSize.height / -4)];
        [self addChild:self.stacksLabel z:5];
    }
    [self updateStacks];

}

- (void)updateStacks
{
    NSInteger stacks = self.ability.stacks;
    NSString *stacksString = stacks > 0 ? [NSString stringWithFormat:@"%d", stacks] : nil;
    [self.stacksLabel setString:stacksString];
}

- (void)setAbility:(AbilityDescriptor *)newAbility {
    if ([_ability.abilityName isEqualToString:newAbility.abilityName]) return;
    [_ability release];
    _ability = [newAbility retain];
    [self configureNode];
}

#pragma mark - CCRBGAProtocol
- (void)setColor:(ccColor3B)color
{
    //Nothing
}

- (ccColor3B)color
{
    return ccBLACK;
}

- (void)setOpacity:(GLubyte)opacity
{
    for (CCNode *child in self.children){
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            id<CCRGBAProtocol> colorChild = (CCSprite*)child;
            [colorChild setOpacity:opacity];
        }
    }
}

- (GLubyte)opacity
{
    float highestOpacity = 0;
    for (CCNode *child in self.children){
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            id<CCRGBAProtocol> colorChild = (CCSprite*)child;
            highestOpacity = [colorChild opacity] > highestOpacity ? [colorChild opacity] : highestOpacity;
        }
    }
    return highestOpacity;
}

@end

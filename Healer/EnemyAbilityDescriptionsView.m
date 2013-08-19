//
//  BossAbilityDescriptionsView.m
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "EnemyAbilityDescriptionsView.h"
#import "Enemy.h"
#import "EnemyAbilityDescriptorIcon.h"
#import "SimpleAudioEngine.h"

@interface EnemyAbilityDescriptionsView ()
@property (nonatomic, readwrite) NSInteger lastCount;
@property (nonatomic, retain) NSMutableArray *descriptorIcons;
@end

@implementation EnemyAbilityDescriptionsView

- (void)dealloc{
    [_descriptorIcons release];
    [super dealloc];
}

- (id)initWithBoss:(Enemy*)newBoss {
    if (self = [super init]){
        self.boss = newBoss;
        self.descriptorIcons = [NSMutableArray arrayWithCapacity:MAX_SHOWN];
        [self configureIcons];
    }
    return self;
}

- (void)configureIcons {
    NSMutableArray *expiredAbilityIcons = [NSMutableArray arrayWithCapacity:5];
    for (int i = 0; i < MAX_SHOWN; i++){
        if (i < self.boss.abilityDescriptors.count){
            if (i < self.descriptorIcons.count){
                //If we have one, just replace it
                [[self.descriptorIcons objectAtIndex:i] setAbility:[self.boss.abilityDescriptors objectAtIndex:i]];
            } else {
                EnemyAbilityDescriptorIcon *newIcon = [[EnemyAbilityDescriptorIcon alloc] initWithAbility:[self.boss.abilityDescriptors objectAtIndex:i] target:self selector:@selector(bossAbilitySelected:)];
                [self.descriptorIcons addObject:newIcon];
                [self addChild:newIcon];
                [newIcon release];
            }
            EnemyAbilityDescriptorIcon *currentIcon = [self.descriptorIcons objectAtIndex:i];
            [currentIcon setAnchorPoint:CGPointZero];
            [currentIcon setPosition:CGPointMake(50 * i, 0)];
            [currentIcon updateStacks];

        }
        
        if (self.descriptorIcons.count > i && self.boss.abilityDescriptors.count < self.descriptorIcons.count){
            [expiredAbilityIcons addObject:[self.descriptorIcons objectAtIndex:i]];
        }
    }
    
    for (EnemyAbilityDescriptorIcon *icon in expiredAbilityIcons){
        //Get rid of the ability icons we no longer need
        [icon removeFromParentAndCleanup:YES];
        [self.descriptorIcons removeObject:icon];
    }
}

- (void)bossAbilitySelected:(id)sender {
    PLAY_BUTTON_CLICK;
    CCMenuItemSprite *menuItem = (CCMenuItemSprite*)sender;
    AbilityDescriptor *abilityDesc = (AbilityDescriptor*)[menuItem userData];
    [self.delegate abilityDescriptionViewDidSelectAbility:abilityDesc];
}

- (void)update {
    [self configureIcons];
}

- (void)fadeIn
{
    self.opacity = 0;
    [self runAction:[CCFadeTo actionWithDuration:.5 opacity:255]];
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

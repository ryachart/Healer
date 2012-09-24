//
//  BossAbilityDescriptionsView.m
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "BossAbilityDescriptionsView.h"
#import "Boss.h"
#import "BossAbilityDescriptorIcon.h"


@interface BossAbilityDescriptionsView ()
@property (nonatomic, readwrite) NSInteger lastCount;
@property (nonatomic, retain) NSMutableArray *descriptorIcons;
@end

@implementation BossAbilityDescriptionsView

- (void)dealloc{
    [_descriptorIcons release];
    [super dealloc];
}

- (id)initWithBoss:(Boss*)newBoss {
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
                BossAbilityDescriptorIcon *newIcon = [[BossAbilityDescriptorIcon alloc] initWithAbility:[self.boss.abilityDescriptors objectAtIndex:i] target:self selector:@selector(bossAbilitySelected:)];
                [self.descriptorIcons addObject:newIcon];
                [self addChild:newIcon];
                [newIcon release];
            }
            [[self.descriptorIcons objectAtIndex:i] setAnchorPoint:CGPointZero];
            [[self.descriptorIcons objectAtIndex:i] setPosition:CGPointMake(80 * i, 0)];

        }
        
        if (self.descriptorIcons.count > i && self.boss.abilityDescriptors.count < self.descriptorIcons.count){
            [expiredAbilityIcons addObject:[self.descriptorIcons objectAtIndex:i]];
        }
    }
    
    for (BossAbilityDescriptorIcon *icon in expiredAbilityIcons){
        //Get rid of the ability icons we no longer need
        [icon removeFromParentAndCleanup:YES];
        [self.descriptorIcons removeObject:icon];
    }
}

- (void)bossAbilitySelected:(id)sender {
    CCMenuItemSprite *menuItem = (CCMenuItemSprite*)sender;
    AbilityDescriptor *abilityDesc = (AbilityDescriptor*)[menuItem userData];
    [self.delegate abilityDescriptionViewDidSelectAbility:abilityDesc];
}

- (void)update {
    [self configureIcons];
}

@end

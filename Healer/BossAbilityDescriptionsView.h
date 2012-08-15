//
//  BossAbilityDescriptionsView.h
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

#define MAX_SHOWN 5

@class Boss, AbilityDescriptor;

@protocol AbilityDescriptionViewDelegate <NSObject>

- (void)abilityDescriptionViewDidSelectAbility:(AbilityDescriptor*)descriptor;

@end

@interface BossAbilityDescriptionsView : CCNode
@property (nonatomic, assign) Boss *boss;
@property (nonatomic, assign) id<AbilityDescriptionViewDelegate> delegate;

- (id)initWithBoss:(Boss*)boss;

- (void)update;

@end

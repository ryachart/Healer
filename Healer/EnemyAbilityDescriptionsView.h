//
//  BossAbilityDescriptionsView.h
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

#define MAX_SHOWN 5

@class Enemy, AbilityDescriptor;

@protocol AbilityDescriptionViewDelegate <NSObject>

- (void)abilityDescriptionViewDidSelectAbility:(AbilityDescriptor*)descriptor;

@end

@interface EnemyAbilityDescriptionsView : CCNode <CCRGBAProtocol>
@property (nonatomic, assign) Enemy *boss;
@property (nonatomic, assign) id<AbilityDescriptionViewDelegate> delegate;

- (id)initWithBoss:(Enemy*)boss;
- (void)fadeIn;
- (void)update;

@end

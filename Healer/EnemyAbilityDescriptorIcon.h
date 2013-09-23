//
//  BossAbilityDescriptorIcon.h
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class AbilityDescriptor;

@interface EnemyAbilityDescriptorIcon : CCNode <CCRGBAProtocol>
@property (nonatomic, retain) AbilityDescriptor *ability;

- (id)initWithAbility:(AbilityDescriptor*)ability target:(id)target selector:(SEL)selector;
- (void)updateStacks;
@end

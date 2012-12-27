//
//  BossAbilityDescriptorIcon.h
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class AbilityDescriptor;

@interface BossAbilityDescriptorIcon : CCNode <CCRGBAProtocol>
@property (nonatomic, retain) AbilityDescriptor *ability;

- (id)initWithAbility:(AbilityDescriptor*)ability target:(id)target selector:(SEL)selector;

@end

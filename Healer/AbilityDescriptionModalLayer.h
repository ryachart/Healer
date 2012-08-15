//
//  AbilityDescriptionModalLayer.h
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class AbilityDescriptor;

@protocol AbilityDescriptorModalDelegate <NSObject>

- (void)abilityDescriptorModaldidComplete:(id)modal;

@end

@interface AbilityDescriptionModalLayer : CCLayerColor
@property (nonatomic, assign) id <AbilityDescriptorModalDelegate> delegate;
- (id)initWithAbilityDescriptor:(AbilityDescriptor*)descriptor;
@end


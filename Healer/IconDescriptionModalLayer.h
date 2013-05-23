//
//  AbilityDescriptionModalLayer.h
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class AbilityDescriptor;

@protocol IconDescriptorModalDelegate <NSObject>

- (void)iconDescriptionModalDidComplete:(id)modal;

@end

@interface IconDescriptionModalLayer : CCLayerColor <CCTargetedTouchDelegate>
@property (nonatomic, assign) id <IconDescriptorModalDelegate> delegate;
- (id)initWithAbilityDescriptor:(AbilityDescriptor*)descriptor;
- (id)initWithIconName:(NSString *)iconName title:(NSString *)title andDescription:(NSString *)description;
- (id)initAsMainContentSalesModal;
@end


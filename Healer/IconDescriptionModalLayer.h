//
//  AbilityDescriptionModalLayer.h
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class AbilityDescriptor, EquipmentItem;

@protocol IconDescriptorModalDelegate <NSObject>

- (void)iconDescriptionModalDidComplete:(id)modal;

@end

@interface IconDescriptionModalLayer : CCLayerColor <CCTargetedTouchDelegate>
@property (nonatomic, assign) id <IconDescriptorModalDelegate> delegate;
@property (nonatomic, readwrite) BOOL isConfirmed; //For confirmation dialogs
- (id)initWithAbilityDescriptor:(AbilityDescriptor*)descriptor;
- (id)initWithIconName:(NSString *)iconName title:(NSString *)title andDescription:(NSString *)description;
- (id)initAsMainContentSalesModal;
- (id)initAsItemSellConfirmModalWithItem:(EquipmentItem*)item;
- (id)initAsConfirmationDialogueWithDescription:(NSString *)description;
@end


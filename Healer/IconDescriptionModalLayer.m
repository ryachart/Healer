//
//  AbilityDescriptionModalLayer.m
//  Healer
//
//  Created by Ryan Hart on 8/8/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "IconDescriptionModalLayer.h"
#import "AbilityDescriptor.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"
#import "CCLabelTTFShadow.h"
#import "PlayerDataManager.h"
#import "PurchaseManager.h"


#define TARGET_WIDTH 75.0f
#define TARGET_HEIGHT 75.0f


@interface IconDescriptionModalLayer ()
@property (nonatomic, assign) BackgroundSprite *alertDialogBackground;
@end

@implementation IconDescriptionModalLayer

- (id)initWithBase
{
    if (self = [super init]) {
        self.scale = 0;
        
        self.alertDialogBackground = [[[BackgroundSprite alloc] initWithAssetName:@"alert-dialog-ipad"] autorelease];
        [self.alertDialogBackground setPosition:CGPointMake(512, 384)];
        [self.alertDialogBackground setAnchorPoint:CGPointMake(.5, .5)];
        [self addChild:self.alertDialogBackground];
    }
    return self;
}

- (id)initWithIconName:(NSString *)iconName title:(NSString *)title andDescription:(NSString *)description{
    if (self = [self initWithBase]) {
        BasicButton *doneButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(shouldDismiss) andTitle:@"Done"];
        [doneButton setScale:.75];
        CCMenu *menu = [CCMenu menuWithItems:doneButton, nil];
        [menu setPosition:CGPointMake(356, 190)];
        [self.alertDialogBackground addChild:menu];
        
        NSInteger noIconTitleAdjust = 0;
        NSInteger noIconDescAdjust = 0;
        if (!iconName) {
            noIconTitleAdjust = -20;
            noIconDescAdjust = -26;
        }
        
        CCLabelTTFShadow *nameLabel = [CCLabelTTFShadow labelWithString:title dimensions:CGSizeMake(self.alertDialogBackground.contentSize.width / 2, self.alertDialogBackground.contentSize.height / 4) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        [nameLabel setPosition:CGPointMake(376 + noIconTitleAdjust, 276)];
        [self.alertDialogBackground addChild:nameLabel];
        
        CCLabelTTFShadow *descLabel = [CCLabelTTFShadow labelWithString:description dimensions:CGSizeMake(self.alertDialogBackground.contentSize.width / 2.25, self.alertDialogBackground.contentSize.width / 2) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        [descLabel setPosition:CGPointMake(390 + noIconDescAdjust, 122)];
        [self.alertDialogBackground addChild:descLabel];
        
        if (iconName) {
            CCSprite *descImage = [CCSprite spriteWithSpriteFrameName:iconName];
            descImage.scaleX = TARGET_WIDTH / descImage.contentSize.width;
            descImage.scaleY = TARGET_HEIGHT / descImage.contentSize.height;
            [descImage setPosition:CGPointMake(200, 260)];
            [self.alertDialogBackground addChild:descImage];
        }
        
    }
    return self;
}

- (id)initWithAbilityDescriptor:(AbilityDescriptor *)descriptor {
    if (self = [self initWithIconName:descriptor.iconName title:descriptor.abilityName andDescription:descriptor.abilityDescription]) {
        
    }
    return self;
}

- (id)initAsMainContentSalesModal
{
    if (self = [self initWithBase]) {
        CCLabelTTFShadow *nameLabel = [CCLabelTTFShadow labelWithString:@"GET THE LEGACY OF TORMENT" dimensions:CGSizeMake(self.alertDialogBackground.contentSize.width / 2, self.alertDialogBackground.contentSize.height / 4) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [nameLabel setPosition:CGPointMake(356, 276)];
        [nameLabel setColor:ccRED];
        [self.alertDialogBackground addChild:nameLabel];
        
        CCLabelTTFShadow *descLabel = [CCLabelTTFShadow labelWithString:END_FREE_STRING dimensions:CGSizeMake(self.alertDialogBackground.contentSize.width / 2.5, self.alertDialogBackground.contentSize.width / 2) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        [descLabel setPosition:CGPointMake(364, 122)];
        [self.alertDialogBackground addChild:descLabel];
        
        BasicButton *doneButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(shouldDismiss) andTitle:@"Later"];
        [doneButton setScale:.75];
        
        BasicButton *purchaseButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(purchaseMainContent) andTitle:@"Purchase"];
        [purchaseButton setScale:.75];
        
        CCMenu *menu = [CCMenu menuWithItems:doneButton, purchaseButton, nil];
        [menu alignItemsHorizontally];
        [menu setPosition:CGPointMake(356, 190)];
        [self.alertDialogBackground addChild:menu];
    }
    return self;
}

- (void)onEnter {
    [super onEnter];
    
    [self runAction:[CCScaleTo actionWithDuration:.15 scale:1.0]];
}

- (void)purchaseMainContent
{
    [[PurchaseManager sharedPurchaseManager] purchaseLegacyOfTorment];
    [self shouldDismiss];
}

- (void)shouldDismiss {
    [self.delegate iconDescriptionModalDidComplete:self];
}
@end

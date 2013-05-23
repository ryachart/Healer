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
@property (nonatomic, assign) CCMenu *menu;
@end

@implementation IconDescriptionModalLayer

- (id)initWithBase
{
    if (self = [super init]) {
        
        self.alertDialogBackground = [[[BackgroundSprite alloc] initWithAssetName:@"alert-dialog"] autorelease];
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
        self.menu = [CCMenu menuWithItems:doneButton, nil];
        [self.menu setPosition:CGPointMake(356, 190)];
        [self.alertDialogBackground addChild:self.menu];
        
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
    if (self = [super init]) {
        self.alertDialogBackground = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"lot-expansion"] autorelease];
        [self addChild:self.alertDialogBackground];
        
        BasicButton *doneButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(shouldDismiss) andTitle:@"Later"];
        [doneButton setScale:.75];
        
        BasicButton *purchaseButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(purchaseMainContent) andTitle:@"Purchase"];
        [purchaseButton setScale:.75];
        
        self.menu = [CCMenu menuWithItems:doneButton, purchaseButton, nil];
        [self.menu alignItemsHorizontallyWithPadding:100];
        [self.menu setPosition:CGPointMake(512, 70)];
        [self.alertDialogBackground addChild:self.menu];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPurchaseExpansion) name:PlayerDidPurchaseExpansionNotification object:nil];
    }
    return self;
}

- (void)onEnter {
    [super onEnter];
    
    float targetScale = self.scale;
    
    self.scale = 0;
    [self runAction:[CCScaleTo actionWithDuration:.15 scale:targetScale]];
    [[CCDirectorIOS sharedDirector].touchDispatcher addTargetedDelegate:self priority:kCCMenuHandlerPriority -1 swallowsTouches:YES];
    
    if (self.menu) {
        [[CCDirectorIOS sharedDirector].touchDispatcher setPriority:kCCMenuHandlerPriority - 2 forDelegate:self.menu];
    }
}

- (void)onExit
{
    [super onExit];
    [[CCDirectorIOS sharedDirector].touchDispatcher removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didPurchaseExpansion
{
    [self shouldDismiss];
}

- (void)purchaseMainContent
{
    [[PurchaseManager sharedPurchaseManager] purchaseLegacyOfTorment];
}

- (void)shouldDismiss {
    [self.delegate iconDescriptionModalDidComplete:self];
}

#pragma mark - Targeted Delegate
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}
@end

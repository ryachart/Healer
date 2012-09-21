//
//  DivinityTierCard.m
//  Healer
//
//  Created by Ryan Hart on 9/3/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "DivinityTierCard.h"
#import "Divinity.h"
#import "BasicButton.h"
#import "Shop.h"
#import "GoldCounterSprite.h"

@interface DivinityTierCard ()
@property (nonatomic, assign) CCSprite *selectedChoiceIcon;
@property (nonatomic, assign) CCLabelTTF *selectedChoiceTitle;
@property (nonatomic, assign) CCLabelTTF *selectedChoiceDescription;

@end

@implementation DivinityTierCard
- (id)initForDivinityTier:(NSInteger)tier {
    if (self = [super init]){
        self.tier = tier;
        self.anchorPoint = CGPointZero;
        BOOL isUnlocked = [Shop numDivinityTiersPurchased] > tier;
        
        if (isUnlocked){
            NSString *spriteName = [NSString stringWithFormat:@"divinity_tier%i_frame.png", tier + 1];
            CCSprite *divFrame = [CCSprite spriteWithSpriteFrameName:spriteName];
            [divFrame setAnchorPoint:CGPointZero];
            [self addChild:divFrame];
            
            NSString* titleString = nil;
            NSString* iconFrameName = nil;
            NSString* titleDescription = nil;
            if ([Divinity selectedChoiceForTier:self.tier]){
                titleString = [Divinity selectedChoiceForTier:self.tier];
                iconFrameName = [Divinity spriteFrameNameForChoice:titleString];
                titleDescription = [Divinity descriptionForChoice:titleString];
                titleString = [titleString uppercaseString];
                
                if (![[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:iconFrameName]){
                    iconFrameName = @"default_divinity.png";
                }
            }else {
                titleString = @"CHOOSE";
                titleDescription = @"Select from these three choices to enhance your abilities.";
                iconFrameName = @"default_divinity.png";
            }
            NSInteger fontSize = 14.0;
            self.selectedChoiceIcon = [CCSprite spriteWithSpriteFrameName:iconFrameName];
            self.selectedChoiceTitle = [CCLabelTTF labelWithString:titleString dimensions:CGSizeMake(170, 30) alignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:fontSize];
            self.selectedChoiceDescription = [CCLabelTTF labelWithString:titleDescription dimensions:CGSizeMake(170, 96) alignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:12.0];
            
            [self.selectedChoiceIcon setScale:.5];
            [self.selectedChoiceIcon setPosition:CGPointMake(45, 50)];
            
            [self.selectedChoiceTitle setPosition:CGPointMake(160, 75)];
            [self.selectedChoiceDescription setColor:ccc3(240,181, 123)];
            [self.selectedChoiceDescription setPosition:CGPointMake(168, 25)];
            
            [self addChild:self.selectedChoiceIcon];
            [self addChild:self.selectedChoiceTitle];
            [self addChild:self.selectedChoiceDescription];

        }else {
            BOOL isNextDivinityTierToUnlock = [Shop numDivinityTiersPurchased] == tier;
            BasicButton *unlockButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(unlockTier:) andTitle:@"Unlock"];
            [unlockButton setScale:.5];
            [unlockButton setIsEnabled:isNextDivinityTierToUnlock];
            CCMenu *unlockButtonMenu = [CCMenu menuWithItems:unlockButton, nil];
            [unlockButtonMenu setPosition:CGPointMake(70, 68 - (self.tier * 5))];
            [self addChild:unlockButtonMenu];
            CCSprite *goldCoin = [CCSprite spriteWithSpriteFrameName:@"gold_coin.png"];
            [goldCoin setPosition:CGPointMake(150, unlockButtonMenu.position.y)];
            [goldCoin setScale:.28];
            [self addChild:goldCoin];
            CCLabelTTF *costLabel = [GoldCounterSprite goldCostLabelWithCost:[Shop costForDivinityTier:tier] andFontSize:24.0];
            [costLabel setPosition:CGPointMake(168, unlockButtonMenu.position.y - 18.0)];
            [self addChild:costLabel];
        }
    }
    return self;
}

- (void)unlockTier:(id)sender {
    [self.delegate unlockPurchasedForDivinityTier:self.tier];
}
@end

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

- (id)initForDivinityTier:(NSInteger)tier
{
    return [self initForDivinityTier:tier withSelectedChoice:[Divinity selectedChoiceForTier:tier] forceUnlocked:NO showsBackground:YES];
}

- (id)initForDivinityTier:(NSInteger)tier withSelectedChoice:(NSString *)choice forceUnlocked:(BOOL)forceUnlocked showsBackground:(BOOL)showsBackground {
    if (self = [super init]){
        self.tier = tier;
        self.anchorPoint = CGPointZero;
        BOOL isUnlocked = [Divinity numDivinityTiersUnlocked] > tier || forceUnlocked;
        
        if (isUnlocked){
            NSString *spriteName = [NSString stringWithFormat:@"divinity_tier%i_frame.png", tier + 1];
            CCSprite *divFrame = [CCSprite spriteWithSpriteFrameName:spriteName];
            if (!showsBackground) {
                [divFrame setOpacity:0];
            }
            [divFrame setAnchorPoint:CGPointZero];
            [self addChild:divFrame];
            
            NSString* titleString = nil;
            NSString* iconFrameName = nil;
            NSString* titleDescription = nil;
            if (choice){
                titleString = choice;
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
            self.selectedChoiceTitle = [CCLabelTTF labelWithString:titleString dimensions:CGSizeMake(170, 30) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:fontSize];
            self.selectedChoiceDescription = [CCLabelTTF labelWithString:titleDescription dimensions:CGSizeMake(170, 96) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:12.0];
            
            [self.selectedChoiceIcon setScale:.5];
            [self.selectedChoiceIcon setPosition:CGPointMake(45, 50)];
            
            [self.selectedChoiceTitle setPosition:CGPointMake(160, 75)];
            [self.selectedChoiceDescription setColor:ccc3(240,181, 123)];
            [self.selectedChoiceDescription setPosition:CGPointMake(168, 25)];
            
            [self addChild:self.selectedChoiceIcon];
            [self addChild:self.selectedChoiceTitle];
            [self addChild:self.selectedChoiceDescription];

        }else {
            CCLabelTTF *requires = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Unlocks At %i", [Divinity requiredRatingForTier:tier]] dimensions:CGSizeMake(200, 30) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
            [requires setPosition:CGPointMake(130, 45)];
            [self addChild:requires];
            
            CCSprite *difficultySkull = [CCSprite spriteWithSpriteFrameName:@"difficulty_skull.png"];
            [difficultySkull setPosition:CGPointMake(requires.contentSize.width, 45)];
            [self addChild:difficultySkull];
        }
    }
    return self;
}

@end

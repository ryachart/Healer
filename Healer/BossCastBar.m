//
//  BossCastBar.m
//  Healer
//
//  Created by Ryan Hart on 2/8/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "BossCastBar.h"
#import "Ability.h"
#import "ClippingNode.h"
#import "CCLabelTTFShadow.h"
#import "Boss.h"

#define CASTBAR_INSET_WIDTH 4
#define CASTBAR_INSET_HEIGHT 5

@interface BossCastBar ()
@property (nonatomic, assign) ClippingNode *castBarClippingNode;
@property (nonatomic, assign) CCSprite *castBar;
@property (nonatomic, readwrite) BOOL isCastingAbilityChanneled;
@end

@implementation BossCastBar

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
        
        CCSprite *background = [CCSprite spriteWithSpriteFrameName:@"cast_bar_back.png"];
        [background setAnchorPoint:CGPointZero];
        [self addChild:background];
        
        self.timeRemaining = [CCLabelTTFShadow labelWithString:@"" dimensions:self.contentSize hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.timeRemaining setAnchorPoint:CGPointZero];
        [self.timeRemaining setColor:ccc3(255, 255, 255)];
        [self.timeRemaining setPosition:CGPointMake(20, 12)];
        [self addChild:self.timeRemaining z:100];
        
        self.castBar = [CCSprite spriteWithSpriteFrameName:@"cast_bar_fill.png"];
        [self.castBar setColor:ccORANGE];
        [self.castBar setPosition:CGPointMake(CASTBAR_INSET_WIDTH, CASTBAR_INSET_HEIGHT)];
        [self.castBar setAnchorPoint:CGPointZero];
        
        self.castBarClippingNode = [ClippingNode node];
        [self.castBarClippingNode setAnchorPoint:CGPointZero];
        [self.castBarClippingNode setClippingRegion:CGRectMake(0,0,0,0)];
        [self.castBarClippingNode addChild:self.castBar];
        
        [self addChild:self.castBarClippingNode];
    }
    return self;
}

- (void)postFadeCleanup
{
    [self.timeRemaining setString:@""];
    [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0, 0, 0)];
}

-(void)update
{
    Ability *activeAbility = self.boss.visibleAbility;
    
	if (!activeAbility){
        const NSInteger fadeOutTag = 43234;
        if (![self getActionByTag:fadeOutTag] && self.opacity > 0) {
            [self stopAllActions];
            NSTimeInterval fadeTime = 1.0;
            CCFadeTo *fadeOut = [CCFadeTo actionWithDuration:fadeTime opacity:0];
            [fadeOut setTag:fadeOutTag];
            [self runAction:fadeOut];
            [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:fadeTime] two:[CCCallFunc actionWithTarget:self selector:@selector(postFadeCleanup)]]];
            
            if (!self.isCastingAbilityChanneled) {
                [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0,(self.castBar.contentSize.width + CASTBAR_INSET_WIDTH), self.castBar.contentSize.height + CASTBAR_INSET_HEIGHT)];
            }
        }
        self.isCastingAbilityChanneled = NO;
        
	} else {
        const NSInteger fadeInTag = 46433;
        if (![self getActionByTag:fadeInTag]) {
            [self stopAllActions];
            CCFadeTo *fadeIn = [CCFadeTo actionWithDuration:.25 opacity:255];
            [fadeIn setTag:fadeInTag];
            [self runAction:fadeIn];
        }
        float timeRemaining = activeAbility.isChanneling ? activeAbility.channelTimeRemaining :activeAbility.remainingActivationTime;
        float maxTimeRemaining = activeAbility.isChanneling ? activeAbility.maxChannelTime : activeAbility.activationTime;
		float percentTimeRemaining =  timeRemaining / maxTimeRemaining;
        if (activeAbility.isChanneling) {
            percentTimeRemaining = 1.0 - percentTimeRemaining;
            self.isCastingAbilityChanneled = YES;
        }
        [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0,(self.castBar.contentSize.width + CASTBAR_INSET_WIDTH) * (1.0 - percentTimeRemaining), self.castBar.contentSize.height + CASTBAR_INSET_HEIGHT)];
		[self.timeRemaining setString:[NSString stringWithFormat:@"%@", self.boss.visibleAbility.title]];
	}
}

#pragma mark - CCRBGAProtocol

- (void)setColor:(ccColor3B)color
{
    //Nothing
}

- (ccColor3B)color
{
    return ccBLACK;
}

- (void)setOpacity:(GLubyte)opacity
{
    for (CCNode *child in self.children){
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            id<CCRGBAProtocol> colorChild = (CCSprite*)child;
            [colorChild setOpacity:opacity];
        }
    }
}

- (GLubyte)opacity
{
    float highestOpacity = 0;
    for (CCNode *child in self.children){
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            id<CCRGBAProtocol> colorChild = (CCSprite*)child;
            highestOpacity = [colorChild opacity] > highestOpacity ? [colorChild opacity] : highestOpacity;
        }
    }
    return highestOpacity;
}

@end
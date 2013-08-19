//
//  BossCastBar.m
//  Healer
//
//  Created by Ryan Hart on 2/8/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "EnemyCastBar.h"
#import "Ability.h"
#import "ClippingNode.h"
#import "CCLabelTTFShadow.h"
#import "Enemy.h"

#define CASTBAR_INSET_WIDTH 4
#define CASTBAR_INSET_HEIGHT 5

@interface EnemyCastBar ()
@property (nonatomic, assign) CCProgressTimer *castBar;
@property (nonatomic, readwrite) BOOL isCastingAbilityChanneled;
@property (nonatomic, assign) CCLabelTTFShadow *castTitle;
@property (nonatomic, assign) CCSprite *abilityIcon;

@end

@implementation EnemyCastBar

- (id)init{
    if (self = [super init]) {
        // Initialization code
        
        CCSprite *healthBack = [CCSprite spriteWithSpriteFrameName:@"bar_back_large.png"];
        [self addChild:healthBack];
        
        self.castBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithSpriteFrameName:@"bar_fill_large.png"]];
        [self.castBar setColor:ccORANGE];
        self.castBar.midpoint = CGPointMake(0, .5);
        self.castBar.barChangeRate = CGPointMake(1.0, 0);
        self.castBar.type = kCCProgressTimerTypeBar;
        [self addChild:self.castBar];
        
        self.castTitle = [CCLabelTTFShadow labelWithString:@"" dimensions:healthBack.contentSize hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        [self.castTitle setColor:ccc3(255, 255, 255)];
        [self.castTitle setPosition:CGPointMake(0, -5)];
        [self addChild:self.castTitle z:100];
        
        self.abilityIcon = [CCSprite node];
        self.abilityIcon.scale = .26;
        [self.abilityIcon setPosition:CGPointMake(-self.castBar.contentSize.width / 2 + 12, 0)];
        [self addChild:self.abilityIcon];
        
        self.opacity = 0;

    }
    return self;
}

- (void)postFadeCleanup
{
    [self.castTitle setString:@""];
    [self.castBar setPercentage:0.0];
}

-(void)update
{
    Ability *activeAbility = self.enemy.visibleAbility;
    
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
                [self.castBar setPercentage:100.0];
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
        
        [self.abilityIcon setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:activeAbility.iconName]];
        [self.castBar setPercentage:(1-percentTimeRemaining) * 100];
		[self.castTitle setString:[NSString stringWithFormat:@"%@", self.enemy.visibleAbility.title]];
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
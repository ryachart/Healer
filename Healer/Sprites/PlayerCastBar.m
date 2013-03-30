//
//  PlayerCastBar.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerCastBar.h"
#import "Spell.h"
#import "CCLabelTTFShadow.h"
#import "Player.h"

#define CASTBAR_INSET_WIDTH 4
#define CASTBAR_INSET_HEIGHT 4

@interface PlayerCastBar ()
@property (nonatomic, assign) Spell* castingSpell;
@property (nonatomic, assign) CCSprite *spellIcon;
@property (nonatomic, assign) CCProgressTimer *castBar;
@property (nonatomic, readwrite) GLubyte opacity;
@property (nonatomic, readwrite) BOOL isInterrupted;
@property (nonatomic, readwrite) float stunMax;
@end

@implementation PlayerCastBar

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
        
        CCSprite *background = [CCSprite spriteWithSpriteFrameName:@"bar_back_long.png"];
        [background setAnchorPoint:CGPointZero];
        [self addChild:background];
        
        self.timeRemaining = [CCLabelTTFShadow labelWithString:@"" dimensions:background.contentSize hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.timeRemaining setAnchorPoint:CGPointZero];
        [self.timeRemaining setColor:ccc3(255, 255, 255)];
        [self.timeRemaining setPosition:CGPointMake(0, 0)];
        [self addChild:self.timeRemaining z:100];
        
        self.castBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithSpriteFrameName:@"bar_fill_long.png"]];
        [self.castBar setColor:ccGREEN];
        [self.castBar setPosition:CGPointMake(CASTBAR_INSET_WIDTH, CASTBAR_INSET_HEIGHT)];
        [self.castBar setAnchorPoint:CGPointZero];
        self.castBar.midpoint = CGPointMake(0, .5);
        self.castBar.barChangeRate = CGPointMake(1.0, 0);
        self.castBar.type = kCCProgressTimerTypeBar;
        [self addChild:self.castBar];
        
        self.spellIcon = [CCSprite node];
        self.spellIcon.position = CGPointMake(17, 17);
        self.spellIcon.scale = .28;
        [self addChild:self.spellIcon];
        
        self.opacity = 0; //This needs to be initialized after we setup our children
    }
    return self;
}

- (void)postFadeCleanup
{
    [self.timeRemaining setString:@""];
    [self.castBar setPercentage:0.0];
}

-(void)update
{
    Spell *spell = self.player.spellBeingCast;
    
	if ((!spell || self.player.remainingCastTime <= 0) && !self.player.isStunned){
        const NSInteger fadeOutTag = 43234;
        if (![self getActionByTag:fadeOutTag] && self.opacity > 0) {
            [self stopAllActions];
            NSTimeInterval fadeTime = 1.0;
            CCFadeTo *fadeOut = [CCFadeTo actionWithDuration:fadeTime opacity:0];
            [fadeOut setTag:fadeOutTag];
            [self runAction:fadeOut];
            [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:fadeTime] two:[CCCallFunc actionWithTarget:self selector:@selector(postFadeCleanup)]]];
        }
        if (self.castingSpell) {
            if (!self.isInterrupted) {
                self.timeRemaining.string = [NSString stringWithFormat:@"%@: 0:00", self.castingSpell.title];
            }
            [self.castBar setPercentage:100.0f];
            self.castingSpell = nil;
        }
	}
	else {
        if (self.player.isStunned) {
            float stunDur = self.player.stunDuration;
            if (stunDur > self.stunMax) {
                self.stunMax = stunDur;
            }
            [self.timeRemaining setString:[NSString stringWithFormat:@"Stunned! %1.2f", self.player.stunDuration]];
            self.castBar.color = ccRED;
            self.castBar.percentage = 100 * (stunDur/self.stunMax);
        } else {
            self.stunMax = 0;
            self.spellIcon.displayFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spell.spriteFrameName];
            
            const NSInteger fadeInTag = 46433;
            if (![self getActionByTag:fadeInTag]) {
                [self stopAllActions];
                CCFadeTo *fadeIn = [CCFadeTo actionWithDuration:.25 opacity:255];
                [fadeIn setTag:fadeInTag];
                [self runAction:fadeIn];
            }
            self.isInterrupted = NO;
            [self.castBar setColor:ccGREEN];
            self.castingSpell = spell;
            
            float percentTimeRemaining = self.player.remainingCastTime/(self.player.spellBeingCast.castTime * self.player.castTimeAdjustment) ;
            [self.castBar setPercentage:100 * (1.0 - percentTimeRemaining)];
            [self.timeRemaining setString:[NSString stringWithFormat:@"%@ %1.2f", spell.title,  self.player.remainingCastTime]];
        }
	}
}

-(void)displayInterruption
{
    [self.castBar setColor:ccRED];
    self.timeRemaining.string = @"Interrupted!";
    self.isInterrupted = YES;
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

- (void)setOpacity:(GLubyte)newOpacity
{
    for (CCNode *child in self.children){
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            id<CCRGBAProtocol> colorChild = (CCSprite*)child;
            [colorChild setOpacity:newOpacity];
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

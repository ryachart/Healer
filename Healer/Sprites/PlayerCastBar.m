//
//  PlayerCastBar.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerCastBar.h"
#import "Spell.h"
#import "ClippingNode.h"
#import "CCLabelTTFShadow.h"

#define CASTBAR_INSET_WIDTH 4
#define CASTBAR_INSET_HEIGHT 4

@interface PlayerCastBar ()
@property (nonatomic, assign) Spell* castingSpell;
@property (nonatomic, assign) ClippingNode *castBarClippingNode;
@property (nonatomic, readwrite) float percentTimeRemaining;
@property (nonatomic, readwrite) GLubyte opacity;
@property (nonatomic, readwrite) BOOL isInterrupted;
@end

@implementation PlayerCastBar
@synthesize opacity=_opacity;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
		self.percentTimeRemaining = 0.0;
        
        CCSprite *background = [CCSprite spriteWithSpriteFrameName:@"bar_back_long.png"];
        [background setAnchorPoint:CGPointZero];
        [self addChild:background];
        
        self.timeRemaining = [CCLabelTTFShadow labelWithString:@"" dimensions:background.contentSize hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.timeRemaining setAnchorPoint:CGPointZero];
        [self.timeRemaining setColor:ccc3(255, 255, 255)];
        [self.timeRemaining setPosition:CGPointMake(0, 0)];
        [self addChild:self.timeRemaining z:100];
        
        self.castBar = [CCSprite spriteWithSpriteFrameName:@"bar_fill_long.png"];
        [self.castBar setColor:ccGREEN];
        [self.castBar setPosition:CGPointMake(CASTBAR_INSET_WIDTH, CASTBAR_INSET_HEIGHT)];
        [self.castBar setAnchorPoint:CGPointZero];

        self.castBarClippingNode = [ClippingNode node];
        [self.castBarClippingNode setAnchorPoint:CGPointZero];
        [self.castBarClippingNode setClippingRegion:CGRectMake(0,0,0,0)];
        [self.castBarClippingNode addChild:self.castBar];
        
        [self addChild:self.castBarClippingNode];
        self.opacity = 0; //This needs to be initialized after we setup our children
    }
    return self;
}

- (void)postFadeCleanup
{
    [self.timeRemaining setString:@""];
    [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0, 0, 0)];
}

-(void)updateTimeRemaining:(NSTimeInterval)remaining ofMaxTime:(NSTimeInterval)maxTime forSpell:(Spell*)spell
{
	if (remaining <= 0){
        const NSInteger fadeOutTag = 43234;
        if (![self getActionByTag:fadeOutTag] && self.opacity > 0) {
            [self stopAllActions];
            NSTimeInterval fadeTime = 1.0;
            CCFadeTo *fadeOut = [CCFadeTo actionWithDuration:fadeTime opacity:0];
            [fadeOut setTag:fadeOutTag];
            [self runAction:fadeOut];
            [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:fadeTime] two:[CCCallFunc actionWithTarget:self selector:@selector(postFadeCleanup)]]];
        }
		self.percentTimeRemaining = 0.0;
        if (self.castingSpell) {
            if (!self.isInterrupted) {
                self.timeRemaining.string = [NSString stringWithFormat:@"%@: 0:00", self.castingSpell.title];
            }
            [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0,(self.castBar.contentSize.width + CASTBAR_INSET_WIDTH), self.castBar.contentSize.height + CASTBAR_INSET_HEIGHT)];
            self.castingSpell = nil;
        }
	}
	else {
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
        
		self.percentTimeRemaining = remaining/maxTime;
        [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0,(self.castBar.contentSize.width + CASTBAR_INSET_WIDTH) * (1.0 - self.percentTimeRemaining), self.castBar.contentSize.height + CASTBAR_INSET_HEIGHT)];
		[self.timeRemaining setString:[NSString stringWithFormat:@"%@ %1.2f", spell.title,  remaining]];
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

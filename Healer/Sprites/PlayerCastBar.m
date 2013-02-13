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
#define CASTBAR_INSET_HEIGHT 5

@interface PlayerCastBar ()
@property (nonatomic, readwrite) BOOL castHasBegun;
@property (nonatomic, assign) ClippingNode *castBarClippingNode;
@property (nonatomic, readwrite) float percentTimeRemaining;
@end

@implementation PlayerCastBar

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
		self.percentTimeRemaining = 0.0;
        self.opacity = 0;
        
        CCSprite *background = [CCSprite spriteWithSpriteFrameName:@"cast_bar_back.png"];
        [background setAnchorPoint:CGPointZero];
        [self addChild:background];
        
        self.timeRemaining = [CCLabelTTFShadow labelWithString:@"" dimensions:self.contentSize hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.timeRemaining setAnchorPoint:CGPointZero];
        [self.timeRemaining setColor:ccc3(255, 255, 255)];
        [self.timeRemaining setPosition:CGPointMake(-10, -50)];
        [self addChild:self.timeRemaining z:100];
        
        self.castBar = [CCSprite spriteWithSpriteFrameName:@"cast_bar_fill.png"];
        [self.castBar setColor:ccGREEN];
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

-(void)updateTimeRemaining:(NSTimeInterval)remaining ofMaxTime:(NSTimeInterval)maxTime forSpell:(Spell*)spell
{
	if (remaining <= 0){
        const NSInteger fadeOutTag = 43234;
        if (![self getActionByTag:fadeOutTag] && self.opacity > 0) {
            [self stopAllActions];
            CCFadeTo *fadeOut = [CCFadeTo actionWithDuration:1.0 opacity:0];
            [fadeOut setTag:fadeOutTag];
            [self runAction:fadeOut];
        }
		[self.timeRemaining setString:@""];
		self.percentTimeRemaining = 0.0;
        [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0, 0, 0)];
        if (self.castHasBegun) {
            self.castHasBegun = NO;
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
        if (!self.castHasBegun) {
            self.castHasBegun = YES;
        }
		self.percentTimeRemaining = remaining/maxTime; //4 - (1.0 - percentTimeRemaining) * self.castBar.contentSize.width
        [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0,(self.castBar.contentSize.width + CASTBAR_INSET_WIDTH) * (1.0 - self.percentTimeRemaining), self.castBar.contentSize.height + CASTBAR_INSET_HEIGHT)];
		[self.timeRemaining setString:[NSString stringWithFormat:@"%@: %1.2f", spell.title,  remaining]];
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

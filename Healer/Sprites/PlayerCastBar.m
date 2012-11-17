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

#define CASTBAR_INSET_WIDTH 4
#define CASTBAR_INSET_HEIGHT 5

@interface PlayerCastBar ()
@property (nonatomic, readwrite) BOOL castHasBegun;
@property (nonatomic, assign) ClippingNode *castBarClippingNode;
@end

@implementation PlayerCastBar
@synthesize timeRemaining, castBar;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
		percentTimeRemaining = 0.0;
        
        CCSprite *background = [CCSprite spriteWithSpriteFrameName:@"cast_bar_back.png"];
        [background setAnchorPoint:CGPointZero];
        [self addChild:background];
        
        self.timeRemaining = [CCLabelTTF labelWithString:@"" dimensions:self.contentSize hAlignment:kCCTextAlignmentCenter fontName:@"Marion-Bold" fontSize:24.0];
        [self.timeRemaining setAnchorPoint:CGPointZero];
        [self.timeRemaining setColor:ccc3(25, 25, 25)];
        [self.timeRemaining setPosition:CGPointMake(-10, -50)];
        [self addChild:self.timeRemaining z:100];
        
        self.timeRemainingShadow = [CCLabelTTF labelWithString:@"" dimensions:self.contentSize hAlignment:kCCTextAlignmentCenter fontName:@"Marion-Bold" fontSize:24.0];
        [self.timeRemainingShadow setAnchorPoint:CGPointZero];
        [self.timeRemainingShadow setColor:ccc3(255, 255, 255)];
        [self.timeRemainingShadow setPosition:CGPointMake(-12, -52)];
        [self addChild:self.timeRemainingShadow z:100];
        
        
        self.castBar = [CCSprite spriteWithSpriteFrameName:@"cast_bar_fill.png"];
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

- (void)restartCast
{
    
}

-(void)updateTimeRemaining:(NSTimeInterval)remaining ofMaxTime:(NSTimeInterval)maxTime forSpell:(Spell*)spell
{
	if (remaining <= 0){
		[self.timeRemaining setString:@""];
        [self.timeRemainingShadow setString:@""];
		percentTimeRemaining = 0.0;
        [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0, 0, 0)];
        if (self.castHasBegun) {
            self.castHasBegun = NO;
        }
	}
	else {
        if (!self.castHasBegun) {
            self.castHasBegun = YES;
        }
		percentTimeRemaining = remaining/maxTime; //4 - (1.0 - percentTimeRemaining) * self.castBar.contentSize.width
        [self.castBarClippingNode setClippingRegion:CGRectMake(0, 0,(self.castBar.contentSize.width + CASTBAR_INSET_WIDTH) * (1.0 - percentTimeRemaining), self.castBar.contentSize.height + CASTBAR_INSET_HEIGHT)];
		[timeRemaining setString:[NSString stringWithFormat:@"%@: %1.2f", spell.title,  remaining]];
        [self.timeRemainingShadow setString:[NSString stringWithFormat:@"%@: %1.2f", spell.title,  remaining]];
	}
}

@end

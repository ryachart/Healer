//
//  PlayerMoveButton.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerMoveButton.h"

@interface PlayerMoveButton ()
@property (nonatomic, assign) CCSprite *buttonSprite;
@end

@implementation PlayerMoveButton

- (void)dealloc {
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
		self.isMoving = NO;
        self.isTouchEnabled = YES;
        
        self.buttonSprite = [CCSprite spriteWithSpriteFrameName:@"cast_cancel.png"];
        [self.buttonSprite setAnchorPoint:CGPointZero];
        [self addChild:self.buttonSprite];
        
        self.opacity = 0;
        
    }
    return self;
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    CGRect layerRect =  [self boundingBox];
    layerRect.origin = CGPointZero;
    CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
    if (CGRectContainsPoint(layerRect, convertedToNodeSpacePoint)) {
        self.isMoving = YES;
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isMoving = NO;
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

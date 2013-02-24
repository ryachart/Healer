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

- (id)init {
    if (self = [super init]) {
		self.isMoving = NO;
        self.isTouchEnabled = YES;
        
        
        self.buttonSprite = [CCSprite spriteWithSpriteFrameName:@"button_home.png"];
        [self.buttonSprite setAnchorPoint:CGPointZero];
        [self.buttonSprite setScale:.8];
        [self addChild:self.buttonSprite];
        
        self.contentSize = self.buttonSprite.contentSize;
        
        CCLabelTTF *cancelCast = [CCLabelTTF labelWithString:@"CANCEL CAST" fontName:@"Futura" fontSize:28.0];
        [cancelCast setColor:ccc3(240, 181, 123)];
        [cancelCast setContentSize:self.buttonSprite.contentSize];
        [cancelCast setPosition:CGPointMake(102, 40)];
        [cancelCast setScale:.8];
        [self addChild:cancelCast];
        
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
            [self.buttonSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"button_home_pressed.png"]];
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isMoving = NO;
    [self.buttonSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"button_home.png"]];
}

- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.buttonSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"button_home.png"]];
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

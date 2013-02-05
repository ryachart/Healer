//
//  GradientBorderLayer.m
//  Healer
//
//  Created by Ryan Hart on 2/4/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "GradientBorderLayer.h"

@interface GradientBorderLayer ()
@property (nonatomic, assign) CCLayerGradient *topLayer;
@property (nonatomic, assign) CCLayerGradient *rightLayer;
@property (nonatomic, assign) CCLayerGradient *bottomLayer;
@property (nonatomic, assign) CCLayerGradient *leftLayer;
@property (nonatomic, readwrite) BOOL isFlashing;
@end

@implementation GradientBorderLayer

- (id)init
{
    if (self = [super initWithColor:ccc4(0, 0, 0, 0)]) {
        self.baseColor = ccc3(255, 0, 0);
        self.borderWidth = 100;
        self.initialOpacity = 255;
        self.finalOpacity = 0;
        
        self.topLayer = [[[CCLayerGradient alloc] initWithColor:ccc4(self.baseColor.r, self.baseColor.g, self.baseColor.b, self.initialOpacity) fadingTo:ccc4(self.baseColor.r, self.baseColor.g, self.baseColor.b, self.finalOpacity) alongVector:CGPointMake(0, -1)] autorelease];
        [self.topLayer setContentSize:CGSizeMake(1024, self.borderWidth)];
        [self.topLayer setPosition:CGPointMake(0, 768 - self.borderWidth)];
        self.rightLayer = [[[CCLayerGradient alloc] initWithColor:ccc4(self.baseColor.r, self.baseColor.g, self.baseColor.b, self.initialOpacity) fadingTo:ccc4(self.baseColor.r, self.baseColor.g, self.baseColor.b, self.finalOpacity) alongVector:CGPointMake(-1, 0)] autorelease];
        [self.rightLayer setContentSize:CGSizeMake(self.borderWidth, 768)];
        [self.rightLayer setPosition:CGPointMake(1024 - self.borderWidth, 0)];
        self.bottomLayer = [[[CCLayerGradient alloc] initWithColor:ccc4(self.baseColor.r, self.baseColor.g, self.baseColor.b, self.initialOpacity) fadingTo:ccc4(self.baseColor.r, self.baseColor.g, self.baseColor.b, self.finalOpacity) alongVector:CGPointMake(0, 1)] autorelease];
        [self.bottomLayer setContentSize:CGSizeMake(1024, self.borderWidth)];
        self.leftLayer = [[[CCLayerGradient alloc] initWithColor:ccc4(self.baseColor.r, self.baseColor.g, self.baseColor.b, self.initialOpacity) fadingTo:ccc4(self.baseColor.r, self.baseColor.g, self.baseColor.b, self.finalOpacity) alongVector:CGPointMake(1, 0)] autorelease];
        [self.leftLayer setContentSize:CGSizeMake(self.borderWidth, 768)];
        [self.leftLayer setPosition:CGPointMake(0, 0)];
        
        [self addChild:self.topLayer];
        [self addChild:self.rightLayer];
        [self addChild:self.bottomLayer];
        [self addChild:self.leftLayer];
        
    }
    return self;
}

- (void)flash
{
    self.isFlashing = YES;
    [self setOpacity:0];
    [self runAction:[CCSequence actions:[CCFadeTo actionWithDuration:.1 opacity:255], [CCDelayTime actionWithDuration:.1], [CCFadeTo actionWithDuration:.1 opacity:0], [CCCallBlockN actionWithBlock:^(CCNode *node){
        GradientBorderLayer *gbl = (GradientBorderLayer*)node;
        [gbl setIsFlashing:NO];
    }], nil]];
}

- (void)setOpacity:(GLubyte)opacity
{
    [self.topLayer setOpacity:opacity];
    [self.rightLayer setOpacity:opacity];
    [self.bottomLayer setOpacity:opacity];
    [self.leftLayer setOpacity:opacity];
}

@end

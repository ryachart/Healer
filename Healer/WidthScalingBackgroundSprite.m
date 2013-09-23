//
//  WidthScalingBackgroundSprite.m
//  Healer
//
//  Created by Ryan Hart on 3/28/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "WidthScalingBackgroundSprite.h"

@interface WidthScalingBackgroundSprite ()
@property (nonatomic, assign) CCSprite *leftPiece;
@property (nonatomic, assign) CCSprite *rightPiece;
@property (nonatomic, retain) NSMutableArray *middlePieces;
@property (nonatomic, retain) NSString *prefix;
@end

@implementation WidthScalingBackgroundSprite

- (void)dealloc
{
    [_middlePieces release];
    [_prefix release];
    [super dealloc];
}

- (id)initWithSpritePrefix:(NSString *)prefix
{
    if (self = [super init]) {
        self.prefix = prefix;
        self.middlePieces = [NSMutableArray arrayWithCapacity:200];
        self.leftPiece = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"%@-left.png", self.prefix]];
        self.rightPiece = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"%@-right.png", self.prefix]];
        [self addChild:self.leftPiece];
        [self addChild:self.rightPiece];
    }
    return self;
}

- (CCSprite *)midPiece
{
    return [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"%@-mid.png", self.prefix]];
}

- (void)configureForContentSize
{
    CGPoint leftPoint = CGPointMake(0, 0);
    CGPoint rightPoint = CGPointMake(self.contentSize.width - self.rightPiece.contentSize.width, 0);
    
    self.leftPiece.position = leftPoint;
    self.rightPiece.position = rightPoint;
    
    for (CCSprite *midPiece in self.middlePieces) {
        [midPiece removeFromParentAndCleanup:YES];
    }
    
    NSInteger numSlivers = self.contentSize.width - self.leftPiece.contentSize.width;
    for (int i = 0; i < numSlivers; i++){
        CCSprite *midPiece = [self midPiece];
        [midPiece setPosition:CGPointMake(i, 0)];
        [self addChild:midPiece];
        [self.middlePieces addObject:midPiece];
    }
}

- (void)setContentSize:(CGSize)contentSize
{
    [super setContentSize:contentSize];
    [self configureForContentSize];
}
@end

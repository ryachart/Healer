//
//  LevelSelectSprite.m
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "LevelSelectSprite.h"
#import "PlayerDataManager.h"

@interface LevelSelectSprite ()
@property (nonatomic, assign) CCSprite *selectedRing;
@property (nonatomic, assign) CCLabelTTF *scoreLabel;
@end

@implementation LevelSelectSprite

- (id)initWithLevel:(NSInteger)levelNum
{
    if (self = [super init]) {
        self.levelNum = levelNum;
        self.scale = 1.5;
        CCSprite *indicatorSprite = [CCSprite spriteWithSpriteFrameName:@"cross_blades.png"];        
        CCSprite *indicatorSpriteSelected = [CCSprite spriteWithSpriteFrameName:@"cross_blades.png"];
        [indicatorSpriteSelected setOpacity:122];
        
        CCMenuItemSprite *menuItem = [CCMenuItemSprite itemWithNormalSprite:indicatorSprite selectedSprite:indicatorSpriteSelected target:self selector:@selector(tapped)];
        CCMenu *menu = [CCMenu menuWithItems:menuItem, nil];
        [menu setPosition:CGPointZero];
        [self addChild:menu z:100];
        
        NSInteger rating = [PlayerDataManager levelRatingForLevel:levelNum];
        if (rating > 0) {
            self.scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", rating] dimensions:CGSizeMake(60, 30) hAlignment:kCCTextAlignmentCenter fontName:@"Arial" fontSize:24.0];
            [self.scoreLabel setPosition:CGPointMake(self.contentSize.width / 2.0, - 40)];
            [self addChild:self.scoreLabel];
        }
    }
    return self;
}

- (void)setIsAccessible:(BOOL)isAccessible
{
    _isAccessible = isAccessible;
    [self setVisible:isAccessible];
}

- (void)setSelected:(BOOL)isSelected
{
    if (!self.isAccessible) return;
    if (isSelected) {
        if (!self.selectedRing) {
            self.selectedRing = [CCSprite spriteWithSpriteFrameName:@"sel-ring.png"];
            [self addChild:self.selectedRing z:-5];
            [self.selectedRing runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCSpawn actions:[CCFadeOut actionWithDuration:1.5],[CCScaleTo actionWithDuration:1.5 scale:3.0], nil],[CCCallBlockN actionWithBlock:^(CCNode *node){ [node setScale:1.0];}], nil]]];
        }
    } else {
        [self.selectedRing stopAllActions];
        [self.selectedRing removeFromParentAndCleanup:YES];
        self.selectedRing = nil;
    }
}

- (void)tapped
{
    if (!self.isAccessible) return;
    [self.delegate levelSelectSprite:self didSelectLevel:self.levelNum];
}

@end

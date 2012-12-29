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
@property (nonatomic, assign) CCLabelTTF *scoreLabelShadow;
@end

@implementation LevelSelectSprite

- (id)initWithLevel:(NSInteger)levelNum
{
    if (self = [super init]) {
        self.levelNum = levelNum;
        self.scale = 1.5;
        
//        NSInteger bestScore = [[PlayerDataManager localPlayer] scoreForLevel:self.levelNum];
        
        CCSprite *indicatorSprite = [CCSprite spriteWithSpriteFrameName:@"cross_blades.png"];        
        CCSprite *indicatorSpriteSelected = [CCSprite spriteWithSpriteFrameName:@"cross_blades.png"];
        [indicatorSpriteSelected setOpacity:122];
        
        CCMenuItemSprite *menuItem = [CCMenuItemSprite itemWithNormalSprite:indicatorSprite selectedSprite:indicatorSpriteSelected target:self selector:@selector(tapped)];
        CCMenu *menu = [CCMenu menuWithItems:menuItem, nil];
        [menu setPosition:CGPointZero];
        [self addChild:menu z:100];
        
        NSInteger rating = [[PlayerDataManager localPlayer] levelRatingForLevel:levelNum];
        if (rating > 0) {
            for (int i = 0; i < 5; i++) {
                CGPoint skullPos = CGPointMake((i * 15) - 32, -25);
                CCSprite *skullSprite = [CCSprite spriteWithSpriteFrameName:@"difficulty_skull.png"];
                [skullSprite setPosition:skullPos];
                [skullSprite setScale:.5];
                [self addChild:skullSprite z:100];
                
                if ((i + 1) > rating) {
                    [skullSprite setColor:ccc3(40, 40, 40)];
                }
            }
            
//            self.scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", bestScore] dimensions:CGSizeMake(60, 30) hAlignment:kCCTextAlignmentCenter fontName:@"Marion-Regular" fontSize:20.0f];
//            [self.scoreLabel setColor:ccc3(25, 25, 25)];
//            [self.scoreLabel setPosition:CGPointMake(self.contentSize.width / 2.0, - 50)];
//            [self addChild:self.scoreLabel z:5];
//            
//            self.scoreLabelShadow = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", bestScore] dimensions:CGSizeMake(60, 30) hAlignment:kCCTextAlignmentCenter fontName:@"Marion-Regular" fontSize:20.0f];
//            [self.scoreLabelShadow setColor:ccc3(120, 120, 120)];
//            [self.scoreLabelShadow setPosition:CGPointMake(self.contentSize.width / 2.0 - 1, - 50 - 1)];
//            [self addChild:self.scoreLabelShadow z:4];
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

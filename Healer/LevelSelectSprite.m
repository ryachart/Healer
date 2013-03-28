//
//  LevelSelectSprite.m
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "LevelSelectSprite.h"
#import "PlayerDataManager.h"
#import "Encounter.h"
#import "WidthScalingBackgroundSprite.h"

@interface LevelSelectSprite ()
@property (nonatomic, assign) CCSprite *selectedRing;
@property (nonatomic, assign) CCLabelTTF *scoreLabel;
@property (nonatomic, assign) CCLabelTTF *scoreLabelShadow;
@property (nonatomic, assign) CCLabelTTF *encounterNameLabel;
@property (nonatomic, assign) WidthScalingBackgroundSprite *labelBackground;
@end

@implementation LevelSelectSprite

- (id)initWithLevel:(NSInteger)levelNum
{
    if (self = [super init]) {
        self.levelNum = levelNum;
        
        CCSprite *bossIconSprite = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"boss-icon-%i.png", self.levelNum]];
        CCSprite *bossIconSpriteSelected = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"boss-icon-%i.png", self.levelNum]];
        [bossIconSpriteSelected setOpacity:122];
        
        CCMenuItemSprite *menuItem = [CCMenuItemSprite itemWithNormalSprite:bossIconSprite selectedSprite:bossIconSpriteSelected target:self selector:@selector(tapped)];
        CCMenu *menu = [CCMenu menuWithItems:menuItem, nil];
        [self addChild:menu z:100];
        [menu setScale:.6];
        [menu setPosition:CGPointMake(-204, -150)];
        
        NSInteger rating = [[PlayerDataManager localPlayer] levelRatingForLevel:levelNum];
        if (rating > 0) {
            for (int i = 0; i < 5; i++) {
                CGPoint skullPos = CGPointMake((i * 15) - 30, -44);
                CCSprite *skullSprite = [CCSprite spriteWithSpriteFrameName:@"difficulty_skull.png"];
                [skullSprite setPosition:skullPos];
                [skullSprite setScale:.6];
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

- (void)onExit
{
    [super onExit];
    [self.labelBackground removeFromParentAndCleanup:YES];
}

- (void)setSelected:(BOOL)isSelected
{
    if (!self.isAccessible) return;
    if (isSelected) {
        if (!self.selectedRing) {
            self.selectedRing = [CCSprite spriteWithSpriteFrameName:@"boss-icon-selected.png"];
            [self.selectedRing setPosition:CGPointZero];
            [self addChild:self.selectedRing z:-5];
            [self.selectedRing runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCFadeTo actionWithDuration:1.0 opacity:120], [CCFadeTo actionWithDuration:1.0 opacity:255], nil]]];
        }
        if (!self.labelBackground) {
           
            self.encounterNameLabel = [CCLabelTTF labelWithString:[Encounter encounterForLevel:self.levelNum isMultiplayer:NO].title fontName:@"TrebuchetMS-Bold" fontSize:24.0];
            NSLog(@"%@-%@-%@",self.encounterNameLabel.string, self.encounterNameLabel.description, NSStringFromCGSize(self.encounterNameLabel.contentSize));
            self.encounterNameLabel.horizontalAlignment = kCCTextAlignmentCenter;
            self.encounterNameLabel.position = CGPointMake(self.encounterNameLabel.contentSize.width / 2, 0);
            
            self.labelBackground = [[[WidthScalingBackgroundSprite alloc] initWithSpritePrefix:@"boss-nameplate"] autorelease];
            CGPoint worldPoint = [self convertToWorldSpace:CGPointMake(5, 80)];
            [self.labelBackground setPosition:[self.parent convertToNodeSpace: worldPoint]];
            [self.parent addChild:self.labelBackground z:500];
            //Even numbered widths, for whatever reason, have strange opacity
            [self.labelBackground setContentSize:CGSizeMake(self.encounterNameLabel.contentSize.width + 10 + !((int)self.encounterNameLabel.contentSize.width % 2), self.encounterNameLabel.contentSize.height)];
            [self.labelBackground addChild:self.encounterNameLabel];

        }else {
            self.labelBackground.visible = YES;
        }
        
    } else {
        [self.selectedRing stopAllActions];
        [self.selectedRing removeFromParentAndCleanup:YES];
        self.selectedRing = nil;
        self.labelBackground.visible = NO;
    }
}

- (void)tapped
{
    if (!self.isAccessible) return;
    [self.delegate levelSelectSprite:self didSelectLevel:self.levelNum];
}

@end

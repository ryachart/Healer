//
//  EnemyHealthBar.m
//  Healer
//
//  Created by Ryan Hart on 2/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "EnemyHealthBar.h"
#import "Enemy.h"
#import "CCLabelTTFShadow.h"

#define BAR_INSET_WIDTH 4
#define BAR_INSET_HEIGHT 5

@interface EnemyHealthBar ()
@property (nonatomic, assign) CCProgressTimer *healthBar;
@property (nonatomic, assign) CCLabelTTFShadow *percentageLabel;
@end

@implementation EnemyHealthBar

- (id)init
{
    if (self = [super init]) {
        
        CCSprite *healthBack = [CCSprite spriteWithSpriteFrameName:@"bar_back_large.png"];
        [self addChild:healthBack];
        
        self.healthBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithSpriteFrameName:@"bar_fill_large.png"]];
        [self.healthBar setColor:ccc3(200, 0, 0)];
        self.healthBar.midpoint = CGPointMake(0, .5);
        self.healthBar.barChangeRate = CGPointMake(1.0, 0);
        self.healthBar.type = kCCProgressTimerTypeBar;
        [self addChild:self.healthBar];
        
        self.percentageLabel = [CCLabelTTFShadow labelWithString:@"100.00%" dimensions:healthBack.contentSize hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        [self.percentageLabel setColor:ccc3(255, 255, 255)];
        [self.percentageLabel setPosition:CGPointMake(0, -5)];
        [self addChild:self.percentageLabel z:100];
        
    }
    return self;
}

- (void)onEnter {
    [super onEnter];
    [self.healthBar runAction:[CCProgressTo actionWithDuration:3.0 percent:100]];
}

- (void)update
{
    self.healthBar.percentage = self.enemy.healthPercentage;
    self.percentageLabel.string = [NSString stringWithFormat:@"%1.2f%%", self.enemy.healthPercentage];
}
@end

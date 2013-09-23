//
//  EnemySprite.m
//  Healer
//
//  Created by Ryan Hart on 2/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "EnemySprite.h"
#import "EnemyCastBar.h"
#import "Enemy.h"
#import "EnemyHealthBar.h"

@interface EnemySprite ()
@property (nonatomic, assign) EnemyCastBar *castBar;
@property (nonatomic, assign) EnemyHealthBar *healthBar;
@property (nonatomic, assign) CCSprite *enemySprite;
@property (nonatomic, assign) CCNode *statusNode;
@end

@implementation EnemySprite

- (id)initWithEnemy:(Enemy*)enemy
{
    if (self = [super init]) {
        self.enemy = enemy;
        CCSpriteFrame *enemySpriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:enemy.spriteName];
        
        if (!enemySpriteFrame) {
            enemySpriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"unknown_boss.png"];
        }
        
        self.enemySprite = [CCSprite spriteWithSpriteFrame:enemySpriteFrame];
        [self addChild:self.enemySprite];
        
        CGPoint enemySpritePositionFix = CGPointZero;
        CGPoint center = IS_IPAD ? CGPointMake(0, -150.0) : CGPointMake(0, -50);
        
        //Gross visual hotfixes
        if ([enemy.spriteName isEqualToString:@"twinchampions_battle_portrait.png"]) {
            NSInteger rightAdjust = 70;
            enemySpritePositionFix = CGPointMake(rightAdjust, -35);
            center = ccpAdd(center, CGPointMake(rightAdjust, 0));
        } else if ([enemy.spriteName isEqualToString:@"twinchampions2_battle_portrait.png"]) {
            enemySpritePositionFix = CGPointMake(0, -35);
            center = ccpAdd(center, CGPointMake(-50, 0));
        } else if ([enemy.spriteName hasPrefix:@"fungalravagers"]) {
            enemySpritePositionFix = CGPointMake(0, -20);
        }
        
        [self.enemySprite setPosition:enemySpritePositionFix];
        
        self.statusNode = [CCNode node];
        [self.statusNode setPosition:center];
        [self addChild:self.statusNode];
        
        self.castBar = [[[EnemyCastBar alloc] init] autorelease];
        [self.castBar setEnemy:enemy];
        [self.castBar setPosition:CGPointMake(0, 6)];
        [self.statusNode addChild:self.castBar];
        
        self.healthBar = [[[EnemyHealthBar alloc] init] autorelease];
        [self.healthBar setEnemy:enemy];
        [self.healthBar setPosition:CGPointMake(0, 40)];
        [self.statusNode addChild:self.healthBar];
        
        self.abilitiesView = [[[EnemyAbilityDescriptionsView alloc] initWithBoss:self.enemy] autorelease];
        [self.abilitiesView setPosition:CGPointMake(-128, 84)];
        [self.abilitiesView setDelegate:self];
        [self.statusNode addChild:self.abilitiesView];
        
        
        if (!IS_IPAD) {
            self.enemySprite.scale = .4;
            self.statusNode.scale = .5;
        }
        
        [self checkInactive];
    }
    return self;
}

- (void)checkInactive
{
    if (self.enemy.inactive) {
        [self.enemySprite setColor:ccc3(80, 80, 80)];
    } else {
        [self.enemySprite setColor:ccc3(255, 255, 255)];
    }
}

- (void)update
{
    [self.castBar update];
    [self.healthBar update];
    [self.abilitiesView update];
    [self checkInactive];
    
    if ([self.enemy isDead]) {
        NSInteger fadeOutTag = 43892;
        if (self.visible && ![self getActionByTag:fadeOutTag]) {
            CCFadeTo *fade = [CCFadeTo actionWithDuration:2.0 opacity:0];
            [fade setTag:fadeOutTag];
            [self runAction:[CCSequence actionOne:fade two:[CCCallFunc actionWithTarget:self selector:@selector(finishDyingFade)]]];
        }
    }
}

- (void)removeFromScene
{
    self.visible = NO;
}

- (void)finishDyingFade
{
    self.visible = NO;
}

- (void)abilityDescriptionViewDidSelectAbility:(AbilityDescriptor *)descriptor
{
    [self.delegate abilityDescriptionViewDidSelectAbility:descriptor];
}
@end

//
//  EnemySprite.m
//  Healer
//
//  Created by Ryan Hart on 2/25/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "EnemySprite.h"
#import "EnemyCastBar.h"
#import "Enemy.h"
#import "EnemyHealthBar.h"

@interface EnemySprite ()
@property (nonatomic, assign) EnemyCastBar *castBar;
@property (nonatomic, assign) EnemyHealthBar *healthBar;
@end

@implementation EnemySprite

- (id)initWithEnemy:(Enemy*)enemy
{
    CCSpriteFrame *enemySpriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:enemy.spriteName];
    
    if (!enemySpriteFrame) {
        enemySpriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"unknown_boss.png"];
    }
    
    if (self = [super initWithSpriteFrame:enemySpriteFrame]) {
        self.enemy = enemy;
        
        CGPoint center = CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2);
        
        self.castBar = [[[EnemyCastBar alloc] init] autorelease];
        [self.castBar setEnemy:enemy];
        [self.castBar setPosition:CGPointMake(center.x, 6)];
        [self addChild:self.castBar];
        
        self.healthBar = [[[EnemyHealthBar alloc] init] autorelease];
        [self.healthBar setEnemy:enemy];
        [self.healthBar setPosition:CGPointMake(center.x, 40)];
        [self addChild:self.healthBar];
        
        self.abilitiesView = [[[EnemyAbilityDescriptionsView alloc] initWithBoss:self.enemy] autorelease];
        [self.abilitiesView setPosition:CGPointMake(center.x - 128, 84)];
        [self.abilitiesView setDelegate:self];
        [self addChild:self.abilitiesView];
        
        [self checkInactive];
    }
    return self;
}

- (void)checkInactive
{
    if (self.enemy.inactive) {
        [self setColor:ccc3(80, 80, 80)];
    } else {
        [self setColor:ccc3(255, 255, 255)];
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

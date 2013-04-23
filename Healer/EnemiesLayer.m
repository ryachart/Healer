//
//  EnemiesLayer.m
//  Healer
//
//  Created by Ryan Hart on 2/25/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "EnemiesLayer.h"
#import "Enemy.h"
#import "EnemySprite.h"

@interface EnemiesLayer ()
@property (nonatomic, retain) NSMutableArray *enemySprites;
@end

@implementation EnemiesLayer

- (void)dealloc
{
    [_enemySprites release];
    [super dealloc];
}

- (id)initWithEnemies:(NSArray *)enemies
{
    if (self = [super init]) {
        _enemies = [enemies retain];
        self.areAbilitiesVisible = YES;
        self.enemySprites = [NSMutableArray arrayWithCapacity:3];
    }
    return self;
}

- (void)onEnter
{
    [super onEnter];
    [self createEnemySprites];
}

- (CGPoint)spriteCenterForEnemy:(Enemy *)enemy
{
    return [self convertToWorldSpace:[self frameOriginForIndex:[self.enemies indexOfObject:enemy]]];
}

- (CGPoint)frameOriginForIndex:(NSInteger)index
{
    if (self.enemies.count == 1 || self.enemies.count == 3) {
        //Just some hardcodes...
        switch (index) {
            case 0:
                return CGPointMake(512, 180);
            case 1:
                return CGPointMake(190, 180);
            case 2:
                return CGPointMake(836, 180);
        }
    }
    
    if (self.enemies.count == 2) {
        switch (index) {
            case 0:
                return CGPointMake(300, 200);
            case 1:
                return CGPointMake(700, 200);
        }
    }
    
    return CGPointZero;
}

- (void)createEnemySprites
{
    for (EnemySprite *sprite in self.enemySprites) {
        [sprite removeFromParentAndCleanup:YES];
    }
    
    [self.enemySprites removeAllObjects];
    
    int i = 0;
    for (Enemy *enemy in self.enemies) {
        EnemySprite *sprite = [[[EnemySprite alloc] initWithEnemy:enemy] autorelease];
        [sprite setDelegate:self];
        [sprite setPosition:[self frameOriginForIndex:i]];
        [self addChild:sprite];
        i++;
        [self.enemySprites addObject:sprite];
        sprite.abilitiesView.visible = self.areAbilitiesVisible;
    }
}

- (void)setEnemies:(NSArray *)enemies
{
    [_enemies release];
    _enemies = [enemies retain];
    
    [self createEnemySprites];
}

- (void)setAreAbilitiesVisible:(BOOL)areAbilitiesVisible
{
    for (EnemySprite *sprite in self.enemySprites) {
        sprite.abilitiesView.visible = areAbilitiesVisible;
    }
    _areAbilitiesVisible = areAbilitiesVisible;
}

- (void)fadeInAbilities
{
    _areAbilitiesVisible = YES;
    for (EnemySprite *sprite in self.enemySprites) {
        sprite.abilitiesView.visible = YES;
        [sprite.abilitiesView fadeIn];
    }
}

- (void)update {
    for (EnemySprite *sprite in self.enemySprites) {
        [sprite update];
    }
}

- (void)endBattle
{
    for (EnemySprite *enemy in self.enemySprites) {
        if (enemy.enemy.isDead) {
            [enemy removeFromScene];
        } else {
            enemy.abilitiesView.visible = NO;
        }
    }
}

- (void)abilityDescriptionViewDidSelectAbility:(AbilityDescriptor *)descriptor
{
    [self.delegate abilityDescriptionViewDidSelectAbility:descriptor];
}
@end

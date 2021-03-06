//
//  EnemiesLayer.h
//  Healer
//
//  Created by Ryan Hart on 2/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import "EnemyAbilityDescriptionsView.h"

@class Enemy;

@interface EnemiesLayer : CCLayer <AbilityDescriptionViewDelegate>
@property (nonatomic, retain) NSArray *enemies;
@property (nonatomic, assign) id<AbilityDescriptionViewDelegate>delegate;

@property (nonatomic, readwrite) BOOL areAbilitiesVisible;

- (id)initWithEnemies:(NSArray *)enemies;

- (CGPoint)spriteCenterForEnemy:(Enemy*)enemy;

- (void)update;

- (void)endBattle;

- (void)fadeInAbilities;
@end

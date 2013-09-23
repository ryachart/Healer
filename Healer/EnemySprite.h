//
//  EnemySprite.h
//  Healer
//
//  Created by Ryan Hart on 2/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import "EnemyAbilityDescriptionsView.h"

@class Enemy;
@interface EnemySprite : CCSprite <AbilityDescriptionViewDelegate>
@property (nonatomic, assign) Enemy *enemy;
@property (nonatomic, assign) id<AbilityDescriptionViewDelegate> delegate;
@property (nonatomic, assign) EnemyAbilityDescriptionsView *abilitiesView;
- (id)initWithEnemy:(Enemy*)enemy;
- (void)update;

- (void)removeFromScene;
@end

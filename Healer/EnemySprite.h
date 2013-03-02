//
//  EnemySprite.h
//  Healer
//
//  Created by Ryan Hart on 2/25/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "cocos2d.h"
#import "EnemyAbilityDescriptionsView.h"

@class Enemy;
@interface EnemySprite : CCSprite <AbilityDescriptionViewDelegate>
@property (nonatomic, assign) Enemy *enemy;
@property (nonatomic, assign) id<AbilityDescriptionViewDelegate> delegate;
- (id)initWithEnemy:(Enemy*)enemy;
- (void)update;
@end

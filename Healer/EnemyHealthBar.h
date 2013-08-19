//
//  EnemyHealthBar.h
//  Healer
//
//  Created by Ryan Hart on 2/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class Enemy;

@interface EnemyHealthBar : CCLayer
@property (nonatomic, assign) Enemy *enemy;

- (void)update;
@end

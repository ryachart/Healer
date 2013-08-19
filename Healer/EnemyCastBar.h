//
//  BossCastBar.h
//  Healer
//
//  Created by Ryan Hart on 2/8/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class CCLabelTTFShadow, Enemy;
@interface EnemyCastBar : CCLayerColor
@property (nonatomic, assign) Enemy *enemy;
-(void)update;
@end

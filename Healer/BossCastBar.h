//
//  BossCastBar.h
//  Healer
//
//  Created by Ryan Hart on 2/8/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "cocos2d.h"

@class CCLabelTTFShadow, Boss;
@interface BossCastBar : CCLayerColor
@property (nonatomic, assign) CCLabelTTFShadow *timeRemaining;
@property (nonatomic, assign) Boss *boss;
-(id)initWithFrame:(CGRect)frame;
-(void)update;
@end
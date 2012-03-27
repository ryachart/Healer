//
//  PreBattleScene.h
//  Healer
//
//  Created by Ryan Hart on 3/26/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class Raid, Boss, Player;

@interface PreBattleScene : CCScene
@property (readwrite) NSInteger levelNumber;
-(id)initWithRaid:(Raid*)raid boss:(Boss*)boss andPlayer:(Player*)player;

@end

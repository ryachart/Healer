//
//  PostBattleScene.h
//  Healer
//
//  Created by Ryan Hart on 3/3/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@interface PostBattleScene : CCScene
-(id)initWithVictory:(BOOL)victory andEventLog:(NSArray*)eventLog;

@end

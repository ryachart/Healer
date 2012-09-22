//
//  NormalModeCompleteScene.h
//  Healer
//
//  Created by Ryan Hart on 9/21/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "CCScene.h"

@interface NormalModeCompleteScene : CCScene

+ (BOOL)needsNormalModeCompleteSceneForLevelNumber:(NSInteger)levelNumber;

- (id)initWithVictory:(BOOL)victory eventLog:(NSArray*)eventLog levelNumber:(NSInteger)levelNumber andIsMultiplayer:(BOOL)isMultiplayer deadCount:(NSInteger)numDead andDuration:(NSTimeInterval)duration;

@end

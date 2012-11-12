//
//  NormalModeCompleteScene.h
//  Healer
//
//  Created by Ryan Hart on 9/21/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "CCScene.h"

@class Encounter;
@interface NormalModeCompleteScene : CCScene

+ (BOOL)needsNormalModeCompleteSceneForLevelNumber:(NSInteger)levelNumber;

- (id)initWithVictory:(BOOL)victory encounter:(Encounter*)encounter andIsMultiplayer:(BOOL)isMultiplayer andDuration:(NSTimeInterval)duration;

@end

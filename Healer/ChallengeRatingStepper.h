//
//  ChallengeRatingStepper.h
//  Healer
//
//  Created by Ryan Hart on 11/5/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class Encounter;
@interface ChallengeRatingStepper : CCSprite

- (id)initWithEncounter:(Encounter*)encounter;

+ (NSString*)difficultyWorldForDifficultyNumber:(NSInteger)difficulty;
@end

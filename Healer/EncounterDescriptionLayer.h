//
//  EncounterDescriptionLayer.h
//  Healer
//
//  Created by Ryan Hart on 5/31/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
@class Encounter;
@interface EncounterDescriptionLayer : CCLayer

- (id)initWithEncounter:(Encounter*)encounter;

- (void)dismiss;
@end

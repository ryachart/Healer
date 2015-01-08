//
//  EncounterCard.h
//  Healer
//
//  Created by Ryan Hart on 10/29/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import "Encounter.h"

@interface EncounterCard : CCSprite
@property (nonatomic, readwrite) NSInteger levelNum;
@property (nonatomic, readwrite) EncounterType encounterType;
- (id)initWithLevelNum:(NSInteger)levelNum encounterType:(EncounterType)encounterType;

@end

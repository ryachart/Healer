//
//  EncounterCard.h
//  Healer
//
//  Created by Ryan Hart on 10/29/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@interface EncounterCard : CCSprite
@property (nonatomic, readwrite) NSInteger levelNum;
- (id)initWithLevelNum:(NSInteger)levelNum;

@end

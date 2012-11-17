//
//  RatingCounterSprite.h
//  Healer
//
//  Created by Ryan Hart on 11/16/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@interface RatingCounterSprite : CCSprite
@property (nonatomic, readwrite) BOOL updatesAutomatically; //Defaults to YES
@property (nonatomic, assign) CCLabelTTF *ratingAmountLabel;
@end

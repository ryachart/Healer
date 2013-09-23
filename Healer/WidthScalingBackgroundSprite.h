//
//  WidthScalingBackgroundSprite.h
//  Healer
//
//  Created by Ryan Hart on 3/28/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@interface WidthScalingBackgroundSprite : CCSprite

//Currently doesnt support changing the anchor point from .5,.5

- (id)initWithSpritePrefix:(NSString *)prefix; //Example @"boss-nameplate".  Will append -left.png, -mid.png, and -right.png

@end

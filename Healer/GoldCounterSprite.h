//
//  GoldCounterSprite.h
//  Healer
//
//  Created by Ryan Hart on 9/2/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@interface GoldCounterSprite : CCSprite
+ (CCLabelTTF*)goldCostLabelWithCost:(NSInteger)cost andFontSize:(CGFloat)fontSize;
@end

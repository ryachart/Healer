//
//  GoldCounterSprite.h
//  Healer
//
//  Created by Ryan Hart on 9/2/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class CCLabelTTFShadow;
@interface GoldCounterSprite : CCSprite
@property (nonatomic, readwrite) BOOL updatesAutomatically; //Defaults to YES
+ (CCLabelTTFShadow*)goldCostLabelWithCost:(NSInteger)cost andFontSize:(CGFloat)fontSize;
+ (CCNode *)goldCostNodeForCost:(NSInteger)cost;

- (void)updateGoldAnimated:(BOOL)animated toGold:(NSInteger)gold;
@end

//
//  DivinityTierCard.h
//  Healer
//
//  Created by Ryan Hart on 9/3/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
@protocol DivinityTierCardDelegate <NSObject>

- (void)unlockPurchasedForDivinityTier:(NSInteger)tier;

@end

@interface DivinityTierCard : CCSprite
@property (nonatomic, readwrite) NSInteger tier;
@property (nonatomic, assign) id <DivinityTierCardDelegate> delegate;
- (id)initForDivinityTier:(NSInteger)tier;


@end

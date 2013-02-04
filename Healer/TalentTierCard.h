//
//  DivinityTierCard.h
//  Healer
//
//  Created by Ryan Hart on 9/3/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
@protocol TalentTierCardDelegate <NSObject>

@end

@interface TalentTierCard : CCSprite
@property (nonatomic, readwrite) NSInteger tier;
@property (nonatomic, assign) id <TalentTierCardDelegate> delegate;
- (id)initForDivinityTier:(NSInteger)tier;
- (id)initForDivinityTier:(NSInteger)tier withSelectedChoice:(NSString *)choice forceUnlocked:(BOOL)forceUnlocked showsBackground:(BOOL)showsBackground;


@end

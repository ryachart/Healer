//
//  LevelSelectSprite.h
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import "Encounter.h"

@class LevelSelectSprite;
@protocol LevelSelectSpriteDelegate <NSObject>
- (void)levelSelectSprite:(LevelSelectSprite*)sprite didSelectLevel:(NSInteger)level;
@end

@interface LevelSelectSprite : CCSprite
@property (nonatomic, readwrite) NSInteger levelNum;
@property (nonatomic, readonly) EncounterType encounterType;
@property (nonatomic, assign) id<LevelSelectSpriteDelegate> delegate;
@property (nonatomic, readwrite) BOOL isAccessible;
- (id)initWithLevel:(NSInteger)levelNum encounterType:(EncounterType)encounterType;

- (void)setSelected:(BOOL)isSelected;
@end

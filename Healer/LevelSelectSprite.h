//
//  LevelSelectSprite.h
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class LevelSelectSprite;
@protocol LevelSelectSpriteDelegate <NSObject>
- (void)levelSelectSprite:(LevelSelectSprite*)sprite didSelectLevel:(NSInteger)level;
@end

@interface LevelSelectSprite : CCSprite
@property (nonatomic, readwrite) NSInteger levelNum;
@property (nonatomic, assign) id<LevelSelectSpriteDelegate> delegate;
@property (nonatomic, readwrite) BOOL isAccessible;
- (id)initWithLevel:(NSInteger)levelNum;

- (void)setSelected:(BOOL)isSelected;
@end

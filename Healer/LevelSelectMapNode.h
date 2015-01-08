//
//  LevelSelectMapNode.h
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import "LevelSelectSprite.h"
#import "Encounter.h"

@protocol LevelSelectMapNodeDelegate <NSObject>

- (void)levelSelectMapNodeDidSelectLevelNum:(NSInteger)levelNum encounterType:(EncounterType)encounterType;

@end

@interface LevelSelectMapNode : CCScrollView <LevelSelectSpriteDelegate>
@property (nonatomic, assign) id<LevelSelectMapNodeDelegate> levelSelectDelegate;
- (void)reload;
- (void)selectFurthestLevel;
@end

//
//  LevelSelectMapNode.m
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "LevelSelectMapNode.h"
#import "BasicButton.h"
#import "HealerStartScene.h"
#import "PlayerDataManager.h"
#import "EncounterCard.h"
#import "BackgroundSprite.h"
#import "LevelSelectSprite.h"

#define NUM_ENCOUNTERS 21

#define MAX_HARDMODES 4

@interface LevelSelectMapNode ()
@property (nonatomic, retain) NSMutableArray *levelSelectSprites;
@end

@implementation LevelSelectMapNode

- (void)dealloc {
    [_levelSelectSprites release];
    [super dealloc];
}

- (id)init {
    if (self = [super initWithViewSize:CGSizeMake(1024, 768)]) {
        self.bounces = NO;
        
        BackgroundSprite *map1 = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"map-level-1"] autorelease];
        [self addChild:map1];
        
        BackgroundSprite *map2 = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"map-level-2"] autorelease];
        [map2 setPosition:CGPointMake(1024, 0)];
        [self addChild:map2];
        
        BackgroundSprite *map3 = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"map-level-3"] autorelease];
        [map3 setPosition:CGPointMake(2048, 0)];
        [self addChild:map3];
        
        CGSize mapSize = CGSizeMake(3072, 768);
        CCLayerColor *layerWithColor = [CCLayerColor layerWithColor:ccc4(200, 137, 83, 255)];
        [layerWithColor setContentSize:CGSizeMake(mapSize.width * 2, mapSize.height)];
        [self addChild:layerWithColor z:-100];
        
        self.contentSize = mapSize;
        self.direction = SWScrollViewDirectionHorizontal;
        
        self.levelSelectSprites = [NSMutableArray arrayWithCapacity:20];
        
        [self configureLevelSelectSprites];
    }
    return self;
}

- (void)reload {
    [self configureLevelSelectSprites];
}

- (void)configureLevelSelectSprites {
    for (LevelSelectSprite *levelSelSprite in self.levelSelectSprites) {
        [levelSelSprite removeFromParentAndCleanup:YES];
    }
    [self.levelSelectSprites removeAllObjects];
    
    NSInteger startingLevel = 1;
    
//    if ([[PlayerDataManager localPlayer] highestLevelCompleted] > 0) {
//        startingLevel = 2;
//    }
    
    for (int i = startingLevel; i <= NUM_ENCOUNTERS; i++){

        //This level is valid for us to play
        LevelSelectSprite *levelSelectSprite = [[[LevelSelectSprite alloc] initWithLevel:i] autorelease];
        [levelSelectSprite setPosition:[self pointForLevelNumber:i]];
        [levelSelectSprite setDelegate:self];
        [self addChild:levelSelectSprite];
        [self.levelSelectSprites addObject:levelSelectSprite];
        
        if (i  > [[PlayerDataManager localPlayer] highestLevelCompleted] + 1){
            //Invalid levels
            [levelSelectSprite setIsAccessible:NO];
        } else {
            [levelSelectSprite setIsAccessible:YES];
        }
        
    }
}

- (void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    
    if ([[PlayerDataManager localPlayer] lastSelectedLevel] <= 1) {
        [self selectFurthestLevel];
    } else {
        [self selectLevel:[[PlayerDataManager localPlayer] lastSelectedLevel]];
    }
}

- (void)levelSelectSprite:(LevelSelectSprite *)sprite didSelectLevel:(NSInteger)level
{
    for (LevelSelectSprite *iSprite in self.levelSelectSprites) {
        if (sprite != iSprite) {
            [iSprite setSelected:NO];
        }
    }
    
    [sprite setSelected:YES];
    [self.levelSelectDelegate levelSelectMapNodeDidSelectLevelNum:level];
}

- (CGPoint)pointForLevelNumber:(NSInteger)levelNum
{
    switch (levelNum) {
        case 1:
            return CGPointMake(738, 614);
        case 2:
            return CGPointMake(705, 490);
        case 3:
            return CGPointMake(646, 368);
        case 4:
            return CGPointMake(752, 266);
        case 5:
            return CGPointMake(900, 192);
        case 6:
            return CGPointMake(988, 124);
        case 7:
            return CGPointMake(1096, 90);
        case 8:
            return CGPointMake(1232, 92);
        case 9:
            return CGPointMake(1310, 170);
        case 10:
            return CGPointMake(1396, 246);
        case 11:
            return CGPointMake(1500, 290);
        case 12:
            return CGPointMake(1554, 184);
        case 13:
            return CGPointMake(1606, 80);
        case 14:
            return CGPointMake(1850, 200);
        case 15:
            return CGPointMake(1992, 154);
        case 16:
            return CGPointMake(2132, 154);
        case 17:
            return CGPointMake(2276, 154);
        case 18:
            return CGPointMake(2356, 264);
        case 19:
            return CGPointMake(2406, 480);
        case 20:
            return CGPointMake(2430, 580);
        case 21:
            return CGPointMake(2468, 664);
        default:
            break;
    }
    
    return CGPointMake(330 + 80 * levelNum, 768.0 - 100.0f - (50 * (levelNum % 7)));
}

- (void)selectLevel:(NSInteger)level
{
    LevelSelectSprite *lastLevelSprite = nil;
    
    for (int i = 0; i < self.levelSelectSprites.count; i++) {
        LevelSelectSprite *sprite = [self.levelSelectSprites objectAtIndex:i];
        if (sprite.levelNum == level) {
            lastLevelSprite = sprite;
            break;
        }
    }
    
    if (lastLevelSprite) {
        [lastLevelSprite setSelected:YES];
        [self.levelSelectDelegate levelSelectMapNodeDidSelectLevelNum:lastLevelSprite.levelNum];
    }
    
    CGPoint contentOffset = CGPointMake(MIN(0,-lastLevelSprite.position.x + self.viewSize.width * .5), 0);
    [self setContentOffset:contentOffset animated:YES];
}

- (void)selectFurthestLevel
{
    [self selectLevel:MIN(NUM_ENCOUNTERS, [[PlayerDataManager localPlayer] highestLevelCompleted] + 1)];
}

@end

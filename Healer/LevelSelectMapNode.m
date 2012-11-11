//
//  LevelSelectMapNode.m
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "LevelSelectMapNode.h"
#import "BasicButton.h"
#import "HealerStartScene.h"
#import "PlayerDataManager.h"
#import "EncounterCard.h"
#import "BackgroundSprite.h"

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
        
        CGSize mapSize = CGSizeMake(2048, 768);
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
    
    if ([PlayerDataManager highestLevelCompleted] > 0) {
        startingLevel = 2;
    }
    
    for (int i = startingLevel; i <= NUM_ENCOUNTERS; i++){

        //This level is valid for us to play
        LevelSelectSprite *levelSelectSprite = [[[LevelSelectSprite alloc] initWithLevel:i] autorelease];
        [levelSelectSprite setPosition:[self pointForLevelNumber:i]];
        [levelSelectSprite setDelegate:self];
        [self addChild:levelSelectSprite];
        [self.levelSelectSprites addObject:levelSelectSprite];
        
        if (i  > [PlayerDataManager highestLevelCompleted] + 1){
            //Invalid levels
            [levelSelectSprite setIsAccessible:NO];
        } else {
            [levelSelectSprite setIsAccessible:YES];
        }
        
    }
}

- (void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    [self selectFurthestLevel];
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
            return CGPointMake(590, 635);
        case 2:
            return CGPointMake(300, 516);
        case 3:
            return CGPointMake(150, 480);
        case 4:
            return CGPointMake(222, 330);
        case 5:
            return CGPointMake(500, 250);
        case 6:
            return CGPointMake(660, 270);
        case 7:
            return CGPointMake(784, 300);
//        case 8:
//            return CGPointMake(1024 + 120, 680); //The fuck? These appear on the 2nd page
        default:
            break;
    }
    
    return CGPointMake(480 + 80 * levelNum, 768.0 - 100.0f - (50 * (levelNum % 7)));
}

- (void)selectFurthestLevel
{
    LevelSelectSprite *lastLevelSprite = nil;

    for (int i = self.levelSelectSprites.count - 1; i >= 0; i--) {
        if ([[self.levelSelectSprites objectAtIndex:i] isAccessible]) {
            lastLevelSprite = [self.levelSelectSprites objectAtIndex:i];
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

@end

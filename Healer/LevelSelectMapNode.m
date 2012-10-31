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
#import "PersistantDataManager.h"
#import "EncounterCard.h"

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
        
        CGSize mapSize = CGSizeMake(2400, 768);
        CCLayerColor *layerWithColor = [CCLayerColor layerWithColor:ccc4(200, 137, 83, 255)];
        [layerWithColor setContentSize:mapSize];
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
    
    for (int i = 1; i <= NUM_ENCOUNTERS; i++){
        if (CURRENT_MODE == DifficultyModeHard){
            if (i == 1 || i > MAX_HARDMODES){
                continue;
            }
        }
        

        //This level is valid for us to play
        LevelSelectSprite *levelSelectSprite = [[[LevelSelectSprite alloc] initWithLevel:i] autorelease];
        [levelSelectSprite setPosition:[self pointForLevelNumber:i]];
        [levelSelectSprite setDelegate:self];
        [self addChild:levelSelectSprite];
        [self.levelSelectSprites addObject:levelSelectSprite];
        
        if (i  > [PersistantDataManager highestLevelCompletedForMode:CURRENT_MODE] + 1){
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
    return CGPointMake(100 * levelNum, 768.0 - 100.0f - (50 * (levelNum % 8)));
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
}

@end

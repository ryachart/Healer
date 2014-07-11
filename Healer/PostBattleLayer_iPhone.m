//
//  PostBattleLayer_iPhone.m
//  Healer
//
//  Created by Ryan Hart on 9/21/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "PostBattleLayer_iPhone.h"
#import "PlayerDataManager.h"
#import "BasicButton.h"
#import "CCLabelTTFShadow.h"


@implementation PostBattleLayer_iPhone

- (id)initWithVictory:(BOOL)victory encounter:(Encounter *)enc andIsMultiplayer:(BOOL)isMult
{
    if (self = [super initWithColor:ccc4(0, 0, 0, 175)]) {
        [self initializeDataForVictory:victory encounter:enc isMultiplayer:isMult];
        BasicButton *leave = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneMap) andTitle:@"Leave"];
        BasicButton *openChest = [BasicButton basicButtonWithTarget:self andSelector:@selector(open) andTitle:@"Open Chest"];
        
        CCMenu *leaveMenu = [CCMenu menuWithItems:openChest, leave, nil];
        [leaveMenu setPosition:CGPointMake(SCREEN_WIDTH / 2, 380)];
        [self addChild:leaveMenu];
        
        int previousTotalRating = [PlayerDataManager localPlayer].totalRating;
        int previousGold = [PlayerDataManager localPlayer].gold;
        [self processPlayerDataProgressionForMatch];
        int ratingDiff = [PlayerDataManager localPlayer].totalRating - previousTotalRating;
        int goldDiff = [PlayerDataManager localPlayer].gold - previousGold;
        
        CCLabelTTFShadow *goldDiffLabel = [CCLabelTTFShadow labelWithString:[NSString stringWithFormat:@"+ %i", goldDiff] fontName:@"TrebuchetMS-Bold" fontSize:18.0f];
        CCLabelTTFShadow *ratingDiffLabel = [CCLabelTTFShadow labelWithString:[NSString stringWithFormat:@"+ %i", ratingDiff] fontName:@"TrebuchetMS-Bold" fontSize:18.0f];

        ratingDiffLabel.position = CGPointMake(SCREEN_WIDTH / 2, leaveMenu.position.y - 50);
        goldDiffLabel.position = CGPointMake(SCREEN_WIDTH / 2, ratingDiffLabel.position.y - 36);
        
        CCSprite *skullSprite = [CCSprite spriteWithSpriteFrameName:@"difficulty_skull.png"];
        CCSprite *goldSprite = [CCSprite spriteWithSpriteFrameName:@"gold_coin.png"];
        skullSprite.position = CGPointMake(ratingDiffLabel.position.x + 50, ratingDiffLabel.position.y);
        goldSprite.position = CGPointMake(goldDiffLabel.position.x + 50, goldDiffLabel.position.y);
        
        [self addChild:goldDiffLabel];
        [self addChild:ratingDiffLabel];
        [self addChild:skullSprite];
        [self addChild:goldSprite];
    }
    return self;
}

- (void)openChest
{
    
}

- (void)doneMap
{
    [self.delegate postBattleLayerDidTransitionToScene:PostBattleLayerDestinationMap asVictory:NO];
}


@end

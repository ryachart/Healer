//
//  LevelSelectScene_iPhone.m
//  Healer
//
//  Created by Ryan Hart on 5/20/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "LevelSelectScene_iPhone.h"
#import "BasicButton.h"
#import "HealerStartScene_iPhone.h"
#import "PlayerDataManager.h"
#import "CCLabelTTFShadow.h"
#import "BackgroundSprite.h"
#import "Encounter.h"
#import "GamePlayScene.h"

@interface LevelSelectScene_iPhone ()
@property (nonatomic, assign) CCTableView *levelSelectTable;
@end

@implementation LevelSelectScene_iPhone

- (id)init
{
    if (self = [super init]) {
        BackgroundSprite *bgSprite = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg"] autorelease];
        [self addChild:bgSprite];
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [self addChild:backButton];
        [backButton setPosition:CGPointMake(85, SCREEN_HEIGHT * .92)];
        
        self.levelSelectTable = [[[CCTableView alloc] initWithViewSize:CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT - 80)] autorelease];
        self.levelSelectTable.verticalFillOrder = SWTableViewFillTopDown;
        [self.levelSelectTable setPosition:CGPointMake(SCREEN_WIDTH * .14, 0)];
        [self addChild:self.levelSelectTable];
        self.levelSelectTable.contentSize = CGSizeMake(SCREEN_WIDTH, 2000);
        [self.levelSelectTable setDataSource:self];
        [self.levelSelectTable setDelegate:self];
        
    }
    return self;
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene_iPhone alloc] init] autorelease]]];
}

- (void)onEnter
{
    [super onEnter];
    [self.levelSelectTable reloadData];
    [self.levelSelectTable scrollToTopAnimated:NO];
}

- (CGSize)cellSizeForTable:(CCTableView *)table
{
    return CGSizeMake(SCREEN_WIDTH - 20, 80);
}

- (CCTableViewCell*)table:(CCTableView *)table cellAtIndex:(NSUInteger)idx
{
    CCTableViewSpriteCell *availableCell = (CCTableViewSpriteCell*)[table dequeueCell];
    
    if (!availableCell) {
        availableCell = [[[CCTableViewSpriteCell alloc] init] autorelease];
    }
    
    NSInteger levelNumber = idx + 1;
    
    CCSprite *cellSprite = [CCSprite spriteWithSpriteFrameName:@"button_home.png"];
    CCLabelTTFShadow *levelNumberLabel = [CCLabelTTFShadow labelWithString:[NSString stringWithFormat:@"%@", [Encounter pocketEncounterForLevel:levelNumber].title] fontName:@"TrebuchetMS-Bold" fontSize:24.0];
    levelNumberLabel.position = CGPointMake(cellSprite.contentSize.width /2, cellSprite.contentSize.height / 2);
    [cellSprite addChild:levelNumberLabel];
    
    
    [availableCell setSprite:cellSprite];
    return availableCell;
}

- (NSUInteger)numberOfCellsInTableView:(CCTableView *)table
{
    return [PlayerDataManager localPlayer].highestLevelCompleted + 1;
}

- (void)table:(CCTableView *)table cellTouched:(CCTableViewCell *)cell
{
    NSInteger levelNumber = cell.idx + 1;
    Encounter *enc = [Encounter pocketEncounterForLevel:levelNumber];
    Player *player = [[[Player alloc] initWithHealth:1400 energy:1000 energyRegen:10] autorelease];
    [player setActiveSpells:enc.recommendedSpells];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"assets-iphone/%@.plist", enc.bossKey]];
    GamePlayScene *scene = [[[GamePlayScene alloc] initWithEncounter:enc andPlayers:[NSArray arrayWithObject:player]] autorelease];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:scene]];
}

@end

//
//  LevelSelectMapScene.m
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "LevelSelectMapScene.h"
#import "BasicButton.h"
#import "HealerStartScene.h"
#import "EncounterCard.h"
#import "Encounter.h"
#import "PreBattleScene.h"
#import "Player.h"
#import "Divinity.h"
#import "PlayerDataManager.h"

@interface LevelSelectMapScene ()
@property (nonatomic, assign) LevelSelectMapNode *mapScrollView;
@property (assign) CCMenu *diffMenu;
@property (nonatomic, assign) EncounterCard *encCard;
@property (nonatomic, assign) BasicButton *battleButton;

@end

@implementation LevelSelectMapScene

- (void)dealloc
{
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        
        self.mapScrollView = [[[LevelSelectMapNode alloc] init] autorelease];
        [self.mapScrollView setLevelSelectDelegate:self];
        [self addChild:self.mapScrollView];
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:CGPointMake(100, 725)];
        [self addChild:backButton z:100];
    
        self.encCard = [[[EncounterCard alloc] initWithLevelNum:1] autorelease];
        [self addChild:self.encCard z:5];
        [self.encCard setPosition:CGPointMake(500, 100)];
        

        self.battleButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(battle) andTitle:@"Battle!"];
        CCMenu *battleMenu = [CCMenu menuWithItems:self.battleButton, nil];
        [battleMenu setPosition:CGPointMake(850, 100)];
        [self addChild:battleMenu];
        
        [self reloadDifficultyMenu];
    }
    return self;
}

- (void)loadEncounterCardForSelectedEncounter:(NSInteger)selectedEncounter {
    [self.encCard setLevelNum:selectedEncounter];
}

- (void)battle {
    NSInteger level = self.encCard.levelNum;
    Encounter *encounter = [Encounter encounterForLevel:level isMultiplayer:NO];
    Player *basicPlayer = [[[Player alloc] initWithHealth:100 energy:1000 energyRegen:10] autorelease];
    [Encounter configurePlayer:basicPlayer forRecSpells:encounter.recommendedSpells];
    
    if (encounter.boss && basicPlayer && encounter.raid){
        
        PreBattleScene *pbs = [[[PreBattleScene alloc] initWithRaid:encounter.raid boss:encounter.boss andPlayer:basicPlayer] autorelease];
        [pbs setLevelNumber:level];
        if ([Divinity isDivinityUnlocked]){
            [basicPlayer setDivinityConfig:[Divinity localDivinityConfig]];
        }
        [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInR transitionWithDuration:1.0 scene:pbs]];
    }
}

- (void)reloadDifficultyMenu
{
    if (self.diffMenu){
        [self.diffMenu removeFromParentAndCleanup:YES];
        self.diffMenu = nil;
    }
    
    NSString *title = CURRENT_MODE == DifficultyModeNormal ? @"Normal" : @"Hard";
    CCMenuItemSprite *diffButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(toggleDifficulty) andTitle:title];
    self.diffMenu = [CCMenu menuWithItems:diffButton, nil];
    [self.diffMenu setPosition:CGPointMake(120, 45)];
    [self addChild:self.diffMenu];
}

-(void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInL transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}

- (void)toggleDifficulty {
    if (![PlayerDataManager hardModeUnlocked]){
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Hard Mode Locked" message:@"Complete the game on Normal mode to unlock hard mode" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil] autorelease];
        [alert show];
    }else {
        if (CURRENT_MODE == DifficultyModeNormal){
            [PlayerDataManager setDifficultyMode:DifficultyModeHard];
        }else {
            [PlayerDataManager setDifficultyMode:DifficultyModeNormal];
        }

        [self.mapScrollView reload];
        [self reloadDifficultyMenu];
        [self.mapScrollView selectFurthestLevel];
    }
}

- (void)levelSelectMapNodeDidSelectLevelNum:(NSInteger)levelNum
{
    [self loadEncounterCardForSelectedEncounter:levelNum];
}

@end

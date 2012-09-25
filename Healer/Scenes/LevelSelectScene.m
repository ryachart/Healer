//
//  LevelSelectScene.m
//  Healer
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LevelSelectScene.h"
#import "PersistantDataManager.h"
#import "PreBattleScene.h"
#import "HealerStartScene.h"
#import "Encounter.h"
#import "Shop.h"
#import "BackgroundSprite.h"
#import "Divinity.h"
#import "BasicButton.h"

#define NUM_ENCOUNTERS 21

@interface LevelSelectScene ()
@property (assign) CCMenu *menu;
@property (assign) CCMenu *diffMenu;

- (void)beginGameWithSelectedLevel:(id)sender;
- (void)back;
- (void)beginEndlessVoidEncounter:(id)sender;

@end

@implementation LevelSelectScene

-(id)init{
    if (self = [super init]){
#if TARGET_IPHONE_SIMULATOR
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:100] forKey:PlayerHighestLevelCompleted];
#endif
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background"] autorelease]];
        
        [self configureMenuForCurrentMode];
        
        CCLabelTTF *difficultyLabel = [CCLabelTTF labelWithString:@"Difficulty:" fontName:@"Arial" fontSize:32.0];
        [difficultyLabel setPosition:CGPointMake(120, 100)];
        [self addChild:difficultyLabel];
        
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:CGPointMake(100, 725)];
        [self addChild:backButton];
        
        if ([PlayerDataManager highestLevelCompletedForMode:DifficultyModeNormal] >= 8){
            CCMenu *endlessButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"The Endless Void" fontName:@"Arial" fontSize:28.0] target:self selector:@selector(beginEndlessVoidEncounter:)], nil];
            [endlessButton setPosition:CGPointMake(512, 40)];
            [endlessButton setColor:ccWHITE];
            [self addChild:endlessButton];
        }
    }
    return self;
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
        [self configureMenuForCurrentMode];
    }
}

- (void)configureMenuForCurrentMode
{
    if (self.menu){
        [self.menu removeFromParentAndCleanup:YES];
        self.menu = nil;
    }
    
    if (self.diffMenu){
        [self.diffMenu removeFromParentAndCleanup:YES];
        self.diffMenu = nil;
    }
    
    NSString *title = CURRENT_MODE == DifficultyModeNormal ? @"Normal" : @"Hard";
    CCMenuItemSprite *diffButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(toggleDifficulty) andTitle:title];
    self.diffMenu = [CCMenu menuWithItems:diffButton, nil];
    [self.diffMenu setPosition:CGPointMake(120, 45)];
    [self addChild:self.diffMenu];
    
    self.menu = [CCMenu menuWithItems:nil];
    for (int i = 0; i < NUM_ENCOUNTERS; i++){
        if (CURRENT_MODE == DifficultyModeHard && i == 0){
            continue;
        }
        
        NSString *levelLabelText = nil;
        if (i  > [PlayerDataManager highestLevelCompletedForMode:CURRENT_MODE]){
            levelLabelText = @"????";
        }else{
            NSString* bossTitle = [Encounter encounterForLevel:i+1 isMultiplayer:NO].boss.title;
            NSString* finalString = bossTitle;
            NSInteger levelRating = [PlayerDataManager levelRatingForLevel:i+1 withMode:CURRENT_MODE];
            if (levelRating > 0) {
                finalString = [finalString stringByAppendingFormat:@" %i/10", levelRating];
            }
            levelLabelText = finalString;
        }
        CCMenuItemLabel *levelButton = [[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:levelLabelText fontName:@"Arial" fontSize:32] target: self selector:@selector(beginGameWithSelectedLevel:)];
        [levelButton.label setColor:ccBLACK];
        levelButton.tag = i +1;
        if (i  > ([[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue] )){
            levelButton.opacity = 125;
        }
        [self.menu addChild:levelButton];
        [levelButton release];
    }
    [self.menu setPosition:ccp([CCDirector sharedDirector].winSize.width /2, [CCDirector sharedDirector].winSize.height * .55)];
    [self.menu setColor:ccc3(255, 255, 255)];
    
    NSInteger leftCol = 10;
    NSInteger rightCol = 11;
    
    if (CURRENT_MODE == DifficultyModeHard){
        leftCol = 10;
        rightCol = 10;
    }
    [self.menu alignItemsInRows:[NSNumber numberWithInt:leftCol],[NSNumber numberWithInt:rightCol], nil];
    [self addChild:self.menu];
}


-(void)beginGameWithSelectedLevel:(CCMenuItemLabel*)sender{
    int level = sender.tag;
    srand(time(NULL));
    
    int highestCompleted = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue];
    
    if (highestCompleted + 1 < level){
        return;
    }
    
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

- (void)beginEndlessVoidEncounter:(id)sender{
    Encounter *encounter = [Encounter survivalEncounterIsMultiplayer:NO];
    Player *basicPlayer = [[[Player alloc] initWithHealth:100 energy:1000 energyRegen:10] autorelease];
    [Encounter configurePlayer:basicPlayer forRecSpells:encounter.recommendedSpells];
    
    if (encounter.boss && basicPlayer && encounter.raid){
        
        PreBattleScene *pbs = [[PreBattleScene alloc] initWithRaid:encounter.raid boss:encounter.boss andPlayer:basicPlayer];
        [pbs setLevelNumber:encounter.levelNumber];
        if ([Divinity isDivinityUnlocked]){
            [basicPlayer setDivinityConfig:[Divinity localDivinityConfig]];
        }
        [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInR transitionWithDuration:1.0 scene:pbs]];
        [pbs release];
        
    }
}

-(void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInL transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}


@end

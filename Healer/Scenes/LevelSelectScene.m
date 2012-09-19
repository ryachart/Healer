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

- (void)beginGameWithSelectedLevel:(id)sender;
- (void)back;
- (void)beginEndlessVoidEncounter:(id)sender;

@end

@implementation LevelSelectScene
@synthesize menu;
-(id)init{
    if (self = [super init]){
#if TARGET_IPHONE_SIMULATOR
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:100] forKey:PlayerHighestLevelCompleted];
#endif
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background-ipad"] autorelease]];
        self.menu = [CCMenu menuWithItems:nil];
        for (int i = 0; i < NUM_ENCOUNTERS; i++){
            NSString *levelLabelText = nil;
            if (i  > [PlayerDataManager highestLevelCompleted]){
                levelLabelText = @"????";
            }else{
                NSString* bossTitle = [Encounter encounterForLevel:i+1 isMultiplayer:NO].boss.title;
                NSString* finalString = bossTitle;
                NSInteger levelRating = [PlayerDataManager levelRatingForLevel:i+ 1];
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
        [self.menu alignItemsInRows:[NSNumber numberWithInt:10],[NSNumber numberWithInt:11], nil];
        [self addChild:self.menu];
        
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:CGPointMake(90, 725)];
        [self addChild:backButton];
        
        if ([PlayerDataManager highestLevelCompleted] >= 8){
            CCMenu *endlessButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"The Endless Void" fontName:@"Arial" fontSize:28.0] target:self selector:@selector(beginEndlessVoidEncounter:)], nil];
            [endlessButton setPosition:CGPointMake(512, 40)];
            [endlessButton setColor:ccWHITE];
            [self addChild:endlessButton];
        }
    }
    return self;
}


-(void)beginGameWithSelectedLevel:(CCMenuItemLabel*)sender{
    int level = sender.tag;
    srand(time(NULL));
    
    int highestCompleted = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue];
    
    if (highestCompleted + 1 < level){
        return;
    }
    
    Encounter *encounter = [Encounter encounterForLevel:level isMultiplayer:NO];
    Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
    [Encounter configurePlayer:basicPlayer forRecSpells:encounter.recommendedSpells];
    
    if (encounter.boss && basicPlayer && encounter.raid){
        
        PreBattleScene *pbs = [[PreBattleScene alloc] initWithRaid:encounter.raid boss:encounter.boss andPlayer:basicPlayer];
        [pbs setLevelNumber:level];
        if ([Divinity isDivinityUnlocked]){
            [basicPlayer setDivinityConfig:[Divinity localDivinityConfig]];
        }
        [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInR transitionWithDuration:1.0 scene:pbs]];
        [pbs release];

    }
    [basicPlayer release];
}

- (void)beginEndlessVoidEncounter:(id)sender{
    Encounter *encounter = [Encounter survivalEncounterIsMultiplayer:NO];
    Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
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
    [basicPlayer release];

}

-(void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInL transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}


@end

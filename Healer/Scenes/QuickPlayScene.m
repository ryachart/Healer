//
//  QuickPlayScene.m
//  Healer
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QuickPlayScene.h"
#import "PersistantDataManager.h"
#import "PreBattleScene.h"
#import "HealerStartScene.h"
#import "Encounter.h"
#import "Shop.h"
#import "BackgroundSprite.h"
#import "Divinity.h"

#define NUM_ENCOUNTERS 18

@interface QuickPlayScene ()
@property (assign) CCMenu *menu;

- (void)beginGameWithSelectedLevel:(id)sender;
- (void)back;
- (void)beginEndlessVoidEncounter:(id)sender;

@end

@implementation QuickPlayScene
@synthesize menu;
-(id)init{
    if (self = [super init]){
#if TARGET_IPHONE_SIMULATOR
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:100] forKey:PlayerHighestLevelCompleted];
#endif
        [self addChild:[[[BackgroundSprite alloc] initWithAssetName:@"wood-bg-ipad"] autorelease]];
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
        [self.menu setPosition:ccp([CCDirector sharedDirector].winSize.width /2, [CCDirector sharedDirector].winSize.height * .63)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self.menu alignItemsInRows:[NSNumber numberWithInt:NUM_ENCOUNTERS/2],[NSNumber numberWithInt:(int)round(NUM_ENCOUNTERS/2.0)], nil];
        [self addChild:self.menu];
        
        
        CCMenu *backButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Back" fontName:@"Arial" fontSize:24.0] target:self selector:@selector(back)], nil];
        [backButton setPosition:CGPointMake(30, [CCDirector sharedDirector].winSize.height * .9)];
        [backButton setColor:ccWHITE];
        [self addChild:backButton];
        
        CCMenu *endlessButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"The Endless Void" fontName:@"Arial" fontSize:28.0] target:self selector:@selector(beginEndlessVoidEncounter:)], nil];
        [endlessButton setRotation:-45.0];
        [endlessButton setPosition:CGPointMake(-275, [CCDirector sharedDirector].winSize.height * .45)];
        [endlessButton setColor:ccWHITE];
        [self addChild:endlessButton];
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
    [[CCDirector sharedDirector] replaceScene:[[[HealerStartScene alloc] init] autorelease]];
}


@end

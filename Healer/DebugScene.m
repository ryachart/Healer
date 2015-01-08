//
//  DebugScene.m
//  Healer
//
//  Created by Ryan Hart on 7/21/14.
//  Copyright (c) 2014 Ryan Hart Games. All rights reserved.
//

#import "DebugScene.h"
#import "cocos2d.h"
#import "BasicButton.h"
#import "HealerStartScene.h"
#import "Raid.h"
#import "Encounter.h"
#import "PreBattleScene.h"
#import "PlayerDataManager.h"
#import "Enemy.h"
#import "Player.h"

@implementation DebugScene

- (id)init
{
    if (self = [super init]) {
        CCMenu *backMenu = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backMenu setPosition:BACK_BUTTON_POS];
        [self addChild:backMenu];
        
        CCMenuItem *debugEncounter = [BasicButton basicButtonWithTarget:self andSelector:@selector(beginDebugEncounter) andTitle:@"Encounter"];
        CCMenu *debugMenu = [CCMenu menuWithItems:debugEncounter, nil];
        [self addChild:debugMenu];
    }
    return self;
}

- (void)beginDebugEncounter
{
    Raid *basicRaid = [[[Raid alloc] init] autorelease];
    NSMutableArray *enemies = [NSMutableArray arrayWithCapacity:3];
    NSInteger numArcher = 0;
    NSInteger numGuardian = 0;
    NSInteger numChampion = 0;
    NSInteger numWarlock = 0;
    NSInteger numWizard = 0;
    NSInteger numBerserker = 0;
    
    numWizard = 3;
    numWarlock = 3;
    numArcher = 3;
    numBerserker = 5;
    numChampion = 4;
    numGuardian = 1;
    
    for (int i = 0; i < numWizard; i++){
        [basicRaid addRaidMember:[Wizard defaultWizard]];
    }
    for (int i = 0; i < numArcher; i++){
        [basicRaid addRaidMember:[Archer defaultArcher]];
    }
    for (int i = 0; i < numWarlock; i++){
        [basicRaid addRaidMember:[Warlock defaultWarlock]];
    }
    for (int i = 0; i < numBerserker; i++){
        [basicRaid addRaidMember:[Berserker defaultBerserker]];
    }
    for (int i = 0; i < numChampion; i++){
        [basicRaid addRaidMember:[Champion defaultChampion]];
    }
    for (int i = 0; i < numGuardian; i++){
        [basicRaid addRaidMember:[Guardian defaultGuardian]];
    }
    
    NSString *bossKey = @"testBoss";
    NSString *info = @"The test boss";
    NSString *title = @"Test Boss";
    
    TestBoss *boss = [TestBoss defaultBoss];
    [enemies addObject:boss];
    
    Encounter *encToReturn = [[Encounter alloc] initWithRaid:basicRaid enemies:enemies andSpells:nil andEncounterType:EncounterTypeTest];
    [encToReturn setInfo:info];
    [encToReturn setTitle:title];
    //[encToReturn setLevelNumber:999];
    [encToReturn setBossKey:bossKey];
    
    Player* player = [PlayerDataManager playerFromLocalPlayer];
    PreBattleScene *pbs = [[PreBattleScene alloc] initWithEncounter:encToReturn andPlayer:player];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:pbs]];
    
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}
@end

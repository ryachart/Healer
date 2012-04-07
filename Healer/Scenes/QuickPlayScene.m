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
@interface QuickPlayScene ()
@property (retain) CCMenuItemLabel *easyModeButton;
@property (retain) CCMenuItemLabel *mediumModeButton;
@property (retain) CCMenuItemLabel *hardModeButton;
@property (retain) CCMenuItemLabel *extremeModeButton;
@property (retain) CCMenu *menu;

-(void)beginGameWithSelectedLevel:(id)sender;

-(void)back;

@end

@implementation QuickPlayScene
@synthesize easyModeButton;
@synthesize mediumModeButton;
@synthesize hardModeButton;
@synthesize extremeModeButton;
@synthesize menu;
-(id)init{
    if (self = [super init]){
#if DEBUG
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:100] forKey:PlayerHighestLevelCompleted];
#endif
        self.menu = [CCMenu menuWithItems:nil];
        for (int i = 0; i < 8; i++){
            CCMenuItemLabel *levelButton = [[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:[NSString stringWithFormat:@"Level %i", i + 1] fontName:@"Arial" fontSize:32] target: self selector:@selector(beginGameWithSelectedLevel:)];
            levelButton.tag = i +1;
            if (i > ([[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue] )){
                levelButton.opacity = 125;
            }
            [self.menu addChild:levelButton];
        }
        [self.menu setPosition:ccp([CCDirector sharedDirector].winSize.width /2, [CCDirector sharedDirector].winSize.height / 2)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self.menu alignItemsInRows:[NSNumber numberWithInt:8]/*,[NSNumber numberWithInt:10]*/, nil];
        [self addChild:self.menu];
        
        
        CCMenu *backButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Back" fontName:@"Arial" fontSize:24.0] target:self selector:@selector(back)], nil];
        [backButton setPosition:CGPointMake(30, [CCDirector sharedDirector].winSize.height * .9)];
        [backButton setColor:ccWHITE];
        [self addChild:backButton];
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
    
    Raid *basicRaid = nil;
    Player *basicPlayer = nil;
    Boss *basicBoss = nil;
    
    if (level == 1){
        basicRaid = [[Raid alloc] init];
        basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        basicBoss = [Ghoul defaultBoss];
        
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], nil]];
        
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }

    }
    
    if (level == 2){
        basicRaid = [[Raid alloc] init];
        basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        basicBoss = [CorruptedTroll defaultBoss];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], nil]];
        
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
    }
    
    if (level == 3){
        basicRaid = [[Raid alloc] init];
        basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        basicBoss = [Drake defaultBoss];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil]];
        
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Guardian  defaultGuardian]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
    }
    
    if (level == 4){
        basicRaid = [[Raid alloc] init];
        basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        basicBoss = [Trulzar defaultBoss];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [Purify defaultSpell], nil]];
        
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
    }
    
    if (level == 5){
        basicRaid = [[Raid alloc] init];
        basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        basicBoss = [DarkCouncil defaultBoss];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell],[Purify defaultSpell], [Regrow defaultSpell], nil]];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
    }
    
    if (level == 6){
        basicRaid = [[Raid alloc] init];
        basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        basicBoss = [PlaguebringerColossus defaultBoss];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [ForkedHeal defaultSpell], [Regrow defaultSpell], nil]];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
    }
    
    if (level == 7){
        basicRaid = [[Raid alloc] init];
        basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        basicBoss = [SporeRavagers defaultBoss];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [HealingBurst defaultSpell], [Regrow defaultSpell], nil]];
        
        for (int i = 0; i < 7; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
    }
    
    if (level == 8){
        basicRaid = [[Raid alloc] init];
        basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        basicBoss = [MischievousImps defaultBoss];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [Barrier defaultSpell], [HealingBurst defaultSpell], [Purify defaultSpell], nil]];
        
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
    }
    
    if (basicBoss && basicPlayer && basicRaid){
        
        PreBattleScene *pbs = [[PreBattleScene alloc] initWithRaid:basicRaid boss:basicBoss andPlayer:basicPlayer];
        [pbs setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:pbs]];
        [pbs release];

    }
    [basicPlayer release];
    [basicRaid release];
}

-(void)back
{
    [[CCDirector sharedDirector] replaceScene:[[[HealerStartScene alloc] init] autorelease]];
}


- (void)dealloc {
    [super dealloc];
}


@end

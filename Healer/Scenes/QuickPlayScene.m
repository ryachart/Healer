//
//  QuickPlayScene.m
//  Healer
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QuickPlayScene.h"
#import "PersistantDataManager.h"

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
        self.menu = [CCMenu menuWithItems:nil];
        for (int i = 0; i < 20; i++){
            CCMenuItemLabel *levelButton = [[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:[NSString stringWithFormat:@"Level %i", i + 1] fontName:@"Arial" fontSize:32] target: self selector:@selector(beginGameWithSelectedLevel:)];
            levelButton.tag = i +1;
            if (i > ([[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue] )){
                levelButton.opacity = 125;
            }
            [self.menu addChild:levelButton];
        }
        [self.menu setPosition:ccp([CCDirector sharedDirector].winSize.width /2, [CCDirector sharedDirector].winSize.height / 2)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self.menu alignItemsInRows:[NSNumber numberWithInt:10],[NSNumber numberWithInt:10], nil];
        [self addChild:self.menu];
    }
    return self;
}


-(void)beginGameWithSelectedLevel:(CCMenuItemLabel*)sender{
    int level = sender.tag;
    srand(time(NULL));
    
    int i = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue];
    
    if (i + 1 < level){
        return;
    }
    
    if (level == 1){
        Raid *basicRaid = [[Raid alloc] init];
        Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
        Boss *basicBoss = [[Boss alloc] initWithHealth:7500 damage:12 targets:1 frequency:1.5 andChoosesMT:NO];
        [basicBoss setTitle:@"Zombie"];
        
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], nil]];
        
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Troll defaultTroll]];
        }
        GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:basicRaid boss:basicBoss andPlayer:basicPlayer];
        [gps setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
        [gps release];
        [basicBoss release];
        [basicPlayer release];
        [basicRaid release];
    }
    
    if (level == 2){
        Raid *basicRaid = [[Raid alloc] init];
        Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
        Boss *basicBoss = [[Boss alloc] initWithHealth:12000 damage:12 targets:1 frequency:1.4 andChoosesMT:NO];
        [basicBoss setTitle:@"Zombie Wizard"];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], nil]];
        
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Troll defaultTroll]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Ogre defaultOgre]];
        }
        GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:basicRaid boss:basicBoss andPlayer:basicPlayer];
        [gps setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
        [gps release];
        [basicBoss release];
        [basicPlayer release];
        [basicRaid release];
    }
    
    if (level == 3){
        Raid *basicRaid = [[Raid alloc] init];
        Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
        Boss *basicBoss = [[Boss alloc] initWithHealth:20000 damage:8 targets:4 frequency:.8 andChoosesMT:NO];
        [basicBoss setTitle:@"Zombie Horde"];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], nil]];
        
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Troll defaultTroll]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Ogre defaultOgre]];
        }
        
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Witch defaultWitch]];
        }
        GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:basicRaid boss:basicBoss andPlayer:basicPlayer];
        [gps setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
        [gps release];
        [basicBoss release];
        [basicPlayer release];
        [basicRaid release];
    }
    
    if (level == 4){
        Raid *basicRaid = [[Raid alloc] init];
        Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
        Boss *basicBoss = [[Boss alloc] initWithHealth:50000 damage:50 targets:2 frequency:5.0 andChoosesMT:NO];
        [basicBoss setTitle:@"Knights of Fargore"];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil]];
        
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Troll defaultTroll]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Ogre defaultOgre]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Witch defaultWitch]];
        }
        GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:basicRaid boss:basicBoss andPlayer:basicPlayer];
        [gps setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
        [gps release];
        [basicBoss release];
        [basicPlayer release];
        [basicRaid release];
    }
    
    if (level == 5){
        Raid *basicRaid = [[Raid alloc] init];
        Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
        Boss *basicBoss = [[Boss alloc] initWithHealth:75000 damage:60 targets:3 frequency:4.5 andChoosesMT:NO];
        [basicBoss setTitle:@"Fargore General"];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil]];
        
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Troll defaultTroll]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Ogre defaultOgre]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Witch defaultWitch]];
        }
        GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:basicRaid boss:basicBoss andPlayer:basicPlayer];
        [gps setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
        [gps release];
        [basicBoss release];
        [basicPlayer release];
        [basicRaid release];
    }
    
    if (level == 6){
        Raid *basicRaid = [[Raid alloc] init];
        Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
        Boss *basicBoss = [[Boss alloc] initWithHealth:50000 damage:50 targets:5 frequency:5.0 andChoosesMT:NO];
        [basicBoss setTitle:@"Drake of Thelia"];
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil]];
        
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Troll defaultTroll]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Ogre defaultOgre]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Witch defaultWitch]];
        }
        GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:basicRaid boss:basicBoss andPlayer:basicPlayer];
        [gps setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
        [gps release];
        [basicBoss release];
        [basicPlayer release];
        [basicRaid release];
    }
}

-(void)back
{
	//[self.navigationController popViewControllerAnimated:YES];
}


- (void)dealloc {
    [super dealloc];
}


@end

//
//  QuickPlayScene.m
//  Healer
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QuickPlayScene.h"

@interface QuickPlayScene ()
@property (retain) CCMenuItemLabel *easyModeButton;
@property (retain) CCMenuItemLabel *mediumModeButton;
@property (retain) CCMenuItemLabel *hardModeButton;
@property (retain) CCMenuItemLabel *extremeModeButton;
@property (retain) CCMenu *menu;

-(void)startEasyGame;
-(void)startMediumGame;
-(void)startHardGame;
-(void)startExtremeGame;
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
        self.easyModeButton = [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Easy Game" fontName:@"Arial" fontSize:32] target:self selector:@selector(startEasyGame)] autorelease];
        self.mediumModeButton= [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Medium Game" fontName:@"Arial" fontSize:32] target:self selector:@selector(startMediumGame)] autorelease];
        [self.mediumModeButton setPosition:ccp(0, 50)];
        self.hardModeButton= [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Hard Game" fontName:@"Arial" fontSize:32] target:self selector:@selector(startHardGame)] autorelease];
        [self.hardModeButton setPosition:ccp(0, 100)];
        self.extremeModeButton= [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Extreme Game" fontName:@"Arial" fontSize:32] target:self selector:@selector(startExtremeGame)] autorelease];
        [self.extremeModeButton  setPosition:ccp(0, 150)];
        
        
        self.menu = [CCMenu menuWithItems:self.easyModeButton, self.mediumModeButton, self.hardModeButton, self.extremeModeButton, nil];
        
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .4, winSize.height * 1/3)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu];
    }
    return self;
}

-(void)startEasyGame
{
	srand(time(NULL));
	
	Raid* demoRaid = [[Raid alloc] init];
	Player* demoPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
	Giant* demoBoss = 	[Giant defaultBoss];

	[demoPlayer setActiveSpells:[NSArray arrayWithObjects:[SurgingGrowth defaultSpell], [RoarOfLife defaultSpell], [FieryAdrenaline defaultSpell], [WoundWeaving defaultSpell], nil]];
	
	for (int i = 0; i < 5; i++){
		[demoRaid addRaidMember:[Witch defaultWitch]];
	}
	for (int i = 0; i < 10; i++){
		[demoRaid addRaidMember:[Ogre defaultOgre]];
	}
	for (int i =0; i < 10; i++){
		[demoRaid addRaidMember:[Troll defaultTroll]];
	}
	
	
	InGameViewController* demoGameVC = [[InGameViewController alloc] initWithNibName:@"InGameViewController" bundle:nil];
	[demoGameVC readyWithRaid:demoRaid boss:demoBoss andPlayer:demoPlayer];
	
	//[self.navigationController pushViewController:demoGameVC animated:YES];
	
	
}

-(void)startMediumGame
{
	Raid* demoRaid = [[Raid alloc] init];
	Player* demoPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
	Dragon* demoBoss = 	[Dragon defaultBoss];
	[demoPlayer setActiveSpells:[NSArray arrayWithObjects:[TwoWinds defaultSpell], [SymbioticConnection defaultSpell], [GloriousBeam defaultSpell], nil]];
	
	for (int i = 0; i < 7; i++){
		[demoRaid addRaidMember:[Witch defaultWitch]];
	}
	for (int i = 0; i < 9; i++){
		[demoRaid addRaidMember:[Ogre defaultOgre]];
	}
	for (int i =0; i < 9; i++){
		[demoRaid addRaidMember:[Troll defaultTroll]];
	}
	
	
	InGameViewController* demoGameVC = [[InGameViewController alloc] initWithNibName:@"InGameViewController" bundle:nil];
	[demoGameVC readyWithRaid:demoRaid boss:demoBoss andPlayer:demoPlayer];
	
	//[self.navigationController pushViewController:demoGameVC animated:YES];
	
}

-(void)startHardGame
{
	Raid* demoRaid = [[Raid alloc] init];
	Player* demoPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
	Hydra* demoBoss = 	[Hydra defaultBoss];

	[demoPlayer setActiveSpells:[NSArray arrayWithObjects:[QuickHeal defaultSpell], [SuperHeal defaultSpell], [ForkedHeal defaultSpell], [UnleashedNature defaultSpell], nil]];
	
	for (int i = 0; i < 9; i++){
		[demoRaid addRaidMember:[Witch defaultWitch]];
	}
	for (int i = 0; i < 8; i++){
		[demoRaid addRaidMember:[Ogre defaultOgre]];
	}
	for (int i =0; i < 8; i++){
		[demoRaid addRaidMember:[Troll defaultTroll]];
	}
	
	
	InGameViewController* demoGameVC = [[InGameViewController alloc] initWithNibName:@"InGameViewController" bundle:nil];
	[demoGameVC readyWithRaid:demoRaid boss:demoBoss andPlayer:demoPlayer];
	
	//[self.navigationController pushViewController:demoGameVC animated:YES];
	
}

-(void)startExtremeGame
{
	Raid* demoRaid = [[Raid alloc] init];
	Player* demoPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
	ChaosDemon* demoBoss = 	[ChaosDemon defaultBoss];
	
	[demoPlayer setActiveSpells:[NSArray arrayWithObjects:[QuickHeal defaultSpell], [SuperHeal defaultSpell], [ForkedHeal defaultSpell],[SurgeOfLife defaultSpell], nil]];
	
	for (int i = 0; i < 9; i++){
		[demoRaid addRaidMember:[Witch defaultWitch]];
	}
	for (int i = 0; i < 8; i++){
		[demoRaid addRaidMember:[Ogre defaultOgre]];
	}
	for (int i =0; i < 8; i++){
		[demoRaid addRaidMember:[Troll defaultTroll]];
	}
	
	
	InGameViewController* demoGameVC = [[InGameViewController alloc] initWithNibName:@"InGameViewController" bundle:nil];
	[demoGameVC readyWithRaid:demoRaid boss:demoBoss andPlayer:demoPlayer];
	
	//[self.navigationController pushViewController:demoGameVC animated:YES];
	
}

-(void)back
{
	//[self.navigationController popViewControllerAnimated:YES];
	
}


- (void)dealloc {
    [super dealloc];
}


@end

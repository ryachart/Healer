    //
//  QuickPlayViewController.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QuickPlayViewController.h"


@implementation QuickPlayViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

-(IBAction)startEasyGame
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
	
	[self.navigationController pushViewController:demoGameVC animated:YES];
	
	
}

-(IBAction)startMediumGame
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
	
	[self.navigationController pushViewController:demoGameVC animated:YES];
	
}

-(IBAction)startHardGame
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
	
	[self.navigationController pushViewController:demoGameVC animated:YES];
	
}

-(IBAction)startExtremeGame
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
	
	[self.navigationController pushViewController:demoGameVC animated:YES];
	
}

-(IBAction)back
{
	[self.navigationController popViewControllerAnimated:YES];
	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

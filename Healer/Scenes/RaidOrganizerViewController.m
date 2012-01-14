    //
//  RaidOrganizerViewController.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidOrganizerViewController.h"
#import "GamePlayScene.h"

@implementation RaidOrganizerViewController
@synthesize spotsRemainingLabel;
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	theRaid = [[Raid alloc] init];
	[raidView spawnRects];
	[spotsRemainingLabel setText:[NSString stringWithFormat:@"Spots: %i", spotsRemaining]];
}


-(void)readyWithEncounter:(Encounter*)encounter andSelectedSpells:(NSArray*)selSpells
{
	
	selectedEncounter = encounter;
	selectedSpells = selSpells;
	
	spotsRemaining = [encounter raidSize];
	
}

-(IBAction)encounterStart
{
	Player* thePlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
	[thePlayer setActiveSpells:selectedSpells];
	
	/*Raid *theRaid = [[Raid alloc] init];
	
	
	
	for (int i = 0; i < [selectedEncounter numWitches]; i++){
		[theRaid addRaidMember:[Witch defaultWitch]];
	}
	for (int i = 0; i < [selectedEncounter numOgres]; i++){
		[theRaid addRaidMember:[Ogre defaultOgre]];
	}
	for (int i =0; i < [selectedEncounter numTrolls]; i++){
		[theRaid addRaidMember:[Troll defaultTroll]];
	}
	*/
	
	
	GamePlayScene *igVC = [[GamePlayScene alloc] initWithRaid:theRaid boss:[selectedEncounter theBoss] andPlayer:thePlayer];
    [thePlayer release];
	[igVC setActiveEncounter:selectedEncounter];
//	[igVC setViewControllerToBecome:[vcs objectAtIndex:[vcs indexOfObject:self]-1]];
	
	//[thePlayer release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


-(IBAction)addWitch{
	if ([[theRaid raidMembers] count] == [selectedEncounter raidSize])
	{
		UIAlertView *fullRaid = [[UIAlertView alloc] initWithTitle:@"Full Raid" message:@"Your Raid is full" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[fullRaid show];
		[fullRaid release];
		return;
	}
	
	if ([theRaid classCount:RaidMemberTypeWitch] < [selectedEncounter numWitches]){
		RaidMember *rmToAdd = [Witch defaultWitch];
		[theRaid addRaidMember:rmToAdd];
		RaidMemberHealthView *rmhv = [[RaidMemberHealthView alloc] initWithFrame:[raidView vendNextUsableRect]];
		//NSLog(@"Vended Rect: %1.1f", (float)CGRectGetWidth([rmhv frame]));
		[rmhv setMemberData:rmToAdd];
		[raidView addRaidMemberHealthView:rmhv];
		spotsRemaining--;
		[spotsRemainingLabel setText:[NSString stringWithFormat:@"Spots: %i", spotsRemaining]];
	}
}
-(IBAction)removeWitch{
	if ([theRaid classCount:RaidMemberTypeWitch] > 0){
		
	}
}
-(IBAction)addTroll{
	if ([[theRaid raidMembers] count] == [selectedEncounter raidSize])
	{
		UIAlertView *fullRaid = [[UIAlertView alloc] initWithTitle:@"Full Raid" message:@"Your Raid is full" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[fullRaid show];
		[fullRaid release];
		return;
	}
	
	if ([theRaid classCount:RaidMemberTypeTroll] < [selectedEncounter numTrolls]){
		RaidMember *rmToAdd = [Troll defaultTroll];
		[theRaid addRaidMember:rmToAdd];
		RaidMemberHealthView *rmhv = [[RaidMemberHealthView alloc] initWithFrame:[raidView vendNextUsableRect]];
		//NSLog(@"Vended Rect: %1.1f", (float)CGRectGetWidth([rmhv frame]));
		[rmhv setMemberData:rmToAdd];
		[raidView addRaidMemberHealthView:rmhv];
		spotsRemaining--;
		[spotsRemainingLabel setText:[NSString stringWithFormat:@"Spots: %i", spotsRemaining]];
	}
}
-(IBAction)removeTroll{
	if ([theRaid classCount:RaidMemberTypeTroll] > 0){
		
	}
}
-(IBAction)addOgre{
	if ([[theRaid raidMembers] count] == [selectedEncounter raidSize])
	{
		UIAlertView *fullRaid = [[UIAlertView alloc] initWithTitle:@"Full Raid" message:@"Your Raid is full" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[fullRaid show];
		[fullRaid release];
		return;
	}
	
	if ([theRaid classCount:RaidMemberTypeOgre] < [selectedEncounter numOgres]){
		RaidMember *rmToAdd = [Ogre defaultOgre];
		[theRaid addRaidMember:rmToAdd];
		RaidMemberHealthView *rmhv = [[RaidMemberHealthView alloc] initWithFrame:[raidView vendNextUsableRect]];
		//NSLog(@"Vended Rect: %1.1f", (float)CGRectGetWidth([rmhv frame]));
		[rmhv setMemberData:rmToAdd];
		[raidView addRaidMemberHealthView:rmhv];
		spotsRemaining--;
		[spotsRemainingLabel setText:[NSString stringWithFormat:@"Spots: %i", spotsRemaining]];
	}
}
-(IBAction)removeOgre{
	if ([theRaid classCount:RaidMemberTypeOgre] > 0){
		
	}
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

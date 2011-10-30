    //
//  CharacterOrganizerViewController.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CharacterOrganizerViewController.h"
#import "RaidOrganizerViewController.h"

@implementation CharacterOrganizerViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

-(void)viewDidAppear:(BOOL)animated{
	nextEnc = [Encounter nextEncounter:[characterShowing encountersCompleted] andClass:[characterShowing characterClass]];

	[self reloadData];
}

-(void)reloadData{
	[spellDescription setText:@""];
	[encounterDescription setText:@""];
	[spellsTable reloadData];
	[encountersTable reloadData];
}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	PersistantDataManager* dataMan = [PersistantDataManager sharedInstance];
	characterShowing = [dataMan selectedCharacter];
	
	nextEnc = [Encounter nextEncounter:[characterShowing encountersCompleted] andClass:[characterShowing characterClass]];
	
	spellSet = [[NSMutableArray alloc] initWithCapacity:MAX_SPELLS_ACTIVE];
}


-(IBAction)back
{
	[self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)addSpell
{
	if ([spellsTable indexPathForSelectedRow] != nil){
		NSString *selectedSpellTitle = [[[spellsTable cellForRowAtIndexPath:[spellsTable indexPathForSelectedRow]] textLabel] text];
		for (Spell* spel in spellSet){
			if ([[spel title] isEqualToString:selectedSpellTitle])
				return;
		}
		[spellSet addObject:[Spell spellFromTitle:selectedSpellTitle]];
		[selSpellView addSpell:[Spell spellFromTitle:selectedSpellTitle]];
		NSLog(@"Adding %@", selectedSpellTitle);
	}
}

-(IBAction)assembleRaid
{
	if ([spellSet count] == 0){
		NSLog(@"No spells");
		UIAlertView *noSpellsChosenAlert = [[UIAlertView alloc] initWithTitle:@"No spells!" message:@"Add some spells" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[noSpellsChosenAlert show];
		[noSpellsChosenAlert release];
		return;
	}
	
	if ([encountersTable indexPathForSelectedRow] == nil){
		NSLog(@"No encounter");
		UIAlertView *noEncounterChosenAlert = [[UIAlertView alloc] initWithTitle:@"No encounter!" message:@"Pick an Encounter!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[noEncounterChosenAlert show];
		[noEncounterChosenAlert release];
		return;
	}
	
	RaidOrganizerViewController *rOrgVC = [[RaidOrganizerViewController alloc] initWithNibName:@"RaidOrganizerViewController" bundle:nil];
	NSString *selectedEncounter = [[[encountersTable cellForRowAtIndexPath:[encountersTable indexPathForSelectedRow]] textLabel] text];
	[rOrgVC readyWithEncounter:[Encounter encounterForTitle:selectedEncounter] andSelectedSpells:spellSet];
	 
	[self.navigationController pushViewController:rOrgVC animated:YES];
	
	
}

#pragma mark -
#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	
	if (tableView == spellsTable){
		[spellDescription setText:[[Spell spellFromTitle:[[characterShowing knownSpells] objectAtIndex:row]] description]];
	}
	
	if (tableView == encountersTable){
		if (row == [[characterShowing encountersCompleted] count]-1)
		{
			[encounterDescription setText:[nextEnc description]];
		}
		else{
			[encounterDescription setText:[[Encounter encounterForTitle:[[characterShowing encountersCompleted] objectAtIndex:row+1]] description]];
			//[[thisCell textLabel] setText:[[characterShowing encountersCompleted] objectAtIndex:row+1]];
		}
	}
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == spellsTable){
		return 50;
	}
	
	if (tableView == encountersTable){
		return 50;
	}
	
	return 0.0;
}
#pragma mark -
#pragma mark UITableViewDatasource Methods

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section{
	if (table == spellsTable){
		return [[characterShowing knownSpells] count];
	}
	
	if (table == encountersTable){
		return [[characterShowing encountersCompleted] count];
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *thisCell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,200,100) reuseIdentifier:@"Cell"];
	NSInteger row = [indexPath row];
	
	if (tableView == spellsTable){
		[[thisCell textLabel] setText:[[characterShowing knownSpells] objectAtIndex:row]];
	}
	
	if (tableView == encountersTable){
		if (row == [[characterShowing encountersCompleted] count]-1)
		{
			[[thisCell textLabel] setText:[nextEnc title]];
		}
		else{
			[[thisCell textLabel] setText:[[characterShowing encountersCompleted] objectAtIndex:row+1]];
		}
	}
	
	return thisCell;
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 0.0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.0;
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

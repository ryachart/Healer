    //
//  CharacterSelectionViewController.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CharacterSelectionViewController.h"
#import "PersistantDataManager.h"
#import "Character.h"
#import "CharacterOrganizerViewController.h"
#import "CreateNewCharacterViewController.h"
#import "CharacterSheetViewController.h"

@implementation CharacterSelectionViewController

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
	
	[self loadAllCharacters];

}

-(void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	
	[self loadAllCharacters];
}
-(void)loadAllCharacters
{
	[slot1 setTitle:@"Empty Slot" forState:UIControlStateNormal];
	[slot2 setTitle:@"Empty Slot" forState:UIControlStateNormal];
	[slot3 setTitle:@"Empty Slot" forState:UIControlStateNormal];
	[slot4 setTitle:@"Empty Slot" forState:UIControlStateNormal];
	[slot5 setTitle:@"Empty Slot" forState:UIControlStateNormal];
	
	//Load Characters and fill the slots
	PersistantDataManager *dataMan = [PersistantDataManager sharedInstance];
	
	for (int i=0; i < [[dataMan characters] count]; i++){
		Character* currentChar = [[dataMan characters] objectAtIndex:i];
		switch (i) {
			case 0:[slot1 setTitle:[currentChar name] forState:UIControlStateNormal];
				break;
			case 1:[slot2 setTitle:[currentChar name] forState:UIControlStateNormal];
				break;
			case 2:[slot3 setTitle:[currentChar name] forState:UIControlStateNormal];
				break;
			case 3:[slot4 setTitle:[currentChar name] forState:UIControlStateNormal];
				break;
			case 4:[slot5 setTitle:[currentChar name] forState:UIControlStateNormal];
				break;
			default:
				break;
		}
	}
}

-(IBAction)back
{
	[self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)slotSelected:(id)sender
{
	UIButton *sent = sender;
	
	PersistantDataManager *dataMan = [PersistantDataManager sharedInstance];
	
	if ([sent tag] < [[dataMan characters] count]){
		//We've selected a character
		[dataMan setSelectedCharacter:[[dataMan characters] objectAtIndex:[sent tag]]];
		CharacterSheetViewController *charOrg = [[CharacterSheetViewController alloc] initWithNibName:@"CharacterSheetViewController" bundle:nil];
		[self.navigationController pushViewController:charOrg animated:YES];
		[charOrg release];
		//[self.navigationController popViewControllerAnimated:NO];
	}
	else {
		CreateNewCharacterViewController *newCharVC = [[CreateNewCharacterViewController alloc] initWithNibName:@"CreateNewCharacterViewController" bundle:nil];
		
		[self.navigationController pushViewController:newCharVC animated:YES];
		[newCharVC release];
		//[self.navigationController popViewControllerAnimated:NO];
	}
	
}
-(IBAction)deletionSelected:(id)sender
{
	UIButton* sent = sender;
	PersistantDataManager *dataMan = [PersistantDataManager sharedInstance];
	
	switch (sent.tag){
		case 0:
			if (![[slot1 titleLabel].text isEqualToString:@"Empty Slot"]){
				[dataMan deleteCharacterWithName:[slot1 titleLabel].text];
				[self loadAllCharacters];
			}
			break;
		case 1:
			if (![[slot2 titleLabel].text isEqualToString:@"Empty Slot"]){
				[dataMan deleteCharacterWithName:[slot2 titleLabel].text];
				[self loadAllCharacters];
			}
			break;
		case 2:
			if (![[slot3 titleLabel].text isEqualToString:@"Empty Slot"]){
				[dataMan deleteCharacterWithName:[slot3 titleLabel].text];
				[self loadAllCharacters];
			}
			break;
		case 3:
			if (![[slot4 titleLabel].text isEqualToString:@"Empty Slot"]){
				[dataMan deleteCharacterWithName:[slot4 titleLabel].text];
				[self loadAllCharacters];
			}
			break;
		case 4:
			if (![[slot5 titleLabel].text isEqualToString:@"Empty Slot"]){
				[dataMan deleteCharacterWithName:[slot5 titleLabel].text];
				[self loadAllCharacters];
			}
			break;
		
	}
	
	
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

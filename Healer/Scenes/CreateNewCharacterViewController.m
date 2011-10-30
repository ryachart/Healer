    //
//  CreateNewCharacterViewController.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CreateNewCharacterViewController.h"
#import "PersistantDataManager.h"

@implementation CreateNewCharacterViewController

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
	
	selectedClass = CharacterClassShaman;
	
	[classDescription setText:ShamanDescription];
	
	
}


-(IBAction)classValueChanged:(id)sender
{
	UISegmentedControl *seg = sender;
	
	switch (seg.selectedSegmentIndex){
		case 0:
			selectedClass = CharacterClassShaman;
			[classDescription setText:ShamanDescription];
			break;
		case 1:
			selectedClass = CharacterClassRitualist;
			[classDescription setText:RitualistDescription];
			break;
		case 2:
			selectedClass = CharacterClassSeer;
			[classDescription setText:SeerDescription];
			break;
	}
	
}
-(IBAction)createButtonSelected
{
	if ([[nameField text] isEqualToString:@""]){
		UIAlertView *mustNameAlert = [[UIAlertView alloc] initWithTitle:@"No Name" message:@"You must name your character" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[mustNameAlert show];
		[mustNameAlert release];
	}
	else {
		PersistantDataManager *dataMan = [PersistantDataManager sharedInstance];
		if ([dataMan canAddCharacterWithName:[nameField text]]){
			[dataMan addNewCharacterWithName:[nameField text] andClass:selectedClass];
			[self.navigationController popViewControllerAnimated:YES];
		}
		else{
			UIAlertView *mustNameAlert = [[UIAlertView alloc] initWithTitle:@"Bad name" message:@"You can't name it that!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[mustNameAlert show];
			[mustNameAlert release];
		}
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

-(BOOL)textFieldShouldReturn:(UITextField*)theField{
	[theField resignFirstResponder];
	
	return YES;
}

- (void)dealloc {
    [super dealloc];
}


@end

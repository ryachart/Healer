    //
//  CharacterSheetViewController.m
//  RaidLeader
//
//  Created by Ryan Hart on 11/5/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import "CharacterSheetViewController.h"


@implementation CharacterSheetViewController

@synthesize cEquipView, cBagView, cActiveSpellView, cSpellView;
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	charInfoRect = [cEquipView frame];
	cSpellView = [[CharacterSpellView alloc] initWithFrame:charInfoRect];
	[self.view addSubview:cSpellView];
	[cSpellView setHidden:YES];
}



-(IBAction)switchCharInfo:(UISegmentedControl*)sender{
	switch ([sender selectedSegmentIndex]){
		case 0:
			cSpellView.hidden = YES;
			cEquipView.hidden = NO;
			break;
		case 1:
			cSpellView.hidden = NO;
			cEquipView.hidden = YES;
			break;
	}
}

-(IBAction)backClicked{
	[self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
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

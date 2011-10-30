//
//  CreateNewCharacterViewController.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataDefinitions.h"

 
@interface CreateNewCharacterViewController : UIViewController <UITextFieldDelegate> {
	IBOutlet UITextField *nameField;
	IBOutlet UISegmentedControl *classSelector;
	IBOutlet UIImageView *characterPicture;
	IBOutlet UITextView *classDescription;
	
	NSString *selectedClass;
}
-(IBAction)classValueChanged:(id)sender;

-(IBAction)createButtonSelected;
@end

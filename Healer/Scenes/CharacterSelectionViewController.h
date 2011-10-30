//
//  CharacterSelectionViewController.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CharacterSelectionViewController : UIViewController {
	IBOutlet UIButton *slot1;
	IBOutlet UIButton *slot2;
	IBOutlet UIButton *slot3;
	IBOutlet UIButton *slot4;
	IBOutlet UIButton *slot5;
}

-(IBAction)back;
-(IBAction)slotSelected:(id)sender;
-(IBAction)deletionSelected:(id)sender;
-(void)loadAllCharacters;
@end

//
//  CharacterOrganizerViewController.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Character.h"
#import "PersistantDataManager.h"
#import "Encounter.h"
#import "SelectedSpellView.h"

#define MAX_SPELLS_ACTIVE 4
@interface CharacterOrganizerViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {
	IBOutlet UITableView *spellsTable;
	IBOutlet UITableView *encountersTable;
	IBOutlet UITextView *spellDescription;
	IBOutlet UITextView *encounterDescription;
	IBOutlet SelectedSpellView* selSpellView;
	
	Character *characterShowing;
	Encounter *nextEnc;
	NSMutableArray *spellSet;
}
-(IBAction)back;
-(IBAction)addSpell;
-(IBAction)assembleRaid;
-(void)reloadData;
@end

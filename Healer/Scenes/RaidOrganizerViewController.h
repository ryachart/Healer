//
//  RaidOrganizerViewController.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Encounter.h"
#import "RaidView.h"
#import "Raid.h"
#import "RaidMember.h"
#import "RaidMemberHealthView.h"

@interface RaidOrganizerViewController : UIViewController {
	Encounter *selectedEncounter;
	NSArray *selectedSpells;
	
	IBOutlet RaidView *raidView;
	Raid *theRaid;
	
	IBOutlet UILabel *spotsRemainingLabel;
	NSInteger spotsRemaining;
}
@property (nonatomic, retain) IBOutlet UILabel *spotsRemainingLabel;

-(void)readyWithEncounter:(Encounter*)encounter andSelectedSpells:(NSArray*)selSpells;
-(IBAction)encounterStart;

-(IBAction)addWitch;
-(IBAction)removeWitch;
-(IBAction)addTroll;
-(IBAction)removeTroll;
-(IBAction)addOgre;
-(IBAction)removeOgre;
@end

//
//  InGameViewController.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameObjects.h"
#import "GameUserInterface.h"
#import "AudioController.h"
#import "Encounter.h"

@class Chargable;
/* This is the screen we see while involved in a raid */
@interface InGameViewController : UIViewController <RaidMemberHealthViewDelegate, PlayerSpellButtonDelegate, PlayerHealthViewDelegate, ChannelingDelegate> {
	NSTimer* gameLoopTimer;
	
	NSMutableDictionary *memberToHealthView;
	NSMutableArray *selectedRaidMembers;
	
	//Data Models
	Raid *raid;
	Boss *boss;
	Player *player;
	Encounter *activeEncounter;
	
	//GameNavigation
	UIViewController *viewControllerToBecome;
	
	//Interface Elements
	IBOutlet RaidView *raidView;
	IBOutlet BossHealthView *bossHealthView;
	IBOutlet PlayerCastBar *playerCastBar;
	IBOutlet PlayerHealthView *playerHealthView;
	IBOutlet PlayerEnergyView *playerEnergyView;
	IBOutlet PlayerSpellButton *spell1;
	IBOutlet PlayerSpellButton *spell2;
	IBOutlet PlayerSpellButton *spell3;
	IBOutlet PlayerSpellButton *spell4;
	IBOutlet PlayerMoveButton *playerMoveButton;
	IBOutlet UILabel *alertStatus;
}
@property (readwrite, retain) Encounter *activeEncounter;
@property (nonatomic, retain) UIViewController *viewControllerToBecome;
-(void)readyWithRaid:(Raid*)raidToUse boss:(Boss*)bossToUse andPlayer:(Player*)playerToUse;

-(void)gameEvent:(NSTimer*)timer;

-(void)thisMemberSelected:(RaidMemberHealthView*)hv;
-(void)thisMemberUnselected:(RaidMemberHealthView *)hv;
-(void)playerSelected:(PlayerHealthView *)hv;
-(void)playerUnselected:(PlayerHealthView *)hv;
-(void)spellButtonSelected:(PlayerSpellButton*)spell;
@end

//
//  CharacterSheetViewController.h
//  RaidLeader
//
//  Created by Ryan Hart on 11/5/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CharacterSheet.h"

@interface CharacterSheetViewController : UIViewController {
	IBOutlet UIButton *worldMapButton;
	IBOutlet UIButton *navigateBackButton;

	
	IBOutlet CharacterEquipmentView *cEquipView;
	IBOutlet CharacterActiveSpellView *cActiveSpellView;
	IBOutlet CharacterBagView *cBagView;
	CharacterSpellView *cSpellView;
	
	CGRect charInfoRect;

}
@property (nonatomic, retain) IBOutlet CharacterEquipmentView *cEquipView;
@property (nonatomic, retain) IBOutlet CharacterActiveSpellView *cActiveSpellView;
@property (nonatomic, retain) IBOutlet CharacterBagView *cBagView;
@property (nonatomic, retain) IBOutlet CharacterSpellView *cSpellView;

-(IBAction)switchCharInfo:(UISegmentedControl*)sender;
-(IBAction)backClicked;
@end

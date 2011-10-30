//
//  CharacterEquipmentView.h
//  RaidLeader
//
//  Created by Ryan Hart on 11/5/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemContainer.h"

@interface CharacterEquipmentView : UIView {
	ItemContainer *headSlot;
	ItemContainer *heldSlot;
	ItemContainer *handSlot;
	ItemContainer *chestSlot;
	ItemContainer *legSlot;
	ItemContainer *feetSlot;
}

@end

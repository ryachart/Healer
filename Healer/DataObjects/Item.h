//
//  Item.h
//  RaidLeader
//
//  Created by Ryan Hart on 11/6/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import "ItemCardView.h"


enum ItemSlotType {
	ItemSlotTypeHead,
	ItemSlotTypeChest,
	ItemSlotTypeHands,
	ItemSlotTypeLegs,
	ItemSlotTypeFeet,
	ItemSlotTypeHeld
};

typedef NSInteger ItemSlotType;

@interface Item : NSObject {
	NSString *name;
}
@property (nonatomic, retain) NSString *name;
- (id)initAsItemWithName:(NSString*)named;
-(ItemCardView*)itemCardViewForItem;
@end

//
//  ItemContainer.h
//  RaidLeader
//
//  Created by Ryan Hart on 11/6/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item.h"
#import "Container.h"

@interface ItemContainer : UIView <Container> {
	Item *item;
	ItemSlotType containerType;
	NSString *name;
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) Item *item;
@property (readwrite) ItemSlotType containerType;

- (id)initWithFrame:(CGRect)frame andName:(NSString*)title;

@end

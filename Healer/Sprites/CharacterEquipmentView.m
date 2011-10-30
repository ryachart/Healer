//
//  CharacterEquipmentView.m
//  RaidLeader
//
//  Created by Ryan Hart on 11/5/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import "CharacterEquipmentView.h"


@implementation CharacterEquipmentView


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.

    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
	self = [super initWithCoder:aDecoder];
	if (self){
		CGFloat width = CGRectGetWidth(self.frame);
		CGFloat height = CGRectGetHeight(self.frame);
		
		CGRect headRect = CGRectMake(width*.4, 0, width * .2, height*.2);
		CGRect chestRect = CGRectMake(0, height*.4, width*.2, height*.2);
		CGRect handsRect = CGRectMake(width*.8, height*.4, width * .2, height*.2);
		CGRect legsRect = CGRectMake(width*.8, height*.6, width * .2, height*.2);
		CGRect feetRect = CGRectMake(0, height*.6, width * .2, height * .2);
		CGRect heldRect = CGRectMake(width*.4, height*.8, width *.2, height * .2);
		
		headSlot = [[ItemContainer alloc] initWithFrame:headRect andName:@"Head"];
		[headSlot setContainerType:ItemSlotTypeHead];
		
		chestSlot = [[ItemContainer alloc] initWithFrame:chestRect andName:@"Chest"];
		[chestSlot setContainerType:ItemSlotTypeChest];
		
		handSlot = [[ItemContainer alloc] initWithFrame:handsRect andName:@"Hands"];
		[handSlot setContainerType:ItemSlotTypeHands];
		
		legSlot = [[ItemContainer alloc] initWithFrame:legsRect andName:@"Legs"];
		[legSlot setContainerType:ItemSlotTypeLegs];
		
		feetSlot = [[ItemContainer alloc] initWithFrame:feetRect andName:@"Feet"];
		[feetSlot setContainerType:ItemSlotTypeFeet];
		
		heldSlot = [[ItemContainer alloc] initWithFrame:heldRect andName:@"Held"];
		[heldSlot setContainerType:ItemSlotTypeHeld];
		
		[self addSubview:headSlot];
		[self addSubview:chestSlot];
		[self addSubview:handSlot];
		[self addSubview:legSlot];
		[self addSubview:feetSlot];
		[self addSubview:heldSlot];
		
		
		
	}
	return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	NSLog(@"Begins");
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	NSLog(@"Moved");
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	NSLog(@"Ended");
}

- (void)dealloc {
    [super dealloc];
}


@end

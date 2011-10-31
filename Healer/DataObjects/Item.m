//
//  Item.m
//  RaidLeader
//
//  Created by Ryan Hart on 11/6/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import "Item.h"
#import "GameInfo.h"

@implementation Item

@synthesize name;

- (id)initAsItemWithName:(NSString*)named{
	self = [super init];
	if (self){
		name = named;
	}
	return self;
}

-(ItemCardView*)itemCardViewForItem{
	
	//Configure the card based on graphical information described in the item database
	
	ItemCardView *itemCardView = [[ItemCardView	alloc] initWithFrame:CGRectMake(0,0, 100, 100)];
	[itemCardView setBackgroundColor:[UIColor blueColor]];
	[itemCardView addSubview:[[UIImageView alloc] initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[[[[GameInfo sharedInstance] itemDictionary] objectForKey:name] objectForKey:@"Image"]  ofType:@"png"]]]]];
	
	return [itemCardView autorelease];
	
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    [super dealloc];
}


@end

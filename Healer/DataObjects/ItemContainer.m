//
//  ItemContainer.m
//  RaidLeader
//
//  Created by Ryan Hart on 11/6/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import "ItemContainer.h"


@implementation ItemContainer

@synthesize item, name, containerType;

- (id)initWithFrame:(CGRect)frame andName:(NSString*)title{
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
		name = title;
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)*.2)];
		[titleLabel setText:name];
		[titleLabel setBackgroundColor:[UIColor clearColor]];
		[titleLabel setTextColor:[UIColor blueColor]];
		[titleLabel setTextAlignment:UITextAlignmentCenter];
		[self addSubview:titleLabel];
		[self setBackgroundColor:[UIColor grayColor]];
    }
    return self;
}


-(void)dropObjectIntoContainer:(id)obj{
	if ([obj isKindOfClass:[Item class]]){
		if (item != nil){
			[[item itemCardViewForItem] removeFromSuperview];
			item = nil;
		}
		item = obj;
		[self addSubview:[item itemCardViewForItem]];
		
	}
}

-(void)emptyContainer{
	item = nil;
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

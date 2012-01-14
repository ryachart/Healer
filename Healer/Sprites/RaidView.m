//
//  RaidView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidView.h"


@implementation RaidView


-(BOOL)addRaidMemberHealthView:(RaidMemberHealthView*)healthView
{
	if (nextRectToUse-1 < MAXIMUM_RAID_MEMBERS_ALLOWED){
		[self addChild:healthView];
		if (nextRectToUse % 2 == 0){
//			[healthView setBackgroundColor:[UIColor grayColor]];
//			[healthView setDefaultBackgroundColor:[UIColor grayColor]];
		}
		else {
//			[healthView setBackgroundColor:[UIColor darkGrayColor]];
//			[healthView setDefaultBackgroundColor:[UIColor darkGrayColor]];
		}

		return YES;
	}
	return NO;
}

-(void)updateRaidHealth
{
	for (RaidMemberHealthView *rmhv in self.children){
		[rmhv updateHealth];
	}
	
}
-(void)spawnRects{
	if (rectsToUse == nil){
		rectsToUse = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED];
		int numCols = 5;
		int numRows = 5;
	
		float cellWidth = (self.contentSize.width * .95) / numCols; //We save 10% of the view for some semblance of a border
		float cellHeight = (self.contentSize.height * .95) / numRows ;
		float borderWidthSize = self.contentSize.width * .025;
		float borderHeightSize = self.contentSize.height * .025;
	
		for (int y = 0; y < numRows; y++){
		
			for (int x = 0; x < numCols; x++){
				float cellX = borderWidthSize + cellWidth*x;
				float cellY = borderHeightSize + cellHeight*y;
				GameRect *rect = [GameRect alloc];
				[rect setFrame:CGRectMake(cellX, cellY, cellWidth, cellHeight)];
				[rectsToUse addObject:rect];
			}
		}
	
		nextRectToUse = 0;
	}
	
}

-(CGRect)vendNextUsableRect
{
	NSInteger rectToUse = nextRectToUse;
	nextRectToUse++;
	if (rectToUse >= 25)
		return CGRectMake(0,0,0,0);
	
	return [[rectsToUse objectAtIndex:rectToUse] frame];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [super dealloc];
}


@end

//
//  RaidView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidView.h"


@interface RaidView ()
@property (nonatomic, assign) CCSprite *backgroundSprite;
@end

@implementation RaidView
@synthesize rectsToUse, backgroundSprite, raidViews;

- (id)init {
    if (self = [super init]){
        self.backgroundSprite = [CCSprite spriteWithSpriteFrameName:@"raid_view_back.png"];
        [self.backgroundSprite setAnchorPoint:CGPointZero];
        [self addChild:self.backgroundSprite];
        
        self.raidViews = [NSMutableArray arrayWithCapacity:20];
        self.scale = 1.2;
    }
    return self;
}

-(BOOL)addRaidMemberHealthView:(RaidMemberHealthView*)healthView
{
	if (nextRectToUse-1 < MAXIMUM_RAID_MEMBERS_ALLOWED){
		[self addChild:healthView];
        [self.raidViews addObject:healthView];
		return YES;
	}
	return NO;
}

-(CGPoint)frameCenterForMember:(RaidMember*)raidMember{
    for (RaidMemberHealthView *rmhv in self.raidViews){
        if (rmhv.memberData == raidMember){
            CGPoint framePosition = rmhv.position;
            return [self convertToWorldSpace:ccpAdd(framePosition, ccp(rmhv.contentSize.width /2 ,rmhv.contentSize.height /2))];
        }
    }
    return CGPointZero;
}

-(void)updateRaidHealth
{
	for (RaidMemberHealthView *rmhv in self.raidViews){
		[rmhv updateHealth];
	}
}

-(void)spawnRects{
	if (rectsToUse == nil){
		self.rectsToUse = [[[NSMutableArray alloc] initWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED] autorelease];
		int numCols = 5;
		int numRows = 4;
	
		float cellWidth = (self.contentSize.width * .95) / numCols;
		float cellHeight = (self.contentSize.height * .88) / numRows ;
		float borderWidthSize = self.contentSize.width * .05;
		float borderHeightSize = self.contentSize.height * .015;
	
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
	if (rectToUse >= 20)
		return CGRectMake(0,0,0,0);
	
	return [[rectsToUse objectAtIndex:rectToUse] frame];
}

- (void)dealloc {
    [raidViews release];
    [rectsToUse release];
    [super dealloc];
}


@end

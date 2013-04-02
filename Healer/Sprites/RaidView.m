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
@property (nonatomic, readwrite) NSTimeInterval confusionCooldown;
@property (nonatomic, readwrite) NSInteger nextRectToUse;
@end

@implementation RaidView

- (void)dealloc {
    [_raidViews release];
    [_rectsToUse release];
    [super dealloc];
}

- (id)init {
    if (self = [super init]){
        self.backgroundSprite = [CCNode node];
        
        self.raidViews = [NSMutableArray arrayWithCapacity:20];
    }
    return self;
}

-(BOOL)addRaidMemberHealthView:(RaidMemberHealthView*)healthView
{
	if (self.nextRectToUse - 1 < MAXIMUM_RAID_MEMBERS_ALLOWED){
		[self addChild:healthView];
        [self.raidViews addObject:healthView];
		return YES;
	}
	return NO;
}


-(CGPoint)randomMissedProjectileDestination {
    CGPoint returnPoint = CGPointZero;
    NSInteger otherPos = arc4random() % 600 + 200;
    
    NSInteger offscreen = -40;
    
    returnPoint = CGPointMake(otherPos, offscreen);
    return returnPoint;
}

-(CGPoint)frameCenterForMember:(RaidMember*)raidMember{
    for (RaidMemberHealthView *rmhv in self.raidViews){
        if (rmhv.member == raidMember){
            CGPoint framePosition = rmhv.position;
            return [self convertToWorldSpace:ccpAdd(framePosition, ccp(rmhv.contentSize.width /2 ,rmhv.contentSize.height /2))];
        }
    }
    return CGPointZero;
}

-(void)updateRaidHealthWithPlayer:(Player*)player andTimeDelta:(ccTime)delta
{
    if (player.isConfused){
        self.confusionCooldown += delta;
        if (self.confusionCooldown >= 1.5){
            RaidMemberHealthView *randomRMHV = [self.raidViews objectAtIndex:arc4random() % self.raidViews.count];
            [randomRMHV triggerConfusion];
            self.confusionCooldown = 0.0;
        }
    }
	for (RaidMemberHealthView *rmhv in self.raidViews){
		[rmhv updateHealthForInterval:delta];
	}
}

-(NSMutableArray*)rectsToUse{
	if (!_rectsToUse ){
		_rectsToUse = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED];
		int numCols = 5;
		int numRows = 4;
	
		float cellWidth = (self.contentSize.width) / numCols;
		float cellHeight = (self.contentSize.height) / numRows ;
		float borderWidthSize = 0;
		float borderHeightSize = 0;
	
		for (int y = 0; y < numRows; y++){
			for (int x = 0; x < numCols; x++){
				float cellX = borderWidthSize + cellWidth*x;
				float cellY = borderHeightSize + cellHeight*y;
				GameRect *rect = [[[GameRect alloc] init] autorelease];
				[rect setFrame:CGRectMake(cellX, cellY, cellWidth, cellHeight)];
				[_rectsToUse addObject:rect];
                borderWidthSize = 0;
                borderHeightSize = 0; //Only use borders for cells not on the first col/row
			}
            borderWidthSize = 0;
            borderHeightSize = 0;
		}
	
		self.nextRectToUse = 0;
	}
	return _rectsToUse;
}

-(CGRect)nextUsableRect
{
	CGRect rect = [[self.rectsToUse objectAtIndex:self.nextRectToUse] frame];
	self.nextRectToUse++;
	return rect;
}

-(RaidMemberHealthView*)healthViewForMember:(RaidMember*)raidMember
{
    for (RaidMemberHealthView *rmhv in self.raidViews){
        if (rmhv.member == raidMember){
            return rmhv;
        }
    }
    return nil;
}

- (void)endBattleWithSuccess:(BOOL)success
{
    for (RaidMemberHealthView *healthView in self.raidViews) {
        [healthView runAction:[CCFadeOut actionWithDuration:1.0]];
    }
}

@end

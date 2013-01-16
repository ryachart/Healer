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
@end

@implementation RaidView
@synthesize rectsToUse, backgroundSprite, raidViews;

- (id)init {
    if (self = [super init]){
        self.backgroundSprite = [CCSprite spriteWithSpriteFrameName:@"raid_view_back.png"];
        [self.backgroundSprite setAnchorPoint:CGPointZero];
        [self.backgroundSprite setVisible:NO];
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


-(CGPoint)randomMissedProjectileDestination {
    CGPoint returnPoint = CGPointZero;
    NSInteger otherPos = arc4random() % 500;
    
    NSInteger offscreen = -40;
    
    if (arc4random() % 2 == 0){
        returnPoint = CGPointMake(otherPos, offscreen);
    }else{
        returnPoint = CGPointMake(offscreen, otherPos);
    }
    return returnPoint;
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
				GameRect *rect = [[[GameRect alloc] init] autorelease];
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

-(RaidMemberHealthView*)healthViewForMember:(RaidMember*)raidMember
{
    for (RaidMemberHealthView *rmhv in self.raidViews){
        if (rmhv.memberData == raidMember){
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

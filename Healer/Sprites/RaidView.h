//
//  RaidView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RaidMemberHealthView.h"
#import "GameRect.h"
#import "cocos2d.h"

/* A RaidView contains an Array of all the Raid member health views and lays them 
   out based on the frame size.
 */

@class RaidMemberHealthView;
@interface RaidView : CCLayer {
	NSInteger nextRectToUse;
}
@property (nonatomic, retain) NSMutableArray *rectsToUse;
@property (nonatomic, retain) NSMutableArray *raidViews;

//Returns Yes is successful, no otherwise.
-(BOOL)addRaidMemberHealthView:(RaidMemberHealthView*)healthView;

-(CGPoint)frameCenterForMember:(RaidMember*)raidMember;
-(RaidMemberHealthView*)healthViewForMember:(RaidMember*)raidMember;
-(CGPoint)randomMissedProjectileDestination;
-(void)spawnRects;
-(CGRect)vendNextUsableRect;

-(void)updateRaidHealthWithPlayer:(Player*)player andTimeDelta:(ccTime)delta;

@end

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
@interface RaidView : CCLayer {
	NSMutableArray *rectsToUse;
	NSInteger nextRectToUse;
}

//Returns Yes is successful, no otherwise.
-(BOOL)addRaidMemberHealthView:(RaidMemberHealthView*)healthView;

-(void)spawnRects;
-(CGRect)vendNextUsableRect;

-(void)updateRaidHealth;

@end

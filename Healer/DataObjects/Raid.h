//
//  Raid.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RaidMember.h"

#define MAXIMUM_RAID_MEMBERS_ALLOWED 26
/* A collection of RaidMembers */


@interface Raid : NSObject {
	NSMutableArray *raidMembers;
}
@property (readonly) NSMutableArray *raidMembers;

- (void)addRaidMember:(RaidMember*)member;
- (NSArray*)getAliveMembers;
- (NSInteger)deadCount;

- (RaidMember*)lowestHealthMember;
- (RaidMember*)randomLivingMember;
- (RaidMember*)randomLivingMemberWithPositioning:(Positioning)pos;

//Multiplayer
- (RaidMember*)memberForBattleID:(NSString*)battleID;
- (NSArray*)lowestHealthTargets:(NSInteger)numTargets withRequiredTarget:(RaidMember*)reqTarget;
@end

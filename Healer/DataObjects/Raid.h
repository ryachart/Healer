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


@interface Raid : NSObject
@property (nonatomic, retain, readonly) NSMutableArray *raidMembers;

- (void)addRaidMember:(RaidMember*)member;
- (NSArray*)livingMembers;
- (NSInteger)deadCount;

- (NSArray *)livingMembersWithPositioning:(Positioning)pos;

- (RaidMember*)lowestHealthMember;
- (RaidMember*)randomLivingMember;
- (RaidMember*)randomLivingMemberWithPositioning:(Positioning)pos;
- (NSArray*)randomTargets:(NSInteger)numTargets withPositioning:(Positioning)pos;
- (NSArray*)lowestHealthTargets:(NSInteger)numTargets withRequiredTarget:(RaidMember*)reqTarget;

//Multiplayer
- (RaidMember*)memberForBattleID:(NSString*)battleID;
@end

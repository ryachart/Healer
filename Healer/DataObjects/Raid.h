//
//  Raid.h
//  Healer
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RaidMember.h"
#define MAXIMUM_RAID_MEMBERS_ALLOWED 26
/* A collection of RaidMembers */

typedef BOOL (^RaidMemberComparator)(RaidMember*);

@class Player;

@interface Raid : NSObject
@property (nonatomic, retain, readonly) NSMutableArray *members;
@property (nonatomic, retain, readonly) NSMutableArray *players;
@property (nonatomic, readonly) NSArray *raidMembers;
- (void)addPlayer:(Player*)player;
- (void)addRaidMember:(RaidMember*)member;
- (NSArray*)livingMembers;
- (NSInteger)deadCount;

- (NSArray*)membersSatisfyingComparator:(RaidMemberComparator)comparator;

//Conveniece Methods for querying members
- (RaidMember*)randomMemberSatisfyingComparator:(RaidMemberComparator)comparator;
- (NSArray *)livingMembersWithPositioning:(Positioning)pos;
- (RaidMember*)lowestHealthMember;
- (RaidMember*)randomLivingMember;
- (RaidMember*)randomNonGuardianLivingMember;
- (RaidMember*)randomNonPlayerLivingMember;
- (RaidMember*)randomNonPlayerNonGuardianLivingMember;
- (RaidMember*)randomLivingMemberWithPositioning:(Positioning)pos;
- (NSArray*)randomTargets:(NSInteger)numTargets withPositioning:(Positioning)pos;
- (NSArray*)randomTargets:(NSInteger)numTargets withPositioning:(Positioning)pos excludingTargets:(NSArray*)targets;
- (NSArray*)lowestHealthTargets:(NSInteger)numTargets withRequiredTarget:(RaidMember*)reqTarget;

//Multiplayer
- (RaidMember*)memberForNetworkId:(NSString*)battleID;
@end

//
//  Raid.m
//  Healer
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

#import "Raid.h"
#import "Player.h"

@interface Raid ()
@property (nonatomic, retain) NSMutableDictionary *raidMemberNetworkIds;
@end

@implementation Raid

- (void)dealloc {
    [_players release]; _players = nil;
    [_members release]; _members = nil;
    [_raidMemberNetworkIds release]; _raidMemberNetworkIds = nil;
    [super dealloc];
}

- (id)init {
    if (self = [super init]){
        _members = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED];
        self.raidMemberNetworkIds = [NSMutableDictionary dictionaryWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED];
        _players = [[NSMutableArray arrayWithCapacity:2] retain];
	}
	return self;
}

- (void)addRaidMember:(RaidMember*)member {
	if ([self.raidMembers count] < MAXIMUM_RAID_MEMBERS_ALLOWED && ![self.raidMembers containsObject:member]){
		[_members addObject:member];
        
        if (member.networkId){
            [self.raidMemberNetworkIds setObject:member forKey:member.networkId];
        }else{
            member.networkId = [NSString stringWithFormat:@"%@%i",  NSStringFromClass([member class]), self.raidMembers.count];
            [self.raidMemberNetworkIds setObject:member forKey:member.networkId];

        }
	}
}

- (void)addPlayer:(Player *)player {
    if (![self.players containsObject:player]) {
        [self.players addObject:player];
    }
}

- (NSInteger)deadCount {
    NSInteger deadCount = 0;
    
    for (HealableTarget *member in self.raidMembers){
        if (member.isDead){
            deadCount++;
        }
    }
    return deadCount;
}

- (RaidMember*)memberForNetworkId:(NSString *)battleID {
    return [self.raidMemberNetworkIds objectForKey:battleID];
}

- (NSArray *)raidMembers
{
    NSArray *members = [self.players arrayByAddingObjectsFromArray:_members];
    return members;
}

- (NSArray*)membersSatisfyingComparator:(RaidMemberComparator)comparator
{
    NSMutableArray *satisfyingMembers = [NSMutableArray arrayWithCapacity:self.raidMembers.count];
    for (RaidMember *member in self.raidMembers) {
        if (comparator(member)) {
            [satisfyingMembers addObject:member];
        }
    }
    
    if (satisfyingMembers.count == 0) {
        return nil;
    }
    
    return satisfyingMembers;
}

-(NSArray*)livingMembers
{
	NSMutableArray *aliveMembers = [[[NSMutableArray alloc] initWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED] autorelease];
	for (HealableTarget *member in self.raidMembers)
	{
		if (![member isDead]){
			[aliveMembers addObject:member];
		}
	}
	
	return aliveMembers;
}

- (RaidMember*)randomMemberSatisfyingComparator:(RaidMemberComparator)comparator {
    NSArray *candidates = [self membersSatisfyingComparator:comparator];
    if (candidates.count == 0) {
        return nil;
    }
    return [candidates objectAtIndex:arc4random() % candidates.count];
}

- (RaidMember*)randomLivingMemberWithPositioning:(Positioning)pos {
    return [self randomMemberSatisfyingComparator:^BOOL (RaidMember *member) {
        if (member.isDead || member.positioning != pos) {
            return NO;
        }
        return YES;
    }];
}

- (RaidMember*)randomLivingMember {
    return [self randomMemberSatisfyingComparator:^BOOL(RaidMember *member) {
        if (member.isDead) {
            return false;
        }
        return true;
    }];
}

- (RaidMember*)randomNonPlayerLivingMember {
    return [self randomMemberSatisfyingComparator:^BOOL(RaidMember *member) {
        if (member.isDead && ![member isKindOfClass:[Player class]]) {
            return false;
        }
        return true;
    }];
}

- (RaidMember*)randomNonGuardianLivingMember {
    return [self randomMemberSatisfyingComparator:^BOOL(RaidMember *member) {
        if (member.isDead && ![member isKindOfClass:[Guardian class]]) {
            return false;
        }
        return true;
    }];
}

- (RaidMember*)randomNonPlayerNonGuardianLivingMember {
    return [self randomMemberSatisfyingComparator:^BOOL(RaidMember *member) {
        if (member.isDead && ![member isKindOfClass:[Player class]] && ![member isKindOfClass:[Guardian class]]) {
            return false;
        }
        return true;
    }];
}

- (NSArray*)randomTargets:(NSInteger)numTargets withPositioning:(Positioning)pos {
    return [self randomTargets:numTargets withPositioning:pos excludingTargets:[NSArray array]];
}

- (NSArray*)randomTargets:(NSInteger)numTargets withPositioning:(Positioning)pos excludingTargets:(NSArray*)exclTargets {
    NSMutableArray *candidates = [NSMutableArray arrayWithArray:[self membersSatisfyingComparator:^BOOL (RaidMember *member) {
        if ([exclTargets containsObject:member] || (member.positioning != pos && pos != Any)) {
            return NO;
        }
        return YES;
    }]];
    
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:numTargets];
    
    for (int i = 0; i < MIN(numTargets, candidates.count); i++) {
        [targets addObject:[candidates objectAtIndex:arc4random() % candidates.count]];
    }
    
    return targets;
}

-(RaidMember*)lowestHealthRaidMemberInSet:(NSArray*)raid{
    if (raid.count == 0){
        return nil;
    }
    float lowestHealth = [(RaidMember*)[raid objectAtIndex:0] healthPercentage];
    RaidMember *candidate = [raid objectAtIndex:0];
    for (RaidMember *member in raid){
        if (member.isDead)
            continue;
        if (member.healthPercentage <= lowestHealth){
            lowestHealth = member.healthPercentage;
            candidate = member;
        }
    }
    
    if (candidate.healthPercentage == 1.0){
        //If the lowest health raid member is full health, choose a random member because this behaves
        //better for abilities that target lowest health raid members
        return [raid objectAtIndex:arc4random() % raid.count];
    }
    
    return candidate;
}

- (RaidMember*)lowestHealthMember {
    return [[self lowestHealthTargets:1 withRequiredTarget:nil] objectAtIndex:0];
}

- (NSArray*)lowestHealthTargets:(NSInteger)numTargets withRequiredTarget:(RaidMember*)reqTarget{
    NSMutableArray *finalTargets = [NSMutableArray arrayWithCapacity:numTargets];
    NSMutableArray *candidates = [NSMutableArray arrayWithArray:[self livingMembers]];
    [candidates removeObject:reqTarget];
    
    
    int aliveMembers = [[self livingMembers] count];
    int possibleTargets = numTargets - (reqTarget ? 1 : 0);
    if (possibleTargets > aliveMembers){
        possibleTargets = aliveMembers;
    }
    for (int i = 0; i < possibleTargets; i++){
        RaidMember *lowestHealthTarget = [self lowestHealthRaidMemberInSet:candidates];
        if (lowestHealthTarget){
            [finalTargets addObject:lowestHealthTarget];
            [candidates removeObject:lowestHealthTarget];
        }
    }
    
    if (reqTarget){
        [finalTargets addObject:reqTarget];
    }
    return finalTargets;
}

- (NSArray *)livingMembersWithPositioning:(Positioning)pos {
    return [self membersSatisfyingComparator:^BOOL (RaidMember *member){
        if (member.positioning != pos) {
            return NO;
        }
        return YES;
    }];
}

@end

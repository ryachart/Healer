//
//  Raid.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Raid.h"
@interface Raid ()
@property (nonatomic, retain) NSMutableDictionary *raidMemberBattleIDDictionary;
@end

@implementation Raid

@synthesize raidMembers, raidMemberBattleIDDictionary;
-(void)dealloc{
    [raidMemberBattleIDDictionary release];
    [super dealloc];
}

-(id)init{
    if (self = [super init]){
        raidMembers = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED];
        self.raidMemberBattleIDDictionary = [NSMutableDictionary dictionaryWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED];
	}
	return self;
}

-(void)addRaidMember:(RaidMember*)member
{
	if ([raidMembers count] < MAXIMUM_RAID_MEMBERS_ALLOWED && ![raidMembers containsObject:member]){
		[raidMembers addObject:member];
        
        if (member.battleID){
            [self.raidMemberBattleIDDictionary setObject:member forKey:member.battleID];
        }else{
            member.battleID = [NSString stringWithFormat:@"%@%i",  NSStringFromClass([member class]), self.raidMembers.count];
            [self.raidMemberBattleIDDictionary setObject:member forKey:member.battleID];

        }
	}
}

-(NSInteger)deadCount{
    NSInteger deadCount = 0;
    
    for (HealableTarget *member in self.raidMembers){
        if (member.isDead){
            deadCount++;
        }
    }
    return deadCount;
}

-(NSArray*)getAliveMembers
{
	NSMutableArray *aliveMembers = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED];
	
	for (HealableTarget *member in raidMembers)
	{
		if (![member isDead]){
			[aliveMembers addObject:member];
		}
	}
	
	return [aliveMembers autorelease];
}

-(RaidMember*)randomLivingMember{
    RaidMember *selectedMember = nil;
    
    do {
        selectedMember = [self.raidMembers objectAtIndex:arc4random() % self.raidMembers.count];
        if (selectedMember.isDead)
            selectedMember = nil;
    }while (!selectedMember);
    return selectedMember;
}

-(RaidMember*)memberForBattleID:(NSString *)battleID{
    return [self.raidMemberBattleIDDictionary objectForKey:battleID];
}

-(RaidMember*)lowestHealthRaidMemberSet:(NSArray*)raid{
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
    return candidate;
}

-(NSArray*)lowestHealthTargets:(NSInteger)numTargets withRequiredTarget:(RaidMember*)reqTarget{
    NSMutableArray *finalTargets = [NSMutableArray arrayWithCapacity:numTargets];
    NSMutableArray *candidates = [NSMutableArray arrayWithArray:[self getAliveMembers]];
    [candidates removeObject:reqTarget];
    
    
    int aliveMembers = [[self getAliveMembers] count];
    int possibleTargets = numTargets - (reqTarget ? 1 : 0);
    if (possibleTargets > aliveMembers){
        possibleTargets = aliveMembers;
    }
    for (int i = 0; i < possibleTargets; i++){
        RaidMember *lowestHealthTarget = [self lowestHealthRaidMemberSet:candidates];
        [finalTargets addObject:lowestHealthTarget];
        [candidates removeObject:lowestHealthTarget];
    }
    
    if (reqTarget){
        [finalTargets addObject:reqTarget];
    }
    return finalTargets;
}

@end

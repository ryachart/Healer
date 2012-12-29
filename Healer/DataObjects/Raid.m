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
    [raidMembers release]; raidMembers = nil;
    [raidMemberBattleIDDictionary release]; raidMemberBattleIDDictionary = nil;
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

-(NSArray*)livingMembers
{
	NSMutableArray *aliveMembers = [[[NSMutableArray alloc] initWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED] autorelease];
	
	for (HealableTarget *member in raidMembers)
	{
		if (![member isDead]){
			[aliveMembers addObject:member];
		}
	}
	
	return aliveMembers;
}

- (RaidMember*)randomLivingMemberWithPositioning:(Positioning)pos {
    RaidMember *selectedMember = nil;
    int safety = 0;
    do {
        selectedMember = [self randomLivingMember];
        if (pos != Any && selectedMember.positioning != pos){
            selectedMember = nil;
        }
        safety++;
        if (safety > 25){
            break;
        }
    }while (!selectedMember);
    return selectedMember;
}

-(RaidMember*)randomLivingMember{
    RaidMember *selectedMember = nil;
    int safety = 0;
    do {
        selectedMember = [self.raidMembers objectAtIndex:arc4random() % self.raidMembers.count];
        if (selectedMember.isDead)
            selectedMember = nil;
        safety++;
        if (safety > 25){
            break;
        }
    }while (!selectedMember);
    return selectedMember;
}

- (NSArray*)randomTargets:(NSInteger)numTargets withPositioning:(Positioning)pos{
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:numTargets];
    
    int safety = 0;
    while (targets.count < numTargets){
        RaidMember *candidate = [self randomLivingMemberWithPositioning:pos];
        if (candidate) {
            if (![targets containsObject:candidate]){
                [targets addObject:candidate];
            }
        }
        if (safety >= 25){
            break;
        }
        safety++;
    }
    return targets;
}

-(RaidMember*)memberForBattleID:(NSString *)battleID{
    return [self.raidMemberBattleIDDictionary objectForKey:battleID];
}

-(RaidMember*)lowestHealthRaidMemberSet:(NSArray*)raid{
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
        RaidMember *lowestHealthTarget = [self lowestHealthRaidMemberSet:candidates];
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
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:20];
    NSArray *candidates = [self livingMembers];
    
    for (RaidMember *member in candidates) {
        if (member.positioning == pos) {
            [targets addObject:member];
        }
    }
    return targets;
}

@end

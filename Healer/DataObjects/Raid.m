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
-(id)init{
    if (self = [super init]){
        raidMembers = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED];
        self.raidMemberBattleIDDictionary = [NSMutableDictionary dictionaryWithCapacity:MAXIMUM_RAID_MEMBERS_ALLOWED];
	}
	return self;
}

-(NSInteger)classCount:(NSString*)classToCount{
	NSInteger witchCount = 0;
	NSInteger ogreCount = 0;
	NSInteger trollCount = 0;
	
	for (RaidMember *member in raidMembers){
		if ([member class] == [Ogre class]){
			ogreCount++;
		}
		if ([member class] == [Witch class]){
			witchCount++;
		}
		if ([member class] == [Troll class]){
			trollCount++;
		}
	}
	
	if ([classToCount isEqualToString:RaidMemberTypeOgre]){
		return ogreCount;
	}
	if ([classToCount isEqualToString:RaidMemberTypeTroll]){
		return trollCount;
	}
	if ([classToCount isEqualToString:RaidMemberTypeWitch]){
		return witchCount;
	}
	
	return 0;
}

-(void)addRaidMember:(RaidMember*)member
{
	if ([raidMembers count] < MAXIMUM_RAID_MEMBERS_ALLOWED && ![raidMembers containsObject:member]){
		[raidMembers addObject:member];
        
        if (member.battleID){
            [self.raidMemberBattleIDDictionary setObject:member forKey:member.battleID];
        }
	}
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
@end

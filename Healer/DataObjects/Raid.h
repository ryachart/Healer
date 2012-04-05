//
//  Raid.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RaidMember.h"
#import "DataDefinitions.h"

/* A collection of RaidMembers */


@interface Raid : NSObject {
	NSMutableArray *raidMembers;
}
@property (readonly) NSMutableArray *raidMembers;
-(id) init;

-(void)addRaidMember:(RaidMember*)member;
-(NSArray*)getAliveMembers;

-(NSInteger)classCount:(NSString*)classToCount;
-(RaidMember*)randomLivingMember;

//Multiplayer
-(RaidMember*)memberForBattleID:(NSString*)battleID;
@end

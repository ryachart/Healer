//
//  RaidMember.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidMember.h"
#import "GameObjects.h"

@implementation RaidMember
@synthesize lastAttack;

-(id) initWithHealth:(NSInteger)hlth damageDealt:(NSInteger)damage andDmgFrequency:(float)dmgFreq
{
    if (self = [super init]){
        maximumHealth = hlth;
        health = hlth;
        
        damageDealt = damage;
        damageFrequency = dmgFreq;
        
        activeEffects = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_STATUS_EFFECTS];
    }
	return self;
}

-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
	
	
}


@end

@implementation Witch
+(Witch*)defaultWitch
{
	Witch *defWitch = [[Witch alloc] initWithHealth:50 damageDealt:65 andDmgFrequency:.65];
	
	return [defWitch autorelease];
}

-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
	lastAttack += timeDelta;
	if (lastAttack >= damageFrequency){
		lastAttack = 0.0;
		
		[theBoss setHealth:[theBoss health] - damageDealt];
		
	}

	
	for (int i = 0; i < [activeEffects count]; i++){
		Effect *effect = [activeEffects objectAtIndex:i];
		[effect combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
		if ([effect isExpired]){
			[effect expire];
			[activeEffects removeObjectAtIndex:i];
		}
	}
}

@end

@implementation Troll
+(Troll*)defaultTroll
{
	Troll *defTroll = [[Troll alloc] initWithHealth:75 damageDealt:62 andDmgFrequency:.80];
	
	return [defTroll autorelease];
}

-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
	lastAttack+= timeDelta;
	if (lastAttack >= damageFrequency){
		lastAttack = 0.0;
		
		[theBoss setHealth:[theBoss health] - damageDealt];
		
	}
	
	for (int i = 0; i < [activeEffects count]; i++){
		Effect *effect = [activeEffects objectAtIndex:i];
		[effect combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
		if ([effect isExpired]){
			[effect expire];
			[activeEffects removeObjectAtIndex:i];
		}
	}
	
}
@end

@implementation Ogre
+(Ogre*)defaultOgre
{
	Ogre *defOgre = [[Ogre alloc] initWithHealth:100 damageDealt:50 andDmgFrequency:1.0];
	return [defOgre autorelease];
}

-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
	lastAttack+= timeDelta;
	if (lastAttack >= damageFrequency){
		lastAttack = 0.0;
		
		[theBoss setHealth:[theBoss health] - damageDealt];
		
	}
	
	for (int i = 0; i < [activeEffects count]; i++){
		Effect *effect = [activeEffects objectAtIndex:i];
		[effect combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
		if ([effect isExpired]){
			[effect expire];
			[activeEffects removeObjectAtIndex:i];
		}
	}
	
}
@end
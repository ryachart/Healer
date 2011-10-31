//
//  Boss.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Boss.h"
#import "GameObjects.h"

@implementation Boss
@synthesize lastAttack, health, maximumHealth, title;
-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq andChoosesMT:(BOOL)chooses{
	health = hlth;
	maximumHealth = hlth;
	damage = dmg;
	targets = trgets;
	frequency = freq;
	choosesMainTank = chooses;
	lastAttack = nil;
	title = @"";
	return self;
	
}

-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(NSDate*)theTime
{
	if (lastAttack == nil)
		lastAttack = [theTime copyWithZone:nil];
	
	NSTimeInterval timeSinceLastAttack = [theTime timeIntervalSinceDate:lastAttack];
	if (timeSinceLastAttack >= frequency){
		
		[lastAttack release];
		lastAttack = [theTime	copyWithZone:nil];
		
		NSInteger damagePerTarget = damage/targets;
		NSArray* victims = [theRaid getAliveMembers];
		
		RaidMember *target;
		
		if (targets <= [victims count]){
			for (int i = 0; i < targets; i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				
				[target setHealth:[target health] - damagePerTarget];
			}
		}
		else{
			
			for (int i = 0; i < targets; i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				[target setHealth:[target health] - damagePerTarget];
				
				if ([[theRaid getAliveMembers] count] == 0){
					i = targets;
				}
			}
		}
		
	}
}

-(void)setHealth:(NSInteger)newHealth
{
	health = newHealth;
	if (health < 0) health = 0;
}

-(BOOL)isDead
{
	return health <= 0;
}

+(id)defaultBoss
{
	return nil;
}
@end
@implementation MinorDemon
+(id)defaultBoss{
	MinorDemon *defMinorDemon = [[MinorDemon alloc] initWithHealth:25000 damage:24 targets:2 frequency:.85 andChoosesMT:NO];
	[defMinorDemon setTitle:@"Minor Demon"];
	return [defMinorDemon autorelease];
	
}
@end

@implementation FieryDemon
+(id)defaultBoss{
	FieryDemon *fireDemon = [[FieryDemon alloc] initWithHealth:40000 damage:28 targets:2 frequency:0.80 andChoosesMT:NO];
	[fireDemon setTitle:@"Fiery Demon"];
	return [fireDemon autorelease];
}

-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(NSDate*)theTime
{
	
	if (lastAttack == nil)
		lastAttack = [theTime copyWithZone:nil];
	
	NSTimeInterval timeSinceLastAttack = [theTime timeIntervalSinceDate:lastAttack];
	if (timeSinceLastAttack >= frequency){
		
		NSInteger fireballChance = arc4random()% 100;
		if (fireballChance <= 15 && ![[player activeEffects] containsObject:currentFireball])
		{
			BigFireball *fireBall = [[BigFireball alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative];
			currentFireball = fireBall;
			[fireBall setLastPosition:[player position]];
			[player addEffect:fireBall];
		}
		
		[lastAttack release];
		lastAttack = [theTime	copyWithZone:nil];
		
		NSInteger damagePerTarget = damage/targets;
		NSArray* victims = [theRaid getAliveMembers];
		
		RaidMember *target;
		
		if (targets <= [victims count]){
			for (int i = 0; i < targets; i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				
				[target setHealth:[target health] - damagePerTarget];
			}
		}
		else{
			
			for (int i = 0; i < targets; i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				[target setHealth:[target health] - damagePerTarget];
				
				if ([[theRaid getAliveMembers] count] == 0){
					i = targets;
				}
			}
		}
		
	}
}

@end

@implementation BringerOfEvil
@synthesize numEnrages;
+(id)defaultBoss{
	BringerOfEvil *boe = [[BringerOfEvil alloc] initWithHealth:120000 damage:30 targets:5 frequency:0.75 andChoosesMT:NO];
	[boe setNumEnrages:0];
	[boe setTitle:@"Bringer of Evil"];
	return [boe autorelease];
}
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(NSDate*)theTime
{
	
	
	float PercentageHealthRemain = (((float)health)/maximumHealth) * 100;
	
	if (PercentageHealthRemain <= 5 && numEnrages == 0)
	{
		[player setStatusText:@"The Bringer of Evil is ENRAGED!"];
		damage = damage *2;
		numEnrages++;
	}
	
	if (lastAttack == nil)
		lastAttack = [theTime copyWithZone:nil];
	
	NSTimeInterval timeSinceLastAttack = [theTime timeIntervalSinceDate:lastAttack];
	if (timeSinceLastAttack >= frequency){
		
		NSInteger fireballChance = arc4random()% 100;
		if (fireballChance <= 5 && ![[player activeEffects] containsObject:currentFireball])
		{
			BigFireball *fireBall = [[BigFireball alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative];
			currentFireball = fireBall;
			[fireBall setLastPosition:[player position]];
			[player addEffect:fireBall];
		}
		
		[lastAttack release];
		lastAttack = [theTime	copyWithZone:nil];
		
		NSInteger damagePerTarget = damage/targets;
		NSArray* victims = [theRaid getAliveMembers];
		
		RaidMember *target;
		
		if (targets <= [victims count]){
			for (int i = 0; i < targets; i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				
				[target setHealth:[target health] - damagePerTarget];
			}
		}
		else{
			
			for (int i = 0; i < targets; i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				[target setHealth:[target health] - damagePerTarget];
				
				if ([[theRaid getAliveMembers] count] == 0){
					i = targets;
				}
			}
		}
		
	}
}
@end
#pragma mark -
#pragma mark Demo Bosses
@implementation Dragon
+(id)defaultBoss{
	Dragon *defDragon = [[Dragon alloc] initWithHealth:100000 damage:28 targets:4 frequency:0.80 andChoosesMT:NO];
	[defDragon setTitle:@"Dragon"];
	return [defDragon autorelease];
}@end
@implementation Hydra
+(id)defaultBoss{
	Hydra *defHy = [[Hydra alloc] initWithHealth:125000 damage:28 targets:4 frequency:0.75 andChoosesMT:NO];
	[defHy setTitle:@"Hydra"];
	return [defHy autorelease];
}
@end

@implementation Giant
+(id)defaultBoss{
	Giant *defGi = [[Giant alloc] initWithHealth:85000 damage:30 targets:3 frequency:0.75 andChoosesMT:NO];
	[defGi setTitle:@"Giant"];
	return [defGi autorelease];
}
@end

@implementation ChaosDemon
@synthesize numEnrages;
+(id)defaultBoss{
	ChaosDemon *defCD = [[ChaosDemon alloc] initWithHealth:115000 damage:20 targets:4 frequency:0.50 andChoosesMT:NO];
	[defCD setNumEnrages:0];
	[defCD setTitle:@"Chaos Demon"];
	return [defCD autorelease];
}
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(NSDate*)theTime
{
	
	
	float PercentageHealthRemain = (((float)health)/maximumHealth) * 100;
	
	if (PercentageHealthRemain <= 5 && numEnrages == 0)
	{
		damage = damage *2;
		numEnrages++;
	}
	
	if (lastAttack == nil)
		lastAttack = [theTime copyWithZone:nil];
	
	NSTimeInterval timeSinceLastAttack = [theTime timeIntervalSinceDate:lastAttack];
	if (timeSinceLastAttack >= frequency){
		
		NSInteger fireballChance = arc4random()% 100;
		if (fireballChance <= 10 && ![[player activeEffects] containsObject:currentFireball])
		{
			BigFireball *fireBall = [[BigFireball alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative];
			currentFireball = fireBall;
			[fireBall setLastPosition:[player position]];
			[player addEffect:fireBall];
		}
		
		[lastAttack release];
		lastAttack = [theTime	copyWithZone:nil];
		
		NSInteger damagePerTarget = damage/targets;
		NSArray* victims = [theRaid getAliveMembers];
		
		RaidMember *target;
		
		if (targets <= [victims count]){
			for (int i = 0; i < targets; i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				
				[target setHealth:[target health] - damagePerTarget];
			}
		}
		else{
			
			for (int i = 0; i < targets; i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				[target setHealth:[target health] - damagePerTarget];
				
				if ([[theRaid getAliveMembers] count] == 0){
					i = targets;
				}
			}
		}
		
	}
}
@end


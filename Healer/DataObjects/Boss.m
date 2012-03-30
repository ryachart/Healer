//
//  Boss.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Boss.h"
#import "GameObjects.h"
#import "RaidMember.h"

@interface Boss ()
@property (nonatomic, retain) RaidMember *focusTarget;
-(int)damageDealt;
@end

@implementation Boss
@synthesize lastAttack, health, maximumHealth, title, logger, focusTarget, announcer;

-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq andChoosesMT:(BOOL)chooses{
    if (self = [super init]){
        health = hlth;
        maximumHealth = hlth;
        damage = dmg;
        targets = trgets;
        frequency = freq;
        choosesMainTank = chooses;
        lastAttack = 0.0f;
        title = @"";
    }
	return self;
	
}

-(int)damageDealt{
    
    float multiplyModifier = 1;
    int additiveModifier = 0;
    
    if (choosesMainTank && self.focusTarget.isDead){
        multiplyModifier *= 3; //The tank died.  Outgoing damage is now tripled
    }
    
    return (int)round((float)damage/(float)targets * multiplyModifier) + additiveModifier;
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid*)raid andPlayer:(Player*)player{
    //The main entry point for health based triggers
}

-(void)damageTarget:(RaidMember*)target{
    if (![target raidMemberShouldDodgeAttack:0.0]){
        int thisDamage = self.damageDealt;
        
        if (target == self.focusTarget){
            thisDamage = (int)round(thisDamage * .2);
        }
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:thisDamage] andEventType:CombatEventTypeDamage]];
        [target setHealth:[target health] - thisDamage];
        
        if ([target isDead]){
            [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:nil andEventType:CombatEventTypeMemberDied]];
        }
    }else{
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:0 andEventType:CombatEventTypeDodge]];
    }
}

-(void)chooseMainTankInRaid:(Raid *)theRaid{
    if (choosesMainTank && !self.focusTarget){
        int highestHealth = ((RaidMember*)[theRaid.raidMembers objectAtIndex:0]).maximumHealth;
        RaidMember *tempTarget = [theRaid.raidMembers objectAtIndex:0];
        for (int i = 1; i < theRaid.raidMembers.count; i++){
            if (((RaidMember*)[theRaid.raidMembers objectAtIndex:i]).maximumHealth > highestHealth){
                highestHealth = ((RaidMember*)[theRaid.raidMembers objectAtIndex:i]).maximumHealth;
                tempTarget = ((RaidMember*)[theRaid.raidMembers objectAtIndex:i]);
            }
        }
        self.focusTarget = tempTarget;
        [self.focusTarget setIsFocused:YES];
    }
}

-(void)performStandardAttackOnTheRaid:(Raid*)theRaid andPlayer:(Player*)thePlayer withTime:(float)theTime{
    self.lastAttack+= theTime;

    if (self.lastAttack >= frequency){
		
		self.lastAttack = 0;
		
		NSArray* victims = [theRaid getAliveMembers];
		
		RaidMember *target = nil;
		
        if (choosesMainTank && !self.focusTarget.isDead){
            [self damageTarget:self.focusTarget];
            if (self.focusTarget.isDead){
                [self.announcer announce:[NSString stringWithFormat:@"%@ enters a blood rage upon killing his focused target.", self.title]];
                
            }
        }
		if (targets <= [victims count]){
			for (int i = 0; i < targets - (int)(choosesMainTank && !self.focusTarget.isDead); i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				
                [self damageTarget:target];
			}
		}
		else{
			for (int i = 0; i < targets - (int)(choosesMainTank && !self.focusTarget.isDead); i++){
				do{
                    if ([victims count] <= 0){
                        break;
                    }
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
                [self damageTarget:target];
				
				if ([[theRaid getAliveMembers] count] == 0){
					i = targets;
				}
			}
		}
		
	}

}
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(float)theTime
{
    [self healthPercentageReached:(float)self.health/(float)self.maximumHealth withRaid:theRaid andPlayer:player];

    [self chooseMainTankInRaid:theRaid];
	
    [self performStandardAttackOnTheRaid:theRaid andPlayer:player withTime:theTime];
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

-(NSString*)sourceName{
    return self.title;
}
-(NSString*)targetName{
    return self.title;
}
@end

#pragma mark - Shipping Bosses (Merc Campaign)









#pragma mark - Deprecated Bosses
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

-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    self.lastAttack+= timeDelta;
	
	if (self.lastAttack >= frequency){
		
		NSInteger fireballChance = arc4random()% 100;
		if (fireballChance <= 15 && ![[player activeEffects] containsObject:currentFireball])
		{
			BigFireball *fireBall = [[BigFireball alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative];
			currentFireball = fireBall;
			[fireBall setLastPosition:[player position]];
			[player addEffect:fireBall];
		}
		self.lastAttack = 0.0;
		
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
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
	float PercentageHealthRemain = (((float)health)/maximumHealth) * 100;
	self.lastAttack+= timeDelta;
    
	if (PercentageHealthRemain <= 5 && numEnrages == 0)
	{
		[player setStatusText:@"The Bringer of Evil is ENRAGED!"];
		damage = damage *2;
		numEnrages++;
	}
	

	if (self.lastAttack >= frequency){
		
		NSInteger fireballChance = arc4random()% 100;
		if (fireballChance <= 5 && ![[player activeEffects] containsObject:currentFireball])
		{
			BigFireball *fireBall = [[BigFireball alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative];
			currentFireball = fireBall;
			[fireBall setLastPosition:[player position]];
			[player addEffect:fireBall];
            [fireBall release];
		}
		
        self.lastAttack = 0.0f;
		
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
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
	float PercentageHealthRemain = (((float)health)/maximumHealth) * 100;
	
	if (PercentageHealthRemain <= 5 && numEnrages == 0)
	{
		damage = damage *2;
		numEnrages++;
	}
	
    self.lastAttack += timeDelta;
	
	if (self.lastAttack >= frequency){
		
		NSInteger fireballChance = arc4random()% 100;
		if (fireballChance <= 10 && ![[player activeEffects] containsObject:currentFireball])
		{
			BigFireball *fireBall = [[BigFireball alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative];
			currentFireball = fireBall;
			[fireBall setLastPosition:[player position]];
			[player addEffect:fireBall];
		}
		
        self.lastAttack = 0.0f;
		
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


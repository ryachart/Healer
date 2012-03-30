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
@synthesize damageDealt;
@synthesize title;
@synthesize dodgeChance;

-(id) initWithHealth:(NSInteger)hlth damageDealt:(NSInteger)damage andDmgFrequency:(float)dmgFreq
{
    if (self = [super init]){
        maximumHealth = hlth;
        health = hlth;
        
        damageDealt = damage;
        damageFrequency = dmgFreq;
        self.title = @"NOTITLE";
        self.dodgeChance = 0.0;
        activeEffects = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_STATUS_EFFECTS];
    }
	return self;
}

-(void)performAttackIfAbleOnTarget:(Boss*)target{
	if (lastAttack >= damageFrequency && !self.isDead){
		lastAttack = 0.0;
		
		[target setHealth:[target health] - self.damageDealt];
		
	}
}

-(void)updateEffects:(Boss*)theBoss raid:(Raid*)theRaid player:(Player*)thePlayer time:(float)timeDelta{
    NSMutableArray *effectsToRemove = [NSMutableArray arrayWithCapacity:5];
	for (int i = 0; i < [activeEffects count]; i++){
		Effect *effect = [activeEffects objectAtIndex:i];
		[effect combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
		if ([effect isExpired]){
			[effect expire];
            [effectsToRemove addObject:effect];
		}
	}
    
    for (Effect *effect in effectsToRemove){
        [activeEffects removeObject:effect];
        
    }
}

-(void)dealloc{
    [activeEffects release]; activeEffects = nil;
    [super dealloc];
}

-(float)dps{
    return (float)damageDealt  / damageFrequency;
}


-(NSInteger)damageDealt{
    int finalAmount = damageDealt;
    int fuzzRange = (int)round(damageDealt * .05);
    int fuzz = arc4random() % (fuzzRange + 1);
    
    finalAmount += fuzz * (arc4random() % 2 == 0 ? -1 : 1);
    return finalAmount;
}

-(BOOL)raidMemberShouldDodgeAttack:(float)modifer{
    return arc4random() % 100 <= (100 * self.dodgeChance);
}

-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
    lastAttack += timeDelta;
    [self performAttackIfAbleOnTarget:theBoss];
    [self updateEffects:theBoss raid:theRaid player:thePlayer time:timeDelta];
	
}


@end


#pragma mark - Merc Campaign Allies

@implementation  Guardian
+(Guardian*)defaultGuardian{
    return [[[Guardian alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:100 damageDealt:50 andDmgFrequency:1.0]){
        self.title = @"Guardian";
        self.dodgeChance = .09;
    }
    return self;
}
@end


@implementation Soldier
+(Soldier*)defaultSoldier{
    return [[[Soldier alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:75 damageDealt:62 andDmgFrequency:.80]){
        self.title = @"Soldier";
        self.dodgeChance = .07;
    }
    return self;
}
@end

@implementation  Demonslayer
+(Demonslayer*)defaultDemonslayer{
    return [[[Demonslayer alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:75 damageDealt:62 andDmgFrequency:.80]){
        self.title = @"Demonslayer";
        self.dodgeChance = .05;
    }
    return self;
}
@end

@implementation Champion

@end

@implementation  Wizard
+(Wizard*)defaultWizard{
    return [[[Wizard alloc] init] autorelease];
}

-(id)init{
    if (self = [super initWithHealth:75 damageDealt:25 andDmgFrequency:1.0]){
        self.title = @"Wizard";
        self.dodgeChance = .05;
        lastEnergyGrant = 0.0;
    }
    return self;
}

-(void)combatActions:(Boss *)theBoss raid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)timeDelta{
    [super combatActions:theBoss raid:theRaid thePlayer:thePlayer gameTime:timeDelta];
    lastEnergyGrant += timeDelta;
    if (lastEnergyGrant > 1.0){
        [thePlayer setEnergy:thePlayer.energy + 1];
        lastEnergyGrant = 0.0;
    }
    
}
@end

@implementation Berserker
+(Berserker*)defaultBerserker{
    return [[[Berserker alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:70 damageDealt:70 andDmgFrequency:1.0]){
    
    }
}

@end


#pragma mark - Deprecated Party Members

@implementation Witch
+(Witch*)defaultWitch
{
	Witch *defWitch = [[Witch alloc] initWithHealth:50 damageDealt:65 andDmgFrequency:.65];
	
	return [defWitch autorelease];
}

-(BOOL)raidMemberShouldDodgeAttack:(float)modifer{
    return arc4random() % 100 <= 5;
}

@end

@implementation Troll
+(Troll*)defaultTroll
{
	Troll *defTroll = [[Troll alloc] initWithHealth:75 damageDealt:62 andDmgFrequency:.80];
	
	return [defTroll autorelease];
}

-(BOOL)raidMemberShouldDodgeAttack:(float)modifer{
    return arc4random() % 100 <= 8;
}
@end

@implementation Ogre
+(Ogre*)defaultOgre
{
	Ogre *defOgre = [[Ogre alloc] initWithHealth:100 damageDealt:50 andDmgFrequency:1.0];
	return [defOgre autorelease];
}

-(BOOL)raidMemberShouldDodgeAttack:(float)modifer{
    return arc4random() % 100 <= 10;
}
@end
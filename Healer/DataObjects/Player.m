//
//  Player.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Player.h"
#import "GameObjects.h"
#import "AudioController.h"
@implementation Player

@synthesize activeSpells, spellBeingCast, energy, maximumEnergy, spellTarget, additionalTargets, statusText;
@synthesize position;

-(id)initWithHealth:(NSInteger)hlth energy:(NSInteger)enrgy energyRegen:(NSInteger)energyRegen
{
	health = maximumHealth = hlth;
	energy = enrgy;
	energyRegenPerSecond = energyRegen;
	maximumEnergy = enrgy;
	targetIsSelf = NO;
	spellTarget = nil;
	spellBeingCast = nil;
	isCasting = NO;
	lastEnergyRegen = 0.0f;
	statusText = @"";
	position = 0;
	maxChannelTime = 5;
    castStart = 0.0f;
	
	for (int i = 0; i < CastingDisabledReasonTotal; i++){
		castingDisabledReasons[i] = NO;
	}
	
	activeEffects = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_STATUS_EFFECTS];
	return self;
}

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
	if (isCasting){
        castStart+= timeDelta;
		if ([spellTarget isDead]){
			[spellBeingCast spellInterrupted];
			spellTarget = nil;
			spellBeingCast = nil;
			isCasting = NO;
			castStart = 0.0f;
		}
		else if ([self remainingCastTime] <= 0){
			//NSLog(@"Spell is finished being cast");
			//SPELL END CAST
			[spellBeingCast spellEndedCasting];
			[spellBeingCast combatActions:theBoss theRaid:theRaid thePlayer:self gameTime:timeDelta];
		
			spellTarget = nil;
			spellBeingCast = nil;
			isCasting = NO;
			castStart = 0.0f;
			additionalTargets = nil;
		}
		
	}
	
    lastEnergyRegen+= timeDelta;
    if (lastEnergyRegen >= 1.0)
    {
        //NSLog("Replenishing %i energy", energyRegenPerSecond);
        [self setEnergy:energy + energyRegenPerSecond + [self channelingBonus]];
        lastEnergyRegen = 0.0;
    }
	//NSLog(@"Checking Effects %i", [activeEffects count]);
	
	for (int i = 0; i < [activeEffects count]; i++){
		Effect *effect = [activeEffects objectAtIndex:i];
		[effect combatActions:theBoss theRaid:theRaid thePlayer:self gameTime:timeDelta];
		if ([effect isExpired]){
			[effect expire];
			[activeEffects removeObjectAtIndex:i];
		}
	}
	/*
	for (Effect *effect in activeEffects){
		[effect combatActions:theBoss theRaid:theRaid thePlayer:self gameTime:theTime];
		if ([effect isExpired]){
			[activeEffects removeObject:effect];
		}
	}*/
	
}

-(NSTimeInterval) remainingCastTime
{
	if (castStart != 0.0 && isCasting){
		return castStart - [spellBeingCast castTime];
	}
	else {
		return 0.0;
	}
}

-(BOOL)canCast{
	BOOL cast = NO;
	for (int i = 0; i < CastingDisabledReasonTotal; i++){
		cast = cast || castingDisabledReasons[i];
	}
	return !cast;
}

-(void)enableCastingWithReason:(CastingDisabledReason)reason{
	castingDisabledReasons[reason] = NO;
	
}
-(void)disableCastingWithReason:(CastingDisabledReason)reason{
	castingDisabledReasons[reason] = YES;
	[spellBeingCast spellInterrupted];
	spellTarget = nil;
	spellBeingCast = nil;
	isCasting = NO;
	castStart = 0.0;
	additionalTargets = nil;
}


-(void)beginCasting:(Spell*)theSpell withTargets:(NSArray*)targets
{
	if ([self canCast] == NO){
		return;
	}
	
	RaidMember* primaryTarget = [targets objectAtIndex:0];
	
	if (spellBeingCast == theSpell && spellTarget == primaryTarget ) {
		//NSLog(@"Attempting a recast on the same target.  Cancelling..");
		return;
	}
	//NSLog(@"Energy: %i, Cost: %i", [self energy], [theSpell energyCost]);
	NSInteger energyDiff = [self energy] - [theSpell energyCost];
	//NSLog(@"Energy Diff: %i", energyDiff);
	if (energyDiff < 0) {
		NSLog(@"Not enough energy");
		[[AudioController sharedInstance] playTitle:OUT_OF_MANA_TITLE];
		return;
	}
	//SPELL BEGIN CAST
	[theSpell spellBeganCasting];
	spellBeingCast = theSpell;
	spellTarget = primaryTarget;
	castStart = 0.0001;
	isCasting = YES;
	
	additionalTargets = [targets copyWithZone:nil];
	
}

-(void)setEnergy:(NSInteger)newEnergy
{
	energy = newEnergy;
	if (energy < 0) energy = 0;
	if (energy > maximumEnergy) energy = maximumHealth;
}

-(int)channelingBonus{
	
	if ([self channelingTime] >= maxChannelTime){
		//NSLog(@"Bonus is 10");
		return 10;
	}
	else if ([self channelingTime] >= .5 * maxChannelTime){
		//NSLog(@"Bonus is 5");
		return 6;
		
	}
	else if ([self channelingTime] >= .25 * maxChannelTime){
		//NSLog(@"Bonus is 2");
		return 3;
	}
	
	return 0;
}

-(void)startChanneling{
	channelingStartTime = 0.0001;
	[self disableCastingWithReason:CastingDisabledReasonChanneling];
	
	[[AudioController sharedInstance] playTitle:CHANNELING_SPELL_TITLE looping:20];
	
}

-(void)stopChanneling{
	channelingStartTime = 0.0;
	[self enableCastingWithReason:CastingDisabledReasonChanneling];
	
	[[AudioController sharedInstance] stopTitle:CHANNELING_SPELL_TITLE];
}

-(NSTimeInterval)channelingTime{
	if (channelingStartTime != 0.0){
		return channelingStartTime;	
	}
	
	return 0.0;
}

-(BOOL)isDead{
	return health <= 0;
}
@end

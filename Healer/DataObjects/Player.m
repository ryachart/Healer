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
#import <GameKit/GameKit.h>
#import "Divinity.h"

@implementation Player

@synthesize activeSpells, spellBeingCast, energy, maximumEnergy, spellTarget, additionalTargets, statusText;
@synthesize position, logger, spellsOnCooldown=_spellsOnCooldown, announcer, playerID, isAudible;
@synthesize divinityConfig;

-(id)initWithHealth:(NSInteger)hlth energy:(NSInteger)enrgy energyRegen:(NSInteger)energyRegen
{
    if (self = [super init]){
        self.isAudible = YES;
        health = maximumHealth = hlth;
        energy = enrgy;
        energyRegenPerSecond = energyRegen;
        maximumEnergy = enrgy;
        targetIsSelf = NO;
        spellTarget = nil;
        spellBeingCast = nil;
        isCasting = NO;
        lastEnergyRegen = 0.0f;
        self.statusText = @"";
        position = 0;
        maxChannelTime = 5;
        castStart = 0.0f;
        
        _spellsOnCooldown = [[NSMutableSet setWithCapacity:4] retain];
        
        for (int i = 0; i < CastingDisabledReasonTotal; i++){
            castingDisabledReasons[i] = NO;
        }
        
    }
	return self;
}

- (void)setDivinityConfig:(NSDictionary *)divCnfg {
    [divinityConfig release];
    divinityConfig = [divCnfg retain];
    
    NSMutableArray *divinityEffectsToRemove = [NSMutableArray arrayWithCapacity:5];
    for (Effect *effect in self.activeEffects){
        if (effect.effectType == EffectTypeDivinity){
            [divinityEffectsToRemove addObject:effect];
        }
    }
    for (Effect* effect in divinityEffectsToRemove){
        [self.activeEffects removeObject:effect];
    }
    NSArray *newDivinityEffects = [Divinity effectsForConfiguration:divinityConfig];
    for (Effect *effect in newDivinityEffects){
        [self addEffect:effect];
    }
    
}

- (void)setActiveSpells:(NSArray *)actSpells{
    for (Spell* spell in actSpells){
        [spell setOwner:self];
    }
    [activeSpells release];
    activeSpells = [actSpells retain];
}

- (NSString*)initialStateMessage{
    return @"ERRR:UNIMPL";
}

- (NSString*)networkID{
    return [NSString stringWithFormat:@"P-%@", self.playerID];
}

- (NSString*)asNetworkMessage{
    NSString *message = [NSString stringWithFormat:@"PLYR|%@|%i|%i|", self.playerID, self.health, self.energy];
    return message;
}
- (void)updateWithNetworkMessage:(NSString*)message{
    NSArray *components = [message componentsSeparatedByString:@"|"];
    if ([self.playerID isEqualToString:[components objectAtIndex:1]]){
        self.health = [[components objectAtIndex:2] intValue];
        self.energy = [[components objectAtIndex:3] intValue];
    }else{
        NSLog(@"IM BEING UPDATED WITH A DIFFERENT PLAYER OBJECT.");
    }
}

-(void)dealloc{
    [activeSpells release];
    [announcer release];
    [spellBeingCast release];
    [statusText release];
    [playerID release];
    [_spellsOnCooldown release]; _spellsOnCooldown = nil;
    [additionalTargets release]; additionalTargets = nil;
    [divinityConfig release];
    [super dealloc];
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
        [self.healthAdjustmentModifiers removeObject:effect];
        [activeEffects removeObject:effect];
    }
}

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
	if (isCasting){
        castStart+= timeDelta;
		if ([spellTarget isDead]){
            [self interrupt];
		}
		else if ([self remainingCastTime] <= 0){
			//SPELL END CAST
            if (self.isAudible){
                [spellBeingCast spellEndedCasting];
            }
			[spellBeingCast combatActions:theBoss theRaid:theRaid thePlayer:self gameTime:timeDelta];
		
			spellTarget = nil;
			spellBeingCast = nil;
			isCasting = NO;
			castStart = 0.0f;
			[additionalTargets release]; additionalTargets = nil;
		}
		
	}
	
    lastEnergyRegen+= timeDelta;
    if (lastEnergyRegen >= 1.0)
    {
        [self setEnergy:energy + energyRegenPerSecond + [self channelingBonus]];
        lastEnergyRegen = 0.0;
    }
    
    [self updateEffects:theBoss raid:theRaid player:self time:timeDelta];
    
    NSMutableArray *spellsOffCooldown = [NSMutableArray  arrayWithCapacity:4];
    for (Spell *spell in [self spellsOnCooldown]){
        [spell updateCooldowns:timeDelta];
        if (spell.cooldownRemaining == 0){
            [spellsOffCooldown  addObject:spell];
        }
    }
    
    for (Spell *spellToRemove in spellsOffCooldown){
        [self.spellsOnCooldown removeObject:spellToRemove];
    }
	
}

- (void)interrupt{
    if (self.isAudible){
        [spellBeingCast spellInterrupted];
    }
    spellTarget = nil;
    spellBeingCast = nil;
    isCasting = NO;
    castStart = 0.0f;
}

-(NSTimeInterval) remainingCastTime
{
	if (castStart != 0.0 && isCasting){
		return [spellBeingCast castTime] - castStart;
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
    if (self.isAudible){
        [spellBeingCast spellInterrupted];
    }
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
	NSInteger energyDiff = [self energy] - [theSpell energyCost];
	if (energyDiff < 0) {
        if (self.isAudible){
            [self.announcer errorAnnounce:@"Not enough Energy"];
            [[AudioController sharedInstance] playTitle:OUT_OF_MANA_TITLE];
        }
		return;
	}
	//SPELL BEGIN CAST
    if (self.isAudible){
        [theSpell spellBeganCasting];
    }
	spellBeingCast = theSpell;
	spellTarget = primaryTarget;
	castStart = 0.0001;
	isCasting = YES;
	
    [additionalTargets release];
	additionalTargets = [targets retain];
	
}

-(void)setEnergy:(NSInteger)newEnergy
{
	energy = newEnergy;
	if (energy < 0) energy = 0;
	if (energy > maximumEnergy) energy = maximumEnergy;
}

-(int)channelingBonus{
	
	if ([self channelingTime] >= maxChannelTime){
		return 10;
	}
	else if ([self channelingTime] >= .5 * maxChannelTime){
		return 6;
		
	}
	else if ([self channelingTime] >= .25 * maxChannelTime){
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

-(NSString*)sourceName{
    return [NSString stringWithFormat:@"PLAYER:%@", self.battleID];
}

-(NSString*)targetName{
    return [self sourceName];
}

-(BOOL)isDead{
	return health <= 0;
}
@end

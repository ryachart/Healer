//
//  Player.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HealableTarget.h"

/* The Player class contains the necessary information for managing a player while
	the game is taking place.  The Player is not a data type that persists between games
	to track data (such as high scores, progression, learned spells, etc).  
*/

enum CastingDisabledReason {
	CastingDisabledReasonMoving = 0,
	CastingDisabledReasonChanneling = 1,
	CastingDisabledReasonTotal = 2
};

typedef int CastingDisabledReason;

#define MAXIMUM_SPELLS_ALLOWED 4
#define CHANNELING_SPELL_TITLE @"PlayerChanneling"
#define OUT_OF_MANA_TITLE @"OutOfMana"

@class Boss;
@class Raid;
@class Spell;
@class RaidMember;

@interface Player : HealableTarget {
	//In Game Data
	NSArray *activeSpells;
	NSInteger energy;
	NSInteger energyRegenPerSecond;
	NSInteger maximumEnergy;
	
	//Spell Casting Data
	BOOL targetIsSelf;
	BOOL isCasting;
	Spell *spellBeingCast;
	RaidMember *spellTarget;
	NSDate *castStart;
	NSArray *additionalTargets;
	
	//Temporal Combat Data
	NSDate *lastEnergyRegen;
	NSDate *channelingStartTime;
	NSTimeInterval maxChannelTime;
	
	//Location Data
	NSInteger position;
	
	NSString *statusText;
	
	BOOL castingDisabledReasons[CastingDisabledReasonTotal];
	
}
@property (assign) NSArray *activeSpells;
@property (retain) Spell *spellBeingCast;
@property (setter=setEnergy) NSInteger energy;
@property (nonatomic, copy) NSDate *castStart;
@property (nonatomic, copy) NSDate *lastEnergyRegen;
@property (assign) NSArray* additionalTargets;
@property (assign) RaidMember* spellTarget;
@property (nonatomic, retain) NSString *statusText;
@property NSInteger position;
@property NSInteger maximumEnergy;

-(id)initWithHealth:(NSInteger)hlth energy:(NSInteger)enrgy energyRegen:(NSInteger)energyRegen;

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid gameTime:(NSDate*)theTime;

-(void)disableCastingWithReason:(CastingDisabledReason)reason;
-(void)enableCastingWithReason:(CastingDisabledReason)reason;

-(void)beginCasting:(Spell*)theSpell withTargets:(NSArray*)targets;
-(BOOL)canCast;
-(NSTimeInterval) remainingCastTime;

//Channeling Info
-(int)channelingBonus;
-(void)startChanneling;
-(void)stopChanneling;
-(NSTimeInterval)channelingTime;

-(BOOL)isDead;
-(void)setEnergy:(NSInteger)newEnergy;
@end

//
//  Player.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HealableTarget.h"
#import "Announcer.h"

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
@class Effect;

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
	float castStart;
	NSArray *additionalTargets;
	
	//Temporal Combat Data
	float lastEnergyRegen;
	float channelingStartTime;
	NSTimeInterval maxChannelTime;
	
	//Location Data
	NSInteger position;
	
	NSString *statusText;
	
	BOOL castingDisabledReasons[CastingDisabledReasonTotal];
}
@property (nonatomic, retain) NSArray *activeSpells;
@property (nonatomic, assign) id<Announcer> announcer;
@property (nonatomic, readonly)  NSMutableSet *spellsOnCooldown;
@property (nonatomic, retain) NSDictionary *divinityConfig;
@property (retain) Spell *spellBeingCast;
@property (nonatomic, setter=setEnergy:) NSInteger energy;
@property (retain) NSArray* additionalTargets;
@property (retain) RaidMember* spellTarget;
@property (nonatomic, retain) NSString *statusText;
@property NSInteger position;
@property NSInteger maximumEnergy;
@property (nonatomic, readwrite) float castTimeAdjustment;

- (id)initWithHealth:(NSInteger)hlth energy:(NSInteger)enrgy energyRegen:(NSInteger)energyRegen;

- (void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid gameTime:(float)timeDelta;

- (void)disableCastingWithReason:(CastingDisabledReason)reason;
- (void)enableCastingWithReason:(CastingDisabledReason)reason;

- (void)beginCasting:(Spell*)theSpell withTargets:(NSArray*)targets;
- (BOOL)canCast;
- (NSTimeInterval) remainingCastTime;

- (void)interrupt;

//Channeling Info
- (int)channelingBonus;
- (void)startChanneling;
- (void)stopChanneling;
- (NSTimeInterval)channelingTime;

- (BOOL)isDead;
- (void)setEnergy:(NSInteger)newEnergy;

- (void)playerDidHealFor:(NSInteger)amount onTarget:(RaidMember*)target fromSpell:(Spell*)spell;
- (void)playerDidHealFor:(NSInteger)amount onTarget:(RaidMember *)target fromEffect:(Effect *)effect;

- (NSString*)initialStateMessage; //For notifying servers what our player state looks like
- (NSString*)asNetworkMessage;
- (void)updateWithNetworkMessage:(NSString*)message;

- (BOOL)hasDivinityEffectWithTitle:(NSString*)title;
//Multiplayer
@property (nonatomic, retain) NSString* playerID;
@property (nonatomic, readwrite) BOOL isAudible; //Turn off other sounds;
@end

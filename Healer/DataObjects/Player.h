//
//  Player.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RaidMember.h"
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

@class Enemy;
@class Raid;
@class Spell;
@class Effect;

#define MINIMUM_AVATAR_TRIGGER_AMOUNT 25
@protocol RedemptionDelegate;

@interface Player : RaidMember <RedemptionDelegate> {
	BOOL castingDisabledReasons[CastingDisabledReasonTotal];
}
@property (nonatomic, retain) NSArray *activeSpells;
@property (nonatomic, retain, readonly) NSMutableSet *spellsOnCooldown;
@property (nonatomic, retain) NSDictionary *divinityConfig;
@property (nonatomic, retain) Spell *spellBeingCast;
@property (nonatomic, readwrite) float energy;
@property (nonatomic, retain) NSArray* additionalTargets;
@property (nonatomic, assign) RaidMember* spellTarget;
@property (nonatomic, retain) NSString *statusText;
@property (nonatomic, readonly) NSInteger maximumEnergy;
@property (nonatomic, readonly) NSInteger energyRegenPerSecond;
@property (nonatomic, readwrite) float castTimeAdjustment;
@property (nonatomic, readwrite) float spellCostAdjustment;
@property (nonatomic, readwrite) float spellCriticalChance;
@property (nonatomic, readwrite) float criticalBonusMultiplier;
@property (nonatomic, readwrite) float cooldownAdjustment;
@property (nonatomic, readwrite) NSInteger avatarCounter;
@property (nonatomic, readwrite) BOOL isConfused;
@property (nonatomic, readwrite) NSInteger overhealingToDistribute;
@property (nonatomic, readwrite) BOOL isCasting;
@property (nonatomic, readwrite) float castStart;
@property (nonatomic, readwrite) BOOL shouldAttack;

//Temporal Combat Data
@property (nonatomic, readwrite) float lastEnergyRegen;
@property (nonatomic, readwrite) float channelingStartTime;
@property (nonatomic, readwrite) NSTimeInterval maxChannelTime;

- (id)initWithHealth:(NSInteger)hlth energy:(NSInteger)enrgy energyRegen:(NSInteger)energyRegen;

- (float)castTimeAdjustmentForSpell:(Spell*)spell;
- (float)spellCostAdjustmentForSpell:(Spell*)spell;
- (float)healingDoneMultiplierForSpell:(Spell*)spell;

- (void)disableCastingWithReason:(CastingDisabledReason)reason;
- (void)enableCastingWithReason:(CastingDisabledReason)reason;

- (void)beginCasting:(Spell*)theSpell withTargets:(NSArray*)targets;
- (BOOL)canCast;
- (NSTimeInterval)remainingCastTime;
- (void)interrupt;

- (int)channelingBonus;
- (void)startChanneling;
- (void)stopChanneling;
- (NSTimeInterval)channelingTime;

- (void)playerDidHealFor:(NSInteger)amount onTarget:(RaidMember*)target fromSpell:(Spell*)spell withOverhealing:(NSInteger)overhealing asCritical:(BOOL)critical;
- (void)playerDidHealFor:(NSInteger)amount onTarget:(RaidMember *)target fromEffect:(Effect *)effect withOverhealing:(NSInteger)overhealing asCritical:(BOOL)critical;

- (BOOL)hasDivinityEffectWithTitle:(NSString*)title;

- (void)configureForRecommendedSpells:(NSArray*)recommendSpells withLastUsedSpells:(NSArray*)lastUsedSpells;

//Multiplayer
@property (nonatomic, retain) NSString* playerID;
@property (nonatomic, readwrite) BOOL isLocalPlayer; //Turn off other sounds, this is sort of a buggy thing...;
@property (nonatomic, readonly) NSString* spellsAsNetworkMessage;

- (NSString*)initialStateMessage; //For notifying servers what our player state looks like
- (NSString*)asNetworkMessage;
- (void)updateWithNetworkMessage:(NSString*)message;
@end

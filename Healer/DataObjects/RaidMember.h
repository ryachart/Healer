//
//  RaidMember.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

/* A RaidMember can be one of three types:
	Troll
	Ogre
	Witch
 
	This is the parent class for these three subtypes.
	A RaidMember class can not stand on its own.
 */

#import <Foundation/Foundation.h>
#import "HealableTarget.h"
#import "CombatEvent.h"
#import "Announcer.h"

@class Boss;
@class Raid;
@class Player;

typedef enum {
    Any = 0,
    Ranged,
    Melee
} Positioning;

@interface RaidMember : HealableTarget {
	float damageFrequency; //All Raid members deal damage at some frequency
	
	//Combat Action Data
	float lastAttack;
	
}
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* info;
@property (nonatomic,  readwrite) NSInteger damageDealt; //All RaidMembers deal some damage
@property (readwrite) float lastAttack;
@property (nonatomic, readwrite) float dodgeChance;
@property (readwrite) float criticalChance;
@property (readonly) Positioning positioning;
@property (nonatomic, assign) id<Announcer>announcer;

- (float)dps;
- (id)initWithHealth:(NSInteger)hlth damageDealt:(NSInteger)damage andDmgFrequency:(float)dmgFreq andPositioning:(Positioning)position;
- (BOOL)raidMemberShouldDodgeAttack:(float)modifer;
- (void)didPerformCriticalStrikeForAmount:(NSInteger)amount;
//This function is overriden by each subtype of RaidMember.
//It allows a RaidMember to be asked to take any combatActions while the games goes on.
//It also allows a RaidMember to deal damage.
- (void)combatActions:(Boss*)theBoss raid:(Raid*)theRaid players:(NSArray*)players gameTime:(float)timeDelta;

- (NSString*)asNetworkMessage;
- (void)updateWithNetworkMessage:(NSString*)message;
@end

//AVERAGE HEALTH: 1240
@interface Guardian : RaidMember
+(Guardian*)defaultGuardian;
@end
@interface Berserker : RaidMember 
+(Berserker*)defaultBerserker;
@end
@interface Archer : RaidMember 
+(Archer*)defaultArcher;
@end
@interface Wizard : RaidMember{
    float lastEnergyGrant;
}
@property (nonatomic, readwrite) BOOL energyGrantAnnounced;
+(Wizard*)defaultWizard;
@end
@interface Champion : RaidMember
@property (nonatomic, readwrite) BOOL deathEffectApplied;
+(Champion *)defaultChampion;
@end
@interface Warlock : RaidMember
@property (nonatomic, readwrite) BOOL deathEffectApplied;
+(Warlock*)defaultWarlock;
@end
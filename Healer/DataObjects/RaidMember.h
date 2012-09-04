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

@class Boss;
@class Raid;
@class Player;

typedef enum {
    Ranged,
    Melee,
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
@property (readwrite) float dodgeChance;
@property (readwrite) float criticalChance;
@property (readonly) Positioning positioning;

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

//AVERAGE HEALTH: 124
@interface Guardian : RaidMember
@property (nonatomic, readwrite) NSInteger overhealingShield;
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
+(Wizard*)defaultWizard;
@end
@interface Champion : RaidMember 
+(Champion *)defaultChampion;
@end
@interface Warlock : RaidMember
@property (nonatomic, readwrite) NSTimeInterval healCooldown;
+(Warlock*)defaultWarlock;
@end
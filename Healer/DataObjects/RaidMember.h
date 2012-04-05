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
@interface RaidMember : HealableTarget {
	float damageFrequency; //All Raid members deal damage at some frequency
	
	//Combat Action Data
	float lastAttack;
	
}
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* info;
@property (nonatomic, retain) NSString* battleID;
@property (nonatomic,  readwrite) NSInteger damageDealt; //All RaidMembers deal some damage
@property (readwrite) float lastAttack;
@property (readwrite) float dodgeChance;
-(float)dps;

-(id) initWithHealth:(NSInteger)hlth damageDealt:(NSInteger)damage andDmgFrequency:(float)dmgFreq;
-(BOOL)raidMemberShouldDodgeAttack:(float)modifer;

//This function is overriden by each subtype of RaidMember.
//It allows a RaidMember to be asked to take any combatActions while the games goes on.
//It also allows a RaidMember to deal damage.
-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta;


@end


@interface Guardian : RaidMember 
+(Guardian*)defaultGuardian;
@end
@interface Soldier : RaidMember 
+(Soldier*)defaultSoldier;
@end
@interface Demonslayer : RaidMember 
+(Demonslayer*)defaultDemonslayer;
@end
@interface Wizard : RaidMember{
    float lastEnergyGrant;
}
+(Wizard*)defaultWizard;
@end
@interface Champion : RaidMember 
+(Champion *)defaultChampion;
@end
@interface Berserker : RaidMember
+(Berserker*)defaultBerserker;
@end
#pragma mark - Deprecated
//Witches deal the most damage but take the most damage
@interface Witch : RaidMember {
	
}

+(Witch*)defaultWitch;

@end

//Trolls deal average damage, but slowly regenerate health by themselves
@interface Troll : RaidMember{
		
}
+(Troll*)defaultTroll;

@end

//Ogres deal the least damage, but take the least damage.
@interface Ogre : RaidMember {

}
+(Ogre*)defaultOgre;
@end
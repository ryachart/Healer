//
//  Boss.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CombatEvent.h"
#import "Announcer.h"
#import "Agent.h"
@class Player;
@class Raid;
@class RaidMember;
@class Effect;
/*A collection of data regarding a boss.
  To make special bosses, subclass boss and override
  combatActions.
 */
@interface Boss : Agent {
	NSInteger health;
	NSInteger maximumHealth;
	NSInteger damage;
	NSInteger targets;
	float frequency;
	BOOL choosesMainTank;
	NSString *title;
	
	//Combat Action Data
    BOOL healthThresholdCrossed[101];
}
@property (nonatomic, readwrite) BOOL isMultiplayer;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) id <Announcer> announcer;
@property (nonatomic, setter=setHealth:) NSInteger health;
@property (nonatomic, readwrite) float criticalChance;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, assign) id<EventLogger> logger;
@property (nonatomic, readwrite) NSInteger phase;
@property NSInteger maximumHealth;

@property (nonatomic, readwrite) float lastAttack;

-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq andChoosesMT:(BOOL)chooses;
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(float)timeDelta;
-(void)setHealth:(NSInteger)newHealth;
-(BOOL)isDead;
-(float)healthPercentage; //In Hundreds form
+(id)defaultBoss;
-(void)healthPercentageReached:(float)percentage withRaid:(Raid*)raid andPlayer:(Player*)player;
@end


#pragma mark - Shipping Bosses
@interface Ghoul : Boss
@end

@interface CorruptedTroll : Boss
@property (readwrite) NSTimeInterval lastRockTime;
@property (readwrite) NSTimeInterval enraging;
@end

@interface Drake : Boss
@property (readwrite) NSTimeInterval lastFireballTime;
@end

@interface Trulzar : Boss
@property (readwrite) NSTimeInterval lastPoisonTime;
@property (readwrite) NSTimeInterval lastPotionTime;
@end

@interface DarkCouncil : Boss
@property (nonatomic, retain) RaidMember *rothVictim;
@property (readwrite) NSTimeInterval lastPoisonballTime;
@property (readwrite) NSTimeInterval lastDarkCloud;
@end

@interface PlaguebringerColossus: Boss
@property (readwrite) NSInteger numBubblesPopped;
@property (readwrite) NSTimeInterval lastSickeningTime;
@end

@interface SporeRavagers : Boss
@property (readwrite) NSTimeInterval lastSecondaryAttack;
@property (readwrite) BOOL isEnraged;
@property (nonatomic, retain) RaidMember *focusTarget2;
@property (nonatomic, retain) RaidMember *focusTarget3;

@end

@interface MischievousImps: Boss
@property (readwrite) NSTimeInterval lastPotionThrow;
@end

@interface BefouledTreat : Boss
@property (readwrite) NSTimeInterval lastRootquake;
@end

@interface TwinChampions : Boss
@property (nonatomic, retain) RaidMember *focusTarget2;
@property (nonatomic, readwrite) NSTimeInterval lastFocusTarget2Attack;
@property (nonatomic, readwrite) NSTimeInterval lastAxecution;
@property (nonatomic, readwrite) NSTimeInterval lastGushingWound;
@end

@interface Baraghast : Boss
@end

@interface CrazedSeer : Boss
@end

@interface GatekeeperDelsarn : Boss
@end

@interface SkeletalDragon: Boss
@end

@interface ColossusOfBone : Boss
@end

@interface OverseerOfDelsarn : Boss
@end

@interface TheUnspeakable : Boss
@end

@interface BaraghastReborn : Boss
@end

@interface AvatarOfTorment1 : Boss
@end

@interface AvatarOfTorment2 : Boss
@end

@interface SoulOfTorment : Boss
@end


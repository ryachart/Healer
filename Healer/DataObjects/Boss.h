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
#import "HealableTarget.h"
#import "PlayerDataManager.h"

@class Player;
@class Raid;
@class RaidMember;
@class Effect;
@class Ability;
@class AbilityDescriptor;
/*A collection of data regarding a boss.
  To make special bosses, subclass boss and override
  combatActions.
 */
@interface Boss : HealableTarget {	
	//Combat Action Data
    BOOL healthThresholdCrossed[101];
}
@property (nonatomic, readwrite) BOOL isMultiplayer;
@property (nonatomic, readwrite) NSInteger difficulty;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, assign) id <Announcer> announcer;
@property (nonatomic, readwrite) float criticalChance;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, assign) id<EventLogger> logger;
@property (nonatomic, readwrite) NSInteger phase;
@property (nonatomic, readwrite) NSTimeInterval duration;
@property (nonatomic, retain) NSMutableArray *abilities;
@property (nonatomic, retain) NSArray *abilityDescriptors;
@property (nonatomic, assign) Ability *autoAttack;
@property (nonatomic, retain) NSString *namePlateTitle;

+ (id)defaultBoss;
- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses;

- (void)combatActions:(NSArray*)player theRaid:(Raid*)theRaid gameTime:(float)timeDelta;

- (float)healthPercentage; //In Hundreds form
- (void)healthPercentageReached:(float)percentage withRaid:(Raid*)raid andPlayer:(Player*)player;


- (void)configureBossForDifficultyLevel:(NSInteger)difficulty;

#pragma Ability Methods
- (void)addAbility:(Ability*)ability;
- (void)removeAbility:(Ability*)ability;
- (void)addAbilityDescriptor:(AbilityDescriptor*)descriptor;
- (void)clearExtraDescriptors;
- (Ability*)abilityWithTitle:(NSString*)ability;

- (void)ownerWillExecuteAbility:(Ability*)ability;
- (void)ownerDidExecuteAbility:(Ability*)ability;
- (void)ownerDidBeginAbility:(Ability*)ability;

@end


#pragma mark - Shipping Bosses
@interface Ghoul : Boss
@end

@interface CorruptedTroll : Boss
@property (nonatomic, assign) Ability *caveIn;
@property (readwrite) NSTimeInterval enraging;
@end

@interface Drake : Boss
@property (nonatomic, readwrite, assign) Ability *fireballAbility;
@end

@interface Trulzar : Boss
@property (nonatomic, assign) Ability *poisonNova;
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

@class FocusedAttack;
@interface FungalRavagers : Boss
@property (readwrite) BOOL isEnraged;
@property (nonatomic, assign) FocusedAttack *secondTargetAttack;
@property (nonatomic, assign) FocusedAttack *thirdTargetAttack;

@end

@interface MischievousImps: Boss
@property (readwrite) NSTimeInterval lastPotionThrow;
@end

@interface BefouledTreant : Boss
@property (readwrite) NSTimeInterval lastRootquake;
@end

@interface TwinChampions : Boss
@property (nonatomic, assign) FocusedAttack *firstFocusedAttack;
@property (nonatomic, assign) FocusedAttack *secondFocusedAttack;
@property (nonatomic, readwrite) NSTimeInterval lastAxecution;
@property (nonatomic, readwrite) NSTimeInterval lastGushingWound;
@end

@interface Baraghast : Boss
@property (nonatomic, retain) NSMutableArray *remainingAbilities;
@end

@interface CrazedSeer : Boss
@end

@interface GatekeeperDelsarn : Boss
@end

@interface SkeletalDragon: Boss
@property (nonatomic, retain) Ability *boneThrowAbility;
@property (nonatomic, retain) Ability *sweepingFlame;
@property (nonatomic, retain) Ability *tailLash;
@property (nonatomic, retain) FocusedAttack *tankDamage;
@end

@interface ColossusOfBone : Boss
@property (nonatomic, readwrite) BOOL hasShownCrushingPunchThisCooldown;
@property (nonatomic, retain) Ability *boneQuake;
@property (nonatomic, retain) Ability *crushingPunch;
@end

@interface OverseerOfDelsarn : Boss
@property (nonatomic, retain) Ability *projectilesAbility;
@property (nonatomic, retain) NSMutableArray *demonAbilities;
@end

@interface TheUnspeakable : Boss
@property (nonatomic, retain) Ability *oozeAll;
@end

@interface BaraghastReborn : Boss
@property (nonatomic, retain) Ability *deathwave;
@end

@interface AvatarOfTorment1 : Boss
@end

@interface AvatarOfTorment2 : Boss
@end

@interface SoulOfTorment : Boss
@end

@interface TheEndlessVoid : Boss
@end

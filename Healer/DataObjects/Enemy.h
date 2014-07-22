//
//  Boss.h
//  Healer
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CombatEvent.h"
#import "Announcer.h"
#import "HealableTarget.h"
#import "PlayerDataManager.h"

#define kThreatPriorityDead -9999
#define kThreatPriorityRandom -9998

@class Player;
@class Raid;
@class RaidMember;
@class Effect;
@class Ability;
@class AbilityDescriptor;

@interface Enemy : HealableTarget {	
    BOOL healthThresholdCrossed[101];
}
@property (nonatomic, readwrite) BOOL inactive;
@property (nonatomic, readwrite) BOOL isMultiplayer;
@property (nonatomic, readwrite) NSInteger difficulty;
@property (nonatomic, readwrite) float criticalChance;
@property (nonatomic, assign) id<EventLogger> logger;
@property (nonatomic, readwrite) NSInteger phase;
@property (nonatomic, retain) NSMutableArray *abilities;
@property (nonatomic, retain) NSArray *abilityDescriptors;
@property (nonatomic, assign) Ability *autoAttack;
@property (nonatomic, assign) Ability *stunnedAbility;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString *namePlateTitle;
@property (nonatomic, retain) NSString *spriteName;
@property (nonatomic, readwrite) NSInteger threatPriority;

@property (nonatomic, readonly) Ability *visibleAbility;
@property (nonatomic, readonly) RaidMember *target;
@property (nonatomic, readonly) BOOL isBusy;
+ (id)defaultBoss;
- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses;

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta;

- (float)healthPercentage; //In Hundreds form
- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta;

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty;

- (void)stunForDuration:(NSTimeInterval)duration;
- (void)ownerDidDamageTarget:(RaidMember*)target withEffect:(Effect*)effect forDamage:(NSInteger)damage;

#pragma Ability Methods
- (void)addAbility:(Ability*)ability;
- (void)removeAbility:(Ability*)ability;
- (void)addAbilityDescriptor:(AbilityDescriptor*)descriptor;
- (void)clearExtraDescriptors;
- (Ability*)abilityWithKey:(NSString*)ability;

- (void)ownerDidDamageTarget:(RaidMember*)target withAbility:(Ability*)ability forDamage:(NSInteger)damage;
- (void)ownerWillExecuteAbility:(Ability*)ability;
- (void)ownerDidExecuteAbility:(Ability*)ability;
- (void)ownerDidBeginAbility:(Ability*)ability;
- (void)ownerDidChannelTickForAbility:(Ability *)ability;

@end


#pragma mark - Shipping Bosses
@interface Ghoul : Enemy
@end

@interface CorruptedTroll : Enemy
@property (nonatomic, assign) Ability *smash;
@property (readwrite) NSTimeInterval enraging;
@end

@interface Drake : Enemy
@property (nonatomic, readwrite, assign) Ability *fireballAbility;
@end

@interface Trulzar : Enemy
@property (nonatomic, assign) Ability *poisonNova;
@property (readwrite) NSTimeInterval lastPoisonTime;
@property (readwrite) NSTimeInterval lastPotionTime;
@end

@interface Teritha : Enemy
@end

@interface Grimgon : Enemy
@end

@interface Galcyon : Enemy
@end

@interface DarkCouncil : Enemy
@end

@interface PlaguebringerColossus: Enemy
@property (readwrite) NSInteger numBubblesPopped;
@end

@interface FinalRavager : Enemy
@end

@interface MischievousImps: Enemy
@property (readwrite) NSTimeInterval lastPotionThrow;
@end

@interface BefouledTreant : Enemy
@end

@interface Sarroth : Enemy

@end

@interface Vorroth : Enemy

@end

@interface Baraghast : Enemy
@property (nonatomic, retain) NSMutableArray *remainingAbilities;
@end

@interface CrazedSeer : Enemy
@end

@interface GatekeeperDelsarn : Enemy
@end

@class FocusedAttack;
@interface SkeletalDragon: Enemy
@property (nonatomic, retain) Ability *boneThrowAbility;
@property (nonatomic, retain) Ability *sweepingFlame;
@property (nonatomic, retain) Ability *tailLash;
@property (nonatomic, retain) FocusedAttack *tankDamage;
@end

@interface ColossusOfBone : Enemy
@property (nonatomic, readwrite) BOOL hasShownCrushingPunchThisCooldown;
@property (nonatomic, retain) Ability *boneQuake;
@property (nonatomic, retain) Ability *crushingPunch;
@end

@interface OverseerOfDelsarn : Enemy
@property (nonatomic, retain) Ability *projectilesAbility;
@property (nonatomic, retain) NSMutableArray *demonAbilities;
@end

@interface TheUnspeakable : Enemy
@property (nonatomic, retain) Ability *oozeAll;
@end

@interface BaraghastReborn : Enemy
@property (nonatomic, retain) Ability *deathwave;
@end

@interface AvatarOfTorment1 : Enemy
@end

@interface AvatarOfTorment2 : Enemy
@end

@interface SoulOfTorment : Enemy
@property (nonatomic, readwrite) BOOL hasAddedGrowingTorment;
@end

@interface TheEndlessVoid : Enemy
@end

@interface FungalRavager : Enemy
@end

@interface TestBoss : Enemy
@end


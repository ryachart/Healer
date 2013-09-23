//
//  RaidMember.h
//  Healer
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

#import "HealableTarget.h"
#import "Announcer.h"

@class Enemy;
@class Raid;
@class Player;

typedef enum {
    Any = 0,
    Ranged,
    Melee
} Positioning;

@interface RaidMember : HealableTarget
@property (nonatomic, readwrite) BOOL isFocused;
@property (nonatomic, readwrite) float damageFrequency;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* info;
@property (nonatomic, readwrite) NSInteger damageDealt;
@property (nonatomic, readwrite) float lastAttack;
@property (nonatomic, readwrite) float dodgeChance;
@property (nonatomic, readwrite) float criticalChance;
@property (nonatomic, readwrite) Positioning positioning;
@property (nonatomic, readwrite) ccColor3B classColor;
@property (nonatomic, readwrite) BOOL isStunned;
@property (nonatomic, readwrite) float stunDuration;
@property (nonatomic, readwrite) BOOL isInvalidAttackTarget;

- (float)dps;
- (id)initWithHealth:(NSInteger)hlth damageDealt:(NSInteger)damage andDmgFrequency:(float)dmgFreq andPositioning:(Positioning)position;
- (BOOL)raidMemberShouldDodgeAttack:(float)modifer;
- (void)didPerformCriticalStrikeForAmount:(NSInteger)amount;
- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta;
- (void)performAttackIfAbleOnTarget:(Enemy*)target;
- (Enemy *)highestPriorityEnemy:(NSArray *)enemies;

- (NSString*)asNetworkMessage;
- (void)updateWithNetworkMessage:(NSString*)message;
@end

//AVERAGE HEALTH: 1240
@interface Guardian : RaidMember
+ (Guardian*)defaultGuardian;
@end

@interface Berserker : RaidMember 
+ (Berserker*)defaultBerserker;
@end

@interface Archer : RaidMember 
+ (Archer*)defaultArcher;
@end

@interface Wizard : RaidMember
@property (nonatomic, readwrite) float lastEnergyGrant;
@property (nonatomic, readwrite) BOOL energyGrantAnnounced;
+ (Wizard*)defaultWizard;
@end

@interface Champion : RaidMember
@property (nonatomic, readwrite) BOOL deathEffectApplied;
+ (Champion *)defaultChampion;
@end

@interface Warlock : RaidMember
@property (nonatomic, readwrite) BOOL deathEffectApplied;
+ (Warlock*)defaultWarlock;
@end
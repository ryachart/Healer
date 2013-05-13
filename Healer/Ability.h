//
//  Ability.h
//  Healer
//
//  Created by Ryan Hart on 5/10/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//
//


#import <Foundation/Foundation.h>
#import "RaidMember.h"
#import "ProjectileEffect.h"
#import "Collectible.h"

#define kAbilityRequiresTrigger 99999

@class Raid, Player, Enemy, Agent, HealableTarget, AbilityDescriptor, Effect;
@interface Ability : NSObject <CollectibleDelegate>

@property (nonatomic, readwrite) float failureChance;
@property (nonatomic, readwrite) float bonusCriticalChance; //In addition to owner crit chance
@property (nonatomic, readwrite) float criticalChance;
@property (nonatomic, readwrite) NSTimeInterval timeApplied;
@property (nonatomic, readwrite) NSTimeInterval cooldown; //9999 denotes an ability that must be triggered
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *info;
@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *iconName;
@property (nonatomic, assign) Enemy *owner;
@property (nonatomic, readwrite) NSInteger abilityValue; //Damage or DoT value or Number of Targets - Depends on the ability
@property (nonatomic, readwrite) BOOL isDisabled;
@property (nonatomic, readonly) AbilityDescriptor *descriptor;
@property (nonatomic, retain) NSString *attackParticleEffectName; //Defaults to blood_spurt.plist
@property (nonatomic, readwrite) NSInteger difficulty;
@property (nonatomic, readwrite) float cooldownVariance;
@property (nonatomic, readwrite) float channelTimeRemaining;
@property (nonatomic, readwrite) float maxChannelTime;
@property (nonatomic, readonly) BOOL isChanneling;
@property (nonatomic, readwrite) BOOL ignoresBusy; //This ability will trigger even when the owner is busy.
@property (nonatomic, readwrite) float dodgeChanceAdjustment;

//Activation Times
@property (nonatomic, readwrite) BOOL isActivating;
@property (nonatomic, readwrite) NSTimeInterval remainingActivationTime;
@property (nonatomic, readwrite) float remainingActivationPercentage;
@property (nonatomic, readwrite) NSTimeInterval activationTime; //How long the cast time to warn the user

//Audio
@property (nonatomic, retain) NSString *activationSound;
@property (nonatomic, retain) NSString *executionSound;


- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta;

- (void)triggerAbilityForRaid:(Raid*)theRaid players:(NSArray*)players enemies:(NSArray*)enemies;
- (void)channelTickForRaid:(Raid*)theRaid players:(NSArray*)players enemies:(NSArray*)enemies;

- (BOOL)checkFailed;
- (void)activateAbility;
- (void)abilityDidFailToActivateForRaid:(Raid*)theRaid players:(NSArray*)players enemies:(NSArray*)enemies;

- (void)willDamageTarget:(RaidMember*)target;
- (void)startChannel:(float)channel; //Zero ticks, purely visual
- (void)startChannel:(float)channel withTicks:(NSInteger)numTicks;

- (void)interrupt;
@end


@interface Attack : Ability
@property (nonatomic, readwrite) NSInteger numberOfTargets; //Default 1
@property (nonatomic, readwrite) BOOL ignoresGuardians;
@property (nonatomic, readwrite) BOOL ignoresPlayers;
@property (nonatomic, retain) Effect *appliedEffect;
@property (nonatomic, readwrite) BOOL requiresDamageToApplyEffect;
@property (nonatomic, readwrite) BOOL removesPositiveEffects;
@property (nonatomic, readwrite) BOOL prefersTargetsWithoutVisibleEffects;
@property (nonatomic, retain) NSString *damageAudioName;
- (RaidMember *)targetFromRaid:(Raid*)raid;
- (id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd;
@end

@interface FocusedAttack : Attack
@property (nonatomic, readwrite ) BOOL enrageApplied;
@property (nonatomic, retain) RaidMember *focusTarget;
@end

@interface SustainedAttack : Attack
@property (nonatomic, retain) RaidMember *focusTarget;
@property (nonatomic, readwrite) NSInteger currentAttacksRemaining;
@end

@interface BoneThrow : Ability
@end

@interface ProjectileAttack : Ability
@property (nonatomic, readwrite) BOOL ignoresGuardians;
@property (nonatomic, readwrite) NSInteger attacksPerTrigger; //Defaults to 1
@property (nonatomic, retain) Effect *appliedEffect;
@property (nonatomic, retain) NSString* spriteName;
@property (nonatomic, retain) NSString* explosionParticleName;
@property (nonatomic, retain) NSString* explosionSoundName;
@property (nonatomic, readwrite) ProjectileEffectType effectType;
@property (nonatomic, readwrite) ccColor3B projectileColor;
- (void)fireAtRaid:(Raid*)raid;

@end

typedef enum {
    OverseerProjectileFire,
    OverseerProjectileShadow,
    OverseerProjectileBlood,
    OverseerProjectileTypeAll
} OverseerProjectileType;

@interface OverseerProjectiles : Ability {
     NSInteger usableProjectiles[OverseerProjectileTypeAll];
}
- (void)setProjectileType:(OverseerProjectileType)type isUsable:(BOOL)isUsable;
- (void)setAllProjectileUsability:(BOOL)isUsable;
@end

@interface StackingDamage : Ability
@end

@interface RaidDamagePulse : Ability //Deals <abilityValue> damage over the duration to all raid members
@property (nonatomic, readwrite) NSTimeInterval duration;
@property (nonatomic, readwrite) NSInteger numTicks;
@property (nonatomic, retain) NSString *pulseSoundTitle;
@end

@interface BaraghastBreakOff : Ability
@property (nonatomic, retain) FocusedAttack *ownerAutoAttack;
@end

@interface BaraghastRoar : Ability
@property (nonatomic, readwrite) BOOL interruptAppliesDot;
@end

@interface Debilitate : Ability 
@property (nonatomic, readwrite) NSInteger numTargets;
@end

@interface Crush : Ability
@property (nonatomic, assign) RaidMember *target;
@end

@interface Deathwave : Ability 
@end

@interface RandomAbilityGenerator : Ability
@property (nonatomic, retain) NSMutableArray *managedAbilities;
@property (nonatomic, readwrite) NSInteger maxAbilities; //Defaults to 5
@end

@interface InvertedHealing : Ability
@property (nonatomic, readwrite) NSInteger numTargets;
@end

@interface SoulBurn : Ability
@end

@interface GainAbility : Ability
@property (nonatomic, retain) Ability *abilityToGain;
@end

@interface RaidDamage : Ability
@property (nonatomic, retain) Effect *appliedEffect;
@end

@interface Grip : Ability
@end

@interface Impale : Ability 
@end

@interface BloodDrinker : FocusedAttack 
@end

@interface TargetTypeAttack : Ability
@property (nonatomic, readwrite) Positioning targetPositioningType;
@property (nonatomic, readwrite) NSInteger numTargets;
@property (nonatomic, retain) Effect *appliedEffect;
@end

@interface AlternatingFlame : TargetTypeAttack
@end

@interface BoneQuake : RaidDamage
@end

@interface BloodMinion : Ability
@end

@interface FireMinion : Ability
@end

@interface ShadowMinion : Ability
@property (nonatomic, readwrite) BOOL hasAppliedDrain;
@end

@interface GroundSmash : Ability
@end

@interface RaidApplyEffect : Ability
@property (nonatomic, retain) Effect *appliedEffect;
@end

@interface OozeRaid : RaidApplyEffect
@property (nonatomic, readwrite) NSInteger originalCooldown;
@end

@interface OozeTwoTargets : Ability
@end

@interface GraspOfTheDamned : Attack
@end

@interface SoulPrison : Ability
//Abiltiy Value is Number of Targets
@end

@interface DisruptionCloud : Ability
//Ability Value is valuePerTick of the cloud
@end

@interface Confusion : Ability
//Ability Value is confusion duration
@end

@interface DisorientingBoulder : ProjectileAttack
@end

@interface Cleave : Ability
+ (Cleave *)normalCleave;
//Hits a random number of melee opponents. Always affects at least 1 Guardian when it triggers
@end

@interface EnsureEffectActiveAbility : Ability
@property (nonatomic, retain) RaidMember *victim;
@property (nonatomic, retain) Effect *ensuredEffect;
@property (nonatomic, readwrite) BOOL isChanneled;
@end

@interface WaveOfTorment : Ability
@end

@interface StackingEnrage : Ability
@property (nonatomic, retain) Effect *enrageEffect;
@end

@interface Breath : Ability
@property (nonatomic, retain) NSString *breathParticleName;
@end

@interface Earthquake : Ability
@end

@interface RandomPotionToss : Ability
- (void)triggerAbilityAtRaid:(Raid*)raid;
@end

@interface PlaguebringerSicken : Ability
@end

@interface DarkCloud : Ability
@end

@interface RaidDamageSweep : Ability
@end

@interface ChannelledEnemyAttackAdjustment : Ability
@property (nonatomic, readwrite) float damageMultiplier;
@property (nonatomic, readwrite) float attackSpeedMultiplier;
@property (nonatomic, readwrite) NSTimeInterval duration;
@end

@interface ConstrictingVines : Ability
@property (nonatomic, readwrite) float stunDuration;
@end

@interface ShatterArmor : Ability
@end

@interface BrokenWill : Ability
@property (nonatomic, retain) RaidMember *target;
@property (nonatomic, retain) SustainedAttack *additionalAttack;
@end

@interface TailLash : RaidDamage
@end

@interface BloodCrush : Crush
@end

@interface InterruptionAbility : Ability
@property (nonatomic, retain) Effect *appliedEffectOnInterrupt;
@end

@interface Soulshatter : Ability
@end

@interface ScentOfDeath : Ability
@end

@interface BlindingSmokeAttack : Ability
@end

@interface DisableSpell : Ability
@end

@interface ImproveProjectileAbility : Ability
@property (nonatomic, assign) ProjectileAttack *abilityToImprove;
@end

@interface AttackHealersAbility : Attack
@end

@interface SpewManaOrbsAbility : Ability
@end

@interface OrbsOfFury : Ability
@property (nonatomic, readwrite) float particleEffectCooldown;
@property (nonatomic, retain) Effect *ownerEffect;
@end
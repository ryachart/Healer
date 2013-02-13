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

#define kAbilityRequiresTrigger 9999

@class Raid, Player, Boss, Agent, HealableTarget, AbilityDescriptor, Effect;
@interface Ability : NSObject

@property (nonatomic, readwrite) float failureChance;
@property (nonatomic, readwrite) NSTimeInterval timeApplied;
@property (nonatomic, readwrite) NSTimeInterval cooldown; //9999 denotes an ability that must be triggered
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *info;
@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *iconName;
@property (nonatomic, assign) Boss *owner;
@property (nonatomic, readwrite) NSInteger abilityValue; //Damage or DoT value or Number of Targets - Depends on the ability
@property (nonatomic, readwrite) BOOL isDisabled;
@property (nonatomic, readonly) AbilityDescriptor *descriptor;
@property (nonatomic, retain) NSString *attackParticleEffectName; //Defaults to blood_spurt.plist
@property (nonatomic, readwrite) NSInteger difficulty;
@property (nonatomic, readwrite) float cooldownVariance;
@property (nonatomic, readwrite) float channelTimeRemaining;
@property (nonatomic, readwrite) float maxChannelTime;
@property (nonatomic, readonly) BOOL isChanneling;

//Activation Times
@property (nonatomic, readwrite) BOOL isActivating;
@property (nonatomic, readwrite) NSTimeInterval remainingActivationTime;
@property (nonatomic, readwrite) float remainingActivationPercentage;
@property (nonatomic, readwrite) NSTimeInterval activationTime; //How long the cast time to warn the user

- (void)combatActions:(Raid*)theRaid boss:(Boss*)theBoss players:(NSArray*)players gameTime:(float)timeDelta;
- (void)triggerAbilityForRaid:(Raid*)theRaid andPlayers:(NSArray*)players;
- (BOOL)checkFailed;

- (void)willDamageTarget:(RaidMember*)target;
- (void)startChannel:(float)channel;
@end


@interface Attack : Ability
@property (nonatomic, retain) Effect *appliedEffect;
@property (nonatomic, readwrite) BOOL requiresDamageToApplyEffect;
- (RaidMember *)targetFromRaid:(Raid*)raid;
- (id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd;
@end

@interface FocusedAttack : Attack
@property (nonatomic, readwrite ) BOOL enrageApplied;
@property (nonatomic, retain) RaidMember *focusTarget;
@end

@interface SustainedAttack : Attack
@property (nonatomic, retain) RaidMember *currentTarget;
@property (nonatomic, readwrite) NSInteger currentAttacksRemaining;
@end

@interface BoneThrow : Ability
@end

@interface ProjectileAttack : Ability
@property (nonatomic, retain) Effect *appliedEffect;
@property (nonatomic, retain) NSString* spriteName;
@property (nonatomic, retain) NSString* explosionParticleName;
@property (nonatomic, readwrite) ProjectileEffectType effectType;
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
@end

@interface BaraghastBreakOff : Ability
@property (nonatomic, retain) FocusedAttack *ownerAutoAttack;
@end

@interface BaraghastRoar : Ability
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
@end

@interface WaveOfTorment : Ability
@end

@interface StackingEnrage : Ability
@property (nonatomic, retain) Effect *enrageEffect;
@end

@interface FlameBreath : Ability
@end
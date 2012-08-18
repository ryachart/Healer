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

@class Raid, Player, Boss, Agent, HealableTarget, AbilityDescriptor, Effect;
@interface Ability : NSObject

@property (nonatomic, readwrite) float failureChance;
@property (nonatomic, readwrite) NSTimeInterval timeApplied;
@property (nonatomic, readwrite) NSTimeInterval cooldown; //9999 denotes an ability that must be triggered
@property (nonatomic, retain ) NSString *title;
@property (nonatomic, assign) Agent *owner;
@property (nonatomic, readwrite) NSInteger abilityValue; //Damage or DoT value or something
@property (nonatomic, readwrite) BOOL isDisabled;
@property (nonatomic, retain) AbilityDescriptor *descriptor;
@property (nonatomic, retain) NSString *attackParticleEffectName; //Defaults to blood_spurt.plist

- (void)combatActions:(Raid*)theRaid boss:(Boss*)theBoss players:(NSArray*)players gameTime:(float)timeDelta;
- (void)triggerAbilityForRaid:(Raid*)theRaid andPlayers:(NSArray*)players;
- (BOOL)checkFailed;

- (void)willDamageTarget:(RaidMember*)target;
@end


@interface Attack : Ability
@property (nonatomic, retain) Effect *appliedEffect;
- (RaidMember *)targetFromRaid:(Raid*)raid;
- (id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd;
@end

@interface FocusedAttack : Attack
@property (nonatomic, readwrite ) BOOL enrageApplied;
@property (nonatomic, retain) RaidMember *focusTarget;
@end

@interface BoneThrow : Ability
@end

@interface ProjectileAttack : Ability
@property (nonatomic, retain) NSString* spriteName;
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
@end

@interface TargetTypeFlameBreath : TargetTypeAttack
@end

@interface BoneQuake : RaidDamage
@end

@interface BloodMinion : Ability
@end

@interface FireMinion : Ability
@end

@interface ShadowMinion : Ability
@end

@interface RaidApplyEffect : Ability
@property (nonatomic, retain) Effect *appliedEffect;
@end

@interface OozeRaid : RaidApplyEffect
@property (nonatomic, readwrite) NSInteger originalCooldown;
@end

@interface OozeTwoTargets : Ability

@end
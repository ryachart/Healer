//
//  Ability.h
//  Healer
//
//  Created by Ryan Hart on 5/10/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//
//


#import <Foundation/Foundation.h>

@class Raid, RaidMember, Player, Boss, Agent, HealableTarget;
@interface Ability : NSObject

@property (nonatomic, readwrite) float failureChance;
@property (nonatomic, readwrite) NSTimeInterval timeApplied;
@property (nonatomic, readwrite) NSTimeInterval cooldown; //9999 denotes an ability that must be triggered
@property (nonatomic, retain ) NSString *title;
@property (nonatomic, retain) Agent *owner;
@property (nonatomic, readwrite) NSInteger abilityValue; //Damage or DoT value or something
@property (nonatomic, readwrite) BOOL isDisabled;

- (void)combatActions:(Raid*)theRaid boss:(Boss*)theBoss players:(NSArray*)players gameTime:(float)timeDelta;
- (void)triggerAbilityForRaid:(Raid*)theRaid andPlayers:(NSArray*)players;
- (BOOL)checkFailed;
@end


@interface Attack : Ability
- (RaidMember *)targetFromRaid:(Raid*)raid;
-(id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd;
@end

@interface FocusedAttack : Attack
@property (nonatomic, retain) RaidMember *focusTarget;
@end

@interface Fireball : Ability
@property (nonatomic, retain) NSString* spriteName;
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

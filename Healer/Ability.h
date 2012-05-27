//
//  Ability.h
//  Healer
//
//  Created by Ryan Hart on 5/10/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//
//


#import <Foundation/Foundation.h>

typedef enum {
    TargetPreferenceRandom,     //Choose a new target every use
    TargetPreferenceStatic,     //Choose a target once and use that unless it dies
    TargetPreferenceGuardian,   //Choose a Guardian unless there are none.
    TargetPreferenceWizard     //Choose a Wizard unless there are none
    
} TargetPreference;

@class Raid, Player, Boss, Agent, HealableTarget;
@interface Ability : NSObject

@property (nonatomic, readwrite) float failureChance;
@property (nonatomic, readwrite) NSTimeInterval cooldown;
@property (nonatomic, retain ) NSString *title;
@property (nonatomic, retain) Agent *owner;
@property (nonatomic, readwrite) NSInteger abilityValue; //Damage or DoT value or something
@property (nonatomic, retain) NSArray *targets;

-(void)combatActions:(Raid*)theRaid boss:(Boss*)theBoss player:(Player*)thePlayer gameTime:(float)timeDelta;
@end


@interface BasicAttack : Ability

-(id)initWithDamage:(NSInteger)dmg andCooldown:(NSTimeInterval)cd;
@end
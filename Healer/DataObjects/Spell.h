//
//  Spell.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpellAudioData.h"

@class Boss;
@class Raid;
@class Player;
@class Effect;
@class Agent;

@interface Spell : NSObject {
	float castTime;
	NSInteger targets;
	NSInteger healingAmount;
	NSInteger energyCost;
	NSArray *percentagesPerTarget;
	BOOL isMultitouch;
}

-(id)initWithTitle:(NSString*)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd;
+(id)defaultSpell;
@property (readonly, retain) NSString *title;
@property (nonatomic, readonly, retain) NSString* spellID;
@property (nonatomic, assign) Agent *owner;
@property (nonatomic, readwrite) NSInteger healingAmount;
@property NSInteger energyCost;
@property float castTime;
@property (nonatomic, setter=setTargets:) NSInteger targets;
@property (nonatomic, copy) NSArray *percentagesPerTarget;
@property (retain, getter=description) NSString *description;
@property (nonatomic, readonly) NSString* info;
@property (retain, readonly) SpellAudioData *spellAudioData;
@property (nonatomic, readwrite) float cooldownRemaining;
@property (nonatomic, readwrite) float cooldown;
@property (nonatomic, retain) Effect* appliedEffect;
- (NSString*)spellDescription;
- (BOOL)isInstant;
- (void)setTargets:(NSInteger)numOfTargets withPercentagesPerTarget:(NSArray*)percentages;
- (void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)theTime;
- (void)updateCooldowns:(float)theTime;
- (void)spellBeganCasting;
- (void)spellEndedCasting;
- (void)spellInterrupted;
- (void)applyTemporaryCooldown:(NSTimeInterval)tempCD;


@end


@protocol Chargable

@required
-(NSDate*)chargeStart;
-(NSDate*)chargeEnd;
-(NSTimeInterval)maxChargeTime;
-(NSTimeInterval)currentChargeTime;
-(void)beginCharging:(NSDate*)startTime;
-(void)endCharging:(NSDate*)endTime;

@end

//SIMPLE GAME SPELLS
@interface Heal : Spell //Basic Efficient Low throughput Heal
@end

@interface GreaterHeal : Spell //Simple High cost high efficiency Heal
@end

@interface ForkedHeal : Spell //Two target heal with good efficiency
@end

@interface Regrow : Spell //Instant cast 12 second HoT
@end

@interface Barrier : Spell //Fast cast expensive Absorb
@end

@interface HealingBurst : Spell //Instant cast short cooldown heal
@end

@interface Purify : Spell //Cure
@end

@interface OrbsOfLight : Spell //Reactive Heal
@end

@interface SwirlingLight : Spell //Intensified HoT
@end

@interface LightEternal : Spell //Prayer of Smart Healing
@end

@interface WanderingSpirit : Spell //Prayer of Auto-Mending
@end

@interface Respite : Spell //Mana Prayer
@end

@interface WardOfAncients : Spell
@end

////BASIC TEST SPELLS/////
@interface QuickHeal : Spell

@end

@interface SuperHeal : Spell

@end

@interface SurgeOfLife : Spell

@end

@interface HealingBreath : Spell

@end

@interface GloriousBeam : Spell

@end

////SHAMAN SPELLS///////
@interface RoarOfLife : Spell

@end

@interface WoundWeaving : Spell

@end

@interface SurgingGrowth : Spell

@end

@interface FieryAdrenaline : Spell

@end

@interface TwoWinds : Spell

@end

@interface SymbioticConnection : Spell

@end

@interface UnleashedNature : Spell

@end


////SEER SPELLS/////

@interface ShiningAegis : Spell
@end

@interface Bulwark : Spell
@end

@interface EtherealArmor : Spell
@end

/*
@interface Guardian : Spell
@end

@interface BlessedDefenses: Spell
@end

@interface BondOfStrength : Spell
@end

@interface ChainOfFortitude : Spell
@end
*/
////RITUALIST SPELLS/////


@interface HastyBrew : Spell <Chargable>{
	NSDate *chargeStart;
	NSDate *chargeEnd;
}
@property (nonatomic, retain) NSDate *chargeStart;
@property (nonatomic, retain) NSDate *chargeEnd;
+(id)defaultSpell;
@end
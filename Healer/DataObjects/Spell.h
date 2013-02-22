//
//  Spell.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Enemy;
@class Raid;
@class Player;
@class Effect;
@class Agent;
@class RaidMember;

typedef enum {
    SpellTypeBasic,
    SpellTypePeriodic,
    SpellTypeMulti,
    SpellTypeProtective,
    SpellTypeEmpowering
} SpellType;

@interface Spell : NSObject

-(id)initWithTitle:(NSString*)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd;
+(id)defaultSpell;
@property (nonatomic, readonly, retain) NSString *title;
@property (nonatomic, readonly, retain) NSString* spellID;
@property (nonatomic, assign) Player *owner;
@property (nonatomic, readwrite) NSInteger healingAmount;
@property (nonatomic, readonly) NSInteger energyCost;
@property (nonatomic, readwrite) float castTime;
@property (nonatomic, setter=setTargets:) NSInteger targets;
@property (nonatomic, copy) NSArray *percentagesPerTarget;
@property (retain, getter=description) NSString *description;
@property (nonatomic, readonly) NSString* info;
@property (nonatomic, readwrite) float cooldownRemaining;
@property (nonatomic, readwrite) float cooldown;
@property (nonatomic, retain) Effect* appliedEffect;
@property (nonatomic, readwrite) BOOL isExclusiveEffectTarget;
@property (nonatomic, readwrite) BOOL isMultitouch;

@property (nonatomic, readonly) NSString* spellTypeDescription;
@property (nonatomic, readwrite) SpellType spellType;

@property (nonatomic, retain) NSString *beginCastingAudioTitle;
@property (nonatomic, retain) NSString *endCastingAudioTitle;
@property (nonatomic, retain) NSString *interruptedAudioTitle;

- (NSString*)spriteFrameName;
- (NSString*)spellDescription;
- (BOOL)isInstant;
- (void)setTargets:(NSInteger)numOfTargets withPercentagesPerTarget:(NSArray*)percentages;
- (void)spellFinishedCastingForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta;
- (void)updateCooldowns:(float)theTime;
- (void)spellBeganCasting;
- (void)spellEndedCasting;
- (void)spellInterrupted;
- (void)applyTemporaryCooldown:(NSTimeInterval)tempCD;


//Subclass overrides
- (void)checkDivinity;
- (void)willHealTarget:(RaidMember*)target inRaid:(Raid*)raid withEnemies:(NSArray*)enemies andPlayers:(NSArray*)players forAmount:(NSInteger)amount;
- (void)didHealTarget:(RaidMember*)target inRaid:(Raid*)raid withEnemies:(NSArray*)enemies andPlayers:(NSArray*)players forAmount:(NSInteger)amount;
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

@interface TouchOfHope : Spell
@end

@interface SoaringSpirit : Spell
@end

@interface FadingLight : Spell
@end

@interface Sunburst : Spell
@end

@interface StarsOfAravon : Spell
@end

@interface BlessedArmor : Spell
@end

@interface Attunement : Spell
@end
////RITUALIST SPELLS/////
@interface HastyBrew : Spell <Chargable>{
	NSDate *chargeStart;
	NSDate *chargeEnd;
}
@property (nonatomic, retain) NSDate *chargeStart;
@property (nonatomic, retain) NSDate *chargeEnd;
+(id)defaultSpell;
@end
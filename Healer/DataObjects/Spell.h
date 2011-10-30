//
//  Spell.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpellAudioData.h"
#import "SpellCardView.h"

@class Boss;
@class Raid;
@class Player;

@interface Spell : NSObject {
	float castTime;
	float coolDown;
	NSInteger targets;
	NSInteger healingAmount;
	NSInteger energyCost;
	NSArray *percentagesPerTarget;
	BOOL isMultitouch;
	NSString *title;
	
	
	NSString *description;
	
	SpellAudioData *spellAudioData;
	
	NSDate *spellCastTime;
	
}
-(id)initWithTitle:(NSString*)ttle healAmnt:(NSInteger)healAmnt energyCost:(NSInteger)nrgyCost castTime:(float)time andCooldown:(float)cd;
+(id)defaultSpell;
+(Spell*)spellFromTitle:(NSString*)ttle;
@property (readonly, retain) NSString *title;
@property NSInteger healingAmount;
@property NSInteger energyCost;
@property float castTime;
@property (nonatomic, setter=setTargets:) NSInteger targets;
@property (nonatomic, copy) NSArray *percentagesPerTarget;
@property (retain, getter=description) NSString *description;
@property (retain, readonly) SpellAudioData *spellAudioData;

-(SpellCardView*)spellCardView;
-(NSString*)description;
-(BOOL)isInstant;
-(void)setTargets:(NSInteger)numOfTargets withPercentagesPerTarget:(NSArray*)percentages;

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime;
-(void)spellBeganCasting;
-(void)spellEndedCasting;
-(void)spellInterrupted;

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

////BASIC TEST SPELLS/////
@interface QuickHeal : Spell

@end

@interface SuperHeal : Spell

@end

@interface ForkedHeal : Spell

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
//
//  HealableTarget.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAXIMUM_STATUS_EFFECTS 25
@class Effect;
@class HealthAdjustmentModifier;
@interface HealableTarget : NSObject {
	NSInteger health; //All HealableTargets must have health
	NSInteger maximumHealth;
	
	NSMutableArray *activeEffects;
	NSMutableArray *healthAdjustmentModifiers;
}
@property (setter=setHealth) NSInteger health;
@property NSInteger maximumHealth;
@property (readonly) NSMutableArray *activeEffects;

-(void)setHealth:(NSInteger)newHealth;
-(BOOL)isDead;
-(void)addEffect:(Effect*)theEffect;
-(void)addHealthAdjustmentModifier:(HealthAdjustmentModifier*)hamod;
@end

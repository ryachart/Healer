//
//  HealableTarget.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HealableTarget.h"
#import "GameObjects.h"
#import "Effect.h"

@implementation HealableTarget
@synthesize health, maximumHealth, activeEffects;

-(void)setHealth:(NSInteger)newHealth
{
	for (HealthAdjustmentModifier* ham in healthAdjustmentModifiers){
		[ham willChangeHealthFrom:&health toNewHealth:&newHealth];
	}
	NSInteger prevHealth = health;
	health = newHealth;
	for (HealthAdjustmentModifier* ham in healthAdjustmentModifiers){
		[ham didChangeHealthFrom:prevHealth toNewHealth:newHealth];
	}
	if (health < 0) health = 0;
	if (health > maximumHealth) {
		//NSLog(@"Health>MaxHealth");
		health = maximumHealth;
	}
}

-(void)addEffect:(Effect*)theEffect
{
	if (activeEffects != nil){
		for (Effect *effectFA in activeEffects){
			if ([effectFA class] == [theEffect class]){
				NSLog(@"This target already has a copy of that effect");
				return;
			}
		}
		
		[theEffect setTimeApplied:[[NSDate date] copyWithZone:nil]];
		if ([theEffect conformsToProtocol:@protocol(HealthAdjustmentModifier)]){
			[self addHealthAdjustmentModifier:(HealthAdjustmentModifier*)theEffect];
		}
		[theEffect setTarget:self];
		[activeEffects addObject:theEffect];
	}
	else {
		NSLog(@"Effects Array is nil");
	}

}

-(void)addHealthAdjustmentModifier:(HealthAdjustmentModifier*)hamod{
	if (healthAdjustmentModifiers == nil){
		healthAdjustmentModifiers = [[NSMutableArray alloc] initWithCapacity:5];
	}
	
	[healthAdjustmentModifiers addObject:hamod];
}

-(BOOL)isDead
{
	return health <= 0;
}
@end

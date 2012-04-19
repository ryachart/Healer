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
@synthesize health, maximumHealth, activeEffects, isFocused;
@synthesize battleID, hasDied;

-(void)setHealth:(NSInteger)newHealth
{
    if (self.hasDied){
        return;
    }
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
		health = maximumHealth;
	}
    if (health == 0){
        self.hasDied = YES;
        [self.logger logEvent:[CombatEvent eventWithSource:self target:self value:nil andEventType:CombatEventTypeMemberDied]];
    }
}

-(void)addEffect:(Effect*)theEffect
{
	if (activeEffects != nil){
        NSMutableArray *similarEffects = [NSMutableArray arrayWithCapacity:theEffect.maxStacks];
		for (Effect *effectFA in activeEffects){
			if ([effectFA.title isEqualToString:theEffect.title]){
                [similarEffects addObject:effectFA];
			}
		}
        
        if (similarEffects.count >= theEffect.maxStacks){
            return;
        }
		
		[theEffect setTimeApplied:0.0001];
        for (Effect *simEffect in similarEffects){
            [simEffect setTimeApplied:0.0001]; //Refresh the duration of the existing versions of the effects if a second one is applied over.
        }
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

-(NSString*)sourceName{
    return [[self class] description];
}
-(NSString*)targetName{
    return [[self class] description];
}

-(void)dealloc{
    [healthAdjustmentModifiers release]; healthAdjustmentModifiers = nil;
    [super dealloc];
}
@end

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
@synthesize battleID, hasDied, healthAdjustmentModifiers;

-(id)init{
    if (self = [super init]){
        activeEffects = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_STATUS_EFFECTS];
    }
    return self;
}

-(float)healingDoneMultiplier{
    float base = [super healingDoneMultiplier];
    
    for (Effect *eff in self.activeEffects){
        base += [eff healingDoneMultiplierAdjustment];
    }
    
    return base;
}

-(float)damageDoneMultiplier{
    float base = [super damageDoneMultiplier];
    
    for (Effect *eff in self.activeEffects){
        base += [eff damageDoneMultiplierAdjustment];
    }
    return base;
}

-(float)healthPercentage{
    return (float)self.health/(float)self.maximumHealth;
}

-(void)setHealth:(NSInteger)newHealth
{
    NSInteger overHealing = 0;
    NSInteger totalHealing = 0;
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
        overHealing = health - maximumHealth;
		health = maximumHealth;
	}
    if (prevHealth < health){
        totalHealing = health - prevHealth;
    }
    [self didReceiveHealing:totalHealing andOverhealing:overHealing];
    if (health == 0){
        self.hasDied = YES;
        [self.logger logEvent:[CombatEvent eventWithSource:self target:self value:nil andEventType:CombatEventTypeMemberDied]];
    }
}

- (void)didReceiveHealing:(NSInteger)amount andOverhealing:(NSInteger)overAmount{
    
}

- (NSInteger)effectCountOfType:(EffectType)type {
    if (self.isDead){
        return 0;
    }
    NSInteger count = 0;
    for (Effect *eff in self.activeEffects){
        if (eff.effectType == type){
            count++;
        }
    }
    return count;
}

-(void)addEffect:(Effect*)theEffect
{
	if (activeEffects != nil){
        NSMutableArray *similarEffects = [NSMutableArray arrayWithCapacity:theEffect.maxStacks];
		for (Effect *effectFA in activeEffects){
			if ([effectFA isKindOfEffect:theEffect] && effectFA.owner == theEffect.owner && !effectFA.isIndependent){
                [similarEffects addObject:effectFA];
			}
		}
        
        if (similarEffects.count >= theEffect.maxStacks){
            for (Effect *simEffect in similarEffects){
                [simEffect reset]; //Refresh the duration of the existing versions of the effects if a second one is applied over.
            }
            return;
        }
		
		[theEffect reset];
        for (Effect *simEffect in similarEffects){
            [simEffect reset]; //Refresh the duration of the existing versions of the effects if a second one is applied over.
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

- (void)removeEffect:(Effect *)theEffect{
    if (activeEffects != nil){
        [theEffect setTarget:nil];
        if ([self.healthAdjustmentModifiers containsObject:theEffect]){
            [self.healthAdjustmentModifiers removeObject:theEffect];
        }
        [self.activeEffects removeObject:theEffect];
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
    [battleID release];
    [activeEffects release]; activeEffects = nil;
    [healthAdjustmentModifiers release]; healthAdjustmentModifiers = nil;
    [super dealloc];
}

- (BOOL)hasEffectWithTitle:(NSString*)title {
    BOOL hasEffect = NO;
    
    for (Effect *eff in self.activeEffects){
        if ([eff.title isEqualToString:title]){
            hasEffect = YES; break;
        }
    }
    return hasEffect;
}
@end

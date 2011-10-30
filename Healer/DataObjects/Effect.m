//
//  Effect.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Effect.h"
#import "GameObjects.h"
#import "AudioController.h"
@implementation Effect
@synthesize duration, timeApplied, isExpired, target, effectType;

-(id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type
{
	duration = dur;
	isExpired = NO;
	effectType = type;
	return self;
}

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
{
	if (timeApplied != nil && !isExpired)
	{
		 
		NSTimeInterval timeSinceStart = [theTime timeIntervalSinceDate:timeApplied];
		//NSLog(@"TimeSinceStart %1.2f", timeSinceStart);
		//NSLog(@"Duration: %1.2f", duration);
		//[thePlayer setStatusText:[NSString stringWithFormat:@"You will be destroyed in %1.2f seconds",timeSinceStart]];
		if (timeSinceStart >= duration){
			//Here we do some effect, but we have to subclass Effects to decide what that is
			//NSLog(@"Effect Expired");
			//The one thing we always do here is expire the effect
			timeApplied = nil;
			isExpired = YES;
			[thePlayer setStatusText:@""];
			
		}
		
	}
	
}

-(void)expire{

}
@end


@implementation BigFireball

@synthesize lastPosition;

-(id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type{
	if (self = [super initWithDuration:dur andEffectType:type]){
		AudioController* ac = [AudioController sharedInstance];
		audioTitles = [[NSMutableArray alloc] initWithCapacity:2];
		[audioTitles addObject:[NSString stringWithFormat:@"FireballStart%@", self]];
		[audioTitles addObject:[NSString stringWithFormat:@"FireballImpact%@", self]];
		[ac addNewPlayerWithTitle:[audioTitles objectAtIndex:0] andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"FireballStart" ofType:@"wav"]]];
		[ac addNewPlayerWithTitle:[audioTitles objectAtIndex:1] andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"FireBallImpact" ofType:@"wav"]]];
		[ac playTitle:[audioTitles objectAtIndex:0]];
	}
	
	return self;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
{
	if (timeApplied != nil && !isExpired)
	{
		
		NSTimeInterval timeSinceStart = [theTime timeIntervalSinceDate:timeApplied];
		//NSLog(@"TimeSinceStart %1.2f", timeSinceStart);
		//NSLog(@"Duration: %1.2f", duration);
		[thePlayer setStatusText:[NSString stringWithFormat:@"A Fireball will strike you in %1.2f seconds. Move!",duration - timeSinceStart]];
		if (timeSinceStart >= duration){
			//Here we do some effect, but we have to subclass Effects to decide what that is
			//NSLog(@"Effect Expired");
			//The one thing we always do here is expire the effect
			
			NSInteger movementDelta = [thePlayer position] - lastPosition;
			if (movementDelta < 30){
				[thePlayer setHealth:[thePlayer health] - 50];
				AudioController *ac = [AudioController sharedInstance];
				[ac playTitle:[audioTitles objectAtIndex:1]];
			}
			timeApplied = nil;
			isExpired = YES;
			lastPosition = [thePlayer position];
			[thePlayer setStatusText:@""];
			
		}
		
	}
	
}

-(void)expire{
		AudioController* ac = [AudioController sharedInstance];
		[ac removeAudioPlayerWithTitle:@"FireballStart"];
		[ac removeAudioPlayerWithTitle:@"FireballImpact"];	
}

@end

@implementation HealOverTimeEffect

@synthesize numOfTicks, healingPerTick;

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
{
	if (timeApplied != nil && !isExpired)
	{
		if (lastTick == nil){
			lastTick = [theTime copyWithZone:nil];
		}
		
		NSTimeInterval timeSinceStart = [theTime timeIntervalSinceDate:timeApplied];
		NSTimeInterval timeSinceLastTick = [theTime timeIntervalSinceDate:lastTick];
		//NSLog(@"TimeSinceStart %1.2f", timeSinceStart);
		//NSLog(@"Duration: %1.2f", duration);
		//[thePlayer setStatusText:[NSString stringWithFormat:@"A Fireball will strike you in %1.2f seconds. Move!",duration - timeSinceStart]];
		if (timeSinceLastTick >= (duration/numOfTicks)){
			[target setHealth:[target health] + healingPerTick];
			//NSLog(@"Tick");
			lastTick = [theTime copyWithZone:nil];
		}
		if (timeSinceStart >= duration){
			[target setHealth:[target health] + healingPerTick];
			//NSLog(@"Tick");
			//Here we do some effect, but we have to subclass Effects to decide what that is
			//NSLog(@"Expired");
			//The one thing we always do here is expire the effect
			timeApplied = nil;
			isExpired = YES;
			
		}
		
	}
	
}

@end

@implementation ShieldEffect
@synthesize amountToShield;

-(void)willChangeHealthFrom:(NSInteger*)currentHealth toNewHealth:(NSInteger*)newHealth
{
	if (*newHealth >= *currentHealth)
	{
		return;
	}
	
	NSInteger healthDelta = *currentHealth - *newHealth;
	
	if (healthDelta >= amountToShield){
		NSLog(@"%@: Absorbing %i damage and expiring.", self, amountToShield);
		*newHealth += amountToShield;
		amountToShield = 0;
		isExpired = YES;
	}
	else if (healthDelta < amountToShield){
		NSLog(@"Absorbing %i damage", healthDelta);
		*newHealth += healthDelta;
		amountToShield -= healthDelta;
	}
	NSLog(@"Amount to Shield: %i", amountToShield);
}
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth
{
	//NSLog(@"Shield Recognized: DidChangeHealth");
}
@end

#pragma mark -
#pragma mark Shaman Spells

@implementation RoarOfLifeEffect
+(id)defaultEffect{
	RoarOfLifeEffect *rolEffect = [[RoarOfLifeEffect alloc] initWithDuration:12 andEffectType:EffectTypePositive];
	[rolEffect setNumOfTicks:6];
	[rolEffect setHealingPerTick:3];
	return rolEffect;
}
@end

@implementation WoundWeavingEffect
+(id)defaultEffect{
	WoundWeavingEffect *wwe = [[WoundWeavingEffect alloc] initWithDuration:9 andEffectType:EffectTypePositive];
	[wwe setNumOfTicks:3];
	[wwe setHealingPerTick:12];
	return wwe;
}
@end

@implementation SurgingGrowthEffect
+(id)defaultEffect{
	SurgingGrowthEffect *sge = [[SurgingGrowthEffect alloc] initWithDuration:5 andEffectType:EffectTypePositive];
	[sge setNumOfTicks:5];
	[sge setHealingPerTick:1];
	return sge;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(NSDate*)theTime
{
	if (timeApplied != nil && !isExpired)
	{
		if (lastTick == nil){
			lastTick = [theTime copyWithZone:nil];
		}
		
		NSTimeInterval timeSinceStart = [theTime timeIntervalSinceDate:timeApplied];
		NSTimeInterval timeSinceLastTick = [theTime timeIntervalSinceDate:lastTick];
		//NSLog(@"TimeSinceStart %1.2f", timeSinceStart);
		//NSLog(@"Duration: %1.2f", duration);
		//[thePlayer setStatusText:[NSString stringWithFormat:@"A Fireball will strike you in %1.2f seconds. Move!",duration - timeSinceStart]];
		if (timeSinceLastTick >= (duration/numOfTicks)){
			[target setHealth:[target health] + healingPerTick];
			//NSLog(@"Tick");
			healingPerTick += 1;
			lastTick = [theTime copyWithZone:nil];
		}
		if (timeSinceStart >= duration){
			[target setHealth:[target health] + healingPerTick];
			[target setHealth:[target health] + healingPerTick*2];
			//NSLog(@"Tick");
			//Here we do some effect, but we have to subclass Effects to decide what that is
			//NSLog(@"Expired");
			//The one thing we always do here is expire the effect
			timeApplied = nil;
			isExpired = YES;
			
		}
		
	}
	
}
@end

@implementation FieryAdrenalineEffect
+(id)defaultEffect{
	FieryAdrenalineEffect * fae = [[FieryAdrenalineEffect alloc] initWithDuration:10 andEffectType:EffectTypePositive];
	[fae setNumOfTicks:5];
	[fae setHealingPerTick:3];
	return fae;
}
-(void)didChangeHealthFrom:(NSInteger )health toNewHealth:(NSInteger )newHealth
{
	if (health > newHealth){
		timeApplied = nil;
		timeApplied = [[NSDate date] copyWithZone:nil];
		NSLog(@"Target took damage...refreshing duration");
	}
}
-(void)willChangeHealthFrom:(NSInteger *)health toNewHealth:(NSInteger *)newHealth{
	
}
@end

@implementation TwoWindsEffect
+(id)defaultEffect{
	TwoWindsEffect *twe = [[TwoWindsEffect alloc] initWithDuration:12 andEffectType:EffectTypePositive];
	[twe setNumOfTicks:4];
	[twe setHealingPerTick:8];
	return twe;
}

@end

@implementation SymbioticConnectionEffect
+(id)defaultEffect{
	SymbioticConnectionEffect *sce = [[SymbioticConnectionEffect alloc] initWithDuration:9 andEffectType:EffectTypePositive];
	[sce setNumOfTicks:3];
	[sce setHealingPerTick:10];
	return sce;
	
}
@end

@implementation UnleashedNatureEffect
+(id)defaultEffect{
	UnleashedNatureEffect *unle = [[UnleashedNatureEffect alloc] initWithDuration:12 andEffectType:EffectTypePositive];
	[unle setNumOfTicks:6];
	[unle setHealingPerTick:3];
	return unle;
}
@end

#pragma mark -
#pragma mark Seer Effects

@implementation ShiningAegisEffect
+(id)defaultEffect{
	ShiningAegisEffect *sae = [[ShiningAegisEffect alloc] initWithDuration:12 andEffectType:EffectTypePositive];
	[sae setAmountToShield:20];
	return sae;
}

@end

@implementation BulwarkEffect
+(id)defaultEffect{
	BulwarkEffect *be = [[BulwarkEffect alloc] initWithDuration:15 andEffectType:EffectTypePositive];
	[be setAmountToShield:40];
	return be;
}

@end

@implementation EtherealArmorEffect
+(id)defaultEffect{
	EtherealArmorEffect *eae = [[EtherealArmorEffect alloc] initWithDuration:15 andEffectType:EffectTypePositive];
	return eae;
}

-(void)didChangeHealthFrom:(NSInteger )health toNewHealth:(NSInteger )newHealth
{
}
-(void)willChangeHealthFrom:(NSInteger *)health toNewHealth:(NSInteger *)newHealth{
	
	if (*health > *newHealth){
		NSInteger healthDelta = *health - *newHealth;
	
		NSInteger newHealthDelta = healthDelta	* .25;
		NSLog(@"Lowering damage taken by %i", *health- newHealthDelta);
		*newHealth = *health - newHealthDelta;
	}
}

@end


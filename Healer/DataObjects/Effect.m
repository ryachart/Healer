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
#import "Agent.h"
#import "Player.h"

@implementation Effect
@synthesize duration, isExpired, target, effectType, timeApplied=_timeApplied, maxStacks, spriteName, title, ailmentType, owner;
@synthesize needsOwnershipResolution, ownerNetworkID; //HACKY

-(id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type
{
    if (self = [super init]){
        duration = dur;
        isExpired = NO;
        effectType = type;
        self.maxStacks = 1;
        self.timeApplied = 0.0;
        self.spriteName = nil;
        self.title = nil;
    }
	return self;
}

-(void)reset{
    self.timeApplied = 0.0;
    self.isExpired = NO;
}

-(id)copy{
    Effect *copied = [[[self class] alloc] initWithDuration:self.duration andEffectType:self.effectType];
    copied.maxStacks = self.maxStacks;
    copied.spriteName = self.spriteName;
    copied.title = self.title;
    copied.owner = self.owner;
    return copied;
}

-(void)solveOwnershipResolutionForBoss:(Boss*)boss andRaid:(Raid*)raid andPlayer:(Player*)player{
    if (self.needsOwnershipResolution && self.ownerNetworkID){
        
        //For this network hack we only care if it's me or not me.
        if ([player.networkID isEqualToString:self.ownerNetworkID]){
            self.owner = player;
        }
        self.needsOwnershipResolution = NO;
        self.ownerNetworkID = nil;
    }
}

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
    [self solveOwnershipResolutionForBoss:theBoss andRaid:theRaid andPlayer:thePlayer];
	if (self.timeApplied != 0.0 && !isExpired)
	{
        self.timeApplied += timeDelta;
		if (self.timeApplied >= duration){
			//Here we do some effect, but we have to subclass Effects to decide what that is
			//The one thing we always do here is expire the effect
			self.timeApplied = 0.0;
			isExpired = YES;
			[thePlayer setStatusText:@""];
			
		}
		
	}
	
}

-(BOOL)isEqual:(Effect*)object{
    if ([self.title isEqualToString:object.title]){
        return YES;
    }
    return NO;
}

-(void)expire{

}
//EFF|TARGET|TITLE|DURATION|TYPE|SPRITENAME|OWNER
-(NSString*)asNetworkMessage{
    NSString* message = [NSString stringWithFormat:@"EFF|%@|%f|%f|%i|%@|%@", self.title, self.duration, self.timeApplied ,self.effectType, self.spriteName, self.owner];
    
    return message;
}
-(id)initWithNetworkMessage:(NSString*)message{
    NSArray *messageComponents = [message componentsSeparatedByString:@"|"];
    if (self = [self initWithDuration:[[messageComponents objectAtIndex:2] doubleValue] andEffectType:[[messageComponents objectAtIndex:4] intValue]]){
        self.title = [messageComponents objectAtIndex:1];
        self.timeApplied = [[messageComponents objectAtIndex:3] doubleValue];
        self.spriteName = [messageComponents objectAtIndex:5];
    }
    return self;
}
@end

@implementation RepeatedHealthEffect

@synthesize numOfTicks, valuePerTick,numHasTicked;

-(id)copy{
    RepeatedHealthEffect *copy = [super copy];
    [copy setNumOfTicks:self.numOfTicks];
    [copy setValuePerTick:self.valuePerTick];
    return copy;
}

-(void)reset{
    [super reset];
    lastTick = 0.0;
    self.numHasTicked = 0.0;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
    [self solveOwnershipResolutionForBoss:theBoss andRaid:theRaid andPlayer:thePlayer];
	if (!isExpired)
	{
        self.timeApplied += timeDelta;
		lastTick += timeDelta;
		if (lastTick >= (duration/numOfTicks)){
            [self tick];
			lastTick = 0.0;
		}
		if (self.timeApplied >= duration){
            if (self.numHasTicked < self.numOfTicks){
                [self tick];
            }
            //[self tick];
			//The one thing we always do here is expire the effect
			self.timeApplied = 0.0;
			isExpired = YES;
		}
	}
}

-(void)tick{
    self.numHasTicked++;
    if (!target.isDead){
        CombatEventType eventType = valuePerTick > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:valuePerTick] andEventType:eventType]];
        [target setHealth:[target health] + valuePerTick];
    }
}

@end

@implementation ShieldEffect
@synthesize amountToShield;

-(id)copy{
    ShieldEffect *copy = [super copy];
    [copy setAmountToShield:self.amountToShield];
    return copy;
}   

-(void)willChangeHealthFrom:(NSInteger*)currentHealth toNewHealth:(NSInteger*)newHealth
{
	if (*newHealth >= *currentHealth)
	{
		return;
	}
	
	NSInteger healthDelta = *currentHealth - *newHealth;
	
	if (healthDelta >= amountToShield){
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:amountToShield] andEventType:CombatEventTypeHeal]];
		*newHealth += amountToShield;
		amountToShield = 0;
		isExpired = YES;
	}
	else if (healthDelta < amountToShield){
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:amountToShield] andEventType:CombatEventTypeHeal]];
		*newHealth += healthDelta;
		amountToShield -= healthDelta;
	}
}
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth
{
}
@end


@implementation ReactiveHealEffect
@synthesize amountPerReaction, triggerCooldown, effectCooldown=_effectCooldown;
-(id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type{
    if (self = [super initWithDuration:dur andEffectType:type]){
        self.effectCooldown = 1.0;
    }
    return self;
}
-(void)setEffectCooldown:(float)effCD{
    _effectCooldown = effCD;
    self.triggerCooldown = self.effectCooldown;
    
}
-(id)copy{
    ReactiveHealEffect *copy = [super copy];
    [copy setAmountPerReaction:self.amountPerReaction];
    [copy setTriggerCooldown:self.triggerCooldown];
    [copy setEffectCooldown:self.effectCooldown];
    return copy;
}

-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)timeDelta{
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
    if (self.triggerCooldown < self.effectCooldown){
        self.triggerCooldown += timeDelta;
    }
}

-(void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    
}
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth{
    if (currentHealth > newHealth){
        if (self.triggerCooldown >= self.effectCooldown){
            self.triggerCooldown = 0.0;
            DelayedHealthEffect *orbPop = [[DelayedHealthEffect alloc] initWithDuration:0.5 andEffectType:EffectTypePositiveInvisible];
            [orbPop setOwner:self.owner];
            [orbPop setValue:self.amountPerReaction];
            
            [self.target addEffect:orbPop];
            [orbPop release];
        }
    }
    
    
}
@end

@implementation  DelayedHealthEffect
@synthesize value;
-(id)copy{
    DelayedHealthEffect *copy = [super copy];
    [copy setValue:self.value];
    return copy;
}
-(void)expire{
    if (!self.target.isDead){
        CombatEventType eventType = self.value > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
        [self.target setHealth:self.target.health + self.value];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:self.value] andEventType:eventType]];
    }
    [super expire];
}
@end

@implementation SwirlingLightEffect

-(void)tick{
    int similarEffectCount = 1;
    for (Effect *effect in target.activeEffects){
        if ([effect isEqual:self]){
            similarEffectCount++;
        }
    }
    
    [self.target setHealth:self.target.health + (int)round((self.valuePerTick * (similarEffectCount * .25)))];
}
@end


@implementation TrulzarPoison
-(void)tick{
    if (!target.isDead){
        float percentComplete = self.timeApplied / self.duration;
        CombatEventType eventType = self.valuePerTick > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:self.valuePerTick] andEventType:eventType]];
        [self.target setHealth:self.target.health + [self valuePerTick] * (int)round(1+percentComplete)];
    }
}

@end

@implementation CouncilPoisonball
-(void)expire{
    RepeatedHealthEffect *poisonDoT = [[RepeatedHealthEffect alloc] initWithDuration:12 andEffectType:EffectTypeNegative];
    [poisonDoT setTitle:@"council-ball-dot"];
    [poisonDoT setSpriteName:@"poison.png"];
    [poisonDoT setValuePerTick:-3];
    [poisonDoT setNumOfTicks:4];
    [poisonDoT setOwner:self.owner];
    [self.target addEffect:poisonDoT];
    [poisonDoT release];
    [super expire];
}
@end

@implementation  ExpiresAtFullHealthRHE

-(void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)timeDelta{
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
    if (self.target.health > self.target.maximumHealth * .98){
        self.isExpired = YES;
    }
}

@end

@implementation ImpLightningBottle 
-(void)expire{
    [self.target setHealth:self.target.health - 15];
    RepeatedHealthEffect *burnDoT = [[RepeatedHealthEffect alloc] initWithDuration:12 andEffectType:EffectTypeNegative];
    [burnDoT setOwner:self.owner];
    [burnDoT setTitle:@"imp-burn-dot"];
    [burnDoT setSpriteName:@"poison.png"];
    [burnDoT setValuePerTick:-20];
    [burnDoT setNumOfTicks:4];
    [self.target addEffect:burnDoT];
    [burnDoT release];
    [super expire];
}
@end

@implementation BulwarkEffect
+(id)defaultEffect{
	BulwarkEffect *be = [[BulwarkEffect alloc] initWithDuration:15 andEffectType:EffectTypePositive];
    [be setTitle:@"bulwark-effect"];
	[be setAmountToShield:60];
    [be setSpriteName:@"healing_default.png"];
    [be setMaxStacks:1];
	return [be autorelease];
}

@end


#pragma mark - DEPRECATED SPELLS
#pragma mark -
#pragma mark Shaman Spells

@implementation RoarOfLifeEffect
+(id)defaultEffect{
	RoarOfLifeEffect *rolEffect = [[RoarOfLifeEffect alloc] initWithDuration:12 andEffectType:EffectTypePositive];
	[rolEffect setNumOfTicks:6];
	[rolEffect setValuePerTick:3];
	return [rolEffect autorelease];
}
@end

@implementation WoundWeavingEffect
+(id)defaultEffect{
	WoundWeavingEffect *wwe = [[WoundWeavingEffect alloc] initWithDuration:9 andEffectType:EffectTypePositive];
	[wwe setNumOfTicks:3];
	[wwe setValuePerTick:12];
	return [wwe autorelease];
}
@end

@implementation SurgingGrowthEffect
+(id)defaultEffect{
	SurgingGrowthEffect *sge = [[SurgingGrowthEffect alloc] initWithDuration:5 andEffectType:EffectTypePositive];
	[sge setNumOfTicks:5];
	[sge setValuePerTick:1];
	return [sge autorelease];
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
	if (self.timeApplied != 0.0 && !isExpired)
	{
		lastTick += timeDelta;
		if (lastTick  >= (duration/numOfTicks)){
			[target setHealth:[target health] + valuePerTick];
			//NSLog(@"Tick");
			valuePerTick += 1;
			lastTick = 0.0;
		}
		if (self.timeApplied >= duration){
			[target setHealth:[target health] + valuePerTick];
			[target setHealth:[target health] + valuePerTick*2];
			//NSLog(@"Tick");
			//Here we do some effect, but we have to subclass Effects to decide what that is
			//NSLog(@"Expired");
			//The one thing we always do here is expire the effect
			self.timeApplied = 0.0;;
			isExpired = YES;
			
		}
		
	}
	
}
@end

@implementation FieryAdrenalineEffect
+(id)defaultEffect{
	FieryAdrenalineEffect * fae = [[FieryAdrenalineEffect alloc] initWithDuration:10 andEffectType:EffectTypePositive];
	[fae setNumOfTicks:5];
	[fae setValuePerTick:3];
	return [fae autorelease];
}
-(void)didChangeHealthFrom:(NSInteger )health toNewHealth:(NSInteger )newHealth
{
	if (health > newHealth){
		self.timeApplied = 0.001; //BAD: It should actually refresh to zero but that breaks other logic
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
	[twe setValuePerTick:8];
	return [twe autorelease];
}

@end

@implementation SymbioticConnectionEffect
+(id)defaultEffect{
	SymbioticConnectionEffect *sce = [[SymbioticConnectionEffect alloc] initWithDuration:9 andEffectType:EffectTypePositive];
	[sce setNumOfTicks:3];
	[sce setValuePerTick:10];
	return [sce autorelease];
	
}
@end

@implementation UnleashedNatureEffect
+(id)defaultEffect{
	UnleashedNatureEffect *unle = [[UnleashedNatureEffect alloc] initWithDuration:12 andEffectType:EffectTypePositive];
	[unle setNumOfTicks:6];
	[unle setValuePerTick:3];
	return [unle autorelease];
}
@end

#pragma mark -
#pragma mark Seer Effects

@implementation ShiningAegisEffect
+(id)defaultEffect{
	ShiningAegisEffect *sae = [[ShiningAegisEffect alloc] initWithDuration:12 andEffectType:EffectTypePositive];
	[sae setAmountToShield:20];
	return [sae autorelease];
}

@end



@implementation EtherealArmorEffect
+(id)defaultEffect{
	EtherealArmorEffect *eae = [[EtherealArmorEffect alloc] initWithDuration:15 andEffectType:EffectTypePositive];
	return [eae autorelease];
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

@implementation BigFireball

@synthesize lastPosition;

-(id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type{
	if (self = [super initWithDuration:dur andEffectType:type]){
		AudioController* ac = [AudioController sharedInstance];
		audioTitles = [[NSMutableArray alloc] initWithCapacity:2];
		[audioTitles addObject:[NSString stringWithFormat:@"FireballStart%@", self]];
		[audioTitles addObject:[NSString stringWithFormat:@"FireballImpact%@", self]];
		[ac addNewPlayerWithTitle:[audioTitles objectAtIndex:0] andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/FireballStart" ofType:@"wav"]]];
		[ac addNewPlayerWithTitle:[audioTitles objectAtIndex:1] andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/FireBallImpact" ofType:@"wav"]]];
		[ac playTitle:[audioTitles objectAtIndex:0]];
	}
	
	return self;
}
-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid thePlayer:(Player*)thePlayer gameTime:(float)timeDelta
{
	if (self.timeApplied != 0.0 && !isExpired)
	{
		self.timeApplied += timeDelta;
		[thePlayer setStatusText:[NSString stringWithFormat:@"A Fireball will strike you in %1.2f seconds. Move!",duration - self.timeApplied]];
		if (timeDelta >= duration){
			//Here we do some effect, but we have to subclass Effects to decide what that is
			
			NSInteger movementDelta = [thePlayer position] - lastPosition;
			if (movementDelta < 30){
				[thePlayer setHealth:[thePlayer health] - 50];
				AudioController *ac = [AudioController sharedInstance];
				[ac playTitle:[audioTitles objectAtIndex:1]];
			}
			self.timeApplied = 0.0;
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

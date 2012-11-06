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
#import "Ability.h"
#import "Spell.h"
#import "RaidMember.h"

@implementation Effect
@synthesize duration, isExpired, target, effectType, timeApplied=_timeApplied, maxStacks, spriteName, title, ailmentType, owner, healingDoneMultiplierAdjustment, damageDoneMultiplierAdjustment, castTimeAdjustment;
@synthesize needsOwnershipResolution, ownerNetworkID, failureChance; //HACKY

-(void)dealloc{
    [spriteName release];
    [title release];
    [ownerNetworkID release];
    [super dealloc];
}
-(id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type
{
    if (self = [super init]){
        duration = dur;
        isExpired = NO;
        effectType = type;
        self.maxStacks = 1;
        self.isIndependent = NO;
        self.spellCostAdjustment = 0.0;
    }
	return self;
}

-(BOOL)shouldFail{
    return (arc4random() % 1000) <= (failureChance * 1000);
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
    copied.isIndependent = self.isIndependent;
    copied.ailmentType = self.ailmentType;
    copied.damageDoneMultiplierAdjustment = self.damageDoneMultiplierAdjustment;
    copied.healingDoneMultiplierAdjustment = self.healingDoneMultiplierAdjustment;
    copied.castTimeAdjustment = self.castTimeAdjustment;
    copied.spellCostAdjustment = self.spellCostAdjustment;
    copied.failureChance = self.failureChance;
    copied.causesConfusion = self.causesConfusion;
    return copied;
}

- (void)targetDidCastSpell:(Spell*)spell {
    
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
	if (!isExpired && duration != -1)
	{
        self.timeApplied += timeDelta;
		if (self.timeApplied >= duration ){
			//Here we do some effect, but we have to subclass Effects to decide what that is
			//The one thing we always do here is expire the effect
			self.timeApplied = 0.0;
			isExpired = YES;			
		}
		
	}
	
}

-(NSString*)title{
    if (title){
        return title;
    }
    return NSStringFromClass([self class]);
}

- (BOOL)isKindOfEffect:(Effect*)effect {
    if ([self.title isEqualToString:effect.title]){
        return YES;
    }
    return NO;
}

-(void)effectWillBeDispelled:(Raid*)raid player:(Player*)player{
    
}

-(void)expire{
    //This gets called when an effect is removed, not to cause an effect to expire
}

//EFF|TARGET|TITLE|DURATION|TYPE|SPRITENAME|OWNER|HDM|DDM|Ind
-(NSString*)asNetworkMessage{
    NSString* message = [NSString stringWithFormat:@"EFF|%@|%f|%f|%i|%@|%@|%f|%f|%i", self.title, self.duration, self.timeApplied ,self.effectType, self.spriteName, self.owner, self.healingDoneMultiplierAdjustment, self.damageDoneMultiplierAdjustment, self.isIndependent];
    
    return message;
}
-(id)initWithNetworkMessage:(NSString*)message{
    NSArray *messageComponents = [message componentsSeparatedByString:@"|"];
    if (self = [self initWithDuration:[[messageComponents objectAtIndex:2] doubleValue] andEffectType:[[messageComponents objectAtIndex:4] intValue]]){
        self.title = [messageComponents objectAtIndex:1];
        self.timeApplied = [[messageComponents objectAtIndex:3] doubleValue];
        self.spriteName = [messageComponents objectAtIndex:5];
        self.ownerNetworkID = [messageComponents objectAtIndex:6];
        self.healingDoneMultiplierAdjustment = [[messageComponents objectAtIndex:7] floatValue];
        self.damageDoneMultiplierAdjustment = [[messageComponents objectAtIndex:8] floatValue];
        self.isIndependent = [[messageComponents objectAtIndex:9] boolValue];
    }
    return self;
}
@end

#pragma mark - Divinity Effects

@implementation DivinityEffect
@synthesize divinityKey;
- (void)dealloc {
    [divinityKey release];
    [super dealloc];
}
- (id)initWithDivinityKey:(NSString *)divKey {
    if (self=[super initWithDuration:-1 andEffectType:EffectTypeDivinity]){
        self.divinityKey = divKey;
        self.title = divKey;
        
        if ([divKey isEqualToString:@"godstouch"]){
            self.healingDoneMultiplierAdjustment = .1;
            self.spellCostAdjustment = .1;
        }
    }
    return self;
}

@end

#pragma mark - Shipping Spell Effects
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
	if (!isExpired && duration != -1)
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
			//The one thing we always do here is expire the effect
			self.timeApplied = 0.0;
			isExpired = YES;
		}
	}
}


-(void)tick{
    self.numHasTicked++;
    if (!self.target.isDead){
        if (self.shouldFail){
            
        }else{
            NSInteger amount = FUZZ(self.valuePerTick, 15.0);
            CombatEventType eventType = amount > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
            float modifier = amount > 0 ? self.owner.healingDoneMultiplier : self.owner.damageDoneMultiplier;
            NSInteger preHealth = self.target.health;
            [self.target setHealth:[self.target health] + amount * modifier];
            NSInteger finalAmount = self.target.health - preHealth;
            if ([self.owner isKindOfClass:[Player class]]){
                NSInteger overheal = amount - finalAmount;
                [(Player*)self.owner playerDidHealFor:finalAmount onTarget:(RaidMember*)self.target fromEffect:self withOverhealing:overheal];

            }else {
                //This is boss damage in the form of dots
                [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:amount] andEventType:eventType]];
            }
        }
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
            [orbPop setIsIndependent:YES];
            [orbPop setOwner:self.owner];
            [orbPop setValue:self.amountPerReaction * self.owner.healingDoneMultiplier];
            
            [self.target addEffect:orbPop];
            [orbPop release];
        }
    }
    
    
}
@end

@implementation  DelayedHealthEffect
@synthesize value, appliedEffect;
- (void)dealloc{
    [appliedEffect release];
    [super dealloc];
}
- (id)copy{
    DelayedHealthEffect *copy = [super copy];
    [copy setValue:self.value];
    [copy setAppliedEffect:self.appliedEffect];
    return copy;
}

- (void)reset {
    [super reset];
}

- (void)expire{
    if (!self.target.isDead){
        if (self.shouldFail){
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:0 andEventType:CombatEventTypeDodge]];
        }else{
            CombatEventType eventType = self.value > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
            float modifier = self.value > 0 ? self.owner.healingDoneMultiplier : self.owner.damageDoneMultiplier;
            NSInteger amount = self.value * modifier;
            NSInteger preHealth = self.target.health;
            [self.target setHealth:self.target.health + amount];
            NSInteger finalAmount = self.target.health - preHealth;
            if ([self.owner isKindOfClass:[Player class]]){
                NSInteger overheal = amount - finalAmount;
                [(Player*)self.owner playerDidHealFor:finalAmount onTarget:(RaidMember*)self.target fromEffect:self withOverhealing:overheal];
            }else {
                [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:self.value] andEventType:eventType]];
            }
            if (self.appliedEffect){
                [self.appliedEffect setOwner:self.owner];
                [self.target addEffect:self.appliedEffect];
                self.appliedEffect = nil;
            }
        }
    }
    [super expire];
}
@end

@implementation SwirlingLightEffect

-(void)tick{
    int similarEffectCount = 1;
    for (Effect *effect in self.target.activeEffects){
        if ([effect isKindOfEffect:self]){
            similarEffectCount++;
        }
    }
    NSInteger preHealth = self.target.health;
    [self.target setHealth:self.target.health + (int)round((self.owner.healingDoneMultiplier * self.valuePerTick * (similarEffectCount * .25)))];
    NSInteger finalAmount = self.target.health - preHealth;
    NSInteger overheal = self.valuePerTick - finalAmount;
    [(Player*)self.owner playerDidHealFor:finalAmount onTarget:(RaidMember*)self.target fromEffect:self withOverhealing:overheal];
}
@end


@implementation TrulzarPoison
-(void)tick{
    if (!self.target.isDead){
        float percentComplete = self.timeApplied / self.duration;
        CombatEventType eventType = self.valuePerTick > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:self.valuePerTick] andEventType:eventType]];
        [self.target setHealth:self.target.health + self.owner.damageDoneMultiplier * ([self valuePerTick] * (int)round(1+percentComplete))];
    }
}

@end

@implementation CouncilPoison
-(void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    if (*currentHealth < *newHealth){
		NSInteger healthDelta = *currentHealth - *newHealth;
		NSInteger newHealthDelta = healthDelta * .5;
		*newHealth = *currentHealth - newHealthDelta;
	}
}
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth{
    
}
@end

@implementation CouncilPoisonball
-(void)expire{
    if (self.shouldFail){
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:0 andEventType:CombatEventTypeDodge]];
    }else{
        CouncilPoison *poisonDoT = [[CouncilPoison alloc] initWithDuration:6 andEffectType:EffectTypeNegative];
        [poisonDoT setTitle:@"council-ball-dot"];
        [poisonDoT setSpriteName:@"poison.png"];
        [poisonDoT setValuePerTick:-40];
        [poisonDoT setNumOfTicks:3];
        [poisonDoT setOwner:self.owner];
        [poisonDoT setAilmentType:AilmentPoison];
        [self.target addEffect:poisonDoT];
        [poisonDoT release];
        [super expire];
    }
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

@implementation DamageTakenDecreasedEffect
@synthesize percentage;
-(void)didChangeHealthFrom:(NSInteger )health toNewHealth:(NSInteger )newHealth
{
}
-(void)willChangeHealthFrom:(NSInteger *)health toNewHealth:(NSInteger *)newHealth{
	
	if (*health > *newHealth){
		NSInteger healthDelta = *health - *newHealth;
        
		NSInteger newHealthDelta = healthDelta	* (1 - percentage);
		*newHealth = *health - newHealthDelta;
	}
}
@end

@implementation DamageTakenIncreasedEffect
@synthesize percentage;
-(void)didChangeHealthFrom:(NSInteger )health toNewHealth:(NSInteger )newHealth
{
}
-(void)willChangeHealthFrom:(NSInteger *)health toNewHealth:(NSInteger *)newHealth{
	
	if (*health > *newHealth){
		NSInteger healthDelta = *health - *newHealth;
        
		NSInteger newHealthDelta = healthDelta	* (1 + percentage);
		*newHealth = *health - newHealthDelta;
	}
}
@end

@implementation BulwarkEffect
+(id)defaultEffect{
	BulwarkEffect *be = [[BulwarkEffect alloc] initWithDuration:15 andEffectType:EffectTypePositive];
    [be setTitle:@"bulwark-effect"];
	[be setAmountToShield:600];
    [be setSpriteName:@"healing_default.png"];
    [be setMaxStacks:1];
	return [be autorelease];
}
@end

@implementation RothPoison
@synthesize dispelDamageValue, baseValue, valuePerTick=_valuePerTick;
-(void)setValuePerTick:(NSInteger)valPerTick{
    if (self.baseValue == 0){
        self.baseValue = valPerTick;
    }
    _valuePerTick = valPerTick;
}

-(void)tick{
    [super tick];
    self.valuePerTick = self.baseValue * self.numHasTicked;
}
-(void)effectWillBeDispelled:(Raid *)raid player:(Player *)player{
    for (RaidMember*member in raid.raidMembers){
        [member setHealth:member.health + (self.dispelDamageValue * self.owner.damageDoneMultiplier)];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:[NSNumber numberWithInt:self.dispelDamageValue * self.owner.damageDoneMultiplier] andEventType:CombatEventTypeDamage]];
    }
}
@end 


@implementation DarkCloudEffect 
@synthesize baseValue, valuePerTick=_valuePerTick;

-(void)setValuePerTick:(NSInteger)valPerTick{
    if (self.baseValue == 0){
        self.baseValue = valPerTick;
    }
    _valuePerTick = valPerTick;
}
-(void)tick{
    self.valuePerTick = (2 - self.target.healthPercentage) * baseValue;
    [super tick];
}
-(void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    if (*currentHealth < *newHealth){
		NSInteger healthDelta = *currentHealth - *newHealth;
		NSInteger newHealthDelta = healthDelta * .05;
		*newHealth = *currentHealth - newHealthDelta;
	}
}
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth{
    
}
-(void)expire{
    [super expire];
}
@end

@implementation  ExecutionEffect
@synthesize effectivePercentage;
-(id)copy{
    ExecutionEffect * copy = [super copy];
    [copy setEffectivePercentage:self.effectivePercentage];
    return copy;
}

-(void)expire{
    if (self.target.healthPercentage <= effectivePercentage && !self.target.isDead){
        CombatEventType eventType = self.value > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
        [self.target setHealth:self.target.health + self.value];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:self.value] andEventType:eventType]]; 
    }
}
@end

@implementation IntensifyingRepeatedHealthEffect
@synthesize increasePerTick;
-(id)copy{
    IntensifyingRepeatedHealthEffect *copy = [super copy];
    [copy setIncreasePerTick:self.increasePerTick];
    return copy;
}
-(void)tick{
    [super tick];
    self.valuePerTick *= (1 + increasePerTick);
}
@end

@implementation WanderingSpiritEffect
@synthesize raid;

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)timeDelta{
    if (!self.raid) {
        self.raid = theRaid;
    }
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
}

- (void)reset{
    //Because WanderingSpirit Swaps targets we never want to reset it's time applied
    isExpired = NO;
}
- (void)tick{
    [super tick];
    RaidMember *candidate = nil;
    if (arc4random() % 2 == 0){
        candidate = [[self.raid lowestHealthTargets:1 withRequiredTarget:nil] objectAtIndex:0];
    }else {
        candidate = [self.raid randomLivingMember];
    }
    if (candidate != self.target && candidate != nil){
        [self retain];
        [self.target removeEffect:self];
        [candidate addEffect:self];
        [self release];
    }
}
@end

@implementation BreakOffEffect
@synthesize reenableAbility;
- (id)copy{
    BreakOffEffect *copy = [super copy];
    [copy setReenableAbility:self.reenableAbility];
    return copy;
}

- (void)dealloc{
    [reenableAbility release];
    [super dealloc];
}
- (void)expire{
    [self.reenableAbility setIsDisabled:NO];
    [super expire];
}
@end

@implementation InvertedHealingEffect
@synthesize percentageConvertedToDamage;
- (id)copy {
    InvertedHealingEffect *copy = [super copy];
    [copy setPercentageConvertedToDamage:self.percentageConvertedToDamage];
    return copy;
}
- (void)willChangeHealthFrom:(NSInteger*)currentHealth toNewHealth:(NSInteger*)newHealth {
    if (*currentHealth < *newHealth){
		NSInteger healthDelta = *currentHealth - *newHealth;
		NSInteger newHealthDelta = -(healthDelta * self.percentageConvertedToDamage);
		*newHealth = *currentHealth - newHealthDelta;
	}
}
- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth{
    
}
@end

@implementation SoulBurnEffect 
@synthesize energyToBurn, needsToBurnEnergy;
- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)timeDelta {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
    
    if (self.needsToBurnEnergy){
        [thePlayer setEnergy:thePlayer.energy - self.energyToBurn];
        self.needsToBurnEnergy = NO;
    }
}

- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth {
    
}

- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth{
    if (currentHealth < newHealth){
        self.needsToBurnEnergy = YES;
    }
}
@end


@implementation GripEffect
-(void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    if (*currentHealth < *newHealth){
		NSInteger healthDelta = *currentHealth - *newHealth;
		NSInteger newHealthDelta = healthDelta * .02;
		*newHealth = *currentHealth - newHealthDelta;
	}
}
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth{
    
}
@end

@implementation TouchOfHopeEffect

- (void)tick {
    if (self.target.healthPercentage < 1.0){
        Player *owningPlayer = (Player*)self.owner;
        [owningPlayer setEnergy:owningPlayer.energy + 12];
    }
    [super tick];
}
@end

@implementation FallenDownEffect

+ (id)defaultEffect {
    FallenDownEffect *fde = [[FallenDownEffect alloc] initWithDuration:-1.0 andEffectType:EffectTypeNegative];
    [fde setTitle:@"fallen-down"];
    [fde setSpriteName:@"fallen-down.png"];
    [fde setGetUpThreshold:.8];
    [fde setAilmentType:AilmentTrauma];
    return [fde autorelease];
}

- (float)damageDoneMultiplierAdjustment {
    return -1.0;
}

- (double)duration {
    return -1.0;
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)timeDelta {
    if (self.target.healthPercentage > self.getUpThreshold){
        self.isExpired = YES;
    }
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
}
@end

@implementation HealingDoneAdjustmentEffect

- (id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type {
    if (self = [super initWithDuration:dur andEffectType:type]){
        self.percentageHealingReceived = 1.0;
    }
    return self;
}
- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    if (*currentHealth < *newHealth){
		NSInteger healthDelta = *currentHealth - *newHealth;
		NSInteger newHealthDelta = healthDelta * self.percentageHealingReceived;
		*newHealth = *currentHealth - newHealthDelta;
	}
}
- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth {
    
}
@end

@implementation EngulfingSlimeEffect

+ (id)defaultEffect {
    EngulfingSlimeEffect *ese = [[EngulfingSlimeEffect alloc] initWithDuration:45.0 andEffectType:EffectTypeNegative];
    [ese setTitle:@"e-slime-eff"];
    [ese setValuePerTick:-1];
    [ese setNumOfTicks:50];
    [ese setSpriteName:@"engulfing_slime.png"];
    [ese setMaxStacks:5];
    [ese setAilmentType:AilmentPoison];
    
    return [ese autorelease];
}

- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{

}
- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth {
    if (currentHealth < newHealth){
		self.isExpired = YES;
	}
}
- (void)effectWillBeDispelled:(Raid *)raid player:(Player *)player {
    for (Effect *effect in self.target.activeEffects){
        if ([effect isKindOfEffect:self] && effect != self){
            effect.isExpired = YES;
        }
    }
}
- (void)tick {
    [super tick];
    NSInteger similarEffectsCount = 0;
    for (Effect *effect in self.target.activeEffects){
        if ([effect isKindOfEffect:self]){
            similarEffectsCount++;
        }
    }
    if (similarEffectsCount >= 5 && !self.target.isDead){
        self.target.health = 0;
        [[(Boss*)self.owner announcer] announce:@"This Unspeakable grows stronger by consuming your ally."];
        Effect *damageBoost = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositive] autorelease];
        [damageBoost setDamageDoneMultiplierAdjustment:.075];
        [damageBoost setMaxStacks:20];
        [damageBoost setTitle:@"unspeak-consume"];
        [(Boss*)self.owner addEffect:damageBoost];
    }
}
@end

@implementation BlessedArmorEffect

-(void)didChangeHealthFrom:(NSInteger )health toNewHealth:(NSInteger )newHealth
{
}
-(void)willChangeHealthFrom:(NSInteger *)health toNewHealth:(NSInteger *)newHealth{
	
	if (*health > *newHealth){
		NSInteger healthDelta = *health - *newHealth;
		NSInteger newHealthDelta = healthDelta	* .5;
		*newHealth = *health - newHealthDelta;
	}
}
@end

@implementation RedemptionEffect

-(void)didChangeHealthFrom:(NSInteger )health toNewHealth:(NSInteger )newHealth
{
}
-(void)willChangeHealthFrom:(NSInteger *)health toNewHealth:(NSInteger *)newHealth{
	
	if (*newHealth <= 0){
        if ([self.redemptionDelegate canRedemptionTrigger]){
            *newHealth = 300;
            [self.redemptionDelegate redemptionDidTriggerOnTarget:self.target];
        }
    }
}
@end

@implementation AvatarEffect
- (void)healRaidWithPulse:(Raid*)theRaid{
    NSArray* raid = [theRaid getAliveMembers];
    for (RaidMember* member in raid){
        [member setHealth:member.health + 20];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:@20 andEventType:CombatEventTypeHeal]];
    }
}

- (void)healNeededTargetInRaid:(Raid*)theRaid{
    NSArray *possibleTargets = [theRaid lowestHealthTargets:3 withRequiredTarget:nil];
    
    RaidMember *target = [possibleTargets objectAtIndex:arc4random() % possibleTargets.count];
    [target setHealth:target.health + (target.maximumHealth * .25)];
    [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:target value:[NSNumber numberWithInt:(target.maximumHealth * .25)] andEventType:CombatEventTypeHeal]];
}

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)timeDelta{
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
    
    self.raidWidePulseCooldown += timeDelta;
    self.healingSpellCooldown += timeDelta;
    
    if (self.raidWidePulseCooldown >= 1.5){
        [self healRaidWithPulse:theRaid];
        self.raidWidePulseCooldown = 0;
    }
    
    if (self.healingSpellCooldown >= 2.5){
        [self healNeededTargetInRaid:theRaid];
        self.healingSpellCooldown = 0;
    }
    
}
@end

@implementation GuardianBarrierEffect
- (void)willChangeHealthFrom:(NSInteger*)currentHealth toNewHealth:(NSInteger*)newHealth
{
	if (*newHealth >= *currentHealth)
	{
		return;
	}
	
	NSInteger healthDelta = *currentHealth - *newHealth;
	
	if (healthDelta >= self.owningGuardian.overhealingShield){
		*newHealth += self.owningGuardian.overhealingShield;
		self.owningGuardian.overhealingShield = 0;
	}
	else if (healthDelta < self.owningGuardian.overhealingShield){
		*newHealth += healthDelta;
		self.owningGuardian.overhealingShield -= healthDelta;
	}
}
- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth {
    
}
@end

@implementation GraspOfTheDamnedEffect

- (void)combatActions:(Boss *)theBoss theRaid:(Raid *)theRaid thePlayer:(Player *)thePlayer gameTime:(float)timeDelta {
    [super combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
    if (self.needsDetonation && !self.isExpired){
        NSArray *aliveMembers = [theRaid getAliveMembers];
        NSInteger damageDealt = 350 * (self.owner.damageDoneMultiplier);
        for (RaidMember *member in aliveMembers){
            [member setHealth:member.health - damageDealt];
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:[NSNumber numberWithInt:damageDealt] andEventType:CombatEventTypeDamage]];
        }
        self.needsDetonation = NO;
        self.isExpired = YES;
        [[(Boss*)self.owner announcer] displayParticleSystemWithName:@"fire_explosion.plist" onTarget:(RaidMember*)self.target];
        [[(Boss*)self.owner announcer] displayScreenShakeForDuration:1.0];
    }
}
- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    
}
- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth {
    if (newHealth > currentHealth){
        self.needsDetonation = YES;
    }
}

@end

@implementation SoulPrisonEffect
- (id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type {
    if (self = [super initWithDuration:dur andEffectType:type]){
        self.percentage = 1.0;
        self.title = @"soul-prison-eff";
        self.spriteName = @"soul_prison.png";
    }
    return self;
}

- (void)expire {
    DelayedHealthEffect *finisher = [[[DelayedHealthEffect alloc] initWithDuration:.25 andEffectType:EffectTypeNegativeInvisible] autorelease];
    [finisher setValue:-60];
    [finisher setTitle:@"soulpris-finish"];
    [finisher setOwner:self.owner];
    [self.target addEffect:finisher];
    
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
		if (lastTick  >= (duration/self.numOfTicks)){
			[self.target setHealth:[self.target health] + self.valuePerTick];
			//NSLog(@"Tick");
			self.valuePerTick += 1;
			lastTick = 0.0;
		}
		if (self.timeApplied >= duration){
			[self.target setHealth:[self.target health] + self.valuePerTick];
			[self.target setHealth:[self.target health] + self.valuePerTick*2];
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
		*newHealth = *health - newHealthDelta;
	}
}

@end

@implementation DebilitateEffect 
- (NSInteger)valuePerTick {
    return 0;
}
- (float)damageDoneMultiplierAdjustment {
    return -1.0;
}
@end

@implementation EnergyAdjustmentPerCastEffect
- (id)copy {
    EnergyAdjustmentPerCastEffect *copy = [super copy];
    [copy setEnergyChangePerCast:self.energyChangePerCast];
    return copy;
}
- (void)targetDidCastSpell:(Spell *)spell {
    if ([self.target isMemberOfClass:[Player class]]){
        Player *targettedPlayer = (Player*)self.target;
        [targettedPlayer setEnergy:targettedPlayer.energy - self.energyChangePerCast];
    }
}
@end

//
//  Effect.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Effect.h"
#import "GameObjects.h"
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
        self.stacks = 1;
        self.isIndependent = NO;
        self.spellCostAdjustment = 0.0;
    }
	return self;
}

- (float)healingDoneMultiplierAdjustment {
    return healingDoneMultiplierAdjustment * self.stacks;
}

- (float)damageDoneMultiplierAdjustment {
    return damageDoneMultiplierAdjustment * self.stacks;
}

- (float)castTimeAdjustment {
    return castTimeAdjustment * self.stacks;
}

- (float)spellCostAdjustment {
    return _spellCostAdjustment * self.stacks;
}

- (float)energyRegenAdjustment {
    return _energyRegenAdjustment * self.stacks;
}

- (float)maximumHealthMultiplierAdjustment {
    return _maximumHealthMultiplierAdjustment * self.stacks;
}

- (NSInteger)maximumAbsorbtionAdjustment {
    return _maximumAbsorbtionAdjustment * self.stacks;
}

- (float)criticalChanceAdjustment {
    return _criticalChanceAdjustment * self.stacks;
}

- (float)cooldownMultiplierAdjustment {
    return _cooldownMultiplierAdjustment * self.stacks;
}

- (float)dodgeChanceAdjustment {
    return _dodgeChanceAdjustment * self.stacks;
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
    copied.maxStacks = maxStacks;
    copied.spriteName = self.spriteName;
    copied.title = self.title;
    copied.owner = self.owner;
    copied.isIndependent = self.isIndependent;
    copied.ailmentType = self.ailmentType;
    copied.damageDoneMultiplierAdjustment = damageDoneMultiplierAdjustment;
    copied.healingDoneMultiplierAdjustment = healingDoneMultiplierAdjustment;
    copied.castTimeAdjustment = castTimeAdjustment;
    copied.spellCostAdjustment = _spellCostAdjustment;
    copied.failureChance = self.failureChance;
    copied.causesConfusion = self.causesConfusion;
    copied.damageTakenMultiplierAdjustment = _damageTakenMultiplierAdjustment;
    copied.cooldownMultiplierAdjustment = _cooldownMultiplierAdjustment;
    copied.energyRegenAdjustment = _energyRegenAdjustment;
    copied.criticalChanceAdjustment = _criticalChanceAdjustment;
    copied.maximumHealthMultiplierAdjustment = _maximumHealthMultiplierAdjustment;
    copied.maximumAbsorbtionAdjustment = _maximumAbsorbtionAdjustment;
    copied.dodgeChanceAdjustment = _dodgeChanceAdjustment;
    copied.stacks = self.stacks;
    copied.visibilityPriority = self.visibilityPriority;
    copied.causesStun = self.causesStun;
    copied.healingReceivedMultiplierAdjustment = self.healingReceivedMultiplierAdjustment;
    copied.causesReactiveDodge = self.causesReactiveDodge;
    copied.causesBlind = self.causesBlind;
    return copied;
}

- (void)targetDidCastSpell:(Spell*)spell {
    
}

-(void)solveOwnershipResolutionForEnemies:(NSArray*)enemies andRaid:(Raid*)raid andPlayers:(NSArray*)players{
    if (self.needsOwnershipResolution && self.ownerNetworkID){
        for (Player *player in players) {
            //For this network hack we only care if it's me or not me.
            if ([player.networkID isEqualToString:self.ownerNetworkID]){
                self.owner = player;
                break;
            }
        }
        self.needsOwnershipResolution = NO;
        self.ownerNetworkID = nil;
    }
}

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    [self solveOwnershipResolutionForEnemies:enemies andRaid:raid andPlayers:players];
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

-(void)effectWillBeDispelled:(Raid*)raid player:(Player*)player enemies:(NSArray *)enemies{
    
}

-(void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta {
    //This gets called when an effect is removed, not to cause an effect to expire
}

- (void)player:(Player*)player causedHealing:(NSInteger)healing
{
    
}

- (void)setStacks:(NSInteger)stacks
{
    if (stacks > self.maxStacks) {
        stacks = self.maxStacks;
    }
    _stacks = stacks;
}

- (NSInteger)visibleStacks
{
    return self.stacks;
}

//EFF|TARGET|TITLE|DURATION|TYPE|SPRITENAME|OWNER|HDM|DDM|Ind
-(NSString*)asNetworkMessage{
    NSString* message = [NSString stringWithFormat:@"EFF|%@|%f|%f|%i|%@|%@|%f|%f|%i|%f|%f|%i|%i|%i|%i|%i|%i", self.title, self.duration, self.timeApplied ,self.effectType, self.spriteName, self.owner, healingDoneMultiplierAdjustment, damageDoneMultiplierAdjustment, self.isIndependent, castTimeAdjustment, _cooldownMultiplierAdjustment, _maximumAbsorbtionAdjustment, self.stacks, self.visibilityPriority, self.causesStun, self.causesBlind, self.causesConfusion];
    
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
        self.castTimeAdjustment = [[messageComponents objectAtIndex:10] floatValue];
        self.cooldownMultiplierAdjustment = [[messageComponents objectAtIndex:11] floatValue];
        self.maximumAbsorbtionAdjustment = [[messageComponents objectAtIndex:12] intValue];
        self.stacks = [[messageComponents objectAtIndex:13] intValue];
        self.visibilityPriority = [[messageComponents objectAtIndex:14] intValue];
        self.causesStun = [[messageComponents objectAtIndex:15] boolValue];
        self.causesBlind = [[messageComponents objectAtIndex:16] boolValue];
        self.causesConfusion = [[messageComponents objectAtIndex:17] boolValue];
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
    }
    return self;
}

@end

#pragma mark - Shipping Spell Effects
@implementation RepeatedHealthEffect

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
- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    [self solveOwnershipResolutionForEnemies:enemies andRaid:raid andPlayers:players];
	if (!isExpired && duration != -1)
	{
        self.timeApplied += timeDelta;
		lastTick += timeDelta;
		if (lastTick >= (duration/_numOfTicks)){
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
	} else if (duration == -1.0) {
        //For infinite durations, tick once a second.
        lastTick += timeDelta;
        if (lastTick >= 1.0) {
            [self tick];
            lastTick = 0.0;
        }
    }
}


-(void)tick{
    self.numHasTicked++;
    if (!self.target.isDead){
        if (self.shouldFail){
            
        } else {
            BOOL critical = NO;
            Player *owningPlayer = nil;
            if ([self.owner isKindOfClass:[Player class]]) {
                owningPlayer = (Player*)self.owner;
                if (arc4random() % 100 < owningPlayer.spellCriticalChance * 100) {
                    critical = YES;
                }
            }
            
            NSInteger amount = FUZZ(self.valuePerTick, 15.0);
            if (critical && owningPlayer) {
                amount *= owningPlayer.criticalBonusMultiplier;
            }
            
            CombatEventType eventType = amount > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
            float modifier = amount > 0 ? self.owner.healingDoneMultiplier : self.owner.damageDoneMultiplier;
            NSInteger preHealth = self.target.health;
            [self.target setHealth:[self.target health] + amount * modifier * self.stacks];
            NSInteger finalAmount = self.target.health - preHealth;
            if (owningPlayer){
                NSInteger overheal = amount - finalAmount;
                [(Player*)self.owner playerDidHealFor:finalAmount onTarget:(RaidMember*)self.target fromEffect:self withOverhealing:overheal asCritical:critical];
            } else {
                //This is boss damage in the form of dots
                [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:amount] andEventType:eventType]];
            }
        }
    }
}

@end

@implementation ShieldEffect

-(id)copy{
    ShieldEffect *copy = [super copy];
    [copy setAmountToShield:self.amountToShield];
    return copy;
}

- (NSInteger)maximumAbsorbtionAdjustment
{
    Player *owningPlayer = (Player*)self.owner;
    return self.amountToShield * self.stacks * (self.isCriticalShield ? (owningPlayer.criticalBonusMultiplier) : 1);
}

- (void)reset
{
    [super reset];
    self.isCriticalShield = NO;
    self.hasAppliedAbsorb = NO;
}

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    if (!self.hasAppliedAbsorb) {
        Player *owningPlayer = (Player *)self.owner;
        if (arc4random() % 1000 <= owningPlayer.spellCriticalChance * 1000) {
            self.isCriticalShield = YES;
        }
        self.hasAppliedAbsorb = YES;
        self.target.absorb += self.maximumAbsorbtionAdjustment;
    }
    if (self.target.absorb == 0) {
        self.isExpired = YES;
    }
}

- (void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta
{
    NSInteger absorptionUsed = self.amountToShield * self.stacks - self.target.absorb;
    NSInteger wastedAbsorb = self.amountToShield * self.stacks - absorptionUsed;
    
    if (wastedAbsorb > 0) {
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:wastedAbsorb] andEventType:CombatEventTypeOverheal]];
    }
    
    [super expireForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
}
@end

@implementation BarrierEffect
- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    if (self.isExpired) {
        Player *owningPlayer = (Player*)self.owner;
        [owningPlayer setEnergy:owningPlayer.energy + [(Spell*)[Barrier defaultSpell] energyCost] * .66];
    }
}
@end

@implementation ReactiveHealEffect
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

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
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
            DelayedHealthEffect *orbPop = [[DelayedHealthEffect alloc] initWithDuration:0.25 andEffectType:EffectTypePositiveInvisible];
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
- (void)dealloc{
    [_appliedEffect release];
    [_completionParticleName release];
    [super dealloc];
}
- (id)copy{
    DelayedHealthEffect *copy = [super copy];
    [copy setValue:self.value];
    [copy setAppliedEffect:[[self.appliedEffect copy] autorelease]];
    return copy;
}

- (void)reset {
    [super reset];
}

- (void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta{
    if (!self.target.isDead){
        if (self.shouldFail){
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:0 andEventType:CombatEventTypeDodge]];
        }else{
            CombatEventType eventType = self.value > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
            Player *owningPlayer = nil;
            BOOL critical = NO;
            if ([self.owner isKindOfClass:[Player class]]) {
                owningPlayer = (Player*)self.owner;
                if (arc4random() % 100 < owningPlayer.spellCriticalChance * 100) {
                    critical = YES;
                }
            }
            float modifier = self.value > 0 ? self.owner.healingDoneMultiplier : self.owner.damageDoneMultiplier;
            NSInteger amount = self.value * modifier;
            if (critical && owningPlayer) {
                amount *= owningPlayer.criticalBonusMultiplier;
            }
            NSInteger preHealth = self.target.health;
            [self.target setHealth:self.target.health + amount * self.stacks];
            NSInteger finalAmount = self.target.health - preHealth;
            if (owningPlayer){
                NSInteger overheal = amount - finalAmount;
                [(Player*)self.owner playerDidHealFor:finalAmount onTarget:(RaidMember*)self.target fromEffect:self withOverhealing:overheal asCritical:critical];
            }else {
                [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:self.value] andEventType:eventType]];
            }
            if (self.appliedEffect){
                Effect *applyThis = [[self.appliedEffect copy] autorelease];
                [applyThis setOwner:self.owner];
                [self.target addEffect:applyThis];
                self.appliedEffect = nil;
            }
            if (self.completionParticleName) {
                [self.owner.announcer displayParticleSystemWithName:self.completionParticleName onTarget:(RaidMember*)self.target];
            }
        }
    }
    [super expireForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
}
@end

@implementation SwirlingLightEffect

- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth
{
    
}

- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth
{
    if (*currentHealth < *newHealth){
        
        if (self.stacks == 3) {
            NSInteger healthDelta = *currentHealth - *newHealth;
            NSInteger newHealthDelta = healthDelta * 1.05;
            *newHealth = *currentHealth - newHealthDelta;
        }
	}

}
@end


@implementation TrulzarPoison
-(void)tick{
    if (!self.target.isDead){
        float percentComplete = self.timeApplied / self.duration;
        CombatEventType eventType = self.valuePerTick > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:self.owner.damageDoneMultiplier * ([self valuePerTick] * (int)round(1+percentComplete))] andEventType:eventType]];
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
-(void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta {
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
        [super expireForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    }
}

@end

@implementation  ExpireThresholdRepeatedHealthEffect

- (id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type
{
    if (self = [super initWithDuration:dur andEffectType:type]) {
        self.threshold = 1.0;
    }
    return self;
}

- (id)copy
{
    ExpireThresholdRepeatedHealthEffect *copy = [super copy];
    [copy setThreshold:self.threshold];
    return copy;
}

- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth
{
    
}

- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth
{
    if (currentHealth < newHealth) {
        //A heal occured
        if (self.target.health > self.target.maximumHealth * self.threshold){
            self.isExpired = YES;
        }
    }
}
@end

@implementation RaidDamageOnDispelStackingRHE
- (id)copy
{
    RaidDamageOnDispelStackingRHE *copy = [super copy];
    [copy setDispelDamageValue:self.dispelDamageValue];
    return copy;
}

-(void)effectWillBeDispelled:(Raid *)raid player:(Player *)player enemies:(NSArray *)enemies{
    for (RaidMember*member in raid.raidMembers){
        [member setHealth:member.health + (self.dispelDamageValue * self.owner.damageDoneMultiplier)];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:[NSNumber numberWithInt:self.dispelDamageValue * self.owner.damageDoneMultiplier] andEventType:CombatEventTypeDamage]];
    }
    [self.owner.announcer displayParticleSystemOnRaidWithName:@"poison_raid_burst.plist" delay:0];
    [self.owner.announcer playAudioForTitle:@"explosion2.wav"];
}
@end 


@implementation DarkCloudEffect 

-(void)setValuePerTick:(NSInteger)valPerTick{
    if (self.baseValue == 0){
        self.baseValue = valPerTick;
    }
    [super setValuePerTick:valPerTick];
}
-(void)tick{
    self.valuePerTick = (2 - self.target.healthPercentage) * _baseValue;
    [super tick];
}
-(void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    if (*currentHealth < *newHealth){
		NSInteger healthDelta = *currentHealth - *newHealth;
		NSInteger newHealthDelta = healthDelta * .15;
		*newHealth = *currentHealth - newHealthDelta;
	}
}
-(void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth{
    
}
-(void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta{
    [super expireForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
}
@end

@implementation  ExecutionEffect
@synthesize effectivePercentage;
-(id)copy{
    ExecutionEffect * copy = [super copy];
    [copy setEffectivePercentage:self.effectivePercentage];
    return copy;
}

- (void)dealApplicationDamage
{
    NSInteger currentHealth = self.target.health;
    NSInteger healthLimit = self.target.maximumHealth * .4;
    if (currentHealth > healthLimit) {
        [self.target setHealth:healthLimit];
        if (currentHealth > healthLimit) {
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:(currentHealth - healthLimit)] andEventType:CombatEventTypeDamage]];
        }
    }
    self.hasDealtApplicationDamage = YES;
}

- (void)reset
{
    [super reset];
    self.hasDealtApplicationDamage = NO;
}

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    if (!self.hasDealtApplicationDamage) {
        [self dealApplicationDamage];
    }
}

-(void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta{
    if (self.target.healthPercentage <= effectivePercentage && !self.target.isDead){
        CombatEventType eventType = self.value > 0 ? CombatEventTypeHeal : CombatEventTypeDamage;
        [self.target setHealth:self.target.health + self.value];
        [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:self.value] andEventType:eventType]];
        [self.owner.announcer playAudioForTitle:@"largeaxe.mp3"];
    }
}
@end

@implementation IntensifyingRepeatedHealthEffect
-(id)copy{
    IntensifyingRepeatedHealthEffect *copy = [super copy];
    [copy setIncreasePerTick:self.increasePerTick];
    return copy;
}
-(void)tick{
    [super tick];
    self.valuePerTick *= (1 + _increasePerTick);
}
@end

@implementation WanderingSpiritEffect
- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    self.raid = raid;
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
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

- (void)tick
{
    [super tick];
    [self.owner.announcer playAudioForTitle:@"sword_slash.mp3"];
}
- (void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta{
    [self.reenableAbility setIsDisabled:NO];
    [super expireForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
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
- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    
    if (self.needsToBurnEnergy){
        for (Player *thePlayer in players) {
            [thePlayer setEnergy:thePlayer.energy - self.energyToBurn];
        }
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
		NSInteger newHealthDelta = healthDelta * .2;
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
        [owningPlayer setEnergy:owningPlayer.energy + [(Spell*)[TouchOfHope defaultSpell] energyCost] * .1];
    }
    [super tick];
}
@end

@implementation FallenDownEffect

+ (id)defaultEffect {
    FallenDownEffect *fde = [[FallenDownEffect alloc] initWithDuration:-1.0 andEffectType:EffectTypeNegative];
    [fde setCausesStun:YES];
    [fde setTitle:@"fallen-down"];
    [fde setSpriteName:@"fallen-down.png"];
    [fde setGetUpThreshold:.8];
    [fde setAilmentType:AilmentTrauma];
    return [fde autorelease];
}

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (self.target.healthPercentage > self.getUpThreshold){
        self.isExpired = YES;
    }
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
}
@end

@implementation HealingDoneAdjustmentEffect

- (id)copy
{
    HealingDoneAdjustmentEffect *copy = [super copy];
    [copy setPercentageHealingReceived:self.percentageHealingReceived];
    return copy;
}

- (id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type {
    if (self = [super initWithDuration:dur andEffectType:type]){
        self.percentageHealingReceived = 1.0;
    }
    return self;
}
- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    if (*currentHealth < *newHealth){
		NSInteger healthDelta = *currentHealth - *newHealth;
		NSInteger newHealthDelta = healthDelta * self.percentageHealingReceived * self.stacks;
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
    [ese setValuePerTick:-10];
    [ese setNumOfTicks:50];
    [ese setSpriteName:@"slime.png"];
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
- (void)effectWillBeDispelled:(Raid *)raid player:(Player *)player enemies:(NSArray *)enemies {
    for (Effect *effect in self.target.activeEffects){
        if ([effect isKindOfEffect:self] && effect != self){
            effect.isExpired = YES;
        }
    }
}
- (void)tick {
    [super tick];
    if (self.stacks >= 5 && !self.target.isDead){
        self.target.health = 0;
        [[(Enemy*)self.owner announcer] announce:@"This Unspeakable grows stronger by consuming your ally."];
        Effect *damageBoost = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositive] autorelease];
        [damageBoost setDamageDoneMultiplierAdjustment:.075];
        [damageBoost setMaxStacks:20];
        [damageBoost setTitle:@"unspeak-consume"];
        [(Enemy*)self.owner addEffect:damageBoost];
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
            Effect *immunity = [[[Effect alloc] initWithDuration:2.5 andEffectType:EffectTypePositive] autorelease];
            [immunity setTitle:@"immunity"];
            [immunity setSpriteName:@"redemption.png"];
            [immunity setOwner:self.owner];
            [immunity setDamageTakenMultiplierAdjustment:-1.0];
            [self.target addEffect:immunity];
            [self.redemptionDelegate redemptionDidTriggerOnTarget:self.target];
        }
    }
}
@end

@implementation AvatarEffect
- (void)healRaidWithPulse:(Raid*)theRaid{
    NSArray* raid = [theRaid livingMembers];
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

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    
    self.raidWidePulseCooldown += timeDelta;
    self.healingSpellCooldown += timeDelta;
    
    if (self.raidWidePulseCooldown >= 1.5){
        [self healRaidWithPulse:raid];
        self.raidWidePulseCooldown = 0;
    }
    
    if (self.healingSpellCooldown >= 2.5){
        [self healNeededTargetInRaid:raid];
        self.healingSpellCooldown = 0;
    }
    
}
@end


@implementation GraspOfTheDamnedEffect

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    if (self.needsDetonation && !self.isExpired){
        NSArray *aliveMembers = [raid livingMembers];
        NSInteger damageDealt = 350 * (self.owner.damageDoneMultiplier);
        for (RaidMember *member in aliveMembers){
            [member setHealth:member.health - damageDealt];
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:member value:[NSNumber numberWithInt:damageDealt] andEventType:CombatEventTypeDamage]];
        }
        self.needsDetonation = NO;
        self.isExpired = YES;
        [[(Enemy*)self.owner announcer] displayParticleSystemWithName:@"fire_explosion.plist" onTarget:(RaidMember*)self.target];
        [[(Enemy*)self.owner announcer] displayScreenShakeForDuration:1.0];
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
        self.damageTakenMultiplierAdjustment = -1.0;
        self.title = @"soul-prison-eff";
        self.spriteName = @"soul_prison.png";
    }
    return self;
}

- (void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta {
    DelayedHealthEffect *finisher = [[[DelayedHealthEffect alloc] initWithDuration:.25 andEffectType:EffectTypeNegativeInvisible] autorelease];
    [finisher setValue:-60];
    [finisher setTitle:@"soulpris-finish"];
    [finisher setOwner:self.owner];
    [self.target addEffect:finisher];
    
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
        [targettedPlayer setEnergy:targettedPlayer.energy - self.energyChangePerCast * self.stacks];
    }
}
@end

@implementation IRHEDispelsOnHeal
- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    
}
- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth {
    if (currentHealth < newHealth){
		self.isExpired = YES;
	}
}
@end

@implementation ExpiresAfterSpellCastsEffect

- (id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type
{
    if (self = [super initWithDuration:dur andEffectType:type]) {
        self.numCastsRemaining = 1;
    }
    return self;
}

- (void)targetDidCastSpell:(Spell *)spell
{
    if (self.ignoresInstantSpells && spell.castTime == 0.0) {
        
    } else {
        self.numCastsRemaining--;
        if (self.numCastsRemaining <= 0) {
            self.isExpired = YES;
        }
    }
}
@end

@implementation ContagiousEffect
- (id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type
{
    if (self = [super initWithDuration:dur andEffectType:type]) {
        self.numberSpreads = 1;
    }
    return self;
}
- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    if (self.isSpread) {
        for (int i = 0; i < self.numberSpreads; i++) {
            ContagiousEffect *spreadEffect = [self.copy autorelease];
            [spreadEffect setValuePerTick:spreadEffect.valuePerTick * 1.05];
            RaidMember *randomTarget = [raid randomLivingMember];
            [randomTarget addEffect:spreadEffect];
        }
        self.isSpread = NO;
    }
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
}

- (NSInteger)stacks
{
    return (int)(10.0 - self.timeApplied);
}

- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth
{
    
}

- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth
{
    if (currentHealth < newHealth) {
        if (self.timeApplied / self.duration < .5) {
            self.isSpread = YES;
        }
    }
}
@end

@implementation StackingRepeatedHealthEffect
- (void)tick
{
    [super tick];
    self.stacks++;
}
@end

@implementation StackingRHEDispelsOnHeal
- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    
}
- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth {
    if (currentHealth < newHealth){
		self.isExpired = YES;
	}
}
@end

@implementation WrackingPainEffect

- (id)copy
{
    WrackingPainEffect *copy = [super copy];
    [copy setThreshold:self.threshold];
    return copy;
}

- (id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type
{
    if (self = [super initWithDuration:dur andEffectType:type]) {
        self.threshold = .5;
    }
    return self;
}

- (void)tick
{
    [super tick];
    if (self.target.healthPercentage <= self.threshold) {
        self.isExpired = YES;
    }
}

@end

@implementation BurningInsanity
- (id)initWithDuration:(NSTimeInterval)dur andEffectType:(EffectType)type
{
    if (self = [super initWithDuration:dur andEffectType:type]) {
        [self setTitle:@"Burning Insanity"];
        [self setValuePerTick:-10];
        [self setMaxStacks:3];
        [self setThreshold:.6];
    }
    return self;
}

- (void)combatUpdateForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta
{
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    if (self.stacks >= self.maxStacks) {
        if (!self.isExpired){
            Effect *fury = [[[Effect alloc] initWithDuration:75 andEffectType:EffectTypePositive] autorelease];
            [fury setSpriteName:@"temper.png"];
            [fury setDamageDoneMultiplierAdjustment:4];
            [fury setTitle:@"fury-eff"];
            [fury setOwner:self.owner];
            [self.target addEffect:fury];
        }
        self.isExpired = YES;
    }
}

- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    if (*currentHealth < *newHealth){
		NSInteger healthDelta = *currentHealth - *newHealth;
		NSInteger newHealthDelta = healthDelta * (1 - (.25 * self.stacks));
		*newHealth = *currentHealth - newHealthDelta;
	}
}
@end

@implementation AbsorbsHealingEffect

- (id)copy
{
    AbsorbsHealingEffect *copy = [super copy];
    [copy setHealingToAbsorb:self.healingToAbsorb];
    return copy;
}

- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth{
    if (*currentHealth < *newHealth){
		NSInteger healthDelta = *newHealth - *currentHealth;
        if (self.healingToAbsorb >= healthDelta) {
            *newHealth = *currentHealth;
            self.healingToAbsorb -= healthDelta;
        } else {
            *newHealth = *newHealth - self.healingToAbsorb;
            self.healingToAbsorb = 0;
            self.isExpired = YES;
        }
	}
}
- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth {

}
@end

@implementation DelayedSetHealthEffect

- (void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta{
    if (!self.target.isDead){
        if (self.shouldFail){
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:0 andEventType:CombatEventTypeDodge]];
        }else{
            CombatEventType eventType = CombatEventTypeDamage;
            NSInteger preHealth = self.target.health;
            [self.target setHealth:self.value];
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:preHealth - self.value] andEventType:eventType]];
            if (self.appliedEffect){
                Effect *applyThis = [[self.appliedEffect copy] autorelease];
                [applyThis setOwner:self.owner];
                [self.target addEffect:applyThis];
                self.appliedEffect = nil;
            }
            if (self.completionParticleName) {
                [self.owner.announcer displayParticleSystemWithName:self.completionParticleName onTarget:(RaidMember*)self.target];
            }
        }
    }
}
@end

@implementation ConsumingCorruption
- (id)copy
{
    ConsumingCorruption *copy = [super copy];
    [copy setConsumptionThreshold:self.consumptionThreshold];
    [copy setHealPercentage:self.healPercentage];
    return copy;
}

- (void)tick
{
    if (self.target.healthPercentage <= self.consumptionThreshold) {
        Enemy *enemyOwner = (Enemy*)self.owner;
        [enemyOwner setHealth:enemyOwner.health + enemyOwner.maximumHealth * self.healPercentage];
    }
    [super tick];
}
@end

@implementation UnstableToxin

- (void)effectWillBeDispelled:(Raid *)raid player:(Player *)player enemies:(NSArray *)enemies
{
    Enemy *enemyOwner = (Enemy*)self.owner;
    [enemyOwner stunForDuration:1.0];
    [enemyOwner.announcer displayScreenShakeForDuration:1.0];
    
    for (RaidMember *member in raid.livingMembers) {
        DelayedHealthEffect *explosion = [[[DelayedHealthEffect alloc] initWithDuration:.1 andEffectType:EffectTypeNegativeInvisible] autorelease];
        [explosion setValue:-100];
        [explosion setOwner:self.owner];
        [explosion setTitle:@"unstable-explosion"];
        [member addEffect:explosion];
    }
    [self.owner.announcer playAudioForTitle:@"fieryexplosion.mp3"];
}
@end


@implementation SpiritBarrier
- (void)expireForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta
{
    if (self.healingToAbsorb <= 0) {
        [self.owner.announcer displayParticleSystemOnRaidWithName:@"purple_pulse.plist" delay:0.0];
        for (RaidMember *member in raid.livingMembers) {
            Effect *damageReduction = [[[Effect alloc] initWithDuration:8 andEffectType:EffectTypePositive] autorelease];
            [damageReduction setDamageTakenMultiplierAdjustment:-.80];
            [damageReduction setSpriteName:@"spirit_shell.png"];
            [damageReduction setOwner:self.owner];
            [damageReduction setTitle:@"spirit-shell-eff"];
            [member addEffect:damageReduction];
        }
    }
}
@end

@implementation CorruptedMind

- (id)copy
{
    CorruptedMind *copy = [super copy];
    [copy setEffectForHealing:self.effectForHealing];
    [copy setTickChangeForHealing:self.tickChangeForHealing];
    return copy;
}

- (void)dealloc
{
    [_effectForHealing release];
    [super dealloc];
}

- (void)player:(Player*)player causedHealing:(NSInteger)healing
{
    if (self.effectForHealing) {
        Effect *eff = [[self.effectForHealing copy] autorelease];
        [eff setOwner:self.owner];
        [player addEffect:eff];
    }
    
    self.valuePerTick += self.tickChangeForHealing;
    self.timeApplied = MAX(0,self.timeApplied - .5);
    self.numHasTicked = MAX(0, self.numHasTicked - 1);
}
@end

@implementation PerfectHeal

- (void)combatUpdateForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta
{
    NSArray *excludedEffectTitles = @[@"inverted-healing",@"wracking-pain-eff",@"soul-burn"];
    
    if (self.target.health < self.target.maximumHealth) {
        BOOL skipHealing = NO;
        for (NSString *title in excludedEffectTitles) {
            if ([self.target hasEffectWithTitle:title]) {
                skipHealing = YES;
                break;
            }
        }
        
        if (!skipHealing) {            
            NSInteger healing = 0;
            NSInteger preHealth = self.target.health;
            
            self.target.health = self.target.maximumHealth;
            
            healing = self.target.health - preHealth;
            
            [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:healing] andEventType:CombatEventTypeHeal]];
        }
    }
}

- (void)willChangeHealthFrom:(NSInteger *)currentHealth toNewHealth:(NSInteger *)newHealth
{
    
}

- (void)didChangeHealthFrom:(NSInteger)currentHealth toNewHealth:(NSInteger)newHealth
{
    
}

@end

@implementation DamageOnCastEffect

- (id)copy
{
    DamageOnCastEffect *copy = [super copy];
    [copy setDamage:self.damage];
    return copy;
}

- (void)targetDidCastSpell:(Spell *)spell
{
    [self.target setHealth:self.target.health - self.damage * self.owner.damageDoneMultiplier];
    [self.owner.logger logEvent:[CombatEvent eventWithSource:self.owner target:self.target value:[NSNumber numberWithInt:self.damage * self.owner.damageDoneMultiplier] andEventType:CombatEventTypeDamage]];
}

@end

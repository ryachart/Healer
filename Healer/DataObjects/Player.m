//
//  Player.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Player.h"
#import "GameObjects.h"
#import "AudioController.h"
#import <GameKit/GameKit.h>
#import "Divinity.h"
#import "CombatEvent.h"

@interface Player ()
@property (nonatomic, readwrite) NSTimeInterval redemptionTimeApplied;
@property (nonatomic, readwrite) BOOL isRedemptionApplied;
@property (nonatomic, readwrite) BOOL isGodstouchApplied;
@property (nonatomic, readwrite) NSTimeInterval godstouchTimeApplied;
@property (nonatomic, readwrite) NSTimeInterval currentSpellCastTime;
@end

@implementation Player

@synthesize activeSpells, energy, maximumEnergy, spellTarget, additionalTargets, statusText;
@synthesize position, logger, spellsOnCooldown=_spellsOnCooldown, announcer, playerID, isLocalPlayer;
@synthesize divinityConfig;
@synthesize castTimeAdjustment;

-(void)dealloc{
    [activeSpells release]; activeSpells = nil;
    [_spellBeingCast release]; _spellBeingCast = nil;
    [statusText release]; statusText = nil;
    [playerID release]; playerID = nil;
    [_spellsOnCooldown release]; _spellsOnCooldown = nil;
    [additionalTargets release]; additionalTargets = nil;
    [divinityConfig release]; divinityConfig = nil;
    [super dealloc];
}

-(id)initWithHealth:(NSInteger)hlth energy:(NSInteger)enrgy energyRegen:(NSInteger)energyRegen
{
    if (self = [super init]){
        self.isLocalPlayer = YES;
        self.maximumHealth = hlth;
        health = hlth;
        energy = enrgy;
        energyRegenPerSecond = energyRegen;
        maximumEnergy = enrgy;
        targetIsSelf = NO;
        spellTarget = nil;
        self.spellBeingCast = nil;
        isCasting = NO;
        lastEnergyRegen = 0.0f;
        self.statusText = @"";
        position = 0;
        maxChannelTime = 5;
        castStart = 0.0f;
        self.cooldownAdjustment = 1.0;
        self.castTimeAdjustment = 1.0;
        self.spellCriticalChance = .1; //10% Base chance to crit
        self.criticalBonusMultiplier = 1.5; //50% more on a crit
        
        _spellsOnCooldown = [[NSMutableSet setWithCapacity:4] retain];
        
        for (int i = 0; i < CastingDisabledReasonTotal; i++){
            castingDisabledReasons[i] = NO;
        }
        
    }
	return self;
}

- (float)cooldownAdjustment
{
    float base = _cooldownAdjustment;
    
    for (Effect *eff in self.activeEffects) {
        base += eff.cooldownMultiplierAdjustment;
    }
    return base;
}

- (float)spellCriticalChance
{
    float base = _spellCriticalChance;
    
    for (Effect *eff in self.activeEffects) {
        base += eff.criticalChanceAdjustment;
    }
    
    return base;
}

- (void)setEnergy:(float)newEnergy
{
    energy = newEnergy;
    if (energy < 0) energy = 0;
	if (energy > maximumEnergy) energy = maximumEnergy;
}

- (BOOL)canRedemptionTrigger {
    if (!self.isLocalPlayer){
        return NO;
    }
    if ([self hasDivinityEffectWithTitle:@"redemption"]){
        if (self.redemptionTimeApplied == 0.0){
            return YES;
        }
    }
    return NO;
}

- (BOOL)isConfused {
    BOOL confusion = _isConfused;
    
    if (confusion){
        return confusion;
    }
    
    for (Effect *effect in self.activeEffects){
        if (effect.causesConfusion){
            return YES;
        }
    }
    return NO;
}

- (void)redemptionDidTriggerOnTarget:(HealableTarget *)target {
    self.redemptionTimeApplied = 0.001;
}

- (void)triggerAvatar{
    if (arc4random() % 100 <= 3){
        [self.announcer announce:@"An Avatar comes to your aid!"];
        AvatarEffect *avatar = [[[AvatarEffect alloc] initWithDuration:15 andEffectType:EffectTypePositive] autorelease];
        [avatar setOwner:self];
        [avatar setTitle:@"avatar-effect"];
        [self addEffect:avatar];
    }
    
}

- (float)castTimeAdjustmentForSpell:(Spell*)spell{
    float adjustment = [self castTimeAdjustment];
    return adjustment;
}

- (float)spellCostAdjustmentForSpell:(Spell*)spell{
    float adjustment = [self spellCostAdjustment];
    if ([self hasDivinityEffectWithTitle:@"insight"]){
        adjustment -= .075;
    }
    return adjustment;
}

- (float)healingDoneMultiplierForSpell:(Spell*)spell{
    float adjustment = [self healingDoneMultiplier];
    return adjustment;
}

- (float)spellCostAdjustment {
    float adjustment = 1.0;
    for (Effect *effect in self.activeEffects){
        adjustment -= effect.spellCostAdjustment;
    }
    return MAX(.1, adjustment);
}

- (void)initializeForCombat {
    for (Spell *spell in self.activeSpells) {
        [spell checkDivinity];
    }
}

- (void)cacheCastTimeAdjustment {
    float adjustment = 1.0;
    
    for (Effect *effect in self.activeEffects) {
        adjustment -= effect.castTimeAdjustment;
    }
    
    adjustment = MAX(adjustment, .5);
    self.castTimeAdjustment = adjustment;
}

- (void)setDivinityConfig:(NSDictionary *)divCnfg {
    [divinityConfig release];
    divinityConfig = [divCnfg retain];
    
    NSMutableArray *divinityEffectsToRemove = [NSMutableArray arrayWithCapacity:5];
    for (Effect *effect in self.activeEffects){
        if (effect.effectType == EffectTypeDivinity){
            [divinityEffectsToRemove addObject:effect];
        }
    }
    for (Effect* effect in divinityEffectsToRemove){
        [self.activeEffects removeObject:effect];
    }
    NSArray *newDivinityEffects = [Divinity effectsForConfiguration:divinityConfig];
    for (Effect *effect in newDivinityEffects){
        [self addEffect:effect];
    }
    [self cacheCastTimeAdjustment];
    
}

- (BOOL)hasDivinityEffectWithTitle:(NSString*)title {
    if (self.divinityConfig){
        for (Effect *eff in self.activeEffects){
            if (eff.effectType == EffectTypeDivinity){
                if ([[(DivinityEffect*)eff divinityKey] isEqualToString:title]){
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)addEffect:(Effect *)theEffect {
    [super addEffect:theEffect];
    [self cacheCastTimeAdjustment];
}

- (void)removeEffect:(Effect *)theEffect {
    [super removeEffect:theEffect];
    [self cacheCastTimeAdjustment];
}

- (void)setActiveSpells:(NSArray *)actSpells{
    for (Spell* spell in actSpells){
        [spell setOwner:self];
    }
    [activeSpells release];
    activeSpells = [actSpells retain];
}

- (NSString*)initialStateMessage{
    return @"ERRR:UNIMPL";
}

- (NSString*)networkID{
    return [NSString stringWithFormat:@"P-%@", self.playerID];
}

- (NSString*)spellsAsNetworkMessage {
    NSMutableString *spellsMessage = [NSMutableString stringWithCapacity:40];
    for (Spell *spell in self.activeSpells) {
        [spellsMessage appendFormat:@"|%@", spell.class];
    }
    return spellsMessage;
}

- (NSString*)asNetworkMessage{
    NSString *message = [NSString stringWithFormat:@"PLYR|%@|%i|%f|%1.3f|%i", self.playerID, self.health, self.energy, self.castTimeAdjustment, self.isConfused];
    return message;
}
- (void)updateWithNetworkMessage:(NSString*)message{
    NSArray *components = [message componentsSeparatedByString:@"|"];
    if ([self.playerID isEqualToString:[components objectAtIndex:1]]){
        self.health = [[components objectAtIndex:2] intValue];
        self.energy = [[components objectAtIndex:3] floatValue];
        self.castTimeAdjustment = [[components objectAtIndex:4] floatValue];
        self.isConfused = [[components objectAtIndex:5] boolValue];
    }else{
        NSLog(@"IM BEING UPDATED WITH A DIFFERENT PLAYER OBJECT.");
    }
}

-(void)updateEffects:(Boss*)theBoss raid:(Raid*)theRaid player:(Player*)thePlayer time:(float)timeDelta{
    NSMutableArray *effectsToRemove = [NSMutableArray arrayWithCapacity:5];
	for (int i = 0; i < self.activeEffects.count; i++){
		Effect *effect = [self.activeEffects objectAtIndex:i];
		[effect combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
		if ([effect isExpired]){
			[effect expire];
            [effectsToRemove addObject:effect];
		}
	}
    
    for (Effect *effect in effectsToRemove){
        [self.healthAdjustmentModifiers removeObject:effect];
        [self.activeEffects removeObject:effect];
    }
    [self cacheCastTimeAdjustment];
}

-(void)combatActions:(Boss*)theBoss theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    if (!self.isRedemptionApplied){
        if ([self hasDivinityEffectWithTitle:@"redemption"]){
            NSArray *raid = [theRaid livingMembers];
            for (RaidMember *member in raid){
                RedemptionEffect *redemp = [[RedemptionEffect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible];
                [redemp setRedemptionDelegate:self];
                [redemp setOwner:self];
                [redemp setTitle:@"redemption-eff"];
                [member addEffect:redemp];
                [redemp release];
            }
        }
        self.isRedemptionApplied = YES;
    }
    
    if ([self hasDivinityEffectWithTitle:@"godstouch"]) {
        if (!self.isGodstouchApplied) {
            for (RaidMember *member in theRaid.livingMembers) {
                Effect *godsTouchEffect = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
                [godsTouchEffect setOwner:self];
                [godsTouchEffect setTitle:@"godstouch-shield"];
                [godsTouchEffect setMaximumAbsorbtionAdjustment:120];
                [member addEffect:godsTouchEffect];
            }
            self.isGodstouchApplied = YES;
        }
        self.godstouchTimeApplied += timeDelta;
        if (self.godstouchTimeApplied >= 1.0) {
            self.godstouchTimeApplied = 0.0;
            for (RaidMember *member in theRaid.livingMembers) {
                [member setAbsorb:member.absorb + 5];
            }
        }
    }

    if (self.redemptionTimeApplied > 0.0){
        if (self.redemptionTimeApplied < 30.0){
            self.redemptionTimeApplied += timeDelta;
        } else {
            self.redemptionTimeApplied = 0.0;
        }
    }
    
    if (self.overhealingToDistribute > 150) {
        //For the divinity choice that distributes overhealing
        NSArray *targets = [theRaid lowestHealthTargets:5 withRequiredTarget:nil];
        NSInteger perTarget = MAX(2,self.overhealingToDistribute / 5);
        for (RaidMember *member in targets) {
            NSInteger memberCurrentHealth = member.health;
            [member setHealth:member.health + perTarget];
            NSInteger finalHealing =  member.health - memberCurrentHealth;
            self.overhealingToDistribute -= finalHealing;
            if (finalHealing > 0) {
                [self.logger logEvent:[CombatEvent eventWithSource:self target:member value:[NSNumber numberWithInt:finalHealing] andEventType:CombatEventTypeHeal]];
            }
        }
        self.overhealingToDistribute = 0;
    }
    
	if (isCasting){
        castStart+= timeDelta;
		if ([spellTarget isDead]){
            [self interrupt];
		}
		else if ([self remainingCastTime] <= 0){
			//SPELL END CAST
            if (self.isLocalPlayer){
                [self.spellBeingCast spellEndedCasting];
            }
			[self.spellBeingCast combatActions:theBoss theRaid:theRaid thePlayer:self gameTime:timeDelta];
            for (Effect *eff in self.activeEffects){
                [eff targetDidCastSpell:self.spellBeingCast];
            }
			spellTarget = nil;
			self.spellBeingCast = nil;
            self.currentSpellCastTime = 0.0;
			isCasting = NO;
			castStart = 0.0f;
			[additionalTargets release]; additionalTargets = nil;
		}
		
	}
	
    lastEnergyRegen+= timeDelta;
    float tickFactor = .1;
    if (lastEnergyRegen >= 1.0 * tickFactor)
    {
        float energyRegenAdjustment = 1.0;
        
        for (Effect *eff in self.activeEffects) {
            energyRegenAdjustment += [eff energyRegenAdjustment];
        }
        
        [self setEnergy:energy + (energyRegenPerSecond * energyRegenAdjustment * tickFactor) + [self channelingBonus]];
        lastEnergyRegen = 0.0;
    }
    
    [self updateEffects:theBoss raid:theRaid player:self time:timeDelta];
    
    NSMutableArray *spellsOffCooldown = [NSMutableArray  arrayWithCapacity:4];
    for (Spell *spell in [self spellsOnCooldown]){
        [spell updateCooldowns:timeDelta];
        if (spell.cooldownRemaining == 0){
            [spellsOffCooldown  addObject:spell];
        }
    }
    
    for (Spell *spellToRemove in spellsOffCooldown){
        [self.spellsOnCooldown removeObject:spellToRemove];
    }
	
}

- (void)interrupt{
    if (self.isLocalPlayer){
        [self.spellBeingCast spellInterrupted];
    }
    spellTarget = nil;
    self.spellBeingCast = nil;
    isCasting = NO;
    castStart = 0.0f;
    self.currentSpellCastTime = 0.0;
}

-(NSTimeInterval) remainingCastTime
{
	if (castStart != 0.0 && isCasting){
		return self.currentSpellCastTime - castStart;
	}
	else {
		return 0.0;
	}
}

-(BOOL)canCast{
	BOOL cast = NO;
	for (int i = 0; i < CastingDisabledReasonTotal; i++){
		cast = cast || castingDisabledReasons[i];
	}
	return !cast;
}

-(void)enableCastingWithReason:(CastingDisabledReason)reason{
	castingDisabledReasons[reason] = NO;
	
}
-(void)disableCastingWithReason:(CastingDisabledReason)reason{
	castingDisabledReasons[reason] = YES;
    if (self.isLocalPlayer){
        [self.spellBeingCast spellInterrupted];
    }
	spellTarget = nil;
	self.spellBeingCast = nil;
	isCasting = NO;
	castStart = 0.0;
	additionalTargets = nil;
}


-(void)beginCasting:(Spell*)theSpell withTargets:(NSArray*)targets
{
	if ([self canCast] == NO){
		return;
	}
    
    if (self.spellBeingCast) {
        return;
    }
	
	RaidMember* primaryTarget = [targets objectAtIndex:0];
	NSInteger energyDiff = [self energy] - [theSpell energyCost];
	if (energyDiff < 0) {
        if (self.isLocalPlayer){
            [self.announcer errorAnnounce:@"Not enough mana"];
            [[AudioController sharedInstance] playTitle:OUT_OF_MANA_TITLE];
        }
		return;
	}
	//SPELL BEGIN CAST
    if (self.isLocalPlayer){
        [theSpell spellBeganCasting];
    }
	self.spellBeingCast = theSpell;
    self.currentSpellCastTime = theSpell.castTime * self.castTimeAdjustment;
	spellTarget = primaryTarget;
	castStart = 0.0001;
	isCasting = YES;
	
    [additionalTargets release];
	additionalTargets = [targets retain];
	
}

-(int)channelingBonus{
	
	if ([self channelingTime] >= maxChannelTime){
		return 10;
	}
	else if ([self channelingTime] >= .5 * maxChannelTime){
		return 6;
		
	}
	else if ([self channelingTime] >= .25 * maxChannelTime){
		return 3;
	}
	
	return 0;
}

-(void)startChanneling{
	channelingStartTime = 0.0001;
	[self disableCastingWithReason:CastingDisabledReasonChanneling];
	
	[[AudioController sharedInstance] playTitle:CHANNELING_SPELL_TITLE looping:20];
	
}

-(void)stopChanneling{
	channelingStartTime = 0.0;
	[self enableCastingWithReason:CastingDisabledReasonChanneling];
	
	[[AudioController sharedInstance] stopTitle:CHANNELING_SPELL_TITLE];
}

-(NSTimeInterval)channelingTime{
	if (channelingStartTime != 0.0){
		return channelingStartTime;	
	}
	
	return 0.0;
}

-(NSString*)sourceName{
    return [NSString stringWithFormat:@"PLAYER:%@", self.playerID];
}

-(NSString*)targetName{
    return [self sourceName];
}

-(BOOL)isDead{
	return health <= 0;
}



- (void)playerDidHealFor:(NSInteger)amount onTarget:(RaidMember*)target fromSpell:(Spell*)spell withOverhealing:(NSInteger)overhealing asCritical:(BOOL)critical{
    NSInteger loggedAmount = amount;
    
    if ([self hasDivinityEffectWithTitle:@"avatar"]){
        if (amount >= MINIMUM_AVATAR_TRIGGER_AMOUNT){
            [self triggerAvatar];
        }else{
            self.avatarCounter += amount;
            if (self.avatarCounter >= MINIMUM_AVATAR_TRIGGER_AMOUNT){
                self.avatarCounter = 0;
                [self triggerAvatar];
            }
        }
    }
    
    if ([self hasDivinityEffectWithTitle:@"after-light"] && (
        spell.spellType == SpellTypeBasic ||
        [spell.title isEqualToString:@"Light Eternal"] ||
        [spell.title isEqualToString:@"Forked Heal"])) {
        ShieldEffect *shield = [[[ShieldEffect alloc] initWithDuration:15.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [shield setTitle:@"afterlight-div-eff"];
        [shield setOwner:self];
        [shield setAmountToShield:(int)round((amount + overhealing) * .10)];
        [target addEffect:shield];
    }
    
    if ([self hasDivinityEffectWithTitle:@"shining-aegis"]){
        Effect *armorEffect = [[[Effect alloc] initWithDuration:10 andEffectType:EffectTypePositiveInvisible] autorelease];
        [armorEffect setOwner:self];
        [armorEffect setTitle:@"shining-aegis-armor-eff"];
        [armorEffect setDamageTakenMultiplierAdjustment:-.075];
        [target addEffect:armorEffect];
    }
    
    if ([self hasDivinityEffectWithTitle:@"purity-of-soul"]){
        if (critical) {
            [self.announcer announce:@"The purity of your soul glows brightly"];
            ExpiresAfterSpellCastsEffect *critHaste = [[[ExpiresAfterSpellCastsEffect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
            [critHaste setCastTimeAdjustment:.5];
            [critHaste setNumCastsRemaining:3]; //Why three? This current spell is going to count, unfortunately.
            [critHaste setOwner:self];
            [critHaste setTitle:@"pos-crit-haste"];
            [critHaste setIgnoresInstantSpells:YES];
            [self addEffect:critHaste];
            
            for (Spell *spell in self.spellsOnCooldown) {
                [spell setCooldownRemaining:spell.cooldownRemaining - spell.cooldown * .1];
            }
        }
    }
    
    if ([self hasDivinityEffectWithTitle:@"ancient-knowledge"]){
        self.overhealingToDistribute += (int)round(overhealing * .5);
    }

    if ([self hasDivinityEffectWithTitle:@"searing-power"]){
        Effect *searingHealth = [[[Effect alloc] initWithDuration:60.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [searingHealth setMaximumHealthMultiplierAdjustment:.1];
        [searingHealth setOwner:self];
        [searingHealth setTitle:@"searing-health"];
        [target addEffect:searingHealth];
    }
    
    if ([self hasDivinityEffectWithTitle:@"repel-the-darkness"]){
        Effect *repelTheDarknessEffect = [[[Effect alloc] initWithDuration:10.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [repelTheDarknessEffect setDamageDoneMultiplierAdjustment:.25];
        [repelTheDarknessEffect setOwner:self];
        [repelTheDarknessEffect setTitle:@"repel-damage"];
        [target addEffect:repelTheDarknessEffect];
    }
    
    if ([self hasDivinityEffectWithTitle:@"torrent-of-faith"]){
        HealingDoneAdjustmentEffect *torrentOfFaith = [[[HealingDoneAdjustmentEffect alloc] initWithDuration:60.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [torrentOfFaith setPercentageHealingReceived:1.1];
        [torrentOfFaith setOwner:self];
        [torrentOfFaith setTitle:@"torrent-of-faith-hr"];
        [target addEffect:torrentOfFaith];
    }
    
    if ([self hasDivinityEffectWithTitle:@"sunlight"]){
        Effect *sunlight = [[[Effect alloc] initWithDuration:60.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [sunlight setDodgeChanceAdjustment:.1];
        [sunlight setOwner:self];
        [sunlight setTitle:@"sunlight-dodge"];
        [target addEffect:sunlight];
    }
    
    if (amount > 0){
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:loggedAmount] eventType:CombatEventTypeHeal critical:critical]];
    }
    
    if (overhealing > 0){
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:overhealing] andEventType:CombatEventTypeOverheal]];
    }
}

- (void)playerDidHealFor:(NSInteger)amount onTarget:(RaidMember *)target fromEffect:(Effect *)effect withOverhealing:(NSInteger)overhealing asCritical:(BOOL)critical{
    if (amount > 0){
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:amount] eventType:CombatEventTypeHeal critical:critical]];
    }
    if (overhealing > 0){
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:overhealing] andEventType:CombatEventTypeOverheal]];
    }
    
    if ([self hasDivinityEffectWithTitle:@"after-light"] && [effect.title isEqualToString:@"star-of-aravon-eff"]) {
        ShieldEffect *shield = [[[ShieldEffect alloc] initWithDuration:15.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [shield setTitle:@"afterlight-div-eff"];
        [shield setOwner:self];
        [shield setAmountToShield:(int)round((amount + overhealing) * .10)];
        [target addEffect:shield];
    }
    
    if ([self hasDivinityEffectWithTitle:@"ancient-knowledge"]){
        self.overhealingToDistribute += (int)round(overhealing * .25);
    }
    
    if ([self hasDivinityEffectWithTitle:@"avatar"]){
        if (amount >= MINIMUM_AVATAR_TRIGGER_AMOUNT){
            
        }else{
            self.avatarCounter += amount;
            if (self.avatarCounter >= MINIMUM_AVATAR_TRIGGER_AMOUNT){
                self.avatarCounter = 0;
                [self triggerAvatar];
            }
        }
    }

}
@end

//
//  Player.m
//  Healer
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

#import "Player.h"
#import "GameObjects.h"
#import <GameKit/GameKit.h>
#import "Talents.h"
#import "CombatEvent.h"
#import "EquipmentItem.h"

@interface Player ()
@property (nonatomic, readwrite) NSTimeInterval redemptionTimeApplied;
@property (nonatomic, readwrite) BOOL isRedemptionApplied;
@property (nonatomic, readwrite) BOOL isGodstouchApplied;
@property (nonatomic, readwrite) NSTimeInterval godstouchTimeApplied;
@property (nonatomic, readwrite) NSTimeInterval currentSpellCastTime;
@property (nonatomic, readwrite) float dodgeRemaining;
@property (nonatomic, readwrite) NSInteger maximumHealth;
@end

@implementation Player
@synthesize energy=_energy;

-(void)dealloc {
    [_activeSpells release]; _activeSpells = nil;
    [_spellBeingCast release]; _spellBeingCast = nil;
    [_statusText release]; _statusText = nil;
    [_playerID release]; _playerID = nil;
    [_spellsOnCooldown release]; _spellsOnCooldown = nil;
    [_additionalTargets release]; _additionalTargets = nil;
    [_talentConfig release]; _talentConfig = nil;
    [_equippedItems release]; _equippedItems = nil;
    [super dealloc];
}

-(id)initWithHealth:(NSInteger)hlth energy:(NSInteger)enrgy energyRegen:(NSInteger)energyRegen {
    if (self = [super init]){
        self.spellsFromEquipment = [NSArray array];
        self.isLocalPlayer = YES;
        self.maximumHealth = hlth;
        self.health = hlth;
        _energy = enrgy;
        _energyRegenPerSecond = energyRegen;
        _maximumEnergy = enrgy;
        self.spellTarget = nil;
        self.spellBeingCast = nil;
        self.isCasting = NO;
        self.lastEnergyRegen = 0.0f;
        self.statusText = @"";
        self.positioning = Ranged;
        self.maxChannelTime = 5;
        self.castStart = 0.0f;
        self.cooldownAdjustment = 1.0;
        self.castTimeAdjustment = 1.0;
        self.spellCriticalChance = .05; //5% Base chance to crit
        self.criticalBonusMultiplier = 1.5; //50% more on a crit
        self.damageDealt = 1000;
        self.equippedItems = [NSArray array];
        _spellsOnCooldown = [[NSMutableSet setWithCapacity:4] retain];
        
        for (int i = 0; i < CastingDisabledReasonTotal; i++){
            castingDisabledReasons[i] = NO;
        }
        
    }
	return self;
}

- (NSString *)title {
    return @"Healer";
}

- (float)cooldownAdjustment {
    float base = _cooldownAdjustment;
    
    for (Effect *eff in self.activeEffects) {
        base += eff.cooldownMultiplierAdjustment;
    }
    
    for (EquipmentItem *item in self.equippedItems) {
        base += (item.speed / 100.0);
    }
    return base;
}

- (float)energy {
    if (self.isDead) {
        return 0;
    }
    return _energy;
}

- (float)spellCriticalChance {
    float base = _spellCriticalChance;
    
    for (Effect *eff in self.activeEffects) {
        base += eff.criticalChanceAdjustment;
    }
    
    for (EquipmentItem *item in self.equippedItems) {
        base += (item.crit / 100.0);
    }
    
    return base;
}

- (NSInteger)maximumHealth {
    NSInteger base = [super maximumHealth];
    NSInteger adjustment = 0;
    float multiplier = 1;
    
    for (EquipmentItem *item in self.equippedItems) {
        adjustment += item.health;
    }
    
    for (Effect *eff in self.activeEffects) {
        multiplier += eff.maximumHealthMultiplierAdjustment;
    }
    
    return base + adjustment * multiplier;
}

- (void)setHealth:(NSInteger)newHealth {
    NSInteger prehealth = self.health;
    [super setHealth:newHealth];
    NSInteger healthDelta = prehealth - self.health;
    
    if (healthDelta > 0) {
        //Do spell pushback here?
        if ((float)healthDelta / (float)self.maximumHealth > .15) {
            [self.announcer displayCriticalPlayerDamage];
        }
    }
    
    if (self.isDead) {
        [self interrupt];
    }
}

- (void)setEnergy:(float)newEnergy {
    _energy = newEnergy;
    if (_energy < 0) _energy = 0;
	if (_energy > _maximumEnergy) _energy = _maximumEnergy;
}

- (BOOL)canRedemptionTrigger {
    if (!self.isLocalPlayer){
        return NO;
    }
    if ([self hasTalentEffectWithTitle:@"redemption"]){
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

- (BOOL)isBlinded {
    BOOL blinded = NO;
    for (Effect *effect in self.activeEffects){
        if (effect.causesBlind){
            blinded = YES;
            break;
        }
    }
    return blinded;
}

- (void)redemptionDidTriggerOnTarget:(HealableTarget *)target {
    self.redemptionTimeApplied = 0.001;
    [self.announcer announce:@"The light has redeemed a soul."];
}

- (void)triggerAvatar {
    if (arc4random() % 100 <= 3){
        [self.announcer announce:@"An Avatar comes to your aid!"];
        AvatarEffect *avatar = [[[AvatarEffect alloc] initWithDuration:15 andEffectType:EffectTypePositiveInvisible] autorelease];
        [avatar setOwner:self];
        [avatar setTitle:@"avatar-effect"];
        [self addEffect:avatar];
    }
    
}

- (float)castTimeAdjustmentForSpell:(Spell*)spell {
    float adjustment = [self castTimeAdjustment];
    return adjustment;
}

- (float)spellCostAdjustmentForSpell:(Spell*)spell {
    float adjustment = [self spellCostAdjustment];
    return adjustment;
}

- (float)healingDoneMultiplierForSpell:(Spell*)spell {
    float adjustment = [self healingDoneMultiplier];
    return adjustment;
}

-(float)healingDoneMultiplier{
    float base = 1.0;
    
    for (Effect *eff in self.activeEffects){
        base += [eff healingDoneMultiplierAdjustment];
    }
    
    for (EquipmentItem *item in self.equippedItems) {
        base += (item.healing / 100.0);
    }
    
    return MAX(0, base);
}

- (float)spellCostAdjustment {
    float adjustment = 1.0;
    for (Effect *effect in self.activeEffects){
        adjustment -= effect.spellCostAdjustment;
    }
    return MAX(0.0, adjustment);
}

- (void)initializeForCombat {
    for (Spell *spell in self.activeSpells) {
        [spell checkTalents];
    }
    for (Spell *spell in self.spellsFromEquipment) {
        [spell checkTalents];
    }
}

- (void)cacheCastTimeAdjustment {
    float adjustment = 1.0;
    
    for (Effect *effect in self.activeEffects) {
        adjustment -= effect.castTimeAdjustment;
    }
    
    for (EquipmentItem *item in self.equippedItems) {
        adjustment -= (item.speed / 100.0);
    }
    
    adjustment = MAX(adjustment, .5);
    self.castTimeAdjustment = adjustment;
}

- (void)setTalentConfig:(NSDictionary *)talentConfiguration {
    [_talentConfig release];
    _talentConfig = [talentConfiguration retain];
    
    NSMutableArray *talentEffectsToRemove = [NSMutableArray arrayWithCapacity:5];
    for (Effect *effect in self.activeEffects){
        if (effect.effectType == EffectTypeTalent){
            [talentEffectsToRemove addObject:effect];
        }
    }
    for (Effect* effect in talentEffectsToRemove){
        [self.activeEffects removeObject:effect];
    }
    NSArray *newDivinityEffects = [Talents effectsForConfiguration:_talentConfig];
    for (Effect *effect in newDivinityEffects){
        [self addEffect:effect];
    }
    [self cacheCastTimeAdjustment];
    
}

- (BOOL)hasTalentEffectWithTitle:(NSString*)title {
    if (self.talentConfig){
        for (Effect *eff in self.activeEffects){
            if (eff.effectType == EffectTypeTalent){
                if ([[(TalentEffect*)eff talentKey] isEqualToString:title]){
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
    [_activeSpells release];
    _activeSpells = [actSpells retain];
}

- (void)setSpellsFromEquipment:(NSArray *)spellsFromEquipment
{
    for (Spell* spell in spellsFromEquipment) {
        [spell setOwner:self];
    }
    [_spellsFromEquipment release];
    _spellsFromEquipment = [spellsFromEquipment retain];
}

- (void)configureForRecommendedSpells:(NSArray *)recommendSpells withLastUsedSpells:(NSArray *)lastUsedSpells {
    NSMutableArray *actSpells = [NSMutableArray arrayWithCapacity:4];
    
    if (lastUsedSpells && lastUsedSpells.count > 0){
        [actSpells addObjectsFromArray:lastUsedSpells];
    }else {
        for (Spell *spell in recommendSpells){
            if ([[PlayerDataManager localPlayer] hasSpell:spell]){
                if (actSpells.count < [[PlayerDataManager localPlayer] maximumStandardSpellSlots]) {
                    [actSpells addObject:[[spell class] defaultSpell]];
                }
            }
        }
    }
    //Add other spells the player has
    for (Spell *spell in [[PlayerDataManager localPlayer] allOwnedSpells]){
        if (actSpells.count < [[PlayerDataManager localPlayer] maximumStandardSpellSlots]){
            if (![actSpells containsObject:spell]){
                [actSpells addObject:[[spell class] defaultSpell]];
            }
        }
    }
    [self setActiveSpells:(NSArray*)actSpells];
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

- (NSString*)asNetworkMessage {
    NSString *message = [NSString stringWithFormat:@"PLYR|%@|%i|%f|%1.3f|%i", self.playerID, self.health, self.energy, self.castTimeAdjustment, self.isConfused];
    return message;
}
 
- (void)updateWithNetworkMessage:(NSString*)message {
    NSArray *components = [message componentsSeparatedByString:@"|"];
    if ([self.playerID isEqualToString:[components objectAtIndex:1]]){
        self.health = [[components objectAtIndex:2] intValue];
        self.energy = [[components objectAtIndex:3] floatValue];
        self.castTimeAdjustment = [[components objectAtIndex:4] floatValue];
        self.isConfused = [[components objectAtIndex:5] boolValue];
    }else{
        NSAssert(nil, @"PLAYER BEING UPDATED WITH A DIFFERENT PLAYER OBJECT.");
    }
}

- (void)performAttackIfAbleOnTarget:(Enemy *)target {
    if (self.shouldAttack) {
        [super performAttackIfAbleOnTarget:target];
    }
}

- (void)updateEffects:(NSArray *)enemies raid:(Raid *)theRaid players:(NSArray *)players time:(float)timeDelta {
    [super updateEffects:enemies raid:theRaid players:players time:timeDelta];
    [self cacheCastTimeAdjustment];
}

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    
    if (self.isStunned && self.isCasting) {
        [self interrupt];
    }
    
    if (!self.isRedemptionApplied){
        if ([self hasTalentEffectWithTitle:@"redemption"]){
            for (RaidMember *member in raid.livingMembers){
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
    
    if ([self hasTalentEffectWithTitle:@"godstouch"]) {
        if (!self.isGodstouchApplied) {
            for (RaidMember *member in raid.livingMembers) {
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
            for (RaidMember *member in raid.livingMembers) {
                [member setAbsorb:member.absorb + 3];
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
        //For the talent choice that distributes overhealing
        NSArray *targets = [raid lowestHealthTargets:5 withRequiredTarget:nil];
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
    
    if (self.needsArcaneBlessingShield) {
        RaidMember *target = [raid lowestHealthMember];
        ShieldEffect *shield = [[[ShieldEffect alloc] initWithDuration:10.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [shield setTitle:@"arcane-blessing-div-eff"];
        [shield setOwner:self];
        [shield setAmountToShield:400];
        [target addEffect:shield];
        self.needsArcaneBlessingShield = NO;
    }
    
    if (self.shouldAttack) {
        [self performAttackIfAbleOnTarget:[self highestPriorityEnemy:enemies]];
        self.shouldAttack = NO;
    }
    
	if (self.isCasting){
        self.castStart+= timeDelta;
		if ([self.spellTarget isDead]){
            [self interrupt];
		}
		else if ([self remainingCastTime] <= 0){
			//SPELL END CAST
            if (self.isLocalPlayer){
                [self.spellBeingCast spellEndedCasting];
            }
			[self.spellBeingCast spellFinishedCastingForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
            for (Effect *eff in self.activeEffects){
                [eff targetDidCastSpell:self.spellBeingCast onTarget:self.spellTarget];
            }
			self.spellTarget = nil;
			self.spellBeingCast = nil;
            self.currentSpellCastTime = 0.0;
			self.isCasting = NO;
			self.castStart = 0.0f;
			[_additionalTargets release]; _additionalTargets = nil;
		}
		
	}
	
    self.dodgeRemaining -= timeDelta;
    
    self.lastEnergyRegen+= timeDelta;
    float tickFactor = .1;
    if (self.lastEnergyRegen >= 1.0 * tickFactor)
    {
        float energyRegenAdjustment = 1.0;
        
        for (Effect *eff in self.activeEffects) {
            energyRegenAdjustment += [eff energyRegenAdjustment];
        }
        
        for (EquipmentItem *item in self.equippedItems) {
            energyRegenAdjustment += (item.regen / 100);
        }
        
        [self setEnergy:_energy + (_energyRegenPerSecond * energyRegenAdjustment * tickFactor) + [self channelingBonus]];
        self.lastEnergyRegen = 0.0;
    }
    
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

- (void)interrupt {
    if (self.spellBeingCast) {
        if (self.isLocalPlayer){
            [self.spellBeingCast spellInterrupted];
            [self.announcer announcePlayerInterrupted];
        }
        self.spellTarget = nil;
        self.spellBeingCast = nil;
        self.isCasting = NO;
        self.castStart = 0.0f;
        self.currentSpellCastTime = 0.0;
    }
}

- (BOOL)canDodge {
    for (Effect *eff in self.activeEffects) {
        if (eff.causesReactiveDodge)
            return YES;
    }
    return NO;
}

- (BOOL)hasDodged {
    return self.dodgeRemaining > 0;
}

- (void)dodge {
    self.dodgeRemaining = 5.0;
}

- (void)setDodgeRemaining:(float)dodgeRemaining {
    _dodgeRemaining = MAX(0, dodgeRemaining);
}

- (NSTimeInterval) remainingCastTime {
	if (self.castStart != 0.0 && self.isCasting){
		return self.currentSpellCastTime - self.castStart;
	}
	else {
		return 0.0;
	}
}

- (BOOL)canCast {
	BOOL cast = NO;
	for (int i = 0; i < CastingDisabledReasonTotal; i++){
		cast = cast || castingDisabledReasons[i];
	}
	return !cast && !self.isDead;
}

- (void)enableCastingWithReason:(CastingDisabledReason)reason {
	castingDisabledReasons[reason] = NO;
	
}

- (void)disableCastingWithReason:(CastingDisabledReason)reason {
	castingDisabledReasons[reason] = YES;
    [self interrupt];
}


- (void)beginCasting:(Spell*)theSpell withTargets:(NSArray*)targets {
	if (![self canCast]){
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
        }
		return;
	}
	//SPELL BEGIN CAST
    if (self.isLocalPlayer){
        [theSpell spellBeganCasting];
    }
	self.spellBeingCast = theSpell;
    self.currentSpellCastTime = theSpell.castTime;
	self.spellTarget = primaryTarget;
	self.castStart = 0.0001;
	self.isCasting = YES;
	
    [_additionalTargets release];
	_additionalTargets = [targets retain];
	
}

- (int)channelingBonus {
	
	if ([self channelingTime] >= self.maxChannelTime){
		return 10;
	}
	else if ([self channelingTime] >= .5 * self.maxChannelTime){
		return 6;
		
	}
	else if ([self channelingTime] >= .25 * self.maxChannelTime){
		return 3;
	}
	
	return 0;
}

- (void)startChanneling {
	self.channelingStartTime = 0.0001;
	[self disableCastingWithReason:CastingDisabledReasonChanneling];
}

- (void)stopChanneling {
	self.channelingStartTime = 0.0;
	[self enableCastingWithReason:CastingDisabledReasonChanneling];
}

- (NSTimeInterval)channelingTime {
	if (self.channelingStartTime != 0.0){
		return self.channelingStartTime;
	}
	
	return 0.0;
}

- (NSString*)sourceName {
    return [NSString stringWithFormat:@"PLAYER:%@", self.playerID];
}

- (NSString*)targetName {
    return [self sourceName];
}

- (BOOL)isDead {
	return self.health <= 0;
}

- (void)playerDidHealFor:(NSInteger)amount onTarget:(RaidMember*)target fromSpell:(Spell*)spell withOverhealing:(NSInteger)overhealing asCritical:(BOOL)critical {
    NSInteger loggedAmount = amount;
    
    if ([self hasTalentEffectWithTitle:@"avatar"]){
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
    
    if ((amount + overhealing) > 0 && [self hasTalentEffectWithTitle:@"after-light"]) {
        NSInteger sum = amount + overhealing;
        NSInteger amountToShield = (int)round(sum * .10);
        NSString *effectTitle = @"al-div-eff";
        ShieldEffect *alEffect = nil;
        for (Effect *eff in target.activeEffects) {
            if ([eff.title isEqualToString:effectTitle] && eff.owner == self) {
                alEffect = (ShieldEffect*)eff;
                break;
            }
        }
        if (alEffect) {
            alEffect.amountToShield += amountToShield;
            alEffect.timeApplied = 0;
            target.absorb += amountToShield;
        } else {
            ShieldEffect *shield = [[[ShieldEffect alloc] initWithDuration:15.0 andEffectType:EffectTypePositiveInvisible] autorelease];
            [shield setTitle:effectTitle];
            [shield setOwner:self];
            [shield setAmountToShield:amountToShield];
            [target addEffect:shield];
        }
    }
    
    if ([self hasTalentEffectWithTitle:@"shining-aegis"]){
        DecayingDamageTakenEffect *armorEffect = [[[DecayingDamageTakenEffect alloc] initWithDuration:5 andEffectType:EffectTypePositive] autorelease];
        [armorEffect setOwner:self];
        [armorEffect setVisibilityPriority:-1];
        [armorEffect setSpriteName:@"shining-aegis-effect-icon.png"];
        [armorEffect setTitle:@"shining-aegis-armor-eff"];
        [armorEffect setDamageTakenMultiplierAdjustment:-.25];
        if ([spell.title isEqualToString:@"Stars of Aravon"]) {
            DelayedHealthEffect *delayApplyAegis = [[[DelayedHealthEffect alloc] initWithDuration:1.75 andEffectType:EffectTypePositiveInvisible] autorelease];
            [delayApplyAegis setOwner:self];
            [delayApplyAegis setAppliedEffect:armorEffect];
            [delayApplyAegis setTitle:@"delay-app-aegis"];
            [target addEffect:delayApplyAegis];
        } else {
            [target addEffect:armorEffect];
        }
    }
    
    if ([self hasTalentEffectWithTitle:@"ancient-knowledge"]){
        self.overhealingToDistribute += (int)round(overhealing * .5);
    }

    if ([self hasTalentEffectWithTitle:@"searing-power"]){
        Effect *searingHealth = [[[Effect alloc] initWithDuration:60.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [searingHealth setMaximumHealthMultiplierAdjustment:.1];
        [searingHealth setDamageDoneMultiplierAdjustment:.1];
        [searingHealth setOwner:self];
        [searingHealth setTitle:@"searing-health"];
        [target addEffect:searingHealth];
    }
    
    if ([self hasTalentEffectWithTitle:@"repel-the-darkness"]){
        self.shouldAttack = YES;
    }
    
    if ([self hasTalentEffectWithTitle:@"arcane-blessing"]){
        if (arc4random() % 1000 < 100) {
            self.needsArcaneBlessingShield = YES;
        }
    }
    
    if ([self hasTalentEffectWithTitle:@"sunlight"]){
        ReactiveHealEffect *sunlight = [[[ReactiveHealEffect alloc] initWithDuration:10.0 andEffectType:EffectTypePositiveInvisible] autorelease];
        [sunlight setAmountPerReaction:50];
        [sunlight setEffectCooldown:10.0];
        [sunlight setOwner:self];
        [sunlight setTitle:@"spark-of-life"];
        [target addEffect:sunlight];
    }
    
    
    
    if (amount > 0){
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:loggedAmount] eventType:CombatEventTypeHeal critical:critical]];
        
        for (Effect *eff in target.activeEffects) {
            [eff player:self causedHealing:amount];
        }
        
    }
    
    if (overhealing > 0){
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:overhealing] andEventType:CombatEventTypeOverheal]];
    }
    

}

- (void)playerDidHealFor:(NSInteger)amount onTarget:(RaidMember *)target fromEffect:(Effect *)effect withOverhealing:(NSInteger)overhealing asCritical:(BOOL)critical{
    if (amount > 0){
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:amount] eventType:CombatEventTypeHeal critical:critical]];
        NSArray *copiedEffects = [NSArray arrayWithArray:target.activeEffects];
        for (Effect *eff in copiedEffects) {
            [eff player:self causedHealing:amount];
        }
    }
    if (overhealing > 0){
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:overhealing] andEventType:CombatEventTypeOverheal]];
    }
    
    if ((amount + overhealing) > 0 && [self hasTalentEffectWithTitle:@"after-light"]) {
        NSInteger sum = amount + overhealing;
        NSInteger amountToShield = (int)round(sum * .10);
        NSString *effectTitle = @"al-div-eff";
        ShieldEffect *alEffect = nil;
        for (Effect *eff in target.activeEffects) {
            if ([eff.title isEqualToString:effectTitle] && eff.owner == self) {
                alEffect = (ShieldEffect*)eff;
                break;
            }
        }
        if (alEffect) {
            alEffect.amountToShield += amountToShield;
            alEffect.timeApplied = 0;
            target.absorb += amountToShield;
        } else {
            ShieldEffect *shield = [[[ShieldEffect alloc] initWithDuration:15.0 andEffectType:EffectTypePositiveInvisible] autorelease];
            [shield setTitle:effectTitle];
            [shield setOwner:self];
            [shield setAmountToShield:amountToShield];
            [target addEffect:shield];
        }
    }
    
    if ([self hasTalentEffectWithTitle:@"ancient-knowledge"]){
        self.overhealingToDistribute += (int)round(overhealing * .25);
    }
    
    if ([self hasTalentEffectWithTitle:@"avatar"]){
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

//
//  Boss.m
//  Healer
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 Ryan Hart Games. All rights reserved.
//

#import "Enemy.h"
#import "GameObjects.h"
#import "RaidMember.h"
#import "ProjectileEffect.h"
#import "Ability.h"
#import "AbilityDescriptor.h"
#import "Effect.h"

@interface Enemy ()
@property (nonatomic, readwrite) float challengeDamageDoneModifier;
@property (nonatomic, readwrite) BOOL hasAppliedChallengeEffects;
@property (nonatomic, retain) NSMutableArray *queuedAbilitiesToAdd;
@property (nonatomic, retain) NSMutableArray *queuedAbilitiesToRemove;
@property (nonatomic, readwrite) BOOL shouldQueueAbilityChanges;
@end

@implementation Enemy

- (void)dealloc {
    [_abilities release];
    [_title release];
    [_queuedAbilitiesToAdd release];
    [_queuedAbilitiesToRemove release];
    [_abilityDescriptors release];
    [_namePlateTitle release];
    [super dealloc];
}

- (NSArray*)abilityDescriptors {
    NSMutableArray *activeAbilitiesDescriptors = [NSMutableArray arrayWithCapacity:4];
    
    for (Ability *ab in self.abilities) {
        if (ab.descriptor && !ab.isDisabled){
            [activeAbilitiesDescriptors addObject:ab.descriptor];
        }
    }
    
    return [_abilityDescriptors arrayByAddingObjectsFromArray:activeAbilitiesDescriptors];
}

- (NSString *)namePlateTitle
{
    if (!_namePlateTitle) {
        return self.title;
    }
    return _namePlateTitle;
}

- (NSInteger)threatPriority
{
    if (self.isDead) {
        return kThreatPriorityDead;
    }
    return _threatPriority;
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1: 
            return -.40;
        case 2:
            return -.20;
        case 4:
            return .125;
        case 5:
            return .25;
        case 3: //Normal
        default:
            return 0.0;
    }
}

- (void)stunForDuration:(NSTimeInterval)duration
{
    [self.visibleAbility interrupt];
    [self.stunnedAbility startChannel:duration];
}

- (float)damageDoneMultiplier
{
    return [super damageDoneMultiplier] + [self challengeDamageDoneModifier];
}

- (NSInteger)maximumHealth {
    float challengeMultiplier = 1.0;
    
    switch (self.difficulty) {
        case 1:
            challengeMultiplier = .6;
            break;
        case 2:
            challengeMultiplier = .8;
            break;
        case 4:
            challengeMultiplier = 1.15;
            break;
        case 5:
            challengeMultiplier = 1.4;
            break;
    }
    
    return [super maximumHealth] * challengeMultiplier;
    
}

- (RaidMember*)target
{
    if (self.isDead) {
        return nil;
    }
    RaidMember *tar = nil;
    for (Ability *abil in self.abilities) {
        if ([abil isKindOfClass:[FocusedAttack class]]){
            FocusedAttack *attack = (FocusedAttack*)abil;
            tar = attack.focusTarget;
        }
        if ([abil isKindOfClass:[SustainedAttack class]]) {
            SustainedAttack *attack = (SustainedAttack *)abil;
            tar = attack.focusTarget  ;
        }
    }
    return tar;
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    self.difficulty = difficulty;
    
    for (Ability *ab in self.abilities) {
        [ab setDifficulty:self.difficulty];
    }

    self.health = self.maximumHealth;
}

- (void)addAbilityDescriptor:(AbilityDescriptor*)descriptor {
    [(NSMutableArray*)_abilityDescriptors addObject:descriptor];
}

- (void)clearExtraDescriptors {
    [_abilityDescriptors release];
    _abilityDescriptors = [[NSMutableArray arrayWithCapacity:5] retain];
}

- (void)ownerDidExecuteAbility:(Ability*)ability
{
    
}

- (void)ownerDidBeginAbility:(Ability*)ability
{
    
}

- (void)ownerWillExecuteAbility:(Ability *)ability
{
    
}

- (void)ownerDidChannelTickForAbility:(Ability *)ability
{
    
}

- (void)ownerDidDamageTarget:(RaidMember*)target withAbility:(Ability*)ability forDamage:(NSInteger)damage
{
    
}

- (void)ownerDidDamageTarget:(RaidMember*)target withEffect:(Effect*)effect forDamage:(NSInteger)damage
{
    
}

- (void)dequeueAbilityAdds {
    if (self.queuedAbilitiesToAdd.count > 0){
        for (Ability *ability in self.queuedAbilitiesToAdd){
            [self addAbility:ability];
        }
        [self.queuedAbilitiesToAdd removeAllObjects];
    }
}

- (void)dequeueAbilityRemoves {
    if (self.queuedAbilitiesToRemove.count > 0){
        for (Ability *ability in self.queuedAbilitiesToRemove){
            [self removeAbility:ability];
        }
        [self.queuedAbilitiesToRemove removeAllObjects];
    }
}

- (void)addAbility:(Ability*)ab{
    if (self.shouldQueueAbilityChanges){
        [self.queuedAbilitiesToAdd addObject:ab];
        return;
    }
    ab.owner = self;
    ab.difficulty = self.difficulty;
    [self.abilities addObject:ab];
}

- (void)removeAbility:(Ability*)ab{
    if (self.shouldQueueAbilityChanges) {
        [self.queuedAbilitiesToRemove addObject:ab];
        return;
    }
    [self.abilities removeObject:ab];
}

- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses {
    if (self = [super init]) {
        self.maximumHealth = hlth;
        self.health = hlth;
        self.title = @"";
        self.criticalChance = 0.0;
        self.abilities = [NSMutableArray arrayWithCapacity:5];
        self.abilityDescriptors = [NSMutableArray arrayWithCapacity:5];
        
        self.stunnedAbility = [[[Ability alloc] init] autorelease];
        [self.stunnedAbility setTitle:@"Stunned!"];
        [self.stunnedAbility setIconName:@"confusion.png"];
        [self.stunnedAbility setCooldown:kAbilityRequiresTrigger];
        [self addAbility:self.stunnedAbility];
        
        for (int i = 0; i < 101; i++){
            healthThresholdCrossed[i] = NO;
        }
        self.isMultiplayer = NO;
        
        for (int i = 0; i < trgets; i++){
            if (chooses && i == 0){
                FocusedAttack *focusedAttack = [[[FocusedAttack alloc] initWithDamage:dmg/trgets andCooldown:freq] autorelease];
                [focusedAttack setDamageAudioName:@"thud.mp3"];
                [self addAbility:focusedAttack];
                self.autoAttack = focusedAttack;
            }else{
                Attack *attack = [[Attack alloc] initWithDamage:dmg/trgets andCooldown:freq];
                [attack setDamageAudioName:@"thud.mp3"];
                [self addAbility:attack];
                if (i == 0){
                    self.autoAttack = attack;
                }
                [attack release];
            }
        }
        self.queuedAbilitiesToAdd = [NSMutableArray arrayWithCapacity:1];
        self.queuedAbilitiesToRemove = [NSMutableArray arrayWithCapacity:1];
    }
	return self;
}

- (Ability*)abilityWithKey:(NSString*)abilityTitle
{
    for (Ability*ab in self.abilities) {
        if ([ab.key isEqualToString:abilityTitle]) {
            return ab;
        }
    }
    return nil;
}

-(NSString*)networkID{
    return [NSString stringWithFormat:@"B-%@", self.title];
}


-(float)healthPercentage{
    return (float)self.health / (float)self.maximumHealth * 100;
}


- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    //The main entry point for health based triggers
}

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    for (int i = 100; i >= (int)self.healthPercentage; i--){
        if (!healthThresholdCrossed[i] && self.healthPercentage <= (float)i){
            [self healthPercentageReached:i forPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
            healthThresholdCrossed[i] = YES;
        }
    }
    
    if (!self.inactive) {
        self.shouldQueueAbilityChanges = YES;
        for (Ability *ability in self.abilities){
            [ability combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
        }
        self.shouldQueueAbilityChanges = NO;
        [self dequeueAbilityAdds];
        [self dequeueAbilityRemoves];
    }
    
    [self updateEffects:enemies raid:raid players:players time:timeDelta];
}

+ (id)defaultBoss
{
	return nil;
}

- (NSString*)sourceName{
    return self.title;
}
- (NSString*)targetName{
    return self.title;
}

- (BOOL)isBusy
{
    return self.visibleAbility != nil;
}

- (Ability*)visibleAbility
{
    Ability *visibleAbility = nil;
    for (Ability *ab in self.abilities) {
        if (ab.isChanneling && !ab.ignoresBusy && !ab.isDisabled) {
            visibleAbility = ab;
            break;
        }
    }
    if (!visibleAbility) {
        for (Ability *ab in self.abilities) {
            if (ab.isActivating && !ab.ignoresBusy && !ab.isDisabled) {
                visibleAbility = ab;
                break;
            }
        }
    }
    return visibleAbility;
}
@end

#pragma mark - Shipping Bosses

@implementation Ghoul
+(id)defaultBoss{
    Ghoul *ghoul = [[Ghoul alloc] initWithHealth:110000
                                          damage:300 targets:1 frequency:2.0 choosesMT:NO ];
    [ghoul setTitle:@"Ghoul"];
    [ghoul setSpriteName:@"ghoul_battle_portrait.png"];
    
    ghoul.autoAttack.dodgeChanceAdjustment = -100.0;
    ghoul.autoAttack.failureChance = 0.0;
    
    RepeatedHealthEffect *plagueDot = [[[RepeatedHealthEffect alloc] initWithDuration:12 andEffectType:EffectTypeNegative] autorelease];
    [plagueDot setTitle:@"plague-dot"];
    [plagueDot setValuePerTick:-100];
    [plagueDot setNumOfTicks:4];
    
    Attack *plagueStrike = [[[Attack alloc] initWithDamage:100 andCooldown:30.0] autorelease];
    plagueStrike.failureChance = 0;
    [plagueStrike setExecutionSound:@"slimeimpact.mp3"];
    [plagueStrike setActivationTime:2.5];
    [plagueStrike setKey:@"plague-strike"];
    [plagueStrike setTitle:@"Plague Strike"];
    [plagueStrike setIconName:@"plague.png"];
    [plagueStrike setAppliedEffect:plagueDot];
    [plagueStrike setInfo:@"The Ghoul strikes a random enemy with a sickening attack causing them to be diseased for 12 seconds."];
    [ghoul addAbility:plagueStrike];
    
    return [ghoul autorelease];
}

- (void)ownerDidBeginAbility:(Ability *)ability
{
    if ([ability.key isEqualToString:@"plague-strike"]) {
        [self.announcer announceFtuePlagueStrike];
    }
}

- (void)ownerDidExecuteAbility:(Ability *)ability
{
    if (ability == self.autoAttack) {
        [self.announcer announceFtueAttack];
        self.autoAttack.failureChance = 0.3;
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (percentage == 75.0){
        self.autoAttack.abilityValue *= .9;
    }
    
    if (percentage == 50.0){
        self.autoAttack.abilityValue *= .9;
    }
    
    if (percentage == 25.0){
        self.autoAttack.abilityValue *= .8;
    }
}
@end

@implementation CorruptedTroll

+(id)defaultBoss{
    NSInteger health = 185000;
    NSInteger damage = 350;
    NSTimeInterval freq = 2.25;
    
    CorruptedTroll *corTroll = [[CorruptedTroll alloc] initWithHealth:health damage:damage targets:1 frequency:freq choosesMT:YES];
    corTroll.autoAttack.failureChance = .1;
    [corTroll setSpriteName:@"troll_battle_portrait.png"];
    
    [corTroll setTitle:@"Corrupted Troll"];
    
    Cleave *cleve = [Cleave normalCleave];
    [cleve setInfo:@"Attacks with a chance to deal high damage to all melee range enemies."];
    [corTroll addAbility:cleve];
    
    GroundSmash *groundSmash = [[[GroundSmash alloc] init] autorelease];
    [groundSmash setIconName:@"ground_smash.png"];
    [groundSmash setAbilityValue:54];
    [groundSmash setKey:@"troll-ground-smash"];
    [groundSmash setCooldown:30.0];
    [groundSmash setActivationTime:1.0];
    [groundSmash setTimeApplied:20.0];
    [groundSmash setTitle:@"Ground Smash"];
    [groundSmash setInfo:@"The Corrupted Troll will smash the ground repeatedly causing damage to all enemies."];
    corTroll.smash = groundSmash;
    [corTroll addAbility:corTroll.smash];
    
    ChannelledEnemyAttackAdjustment *frenzy = [[[ChannelledEnemyAttackAdjustment alloc] init] autorelease];
    [frenzy setCooldown:kAbilityRequiresTrigger];
    [frenzy setIconName:@"temper.png"];
    [frenzy setKey:@"frenzy"];
    [frenzy setTitle:@"Frenzy"];
    [frenzy setInfo:@"Occasionally, the Corrupted Troll will attack its Focused target furiously dealing high damage."];
    [frenzy setAttackSpeedMultiplier:.25];
    [frenzy setDamageMultiplier:.5];
    [frenzy setDuration:9.0];
    [corTroll addAbility:frenzy];
    
    return  [corTroll autorelease];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty {
    [super configureBossForDifficultyLevel:difficulty];
    
    if (difficulty <= 2) {
        ChannelledEnemyAttackAdjustment *frenzy = (ChannelledEnemyAttackAdjustment*)[self abilityWithKey:@"frenzy"];
        [frenzy setDamageMultiplier:.35];
        [frenzy setAttackSpeedMultiplier:.25];
        [frenzy setDuration:6.5];
    }
        
    if (difficulty >= 4) {
        self.autoAttack.abilityValue = 500;
        self.autoAttack.failureChance = .25;
    }

    if (difficulty == 5) {
        [self addAbility:[[DisorientingBoulder new] autorelease]];
    }
}

- (void)ownerDidBeginAbility:(Ability *)ability {
    if ([ability.key isEqualToString:@"frenzy"]) {
        [self.announcer announce:@"The Troll swings his club furiously at his focused target!"];
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (percentage == 75.0 || percentage == 50.0 || percentage == 25.0 || percentage == 10.0){
        [[self abilityWithKey:@"frenzy"] activateAbility];
    }
}
@end

@implementation Drake 
+(id)defaultBoss {
    Drake *drake = [[Drake alloc] initWithHealth:185000 damage:0 targets:0 frequency:0 choosesMT:NO ];
    [drake setTitle:@"Tainted Drake"];
    [drake setSpriteName:@"drake_battle_portrait.png"];
    
    NSInteger fireballDamage = 400;
    float fireballFailureChance = .05;
    float fireballCooldown = 1.0;
    
    drake.fireballAbility = [[[ProjectileAttack alloc] init] autorelease];
    drake.fireballAbility.title = @"Spit Fireball";
    drake.fireballAbility.executionSound = @"fireball.mp3";
    [(ProjectileAttack*)drake.fireballAbility setExplosionSoundName:@"explosion2.wav"];
    drake.fireballAbility.activationTime = 1.5;
    [drake.fireballAbility setIconName:@"fireball.png"];
    [drake.fireballAbility setKey:@"fireball-ab"];
    [(ProjectileAttack*)drake.fireballAbility setSpriteName:@"fireball.png"];
    [drake.fireballAbility setAbilityValue:fireballDamage];
    [drake.fireballAbility setFailureChance:fireballFailureChance];
    [drake.fireballAbility setCooldown:fireballCooldown];
    [drake addAbility:drake.fireballAbility];
    
    Breath *fb = [[[Breath alloc] init] autorelease];
    [fb setTitle:@"Flame Breath"];
    [fb setActivationSound:@"dragonroar1.mp3"];
    [fb setKey:@"flame-breath"];
    [fb setIconName:@"burning.png"];
    [fb setAbilityValue:100];
    [fb setActivationTime:2.5];
    [fb setCooldown:kAbilityRequiresTrigger];
    [drake addAbility:fb];
    
    return [drake autorelease];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    
    if (difficulty == 5) {
        RepeatedHealthEffect *clawRakeEffect = [[[RepeatedHealthEffect alloc] initWithDuration:8 andEffectType:EffectTypeNegative] autorelease];
        [clawRakeEffect setHealingReceivedMultiplierAdjustment:-.5];
        [clawRakeEffect setNumOfTicks:8];
        [clawRakeEffect setValuePerTick:-10];
        [clawRakeEffect setTitle:@"claw-rake-eff"];
        
        Attack *clawRake = [[[Attack alloc] initWithDamage:350 andCooldown:22.0] autorelease];
        [clawRake setExecutionSound:@"sharpimpactbleeding.mp3"];
        [clawRake setKey:@"claw-rake"];
        [clawRake setTitle:@"Claw Rake"];
        [clawRake setIconName:@"gushing_wound.png"];
        [clawRake setInfo:@"Strikes a random ally causing them to receive 50% less healing for 8 seconds."];
        [clawRake setActivationTime:1.0];
        [clawRake setCooldownVariance:.2];
        [clawRake setAppliedEffect:clawRakeEffect];
        [self addAbility:clawRake];
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta  {
    
    if (percentage == 50.0 || percentage == 75.0 || percentage == 25.0){
        //Trigger Flame Breath
        [self.announcer announce:@"The Drake takes a deep breath..."];
        [[self abilityWithKey:@"flame-breath"] activateAbility];
    }
}
@end

@implementation MischievousImps
+(id)defaultBoss {
    MischievousImps *boss = [[MischievousImps alloc] initWithHealth:112500 damage:0 targets:0 frequency:2.25 choosesMT:NO];
    [boss setSpriteName:@"imps_battle_portrait.png"];
    
    RandomPotionToss *rpt = [[[RandomPotionToss alloc] init] autorelease];
    [rpt setKey:@"potions"];
    [rpt setTitle:@"Throw Vial"];
    [rpt setIconName:@"vial_throw.png"];
    [rpt setExecutionSound:@"whiff.mp3"];
    [rpt setCooldown:11.0];
    [rpt setActivationTime:1.5];
    [boss addAbility:rpt];
    
    [boss setTitle:@"Mischievious Imps"];
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (percentage == 100.0) {
        [self.announcer playAudioForTitle:@"imp_cackle.mp3"];
    }
    
    if (percentage == 99.0){
        RandomPotionToss *potionAbility = (RandomPotionToss*)[self abilityWithKey:@"potions"];
        [potionAbility triggerAbilityAtRaid:raid];
        [self.announcer announce:@"An imp angrily hurls the entire case of flasks at you!"];
        
        [potionAbility setActivationTime:potionAbility.activationTime / 2];
        [potionAbility setCooldown:potionAbility.cooldown / 2];
        [self.announcer playAudioForTitle:@"imp_cackle.mp3"];
    }
    
    if (self.difficulty == 5) {
        if (percentage == 75.0 || percentage == 50.0 || percentage == 25.0) {
            RandomPotionToss *potionAbility = (RandomPotionToss*)[self abilityWithKey:@"potions"];
            [potionAbility triggerAbilityAtRaid:raid];
            [self.announcer announce:@"An imp angrily hurls the entire case of flasks at you!"];
        }
    }
    
    if (percentage == 25.0){
        [[self abilityWithKey:@"potions"] setIsDisabled:YES];
        [self.announcer announce:@"The imp begins attacking angrily!"];
        self.autoAttack.isDisabled = YES;
        
        Ability *attackAngrily = [[[Ability alloc] init] autorelease];
        [attackAngrily setTitle:@"Frenzied Attacking"];
        [attackAngrily setIconName:@"roar.png"];
        [attackAngrily setCooldown:kAbilityRequiresTrigger];
        [self addAbility:attackAngrily];
        [attackAngrily startChannel:9999];
        
        SustainedAttack *attack = [[[SustainedAttack alloc] initWithDamage:250 andCooldown:.85] autorelease];
        attack.ignoresBusy = YES;
        [attack setFailureChance:.15];
        [self addAbility:attack];
    }
}
@end

@implementation BefouledTreant

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty {
    [super configureBossForDifficultyLevel:difficulty];
    
    if (difficulty > 4) {
        ConstrictingVines *vines = [[[ConstrictingVines alloc] init] autorelease];
        [vines setExecutionSound:@"vinestightening.mp3"];
        [vines setIconName:@"constrict.png"];
        [vines setAbilityValue:80];
        [vines setStunDuration:4.0];
        [vines setKey:@"vines"];
        [vines setTimeApplied:40];
        [vines setCooldown:55.0];
        [vines setCooldownVariance:.2];
        [self addAbility:vines];
    }
}

+(id)defaultBoss {
    NSInteger bossDamage = 390;
    
    BefouledTreant *boss = [[BefouledTreant alloc] initWithHealth:560000 damage:bossDamage targets:1 frequency:3.0 choosesMT:YES ];
    boss.autoAttack.failureChance = .25;
    [boss setTitle:@"Befouled Akarus"];
    [boss setSpriteName:@"treant_battle_portrait.png"];
    
    Cleave *cleave = [Cleave normalCleave];
    [boss addAbility:cleave];
    
    Earthquake *eq = [[[Earthquake alloc] init] autorelease];
    [eq setTitle:@"Earthquake"];
    [eq setKey:@"root-quake"];
    [eq setIconName:@"quake.png"];
    [eq setExecutionSound:@"earthquake.mp3"];
    [eq setCooldown:28.0];
    [eq setActivationTime:2.0];
    [eq setAbilityValue:35];
    [boss addAbility:eq];
    
    RepeatedHealthEffect *lashDoT = [[[RepeatedHealthEffect alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative] autorelease];
    [lashDoT setTitle:@"lash"];
    [lashDoT setAilmentType:AilmentTrauma];
    [lashDoT setValuePerTick:-36];
    [lashDoT setNumOfTicks:5];
    [lashDoT setSpriteName:@"bleeding.png"];
    
    RaidDamage *branchAttack = [[[RaidDamage alloc] init] autorelease];
    [branchAttack setActivationSound:@"treebranchdrawback.mp3"];
    [branchAttack setExecutionSound:@"treebranchwhipforward.mp3"];
    [branchAttack setTitle:@"Viscious Branches"];
    [branchAttack setKey:@"branch-attack"];
    [branchAttack setIconName:@"branch_thrash.png"];
    [branchAttack setCooldown:kAbilityRequiresTrigger];
    [branchAttack setActivationTime:2.0];
    [branchAttack setAbilityValue:208];
    [branchAttack setAppliedEffect:lashDoT];
    [boss addAbility:branchAttack];
    return [boss autorelease];
}

- (void)ownerDidBeginAbility:(Ability *)ability
{
    if ([ability.key isEqualToString:@"root-quake"]) {
        [self.announcer announce:@"The Akarus' roots move the earth."];
    }
    
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (percentage == 96.0 || percentage == 74.0 || percentage == 50.0 || percentage == 29.0){
        [self.announcer announce:@"The Akarus pulls its enormous branches back to lash out at your allies."];
        [[self abilityWithKey:@"branch-attack"] activateAbility];
    }
}
@end

@implementation FinalRavager
+(id)defaultBoss {
    FinalRavager *boss = [[FinalRavager alloc] initWithHealth:187000 damage:141 targets:1 frequency:2.0 choosesMT:YES ];
    boss.autoAttack.failureChance = .25;
    [boss setTitle:@"Fungal Ravagers"];
    [boss setCriticalChance:.5];
    
    [boss setSpriteName:@"fungalravagers_battle_portrait.png"];
    
    AbilityDescriptor *vileExploDesc = [[AbilityDescriptor alloc] init];
    [vileExploDesc setAbilityDescription:@"The Fungal Ravager is surrounded by a toxic mist dealing constant damage to all enemies."];
    [vileExploDesc setIconName:@"poison2.png"];
    [vileExploDesc setAbilityName:@"Toxic Mist"];
    [boss addAbilityDescriptor:vileExploDesc];
    [vileExploDesc release];
    
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    
    if (percentage == 100.0){
        [self.announcer announce:@"A putrid green mist fills the area..."];
        [self.announcer playAudioForTitle:@"wolvesgrowling.mp3"];
        [self.announcer displayParticleSystemOnRaidWithName:@"green_mist.plist" forDuration:-1.0 offset:CGPointMake(0, -100)]; //Lower this because it's a 10 man...kind of awful
        for (RaidMember *member in raid.raidMembers){
            NSInteger damage = -(arc4random() % 10 + 5);
            if (self.difficulty == 5) {
                damage *= .5;
            }
            RepeatedHealthEffect *rhe = [[RepeatedHealthEffect alloc] initWithDuration:-1.0 andEffectType:EffectTypeNegativeInvisible];
            [rhe setOwner:self];
            [rhe setTitle:@"fungal-ravager-mist"];
            [rhe setValuePerTick:damage];
            [member addEffect:rhe];
            [rhe release];
        }
    }
    
    if (percentage == 99.0){
        float damageBonus = 1.25;
        [self.announcer announce:@"The final Ravager glows with rage."];
        [self.announcer playAudioForTitle:@"wolvesgrowling.mp3"];
        AbilityDescriptor *rage = [[[AbilityDescriptor alloc] init] autorelease];
        [rage setAbilityDescription:@"The Fungal Ravager is enraged."];
        [rage setIconName:@"ravager_remaining.png"];
        [rage setAbilityName:@"Rage"];
        [self addAbilityDescriptor:rage];
        Effect *enragedEffect = [[Effect alloc] initWithDuration:300 andEffectType:EffectTypePositiveInvisible];
        [enragedEffect setIsIndependent:YES];
        [enragedEffect setTarget:self];
        [enragedEffect setOwner:self];
        [enragedEffect setDamageDoneMultiplierAdjustment:damageBonus];
        [self addEffect:enragedEffect];
        [enragedEffect release];
    }
}
@end

@implementation FungalRavager

- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses
{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq choosesMT:chooses]) {
        AbilityDescriptor *vileExploDesc = [[AbilityDescriptor alloc] init];
        [vileExploDesc setAbilityDescription:@"When a Fungal Ravager dies it explodes coating random targets in burning slime."];
        [vileExploDesc setIconName:@"pus_burst.png"];
        [vileExploDesc setAbilityName:@"Vile Explosion"];
        [self addAbilityDescriptor:vileExploDesc];
        [vileExploDesc release];
    }
    return self;
}

-(void)ravagerDiedFocusing:(RaidMember*)focus andRaid:(Raid*)raid{
    [self.announcer announce:@"A Fungal Ravager falls to the ground and explodes!"];
    [self.announcer displayScreenShakeForDuration:2.5];
    [self.announcer playAudioForTitle:@"fieryexplosion.mp3"];
    [focus setIsFocused:NO];
    
    NSInteger numTargets = arc4random() % 3 + 2;
    
    NSArray *members = [raid randomTargets:numTargets withPositioning:Any];
    for (RaidMember *member in members){
        NSInteger damage = arc4random() % 300 + 450;
        RepeatedHealthEffect *damageEffect = [[[RepeatedHealthEffect alloc] initWithDuration:2.5 andEffectType:EffectTypeNegative] autorelease];
        [damageEffect setAilmentType:AilmentPoison];
        [damageEffect setSpriteName:@"pus_burst.png"];
        [damageEffect setNumOfTicks:3];
        [damageEffect setValuePerTick:-damage / 3];
        [damageEffect setOwner:self];
        [damageEffect setTitle:@"ravager-explo"];
        [member addEffect:damageEffect];
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta 
{
    if (percentage == 1.0) {
        RaidMember *target = [(FocusedAttack*)self.autoAttack focusTarget];
        [self ravagerDiedFocusing:target andRaid:raid];
        
        if (self.difficulty == 5) {
            WanderingSpiritEffect *wse = [[[WanderingSpiritEffect alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
            [wse setAilmentType:AilmentTrauma];
            [wse setTitle:@"pred-fungus-effect"];
            [wse setSpriteName:@"plague.png"];
            [wse setValuePerTick:-self.autoAttack.abilityValue * .5];
            [wse setOwner:self];
            [target addEffect:wse];
        }
    }
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    if (difficulty == 5) {
        AbilityDescriptor *fungusDesc = [[[AbilityDescriptor alloc] init] autorelease];
        [fungusDesc setIconName:@"poison.png"];
        [fungusDesc setAbilityDescription:@"When killed, the ravager becomes a living fungus that hunts for the weakest ally and devours them alive."];
        [fungusDesc setAbilityName:@"Predator Fungus"];
        [self addAbilityDescriptor:fungusDesc];
    }
}

@end

@implementation PlaguebringerColossus
+(id)defaultBoss {
    //427500
    PlaguebringerColossus *boss = [[PlaguebringerColossus alloc] initWithHealth:560000 damage:330 targets:1 frequency:2.5 choosesMT:YES];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Plaguebringer Colossus"];
    [boss setSpriteName:@"plaguebringer_battle_portrait.png"];
    
    AbilityDescriptor *pusExploDesc = [[AbilityDescriptor alloc] init];
    [pusExploDesc setAbilityDescription:@"When the Colossus suffers 20% of its health in damage a section of its body explodes dealing high damage to enemies."];
    [pusExploDesc setIconName:@"pus_burst.png"];
    [pusExploDesc setAbilityName:@"Limb Bomb"];
    [boss addAbilityDescriptor:pusExploDesc];
    [pusExploDesc release];
    
    [boss addAbility:[Cleave normalCleave]];
    
    PlaguebringerSicken *sicken = [[[PlaguebringerSicken alloc] init] autorelease];
    [sicken setExecutionSound:@"slimespraying.mp3"];
    [sicken setInfo:@"The Colossus will sicken targets causing them to take damage until they are healed to full health."];
    [sicken setKey:@"sicken"];
    [sicken setIconName:@"plague.png"];
    [sicken setTitle:@"Sicken"];
    [sicken setActivationTime:2.5];
    [sicken setAbilityValue:100];
    [sicken setCooldown:13.0];
    [boss addAbility:sicken];
    return [boss autorelease];
}

-(void)burstPussBubbleOnRaid:(Raid*)theRaid{
    [self.announcer announce:@"A putrid sac of filth bursts onto your allies"];
    [self.announcer displayScreenShakeForDuration:1.0];
    [self.announcer playAudioForTitle:@"fieryexplosion.mp3"];
    [self.announcer playAudioForTitle:@"grossbubble.mp3" afterDelay:2.0];
    self.numBubblesPopped++;
    //Boss does 10% less damage for each bubble popped
    Effect *reducedDamageEffect = [[Effect alloc] initWithDuration:300 andEffectType:EffectTypePositiveInvisible];
    [reducedDamageEffect setIsIndependent:YES];
    [reducedDamageEffect setTarget:self];
    [reducedDamageEffect setOwner:self];
    [reducedDamageEffect setDamageDoneMultiplierAdjustment:-0.1];
    [self addEffect:reducedDamageEffect];
    [reducedDamageEffect release];
    
    for (RaidMember *member in theRaid.raidMembers){
        if (!member.isDead){
            RepeatedHealthEffect *singleTickDot = [[RepeatedHealthEffect alloc] initWithDuration:3.0 andEffectType:EffectTypeNegative];
            [singleTickDot setOwner:self];
            [singleTickDot setTitle:@"pbc-pussBubble"];
            [singleTickDot setNumOfTicks:2];
            [singleTickDot setAilmentType:AilmentPoison];
            [singleTickDot setValuePerTick:-(arc4random() % 150 + 200)];
            [singleTickDot setSpriteName:@"pus_burst.png"];
            [member addEffect:singleTickDot];
            [singleTickDot release];
        }
    }
}

-(void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta{
    if (((int)percentage) % 20 == 0 && percentage != 100){
        [self burstPussBubbleOnRaid:raid];
    }
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    
    if (difficulty == 5) {
        ConsumingCorruption *corrEff = [[[ConsumingCorruption alloc] initWithDuration:12 andEffectType:EffectTypeNegative] autorelease];
        [corrEff setValuePerTick:-100];
        [corrEff setConsumptionThreshold:.5];
        [corrEff setHealPercentage:.02];
        [corrEff setNumOfTicks:5];
        [corrEff setTitle:@"consuming-corruption"];
        
        Attack *consumingCorruption = [[[Attack alloc] initWithDamage:0 andCooldown:30.0] autorelease];
        [consumingCorruption setExecutionSound:@"slimeimpact.mp3"];
        [consumingCorruption setPrefersTargetsWithoutVisibleEffects:YES];
        [consumingCorruption setIgnoresGuardians:YES];
        [consumingCorruption setRequiresDamageToApplyEffect:NO];
        [consumingCorruption setAbilityValue:100];
        [consumingCorruption setInfo:@"A plague that heals the Colossus if it damages a target below 50% health."];
        [consumingCorruption setActivationTime:1.5];
        [consumingCorruption setIconName:@"corruption.png"];
        [consumingCorruption setTitle:@"Consuming Corruption"];
        [consumingCorruption setAppliedEffect:corrEff];
        [self addAbility:consumingCorruption];
    }
}

@end

@implementation Trulzar
+(id)defaultBoss {
    Trulzar *boss = [[Trulzar alloc] initWithHealth:2600000 damage:0 targets:0 frequency:100.0 choosesMT:NO];
    [boss setTitle:@"Trulzar the Maleficar"];
    [boss setNamePlateTitle:@"Trulzar"];
    [boss setSpriteName:@"trulzar_battle_portrait.png"];
    
    boss.lastPotionTime = 6.0;
    
    TrulzarPoison *poisonEffect = [[[TrulzarPoison alloc] initWithDuration:24 andEffectType:EffectTypeNegative] autorelease];
    [poisonEffect setAilmentType:AilmentPoison];
    [poisonEffect setValuePerTick:-120];
    [poisonEffect setNumOfTicks:30];
    [poisonEffect setTitle:@"trulzar-poison1"];
    
    Attack *poisonAttack = [[[Attack alloc] initWithDamage:100 andCooldown:10] autorelease];
    [poisonAttack setExecutionSound:@"gas_impact.mp3"];
    [poisonAttack setPrefersTargetsWithoutVisibleEffects:YES];
    [poisonAttack setAttackParticleEffectName:@"poison_cloud.plist"];
    [poisonAttack setKey:@"poison-attack"];
    [poisonAttack setIconName:@"poison.png"];
    [poisonAttack setInfo:@"Trulzar fills an allies veins with poison dealing increasing damage over time.  This effect may be removed with the Purify spell."];
    [poisonAttack setTitle:@"Inject Poison"];
    [poisonAttack setCooldown:9.0];
    [poisonAttack setActivationTime:2.0];
    [poisonAttack setAppliedEffect:poisonEffect];
    [boss addAbility:poisonAttack];
    
    ProjectileAttack *potionThrow = [[[ProjectileAttack alloc] init] autorelease];
    [potionThrow setTitle:@"Toxic Vial"];
    [potionThrow setKey:@"potion-throw"];
    [potionThrow setIconName:@"vial_throw.png"];
    [potionThrow setExecutionSound:@"whiff.mp3"];
    [potionThrow setExplosionSoundName:@"glassvialthrownwliquid.mp3"];
    [potionThrow setCooldown:8.0];
    [potionThrow setSpriteName:@"potion.png"];
    [potionThrow setActivationTime:1.0];
    [potionThrow setExplosionParticleName:@"poison_cloud.plist"];
    [potionThrow setEffectType:ProjectileEffectTypeThrow];
    [potionThrow setAbilityValue:450];
    [potionThrow setProjectileColor:ccGREEN];
    [potionThrow setTimeApplied:7.0];
    [boss addAbility:potionThrow];
    
    RaidDamagePulse *pulse = [[[RaidDamagePulse alloc] init] autorelease];
    [pulse setPulseSoundTitle:@"explosion_pulse.wav"];
    [pulse setIconName:@"poison_explosion.png"];
    [pulse setActivationTime:2.0];
    [pulse setTitle:@"Poison Nova"];
    [pulse setKey:@"poison-nova"];
    [pulse setAbilityValue:550];
    [pulse setNumTicks:4];
    [pulse setDuration:12.0];
    [pulse setCooldown:60.0];
    [pulse setTimeApplied:40.0];
    [boss addAbility:pulse];
    boss.poisonNova = pulse;

    return [boss autorelease];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    if (difficulty == 5) {
        
        [[self abilityWithKey:@"poison-attack"] setCooldown:16.0];
        
        UnstableToxin *unstable = [[[UnstableToxin alloc] initWithDuration:20.0 andEffectType:EffectTypeNegative] autorelease];
        [unstable setTitle:@"unstable-tox"];
        [unstable setValuePerTick:-100];
        [unstable setNumOfTicks:20];
        [unstable setAilmentType:AilmentPoison];
        
        self.poisonNova.cooldown = 75;
        
        Attack *unstableToxin = [[[Attack alloc] initWithDamage:0 andCooldown:18.0] autorelease];
        [unstableToxin setPrefersTargetsWithoutVisibleEffects:YES];
        [unstableToxin setKey:@"unstable"];
        [unstableToxin setTimeApplied:10.0];
        unstableToxin.failureChance = 0.0;
        unstable.dodgeChanceAdjustment = -100.0f;
        [unstableToxin setActivationTime:1.5];
        [unstableToxin setRequiresDamageToApplyEffect:NO];
        [unstableToxin setTitle:@"Unstable Toxin"];
        [unstableToxin setInfo:@"A strange poison that will explode and stun Trulzar for a brief time when removed with Purify."];
        [unstableToxin setIconName:@"curse.png"];
        [unstableToxin setAppliedEffect:unstable];
        [self addAbility:unstableToxin];
        
        RaidDamagePulse *pulse = [[[RaidDamagePulse alloc] init] autorelease];
        [pulse setPulseSoundTitle:@"explosion_pulse.wav"];
        [pulse setIconName:@"poison_explosion.png"];
        [pulse setActivationTime:1.0];
        [pulse setTitle:@"Empowered Nova"];
        [pulse setKey:@"emp-poison-nova"];
        [pulse setAbilityValue:1950];
        [pulse setNumTicks:4];
        [pulse setDuration:12.0];
        [pulse setCooldown:61.0];
        [pulse setTimeApplied:40.0];
        [self addAbility:pulse];
    }
}

-(void)applyWeakPoisonToTarget:(RaidMember*)target{
    TrulzarPoison *poisonEffect = [[TrulzarPoison alloc] initWithDuration:24 andEffectType:EffectTypeNegative];
    [self.announcer displayParticleSystemWithName:@"poison_cloud.plist" onTarget:target];
    [poisonEffect setOwner:self];
    [poisonEffect setSpriteName:@"poison.png"];
    [poisonEffect setAilmentType:AilmentPoison];
    [poisonEffect setValuePerTick:-40];
    [poisonEffect setNumOfTicks:24];
    [poisonEffect setTitle:@"trulzar-poison2"];
    [target addEffect:poisonEffect];
    [poisonEffect release];
}

-(void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta{
    
    if (percentage == 99.0) {
        [self.announcer announce:@"\"You've arrived just in time.  Your shallow graves were getting cold.\""];
    }
    
    if (percentage == 50.0) {
        [self.announcer announce:@"\"Even if you defeat me, you will not best my masters.\""];
    }
    
    if (percentage == 10.0) {
        [self.announcer announce:@"\"You think you have won? Oh, but the best is yet to come.\""];
    }
    
    if (percentage == 7.0){
        [self.announcer announce:@"Trulzar cackles as the room fills with noxious poison."];
        [self.announcer displayParticleSystemOnRaidWithName:@"poison_raid_burst.plist" delay:0.0];
        [self.poisonNova setIsDisabled:YES];
        [self.announcer playAudioForTitle:@"gas_impact.wav"];
        
        if (self.difficulty == 5) {
            [[self abilityWithKey:@"unstable"] setIsDisabled:YES];
            [[self abilityWithKey:@"emp-poison-nova"] setIsDisabled:YES];
        }
        [[self abilityWithKey:@"poison-attack"] setIsDisabled:YES];
        for (RaidMember *member in raid.livingMembers){
            [self applyWeakPoisonToTarget:member];
        }
    }
}

- (void)ownerDidChannelTickForAbility:(Ability *)ability
{
    if (ability == self.poisonNova || [ability.key isEqualToString:@"emp-poison-nova"]) {
        [self.announcer displayParticleSystemOnRaidWithName:@"poison_raid_burst.plist" delay:0.0];
    }
}

@end

@implementation Galcyon

- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses
{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq choosesMT:chooses]) {
        RaidDamageOnDispelStackingRHE *poison = [[[RaidDamageOnDispelStackingRHE alloc] initWithDuration:-1.0 andEffectType:EffectTypeNegative] autorelease];
        [poison setTitle:@"roth_poison"];
        [poison setAilmentType:AilmentPoison];
        [poison setNumOfTicks:20];
        [poison setMaxStacks:50];
        [poison setValuePerTick:-35];
        [poison setDispelDamageValue:-200];
        
        EnsureEffectActiveAbility *eeaa = [[[EnsureEffectActiveAbility alloc] init] autorelease];
        [eeaa setIsChanneled:YES];
        [eeaa setKey:@"explosive-toxin"];
        [eeaa setTitle:@"Explosive Toxin"];
        [eeaa setIconName:@"poison.png"];
        [eeaa setInfo:@"Galcyon fills an ally with an unstable toxin that deals increasing damage to a single target and explodes when the toxin is removed with Purify."];
        [eeaa setEnsuredEffect:poison];
        [self addAbility:eeaa];
        
        self.spriteName = @"council_battle_portrait.png";
    }
    return self;
}

- (NSInteger)maximumHealth {
    float challengeMultiplier = 1.0;
    
    switch (self.difficulty) {
        case 1:
            challengeMultiplier = .6;
            break;
        case 2:
            challengeMultiplier = .8;
            break;
        case 4:
        case 5:
            challengeMultiplier = 1.15;
            break;
    }
    
    return [super maximumHealth] * challengeMultiplier;
    
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    if (percentage == 99.0) {
        [self.announcer playAudioForTitle:@"galcyon_laugh.mp3"];
        [self.announcer announce:@"\"So you defeated Trulzar? His Magics are so weak.\""];
    }
    
    if (self.difficulty == 5) {
        if (percentage == 20.0) {
            [self.announcer announce:@"Grimgon shouts, \"You worthless fool.  These mortals are going to destroy you.\""];
            
            for (Enemy *enemy in enemies) {
                if ([enemy isKindOfClass:[Grimgon class]]) {
                    [enemy setInactive:NO];
                }
            }
        }
    }
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    
    if (difficulty == 5) {
        EnsureEffectActiveAbility *eea = (EnsureEffectActiveAbility*)[self abilityWithKey:@"explosive-toxin"];
        
        RaidDamageOnDispelStackingRHE *eff =  (RaidDamageOnDispelStackingRHE*)[eea ensuredEffect];
        
        eff.valuePerTick = -12;
        eff.dispelDamageValue = -90;
        
        RaidDamageOnDispelStackingRHE *poison = [[[RaidDamageOnDispelStackingRHE alloc] initWithDuration:-1.0 andEffectType:EffectTypeNegative] autorelease];
        [poison setTitle:@"roth_poison2"];
        [poison setAilmentType:AilmentPoison];
        [poison setNumOfTicks:20];
        [poison setMaxStacks:50];
        [poison setValuePerTick:-12];
        [poison setDispelDamageValue:-90];
        
        EnsureEffectActiveAbility *eeaa = [[[EnsureEffectActiveAbility alloc] init] autorelease];
        [eeaa setKey:@"explosive-toxin2"];
        [eeaa setTitle:@"Explosive Toxin"];
        [eeaa setIconName:@"poison.png"];
        [eeaa setEnsuredEffect:poison];
        [self addAbility:eeaa];
    }
}

@end

@implementation Grimgon

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (percentage == 99.0) {
        if (self.difficulty < 5) {
            self.inactive = NO;
            [self.announcer announce:@"Grimgon chuckles at Galcyon's failure and steps forward."];
        } 
    }
    
    if (self.difficulty == 5) {
        if (percentage == 20.0) {
            [self.announcer announce:@"Grimgon shouts, \"Teritha, together we can destroy these insects!."];
            
            for (Enemy *enemy in enemies) {
                if ([enemy isKindOfClass:[Teritha class]]) {
                    [enemy setInactive:NO];
                }
            }
        }
        
        if (percentage == 18.0) {
            [self.announcer announce:@"Teritha shouts, \"Grimgon, you fool.  Must I do everything myself?"];
        }
    }
}

- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses
{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq choosesMT:chooses]) {
        CouncilPoison *poisonDoT = [[[CouncilPoison alloc] initWithDuration:6 andEffectType:EffectTypeNegative] autorelease];
        [poisonDoT setTitle:@"council-ball-dot"];
        [poisonDoT setSpriteName:@"poison.png"];
        [poisonDoT setValuePerTick:-40];
        [poisonDoT setNumOfTicks:3];
        [poisonDoT setAilmentType:AilmentPoison];
        
        ProjectileAttack *grimgonBolts = [[[ProjectileAttack alloc] init] autorelease];
        [grimgonBolts setKey:@"grimgon-bolts"];
        [grimgonBolts setExecutionSound:@"fireball.mp3"];
        [grimgonBolts setExplosionSoundName:@"liquid_impact.mp3"];
        [grimgonBolts setCooldown:7.5];
        [grimgonBolts setIconName:@"poison2.png"];
        [grimgonBolts setTimeApplied:5.0];
        [grimgonBolts setAttacksPerTrigger:3];
        [grimgonBolts setActivationTime:1.5];
        [grimgonBolts setExplosionParticleName:@"poison_cloud.plist"];
        [grimgonBolts setSpriteName:@"poisonbolt.png"];
        [grimgonBolts setAbilityValue:325];
        [grimgonBolts setAppliedEffect:poisonDoT];
        [grimgonBolts setInfo:@"Vile poison bolts that cause the targets to have healing done to them reduced by 50%."];
        [grimgonBolts setTitle:@"Bolts of Malediction"];
        [self addAbility:grimgonBolts];
        
        DarkCloud *dc = [[[DarkCloud alloc] init] autorelease];
        [dc setKey:@"dark-cloud"];
        [dc setExecutionSound:@"gas_impact.mp3"];
        [dc setIconName:@"choking_cloud.png"];
        [dc setCooldown:18.0];
        [dc setActivationTime:1.5];
        [dc setTitle:@"Choking Cloud"];
        [dc setInfo:@"Grimgon summons a dark cloud over all of your allies that deals more damage to lower health allies and weakens healing magic."];
        [self addAbility:dc];
        
        self.spriteName = @"council2_battle_portrait.png";
    }
    return self;
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    
    if (difficulty == 5) {
        Effect *healingBuff = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositive] autorelease];
        [healingBuff setTitle:@"insight-eff"];
        [healingBuff setSpriteName:@"insight.png"];
        [healingBuff setOwner:self];
        [healingBuff setHealingDoneMultiplierAdjustment:.04];
        [healingBuff setEnergyRegenAdjustment:.04];
        [healingBuff setMaxStacks:99];
        
        CorruptedMind *corrupted = [[[CorruptedMind alloc] initWithDuration:8 andEffectType:EffectTypeNegative] autorelease];
        [corrupted setValuePerTick:-100];
        [corrupted setNumOfTicks:8];
        [corrupted setTickChangeForHealing:-20];
        [corrupted setEffectForHealing:healingBuff];
        [corrupted setTitle:@"corrupted-mind"];

        Attack *corruptedMind = [[[Attack alloc] initWithDamage:300 andCooldown:10.0] autorelease];
        [corruptedMind setExecutionSound:@"curse.mp3"];
        [corruptedMind setPrefersTargetsWithoutVisibleEffects:YES];
        [corruptedMind setIgnoresPlayers:YES];
        [corruptedMind setIconName:@"corrupt_mind.png"];
        [corruptedMind setRequiresDamageToApplyEffect:NO];
        [corruptedMind setActivationTime:1.5];
        [corruptedMind setTitle:@"Corrupt Mind"];
        [corruptedMind setInfo:@"A curse that deals damage and each time the afflicted unit is healed the Healer gains 4% more Healing and Mana Regen."];
        [corruptedMind setAppliedEffect:corrupted];
        [self addAbility:corruptedMind];
    }
}

@end

@implementation Teritha
- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (percentage == 99.0) {
        if (self.difficulty < 5) {
            [[self abilityWithKey:@"ultimate-corruption"] setTimeApplied:0];
            
            self.inactive = NO;
            [self.announcer announce:@"\"These pitiful fools are worthless.  I will finish you myself!\""];
            [self.announcer playAudioForTitle:@"teritha_laugh.mp3"];
        }
    }
    
    if (percentage == 80.0) {
        ProjectileAttack *bolts = (ProjectileAttack*)[self abilityWithKey:@"teritha-bolts"];
        [bolts setAttacksPerTrigger:5];
    }
    
    if (percentage == 50.0) {
        [self.announcer announce:@"Such Insolent Creatures! Embrace your demise!"];
        [self.announcer playAudioForTitle:@"teritha_laugh.mp3"];
        ProjectileAttack *bolts = (ProjectileAttack*)[self abilityWithKey:@"teritha-bolts"];
        [bolts setTimeApplied:-5.0];
        [bolts fireAtRaid:raid];
        [bolts setAttacksPerTrigger:7];
    }
    
    if (percentage == 25.0) {
        [self.announcer announce:@"I am darkness.  I AM YOUR DOOM!"];
        [self.announcer playAudioForTitle:@"teritha_laugh.mp3"];
        ProjectileAttack *bolts = (ProjectileAttack*)[self abilityWithKey:@"teritha-bolts"];
        [bolts setTimeApplied:-5.0];
        [bolts fireAtRaid:raid];
        [bolts setAttacksPerTrigger:10];
    }
}

- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses
{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq choosesMT:chooses]) {
        self.spriteName = @"council3_battle_portrait.png";
        
        WrackingPainEffect *wpe = [[[WrackingPainEffect alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
        [wpe setValuePerTick:-100];
        [wpe setTitle:@"wracking-pain-eff"];
        [wpe setAilmentType:AilmentCurse];
        
        RaidApplyEffect *wrackingPain = [[[RaidApplyEffect alloc] init] autorelease];
        [wrackingPain setExecutionSound:@"explosion_pulse.wav"];
        [wrackingPain setKey:@"wracking-pain"];
        [wrackingPain setTitle:@"Wracking Pain"];
        [wrackingPain setAttackParticleEffectName:@"shadow_burst.plist"];
        [wrackingPain setIconName:@"curse.png"];
        [wrackingPain setInfo:@"Teritha covers your allies in a malicious curse that deals damage until their health is reduced to 50% or less."];
        [wrackingPain setCooldown:60.0];
        [wrackingPain setTimeApplied:58.0];
        [wrackingPain setActivationTime:2.0];
        [wrackingPain setAppliedEffect:wpe];
        [self addAbility:wrackingPain];
        
        ProjectileAttack *bolts = [[[ProjectileAttack alloc] init] autorelease];
        [bolts setIconName:@"shadow_bolt.png"];
        [bolts setKey:@"teritha-bolts"];
        [bolts setExecutionSound:@"fireball.mp3"];
        [bolts setExplosionSoundName:@"explosion5.mp3"];
        [bolts setCooldown:7.5];
        [bolts setTimeApplied:0.0];
        [bolts setAttacksPerTrigger:3];
        [bolts setActivationTime:1.5];
        [bolts setExplosionParticleName:@"shadow_burst.plist"];
        [bolts setSpriteName:@"shadowbolt.png"];
        [bolts setAbilityValue:225];
        [bolts setTitle:@"Bolts of Darkness"];
        [self addAbility:bolts];
    }
    return self;
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    if (self.difficulty == 5) {
        RaidApplyEffect *wp = (RaidApplyEffect*)[self abilityWithKey:@"wracking-pain"];
        
        [(WrackingPainEffect*)wp.appliedEffect setThreshold:.35];
        [wp setInfo:@"Teritha covers your allies in a malicious curse that deals damage until their health is reduced to 35% or less."];
        
        RaidDamagePulse *pulse = [[[RaidDamagePulse alloc] init] autorelease];
        [pulse setInfo:@"When you begin fighting Teritha she starts a dark ritual.  All hope is lost if you and your allies cannot defeat her before she gains Ultimate Corruption."];
        [pulse setIconName:@"poison_explosion.png"];
        [pulse setActivationTime:2.0];
        [pulse setTitle:@"Ultimate Corruption"];
        [pulse setKey:@"ultimate-corruption"];
        [pulse setAbilityValue:2500];
        [pulse setNumTicks:4];
        [pulse setDuration:12.0];
        [pulse setCooldown:220.0];
        [self addAbility:pulse];
    }
}
@end

@implementation Sarroth

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    if (difficulty == 5) {
        BlindingSmokeAttack *blinding = [[[BlindingSmokeAttack alloc] init] autorelease];
        [blinding setExecutionSound:@"bang1.mp3"];
        [blinding setTitle:@"Blinding Glare"];
        [blinding setIconName:@"blind.png"];
        [blinding setInfo:@"A glare that blinds Healers and absorbs 300 healing."];
        [blinding setActivationTime:.5];
        [blinding setCooldown:40];
        [blinding setCooldownVariance:.7];
        [self addAbility:blinding];
    }
}

-(void)axeSweepThroughRaid:(Raid*)theRaid{
    self.autoAttack.timeApplied = -7.0;
    //Set all the other abilities to be on a long cooldown...
    [[self abilityWithKey:@"axe-sweep"] triggerAbilityForRaid:theRaid players:[NSArray array] enemies:[NSArray array]];
    [self.announcer announce:@"Sarroth sweeps through your allies with spinning blades"];
}

-(void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta{
    if (percentage == 99.0) {
        [self.announcer announce:@"\"The Master is Generous.  He provides lambs for the slaughter.\""];
    }
    if (percentage == 80.0 || percentage == 60.0 || percentage == 40.0 || percentage == 20.0){
        [self axeSweepThroughRaid:raid];
    }
}

- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses
{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq choosesMT:chooses]) {
        self.spriteName = @"twinchampions_battle_portrait.png";
        self.namePlateTitle = @"Sarroth";
        [(FocusedAttack*)self.autoAttack setDamageAudioName:@"sword_slash.mp3"];
        RaidDamageSweep *rds = [[[RaidDamageSweep alloc] init] autorelease];
        [rds setAbilityValue:150];
        [rds setBonusCriticalChance:.2];
        [rds setTitle:@"Sweeping Death"];
        [rds setKey:@"axe-sweep"];
        [rds setIconName:@"impale.png"];
        [rds setCooldown:kAbilityRequiresTrigger];
        [self addAbility:rds];
        
        IntensifyingRepeatedHealthEffect *gushingWoundEffect = [[[IntensifyingRepeatedHealthEffect alloc] initWithDuration:9.0 andEffectType:EffectTypeNegative] autorelease];
        [gushingWoundEffect setAilmentType:AilmentTrauma];
        [gushingWoundEffect setIncreasePerTick:.5];
        [gushingWoundEffect setValuePerTick:-230];
        [gushingWoundEffect setNumOfTicks:3];
        [gushingWoundEffect setTitle:@"gushingwound"];
        
        ProjectileAttack *gushingWound = [[[ProjectileAttack alloc] init] autorelease];
        [gushingWound setIgnoresGuardians:YES];
        [gushingWound setKey:@"gushing-wound"];
        [gushingWound setExplosionParticleName:@"blood_spurt.plist"];
        [gushingWound setExecutionSound:@"whiff.mp3"];
        [gushingWound setExplosionSoundName:@"sharpimpactbleeding.mp3"];
        [gushingWound setTitle:@"Deadly Throw"];
        [gushingWound setCooldown:17.0];
        [gushingWound setActivationTime:1.5];
        [gushingWound setEffectType:ProjectileEffectTypeThrow];
        [gushingWound setIconName:@"gushing_wound.png"];
        [gushingWound setSpriteName:@"sword.png"];
        [gushingWound setAppliedEffect:gushingWoundEffect];
        [gushingWound setAbilityValue:250];
        [self addAbility:gushingWound];
    }
    return self;
}
@end

@implementation Vorroth

- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses
{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq choosesMT:chooses]) {
        self.spriteName = @"twinchampions2_battle_portrait.png";
        self.namePlateTitle = @"Vorroth";
        [self addAbility:[Cleave normalCleave]];
        [(FocusedAttack*)self.autoAttack setDamageAudioName:@"largeaxe.mp3"];
        
        ExecutionEffect *executionEffect = [[[ExecutionEffect alloc] initWithDuration:3.75 andEffectType:EffectTypeNegative] autorelease];
        [executionEffect setTitle:@"exec-eff"];
        [executionEffect setValue:-2000];
        [executionEffect setEffectivePercentage:.5];
        [executionEffect setAilmentType:AilmentTrauma];
        
        Attack *executionAttack = [[[Attack alloc] initWithDamage:0 andCooldown:30] autorelease];
        [executionAttack setInfo:@"The Twin Champions will choose a target for execution.  This target will be instantly slain if not above 50% health when the deathblow lands."];
        [executionAttack setPrefersTargetsWithoutVisibleEffects:YES];
        [executionAttack setTitle:@"Execution"];
        [executionAttack setIconName:@"execution.png"];
        [executionAttack setRequiresDamageToApplyEffect:NO];
        [executionAttack setIgnoresGuardians:YES];
        [executionAttack setKey:@"execution"];
        [executionAttack setFailureChance:0];
        [executionAttack setAppliedEffect:executionEffect];
        [self addAbility:executionAttack];
        
    }
    return self;
}

- (void)ownerDidExecuteAbility:(Ability *)ability
{
    if ([ability.key isEqualToString:@"execution"]){
        [self.announcer announce:@"An ally has been chosen for execution!"];
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    if (percentage == 97.0) {
        [self.announcer announce:@"\"We shall feast on their flesh!\""];
    }
}

@end

@implementation Baraghast
- (void)dealloc {
    [_remainingAbilities release];
    [super dealloc];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
}

+(id)defaultBoss {
    Baraghast *boss = [[Baraghast alloc] initWithHealth:3040000 damage:150 targets:1 frequency:1.25 choosesMT:YES];
    boss.autoAttack.failureChance = .30;
    [(FocusedAttack*)boss.autoAttack setDamageAudioName:@"sword_slash.mp3"];
    [boss setTitle:@"Baraghast, Warlord of the Damned"];
    [boss setNamePlateTitle:@"Baraghast"];
    [boss setSpriteName:@"baraghast_battle_portrait.png"];
    
    [boss addAbility:[Cleave normalCleave]];
    
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (percentage == 99.0) {
        [self.announcer announce:@"\"So you've slain some robed fools and worthless minions. Now you shall see true might.\""];
        BaraghastRoar *roar = [[[BaraghastRoar alloc] init] autorelease];
        [roar setKey:@"baraghast-roar"];
        [roar setCooldown:17.5];
        [self addAbility:roar];
    }
    
    if (percentage == 80.0) {
        [self.announcer announce:@"Baraghast looks through your ranks for the weakest ally."];
        BaraghastBreakOff *breakOff = [[[BaraghastBreakOff alloc] init] autorelease];
        [breakOff setKey:@"break-off"];
        [breakOff setCooldown:25];
        [breakOff setOwnerAutoAttack:(FocusedAttack*)self.autoAttack];
        [self addAbility:breakOff];
    }
    
    if (percentage == 60.0) {
        [self.announcer announce:@"Baraghast fills with empowering rage."];
        Crush *crushAbility = [[[Crush alloc] init] autorelease];
        [crushAbility setKey:@"crush"];
        [crushAbility setCooldown:20];
        [crushAbility setTarget:[(FocusedAttack*)self.autoAttack focusTarget]];
        [self addAbility:crushAbility];
    }
    
    if (percentage == 33.0) {
        [self.announcer announce:@"A Dark Energy Surges Beneath Baraghast."];
        Deathwave *dwAbility = [[[Deathwave alloc] init] autorelease];
        [dwAbility setKey:@"deathwave"];
        [dwAbility setTimeApplied:35.0];
        [dwAbility setCooldown:42.0];
        [self addAbility:dwAbility];
    }
    
    if (self.difficulty == 5) {
        if (percentage == 16.0) {
            [[self abilityWithKey:@"deathwave"] setIsDisabled:YES];
            [[self abilityWithKey:@"crush"] setIsDisabled:YES];
            [[self abilityWithKey:@"break-off"] setIsDisabled:YES];
            [[self abilityWithKey:@"baraghast-roar"] setIsDisabled:YES];
            [self.autoAttack setIsDisabled:YES];
            
            [self.announcer announce:@"You have come so far only to die now."];
            
            AbilityDescriptor *godscall = [[[AbilityDescriptor alloc] init] autorelease];
            [godscall setIconName:@"redemption.png"];
            [godscall setAbilityName:@"Light of Purity"];
            [godscall setAbilityDescription:@"Baraghast's use of ancient demonic powers have signaled help from the light reducing your cast times and cooldowns by 50% and reducing all spell costs by 100%."];
            [self addAbilityDescriptor:godscall];
            
            for (Player *player in players) {
                Effect *godscallEffect = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositive] autorelease];
                [godscallEffect setSpriteName:@"redemption.png"];
                [godscallEffect setSpellCostAdjustment:1.0];
                [godscallEffect setCastTimeAdjustment:.5];
                [godscallEffect setCooldownMultiplierAdjustment:-.5];
                [godscallEffect setOwner:self];
                [godscallEffect setTitle:@"godscall-eff"];
                [player addEffect:godscallEffect];
            }
            
            for (RaidMember *member in raid.livingMembers) {
                Effect *stunned = [[[Effect alloc] initWithDuration:8 andEffectType:EffectTypeNegative] autorelease];
                [stunned setSpriteName:@"shadow_prison.png"];
                [stunned setOwner:self];
                [stunned setTitle:@"shadow-prison-eff"];
                [stunned setCausesStun:YES];
                [member addEffect:stunned];
            }
            [self.announcer displayScreenFlash];
            [self.announcer displayScreenShakeForDuration:1.0];
            [self.announcer playAudioForTitle:@"bang1.mp3"];
            
            Ability *endStunAbility = [[[Ability alloc] init] autorelease];
            [endStunAbility setCooldown:8];
            [endStunAbility setKey:@"end-stun"];
            [self addAbility:endStunAbility];
            
        }
    }
    
    if (percentage == 2.0) {
        [self.announcer announce:@"You cannot defeat me.  This is merely a set back."];
    }
}

- (void)ownerDidBeginAbility:(Ability *)ability {
    if ([ability.key isEqualToString:@"deathwave"]){
        for (Ability *ab in self.abilities){
            if (ab != ability){
                [ab setTimeApplied:0];
            }
        }
    }
}

- (void)ownerDidExecuteAbility:(Ability *)ability
{
    if (self.difficulty == 5) {
        if ([ability.key isEqualToString:@"end-stun"]) {
            self.autoAttack.isDisabled = NO;
            [self removeAbility:ability];
            
            Breath *fb = [[[Breath alloc] init] autorelease];
            [fb setBreathParticleName:@"shadow_breath"];
            [fb setTitle:@"Demon Breath"];
            [fb setKey:@"demon-breath"];
            [fb setIconName:@"shadow_breath.png"];
            [fb setInfo:@"A horrible blast of soul-crippling darkness.  This breath deals more damage each time it is used."];
            [fb setAbilityValue:70];
            [fb setActivationTime:2];
            [fb setTimeApplied:15.0];
            [fb setCooldown:17.0];
            [self addAbility:fb];
            
            GroundSmash *groundSmash = [[[GroundSmash alloc] init] autorelease];
            [groundSmash setIconName:@"crushing_punch.png"];
            [groundSmash setAbilityValue:110];
            [groundSmash setKey:@"demonic-fury"];
            [groundSmash setCooldown:20.0];
            [groundSmash setActivationTime:1.5];
            [groundSmash setTimeApplied:80.0];
            [groundSmash setTitle:@"Demonic Fury"];
            [self addAbility:groundSmash];
        }
        
        if ([ability.key isEqualToString:@"demon-breath"]) {
            ability.abilityValue *= 1.25;
        }
    }
}
@end

@implementation CrazedSeer
+ (id)defaultBoss {
    CrazedSeer *seer = [[CrazedSeer alloc] initWithHealth:2720000 damage:0 targets:0 frequency:0 choosesMT:NO ];
    [seer setTitle:@"Crazed Seer Tyonath"];
    [seer setNamePlateTitle:@"Tyonath"];
    [seer setSpriteName:@"tyonath_battle_portrait.png"];
    
    ProjectileAttack *fireballAbility = [[[ProjectileAttack alloc] init] autorelease];
    [fireballAbility setExecutionSound:@"fireball.mp3"];
    [fireballAbility setExplosionSoundName:@"liquid_impact.mp3"];
    [fireballAbility setSpriteName:@"shadowbolt.png"];
    [fireballAbility setExplosionParticleName:@"shadow_burst.plist"];
    [fireballAbility setAbilityValue:-120];
    [fireballAbility setCooldown:4];
    [seer addAbility:fireballAbility];
    
    InvertedHealing *invHeal = [[[InvertedHealing alloc] init] autorelease];
    [invHeal setExecutionSound:@"curse.mp3"];
    [invHeal setNumTargets:3];
    [invHeal setCooldown:5.0];
    [invHeal setActivationTime:1.5];
    [seer addAbility:invHeal];
    
    SoulBurn *sb = [[[SoulBurn alloc] init] autorelease];
    [sb setExecutionSound:@"fire_start.mp3"];
    [sb setActivationTime:2.0];
    [sb setCooldown:14.0];
    [seer addAbility:sb];
    
    ImproveProjectileAbility *gainShadowbolts = [[[ImproveProjectileAbility alloc] init] autorelease];
    [gainShadowbolts setCooldown:60];
    [gainShadowbolts setInfo:@"Tyonath casts more shadow bolts the longer the fight goes on."];
    [gainShadowbolts setTitle:@"Increasing Insanity"];
    [gainShadowbolts setIconName:@"increasing_insanity.png"];
    [gainShadowbolts setAbilityToImprove:fireballAbility];
    [seer addAbility:gainShadowbolts];
    
    RaidDamage *horrifyingLaugh = [[[RaidDamage alloc] init] autorelease];
    [horrifyingLaugh setExecutionSound:@"tyonath_laugh.mp3"];
    [horrifyingLaugh setActivationTime:1.5];
    [horrifyingLaugh setIconName:@"roar.png"];
    [horrifyingLaugh setTitle:@"Horrifying Laugh"];
    [horrifyingLaugh setAbilityValue:125];
    [horrifyingLaugh setCooldown:25];
    [seer addAbility:horrifyingLaugh];
    
    return [seer autorelease];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    
    if (difficulty == 5) {
        DisableSpell *disableSpell = [[[DisableSpell alloc] init] autorelease];
        [disableSpell setCooldown:15];
        [disableSpell setAbilityValue:10.0];
        [disableSpell setTitle:@"Mental Fog"];
        [disableSpell setInfo:@"The Crazed Seer clouds your mind and disables your spells."];
        [disableSpell setIconName:@"cloud_mind.png"];
        [self addAbility:disableSpell];
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    if (percentage == 99.0) {
        [self.announcer announce:@"\"Heheheh the master grants me too much power...too much yes..\""];
    }
    
    if (percentage == 50.0) {
        [self.announcer announce:@"\"Had enough yet?! Heheheh..\""];
    }
    
    if (percentage == 2.0) {
        [self.announcer announce:@"\"Master will remake me.  Master will make me better...\""];
    }
}
@end

@implementation GatekeeperDelsarn
+ (id)defaultBoss {
    GatekeeperDelsarn *boss = [[GatekeeperDelsarn alloc] initWithHealth:4330000 damage:500 targets:1 frequency:2.1 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Gatekeeper of Delsarn"];
    [boss setNamePlateTitle:@"The Gatekeeper"];
    [boss setSpriteName:@"gatekeeper_battle_portrait.png"];
    
    [boss addAbility:[Cleave normalCleave]];
    [boss addGripImpale];
    
    return [boss autorelease];
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1:
            return -.40;
        case 2:
            return -.20;
        case 4:
        case 5:
            return .125;
        case 3: //Normal
        default:
            return 0.0;
    }
}

- (void)addGripImpale
{
    Grip *gripAbility = [[[Grip alloc] init] autorelease];
    [gripAbility setExecutionSound:@"chainstightening.mp3"];
    [gripAbility setKey:@"grip-ability"];
    [gripAbility setActivationTime:1.5];
    [gripAbility setCooldown:10];
    [gripAbility setAbilityValue:-50];
    [self addAbility:gripAbility];
    
    Impale *impaleAbility = [[[Impale alloc] init] autorelease];
    [impaleAbility setExecutionSound:@"sharpimpactbleeding.mp3"];
    [impaleAbility setKey:@"gatekeeper-impale"];
    [impaleAbility setActivationTime:1.5];
    [impaleAbility setCooldown:16];
    [self addAbility:impaleAbility];
    [impaleAbility setAbilityValue:820];
}

- (void)ownerDidExecuteAbility:(Ability *)ability
{
    if ([ability.key isEqualToString:@"open-the-gates"]) {
        [self.announcer displayParticleSystemOnRaidWithName:@"green_mist.plist" forDuration:20];
    }
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    if (difficulty == 5) {
        OrbsOfFury *orbsOfFury = [[[OrbsOfFury alloc] init] autorelease];
        [orbsOfFury setCooldown:16.0];
        [orbsOfFury setCooldownVariance:.4];
        [orbsOfFury setAbilityValue:20];
        [orbsOfFury setIconName:@"red_curse.png"];
        [orbsOfFury setTitle:@"Orbs of Fury"];
        [orbsOfFury setInfo:@"The Gatekeeper summons orbs of fury increasing his damage taken by 10% and damage dealt by 4% per orb.  The Healer may detonate the orbs by tapping them."];
        [self addAbility:orbsOfFury];
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (percentage == 99.0) {
        [self.announcer announce:@"\"You are fools to think you can enter this realm.  You shall suffer.\""];
    }
    
    if (percentage == 80.0){
        [self.announcer announce:@"\"Prepare to taste madness.\""];
        self.autoAttack.abilityValue = 300;
        [self removeAbility:[self abilityWithKey:@"grip-ability"]];
        [self removeAbility:[self abilityWithKey:@"gatekeeper-impale"]];
        
        NSTimeInterval openingTime = 5.0;
        RepeatedHealthEffect *pestilenceDot = [[[RepeatedHealthEffect alloc] initWithDuration:20 andEffectType:EffectTypeNegativeInvisible] autorelease];
        [pestilenceDot setValuePerTick:-40];
        [pestilenceDot setNumOfTicks:10];
        [pestilenceDot setTitle:@"gatekeeper-pestilence"];
        
        RaidApplyEffect *openTheGates = [[[RaidApplyEffect alloc] init] autorelease];
        [openTheGates setAttackParticleEffectName:nil];
        [openTheGates setKey:@"open-the-gates"];
        [openTheGates setTitle:@"Powers from Beyond"];
        [openTheGates setIconName:@"shadow_aura.png"];
        [openTheGates setCooldown:kAbilityRequiresTrigger];
        [openTheGates setActivationTime:openingTime];
        [openTheGates setAppliedEffect:pestilenceDot];
        [self addAbility:openTheGates];
        [openTheGates activateAbility];
        
        StackingEnrage *growingHatred = [[[StackingEnrage alloc] init] autorelease];
        [growingHatred setKey:@"growing-hatred"];
        [growingHatred setAbilityValue:2];
        [growingHatred setCooldown:10.0];
        [growingHatred setTitle:@"Growing Hatred"];
        [growingHatred setIconName:@"temper.png"];
        [growingHatred setInfo:@"The Gatekeeper deals more damage the longer the fight lasts."];
        [growingHatred setActivationTime:1.0];
        [self addAbility:growingHatred];
        
        BurningInsanity *burningInsanity = [[[BurningInsanity alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
        
        RaidApplyEffect *insaneRaid = [[[RaidApplyEffect alloc] init] autorelease];
        [insaneRaid setExecutionSound:@"fieryexplosion.mp3"];
        [insaneRaid setKey:@"insane-raid"];
        [insaneRaid setTitle:@"Burning Insanity"];
        [insaneRaid setIconName:@"burning_insanity.png"];
        [insaneRaid setInfo:@"Reduces healing received by 25% per stack and is removed when the target is healed above 50%. At 3 stacks the target gains Fury dealing 400% damage for 75 sec."];
        [insaneRaid setCooldown:24.0];
        [insaneRaid setAttackParticleEffectName:@"fire_explosion.plist"];
        [insaneRaid setActivationTime:2.0];
        [insaneRaid setAppliedEffect:burningInsanity];
        [self addAbility:insaneRaid];
        
    }
    
    if (percentage == 25.0) {
        self.autoAttack.abilityValue = 500;
        [self removeAbility:[self abilityWithKey:@"insane-raid"]];
        [self addGripImpale];
        //Drink in death +10% damage for each ally slain so far.
        NSInteger dead = [raid deadCount];
        if (dead > 0) {
            [self.announcer announce:@"\"I drink in the death that surrounds me.\""];
        }
        dead++;
        for (int i = 0; i < dead; i++){
            Effect *enrageEffect = [[Effect alloc] initWithDuration:600 andEffectType:EffectTypePositiveInvisible];
            [enrageEffect setIsIndependent:YES];
            [enrageEffect setOwner:self];
            [enrageEffect setTitle:@"drink-in-death"];
            [enrageEffect setDamageDoneMultiplierAdjustment:.1];
            [self addEffect:[enrageEffect autorelease]];
        }
        
    }
}
@end

@implementation SkeletalDragon
- (void)dealloc {
    [_boneThrowAbility release];
    [_sweepingFlame release];
    [_tankDamage release];
    [_tailLash release];
    [super dealloc];
}
+ (id)defaultBoss {
    SkeletalDragon *boss = [[SkeletalDragon alloc] initWithHealth:2190000 damage:0 targets:0 frequency:100 choosesMT:NO ];
    [boss setTitle:@"Skeletal Dragon"];
    [boss setSpriteName:@"skeletaldragon_battle_portrait.png"];
    
    boss.boneThrowAbility = [[[BoneThrow alloc] init] autorelease];
    [boss.boneThrowAbility setActivationTime:1.5];
    [boss.boneThrowAbility setCooldown:3.5];
    [boss addAbility:boss.boneThrowAbility];
    
    RepeatedHealthEffect *burningEffect = [[[RepeatedHealthEffect alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative] autorelease];
    [burningEffect setValuePerTick:-25];
    [burningEffect setNumOfTicks:5];
    [burningEffect setTitle:@"alternating-flame-burn"];
    
    boss.sweepingFlame = [[[AlternatingFlame alloc] init] autorelease];
    [boss.sweepingFlame setExecutionSound:@"fieryexplosion.mp3"];
    [(AlternatingFlame*)boss.sweepingFlame setAppliedEffect:burningEffect];
    [boss.sweepingFlame setActivationTime:1.0];
    [boss.sweepingFlame setCooldown:9.0];
    [boss.sweepingFlame setAbilityValue:400];
    [(AlternatingFlame*)boss.sweepingFlame setNumTargets:5];
    [boss addAbility:boss.sweepingFlame];
    
    boss.tankDamage = [[[FocusedAttack alloc] init] autorelease];
    [boss.tankDamage setAbilityValue:700];
    [boss.tankDamage setCooldown:2.5];
    [boss.tankDamage setFailureChance:.73];
    
    boss.tailLash = [[[TailLash alloc] init] autorelease];
    boss.tailLash.iconName = @"tail_lash.png";
    [boss.tailLash setActivationTime:1.5];
    [boss.tailLash setActivationSound:@"dragonroar1.mp3"];
    [boss.tailLash setTitle:@"Tail Lash"];
    [boss.tailLash setAbilityValue:320];
    [boss.tailLash setCooldown:17.5];
    
    [boss addAbilityDescriptor:[(SkeletalDragon*)boss flyingDescriptor]];
    
    return [boss autorelease];
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1:
        case 2:
        case 3:
        case 4:
            return [super challengeDamageDoneModifier];
        case 5:
            return .35;
        default:
            return 0.0;
    }
}

- (AbilityDescriptor *)flyingDescriptor
{
    AbilityDescriptor *flying= [[[AbilityDescriptor alloc] init] autorelease];
    [flying setIconName:@"flying.png"];
    [flying setAbilityDescription:@"The Skeletal Dragon is flying above you and your allies."];
    [flying setAbilityName:@"Flying"];
    return flying;
}

- (AbilityDescriptor *)groundedDescriptor
{
    AbilityDescriptor *grounded = [[[AbilityDescriptor alloc] init] autorelease];
    [grounded setIconName:@"grounded.png"];
    [grounded setAbilityName:@"Grounded"];
    [grounded setAbilityDescription:@"The Skeletal Dragon has landed and will thrash your enemies with its claws."];
    return grounded;
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    
    if (percentage == 99.0){
        [self.announcer announce:@"The Skeletal Dragon hovers angrily above your allies."];
        [self.announcer playAudioForTitle:@"dragonwings.mp3"];
        
    }
    
    if (percentage == 66.0){
        [self clearExtraDescriptors];
        [self addAbilityDescriptor:[self groundedDescriptor]];
        [self.announcer playAudioForTitle:@"stomp.wav"];
        [self.announcer displayScreenShakeForDuration:.33];
        [self.announcer announce:@"The Skeletal Dragon lands and begins to thrash your allies"];
        self.boneThrowAbility.isDisabled = YES;
        [self addAbility:self.tankDamage];
        [self addAbility:self.tailLash];
        [self.sweepingFlame setCooldown:18.0];
    }
    
    if (percentage == 33.0){
        [self clearExtraDescriptors];
        [self addAbilityDescriptor:[self flyingDescriptor]];
        [self.announcer announce:@"The Skeletal Dragon soars off into the air."];
        [self.announcer playAudioForTitle:@"dragonwings.mp3"];
        [self.sweepingFlame setCooldown:14.5];
        [self.tankDamage setIsDisabled:YES];
        [self.tailLash setIsDisabled:YES];
        [self.boneThrowAbility setIsDisabled:NO];
        [self.boneThrowAbility setCooldown:5.0];
    }

    if (percentage == 5.0){
        [self clearExtraDescriptors];
        [self addAbilityDescriptor:[self groundedDescriptor]];
        [self.announcer displayScreenShakeForDuration:.66];
        [self.announcer playAudioForTitle:@"stomp1.wav"];
        [self.announcer announce:@"The Skeletal Dragon crashes down onto your allies from the sky."];
        NSArray *livingMembers = [raid livingMembers];
        NSInteger damageValue = 7500 / livingMembers.count;
        for (RaidMember *member in livingMembers){
            FallenDownEffect *fde = [FallenDownEffect defaultEffect];
            if ([member isKindOfClass:[Player class]]) {
                [fde setDuration:3.0];
            }
            [fde setOwner:self];
            [member addEffect:fde];
            
            DelayedHealthEffect *fallenDamage = [[DelayedHealthEffect alloc] initWithDuration:.1 andEffectType:EffectTypeNegativeInvisible];
            [fallenDamage setOwner:self];
            [fallenDamage setTitle:@"falling-dragon"];
            [fallenDamage setValue:-damageValue];
            [member addEffect:fallenDamage];
            [fallenDamage release];
        }
    }
}

- (void)ownerDidExecuteAbility:(Ability *)ability {
    if (ability == self.tailLash) {
        [self.announcer displayScreenShakeForDuration:.25];
    }
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    if (difficulty == 5) {
        UndyingFlameEffect *flames = [[[UndyingFlameEffect alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
        [flames setTitle:@"undying-flames-eff"];
        [flames setValuePerTick:-20];
        [flames setStacks:5];
        [flames setMaxStacks:5];
        [flames setVisibilityPriority:100];
        
        UndyingFlame *undyingFlame = [[[UndyingFlame alloc] initWithDamage:1 andCooldown:15.0] autorelease];
        [undyingFlame setActivationTime:1.25];
        [undyingFlame setAttackParticleEffectName:@"flame_spawn.plist"];
        [undyingFlame setExecutionSound:@"dragonroar2.mp3"];
        [undyingFlame setRequiresDamageToApplyEffect:NO];
        [undyingFlame setPrefersTargetsWithoutVisibleEffects:YES];
        [undyingFlame setInfo:@"A target is covered in flames.  The flame starts with 5 stacks but a stack is removed each time the target is healed.  Whenever the dragon applies this flame all flames are reignited."];
        [undyingFlame setIconName:@"soul_burn.png"];
        [undyingFlame setTitle:@"Undying Flame"];
        [undyingFlame setAppliedEffect:flames];
        [self addAbility:undyingFlame];
    }
}
@end

@implementation ColossusOfBone
- (void)dealloc {
    [_boneQuake release];
    [_crushingPunch release];
    [super dealloc];
}
+ (id)defaultBoss {
    ColossusOfBone *cob = [[ColossusOfBone alloc] initWithHealth:1710000 damage:620 targets:1 frequency:2.15 choosesMT:YES];
    [cob setTitle:@"Colossus of Bone"];
    [cob.autoAttack setFailureChance:.35];
    [cob setSpriteName:@"colossusbone_battle_portrait.png"];
    
    cob.crushingPunch = [[[Attack alloc] initWithDamage:0 andCooldown:10.0] autorelease];
    DelayedHealthEffect *crushingPunchEffect = [[DelayedHealthEffect alloc] initWithDuration:3.0 andEffectType:EffectTypeNegative];
    [crushingPunchEffect setTitle:@"crushing-punch"];
    [crushingPunchEffect setOwner:cob];
    [crushingPunchEffect setValue:-900];
    [(Attack*)cob.crushingPunch setAppliedEffect:crushingPunchEffect];
    [(Attack*)cob.crushingPunch setPrefersTargetsWithoutVisibleEffects:YES];
    [crushingPunchEffect release];
    [cob.crushingPunch setFailureChance:.2];
    [cob.crushingPunch setInfo:@"Periodically, this enemy unleashes a colossal strike on a random ally dealing very high damage."];
    [cob.crushingPunch setTitle:@"Crushing Slam"];
    [cob.crushingPunch setIconName:@"crushing_punch.png"];
    [cob addAbility:cob.crushingPunch];
    
    cob.boneQuake = [[[BoneQuake alloc] init] autorelease];
    [cob.boneQuake setIconName:@"quake.png"];
    [cob.boneQuake setExecutionSound:@"earthquake.mp3"];
    [cob.boneQuake setTitle:@"Quake"];
    [cob.boneQuake setAbilityValue:120];
    [cob.boneQuake setActivationTime:1.5];
    [cob.boneQuake setCooldown:28.5];
    [cob addAbility:cob.boneQuake];
    
    BoneThrow *boneThrow = [[[BoneThrow alloc] init] autorelease];
    [boneThrow setActivationTime:1.5];
    [boneThrow setAbilityValue:240];
    [boneThrow setCooldown:14.0];
    [cob addAbility:boneThrow];
    
    return [cob autorelease];
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1:
        case 2:
        case 3:
        case 4:
            return [super challengeDamageDoneModifier];
        case 5:
            return .35;
        default:
            return 0.0;
    }
}

- (void)ownerDidExecuteAbility:(Ability *)ability {
    if (ability == self.boneQuake){
        [self.announcer displayScreenShakeForDuration:3.0];
        float boneQuakeCD = arc4random() % 15 + 15;
        [self.boneQuake setCooldown:boneQuakeCD];
    }
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    
    if (difficulty == 5) {
        InterruptedByFullHealthTargets *boneStorm = [[[InterruptedByFullHealthTargets alloc] init] autorelease];
        [boneStorm setAttackParticleEffectName:nil];
        [boneStorm setInfo:@"The Colossus summons a storm of bones to crush his enemies.  This ability is interrupted if the Colossus detects 3 full health enemies."];
        [boneStorm setTitle:@"Bonestorm"];
        [boneStorm setIconName:@"bonestorm.png"];
        [boneStorm setChannelTickRaidParticleEffectName:@"bonestorm.plist"];
        [boneStorm setRequiredNumberOfTargets:3];
        [boneStorm setActivationTime:1.5];
        [boneStorm setCooldown:60.0];
        [boneStorm setAbilityValue:65];
        [boneStorm setTimeApplied:20.0];
        [self addAbility:boneStorm];
    }
}

@end

@implementation OverseerOfDelsarn
- (void)dealloc {
    [_projectilesAbility release];
    [_demonAbilities release];
    [super dealloc];
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1:
        case 2:
        case 3:
        case 4:
            return [super challengeDamageDoneModifier];
        case 5:
            return .35;
        default:
            return 0.0;
    }
}

+ (id)defaultBoss {
    OverseerOfDelsarn *boss = [[OverseerOfDelsarn alloc] initWithHealth:2580000 damage:0 targets:0 frequency:0 choosesMT:NO ];
    [boss setTitle:@"Overseer of Delsarn"];
    [boss setNamePlateTitle:@"The Overseer"];
    [boss setSpriteName:@"overseer_battle_portrait.png"];
    
    boss.projectilesAbility = [[[OverseerProjectiles alloc] init] autorelease];
    [boss.projectilesAbility setIconName:@"blood_bolt.png"];
    [boss.projectilesAbility setTitle:@"Bolt of Despair"];
    [boss.projectilesAbility setActivationTime:1.25];
    [boss.projectilesAbility setExecutionSound:@"fireball.mp3"];
    [boss.projectilesAbility setAbilityValue:514];
    [boss.projectilesAbility setCooldown:2.5];
    [boss addAbility:boss.projectilesAbility];
    
    boss.demonAbilities = [NSMutableArray arrayWithCapacity:3];
    
    FireMinion *fm = [[FireMinion alloc] init];
    [fm setKey:@"fire-minion"];
    [fm setCooldown:15.0];
    [fm setAbilityValue:315];
    [boss.demonAbilities addObject:fm];
    [fm release];
    
    BloodMinion *bm = [[BloodMinion alloc] init];
    [bm setKey:@"blood-minion"];
    [bm setCooldown:10.0];
    [bm setAbilityValue:90];
    [boss.demonAbilities addObject:bm];
    [bm release];
    
    ShadowMinion *sm = [[ShadowMinion alloc] init];
    [sm setKey:@"shadow-minion"];
    [sm setCooldown:12.0];
    [sm setAbilityValue:153];
    [boss.demonAbilities addObject:sm];
    [sm release];
    
    return [boss autorelease];
}

- (void)addRandomDemonAbility {
    NSInteger indexToAdd = arc4random() % self.demonAbilities.count;
    
    if (self.difficulty == 5) {
        indexToAdd = 0;
    }
    
    Ability *addedAbility = [self.demonAbilities objectAtIndex:indexToAdd];
    [self addAbility:addedAbility];
    [self.demonAbilities removeObjectAtIndex:indexToAdd];
    
    NSString *minionTitle = nil;
    if ([addedAbility.key isEqualToString:@"shadow-minion"]) {
        minionTitle = @"Aura of Shadow";
    } else if ([addedAbility.key isEqualToString:@"fire-minion"]) {
        minionTitle = @"Aura of Flame";
    } else if ([addedAbility.key isEqualToString:@"blood-minion"]) {
        minionTitle = @"Aura of Blood";
    }
    
    if (minionTitle) {
        [self.announcer announce:[NSString stringWithFormat:@"The Overseer conjures  an %@", minionTitle]];
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    if (percentage == 80.0){
        self.projectilesAbility.isDisabled = YES;
        [self.announcer announce:@"The Overseer casts down his staff and begins channeling a demonic ritual."];
        [self addRandomDemonAbility];
    }
    
    if (percentage == 60.0){
        [self addRandomDemonAbility];
    }
    
    if (percentage == 40.0){
        [self addRandomDemonAbility];
    }
    
    if (percentage == 15.0){
        [self.announcer announce:@"The Overseer laughs maniacally and raises his staff again."];
        self.projectilesAbility.abilityValue = 432.0;
        self.projectilesAbility.cooldown = 4.0;
        self.projectilesAbility.isDisabled = NO;
    }
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    if (difficulty == 5) {
        DispelsWhenSelectedRepeatedHealthEffect *consumingShadows = [[[DispelsWhenSelectedRepeatedHealthEffect alloc] initWithDuration:-1 andEffectType:EffectTypeNegativeInvisible] autorelease];
        [consumingShadows setValuePerTick:-170];
        [consumingShadows setTitle:@"consuming-shadows-eff"];
        [consumingShadows setAilmentType:AilmentCurse];
        [consumingShadows setParticleEffectName:@"consuming_shadows.plist"];
        
        Attack *swellingDarkness = [[[Attack alloc] initWithDamage:1 andCooldown:30] autorelease];
        [swellingDarkness setTimeApplied:28.0];
        [swellingDarkness setNumberOfTargets:5];
        [swellingDarkness setAttackParticleEffectName:nil];
        [swellingDarkness setInfo:@"The Overseer covers several allies in shadows, but your radiance will remove the shadows by simply targeting the ally."];
        [swellingDarkness setTitle:@"Consuming Shadows"];
        [swellingDarkness setIconName:@"shadow_prison.png"];
        [swellingDarkness setRequiresDamageToApplyEffect:NO];
        [swellingDarkness setKey:@"consuming-shadows"];
        [swellingDarkness setFailureChance:0];
        [swellingDarkness setAppliedEffect:consumingShadows];
        [self addAbility:swellingDarkness];
    }
}
@end

@implementation TheUnspeakable
- (void)dealloc {
    [_oozeAll release];
    [super dealloc];
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1:
        case 2:
        case 3:
        case 4:
            return [super challengeDamageDoneModifier];
        case 5:
            return .35;
        default:
            return 0.0;
    }
}

+ (id)defaultBoss {
    TheUnspeakable *boss = [[TheUnspeakable alloc] initWithHealth:2900000 damage:0 targets:0 frequency:10.0 choosesMT:NO ];
    boss.autoAttack.failureChance = .25;
    [boss setTitle:@"The Unspeakable"];
    [boss setSpriteName:@"unspeakable_battle_portrait.png"];
    
    AbilityDescriptor *slimeDescriptor = [[[AbilityDescriptor alloc] init] autorelease];
    [slimeDescriptor setIconName:@"slime.png"];
    [slimeDescriptor setAbilityDescription:@"If this slime builds to 5 stacks that ally will be consumed.  Whenever an ally receives healing from you the slime is removed."];
    [slimeDescriptor setAbilityName:@"Engulfing Slime"];
    [boss addAbilityDescriptor:slimeDescriptor];
    
    boss.oozeAll = [[[OozeRaid alloc] init] autorelease];
    [boss.oozeAll setAttackParticleEffectName:nil];
    [boss.oozeAll setTitle:@"Surging Slime"];
    [boss.oozeAll setIconName:@"slime.png"];
    [boss.oozeAll setExecutionSound:@"slimeimpact.mp3"];
    [boss.oozeAll setActivationTime:2.0];
    [boss.oozeAll setTimeApplied:17.0];
    [boss.oozeAll setCooldown:22.0];
    [(OozeRaid*)boss.oozeAll setOriginalCooldown:24.0];
    [(OozeRaid*)boss.oozeAll setAppliedEffect:[EngulfingSlimeEffect defaultEffect]];
    [boss.oozeAll setKey:@"apply-ooze-all"];

    [boss addAbility:boss.oozeAll];
    
    OozeTwoTargets *oozeTwo = [[[OozeTwoTargets alloc] init] autorelease];
    [oozeTwo setTitle:@"Tendrils of Slime"];
    [oozeTwo setIconName:@"slime.png"];
    [oozeTwo setExecutionSound:@"slimespraying.mp3"];
    [oozeTwo setActivationTime:1.0];
    [oozeTwo setAbilityValue:200];
    [oozeTwo setCooldown:17.0];
    [oozeTwo setKey:@"ooze-two"];
    [boss addAbility:oozeTwo];
    
    return [boss autorelease];
}

- (void)setDifficulty:(NSInteger)difficulty
{
    [super setDifficulty:difficulty];
    
    OozeTwoTargets *oozeTwo = (OozeTwoTargets*)[self abilityWithKey:@"ooze-two"];
    NSTimeInterval oozeTwoCD = oozeTwo.cooldown - difficulty;
    [oozeTwo setCooldown:oozeTwoCD];
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {    
    if ((int)percentage % 10 == 0){
        NSTimeInterval reduction = 1.775 * (self.difficulty) / 5.0;
        [(OozeRaid*)self.oozeAll setOriginalCooldown:[(OozeRaid*)self.oozeAll originalCooldown] - reduction];
    }
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    if (difficulty == 5) {
        ConsumeMagic *cMagic = [[[ConsumeMagic alloc] init] autorelease];
        [cMagic setTitle:@"Consume Magic"];
        [cMagic setInfo:@"When the Unspeakable detects periodic healing effects on its enemies, it consumes them and heals itself for 1% for each periodic healing effect consumed."];
        [cMagic setIconName:@"toxic_inversion.png"];
        [cMagic setCooldown:.5];
        [self addAbility:cMagic];
        
        SlimeOrbs *sOrbs = [[[SlimeOrbs alloc] init] autorelease];
        [sOrbs setTitle:@"Overflowing Slime"];
        [sOrbs setInfo:@"Bubbles of slime burst forth.  Healers may pop the bubbles by tapping on them.  Popped bubbles deal less damage for each stack of Engulfing Slime on the target."];
        [sOrbs setIconName:@"pus_burst.png"];
        [sOrbs setCooldown:12.0];
        [sOrbs setCooldownVariance:.25];
        [sOrbs setAbilityValue:200];
        [self addAbility:sOrbs];
        
        AbilityDescriptor *overflowingSlimeEnrage = [[[AbilityDescriptor alloc] init] autorelease];
        [overflowingSlimeEnrage setIconName:@"poison_explosion.png"];
        [overflowingSlimeEnrage setAbilityDescription:[NSString stringWithFormat:@"If there are ever %d bubbles of slime present on the battlefield, The Unspeakable will become empowered", SLIME_REQUIRED_FOR_ENRAGE]];
        [overflowingSlimeEnrage setAbilityName:@"Overcome with Slime"];
        [self addAbilityDescriptor:overflowingSlimeEnrage];
        
    }
}
@end

@implementation BaraghastReborn
- (void)dealloc{
    [_deathwave release];
    [super dealloc];
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1:
        case 2:
        case 3:
        case 4:
            return [super challengeDamageDoneModifier];
        case 5:
            return .45;
        default:
            return 0.0;
    }
}

+ (id)defaultBoss {
    BaraghastReborn *boss = [[BaraghastReborn alloc] initWithHealth:3289000 damage:500 targets:1 frequency:2.25 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Baraghast Reborn"];
    [boss setSpriteName:@"baraghastreborn_battle_portrait.png"];
    
    BaraghastRoar *roar = [[[BaraghastRoar alloc] init] autorelease];
    [roar setCooldown:38.0];
    [roar setAbilityValue:75];
    [roar setCooldownVariance:.2];
    [roar setActivationTime:1.75];
    [roar setInterruptAppliesDot:YES];
    [roar setInfo:@"Interrupts spell casting, dispels all positive spell effects, and deals damage to all enemies.  If a Healer is casting when this ability triggers the Healer suffers damage over time."];
    [roar setKey:@"baraghast-roar"];
    [roar setIconName:@"shadow_roar.png"];
    [roar setTitle:@"Roar of the Damned"];
    [boss addAbility:roar];
    
    boss.deathwave = [[[Deathwave alloc] init] autorelease];
    [boss.deathwave setCooldown:kAbilityRequiresTrigger];
    [boss.deathwave setKey:@"deathwave"];
    [boss addAbility:boss.deathwave ];
    
    return [boss autorelease];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    
    if (self.difficulty <= 3) {
        self.deathwave.abilityValue = 9000;
    }
    
    if (self.difficulty == 5) {
        StackingEnrage *strengthen = [[[StackingEnrage alloc] init] autorelease];
        [strengthen setActivationTime:1.5];
        [strengthen setAbilityValue:20];
        [strengthen setCooldown:kAbilityRequiresTrigger];
        [strengthen setKey:@"strengthen"];
        [strengthen setTitle:@"Strengthen"];
        [self addAbility:strengthen];
        
        SoulCorruptionEffect *sce = [[[SoulCorruptionEffect alloc] initWithDuration:5 andEffectType:EffectTypeNegative] autorelease];
        [sce setHealingToAbsorb:400];
        [sce setTitle:@"soul-corruption-eff"];
        
        Attack *applySoulCorruption = [[[Attack alloc] initWithDamage:0 andCooldown:19.0] autorelease];
        [applySoulCorruption setRequiresDamageToApplyEffect:NO];
        [applySoulCorruption setTitle:@"Soul Corruption"];
        [applySoulCorruption setDodgeChanceAdjustment:-100.0];
        [applySoulCorruption setAttackParticleEffectName:nil];
        [applySoulCorruption setPrefersTargetsWithoutVisibleEffects:YES];
        [applySoulCorruption setFailureChance:0.0];
        [applySoulCorruption setActivationTime:1.5];
        [applySoulCorruption setIconName:@"curse.png"];
        [applySoulCorruption setKey:@"soul-corruption"];
        [applySoulCorruption setInfo:@"Absorbs 400 Healing and increases damage taken by 25%.  When the absorb is broken the healer gains 10% more healing done and all allies gain 10% more maximum health."];
        [applySoulCorruption setAppliedEffect:sce];
        [self addAbility:applySoulCorruption];
    }
}

- (void)ownerDidExecuteAbility:(Ability *)ability {
    if (ability == self.deathwave){
        [self.announcer displayScreenShakeForDuration:1.5];
        for (Ability *ab in self.abilities){
            if (ability != ab) {
                [ab setTimeApplied:0.0];
            }
        }
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta{
    
    if (self.difficulty == 5 && (int)percentage % 10 == 0 && percentage != 100.0) {
        [[self abilityWithKey:@"strengthen"] activateAbility];
    }
    
    if (percentage == 99.0 || percentage == 90.0 || percentage == 10.0){
        [self.deathwave triggerAbilityForRaid:raid players:players enemies:enemies];
    }
    
    if (percentage == 98.0) {
        [self.announcer announce:@"You will all die screaming!"];
    }
    
    if (percentage == 90.0) {
        self.autoAttack.abilityValue = 270;
        [self.announcer announce:@"Weaklings! Kneel before my power."];
        BloodCrush *bloodcrush = [[[BloodCrush alloc] init] autorelease];
        [bloodcrush setKey:@"blood-crush"];
        [bloodcrush setCooldown:40.0];
        [bloodcrush setCooldownVariance:.2];
        [bloodcrush setTimeApplied:24.0];
        [bloodcrush setAbilityValue:950];
        [bloodcrush setTarget:[(FocusedAttack*)self.autoAttack focusTarget]];
        [self addAbility:bloodcrush];
    }
    
    if (percentage == 60.0) {
        [self.announcer announce:@"My power only grows.  Your spirits crumble."];
        DelayedSetHealthEffect *glareEffect = [[[DelayedSetHealthEffect alloc] initWithDuration:7.0 andEffectType:EffectTypeNegative] autorelease];
        [glareEffect setValue:1];
        [glareEffect setTitle:@"glare-effect"];
        
        Attack *glareFromBeyond = [[[Attack alloc] initWithDamage:0 andCooldown:30.0] autorelease];
        [glareFromBeyond setPrefersTargetsWithoutVisibleEffects:YES];
        [glareFromBeyond setExecutionSound:@"bang1.mp3"];
        [glareFromBeyond setIgnoresGuardians:YES];
        [glareFromBeyond setRequiresDamageToApplyEffect:NO];
        [glareFromBeyond setAppliedEffect:glareEffect];
        [glareFromBeyond setIconName:@"disengage.png"];
        [glareFromBeyond setTitle:@"Glare from Beyond"];
        [glareFromBeyond setInfo:@"A horrifying glare that nearly kills any target."];
        [glareFromBeyond setActivationTime:1.5];
        [self addAbility:glareFromBeyond];
    }
    
    if (percentage == 30.0){
        [self.announcer announce:@"I feed on your fear."];
        GraspOfTheDamnedEffect *graspEffect = [[[GraspOfTheDamnedEffect alloc] initWithDuration:8.0 andEffectType:EffectTypeNegative] autorelease];
        [graspEffect setNumOfTicks:6];
        [graspEffect setVisibilityPriority:10];
        [graspEffect setValuePerTick:-50];
        [graspEffect setTitle:@"grasp-of-the-damned-eff"];
        [graspEffect setAilmentType:AilmentCurse];
        GraspOfTheDamned *graspOfTheDamned = [[[GraspOfTheDamned alloc] initWithDamage:0 andCooldown:15.0] autorelease];
        [graspOfTheDamned setRequiresDamageToApplyEffect:NO];
        [graspOfTheDamned setExecutionSound:@"curse.mp3"];
        [graspOfTheDamned setActivationTime:1.5];
        [self addAbility:graspOfTheDamned];
        [graspOfTheDamned setAppliedEffect:graspEffect];
    }
    
    if (percentage == 10.0) {
        [self.announcer announce:@"My rage is unending.  You will not defeat me."];
        BaraghastRoar *roar = (BaraghastRoar*)[self abilityWithKey:@"baraghast-roar"];
        [roar setCooldown:roar.cooldown * .5];
        StackingEnrage *se = [[[StackingEnrage alloc] init] autorelease];
        [se setAbilityValue:5];
        [se setCooldown:roar.cooldown];
        [self addAbility:se];
        [se triggerAbilityForRaid:raid players:players enemies:enemies];
    }
    
    if (percentage == 1.0) {
        [self.announcer announce:@"I AM REBORN!"];
        self.health = self.maximumHealth * .1;
    }
    
}
@end

typedef enum {
    AvatarFire,
    AvatarBlood,
    AvatarShadow
} AvatarFormType;

@implementation AvatarOfTorment1

#define SUBMERGE_KEY @"submerge"
+ (id)defaultBoss {
    AvatarOfTorment1 *boss = [[AvatarOfTorment1 alloc] initWithHealth:2304000 damage:0 targets:0 frequency:0.0 choosesMT:NO];
    [boss setTitle:@"The Avatar of Torment"];
    [boss setNamePlateTitle:@"Torment"];
    [boss setSpriteName:@"avataroftorment_battle_portrait.png"];
    
    AvatarOfTormentSubmerge *submerge = [[AvatarOfTormentSubmerge new] autorelease];
    [submerge setKey:SUBMERGE_KEY];
    [boss addAbility:submerge];
    
    return [boss autorelease];
}

- (void)configureAvatarForFormType:(AvatarFormType)form asEndPhase:(BOOL)isEndPhase
{
    NSString *projectileExecutionSoundName = @"fireball.mp3";
    NSString *projectileExplosionSoundName = @"explosion2.wav";
    NSString *projectileExplosionParticleName = @"fire_explosion.plist";
    NSString *projectileSpriteName = @"fireball.png";
    NSString *tormentInfo = @"Encases an enemy in obsidian causing periodic damage until the prison is broken.  The prison absorbs healing and breaks when it has absorbed too much healing.";
    NSString *tormentIcon = @"obsidian_torment.png";
    NSString *tormentTitle = @"Obsidian Torment";
    
    if (form == AvatarBlood) {
        tormentTitle = @"Sanguine Torment";
        tormentIcon = @"gushing_wound.png";
        tormentInfo = @"Surrounds an ally in horrific gore dealing damage over time and absorbing healing.  Each time the target is healed the healer begins bleeding.";
        projectileExplosionSoundName = @"liquid_impact.mp3";
        projectileExplosionParticleName = @"blood_spurt.plist";
        projectileSpriteName = @"bloodbolt.png";
        
        
        ChannelledRaidProjectileAttack *bloodSpray = [[[ChannelledRaidProjectileAttack alloc] init] autorelease];
        [bloodSpray setTitle:@"Blood Spray"];
        [bloodSpray setIconName:@"blood_bolt.png"];
        [bloodSpray setCooldown: isEndPhase ? 52.5 : 35.0];
        [bloodSpray setAbilityValue:150];
        [bloodSpray setSpriteName:@"bloodbolt.png"];
        [bloodSpray setExplosionParticleName:@"blood_spurt.plist"];
        [bloodSpray setExecutionSound:@"fireball.mp3"];
        [bloodSpray setExplosionSoundName:@"liquid_impact.mp3"];
        [self addAbility:bloodSpray];
    } else if (form == AvatarShadow) {
        tormentTitle = @"Penumbral Torment";
        tormentInfo = @"Surrounds an enemy in shadows dealing damage over time and absorbing healing.  When the target is healed, the healer is cursed doing 5% less healing for 16.0 seconds.";
        tormentIcon = @"shadow_prison.png";
        projectileExplosionParticleName = @"shadow_burst.plist";
        projectileSpriteName = @"shadowbolt.png";
        projectileExplosionSoundName = @"explosion_pulse.wav";
        
        WaveOfTorment *wot = [[[WaveOfTorment alloc] init] autorelease];
        [wot setDodgeChanceAdjustment:-100];
        [wot setIconName:@"deathwave.png"];
        [wot setCooldown: isEndPhase ? 60.0 : 40.0];
        [wot setAbilityValue:75];
        [wot setKey:@"wot"];
        [wot setTitle:@"Waves of Torment"];
        [self addAbility:wot];
    } else {
        
        RainOfFire *rof = [[[RainOfFire alloc] init] autorelease];
        [rof setDodgeChanceAdjustment:-100];
        [rof setTitle:@"Rain of Fire"];
        [rof setIconName:@"fireball.png"];
        [rof setCooldown:isEndPhase ? 40.5 : 27.0];
        [rof setAbilityValue:200];
        [rof setKey:@"rain-of-fire"];
        [self addAbility:rof];
        
    }
    
    ProjectileAttack *projectileAttack = [[[ProjectileAttack alloc] init] autorelease];
    [projectileAttack setExecutionSound:projectileExecutionSoundName];
    [projectileAttack setExplosionSoundName:projectileExplosionSoundName];
    [projectileAttack setSpriteName:projectileSpriteName];
    [projectileAttack setExplosionParticleName:projectileExplosionParticleName];
    [projectileAttack setAbilityValue:300];
    [projectileAttack setCooldown:isEndPhase ? 5.5 : 2.5];
    [self addAbility:projectileAttack];
    
    TormentEffect *tormentEffect = [[[TormentEffect alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
    [tormentEffect setInfiniteDurationTickFrequency:1.5];
    [tormentEffect setValuePerTick:-125];
    [tormentEffect setHealingToAbsorb:600 * self.damageDoneMultiplier];
    
    switch (form) {
        case AvatarBlood:
            [tormentEffect setAppliesBleedRecoil:YES];
            if (self.difficulty == 5) {
                [tormentEffect setAppliesBleedEffect:YES];
                AbilityDescriptor *fear = [[[AbilityDescriptor alloc] init] autorelease];
                [fear setIconName:@"bleeding.png"];
                [fear setAbilityName:@"Fear of Blood"];
                [fear setAbilityDescription:@"Each time Sanguine Torment causes damage the target bleeds for the rest of the encounter."];
                [self addAbilityDescriptor:fear];
            }
            break;
        case AvatarShadow:
            [tormentEffect setAppliesHealingDebuffRecoil:YES];
            if (self.difficulty == 5) {
                [tormentEffect setAppliesHealingReducedEffect:YES];
                AbilityDescriptor *fear = [[[AbilityDescriptor alloc] init] autorelease];
                [fear setIconName:@"toxic_inversion.png"];
                [fear setAbilityName:@"Fear of Darkness"];
                [fear setAbilityDescription:@"Each time Penumbral Torment causes damage the target receives 5% less healing for the rest of the encounter."];
                [self addAbilityDescriptor:fear];
            }
            break;
        case AvatarFire:
            [tormentEffect setIncreasePerTick:.7];
            if (self.difficulty == 5) {
                [tormentEffect setAppliesDamageTakenEffect:YES];
                AbilityDescriptor *fear = [[[AbilityDescriptor alloc] init] autorelease];
                [fear setIconName:@"angry_spirit.png"];
                [fear setAbilityName:@"Fear of Flame"];
                [fear setAbilityDescription:@"Each time Obsidian Torment causes damage the target takes 5% additional damage for the rest of the encounter."];
                [self addAbilityDescriptor:fear];
            }
        default:
            break;
    }
    
    Attack *obsidianTorment = [Attack appliesEffectNonMeleeAttackWithEffect:tormentEffect];
    [obsidianTorment setIgnoresPlayers:YES];
    [obsidianTorment setCooldown:isEndPhase ? 20.0 : 12.0];
    [obsidianTorment setExecutionSound:@"curse.png"];
    [obsidianTorment setTimeApplied:20.0];
    [obsidianTorment setKey:[NSString stringWithFormat:@"torment-%d",form]];
    [obsidianTorment setTitle:tormentTitle];
    [obsidianTorment setInfo:tormentInfo];
    [obsidianTorment setIconName:tormentIcon];
    [self addAbility:obsidianTorment];
}

- (void)clearAbilitiesForSubmerge
{
    NSMutableArray *removeAbilities = [NSMutableArray arrayWithCapacity:2];
    for (Ability *ability in self.abilities) {
        if (![ability.key isEqualToString:SUBMERGE_KEY]) {
            [removeAbilities addObject:ability];
        }
    }
    
    for (Ability *ability in removeAbilities) {
        [self removeAbility:ability];
    }
    
    self.abilityDescriptors = [NSMutableArray array];
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1:
        case 2:
        case 3:
        case 4:
            return [super challengeDamageDoneModifier];
        case 5:
            return .45;
        default:
            return 0.0;
    }
}

- (void)submerge
{
    [[self abilityWithKey:SUBMERGE_KEY] activateAbility];
    [self clearAbilitiesForSubmerge];
}

- (void)emergeForRaid:(Raid*)theRaid
{
    [(AvatarOfTormentSubmerge*)[self abilityWithKey:SUBMERGE_KEY] emergeForRaid:theRaid];
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    if (percentage == 100.0) {
        [self configureAvatarForFormType:AvatarFire asEndPhase:false];
        [self emergeForRaid:raid];
    }
    
    if (percentage == 75.0) {
        [self submerge];
        [self configureAvatarForFormType:AvatarShadow asEndPhase:false];
    }
    
    if (percentage == 50.0) {
        [self submerge];
        [self configureAvatarForFormType:AvatarBlood asEndPhase:false];
    }
    
    if (percentage == 25.0) {
        [self submerge];
        [self configureAvatarForFormType:AvatarBlood asEndPhase:true];
        [self configureAvatarForFormType:AvatarFire asEndPhase:true];
        [self configureAvatarForFormType:AvatarShadow asEndPhase:true];
        self.abilityDescriptors = [NSMutableArray array];
    }
}

@end

@implementation AvatarOfTorment2

+ (id)defaultBoss {
    AvatarOfTorment2 *boss = [[AvatarOfTorment2 alloc] initWithHealth:1320000 damage:0 targets:0 frequency:0.0 choosesMT:NO ];
    [boss setTitle:@"The Avatar of Torment"];
    [boss setNamePlateTitle:@"Torment"];
    [boss setSpriteName:@"avataroftorment_battle_portrait.png"];
    
    DisruptionCloud *dcAbility = [[DisruptionCloud alloc] init];
    [dcAbility setExecutionSound:@"gas_impact.mp3"];
    [dcAbility setKey:@"dis-cloud"];
    [dcAbility setCooldown:23.0];
    [dcAbility setAbilityValue:26];
    [dcAbility setTimeApplied:20.0];
    [boss addAbility:dcAbility];
    [dcAbility release];
    
    ProjectileAttack *projectileAttack = [[ProjectileAttack alloc] init];
    [projectileAttack setExecutionSound:@"fireball.mp3"];
    [projectileAttack setExplosionSoundName:@"explosion_pulse.wav"];
    [projectileAttack setSpriteName:@"shadowbolt.png"];
    [projectileAttack setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack setAbilityValue:-400];
    [projectileAttack setCooldown:.75];
    [projectileAttack setFailureChance:.85];
    [boss addAbility:projectileAttack];
    [projectileAttack release];
    
    ProjectileAttack *projectileAttack2 = [[ProjectileAttack alloc] init];
    [projectileAttack2 setExecutionSound:@"fireball.mp3"];
    [projectileAttack2 setExplosionSoundName:@"explosion2.wav"];
    [projectileAttack2 setSpriteName:@"fireball.png"];
    [projectileAttack2 setExplosionParticleName:@"fire_explosion.plist"];
    [projectileAttack2 setAbilityValue:-400];
    [projectileAttack2 setCooldown:.83];
    [projectileAttack2 setFailureChance:.85];
    [boss addAbility:projectileAttack2];
    [projectileAttack2 release];
    
    ProjectileAttack *projectileAttack3 = [[ProjectileAttack alloc] init];
    [projectileAttack3 setSpriteName:@"bloodbolt.png"];
    [projectileAttack3 setExplosionParticleName:@"blood_spurt.plist"];
    [projectileAttack3 setExecutionSound:@"fireball.mp3"];
    [projectileAttack3 setExplosionSoundName:@"liquid_impact.mp3"];
    [projectileAttack3 setAbilityValue:-320];
    [projectileAttack3 setCooldown:2.5];
    [projectileAttack3 setFailureChance:.2];
    [boss addAbility:projectileAttack3];
    [projectileAttack3 release];
    
    return [boss autorelease];
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1:
        case 2:
        case 3:
        case 4:
            return [super challengeDamageDoneModifier];
        case 5:
            return .45;
        default:
            return 0.0;
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    if (percentage == 99.0 || percentage == 95.0) {
        
        WaveOfTorment *wot = [[[WaveOfTorment alloc] init] autorelease];
        [wot setIconName:@"deathwave.png"];
        [wot setCooldown:40.0];
        [wot setAbilityValue:80];
        [wot setKey:@"wot"];
        [wot setTitle:@"Waves of Torment"];
        [self addAbility:wot];
        [wot triggerAbilityForRaid:raid players:players enemies:enemies];
        if (percentage == 95.0) {
            [self removeAbility:wot]; //Dont add 2 copies of this ability for the second trigger
        } else {
            [self.announcer announce:@"The Avatar of Torment erupts power!"];
        }
    }
    if (percentage == 50.0) {
        [self.announcer announce:@"You feel Anguish cloud your mind..."];
        Confusion *confusionAbility = [[[Confusion alloc] init] autorelease];
        [confusionAbility setExecutionSound:@"cackling_demons.mp3"];
        [confusionAbility setCooldown:14.0];
        [confusionAbility setAbilityValue:7.0];
        [confusionAbility setKey:@"confusion"];
        [self addAbility:confusionAbility];
        [confusionAbility setTimeApplied:10.0];
    }
    
    if (percentage == 20.0) {
        [self.announcer announce:@"The Avatar begins growing stronger."];
        StackingEnrage *se = [[[StackingEnrage alloc] init] autorelease];
        [se setAbilityValue:10];
        [se setCooldown:10];
        [self addAbility:se];
        [se triggerAbilityForRaid:raid players:players enemies:enemies];
    }
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    if (difficulty == 5) {
        PercentageDamageTimeBasedEffect *deathsDoorEffect = [[[PercentageDamageTimeBasedEffect alloc] initWithDuration:10 andEffectType:EffectTypeNegative] autorelease];
        [deathsDoorEffect setTitle:@"deaths-door"];
        
        Attack *deathsDoor = [Attack appliesEffectNonMeleeAttackWithEffect:deathsDoorEffect];
        [deathsDoor setCooldown:20.0];
        [deathsDoor setIconName:@"blind.png"];
        [deathsDoor setTitle:@"Death's Door"];
        [deathsDoor setInfo:@"Applies a curse that deals 150% of the target's maximum health in damage when it ends.  If it is purified, the target takes damage equal to the time remaining."];
        [self addAbility:deathsDoor];
        
        ManaDrain *manaDrain = [[[ManaDrain alloc] init] autorelease];
        [manaDrain setInfo:@"The Avatar draws all mana from the Healers into orbs on the battlefield that last for a short time before dispersing."];
        [manaDrain setTitle:@"Mana Drain"];
        [manaDrain setIconName:@"corrupt_mind.png"];
        [manaDrain setCooldown:40.0];
        [manaDrain setTimeApplied:25.0];
        [manaDrain setCooldownVariance:.33];
        [self addAbility:manaDrain];
    }
}
@end

@implementation SoulOfTorment
+ (id)defaultBoss {
    SoulOfTorment *boss = [[SoulOfTorment alloc] initWithHealth:5400000 damage:0 targets:0 frequency:0.0 choosesMT:NO];
    [boss setSpriteName:@"souloftorment_battle_portrait.png"];
    [boss setTitle:@"The Soul of Torment"];
    [boss setNamePlateTitle:@"Torment"];
    
    [boss gainSoulDrain];
    
    return [boss autorelease];
}

- (void)ownerDidDamageTarget:(RaidMember *)target withAbility:(Ability *)ability forDamage:(NSInteger)damage
{
    if (self.difficulty == 5) {
        if (target.health - damage > target.maximumHealth * .5 && target.health < target.maximumHealth * .5)
        {
            [self.announcer announce:@"Torment grows..."];
            Effect *enrage = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositive] autorelease];
            [enrage setDamageDoneMultiplierAdjustment:.02];
            [enrage setMaxStacks:99];
            [enrage setTitle:@"sot-enrage-stack"];
            [self addEffect:enrage];
            
            if (!self.hasAddedGrowingTorment) {
                self.hasAddedGrowingTorment = YES;
                
                AbilityDescriptor *growingTorment = [[[AbilityDescriptor alloc] init] autorelease];
                [growingTorment setAbilityDescription:@"Whenever the Soul of Torment reduces an ally's health below 50%, The Soul deals 2% additional damage for the rest of the battle."];
                [growingTorment setAbilityName:@"Absorb Torment"];
                [growingTorment setIconName:@"temper.png"];
                [growingTorment setMonitoredEffect:enrage];
                [self addAbilityDescriptor:growingTorment];
            }
        }
    }
}

- (void)ownerDidDamageTarget:(RaidMember*)target withEffect:(Effect*)effect forDamage:(NSInteger)damage
{
    [self ownerDidDamageTarget:target withAbility:nil forDamage:damage];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
}

- (float)challengeDamageDoneModifier
{
    switch (self.difficulty) {
        case 1:
        case 2:
        case 3:
        case 4:
            return [super challengeDamageDoneModifier];
        case 5:
            return .45;
        default:
            return 0.0;
    }
}

- (void)gainSoulDrain
{
    [self.announcer announce:@"The Soul of Torment hungers for souls"];

    StackingRHEDispelsOnHeal *soulDrainEffect = [[[StackingRHEDispelsOnHeal alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
    [soulDrainEffect setMaxStacks:25];
    [soulDrainEffect setValuePerTick:-14];
    [soulDrainEffect setNumOfTicks:10];
    [soulDrainEffect setVisibilityPriority:1];
    [soulDrainEffect setSpriteName:@"curse.png"];
    [soulDrainEffect setTitle:@"soul-drain-eff"];
    
    EnsureEffectActiveAbility *eeaa = [[[EnsureEffectActiveAbility alloc] init] autorelease];
    [eeaa setKey:@"soul-drain"];
    [eeaa setTitle:@"Soul Drain"];
    [eeaa setIconName:@"curse.png"];
    [eeaa setEnsuredEffect:soulDrainEffect];
    [self addAbility:eeaa];
}

- (void)raidDamageToRaid:(Raid*)raid forPlayers:(NSArray*)players
{
    [self.announcer playAudioForTitle:@"cackling_demons.mp3"];
    for (RaidMember *member in raid.livingMembers) {
        RepeatedHealthEffect *damage = [[[RepeatedHealthEffect alloc] initWithDuration:10.0 andEffectType:EffectTypeNegativeInvisible] autorelease];
        [damage setNumOfTicks:8];
        [damage setOwner:self];
        [damage setTitle:@"gather-souls"];
        [damage setValuePerTick:-45];
        [member addEffect:damage];
        [self.announcer displayParticleSystemWithName:@"skull_float.plist" onTarget:member];
    }
}

- (void)healthPercentageReached:(float)percentage forPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    
    if (self.difficulty == 5) {
    }
    
    if (percentage == 99.0 || percentage == 95.0 || percentage == 90.0 || percentage == 85.0 || percentage == 45.0 || percentage == 37.0 || percentage == 28.0 || percentage == 20.0) {
        [self raidDamageToRaid:raid forPlayers:players];
    }
    
    if (percentage == 85.0) {
        [self.announcer announce:@"You will beg for death."];
        [self gainSoulDrain];
        Soulshatter *ss = [[[Soulshatter alloc] init] autorelease];
        [ss setKey:@"soulshatter"];
        [ss setCooldown:35];
        [ss setTimeApplied:30.0];
        [ss setCooldownVariance:.8];
        [self addAbility:ss];
    }

    if (percentage == 70.0) {
        [[self abilityWithKey:@"soulshatter"] setIsDisabled:YES];
        [self.announcer announce:@"I shall feast on your anguish"];
        
        ScentOfDeath *scent = [[[ScentOfDeath alloc] init] autorelease];
        [scent setAbilityValue:300];
        [scent setActivationTime:3.0];
        [scent setCooldownVariance:.8];
        [scent setKey:@"scent"];
        [scent setCooldown:14.0];
        [self addAbility:scent];
        
        Attack *attack = [[[Attack alloc] initWithDamage:120 andCooldown:26] autorelease];
        ContagiousEffect *contagious = [[[ContagiousEffect alloc] initWithDuration:10.0 andEffectType:EffectTypeNegative] autorelease];
        [contagious setTitle:@"contagion"];
        [contagious setNumOfTicks:10];
        [contagious setVisibilityPriority:16];
        [contagious setValuePerTick:-20];
        [contagious setAilmentType:AilmentPoison];
        [attack setIconName:@"plague.png"];
        [attack setExecutionSound:@"slimeimpact.mp3"];
        [attack setTitle:@"Contagious Toxin"];
        [attack setInfo:@"Plagues a target. If the target's is healed before the effect reaches 5 stacks it will spread to others."];
        [attack setKey:@"contagious"];
        [attack setRemovesPositiveEffects:YES];
        [attack setAppliedEffect:contagious];
        [attack setRequiresDamageToApplyEffect:NO];
        [attack setPrefersTargetsWithoutVisibleEffects:YES];
        [self addAbility:attack];
    }
    
    if (percentage == 50.0) {
        [[self abilityWithKey:@"contagious"] setIsDisabled:YES];
        [[self abilityWithKey:@"scent"] setIsDisabled:YES];
        [self.announcer announce:@"ENOUGH! YOU SHALL KNOW TRUE TORMENT."];
        for (RaidMember *member in raid.livingMembers) {
            [member removeEffectsWithTitle:@"soul-drain"];
        }
        for (Ability *ability in self.abilities) {
            if ([ability.key isEqualToString:@"soul-drain"]){
                [ability setIsDisabled:YES];
            }
        }
        
        float damageReduction = .8;
        if (self.difficulty == 5) {
            damageReduction = .99;
        }
        
        SpiritBarrier *barrier = [[[SpiritBarrier alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
        [barrier setTitle:@"spirit-barrier"];
        [barrier setValuePerTick:-20];
        [barrier setNumOfTicks:20];
        [barrier setHealingToAbsorb:400];
        [barrier setVisibilityPriority:16];
        [barrier setDamageReduction:damageReduction];
        
        Attack *spiritBlock = [Attack appliesEffectNonMeleeAttackWithEffect:barrier];
        [spiritBlock setCooldown:40.0];
        [spiritBlock setExecutionSound:@"curse.png"];
        [spiritBlock setTimeApplied:20.0];
        [spiritBlock setKey:@"spirit-barrier"];
        [spiritBlock setTitle:@"Spirit Barrier"];
        [spiritBlock setInfo:[NSString stringWithFormat:@"Hex's a player absorbing the next 400 healing cast on them.  When this absorption is depleted the barrier erupts reducing damage taken for all units by %1.0f.", damageReduction]];
        [spiritBlock setIconName:@"hex.png"];
        [self addAbility:spiritBlock];
        
        NSInteger cataclysmDamage = 1800;
        
        if (self.difficulty == 1) {
            cataclysmDamage = 1200;
        }
        
        RaidDamage *cataclysm = [[[RaidDamage alloc] init] autorelease];
        [cataclysm setExecutionSound:@"gasexplosion.png"];
        [cataclysm setKey:@"cataclysm"];
        [cataclysm setCooldown:35.0];
        [cataclysm setActivationTime:8.0];
        [cataclysm setAbilityValue:cataclysmDamage];
        [cataclysm setAttackParticleEffectName:nil];
        [cataclysm setTitle:@"Cataclysm"];
        [cataclysm setIconName:@"choking_cloud.png"];
        [self addAbility:cataclysm];
        
        FocusedAttack *focusedAttack = [[[FocusedAttack alloc] initWithDamage:550 andCooldown:2.25] autorelease];
        [focusedAttack setFailureChance:.4];
        RepeatedHealthEffect *bleeding = [[[RepeatedHealthEffect alloc] initWithDuration:8.0 andEffectType:EffectTypeNegative] autorelease];
        [focusedAttack setIconName:@"bleeding.png"];
        [bleeding setTitle:@"soul-bleed"];
        [bleeding setSpriteName:@"bleeding.png"];
        [bleeding setDodgeChanceAdjustment:.1];
        [bleeding setMaxStacks:5];
        [bleeding setValuePerTick:-50];
        [bleeding setNumOfTicks:4];
        [focusedAttack setAppliedEffect:bleeding];
        [self addAbility:focusedAttack];
    }
    
    if (percentage == 20.0) {
        [[self abilityWithKey:@"unending-torment"] setCooldown:20];
        [[self abilityWithKey:@"cataclysm"] setIsDisabled:YES];
        [[self abilityWithKey:@"spirit-barrier"] setIsDisabled:YES];
        for (Ability *ability in self.abilities) {
            if ([ability.key isEqualToString:@"soul-drain"]){
                [ability setIsDisabled:NO];
            }
        }
        [self.announcer announce:@"The Soul of Torment poisons your mind and clouds your vision."];
        Confusion *confusionAbility = [[[Confusion alloc] init] autorelease];
        [confusionAbility setExecutionSound:@"cackling_demons.mp3"];
        [confusionAbility setCooldown:14.0];
        [confusionAbility setAbilityValue:8.0];
        [confusionAbility setKey:@"confusion"];
        [self addAbility:confusionAbility];
        [confusionAbility setTimeApplied:10.0];
    }
    
    if (percentage == 10.0) {
        [self.announcer announce:@"YOUR SOULS WILL ANGUISH ALONE IN DARKNESS"];
    }
    
    if (percentage == 1.0) {
        [self.announcer announce:@"NO...NO...IT CANNOT BE...I CAN NOT BE DEFEATED!"];
    }
}

- (void)ownerDidExecuteAbility:(Ability *)ability
{
    if ([ability.key isEqualToString:@"cataclysm"]) {
        [self.announcer displayParticleSystemOnRaidWithName:@"shadow_raid_burst.plist" delay:0];
        [self.announcer displayScreenShakeForDuration:1.5];
    }
}
@end

@implementation TheEndlessVoid

- (void)setHealth:(NSInteger)newHealth {
    if (self.healthPercentage > .5){
        [super setHealth:newHealth];
    }
}

+(id)defaultBoss {
    TheEndlessVoid *endlessVoid = [[TheEndlessVoid alloc] initWithHealth:99999999 damage:400 targets:4 frequency:2.0 choosesMT:NO];
    [endlessVoid setTitle:@"The Endless Void"];
    endlessVoid.autoAttack.failureChance = .25;
    
    StackingDamage *damageStacker = [[StackingDamage alloc] init];
    [damageStacker setAbilityValue:1];
    [damageStacker setCooldown:30];
    [endlessVoid addAbility:damageStacker];
    [damageStacker release];
    
    RandomAbilityGenerator *rag = [[RandomAbilityGenerator alloc] init];
    [rag setCooldown:60];
    [rag setTimeApplied:55.0];
    [rag setKey:@"random-abilities"];
    [endlessVoid addAbility:rag];
    [rag release];
    
     return [endlessVoid autorelease];
}
@end


@implementation TestBoss
+(id)defaultBoss {
    TestBoss *testBoss = [[TestBoss alloc] initWithHealth:99999999 damage:400 targets:4 frequency:2.0 choosesMT:NO];
    [testBoss setTitle:@"Test Boss"];
    testBoss.autoAttack.failureChance = .25;
    
    StackingDamage *damageStacker = [[StackingDamage alloc] init];
    [damageStacker setAbilityValue:1];
    [damageStacker setCooldown:30];
    [testBoss addAbility:damageStacker];
    [damageStacker release];
    
    RandomAbilityGenerator *rag = [[RandomAbilityGenerator alloc] init];
    [rag setCooldown:60];
    [rag setTimeApplied:55.0];
    [rag setKey:@"random-abilities"];
    [testBoss addAbility:rag];
    [rag release];
    
    return [testBoss autorelease];
}
@end
//
//  Boss.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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

-(void)dealloc{
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
            challengeMultiplier = 1.3;
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

- (void)ownerWillExecuteAbility:(Ability *)ability {
    
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

-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses {
    if (self = [super init]){
        self.maximumHealth = hlth;
        self.health = hlth;
        self.title = @"";
        self.criticalChance = 0.0;
        self.abilities = [NSMutableArray arrayWithCapacity:5];
        self.abilityDescriptors = [NSMutableArray arrayWithCapacity:5];
        for (int i = 0; i < 101; i++){
            healthThresholdCrossed[i] = NO;
        }
        self.isMultiplayer = NO;
        
        for (int i = 0; i < trgets; i++){
            if (chooses && i == 0){
                FocusedAttack *focusedAttack = [[[FocusedAttack alloc] initWithDamage:dmg/trgets andCooldown:freq] autorelease];
                [self addAbility:focusedAttack];
                self.autoAttack = focusedAttack;
            }else{
                Attack *attack = [[Attack alloc] initWithDamage:dmg/trgets andCooldown:freq];
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


-(void)healthPercentageReached:(float)percentage withRaid:(Raid*)raid andPlayer:(Player*)player{
    //The main entry point for health based triggers
}

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta
{
    Player *player = [players objectAtIndex:0]; //The first player is the local player
    for (int i = 100; i >= (int)self.healthPercentage; i--){
        if (!healthThresholdCrossed[i] && self.healthPercentage <= (float)i){
            [self healthPercentageReached:i withRaid:raid andPlayer:player];
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

+(id)defaultBoss
{
	return nil;
}

-(NSString*)sourceName{
    return self.title;
}
-(NSString*)targetName{
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
    Ghoul *ghoul = [[Ghoul alloc] initWithHealth:150000
                                          damage:300 targets:1 frequency:2.0 choosesMT:NO ];
    [ghoul setTitle:@"Ghoul"];
    [ghoul setSpriteName:@"ghoul_battle_portrait.png"];
    
    ghoul.autoAttack.dodgeChanceAdjustment = -100.0;
    
    RepeatedHealthEffect *plagueDot = [[[RepeatedHealthEffect alloc] initWithDuration:12 andEffectType:EffectTypeNegative] autorelease];
    [plagueDot setTitle:@"plague-dot"];
    [plagueDot setValuePerTick:-100];
    [plagueDot setNumOfTicks:4];
    
    Attack *plagueStrike = [[[Attack alloc] initWithDamage:100 andCooldown:30.0] autorelease];
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
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 75.0){
        [self.announcer announce:@"A putrid limb falls from the ghoul..."];
        self.autoAttack.abilityValue *= .9;
    }
    
    if (percentage == 50.0){
        [self.announcer announce:@"The ghoul begins to crumble."];
        self.autoAttack.abilityValue *= .9;
    }
    
    if (percentage == 25.0){
        [self.announcer announce:@"The nearly lifeless ghoul shrieks in agony.."];
        self.autoAttack.abilityValue *= .8;
    }
}
@end

@implementation CorruptedTroll

+(id)defaultBoss{
    NSInteger health = 185000;
    NSInteger damage = 350;
    NSTimeInterval freq = 2.25;
    
    CorruptedTroll *corTroll = [[CorruptedTroll alloc] initWithHealth:health damage:damage targets:1 frequency:freq choosesMT:YES ];
    corTroll.autoAttack.failureChance = .1;
    [corTroll setSpriteName:@"troll_battle_portrait.png"];
    
    [corTroll setTitle:@"Corrupted Troll"];
    
    [corTroll addAbility:[Cleave normalCleave]];
    
    GroundSmash *groundSmash = [[[GroundSmash alloc] init] autorelease];
    [groundSmash setAbilityValue:54];
    [groundSmash setKey:@"troll-cave-in"];
    [groundSmash setCooldown:30.0];
    [groundSmash setActivationTime:1.0];
    [groundSmash setTimeApplied:20.0];
    [groundSmash setTitle:@"Ground Smash"];
    [groundSmash setInfo:@"The Corrupted Troll will smash the ground repeatedly causing damage to all allies."];
    corTroll.smash = groundSmash;
    [corTroll addAbility:corTroll.smash];
    
    ChannelledEnemyAttackAdjustment *frenzy = [[[ChannelledEnemyAttackAdjustment alloc] init] autorelease];
    [frenzy setCooldown:kAbilityRequiresTrigger];
    [frenzy setKey:@"frenzy"];
    [frenzy setTitle:@"Frenzy"];
    [frenzy setInfo:@"Occasionally, the Corrupted Troll will attack his Focused target furiously dealing high damage."];
    [frenzy setAttackSpeedMultiplier:.25];
    [frenzy setDamageMultiplier:.5];
    [frenzy setDuration:9.0];
    [corTroll addAbility:frenzy];
    
    
    return  [corTroll autorelease];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty {
    [super configureBossForDifficultyLevel:difficulty];
        
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

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
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
    drake.fireballAbility.activationTime = 1.5;
    [drake.fireballAbility setIconName:@"burning.png"];
    [drake.fireballAbility setKey:@"fireball-ab"];
    [(ProjectileAttack*)drake.fireballAbility setSpriteName:@"fireball.png"];
    [drake.fireballAbility setAbilityValue:fireballDamage];
    [drake.fireballAbility setFailureChance:fireballFailureChance];
    [drake.fireballAbility setCooldown:fireballCooldown];
    [drake addAbility:drake.fireballAbility];
    
    FlameBreath *fb = [[[FlameBreath alloc] init] autorelease];
    [fb setTitle:@"Flame Breath"];
    [fb setKey:@"flame-breath"];
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
        Effect *improvedDamageEffect = [[[Effect alloc] initWithDuration:7 andEffectType:EffectTypeNegative] autorelease];
        [improvedDamageEffect setSpriteName:@"soul_burn.png"];
        [improvedDamageEffect setTitle:@"imprvd-dmg-fireball"];
        [improvedDamageEffect setMaxStacks:3];
        [improvedDamageEffect setDamageTakenMultiplierAdjustment:.2];
        [(ProjectileAttack*)self.fireballAbility setAppliedEffect:improvedDamageEffect];
        
        [self.fireballAbility setInfo:@"The drake spits fireballs that also cause the target's armor to be ignited increasing damage taken from further fireballs by 20% per stack."];
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    
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
    [rpt setCooldown:11.0];
    [rpt setActivationTime:1.5];
    [boss addAbility:rpt];
    
    [boss setTitle:@"Mischievious Imps"];
    return [boss autorelease];
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 99.0){
        RandomPotionToss *potionAbility = (RandomPotionToss*)[self abilityWithKey:@"potions"];
        [potionAbility triggerAbilityAtRaid:raid];
        [self.announcer announce:@"An imp angrily hurls the entire case of flasks at you!"];
        
        [potionAbility setActivationTime:potionAbility.activationTime / 2];
        [potionAbility setCooldown:potionAbility.cooldown / 2];
    }
    
    if (percentage == 25.0){
        [[self abilityWithKey:@"potions"] setIsDisabled:YES];
        [self.announcer announce:@"The imp begins attacking angrily!"];
        self.autoAttack.isDisabled = YES;
        
        Ability *attackAngrily = [[[Ability alloc] init] autorelease];
        [attackAngrily setTitle:@"Frenzied Attacking"];
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
    [branchAttack setTitle:@"Viscious Branches"];
    [branchAttack setKey:@"branch-attack"];
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

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
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

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    
    if (percentage == 100.0){
        [self.announcer announce:@"A putrid green mist fills the area..."];
        [self.announcer displayParticleSystemOnRaidWithName:@"green_mist.plist" forDuration:-1.0];
        for (RaidMember *member in raid.raidMembers){
            RepeatedHealthEffect *rhe = [[RepeatedHealthEffect alloc] initWithDuration:-1.0 andEffectType:EffectTypeNegativeInvisible];
            [rhe setOwner:self];
            [rhe setTitle:@"fungal-ravager-mist"];
            [rhe setValuePerTick:-(arc4random() % 10 + 5)];
            [member addEffect:rhe];
            [rhe release];
        }
    }
    
    if (percentage == 99.0){
        [self.announcer announce:@"The final Ravager glows with rage."];
        AbilityDescriptor *rage = [[[AbilityDescriptor alloc] init] autorelease];
        [rage setAbilityDescription:@"The Fungal Ravager is enraged."];
        [rage setIconName:@"ravager_remaining.png"];
        [rage setAbilityName:@"Rage"];
        [self addAbilityDescriptor:rage];
        Effect *enragedEffect = [[Effect alloc] initWithDuration:300 andEffectType:EffectTypePositiveInvisible];
        [enragedEffect setIsIndependent:YES];
        [enragedEffect setTarget:self];
        [enragedEffect setOwner:self];
        [enragedEffect setDamageDoneMultiplierAdjustment:1.25];
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
    [focus setIsFocused:NO];
    
    NSInteger numTargets = arc4random() % 3 + 2;
    
    NSArray *members = [raid randomTargets:numTargets withPositioning:Any];
    for (RaidMember *member in members){
        NSInteger damage = arc4random() % 300 + 450;
        RepeatedHealthEffect *damageEffect = [[[RepeatedHealthEffect alloc] initWithDuration:2.5 andEffectType:EffectTypeNegative] autorelease];
        [damageEffect setAilmentType:AilmentPoison];
        [damageEffect setSpriteName:@"poison.png"];
        [damageEffect setNumOfTicks:3];
        [damageEffect setValuePerTick:-damage / 3];
        [damageEffect setOwner:self];
        [damageEffect setTitle:@"ravager-explo"];
        [member addEffect:damageEffect];
    }
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player
{
    if (percentage == 1.0) {
        [self ravagerDiedFocusing:[(FocusedAttack*)self.autoAttack focusTarget] andRaid:raid];
    }
}

@end

@implementation PlaguebringerColossus
+(id)defaultBoss {
    //427500
    PlaguebringerColossus *boss = [[PlaguebringerColossus alloc] initWithHealth:560000 damage:330 targets:1 frequency:2.5 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Plaguebringer Colossus"];
    [boss setSpriteName:@"plaguebringer_battle_portrait.png"];
    
    AbilityDescriptor *pusExploDesc = [[AbilityDescriptor alloc] init];
    [pusExploDesc setAbilityDescription:@"When your allies deal enough damage to the Plaguebringer Colossus to break off a section of its body the section explodes vile toxin dealing high damage to your raid."];
    [pusExploDesc setIconName:@"pus_burst.png"];
    [pusExploDesc setAbilityName:@"Limb Bomb"];
    [boss addAbilityDescriptor:pusExploDesc];
    [pusExploDesc release];
    
    [boss addAbility:[Cleave normalCleave]];
    
    PlaguebringerSicken *sicken = [[[PlaguebringerSicken alloc] init] autorelease];
    [sicken setInfo:@"The Colossus will sicken targets causing them to take damage until they are healed to full health."];
    [sicken setKey:@"sicken"];
    [sicken setIconName:@"bleeding.png"];
    [sicken setTitle:@"Sicken"];
    [sicken setActivationTime:2.5];
    [sicken setAbilityValue:100];
    [sicken setCooldown:13.0];
    [boss addAbility:sicken];
    return [boss autorelease];
}

-(void)burstPussBubbleOnRaid:(Raid*)theRaid{
    [self.announcer announce:@"A putrid sac of filth bursts onto your allies"];
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

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (((int)percentage) % 20 == 0 && percentage != 100){
        [self burstPussBubbleOnRaid:raid];
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
    
    AbilityDescriptor *poison = [[AbilityDescriptor alloc] init];
    [poison setAbilityDescription:@"Trulzar fills an allies veins with poison dealing increasing damage over time.  This effect may be removed with the Purify spell."];
    [poison setIconName:@"unknown_ability.png"];
    [poison setAbilityName:@"Necrotic Venom"];
    [boss addAbilityDescriptor:poison];
    [poison release];
    
    TrulzarPoison *poisonEffect = [[[TrulzarPoison alloc] initWithDuration:24 andEffectType:EffectTypeNegative] autorelease];
    [poisonEffect setAilmentType:AilmentPoison];
    [poisonEffect setSpriteName:@"poison.png"];
    [poisonEffect setValuePerTick:-120];
    [poisonEffect setNumOfTicks:30];
    [poisonEffect setTitle:@"trulzar-poison1"];
    
    Attack *poisonAttack = [[[Attack alloc] initWithDamage:100 andCooldown:10] autorelease];
    [poisonAttack setAttackParticleEffectName:@"poison_cloud.plist"];
    [poisonAttack setKey:@"poison-attack"];
    [poisonAttack setTitle:@"Inject Poison"];
    [poisonAttack setCooldown:9.0];
    [poisonAttack setActivationTime:2.0];
    [poisonAttack setAppliedEffect:poisonEffect];
    [boss addAbility:poisonAttack];
    
    ProjectileAttack *potionThrow = [[[ProjectileAttack alloc] init] autorelease];
    [potionThrow setTitle:@"Toxic Vial"];
    [potionThrow setKey:@"potion-throw"];
    [potionThrow setCooldown:8.0];
    [potionThrow setSpriteName:@"potion.png"];
    [potionThrow setActivationTime:1.0];
    [potionThrow setExplosionParticleName:@"poison_cloud.plist"];
    [potionThrow setEffectType:ProjectileEffectTypeThrow];
    [potionThrow setAbilityValue:450];
    [potionThrow setProjectileColor:ccGREEN];
    [boss addAbility:potionThrow];
    
    RaidDamagePulse *pulse = [[[RaidDamagePulse alloc] init] autorelease];
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

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (((int)percentage) == 7){
        [self.announcer announce:@"Trulzar cackles as the room fills with noxious poison."];
        [self.announcer displayParticleSystemOnRaidWithName:@"poison_raid_burst.plist" delay:0.0];
        [self.poisonNova setIsDisabled:YES];
        [[self abilityWithKey:@"poison-attack"] setIsDisabled:YES];
        for (RaidMember *member in raid.livingMembers){
            [self applyWeakPoisonToTarget:member];
        }
    }
}

- (void)ownerDidExecuteAbility:(Ability *)ability
{
    if (ability == self.poisonNova) {
        RaidDamagePulse *pulse = (RaidDamagePulse*)ability;
        NSTimeInterval tickTime = pulse.duration / pulse.numTicks;
        for (int i = 0; i < pulse.numTicks; i++) {
            [self.announcer displayParticleSystemOnRaidWithName:@"poison_raid_burst.plist" delay:(tickTime * (i + 1))];
        }
        
    }
    if ([ability.key isEqualToString:@"poison-attack"]) {
        [self.announcer announce:@"Trulzar fills an ally with poison."];
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

@end

@implementation Grimgon

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if (percentage == 99.0) {
        self.inactive = NO;
        [self.announcer announce:@"Grimgon chuckles at Galcyon's failure and steps forward."];
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
        [grimgonBolts setCooldown:7.5];
        [grimgonBolts setTimeApplied:5.0];
        [grimgonBolts setAttacksPerTrigger:2];
        [grimgonBolts setActivationTime:1.5];
        [grimgonBolts setExplosionParticleName:@"poison_cloud.plist"];
        [grimgonBolts setSpriteName:@"green_fireball.png"];
        [grimgonBolts setAbilityValue:325];
        [grimgonBolts setAppliedEffect:poisonDoT];
        [grimgonBolts setInfo:@"Vile poison bolts that cause the targets to have healing done to them reduced by 50%."];
        [grimgonBolts setTitle:@"Bolts of Malediction"];
        [self addAbility:grimgonBolts];
        
        DarkCloud *dc = [[[DarkCloud alloc] init] autorelease];
        [dc setKey:@"dark-cloud"];
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

@end

@implementation Teritha
- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if (percentage == 99.0) {
        self.inactive = NO;
        [self.announcer announce:@"Teritha shouts, \"These pitiful fools are worthless.  I will finish you myself!\""];
    }
    
    if (percentage == 50.0) {
        [self.announcer announce:@"Such Insolent Creatures! Embrace your demise!"];
        ProjectileAttack *bolts = (ProjectileAttack*)[self abilityWithKey:@"teritha-bolts"];
        [bolts setTimeApplied:-5.0];
        [bolts fireAtRaid:raid];
        [bolts setAttacksPerTrigger:5];
    }
    
    if (percentage == 25.0) {
        [self.announcer announce:@"I am darkness.  I AM YOUR DOOM!"];
        ProjectileAttack *bolts = (ProjectileAttack*)[self abilityWithKey:@"teritha-bolts"];
        [bolts setTimeApplied:-5.0];
        [bolts fireAtRaid:raid];
        [bolts setAttacksPerTrigger:6];
    }
}

- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses
{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq choosesMT:chooses]) {
        self.spriteName = @"council3_battle_portrait.png";
        
        WrackingPainEffect *wpe = [[[WrackingPainEffect alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
        [wpe setValuePerTick:-100];
        [wpe setAilmentType:AilmentCurse];
        
        RaidApplyEffect *wrackingPain = [[[RaidApplyEffect alloc] init] autorelease];
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
        [bolts setKey:@"teritha-bolts"];
        [bolts setCooldown:7.5];
        [bolts setTimeApplied:0.0];
        [bolts setAttacksPerTrigger:3];
        [bolts setActivationTime:1.5];
        [bolts setExplosionParticleName:@"shadow_burst.plist"];
        [bolts setSpriteName:@"purple_fireball.png"];
        [bolts setAbilityValue:225];
        [bolts setTitle:@"Bolts of Darkness"];
        [self addAbility:bolts];
    }
    return self;
}
@end

@implementation Sarroth

-(void)axeSweepThroughRaid:(Raid*)theRaid{
    self.autoAttack.timeApplied = -7.0;
    //Set all the other abilities to be on a long cooldown...
    [[self abilityWithKey:@"axe-sweep"] triggerAbilityForRaid:theRaid players:[NSArray array] enemies:[NSArray array]];
    [self.announcer announce:@"Sarroth sweeps through your allies with spinning blades"];
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 80.0 || percentage == 60.0 || percentage == 40.0 || percentage == 20.0){
        [self axeSweepThroughRaid:raid];
    }
}

- (id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses
{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq choosesMT:chooses]) {
        self.spriteName = @"twinchampions_battle_portrait.png";
        
        RaidDamageSweep *rds = [[[RaidDamageSweep alloc] init] autorelease];
        [rds setAbilityValue:250];
        [rds setTitle:@"Sweeping Death"];
        [rds setKey:@"axe-sweep"];
        [rds setCooldown:kAbilityRequiresTrigger];
        [self addAbility:rds];
        
        IntensifyingRepeatedHealthEffect *gushingWoundEffect = [[[IntensifyingRepeatedHealthEffect alloc] initWithDuration:9.0 andEffectType:EffectTypeNegative] autorelease];
        [gushingWoundEffect setSpriteName:@"bleeding.png"];
        [gushingWoundEffect setAilmentType:AilmentTrauma];
        [gushingWoundEffect setIncreasePerTick:.5];
        [gushingWoundEffect setValuePerTick:-230];
        [gushingWoundEffect setNumOfTicks:3];
        [gushingWoundEffect setTitle:@"gushingwound"];
        
        ProjectileAttack *gushingWound = [[[ProjectileAttack alloc] init] autorelease];
        [gushingWound setIgnoresGuardians:YES];
        [gushingWound setKey:@"gushing-wound"];
        [gushingWound setExplosionParticleName:@"blood_spurt.plist"];
        [gushingWound setTitle:@"Deadly Throw"];
        [gushingWound setCooldown:17.0];
        [gushingWound setActivationTime:1.5];
        [gushingWound setEffectType:ProjectileEffectTypeThrow];
        [gushingWound setIconName:@"gushing_wound.png"];
        [gushingWound setSpriteName:@"sword_champion.png"];
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
        
        [self addAbility:[Cleave normalCleave]];
        
        ExecutionEffect *executionEffect = [[[ExecutionEffect alloc] initWithDuration:3.75 andEffectType:EffectTypeNegative] autorelease];
        [executionEffect setValue:-2000];
        [executionEffect setSpriteName:@"execution.png"];
        [executionEffect setEffectivePercentage:.5];
        [executionEffect setAilmentType:AilmentTrauma];
        
        Attack *executionAttack = [[[Attack alloc] init] autorelease];
        [executionAttack setInfo:@"The Twin Champions will  choose a target for execution.  This target will be instantly slain if not above 50% health when the deathblow lands."];
        [executionAttack setTitle:@"Execution"];
        [executionAttack setIconName:@"temper.png"];
        [executionAttack setRequiresDamageToApplyEffect:NO];
        [executionAttack setIgnoresGuardians:YES];
        [executionAttack setKey:@"execution"];
        [executionAttack setCooldown:30];
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

@end

@implementation Baraghast
- (void)dealloc {
    [_remainingAbilities release];
    [super dealloc];
}

+(id)defaultBoss {
    Baraghast *boss = [[Baraghast alloc] initWithHealth:3040000 damage:150 targets:1 frequency:1.25 choosesMT:YES];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Baraghast, Warlord of the Damned"];
    [boss setNamePlateTitle:@"Baraghast"];
    [boss setSpriteName:@"baraghast_battle_portrait.png"];
    
    [boss addAbility:[Cleave normalCleave]];
    
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if (percentage == 99.0) {
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
@end

@implementation CrazedSeer
+ (id)defaultBoss {
    CrazedSeer *seer = [[CrazedSeer alloc] initWithHealth:2720000 damage:0 targets:0 frequency:0 choosesMT:NO ];
    [seer setTitle:@"Crazed Seer Tyonath"];
    [seer setNamePlateTitle:@"Tyonath"];
    [seer setSpriteName:@"tyonath_battle_portrait.png"];
    
    ProjectileAttack *fireballAbility = [[[ProjectileAttack alloc] init] autorelease];
    [fireballAbility setSpriteName:@"purple_fireball.png"];
    [fireballAbility setAbilityValue:-120];
    [fireballAbility setCooldown:4];
    [seer addAbility:fireballAbility];
    
    InvertedHealing *invHeal = [[[InvertedHealing alloc] init] autorelease];
    [invHeal setNumTargets:3];
    [invHeal setCooldown:5.0];
    [invHeal setActivationTime:1.5];
    [seer addAbility:invHeal];
    
    SoulBurn *sb = [[[SoulBurn alloc] init] autorelease];
    [sb setActivationTime:2.0];
    [sb setCooldown:14.0];
    [seer addAbility:sb];
    
    GainAbility *gainShadowbolts = [[[GainAbility alloc] init] autorelease];
    [gainShadowbolts setCooldown:60];
    [gainShadowbolts setInfo:@"Tyonath casts more shadow bolts the longer the fight goes on."];
    [gainShadowbolts setTitle:@"Increasing Insanity"];
    [gainShadowbolts setIconName:@"increasing_insanity.png"];
    [gainShadowbolts setAbilityToGain:fireballAbility];
    [seer addAbility:gainShadowbolts];
    
    RaidDamage *horrifyingLaugh = [[[RaidDamage alloc] init] autorelease];
    [horrifyingLaugh setActivationTime:1.5];
    [horrifyingLaugh setTitle:@"Horrifying Laugh"];
    [horrifyingLaugh setAbilityValue:125];
    [horrifyingLaugh setCooldown:25];
    [seer addAbility:horrifyingLaugh];
    
    return [seer autorelease];
}
@end

@implementation GatekeeperDelsarn
+ (id)defaultBoss {
    GatekeeperDelsarn *boss = [[GatekeeperDelsarn alloc] initWithHealth:4630000 damage:500 targets:1 frequency:2.1 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Gatekeeper of Delsarn"];
    [boss setNamePlateTitle:@"The Gatekeeper"];
    [boss setSpriteName:@"gatekeeper_battle_portrait.png"];
    
    [boss addAbility:[Cleave normalCleave]];
    
    [boss addGripImpale];
    
    return [boss autorelease];
}

- (void)addGripImpale
{
    Grip *gripAbility = [[[Grip alloc] init] autorelease];
    [gripAbility setKey:@"grip-ability"];
    [gripAbility setActivationTime:1.5];
    [gripAbility setCooldown:22];
    [gripAbility setAbilityValue:-140];
    [self addAbility:gripAbility];
    
    Impale *impaleAbility = [[[Impale alloc] init] autorelease];
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

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if (percentage == 80.0){
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
        [openTheGates setCooldown:kAbilityRequiresTrigger];
        [openTheGates setActivationTime:openingTime];
        [openTheGates setAppliedEffect:pestilenceDot];
        [self addAbility:openTheGates];
        [openTheGates activateAbility];
        
        StackingEnrage *growingHatred = [[[StackingEnrage alloc] init] autorelease];
        [growingHatred setKey:@"growing-hatred"];
        [growingHatred setAbilityValue:1];
        [growingHatred setCooldown:4.0];
        [growingHatred setTitle:@"Growing Hatred"];
        [growingHatred setIconName:@"temper.png"];
        [growingHatred setInfo:@"The Gatekeeper deals more damage the longer the fight lasts."];
        [growingHatred setActivationTime:1.0];
        [self addAbility:growingHatred];
        
        ExpireThresholdRepeatedHealthEffect *burningInsanity = [[[ExpireThresholdRepeatedHealthEffect alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
        [burningInsanity setTitle:@"Burning Insanity"];
        [burningInsanity setDamageDoneMultiplierAdjustment:1.0];
        [burningInsanity setValuePerTick:-10];
        [burningInsanity setMaxStacks:5];
        [burningInsanity setThreshold:.5];
        
        RaidApplyEffect *insaneRaid = [[[RaidApplyEffect alloc] init] autorelease];
        [insaneRaid setKey:@"insane-raid"];
        [insaneRaid setTitle:@"Burning Insanity"];
        [insaneRaid setIconName:@"burning_insanity.png"];
        [insaneRaid setInfo:@"Causes effected targets to deal double damage, but deals damage over time.  The effect is removed when the target is healed above 50% health."];
        [insaneRaid setCooldown:25.0];
        [insaneRaid setActivationTime:2.0];
        [insaneRaid setAppliedEffect:burningInsanity];
        [self addAbility:insaneRaid];
        
    }
    
    if (percentage == 15.0) {
        [self removeAbility:[self abilityWithKey:@"insane-raid"]];
        [self removeAbility:[self abilityWithKey:@"growing-hatred"]];
        [self addGripImpale];
        //Drink in death +10% damage for each ally slain so far.
        NSInteger dead = [raid deadCount];
        if (dead > 0) {
            [self.announcer announce:@"The Gatekeeper grows stronger for each slain ally"];
        }
        dead++;
        for (int i = 0; i < dead; i++){
            Effect *enrageEffect = [[Effect alloc] initWithDuration:600 andEffectType:EffectTypePositiveInvisible];
            [enrageEffect setIsIndependent:YES];
            [enrageEffect setOwner:self];
            [enrageEffect setTitle:@"drink-in-death"];
            [enrageEffect setDamageDoneMultiplierAdjustment:.2];
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
    
    boss.tailLash = [[[RaidDamage alloc] init] autorelease];
    [boss.tailLash setActivationTime:1.5];
    [boss.tailLash setTitle:@"Tail Lash"];
    [boss.tailLash setAbilityValue:320];
    [boss.tailLash setCooldown:24.0];
    [boss.tailLash setFailureChance:.25];
    
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if (percentage == 99.0){
        [self.announcer announce:@"The Skeletal Dragon hovers angrily above your allies."];
    }
    
    if (percentage == 66.0){
        [self.announcer displayScreenShakeForDuration:.33];
        [self.announcer announce:@"The Skeletal Dragon lands and begins to thrash your allies"];
        self.boneThrowAbility.isDisabled = YES;
        [self addAbility:self.tankDamage];
        [self addAbility:self.tailLash];
        [self.sweepingFlame setCooldown:18.0];
    }
    
    if (percentage == 33.0){
        [self.announcer announce:@"The Skeletal Dragon soars off into the air."];
        [self.sweepingFlame setCooldown:14.5];
        [self.tankDamage setIsDisabled:YES];
        [self.tailLash setIsDisabled:YES];
        [self.boneThrowAbility setIsDisabled:NO];
        [self.boneThrowAbility setCooldown:5.0];
    }

    if (percentage == 5.0){
        [self.announcer displayScreenShakeForDuration:.66];
        [self.announcer announce:@"The Skeletal Dragon crashes down onto your allies from the sky."];
        NSArray *livingMembers = [raid livingMembers];
        NSInteger damageValue = 7500 / livingMembers.count;
        for (RaidMember *member in livingMembers){
            FallenDownEffect *fde = [FallenDownEffect defaultEffect];
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
@end

@implementation ColossusOfBone
- (void)dealloc {
    [_boneQuake release];
    [_crushingPunch release];
    [super dealloc];
}
+ (id)defaultBoss {
    ColossusOfBone *cob = [[ColossusOfBone alloc] initWithHealth:1710000 damage:0 targets:0 frequency:0 choosesMT:NO ];
    [cob setTitle:@"Colossus of Bone"];
    [cob setSpriteName:@"colossusbone_battle_portrait.png"];
    
    FocusedAttack *tankAttack = [[FocusedAttack alloc] initWithDamage:620 andCooldown:2.15];
    [tankAttack setFailureChance:.4];
    [cob addAbility:tankAttack];
    [tankAttack release];
    
    cob.crushingPunch = [[[Attack alloc] initWithDamage:0 andCooldown:10.0] autorelease];
    DelayedHealthEffect *crushingPunchEffect = [[DelayedHealthEffect alloc] initWithDuration:3.0 andEffectType:EffectTypeNegative];
    [crushingPunchEffect setTitle:@"crushing-punch"];
    [crushingPunchEffect setOwner:cob];
    [crushingPunchEffect setValue:-900];
    [crushingPunchEffect setSpriteName:@"crush.png"];
    [(Attack*)cob.crushingPunch setAppliedEffect:crushingPunchEffect];
    [crushingPunchEffect release];
    [cob.crushingPunch setFailureChance:.2];
    [cob.crushingPunch setInfo:@"Periodically, this enemy unleashes a thundering strike on a random ally dealing high damage."];
    [cob.crushingPunch setTitle:@"Crushing Punch"];
    [cob.crushingPunch setIconName:@"unstoppable.png"];
    [cob addAbility:cob.crushingPunch];
    
    cob.boneQuake = [[[BoneQuake alloc] init] autorelease];
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

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta {
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    if (self.crushingPunch.timeApplied + 3.0 >= self.crushingPunch.cooldown){
        self.hasShownCrushingPunchThisCooldown = YES;
    }
}

- (void)ownerDidExecuteAbility:(Ability *)ability {
    if (ability == self.boneQuake){
        [self.announcer displayScreenShakeForDuration:3.0];
        float boneQuakeCD = arc4random() % 15 + 15;
        [self.boneQuake setCooldown:boneQuakeCD];
    }
}

@end

@implementation OverseerOfDelsarn
- (void)dealloc {
    [_projectilesAbility release];
    [_demonAbilities release];
    [super dealloc];
}

+ (id)defaultBoss {
    OverseerOfDelsarn *boss = [[OverseerOfDelsarn alloc] initWithHealth:2580000 damage:0 targets:0 frequency:0 choosesMT:NO ];
    [boss setTitle:@"Overseer of Delsarn"];
    [boss setNamePlateTitle:@"The Overseer"];
    [boss setSpriteName:@"overseer_battle_portrait.png"];
    
    boss.projectilesAbility = [[[OverseerProjectiles alloc] init] autorelease];
    [boss.projectilesAbility setTitle:@"Bolt of Despair"];
    [boss.projectilesAbility setActivationTime:1.25];
    [boss.projectilesAbility setAbilityValue:514];
    [boss.projectilesAbility setCooldown:2.5];
    [boss addAbility:boss.projectilesAbility];
    
    boss.demonAbilities = [NSMutableArray arrayWithCapacity:3];
    
    BloodMinion *bm = [[BloodMinion alloc] init];
    [bm setKey:@"blood-minion"];
    [bm setCooldown:10.0];
    [bm setAbilityValue:90];
    [boss.demonAbilities addObject:bm];
    [bm release];
    
    FireMinion *fm = [[FireMinion alloc] init];
    [fm setKey:@"fire-minion"];
    [fm setCooldown:15.0];
    [fm setAbilityValue:315];
    [boss.demonAbilities addObject:fm];
    [fm release];
    
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
    
    Ability *addedAbility = [self.demonAbilities objectAtIndex:indexToAdd];
    [self addAbility:addedAbility];
    [self.demonAbilities removeObjectAtIndex:indexToAdd];
    
    NSString *minionTitle = nil;
    if ([addedAbility.key isEqualToString:@"shadow-minion"]) {
        minionTitle = @"Aura of Shadow";
    } else if ([addedAbility.key isEqualToString:@"fire-minion"]) {
        minionTitle = @"Aura of Fire";
    } else if ([addedAbility.key isEqualToString:@"blood-minion"]) {
        minionTitle = @"Aura of Blood";
    }
    
    if (minionTitle) {
        [self.announcer announce:[NSString stringWithFormat:@"The Overseer conjures  an %@", minionTitle]];
    }
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
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
@end

@implementation TheUnspeakable
- (void)dealloc {
    [_oozeAll release];
    [super dealloc];
}

+ (id)defaultBoss {
    TheUnspeakable *boss = [[TheUnspeakable alloc] initWithHealth:2900000 damage:0 targets:0 frequency:10.0 choosesMT:NO ];
    boss.autoAttack.failureChance = .25;
    [boss setTitle:@"The Unspeakable"];
    [boss setSpriteName:@"unspeakable_battle_portrait.png"];
    
    AbilityDescriptor *slimeDescriptor = [[[AbilityDescriptor alloc] init] autorelease];
    [slimeDescriptor setAbilityDescription:@"As your allies hack their way through the filth beast they become covered in a disgusting slime.  If this slime builds to 5 stacks on any ally that ally will be consumed.  Whenever an ally receives healing from you the slime is removed."];
    [slimeDescriptor setAbilityName:@"Engulfing Slime"];
    [boss addAbilityDescriptor:slimeDescriptor];
    
    boss.oozeAll = [[[OozeRaid alloc] init] autorelease];
    [boss.oozeAll setTitle:@"Surging Slime"];
    [boss.oozeAll setActivationTime:2.0];
    [boss.oozeAll setTimeApplied:17.0];
    [boss.oozeAll setCooldown:22.0];
    [(OozeRaid*)boss.oozeAll setOriginalCooldown:24.0];
    [(OozeRaid*)boss.oozeAll setAppliedEffect:[EngulfingSlimeEffect defaultEffect]];
    [boss.oozeAll setKey:@"apply-ooze-all"];

    [boss addAbility:boss.oozeAll];
    
    OozeTwoTargets *oozeTwo = [[[OozeTwoTargets alloc] init] autorelease];
    [oozeTwo setTitle:@"Tendrils of Slime"];
    [oozeTwo setActivationTime:1.0];
    [oozeTwo setAbilityValue:450];
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

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {    
    if ((int)percentage % 10 == 0){
        NSTimeInterval reduction = 1.775 * (self.difficulty) / 5.0;
        [(OozeRaid*)self.oozeAll setOriginalCooldown:[(OozeRaid*)self.oozeAll originalCooldown] - reduction];
    }
}
@end

@implementation BaraghastReborn
- (void)dealloc{
    [_deathwave release];
    [super dealloc];
}
+ (id)defaultBoss {
    BaraghastReborn *boss = [[BaraghastReborn alloc] initWithHealth:4389000 damage:270 targets:1 frequency:2.25 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Baraghast Reborn"];
    [boss setSpriteName:@"baraghastreborn_battle_portrait.png"];
    
    [boss addAbility:[Cleave normalCleave]];
    
    BaraghastRoar *roar = [[[BaraghastRoar alloc] init] autorelease];
    [roar setCooldown:24.0];
    [roar setKey:@"baraghast-roar"];
    [boss addAbility:roar];
    
    boss.deathwave = [[[Deathwave alloc] init] autorelease];
    [boss.deathwave setCooldown:kAbilityRequiresTrigger];
    [boss.deathwave setKey:@"deathwave"];
    [boss addAbility:boss.deathwave ];
    
    ShatterArmor *shatter = [[[ShatterArmor alloc] init] autorelease];
    [shatter setKey:@"shatter"];
    [shatter setCooldown:36.0];
    [shatter setAbilityValue:1200];
    [shatter setActivationTime:2.0];
    [shatter setCooldownVariance:.33];
    [boss addAbility:shatter];
    
    return [boss autorelease];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    [super configureBossForDifficultyLevel:difficulty];
    
    if (self.difficulty <= 3) {
        self.deathwave.abilityValue = 9000;
    }
    
    if (difficulty == 5) {
        GraspOfTheDamnedEffect *graspEffect = [[[GraspOfTheDamnedEffect alloc] initWithDuration:8.0 andEffectType:EffectTypeNegative] autorelease];
        [graspEffect setNumOfTicks:6];
        [graspEffect setValuePerTick:-100];
        [graspEffect setSpriteName:@"blood_curse.png"];
        [graspEffect setTitle:@"grasp-of-the-damned-eff"];
        [graspEffect setAilmentType:AilmentTrauma];
        GraspOfTheDamned *graspOfTheDamned = [[[GraspOfTheDamned alloc] initWithDamage:0 andCooldown:15.0] autorelease];
        [self addAbility:graspOfTheDamned];
        [graspOfTheDamned setAppliedEffect:graspEffect];
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

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    
    if (percentage == 99.0 || percentage == 85.0 || percentage == 70.0 || percentage == 15.0){
        [self.deathwave triggerAbilityForRaid:raid players:[NSArray arrayWithObject:player] enemies:[NSArray arrayWithObject:self]];
    }
    
    if (percentage == 98.0) {
        [self.announcer announce:@"You will all die screaming!"];
    }
    
    if (percentage == 61.0) {
        
    }
    
    if (percentage == 60.0) {
        [self.announcer announce:@"Baraghast's weapons begin dripping blood."];
        [[self abilityWithKey:@"shatter"] setIsDisabled:YES];
        self.deathwave.isDisabled = YES;
        
        BrokenWill *brokenWill = [[[BrokenWill alloc] init] autorelease];
        [brokenWill setKey:@"broken-will"];
        [brokenWill setTimeApplied:brokenWill.cooldown * .80];
        [self addAbility:brokenWill];
        
        //Stuns the tank until healed to full.  While stunned, Baraghast will attack
        //other raid members randomly.
        //Tanks healing is greatly reduced
        
    }
    
    if (percentage == 15.0) {
        [self removeAbility:[self abilityWithKey:@"broken-will"]];
        BaraghastRoar *roar = (BaraghastRoar*)[self abilityWithKey:@"baraghast-roar"];
        [roar setCooldown:roar.cooldown * .5];
        StackingEnrage *se = [[[StackingEnrage alloc] init] autorelease];
        [se setAbilityValue:5];
        [se setCooldown:roar.cooldown];
        [self addAbility:se];
        [se triggerAbilityForRaid:raid players:[NSArray arrayWithObject:player] enemies:[NSArray arrayWithObject:self]];
        //Gains increasing damage dealt every 6 seconds and roars more often
    }
    
}
@end

@implementation AvatarOfTorment1
+ (id)defaultBoss {
    AvatarOfTorment1 *boss = [[AvatarOfTorment1 alloc] initWithHealth:2880000 damage:0 targets:0 frequency:0.0 choosesMT:NO];
    [boss setTitle:@"The Avatar of Torment"];
    [boss setNamePlateTitle:@"Torment"];
    [boss setSpriteName:@"avataroftorment_battle_portrait.png"];
    
    DisruptionCloud *dcAbility = [[DisruptionCloud alloc] init];
    [dcAbility setKey:@"dis-cloud"];
    [dcAbility setCooldown:23.0];
    [dcAbility setAbilityValue:20];
    [dcAbility setTimeApplied:20.0];
    [boss addAbility:dcAbility];
    [dcAbility release];
    
    AbilityDescriptor *spDescriptor = [[[AbilityDescriptor alloc] init] autorelease];
    [spDescriptor setIconName:@"temper.png"];
    [spDescriptor setAbilityName:@"Soul Prison"];
    [spDescriptor setAbilityDescription:@"Emprisons an ally's soul in unimaginable torment reducing them to just shy of death but preventing all damage done to them."];
    [boss addAbilityDescriptor:spDescriptor];
    
    ProjectileAttack *projectileAttack = [[[ProjectileAttack alloc] init] autorelease];
    [projectileAttack setSpriteName:@"purple_fireball.png"];
    [projectileAttack setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack setAbilityValue:-200];
    [projectileAttack setCooldown:2.5];
    [projectileAttack setFailureChance:.35];
    [boss addAbility:projectileAttack];
    
    ProjectileAttack *projectileAttack2 = [[[ProjectileAttack alloc] init] autorelease];
    [projectileAttack2 setSpriteName:@"purple_fireball.png"];
    [projectileAttack2 setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack2 setAbilityValue:-400];
    [projectileAttack2 setCooldown:2.5];
    [projectileAttack setTimeApplied:2.0];
    [projectileAttack2 setFailureChance:.7];
    [boss addAbility:projectileAttack2];
    
    return [boss autorelease];
}

- (void)soulPrisonAll:(Raid *)raid
{
    [self.announcer announce:@"YOUR SOULS BELONG TO THE ABYSS"];
    for (RaidMember *member in raid.livingMembers) {
        SoulPrisonEffect *spe = [[[SoulPrisonEffect alloc] initWithDuration:35.0 - (self.difficulty - 1.0 * 2) andEffectType:EffectTypeNegative] autorelease];
        [spe setOwner:self];
        NSInteger damage = member.health - 1;
        [self.logger logEvent:[CombatEvent eventWithSource:self target:member value:[NSNumber numberWithInt:damage] andEventType:CombatEventTypeDamage]];
        [member setHealth:1];
        [member addEffect:spe];
    }
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player
{
    if (percentage == 92.0) {
        [self.announcer announce:@"Your mortal souls will shatter beneath the power of torment!"];
    }
    
    if (percentage == 52.0) {
        [self.announcer announce:@"Your pain shall be unending!"];
    }
    
    if (percentage == 90.0 || percentage == 50.0 || percentage == 70.0) {
        [self soulPrisonAll:raid];
    }
    
    if (percentage == 72.0) {
        [self.announcer announce:@"The Avatar of Torment cackles maniacally and pulses with power."];
    }
    
    if (percentage == 70.0) {
        WaveOfTorment *wot = [[[WaveOfTorment alloc] init] autorelease];
        [wot setKey:@"wot"];
        [wot setTitle:@"Waves of Torment"];
        [wot setCooldown:40.0];
        [wot setTimeApplied:0];
        [wot setAbilityValue:72];
        [self addAbility:wot];
    }
    
    if (percentage == 40.0) {
        [self.announcer announce:@"The Avatar of Torment drains your mind"];
        [player setEnergy:0];
        [[self abilityWithKey:@"wot"] setTimeApplied:-20.0];
    }
    
    if (percentage == 25.0) {
        [self.announcer announce:@"Your pain fills me with such power!"];
        GainAbility *gainAbility = [[[GainAbility alloc] init] autorelease];
        [gainAbility setCooldown:20.0];
        
        ProjectileAttack *projectileAttack = [[[ProjectileAttack alloc] init] autorelease];
        [projectileAttack setSpriteName:@"purple_fireball.png"];
        [projectileAttack setExplosionParticleName:@"shadow_burst.plist"];
        [projectileAttack setAbilityValue:-230];
        [projectileAttack setCooldown:1.2];
        [projectileAttack setFailureChance:.2];
        [gainAbility setAbilityToGain:projectileAttack];
        
        [self addAbility:projectileAttack];
        [projectileAttack fireAtRaid:raid];
        [projectileAttack setAbilityValue:-65];
        [projectileAttack setFailureChance:.7];
        [self removeAbility:projectileAttack];
        
        [self addAbility:gainAbility];
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
    [dcAbility setKey:@"dis-cloud"];
    [dcAbility setCooldown:23.0];
    [dcAbility setAbilityValue:26];
    [dcAbility setTimeApplied:20.0];
    [boss addAbility:dcAbility];
    [dcAbility release];
    
    ProjectileAttack *projectileAttack = [[ProjectileAttack alloc] init];
    [projectileAttack setSpriteName:@"purple_fireball.png"];
    [projectileAttack setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack setAbilityValue:-400];
    [projectileAttack setCooldown:.75];
    [projectileAttack setFailureChance:.85];
    [boss addAbility:projectileAttack];
    [projectileAttack release];
    
    ProjectileAttack *projectileAttack2 = [[ProjectileAttack alloc] init];
    [projectileAttack2 setSpriteName:@"purple_fireball.png"];
    [projectileAttack2 setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack2 setAbilityValue:-400];
    [projectileAttack2 setCooldown:.83];
    [projectileAttack2 setFailureChance:.85];
    [boss addAbility:projectileAttack2];
    [projectileAttack2 release];
    
    ProjectileAttack *projectileAttack3 = [[ProjectileAttack alloc] init];
    [projectileAttack3 setSpriteName:@"purple_fireball.png"];
    [projectileAttack3 setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack3 setAbilityValue:-320];
    [projectileAttack3 setCooldown:2.5];
    [projectileAttack3 setFailureChance:.2];
    [boss addAbility:projectileAttack3];
    [projectileAttack3 release];
    
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player
{
    if (percentage == 99.0 || percentage == 95.0) {
        
        WaveOfTorment *wot = [[[WaveOfTorment alloc] init] autorelease];
        [wot setCooldown:40.0];
        [wot setAbilityValue:80];
        [wot setKey:@"wot"];
        [wot setTitle:@"Waves of Torment"];
        [self addAbility:wot];
        [wot triggerAbilityForRaid:raid players:[NSArray arrayWithObject:player] enemies:[NSArray arrayWithObject:self]];
        if (percentage == 95.0) {
            [self removeAbility:wot]; //Dont add 2 copies of this ability for the second trigger
        } else {
            [self.announcer announce:@"The Avatar of Torment erupts power!"];
        }
    }
    if (percentage == 50.0) {
        [self.announcer announce:@"You feel Anguish cloud your mind..."];
        Confusion *confusionAbility = [[[Confusion alloc] init] autorelease];
        [confusionAbility setCooldown:14.0];
        [confusionAbility setAbilityValue:7.0];
        [confusionAbility setKey:@"confusion"];
        [self addAbility:confusionAbility];
        [confusionAbility setTimeApplied:10.0];
    }
    
    if (percentage == 20.0) {
        [self.announcer announce:@"The Avatar becomes enraged."];
        StackingEnrage *se = [[[StackingEnrage alloc] init] autorelease];
        [se setAbilityValue:10];
        [se setCooldown:10];
        [self addAbility:se];
        [se triggerAbilityForRaid:raid players:[NSArray arrayWithObject:player] enemies:[NSArray arrayWithObject:self]];
    }
}
@end

@implementation SoulOfTorment
+ (id)defaultBoss {
    SoulOfTorment *boss = [[SoulOfTorment alloc] initWithHealth:6040000 damage:0 targets:0 frequency:0.0 choosesMT:NO];
    
    [boss setTitle:@"The Soul of Torment"];
    [boss setNamePlateTitle:@"Torment"];
    
    Attack *attack = [[[Attack alloc] initWithDamage:120 andCooldown:20] autorelease];
    ContagiousEffect *contagious = [[[ContagiousEffect alloc] initWithDuration:10.0 andEffectType:EffectTypeNegative] autorelease];
    [contagious setTitle:@"contagion"];
    [contagious setNumOfTicks:10];
    [contagious setValuePerTick:-50];
    [contagious setAilmentType:AilmentPoison];
    [attack setIconName:@"poison.png"];
    [attack setTitle:@"Contagious Toxin"];
    [attack setInfo:@"The Soul of Torment poisons a target causing them to take damage periodically.  If the target's health is healed too much this effect will spread to up to 3 additional allies."];
    [attack setAppliedEffect:contagious];
    [attack setRequiresDamageToApplyEffect:YES];
    [boss addAbility:attack];
    
    [boss gainSoulDrain];
    
    return [boss autorelease];
}

- (void)gainSoulDrain
{
    [self.announcer announce:@"The Soul of Torment hungers for souls"];

    StackingRHEDispelsOnHeal *soulDrainEffect = [[[StackingRHEDispelsOnHeal alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
    [soulDrainEffect setMaxStacks:25];
    [soulDrainEffect setValuePerTick:-14];
    [soulDrainEffect setNumOfTicks:10];
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
    for (Player *player in players) {
        [player setEnergy:player.maximumEnergy];
    }
    for (RaidMember *member in raid.livingMembers) {
        RepeatedHealthEffect *damage = [[[RepeatedHealthEffect alloc] initWithDuration:10.0 andEffectType:EffectTypeNegativeInvisible] autorelease];
        [damage setNumOfTicks:8];
        [damage setOwner:self];
        [damage setTitle:@"gather-souls"];
        [damage setValuePerTick:-75];
        [member addEffect:damage];
    }
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player
{
    if (percentage != 100.0 && (int) percentage % 10 == 0) {
        //Every 10 percent that isn't 100%...
        [self raidDamageToRaid:raid forPlayers:[NSArray arrayWithObject:player]];
    }
    
    if (percentage == 85.0) {
        [self.announcer announce:@"You will beg for death."];
        [self gainSoulDrain];
    }

    if (percentage == 70.0) {
        [self.announcer announce:@"Such glorious anguish"];
        [self gainSoulDrain];
    }
    
    if (percentage == 40.0) {
        [self.announcer announce:@"ENOUGH! YOU SHALL KNOW TRUE TORMENT."];
        NSMutableArray *abilitiesToRemove = [NSMutableArray arrayWithCapacity:5];
        for (RaidMember *member in raid.livingMembers) {
            [member removeEffectsWithTitle:@"soul-drain"];
        }
        for (Ability *ability in self.abilities) {
            if ([ability.key isEqualToString:@"soul-drain"]){
                [abilitiesToRemove addObject:ability];
            }
        }
        for (Ability *ab in abilitiesToRemove) {
            [self removeAbility:ab];
        }
        
        FocusedAttack *focusedAttack = [[[FocusedAttack alloc] initWithDamage:550 andCooldown:2.25] autorelease];
        [focusedAttack setFailureChance:.4];
        RepeatedHealthEffect *bleeding = [[[RepeatedHealthEffect alloc] initWithDuration:8.0 andEffectType:EffectTypeNegative] autorelease];
        [focusedAttack setIconName:@"bleeding.png"];
        [bleeding setTitle:@"soul-bleed"];
        [bleeding setDodgeChanceAdjustment:.1];
        [bleeding setMaxStacks:5];
        [bleeding setValuePerTick:-50];
        [bleeding setNumOfTicks:4];
        [focusedAttack setAppliedEffect:bleeding];
        [self addAbility:focusedAttack];
        
        [[self abilityWithKey:@"contagion"] setCooldown:6.0];
    }
    
    if (percentage == 20.0) {
        [self.announcer announce:@"The Soul of Torment poisons your mind and clouds your vision."];
        Confusion *confusionAbility = [[[Confusion alloc] init] autorelease];
        [confusionAbility setCooldown:14.0];
        [confusionAbility setAbilityValue:8.0];
        [confusionAbility setKey:@"confusion"];
        [self addAbility:confusionAbility];
        [confusionAbility setTimeApplied:10.0];
    }
    
    if (percentage == 10.0) {
        [self.announcer announce:@"YOUR SOULS WILL ANGUISH ALONE IN DARKNESS"];
    }
    
    if (percentage == 2.0) {
        [self.announcer announce:@"NO...NO...IT CANNOT BE...I CAN NOT BE DEFEATED!"];
    }
}

- (void)ownerDidExecuteAbility:(Ability *)ability
{
    if ([ability.key isEqualToString:@"shadow-nova"]){
        RaidDamagePulse *pulse = (RaidDamagePulse*)ability;
        NSTimeInterval tickTime = pulse.duration / pulse.numTicks;
        for (int i = 0; i < pulse.numTicks; i++) {
            [self.announcer displayParticleSystemOnRaidWithName:@"shadow_raid_burst.plist" delay:(tickTime * (i + 1))];
        }
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
    TheEndlessVoid *endlessVoid = [[TheEndlessVoid alloc] initWithHealth:99999999 damage:400 targets:4 frequency:2.0 choosesMT:NO ];
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

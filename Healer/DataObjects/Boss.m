//
//  Boss.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Boss.h"
#import "GameObjects.h"
#import "RaidMember.h"
#import "AudioController.h"
#import "ProjectileEffect.h"
#import "Ability.h"
#import "AbilityDescriptor.h"
#import "Effect.h"

@interface Boss ()
@property (nonatomic, readwrite) float challengeDamageDoneModifier;
@property (nonatomic, readwrite) BOOL hasAppliedChallengeEffects;
@property (nonatomic, retain) NSMutableArray *queuedAbilitiesToAdd;
@property (nonatomic, readwrite) BOOL shouldQueueAbilityAdds;
@end

@implementation Boss
@synthesize title, logger, announcer, criticalChance, info, phase, duration, abilities;
@synthesize queuedAbilitiesToAdd, shouldQueueAbilityAdds;

-(void)dealloc{
    [abilities release];
    [info release];
    [title release];
    [queuedAbilitiesToAdd release];
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

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty
{
    self.difficulty = difficulty;
    
    for (Ability *ab in self.abilities) {
        [ab setDifficulty:self.difficulty];
    }
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

- (void)addAbility:(Ability*)ab{
    if (self.shouldQueueAbilityAdds){
        [self.queuedAbilitiesToAdd addObject:ab];
        return;
    }
    ab.owner = self;
    ab.difficulty = self.difficulty;
    [self.abilities addObject:ab];
}

- (void)removeAbility:(Ability*)ab{
    [self.abilities removeObject:ab];
}

-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses {
    if (self = [super init]){
        health = hlth;
        self.maximumHealth = hlth;
        title = @"";
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
    }
	return self;
}

- (Ability*)abilityWithTitle:(NSString*)abilityTitle
{
    for (Ability*ab in self.abilities) {
        if ([ab.title isEqualToString:abilityTitle]) {
            return ab;
        }
    }
    return nil;
}

-(void)updateEffects:(Boss*)theBoss raid:(Raid*)theRaid player:(Player*)thePlayer time:(float)timeDelta{
    NSMutableArray *effectsToRemove = [NSMutableArray arrayWithCapacity:5];
	for (int i = 0; i < [self.activeEffects count]; i++){
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

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    Player *player = [players objectAtIndex:0]; //The first player is the local player
    float healthPercentage = ((float)self.health/(float)self.maximumHealth) * 100;
    int roundedPercentage = (int)round(healthPercentage);
    int integerOnlyPercentage = (int)healthPercentage;
    if ((healthPercentage - .5) < integerOnlyPercentage){
        //This isnt there yet. We only want it to fire if we rounded up!
    }else{
        if (roundedPercentage < 100 && roundedPercentage > 0){
            for (int i = 100; i >= roundedPercentage; i--){
                if (!healthThresholdCrossed[i]){
                    [self healthPercentageReached:i withRaid:theRaid andPlayer:player];
                    healthThresholdCrossed[i] = YES;;
                }
            }
        }
    }
    self.duration += timeDelta;
    
    if (!self.hasAppliedChallengeEffects) {
        if (self.difficulty > 3) {
            for (Player *plyer in players) {
                Effect *healingReductionChallengeEffect = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypeNegativeInvisible] autorelease];
                float mod = 0;//-.10;
                if (self.difficulty == 5) {
                    mod = 0;//-.15;
                }
                [healingReductionChallengeEffect setTitle:@"hr-red-challengeeff"];
                [healingReductionChallengeEffect setOwner:self];
                [healingReductionChallengeEffect setHealingDoneMultiplierAdjustment:mod];
                [plyer addEffect:healingReductionChallengeEffect];
            }
        }
        self.hasAppliedChallengeEffects = YES;
    }
    
    self.shouldQueueAbilityAdds = YES;
    for (Ability *ability in self.abilities){
        [ability combatActions:theRaid boss:self players:players gameTime:timeDelta];
    }
    self.shouldQueueAbilityAdds = NO;
    [self dequeueAbilityAdds];
    
    [self updateEffects:self raid:theRaid player:player time:timeDelta];
}

-(BOOL)isDead
{
	return health <= 0;
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
@end

#pragma mark - Shipping Bosses (Merc Campaign)

@implementation Ghoul
+(id)defaultBoss{
    Ghoul *ghoul = [[Ghoul alloc] initWithHealth:10920 damage:200 targets:1 frequency:2.0 choosesMT:NO ];
    [ghoul setTitle:@"The Ghoul"];
    [ghoul setInfo:@"These are strange times in the once peaceful kingdom of Theronia.  A dark mist has set beyond the Eastern Mountains and corrupt creatures have begun attacking innocent villagers and travelers along the roads."];
    
    AbilityDescriptor *ad = [[[AbilityDescriptor alloc] init] autorelease];
    [ad setAbilityName:@"Undead Attacks"];
    [ad setAbilityDescription:@"The Ghoul attacks its enemies randomly."];
    [ad setIconName:@"unknown_ability.png"];
    [ghoul addAbilityDescriptor:ad];
    return [ghoul autorelease];
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 75.0){
        [self.announcer announce:@"A putrid limb falls from the ghoul..."];
    }
    
    if (percentage == 50.0){
        [self.announcer announce:@"The ghoul begins to crumble."];
    }
    
    if (percentage == 25.0){
        [self.announcer announce:@"The nearly lifeless ghoul shrieks in agony.."];
    }
}
@end

@implementation CorruptedTroll
@synthesize enraging;
+(id)defaultBoss{
    NSInteger health = 185000;
    NSInteger damage = 350;
    NSTimeInterval freq = 2.25;
    
    CorruptedTroll *corTroll = [[CorruptedTroll alloc] initWithHealth:health damage:damage targets:1 frequency:freq choosesMT:YES ];
    corTroll.autoAttack.failureChance = .1;
    
    [corTroll setTitle:@"Corrupted Troll"];
    [corTroll setInfo:@"Three days ago a Raklorian Troll stumbled out from beyond the mountains and began ravaging the farmlands.  This was unusual behavior for a cave troll, but survivors noted that the troll seemed to be empowered by an evil magic."];
    
    CaveIn *caveIn = [[[CaveIn alloc] init] autorelease];
    [caveIn setAbilityValue:75];
    [caveIn setTitle:@"troll-cave-in"];
    [caveIn setCooldown:25.0];
    [caveIn setActivationTime:.5];
    corTroll.caveIn = caveIn;
    [corTroll addAbility:corTroll.caveIn];
    
    AbilityDescriptor *caveInDesc = [[[AbilityDescriptor alloc] init] autorelease];
    [caveInDesc setAbilityDescription:@"Occasionally, the Corrupted Troll will smash the roof causing rocks to fall onto your allies."];
    [caveInDesc setIconName:@"unknown_ability.png"];
    [caveInDesc setAbilityName:@"Cave In"];
    [caveIn setDescriptor:caveInDesc];
    
    AbilityDescriptor *frenzy = [[AbilityDescriptor alloc] init];
    [frenzy setAbilityDescription:@"Occasionally, the Corrupted Troll will attack his Focused target furiously dealing high damage."];
    [frenzy setIconName:@"unknown_ability.png"];
    [frenzy setAbilityName:@"Frenzy"];
    [corTroll addAbilityDescriptor:frenzy];
    [frenzy release];
    
    return  [corTroll autorelease];
}

- (void)configureBossForDifficultyLevel:(NSInteger)difficulty {
    [super configureBossForDifficultyLevel:difficulty];
    
    [self addAbility:[Cleave normalCleave]];
    
    if (difficulty >= 4) {
        self.autoAttack.abilityValue = 500;
        self.autoAttack.failureChance = .25;
    }

    if (difficulty == 5) {
        [self addAbility:[[DisorientingBoulder new] autorelease]];
    }
}

- (void)ownerDidBeginAbility:(Ability *)ability {
    [self.announcer announce:@"The Troll smashes the cave ceiling"];
    [self.announcer displayScreenShakeForDuration:6.5];
    [self.announcer displayParticleSystemOverRaidWithName:@"falling_rocks.plist"];
}

-(void)startEnraging{
    [self.announcer announce:@"The Troll swings his club furiously at his focused target!"];
    self.enraging += 1.0;
    self.autoAttack.cooldown = 1.5;
}

-(void)stopEnraging{
    [self.announcer announce:@"The Troll is Exhausted!"];
    self.enraging = 0.0;
    self.autoAttack.cooldown = 2.25;
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 75.0 || percentage == 50.0 || percentage == 25.0 || percentage == 10.0){
        [self startEnraging];
    }
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    
    if (self.enraging > 0){
        self.enraging += timeDelta;
        if (self.enraging > 10.0){
            [self stopEnraging];
        }
    }
}
@end

@implementation Drake 
+(id)defaultBoss {
    Drake *drake = [[Drake alloc] initWithHealth:185000 damage:0 targets:0 frequency:0 choosesMT:NO ];
    [drake setTitle:@"Tainted Drake"];
    [drake setInfo:@"A Drake of Soldorn has not been seen in Theronia for ages, but the foul creature has been burning down cottages and farms as well as killing countless innocents.  You and your allies have cornered the drake and forced a confrontation."];
    
    NSInteger fireballDamage = 400;
    float fireballFailureChance = .05;
    float fireballCooldown = 2.5;
    
    AbilityDescriptor *fireball = [[AbilityDescriptor alloc] init];
    [fireball setAbilityDescription:@"The Drake hurls deadly Fireballs at your allies."];
    [fireball setIconName:@"unknown_ability.png"];
    [fireball setAbilityName:@"Spit Fireball"];
    [drake addAbilityDescriptor:fireball];
    [fireball release];
    
    drake.fireballAbility = [[[ProjectileAttack alloc] init] autorelease];
    [drake.fireballAbility setTitle:@"fireball-ab"];
    [(ProjectileAttack*)drake.fireballAbility setSpriteName:@"fireball.png"];
    [drake.fireballAbility setAbilityValue:fireballDamage];
    [drake.fireballAbility setFailureChance:fireballFailureChance];
    [drake.fireballAbility setCooldown:fireballCooldown];
    [drake addAbility:drake.fireballAbility];
    
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
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 77.0 || percentage == 52.0 || percentage == 27.0){
        [self.announcer announce:@"The Drake takes a deep breath..."];
    }
    
    if (percentage == 50.0 || percentage == 75.0 || percentage == 25.0){
        
        [self.fireballAbility setTimeApplied:-5.0]; //Turn off this ability for 5 seconds.
        float effectDuration = 5.0;
        [self.announcer displayBreathEffectOnRaidForDuration:effectDuration];
        for (RaidMember *member in raid.livingMembers) {
            RepeatedHealthEffect *flameBreathEffect = [[[RepeatedHealthEffect alloc] initWithDuration:effectDuration andEffectType:EffectTypeNegativeInvisible] autorelease];
            [flameBreathEffect setNumOfTicks:5];
            [flameBreathEffect setValuePerTick:-(arc4random() % 50 + 100)];
            [flameBreathEffect setOwner:self];
            [flameBreathEffect setTitle:@"flame-breath-eff"];
            [member addEffect:flameBreathEffect];
        }
    }
}
@end


@implementation MischievousImps
@synthesize lastPotionThrow;
+(id)defaultBoss {
    MischievousImps *boss = [[MischievousImps alloc] initWithHealth:225000 damage:0 targets:0 frequency:2.25 choosesMT:NO];
    [boss removeAbility:boss.autoAttack];
    boss.autoAttack = [[[SustainedAttack alloc] initWithDamage:340 andCooldown:2.25] autorelease];
    boss.autoAttack.failureChance = .25;
    [boss addAbility:boss.autoAttack];
    
    [boss setTitle:@"Mischievious Imps"];
    [boss setInfo:@"As the dark mists further encroach upon the kingdom more strange creatures begin terrorizing the innocents.  Viscious imps have infiltrated the alchemical storehouses on the outskirts of Terun."];
    return [boss autorelease];
}

-(void)dealloc{
    [super dealloc];
}

-(void)throwPotionToTarget:(RaidMember *)target withDelay:(float)delay inRaid:(Raid*)theRaid {
    NSInteger possiblePotions = 3;
    if (self.difficulty > 4) {
        possiblePotions = 4;
    }
    
    int potion = arc4random() % possiblePotions;
    float colTime = (1.5 + delay);
    
    if (potion == 0){
        //Liquid Fire
        NSInteger impactDamage = -150;
        NSInteger dotDamage = -200;
        
        DelayedHealthEffect* bottleEffect = [[[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible] autorelease];
        [bottleEffect setValue:impactDamage * self.damageDoneMultiplier];
        [bottleEffect setIsIndependent:YES];
        [bottleEffect setOwner:self];
        [target addEffect:bottleEffect];
        
        RepeatedHealthEffect *burnDoT = [[[RepeatedHealthEffect alloc] initWithDuration:12 andEffectType:EffectTypeNegative] autorelease];
        [burnDoT setOwner:self];
        [burnDoT setTitle:@"imp-burn-dot"];
        [burnDoT setSpriteName:@"burning.png"];
        [burnDoT setValuePerTick:dotDamage];
        [burnDoT setNumOfTicks:4];
        [bottleEffect setAppliedEffect:burnDoT];
        
        ProjectileEffect *bottleVisual = [[[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime] autorelease];
        [bottleVisual setSpriteColor:ccc3(255, 0, 0 )];
        [bottleVisual setType:ProjectileEffectTypeThrow];
        [bottleVisual setCollisionParticleName:@"fire_explosion.plist"];
        [self.announcer displayProjectileEffect:bottleVisual];
        
        
    }else if (potion == 1) {
        //Lightning In a Bottle
        DelayedHealthEffect *bottleEffect = [[[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible] autorelease];
        
        ProjectileEffect *bottleVisual = [[[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime] autorelease];
        [bottleVisual setSpriteColor:ccc3(0, 128, 128)];
        [bottleVisual setType:ProjectileEffectTypeThrow];
        [self.announcer displayProjectileEffect:bottleVisual];
        [bottleEffect setIsIndependent:YES];
        [bottleEffect setOwner:self];
        NSInteger damage = FUZZ(-550, 10);
        [bottleEffect setValue:damage];
        [target addEffect:bottleEffect];
    } else if (potion == 2) {
        //Poison explosion
        
        NSInteger impactDamage = FUZZ(-100, 20);
        
        for (RaidMember *member in theRaid.livingMembers) {
            DelayedHealthEffect* bottleEffect = [[[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible] autorelease];
            [bottleEffect setValue:impactDamage * self.damageDoneMultiplier];
            [bottleEffect setIsIndependent:YES];
            [bottleEffect setOwner:self];
            [member addEffect:bottleEffect];
        }
        
        ProjectileEffect *bottleVisual = [[[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime] autorelease];
        [bottleVisual setSpriteColor:ccc3(0, 128, 128)];
        [bottleVisual setType:ProjectileEffectTypeThrow];
        [bottleVisual setCollisionParticleName:@"gas_explosion.plist"];
        [self.announcer displayProjectileEffect:bottleVisual];
        
    } else if (potion == 3) {
        //Angry Spirit
        NSInteger impactDamage = -150;
        NSInteger dotDamage = -200;
        
        DelayedHealthEffect* bottleEffect = [[[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible] autorelease];
        [bottleEffect setValue:impactDamage * self.damageDoneMultiplier];
        [bottleEffect setIsIndependent:YES];
        [bottleEffect setOwner:self];
        [target addEffect:bottleEffect];
        
        WanderingSpiritEffect *wse = [[[WanderingSpiritEffect alloc] initWithDuration:14.0 andEffectType:EffectTypeNegative] autorelease];
        [wse setAilmentType:AilmentCurse];
        [wse setTitle:@"angry-spirit-effect"];
        [wse setSpriteName:@"angry_spirit.png"];
        [wse setValuePerTick:dotDamage];
        [wse setNumOfTicks:8.0];
        [bottleEffect setAppliedEffect:wse];
        
        ProjectileEffect *bottleVisual = [[[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime] autorelease];
        [bottleVisual setSpriteColor:ccc3(255, 0, 0 )];
        [bottleVisual setType:ProjectileEffectTypeThrow];
        [self.announcer displayProjectileEffect:bottleVisual];
    }
    
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    if (self.healthPercentage > 21.0){
        self.lastPotionThrow+=timeDelta;
        float tickTime = 12.0;
        if (self.lastPotionThrow > tickTime){
            [self throwPotionToTarget:[theRaid randomLivingMember] withDelay:0.0 inRaid:theRaid];
            self.lastPotionThrow = 0.0;
            int throwSound = arc4random() %2 + 1;
            [[AudioController sharedInstance] playTitle:[NSString stringWithFormat:@"imp_throw%i", throwSound]];
            
        }
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 99.0){
        [self.announcer announce:@"An imp grabs a bundle of vials off of a nearby desk."];
    }
    
    if (percentage == 50.0){
        for (RaidMember *member in raid.raidMembers){
            if (!member.isDead){
                [self throwPotionToTarget:member withDelay:0.0 inRaid:raid];
            }
        }
        [self.announcer announce:@"An imp angrily hurls the entire case of flasks at you!"];
        [[AudioController sharedInstance] playTitle:[NSString stringWithFormat:@"imp_throw1"]];
    }
    
    if (percentage == 15.0){
        [self.announcer announce:@"The imps begin attacking angrily!"];
        self.autoAttack.isDisabled = YES;
        
        for (RaidMember *member in raid.livingMembers) {
            FocusedAttack *attack = [[[FocusedAttack alloc] initWithDamage:self.autoAttack.abilityValue * .75 andCooldown:self.autoAttack.cooldown] autorelease];
            [attack setFailureChance:self.autoAttack.failureChance];
            [attack setFocusTarget:member];
            [member setIsFocused:YES];
            [self addAbility:attack];
        }
    }
}
@end

@implementation BefouledTreant
@synthesize lastRootquake;
+(id)defaultBoss {
    NSInteger bossDamage = 390;
    
    BefouledTreant *boss = [[BefouledTreant alloc] initWithHealth:560000 damage:bossDamage targets:1 frequency:3.0 choosesMT:YES ];
    boss.autoAttack.failureChance = .25;
    [boss setTitle:@"Befouled Akarus"];
    [boss setInfo:@"The Akarus, an ancient tree that has long rested in the Peraxu Forest, has become tainted with the foul energy of the dark mists. This once great tree must be ended for good."];
    
    
    Cleave *cleave = [Cleave normalCleave];
    [boss addAbility:cleave];
    
    return [boss autorelease];
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    
    float tickTime = 30.0;
    self.lastRootquake += timeDelta;
    if (self.lastRootquake > tickTime){
        [self performRootquakeOnRaid:theRaid];
        self.lastRootquake = 0.0;
    }
}

-(void)performBranchAttackOnRaid:(Raid*)raid{
    NSInteger branchInitialDamage = 208;
    NSInteger branchDoTTick = -36;
    
    for (RaidMember *member in raid.raidMembers){
        [member setHealth:member.health - branchInitialDamage * self.damageDoneMultiplier];
        [self.logger logEvent:[CombatEvent eventWithSource:self target:member value:[NSNumber numberWithInt:branchInitialDamage * self.damageDoneMultiplier] andEventType:CombatEventTypeDamage]];
        RepeatedHealthEffect *lashDoT = [[RepeatedHealthEffect alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative];
        [lashDoT setOwner:self];
        [lashDoT setTitle:@"lash"];
        [lashDoT setAilmentType:AilmentTrauma];
        [lashDoT setValuePerTick:branchDoTTick];
        [lashDoT setNumOfTicks:5];
        [lashDoT setSpriteName:@"bleeding.png"];
        [member addEffect:[lashDoT autorelease]];
    }
}

-(void)performRootquakeOnRaid:(Raid*)raid{
    [self.announcer announce:@"The Akarus' roots move the earth."];
    [self.announcer displayScreenShakeForDuration:6.0];
    for (RaidMember *member in raid.raidMembers){
        RepeatedHealthEffect *rootquake = [[RepeatedHealthEffect alloc] initWithDuration:6.0 andEffectType:EffectTypeNegativeInvisible];
        [rootquake setOwner:self];
        [rootquake setValuePerTick:-40];
        [rootquake setNumOfTicks:4];
        [rootquake setTitle:@"rootquake"];
        [member addEffect:[rootquake autorelease]];
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 97.0 || percentage == 75.0 || percentage == 51.0 || percentage == 30.0){
        [self.announcer announce:@"The Akarus pulls its enormous branches back to lash out at your allies."];
    }
    if (percentage == 96.0 || percentage == 74.0 || percentage == 50.0 || percentage == 29.0){
        [self performBranchAttackOnRaid:raid];
    }
}
@end

@implementation FungalRavagers
@synthesize isEnraged, secondTargetAttack, thirdTargetAttack;
+(id)defaultBoss {
    FungalRavagers *boss = [[FungalRavagers alloc] initWithHealth:560000 damage:141 targets:1 frequency:2.0 choosesMT:YES ];
    boss.autoAttack.failureChance = .25;
    [boss setTitle:@"Fungal Ravagers"];
    [boss setInfo:@"As the dark mist consumes the Akarus ferocious beasts are birthed from its roots.  The ravagers immediately attack you and your allies."];
    [boss setCriticalChance:.5];
    
    FocusedAttack *secondFocusedAttack = [[FocusedAttack alloc] initWithDamage:162 andCooldown:2.6];
    secondFocusedAttack.failureChance = .25;
    [boss addAbility:secondFocusedAttack];
    [boss setSecondTargetAttack:secondFocusedAttack];
    [secondFocusedAttack release];
    FocusedAttack *thirdFocusedAttack = [[FocusedAttack alloc] initWithDamage:193 andCooldown:3.2];
    thirdFocusedAttack.failureChance = .25;
    [boss addAbility:thirdFocusedAttack];
    [boss setThirdTargetAttack:thirdFocusedAttack];
    [thirdFocusedAttack release];
    
    AbilityDescriptor *vileExploDesc = [[AbilityDescriptor alloc] init];
    [vileExploDesc setAbilityDescription:@"When a Fungal Ravager dies, it explodes coating random targets in toxic venom."];
    [vileExploDesc setIconName:@"unknown_ability.png"];
    [vileExploDesc setAbilityName:@"Vile Explosion"];
    [boss addAbilityDescriptor:vileExploDesc];
    [vileExploDesc release];
    
    return [boss autorelease];
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

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    
    if (percentage == 96.0){
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
    if (percentage == 66.0){
        [self ravagerDiedFocusing:self.thirdTargetAttack.focusTarget andRaid:raid];
        [self removeAbility:self.thirdTargetAttack];
    }
    if (percentage == 33.0){
        [self ravagerDiedFocusing:self.secondTargetAttack.focusTarget andRaid:raid];
        [self removeAbility:self.secondTargetAttack];
    }
    
    if (percentage == 30.0){
        [self.announcer announce:@"The last remaining Ravager glows with rage."];
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


@implementation PlaguebringerColossus
@synthesize lastSickeningTime, numBubblesPopped;
+(id)defaultBoss {
    //427500
    PlaguebringerColossus *boss = [[PlaguebringerColossus alloc] initWithHealth:560000 damage:330 targets:1 frequency:2.5 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Plaguebringer Colossus"];
    [boss setInfo:@"As the Akarus is finally consumed its branches begin to quiver and shake.  As the ground rumbles beneath its might, you and your allies witness a hideous transformation.  What once was a peaceful treant has now become an abomination.  Only truly foul magics could have caused this."];
    
    AbilityDescriptor *sickenDesc = [[AbilityDescriptor alloc] init];
    [sickenDesc setAbilityDescription:@"The Colossus will sicken targets causing them to take damage until they are healed to full health."];
    [sickenDesc setIconName:@"unknown_ability.png"];
    [sickenDesc setAbilityName:@"Strange Sickness"];
    [boss addAbilityDescriptor:sickenDesc];
    [sickenDesc release];
    
    AbilityDescriptor *pusExploDesc = [[AbilityDescriptor alloc] init];
    [pusExploDesc setAbilityDescription:@"When your allies deal enough damage to the Plaguebringer Colossus to break off a section of its body the section explodes vile toxin dealing high damage to your raid."];
    [pusExploDesc setIconName:@"unknown_ability.png"];
    [pusExploDesc setAbilityName:@"Limb Bomb"];
    [boss addAbilityDescriptor:pusExploDesc];
    [pusExploDesc release];
    
    [boss addAbility:[Cleave normalCleave]];
    
    return [boss autorelease];
}

-(void)sickenTarget:(RaidMember *)target{
    ExpiresAtFullHealthRHE *infectedWound = [[ExpiresAtFullHealthRHE alloc] initWithDuration:30.0 andEffectType:EffectTypeNegative];
    [infectedWound setOwner:self];
    [infectedWound setTitle:@"pbc-infected-wound"];
    [infectedWound setAilmentType:AilmentTrauma];
    [infectedWound setValuePerTick:-100];
    [infectedWound setNumOfTicks:15];
    [infectedWound setSpriteName:@"bleeding.png"];
    if (target.health > target.maximumHealth * .58){
        // Spike the health for funsies!
        NSInteger preHealth = target.health;
        [target setHealth:target.health * .58];
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:preHealth - target.health] andEventType:CombatEventTypeDamage]];
    }
    [target addEffect:infectedWound];
    [infectedWound release];
    
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
            [singleTickDot setSpriteName:@"poison.png"];
            [member addEffect:singleTickDot];
            [singleTickDot release];
        }
    }
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    
    self.lastSickeningTime += timeDelta;
    float tickTime =  15.0;
    if (self.lastSickeningTime > tickTime){
        for ( int i = 0; i < 2; i++){
            [self sickenTarget:theRaid.randomLivingMember];
        }
        self.lastSickeningTime = 0.0;
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (((int)percentage) % 20 == 0 && percentage != 100){
        [self burstPussBubbleOnRaid:raid];
    }
}

@end

@implementation Trulzar
@synthesize lastPoisonTime, lastPotionTime;
+(id)defaultBoss {
    Trulzar *boss = [[Trulzar alloc] initWithHealth:2600000 damage:0 targets:0 frequency:100.0 choosesMT:NO ];
    [boss setTitle:@"Trulzar the Maleficar"];
    [boss setNamePlateTitle:@"Trulzar"];
    [boss setInfo:@"Days before the dark mists came, Trulzar disappeared into the Peraxu forest with only a spell book.  This once loyal warlock is wanted for questioning regarding the strange events that have befallen the land.  You have been sent with a large warband to bring Trulzar to justice."];
    
    boss.lastPotionTime = 6.0;
    
    AbilityDescriptor *poison = [[AbilityDescriptor alloc] init];
    [poison setAbilityDescription:@"Trulzar fills an allies veins with poison dealing increasing damage over time.  This effect may be removed with the Purify spell."];
    [poison setIconName:@"unknown_ability.png"];
    [poison setAbilityName:@"Necrotic Venom"];
    [boss addAbilityDescriptor:poison];
    [poison release];
    
    RaidDamagePulse *pulse = [[[RaidDamagePulse alloc] init] autorelease];
    [pulse setTitle:@"poison-nova"];
    [pulse setAbilityValue:550];
    [pulse setNumTicks:4];
    [pulse setDuration:12.0];
    [pulse setCooldown:60.0];
    [pulse setTimeApplied:40.0];
    [boss addAbility:pulse];
    boss.poisonNova = pulse;
    return [boss autorelease];
}

-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq choosesMT:(BOOL)chooses {
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq choosesMT:chooses ]){
    }
    return self;
}

-(void)dealloc{
    [super dealloc];
}
-(void)applyPoisonToTarget:(RaidMember*)target{
    TrulzarPoison *poisonEffect = [[TrulzarPoison alloc] initWithDuration:24 andEffectType:EffectTypeNegative];
    [self.announcer displayParticleSystemWithName:@"poison_cloud.plist" onTarget:target];
    [poisonEffect setOwner:self];
    [poisonEffect setAilmentType:AilmentPoison];
    [poisonEffect setSpriteName:@"poison.png"];
    [poisonEffect setValuePerTick:-120];
    [poisonEffect setNumOfTicks:30];
    [poisonEffect setTitle:@"trulzar-poison1"];
    [target addEffect:poisonEffect];
    
    NSInteger upfrontDamage = (arc4random() % 200) * self.damageDoneMultiplier;
    [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:upfrontDamage] andEventType:CombatEventTypeDamage]];
    [target setHealth:target.health - upfrontDamage];
    [poisonEffect release];
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

-(void)throwPotionToTarget:(RaidMember *)target withDelay:(float)delay{
    float colTime = (1.5 + delay);
    
    //Lightning In a Bottle
    DelayedHealthEffect *bottleEffect = [[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
    
    ProjectileEffect *bottleVisual = [[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime];
    [bottleVisual setType:ProjectileEffectTypeThrow];
    [bottleVisual setSpriteColor:ccc3(0, 255, 0)];
    [self.announcer displayProjectileEffect:bottleVisual];
    [bottleVisual release];
    [bottleEffect setIsIndependent:YES];
    [bottleEffect setOwner:self];
    [bottleEffect setValue:-450];
    [target addEffect:bottleEffect];
    [bottleEffect release];    
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    self.lastPoisonTime += timeDelta;
    self.lastPotionTime += timeDelta;
    
    float tickTime = 10;
    if (self.lastPoisonTime > tickTime){ 
        if (self.healthPercentage > 10.0){
            [self.announcer announce:@"Trulzar fills an ally with poison."];
            [[AudioController sharedInstance] playTitle:@"trulzar_laugh"];
            [self applyPoisonToTarget:[theRaid randomLivingMember]];
            self.lastPoisonTime = 0;
        }
    }
    
    float potionTickTime = self.isMultiplayer ? 5 : 8;
    if (self.lastPotionTime > potionTickTime){
        [self throwPotionToTarget:[theRaid randomLivingMember] withDelay:0.0];
        self.lastPotionTime = 0.0;
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    
    if (((int)percentage) == 7){
        [self.announcer announce:@"Trulzar cackles as the room fills with noxious poison."];
        [self.poisonNova setIsDisabled:YES];
        [[AudioController sharedInstance] playTitle:@"trulzar_death"];
        for (RaidMember *member in raid.raidMembers){
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
    
}

@end

@implementation DarkCouncil
@synthesize lastPoisonballTime, rothVictim, lastDarkCloud;
+(id)defaultBoss {
    DarkCouncil *boss = [[DarkCouncil alloc] initWithHealth:2450000 damage:0 targets:1 frequency:.75 choosesMT:NO ];
    [boss setTitle:@"Council of Dark Summoners"];
    [boss setNamePlateTitle:@"Teritha"];
    [boss setInfo:@"A contract in blood lay signed and sealed in Trulzar's belongings.  He had been summoned by a council of dark summoners to participate in an arcane ritual for some horrible purpose.  You and your allies have followed the sanguine invitation to a dark chamber beneath the Vargothian Swamps."];
    return [boss autorelease];
}

-(void)dealloc{
    [rothVictim release];
    [super dealloc];
}

-(RaidMember*)chooseVictimInRaid:(Raid*)raid{
    RaidMember *victim = nil;
    int safety = 0;
    while (!victim){
        RaidMember *member = [raid randomLivingMember];
        if ([member isKindOfClass:[Archer class]]){
            continue;
        }
        victim = member;  
        safety++;
        if (safety > 25){
            break;
        }
    }
    return victim;
}

-(void)summonDarkCloud:(Raid*)raid{
    for (RaidMember *member in raid.raidMembers){
        DarkCloudEffect *dcEffect = [[DarkCloudEffect alloc] initWithDuration:5 andEffectType:EffectTypeNegativeInvisible];
        [dcEffect setOwner:self];
        [dcEffect setValuePerTick:-30];
        [dcEffect setNumOfTicks:3];
        [member addEffect:dcEffect];
        [dcEffect release];
    }
    [self.announcer displayParticleSystemOnRaidWithName:@"purple_mist.plist" forDuration:-1.0];
}

-(void)shootProjectileAtTarget:(RaidMember*)target withDelay:(float)delay{
    float colTime = (1.5 + delay);
    CouncilPoisonball *fireball = [[CouncilPoisonball alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
    
    ProjectileEffect *fireballVisual = [[ProjectileEffect alloc] initWithSpriteName:@"green_fireball.png" target:target andCollisionTime:colTime];
    [fireballVisual setCollisionParticleName:@"poison_cloud.plist"];
    [self.announcer displayProjectileEffect:fireballVisual];
    [fireballVisual release];
    [fireball setIsIndependent:YES];
    [fireball setOwner:self];
    [fireball setValue:-(arc4random() % 100 + 300)];
    [target addEffect:fireball];
    [fireball release];
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    if (self.phase == 1){
        //Roth
        BOOL hasPoison = NO;
        for (Effect* effect in self.rothVictim.activeEffects){
            if ([effect.title isEqualToString:@"roth_poison"]){
                hasPoison = YES;
                break;
            }
        }
        if (!hasPoison || self.rothVictim.isDead){
            self.rothVictim = [self chooseVictimInRaid:theRaid];
            RaidDamageOnDispelStackingRHE *poison = [[RaidDamageOnDispelStackingRHE alloc] initWithDuration:-1.0 andEffectType:EffectTypeNegative];
            [poison setOwner:self];
            [poison setTitle:@"roth_poison"];
            [poison setSpriteName:@"poison.png"];
            [poison setAilmentType:AilmentPoison];
            [poison setNumOfTicks:20];
            [poison setMaxStacks:50];
            [poison setValuePerTick:-35];
            [poison setDispelDamageValue:-200];
            [self.rothVictim addEffect:[poison autorelease]];
        }
    }
    
    if (self.phase == 2){
        //Grimgon
        [self setNamePlateTitle:@"Grimgon"];
        self.lastPoisonballTime += timeDelta;
        float tickTime = self.isMultiplayer ? 7.5 : 9;
        if (self.lastPoisonballTime > tickTime){ 
            for (int i = 0; i < 2; i++){
                [self shootProjectileAtTarget:[theRaid randomLivingMember] withDelay:i * 1];
            }
            self.lastPoisonballTime = 0;
        }
    }
    
    if (self.phase == 3){
        //Serevon
        [self setNamePlateTitle:@"Serevon"];
        self.lastDarkCloud += timeDelta;
        float tickTime = 18.0;
        if (self.lastDarkCloud > tickTime){
            [self summonDarkCloud:theRaid];
            self.lastDarkCloud = 0.0;
        }
    }
    
    if (self.phase == 4){
        [self setNamePlateTitle:@"Galcyon"];
    }

}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 99.0){
        self.autoAttack.abilityValue = 0;
        [self.announcer announce:@"The room fills with demonic laughter."];
    }
    if (percentage == 97.0){
        //Roth of the Shadows steps forward
        self.phase = 1;
        [self.announcer announce:@"Teritha, The Toxin Mage steps forward."];
        AbilityDescriptor *rothDesc = [[AbilityDescriptor alloc] init];
        [rothDesc setAbilityDescription:@"Teritha channels a curse on an ally dealing increasing damage over time.  When this curse is dispelled it will explode dealing moderate damage to all of your allies."];
        [rothDesc setIconName:@"unknown_ability.png"];
        [rothDesc setAbilityName:@"Curse of Detonation"];
        [self addAbilityDescriptor:rothDesc];
        [rothDesc release];
    }
    
    if (percentage == 75.0){
        [self clearExtraDescriptors];
        //Roth dies
        [self.announcer announce:@"Teritha falls to her knees.  Grimgon, The Darkener takes her place."];
        self.phase = 2;
    }
    if (percentage == 74.0){
        AbilityDescriptor *grimgonDesc = [[AbilityDescriptor alloc] init];
        [grimgonDesc setAbilityDescription:@"Grimgon fires vile green bolts at his enemies dealing damage and causing the targets to have healing done to them reduced by 50%."];
        [grimgonDesc setIconName:@"unknown_ability.png"];
        [grimgonDesc setAbilityName:@"Poisonball"];
        [self addAbilityDescriptor:grimgonDesc];
        [grimgonDesc release];
    }
    
    if (percentage == 50.0){
        [self clearExtraDescriptors];
        [self.announcer announce:@"Grimgon fades to nothing.  Galcyon, Overlord of Darkness pushes away his corpse and raises his wand."];
        //Serevon, Anguish Mage steps forward
        self.phase = 3;
        self.autoAttack.abilityValue = 270;
        self.autoAttack.failureChance = .25;
    }
    if (percentage == 49.0){
        AbilityDescriptor *serevonDesc = [[AbilityDescriptor alloc] init];
        [serevonDesc setAbilityDescription:@"Periodically, Galcyon summons a dark cloud over all of your allies that deals more damage to lower health allies and weakens healing magic."];
        [serevonDesc setIconName:@"unknown_ability.png"];
        [serevonDesc setAbilityName:@"Choking Cloud"];
        [self addAbilityDescriptor:serevonDesc];
        [serevonDesc release];
    }
    
    if (percentage == 25.0){
        [self clearExtraDescriptors];
        //Galcyon, Lord of the Dark Council steps forward
        self.phase = 4;
    }
    
    if (percentage == 23.0){
        for (RaidMember *member in raid.raidMembers){
            [self shootProjectileAtTarget:member withDelay:0.0];
        }
    }
    
    if (percentage == 5.0){
        [self.announcer announce:@"Galycon cries out as steel and magic burns through his flesh."];
        [self summonDarkCloud:raid];
        //Galcyon, Lord of the Dark Council does his last thing..
    }
}
@end

@implementation TwinChampions
@synthesize firstFocusedAttack, secondFocusedAttack;
@synthesize lastAxecution, lastGushingWound;
+(id)defaultBoss {
    NSInteger damage = 190;
    float frequency = 1.30;
    TwinChampions *boss = [[TwinChampions alloc] initWithHealth:2550000 damage:damage targets:1 frequency:frequency choosesMT:YES];
    [boss setFirstFocusedAttack:[[boss abilities] objectAtIndex:0]];
    boss.autoAttack.failureChance = .25;
    
    FocusedAttack *secondFA = [[FocusedAttack alloc] initWithDamage:damage * 4 andCooldown:frequency * 5];
    secondFA.failureChance = .25;
    [boss setSecondFocusedAttack:secondFA];
    [boss addAbility:secondFA];
    [secondFA release];
    
    [boss setTitle:@"Twin Champions of Baraghast"];
    [boss setNamePlateTitle:@"Twin Champions"];
    [boss setInfo:@"You have crossed the eastern mountains through a path filled with ghouls, demons, and other terrible creatures.  Blood stained and battle worn, you and your allies have come across an encampment guarded by two skeletal champions."];
    
    [boss addAbility:[Cleave normalCleave]];
    
    AbilityDescriptor *axecutionDesc = [[AbilityDescriptor alloc] init];
    [axecutionDesc setAbilityDescription:@"The Twin Champions will periodically choose a target for execution.  This target will be instantly slain if not above 50% health when the effect expires."];
    [axecutionDesc setIconName:@"unknown_ability.png"];
    [axecutionDesc setAbilityName:@"Execution"];
    [boss addAbilityDescriptor:axecutionDesc];
    [axecutionDesc release];
    
    return [boss autorelease];
}

-(void)axeSweepThroughRaid:(Raid*)theRaid{
    self.lastAxecution  = -7.0;
    self.firstFocusedAttack.timeApplied = -7.0;
    self.secondFocusedAttack.timeApplied = -7.0;
    self.lastGushingWound = -7.0; 
    //Set all the other abilities to be on a long cooldown...
    
    [self.announcer announce:@"The Champions Break off from the Guardians and sweep through your allies"];
    NSInteger deadCount = [theRaid deadCount];
    for (int i = 0; i < theRaid.raidMembers.count/2; i++){
        NSInteger index = theRaid.raidMembers.count - i - 1;

        RaidMember *member = [theRaid.raidMembers objectAtIndex:index];
        RaidMember *member2 = [theRaid.raidMembers objectAtIndex:i];
        
        NSInteger axeSweepDamage = FUZZ(250, 40);
        
        DelayedHealthEffect *axeSweepEffect = [[DelayedHealthEffect alloc] initWithDuration:i * .5 andEffectType:EffectTypeNegativeInvisible];
        [axeSweepEffect setOwner:self];
        [axeSweepEffect setTitle:@"axesweep"];
        [axeSweepEffect setValue:-axeSweepDamage * (1 + ((float)deadCount/(float)theRaid.raidMembers.count))];
        [axeSweepEffect setFailureChance:.1];     
        DelayedHealthEffect *axeSweep2 = [axeSweepEffect copy];
        [member addEffect:axeSweepEffect];
        [member2 addEffect:axeSweep2];
        
        [axeSweepEffect release];
        [axeSweep2 release];
        
    }
}

-(void)performAxecutionOnRaid:(Raid*)theRaid{
    RaidMember *target = nil;
    
    int safety = 0;
    while (!target || target.isFocused){
        target = [theRaid randomLivingMember];
        safety++;
        if (safety > 25){
            break;
        }
    }
    [self.announcer announce:@"An Ally Has been chosen for Execution..."];
    NSInteger currentHealth = target.health;
    NSInteger healthLimit = target.maximumHealth * .4;
    if (currentHealth > healthLimit) {
        [target setHealth:healthLimit];
        if (currentHealth > healthLimit) {
            [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:(currentHealth - healthLimit)] andEventType:CombatEventTypeDamage]];
        }
    }
    ExecutionEffect *effect = [[ExecutionEffect alloc] initWithDuration:3.75 andEffectType:EffectTypeNegative];
    [effect setOwner:self];
    [effect setValue:-2000];
    [effect setSpriteName:@"execution.png"];
    [effect setEffectivePercentage:.5];
    [effect setAilmentType:AilmentTrauma];
    
    [target addEffect:effect];
    [effect release];
}

-(void)performGushingWoundOnRaid:(Raid*)theRaid{
    for (int i = 0; i < 1; i++){
        RaidMember *target = nil;
        
        int safety = 0;
        while (!target || target.isFocused){
            target = [theRaid randomLivingMember];
            safety++;
            if (safety > 25){
                break;
            }
        }
        
        DelayedHealthEffect *axeThrownEffect = [[DelayedHealthEffect alloc] initWithDuration:1.5 andEffectType:EffectTypeNegativeInvisible];
        [axeThrownEffect setOwner:self];
        [axeThrownEffect setValue:-250];
        [axeThrownEffect setIsIndependent:YES];
        
        IntensifyingRepeatedHealthEffect *gushingWoundEffect = [[IntensifyingRepeatedHealthEffect alloc] initWithDuration:9.0 andEffectType:EffectTypeNegative];
        [gushingWoundEffect setSpriteName:@"bleeding.png"];
        [gushingWoundEffect setAilmentType:AilmentTrauma];
        [gushingWoundEffect setIncreasePerTick:.5];
        [gushingWoundEffect setValuePerTick:-230];
        [gushingWoundEffect setNumOfTicks:3];
        [gushingWoundEffect setOwner:self];
        [gushingWoundEffect setTitle:@"gushingwound"];
        
        [axeThrownEffect setAppliedEffect:gushingWoundEffect];
        
        [target addEffect:axeThrownEffect];
        
        ProjectileEffect *axeVisual = [[ProjectileEffect alloc] initWithSpriteName:@"axe.png" target:target andCollisionTime:1.5];
        [axeVisual setType:ProjectileEffectTypeThrow];
        [self.announcer displayProjectileEffect:axeVisual];
        [axeVisual release];
        [gushingWoundEffect release];
        [axeThrownEffect release];
    }
}

-(void)swapTanks{
    RaidMember *tempSwap = self.secondFocusedAttack.focusTarget;
    self.secondFocusedAttack.focusTarget = self.firstFocusedAttack.focusTarget;
    self.firstFocusedAttack.focusTarget = tempSwap;
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    
    self.lastAxecution += timeDelta;
    self.lastGushingWound += timeDelta;
    
    float axecutionTickTime = 30.0;
    float gushingWoundTickTime = 18.0;
    
    if (self.lastAxecution >= axecutionTickTime){
        [self performAxecutionOnRaid:theRaid];
        self.lastAxecution = 0.0;
    }
    
    if (self.lastGushingWound >= gushingWoundTickTime){
        [self performGushingWoundOnRaid:theRaid];
        self.lastGushingWound = 0.0;
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 80.0 || percentage == 60.0 || percentage == 40.0 || percentage == 20.0){
        [self axeSweepThroughRaid:raid];
        [self swapTanks];
    }
}
@end

@implementation Baraghast
@synthesize remainingAbilities;
- (void)dealloc {
    [remainingAbilities release];
    [super dealloc];
}

+(id)defaultBoss {
    Baraghast *boss = [[Baraghast alloc] initWithHealth:3040000 damage:150 targets:1 frequency:1.25 choosesMT:YES];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Baraghast, Warlord of the Damned"];
    [boss setNamePlateTitle:@"Baraghast"];
    [boss setInfo:@"As his champions fell, the dark warlord emerged from deep in the encampment.  Disgusted with the failure of his champions, he confronts you and your allies himself."];
    
    [boss addAbility:[Cleave normalCleave]];
    
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if (percentage == 99.0) {
        BaraghastRoar *roar = [[BaraghastRoar alloc] init];
        [roar setTitle:@"baraghast-roar"];
        [roar setCooldown:18.0];
        [self addAbility:roar];
        [roar release];
    }
    
    if (percentage == 80.0) {
        [self.announcer announce:@"Baraghast glowers beyond the Guardian at the rest of your allies"];
        BaraghastBreakOff *breakOff = [[BaraghastBreakOff alloc] init];
        [breakOff setTitle:@"break-off"];
        [breakOff setCooldown:25];
        [breakOff setOwnerAutoAttack:(FocusedAttack*)self.autoAttack];
        
        [self addAbility:breakOff];
        [breakOff release];
    }
    
    if (percentage == 60.0) {
        [self.announcer announce:@"Baraghast fills with rage."];
        Crush *crushAbility = [[[Crush alloc] init] autorelease];
        [crushAbility setTitle:@"crush"];
        [crushAbility setCooldown:20];
        [crushAbility setTarget:[(FocusedAttack*)self.autoAttack focusTarget]];
        [self addAbility:crushAbility];
    }
    
    if (percentage == 33.0) {
        [self.announcer announce:@"A Dark Energy Surges Beneath Baraghast..."];
        Deathwave *dwAbility = [[Deathwave alloc] init];
        [dwAbility setTitle:@"deathwave"];
        [dwAbility setCooldown:42.0];
        [self addAbility:dwAbility];
        [dwAbility release];
    }

}

- (void)ownerDidExecuteAbility:(Ability*)ability {
    if ([ability.title isEqualToString:@"deathwave"]){
        for (Ability *ab in self.abilities){
            [ab setTimeApplied:0];
        }
    }
}
@end

@implementation CrazedSeer
+ (id)defaultBoss {
    CrazedSeer *seer = [[CrazedSeer alloc] initWithHealth:2720000 damage:0 targets:0 frequency:0 choosesMT:NO ];
    [seer setTitle:@"Crazed Seer Tyonath"];
    [seer setNamePlateTitle:@"Tyonath"];
    [seer setInfo:@"Seer Tyonath was tormented and tortured after his capture by the Dark Horde. He guards the secrets to Baraghast's origin in a horrific chamber beneath the encampment."];
    
    ProjectileAttack *fireballAbility = [[ProjectileAttack alloc] init];
    [fireballAbility setSpriteName:@"purple_fireball.png"];
    [fireballAbility setAbilityValue:-120];
    [fireballAbility setCooldown:4];
    [seer addAbility:fireballAbility];
    [fireballAbility release];
    
    InvertedHealing *invHeal = [[InvertedHealing alloc] init];
    [invHeal setNumTargets:3];
    [invHeal setCooldown:6.0];
    [seer addAbility:invHeal];
    [invHeal release];
    
    SoulBurn *sb = [[SoulBurn alloc] init];
    [sb setCooldown:16.0];
    [seer addAbility:sb];
    [sb release];
    
    GainAbility *gainShadowbolts = [[GainAbility alloc] init];
    [gainShadowbolts setCooldown:60];
    [gainShadowbolts setAbilityToGain:fireballAbility];
    [seer addAbility:gainShadowbolts];
    [gainShadowbolts release];
    
    RaidDamage *horrifyingLaugh = [[RaidDamage alloc] init];
    [horrifyingLaugh setAbilityValue:125];
    [horrifyingLaugh setCooldown:25];
    [seer addAbility:horrifyingLaugh];
    [horrifyingLaugh release];
    
    AbilityDescriptor *gsdesc = [[AbilityDescriptor alloc] init];
    [gsdesc setAbilityDescription:@"Tyonath casts more shadow bolts the longer the fight goes on."];
    [gsdesc setIconName:@"unknown_ability.png"];
    [gsdesc setAbilityName:@"Increasing Insanity"];
    [gainShadowbolts setDescriptor:gsdesc];
    [gsdesc release];
    
    return [seer autorelease];
}
@end

@implementation GatekeeperDelsarn
+ (id)defaultBoss {
    GatekeeperDelsarn *boss = [[GatekeeperDelsarn alloc] initWithHealth:2030000 damage:500 targets:1 frequency:2.1 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setInfo:@"Still deeper beneath the encampment you have discovered a portal to Delsarn.  No mortal has ever set foot in this ancient realm of evil and unless you and your allies can dispatch the gatekeeper no mortal ever will."];
    [boss setTitle:@"Gatekeeper of Delsarn"];
    [boss setNamePlateTitle:@"The Gatekeeper"];
    
    [boss addAbility:[Cleave normalCleave]];
    
    Grip *gripAbility = [[Grip alloc] init];
    [gripAbility setTitle:@"grip-ability"];
    [gripAbility setCooldown:22];
    [gripAbility setAbilityValue:-140];
    [boss addAbility:gripAbility];
    [gripAbility release];
    
    Impale *impaleAbility = [[Impale alloc] init];
    [impaleAbility setTitle:@"gatekeeper-impale"];
    [impaleAbility setCooldown:16];
    [boss addAbility:impaleAbility];
    [impaleAbility setAbilityValue:820];
    [impaleAbility release];
    
    
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if (percentage == 75.0){
        //Pestilence
        [self.announcer displayParticleSystemOnRaidWithName:@"green_mist.plist" forDuration:20];
        NSArray *livingMembers = [raid livingMembers];
        for (RaidMember *member in livingMembers){
            RepeatedHealthEffect *pestilenceDot = [[RepeatedHealthEffect alloc] initWithDuration:20 andEffectType:EffectTypeNegativeInvisible];
            [pestilenceDot setValuePerTick:-40];
            [pestilenceDot setOwner:self];
            [pestilenceDot setNumOfTicks:10];
            [pestilenceDot setTitle:@"gatekeeper-pestilence"];
            [member addEffect:pestilenceDot];
            [pestilenceDot release];
        }
    }
    
    if (percentage == 50.0) {
        [self.announcer announce:@"The Gatekeeper summons two Blood-Drinker Demons to his side."];
        //Blood drinkers
        BloodDrinker *ability = [[BloodDrinker alloc] initWithDamage:110 andCooldown:1.25];
        [ability setTitle:@"gatekeeper-blooddrinker"];
        [self addAbility:ability];
        [ability release];
        
        BloodDrinker *ability2 = [[BloodDrinker alloc] initWithDamage:110 andCooldown:1.25];
        [ability2 setTitle:@"gatekeeper-blooddrinker"];
        [self addAbility:ability2];
        [ability2 release];
    }
    
    if (percentage == 25.0) {
        [self.announcer announce:@"The Blood Drinkers are slain."];
        for (Ability *ability in self.abilities) {
            if ([ability.title isEqualToString:@"gatekeeper-blooddrinker"]){
                [ability setIsDisabled:YES];
                [[(BloodDrinker*)ability focusTarget] setIsFocused:NO];
            }
        }
    }
    if (percentage == 23.0) {
        //Drink in death +10% damage for each ally slain so far.
        [self.announcer announce:@"The Gatekeeper grows strong for each slain ally"];
        NSInteger dead = [raid deadCount];
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
    [boss setInfo:@"After slaying countless minor demons upon entering Delsarn your party has encountered a towering Skeletal Dragon."];
    [boss setTitle:@"Skeletal Dragon"];
    
    boss.boneThrowAbility = [[[BoneThrow alloc] init] autorelease];
    [boss.boneThrowAbility  setCooldown:5.0];
    [boss addAbility:boss.boneThrowAbility];
    
    RepeatedHealthEffect *burningEffect = [[[RepeatedHealthEffect alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative] autorelease];
    [burningEffect setValuePerTick:-25];
    [burningEffect setNumOfTicks:5];
    [burningEffect setSpriteName:@"burning.png"];
    [burningEffect setTitle:@"alternating-flame-burn"];
    
    boss.sweepingFlame = [[[AlternatingFlame alloc] init] autorelease];
    [(AlternatingFlame*)boss.sweepingFlame setAppliedEffect:burningEffect];
    [boss.sweepingFlame setCooldown:9.0];
    [boss.sweepingFlame setAbilityValue:400];
    [(AlternatingFlame*)boss.sweepingFlame setNumTargets:5];
    [boss addAbility:boss.sweepingFlame];
    
    boss.tankDamage = [[[FocusedAttack alloc] init] autorelease];
    [boss.tankDamage setAbilityValue:700];
    [boss.tankDamage setCooldown:2.5];
    [boss.tankDamage setFailureChance:.73];
    
    boss.tailLash = [[[RaidDamage alloc] init] autorelease];
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
    [cob setInfo:@"As the skeletal dragon falls and crashes to the ground you feel a rumbling in the distance.  Before you and your allies can even recover from the encounter with the skeletal dragon you are besieged by a monstrosity."];
    
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
    [cob addAbility:cob.crushingPunch];
    
    cob.boneQuake = [[[BoneQuake alloc] init] autorelease];
    [cob.boneQuake setAbilityValue:120];
    [cob.boneQuake setCooldown:30.0];
    [cob addAbility:cob.boneQuake];
    
    BoneThrow *boneThrow = [[BoneThrow alloc] init];
    [boneThrow setAbilityValue:240];
    [boneThrow setCooldown:14.0];
    [cob addAbility:boneThrow];
    [boneThrow release];
    
    AbilityDescriptor *crushingPunchDescriptor = [[AbilityDescriptor alloc] init];
    [crushingPunchDescriptor setAbilityDescription:@"Periodically, this enemy unleashes a thundering strike on a random ally dealing high damage."];
    [crushingPunchDescriptor setAbilityName:@"Crushing Punch"];
    [crushingPunchDescriptor setIconName:@"crushing_punch_ability.png"];
    [cob.crushingPunch setDescriptor:crushingPunchDescriptor];
    [crushingPunchDescriptor release];
    
    
    return [cob autorelease];
    
}

- (void)combatActions:(NSArray *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta {
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
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
    [boss setInfo:@"After defeating the most powerful and terrible creatures in Delsarn the Overseer of this treacherous realm confronts you himself."];
    
    boss.projectilesAbility = [[[OverseerProjectiles alloc] init] autorelease];
    [boss.projectilesAbility setAbilityValue:514];
    [boss.projectilesAbility setCooldown:1.5];
    [boss addAbility:boss.projectilesAbility];
    
    boss.demonAbilities = [NSMutableArray arrayWithCapacity:3];
    
    BloodMinion *bm = [[BloodMinion alloc] init];
    [bm setTitle:@"blood-minion"];
    [bm setCooldown:10.0];
    [bm setAbilityValue:90];
    [boss.demonAbilities addObject:bm];
    [bm release];
    
    FireMinion *fm = [[FireMinion alloc] init];
    [fm setTitle:@"fire-minion"];
    [fm setCooldown:15.0];
    [fm setAbilityValue:315];
    [boss.demonAbilities addObject:fm];
    [fm release];
    
    ShadowMinion *sm = [[ShadowMinion alloc] init];
    [sm setTitle:@"shadow-minion"];
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
    if ([addedAbility.title isEqualToString:@"shadow-minion"]) {
        minionTitle = @"Minion of Shadow";
    } else if ([addedAbility.title isEqualToString:@"fire-minion"]) {
        minionTitle = @"Minion of Fire";
    } else if ([addedAbility.title isEqualToString:@"blood-minion"]) {
        minionTitle = @"Minion of Blood";
    }
    
    if (minionTitle) {
        [self.announcer announce:[NSString stringWithFormat:@"The Overseer brings forth a %@", minionTitle]];
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
        self.projectilesAbility.cooldown = 3.75;
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
    [boss setInfo:@"As you peel back the blood-sealed door to the inner sanctum of the Delsari citadel you find a horrific room filled with a disgusting mass of bones and rotten corpses.  The room itself seems to be ... alive."];
    
    boss.oozeAll = [[[OozeRaid alloc] init] autorelease];
    [boss.oozeAll setTimeApplied:19.0];
    [boss.oozeAll setCooldown:24.0];
    [(OozeRaid*)boss.oozeAll setOriginalCooldown:24.0];
    [(OozeRaid*)boss.oozeAll setAppliedEffect:[EngulfingSlimeEffect defaultEffect]];
    [boss.oozeAll setTitle:@"apply-ooze-all"];

    [boss addAbility:boss.oozeAll];
    
    OozeTwoTargets *oozeTwo = [[OozeTwoTargets alloc] init];
    [oozeTwo setAbilityValue:450];
    [oozeTwo setCooldown:17.0];
    [oozeTwo setTitle:@"ooze-two"];
    [boss addAbility:oozeTwo];
    [oozeTwo release];
    
    return [boss autorelease];
}

- (void)setDifficulty:(NSInteger)difficulty
{
    [super setDifficulty:difficulty];
    
    OozeTwoTargets *oozeTwo = (OozeTwoTargets*)[self abilityWithTitle:@"ooze-two"];
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
    BaraghastReborn *boss = [[BaraghastReborn alloc] initWithHealth:3400000 damage:270 targets:1 frequency:2.25 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Baraghast Reborn"];
    [boss setInfo:@"Before you stands the destroyed but risen warchief Baraghast.  His horrible visage once again sows fear in the hearts of all of your allies.  His undead ferocity swells with the ancient and evil power of Delsarn."];
    
    [boss addAbility:[Cleave normalCleave]];
    
    BaraghastRoar *roar = [[[BaraghastRoar alloc] init] autorelease];
    [roar setCooldown:24.0];
    [roar setTitle:@"baraghast-roar"];
    [boss addAbility:roar];
    
    boss.deathwave = [[[Deathwave alloc] init] autorelease];
    [boss.deathwave  setCooldown:kAbilityRequiresTrigger];
    [boss.deathwave  setTitle:@"deathwave"];
    [boss addAbility:boss.deathwave ];
    
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
        for (Ability *ability in self.abilities){
            [ability setTimeApplied:0.0];
        }
    }
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    
    if (self.difficulty <= 3) {
        if (percentage == 99.0 || percentage == 75.0 || percentage == 50.0 || percentage == 25.0){
            [self.deathwave triggerAbilityForRaid:raid andPlayers:[NSArray arrayWithObject:player]];
        }
    } else if (percentage == 99.0 || percentage == 80.0 || percentage == 60.0 || percentage == 40.0 || percentage == 20.0){
        [self.deathwave triggerAbilityForRaid:raid andPlayers:[NSArray arrayWithObject:player]];
    }
    
}
@end

@implementation AvatarOfTorment1
+ (id)defaultBoss {
    AvatarOfTorment1 *boss = [[AvatarOfTorment1 alloc] initWithHealth:2880000 damage:0 targets:0 frequency:0.0 choosesMT:NO ];
    [boss setTitle:@"The Avatar of Torment"];
    [boss setNamePlateTitle:@"Torment"];
    [boss setInfo:@"From the dark heart of Baraghast's shattered corpse emerges a hideous and cackling demon of unfathomable power. Before you stands a massive creature spawned of pure hatred whose only purpose is torment."];
    
    DisruptionCloud *dcAbility = [[DisruptionCloud alloc] init];
    [dcAbility setTitle:@"dis-cloud"];
    [dcAbility setCooldown:23.0];
    [dcAbility setAbilityValue:20];
    [dcAbility setTimeApplied:20.0];
    [boss addAbility:dcAbility];
    [dcAbility release];
    
    AbilityDescriptor *spDescriptor = [[[AbilityDescriptor alloc] init] autorelease];
    [spDescriptor setIconName:@"soul_prison_ability.png"];
    [spDescriptor setAbilityName:@"Soul Prison"];
    [spDescriptor setAbilityDescription:@"Emprisons an ally's soul in unimaginable torment reducing them to just shy of death but preventing all damage done to them."];
    [boss addAbilityDescriptor:spDescriptor];
    
    ProjectileAttack *projectileAttack = [[ProjectileAttack alloc] init];
    [projectileAttack setSpriteName:@"purple_fireball.png"];
    [projectileAttack setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack setAbilityValue:-250];
    [projectileAttack setCooldown:2.5];
    [projectileAttack setFailureChance:.35];
    [boss addAbility:projectileAttack];
    [projectileAttack release];
    
    ProjectileAttack *projectileAttack2 = [[ProjectileAttack alloc] init];
    [projectileAttack2 setSpriteName:@"purple_fireball.png"];
    [projectileAttack2 setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack2 setAbilityValue:-500];
    [projectileAttack2 setCooldown:2.5];
    [projectileAttack setTimeApplied:2.0];
    [projectileAttack2 setFailureChance:.7];
    [boss addAbility:projectileAttack2];
    [projectileAttack2 release];
    
    
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
        [wot setTitle:@"wot"];
        [wot setCooldown:40.0];
        [wot setTimeApplied:0];
        [wot setAbilityValue:100];
        [self addAbility:wot];
    }
    
    if (percentage == 40.0) {
        [self.announcer announce:@"The Avatar of Torment drains your mind"];
        [player setEnergy:0];
        [[self abilityWithTitle:@"wot"] setTimeApplied:-20.0];
    }
    
    if (percentage == 25.0) {
        [self.announcer announce:@"Your pain fills me with such power!"];
        GainAbility *gainAbility = [[[GainAbility alloc] init] autorelease];
        [gainAbility setCooldown:20.0];
        
        ProjectileAttack *projectileAttack = [[[ProjectileAttack alloc] init] autorelease];
        [projectileAttack setSpriteName:@"purple_fireball.png"];
        [projectileAttack setExplosionParticleName:@"shadow_burst.plist"];
        [projectileAttack setAbilityValue:-300];
        [projectileAttack setCooldown:1.2];
        [projectileAttack setFailureChance:.2];
        [gainAbility setAbilityToGain:projectileAttack];
        
        [self addAbility:projectileAttack];
        [projectileAttack fireAtRaid:raid];
        [projectileAttack setAbilityValue:-100];
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
    [boss setInfo:@"Torment will not be vanquished so easily."];
    
    DisruptionCloud *dcAbility = [[DisruptionCloud alloc] init];
    [dcAbility setTitle:@"dis-cloud"];
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
        [wot setTitle:@"wot"];
        [self addAbility:wot];
        [wot triggerAbilityForRaid:raid andPlayers:[NSArray arrayWithObject:player]];
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
        [confusionAbility setTitle:@"confusion"];
        [self addAbility:confusionAbility];
        [confusionAbility setTimeApplied:10.0];
    }
    
    if (percentage == 20.0) {
        [self.announcer announce:@"The Avatar becomes enraged."];
        StackingEnrage *se = [[[StackingEnrage alloc] init] autorelease];
        [se setAbilityValue:10];
        [se setCooldown:10];
        [self addAbility:se];
        [se triggerAbilityForRaid:raid andPlayers:[NSArray arrayWithObject:player]];
    }
}
@end

@implementation SoulOfTorment
+ (id)defaultBoss {
    SoulOfTorment *boss = [[SoulOfTorment alloc] initWithHealth:6040000 damage:0 targets:0 frequency:0.0 choosesMT:NO];
    
    [boss setTitle:@"The Soul of Torment"];
    [boss setNamePlateTitle:@"Torment"];
    [boss setInfo:@"Its body shattered and broken--the last gasp of this terrible creature conspires to unleash its most unspeakable power.  Your allies are bleeding and broken and your souls are exhausted by the strain of endless battle, but the final evil must be vanquished..."];
    
    Attack *attack = [[[Attack alloc] initWithDamage:120 andCooldown:20] autorelease];
    ContagiousEffect *contagious = [[[ContagiousEffect alloc] initWithDuration:10.0 andEffectType:EffectTypeNegative] autorelease];
    [contagious setSpriteName:@"poison.png"];
    [contagious setTitle:@"contagion"];
    [contagious setNumOfTicks:10];
    [contagious setValuePerTick:-50];
    [contagious setAilmentType:AilmentPoison];
    [attack setAppliedEffect:contagious];
    [attack setRequiresDamageToApplyEffect:YES];
    [boss addAbility:attack];
    
    AbilityDescriptor *contagiousDesc = [[[AbilityDescriptor alloc] init] autorelease];
    [contagiousDesc setAbilityDescription:@"The Soul of Torment poisons a target causing them to take damage periodically.  If the target's health is healed too much this effect will spread to up to 3 additional allies."];
    [contagiousDesc setAbilityName:@"Contagious Toxin"];
    [contagiousDesc setIconName:@"unknown_ability.png"];
    [boss addAbilityDescriptor:contagiousDesc];
    
    [boss gainSoulDrain];
    
    return [boss autorelease];
}

- (void)gainSoulDrain
{
    [self.announcer announce:@"The Soul of Torment hungers for souls"];

    StackingRHEDispelsOnHeal *soulDrainEffect = [[[StackingRHEDispelsOnHeal alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
    [soulDrainEffect setMaxStacks:25];
    [soulDrainEffect setValuePerTick:-20];
    [soulDrainEffect setNumOfTicks:10];
    [soulDrainEffect setSpriteName:@"shadow_curse.png"];
    [soulDrainEffect setTitle:@"soul-drain-eff"];
    
    EnsureEffectActiveAbility *eeaa = [[[EnsureEffectActiveAbility alloc] init] autorelease];
    [eeaa setTitle:@"soul-drain"];
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
        [damage setValuePerTick:-100];
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
            if ([ability.title isEqualToString:@"soul-drain"]){
                [abilitiesToRemove addObject:ability];
            }
        }
        for (Ability *ab in abilitiesToRemove) {
            [self removeAbility:ab];
        }
        
        FocusedAttack *focusedAttack = [[[FocusedAttack alloc] initWithDamage:550 andCooldown:2.25] autorelease];
        [focusedAttack setFailureChance:.4];
        RepeatedHealthEffect *bleeding = [[[RepeatedHealthEffect alloc] initWithDuration:8.0 andEffectType:EffectTypeNegative] autorelease];
        [bleeding setSpriteName:@"bleeding.png"];
        [bleeding setTitle:@"soul-bleed"];
        [bleeding setDodgeChanceAdjustment:.1];
        [bleeding setMaxStacks:5];
        [bleeding setValuePerTick:-50];
        [bleeding setNumOfTicks:4];
        [focusedAttack setAppliedEffect:bleeding];
        [self addAbility:focusedAttack];
        
        [[self abilityWithTitle:@"contagion"] setCooldown:6.0];
    }
    
    if (percentage == 20.0) {
        [self.announcer announce:@"The Soul of Torment poisons your mind and clouds your vision."];
        Confusion *confusionAbility = [[[Confusion alloc] init] autorelease];
        [confusionAbility setCooldown:14.0];
        [confusionAbility setAbilityValue:8.0];
        [confusionAbility setTitle:@"confusion"];
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
    if ([ability.title isEqualToString:@"shadow-nova"]){
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
    [endlessVoid setInfo:@"An immortal foe that can not be vanquished.  Withstand as long as you can."];
    endlessVoid.autoAttack.failureChance = .25;
    
    StackingDamage *damageStacker = [[StackingDamage alloc] init];
    [damageStacker setAbilityValue:1];
    [damageStacker setCooldown:30];
    [endlessVoid addAbility:damageStacker];
    [damageStacker release];
    
    RandomAbilityGenerator *rag = [[RandomAbilityGenerator alloc] init];
    [rag setCooldown:60];
    [rag setTimeApplied:55.0];
    [rag setTitle:@"random-abilities"];
    [endlessVoid addAbility:rag];
    [rag release];
    
     return [endlessVoid autorelease];
}
@end

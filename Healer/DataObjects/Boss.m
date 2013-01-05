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
            return .1;
        case 5:
            return .15;
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

- (void)ownerDidExecuteAbility:(Ability*)ability {
    
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

- (void)setAttackDamage:(NSInteger)damage{
    for (Ability *ab in self.abilities){
        if ([ab isKindOfClass:[Attack class]]){
            [ab setAbilityValue:damage];
        }
    }
}

- (void)setAttackSpeed:(float)frequency{
    for (Ability *ab in self.abilities){
        if ([ab isKindOfClass:[Attack class]]){
            [ab setCooldown:frequency];
        }
    }
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
                float mod = -.10;
                if (self.difficulty == 5) {
                    mod = -.15;
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
    Ghoul *ghoul = [[Ghoul alloc] initWithHealth:21840 damage:200 targets:1 frequency:2.0 choosesMT:NO ];
    [ghoul setTitle:@"The Night Ghoul"];
    [ghoul setInfo:@"A ghoul has found its way onto a nearby farmer's land.  It has already killed the farmer's wife.  You will accompany a small band of mercenaries to dispatch the ghoul."];
    
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
    NSInteger damage = 220;
    NSTimeInterval freq = 1.4;
    
    CorruptedTroll *corTroll = [[CorruptedTroll alloc] initWithHealth:health damage:damage targets:1 frequency:freq choosesMT:YES ];
    
    [corTroll setTitle:@"Corrupted Troll"];
    [corTroll setInfo:@"A Troll of Raklor has been identified among the demons brewing in the south.  It has been corrupted and twisted into a foul and terrible creature.  You will journey with a small band of soldiers to the south to dispatch this troll."];
    
    RaidApplyEffect *caveIn = [[[RaidApplyEffect alloc] init] autorelease];
    RepeatedHealthEffect *caveInDoT = [[[RepeatedHealthEffect alloc] initWithDuration:6.0 andEffectType:EffectTypeNegativeInvisible] autorelease];
    [caveInDoT setTitle:@"cave-in-damage"];
    [caveInDoT setValuePerTick:-(arc4random() % 100 + 75)];
    [caveInDoT setNumOfTicks:3];
    [caveIn setTitle:@"troll-cave-in"];
    [caveIn setAppliedEffect:caveInDoT];
    [caveIn setCooldown:25.0];
    [caveIn setActivationTime:.75];
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

    if (difficulty == 5) {
        [self addAbility:[[DisorientingBoulder new] autorelease]];
    }
}

- (void)ownerDidBeginAbility:(Ability *)ability {
    [self.announcer announce:@"The Troll smashes the cave ceiling"];
    [self.announcer displayScreenShakeForDuration:6.75];
    [self.announcer displayParticleSystemOverRaidWithName:@"falling_rocks.plist"];
}

-(void)startEnraging{
    [self.announcer announce:@"The Troll swings his club furiously at his focused target!"];
    self.enraging += 1.0;
    self.autoAttack.cooldown = .95;
}

-(void)stopEnraging{
    [self.announcer announce:@"The Troll is Exhausted!"];
    self.enraging = 0.0;
    self.autoAttack.cooldown = 1.4;
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
    Drake *drake = [[Drake alloc] initWithHealth:400000 damage:0 targets:0 frequency:0 choosesMT:NO ];
    [drake setTitle:@"Tainted Drake"];
    [drake setInfo:@"A Tainted Drake is hidden in the Paragon Cliffs. You and your allies must stop the beast from doing any more damage to the Kingdom.  The king will provide you with a great reward for defeating the beast."];
    
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
    MischievousImps *boss = [[MischievousImps alloc] initWithHealth:405000 damage:0 targets:0 frequency:2.25 choosesMT:NO];
    [boss removeAbility:boss.autoAttack];
    boss.autoAttack = [[[SustainedAttack alloc] initWithDamage:340 andCooldown:2.25] autorelease];
    boss.autoAttack.failureChance = .25;
    [boss addAbility:boss.autoAttack];
    
    [boss setTitle:@"Mischievious Imps"];
    [boss setInfo:@" A local alchemist has posted a small reward for removing a pesky imp infestation from her store.  Sensing something a little more sinister a small party has been dispatched from the Light Ascendant just in case there is more than meets the eye."];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"imp_throw1" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/imp_throw1" ofType:@"m4a"]]];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"imp_throw2" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/imp_throw2" ofType:@"m4a"]]];
    return [boss autorelease];
}

-(void)dealloc{
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"imp_throw1"];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"imp_throw2"];
    [super dealloc];
}

-(void)throwPotionToTarget:(RaidMember *)target withDelay:(float)delay{
    NSInteger possiblePotions = 2;
    if (self.difficulty > 4) {
        possiblePotions = 3;
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
        //        if (self.difficulty == DifficultyModeHard) {
        //            damage *= 1.25;
        //        }
        [bottleEffect setValue:damage];
        [target addEffect:bottleEffect];
    } else if (potion == 2) {
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
            [self throwPotionToTarget:[theRaid randomLivingMember] withDelay:0.0];
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
                [self throwPotionToTarget:member withDelay:0.0];
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
    
    BefouledTreant *boss = [[BefouledTreant alloc] initWithHealth:580000 damage:bossDamage targets:1 frequency:3.0 choosesMT:YES ];
    boss.autoAttack.failureChance = .25;
    [boss setTitle:@"Befouled Treant"];
    [boss setInfo:@"The Akarus, an ancient tree that has sheltered travelers across the Gungoro Plains, has become tainted with the foul energy of The Dark Winds.  It is lashing its way through villagers and farmers.  This once great tree must be ended for good."];
    
    
    Cleave *cleave = [Cleave normalCleave];
    [cleave setAbilityValue:400]; //Gotta tone this shit down.  It's a bit too hard =/
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
    NSInteger branchInitialDamage = 260;
    NSInteger branchDoTTick = -40;
    
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
    [self.announcer announce:@"The Treant's roots move the earth."];
    [self.announcer displayScreenShakeForDuration:6.0];
    for (RaidMember *member in raid.raidMembers){
        RepeatedHealthEffect *rootquake = [[RepeatedHealthEffect alloc] initWithDuration:6.0 andEffectType:EffectTypeNegativeInvisible];
        [rootquake setOwner:self];
        [rootquake setValuePerTick:-50];
        [rootquake setNumOfTicks:4];
        [rootquake setTitle:@"rootquake"];
        [member addEffect:[rootquake autorelease]];
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 97.0 || percentage == 75.0 || percentage == 51.0 || percentage == 30.0){
        [self.announcer announce:@"The Befouled Treant's pulls its enormous branches back to lash out at your allies."];
    }
    if (percentage == 96.0 || percentage == 74.0 || percentage == 50.0 || percentage == 29.0){
        [self performBranchAttackOnRaid:raid];
    }
}
@end

@implementation FungalRavagers
@synthesize isEnraged, secondTargetAttack, thirdTargetAttack;
+(id)defaultBoss {
    FungalRavagers *boss = [[FungalRavagers alloc] initWithHealth:580000 damage:152 targets:1 frequency:2.0 choosesMT:YES ];
    boss.autoAttack.failureChance = .25;
    [boss setTitle:@"Fungal Ravagers"];
    [boss setInfo:@"Royal scouts report toxic spores are bursting from the remains of the colossus slain a few days prior near the outskirts of Theranore.  The spores are releasing a dense fog into a near-by village, and no-one has been able to get close enough to the town to investigate. Conversely, no villagers have left the town, either..."];
    [boss setCriticalChance:.5];
    
    FocusedAttack *secondFocusedAttack = [[FocusedAttack alloc] initWithDamage:180 andCooldown:2.6];
    secondFocusedAttack.failureChance = .25;
    [boss addAbility:secondFocusedAttack];
    [boss setSecondTargetAttack:secondFocusedAttack];
    [secondFocusedAttack release];
    FocusedAttack *thirdFocusedAttack = [[FocusedAttack alloc] initWithDamage:213 andCooldown:3.2];
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
    
    NSInteger numTargets = arc4random() % 3 + 3;
    
    NSArray *members = [raid randomTargets:numTargets withPositioning:Any];
    for (RaidMember *member in members){
        NSInteger damage = arc4random() % 350 + 550;
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
            [rhe setValuePerTick:-(arc4random() % 16 + 6)];
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
    PlaguebringerColossus *boss = [[PlaguebringerColossus alloc] initWithHealth:580000 damage:330 targets:1 frequency:2.5 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Plaguebringer Colossus"];
    [boss setInfo:@"From the west a foul beast is making its way from the Pits of Ulgrust towards a village on the outskirts of Theranore.  This putrid wretch is sure to destroy the village if not stopped. You must lead this group to victory against the wretched beast."];
    
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
    [boss setInfo:@"Before the dark winds came, Trulzar was a teacher at the Academy of Alchemists.  Since then, Trulzar has drawn into seclusion and begun practicing dark magic.  Trulzar has been identified as a Maleficar by the Theranorian Sages."];
    
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
        [[AudioController sharedInstance] addNewPlayerWithTitle:@"trulzar_laugh" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/trulzar_laugh" ofType:@"m4a"]]];
        [[AudioController sharedInstance] addNewPlayerWithTitle:@"trulzar_death" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/trulzar_death" ofType:@"m4a"]]];
    }
    return self;
}

-(void)dealloc{
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"trulzar_laugh"];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"trulzar_death"];
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
    [boss setNamePlateTitle:@"Roth"];
    [boss setInfo:@"A note scribbled in blood was found in Trulzar's quarters.  It mentions a Council responsible for The Dark Winds plaguing Theranore.  Go to the crypt beneath The Hollow and discover what this Council is up to."];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"roth_entrance" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/roth_entrance" ofType:@"m4a"]]];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"roth_death" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/roth_death" ofType:@"m4a"]]];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"grimgon_entrance" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/grimgon_entrance" ofType:@"m4a"]]];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"grimgon_death" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/grimgon_death" ofType:@"m4a"]]];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"serevon_entrance" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/serevon_entrance" ofType:@"m4a"]]];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"serevon_death" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/serevon_death" ofType:@"m4a"]]];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"galcyon_entrance" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/galcyon_entrance" ofType:@"m4a"]]];
    [[AudioController sharedInstance] addNewPlayerWithTitle:@"galcyon_death" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/galcyon_death" ofType:@"m4a"]]];
    return [boss autorelease];
}

-(void)dealloc{
    [rothVictim release];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"roth_entrance"];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"roth_death"];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"grimgon_entrance"];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"grimgon_death"];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"serevon_entrance"];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"serevon_death"];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"galcyon_entrance"];
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"galcyon_death"];
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
            RothPoison *poison = [[RothPoison alloc] initWithDuration:30.0 andEffectType:EffectTypeNegative];
            [poison setOwner:self];
            [poison setTitle:@"roth_poison"];
            [poison setSpriteName:@"poison.png"];
            [poison setAilmentType:AilmentPoison];
            [poison setNumOfTicks:15];
            [poison setValuePerTick:-100];
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
        [self setAttackDamage:0];
        [self.announcer announce:@"The room fills with demonic laughter."];
    }
    if (percentage == 97.0){
        //Roth of the Shadows steps forward
        self.phase = 1;
        [self.announcer announce:@"Roth, The Toxin Mage steps forward."];
        [[AudioController sharedInstance] playTitle:@"roth_entrance"];
        AbilityDescriptor *rothDesc = [[AbilityDescriptor alloc] init];
        [rothDesc setAbilityDescription:@"Roth channels a curse on an ally dealing increasing damage over time.  When this curse is dispelled it will explode dealing moderate damage to all of your allies."];
        [rothDesc setIconName:@"unknown_ability.png"];
        [rothDesc setAbilityName:@"Curse of Detonation"];
        [self addAbilityDescriptor:rothDesc];
        [rothDesc release];
    }
    
    if (percentage == 75.0){
        [self clearExtraDescriptors];
        //Roth dies
        [[AudioController sharedInstance] playTitle:@"roth_death"];
        [self.announcer announce:@"Roth falls to his knees.  Grimgon, The Darkener takes his place."];
        self.phase = 2;
    }
    if (percentage == 74.0){
        [[AudioController sharedInstance] playTitle:@"grimgon_entrance"];
        AbilityDescriptor *grimgonDesc = [[AbilityDescriptor alloc] init];
        [grimgonDesc setAbilityDescription:@"Grimgon fires vile green bolts at his enemies dealing damage and causing the targets to have healing done to them reduced by 50%."];
        [grimgonDesc setIconName:@"unknown_ability.png"];
        [grimgonDesc setAbilityName:@"Poisonball"];
        [self addAbilityDescriptor:grimgonDesc];
        [grimgonDesc release];
    }
    
    if (percentage == 50.0){
        [self clearExtraDescriptors];
        [[AudioController sharedInstance] playTitle:@"grimgon_death"];
        [self.announcer announce:@"Grimgon fades to nothing.  Serevon, Anguish Mage cackles with glee."];
        //Serevon, Anguish Mage steps forward
        self.phase = 3;
        [self setAttackDamage:270];
        self.autoAttack.failureChance = .25;
    }
    if (percentage == 49.0){
        [[AudioController sharedInstance] playTitle:@"serevon_entrance"];
        AbilityDescriptor *serevonDesc = [[AbilityDescriptor alloc] init];
        [serevonDesc setAbilityDescription:@"Periodically, Serevon summons a dark cloud over all of your allies that deals more damage to lower health allies and weakens healing magic."];
        [serevonDesc setIconName:@"unknown_ability.png"];
        [serevonDesc setAbilityName:@"Choking Cloud"];
        [self addAbilityDescriptor:serevonDesc];
        [serevonDesc release];
    }
    
    if (percentage == 25.0){
        [self clearExtraDescriptors];
        //Galcyon, Lord of the Dark Council steps forward
        [[AudioController sharedInstance] playTitle:@"serevon_death"];
        [self.announcer announce:@"Galcyon, Overlord of Darkness pushes away Serevon's corpse and slithers into the fray."];
        self.phase = 4;
    }
    
    if (percentage == 24.0){
        [[AudioController sharedInstance] playTitle:@"galcyon_entrance"];
    }
    
    if (percentage == 23.0){
        for (RaidMember *member in raid.raidMembers){
            [self shootProjectileAtTarget:member withDelay:0.0];
        }
    }
    
    if (percentage == 5.0){
        [[AudioController sharedInstance] playTitle:@"galcyon_death"];
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
    [boss setInfo:@"You and your soldiers have taken the fight straight to the warcamps of Baraghast--Leader of the Dark Horde.  You have been met outside the gates by only two heavily armored demon warriors.  These Champions of Baraghast will stop at nothing to keep you from finding Baraghast."];
    
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
        
        NSInteger axeSweepDamage = arc4random() % 200 + 200;
        
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
    Baraghast *boss = [[Baraghast alloc] initWithHealth:3040000 damage:150 targets:1 frequency:1.25 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Baraghast, Warlord of the Damned"];
    [boss setNamePlateTitle:@"Baraghast"];
    [boss setInfo:@"With his champions defeated, Baraghast himself confronts you and your allies."];
    
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
    [seer setInfo:@"Seer Tyonath was tormented and tortured after his capture by the Dark Horde.  The Darkness has driven him mad.  He guards the secrets to Baraghast's origin in the vaults beneath the Dark Horde's largest encampment - Serevilost."];
    
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
    [horrifyingLaugh setAbilityValue:150];
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
    [boss setInfo:@"Delsarn is the name the Theronian Seers have given to the land that exists beyond the rift discovered within the tome that Seer Tyonath left behind.  The Gatekeeper is a foul beast that stands between your party and passage into Delsarn."];
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
    [boss setInfo:@"After moving beyond the gates of Delsarn, you encounter a horrifying Skeletal Dragon.  It assaults your party and bars the way."];
    [boss setTitle:@"Skeletal Dragon"];
    
    boss.boneThrowAbility = [[[BoneThrow alloc] init] autorelease];
    [boss.boneThrowAbility  setCooldown:5.0];
    [boss addAbility:boss.boneThrowAbility];
    
    boss.sweepingFlame = [[[TargetTypeFlameBreath alloc] init] autorelease];
    [boss.sweepingFlame setCooldown:9.0];
    [boss.sweepingFlame setAbilityValue:550];
    [(TargetTypeFlameBreath*)boss.sweepingFlame setNumTargets:5];
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
    [cob setInfo:@"While traveling even deeper into Delsarn you and your allies are waylayed by a towering creature of unimaginable strength."];
    
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
    [boss setInfo:@"After defeating his most powerful beasts, the Overseer of this treacherous realm confronts you himself.  He bars your way into the inner sanctum."];
    
    boss.projectilesAbility = [[[OverseerProjectiles alloc] init] autorelease];
    [boss.projectilesAbility setAbilityValue:560];
    [boss.projectilesAbility setCooldown:1.5];
    [boss addAbility:boss.projectilesAbility];
    
    boss.demonAbilities = [NSMutableArray arrayWithCapacity:3];
    
    BloodMinion *bm = [[BloodMinion alloc] init];
    [bm setTitle:@"blood-minion"];
    [bm setCooldown:10.0];
    [bm setAbilityValue:100];
    [boss.demonAbilities addObject:bm];
    [bm release];
    
    FireMinion *fm = [[FireMinion alloc] init];
    [fm setTitle:@"fire-minion"];
    [fm setCooldown:15.0];
    [fm setAbilityValue:350];
    [boss.demonAbilities addObject:fm];
    [fm release];
    
    ShadowMinion *sm = [[ShadowMinion alloc] init];
    [sm setTitle:@"shadow-minion"];
    [sm setCooldown:12.0];
    [sm setAbilityValue:170];
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
        self.projectilesAbility.abilityValue = 480.0;
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
    [boss setInfo:@"A disgusting mass of bones and rotten corpses waits in a crypt beneath Delsarn.  It seems to be ... alive."];
    
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
    BaraghastReborn *boss = [[BaraghastReborn alloc] initWithHealth:3400000 damage:150 targets:1 frequency:1.25 choosesMT:YES ];
    boss.autoAttack.failureChance = .30;
    [boss setTitle:@"Baraghast Reborn"];
    [boss setInfo:@"Before you stands the destroyed but risen warchief Baraghast.  His horrible visage once again sows fear in the hearts of all of your allies.  This time he is not only guarding a terrible secret, but his hateful gaze reveals his true purpose -- Revenge."];
    
    [boss addAbility:[Cleave normalCleave]];
    
    BaraghastRoar *roar = [[[BaraghastRoar alloc] init] autorelease];
    [roar setCooldown:24.0];
    [roar setTitle:@"baraghast-roar"];
    [boss addAbility:roar];
    
    boss.deathwave = [[[Deathwave alloc] init] autorelease];
    [boss.deathwave  setCooldown:kAbilityRequiresTrigger];
    [boss.deathwave  setTitle:@"deathwave"];
    [boss addAbility:boss.deathwave ];
    
    GraspOfTheDamnedEffect *graspEffect = [[[GraspOfTheDamnedEffect alloc] initWithDuration:8.0 andEffectType:EffectTypeNegative] autorelease];
    [graspEffect setNumOfTicks:6];
    [graspEffect setValuePerTick:-100];
    [graspEffect setSpriteName:@"blood_curse.png"];
    [graspEffect setTitle:@"grasp-of-the-damned-eff"];
    [graspEffect setAilmentType:AilmentTrauma];
    GraspOfTheDamned *graspOfTheDamned = [[[GraspOfTheDamned alloc] initWithDamage:0 andCooldown:15.0] autorelease];
    [boss addAbility:graspOfTheDamned];
    [graspOfTheDamned setAppliedEffect:graspEffect];
    return [boss autorelease];
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
    if (percentage == 99.0 || percentage == 80.0 || percentage == 60.0 || percentage == 40.0 || percentage == 20.0){
        [self.deathwave triggerAbilityForRaid:raid andPlayers:[NSArray arrayWithObject:player]];
    }
    
}
@end

@implementation AvatarOfTorment1
+ (id)defaultBoss {
    AvatarOfTorment1 *boss = [[AvatarOfTorment1 alloc] initWithHealth:2880000 damage:0 targets:0 frequency:0.0 choosesMT:NO ];
    [boss setTitle:@"The Avatar of Torment"];
    [boss setNamePlateTitle:@"Torment"];
    [boss setInfo:@"From the fallen black heart of Baraghast's shattered soul rose a portal into another plane of existence.  Your allies cautiously moved through the portal and found themselves in a terrifying realm surrounded by shackled and burning souls.  Before you stands a massive creature of spawned of pure hatred and built for torment.  The final battle for your realm's purity begins now."];
    
    DisruptionCloud *dcAbility = [[DisruptionCloud alloc] init];
    [dcAbility setTitle:@"dis-cloud"];
    [dcAbility setCooldown:23.0];
    [dcAbility setAbilityValue:20];
    [dcAbility setTimeApplied:20.0];
    [boss addAbility:dcAbility];
    [dcAbility release];
    
    ProjectileAttack *projectileAttack = [[ProjectileAttack alloc] init];
    [projectileAttack setSpriteName:@"purple_fireball.png"];
    [projectileAttack setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack setAbilityValue:-500];
    [projectileAttack setCooldown:2.5];
    [projectileAttack setFailureChance:.7];
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
    [self.announcer announce:@"\"YOUR SOULS BELONG TO THE ABYSS\""];
    for (RaidMember *member in raid.livingMembers) {
        SoulPrisonEffect *spe = [[[SoulPrisonEffect alloc] initWithDuration:60.0 andEffectType:EffectTypeNegative] autorelease];
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
    
    if (percentage == 90.0 || percentage == 50.0) {
        [self soulPrisonAll:raid];
        SoulPrison *spAbility = [[[SoulPrison alloc] init] autorelease];
        [spAbility setTitle:@"soul-prison"]; 
        [spAbility setCooldown:30.0];
        [spAbility setTimeApplied:-60.0];
        [spAbility setAbilityValue:7];
        [self addAbility:spAbility];
    }
    
    if (percentage == 72.0) {
        [self.announcer announce:@"The Avatar of Torment cackles maniacally and pulses with power."];
    }
    
    if (percentage == 70.0) {
        WaveOfTorment *wot = [[[WaveOfTorment alloc] init] autorelease];
        [wot setTitle:@"wot"];
        [wot setCooldown:40.0];
        [wot setTimeApplied:39.0];
        [wot setAbilityValue:100];
        [self addAbility:wot];
    }
    
    if (percentage == 41.0) {
        [self.announcer announce:@"The Avatar of Torment drains your mind"];
    }
    if (percentage == 40.0) {
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
    [boss setInfo:@"The Avatar of Torment will not be defeated so easily."];
    
    DisruptionCloud *dcAbility = [[DisruptionCloud alloc] init];
    [dcAbility setTitle:@"dis-cloud"];
    [dcAbility setCooldown:23.0];
    [dcAbility setAbilityValue:30];
    [dcAbility setTimeApplied:20.0];
    [boss addAbility:dcAbility];
    [dcAbility release];
    
    ProjectileAttack *projectileAttack = [[ProjectileAttack alloc] init];
    [projectileAttack setSpriteName:@"purple_fireball.png"];
    [projectileAttack setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack setAbilityValue:-500];
    [projectileAttack setCooldown:.75];
    [projectileAttack setFailureChance:.85];
    [boss addAbility:projectileAttack];
    [projectileAttack release];
    
    ProjectileAttack *projectileAttack2 = [[ProjectileAttack alloc] init];
    [projectileAttack2 setSpriteName:@"purple_fireball.png"];
    [projectileAttack2 setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack2 setAbilityValue:-500];
    [projectileAttack2 setCooldown:.83];
    [projectileAttack2 setFailureChance:.85];
    [boss addAbility:projectileAttack2];
    [projectileAttack2 release];
    
    ProjectileAttack *projectileAttack3 = [[ProjectileAttack alloc] init];
    [projectileAttack3 setSpriteName:@"purple_fireball.png"];
    [projectileAttack3 setExplosionParticleName:@"shadow_burst.plist"];
    [projectileAttack3 setAbilityValue:-350];
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
        [wot setAbilityValue:100];
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
        [confusionAbility setAbilityValue:8.0];
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
    SoulOfTorment *boss = [[SoulOfTorment alloc] initWithHealth:5040000 damage:0 targets:0 frequency:0.0 choosesMT:NO];
    
    FocusedAttack *tankAttack = [[[FocusedAttack alloc] initWithDamage:500 andCooldown:2.25] autorelease];
    [tankAttack setFailureChance:.18];
    [boss addAbility:tankAttack];
    boss.autoAttack = tankAttack;
    
    [boss setTitle:@"The Soul of Torment"];
    [boss setNamePlateTitle:@"Torment"];
    [boss setInfo:@"Its body shattered and broken--the last gasp of this terrible creature conspires to unleash its most unspeakable power.  This is the last stand of your realm against the evil that terrorizes it."];
    
    RaidDamagePulse *pulse = [[[RaidDamagePulse alloc] init] autorelease];
    [pulse setTitle:@"shadow-nova"];
    [pulse setAbilityValue:550];
    [pulse setNumTicks:3];
    [pulse setDuration:15.0];
    [pulse setCooldown:80.0];
    [pulse setTimeApplied:75.0];
    [boss addAbility:pulse];
    
    return [boss autorelease];
}

- (void)gainSoulDrain
{
    [self.announcer announce:@"The Soul of Torment hungers for souls"];

    IRHEDispelsOnHeal *soulDrainEffect = [[[IRHEDispelsOnHeal alloc] initWithDuration:-1 andEffectType:EffectTypeNegative] autorelease];
    [soulDrainEffect setIncreasePerTick:.05];
    [soulDrainEffect setValuePerTick:-80];
    [soulDrainEffect setNumOfTicks:10];
    [soulDrainEffect setSpriteName:@"shadow_curse.png"];
    [soulDrainEffect setTitle:@"soul-drain-eff"];
    
    EnsureEffectActiveAbility *eeaa = [[[EnsureEffectActiveAbility alloc] init] autorelease];
    [eeaa setEnsuredEffect:soulDrainEffect];
    [self addAbility:eeaa];
}


- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player
{
    if (percentage == 90.0) {
        [self.announcer announce:@"You will beg for death."];
        [self gainSoulDrain];
    }

    if (percentage == 70.0) {
        [self.announcer announce:@"Such glorious anguish"];
        [self gainSoulDrain];
    }
    
    if (percentage == 50.0) {
        [self.announcer announce:@"Your cries of pain only strengthen me"];
        [self gainSoulDrain];
    }

    if (percentage == 40.0) {
        [self.announcer announce:@"YOU CANNOT WITHSTAND THIS TORMENT"];
    }
    
    if (percentage == 30.0) {
        [self.announcer announce:@"The Soul of Torment poisons your mind and clouds your vision."];
        Confusion *confusionAbility = [[[Confusion alloc] init] autorelease];
        [confusionAbility setCooldown:14.0];
        [confusionAbility setAbilityValue:8.0];
        [confusionAbility setTitle:@"confusion"];
        [self addAbility:confusionAbility];
        [confusionAbility setTimeApplied:10.0];
    }
    
    if (percentage == 10.0) {
        [self.announcer announce:@"YOUR SOULS WILL BURN IN DARKNESS"];
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

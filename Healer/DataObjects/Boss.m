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


@interface Boss ()
@property (nonatomic, retain) NSMutableArray *queuedAbilitiesToAdd;
@property (nonatomic, readwrite) BOOL shouldQueueAbilityAdds;
@end

@implementation Boss
@synthesize title, logger, announcer, criticalChance, info, isMultiplayer=_isMultiplayer,phase, duration, abilities;
@synthesize queuedAbilitiesToAdd, shouldQueueAbilityAdds;
-(void)dealloc{
    [abilities release];
    [info release];
    [title release];
    [queuedAbilitiesToAdd release];
    [_abilityDescriptors release];
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

-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq andChoosesMT:(BOOL)chooses{
    if (self = [super init]){
        health = hlth;
        maximumHealth = hlth;
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
                FocusedAttack *focusedAttack = [[FocusedAttack alloc] initWithDamage:dmg/trgets andCooldown:freq];
                [self addAbility:focusedAttack];
                [focusedAttack release];
            }else{
                Attack *attack = [[Attack alloc] initWithDamage:dmg/trgets andCooldown:freq];
                [self addAbility:attack];
                [attack release];
            }
        }
        self.queuedAbilitiesToAdd = [NSMutableArray arrayWithCapacity:1];
    }
	return self;
	
}

-(void)updateEffects:(Boss*)theBoss raid:(Raid*)theRaid player:(Player*)thePlayer time:(float)timeDelta{
    NSMutableArray *effectsToRemove = [NSMutableArray arrayWithCapacity:5];
	for (int i = 0; i < [activeEffects count]; i++){
		Effect *effect = [activeEffects objectAtIndex:i];
		[effect combatActions:theBoss theRaid:theRaid thePlayer:thePlayer gameTime:timeDelta];
		if ([effect isExpired]){
			[effect expire];
            [effectsToRemove addObject:effect];
		}
	}
    
    for (Effect *effect in effectsToRemove){
        [self.healthAdjustmentModifiers removeObject:effect];
        [activeEffects removeObject:effect];
    }
}

-(NSString*)networkID{
    return [NSString stringWithFormat:@"B-%@", self.title];
}

-(void)setIsMultiplayer:(BOOL)isMultiplayer{
    _isMultiplayer = isMultiplayer;
    
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
    
    self.shouldQueueAbilityAdds = YES;
    for (Ability *ability in self.abilities){
        [ability combatActions:theRaid boss:self players:players gameTime:timeDelta];
    }
    self.shouldQueueAbilityAdds = NO;
    [self dequeueAbilityAdds];
    
    [self updateEffects:self raid:theRaid player:player time:timeDelta];
}

-(void)setHealth:(NSInteger)newHealth
{
	health = newHealth;
	if (health < 0) health = 0;
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
    Ghoul *ghoul = [[Ghoul alloc] initWithHealth:6750 damage:20 targets:1 frequency:2.0 andChoosesMT:NO];
    [ghoul setTitle:@"The Night Ghoul"];
    [ghoul setInfo:@"A ghoul has found its way onto a nearby farmer's land.  It has already killed the farmer's wife.  You will accompany a small band of mercenaries to dispatch the ghoul."];
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
@synthesize lastRockTime, enraging;
+(id)defaultBoss{
    CorruptedTroll *corTroll = [[CorruptedTroll alloc] initWithHealth:45000 damage:22 targets:1 frequency:1.4 andChoosesMT:YES];
    
    [corTroll setTitle:@"Corrupted Troll"];
    [corTroll setInfo:@"A Troll of Raklor has been identified among the demons brewing in the south.  It has been corrupted and twisted into a foul and terrible creature.  You will journey with a small band of soldiers to the south to dispatch this troll."];
    
    AbilityDescriptor *caveIn = [[AbilityDescriptor alloc] init];
    [caveIn setAbilityDescription:@"Occasionally, the Corrupted Troll will smash the roof causing rocks to fall onto your allies."];
    [caveIn setIconName:@"unknown_ability.png"];
    [caveIn setAbilityName:@"Cave In"];
    [corTroll addAbilityDescriptor:caveIn];
    [caveIn release];
    
    AbilityDescriptor *frenzy = [[AbilityDescriptor alloc] init];
    [frenzy setAbilityDescription:@"Occasionally, the Corrupted Troll will attack his Focused target furiously dealing high damage."];
    [frenzy setIconName:@"unknown_ability.png"];
    [frenzy setAbilityName:@"Frenzy"];
    [corTroll addAbilityDescriptor:frenzy];
    [frenzy release];
    
    return  [corTroll autorelease];
}
-(void)doCaveInOnRaid:(Raid*)theRaid{
    [self.announcer displayScreenShakeForDuration:2.5];
    [self.announcer announce:@"The Corrupted Troll Smashes the cave ceiling"];
    [self.announcer displayPartcileSystemOverRaidWithName:@"falling_rocks.plist"];
    for (RaidMember *member in theRaid.raidMembers){
        if (!member.isDead){
            NSInteger damageDealt = (arc4random() % 20 + 20);
            if (member.isFocused){
                damageDealt = MAX(damageDealt, 25); //The Tank is armored
            }
            [self.logger logEvent:[CombatEvent eventWithSource:self target:member value:[NSNumber numberWithInt:damageDealt] andEventType:CombatEventTypeDamage]];
            [member setHealth:member.health - damageDealt * self.damageDoneMultiplier];
        }
    }
}

-(void)startEnraging{
    [self.announcer announce:@"The Cave Troll Swings his club furiously at the focused target!"];
    self.enraging += 1.0;
    Effect *enragingEffect = [[Effect alloc] initWithDuration:9 andEffectType:EffectTypePositiveInvisible];
    [enragingEffect setTarget:self];
    [enragingEffect setOwner:self];
    [enragingEffect setTitle:@"troll-temp-enrage"];
    [enragingEffect setDamageDoneMultiplierAdjustment:.35];
    [self addEffect:enragingEffect];
    [enragingEffect release];
}

-(void)stopEnraging{
    [self.announcer announce:@"The Cave Troll is Exhausted!"];
    self.enraging = 0.0;
    self.lastRockTime = 5.0;
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 75.0 || percentage == 50.0 || percentage == 20.0){
        [self startEnraging];
    }
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    lastRockTime += timeDelta;
    float tickTime = self.isMultiplayer ? 15.0 : 25.0;
    
    if (lastRockTime > tickTime){
        if (!self.enraging){
            [self doCaveInOnRaid:theRaid];
            lastRockTime = 0.0;
        }
    }
    
    if (self.enraging > 0){
        self.enraging += timeDelta;
        if (self.enraging > 10.0){
            [self stopEnraging];
        }
    }
}
@end

@implementation Drake 
@synthesize lastFireballTime;
+(id)defaultBoss{
    Drake *drake = [[Drake alloc] initWithHealth:52000 damage:16 targets:1 frequency:1.2 andChoosesMT:NO];
    [drake setTitle:@"Tainted Drake"];
    [drake setInfo:@"A Tainted Drake is hidden in the Paragon Cliffs. You and your allies must stop the beast from doing any more damage to the Kingdom.  The king will provide you with a great reward for defeating the beast."];
    
    AbilityDescriptor *fireball = [[AbilityDescriptor alloc] init];
    [fireball setAbilityDescription:@"The Drake hurls deadly Fireballs at your allies."];
    [fireball setIconName:@"unknown_ability.png"];
    [fireball setAbilityName:@"Spit Fireball"];
    [drake addAbilityDescriptor:fireball];
    [fireball release];
    
    return [drake autorelease];
}

-(void)shootFireballAtTarget:(RaidMember*)target withDelay:(float)delay{
    float colTime = (1.5 + delay);
    DelayedHealthEffect *fireball = [[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
    
    ProjectileEffect *fireballVisual = [[ProjectileEffect alloc] initWithSpriteName:@"fireball.png" target:target andCollisionTime:colTime];
    [fireballVisual setCollisionParticleName:@"fire_explosion.plist"];
    [self.announcer displayProjectileEffect:fireballVisual];
    [fireballVisual release];
    [fireball setOwner:self];
    [fireball setIsIndependent:YES];
    [fireball setFailureChance:.15];
    [fireball setValue:-(arc4random() % 20 + 25)];
    [target addEffect:fireball];
    [fireball release];
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    
    self.lastFireballTime += timeDelta;
    float tickTime = self.isMultiplayer ? 3.5 : 4.0;
    if (self.lastFireballTime > tickTime){
        [self shootFireballAtTarget:[theRaid randomLivingMember] withDelay:0.0];
        self.lastFireballTime = 0;
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (self.isMultiplayer ? (percentage == 75.0 || percentage == 50.0 || percentage == 25.0) : (percentage == 50.0) ){
        int i = 0;
        for (RaidMember *member in raid.raidMembers){
            if (!member.isDead){
                [self shootFireballAtTarget:member withDelay:i * .75];
            }
            i++;
        }
    }
}
@end

@implementation Trulzar
@synthesize lastPoisonTime, lastPotionTime;
+(id)defaultBoss{
    Trulzar *boss = [[Trulzar alloc] initWithHealth:320000 damage:50 targets:2 frequency:3.0 andChoosesMT:NO];
    [boss setTitle:@"Trulzar the Maleficar"];
    [boss setInfo:@"Before the dark winds came, Trulzar was an aide to the King of Theranore and a teacher at the Academy of Alchemists.  Since the Dark winds, Trulzar has drawn into seclusion.  No one had heard from him for years until a brash student who had heard of his exploits paid him a visit.  The student was not heard from for days until a walking corpse that was later identified as the student was slaughtered at the gates by guardsmen.  Trulzar has been identified as a Maleficar by the Theranorian Sages."];
    
    AbilityDescriptor *poison = [[AbilityDescriptor alloc] init];
    [poison setAbilityDescription:@"Trulzar fills an allies veins with poison dealing increasing damage over time.  This effect may be removed with the Purify spell."];
    [poison setIconName:@"unknown_ability.png"];
    [poison setAbilityName:@"Necrotic Venom"];
    [boss addAbilityDescriptor:poison];
    [poison release];
    return [boss autorelease];
}



-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq andChoosesMT:(BOOL)chooses{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq andChoosesMT:chooses]){
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
    [poisonEffect setValuePerTick:-12];
    [poisonEffect setNumOfTicks:30];
    [poisonEffect setTitle:@"trulzar-poison1"];
    [target addEffect:poisonEffect];
    
    NSInteger upfrontDamage = (arc4random() % 20) * self.damageDoneMultiplier;
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
    [poisonEffect setValuePerTick:-4];
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
    [bottleVisual setSpriteColor:ccc3(0, 255, 0)];
    [self.announcer displayThrowEffect:bottleVisual];
    [bottleVisual release];
    [bottleEffect setIsIndependent:YES];
    [bottleEffect setOwner:self];
    [bottleEffect setValue:-45];
    [target addEffect:bottleEffect];
    [bottleEffect release];    
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    self.lastPoisonTime += timeDelta;
    self.lastPotionTime += timeDelta;
    
    float tickTime = self.isMultiplayer ? 5 : 10;
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
        [[AudioController sharedInstance] playTitle:@"trulzar_death"];
        for (RaidMember *member in raid.raidMembers){
            [self applyWeakPoisonToTarget:member];
        }
    }
}

@end

@implementation DarkCouncil
@synthesize lastPoisonballTime, rothVictim, lastDarkCloud;
+(id)defaultBoss{
    DarkCouncil *boss = [[DarkCouncil alloc] initWithHealth:340000 damage:0 targets:1 frequency:.75 andChoosesMT:NO];
    [boss setTitle:@"Council of Dark Summoners"];
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
        [dcEffect setValuePerTick:-3];
        [dcEffect setNumOfTicks:3];
        [member addEffect:dcEffect];
        [dcEffect release];
    }
    [self.announcer displayPartcileSystemOnRaidWithName:@"purple_mist.plist" forDuration:-1.0];
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
    [fireball setValue:self.isMultiplayer ? -(arc4random() % 20 + 30) : -(arc4random() % 10 + 30)];
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
            [poison setValuePerTick:-10];
            [poison setDispelDamageValue:-20];
            [self.rothVictim addEffect:[poison autorelease]];
        }
    }
    
    if (self.phase == 2){
        //Grimgon
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
        self.lastDarkCloud += timeDelta;
        float tickTime = 18.0;
        if (self.lastDarkCloud > tickTime){
            [self summonDarkCloud:theRaid];
            self.lastDarkCloud = 0.0;
        }
    }
    
    if (self.phase == 4){
        
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
        [self setAttackDamage:20];
    }
    if (percentage == 49.0){
        [[AudioController sharedInstance] playTitle:@"serevon_entrance"];
        AbilityDescriptor *serevonDesc = [[AbilityDescriptor alloc] init];
        [serevonDesc setAbilityDescription:@"Periodically, Serevon summons a dark cloud over all of your allies that deals more damage to lower health allies."];
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


@implementation PlaguebringerColossus
@synthesize lastSickeningTime, numBubblesPopped;
+(id)defaultBoss{
    //427500
    PlaguebringerColossus *boss = [[PlaguebringerColossus alloc] initWithHealth:250000 damage:30 targets:2 frequency:2.5 andChoosesMT:YES];
    [boss setTitle:@"Plaguebringer Colossus"];
    [boss setInfo:@"From the west a foul beast is making its way from the Pits of Ulgrust towards a village on the outskirts of Theranore.  This putrid wretch is sure to destroy the village if not stopped.  The village people have foreseen their impending doom and sent young and brave hopefuls to join The Light Ascendant in exchange for protection.  You must lead this group to victory against the wretched beast."];
    
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
    
    return [boss autorelease];
}

-(void)sickenTarget:(RaidMember *)target{
    ExpiresAtFullHealthRHE *infectedWound = [[ExpiresAtFullHealthRHE alloc] initWithDuration:30.0 andEffectType:EffectTypeNegative];
    [infectedWound setOwner:self];
    [infectedWound setTitle:@"pbc-infected-wound"];
    [infectedWound setAilmentType:AilmentTrauma];
    [infectedWound setValuePerTick: self.isMultiplayer ? -8 : -4];
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
            RepeatedHealthEffect *singleTickDot = [[RepeatedHealthEffect alloc] initWithDuration:1.5 andEffectType:EffectTypeNegative];
            [singleTickDot setOwner:self];
            [singleTickDot setTitle:@"pbc-pussBubble"];
            [singleTickDot setNumOfTicks:1];
            [singleTickDot setAilmentType:AilmentPoison];
            [singleTickDot setValuePerTick:-50];
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
    float tickTime = self.isMultiplayer ? 7.0 : 15.0;
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

@implementation SporeRavagers
@synthesize isEnraged, secondTargetAttack, thirdTargetAttack;
+(id)defaultBoss{
    SporeRavagers *boss = [[SporeRavagers alloc] initWithHealth:405000 damage:14 targets:1 frequency:2.5 andChoosesMT:YES];
    [boss setTitle:@"Spore Ravagers"];
    [boss setInfo:@"Royal scouts report toxic spores are bursting from the remains of the colossus slain a few days prior near the outskirts of Theranore.  The spores are releasing a dense fog into a near-by village, and no-one has been able to get close enough to the town to investigate. Conversely, no villagers have left the town, either..."];
    [boss setCriticalChance:.5];
    
    FocusedAttack *secondFocusedAttack = [[FocusedAttack alloc] initWithDamage:14 andCooldown:2.6];
    [boss addAbility:secondFocusedAttack];
    [boss setSecondTargetAttack:secondFocusedAttack];
    [secondFocusedAttack release];
    FocusedAttack *thirdFocusedAttack = [[FocusedAttack alloc] initWithDamage:14 andCooldown:2.7];
    [boss addAbility:thirdFocusedAttack];
    [boss setThirdTargetAttack:thirdFocusedAttack];
    [thirdFocusedAttack release];
    
    AbilityDescriptor *vileExploDesc = [[AbilityDescriptor alloc] init];
    [vileExploDesc setAbilityDescription:@"When a Spore Ravager dies, it explodes dealing high damage to random nearby targets."];
    [vileExploDesc setIconName:@"unknown_ability.png"];
    [vileExploDesc setAbilityName:@"Vile Explosion"];
    [boss addAbilityDescriptor:vileExploDesc];
    [vileExploDesc release];
    
    return [boss autorelease];
}

-(void)ravagerDiedFocusing:(RaidMember*)focus andRaid:(Raid*)raid{
    [self.announcer announce:@"A Spore Ravager falls to the ground and explodes!"];
    [focus setIsFocused:NO];
    for (int i = 0; i < 5; i++){
        RaidMember *member = [raid randomLivingMember];
        [member setHealth:member.health - 50 * self.damageDoneMultiplier];
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    
    if (percentage == 96.0){
        [self.announcer announce:@"A putrid green mist fills the area..."];
        [self.announcer displayPartcileSystemOnRaidWithName:@"green_mist.plist" forDuration:-1.0];
        for (RaidMember *member in raid.raidMembers){
            RepeatedHealthEffect *rhe = [[RepeatedHealthEffect alloc] initWithDuration:300 andEffectType:EffectTypeNegativeInvisible];
            [rhe setOwner:self];
            [rhe setTitle:@"spore-ravager-mist"];
            [rhe setValuePerTick:self.isMultiplayer ? -4 : -2];
            [rhe setNumOfTicks:60];
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
        [self.announcer announce:@"The last remaining Spore Ravager glows with rage."];
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

@implementation MischievousImps
@synthesize lastPotionThrow;
+(id)defaultBoss{
    MischievousImps *boss = [[MischievousImps alloc] initWithHealth:50000 damage:27 targets:1 frequency:2.25 andChoosesMT:YES];
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
    int potion = arc4random() % 2;
    float colTime = (1.5 + delay);

    if (potion == 0){
        //Liquid Fire
        ImpLightningBottle* bottleEffect = [[ImpLightningBottle alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
        
        ProjectileEffect *bottleVisual = [[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime];
        [bottleVisual setSpriteColor:ccc3(255, 0, 0 )];
        [self.announcer displayThrowEffect:bottleVisual];
        [bottleVisual release];
        [bottleEffect setIsIndependent:YES];
        [bottleEffect setOwner:self];
        [target addEffect:bottleEffect];
        [bottleEffect release];
        
    }else if (potion == 1){
        //Lightning In a Bottle
        DelayedHealthEffect *bottleEffect = [[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
        
        ProjectileEffect *bottleVisual = [[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime];
        [bottleVisual setSpriteColor:ccc3(0, 128, 128)];
        [self.announcer displayThrowEffect:bottleVisual];
        [bottleVisual release];
        [bottleEffect setIsIndependent:YES];
        [bottleEffect setOwner:self];
        [(ImpLightningBottle*)bottleEffect setValue:-45];
        [target addEffect:bottleEffect];
        [bottleEffect release];
    }
    
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];
    if (self.healthPercentage > 30.0){
        self.lastPotionThrow+=timeDelta;
        float tickTime = self.isMultiplayer ? 6.0 : 12.0;
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
    
    if (self.isMultiplayer && percentage == 75.0){
        for (RaidMember *member in raid.raidMembers){
            if (!member.isDead){
                [self throwPotionToTarget:member withDelay:0.0];
            }
        }
        [self.announcer announce:@"An imp angrily hurls the entire case of flasks at you!"];
        [[AudioController sharedInstance] playTitle:[NSString stringWithFormat:@"imp_throw1"]];
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
    
    if (percentage == 20.0){
        [self.announcer announce:@"All of the imps angrily pounce on their focused target!"];
        [self setAttackSpeed:1.2];
    }
}
@end

@implementation BefouledTreat
@synthesize lastRootquake;
+(id)defaultBoss{
    BefouledTreat *boss = [[BefouledTreat alloc] initWithHealth:100000 damage:35 targets:1 frequency:3.0 andChoosesMT:YES];
    [boss setTitle:@"Befouled Treant"];
    [boss setInfo:@"The Akarus, an ancient tree that has sheltered travelers across the Gungoro Plains, has become tainted with the foul energy of The Dark Winds.  It is lashing its way through villagers and farmers.  This once great tree must be ended for good."];
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
    for (RaidMember *member in raid.raidMembers){
        [member setHealth:member.health - 26 * self.damageDoneMultiplier];
        [self.logger logEvent:[CombatEvent eventWithSource:self target:member value:[NSNumber numberWithInt:26 * self.damageDoneMultiplier] andEventType:CombatEventTypeDamage]];
        RepeatedHealthEffect *lashDoT = [[RepeatedHealthEffect alloc] initWithDuration:5.0 andEffectType:EffectTypeNegative];
        [lashDoT setOwner:self];
        [lashDoT setTitle:@"lash"];
        [lashDoT setAilmentType:AilmentTrauma];
        [lashDoT setValuePerTick:-4];
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
        [rootquake setValuePerTick:-4];
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


@implementation TwinChampions
@synthesize firstFocusedAttack, secondFocusedAttack;
@synthesize lastAxecution, lastGushingWound;
+(id)defaultBoss{
    NSInteger damage = 15;
    float frequency = 1.30;
    TwinChampions *boss = [[TwinChampions alloc] initWithHealth:430000 damage:damage targets:1 frequency:frequency andChoosesMT:YES];
    [boss setFirstFocusedAttack:[[boss abilities] objectAtIndex:0]];
    
    FocusedAttack *secondFA = [[FocusedAttack alloc] initWithDamage:damage * 4 andCooldown:frequency * 5];
    [boss setSecondFocusedAttack:secondFA];
    [boss addAbility:secondFA];
    [secondFA release];
    
    [boss setTitle:@"Twin Champions of Baraghast"];
    [boss setInfo:@"You and your soldiers have taken the fight straight to the warcamps of Baraghast--Leader of the Dark Horde.  You have been met outside the gates by only two heavily armored demon warriors.  These Champions of Baraghast will stop at nothing to keep you from finding Baraghast."];
    
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
        
        DelayedHealthEffect *axeSweepEffect = [[DelayedHealthEffect alloc] initWithDuration:i * .5 andEffectType:EffectTypeNegativeInvisible];
        [axeSweepEffect setOwner:self];
        [axeSweepEffect setTitle:@"axesweep"];
        [axeSweepEffect setValue:-20 * (1 + ((float)deadCount/(float)theRaid.raidMembers.count))];
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
    [target setHealth:target.maximumHealth * .4];
    ExecutionEffect *effect = [[ExecutionEffect alloc] initWithDuration:3.75 andEffectType:EffectTypeNegative];
    [effect setOwner:self];
    [effect setValue:-200];
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
        [axeThrownEffect setValue:-25];
        [axeThrownEffect setIsIndependent:YES];
        
        IntensifyingRepeatedHealthEffect *gushingWoundEffect = [[IntensifyingRepeatedHealthEffect alloc] initWithDuration:9.0 andEffectType:EffectTypeNegative];
        [gushingWoundEffect setSpriteName:@"bleeding.png"];
        [gushingWoundEffect setAilmentType:AilmentTrauma];
        [gushingWoundEffect setIncreasePerTick:.5];
        [gushingWoundEffect setValuePerTick:-23];
        [gushingWoundEffect setNumOfTicks:3];
        [gushingWoundEffect setOwner:self];
        [gushingWoundEffect setTitle:@"gushingwound"];
        
        [axeThrownEffect setAppliedEffect:gushingWoundEffect];
        
        [target addEffect:axeThrownEffect];
        
        ProjectileEffect *axeVisual = [[ProjectileEffect alloc] initWithSpriteName:@"axe.png" target:target andCollisionTime:1.5];
        [self.announcer displayThrowEffect:axeVisual];
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
@synthesize autoAttack, remainingAbilities;
- (void)dealloc {
    [remainingAbilities release];
    [super dealloc];
}

+(id)defaultBoss{
    Baraghast *boss = [[Baraghast alloc] initWithHealth:450000 damage:12 targets:1 frequency:1.25 andChoosesMT:YES];
    [boss setAutoAttack:[[boss abilities] objectAtIndex:0]];
    [boss setTitle:@"Baraghast, Warlord of the Damned"];
    [boss setInfo:@"With his champions defeated, Baraghast himself confronts you and your allies."];
    return [boss autorelease];
}

- (void)combatActions:(NSArray*)players theRaid:(Raid*)theRaid gameTime:(float)timeDelta
{
    [super combatActions:players theRaid:theRaid gameTime:timeDelta];

}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if (percentage == 99.0) {
        BaraghastRoar *roar = [[BaraghastRoar alloc] init];
        [roar setTitle:@"baraghast-roar"];
        [roar setCooldown:18.0];
        [roar setOwner:self];
        [self addAbility:roar];
        [roar release];
    }
    
    if (percentage == 80.0) {
        [self.announcer announce:@"Baraghast glowers beyond the Guardian at the rest of your allies"];
        BaraghastBreakOff *breakOff = [[BaraghastBreakOff alloc] init];
        [breakOff setTitle:@"break-off"];
        [breakOff setCooldown:25];
        [breakOff setOwner:self];
        [breakOff setOwnerAutoAttack:self.autoAttack];
        
        [self addAbility:breakOff];
        [breakOff release];
    }
    
    if (percentage == 60.0) {
        [self.announcer announce:@"Baraghast fills with rage."];
        Crush *crushAbility = [[Crush alloc] init];
        [crushAbility setTitle:@"crush"];
        [crushAbility setCooldown:20];
        [crushAbility setTarget:self.autoAttack.focusTarget];
        [self addAbility:crushAbility];
        [crushAbility release];
    }
    
    if (percentage == 33.0) {
        [self.announcer announce:@"A Dark Energy Surges Beneath Baraghast..."];
        Deathwave *dwAbility = [[Deathwave alloc] init];
        [dwAbility setTitle:@"deathwave"];
        [dwAbility setCooldown:32.0];
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
    CrazedSeer *seer = [[CrazedSeer alloc] initWithHealth:390000 damage:0 targets:0 frequency:0 andChoosesMT:NO];
    [seer setTitle:@"Crazed Seer Tyonath"];
    [seer setInfo:@"Seer Tyonath was tormented and tortured after his capture by the Dark Horde.  The Darkness has driven him mad.  He guards the secrets to Baraghast's origin in the vaults beneath the Dark Horde's largest encampment - Serevilost."];
    
    ProjectileAttack *fireballAbility = [[ProjectileAttack alloc] init];
    [fireballAbility setSpriteName:@"purple_fireball.png"];
    [fireballAbility setAbilityValue:-12];
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
    [horrifyingLaugh setAbilityValue:15];
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
+ (id)defaultBoss{
    GatekeeperDelsarn *boss = [[GatekeeperDelsarn alloc] initWithHealth:300000 damage:40 targets:1 frequency:2.1 andChoosesMT:YES];
    [boss setInfo:@"Delsarn is the name the Theronian Seers have given to the land that exists beyond the rift discovered within the tome that Seer Tyonath left behind.  The Gatekeeper is a foul beast that stands between your party and passage into Delsarn."];
    [boss setTitle:@"Gatekeeper of Delsarn"];
    
    Grip *gripAbility = [[Grip alloc] init];
    [gripAbility setTitle:@"grip-ability"];
    [gripAbility setCooldown:22];
    [gripAbility setAbilityValue:-14];
    [boss addAbility:gripAbility];
    [gripAbility release];
    
    Impale *impaleAbility = [[Impale alloc] init];
    [impaleAbility setTitle:@"gatekeeper-impale"];
    [impaleAbility setCooldown:16];
    [boss addAbility:impaleAbility];
    [impaleAbility setAbilityValue:82];
    [impaleAbility release];
    
    
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if (percentage == 75.0){
        //Pestilence
        [self.announcer displayPartcileSystemOnRaidWithName:@"green_mist.plist" forDuration:20];
        NSArray *livingMembers = [raid getAliveMembers];
        for (RaidMember *member in livingMembers){
            RepeatedHealthEffect *pestilenceDot = [[RepeatedHealthEffect alloc] initWithDuration:20 andEffectType:EffectTypeNegativeInvisible];
            [pestilenceDot setValuePerTick:-4];
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
        BloodDrinker *ability = [[BloodDrinker alloc] initWithDamage:10 andCooldown:1.25];
        [ability setTitle:@"gatekeeper-blooddrinker"];
        [self addAbility:ability];
        [ability release];
        
        BloodDrinker *ability2 = [[BloodDrinker alloc] initWithDamage:10 andCooldown:1.25];
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
+ (id)defaultBoss{
    SkeletalDragon *boss = [[SkeletalDragon alloc] initWithHealth:300000 damage:0 targets:0 frequency:100 andChoosesMT:NO];
    [boss setInfo:@"After moving beyond the gates of Delsarn, you encounter a horrifying Skeletal Dragon.  It assaults your party and bars the way."];
    [boss setTitle:@"Skeletal Dragon"];
    
    boss.boneThrowAbility = [[[BoneThrow alloc] init] autorelease];
    [boss.boneThrowAbility  setCooldown:5.0];
    [boss addAbility:boss.boneThrowAbility];
    
    boss.sweepingFlame = [[[TargetTypeFlameBreath alloc] init] autorelease];
    [boss.sweepingFlame setCooldown:9.0];
    [boss.sweepingFlame setAbilityValue:60];
    [(TargetTypeFlameBreath*)boss.sweepingFlame setNumTargets:5];
    [boss addAbility:boss.sweepingFlame];
    
    boss.tankDamage = [[[FocusedAttack alloc] init] autorelease];
    [boss.tankDamage setAbilityValue:70];
    [boss.tankDamage setCooldown:2.5];
    [boss.tankDamage setFailureChance:.7];
    
    boss.tailLash = [[[RaidDamage alloc] init] autorelease];
    [boss.tailLash setAbilityValue:32];
    [boss.tailLash setCooldown:22.0];
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
        NSArray *livingMembers = [raid getAliveMembers];
        NSInteger damageValue = 750 / livingMembers.count;
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
    ColossusOfBone *cob = [[ColossusOfBone alloc] initWithHealth:200000 damage:0 targets:0 frequency:0 andChoosesMT:NO];
    [cob setTitle:@"Colossus of Bone"];
    [cob setInfo:@"Traveling even deeper into Delsarn, you and your allies are stopped by a towering creature of mythical size."];
    
    FocusedAttack *tankAttack = [[FocusedAttack alloc] initWithDamage:62 andCooldown:2.45];
    [tankAttack setFailureChance:.4];
    [cob addAbility:tankAttack];
    [tankAttack release];
    
    cob.crushingPunch = [[Attack alloc] initWithDamage:0 andCooldown:10.0];
    DelayedHealthEffect *crushingPunchEffect = [[DelayedHealthEffect alloc] initWithDuration:3.0 andEffectType:EffectTypeNegative];
    [crushingPunchEffect setTitle:@"crushing-punch"];
    [crushingPunchEffect setOwner:cob];
    [crushingPunchEffect setValue:-90];
    [crushingPunchEffect setSpriteName:@"crush.png"];
    [(Attack*)cob.crushingPunch setAppliedEffect:crushingPunchEffect];
    [crushingPunchEffect release];
    [cob.crushingPunch setFailureChance:.2];
    [cob addAbility:cob.crushingPunch];
    [cob.crushingPunch release];
    
    cob.boneQuake = [[BoneQuake alloc] init];
    [cob.boneQuake setAbilityValue:12];
    [cob.boneQuake setCooldown:30.0];
    [cob addAbility:cob.boneQuake];
    [cob.boneQuake release];
    
    BoneThrow *boneThrow = [[BoneThrow alloc] init];
    [boneThrow setAbilityValue:24];
    [boneThrow setCooldown:14.0];
    [cob addAbility:boneThrow];
    [boneThrow release];
    
    AbilityDescriptor *crushingPunchDescriptor = [[AbilityDescriptor alloc] init];
    [crushingPunchDescriptor setAbilityDescription:@"Periodically, this enemy unleashes a vicious strike on a random ally dealing high damage."];
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
    [super dealloc];
}

+ (id)defaultBoss {
    OverseerOfDelsarn *boss = [[OverseerOfDelsarn alloc] initWithHealth:340000 damage:0 targets:0 frequency:0 andChoosesMT:NO];
    [boss setTitle:@"Overseer of Delsarn"];
    [boss setInfo:@"After defeating his most powerful beasts, the Overseer of this treacherous realm confronts you himself.  He bars your way into the inner sanctum."];
    
    boss.projectilesAbility = [[[OverseerProjectiles alloc] init] autorelease];
    [boss.projectilesAbility setAbilityValue:56];
    [boss.projectilesAbility setCooldown:1.5];
    [boss addAbility:boss.projectilesAbility];
    
    boss.demonAbilities = [NSMutableArray arrayWithCapacity:3];
    
    BloodMinion *bm = [[BloodMinion alloc] init];
    [bm setTitle:@"blood-minion"];
    [bm setCooldown:10.0];
    [bm setAbilityValue:10];
    [boss.demonAbilities addObject:bm];
    [bm release];
    
    FireMinion *fm = [[FireMinion alloc] init];
    [fm setTitle:@"fire-minion"];
    [fm setCooldown:15.0];
    [fm setAbilityValue:35];
    [boss.demonAbilities addObject:fm];
    [fm release];
    
    ShadowMinion *sm = [[ShadowMinion alloc] init];
    [sm setTitle:@"shadow-minion"];
    [sm setCooldown:12.0];
    [sm setAbilityValue:20];
    [boss.demonAbilities addObject:sm];
    [sm release];
    
    return [boss autorelease];
}

- (void)addRandomDemonAbility {
    NSInteger indexToAdd = arc4random() % self.demonAbilities.count;
    
    [self addAbility:[self.demonAbilities objectAtIndex:indexToAdd]];
    [self.demonAbilities removeObjectAtIndex:indexToAdd];
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
    
    if (percentage == 20.0){
        [self.announcer announce:@"The Overseer laughs maniacally and raises his staff again."];
        self.projectilesAbility.cooldown = 3.5;
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
    TheUnspeakable *boss = [[TheUnspeakable alloc] initWithHealth:400000 damage:0 targets:0 frequency:0 andChoosesMT:NO];
    [boss setTitle:@"The Unspeakable"];
    [boss setInfo:@"A disgusting mass of boness and rotten corpses sits in a crypt beneath Delsarn."];
    
    boss.oozeAll = [[[OozeRaid alloc] init] autorelease];
    [boss.oozeAll setTimeApplied:19.0];
    [boss.oozeAll setCooldown:24.0];
    [(OozeRaid*)boss.oozeAll setOriginalCooldown:24.0];
    [(OozeRaid*)boss.oozeAll setAppliedEffect:[EngulfingSlimeEffect defaultEffect]];
    [boss.oozeAll setTitle:@"apply-ooze-all"];

    [boss addAbility:boss.oozeAll];
    
    OozeTwoTargets *oozeTwo = [[OozeTwoTargets alloc] init];
    [oozeTwo setCooldown:10.0];
    [oozeTwo setTitle:@"ooze-two"];
    [boss addAbility:oozeTwo];
    [oozeTwo release];
    
    return [boss autorelease];
}

- (void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player {
    if ((int)percentage % 10 == 0){
        [(OozeRaid*)self.oozeAll setOriginalCooldown:[(OozeRaid*)self.oozeAll originalCooldown] - 1.5];
    }
}
@end

@implementation BaraghastReborn
@end

@implementation AvatarOfTorment1
@end

@implementation AvatarOfTorment2
@end

@implementation SoulOfTorment
@end

@implementation TheEndlessVoid

- (void)setHealth:(NSInteger)newHealth {
    if (self.healthPercentage > .5){
        [super setHealth:newHealth];
    }
}

+(id)defaultBoss{
    TheEndlessVoid *endlessVoid = [[TheEndlessVoid alloc] initWithHealth:99999999 damage:40 targets:4 frequency:2.0 andChoosesMT:NO];
    [endlessVoid setTitle:@"The Endless Void"];
    [endlessVoid setInfo:@"An immortal foe that can not be vanquished.  Withstand as long as you can."];
    
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

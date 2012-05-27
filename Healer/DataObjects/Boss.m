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

@interface Boss ()
@property (nonatomic, retain) RaidMember *focusTarget;
-(int)damageDealt;
-(RaidMember*)highestHealthMemberInRaid:(Raid*)theRaid excluding:(NSArray*)array;
@end

@implementation Boss
@synthesize lastAttack,title, logger, focusTarget, announcer, criticalChance, info, isMultiplayer=_isMultiplayer,phase, duration;
-(void)dealloc{
    [info release];
    [announcer release];
    [title release];
    [super dealloc];
}

-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq andChoosesMT:(BOOL)chooses{
    if (self = [super init]){
        health = hlth;
        maximumHealth = hlth;
        damage = dmg;
        targets = trgets;
        frequency = freq;
        choosesMainTank = chooses;
        lastAttack = 0.0f;
        title = @"";
        self.criticalChance = 0.0;
        for (int i = 0; i < 101; i++){
            healthThresholdCrossed[i] = NO;
        }
        self.isMultiplayer = NO;
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
-(int)damageDealt{
    
    float multiplyModifier = self.damageDoneMultiplier;
    int additiveModifier = 0;
    
    if (choosesMainTank && self.focusTarget.isDead){
        multiplyModifier *= 3; //The tank died.  Outgoing damage is now tripled
    }
    
    if (self.isMultiplayer){
        multiplyModifier += 1.5;
    }
    
    if (self.criticalChance != 0.0 && arc4random() % 100 < (self.criticalChance * 100)){
        multiplyModifier += 1.5;
    }
    
    return (int)round((float)damage/(float)targets * multiplyModifier) + additiveModifier;
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid*)raid andPlayer:(Player*)player{
    //The main entry point for health based triggers
}

-(void)damageTarget:(RaidMember*)target{
    if (![target raidMemberShouldDodgeAttack:0.0]){
        int thisDamage = self.damageDealt;
        
        if (target.isFocused){
            thisDamage = (int)round(thisDamage * 1.2);
        }
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:[NSNumber numberWithInt:thisDamage] andEventType:CombatEventTypeDamage]];
        [target setHealth:[target health] - thisDamage];
        if (thisDamage > 0){
            [self.announcer displayParticleSystemWithName:@"blood_spurt.plist" onTarget:target];
        }
        
    }else{
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:0 andEventType:CombatEventTypeDodge]];
    }
}

-(RaidMember*)highestHealthMemberInRaid:(Raid*)theRaid excluding:(NSArray*)members{
    if (!members){
        members = [NSArray array];
    }
    RaidMember *tempTarget = [theRaid.raidMembers objectAtIndex:0];
    int highestHealth = ((RaidMember*)[theRaid.raidMembers objectAtIndex:0]).maximumHealth;
    for (int i = 1; i < theRaid.raidMembers.count; i++){
        if (((RaidMember*)[theRaid.raidMembers objectAtIndex:i]).maximumHealth > highestHealth && ![members containsObject:[theRaid.raidMembers objectAtIndex:i]]){
            highestHealth = ((RaidMember*)[theRaid.raidMembers objectAtIndex:i]).maximumHealth;
            tempTarget = ((RaidMember*)[theRaid.raidMembers objectAtIndex:i]);
        }
    }
    return tempTarget;
}

-(void)chooseMainTankInRaid:(Raid *)theRaid{
    if (choosesMainTank && !self.focusTarget){
        self.focusTarget = [self highestHealthMemberInRaid:theRaid excluding:nil];
        [self.focusTarget setIsFocused:YES];
    }
}

-(void)performStandardAttackOnTheRaid:(Raid*)theRaid andPlayer:(Player*)thePlayer withTime:(float)theTime{
    self.lastAttack+= theTime;

    if (self.lastAttack >= frequency){
		
		self.lastAttack = 0;
		
		NSArray* victims = [theRaid getAliveMembers];
		
		RaidMember *target = nil;
		
        if (choosesMainTank && !self.focusTarget.isDead){
            [self damageTarget:self.focusTarget];
            if (self.focusTarget.isDead){
                [self.announcer announce:[NSString stringWithFormat:@"%@ frenzies upon killing its focused target.", self.title]];
                
            }
        }
		if (targets <= [victims count]){
			for (int i = 0; i < targets - (int)(choosesMainTank && !self.focusTarget.isDead); i++){
				do{
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
				
                [self damageTarget:target];
			}
		}
		else{
			for (int i = 0; i < targets - (int)(choosesMainTank && !self.focusTarget.isDead); i++){
				do{
                    if ([victims count] <= 0){
                        break;
                    }
					NSInteger targetIndex = arc4random() % [victims count];
					
					target = [victims objectAtIndex:targetIndex];
				} while ([target isDead]);
                [self damageTarget:target];
				
				if ([[theRaid getAliveMembers] count] == 0){
					i = targets;
				}
			}
		}
		
	}

}
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(float)theTime
{
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
    self.duration += theTime;
    [self chooseMainTankInRaid:theRaid];
	
    [self performStandardAttackOnTheRaid:theRaid andPlayer:player withTime:theTime];
    [self updateEffects:self raid:theRaid player:player time:theTime];
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
    Ghoul *ghoul = [[Ghoul alloc]initWithHealth:6750 damage:20 targets:1 frequency:2.0 andChoosesMT:NO];
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
    return  [corTroll autorelease];
}
-(void)doCaveInOnRaid:(Raid*)theRaid{
    [self.announcer displayScreenShakeForDuration:2.5];
    [self.announcer announce:@"The Corrupted Troll Smashes the cave ceiling"];
    [self.announcer displayPartcileSystemOverRaidWithName:@"falling_rocks.plist"];
    for (RaidMember *member in theRaid.raidMembers){
        if (!member.isDead){
            NSInteger damageDealt = (arc4random() % 20 + 20);
            if (member == self.focusTarget){
                damageDealt = MAX(damageDealt, 25); //The Tank is armored
            }
            [self.logger logEvent:[CombatEvent eventWithSource:self target:member value:[NSNumber numberWithInt:damageDealt] andEventType:CombatEventTypeDamage]];
            [member setHealth:member.health - damageDealt * self.damageDoneMultiplier];
        }
    }
}

-(int)damageDealt{
    int modDmg = [super damageDealt];
    if (self.enraging > 0.0){
        modDmg *= 1.35;
    }
    return modDmg;
}

-(void)startEnraging{
    [self.announcer announce:@"The Cave Troll Swings his club furiously at the focused target!"];
    self.enraging += 1.0;
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

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
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
    [fireball setFailureChance:.15];
    [fireball setValue:-(arc4random() % 20 + 25)];
    [target addEffect:fireball];
    [fireball release];
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    
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
    
    [bottleEffect setOwner:self];
    [bottleEffect setValue:-45];
    [target addEffect:bottleEffect];
    [bottleEffect release];    
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
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
    DarkCouncil *boss = [[DarkCouncil alloc] initWithHealth:340000 damage:5 targets:5 frequency:.75 andChoosesMT:NO];
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
    while (!victim){
        RaidMember *member = [raid randomLivingMember];
        if ([member isKindOfClass:[Demonslayer class]]){
            continue;
        }
        victim = member;    
    }
    return victim;
}

-(void)summonDarkCloud:(Raid*)raid{
    for (RaidMember *member in raid.raidMembers){
        DarkCloudEffect *dcEffect = [[DarkCloudEffect alloc] initWithDuration:6 andEffectType:EffectTypeNegativeInvisible];
        [dcEffect setOwner:self];
        [dcEffect setValuePerTick:-5];
        [dcEffect setNumOfTicks:3];
        [member addEffect:dcEffect];
        [dcEffect release];
    }
    [self.announcer displayPartcileSystemOnRaidWithName:@"purple_mist.plist"];
}

-(void)shootProjectileAtTarget:(RaidMember*)target withDelay:(float)delay{
    float colTime = (1.5 + delay);
    CouncilPoisonball *fireball = [[CouncilPoisonball alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
    
    ProjectileEffect *fireballVisual = [[ProjectileEffect alloc] initWithSpriteName:@"green_fireball.png" target:target andCollisionTime:colTime];
    [fireballVisual setCollisionParticleName:@"poison_cloud.plist"];
    [self.announcer displayProjectileEffect:fireballVisual];
    [fireballVisual release];
    
    [fireball setOwner:self];
    [fireball setValue:self.isMultiplayer ? -(arc4random() % 20 + 30) : -(arc4random() % 10 + 30)];
    [target addEffect:fireball];
    [fireball release];
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    if (self.phase == 1){
        //Roth
        if (![[self.rothVictim activeEffects] containsObject:[[[RothPoison alloc] init] autorelease]] || self.rothVictim.isDead){
            self.rothVictim = [self chooseVictimInRaid:theRaid];
            RothPoison *poison = [[RothPoison alloc] initWithDuration:30.0 andEffectType:EffectTypeNegative];
            [poison setOwner:self];
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
        damage = 0;
        [self.announcer announce:@"The room fills with demonic laughter."];
    }
    if (percentage == 97.0){
        //Roth of the Shadows steps forward
        self.phase = 1;
        [self.announcer announce:@"Roth, The Toxin Mage steps forward."];
        [[AudioController sharedInstance] playTitle:@"roth_entrance"];
    }
    
    if (percentage == 75.0){
        //Roth dies
        [[AudioController sharedInstance] playTitle:@"roth_death"];
        [self.announcer announce:@"Roth falls to his knees.  Grimgon, The Darkener takes his place."];
        self.phase = 2;
    }
    if (percentage == 74.0){
        [[AudioController sharedInstance] playTitle:@"grimgon_entrance"];
    }
    
    if (percentage == 50.0){
        [[AudioController sharedInstance] playTitle:@"grimgon_death"];
        [self.announcer announce:@"Grimgon fades to nothing.  Serevon, Anguish Mage cackles with glee."];
        //Serevon, Anguish Mage steps forward
        self.phase = 3;
        targets = 1;
        damage = 20;
    }
    if (percentage == 49.0){
        [[AudioController sharedInstance] playTitle:@"serevon_entrance"];
    }
    
    if (percentage == 25.0){
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
     
-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    
    self.lastSickeningTime += timeDelta;
    float tickTime = self.isMultiplayer ? 7.0 : 15.0;
    if (self.lastSickeningTime > tickTime){
        for ( int i = 0; i < 2; i++){
            [self sickenTarget:theRaid.randomLivingMember];
        }
        self.lastSickeningTime = 0.0;
    }
}

-(int)damageDealt{
    int dmg = [super damageDealt];
    return dmg * (1 - self.numBubblesPopped * .1);
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (((int)percentage) % 20 == 0 && percentage != 100){
        [self burstPussBubbleOnRaid:raid];
    }
}

@end

@implementation SporeRavagers
@synthesize focusTarget2, focusTarget3, lastSecondaryAttack, isEnraged;
-(void)dealloc{
    [focusTarget2 release];
    [focusTarget3 release];
    [super dealloc];
}
+(id)defaultBoss{
    SporeRavagers *boss = [[SporeRavagers alloc] initWithHealth:405000 damage:19 targets:1 frequency:2.5 andChoosesMT:YES];
    [boss setTitle:@"Spore Ravagers"];
    [boss setInfo:@"Royal scouts report toxic spores are bursting from the remains of the colossus slain a few days prior near the outskirts of Theranore.  The spores are releasing a dense fog into a near-by village, and no-one has been able to get close enough to the town to investigate. Conversely, no villagers have left the town, either..."];
    [boss setCriticalChance:.5];
    return [boss autorelease];
}
-(void)chooseSecondAndThirdFocusTargetsFromRaid:(Raid*)raid{
    int highestHealth = ((RaidMember*)[raid.raidMembers objectAtIndex:0]).maximumHealth;
    NSMutableArray *selectableMembers = [NSMutableArray arrayWithArray:raid.raidMembers];
    [selectableMembers removeObject:self.focusTarget];
    
    RaidMember *tempTarget = [selectableMembers objectAtIndex:0];
    for (int i = 1; i < selectableMembers.count; i++){
        if (((RaidMember*)[selectableMembers objectAtIndex:i]).maximumHealth > highestHealth){
            highestHealth = ((RaidMember*)[selectableMembers objectAtIndex:i]).maximumHealth;
            tempTarget = ((RaidMember*)[selectableMembers objectAtIndex:i]);
        }
    }
    self.focusTarget2 = tempTarget;
    [self.focusTarget2 setIsFocused:YES];
    
    [selectableMembers removeObject:self.focusTarget2];
    
    
    tempTarget = [selectableMembers objectAtIndex:0];
    highestHealth = tempTarget.maximumHealth;
    for (int i = 1; i < selectableMembers.count; i++){
        if (((RaidMember*)[selectableMembers objectAtIndex:i]).maximumHealth > highestHealth){
            highestHealth = ((RaidMember*)[selectableMembers objectAtIndex:i]).maximumHealth;
            tempTarget = ((RaidMember*)[selectableMembers objectAtIndex:i]);
        }
    }
    self.focusTarget3 = tempTarget;
    [self.focusTarget3 setIsFocused:YES];
    
}

-(void)ravagerDiedFocusing:(RaidMember*)focus andRaid:(Raid*)raid{
    [self.announcer announce:@"A Spore Ravager falls to the ground and explodes!"];
    
    [focus setIsFocused:NO];
    
    for (int i = 0; i < 5; i++){
        RaidMember *member = [raid randomLivingMember];
        [member setHealth:member.health - 50 * self.damageDoneMultiplier];
    }
    
}

-(int)damageDealt{
    float multiplyModifier = 1;
    
    if (self.isEnraged){
        multiplyModifier *= 2.25;
    }
    
    if ((self.focusTarget.isDead ) || (self.focusTarget2 && self.focusTarget2.isDead ) || (self.focusTarget3 && self.focusTarget3.isDead )){
        multiplyModifier *= 3; //The tank died.  Outgoing damage is now tripled
    }
    
    if (self.isMultiplayer){
        multiplyModifier *= 1.5;
    }
    
    if (self.criticalChance && arc4random() % 100 < (self.criticalChance * 100)){
        multiplyModifier *= 1.5;
    }
    
    return (int)round((float)damage/(float)targets * multiplyModifier);
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    
    if (!self.focusTarget2 && !self.focusTarget3 && self.healthPercentage > 90.0){
        [self chooseSecondAndThirdFocusTargetsFromRaid:theRaid];
    }
    
    self.lastSecondaryAttack += timeDelta;
    if (self.lastSecondaryAttack > frequency){
        if (self.focusTarget2)
        [self damageTarget:self.focusTarget2];
        if (self.focusTarget3)
        [self damageTarget:self.focusTarget3];
        self.lastSecondaryAttack = 0.0;
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    
    if (percentage == 96.0){
        [self.announcer announce:@"A putrid green mist fills the area..."];
        [self.announcer displayPartcileSystemOnRaidWithName:@"green_mist.plist"];
        for (RaidMember *member in raid.raidMembers){
            RepeatedHealthEffect *rhe = [[RepeatedHealthEffect alloc] initWithDuration:300 andEffectType:EffectTypeNegativeInvisible];
            [rhe setOwner:self];
            [rhe setTitle:@"spore-ravager-green-mist"];
            [rhe setValuePerTick:self.isMultiplayer ? -5 : -2];
            [rhe setNumOfTicks:60];
            [member addEffect:rhe];
            [rhe release];
        }
    }
    if (percentage == 66.0){
        [self ravagerDiedFocusing:self.focusTarget3 andRaid:raid];
        if (!self.focusTarget3.isDead){
            self.focusTarget3 = nil;
        }
    }
    if (percentage == 33.0){
        [self ravagerDiedFocusing:self.focusTarget2 andRaid:raid];
        if (!self.focusTarget2.isDead){
            self.focusTarget2 = nil;
        }
    }
    
    if (percentage == 30.0){
        [self.announcer announce:@"The last remaining Spore Ravager glows with rage."];
        self.isEnraged = YES;
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

-(int)damageDealt{
    int dmg = [super damageDealt];
    return dmg;
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
        
        [bottleEffect setOwner:self];
        [(ImpLightningBottle*)bottleEffect setValue:-45];
        [target addEffect:bottleEffect];
        [bottleEffect release];
    }
    
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
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
        frequency /= 2.0;
        damage *= self.isMultiplayer ? 1.05 : .75 ;
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

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    
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
@synthesize lastFocusTarget2Attack, lastAxecution, focusTarget2, lastGushingWound;
-(void)dealloc{
    [focusTarget2 release];
    [super dealloc];
}
+(id)defaultBoss{
    TwinChampions *boss = [[TwinChampions alloc] initWithHealth:430000 damage:14 targets:1 frequency:1.25 andChoosesMT:YES];
    [boss setTitle:@"Twin Champions of Baraghast"];
    [boss setInfo:@"You and your soldiers have taken the fight straight to the warcamps of Baraghast--Leader of the Dark Horde.  You have been met outside the gates by only two heavily armored demon warriors.  These Champions of Baraghast will stop at nothing to keep you from finding Baraghast."];
    return [boss autorelease];
}

-(void)axeSweepThroughRaid:(Raid*)theRaid{
    self.lastAttack = -7.0;
    self.lastAxecution  = -7.0;
    self.lastFocusTarget2Attack = -7.0;
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
        [axeSweepEffect setValue:-24 * (1 + (deadCount/theRaid.raidMembers.count))];
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
    
    while (!target || target == self.focusTarget || target == self.focusTarget2){
        target = [theRaid randomLivingMember];
    }
    [self.announcer announce:@"An Ally Has been chosen for Execution..."];
    [target setHealth:target.maximumHealth * .4];
    ExecutionEffect *effect = [[ExecutionEffect alloc] initWithDuration:3.0 andEffectType:EffectTypeNegative];
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
        
        while (!target || target == self.focusTarget || target == self.focusTarget2){
            target = [theRaid randomLivingMember];
        }
        
        DelayedHealthEffect *axeThrownEffect = [[DelayedHealthEffect alloc] initWithDuration:1.5 andEffectType:EffectTypeNegativeInvisible];
        [axeThrownEffect setOwner:self];
        [axeThrownEffect setValue:-30];
        
        IntensifyingRepeatedHealthEffect *gushingWoundEffect = [[IntensifyingRepeatedHealthEffect alloc] initWithDuration:9.0 andEffectType:EffectTypeNegative];
        [gushingWoundEffect setSpriteName:@"bleeding.png"];
        [gushingWoundEffect setAilmentType:AilmentTrauma];
        [gushingWoundEffect setIncreasePerTick:.5];
        [gushingWoundEffect setValuePerTick:-28];
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
    RaidMember *tempSwap = self.focusTarget2;
    self.focusTarget2 = self.focusTarget;
    self.focusTarget = tempSwap;
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    
    self.lastAxecution += timeDelta;
    self.lastFocusTarget2Attack += timeDelta;
    self.lastGushingWound += timeDelta;
    
    float axecutionTickTime = 30.0;
    float gushingWoundTickTime = 18.0;
    
    if (self.lastAxecution >= axecutionTickTime){
        [self performAxecutionOnRaid:theRaid];
        self.lastAxecution = 0.0;
    }
    
    if (self.lastFocusTarget2Attack >= (frequency * 5.0)){
        if (!self.focusTarget2){
             self.focusTarget2 = [self highestHealthMemberInRaid:theRaid excluding:[NSArray arrayWithObject:self.focusTarget]];
            [self.focusTarget2 setIsFocused:YES];
        }
        NSInteger tempDamage = damage;
        damage *= 4.0;
        [self damageTarget:self.focusTarget2];
        damage = tempDamage;
        self.lastFocusTarget2Attack = 0.0;
        if (self.focusTarget2.isDead){
            [self damageTarget:[theRaid randomLivingMember]];
            damage *= 4.0;
        }
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
@end

@implementation CrazedSeer
@end

@implementation GatekeeperDelsarn
@end

@implementation SkeletalDragon
@end

@implementation ColossusOfBone 
@end

@implementation OverseerOfDelsarn 
@end

@implementation TheUnspeakable
@end

@implementation BaraghastReborn
@end

@implementation AvatarOfTorment1
@end

@implementation AvatarOfTorment2
@end

@implementation SoulOfTorment
@end

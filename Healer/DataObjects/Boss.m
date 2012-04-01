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
@end

@implementation Boss
@synthesize lastAttack, health, maximumHealth, title, logger, focusTarget, announcer, criticalChance;

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
    }
	return self;
	
}

-(float)healthPercentage{
    return (float)self.health / (float)self.maximumHealth * 100;
}
-(int)damageDealt{
    
    float multiplyModifier = 1;
    int additiveModifier = 0;
    
    if (choosesMainTank && self.focusTarget.isDead){
        multiplyModifier *= 3; //The tank died.  Outgoing damage is now tripled
    }
    
    if (self.criticalChance != 0.0 && arc4random() % 100 < (self.criticalChance * 100)){
        multiplyModifier *= 1.5;
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
        
        if ([target isDead]){
            [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:nil andEventType:CombatEventTypeMemberDied]];
        }
    }else{
        [self.logger logEvent:[CombatEvent eventWithSource:self target:target value:0 andEventType:CombatEventTypeDodge]];
    }
}

-(void)chooseMainTankInRaid:(Raid *)theRaid{
    if (choosesMainTank && !self.focusTarget){
        int highestHealth = ((RaidMember*)[theRaid.raidMembers objectAtIndex:0]).maximumHealth;
        RaidMember *tempTarget = [theRaid.raidMembers objectAtIndex:0];
        for (int i = 1; i < theRaid.raidMembers.count; i++){
            if (((RaidMember*)[theRaid.raidMembers objectAtIndex:i]).maximumHealth > highestHealth){
                highestHealth = ((RaidMember*)[theRaid.raidMembers objectAtIndex:i]).maximumHealth;
                tempTarget = ((RaidMember*)[theRaid.raidMembers objectAtIndex:i]);
            }
        }
        self.focusTarget = tempTarget;
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
            for (int i = 100; i > roundedPercentage; i--){
                if (!healthThresholdCrossed[i]){
                    [self healthPercentageReached:i withRaid:theRaid andPlayer:player];
                    healthThresholdCrossed[i] = YES;;
                }
            }
        }
    }

    [self chooseMainTankInRaid:theRaid];
	
    [self performStandardAttackOnTheRaid:theRaid andPlayer:player withTime:theTime];
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
    Ghoul *ghoul = [[Ghoul alloc]initWithHealth:6750 damage:10 targets:1 frequency:1.5 andChoosesMT:NO];
    [ghoul setTitle:@"The Night Ghoul"];
    return [ghoul autorelease];
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    NSLog(@"Percentage: % 1.2f", percentage);
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
+(id)defaultBoss{
    CorruptedTroll *corTroll = [[CorruptedTroll alloc] initWithHealth:45000 damage:10 targets:2 frequency:1.4 andChoosesMT:YES];
    [corTroll setTitle:@"Corrupted Troll"];
    
    return  [corTroll autorelease];
}
@end

@implementation Drake 
@synthesize lastFireballTime;
+(id)defaultBoss{
    Drake *drake = [[Drake alloc] initWithHealth:52000 damage:4 targets:4 frequency:.8 andChoosesMT:NO];
    [drake setTitle:@"Drake of Soldorn"];
    return [drake autorelease];
}

-(void)shootFireballAtTarget:(RaidMember*)target withDelay:(float)delay{
    float colTime = (1.5 + delay);
    DelayedHealthEffect *fireball = [[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
    
    ProjectileEffect *fireballVisual = [[ProjectileEffect alloc] initWithSpriteName:@"fireball.png" target:target andCollisionTime:colTime];
    [fireballVisual setCollisionParticleName:@"fire_explosion.plist"];
    [self.announcer displayProjectileEffect:fireballVisual];
    [fireballVisual release];
    
    [fireball setValue:-20];
    [target addEffect:fireball];
    [fireball release];
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    
    self.lastFireballTime += timeDelta;
    if (self.lastFireballTime > 5.0){
        [self shootFireballAtTarget:[theRaid randomLivingMember] withDelay:0.0];
        self.lastFireballTime = 0;
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (percentage == 50.0){
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
@synthesize lastPoisonTime;
+(id)defaultBoss{
    Trulzar *boss = [[Trulzar alloc] initWithHealth:180000 damage:20 targets:10 frequency:2.5 andChoosesMT:NO];
    [boss setTitle:@"Trulzar the Maleficar"];
    return [boss autorelease];
}

-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq andChoosesMT:(BOOL)chooses{
    if (self = [super initWithHealth:hlth damage:dmg targets:trgets frequency:freq andChoosesMT:chooses]){
        [[AudioController sharedInstance] addNewPlayerWithTitle:@"trulzar-laugh" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/trulzar-laugh" ofType:@"m4a"]]];
    }
    return self;
}

-(void)dealloc{
    [[AudioController sharedInstance] removeAudioPlayerWithTitle:@"trulzar-laugh"];
    [super dealloc];
}
-(void)applyPoisonToTarget:(RaidMember*)target{
    TrulzarPoison *poisonEffect = [[TrulzarPoison alloc] initWithDuration:24 andEffectType:EffectTypeNegative];
    [self.announcer displayParticleSystemWithName:@"poison_cloud.plist" onTarget:target];
    [poisonEffect setSpriteName:@"poison.png"];
    [poisonEffect setValuePerTick:-7];
    [poisonEffect setNumOfTicks:24];
    [poisonEffect setTitle:@"trulzar-poison1"];
    [target addEffect:poisonEffect];
    [poisonEffect release];
}

-(void)applyWeakPoisonToTarget:(RaidMember*)target{
    TrulzarPoison *poisonEffect = [[TrulzarPoison alloc] initWithDuration:24 andEffectType:EffectTypeNegative];
    [self.announcer displayParticleSystemWithName:@"poison_cloud.plist" onTarget:target];
    [poisonEffect setSpriteName:@"poison.png"];
    [poisonEffect setValuePerTick:-2];
    [poisonEffect setNumOfTicks:24];
    [poisonEffect setTitle:@"trulzar-poison2"];
    [target addEffect:poisonEffect];
    [poisonEffect release];
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    self.lastPoisonTime += timeDelta;
    
    if (self.lastPoisonTime > 10){ 
        if (self.healthPercentage > 10.0){
            [self.announcer announce:@"Trulzar fills an ally with poison."];
            [[AudioController sharedInstance] playTitle:@"trulzar-laugh"];
            [self applyPoisonToTarget:[theRaid randomLivingMember]];
            self.lastPoisonTime = 0;
        }
    }
}

-(void)healthPercentageReached:(float)percentage withRaid:(Raid *)raid andPlayer:(Player *)player{
    if (((int)percentage) % 10 == 0 && ((int)percentage) != 100){
        //Every 10% of his life....
        for (RaidMember *member in raid.raidMembers){
            [self.announcer announce:@"Trulzar's corruption surges in poisoned victims."];
            if (!member.isDead){
                BOOL isPoisoned = NO;
                for (Effect *effect in member.activeEffects){
                    if ([effect.title isEqualToString:@"trulzar-poison1"]){
                        isPoisoned = YES;
                        break;
                    }
                }
                
                if (isPoisoned){
                    [member setHealth: 1];
                }
            }
        }
    }
    
    if (((int)percentage) == 7){
        for (RaidMember *member in raid.raidMembers){
            [self.announcer announce:@"Trulzar cackles as the room fills with noxious poison."];
            [self applyWeakPoisonToTarget:member];
        }
    }
}

@end

@implementation DarkCouncil
@synthesize lastPoisonballTime;
+(id)defaultBoss{
    DarkCouncil *boss = [[DarkCouncil alloc] initWithHealth:292500 damage:5 targets:5 frequency:.75 andChoosesMT:NO];
    [boss setTitle:@"Council of Dark Summoners"];
    return [boss autorelease];
}

-(void)shootProjectileAtTarget:(RaidMember*)target withDelay:(float)delay{
    float colTime = (1.5 + delay);
    CouncilPoisonball *fireball = [[CouncilPoisonball alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
    
    ProjectileEffect *fireballVisual = [[ProjectileEffect alloc] initWithSpriteName:@"green_fireball.png" target:target andCollisionTime:colTime];
    [fireballVisual setCollisionParticleName:@"poison_cloud"];
    [self.announcer displayProjectileEffect:fireballVisual];
    [fireballVisual release];
    
    [fireball setValue:-20];
    [target addEffect:fireball];
    [fireball release];
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    self.lastPoisonballTime += timeDelta;
    
    if (self.lastPoisonballTime > 10){ 
        for (int i = 0; i < 2; i++){
            [self shootProjectileAtTarget:[theRaid randomLivingMember] withDelay:i * 1];
        }
        self.lastPoisonballTime = 0;
    }
}
@end


@implementation PlaguebringerColossus
@synthesize lastSickeningTime, numBubblesPopped;
+(id)defaultBoss{
    //427500
    PlaguebringerColossus *boss = [[PlaguebringerColossus alloc] initWithHealth:427500 damage:16 targets:2 frequency:2.5 andChoosesMT:YES];
    [boss setTitle:@"Plaguebringer Colossus"];
    return [boss autorelease];
}

-(void)sickenTarget:(RaidMember *)target{
    ExpiresAtFullHealthRHE *infectedWound = [[ExpiresAtFullHealthRHE alloc] initWithDuration:30.0 andEffectType:EffectTypeNegative];
    [infectedWound setTitle:@"pbc-infected-wound"];
    [infectedWound setValuePerTick:-2];
    [infectedWound setNumOfTicks:15];
    [infectedWound setSpriteName:@"poison.png"];
    if (target.health > target.maximumHealth * .98){
        //Force the health under .98 so it doesnt immediately expire when applied.
        [target setHealth:target.health * .94];
    }
    [target addEffect:infectedWound];
    [infectedWound release];
    
}

-(void)burstPussBubbleOnRaid:(Raid*)theRaid{
    [self.announcer announce:@"A putrid sac of filth bursts onto your allies"];
    self.numBubblesPopped++;
    for (RaidMember *member in theRaid.raidMembers){
        if (!member.isDead){
            RepeatedHealthEffect *singleTickDot = [[RepeatedHealthEffect alloc] initWithDuration:1.0 andEffectType:EffectTypeNegative];
            [singleTickDot setTitle:@"pbc-pussBubble"];
            [singleTickDot setNumOfTicks:1];
            [singleTickDot setValuePerTick:-20];
            [singleTickDot setSpriteName:@"poison.png"];
            [member addEffect:singleTickDot];
            [singleTickDot release];
        }
    }
}
     
-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    
    self.lastSickeningTime += timeDelta;
    if (self.lastSickeningTime > 15.0){
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
+(id)defaultBoss{
    SporeRavagers *boss = [[SporeRavagers alloc] initWithHealth:405000 damage:8 targets:1 frequency:2.5 andChoosesMT:YES];
    [boss setTitle:@"Spore Ravagers"];
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
        [member setHealth:member.health - 35];
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
        for (RaidMember *member in raid.raidMembers){
            RepeatedHealthEffect *rhe = [[RepeatedHealthEffect alloc] initWithDuration:300 andEffectType:EffectTypeNegativeInvisible];
            [rhe setTitle:@"spore-ravager-green-mist"];
            [rhe setValuePerTick:-1];
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
    MischievousImps *boss = [[MischievousImps alloc] initWithHealth:97500 damage:16 targets:1 frequency:3.0 andChoosesMT:YES];
    [boss setTitle:@"Mischievious Imps"];
    
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
        
        [target addEffect:bottleEffect];
        [bottleEffect release];
        
    }else if (potion == 1){
        //Lightning In a Bottle
        DelayedHealthEffect *bottleEffect = [[DelayedHealthEffect alloc] initWithDuration:colTime andEffectType:EffectTypeNegativeInvisible];
        
        ProjectileEffect *bottleVisual = [[ProjectileEffect alloc] initWithSpriteName:@"potion.png" target:target andCollisionTime:colTime];
        [bottleVisual setSpriteColor:ccc3(0, 128, 128)];
        [self.announcer displayThrowEffect:bottleVisual];
        [bottleVisual release];
        
        [(ImpLightningBottle*)bottleEffect setValue:-20];
        [target addEffect:bottleEffect];
        [bottleEffect release];
    }
    
}

-(void)combatActions:(Player *)player theRaid:(Raid *)theRaid gameTime:(float)timeDelta{
    
    [super combatActions:player theRaid:theRaid gameTime:timeDelta];
    if (self.healthPercentage > 30.0){
        self.lastPotionThrow+=timeDelta;
        if (self.lastPotionThrow > 12){
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
    
    if (percentage == 30.0){
        [self.announcer announce:@"All of the imps angrily pounce on their focused target!"];
        frequency /= 2.0;
        damage *= .75;
    }
}
@end
//
//  RaidMember.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidMember.h"
#import "GameObjects.h"
#import "HealableTarget.h"

@interface RaidMember ()
-(void)performAttackIfAbleOnTarget:(Boss*)target;
@end

@implementation RaidMember
@synthesize lastAttack;
@synthesize damageDealt;
@synthesize title;
@synthesize dodgeChance;
@synthesize info;
@synthesize positioning;

-(id)initWithHealth:(NSInteger)hlth damageDealt:(NSInteger)damage andDmgFrequency:(float)dmgFreq andPositioning:(Positioning)position
{
    if (self = [super init]){
        maximumHealth = hlth;
        health = hlth;
        
        damageDealt = damage;
        damageFrequency = dmgFreq;
        self.title = @"NOTITLE";
        self.info = @"NOINFO";
        self.dodgeChance = 0.0;
        self.criticalChance = .05;
        positioning = position;
    }
	return self;
}

-(NSString*)networkID{
    return [NSString stringWithFormat:@"R-%@", self.battleID];
}
-(NSString *)sourceName {
    return [NSString stringWithFormat:@"%@:%@", self.title, self.battleID];
}

-(NSString*)targetName{
    return self.sourceName;
}

-(void)performAttackIfAbleOnTarget:(Boss*)target{
	if (lastAttack >= damageFrequency && !self.isDead){
		lastAttack = 0.0;
		
		[target setHealth:[target health] - (self.damageDealt * self.damageDoneMultiplier)];
		
	}
}

- (void)didPerformCriticalStrikeForAmount:(NSInteger)amount{
    
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

-(void)dealloc{
    [title release];
    [info release];
    [super dealloc];
}

-(float)dps{
    return (float)damageDealt  / damageFrequency;
}


-(NSInteger)damageDealt{
    int finalAmount = damageDealt;
    int fuzzRange = (int)round(damageDealt * .05);
    int fuzz = arc4random() % (fuzzRange + 1);
    
    finalAmount += fuzz * (arc4random() % 2 == 0 ? -1 : 1);
    
    if (arc4random() % 100 < (100 * self.criticalChance)){
        finalAmount *= 1.5;
        [self didPerformCriticalStrikeForAmount:finalAmount];
    }
    return finalAmount;
}

-(BOOL)raidMemberShouldDodgeAttack:(float)modifer{
    return arc4random() % 100 <= (100 * self.dodgeChance);
}

-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid players:(NSArray*)players gameTime:(float)timeDelta
{
    Player *thePlayer = [players objectAtIndex:0];
    lastAttack += timeDelta;
    [self performAttackIfAbleOnTarget:theBoss];
    [self updateEffects:theBoss raid:theRaid player:thePlayer time:timeDelta];
	
}


-(NSString*)asNetworkMessage{
    NSMutableString* message = [NSMutableString stringWithFormat:@"RDMBR|%@|%i|%i|", self.battleID, self.health, self.isFocused];
    for (Effect*effect in self.activeEffects){
        [message appendFormat:@"#%@", effect.asNetworkMessage];
    }
    return message;
}
-(void)updateWithNetworkMessage:(NSString*)message{
    NSArray* effectComponents = [message componentsSeparatedByString:@"#"];
    
    NSArray* components = [[effectComponents objectAtIndex:0] componentsSeparatedByString:@"|"];
    
    NSInteger healthFromMessage = [[components objectAtIndex:2] intValue];
    if (healthFromMessage >= 0 && healthFromMessage <= self.maximumHealth){
        self.health = healthFromMessage;
    }
    
    NSMutableArray *effects = [NSMutableArray arrayWithCapacity:5];
    for (int i = 1; i < effectComponents.count; i++){
        Effect *networkEffect = [[Effect alloc] initWithNetworkMessage:[effectComponents objectAtIndex:i]];
        [networkEffect setTarget:self];
        [effects addObject:networkEffect];
        [networkEffect release];
    }
    [activeEffects release];
    activeEffects = [effects retain];
    
    BOOL focused = [[components objectAtIndex:3] boolValue];
    
    self.isFocused = focused;
}


@end

@implementation  Guardian
+(Guardian*)defaultGuardian{
    return [[[Guardian alloc] init] autorelease];
}
- (void)didReceiveHealing:(NSInteger)amount andOverhealing:(NSInteger)overAmount{
    [super didReceiveHealing:amount andOverhealing:overAmount];
    self.overhealingShield += overAmount;
}
- (void)setOverhealingShield:(NSInteger)overhealingShield{
    _overhealingShield = overhealingShield;
    NSInteger maxOverheal = 25;
    if (_overhealingShield > maxOverheal){
        _overhealingShield = maxOverheal;
    }
}

-(id)init{
    if (self = [super initWithHealth:175 damageDealt:50 andDmgFrequency:1.0 andPositioning:Melee]){
        self.title = @"Guardian";
        self.dodgeChance = .15;
        self.info = @"The Guardian can draw attention from enemies and become focused.  Healing a Guardian beyond full health creates a shield that absorbs damage.";
        
        GuardianBarrierEffect *gbe = [[GuardianBarrierEffect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible];
        [gbe setOwningGuardian:self];
        [gbe setTitle:@"guardian-barrier-eff"];
        [self addEffect:gbe];
        [gbe release];
    }
    return self;
}
@end


@implementation Berserker
+(Berserker*)defaultBerserker{
    return [[[Berserker alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:120 damageDealt:62 andDmgFrequency:.75 andPositioning:Melee]){
        self.title = @"Berserker";
        self.info = @"The Berserker has moderate health and damage. When dealing a critical strike, this ally heals itself.";
        self.dodgeChance = .07;
        self.criticalChance = .1;
    }
    return self;
}
- (void)didPerformCriticalStrikeForAmount:(NSInteger)amount{
    self.health += 5;
}
@end

@implementation  Archer
+(Archer*)defaultArcher{
    return [[[Archer alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:100 damageDealt:65 andDmgFrequency:.6 andPositioning:Ranged]){
        self.title = @"Archer";
        self.info = @"The Archer has low health but deals high damage.";
        self.dodgeChance = .05;
    }
    return self;
}
@end

@implementation Champion
+(Champion*)defaultChampion{
    return [[[Champion alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:125 damageDealt:88 andDmgFrequency:1.1 andPositioning:Melee]){
        self.title = @"Champion";
        self.info = @"The Champion has more health and deals more damage when healed to full.";
        self.dodgeChance = .07;
    }
    return self;
}

-(int)damageDealt{
    int baseDamage = [super damageDealt];
    
    return baseDamage - (self.maximumHealth - self.health);
}
@end

@implementation  Wizard
+(Wizard*)defaultWizard{
    return [[[Wizard alloc] init] autorelease];
}

-(id)init{
    if (self = [super initWithHealth:125 damageDealt:30 andDmgFrequency:1.2 andPositioning:Ranged]){
        self.title = @"Wizard";
        self.dodgeChance = .07;
        self.info = @"The Wizard has moderate health and low damage but periodically grants you energy.";
        lastEnergyGrant = 0.0;
    }
    return self;
}

-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid players:(NSArray*)players gameTime:(float)timeDelta
{
    [super combatActions:theBoss raid:theRaid players:players gameTime:timeDelta];
    lastEnergyGrant += timeDelta;
    if (lastEnergyGrant > 1.0){
        if (!self.isDead){
            for (Player *player in players){
                [player setEnergy:player.energy + 6];
            }
        }
        lastEnergyGrant = 0.0;
    }
    
}
@end

@implementation Warlock
+(Warlock*)defaultWarlock{
    return [[[Warlock alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:110 damageDealt:60 andDmgFrequency:.7 andPositioning:Ranged]){
        self.title = @"Warlock";
        self.info = @"The Warlock has moderate health and heals itself for a small amount when at low health.";
        self.dodgeChance = .07;
    }
    return self;
}
- (void)combatActions:(Boss *)theBoss raid:(Raid *)theRaid players:(NSArray *)players gameTime:(float)timeDelta{
    [super combatActions:theBoss raid:theRaid players:players gameTime:timeDelta];
    
    if (self.healthPercentage < .5){
        self.healCooldown += timeDelta;
        if (self.healCooldown >= 1.5){
            self.health += 2;
            self.healCooldown = 0.0;
        }
    }
    
}
@end
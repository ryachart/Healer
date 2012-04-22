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

-(id) initWithHealth:(NSInteger)hlth damageDealt:(NSInteger)damage andDmgFrequency:(float)dmgFreq
{
    if (self = [super init]){
        maximumHealth = hlth;
        health = hlth;
        
        damageDealt = damage;
        damageFrequency = dmgFreq;
        self.title = @"NOTITLE";
        self.info = @"NOINFO";
        self.dodgeChance = 0.0;
        activeEffects = [[NSMutableArray alloc] initWithCapacity:MAXIMUM_STATUS_EFFECTS];
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
		
		[target setHealth:[target health] - self.damageDealt];
		
	}
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
        [activeEffects removeObject:effect];
        
    }
}

-(void)dealloc{
    [activeEffects release]; activeEffects = nil;
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


#pragma mark - Merc Campaign Allies

@implementation  Guardian
+(Guardian*)defaultGuardian{
    return [[[Guardian alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:175 damageDealt:50 andDmgFrequency:1.0]){
        self.title = @"Guardian";
        self.dodgeChance = .09;
        self.info = @"The Guardian has high health but low damage.";
    }
    return self;
}
@end


@implementation Soldier
+(Soldier*)defaultSoldier{
    return [[[Soldier alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:120 damageDealt:62 andDmgFrequency:.80]){
        self.title = @"Soldier";
        self.info = @"The Soldier has moderate health and moderate damage.";
        self.dodgeChance = .07;
    }
    return self;
}
@end

@implementation  Demonslayer
+(Demonslayer*)defaultDemonslayer{
    return [[[Demonslayer alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:100 damageDealt:65 andDmgFrequency:.6]){
        self.title = @"Demonslayer";
        self.info = @"ATheDemonslayer has low health but high damage.";
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
    if (self = [super initWithHealth:115 damageDealt:80 andDmgFrequency:1.0]){
        self.title = @"Champion";
        self.info = @"The Champion has more health and deals more damage the more health it has.";
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
    if (self = [super initWithHealth:125 damageDealt:25 andDmgFrequency:1.0]){
        self.title = @"Wizard";
        self.dodgeChance = .07;
        self.info = @"The Wizard has moderate health and low damage but improves your energy regeneration";
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

@implementation Berserker
+(Berserker*)defaultBerserker{
    return [[[Berserker alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:107 damageDealt:140 andDmgFrequency:1.0]){
        self.title = @"Berserker";
        self.info = @"The Berserker has moderate health and deals more damage at low health.";
        self.dodgeChance = .07;
    }
    return self;
}

-(int)damageDealt{
    int baseDamage = self.damageDealt;
    return baseDamage - self.health;
}
@end
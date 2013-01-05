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

-(void)dealloc{
    [title release];
    [info release];
    [super dealloc];
}

-(id)initWithHealth:(NSInteger)hlth damageDealt:(NSInteger)damage andDmgFrequency:(float)dmgFreq andPositioning:(Positioning)position
{
    if (self = [super init]){
        self.maximumHealth = hlth;
        health = hlth;
        damageDealt = damage;
        damageFrequency = dmgFreq;
        self.title = @"NOTITLE";
        self.info = @"NOINFO";
        self.dodgeChance = 0.0;
        self.criticalChance = .05;
        positioning = position;
        self.lastAttack = (arc4random() % (int)(dmgFreq * 10)) / 10.0; //Seed with slightly random attacks
    }
	return self;
}

- (float)dodgeChance
{
    float base = dodgeChance;
    for (Effect *eff in self.activeEffects) {
        base += eff.dodgeChanceAdjustment;
    }
    return base;
}

- (void)healSelfForAmount:(NSInteger)amount {
    if (amount > 0){
        if (!self.hasDied && !self.isDead){
            health = MIN(self.maximumHealth , health + amount);
        }
    }
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
        [self.announcer displayAttackFromRaidMember:self];
	}
}

- (void)didPerformCriticalStrikeForAmount:(NSInteger)amount{
    
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
    
    //Health adjustment
    finalAmount *= MAX(self.healthPercentage, 0.6);
    
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
	self.absorb = self.absorb; //Verify that our absorption amount is still valid.
}


-(NSString*)asNetworkMessage{
    NSMutableString* message = [NSMutableString stringWithFormat:@"RDMBR|%@|%i|%i|%i|%i", self.battleID, self.health, self.isFocused, self.absorb, self.maximumAbsorbtion];
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
    self.activeEffects = effects;
    
    BOOL focused = [[components objectAtIndex:3] boolValue];
    
    self.isFocused = focused;
    
    self.absorb = [[components objectAtIndex:4] intValue];
}


@end

@implementation  Guardian
+(Guardian*)defaultGuardian{
    return [[[Guardian alloc] init] autorelease];
}
- (void)didReceiveHealing:(NSInteger)amount andOverhealing:(NSInteger)overAmount{
    [super didReceiveHealing:amount andOverhealing:overAmount];
    self.absorb += (int)round(overAmount * 1.1);
}

-(id)init{
    if (self = [super initWithHealth:1753 damageDealt:287 andDmgFrequency:1.25 andPositioning:Melee]){
        self.title = @"Guardian";
        self.dodgeChance = .15;
        self.info = @"Overhealing creates protective shield";
        
        Effect *gbe = [[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible];
        [gbe setMaximumAbsorbtionAdjustment:250];
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
    if (self = [super initWithHealth:1192 damageDealt:748 andDmgFrequency:.75 andPositioning:Melee]){
        self.title = @"Berserker";
        self.info = @"Deals very high damage";
        self.dodgeChance = .07;
        self.criticalChance = .1;
        self.lastAttack = arc4random() % 70 / 100.0;
    }
    return self;
}
- (void)didPerformCriticalStrikeForAmount:(NSInteger)amount{
    [self healSelfForAmount:50];
}
@end

@implementation  Archer
+(Archer*)defaultArcher{
    return [[[Archer alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:1013 damageDealt:1232 andDmgFrequency:1.2 andPositioning:Ranged]){
        self.title = @"Archer";
        self.info = @"Deals very high damage";
        self.dodgeChance = .05;
        self.lastAttack = arc4random() % 110 / 100.0;
    }
    return self;
}
@end

@implementation Champion
+(Champion*)defaultChampion{
    return [[[Champion alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:1246 damageDealt:664 andDmgFrequency:2.5 andPositioning:Melee]){
        self.title = @"Champion";
        self.info = @"Reduces enemy damage by 5%.";
        self.dodgeChance = .07;
        self.lastAttack = arc4random() % 240 / 100.0f;
    }
    return self;
}

- (void)combatActions:(Boss *)theBoss raid:(Raid *)theRaid players:(NSArray *)players gameTime:(float)timeDelta{
    [super combatActions:theBoss raid:theRaid players:players gameTime:timeDelta];
    
    if (self.isDead && !self.deathEffectApplied) {
        Effect *damageImprovement = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
        [damageImprovement setOwner:self];
        [damageImprovement setTitle:[NSString stringWithFormat:@"%@-dmg-eff", self.battleID]];
        [damageImprovement setDamageDoneMultiplierAdjustment:.05];
        [theBoss addEffect:damageImprovement];
        self.deathEffectApplied = YES;
    }
}

@end

@implementation  Wizard
+(Wizard*)defaultWizard{
    return [[[Wizard alloc] init] autorelease];
}

-(id)init{
    if (self = [super initWithHealth:1157 damageDealt:304 andDmgFrequency:1.2 andPositioning:Ranged]){
        self.title = @"Wizard";
        self.dodgeChance = .07;
        self.info = @"Periodically grants you energy";
        lastEnergyGrant = arc4random() % 7; //Initialize to a random value so they arent all the same time
    }
    return self;
}

-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid players:(NSArray*)players gameTime:(float)timeDelta
{
    [super combatActions:theBoss raid:theRaid players:players gameTime:timeDelta];
    lastEnergyGrant += timeDelta;
    
    NSTimeInterval tickTime = 10.0;
    NSTimeInterval orbTravelTime = 1.5;
    NSInteger energyGrant = 60;
    
    if (lastEnergyGrant > (tickTime - orbTravelTime) && !self.energyGrantAnnounced && !self.isDead) {
        [self.announcer displayEnergyGainFrom:self];
        self.energyGrantAnnounced = YES;
    }
    
    if (lastEnergyGrant > tickTime) {
        if (!self.isDead){
            for (Player *player in players){
                [player setEnergy:player.energy + energyGrant];
            }
        }
        lastEnergyGrant = 0.0;
        self.energyGrantAnnounced = NO;
    }
    
}
@end

@implementation Warlock
+(Warlock*)defaultWarlock{
    return [[[Warlock alloc] init] autorelease];
}
-(id)init{
    if (self = [super initWithHealth:1142 damageDealt:521 andDmgFrequency:2.0 andPositioning:Ranged]){
        self.title = @"Warlock";
        self.info = @"Reduces enemy damage by 5%";
        self.dodgeChance = .07;
        self.lastAttack = arc4random() % 190 / 100.0f;
    }
    return self;
}

-(void)performAttackIfAbleOnTarget:(Boss*)target{
	if (lastAttack >= damageFrequency && !self.isDead){
		lastAttack = 0.0;
        
        if (self.healthPercentage < .5){
            [self healSelfForAmount:50];
        } else {
            [target setHealth:[target health] - (self.damageDealt * self.damageDoneMultiplier)];
            [self.announcer displayAttackFromRaidMember:self];
        }
		
	}
}

- (void)combatActions:(Boss *)theBoss raid:(Raid *)theRaid players:(NSArray *)players gameTime:(float)timeDelta{
    [super combatActions:theBoss raid:theRaid players:players gameTime:timeDelta];
    
    if (self.isDead && !self.deathEffectApplied) {
        Effect *damageImprovement = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
        [damageImprovement setOwner:self];
        [damageImprovement setTitle:[NSString stringWithFormat:@"%@-dmg-eff", self.battleID]];
        [damageImprovement setDamageDoneMultiplierAdjustment:.05];
        [theBoss addEffect:damageImprovement];
        self.deathEffectApplied = YES;
    }
    
}
@end
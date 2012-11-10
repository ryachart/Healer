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
    self.activeEffects = effects;
    
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
    self.absorb += (int)round(overAmount * 1.1);
}

-(id)init{
    if (self = [super initWithHealth:1750 damageDealt:29 andDmgFrequency:1.25 andPositioning:Melee]){
        self.title = @"Guardian";
        self.dodgeChance = .15;
        self.info = @"The Guardian can draw attention from enemies and become focused. Overhealing a Guardian creates a shield that absorbs damage.";
        
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
    if (self = [super initWithHealth:1200 damageDealt:75 andDmgFrequency:.75 andPositioning:Melee]){
        self.title = @"Berserker";
        self.info = @"The Berserker deals very high damage. When dealing a critical strike this ally heals itself.";
        self.dodgeChance = .07;
        self.criticalChance = .1;
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
    if (self = [super initWithHealth:1000 damageDealt:60 andDmgFrequency:.6 andPositioning:Ranged]){
        self.title = @"Archer";
        self.info = @"The Archer deals very high damage.";
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
    if (self = [super initWithHealth:1250 damageDealt:29 andDmgFrequency:1.1 andPositioning:Melee]){
        self.title = @"Champion";
        self.info = @"The Champion deals more damage when healed to full and reduces enemy damage by 5%.";
        self.dodgeChance = .07;
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

-(int)damageDealt{
    int baseDamage = [super damageDealt];
    int fullHealthBonus = self.health == self.maximumHealth ? 10 : 0;
    return baseDamage + fullHealthBonus;
}
@end

@implementation  Wizard
+(Wizard*)defaultWizard{
    return [[[Wizard alloc] init] autorelease];
}

-(id)init{
    if (self = [super initWithHealth:1250 damageDealt:30 andDmgFrequency:1.2 andPositioning:Ranged]){
        self.title = @"Wizard";
        self.dodgeChance = .07;
        self.info = @"The Wizard has moderate health and low damage but periodically grants you energy.";
        lastEnergyGrant = arc4random() % 10; //Initialize to a random value so they arent all the same time
    }
    return self;
}

-(void) combatActions:(Boss*)theBoss raid:(Raid*)theRaid players:(NSArray*)players gameTime:(float)timeDelta
{
    [super combatActions:theBoss raid:theRaid players:players gameTime:timeDelta];
    lastEnergyGrant += timeDelta;
    
    NSTimeInterval tickTime = 10.0;
    NSTimeInterval orbTravelTime = 2.0;
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
    if (self = [super initWithHealth:1100 damageDealt:50 andDmgFrequency:2.0 andPositioning:Ranged]){
        self.title = @"Warlock";
        self.info = @"The Warlock heals itself for a small amount when at low health and reduces enemy damage by 5%.";
        self.dodgeChance = .07;
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
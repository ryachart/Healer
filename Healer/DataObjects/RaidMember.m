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
#import "CombatEvent.h"

@interface RaidMember ()
-(void)performAttackIfAbleOnTarget:(Enemy*)target;
@end

@implementation RaidMember
-(void)dealloc{
    [_title release];
    [_info release];
    [super dealloc];
}

- (ccColor3B)classColor
{
    return ccWHITE;
}

-(id)initWithHealth:(NSInteger)hlth damageDealt:(NSInteger)damage andDmgFrequency:(float)dmgFreq andPositioning:(Positioning)position
{
    if (self = [super init]){
        self.maximumHealth = hlth;
        self.health = hlth;
        self.damageDealt = damage;
        self.damageFrequency = dmgFreq;
        self.title = @"NOTITLE";
        self.info = @"NOINFO";
        self.dodgeChance = 0.0;
        self.criticalChance = .05;
        _positioning = position;
        self.lastAttack = (arc4random() % (int)(dmgFreq * 10)) / 10.0; //Seed with slightly random attacks
    }
	return self;
}

- (BOOL)isInvalidAttackTarget
{
    return self.damageTakenMultiplierAdjustment == 0.0;
}

- (float)dodgeChance
{
    float base = _dodgeChance;
    for (Effect *eff in self.activeEffects) {
        base += eff.dodgeChanceAdjustment;
    }
    return base;
}

- (void)healSelfForAmount:(NSInteger)amount {
    if (amount > 0){
        if (!self.hasDied && !self.isDead){
            [self passiveHealForAmount:amount];
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

-(void)performAttackIfAbleOnTarget:(Enemy*)target{
	if (_lastAttack >= _damageFrequency && !self.isDead && !self.isStunned){
		_lastAttack = 0.0;
		
		[target setHealth:[target health] - (self.damageDealt * self.damageDoneMultiplier)];
        [self.announcer displayAttackFromRaidMember:self onTarget:target];
	}
}

- (BOOL)isStunned
{
    return self.stunDuration > 0;
}

- (float)stunDuration
{
    for (Effect *eff in self.activeEffects) {
        if (eff.causesStun) {
            return eff.duration - eff.timeApplied;
        }
    }
    return 0.0;
}

- (void)didPerformCriticalStrikeForAmount:(NSInteger)amount{
    
}

-(float)dps{
    return (float)_damageDealt  / _damageFrequency;
}

-(NSInteger)damageDealt{
    int finalAmount = _damageDealt;
    int fuzzRange = (int)round(_damageDealt * .05);
    int fuzz = arc4random() % (fuzzRange + 1);
    
    finalAmount += fuzz * (arc4random() % 2 == 0 ? -1 : 1);
    
    if (arc4random() % 100 < (100 * self.criticalChance)){
        finalAmount *= 1.5;
        [self didPerformCriticalStrikeForAmount:finalAmount];
    }
    
    //Health adjustment
    finalAmount *= 1 - (.25 - .25 * self.healthPercentage);
    
    return finalAmount;
}

-(BOOL)raidMemberShouldDodgeAttack:(float)modifer{
    return arc4random() % 10000 <= (10000 * (self.dodgeChance + modifer));
}

- (Enemy *)highestPriorityEnemy:(NSArray *)enemies
{
    NSMutableArray *randomPriorities = [NSMutableArray arrayWithCapacity:enemies.count];
    Enemy *highestPriority = [enemies objectAtIndex:0];
    for (int i = 0; i < enemies.count; i++) {
        Enemy *thisEnemy = [enemies objectAtIndex:i];
        if ([thisEnemy threatPriority] > highestPriority.threatPriority) {
            highestPriority = [enemies objectAtIndex:i];
        }
        if (thisEnemy.threatPriority == kThreatPriorityRandom) {
            [randomPriorities addObject:thisEnemy];
        }
    }
    
    if (randomPriorities.count >= 1) {
        return [randomPriorities objectAtIndex:arc4random() % randomPriorities.count];
    }
    return highestPriority;
}

- (void)combatUpdateForPlayers:(NSArray*)players enemies:(NSArray*)enemies theRaid:(Raid*)raid gameTime:(float)timeDelta;
{
    self.lastAttack += timeDelta;
    Enemy *theBoss = [self highestPriorityEnemy:enemies];
    [self performAttackIfAbleOnTarget:theBoss];
    [self updateEffects:enemies raid:raid players:players time:timeDelta];
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
- (ccColor3B)classColor
{
    return ccc3(255,207,91);
}

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
- (ccColor3B)classColor
{
    return ccc3(255,70,70);
}

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
- (ccColor3B)classColor
{
    return ccc3(29,167,18);
}
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
- (ccColor3B)classColor
{
    return ccc3(240,255,0);
}

+(Champion*)defaultChampion{
    return [[[Champion alloc] init] autorelease];
}

-(id)init{
    if (self = [super initWithHealth:1246 damageDealt:664 andDmgFrequency:2.5 andPositioning:Melee]){
        self.title = @"Champion";
        self.info = @"Improves ally's damage by 20%";
        self.dodgeChance = .07;
        self.lastAttack = arc4random() % 240 / 100.0f;
    }
    return self;
}

- (void)combatUpdateForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta {
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    
    if (self.isDead && !self.deathEffectApplied) {
        for (RaidMember *member in raid.livingMembers) {
            Effect *damageNerf = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
            [damageNerf setOwner:self];
            [damageNerf setTitle:[NSString stringWithFormat:@"%@-dmg-eff", self.battleID]];
            [damageNerf setDamageDoneMultiplierAdjustment:-.2];
            [member addEffect:damageNerf];
            self.deathEffectApplied = YES;
        }
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
        self.info = @"Periodically grants you Mana";
        self.lastEnergyGrant = arc4random() % 7; //Initialize to a random value so they arent all the same time
    }
    return self;
}

- (void)combatUpdateForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta
{
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    self.lastEnergyGrant += timeDelta;
    
    NSTimeInterval tickTime = 10.0;
    NSTimeInterval orbTravelTime = 1.5;
    NSInteger energyGrant = 24;
    NSInteger criticalGrantChance = 5;
    
    if (self.lastEnergyGrant > (tickTime - orbTravelTime) && !self.energyGrantAnnounced && !self.isDead) {
        [self.announcer displayEnergyGainFrom:self];
        self.energyGrantAnnounced = YES;
    }
    
    if (self.lastEnergyGrant > tickTime) {
        if (!self.isDead && !self.isStunned){
            for (Player *player in players){
                if (arc4random() % 100 < criticalGrantChance) {
                    energyGrant *= 2;
                }
                [player setEnergy:player.energy + energyGrant];
            }
        }
        self.lastEnergyGrant = 0.0;
        self.energyGrantAnnounced = NO;
    }
    
}
- (ccColor3B)classColor
{
    return ccc3(0,96,255);
}
@end

@implementation Warlock
+(Warlock*)defaultWarlock{
    return [[[Warlock alloc] init] autorelease];
}

- (ccColor3B)classColor
{
    return ccc3(161,33,220);
}

- (id)init{
    if (self = [super initWithHealth:1142 damageDealt:521 andDmgFrequency:2.0 andPositioning:Ranged]){
        self.title = @"Warlock";
        self.info = @"Reduces enemy damage by 20%";
        self.dodgeChance = .07;
        self.lastAttack = arc4random() % 190 / 100.0f;
    }
    return self;
}

-(void)performAttackIfAbleOnTarget:(Enemy*)target{
	if (self.lastAttack >= self.damageFrequency && !self.isDead && !self.isStunned){
		self.lastAttack = 0.0;
        
        if (self.healthPercentage < .5){
            [self healSelfForAmount:50];
        } else {
            [target setHealth:[target health] - (self.damageDealt * self.damageDoneMultiplier)];
            [self.announcer displayAttackFromRaidMember:self onTarget:target];
        }
		
	}
}

- (void)combatUpdateForPlayers:(NSArray *)players enemies:(NSArray *)enemies theRaid:(Raid *)raid gameTime:(float)timeDelta {
    [super combatUpdateForPlayers:players enemies:enemies theRaid:raid gameTime:timeDelta];
    
    if (self.isDead && !self.deathEffectApplied) {
        Enemy *theBoss = (Enemy*)[enemies objectAtIndex:0];
        Effect *damageImprovement = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
        [damageImprovement setOwner:self];
        [damageImprovement setTitle:[NSString stringWithFormat:@"%@-dmg-eff", self.battleID]];
        [damageImprovement setDamageDoneMultiplierAdjustment:.2];
        [theBoss addEffect:damageImprovement];
        self.deathEffectApplied = YES;
    }
}
@end
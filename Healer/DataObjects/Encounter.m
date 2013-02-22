//
//  Encounter.m
//  RaidLeader
//
//  Created by Ryan Hart on 5/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Encounter.h"
#import "Player.h"
#import "Raid.h"
#import "RaidMember.h"
#import "Enemy.h"
#import "Spell.h"
#import "Shop.h"
#import "PlayerDataManager.h"
#import "CombatEvent.h"

@interface Encounter ()
@property (nonatomic, readwrite) NSInteger levelNumber;
@end

@implementation Encounter

- (void)dealloc{
    [_raid release];
    [_enemies release];
    [_requiredSpells release];
    [_recommendedSpells release];
    [_combatLog release];
    [super dealloc];
}

-(id)initWithRaid:(Raid*)rd andBoss:(Enemy*)bs andSpells:(NSArray*)sps{
    if (self = [super init]){
        self.raid = rd;
        self.enemies = [NSArray arrayWithObject:bs];
        self.recommendedSpells  = sps;
        self.difficulty = 2;
        
        self.combatLog = [NSMutableArray arrayWithCapacity:500];
    }
    return self;
}

- (Enemy *)boss
{
    return (Enemy*)[self.enemies objectAtIndex:0];
}

- (NSInteger)score
{
    if (self.levelNumber == 1) {
        return 0; //No score for level 1
    }
    NSInteger score = self.difficulty * (1400 * self.healingDone / self.damageTaken + 1400 * self.raid.livingMembers.count / self.raid.raidMembers.count) ;
    return score;
}

- (NSInteger)damageTaken
{
    int totalDamageTaken = 0;
    for (CombatEvent *event in self.combatLog){
        if ((event.type == CombatEventTypeDamage || event.type == CombatEventTypeShielding) && [[event source] isKindOfClass:[Enemy class]]){
            NSInteger dmgVal = [[event value] intValue];
            totalDamageTaken +=  abs(dmgVal);
        }
    }
    return MAX(1, totalDamageTaken);
}

- (NSInteger)healingDone
{
    NSString* thisPlayerId = nil;
    //    if (self.isMultiplayer) {
    //        thisPlayerId = [GKLocalPlayer localPlayer].playerID;
    //    }
    return [[[CombatEvent statsForPlayer:thisPlayerId fromLog:self.combatLog] objectForKey:PlayerHealingDoneKey] intValue];
}

- (NSInteger)overhealingDone
{
    NSString* thisPlayerId = nil;
//    if (self.isMultiplayer) {
//        thisPlayerId = [GKLocalPlayer localPlayer].playerID;
//    }
    return [[[CombatEvent statsForPlayer:thisPlayerId fromLog:self.combatLog] objectForKey:PlayerOverHealingDoneKey] intValue];
}

- (void)setLevelNumber:(NSInteger)levelNumber
{
    _levelNumber = levelNumber;
    self.difficulty = [[PlayerDataManager localPlayer] difficultyForLevelNumber:levelNumber];
}

- (void)setDifficulty:(NSInteger)difficulty
{
    _difficulty = MAX(1,MIN(5, difficulty));
    [[PlayerDataManager localPlayer] difficultySelected:self.difficulty forLevelNumber:self.levelNumber];
}

- (void)encounterWillBegin
{
    for (Enemy *boss in self.enemies) {
        [boss configureBossForDifficultyLevel:self.difficulty];
    }
}

- (NSInteger)reward
{
    NSInteger baseGold = [Encounter goldForLevelNumber:self.levelNumber];
    baseGold += (self.difficulty - 1) * 25;
    return baseGold;
}

- (void)saveCombatLog
{
    if (self.combatLog.count > 0) {
        NSMutableArray *events = [NSMutableArray arrayWithCapacity:self.combatLog.count];
        for (CombatEvent *event in self.combatLog){
            [events addObject:[event logLine]];
        }
        //Save the Combat Log to disk...
        [self writeApplicationData:(NSData*)events toFile:[NSString stringWithFormat:@"%@-%@", [[self.combatLog   objectAtIndex:0] timeStamp], [[self.combatLog lastObject] timeStamp]]];
    }
}

- (BOOL)writeApplicationData:(NSData *)data toFile:(NSString *)fileName {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	if (!documentsDirectory) {
		NSLog(@"Documents directory not found!");
		return NO;
	}
	NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
	return ([data writeToFile:appFile atomically:YES]);
}

#pragma mark - Class Methods

+ (Encounter*)randomMultiplayerEncounter{
    NSInteger roll = (arc4random() % 5 + 6);
    return [Encounter encounterForLevel:roll isMultiplayer:YES];
}

+ (Encounter*)encounterForLevel:(NSInteger)level isMultiplayer:(BOOL)multiplayer{
    Raid *basicRaid = [[[Raid alloc] init] autorelease];
    Enemy *basicBoss = nil;
    NSMutableArray *spells = nil;
    
    NSInteger numArcher = 0;
    NSInteger numGuardian = 0;
    NSInteger numChampion = 0;
    NSInteger numWarlock = 0;
    NSInteger numWizard = 0;
    NSInteger numBerserker = 0;
    
    NSString *bossKey = nil;
    
    if (level == 1){
        basicBoss = [Ghoul defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], nil];
        numChampion = 2;
        bossKey = @"ghoul";
    }
    
    if (level == 2){
        basicBoss = [CorruptedTroll defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil];
        
        numWizard = 1;
        numArcher = 1;
        numChampion = 1;
        numGuardian = 1;
        bossKey = @"troll";
    }
    
    if (level == 3){
        basicBoss = [Drake defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell],[GreaterHeal defaultSpell], nil];
        numWizard = 1;
        numArcher = 1;
        numChampion = 1;
        numGuardian = 1;
        bossKey = @"drake";
    }
    
    if (level == 4){
        basicBoss = [MischievousImps defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil];
        numWizard = 1;
        numArcher = 1;
        numChampion = 1;
        numGuardian = 1;
        bossKey = @"imps";
    }
    
    if (level == 5){
        basicBoss = [BefouledTreant defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell],[ForkedHeal defaultSpell], nil];
        
        numWizard = 2;
        numArcher = 2;
        numWarlock = 2;
        numChampion = 2;
        numGuardian = 1;
        bossKey = @"treant";
    }
    
    if (level == 6){
        basicBoss = [FungalRavagers defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [LightEternal defaultSpell], [Regrow defaultSpell], nil];
        
        numArcher = 2;
        numWarlock = 1;
        numWizard = 2;
        numChampion = 1;
        numGuardian = 3;
        bossKey = @"fungalravagers";
    }
    
    if (level == 7){
        basicBoss = [PlaguebringerColossus defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [ForkedHeal defaultSpell], [Regrow defaultSpell], nil];
        
        numArcher = 2;
        numWarlock = 2;
        numWizard = 2;
        numChampion = 2;
        numGuardian = 1;
        bossKey = @"plaguebringer";
    }
    
    if (level == 8){
        basicBoss = [Trulzar defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [Purify defaultSpell], [Regrow defaultSpell], nil];
    
        numWizard = 3;
        numArcher = 4;
        numWarlock = 2;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"trulzar";
    }
    
    if (level == 9){
        basicBoss = [DarkCouncil defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [Purify defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        numWizard = 3;
        numArcher = 2;
        numWarlock = 4;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"council";
    }
    
    if (level == 10){
        basicBoss = [TwinChampions defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal  defaultSpell], [GreaterHeal defaultSpell] , [Barrier defaultSpell], [HealingBurst defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 2;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 2;
        bossKey = @"twinchampions";
    }
    
    if (level == 11){
        basicBoss = [Baraghast defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"baraghast";
    }
    
    if (level == 12){
        basicBoss = [CrazedSeer defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"tyonath";
    }
    
    if (level == 13){
        basicBoss = [GatekeeperDelsarn defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 3;
        numWarlock = 4;
        numBerserker = 3;
        numChampion = 3;
        numGuardian = 3; //Blooddrinkers
        bossKey = @"gatekeeper";
    }
    
    if (level == 14){
        basicBoss = [SkeletalDragon defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"skeletaldragon";
    }
    
    if (level == 15){
        basicBoss = [ColossusOfBone defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numArcher = 4;
        numWizard = 3;
        numWarlock = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"colossusbone";
    }
    
    if (level == 16){
        basicBoss = [OverseerOfDelsarn defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal  defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numArcher = 4;
        numWarlock = 4;
        numWizard = 3;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"overseer";
    }
    
    if (level == 17){
        basicBoss = [TheUnspeakable defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numArcher = 4;
        numWarlock = 4;
        numWizard = 3;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"unspeakable";
    }
    
    if (level == 18){
        basicBoss = [BaraghastReborn defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"baraghastreborn";
    }
    
    if (level == 19){
        basicBoss = [AvatarOfTorment1 defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"avataroftorment";
    }
    
    if (level == 20){
        basicBoss = [AvatarOfTorment2 defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"avataroftorment";
    }
    
    if (level == 21){
        basicBoss = [SoulOfTorment defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"souloftorment";
    }
    
    if (!basicBoss){
        //If passed in an invalid level number and werent able to generate a boss...
        return nil;
    }
    
    for (int i = 0; i < numWizard; i++){
        [basicRaid addRaidMember:[Wizard defaultWizard]];
    }
    for (int i = 0; i < numArcher; i++){
        [basicRaid addRaidMember:[Archer defaultArcher]];
    }
    for (int i = 0; i < numWarlock; i++){
        [basicRaid addRaidMember:[Warlock defaultWarlock]];
    }
    for (int i = 0; i < numBerserker; i++){
        [basicRaid addRaidMember:[Berserker defaultBerserker]];
    }
    for (int i = 0; i < numChampion; i++){
        [basicRaid addRaidMember:[Champion defaultChampion]];
    }
    for (int i = 0; i < numGuardian; i++){
        [basicRaid addRaidMember:[Guardian defaultGuardian]];
    }
    
    basicBoss.isMultiplayer = multiplayer;
    Encounter *encToReturn = [[Encounter alloc] initWithRaid:basicRaid andBoss:basicBoss andSpells:spells];
    [encToReturn setLevelNumber:level];
    [encToReturn setBossKey:bossKey];
    return [encToReturn autorelease];
    
}

+(NSInteger)goldForLevelNumber:(NSInteger)levelNumber{
    NSInteger gold = 0;
    
    switch (levelNumber) {
        case 1:
            return -25;
        case 2:
        case 3:
        case 4:
        case 5:
            gold = 25;
            break;
        case 6:
        case 7:
        case 8:
        case 9:
        case 10:
            gold = 50;
            break;
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
            gold = 75;
            break;
        case 16:
        case 17:
        case 18:
        case 19:
            gold = 100;
            break;
        case 20:
            gold = 125;
            break;
        case 21:
            return 1;
            break;
    }
    
    return gold;
}

+ (Encounter*)survivalEncounterIsMultiplayer:(BOOL)multiplayer{
    Raid *basicRaid = [[[Raid alloc] init] autorelease];
    Enemy *basicBoss = [TheEndlessVoid defaultBoss];
    NSArray *spells = [NSArray arrayWithObjects:[Heal  defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];; 
    
    for (int i = 0; i < 4; i++){
        [basicRaid addRaidMember:[Wizard defaultWizard]];
    }
    for (int i = 0; i < 3; i++){
        [basicRaid addRaidMember:[Warlock defaultWarlock]];
    }
    for (int i = 0; i < 4; i++){
        [basicRaid addRaidMember:[Archer defaultArcher]];
    }
    for (int i = 0; i < 4; i++){
        [basicRaid addRaidMember:[Berserker defaultBerserker]];
    }
    for (int i = 0; i < 4; i++){
        [basicRaid addRaidMember:[Champion defaultChampion]];
    }
    for (int i = 0; i < 1; i++){
        [basicRaid addRaidMember:[Guardian defaultGuardian]];
    }
    
    basicBoss.isMultiplayer = multiplayer;
    Encounter *encToReturn = [[Encounter alloc] initWithRaid:basicRaid andBoss:basicBoss andSpells:spells];
    [encToReturn setLevelNumber:ENDLESS_VOID_ENCOUNTER_NUMBER];
    return [encToReturn autorelease];
}

+ (NSInteger)goldRewardForSurvivalEncounterWithDuration:(NSTimeInterval)duration {
    if (duration < 120){
        return 0;
    }
    
    return MIN(200, MAX(0, (duration - 120) / 2));
    
}

+ (NSString *)backgroundPathForEncounter:(NSInteger)encounter
{
    NSString *background = @"default-battle-bg";
    switch (encounter) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
            background = @"kingdom-bg";
            break;
    }
    return background;
}

@end
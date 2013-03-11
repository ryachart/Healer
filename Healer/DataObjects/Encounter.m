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
#import "Ability.h"

@interface Encounter ()
@property (nonatomic, readwrite) NSInteger levelNumber;
@end

@implementation Encounter

- (void)dealloc{
    [_raid release];
    [_enemies release];
    [_info release];
    [_title release];
    [_requiredSpells release];
    [_recommendedSpells release];
    [_combatLog release];
    [super dealloc];
}

- (id)initWithRaid:(Raid *)raid enemies:(NSArray *)enemies andSpells:(NSArray *)spells{
    if (self = [super init]){
        self.raid = raid;
        self.enemies = enemies;
        self.recommendedSpells  = spells;
        self.difficulty = 2;
        
        self.combatLog = [NSMutableArray arrayWithCapacity:500];
    }
    return self;
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
    NSMutableArray *enemies = [NSMutableArray arrayWithCapacity:3];
    NSMutableArray *spells = nil;
    
    NSInteger numArcher = 0;
    NSInteger numGuardian = 0;
    NSInteger numChampion = 0;
    NSInteger numWarlock = 0;
    NSInteger numWizard = 0;
    NSInteger numBerserker = 0;
    
    NSString *bossKey = nil;
    NSString *info = nil;
    NSString *title = nil;
    
    if (level == 1){
        [enemies addObject:[Ghoul defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], nil];
        numChampion = 2;
        bossKey = @"ghoul";
        info = @"These are strange times in the once peaceful kingdom of Theronia.  A dark mist has set beyond the Eastern Mountains and corrupt creatures have begun attacking innocent villagers and travelers along the roads.";
        title = @"The Ghoul";
    }
    
    if (level == 2){
        [enemies addObject:[CorruptedTroll defaultBoss]];
        
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil];
        
        numWizard = 1;
        numArcher = 1;
        numChampion = 1;
        numGuardian = 1;
        bossKey = @"troll";
        info = @"Three days ago a Raklorian Troll stumbled out from beyond the mountains and began ravaging the farmlands.  This was unusual behavior for a cave troll, but survivors noted that the troll seemed to be empowered by an evil magic.";
        title = @"Corrupted Troll";
    }
    
    if (level == 3){
        [enemies addObject:[Drake defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell],[GreaterHeal defaultSpell], nil];
        numWizard = 1;
        numArcher = 1;
        numChampion = 1;
        numGuardian = 1;
        bossKey = @"drake";
        
        info = @"A Drake of Soldorn has not been seen in Theronia for ages, but the foul creature has been burning down cottages and farms as well as killing countless innocents.  You and your allies have cornered the drake and forced a confrontation.";
        title = @"Tainted Drake";
    }
    
    if (level == 4){
        MischievousImps *boss = [MischievousImps defaultBoss];
        [enemies addObject:boss];
        Enemy *imp2 = [[[Enemy alloc] initWithHealth:boss.health damage:0 targets:1 frequency:1.25 choosesMT:NO] autorelease];
        [imp2 setThreatPriority:1];
        [imp2 setSpriteName:@"imps2_battle_portrait.png"];
        [imp2 setTitle:@"Imp"];
        [imp2 removeAbility:boss.autoAttack];
        imp2.autoAttack = [[[SustainedAttack alloc] initWithDamage:340 andCooldown:2.25] autorelease];
        imp2.autoAttack.failureChance = .25;
        [imp2 addAbility:imp2.autoAttack];
        [enemies addObject:imp2];
        
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil];
        numWizard = 1;
        numArcher = 1;
        numChampion = 1;
        numGuardian = 1;
        bossKey = @"imps";
        
        info = @"As the dark mists further encroach upon the kingdom more strange creatures begin terrorizing the innocents.  Viscious imps have infiltrated the alchemical storehouses on the outskirts of Terun.";
        title = @"Mischievious Imps";
    }
    
    if (level == 5){
        [enemies addObject:[BefouledTreant defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell],[ForkedHeal defaultSpell], nil];
        
        numWizard = 2;
        numArcher = 2;
        numWarlock = 2;
        numChampion = 2;
        numGuardian = 1;
        bossKey = @"treant";
        
        info = @"The Akarus, an ancient tree that has long rested in the Peraxu Forest, has become tainted with the foul energy of the dark mists. This once great tree must be ended for good.";
        title = @"Befouled Akarus";
    }
    
    if (level == 6){
        FinalRavager *boss = [FinalRavager defaultBoss];
        [enemies addObject:boss];
        
        FungalRavager *boss2 = [[[FungalRavager alloc] initWithHealth:boss.health damage:162 targets:1 frequency:2.6 choosesMT:YES] autorelease];
        boss2.autoAttack.failureChance = .25;
        boss2.threatPriority = 1;
        
        FungalRavager *boss3 = [[[FungalRavager alloc] initWithHealth:boss.health damage:193 targets:1 frequency:3.2 choosesMT:YES] autorelease];
        boss3.autoAttack.failureChance = .25;
        boss3.threatPriority = 2;
        
        [enemies addObject:boss2];
        [enemies addObject:boss3];
        
        [boss2 setSpriteName:@"fungalravagers2_battle_portrait.png"];
        [boss3 setSpriteName:@"fungalravagers3_battle_portrait.png"];
        
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [LightEternal defaultSpell], [Regrow defaultSpell], nil];
        
        numArcher = 2;
        numWarlock = 1;
        numWizard = 2;
        numChampion = 1;
        numGuardian = 3;
        bossKey = @"fungalravagers";
        
        info = @"As the dark mist consumes the Akarus ferocious beasts are birthed from its roots.  The ravagers immediately attack you and your allies.";
        title = @"Fungal Ravagers";
    }
    
    if (level == 7){
        [enemies addObject:[PlaguebringerColossus defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [ForkedHeal defaultSpell], [Regrow defaultSpell], nil];
        
        numArcher = 2;
        numWarlock = 2;
        numWizard = 2;
        numChampion = 2;
        numGuardian = 1;
        bossKey = @"plaguebringer";
        
        info = @"As the Akarus is finally consumed its branches begin to quiver and shake.  As the ground rumbles beneath its might, you and your allies witness a hideous transformation.  What once was a peaceful treant has now become an abomination.  Only truly foul magics could have caused this.";
        title = @"Plaguebringer Colossus";
    }
    
    if (level == 8){
        [enemies addObject:[Trulzar defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [Purify defaultSpell], [Regrow defaultSpell], nil];
    
        numWizard = 3;
        numArcher = 4;
        numWarlock = 2;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"trulzar";
        
        info = @"Days before the dark mists came, Trulzar disappeared into the Peraxu forest with only a spell book.  This once loyal warlock is wanted for questioning regarding the strange events that have befallen the land.  You have been sent with a large warband to bring Trulzar to justice.";
        title = @"Trulzar the Maleficar";
    }
    
    if (level == 9){
        Teritha *teritha = [[[Teritha alloc] initWithHealth:1000000 damage:0 targets:0 frequency:0 choosesMT:NO] autorelease];
        [teritha setInactive:YES];
        [teritha setThreatPriority:1];
        
        Grimgon *grimgon = [[[Grimgon alloc] initWithHealth:600000 damage:0 targets:0 frequency:0 choosesMT:NO] autorelease];
        [grimgon setInactive:YES];
        [grimgon setThreatPriority:2];
        
        Galcyon *galcyon = [[[Galcyon alloc] initWithHealth:600000 damage:0 targets:0 frequency:0 choosesMT:NO] autorelease];
        [galcyon setThreatPriority:3];
        
        [enemies addObject:teritha];
        [enemies addObject:grimgon];
        [enemies addObject:galcyon];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [Purify defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        numWizard = 3;
        numArcher = 2;
        numWarlock = 4;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"council";
        info = @"A contract in blood lay signed and sealed in Trulzar's belongings.  He had been summoned by a council of dark summoners to participate in an arcane ritual for some horrible purpose.  You and your allies have followed the sanguine invitation to a dark chamber beneath the Vargothian Swamps.";
        title = @"Council of Dark Summoners";
    }
    
    if (level == 10){
        Vorroth *vorroth = [[[Vorroth alloc] initWithHealth:1250000 damage:190 targets:1 frequency:1.3 choosesMT:YES] autorelease];
        vorroth.autoAttack.failureChance = .25;
        Sarroth *sarroth = [[[Sarroth alloc] initWithHealth:1250000 damage:760 targets:1 frequency:6.5 choosesMT:YES] autorelease];
        sarroth.autoAttack.failureChance = .25;
        
        vorroth.threatPriority = kThreatPriorityRandom;
        sarroth.threatPriority = kThreatPriorityRandom;
        
        [enemies addObject:vorroth];
        [enemies addObject:sarroth];
        spells = [NSArray arrayWithObjects:[Heal  defaultSpell], [GreaterHeal defaultSpell] , [Barrier defaultSpell], [HealingBurst defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 2;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 2;
        bossKey = @"twinchampions";
        info = @"You have crossed the eastern mountains through a path filled with ghouls, demons, and other terrible creatures.  Blood stained and battle worn, you and your allies have come across an encampment guarded by two skeletal champions.";
        title = @"Twin Champions of Baraghast";
    }
    
    if (level == 11){
        [enemies addObject:[Baraghast defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"baraghast";
        
        info = @"As his champions fell the dark warlord emerged from deep in the encampment.  Disgusted with the failure of his champions he confronts you and your allies himself.";
        title = @"Baraghast, Warlord of the Damned";
    }
    
    if (level == 12){
        [enemies addObject:[CrazedSeer defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"tyonath";
        
        info = @"Seer Tyonath was tormented and tortured after his capture by the Dark Horde. He guards the secrets to Baraghast's origin in a horrific chamber beneath the encampment.";
        title = @"Crazed Seer Tyonath";
    }
    
    if (level == 13){
        [enemies addObject:[GatekeeperDelsarn defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 3;
        numWarlock = 4;
        numBerserker = 3;
        numChampion = 3;
        numGuardian = 3; //Blooddrinkers
        bossKey = @"gatekeeper";
        
        info = @"Still deeper beneath the encampment you have discovered a portal to Delsarn.  No mortal has ever set foot in this ancient realm of evil and unless you and your allies can dispatch the gatekeeper no mortal ever will.";
        title = @"Gatekeeper of Delsarn";
    }
    
    if (level == 14){
        [enemies addObject:[SkeletalDragon defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"skeletaldragon";
        
        info = @"After slaying countless Delsari minor demons, your party has encountered a towering Skeletal Dragon.";
        title = @"Skeletal Dragon";
        
    }
    
    if (level == 15){
        [enemies addObject:[ColossusOfBone defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numArcher = 4;
        numWizard = 3;
        numWarlock = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"colossusbone";
        info = @"As the skeletal dragon falls and crashes to the ground you feel a rumbling in the distance.  Before you and your allies can even recover from the encounter with the skeletal dragon you are besieged by a monstrosity.";
        title = @"Colossus of Bone";
    }
    
    if (level == 16){
        [enemies addObject:[OverseerOfDelsarn defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal  defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numArcher = 4;
        numWarlock = 4;
        numWizard = 3;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"overseer";
        
        info = @"After defeating the most powerful and terrible creatures in Delsarn the Overseer of this treacherous realm confronts you himself.";
        title = @"Overseer of Delsarn";
    }
    
    if (level == 17){
        [enemies addObject:[TheUnspeakable defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numArcher = 4;
        numWarlock = 4;
        numWizard = 3;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"unspeakable";
        
        info = @"As you peel back the blood-sealed door to the inner sanctum of the Delsari citadel you find a horrific room filled with a disgusting mass of bones and rotten corpses.  The room itself seems to be ... alive.";
        title = @"The Unspeakable";
    }
    
    if (level == 18){
        [enemies addObject:[BaraghastReborn defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"baraghastreborn";
        
        info = @"Before you stands the destroyed but risen warchief Baraghast.  His horrible visage once again sows fear in the hearts of all of your allies.  His undead ferocity swells with the ancient and evil power of Delsarn.";
        title = @"Baraghast Reborn";
    }
    
    if (level == 19){
        [enemies addObject:[AvatarOfTorment1 defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"avataroftorment";
        
        info = @"From the dark heart of Baraghast's shattered corpse emerges a hideous and cackling demon of unfathomable power. Before you stands a massive creature spawned of pure hatred whose only purpose is torment.";
        title = @"The Avatar of Torment";
    }
    
    if (level == 20){
        [enemies addObject:[AvatarOfTorment2 defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"avataroftorment";
        
        info = @"Torment will not be vanquished so easily.";
        title = @"The Avatar of Torment";
    }
    
    if (level == 21){
        [enemies addObject:[SoulOfTorment defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 4;
        numArcher = 4;
        numBerserker = 4;
        numChampion = 3;
        numGuardian = 1;
        bossKey = @"souloftorment";
        
        info = @"Its body shattered and broken--the last gasp of this terrible creature conspires to unleash its most unspeakable power.  Your allies are bleeding and broken and your souls are exhausted by the strain of endless battle, but the final evil must be vanquished...";
        title = @"The Soul of Torment";
    }
    
    if (enemies.count == 0){
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
    
    for (Enemy *enemy in enemies) {
        enemy.isMultiplayer = multiplayer;
    }
    Encounter *encToReturn = [[Encounter alloc] initWithRaid:basicRaid enemies:enemies andSpells:spells];
    [encToReturn setInfo:info];
    [encToReturn setTitle:title];
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
            return 150;
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
    Encounter *encToReturn = [[Encounter alloc] initWithRaid:basicRaid enemies:[NSArray arrayWithObject:basicBoss] andSpells:spells];
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
    NSString *background = @"kingdom-bg";
    switch (encounter) {
        case 1:
            break;
        case 2:
        case 3:
            background = @"cave-bg";
            break;
        case 4:
            background = @"kingdom-bg";
            break;
        case 5:
        case 6:
        case 7:
            break;
        case 8:
        case 9:
            background = @"throne-bg";
            break;
        case 10:
            break;
    }
    return background;
}

@end
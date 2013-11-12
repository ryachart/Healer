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
#import "EquipmentItem.h"
#import "LootTable.h"

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
    if (self.levelNumber == 4) {
        if (self.difficulty == 5) {
            NSInteger brutalHealth = 80000;
            Enemy *attackingImp = [self.enemies objectAtIndex:1];
            [attackingImp setThreatPriority:kThreatPriorityRandom];
            [attackingImp setMaximumHealth:brutalHealth];
            [attackingImp setHealth:brutalHealth];
            Enemy *imp3 = [[[Enemy alloc] initWithHealth:brutalHealth damage:0 targets:1 frequency:1.25 choosesMT:NO] autorelease];
            [imp3 setThreatPriority:kThreatPriorityRandom];
            [imp3 setSpriteName:@"imps4_battle_portrait.png"];
            [imp3 setTitle:@"Imp"];
            self.enemies = [self.enemies arrayByAddingObject:imp3];
            
            ProjectileAttack *bolts = [[[ProjectileAttack alloc] init] autorelease];
            [bolts setSpriteName:@"shadowbolt.png"];
            bolts.executionSound = @"fireball.mp3";
            bolts.explosionSoundName = @"explosion_pulse.wav";
            [bolts setExplosionParticleName:@"shadow_burst.plist"];
            [bolts setAbilityValue:-300];
            [bolts setCooldown:4];
            [imp3 addAbility:bolts];
            
            Effect *cackleFailed = [[[Effect alloc] initWithDuration:10.0 andEffectType:EffectTypeNegative] autorelease];
            [cackleFailed setCastTimeAdjustment:-.5];
            [cackleFailed setTitle:@"cackle-fail"];
            
            InterruptionAbility *cackle = [[[InterruptionAbility alloc] init] autorelease];
            [cackle setExecutionSound:@"imp_cackle.mp3"];
            [cackle setCooldown:24.0];
            [cackle setCooldownVariance:.4];
            [cackle setActivationTime:1.5];
            [cackle setIconName:@"shadow_roar.png"];
            [cackle setAppliedEffectOnInterrupt:cackleFailed];
            [cackle setInfo:@"Interrupts casting.  If a Healer is casting when this ability completes the Healer's cast times are increased by 50% for 10 seconds."];
            [cackle setTitle:@"Cackle"];
            [imp3 addAbility:cackle];
            
        }
    }
    
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
    NSArray *spells = nil;
    
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
        numWizard = 1;
        numArcher = 1;
        numChampion = 1;
        numGuardian = 1;
        bossKey = @"ghoul";
        info = @"You have been sent to a local farm to sound the King’s Call-to-Arms.  Upon your arrival you notice the men you’ve been sent to recruit fighting off a foul-looking creature.  A mangled body of a long-dead Theronian soldier is swinging wildly at your allies.  You rush to their aid.";
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
        info = @"After enlisting the aid of a small band of soldiers you begin your trek back to Terun.  Upon your return you notice that the ground around a local cave, home to a Raklorian Troll, has stains of blood leading into the cave’s entrance. You and your allies enter to investigate.";
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
        
        info = @"Upon further investigation you discover that the Troll’s sanctum leads deeper into the cavern.  You find that the Troll hasn’t been eating all of the livestock that it has been stealing; rather, feeding it to something more terrible.";
        title = @"Tainted Drake";
    }
    
    if (level == 4){
        MischievousImps *boss = [MischievousImps defaultBoss];
        [enemies addObject:boss];
        Enemy *imp2 = [[[Enemy alloc] initWithHealth:boss.health damage:0 targets:1 frequency:1.25 choosesMT:NO] autorelease];
        [imp2 setThreatPriority:2];
        [imp2 setSpriteName:@"imps2_battle_portrait.png"];
        [imp2 setTitle:@"Imp"];
        [imp2 removeAbility:imp2.autoAttack];
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
        info = @"On your way to the King's keep you are approached by a flustered guard.  He informs you that imps have invaded the capital’s Alchemical Storehouse.  The warehouse is home to dangerous potions and elixirs.  To avoid a major catastrophe your party hurries to the storehouse.";
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
        
        info = @"Your warband has been sent to the Green Citadel deep in the Peraxu Forest.  The Archmage Tyonath journeyed there weeks ago but never returned.  Upon approaching the forest’s edge you encounter the Akarus, a wise old treant and guardian of the forest.  Tainted by foul magics the Akarus confronts you as an enemy.";
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
        
        info = @"With a monstrous crash the sage old tree comes thundering to the earth.  As you are all catching your breath a fog of spores releases itself from the tree.  The tree withers before you at an unnatural rate.  Through the dark, stifling cloud you can see three pairs of yellow, glowing eyes.";
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
        
        info = @"As the last Ravager falls you notice the forest wither more and more as it recedes into darkness.  The ground is dying in sync with the vegetation and, as the sky darkens you discover that the now mutated Akarus has risen once more.";
        title = @"Plaguebringer Colossus";
    }
    
    if (level == 8){
        [enemies addObject:[Trulzar defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [Purify defaultSpell], [Regrow defaultSpell], nil];
    
        numWizard = 3;
        numArcher = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"trulzar";
        
        info = @"After a grueling journey through the forest you come to the doors of The Green Citadel. The citadel itself is now black and seems to be the center of the forest’s corruption.  A torn violet banner now hangs over its entrance.  You open the doors cautiously to find Trulzar, the Citadel’s keeper.  He is...changed.";
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
        numArcher = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"council";
        info = @"One of your wizards finds a writ of orders in Trulzar’s belongings.  He was ordered to torture and brainwash a prisoner.  It was signed by a name unknown to you - Baraghast.  As you journey deeper into the citadel you find three hooded wizards channeling an incantation over an altar. Stop them!";
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
        numArcher = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 3;
        numGuardian = 2;
        bossKey = @"twinchampions";
        info = @"As the last of the council of dark wizards falls a beam of blue light emits from the altar.  The beam streaks through grooves cut into the floor leading to the exit.  The doors fly open revealing a throne room.  Two huge, armored skeletons come to life and assemble before you.";
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
        
        info = @"A large, bulky suit of armor slumped on the throne before you, stirs.  A pair of glowing red eyes spark to life, and the breathless mass of flesh and armor slowly rises before you.  With disembodied echo the creature speaks to you, \"I am Baraghast, Warlord of the Damned.  Your villages will burn. Your cities will anguish.  Torment is coming.\".";
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
        
        info = @"Your group moves onward toward what you believe to be the prison tower.  After climbing the spiral staircase you enter a large chamber at the top of the tower.  Alone in the dark stands a wizard in tattered cloth.  He appears to be blind.  He hears your entrance and grins with crooked teeth. Through furious cackles he shouts,\"Visitors!\"";
        title = @"Crazed Seer Tyonath";
    }
    
    if (level == 13){
        [enemies addObject:[GatekeeperDelsarn defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"gatekeeper";
        
        info = @"Your captain sends word to the king discussing the fates of the forest, the citadel, and the archmage.  Days later, the king responds.  Baraghast’s words seem to hint at the fulfillment of a dark prophecy.  He orders you to take the citadel’s portal to Delsarn to investigate.  As you approach the portal a hulking fiend emerges to stop you.";
        title = @"Gatekeeper of Delsarn";
    }
    
    if (level == 14){
        [enemies addObject:[SkeletalDragon defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numArcher = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"skeletaldragon";
        
        info = @"On the other side of the portal you find an underground entrance to a subterranean lair beneath the landscape known as the Gateway to Delsarn. You make your way through the lair and approach a chamber with the skeletal remains of a dragon.  Before you can leave the chasm the skeleton glows with dark magic and rises to block your path.";
        title = @"Skeletal Dragon";
        
    }
    
    if (level == 15){
        [enemies addObject:[ColossusOfBone defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numArcher = 3;
        numWizard = 3;
        numWarlock = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"colossusbone";
        info = @"The dragon shatters before you and its bone fragments drop off into the toxic pool over which it stands.  The green concoction begins to bubble and boil and from it ascends a colossal construct of bone.";
        title = @"Colossus of Bone";
    }
    
    if (level == 16){
        [enemies addObject:[OverseerOfDelsarn defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal  defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numArcher = 3;
        numWarlock = 3;
        numWizard = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"overseer";
        
        info = @"You enter Delsarn to see the streets deserted. As you approach the castle you see the violet banner of the Damned hanging from the entryway.  Outside the castle gates a hooded Delsari battlemage confronts you. \"You will not stop us from bringing Torment to this world.  Delsarn has already fallen to our dark lord. Theronia shall be next.\"";
        title = @"Overseer of Delsarn";
    }
    
    if (level == 17){
        [enemies addObject:[TheUnspeakable defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numArcher = 3;
        numWarlock = 3;
        numWizard = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"unspeakable";
        
        info = @"As the overseer falls crazed cultists pour from the castle.  The sheer number of cultists forces you into full retreat from the city streets.  You fall back into a dark sewer beneath the city’s magic academy.  The cultists grow wide-eyed and flee as a strange rumbling grows behind you.";
        title = @"The Unspeakable";
    }
    
    if (level == 18){
        [enemies addObject:[BaraghastReborn defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        numWizard = 3;
        numWarlock = 3;
        numArcher = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"baraghastreborn";
        
        info = @"You emerge from the sewer just outside the city.  As you leave Delsarn to regroup and send word you hear an all too familiar roar behind you.  Reborn in blood, Baraghast approaches with glowing runes of power seared into his reformed flesh.";
        title = @"Baraghast Reborn";
    }
    
    if (level == 19){
        [enemies addObject:[AvatarOfTorment1 defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 3;
        numArcher = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"avataroftorment";
        
        info = @"As Baraghast falls the ground shakes and the mountain in the distance erupts into a torrent of obsidian and brimstone.  A bright red portal opens before you as an invitation to your own demise.  Beyond the portal you emerge to a demonic creature. \"I,\"he snarls, \"am Torment’s vessel.\"";
        title = @"The Avatar of Torment";
    }
    
    if (level == 20){
        [enemies addObject:[AvatarOfTorment2 defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 3;
        numArcher = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"avataroftorment";
        
        info = @"The Avatar sinks beneath the pool of molten rock to regain its power.  Knowing you have not yet vanquished this beast your allies briefly recover and prepare for a second battle against this demon.";
        title = @"The Avatar of Torment II";
    }
    
    if (level == 21){
        [enemies addObject:[SoulOfTorment defaultBoss]];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        numWizard = 3;
        numWarlock = 3;
        numArcher = 3;
        numBerserker = 5;
        numChampion = 4;
        numGuardian = 1;
        bossKey = @"souloftorment";
        
        info = @"Its flesh shattered and broken, you stand before a massive orb of blinding light.  Red light rays violently lash out at your party members.  You feel your mind succumbing to your body’s intense pain.  You take one deep breath to calm your senses, and prepare your most powerful magics to end this great evil once and for all.";
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

+ (Encounter*)pocketEncounterForLevel:(NSInteger)level
{
    
    Raid *raid = [[[Raid alloc] init] autorelease];
    Enemy *enemyForEncounter = nil;
    NSMutableArray *enemies = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *spells = [NSMutableArray arrayWithCapacity:4];
    NSString *info = @"LOL TROLL";
    NSString *title = @"Corrupted Troll";
    NSString *bossKey = @"troll";
    
    NSInteger numArcher = 0;
    NSInteger numGuardian = 0;
    NSInteger numChampion = 0;
    NSInteger numWarlock = 0;
    NSInteger numWizard = 0;
    NSInteger numBerserker = 0;
    
    if (level == 1) {    
        enemyForEncounter = [CorruptedTroll defaultBoss];
        bossKey = @"troll";
    } else if (level == 2) {
        enemyForEncounter = [Drake defaultBoss];
        bossKey = @"drake";
    } else if (level == 3){
        enemyForEncounter = [MischievousImps defaultBoss];
        bossKey = @"imps";
    } else if (level == 4) {
        enemyForEncounter = [BefouledTreant defaultBoss];
        bossKey = @"treant";
    } else if (level == 5) {
        enemyForEncounter = [FinalRavager defaultBoss];
        bossKey = @"fungalravagers";
    } else if (level == 6) {
        enemyForEncounter = [PlaguebringerColossus defaultBoss];
        bossKey = @"plaguebringer";
    } else if (level == 7) {
        enemyForEncounter = [Trulzar defaultBoss];
        bossKey = @"trulzar";
    } else if (level == 8) {
        enemyForEncounter = [Baraghast defaultBoss];
        bossKey = @"baraghast";
    } else if (level == 9) {
        enemyForEncounter = [CrazedSeer defaultBoss];
        bossKey = @"tyonath";
    } else if (level == 10) {
        enemyForEncounter = [GatekeeperDelsarn defaultBoss];
        bossKey = @"gatekeeper";
    } else if (level == 11) {
        enemyForEncounter = [SkeletalDragon defaultBoss];
        bossKey = @"skeletaldragon";
    } else if (level == 12) {
        enemyForEncounter = [ColossusOfBone defaultBoss];
        bossKey = @"colossusbone";
    } else if (level == 13) {
        enemyForEncounter = [OverseerOfDelsarn defaultBoss];
        bossKey = @"overseer";
    } else {
        enemyForEncounter = [TheEndlessVoid defaultBoss];
        info = @"The Endless Void";
        title = @"The Endless Void";
        [(TheEndlessVoid*)enemyForEncounter setRequiredResets:level - 1];
        bossKey = @"endlessvoid";
    }
    
    title = bossKey;
    
    [enemyForEncounter reconfigureMaximumHealth:780000];
    [enemyForEncounter configureBossForDifficultyLevel:2];
    
    [enemies addObject:enemyForEncounter];
    
    [spells addObject:[Heal defaultSpell]];
    
    if (level != 7) {
        [spells addObject:[GreaterHeal defaultSpell]];
    } else {
        [spells addObject:[Purify defaultSpell]];
    }
    [spells addObject:[Regrow defaultSpell]];
    [spells addObject:[ForkedHeal defaultSpell]];
    
    numWizard = 2;
    numWarlock = 2;
    numArcher = 2;
    numBerserker = 2;
    numChampion = 2;
    numGuardian = 1;
    
    
    for (int i = 0; i < numWizard; i++){
        [raid addRaidMember:[Wizard defaultWizard]];
    }
    for (int i = 0; i < numArcher; i++){
        [raid addRaidMember:[Archer defaultArcher]];
    }
    for (int i = 0; i < numWarlock; i++){
        [raid addRaidMember:[Warlock defaultWarlock]];
    }
    for (int i = 0; i < numBerserker; i++){
        [raid addRaidMember:[Berserker defaultBerserker]];
    }
    for (int i = 0; i < numChampion; i++){
        [raid addRaidMember:[Champion defaultChampion]];
    }
    for (int i = 0; i < numGuardian; i++){
        [raid addRaidMember:[Guardian defaultGuardian]];
    }
    
    Encounter *encToReturn = [[[Encounter alloc] initWithRaid:raid enemies:enemies andSpells:spells] autorelease];
    [encToReturn setInfo:info];
    [encToReturn setTitle:title];
    [encToReturn setBossKey:bossKey];
    [encToReturn setLevelNumber:level];
    return encToReturn;
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
            background = IS_IPAD ? @"kingdom-bg" : @"cave-lava-bg";
            break;
        case 2:
        case 3:
            background = @"cave-lava-bg";
            break;
        case 4:
            background = @"kingdom-bg";
            break;
        case 5:
            background = @"forest-day-bg";
            break;
        case 6:
        case 7:
            background = @"forest-night-bg";
            break;
        case 8:
            background = @"darkroom-bg";
            break;
        case 9:
        case 10:
            background = @"throne-bg";
            break;
        case 11:
        case 12:
            background = @"darkroom-bg";
            break;
        case 13:
            background = @"portal-bg";
            break;
        case 14:
        case 15:
            background = @"cave-poison-bg";
            break;
        case 16:
            background = @"city-bg";
            break;
        case 17:
            background = @"cave-poison-bg";
            break;
        case 18:
            background = @"city-bg";
            break;
        case 19:
        case 20:
        case 21:
            background = @"tormentrealm-bg";
            break;
        default:
            background = @"cave-poison-bg";
            break;
            
    }
    return background;
}

- (NSString *)battleTrackTitle
{
    switch (self.levelNumber) {
        case 7:
        case 8:
        case 9:
        case 11:
        case 19:
        case 20:
        case 21:
            return @"sounds/battle2.mp3";
    }
    
    return @"sounds/battle1.mp3";
}

+ (NSArray *)weightsForDifficulty:(NSInteger)difficulty
{
    if (difficulty <= 2) {
        return @[@70, @25, @5, @0];
    } else if (difficulty == 3) {
        return @[@55, @35, @10, @0];
    } else if (difficulty == 4) {
        return @[@30, @50, @20, @0];
    } else if (difficulty == 5) {
        return @[@0, @30, @50, @20];
    }
    return @[@100,@0,@0,@0];
}

+ (EquipmentItem*)randomItemForLevelNumber:(NSInteger)levelNum difficulty:(NSInteger)difficulty rarity:(ItemRarity)rarity
{
    NSInteger ql = 0;
    if (levelNum <= 7) {
        ql = min(difficulty, 4);
    } else if (levelNum <= 13) {
        ql = min(2+difficulty, 6);
    } else if (levelNum <= 21) {
        ql = min(4+difficulty, 8);
    }
    
    return [EquipmentItem randomItemWithRarity:rarity andQuality:ql];
}


+ (NSArray *)epicItemsForLevelNumber:(NSInteger)levelNumber
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:2];
    
    if (levelNumber == 2) {
        EquipmentItem *trollEpic = [[[EquipmentItem alloc] initWithName:@"Codex of Rage" health:15 regen:1.0 speed:0 crit:0 healing:2.0 slot:SlotTypeWeapon rarity:ItemRarityEpic specialKey:@"burst1" quality:3 uniqueId:100] autorelease];
        [items addObject:trollEpic];
    }
    
    if (levelNumber == 3) {
        EquipmentItem *drakeEpic = [[[EquipmentItem alloc] initWithName:@"Drakewing Hood" health:0 regen:0.0 speed:1.5 crit:2.25 healing:2.0 slot:SlotTypeHead rarity:ItemRarityEpic specialKey:nil quality:3 uniqueId:101] autorelease];
        [items addObject:drakeEpic];
    }
    
    if (levelNumber == 4) {
        EquipmentItem *impsEpic = [[[EquipmentItem alloc] initWithName:@"Pendant of Mischief" health:0 regen:3.0 speed:1.5 crit:2.25 healing:0.0 slot:SlotTypeNeck rarity:ItemRarityEpic specialKey:nil quality:4 uniqueId:102] autorelease];
        [items addObject:impsEpic];
    }
    
    if (levelNumber == 5) {
        EquipmentItem *treantEpic = [[[EquipmentItem alloc] initWithName:@"Barkskin Trousers" health:30 regen:0.0 speed:0.0 crit:2.25 healing:2.5 slot:SlotTypeLegs rarity:ItemRarityEpic specialKey:nil quality:4 uniqueId:103] autorelease];
        [items addObject:treantEpic];
    }
    
    if (levelNumber == 6) {
        EquipmentItem *ravagersEpic = [[[EquipmentItem alloc] initWithName:@"Sandals of Regrowth" health:0 regen:2.0 speed:0 crit:3.0 healing:3.5 slot:SlotTypeBoots rarity:ItemRarityEpic specialKey:nil quality:5 uniqueId:104] autorelease];
        [items addObject:ravagersEpic];
    }
    
    if (levelNumber == 7) {
        EquipmentItem *plaguebringerEpic = [[[EquipmentItem alloc] initWithName:@"Gown of the Purifier" health:50 regen:2.0 speed:0 crit:0 healing:2.5 slot:SlotTypeChest rarity:ItemRarityEpic specialKey:nil quality:5 uniqueId:105] autorelease];
        [items addObject:plaguebringerEpic];
    }
    
    if (levelNumber == 8) {
        EquipmentItem *trulzarEpic = [[[EquipmentItem alloc] initWithName:@"The Maleficar's Cowl" health:0 regen:3.5 speed:2.5 crit:0.0 healing:2.5 slot:SlotTypeHead rarity:ItemRarityEpic specialKey:nil quality:5 uniqueId:106] autorelease];
        [items addObject:trulzarEpic];
    }
    
    if (levelNumber == 9) {
        EquipmentItem *councilEpic = [[[EquipmentItem alloc] initWithName:@"Amulet of the Ritualist" health:25 regen:0 speed:1.0 crit:0 healing:4.0 slot:SlotTypeNeck rarity:ItemRarityEpic specialKey:nil quality:5 uniqueId:107] autorelease];
        [items addObject:councilEpic];
        EquipmentItem *councilEpic2 = [[[EquipmentItem alloc] initWithName:@"Words of Warding" health:0 regen:3.5 speed:0.0 crit:0.0 healing:4.0 slot:SlotTypeWeapon rarity:ItemRarityEpic specialKey:@"purify1" quality:5 uniqueId:200] autorelease];
        [items addObject:councilEpic2];
    }
    
    if (levelNumber == 10) {
        EquipmentItem *twinsEpic = [[[EquipmentItem alloc] initWithName:@"Blood-splattered Pants" health:0 regen:4.0 speed:3.0 crit:4.5 healing:0 slot:SlotTypeLegs rarity:ItemRarityEpic specialKey:nil quality:6 uniqueId:108] autorelease];
        [items addObject:twinsEpic];
        
        EquipmentItem *twinsEpic2 = [[[EquipmentItem alloc] initWithName:@"Executioner's Cowl" health:40 regen:0 speed:0 crit:4.5 healing:3.0 slot:SlotTypeHead rarity:ItemRarityEpic specialKey:nil quality:6 uniqueId:201] autorelease];
        [items addObject:twinsEpic2];
    }
    
    if (levelNumber == 11) {
        EquipmentItem *baraghastEpic = [[[EquipmentItem alloc] initWithName:@"Tome of the Warlord" health:0 regen:1.5 speed:0.0 crit:2.25 healing:6.0 slot:SlotTypeWeapon rarity:ItemRarityEpic specialKey:@"raidheal1" quality:6 uniqueId:109] autorelease];
        [items addObject:baraghastEpic];
        EquipmentItem *baraghastEpic2 = [[[EquipmentItem alloc] initWithName:@"Hate-Imbued Libram" health:0 regen:3.0 speed:3.0 crit:0 healing:3.0 slot:SlotTypeWeapon rarity:ItemRarityEpic specialKey:@"blast1" quality:6 uniqueId:202] autorelease];
        [items addObject:baraghastEpic2];
    }
    
    if (levelNumber == 12) {
        EquipmentItem *seerEpic = [[[EquipmentItem alloc] initWithName:@"Gown of Insanity" health:50 regen:4 speed:0 crit:0 healing:4 slot:SlotTypeChest rarity:ItemRarityEpic specialKey:nil quality:7 uniqueId:110] autorelease];
        [items addObject:seerEpic];
    }
    
    if (levelNumber == 13) {
        EquipmentItem *gatekeeperEpic = [[[EquipmentItem alloc] initWithName:@"Boots from Beyond" health:40 regen:0 speed:3.5 crit:4.5 healing:0 slot:SlotTypeBoots rarity:ItemRarityEpic specialKey:nil quality:7 uniqueId:111] autorelease];
        [items addObject:gatekeeperEpic];
    }
    
    if (levelNumber == 14) {
        EquipmentItem *dragonEpic = [[[EquipmentItem alloc] initWithName:@"Bone-scaled Breeches" health:50 regen:5.0 speed:3.5 crit:0.0 healing:0 slot:SlotTypeLegs rarity:ItemRarityEpic specialKey:nil quality:8 uniqueId:112] autorelease];
        [items addObject:dragonEpic];
    }
    
    if (levelNumber == 15) {
        EquipmentItem *colossusEpic = [[[EquipmentItem alloc] initWithName:@"Colossal Bone Necklace" health:0 regen:3.0 speed:0 crit:9.0 healing:3.0 slot:SlotTypeNeck rarity:ItemRarityEpic specialKey:nil quality:8 uniqueId:113] autorelease];
        [items addObject:colossusEpic];
    }
    
    if (levelNumber == 16) {
        EquipmentItem *overseerEpic = [[[EquipmentItem alloc] initWithName:@"Tome of the Overseer" health:0 regen:3.0 speed:3.0 crit:4.5 healing:3.0 slot:SlotTypeWeapon rarity:ItemRarityEpic specialKey:@"healbuff1" quality:8 uniqueId:115] autorelease];
        [items addObject:overseerEpic];
    }
    
    if (levelNumber == 17) {
        EquipmentItem *unspeakableEpic = [[[EquipmentItem alloc] initWithName:@"Slime-soaked Waders" health:35 regen:5.0 speed:5.0 crit:0.0 healing:0 slot:SlotTypeBoots rarity:ItemRarityEpic specialKey:nil quality:8 uniqueId:114] autorelease];
        [items addObject:unspeakableEpic];
    }
    
    if (levelNumber == 18) {
        EquipmentItem *rebornEpic = [[[EquipmentItem alloc] initWithName:@"Shawl of the Reborn" health:25 regen:5.0 speed:2.5 crit:0 healing:5.0 slot:SlotTypeHead rarity:ItemRarityEpic specialKey:nil quality:9 uniqueId:116] autorelease];
        [items addObject:rebornEpic];
    }
    
    if (levelNumber == 19 || levelNumber == 20) {
        EquipmentItem *avatar1Epic = [[[EquipmentItem alloc] initWithName:@"Amulet of Torment" health:0 regen:5 speed:0 crit:5.25 healing:5.0 slot:SlotTypeNeck rarity:ItemRarityEpic specialKey:nil quality:9 uniqueId:117] autorelease];
        [items addObject:avatar1Epic];
    }
    
    if (levelNumber == 21) {
        EquipmentItem *soulEpic = [[[EquipmentItem alloc] initWithName:@"Soul-Imbued Robes" health:70 regen:5.0 speed:5.0 crit:0.0 healing:0.0 slot:SlotTypeChest rarity:ItemRarityEpic specialKey:nil quality:9 uniqueId:118] autorelease];
        [items addObject:soulEpic];
    }
    
    
    return items;
}

+ (NSArray *)legendaryItemsForLevelNumber:(NSInteger)levelNumber
{
    NSMutableArray *array = [NSMutableArray array];
    if (levelNumber == 12){
        EquipmentItem *seerLegend = [[[EquipmentItem alloc] initWithName:@"Boots of the Ancients" health:50 regen:5.0 speed:5.0 crit:0 healing:5.0 slot:SlotTypeBoots rarity:ItemRarityLegendary specialKey:nil quality:10 uniqueId:300] autorelease];
        [array addObject:seerLegend];
    }
    
    if (levelNumber == 16) {
        EquipmentItem *overseerLegend = [[[EquipmentItem alloc] initWithName:@"Pendant of the Ancients" health:50 regen:5.0 speed:0 crit:7.5 healing:5.0 slot:SlotTypeNeck  rarity:ItemRarityLegendary specialKey:nil quality:10 uniqueId:301] autorelease];
        [array addObject:overseerLegend];
    }
    
    if (levelNumber == 18) {
        EquipmentItem *rebornLegend = [[[EquipmentItem alloc] initWithName:@"Robes of the Ancients" health:75 regen:5.0 speed:0 crit:7.5 healing:7.5 slot:SlotTypeChest rarity:ItemRarityLegendary specialKey:nil quality:10 uniqueId:301] autorelease];
        [array addObject:rebornLegend];
    }
    
    if (levelNumber == 19) {
        EquipmentItem *avatar1Legend = [[[EquipmentItem alloc] initWithName:@"Breeches of the Ancients" health:50 regen:0 speed:5.0 crit:7.5 healing:7.5 slot:SlotTypeLegs rarity:ItemRarityLegendary specialKey:nil quality:10 uniqueId:301] autorelease];
        [array addObject:avatar1Legend];
    }
    
    if (levelNumber == 20) {
        EquipmentItem *avatar2Legend = [[[EquipmentItem alloc] initWithName:@"Crown of the Ancients" health:50 regen:5.0 speed:0 crit:7.5 healing:7.5 slot:SlotTypeHead rarity:ItemRarityLegendary specialKey:nil quality:10 uniqueId:301] autorelease];
        [array addObject:avatar2Legend];
    }
    
    if (levelNumber == 21) {
        EquipmentItem *soulLegend = [[[EquipmentItem alloc] initWithName:@"Aravon's Lesson" health:40 regen:6.0 speed:5.0 crit:0 healing:5.0 slot:SlotTypeWeapon rarity:ItemRarityLegendary specialKey:@"aravon1" quality:10 uniqueId:301] autorelease];
        [array addObject:soulLegend];
    }
    
    return array;
}


- (EquipmentItem *)randomLootReward
{
    NSArray *weights = [Encounter weightsForDifficulty:self.difficulty];
    EquipmentItem *green = [Encounter randomItemForLevelNumber:self.levelNumber difficulty:self.difficulty rarity:ItemRarityUncommon];
    EquipmentItem *blue = [Encounter randomItemForLevelNumber:self.levelNumber difficulty:self.difficulty rarity:ItemRarityRare];
    NSArray *epics = [Encounter epicItemsForLevelNumber:self.levelNumber];
    EquipmentItem *epic = nil;
    if (epics.count == 0) {
        epic = [Encounter randomItemForLevelNumber:self.levelNumber difficulty:self.difficulty rarity:ItemRarityRare];
    } else {
        epic = [epics objectAtIndex:arc4random() % epics.count];
    }
    NSArray *legendarys = [Encounter legendaryItemsForLevelNumber:self.levelNumber];
    EquipmentItem *legendary = nil;
    if (legendarys.count == 0) {
        legendarys = [Encounter epicItemsForLevelNumber:self.levelNumber];
        if (legendarys.count == 0) {
            legendary = [Encounter randomItemForLevelNumber:self.levelNumber difficulty:self.difficulty rarity:ItemRarityRare];
        } else {
            legendary = [legendarys objectAtIndex:arc4random() % legendarys.count];
        }
    } else {
            legendary = [legendarys objectAtIndex:arc4random() % legendarys.count];
    }
    NSArray *items = [NSArray arrayWithObjects:green,blue, epic, legendary, nil];
    LootTable *table = [[[LootTable alloc] initWithItems:items andWeights:weights] autorelease];
    
    
    return [table randomObject];
}

@end
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
#import "Boss.h"
#import "Spell.h"

@interface Encounter ()
@property (nonatomic, readwrite) NSInteger levelNumber;
@end

@implementation Encounter
@synthesize raid, boss, requiredSpells, recommendedSpells, levelNumber;

- (void)dealloc{
    [raid release];
    [boss release];
    [requiredSpells release];
    [recommendedSpells release];
    [super dealloc];
}
-(id)initWithRaid:(Raid*)rd andBoss:(Boss*)bs andSpells:(NSArray*)sps{
    if (self = [super init]){
        self.raid = rd;
        self.boss = bs;
        self.recommendedSpells  = sps;
    }
    return self;
}

+ (Encounter*)randomMultiplayerEncounter{
    return [Encounter encounterForLevel:(arc4random() % 5 + 6) isMultiplayer:YES];
}

+ (Encounter*)encounterForLevel:(NSInteger)level isMultiplayer:(BOOL)multiplayer{
    Raid *basicRaid = nil;
    Boss *basicBoss = nil;
    NSMutableArray *spells = [NSMutableArray arrayWithCapacity:4];
    if (level == 1){
        basicRaid = [[Raid alloc] init];
        basicBoss = [Ghoul defaultBoss];
        
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], nil];
        
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        
    }
    
    if (level == 2){
        basicRaid = [[Raid alloc] init];
        basicBoss = [CorruptedTroll defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil];
        
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
    }
    
    if (level == 3){
        basicRaid = [[Raid alloc] init];
        basicBoss = [Drake defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell],[GreaterHeal defaultSpell], nil];
        
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Guardian  defaultGuardian]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Archer defaultArcher]];
        }
    }
    
    if (level == 4){
        basicRaid = [[Raid alloc] init];
        basicBoss = [MischievousImps defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], nil];
        
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 1; i++){
            [basicRaid addRaidMember:[Archer defaultArcher]];
        }
    }
    
    if (level == 5){
        basicRaid = [[Raid alloc] init];
        basicBoss = [BefouledTreat defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell],[ForkedHeal defaultSpell], nil];
        
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Archer defaultArcher]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
    }
    
    if (level == 6){
        basicRaid = [[Raid alloc] init];
        basicBoss = [PlaguebringerColossus defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [ForkedHeal defaultSpell], [Regrow defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Archer defaultArcher]];
        }
    }
    
    if (level == 7){
        basicRaid = [[Raid alloc] init];
        basicBoss = [SporeRavagers defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [LightEternal defaultSpell], [Regrow defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Archer defaultArcher]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
    }
    
    if (level == 8){
        basicRaid = [[Raid alloc] init];
        basicBoss = [Trulzar defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [Purify defaultSpell], [Regrow defaultSpell], nil];
        
        for (int i = 0; i < 7; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Archer defaultArcher]];
        }
    }
    
    if (level == 9){
        basicRaid = [[Raid alloc] init];
        basicBoss = [DarkCouncil defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [Purify defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 10){
        basicRaid = [[Raid alloc] init];
        basicBoss = [TwinChampions defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal  defaultSpell], [GreaterHeal defaultSpell] , [Barrier defaultSpell], [HealingBurst defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
    }
    
    if (level == 11){
        basicRaid = [[Raid alloc] init];
        basicBoss = [Baraghast defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 12){
        basicRaid = [[Raid alloc] init];
        basicBoss = [CrazedSeer defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 13){
        basicRaid = [[Raid alloc] init];
        basicBoss = [GatekeeperDelsarn defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 14){
        basicRaid = [[Raid alloc] init];
        basicBoss = [SkeletalDragon defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 15){
        basicRaid = [[Raid alloc] init];
        basicBoss = [ColossusOfBone defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 16){
        basicRaid = [[Raid alloc] init];
        basicBoss = [OverseerOfDelsarn defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 17){
        basicRaid = [[Raid alloc] init];
        basicBoss = [TheUnspeakable defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 18){
        basicRaid = [[Raid alloc] init];
        basicBoss = [BaraghastReborn defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 19){
        basicRaid = [[Raid alloc] init];
        basicBoss = [AvatarOfTorment1 defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 20){
        basicRaid = [[Raid alloc] init];
        basicBoss = [AvatarOfTorment2 defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (level == 21){
        basicRaid = [[Raid alloc] init];
        basicBoss = [SoulOfTorment defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal    defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Warlock defaultWarlock]];
        }
        
    }
    
    if (!basicBoss || !basicRaid){
        [basicRaid release];
        return nil;
    }
    
    basicBoss.isMultiplayer = multiplayer;
    Encounter *encToReturn = [[Encounter alloc] initWithRaid:[basicRaid autorelease] andBoss:basicBoss andSpells:spells];
    [encToReturn setLevelNumber:level];
    return [encToReturn autorelease];;
    
}

+(NSInteger)goldForLevelNumber:(NSInteger)levelNumber isFirstWin:(BOOL)isFirstWin isMultiplayer:(BOOL)isMultiplayer{
    NSInteger gold = 0;
    
    if (isFirstWin){
        switch (levelNumber) {
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
                gold = 100;
                break;
            case 6:
            case 7:
            case 8:
            case 9:
            case 10:
                gold = 200;
                break;
            case 11:
            case 12:
            case 13:
            case 14:
            case 15:
                gold = 300;
                break;
            case 16:
            case 17:
            case 18:
            case 19:
                gold = 400;
                break;
            case 20:
            case 21:
                gold = 500;
                break;
        }
    }else{
        switch (levelNumber) {
            case 1:
                gold = 0;
                break;
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
            case 21:
                gold = 125;
                break;
                break;
        }
    }
    if (isMultiplayer && !isFirstWin){
        gold *= 2;
    }
    
    return gold;
}

+ (Encounter*)survivalEncounterIsMultiplayer:(BOOL)multiplayer{
    Raid *basicRaid = nil;
    Boss *basicBoss = nil;
    NSArray *spells = nil;
    basicRaid = [[Raid alloc] init];
    basicBoss = [TheEndlessVoid defaultBoss];
    spells = [NSArray arrayWithObjects:[Heal  defaultSpell], [GreaterHeal defaultSpell] , [Regrow defaultSpell], [LightEternal defaultSpell], nil];
    
    for (int i = 0; i < 5; i++){
        [basicRaid addRaidMember:[Soldier defaultSoldier]];
    }
    for (int i = 0; i < 5; i++){
        [basicRaid addRaidMember:[Champion defaultChampion]];
    }
    for (int i = 0; i < 3; i++){
        [basicRaid addRaidMember:[Wizard defaultWizard]];
    }
    for (int i = 0; i < 4; i++){
        [basicRaid addRaidMember:[Warlock defaultWarlock]];
    }
    for (int i = 0; i < 3; i++){
        [basicRaid addRaidMember:[Guardian defaultGuardian]];
    }
    
    basicBoss.isMultiplayer = multiplayer;
    Encounter *encToReturn = [[Encounter alloc] initWithRaid:[basicRaid autorelease] andBoss:basicBoss andSpells:spells];
    return [encToReturn autorelease];;
}

@end
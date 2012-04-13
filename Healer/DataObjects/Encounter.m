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

@implementation Encounter
@synthesize raid, boss, activeSpells;
-(id)initWithRaid:(Raid*)rd andBoss:(Boss*)bs andSpells:(NSArray*)sps{
    if (self = [super init]){
        self.raid = rd;
        self.boss = bs;
        self.activeSpells  = sps;
    }
    return self;
}


+(Encounter*)encounterForLevel:(NSInteger)level isMultiplayer:(BOOL)multiplayer{
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
    }
    
    if (level == 3){
        basicRaid = [[Raid alloc] init];
        basicBoss = [MischievousImps defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [Barrier defaultSpell], [Purify defaultSpell], nil];
        
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
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
    }
    
    if (level == 4){
        basicRaid = [[Raid alloc] init];
        basicBoss = [Drake defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell],[GreaterHeal defaultSpell], [ForkedHeal defaultSpell], nil];
        
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
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
    }
    
    if (level == 5){
        basicRaid = [[Raid alloc] init];
        basicBoss = [Trulzar defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell],[ForkedHeal defaultSpell], [Purify defaultSpell], nil];
        
        for (int i = 0; i < 4; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
    }
    
    if (level == 6){
        basicRaid = [[Raid alloc] init];
        basicBoss = [DarkCouncil defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [ForkedHeal defaultSpell],[Purify defaultSpell], [Regrow defaultSpell], nil];
        
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
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
    }
    
    if (level == 7){
        basicRaid = [[Raid alloc] init];
        basicBoss = [PlaguebringerColossus defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [LightEternal defaultSpell], [Regrow defaultSpell], nil];
        
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Soldier defaultSoldier]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Champion defaultChampion]];
        }
        for (int i = 0; i < 5; i++){
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
        for (int i = 0; i < 3; i++){
            [basicRaid addRaidMember:[Wizard defaultWizard]];
        }
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Guardian defaultGuardian]];
        }
    }
    
    if (level == 8){
        basicRaid = [[Raid alloc] init];
        basicBoss = [SporeRavagers defaultBoss];
        spells = [NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [LightEternal defaultSpell], [Regrow defaultSpell], nil];
        
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
            [basicRaid addRaidMember:[Demonslayer defaultDemonslayer]];
        }
    }
    
    if (!basicBoss || !basicRaid){
        [basicRaid release];
        return nil;
    }
    
    basicBoss.isMultiplayer = multiplayer;
    return [[[Encounter alloc] initWithRaid:[basicRaid autorelease] andBoss:basicBoss andSpells:spells] autorelease];
    
}
@end
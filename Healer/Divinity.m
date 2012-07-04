//
//  Divinity.m
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "Divinity.h"
#import "Effect.h"


NSString* const IsDivinityUnlockedKey = @"com.healer.isDivinityUnlocked";
NSString* const DivinityConfig = @"com.healer.divinityConfig";

static NSDictionary *divinityInfo = nil;

@implementation Divinity

+ (BOOL)isDivinityUnlocked {
    return [[NSUserDefaults standardUserDefaults] boolForKey:IsDivinityUnlockedKey];
}

+ (NSArray*)divinityChoicesForTier:(NSInteger)tier {
    NSMutableArray *choices = [NSMutableArray arrayWithCapacity:3];
    
    switch (tier) {
        case 0:
            [choices addObject:@"Healing Hands"];
            [choices addObject:@"Blessed Power"];
            [choices addObject:@"Warding Touch"];
            break;
        case 1:
            [choices addObject:@"Surging Glory"];
            [choices addObject:@"Sunlight"];
            [choices addObject:@"After Light"];
            break;
        case 2:
            [choices addObject:@"Shining Aegis"];
            [choices addObject:@"Ancient Knowledge"];
            [choices addObject:@"Purity of Soul"];
            break;
        case 3:
            [choices addObject:@"Searing Power"];
            [choices addObject:@"Repel The Darkness"];
            [choices addObject:@"Torrent of Faith"];
            break;
        case 4:
            [choices addObject:@"Godstouch"];
            [choices addObject:@"The Chosen"];
            [choices addObject:@"Avatar"];
            break;
        default:
            break;
    }
    return choices;
}

+ (NSString*)choiceTitleToKey:(NSString*)title {
    return [[title lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
}

+ (void)loadDivinityInfo {
    NSString *pathToDict = [[NSBundle mainBundle] pathForResource:@"divinity" ofType:@"plist"];
    divinityInfo = [[NSDictionary dictionaryWithContentsOfFile:pathToDict] retain];
}

+ (NSString*)descriptionForChoice:(NSString *)choice {
    if (!divinityInfo){
        [self loadDivinityInfo];
    }
    NSString* desc = [divinityInfo objectForKey:[Divinity choiceTitleToKey:choice]];
    
    if (!desc){
        return @"Unfinished!";
    }
    return desc;
}

+ (void)unlockDivinity {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:IsDivinityUnlockedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)selectChoice:(NSString*)choice forTier:(NSInteger)tier{
    NSDictionary *divinityConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:DivinityConfig];
    
    if (!divinityConfig){
        divinityConfig = [NSDictionary dictionary];
    }
    
    NSMutableDictionary *newConfig = [NSMutableDictionary dictionaryWithDictionary:divinityConfig];
    
    [newConfig setObject:choice forKey:[NSString stringWithFormat:@"tier-%i", tier]];
    
    [[NSUserDefaults standardUserDefaults] setObject:newConfig forKey:DivinityConfig];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray*)effectsForConfiguration:(NSDictionary*)configuration {
    NSMutableArray *effects = [NSMutableArray arrayWithCapacity:5];
    NSString *tier0choice = [configuration objectForKey:[NSString stringWithFormat:@"tier-%i", 0]];
    if (tier0choice){
        if ([tier0choice isEqualToString:@"Healing Hands"]){
            DivinityEffect *divEff = [[DivinityEffect alloc] initWithDivinityKey:tier0choice];
            [effects addObject:[divEff autorelease]];
        }else if ([tier0choice isEqualToString:@"Blessed Power"]){
            DivinityEffect *divEff = [[DivinityEffect alloc] initWithDivinityKey:tier0choice];
            [effects addObject:[divEff autorelease]];
        }else if ([tier0choice isEqualToString:@"Warding Touch"]){
            DivinityEffect *divEff = [[DivinityEffect alloc] initWithDivinityKey:tier0choice];
            [effects addObject:[divEff autorelease]];
        }else {
            NSAssert(nil, @"tier0choice not found");
        }
    }
    return effects;
}

+ (NSString*)selectedChoiceForTier:(NSInteger)tier {
    NSDictionary *config =  [[NSUserDefaults standardUserDefaults] dictionaryForKey:DivinityConfig];
    
    return [config objectForKey:[NSString stringWithFormat:@"tier-%i", tier]];
}

+ (NSDictionary*)localDivinityConfig {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:DivinityConfig];
}

@end

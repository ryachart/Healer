//
//  Divinity.m
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "Divinity.h"
#import "Effect.h"
#import "PlayerDataManager.h"

NSString* const IsDivinityUnlockedKey = @"com.healer.isDivinityUnlocked";
NSString* const DivinityConfig = @"com.healer.divinityConfig";

static NSDictionary *divinityInfo = nil;

@implementation Divinity

+ (BOOL)isDivinityUnlocked {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return [[NSUserDefaults standardUserDefaults] boolForKey:IsDivinityUnlockedKey];
}

+ (NSArray*)divinityChoicesForTier:(NSInteger)tier {
    NSMutableArray *choices = [NSMutableArray arrayWithCapacity:3];
    
    switch (tier) {
        case 0:
            [choices addObject:@"Healing Hands"];
            [choices addObject:@"Blessed Power"];
            [choices addObject:@"Insight"];
            break;
        case 1:
            [choices addObject:@"Surging Glory"];
            [choices addObject:@"Shining Aegis"];
            [choices addObject:@"After Light"];
            break;
        case 2:
            [choices addObject:@"Repel The Darkness"];
            [choices addObject:@"Ancient Knowledge"];
            [choices addObject:@"Purity of Soul"];
            break;
        case 3:
            [choices addObject:@"Searing Power"];
            [choices addObject:@"Sunlight"];
            [choices addObject:@"Torrent of Faith"];
            break;
        case 4:
            [choices addObject:@"Godstouch"];
            [choices addObject:@"Redemption"];
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

+ (NSString*)spriteFrameNameForChoice:(NSString*)choice
{
    return [[[Divinity choiceTitleToKey:choice] stringByAppendingString:@"-icon"] stringByAppendingPathExtension:@"png"];
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
    for (int i = 0; i < 5; i++){
        NSString *tierChoice = [configuration objectForKey:[NSString stringWithFormat:@"tier-%i", i]];
        if (tierChoice){
            DivinityEffect *divEff = [[DivinityEffect alloc] initWithDivinityKey:[Divinity choiceTitleToKey:tierChoice]];
            [effects addObject:[divEff autorelease]];
            if ([tierChoice isEqualToString:@"surging-glory"]) {
                [divEff setEnergyRegenAdjustment:.1];
            }
            if ([tierChoice isEqualToString:@"repel-the-darkness"]) {
                [divEff setHealingDoneMultiplierAdjustment:.05];
                [divEff setCastTimeAdjustment:-.05];
            }
            
            if ([tierChoice isEqualToString:@"blessed-power"]){
                [divEff setCastTimeAdjustment:-0.075];
            }
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

+ (void)resetConfig {
    [[NSUserDefaults standardUserDefaults] setValue:[NSDictionary dictionary] forKey:DivinityConfig];
}

+ (NSInteger)requiredRatingForTier:(NSInteger)tier {
    switch (tier) {
        case 0:
            return 25;
        case 1:
            return 40;
        case 2:
            return 60;
        case 3:
            return 80;
        case 4:
            return 90;
    }
    return NSUIntegerMax; //Loooool
}

+ (NSInteger)numDivinityTiersUnlocked
{
    NSInteger currentRating = [PlayerDataManager totalRating];
    NSInteger totalTiers = 0;
    for (int i = 0; i < 5; i++){
        if (currentRating >= [Divinity requiredRatingForTier:i]) {
            totalTiers++;
        }
    }
    return totalTiers;
}

@end

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


static NSDictionary *divinityInfo = nil;

@implementation Divinity

+ (BOOL)isDivinityUnlocked {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return [[PlayerDataManager localPlayer] totalRating] >= 25;
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

+ (NSArray*)effectsForConfiguration:(NSDictionary*)configuration {
    NSMutableArray *effects = [NSMutableArray arrayWithCapacity:5];
    for (int i = 0; i < 5; i++){
        NSString *tierChoice = [configuration objectForKey:[NSString stringWithFormat:@"tier-%i", i]];
        if (tierChoice){
            NSString *tierChoiceKey = [self choiceTitleToKey:tierChoice];
            DivinityEffect *divEff = [[DivinityEffect alloc] initWithDivinityKey:[Divinity choiceTitleToKey:tierChoice]];
            [effects addObject:[divEff autorelease]];
            
            if ([tierChoiceKey isEqualToString:@"healing-hands"]) {
                [divEff setCriticalChanceAdjustment:0.1];
            }
            
            if ([tierChoiceKey isEqualToString:@"surging-glory"]) {
                [divEff setEnergyRegenAdjustment:.5];
            }
            
            if ([tierChoiceKey isEqualToString:@"blessed-power"]){
                [divEff setCastTimeAdjustment:-0.1];
                [divEff setCooldownMultiplierAdjustment:-0.1];
            }
        }
    }
    return effects;
}

+ (NSInteger)requiredRatingForTier:(NSInteger)tier {
    switch (tier) {
        case 0:
            return 25;
        case 1:
            return 35;
        case 2:
            return 50;
        case 3:
            return 75;
        case 4:
            return 85;
    }
    return NSUIntegerMax; //Loooool
}

+ (NSInteger)numDivinityTiersUnlocked
{
    NSInteger currentRating = [[PlayerDataManager localPlayer] totalRating];
    NSInteger totalTiers = 0;
    for (int i = 0; i < 5; i++){
        if (currentRating >= [Divinity requiredRatingForTier:i]) {
            totalTiers++;
        }
    }
    return totalTiers;
}

@end

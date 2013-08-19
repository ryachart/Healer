//
//  Divinity.m
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "Talents.h"
#import "Effect.h"
#import "PlayerDataManager.h"


static NSDictionary *talentInfo = nil;

@implementation Talents

+ (NSArray*)talentChoicesForTier:(NSInteger)tier {
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
            [choices addObject:@"Arcane Blessing"];
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
    return [[[Talents choiceTitleToKey:choice] stringByAppendingString:@"-icon"] stringByAppendingPathExtension:@"png"];
}

+ (void)loadDivinityInfo {
    NSString *pathToDict = [[NSBundle mainBundle] pathForResource:@"talents" ofType:@"plist"];
    talentInfo = [[NSDictionary dictionaryWithContentsOfFile:pathToDict] retain];
}

+ (NSString*)descriptionForChoice:(NSString *)choice {
    if (!talentInfo){
        [self loadDivinityInfo];
    }
    NSString* desc = [talentInfo objectForKey:[Talents choiceTitleToKey:choice]];
    
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
            TalentEffect *divEff = [[TalentEffect alloc] initWithTalentKey:[Talents choiceTitleToKey:tierChoice]];
            [effects addObject:[divEff autorelease]];
            
            if ([tierChoiceKey isEqualToString:@"healing-hands"]) {
                [divEff setCriticalChanceAdjustment:0.1];
            }
            
            if ([tierChoiceKey isEqualToString:@"surging-glory"]) {
                [divEff setEnergyRegenAdjustment:.1];
            }
            
            if ([tierChoiceKey isEqualToString:@"blessed-power"]){
                [divEff setCastTimeAdjustment:0.1];
                [divEff setCooldownMultiplierAdjustment:-0.1];
            }
            
            if ([tierChoiceKey isEqualToString:@"insight"]) {
                [divEff setSpellCostAdjustment:.1];
            }
            
            if ([tierChoiceKey isEqualToString:@"repel-the-darkness"]) {
                [divEff setCastTimeAdjustment:.05];
            }
            
            if ([tierChoiceKey isEqualToString:@"ancient-knowledge"]) {
                [divEff setCriticalChanceAdjustment:.05];
            }
            
            if ([tierChoiceKey isEqualToString:@"purity-of-soul"]){
                [divEff setHealingDoneMultiplierAdjustment:.1];
                [divEff setDamageTakenMultiplierAdjustment:-.10];
            }
        }
    }
    return effects;
}

+ (NSInteger)requiredRatingForTier:(NSInteger)tier {
    switch (tier) {
        case 0:
            return 15;
        case 1:
            return 30;
        case 2:
            return 45;
        case 3:
            return 60;
        case 4:
            return 80;
    }
    return NSUIntegerMax; //Loooool
}

@end

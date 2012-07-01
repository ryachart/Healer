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
            [choices addObject:@"Grace"];
            break;
        case 1:
            [choices addObject:@"Surging Glory"];
            [choices addObject:@"Sunlight"];
            [choices addObject:@"Radiance"];
            break;
        case 2:
            [choices addObject:@"Aegis"];
            [choices addObject:@"Ancient Knowledge"];
            [choices addObject:@"Strength of Kings"];
            break;
        case 3:
            [choices addObject:@"Light of Freylos"];
            [choices addObject:@"Mystic Alignment"];
            [choices addObject:@"Torrent of Faith"];
            break;
        case 4:
            [choices addObject:@"Godstouch"];
            [choices addObject:@"Purity"];
            [choices addObject:@"Avatar"];
            break;
        default:
            break;
    }
    return choices;
}

+ (NSString*)descriptionForChoice:(NSString *)choice {
    return @"Not yet in! Sorry :(";
}

+ (void)unlockDivinity {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:IsDivinityUnlockedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setDivinityConfig:(NSString *)choice forTier:(NSString *)tier {
    NSDictionary *divinityConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:DivinityConfig];
    
    if (!divinityConfig){
        divinityConfig = [NSDictionary dictionary];
    }
    
    NSMutableDictionary *newConfig = [NSMutableDictionary dictionaryWithDictionary:divinityConfig];
    
    [newConfig setObject:choice forKey:tier];
    
    [[NSUserDefaults standardUserDefaults] setObject:newConfig forKey:DivinityConfig];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray*)effectsForCurrentConfiguration {
    return nil;
}

@end

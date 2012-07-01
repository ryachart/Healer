//
//  Divinity.h
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const DivinityTier1Key;
extern NSString* const DivinityTier2Key;
extern NSString* const DivinityTier3Key;
extern NSString* const DivinityTier4Key;
extern NSString* const DivinityTier5Key;


@interface Divinity : NSObject

+ (NSArray*)divinityChoicesForTier:(NSInteger)tier;
+ (NSString*)descriptionForChoice:(NSString*)choice;

+ (BOOL)isDivinityUnlocked;
+ (void)unlockDivinity;

+ (void)setDivinityConfig:(NSString*)choice forTier:(NSString*)tier;
+ (NSArray*)effectsForCurrentConfiguration;

@end

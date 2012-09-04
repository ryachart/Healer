//
//  Divinity.h
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>


#define NUM_DIV_TIERS 5

@interface Divinity : NSObject

+ (NSArray*)divinityChoicesForTier:(NSInteger)tier;
+ (NSString*)descriptionForChoice:(NSString*)choice;
+ (NSString*)spriteFrameNameForChoice:(NSString*)choice;

+ (BOOL)isDivinityUnlocked;
+ (void)unlockDivinity;

+ (void)selectChoice:(NSString*)choice forTier:(NSInteger)tier;
+ (NSString*)selectedChoiceForTier:(NSInteger)tier;

+ (NSArray*)effectsForConfiguration:(NSDictionary*)configuration;

+ (void)resetConfig;
+ (NSDictionary*)localDivinityConfig;

@end

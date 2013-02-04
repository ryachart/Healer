//
//  Divinity.h
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>


#define NUM_DIV_TIERS 5

@interface Talents : NSObject

+ (NSArray*)divinityChoicesForTier:(NSInteger)tier;
+ (NSString*)descriptionForChoice:(NSString*)choice;
+ (NSString*)spriteFrameNameForChoice:(NSString*)choice;

+ (BOOL)isDivinityUnlocked;
+ (NSInteger)numDivinityTiersUnlocked;

+ (NSArray*)effectsForConfiguration:(NSDictionary*)configuration;

+ (NSInteger)requiredRatingForTier:(NSInteger)tier;

@end

//
//  Divinity.h
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import <Foundation/Foundation.h>


#define NUM_DIV_TIERS 5

@interface Talents : NSObject

+ (NSArray*)talentChoicesForTier:(NSInteger)tier;
+ (NSString*)descriptionForChoice:(NSString*)choice;
+ (NSString*)spriteFrameNameForChoice:(NSString*)choice;

+ (NSArray*)effectsForConfiguration:(NSDictionary*)configuration;

+ (NSInteger)requiredRatingForTier:(NSInteger)tier;

@end

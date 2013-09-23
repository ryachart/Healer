//
//  NSString+Obfuscation.m
//  Healer
//
//  Created by Ryan Hart on 6/12/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "NSString+Obfuscation.h"

#define OBFUSCATION_DELTA 1

@implementation NSString (Obfuscation)

- (NSString *)obfuscatedString
{
    NSMutableString *obfuscatedString = [NSMutableString stringWithCapacity:self.length];
    for (int i = 0; i < self.length; i++) {
        unichar character = [self characterAtIndex:i];
        character += OBFUSCATION_DELTA;
        [obfuscatedString appendFormat:@"%C", character];
    }
    return [NSString stringWithString:obfuscatedString];
}

- (NSString *)deobfuscatedString
{
    NSMutableString *obfuscatedString = [NSMutableString stringWithCapacity:self.length];
    for (int i = 0; i < self.length; i++) {
        unichar character = [self characterAtIndex:i];
        character -= OBFUSCATION_DELTA;
        [obfuscatedString appendFormat:@"%C", character];
    }
    return [NSString stringWithString:obfuscatedString];
}

@end

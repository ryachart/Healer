//
//  NSString+Obfuscation.h
//  Healer
//
//  Created by Ryan Hart on 6/12/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Obfuscation)
- (NSString *)obfuscatedString;
- (NSString *)deobfuscatedString;
@end

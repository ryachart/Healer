//
//  AbilityDescriptor.m
//  Healer
//
//  Created by Ryan Hart on 8/1/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "AbilityDescriptor.h"

@implementation AbilityDescriptor

- (NSString*)iconName{
    if (!_iconName){
        return @"unknown_ability.png";
    }
    return _iconName;
}

@end

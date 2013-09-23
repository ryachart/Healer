//
//  AbilityDescriptor.m
//  Healer
//
//  Created by Ryan Hart on 8/1/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "AbilityDescriptor.h"
#import "Effect.h"

@implementation AbilityDescriptor

- (NSString*)iconName{
    if (!_iconName){
        return @"unknown_ability.png";
    }
    return _iconName;
}

- (NSInteger)stacks
{
    if (self.monitoredEffect) {
        return self.monitoredEffect.stacks;
    }
    return 0;
}

@end

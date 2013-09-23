//
//  Agent.m
//  Healer
//
//  Created by Ryan Hart on 4/18/12.
//  Copyright 2010 Ryan Hart Games. All rights reserved.

#import "Agent.h"

@implementation Agent

- (void)initializeForCombat {
    
}

-(float)healingDoneMultiplier{
    return 1.0;
}

-(float)damageDoneMultiplier{
    return 1.0;
}

-(NSString*)networkID{
    return [NSString stringWithFormat:@"Agent:%@", self];
}
-(NSString*)sourceName{
    return @"";
}

-(NSString *)targetName{
    return @"";
}

@end

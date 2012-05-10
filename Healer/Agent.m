//
//  Agent.m
//  Healer
//
//  Created by Ryan Hart on 4/18/12.
//

#import "Agent.h"

@implementation Agent
@synthesize logger;

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

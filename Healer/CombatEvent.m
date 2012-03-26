//
//  CombatEvent.m
//  Healer
//
//  Created by Ryan Hart on 3/25/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "CombatEvent.h"

@implementation CombatEvent
@synthesize type = _type, value, source, target;
-(id)initWithSource:(id<EventDataSource>)src target:(id<EventDataSource>)trgt value:(NSNumber*)val andEventType:(CombatEventType)typ{
    self = [super init];
    if (self){
        self.source = src;
        self.target = trgt;
        self.value = val;
        self.type = typ;
    }
    return self;
}

+(CombatEvent*)eventWithSource:(id<EventDataSource>)source target:(id<EventDataSource>)target value:(NSNumber*)value andEventType:(CombatEventType)type{
    return [[[CombatEvent alloc] initWithSource:source target:target value:value andEventType:type] autorelease];
}
-(NSString*)logLine{
    return [NSString stringWithFormat:@"%@"];
}
-(void)dealloc{
    [super dealloc];
}
@end

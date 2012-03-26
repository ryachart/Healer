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
-(id)initWithSource:(id<EventDataSource>)source target:(id<EventDataSource>)target value:(NSNumber*)value andEventType:(CombatEventType)type{
    self = [super init];
    if (self){
        self.source = source;
        self.target = target;
        self.value = value;
        self.type = type;
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

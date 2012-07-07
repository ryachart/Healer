//
//  CombatEvent.m
//  Healer
//
//  Created by Ryan Hart on 3/25/12.
//

#import "CombatEvent.h"

@implementation CombatEvent
@synthesize type = _type, value, source, target, timeStamp;
-(id)initWithSource:(id<EventDataSource>)src target:(id<EventDataSource>)trgt value:(NSNumber*)val andEventType:(CombatEventType)typ{
    self = [super init];
    if (self){
        self.source = src;
        self.target = trgt;
        self.value = val;
        self.type = typ;
        self.timeStamp = [NSDate date];
    }
    return self;
}

+(CombatEvent*)eventWithSource:(id<EventDataSource>)source target:(id<EventDataSource>)target value:(NSNumber*)value andEventType:(CombatEventType)type{
    return [[[CombatEvent alloc] initWithSource:source target:target value:value andEventType:type] autorelease];
}

-(NSString*)nameForType:(CombatEventType)type{
    switch (type) {
        case CombatEventTypeBegan:
            return @"Combat Began";
        case CombatEventTypeHeal:
            return @"Heal";
        case CombatEventTypeDamage:
            return @"Damage";
        case CombatEventTypeMemberDied:
            return @"MemberDied";
        case CombatEventTypeDodge:
            return @"Dodged";
        case CombatEventEnded:
            return @"Combat Ended";
        case CombatEventTypeOverheal:
            return @"Overheal";
        default:
            break;
    }
    return nil;
}

-(NSString*)description{
    return [self logLine];
}

-(NSString*)logLine{
    return [NSString stringWithFormat:@"[%@][SRC:%@][TAR:%@][VAL:%@][TYPE:%@]",[self.timeStamp description] ,[self.source sourceName], [self.target targetName], [self.value description], [self nameForType:self.type]];
}
-(void)dealloc{
    [source release];
    [target release];
    [value release];
    [timeStamp release];
    [super dealloc];
}
@end

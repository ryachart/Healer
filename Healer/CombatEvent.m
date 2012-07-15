//
//  CombatEvent.m
//  Healer
//
//  Created by Ryan Hart on 3/25/12.
//

#import "CombatEvent.h"
#import "Player.h"

NSString* const PlayerHealingDoneKey = @"com.healer.eventlog.healingdone";
NSString* const PlayerOverHealingDoneKey = @"com.healer.eventlog.overhealingdone";

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
        case CombatEventTypePlayerInterrupted:
            return @"Interrupted";
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

+ (NSDictionary*)statsForPlayer:(NSString*)playerId fromLog:(NSArray*)log {
    NSInteger playerHealingDone = 0;
    NSInteger playerOverheal = 0;
    for (CombatEvent *event in log){
        if (event.type == CombatEventTypeHeal) {
            if ([[(Player*)event.source playerID] isEqualToString:playerId] || !playerId){
                playerHealingDone += [[event value] intValue];
            }
        }
        if (event.type == CombatEventTypeOverheal) {
            if ([[(Player*)event.source playerID] isEqualToString:playerId] || !playerId){
                playerOverheal += [[event value] intValue];
            }
        }
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:playerHealingDone], PlayerHealingDoneKey, 
        [NSNumber numberWithInt:playerOverheal], PlayerOverHealingDoneKey, nil];
}
@end

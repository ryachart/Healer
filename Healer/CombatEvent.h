//
//  CombatEvent.h
//  Healer
//
//  Created by Ryan Hart on 3/25/12.
//

#import <Foundation/Foundation.h>


typedef enum {
    CombatEventTypeBegan,
    CombatEventTypeDodge,
    CombatEventTypeHeal,
    CombatEventTypeOverheal,
    CombatEventTypeDamage,
    CombatEventTypeMemberDied,
    CombatEventTypePlayerInterrupted,
    CombatEventEnded
} CombatEventType;

@protocol EventDataSource <NSObject>

-(NSString*)sourceName;
-(NSString*)targetName;

@end


extern NSString* const PlayerHealingDoneKey;
extern NSString* const PlayerOverHealingDoneKey;

@interface CombatEvent : NSObject
@property (nonatomic, retain) NSDate *timeStamp;
@property (nonatomic, retain) id <EventDataSource> source;
@property (nonatomic, retain) id <EventDataSource> target;
@property (nonatomic, retain) NSNumber *value;
@property (readwrite) CombatEventType type;
@property (readwrite) BOOL critical;
+(CombatEvent*)eventWithSource:(id<EventDataSource>)source target:(id<EventDataSource>)target value:(NSNumber*)value andEventType:(CombatEventType)type;
+(CombatEvent*)eventWithSource:(id<EventDataSource>)source target:(id<EventDataSource>)target value:(NSNumber*)value eventType:(CombatEventType)type critical:(BOOL)critical;

-(NSString*)logLine;

+ (NSDictionary*)statsForPlayer:(NSString*)playerId fromLog:(NSArray*)log;
@end


@protocol EventLogger <NSObject>

-(void)logEvent:(CombatEvent*)event;

@end
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
    CombatEventEnded
} CombatEventType;

@protocol EventDataSource <NSObject>

-(NSString*)sourceName;
-(NSString*)targetName;

@end


@interface CombatEvent : NSObject
@property (nonatomic, retain) NSDate *timeStamp;
@property (nonatomic, retain) id <EventDataSource> source;
@property (nonatomic, retain) id <EventDataSource> target;
@property (nonatomic, retain) NSNumber *value;
@property (readwrite) CombatEventType type;
+(CombatEvent*)eventWithSource:(id<EventDataSource>)source target:(id<EventDataSource>)target value:(NSNumber*)value andEventType:(CombatEventType)type;

-(NSString*)logLine;

@end


@protocol EventLogger <NSObject>

-(void)logEvent:(CombatEvent*)event;

@end
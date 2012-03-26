//
//  CombatEvent.h
//  Healer
//
//  Created by Ryan Hart on 3/25/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    CombatEventTypeDodge,
    CombatEventTypeHeal,
    CombatEventTypeDamage
} CombatEventType;

@protocol EventDataSource <NSObject>

-(NSString*)sourceName;
-(NSString*)targetName;

@end


@interface CombatEvent : NSObject
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
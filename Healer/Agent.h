//
//  Agent.h
//  Healer
//
//  Created by Ryan Hart on 4/18/12.
//  Copyright 2010 Ryan Hart Games. All rights reserved.

#import <Foundation/Foundation.h>
#import "CombatEvent.h"
#import "Announcer.h"

@class Ability;

@interface Agent : NSObject <EventDataSource>
@property (nonatomic, readonly) NSString* networkID;
@property (nonatomic, assign) id<EventLogger> logger;
@property (nonatomic, assign) id<Announcer>announcer;
@property (nonatomic, readonly) float healingDoneMultiplier; //Default 1.0. For all healing done
@property (nonatomic, readonly) float damageDoneMultiplier; //Default 1.0 For all damage done
- (void)initializeForCombat;
@end

//
//  Agent.h
//  Healer
//
//  Created by Ryan Hart on 4/18/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CombatEvent.h"

@interface Agent : NSObject <EventDataSource>
@property (nonatomic, assign) id<EventLogger> logger;
@end

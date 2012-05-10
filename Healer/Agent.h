//
//  Agent.h
//  Healer
//
//  Created by Ryan Hart on 4/18/12.
//

#import <Foundation/Foundation.h>
#import "CombatEvent.h"

@interface Agent : NSObject <EventDataSource>
@property (nonatomic, readonly) NSString* networkID;
@property (nonatomic, assign) id<EventLogger> logger;
@end

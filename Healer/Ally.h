//
//  Ally.h
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright 2011 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Agent.h"
#import "cocos2d.h"

@interface Ally : Agent {
    
    CCSprite *healthBar;
    BOOL showHealthBar;
    
    NSMutableDictionary *defaults;
}

-(void) updateHealthBar;

@property(nonatomic, retain) CCSprite *healthBar;
@property(nonatomic, retain) NSMutableDictionary *defaults;

@end

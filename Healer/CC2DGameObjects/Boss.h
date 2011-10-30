//
//  Boss.h
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright 2011 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Agent.h"
#import "cocos2d.h"

@interface Boss : Agent {
    
    CCSprite *healthBar;
    BOOL showHealthBar;
    
    NSMutableDictionary *defaults;
}

@property(nonatomic, retain) CCSprite *healthBar;
@property(nonatomic, retain) NSMutableDictionary *defaults;

@end

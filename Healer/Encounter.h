//
//  Encounter.h
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright 2011 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Player.h"
#import "Ally.h"
#import "Boss.h"

@interface Encounter : NSObject {
    
    NSMutableDictionary *plistDefaults;
    NSMutableArray *allies;
    NSMutableArray *bosses;
    
    Player *player;
    
    
}

-(void) addAlly:(Ally*) ally;
-(void) addBoss:(Boss*) boss;

@property(nonatomic, retain) NSMutableDictionary *plistDefaults;
@property(nonatomic, retain) NSMutableArray *allies;
@property(nonatomic, retain) NSMutableArray *bosses;
@property(nonatomic, retain) Player *player;

@end

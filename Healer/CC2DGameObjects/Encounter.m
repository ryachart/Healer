//
//  Encounter.m
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright 2011 Apple. All rights reserved.
//

#import "Encounter.h"
#import "AssetManager.h"


@implementation Encounter

@synthesize plistDefaults;
@synthesize allies;
@synthesize bosses;
@synthesize player;

-(id) init
{
    self = [super init];
    if (self)
    {
        self.plistDefaults = [[AssetManager sharedInstance] getDefaults];
        
        self.allies = [NSMutableArray array];
        self.bosses = [NSMutableArray array];
        self.player = nil; // gasp
    }
    
    return self;
}

-(void) addAlly:(Ally*) ally
{
    [allies addObject:ally];
}

-(void) addBoss:(Boss*) boss
{
    [bosses addObject:boss];
}

@end

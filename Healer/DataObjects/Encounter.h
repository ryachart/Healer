//
//  Encounter.h
//  RaidLeader
//
//  Created by Ryan Hart on 5/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Raid;
@class Boss;
@interface Encounter : NSObject {
}
@property (nonatomic, retain) Raid *raid;
@property (nonatomic, retain) Boss *boss;
@property (nonatomic, retain) NSArray *activeSpells; //An Array of Spell Classnames
@property (nonatomic, readonly) NSInteger levelNumber;

-(id)initWithRaid:(Raid*)raid andBoss:(Boss*)boss andSpells:(NSArray*)spells; 


+(Encounter*)encounterForLevel:(NSInteger)level isMultiplayer:(BOOL)multiplayer;
@end

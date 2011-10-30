//
//  Character.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Spell.h"

@class Encounter;
@interface Character : NSObject {
	NSString *name;
	NSArray *knownSpells;
	NSArray *encountersCompleted;
	NSString *characterClass;
}
@property (retain) NSString* name;
@property (retain) NSArray* knownSpells;
@property (retain) NSArray *encountersCompleted;
@property (retain) NSString* characterClass;

-(void)addNewSpell:(Spell*)spell;
-(void)addNewEncounterCompleted:(Encounter*)encounter;
@end

//
//  Character.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Character.h"
#import "Encounter.h"

@implementation Character
@synthesize name, characterClass, encountersCompleted, knownSpells;

-(void)addNewSpell:(Spell*)spell{
	for (NSString* titles in knownSpells){
		if ([titles isEqualToString:[spell title]]){
			return;
		}
	}
	
	NSMutableArray *newArray = [[NSMutableArray arrayWithArray:knownSpells] retain];
	[newArray addObject:[spell title]];
	knownSpells = newArray;
}

-(void)addNewEncounterCompleted:(Encounter*)encounter{
	for (NSString* titles in encountersCompleted){
		if ([titles isEqualToString:[encounter title]]){
			return;
		}
	}
	
	NSMutableArray *newArray = [[NSMutableArray arrayWithArray:encountersCompleted] retain];
	[newArray addObject:[encounter title]];
	encountersCompleted = newArray;
}
@end

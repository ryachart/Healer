//
//  PersistantDataManager.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Character.h"
#define MAX_CHARACTERS 5
#define SAVE_FILE_NAME @"SavedCharacterData"

extern NSString* const PlayerHighestLevelAttempted;
extern NSString* const PlayerHighestLevelCompleted;

@interface PersistantDataManager : NSObject {
	Character* selectedCharacter;
	NSMutableArray *characters;
}
@property (retain) Character* selectedCharacter;
@property (retain) NSMutableArray *characters;
+(id)sharedInstance;

-(void)saveData;
-(void)loadData;
-(void)addNewCharacterWithName:(NSString*)name andClass:(NSString*)theClass;
-(void)deleteCharacterWithName:(NSString*)name;
-(Character*)characterByName:(NSString*)name;
-(BOOL)canAddCharacterWithName:(NSString*)name;

- (BOOL)writeApplicationData:(NSData *)data toFile:(NSString *)fileName;
- (BOOL)writeApplicationPlist:(id)plist toFile:(NSString *)fileName;
- (NSData *)applicationPlistFromFile:(NSString *)fileName;
- (NSData *)applicationDataFromFile:(NSString *)fileName;
@end

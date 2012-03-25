//
//  PersistantDataManager.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PersistantDataManager.h"
#import "DataDefinitions.h"

NSString* const PlayerHighestLevelAttempted = @"com.healer.playerHighestLevelAttempted";
NSString* const PlayerHighestLevelCompleted = @"com.healer.playerHighestLevelCompleted";


@implementation PersistantDataManager

@synthesize selectedCharacter, characters;

static PersistantDataManager* sharedManager = nil;

+(id)sharedInstance
{
	@synchronized([PersistantDataManager class]){
		if (sharedManager == nil){
			sharedManager = [[self alloc] init];
			
		}
	}
	return sharedManager;
}

+(id)alloc
{
	@synchronized([PersistantDataManager class])
	{
		NSAssert(sharedManager == nil, @"Attempted to allocate a second instance of a singleton.");
		sharedManager = [super alloc];
		return sharedManager;
	}
	
	return nil;
}

-(id)init{
	if (self = [super init]){
		//Load all the data from the file
		characters = [NSMutableArray arrayWithCapacity:MAX_CHARACTERS];
		[characters retain];
		selectedCharacter = nil;
		
		[self loadData];
	}
	
	return self;
}

-(void)loadData
{
	for (int i = 0; i < MAX_CHARACTERS; i++){
		id dataFromFile;
		NSString *appFile = SAVE_FILE_NAME;
		appFile = [appFile stringByAppendingFormat:[NSString stringWithFormat:@"%i.dat",i], nil];
		if ((dataFromFile = [self applicationPlistFromFile:appFile])){
			NSLog(@"Found a file");
			NSDictionary *dictFromFile = (NSDictionary*)dataFromFile;
			NSString* name = [dictFromFile objectForKey:@"Name"];
			NSString* charClass = [dictFromFile objectForKey:@"Class"];
			NSArray* knownSpells = [dictFromFile objectForKey:@"KnownSpells"];
			NSArray* encountersComp = [dictFromFile objectForKey:@"EncountersCompleted"];
			
			Character *charToAdd = [[Character alloc] init];
			[charToAdd setName:name];
			[charToAdd setCharacterClass:charClass];
			[charToAdd setKnownSpells:knownSpells];
			[charToAdd setEncountersCompleted:encountersComp];
			[[self characters] addObject:charToAdd];
			[charToAdd release];
		}
		else {
			NSLog(@"Im all out of files...finishing!");
			i = MAX_CHARACTERS;
		}

	}
}
-(void)saveData
{
	//Write all data to a file
	
	int i = 0;
	for (Character *charc in characters){
		NSArray *keys = [NSArray arrayWithObjects:@"Name", @"Class", @"KnownSpells", @"EncountersCompleted", nil];
		NSArray *values = [NSArray arrayWithObjects:[charc name], [charc characterClass], [charc knownSpells], [charc encountersCompleted], nil];
		NSDictionary *savableDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
		NSString *appFile = SAVE_FILE_NAME;
		appFile = [appFile stringByAppendingFormat:@"%i.dat", i];
		[self writeApplicationPlist:savableDict toFile:appFile];
		i++;
	}
}

/* Utility functions for file I/O */
/**********************************/

- (BOOL)writeApplicationData:(NSData *)data toFile:(NSString *)fileName {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	if (!documentsDirectory) {
		NSLog(@"Documents directory not found!");
		return NO;
	}
	NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
	return ([data writeToFile:appFile atomically:YES]);
}

- (BOOL)writeApplicationPlist:(id)plist toFile:(NSString *)fileName {
    NSString *error;
    NSData *pData = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
    if (!pData) {
        NSLog(@"%@", error);
        return NO;
    }
    return ([self writeApplicationData:pData toFile:(NSString *)fileName]);
}

- (NSData *)applicationDataFromFile:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSData *myData = [[[NSData alloc] initWithContentsOfFile:appFile] autorelease];
    return myData;
}

- (id)applicationPlistFromFile:(NSString *)fileName {
    NSData *retData;
    NSString *error;
    id retPlist;
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	
    retData = [self applicationDataFromFile:fileName];
    if (!retData) {
        NSLog(@"Data file not returned.");
        return nil;
    }
    retPlist = [NSPropertyListSerialization propertyListFromData:retData  mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
    if (!retPlist){
        NSLog(@"Plist not returned, error: %@", error);
    }
    return retPlist;
}

/* End Utility Functions for File I/O */
/**************************************/

-(Character*)characterByName:(NSString*)name
{
	for (Character* charc in characters){
		if ([[charc name] isEqualToString:name]){
			return charc;
		}
	}
	return nil;
}

-(void)addNewCharacterWithName:(NSString*)name andClass:(NSString *)theClass
{
	if ([self canAddCharacterWithName:name]){
		Character* addMe = [[Character alloc] init];
		[addMe setName:name];
		[addMe setCharacterClass:theClass];
		
		if (theClass == CharacterClassRitualist){
			[addMe setKnownSpells:[NSArray arrayWithObjects:@"Healing Breath", nil]];
		}
		if (theClass == CharacterClassShaman){
			[addMe setKnownSpells:[NSArray arrayWithObjects:@"Roar of Life", nil]];
		}
		if (theClass == CharacterClassSeer){
			[addMe setKnownSpells:[NSArray arrayWithObjects:@"Shining Aegis", nil]];
		}
		[addMe setEncountersCompleted:[NSArray arrayWithObjects:@"VoidEnc", nil]];
		[characters addObject:addMe];
		[self saveData];
		[addMe release];
	}
	else{
		NSLog(@"Can't add character");
	}

	
}

-(void)deleteAllFiles{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	for (int i = 0; i < MAX_CHARACTERS; i++){
		NSString *appFile = SAVE_FILE_NAME;
		appFile = [appFile stringByAppendingFormat:@"%i.dat", i];
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		if (!documentsDirectory) {
			NSLog(@"Documents directory not found!");
		}
		NSString *finalPath = [documentsDirectory stringByAppendingPathComponent:appFile];
		
		[fm removeItemAtPath:finalPath error:nil];
	}
}

-(void)deleteCharacterWithName:(NSString*)name
{
	int objectIndexToDelete = 0;
	
	for (objectIndexToDelete = 0; objectIndexToDelete < [characters count]; objectIndexToDelete++){
		if ([[[characters objectAtIndex:objectIndexToDelete] name] isEqualToString:name]){
			break;
		}
	}
	
	[self deleteAllFiles];
	[characters removeObjectAtIndex:objectIndexToDelete];
	[self saveData];
	
}



-(BOOL)canAddCharacterWithName:(NSString*)name
{
	BOOL retVal = ([characters count] < MAX_CHARACTERS);
	
	if ([name isEqualToString:CharacterClassRitualist]) return NO;
	if ([name isEqualToString:CharacterClassSeer]) return NO;
	if ([name isEqualToString:CharacterClassShaman]) return NO;
	
	for (Character* charc in characters)
	{
		retVal = retVal && ![[charc name] isEqualToString:name];
	}
	return retVal;
}
@end

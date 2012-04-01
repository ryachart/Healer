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
		
	}
	
	return self;
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

@end

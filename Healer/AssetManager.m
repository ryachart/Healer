//
//  AssetManager.m
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright 2011 Apple. All rights reserved.
//

#import "AssetManager.h"


@implementation AssetManager

@synthesize plistDefaults;

static AssetManager* sharedAssetManager = nil;

+(id)sharedInstance
{
	@synchronized([AssetManager class]){
		if (sharedAssetManager == nil){
            sharedAssetManager = [[self alloc] init];
		}
	}
	return sharedAssetManager;
}

+(id)alloc
{
	@synchronized([AssetManager class])
	{
		NSAssert(sharedAssetManager == nil, @"Attempted to allocate a second instance of a singleton.");
		sharedAssetManager = [super alloc];
		return sharedAssetManager;
	}
	
	return nil;
}

-(id) init
{
    self = [super init];
    if (self)
    {
        // Load defaults plist into dictionary
        NSString *pathToDefaultsPlist = [[NSBundle mainBundle] pathForResource:@"GameDefaults" ofType:@"plist"];
        plistDefaults = [[NSMutableDictionary alloc] initWithContentsOfFile:pathToDefaultsPlist];
    }
    
    return self;
}

-(NSMutableDictionary *) getDefaults
{
    return plistDefaults;
}
     
@end

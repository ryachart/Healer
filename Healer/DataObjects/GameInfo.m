//
//  GameInfo.m
//  RaidLeader
//
//  Created by Ryan Hart on 11/7/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import "GameInfo.h"


@implementation GameInfo

@synthesize itemDictionary;

static GameInfo* sharedController = nil;

+(id)sharedInstance
{
	@synchronized([GameInfo class]){
		if (sharedController == nil){
			sharedController = [[self alloc] init];
		}
	}
	return sharedController;
}

+(id)alloc
{
	@synchronized([GameInfo class])
	{
		NSAssert(sharedController == nil, @"Attempted to allocate a second instance of a singleton.");
		sharedController = [super alloc];
		return sharedController;
	}
	
	return nil;
}

-(id)init{
	self = [super init];
	if (self){
		itemDictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Items" ofType:@"plist"]];
	}
	return self;
}



@end

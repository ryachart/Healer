//
//  SpellAudioData.m
//  RaidLeader
//
//  Created by Ryan Hart on 5/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SpellAudioData.h"
#import "AudioController.h"

@implementation SpellAudioData

@synthesize beginTitle, interruptedTitle, finishedTitle;
-(id)init{
	if (self = [super init]){
		beginSound = nil;
		beginTitle = nil;
		interruptedSound = nil;
		interruptedTitle = nil;
		finishedSound = nil;
		finishedTitle = nil;
	}
	return self;
}
-(void)setBeginSound:(NSURL*)soundPath andTitle:(NSString*)title
{
	beginSound = [soundPath retain];
	self.beginTitle = title;
	
}
-(void)setInterruptedSound:(NSURL*)soundPath andTitle:(NSString*)title
{
	interruptedSound = [soundPath retain];
	self.interruptedTitle = title;
	
}
-(void)setFinishedSound:(NSURL*)soundPath andTitle:(NSString*)title
{
	finishedSound = [soundPath retain];
	self.finishedTitle = title;
}

-(void)cacheSpellAudio{
	AudioController* ac = [AudioController sharedInstance];
	
	if (beginTitle != nil && beginSound != nil){
		[ac addNewPlayerWithTitle:beginTitle andURL:beginSound];
	}
	if (interruptedTitle != nil && interruptedSound != nil){
		[ac addNewPlayerWithTitle:interruptedTitle andURL:interruptedSound];
	}
	if (finishedTitle != nil && finishedSound != nil){
		[ac addNewPlayerWithTitle:finishedTitle andURL:finishedSound];
	}
}

-(void)releaseSpellAudio
{
	AudioController *ac = [AudioController sharedInstance];
	
	if (beginTitle != nil){
		[ac removeAudioPlayerWithTitle:beginTitle];
	}
	if (interruptedTitle != nil){
		[ac removeAudioPlayerWithTitle:interruptedTitle];
	}
	if (finishedTitle != nil){
		[ac removeAudioPlayerWithTitle:finishedTitle];
	}
}

-(void)dealloc{
	[super dealloc];
	[beginSound release];
	[interruptedSound release];
	[finishedSound release];
}
@end

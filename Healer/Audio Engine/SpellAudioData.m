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
-(id)init{
	if (self = [super init]){
		_beginSound = nil;
		_beginTitle = nil;
		_interruptedSound = nil;
		_interruptedTitle = nil;
		_finishedSound = nil;
		_finishedTitle = nil;
	}
	return self;
}
-(void)setBeginSound:(NSURL*)soundPath andTitle:(NSString*)title
{
    [_beginSound release];
	_beginSound = [soundPath retain];
	self.beginTitle = title;
	
}
-(void)setInterruptedSound:(NSURL*)soundPath andTitle:(NSString*)title
{
    [_interruptedSound release];
	_interruptedSound = [soundPath retain];
	self.interruptedTitle = title;
	
}
-(void)setFinishedSound:(NSURL*)soundPath andTitle:(NSString*)title
{
    NSAssert(soundPath, @"Attempt to initialize a song with a nil path and title %@", title);
    [_finishedSound release];
	_finishedSound = [soundPath retain];
	self.finishedTitle = title;
}

-(void)cacheSpellAudio{
	AudioController* ac = [AudioController sharedInstance];
	
	if (_beginTitle != nil && _beginSound != nil){
		[ac addNewPlayerWithTitle:_beginTitle andURL:_beginSound];
	}
	if (_interruptedTitle != nil && _interruptedSound != nil){
		[ac addNewPlayerWithTitle:_interruptedTitle andURL:_interruptedSound];
	}
	if (_finishedTitle != nil && _finishedSound != nil){
		[ac addNewPlayerWithTitle:_finishedTitle andURL:_finishedSound];
	}
}

-(void)releaseSpellAudio
{
	AudioController *ac = [AudioController sharedInstance];
	
	if (_beginTitle != nil){
		[ac removeAudioPlayerWithTitle:_beginTitle];
	}
	if (_interruptedTitle != nil){
		[ac removeAudioPlayerWithTitle:_interruptedTitle];
	}
	if (_finishedTitle != nil){
		[ac removeAudioPlayerWithTitle:_finishedTitle];
	}
}

-(void)dealloc{
	[_beginSound release];
	[_interruptedSound release];
	[_finishedSound release];
    [_beginTitle release];
    [_interruptedTitle release];
    [_finishedTitle release];
    [super dealloc];
}
@end

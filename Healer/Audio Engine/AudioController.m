//
//  AudioController.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AudioController.h"


@implementation AudioController

@synthesize audioPlayers;
@synthesize titles;

static AudioController* sharedController = nil;

+(id)sharedInstance
{
	@synchronized([AudioController class]){
		if (sharedController == nil){
			 sharedController = [[self alloc] init];
		}
	}
	return sharedController;
}

+(id)alloc
{
	@synchronized([AudioController class])
	{
		NSAssert(sharedController == nil, @"Attempted to allocate a second instance of a singleton.");
		sharedController = [super alloc];
		return sharedController;
	}
	
	return nil;
}


-(id)init{
	if ((self = [super init])){
	
		[self setAudioPlayers:[NSMutableDictionary dictionaryWithCapacity:30]];
		dupPlayers = 0;
		[[AVAudioSession sharedInstance] setActive:YES error:nil];
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
	}
	return self;
	
}

-(void)addNewPlayerWithTitle:(NSString*)title andURL:(NSURL*)url
{
	NSError *err = nil;
	//NSData *data = [NSData dataWithContentsOfFile:[url path]];
	AVAudioPlayer *newAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
	
	if (err){
		NSLog(@"Error: %@", [err description]);
	}
	//[newAudioPlayer setDelegate:self]
	
    [newAudioPlayer prepareToPlay];
	if (newAudioPlayer){
		[audioPlayers setObject:newAudioPlayer forKey:title];
		//[newAudioPlayer prepareToPlay];
		[newAudioPlayer setDelegate:self];
		[newAudioPlayer release];
	}
}

-(void)addNewPlayerWithTitle:(NSString*)title andData:(NSData*)data atVolume:(float)volume
{
	NSError *err = nil;
	AVAudioPlayer *newAudioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&err];
	if (err){
		NSLog(@"Error: %@", [err description]);
	}
	
	if (newAudioPlayer){
		[audioPlayers setObject:newAudioPlayer forKey:title];
		newAudioPlayer.volume = volume;
		[newAudioPlayer prepareToPlay];
		[newAudioPlayer setDelegate:self];
		[newAudioPlayer release];
	}
}

-(void)addNewPlayerWithTitle:(NSString*)title andData:(NSData*)data
{
	[self addNewPlayerWithTitle:title andData:data atVolume:1.0];
}

-(void)playTitle: (NSString*)title
		 looping: (NSInteger)numberOfLoops
{
	if ([audioPlayers count] > 0){
		AVAudioPlayer *player = [audioPlayers objectForKey:title];
#if DEBUG
        [player setVolume:.1];
#endif
		[player setNumberOfLoops:0];
		if ([player isPlaying]){
			[player setCurrentTime:0.0];
		}
		else{
			[player setNumberOfLoops:numberOfLoops];
			if (![player play]){
				NSLog(@"Failed to play!");
			}
		}
	}	
}

-(void)playTitles: (NSArray *)playTitles
	   inSequence: (BOOL)playInSequence
{
	if (playInSequence) {
		if (!self.titles) {
			[self setTitles: [[playTitles mutableCopy] autorelease]];			
		}
		
		[self playTitle: [self.titles objectAtIndex: 0]
				looping: 0];
				
	} else {	// play simultaneously
		for (NSString *title in playTitles) {
			[self playTitle: title
					looping: 0];
		}
	}
}

-(void)playTitle:(NSString*)title
{
	[self playTitle: title looping: 0];
}

-(void)pauseTitle:(NSString*)title
{
	if ([audioPlayers count] > 0){
		AVAudioPlayer *player = [audioPlayers objectForKey:title];
		[player pause];
	}
	
}
-(void)stopTitle:(NSString*)title
{
	if ([audioPlayers count] > 0){
		AVAudioPlayer *player = [audioPlayers objectForKey:title];
		if ([player isPlaying]){
			[player stop];
		}
	}
	
}

-(void)stopAll
{
	for (NSString *aTitle in [audioPlayers allKeys]) {
		AVAudioPlayer *aPlayer = (AVAudioPlayer *)[audioPlayers objectForKey: aTitle];
		[aPlayer stop];
	}
}

-(void)removeAudioPlayerWithTitle:(NSString*)title
{
	if ([audioPlayers count] > 0){
		AVAudioPlayer *selectedPlayer = [audioPlayers objectForKey:title];
		if ([selectedPlayer	isPlaying]){
			//Delay the remove
			NSTimer* delayTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:[selectedPlayer duration]] interval:0.0 target:self selector:@selector(delayedRemove:) userInfo:title repeats:NO];
			[[NSRunLoop mainRunLoop] addTimer:delayTimer forMode:NSDefaultRunLoopMode];
			[delayTimer release];
		}
		else {
	
			[audioPlayers removeObjectForKey:title];
			if ([audioPlayers count] == 0)
			{
				AVAudioSession *avasession = [AVAudioSession sharedInstance];
				[avasession setActive:NO error:nil];
			}
		}
	}
	
	
}

-(void)delayedRemove:(id)data{
	NSString* title = (NSString*)data;
	
	[audioPlayers removeObjectForKey:title];
	if ([audioPlayers count] == 0)
	{
		AVAudioSession *avasession = [AVAudioSession sharedInstance];
		[avasession setActive:NO error:nil];
	}
}

-(void)delayedRelease:(id)data{
	AVAudioPlayer* releasedPlayer = (AVAudioPlayer*)data;
	dupPlayers--;
	[audioPlayers removeObjectForKey:[NSString stringWithFormat:@"%@", releasedPlayer]];
}

-(void)removeAll
{
	[self setAudioPlayers: nil];
	[[AVAudioSession sharedInstance] setActive:NO];
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{/*
	if (self.titles && self.titles.count > 0) {
		[self playTitles: self.titles
			  inSequence: YES];
		[self.titles removeObjectAtIndex:0];
	} else {
		[self setTitles: nil];
	}*/
}
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError*)error
{
	NSLog(@"Decode Error");
}
-(void)audioPlayerBeginInterruption:(AVAudioPlayer*)player
{
	
}
-(void)audioPlayerEndInterruption:(AVAudioPlayer*)player
{
	
}

-(void)dealloc{
	[super dealloc];
	
}
@end

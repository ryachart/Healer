//
//  AudioController.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface AudioController : NSObject <AVAudioPlayerDelegate> {
	NSMutableDictionary *audioPlayers;
	NSMutableArray	*titles;
	NSInteger dupPlayers;
}

@property (nonatomic, retain) NSMutableDictionary *audioPlayers;
@property (nonatomic, retain) NSMutableArray *titles;


+(id)sharedInstance;
-(id)init;
-(void)addNewPlayerWithTitle:(NSString*)title andURL:(NSURL*)url;
-(void)addNewPlayerWithTitle:(NSString*)title andData:(NSData*)url;
-(void)addNewPlayerWithTitle:(NSString*)title andData:(NSData*)data atVolume:(float)volume;
-(void)playTitle:(NSString*)title;
-(void)playTitle:(NSString*)title looping:(NSInteger)numberOfLoops;
-(void)playTitles:(NSArray*)titles inSequence:(BOOL)playInSequence;
-(void)pauseTitle:(NSString*)title;
-(void)stopTitle:(NSString*)title;
-(void)stopAll;
-(void)removeAudioPlayerWithTitle:(NSString*)title;
-(void)removeAll;
- (BOOL)isTitlePlaying:(NSString*)title;

@end

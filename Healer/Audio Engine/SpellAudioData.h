//
//  SpellAudioData.h
//  RaidLeader
//
//  Created by Ryan Hart on 5/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SpellAudioData : NSObject {
	NSURL *beginSound;
	NSString *beginTitle;
	
	NSURL *interruptedSound;
	NSString *interruptedTitle;
	
	NSURL *finishedSound;
	NSString *finishedTitle;
	
}
@property (readwrite, retain) NSString *beginTitle, *interruptedTitle, *finishedTitle;

-(void)setBeginSound:(NSURL*)soundPath andTitle:(NSString*)title;
-(void)setInterruptedSound:(NSURL*)soundPath andTitle:(NSString*)title;
-(void)setFinishedSound:(NSURL*)soundPath andTitle:(NSString*)title;


-(void)cacheSpellAudio;
-(void)releaseSpellAudio;
@end

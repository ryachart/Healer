//
//  MultiplayerSetupScene.h
//  Healer
//
//  Created by Ryan Hart on 4/4/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
#import <GameKit/GameKit.h>

@class Encounter;

@interface MultiplayerSetupScene : CCScene <GKMatchDelegate>
@property (nonatomic, retain) GKMatch *match;
@property (nonatomic, retain) GKVoiceChat *matchVoiceChat;
@property (nonatomic, retain) NSString* serverPlayerID;
@property (nonatomic, retain) Encounter *selectedEncounter;

-(BOOL)isServer;
-(id)initWithPreconfiguredMatch:(GKMatch*)preConMatch andServerID:(NSString*)serverID;
@end

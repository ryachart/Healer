//
//  MultiplayerSetupScene.h
//  Healer
//
//  Created by Ryan Hart on 4/4/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
#import <GameKit/GameKit.h>

@interface MultiplayerSetupScene : CCScene <GKMatchDelegate>
@property (nonatomic, retain) GKMatch *match;
@property (nonatomic, retain) NSString* serverPlayerID;

-(BOOL)isServer;

@end

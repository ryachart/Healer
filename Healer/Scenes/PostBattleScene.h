//
//  PostBattleScene.h
//  Healer
//
//  Created by Ryan Hart on 3/3/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
#import <GameKit/GameKit.h>

@interface PostBattleScene : CCScene <GKMatchDelegate>
@property (nonatomic, retain) GKMatch*match;
@property (nonatomic, retain) NSString* serverPlayerId;
@property (nonatomic, retain) GKVoiceChat *matchVoiceChat;

-(id)initWithVictory:(BOOL)victory andEventLog:(NSArray*)eventLog;


@end

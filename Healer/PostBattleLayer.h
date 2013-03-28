//
//  PostBattleLayer.h
//  Healer
//
//  Created by Ryan Hart on 3/20/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "cocos2d.h"
#import <GameKit/GameKit.h>

@class Encounter;

@interface PostBattleLayer : CCLayerColor

- (id)initWithVictory:(BOOL)victory encounter:(Encounter*)enc andIsMultiplayer:(BOOL)isMult andDuration:(NSTimeInterval)duration;

@property (nonatomic, retain) GKMatch* match;
@property (nonatomic, retain) NSString* serverPlayerId;
@property (nonatomic, retain) GKVoiceChat *matchVoiceChat;
@end

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

typedef enum {
    PostBattleLayerDestinationMap,
    PostBattleLayerDestinationShop,
    PostBattleLayerDestinationTalents
} PostBattleLayerDestination;

@protocol PostBattleLayerDelegate

- (void)postBattleLayerWillAwardLoot;
- (void)postBattleLayerDidTransitionToScene:(PostBattleLayerDestination)destination asVictory:(BOOL)victory;

@end

@interface PostBattleLayer : CCLayerColor

- (id)initWithVictory:(BOOL)victory encounter:(Encounter*)enc andIsMultiplayer:(BOOL)isMult andDuration:(NSTimeInterval)duration;

@property (nonatomic, assign) id <PostBattleLayerDelegate> delegate;

@property (nonatomic, retain) GKMatch* match;
@property (nonatomic, retain) NSString* serverPlayerId;
@property (nonatomic, retain) GKVoiceChat *matchVoiceChat;
@end

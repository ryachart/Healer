//
//  PostBattleScene.h
//  Healer
//
//  Created by Ryan Hart on 3/3/12.
//

#import "cocos2d.h"
#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@class Encounter;

@interface PostBattleScene : CCScene <GKMatchDelegate>
@property (nonatomic, retain) GKMatch*match;
@property (nonatomic, retain) NSString* serverPlayerId;
@property (nonatomic, retain) GKVoiceChat *matchVoiceChat;

- (id)initWithVictory:(BOOL)victory eventLog:(NSArray*)eventLog encounter:(Encounter*)enc andIsMultiplayer:(BOOL)isMultiplayer deadCount:(NSInteger)numDead andDuration:(NSTimeInterval)duration;

@end

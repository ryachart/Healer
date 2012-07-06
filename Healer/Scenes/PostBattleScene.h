//
//  PostBattleScene.h
//  Healer
//
//  Created by Ryan Hart on 3/3/12.
//

#import "cocos2d.h"
#import <GameKit/GameKit.h>

@interface PostBattleScene : CCScene <GKMatchDelegate>
@property (nonatomic, retain) GKMatch*match;
@property (nonatomic, retain) NSString* serverPlayerId;
@property (nonatomic, retain) GKVoiceChat *matchVoiceChat;

- (id)initWithVictory:(BOOL)victory eventLog:(NSArray*)eventLog levelNumber:(NSInteger)levelNumber andIsMultiplayer:(BOOL)isMultiplayer andFallenMembers:(NSInteger)numDead;


@end

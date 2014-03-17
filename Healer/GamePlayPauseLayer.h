//
//  GamePlayPauseLayer.h
//  Healer
//
//  Created by Ryan Hart on 3/31/12.
//

#import "cocos2d.h"

@class Encounter;

@protocol PauseLayerDelegate <NSObject>

- (void)pauseLayerDidFinish;
- (void)pauseLayerDidQuit;
- (void)pauseLayerDidRestart;

@end

@interface GamePlayPauseLayer : CCLayerColor <CCTableViewDataSource, CCTableViewDelegate>
@property (nonatomic, assign) id delegate;
- (id)initWithDelegate:(id)delegate encounter:(Encounter*)encounter;
- (void)quit;
- (void)close;
@end

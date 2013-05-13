//
//  GamePlayPauseLayer.h
//  Healer
//
//  Created by Ryan Hart on 3/31/12.
//

#import "cocos2d.h"

@protocol PauseLayerDelegate <NSObject>

- (void)pauseLayerDidFinish;
- (void)pauseLayerDidQuit;
- (void)pauseLayerDidRestart;

@end

@interface GamePlayPauseLayer : CCLayerColor
@property (nonatomic, assign) id delegate;
-(id)initWithDelegate:(id)delegate;

-(void)quit;
-(void)close;
@end

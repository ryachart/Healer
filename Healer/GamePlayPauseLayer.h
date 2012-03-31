//
//  GamePlayPauseLayer.h
//  Healer
//
//  Created by Ryan Hart on 3/31/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "CCLayer.h"

@protocol PauseLayerDelegate <NSObject>

-(void)pauseLayerDidFinish;

@end

@interface GamePlayPauseLayer : CCLayerColor
@property (nonatomic, assign) id delegate;
-(id)initWithDelegate:(id)delegate;

-(void)quit;
-(void)close;
@end

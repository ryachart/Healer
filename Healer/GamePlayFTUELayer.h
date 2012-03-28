//
//  GamePlayFTUELayer.h
//  Healer
//
//  Created by Ryan Hart on 3/28/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@protocol GamePlayFTUELayerDelegate <NSObject>

-(void)ftueLayerDidComplete;

@end

@interface GamePlayFTUELayer : CCLayerColor
@property (nonatomic, assign) CCLayerColor *highlightLayer;
@property (nonatomic, assign) CCLabelTTF *informationLabel;
@property (nonatomic, assign) id delegate;

-(void)showWelcome;
-(void)showPlayerInformation;
-(void)showSpellInformation;
-(void)showBossInformation;
-(void)showRaidInformation;
-(void)showGoodLuck;

@end

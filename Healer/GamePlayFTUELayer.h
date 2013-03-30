//
//  GamePlayFTUELayer.h
//  Healer
//
//  Created by Ryan Hart on 3/28/12.
//

#import "cocos2d.h"

@protocol GamePlayFTUELayerDelegate <NSObject>

-(void)ftueLayerDidComplete:(CCNode*)ftueLayer;

@end

@interface GamePlayFTUELayer : CCLayerColor
@property (nonatomic, assign) id delegate;

- (void)clear;

- (void)waitForSelectionOnTargetAtFrame:(CGPoint)frameLoc;
- (void)waitForHeal;
- (void)waitForSelectionOfAbilityIcon;

//Old FTUE
-(void)showWelcome;
-(void)showPlayerInformation;
-(void)showSpellInformation;
-(void)showBossInformation;
-(void)showRaidInformation;
-(void)showGoodLuck;

@end

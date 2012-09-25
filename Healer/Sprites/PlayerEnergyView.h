//
//  PlayerEnergyView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <cocos2d.h>
#import "GameObjects.h"

@class Scale9Sprite;
@class ChannelingDelegate;

@interface PlayerEnergyView : CCLayerColor {
	double percentEnergy;
	double percentChanneled;
    BOOL isTouched;
}
@property (nonatomic, assign) ChannelingDelegate *channelDelegate;
@property (nonatomic, assign) Scale9Sprite *energyStyleFrame;
@property (nonatomic, assign) CCSprite *energyBar;
@property (nonatomic, assign) CCLabelTTF *energyLabel;
@property (readwrite) double percentChanneled;
- (id)initWithFrame:(CGRect)frame;
- (void)updateWithEnergy:(NSInteger)current andMaxEnergy:(NSInteger)max;
@end

@protocol ChannelingDelegate

-(void)beginChanneling;
-(void)endChanneling;

@end


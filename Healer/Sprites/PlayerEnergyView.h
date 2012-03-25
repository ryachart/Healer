//
//  PlayerEnergyView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObjects.h"

@class ChannelingDelegate;

@interface PlayerEnergyView : CCLayerColor {
	double percentEnergy;
	double percentChanneled;
	
	ChannelingDelegate *channelDelegate;
	BOOL isTouched;
}
@property (retain) ChannelingDelegate *channelDelegate;
@property (nonatomic, assign) CCLayerColor *energyBar;
@property (nonatomic, assign) CCLabelTTF *energyLabel;
@property (readwrite) double percentChanneled;
- (id)initWithFrame:(CGRect)frame;
-(void)updateWithEnergy:(NSInteger)current andMaxEnergy:(NSInteger)max;
@end

@protocol ChannelingDelegate

-(void)beginChanneling;
-(void)endChanneling;

@end


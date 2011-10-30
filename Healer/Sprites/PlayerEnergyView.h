//
//  PlayerEnergyView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameObjects.h"

@class ChannelingDelegate;

@interface PlayerEnergyView : UIView {
	UILabel *energyLabel;
	
	double percentEnergy;
	double percentChanneled;
	
	ChannelingDelegate *channelDelegate;
	
}
@property (retain) ChannelingDelegate *channelDelegate;
@property (readwrite) double percentChanneled;

-(void)updateWithEnergy:(NSInteger)current andMaxEnergy:(NSInteger)max;
@end

@protocol ChannelingDelegate

-(void)beginChanneling;
-(void)endChanneling;

@end


//
//  PlayerEnergyView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <cocos2d.h>
#import "GameObjects.h"


@class ChannelingDelegate, CCLabelTTFShadow;

@interface PlayerStatusView : CCLayer
@property (nonatomic, readwrite) float percentEnergy;
@property (nonatomic, assign) ChannelingDelegate *channelDelegate;
@property (nonatomic, readwrite) double percentChanneled;
- (id)initWithFrame:(CGRect)frame;
- (void)updateWithPlayer:(Player*)player;
@end

@protocol ChannelingDelegate

-(void)beginChanneling;
-(void)endChanneling;

@end


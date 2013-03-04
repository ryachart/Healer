//
//  PlayerCastBar.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@class CCLabelTTFShadow, Player;
@interface PlayerCastBar : CCLayer <CCRGBAProtocol> 
@property (nonatomic, assign) CCLabelTTFShadow *timeRemaining;
@property (nonatomic, assign) Player *player;

-(id)initWithFrame:(CGRect)frame;
-(void)update;
-(void)displayInterruption;
@end

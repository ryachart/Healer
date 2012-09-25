//
//  PlayerHealthView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Player.h"
#import "cocos2d.h"

@class PlayerHealthViewDelegate;

@interface PlayerHealthView : CCLayerColor {
	BOOL isTouched;
}
@property (nonatomic, retain) CCLayerColor *healthBar;
@property (nonatomic, assign, setter=setMemberData:) HealableTarget* memberData;
@property (nonatomic, retain) CCLabelTTF *healthLabel;
@property (nonatomic, assign) PlayerHealthViewDelegate *interactionDelegate;
@property ccColor3B defaultBackgroundColor;
@property BOOL isTouched;
-(id)initWithFrame:(CGRect)frame;
-(void)setMemberData:(HealableTarget*)thePlayer;

-(void)updateHealth;

@end


@protocol PlayerHealthViewDelegate 
-(void)playerSelected:(PlayerHealthView*)hv;
-(void)playerUnselected:(PlayerHealthView*)hv;

@end
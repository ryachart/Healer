//
//  PlayerHealthView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Player.h"

@class PlayerHealthViewDelegate;

@interface PlayerHealthView : UIView {
	UILabel *healthLabel;
	UIColor *defaultBackgroundColor;
	HealableTarget* memberData;
	BOOL isTouched;
	
	PlayerHealthViewDelegate *interactionDelegate;
}
@property (assign, setter=setMemberData) HealableTarget* memberData;
@property (nonatomic, retain) IBOutlet UILabel *healthLabel;
@property (nonatomic, retain) PlayerHealthViewDelegate *interactionDelegate;
@property (retain) UIColor *defaultBackgroundColor;
@property BOOL isTouched;

-(void)setMemberData:(HealableTarget*)thePlayer;

-(void)updateHealth;

@end


@protocol PlayerHealthViewDelegate 
-(void)playerSelected:(PlayerHealthView*)hv;
-(void)playerUnselected:(PlayerHealthView*)hv;

@end
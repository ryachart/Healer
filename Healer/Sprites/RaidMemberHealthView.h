//
//  RaidMemberHealthView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameObjects.h"

@class RaidMemberHealthViewDelegate;

@interface RaidMemberHealthView : UIView {
	UILabel *classNameLabel;
	UILabel *healthLabel;
	UILabel *effectsLabel;
	UIColor *defaultBackgroundColor;
	
	HealableTarget* memberData;
	RaidMemberHealthViewDelegate *interactionDelegate;
	
	BOOL isTouched;
	
}
@property (assign, setter=setMemberData) HealableTarget* memberData;
@property (nonatomic, retain) UILabel *classNameLabel;
@property (nonatomic, retain) UILabel *healthLabel;
@property (nonatomic, retain) UILabel *effectsLabel;
@property (nonatomic, retain) RaidMemberHealthViewDelegate *interactionDelegate;
@property (retain) UIColor *defaultBackgroundColor;
@property BOOL isTouched;
-(void)setMemberData:(HealableTarget*)rdMember;

-(void)updateHealth;
@end

@protocol RaidMemberHealthViewDelegate

-(void)thisMemberSelected:(RaidMemberHealthView*)hv;
-(void)thisMemberUnselected:(RaidMemberHealthView*)hv;

@end


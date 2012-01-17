//
//  RaidMemberHealthView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameObjects.h"
#import "cocos2d.h"

@class RaidMemberHealthViewDelegate;

@interface RaidMemberHealthView : CCLayerColor {
	HealableTarget* memberData;
	RaidMemberHealthViewDelegate *interactionDelegate;
	
	
}
@property (nonatomic, assign, setter=setMemberData:) HealableTarget* memberData;
@property (nonatomic, retain) CCLayerColor *healthBarLayer;
@property (nonatomic, retain) CCLabelTTF *classNameLabel;
@property (nonatomic, retain) CCLabelTTF *healthLabel;
@property (nonatomic, retain) CCLabelTTF *effectsLabel;
@property (nonatomic, retain) RaidMemberHealthViewDelegate *interactionDelegate;
@property (nonatomic, readwrite) ccColor3B defaultBackgroundColor;
@property (nonatomic) BOOL isTouched;
-(void)setMemberData:(HealableTarget*)rdMember;

-(void)updateHealth;
-(id)initWithFrame:(CGRect)frame;
@end

@protocol RaidMemberHealthViewDelegate

-(void)thisMemberSelected:(RaidMemberHealthView*)hv;
-(void)thisMemberUnselected:(RaidMemberHealthView*)hv;

@end


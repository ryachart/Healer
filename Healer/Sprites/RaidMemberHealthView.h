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

typedef enum {
    RaidViewSelectionStateNone,
    RaidViewSelectionStateSelected,
    RaidViewSelectionStateAltSelected
} RaidViewSelectionState;

@class CCRoundedRect;
@class RaidMemberHealthViewDelegate;

@interface RaidMemberHealthView : CCLayer {
	HealableTarget* memberData;
	RaidMemberHealthViewDelegate *interactionDelegate;
}
@property (nonatomic, assign, setter=setMemberData:) HealableTarget* memberData;
@property (nonatomic, retain) CCLabelTTF *healthLabel;
@property (nonatomic, retain) RaidMemberHealthViewDelegate *interactionDelegate;
@property (nonatomic) BOOL isTouched;
@property (nonatomic, readwrite) RaidViewSelectionState selectionState;
-(void)setMemberData:(HealableTarget*)rdMember;

-(void)updateHealth;
-(id)initWithFrame:(CGRect)frame;

-(void)displaySCT:(NSString*)sct;
@end

@protocol RaidMemberHealthViewDelegate

-(void)thisMemberSelected:(RaidMemberHealthView*)hv;
-(void)thisMemberUnselected:(RaidMemberHealthView*)hv;

@end


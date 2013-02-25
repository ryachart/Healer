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
#import "CCLabelTTFShadow.h"

typedef enum {
    RaidViewSelectionStateNone,
    RaidViewSelectionStateSelected,
    RaidViewSelectionStateAltSelected
} RaidViewSelectionState;

@class RaidMemberHealthViewDelegate;

@interface RaidMemberHealthView : CCLayer <CCRGBAProtocol>
@property (nonatomic, assign) RaidMember* member;
@property (nonatomic, retain) CCLabelTTFShadow *healthLabel;
@property (nonatomic, assign) RaidMemberHealthViewDelegate *interactionDelegate;
@property (nonatomic) BOOL isTouched;
@property (nonatomic, readwrite) RaidViewSelectionState selectionState;

- (void)updateHealthForInterval:(ccTime)time;
- (id)initWithFrame:(CGRect)frame;

- (void)displaySCT:(NSString*)sct;
- (void)displaySCT:(NSString*)sct asCritical:(BOOL)critical;
- (void)triggerConfusion;

@end

@protocol RaidMemberHealthViewDelegate

- (void)thisMemberSelected:(RaidMemberHealthView*)hv;
- (void)thisMemberUnselected:(RaidMemberHealthView*)hv;

@end


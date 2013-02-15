//
//  PlayerMoveButton.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <cocos2d.h>


@interface PlayerMoveButton : CCLayer <CCRGBAProtocol>
@property (nonatomic, readwrite) BOOL isMoving;
- (id)initWithFrame:(CGRect)frame;
@end

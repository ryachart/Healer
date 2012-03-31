//
//  RaidMemberPreBattleCard.h
//  Healer
//
//  Created by Ryan Hart on 3/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
@class RaidMember;
@interface RaidMemberPreBattleCard : CCLayerColor
-(id)initWithFrame:(CGRect)frame count:(NSInteger)count andRaidMember:(RaidMember *)member;
@end

//
//  RaidMemberPreBattleCard.h
//  Healer
//
//  Created by Ryan Hart on 3/30/12.
//

#import "cocos2d.h"
@class RaidMember;
@interface RaidMemberPreBattleCard : CCSprite
-(id)initWithFrame:(CGRect)frame count:(NSInteger)count andRaidMember:(RaidMember *)member;
@end

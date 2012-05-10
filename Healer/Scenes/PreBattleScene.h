//
//  PreBattleScene.h
//  Healer
//
//  Created by Ryan Hart on 3/26/12.
//

#import "cocos2d.h"
#import "AddRemoveSpellLayer.h"

@class Raid, Boss, Player;

@interface PreBattleScene : CCScene <SpellSwitchDelegate>
@property (readwrite) NSInteger levelNumber;
-(id)initWithRaid:(Raid*)raid boss:(Boss*)boss andPlayer:(Player*)player;

@end

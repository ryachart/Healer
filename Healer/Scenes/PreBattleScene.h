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
@property (nonatomic, retain) Player *player;
@property (nonatomic, retain) Boss *boss;
@property (nonatomic, retain) Raid *raid;
-(id)initWithRaid:(Raid*)raid boss:(Boss*)boss andPlayer:(Player*)player;
-(void)doneButton;
-(void)changeSpells;
@end

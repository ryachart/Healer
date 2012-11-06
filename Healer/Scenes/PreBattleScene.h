//
//  PreBattleScene.h
//  Healer
//
//  Created by Ryan Hart on 3/26/12.
//

#import "cocos2d.h"
#import "AddRemoveSpellLayer.h"

@class Encounter, Player, BasicButton;

@interface PreBattleScene : CCScene <SpellSwitchDelegate>
@property (readwrite) NSInteger levelNumber;
@property (nonatomic, retain) Player *player;
@property (nonatomic, retain) Encounter *encounter;
@property (nonatomic, assign) BasicButton *continueButton;

- (id)initWithEncounter:(Encounter*)enc andPlayer:(Player*)player;
- (void)doneButton;
- (void)changeSpells;
- (void)back;
@end

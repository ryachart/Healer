//
//  GamePlayScene.h
//  Healer
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObjects.h"
#import "GameUserInterface.h"
#import "AudioController.h"
#import "Encounter.h"


@class PlayerSpellButton;
@class RaidView;
@class Chargable;
@class BossHealthView;
@class PlayerHealthView;
@class PlayerEnergyView;
@class PlayerMoveButton;
@class PlayerCastBar;
/* This is the screen we see while involved in a raid */
@interface GamePlayScene : CCScene {
	NSMutableDictionary *memberToHealthView;
	NSMutableArray *selectedRaidMembers;
	
}
@property (readwrite, retain) Encounter *activeEncounter;
//Interface Elements
@property (nonatomic, retain) PlayerSpellButton *spellView1;
@property (nonatomic, retain) PlayerSpellButton *spellView2;
@property (nonatomic, retain) PlayerSpellButton *spellView3;
@property (nonatomic, retain) PlayerSpellButton *spellView4;
@property (nonatomic, retain) RaidView* raidView;
@property (nonatomic, retain) BossHealthView *bossHealthView;
@property (nonatomic, retain) PlayerHealthView *playerHealthView;
@property (nonatomic, retain) PlayerEnergyView *playerEnergyView;
@property (nonatomic, retain) PlayerMoveButton *playerMoveButton;
@property (nonatomic, retain) PlayerCastBar *playerCastBar;
@property (nonatomic, retain) CCLabelTTF *alertStatus;

-(id)initWithRaid:(Raid*)raidToUse boss:(Boss*)bossToUse andPlayer:(Player*)playerToUse;

@end

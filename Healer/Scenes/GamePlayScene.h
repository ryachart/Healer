//
//  GamePlayScene.h
//  Healer
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObjects.h"
#import "CombatEvent.h"
#import "Announcer.h"
#import "GamePlayFTUELayer.h"
#import "GamePlayPauseLayer.h"
#import <GameKit/GameKit.h>
#import "BossHealthView.h"
#import "IconDescriptionModalLayer.h"
#import "EnemyAbilityDescriptionsView.h"
#import "PostBattleLayer.h"

@class PlayerSpellButton;
@class RaidView;
@class Chargable;
@class BossHealthView;
@class PlayerStatusView;
@class PlayerMoveButton;
@class PlayerCastBar;
@class Encounter;

/* This is the screen we see while involved in a raid */
@interface GamePlayScene : CCScene <EventLogger, Announcer, GamePlayFTUELayerDelegate, PauseLayerDelegate, GKMatchDelegate, IconDescriptorModalDelegate, AbilityDescriptionViewDelegate, PostBattleLayerDelegate>
//Interface Elements
@property (nonatomic, retain) NSMutableArray *selectedRaidMembers;
@property (nonatomic, retain) PlayerSpellButton *spellView1;
@property (nonatomic, retain) PlayerSpellButton *spellView2;
@property (nonatomic, retain) PlayerSpellButton *spellView3;
@property (nonatomic, retain) PlayerSpellButton *spellView4;
@property (nonatomic, retain) RaidView* raidView;
@property (nonatomic, retain) BossHealthView *bossHealthView;
@property (nonatomic, retain) PlayerStatusView *playerStatusView;
@property (nonatomic, retain) PlayerMoveButton *playerMoveButton;
@property (nonatomic, retain) PlayerCastBar *playerCastBar;
@property (nonatomic, retain) CCLabelTTF *alertStatus;
- (id)initWithEncounter:(Encounter*)enc player:(Player*)player;
- (id)initWithEncounter:(Encounter*)enc andPlayers:(NSArray*)plyers;
//Multiplayer
@property (nonatomic, readonly) BOOL isServer;
@property (nonatomic, readonly) BOOL isClient;
@property (nonatomic, retain) NSString *serverPlayerID;
@property (nonatomic, retain) GKMatch*match;
@property (nonatomic, retain) GKVoiceChat *matchVoiceChat;
@property (nonatomic, retain) NSArray *players;

-(void)setIsClient:(BOOL)isClient forServerPlayerId:(NSString*)serverPlayerID;


@end

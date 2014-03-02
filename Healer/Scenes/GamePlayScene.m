    //
//  GamePlayScene.m
//  Healer
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GamePlayScene.h"
#import "RaidView.h"
#import "PlayerSpellButton.h"
#import "PlayerMoveButton.h"
#import "PostBattleScene.h"
#import "PlayerDataManager.h"
#import "GamePlayPauseLayer.h"
#import "CCShakeScreen.h"
#import "ParticleSystemCache.h"
#import "Encounter.h"
#import "HealableTarget.h"
#import "PlayerStatusView.h"
#import "PlayerCastBar.h"
#import "BackgroundSprite.h"
#import "NormalModeCompleteScene.h"
#import "BasicButton.h"
#import "CCLabelTTFShadow.h"
#import "GradientBorderLayer.h"
#import "EnemiesLayer.h"
#import "ShopScene.h"
#import "LevelSelectMapScene.h"
#import "TalentScene.h"
#import "SimpleAudioEngine.h"
#import "CollectibleLayer.h"
#import "InventoryScene.h"
#import "PlayerSprite.h"

#define DEBUG_IMMUNITIES false
#define DEBUG_PERFECT_HEALS false
#define DEBUG_HIGH_HPS true
#define DEBUG_WIN_IMMEDIATELY false

#define DEBUG_HPS 250
#define DEBUG_DAMAGE 0.0

#define RAID_Z 5
#define PAUSEABLE_TAG 812

#define NETWORK_THROTTLE 5

#define AMBIENT_BATTLE_LOOP @"sounds/ambientbattle.mp3"

@interface GamePlayScene ()
//Data Models
@property (nonatomic, readwrite) BOOL paused;
@property (nonatomic, readwrite) BOOL restarting;
@property (nonatomic, retain) Encounter *encounter;
@property (nonatomic, readonly) Raid *raid;
@property (nonatomic, readonly) Player *player;
@property (nonatomic, assign) CCLabelTTFShadow *announcementLabel;
@property (nonatomic, assign) CCLabelTTF *errAnnouncementLabel;
@property (nonatomic, retain) GamePlayPauseLayer *pauseMenuLayer;
@property (nonatomic, readwrite) NSInteger networkThrottle;
@property (nonatomic, readwrite) GradientBorderLayer *gradientBorder;
@property (nonatomic, retain) NSMutableDictionary *playingSoundsDict;
@property (nonatomic, assign) EnemiesLayer *enemiesLayer;
@property (nonatomic, assign) GamePlayFTUELayer *ftueLayer;
@property (nonatomic, assign) CCMenu *pauseButton;
@property (nonatomic, assign) CCLayerColor *screenFlashLayer;
@property (nonatomic, readwrite) ALuint ambientBattleKey;
@property (nonatomic, assign) CollectibleLayer *collectibleLayer;
@property (nonatomic, retain) NSMutableArray *effectsPlayedThisSession;
@property (nonatomic, assign) BackgroundSprite *sceneBackground;
@property (nonatomic, assign) BackgroundSprite *mainBackground;
@property (nonatomic, assign) PlayerSprite *healerPortrait;
@property (nonatomic, assign) CCParticleSystemQuad *castingEffect;

@property (nonatomic, retain) NSDictionary *randomTitlesPresetDictionary;
@end

@implementation GamePlayScene

- (void)dealloc {
    [_spellView1 release];
    [_spellView2 release];
    [_spellView3 release];
    [_spellView4 release];
    [_weaponSpell release];
    [_raidView release];
    [_bossHealthView release];
    [_playerStatusView release];
    [_playerMoveButton release];
    [_playerCastBar release];
    [_alertStatus release];
    [_serverPlayerID release];
    [_match release];
    [_matchVoiceChat release];
    [_players release];
    [_selectedRaidMembers release];
    [_encounter release];
    [_pauseMenuLayer release];
    [_playingSoundsDict release];
    [_randomTitlesPresetDictionary release];
    
    if (!_restarting){
        for (NSString *effect in _effectsPlayedThisSession) {
            [[SimpleAudioEngine sharedEngine] unloadEffect:effect];
        }
        if (_encounter && _encounter.bossKey) {
            //Unload the boss specific sprites;
            [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:[NSString stringWithFormat:@"assets/%@.plist", _encounter.bossKey]];
        }
        [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/battle-sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/effect-sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/postbattle.plist"];
        
        [[SimpleAudioEngine sharedEngine] unloadEffect:AMBIENT_BATTLE_LOOP];
    }
    [_effectsPlayedThisSession release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (Player*)player{
    return [self.players objectAtIndex:0];
}

- (Raid*)raid
{
    return self.encounter.raid;
}

- (id)initWithEncounter:(Encounter*)enc player:(Player*)plyre
{
    return [self initWithEncounter:enc andPlayers:[NSArray arrayWithObject:plyre]];
}

- (id)initWithEncounter:(Encounter*)enc andPlayers:(NSArray*)plyers
{
    if (self = [super init]){
        self.encounter = enc;
        self.players = plyers;
        self.playingSoundsDict = [NSMutableDictionary dictionaryWithCapacity:10];
        self.effectsPlayedThisSession = [NSMutableArray arrayWithCapacity:20];
        
        self.randomTitlesPresetDictionary = @{@"thud.mp3": @4, @"whiff.mp3" : @6, @"sword_slash.mp3" : @3};
        
        NSAssert(self.players.count > 0, @"A Battle with no players was initiated.");
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/battle-sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/effect-sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/postbattle.plist"];
        
        
        self.sceneBackground = [[[BackgroundSprite alloc] initWithJPEGAssetName:[Encounter backgroundPathForEncounter:self.encounter.levelNumber]] autorelease];
        [self.sceneBackground setPosition:CGPointMake(0, 408)];
        [self addChild:self.sceneBackground];
        
        self.mainBackground = [[[BackgroundSprite alloc] initWithAssetName:@"battle_back_main"] autorelease];
        [self addChild:self.mainBackground];

        if (self.players.count > 1) {
            for (int i = 1; i < self.players.count; i++){
                Player *iPlayer = [self.players objectAtIndex:i];
                [iPlayer setLogger:self];
                [iPlayer setAnnouncer:self];
                [iPlayer initializeForCombat];
            }
        }
        
        self.gradientBorder = [[[GradientBorderLayer alloc] init] autorelease];
        [self.gradientBorder setOpacity:0];
        [self addChild:self.gradientBorder];
        
        self.screenFlashLayer = [[[CCLayerColor alloc] initWithColor:ccc4(255, 255, 255, 0)] autorelease];
        [self addChild:self.screenFlashLayer];
        
        _paused = YES;
        for (Enemy *enemy in self.encounter.enemies) {
            [enemy setLogger:self];
            [enemy setAnnouncer:self];
        }
        [self.player setLogger:self];
        [self.player setAnnouncer:self];
        [self.player initializeForCombat];
        
        self.players = [NSArray arrayWithObject:self.player];
        
        CGPoint raidViewLoc = CGPointMake(260, 10);
        
        if (self.encounter.raid.members.count <= 5) {
            raidViewLoc = CGPointMake(260, 170);
        } else if (self.encounter.raid.members.count <= 10) {
            raidViewLoc = CGPointMake(260, 120);
        }
        
        self.raidView = [[[RaidView alloc] init] autorelease];
        [self.raidView setPosition:raidViewLoc];
        [self.raidView setContentSize:CGSizeMake(500, 320)];
        [self addChild:self.raidView z:RAID_Z];
        
        self.enemiesLayer = [[[EnemiesLayer alloc] initWithEnemies:self.encounter.enemies] autorelease];
        [self.enemiesLayer setDelegate:self];
        [self.enemiesLayer setPosition:CGPointMake(0, 408)];
        [self.enemiesLayer setAreAbilitiesVisible:NO];
        [self addChild:self.enemiesLayer];
        
        self.castingEffect = [[ParticleSystemCache sharedCache] systemForKey:@"swirly_casty.png"];
        [self.castingEffect setPosition:CGPointMake(54, 280)];
        [self addChild:self.castingEffect];
        
        self.healerPortrait = [[[PlayerSprite alloc] initWithEquippedItems:[PlayerDataManager localPlayer].equippedItems] autorelease];
        [self.healerPortrait setScale:.75];
        self.healerPortrait.flipX = YES;
        [self.healerPortrait setPosition:CGPointMake(130, 180)];
        [self addChild:self.healerPortrait];
        
        self.playerCastBar = [[[PlayerCastBar alloc] initWithFrame:CGRectMake(322,350, 400, 50)] autorelease];
        [self.playerCastBar setPlayer:self.player];
        self.playerStatusView = [[[PlayerStatusView alloc] init] autorelease];
        [self.playerStatusView setPosition:CGPointMake(130, 100)];
        
        self.playerMoveButton = [[[PlayerMoveButton alloc] init] autorelease];
        [self.playerMoveButton setPosition:CGPointMake(-280, -324)];
        [self.playerCastBar addChild:self.playerMoveButton];
        
        self.announcementLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(500, 300) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        [self.announcementLabel setPosition:CGPointMake(512, 440)];
        [self.announcementLabel setColor:ccYELLOW];
        [self.announcementLabel setVisible:NO];
        
        self.errAnnouncementLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(500, 300) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        [self.errAnnouncementLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .5, [CCDirector sharedDirector].winSize.height * .62)];
        [self.errAnnouncementLabel setColor:ccRED];
        [self.errAnnouncementLabel setVisible:NO];
        
        [self addChild:self.playerCastBar];
        [self addChild:self.playerStatusView];
        [self addChild:self.announcementLabel z:100 tag:PAUSEABLE_TAG];
        [self addChild:self.errAnnouncementLabel z:98 tag:PAUSEABLE_TAG];
        
        //CACHE SOUNDS
        [[SimpleAudioEngine sharedEngine] preloadEffect:AMBIENT_BATTLE_LOOP];
        
        for (int i = 0; i < 4; i++){
            switch (i) {
                case 0:
                    self.spellView1 = [[[PlayerSpellButton alloc] init] autorelease];
                    [self.spellView1 setPosition:CGPointMake(910, 295)];
                    if (self.player.activeSpells.count > i) {
                        Spell *spell = [[self.player activeSpells] objectAtIndex:i];
                        [self.spellView1 setSpellData:spell];
                        [self.spellView1 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                        [self.spellView1 setPlayer:self.player];
                    }
                    [self addChild:self.spellView1];
                    break;
                case 1:
                    self.spellView2 = [[[PlayerSpellButton alloc] init] autorelease];
                    [self.spellView2 setPosition:CGPointMake(910, 200)];
                    if (self.player.activeSpells.count > i) {
                        Spell *spell = [[self.player activeSpells] objectAtIndex:i];
                        [self.spellView2 setSpellData:spell];
                        [self.spellView2 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                        [self.spellView2 setPlayer:self.player];
                    }
                    [self addChild:self.spellView2];
                    break;
                case 2:
                    self.spellView3 = [[[PlayerSpellButton alloc] init] autorelease];
                    [self.spellView3 setPosition:CGPointMake(910, 105)];
                    if (self.player.activeSpells.count > i) {
                        Spell *spell = [[self.player activeSpells] objectAtIndex:i];
                        [self.spellView3 setSpellData:spell];
                        [self.spellView3 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                        [self.spellView3 setPlayer:self.player];
                    }
                    [self addChild:self.spellView3];
                    break;
                case 3:
                    self.spellView4 = [[[PlayerSpellButton alloc] init] autorelease];
                    [self.spellView4 setPosition:CGPointMake(910, 10)];
                    if (self.player.activeSpells.count > i) {
                        Spell *spell = [[self.player activeSpells] objectAtIndex:i];
                        [self.spellView4 setSpellData:spell];
                        [self.spellView4 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                        [self.spellView4 setPlayer:self.player];
                    }
                    [self addChild:self.spellView4];
                    break;
                default:
                    break;
            }
        }
        
        if (self.player.spellsFromEquipment.count > 0) {
            self.weaponSpell = [[[PlayerSpellButton alloc] init] autorelease];
            [self.weaponSpell setPosition:CGPointMake(815, 10)];
            [self.weaponSpell setSpellData:[self.player.spellsFromEquipment objectAtIndex:0]];
            [self.weaponSpell setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
            [self.weaponSpell setPlayer:self.player];
            [self addChild:self.weaponSpell];
        }
        
        for (Player *player in self.players) {
            [self.raid addPlayer:player];
        }
        
#if DEBUG_IMMUNITIES
        for (RaidMember *member in self.raid.livingMembers) {
            Effect *immunity = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
            [immunity setOwner:self.player];
            [immunity setDamageTakenMultiplierAdjustment:-1];
            [member addEffect:immunity];
        }
#endif

#if DEBUG_PERFECT_HEALS
        for (RaidMember *member in self.raid.livingMembers) {
            PerfectHeal *immunity = [[[PerfectHeal alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
            [immunity setDamageDoneMultiplierAdjustment:DEBUG_DAMAGE];
            [immunity setOwner:self.player];
            [member addEffect:immunity];
        }
#endif
        
#if DEBUG_HIGH_HPS
        for (int i = 0; i < 5; i++) {
            WanderingSpiritEffect *hot = [[[WanderingSpiritEffect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
            [hot setOwner:self.player];
            [hot setTitle:[NSString stringWithFormat:@"wse-high-hps-%d", i]];
            [hot setValuePerTick:DEBUG_HPS];
            [hot setDamageDoneMultiplierAdjustment:DEBUG_DAMAGE];
            [[self.raid randomLivingMember] addEffect:hot];
        }
#endif
        
        NSArray *raidMembers = [self.raid raidMembers];
        self.selectedRaidMembers = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
        for (RaidMember *member in raidMembers)
        {
            [member setLogger:self];
            [member setAnnouncer:self];
            RaidMemberHealthView *rmhv = [[[RaidMemberHealthView alloc] initWithFrame:[self.raidView nextUsableRect]] autorelease];
            [rmhv setMember:member];
            [rmhv setInteractionDelegate:(RaidMemberHealthViewDelegate*)self];
            [self.raidView addRaidMemberHealthView:rmhv];
        }
        [self.bossHealthView setBossData:[self.encounter.enemies objectAtIndex:0]];
        
        //The timer has to be scheduled after all the init is done!
        CCSprite *pause = [CCSprite spriteWithSpriteFrameName:@"pause-button.png"];
        CCSprite *pauseDown = [CCSprite spriteWithSpriteFrameName:@"pause-down.png"];
        CCMenuItemSprite *pauseButtonItem = [CCMenuItemSprite itemWithNormalSprite:pause selectedSprite:pauseDown target:self selector:@selector(showPauseMenu)];
        self.pauseButton = [CCMenu menuWithItems:pauseButtonItem, nil];
        [self.pauseButton setPosition:CGPointMake(50, [CCDirector sharedDirector].winSize.height * .9325)];
        [self addChild:self.pauseButton];
        
        self.collectibleLayer = [[[CollectibleLayer alloc] initWithOwningPlayer:self.player encounter:self.encounter players:self.players] autorelease];
        [self addChild:self.collectibleLayer z:100];
        
        self.networkThrottle = 0;
        
        if (self.encounter.levelNumber == 1 && [PlayerDataManager localPlayer].ftueState < FTUEStateBattle1Finished) {
            [PlayerDataManager localPlayer].ftueState = FTUEStateFresh;
            //Reset the FTUE state so we do the whole Ftue if the battle isn't finished
            self.ftueLayer = [[[GamePlayFTUELayer alloc] init] autorelease];
            [self.ftueLayer setDelegate:self];
            [self addChild:self.ftueLayer z:1000];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
    return self;
}

-(void)setPaused:(BOOL)newPaused{
    
    if (self.paused == newPaused)
        return;
    
    _paused = newPaused;
    
    if (self.isClient || self.isServer){
        if (_paused == YES){
            return; //Cant pause multiplayerg
        }
    }
    
    if (self.paused){
        for (CCNode *node in self.children) {
            if (node.tag == PAUSEABLE_TAG) {
                [node pauseSchedulerAndActions];
            }
        }
        [[self actionManager] pauseTarget:self];
        [self unschedule:@selector(gameEvent:)];
        [[SimpleAudioEngine sharedEngine] stopEffect:self.ambientBattleKey];
        self.ambientBattleKey = 0;
    }else{
        for (CCNode *node in self.children) {
            if (node.tag == PAUSEABLE_TAG) {
                [node resumeSchedulerAndActions];
            }
        }
        [[self actionManager] resumeTarget:self];
        [self schedule:@selector(gameEvent:)];
    }
    [self.raidView setPaused:newPaused];
    [self.collectibleLayer setIsPaused:newPaused];
}

-(void)showPauseMenu{
    if (self.paused){
        return;
    }
    
    [self setPaused:YES];
    
    if (!self.pauseMenuLayer){
        self.pauseMenuLayer = [[[GamePlayPauseLayer alloc] initWithDelegate:self] autorelease];
        self.pauseMenuLayer.delegate = self;
    }
    [self addChild:self.pauseMenuLayer z:10000];
}

- (void)pauseLayerDidRestart
{
    [self.pauseMenuLayer removeFromParentAndCleanup:YES];
    self.pauseMenuLayer = nil;
    [[PlayerDataManager localPlayer] failLevel:self.encounter.levelNumber];
    
    self.restarting = YES;
    
    Encounter *encounter = [Encounter encounterForLevel:self.encounter.levelNumber isMultiplayer:NO];
    Player *player = [PlayerDataManager playerFromLocalPlayer];
    [player configureForRecommendedSpells:nil withLastUsedSpells:[PlayerDataManager localPlayer].lastUsedSpells];
    
    [encounter encounterWillBegin];
    GamePlayScene *gps = [[[GamePlayScene alloc] initWithEncounter:encounter player:player] autorelease];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.5 scene:gps]];
}

-(void)pauseLayerDidFinish{
    [self.pauseMenuLayer removeFromParentAndCleanup:YES];
    self.pauseMenuLayer = nil;
    [self setPaused:NO];
}

- (void)pauseLayerDidQuit {
    if (self.matchVoiceChat){
        [self.matchVoiceChat stop];
    }
    [self.pauseMenuLayer removeFromParentAndCleanup:YES];
    self.pauseMenuLayer = nil;  
    [self battleEndWithSuccess:NO];
}

- (void)applicationEnteredBackground {
    [self showPauseMenu];
}

-(void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    [self battleBegin];
}

-(void)ftueLayerDidComplete:(CCNode*)ftueLayer{
    [ftueLayer removeFromParentAndCleanup:YES];
    [self battleBegin];
}

-(void)battleBegin{
    __block GamePlayScene *blockSelf = self;
    CCSprite *startingTimer = [CCSprite spriteWithSpriteFrameName:@"three.png"];
    [startingTimer setPosition:CGPointMake(512, 540)];
    [startingTimer setScale:2.0];
    [startingTimer setOpacity:0];
    [self addChild:startingTimer z:1000];
    
    [startingTimer runAction:[CCSequence actions:
                              [CCSpawn actionOne:[CCScaleTo actionWithDuration:.33 scale:1.0] two:[CCFadeTo actionWithDuration:.33 opacity:255]],
                              [CCCallBlock actionWithBlock:^{
        [blockSelf playAudioForTitle:@"bang1.mp3"];
    }],
                              [CCFadeTo actionWithDuration:1.0 opacity:0],
                              [CCCallBlockN actionWithBlock:^(CCNode *node){
        CCSprite *sprite = (CCSprite*)node;
        [sprite setOpacity:0];
        [sprite setScale:2.0];
        [sprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"two.png"]];
        }],
                              [CCSpawn actionOne:[CCScaleTo actionWithDuration:.33 scale:1.0] two:[CCFadeTo actionWithDuration:.33 opacity:255]],
                              [CCCallBlock actionWithBlock:^{
        [blockSelf playAudioForTitle:@"bang1.mp3"];
    }],
                              [CCFadeTo actionWithDuration:1.0 opacity:0],
                              [CCCallBlockN actionWithBlock:^(CCNode *node){
        CCSprite *sprite = (CCSprite*)node;
        [sprite setOpacity:0];
        [sprite setScale:2.0];
        [sprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"one.png"]];
    }],[CCSpawn actionOne:[CCScaleTo actionWithDuration:.33 scale:1.0] two:[CCFadeTo actionWithDuration:.33 opacity:255]],[CCCallBlock actionWithBlock:^{
        [blockSelf playAudioForTitle:@"bang1.mp3"];
    }],
                              [CCFadeTo actionWithDuration:1.0 opacity:0],
                              [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node removeFromParentAndCleanup:YES];
        [blockSelf.enemiesLayer fadeInAbilities];
        [blockSelf setPaused:NO];
        
    }], nil]];
}

#pragma mark - Battle Completion
- (void)postBattleLayerWillAwardLoot
{
    //We need to clear out the UI and center the scene
    [self.raidView endBattleWithSuccess:YES];
    [self.sceneBackground runAction:[CCMoveTo actionWithDuration:1.0 position:CGPointMake(0, 200)]];
    [self.mainBackground runAction:[CCFadeOut actionWithDuration:1.0]];
    [self.healerPortrait runAction:[CCFadeOut actionWithDuration:1.0]];
    [self.castingEffect removeFromParentAndCleanup:YES];
    [self.playerCastBar removeFromParentAndCleanup:YES];
    [self.playerStatusView removeFromParentAndCleanup:YES];
    [self.spellView1 removeFromParentAndCleanup:YES];
    [self.spellView2 removeFromParentAndCleanup:YES];
    [self.spellView3 removeFromParentAndCleanup:YES];
    [self.spellView4 removeFromParentAndCleanup:YES];
    [self.weaponSpell removeFromParentAndCleanup:YES];
}

- (void)postBattleLayerDidTransitionToScene:(PostBattleLayerDestination)destination asVictory:(BOOL)victory
{
    if (destination == PostBattleLayerDestinationMap) {
        LevelSelectMapScene *qps = [[[LevelSelectMapScene alloc] init] autorelease];
        if (self.encounter.levelNumber >= 5) {
            [qps setComingFromVictory:victory];
        }
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:qps]];
    }
    
    if (destination == PostBattleLayerDestinationShop) {
        ShopScene *shopScene = [[[ShopScene alloc] init] autorelease];
        if ([PlayerDataManager localPlayer].ftueState == FTUEStateBattle1Finished)
        {
            if (![[PlayerDataManager localPlayer] hasSpell:[GreaterHeal defaultSpell]]) {
                [shopScene setRequiresGreaterHealFtuePurchase:YES];
            } else {
                [shopScene setReturnsToMap:YES];
                [PlayerDataManager localPlayer].ftueState = FTUEStateGreaterHealPurchased;
            }
        } else {
            [shopScene setReturnsToMap:YES];
        }
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:shopScene]];
    }
    
    if (destination == PostBattleLayerDestinationTalents) {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[TalentScene alloc] init] autorelease]]];
    }
    
    if (destination == PostBattleLayerDestinationArmory) {
        InventoryScene *is = [[[InventoryScene alloc] init] autorelease];
        [is setReturnsToMap:YES];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:is]];
    }
}

-(void)battleEndWithSuccess:(BOOL)success{    
//    if (success && !(self.isServer || self.isClient) && [NormalModeCompleteScene needsNormalModeCompleteSceneForLevelNumber:self.encounter.levelNumber]){
//        //If we just beat the final boss for the first time, show the normal mode complete Scene
//        NormalModeCompleteScene *nmcs = [[[NormalModeCompleteScene alloc] initWithVictory:success encounter:self.encounter andIsMultiplayer:NO andDuration:self.encounter.duration] autorelease];
//        [self setPaused:YES];
//        [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInT transitionWithDuration:1.0 scene:nmcs]];
//        return;
//    }
    
    [[PlayerDataManager localPlayer] submitScore:self.encounter player:self.player];
    
    [[SimpleAudioEngine sharedEngine] crossFadeBackgroundMusic:nil forDuration:.5];
    if (success) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"sounds/victory.mp3"];
        
        NSArray *happyWords = @[@"Huzzah!", @"Victory!", @"Hooray!", @"Glorious!", @"Well Done!", @"Excellent!", @"Very Good!", @"Grand!", @"Heroic!", @"Marvelous", @"Superb!", @"Brilliant!"];
        for (RaidMemberHealthView *hv in self.raidView.raidViews) {
            if (!hv.member.isDead && ![hv.member isKindOfClass:[Player class]]) {
                [hv displaySCT:[happyWords objectAtIndex:arc4random() % happyWords.count] asCritical:NO color:ccWHITE];
            }
        }
        
    } else {
        [[SimpleAudioEngine sharedEngine] playEffect:@"sounds/defeat.mp3"];
    }
    
    for (CCNode *node in self.children) {
        if (node.tag == PAUSEABLE_TAG) {
            [node setVisible:NO];
        }
    }
    
    [[SimpleAudioEngine sharedEngine] stopEffect:self.ambientBattleKey];
    
    if ([PlayerDataManager localPlayer].ftueState == FTUEStateAbilityIconSelected) {
        [PlayerDataManager localPlayer].ftueState = FTUEStateBattle1Finished;
    }
    
    [self updateUIForTime:0];
    
    [self.playerCastBar runAction:[CCFadeTo actionWithDuration:.5 opacity:0]];
    [self.enemiesLayer endBattle];
    [self.pauseButton setEnabled:NO];
    [self.pauseButton runAction:[CCFadeTo actionWithDuration:.5 opacity:0]];
    [self setPaused:YES];
    if (self.isServer){
        [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"BATTLEEND|%i|", success] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
    }
    
    [self transitionToPostBattleWithSuccess:success];
}

- (void)transitionToPostBattleWithSuccess:(BOOL)success {
    PostBattleLayer *pbl = [[[PostBattleLayer alloc] initWithVictory:success encounter:self.encounter andIsMultiplayer:self.isClient || self.isServer andDuration:self.encounter.duration] autorelease];
    pbl.delegate = self;
    if (self.isServer || self.isClient){
        [pbl setServerPlayerId:self.serverPlayerID];
        [pbl setMatch:self.match];
        [pbl setMatchVoiceChat:self.matchVoiceChat];
    }
    [self addChild:pbl z:500];
}

#pragma mark - Control Input

- (void)notifyServerOfTargetSelection:(RaidMember *)target
{
    if (self.isClient) {
        NSString *networkMessage = [NSString stringWithFormat:@"TRGTSEL|%@", target.networkID];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
}

- (void)thisMemberSelected:(RaidMemberHealthView*)hv
{
	if ([[hv member] isDead]) return;
    if ([PlayerDataManager localPlayer].ftueState == FTUEStateTargetSelected) return;
	if ([self.selectedRaidMembers count] == 0){
		[self.selectedRaidMembers addObject:hv];
		[hv setSelectionState:RaidViewSelectionStateSelected];
        [self checkForFtueSelectionForHealthView:hv];
        [hv.member targetWasSelectedByPlayer:self.player];
        [self notifyServerOfTargetSelection:hv.member];
	}
	else if ([self.selectedRaidMembers objectAtIndex:0] == hv){
		//Here we do nothing because the already selected object has been reselected
	}
	else if ([self.selectedRaidMembers objectAtIndex:0] != hv){
		RaidMemberHealthView *currentTarget = [self.selectedRaidMembers objectAtIndex:0];
		if ([currentTarget isTouched]){
			[self.selectedRaidMembers addObject:hv];
			[hv setSelectionState:RaidViewSelectionStateAltSelected];
		}
		else{
            [currentTarget setSelectionState:RaidViewSelectionStateNone];
			[self.selectedRaidMembers removeObjectAtIndex:0];
			[self.selectedRaidMembers insertObject:hv atIndex:0];
            [hv setSelectionState:RaidViewSelectionStateSelected];
            [hv.member targetWasSelectedByPlayer:self.player];
            [self notifyServerOfTargetSelection:hv.member];
            [self checkForFtueSelectionForHealthView:hv];
		}
		
	}
}

- (void)checkForFtueSelectionForHealthView:(RaidMemberHealthView*)hv
{
    if ([PlayerDataManager localPlayer].ftueState < FTUEStateTargetSelected  && hv.member.health != hv.member.maximumHealth) {
        [PlayerDataManager localPlayer].ftueState = FTUEStateTargetSelected;
        [hv updateHealthForInterval:0];
        [self.ftueLayer clear];
        [self.ftueLayer waitForHeal];
    }
}

- (void)thisMemberUnselected:(RaidMemberHealthView*)hv
{
    if ([[hv member] isDead]) return;
	if (hv != [self.selectedRaidMembers objectAtIndex:0]){
		[self.selectedRaidMembers removeObject:hv];
        [hv setSelectionState:RaidViewSelectionStateNone];
	}
	
}

- (void)spellButtonSelected:(PlayerSpellButton*)spell
{
    if ([[spell spellData] cooldownRemaining] > 0.0){
        return;
    }
    
	if ([self.selectedRaidMembers count] > 0 && [self.selectedRaidMembers objectAtIndex:0] != nil){
		NSMutableArray *targets = [NSMutableArray arrayWithCapacity:[self.selectedRaidMembers count]];
		for (RaidMemberHealthView *healthView in self.selectedRaidMembers){
			[targets addObject:[healthView member]];
		}
        
		if ([[spell spellData] conformsToProtocol:@protocol(Chargable)]){
			if ([self.player spellBeingCast] == nil){
				[(Chargable*)[spell spellData] beginCharging:[NSDate date]];
			}
		}
		else{
            [self.player beginCasting:[spell spellData] withTargets:targets];
            if ([PlayerDataManager localPlayer].ftueState == FTUEStateTargetSelected) {
                [PlayerDataManager localPlayer].ftueState = FTUEStateTargetHealed;
                [self.ftueLayer clear];
                self.paused = NO;
            }
            if (self.isClient){
                NSMutableString *message = [NSMutableString string];
                [message appendFormat:@"BGNSPELL|%@", [[spell spellData] spellID]];
                for (RaidMember *target in targets){
                    [message appendFormat:@"|%@", target.networkId];
                }
                [self.match sendDataToAllPlayers:[message dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
            }
		}
	}
}

- (void)spellButtonUnselected:(PlayerSpellButton*)spell{
    if ([[spell spellData] cooldownRemaining] > 0.0){
        return;
    }
	if ([self.selectedRaidMembers count] > 0 && [self.selectedRaidMembers objectAtIndex:0] != nil){
		NSMutableArray *targets = [NSMutableArray arrayWithCapacity:[self.selectedRaidMembers count]];
		for (RaidMemberHealthView *healthView in self.selectedRaidMembers){
			[targets addObject:[healthView member]];
		}
	
		if ([[spell spellData] conformsToProtocol:@protocol(Chargable)]){
			if ([(Chargable*)[spell spellData] chargeStart] != nil){
				[(Chargable*)[spell spellData] endCharging:[NSDate date]];
				[self.player beginCasting:[spell spellData] withTargets:targets];
			}
		}
	}
}

#pragma mark - Ability Descriptor Behaviors

- (void)abilityDescriptionViewDidSelectAbility:(AbilityDescriptor *)descriptor
{
    if ([PlayerDataManager localPlayer].ftueState == FTUEStateTargetHealed) {
        [PlayerDataManager localPlayer].ftueState = FTUEStateAbilityIconSelected;
        [self.ftueLayer clear];
    }
    else if (self.paused){
        return;
    }
    
    if (self.isServer || self.isClient) {
    } else {
        [self setPaused:YES];
    }
    
    IconDescriptionModalLayer *modalLayer = [[[IconDescriptionModalLayer alloc] initWithAbilityDescriptor:descriptor] autorelease];
    [modalLayer setDelegate:self];
    [self addChild:modalLayer z:9999];
    
    CCLabelTTFShadow *pausedTitle = [CCLabelTTFShadow labelWithString:@"Paused" fontName:@"TrebuchetMS-Bold" fontSize:64.0];
    [pausedTitle setPosition:CGPointMake(512, 570)];
    [modalLayer addChild:pausedTitle];
}

- (void)iconDescriptionModalDidComplete:(id)modal {
    IconDescriptionModalLayer *layer = (IconDescriptionModalLayer*)modal;
    [layer removeFromParentAndCleanup:YES];
    if (self.isServer || self.isClient){
        
    }else {
        [self setPaused:NO];
    }
}

#pragma mark - Announcer Behaviors

- (float)lengthOfVector:(CGPoint)vec{
    return sqrt(pow(vec.x, 2) + pow(vec.y, 2));
}

- (float)rotationFromPoint:(CGPoint)a toPoint:(CGPoint)b{
    CGPoint aToBVector = CGPointMake(b.x - a.x, a.y - b.y);
    return CC_RADIANS_TO_DEGREES(atan2(aToBVector.y, aToBVector.x));
}

- (void)displayScreenShakeForDuration:(float)duration{
    [self displayScreenShakeForDuration:duration afterDelay:0.0];
}

- (void)displayScreenShakeForDuration:(float)duration afterDelay:(float)delay
{
    if (self.isServer) {
        NSString* networkMessage = [NSString stringWithFormat:@"SCRNSHK|%1.4f|%1.4f", duration, delay];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    if (delay > 0) {
        [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:delay], [CCShakeScreen actionWithDuration:duration], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node setPosition:CGPointMake(0, 0)];
        }], nil]];
    } else {
        [self runAction:[CCSequence actions:[CCShakeScreen actionWithDuration:duration], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node setPosition:CGPointMake(0, 0)];
        }], nil] ];
    }
}

- (void)displayParticleSystemOnRaidWithName:(NSString*)name forDuration:(float)duration
{
    [self displayParticleSystemOnRaidWithName:name forDuration:duration offset:CGPointZero];
}

- (void)displayParticleSystemOnRaidWithName:(NSString*)name delay:(float)delay
{
    [self displayParticleSystemOnRaidWithName:name delay:delay offset:CGPointZero];
}

-(void)displayParticleSystemOnRaidWithName:(NSString*)name forDuration:(float)duration offset:(CGPoint)offset{
    if (self.isServer){
        NSString* networkMessage = [NSString stringWithFormat:@"STMON|%@|%1.4f|%1.2f|%1.2f", name, duration, offset.x, offset.y];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCParticleSystemQuad *collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:name];
    CGPoint destination = ccpAdd([self.raidView position], ccp(self.raidView.contentSize.width / 2, self.raidView.contentSize.height /2));
    destination = ccpAdd(destination, offset);
    if (duration != -1.0){
        [collisionEffect setDuration:duration];
    }
    [collisionEffect setPosition:destination];
    [collisionEffect setAutoRemoveOnFinish:YES];
    [self addChild:collisionEffect z:100 tag:PAUSEABLE_TAG];
    
}

- (void)displayParticleSystemOnRaidWithName:(NSString*)name delay:(float)delay offset:(CGPoint)offset
{
    if (delay == 0.0) {
        [self displayParticleSystemOnRaidWithName:name forDuration:0.0 offset:offset];
    } else {
        CCSequence *delayedParticle = [CCSequence actionOne:[CCDelayTime actionWithDuration:delay] two:[CCCallBlockN actionWithBlock:^(CCNode *node){
            GamePlayScene *gps = (GamePlayScene *)node;
            [gps displayParticleSystemOnRaidWithName:name forDuration:0.0 offset:offset];
        }]];
        [self runAction:delayedParticle];
    }
}

-(void)displayParticleSystemOverRaidWithName:(NSString*)name{
    if (self.isServer){
        NSString* networkMessage = [NSString stringWithFormat:@"STMOVER|%@", name];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCParticleSystemQuad *collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:name];
    CGPoint destination = ccpAdd([self.raidView position], ccp(self.raidView.contentSize.width / 2, self.raidView.contentSize.height));
    [collisionEffect setPosition:destination];
    [collisionEffect setAutoRemoveOnFinish:YES];
    [self addChild:collisionEffect z:100 tag:PAUSEABLE_TAG];
}

- (void)displayEnergyGainFrom:(RaidMember*)member
{
    CCSprite *energyBall = [CCSprite spriteWithSpriteFrameName:@"energy_orb.png"];
    [energyBall setScale:.5];
    [energyBall setPosition:[self.raidView frameCenterForMember:member]];
    [self addChild:energyBall z:0 tag:PAUSEABLE_TAG];
    [energyBall runAction:[CCSequence actions:[CCJumpTo actionWithDuration:1.5 position:self.playerStatusView.position height:100 jumps:1],[CCScaleTo actionWithDuration:.33 scale:0.0], [CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}

- (void)displayArcherAttackFromRaidMember:(RaidMember *)member onTarget:(Enemy*)target{
    CCSprite *arrowSprite = [CCSprite spriteWithSpriteFrameName:@"arrow_archer.png"];
    [arrowSprite setScale:.5];
    CGPoint enemyPosition = [self.enemiesLayer spriteCenterForEnemy:target];
    CGPoint position = [self.raidView frameCenterForMember:member];
    CGFloat rotation = [self rotationFromPoint:position toPoint:enemyPosition] + 90.0;
    [arrowSprite setPosition:position];
    [arrowSprite setRotation:rotation];
    [self addChild:arrowSprite z:RAID_Z-1 tag:PAUSEABLE_TAG];
    
    [arrowSprite runAction:[CCSequence actions:[CCJumpTo actionWithDuration:.66 position:enemyPosition height:25 jumps:1],[CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}

- (void)displayWarlockAttackFromRaidMember:(RaidMember *)member onTarget:(Enemy*)target{
    CCSprite *arrowSprite = [CCSprite spriteWithSpriteFrameName:@"poisonbolt_1.png"];
    ProjectileEffect *eff = [[[ProjectileEffect alloc] initWithSpriteName:@"poisonbolt.png" target:nil collisionTime:0 sourceAgent:member] autorelease];
    eff.frameCount = [self frameCountForSpriteName:eff.spriteName];
    CCAnimation *spriteAnimation = [self animationFromProjectileEffect:eff];
    [arrowSprite runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:spriteAnimation]]];
    [arrowSprite setScale:.5];
    CGPoint enemyPosition = [self.enemiesLayer spriteCenterForEnemy:target];
    CGPoint position = [self.raidView frameCenterForMember:member];
    CGFloat rotation = [self rotationFromPoint:position toPoint:enemyPosition] + 270.0;
    [arrowSprite setPosition:position];
    [arrowSprite setRotation:rotation];
    [self addChild:arrowSprite z:RAID_Z-1 tag:PAUSEABLE_TAG];
    
    [arrowSprite runAction:[CCSequence actions:[CCMoveTo actionWithDuration:1.25 position:enemyPosition],[CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}

- (void)displayBerserkerAttackFromRaidMember:(RaidMember *)member onTarget:(Enemy*)target{
    CCParticleSystemQuad *collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:@"pow.plist"];
    CGPoint destination = [self.enemiesLayer spriteCenterForEnemy:target];
    
    void (^completionBlock)(void) = ^{
        [collisionEffect setPosition:destination];
        [collisionEffect setAutoRemoveOnFinish:YES];
        [self addChild:collisionEffect z:100 tag:PAUSEABLE_TAG];
    };
    completionBlock();
}

- (void)displayChampionAttackFromRaidMember:(RaidMember *)member onTarget:(Enemy*)target{
    CCParticleSystemQuad *collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:@"pow.plist"];
    CGPoint destination = [self.enemiesLayer spriteCenterForEnemy:target];
    
    void (^completionBlock)(void) = ^{
        [collisionEffect setPosition:destination];
        [collisionEffect setAutoRemoveOnFinish:YES];
        [self addChild:collisionEffect z:100 tag:PAUSEABLE_TAG];
    };
    completionBlock();
}

- (void)displayHealerAttackFromRaidMember:(RaidMember *)member onTarget:(Enemy*)target
{
    CCSprite *arrowSprite = [CCSprite spriteWithSpriteFrameName:@"light_bolt.png"];
    [arrowSprite setScale:.5];
    CGPoint enemyPosition = [self.enemiesLayer spriteCenterForEnemy:target];
    CGPoint position = [self.raidView frameCenterForMember:member];
    CGFloat rotation = [self rotationFromPoint:position toPoint:enemyPosition] + 270.0;
    [arrowSprite setPosition:position];
    [arrowSprite setRotation:rotation];
    [self addChild:arrowSprite z:RAID_Z-1 tag:PAUSEABLE_TAG];
    
    [arrowSprite runAction:[CCSequence actions:[CCMoveTo actionWithDuration:1.25 position:enemyPosition],[CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}

- (void)displayAttackFromRaidMember:(RaidMember*)member onTarget:(Enemy*)target
{
    if ([member isMemberOfClass:[Archer class]]) {
        [self displayArcherAttackFromRaidMember:member onTarget:target];
    } else if ([member isMemberOfClass:[Champion class]]) {
        [self displayChampionAttackFromRaidMember:member onTarget:target];
    } else if ([member isMemberOfClass:[Warlock class]]) {
        [self displayWarlockAttackFromRaidMember:member onTarget:target];
    } else if ([member isMemberOfClass:[Berserker class]]) {
        [self displayBerserkerAttackFromRaidMember:member onTarget:target];
    } else if ([member isMemberOfClass:[Player class]]) {
        [self displayHealerAttackFromRaidMember:member onTarget:target];
    }
}

- (void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target {
    [self displayParticleSystemWithName:name onTarget:target withOffset:CGPointZero];
}

- (void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target withOffset:(CGPoint)offset delay:(NSTimeInterval)delay
{
    if (self.isServer){
        NSString* networkMessage = [NSString stringWithFormat:@"STMTGT|%@|%@|%1.2f|%1.2f|%1.4f", name, target.networkId, offset.x, offset.y, delay];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCParticleSystemQuad *collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:name];
    CGPoint destination = [self.raidView frameCenterForMember:target];
    
    void (^completionBlock)(void) = ^{
        [collisionEffect setPosition:ccpAdd(destination, offset)];
        [collisionEffect setAutoRemoveOnFinish:YES];
        [self addChild:collisionEffect z:100 tag:PAUSEABLE_TAG];
    };
    
    if (delay > 0) {
        [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:delay] two:[CCCallBlock actionWithBlock:completionBlock]]];
    } else {
        completionBlock();
    }
}

- (void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target withOffset:(CGPoint)offset{
    [self displayParticleSystemWithName:name onTarget:target withOffset:offset delay:0.0];
}

- (void)displayBreathEffectOnRaidForDuration:(float)duration withName:(NSString *)name {
    if (self.isServer) {
        NSString* networkMessage = [NSString stringWithFormat:@"BRTHEFF|%1.4f|%@", duration, name];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCParticleSystemQuad *breathEffect = [[ParticleSystemCache sharedCache] systemForKey:name];
    [breathEffect setDuration:duration];
    [breathEffect setPosition:CGPointMake(512, 700)];
    [self addChild:breathEffect z:100 tag:PAUSEABLE_TAG];
}

- (void)displayScreenFlash
{
    [self.screenFlashLayer setOpacity:255];
    [self.screenFlashLayer runAction:[CCFadeTo actionWithDuration:.25 opacity:0]];
}

- (void)displayCriticalPlayerDamage
{
    [self.gradientBorder flash];
}

- (void)displaySprite:(NSString*)spriteName overRaidForDuration:(float)duration {
    if (!spriteName){
        return;
    }
    if (self.isServer){
        NSString* networkMessage = [NSString stringWithFormat:@"SPRTOV|%@|%1.3f", spriteName, duration];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCSprite *sprite = [CCSprite spriteWithSpriteFrameName:spriteName];
    CGFloat scaleTo = 1.0;
    if ([spriteName isEqualToString:@"shield_bubble.png"]){
        //SPECIAL CASES LULZ!!!! =D
        scaleTo = 5.0;
    }
    [sprite setScale:0.0];
    [sprite setPosition:ccpAdd([self.raidView position], ccp(self.raidView.contentSize.width / 2, self.raidView.contentSize.height/2))];
    [self addChild:sprite z:RAID_Z+1 tag:PAUSEABLE_TAG];
    [sprite runAction:[CCSequence actions:[CCScaleTo actionWithDuration:.33 scale:scaleTo],[CCDelayTime actionWithDuration:duration],[CCFadeOut actionWithDuration:.5] ,[CCCallBlockN actionWithBlock:^(CCNode*node){
        [node removeFromParentAndCleanup:YES];
        
    }], nil]];
    
}

-(void)displayProjectileEffect:(ProjectileEffect*)effect{
    CGPoint origin = CGPointZero;
    
    if ([effect.sourceAgent isKindOfClass:[Enemy class]]) {
        origin = [self.enemiesLayer spriteCenterForEnemy:(Enemy*)effect.sourceAgent];
    }
    [self displayProjectileEffect:effect fromOrigin:origin];
}

- (void)displayProjectileEffect:(ProjectileEffect*)effect fromOrigin:(CGPoint)origin
{
    switch (effect.type) {
        case ProjectileEffectTypeThrow:
            [self displayThrowEffect:effect fromOrigin:origin];
            break;
        default:
            [self displayNormalProjectileEffect:effect fromOrigin:origin];
            break;
    }
}

- (NSInteger)frameCountForSpriteName:(NSString *)spriteName
{
    if ([spriteName isEqualToString:@"fireball.png"]) {
        return 12;
    }
    if ([spriteName isEqualToString:@"shadowbolt.png"]) {
        return 12;
    }
    if ([spriteName isEqualToString:@"poisonbolt.png"]) {
        return 12;
    }
    if ([spriteName isEqualToString:@"bloodbolt.png"]) {
        return 12;
    }
    return 0;
}

- (CCAnimation *)animationFromProjectileEffect:(ProjectileEffect *)effect
{
    NSArray *components = [effect.spriteName componentsSeparatedByString:@"."];
    NSString *extension = @"";
    if (components.count > 1) {
        extension = [components objectAtIndex:1];
    }
    NSString *spriteBaseName = [components objectAtIndex:0];
    
    NSMutableArray *spriteFramesInAnimation = [NSMutableArray arrayWithCapacity:effect.frameCount];
    
    for (int i = 0; i < effect.frameCount; i++) {
        NSString *frameName = [NSString stringWithFormat:@"%@_%i.%@", spriteBaseName, i+1 ,extension];
        CCSpriteFrame * frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:frameName];
        [spriteFramesInAnimation addObject:frame];
    }
    
    CCAnimation *spriteAnimation = [CCAnimation animationWithSpriteFrames:spriteFramesInAnimation delay:1.0/60.0f];
    spriteAnimation.restoreOriginalFrame = NO;
    
    return spriteAnimation;
}

- (void)displayNormalProjectileEffect:(ProjectileEffect *)effect fromOrigin:(CGPoint)origin {
    
    if (self.isServer){
        effect.type = ProjectileEffectTypeNormal;
        [self.match sendDataToAllPlayers:[effect.asNetworkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    
    CCSpriteFrame *spriteFrame = nil;
    effect.frameCount = [self frameCountForSpriteName:effect.spriteName];
    CCAnimation *spriteAnimation = nil;
    if (effect.frameCount > 0) {
        spriteAnimation = [self animationFromProjectileEffect:effect];
        spriteFrame = [[spriteAnimation.frames objectAtIndex:0] spriteFrame];
    } else {
        spriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:effect.spriteName];
    }
    
    CCSprite *projectileSprite = [CCSprite spriteWithSpriteFrame:spriteFrame];
    
    if (spriteAnimation) {
        CCRepeatForever *repeater = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:spriteAnimation]];
        [projectileSprite runAction:repeater];
    }
    
    CGPoint originLocation = origin;
    CGPoint destination = [self.raidView frameCenterForMember:(RaidMember*)effect.target];
    
    if (effect.isFailed){
        destination = [self.raidView randomMissedProjectileDestination];
    }
    CCParticleSystemQuad  *collisionEffect = nil;
    if (effect.collisionParticleName && !effect.isFailed){
        collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:effect.collisionParticleName];
    }
    if (projectileSprite){
        __block GamePlayScene *blockSelf = self;
        [projectileSprite setAnchorPoint:CGPointMake(.5, .5)];
        [projectileSprite setVisible:NO];
        [projectileSprite setPosition:originLocation];
        [projectileSprite setRotation:[self rotationFromPoint:originLocation toPoint:destination] - 90.0];
        [projectileSprite setColor:effect.spriteColor];
        [self addChild:projectileSprite z:RAID_Z+1 tag:PAUSEABLE_TAG];
        [projectileSprite runAction:[CCSequence actions:[CCDelayTime actionWithDuration:effect.delay], [CCCallBlockN actionWithBlock:^(CCNode* node){ node.visible = YES;}], [CCMoveTo actionWithDuration:effect.collisionTime position:destination],[CCSpawn actions:[CCCallBlockN actionWithBlock:^(CCNode *node){
            if (effect.collisionSoundName) {
                [blockSelf playAudioForTitle:effect.collisionSoundName];
            }
            if (collisionEffect){
                [collisionEffect setPosition:destination];
                [collisionEffect setAutoRemoveOnFinish:YES];
                [self addChild:collisionEffect z:100 tag:PAUSEABLE_TAG];
            }
        }], [CCFadeOut actionWithDuration:.05], nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];
        }], nil]];
    }

}

- (void)displayThrowEffect:(ProjectileEffect *)effect fromOrigin:(CGPoint)origin{
    if (self.isServer){
        effect.type = ProjectileEffectTypeThrow;
        [self.match sendDataToAllPlayers:[effect.asNetworkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCSprite *projectileSprite = [CCSprite spriteWithSpriteFrameName:effect.spriteName];;

    CGPoint destination = [self.raidView frameCenterForMember:(RaidMember*)effect.target];
    
    CCParticleSystemQuad  *collisionEffect = nil;
    if (effect.collisionParticleName && !effect.isFailed){
        collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:effect.collisionParticleName];
    }
    
    if (projectileSprite){
        __block GamePlayScene *blockSelf = self;
        [projectileSprite setAnchorPoint:CGPointMake(.5, .5)];
        [projectileSprite setVisible:NO];
        [projectileSprite setPosition:origin];
        [projectileSprite setRotation:CC_RADIANS_TO_DEGREES([self rotationFromPoint:origin toPoint:destination]) + 180.0];
        [projectileSprite setColor:effect.spriteColor];
        [self addChild:projectileSprite z:RAID_Z+1 tag:PAUSEABLE_TAG];
        ccBezierConfig bezierConfig = {destination,ccp(destination.x ,origin.y), ccp(destination.x,origin.y) };
        [projectileSprite runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:.3 angle:360.0]]];
        [projectileSprite runAction:[CCSequence actions:[CCDelayTime actionWithDuration:effect.delay], [CCCallBlockN actionWithBlock:^(CCNode* node){ node.visible = YES;}],[CCSpawn actions:[CCBezierTo actionWithDuration:effect.collisionTime bezier:bezierConfig],nil],[CCSpawn actions:[CCCallBlockN actionWithBlock:^(CCNode *node){
            if (effect.collisionSoundName) {
                [blockSelf playAudioForTitle:effect.collisionSoundName];
            }
            if (collisionEffect){
                [collisionEffect setPosition:destination];
                [collisionEffect setAutoRemoveOnFinish:YES];
                [self addChild:collisionEffect z:100 tag:PAUSEABLE_TAG];
            }
        }],[CCScaleTo actionWithDuration:.33 scale:2.0], [CCFadeOut actionWithDuration:.33], nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];
        }], nil]];
    }
}

- (void)displayCollectible:(Collectible *)collectible
{
    [self.collectibleLayer addCollectible:collectible];
}

- (void)announceFtuePlagueStrike
{
    if ([PlayerDataManager localPlayer].ftueState < FTUEStateAbilityIconSelected) {
        self.paused = YES;
        [self.ftueLayer waitForSelectionOfAbilityIcon];
    }
}

- (void)announceFtueAttack
{
    if ([PlayerDataManager localPlayer].ftueState < FTUEStateTargetSelected) {
        self.paused = YES;
        
        RaidMember *hitMember = nil;
        for (RaidMember *member in self.raid.livingMembers) {
            if (member.health != member.maximumHealth) {
                hitMember = member;
                break;
            }
        }
        
        [self.ftueLayer waitForSelectionOnTargetAtFrame:[self.raidView frameCenterForMember:hitMember]];
    }
}

-(void)announce:(NSString *)announcement{
    if (![self.announcementLabel.string isEqualToString:@""]){
        [self.announcementLabel stopAllActions];
        [self.announcementLabel setString:@""];
        [self.announcementLabel setScale:1.0];
    }
    
    if (self.isServer){
        NSString* annoucementMessage = [NSString stringWithFormat:@"ANNC|%@", announcement];
        [self.match sendDataToAllPlayers:[annoucementMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
    }
    
    [self.announcementLabel setVisible:YES];
    [self.announcementLabel setString:announcement];
    [self.announcementLabel runAction:[CCSequence actions:[CCScaleTo actionWithDuration:.3 scale:1.5], [CCScaleTo actionWithDuration:.3 scale:1.0],[CCDelayTime actionWithDuration:3.0], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node setVisible:NO];
        [(CCLabelTTF*)node setString:@""];
    }],nil]];
    
}

-(void)errorAnnounce:(NSString*)announcement{
    [self.errAnnouncementLabel stopAllActions];
    [self.errAnnouncementLabel setVisible:YES];
    [self.errAnnouncementLabel setString:announcement];
    [self.errAnnouncementLabel runAction:[CCSequence actions:[CCScaleTo actionWithDuration:.2 scale:1.25], [CCScaleTo actionWithDuration:.33 scale:1.0],[CCDelayTime actionWithDuration:.5], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node setVisible:NO];
        [(CCLabelTTF*)node setString:@""];
    }],nil]];
}

-(void)announcePlayerInterrupted
{
    [self.playerCastBar displayInterruption];
}

#pragma mark - Audio

- (void)preloadAudioWithTitle:(NSString *)title {
    NSString *audioPath = [@"sounds" stringByAppendingPathComponent:title];
    [[SimpleAudioEngine sharedEngine] preloadEffect:audioPath];
}

- (void)preloadSpellAudio:(Spell*)spell
{
    [self preloadAudioWithTitle:spell.beginCastingAudioTitle];
    [self preloadAudioWithTitle:spell.endCastingAudioTitle];
    [self preloadAudioWithTitle:spell.interruptedAudioTitle];
}

- (void)playAudioForTitle:(NSString *)title
{
    [self playAudioForTitle:title randomTitles:0 afterDelay:0];
}

- (void)playAudioForTitle:(NSString *)title afterDelay:(NSTimeInterval)delay
{
    [self playAudioForTitle:title randomTitles:0 afterDelay:delay];
}

- (void)playAudioForTitle:(NSString *)title randomTitles:(NSInteger)numRandoms afterDelay:(NSTimeInterval)delay
{
    if (delay) {
        [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:delay] two:[CCCallBlockN actionWithBlock:^(CCNode*node){
            GamePlayScene *gps = (GamePlayScene*)node;
            [gps playAudioForTitle:title];
        }]]];
        return;
    }
    NSString *finalTitle = title;
    NSInteger presetRandomCount = [[self.randomTitlesPresetDictionary objectForKey:title] intValue];
    if (presetRandomCount > 0) {
        numRandoms = presetRandomCount;
    }
    if (numRandoms > 0) {
        NSArray *components = [title componentsSeparatedByString:@"."];
        finalTitle = [NSString stringWithFormat:@"%@%i.%@", [components objectAtIndex:0], arc4random() % numRandoms + 1, [components objectAtIndex:1]];
    }
    
    NSString *audioPath = [@"sounds" stringByAppendingPathComponent:finalTitle];
    ALuint sound = [[SimpleAudioEngine sharedEngine] playEffect:audioPath];
    [self.effectsPlayedThisSession addObject:audioPath];
    [self.playingSoundsDict setObject:[NSNumber numberWithUnsignedInt:sound] forKey:title];
}

- (void)stopAudioForTitle:(NSString *)title
{
    NSNumber *number = [self.playingSoundsDict objectForKey:title];
    if (number) {
        ALuint sound = [number unsignedIntValue];
        [[SimpleAudioEngine sharedEngine] stopEffect:sound];
        [self.playingSoundsDict removeObjectForKey:title];
    }
}

-(void)logEvent:(CombatEvent *)event{
    [self.encounter.combatLog addObject:event];
    
    if (event.type == CombatEventTypeDodge){
        RaidMember *dodgedTarget = (RaidMember*)event.target;
        [[self.raidView healthViewForMember:dodgedTarget] displaySCT:@"Dodge" asCritical:NO color:ccYELLOW];
    }
    
    if (event.type == CombatEventTypeHeal){
        RaidMember *healedTarget = (RaidMember*)event.target;
        NSInteger healingAmount = event.value.intValue;
        [[self.raidView healthViewForMember:healedTarget] displaySCT:[NSString stringWithFormat:@"+%i",healingAmount] asCritical:event.critical];
    }
    
    if (event.type == CombatEventTypePlayerInterrupted) {
        if (self.isServer){
            NSString* playerId = [(Player*)event.target playerID];
            if (playerId) {
                [self.match sendData:[[NSString stringWithFormat:@"INTERP|%1.3f", [[event value] floatValue]] dataUsingEncoding:NSUTF8StringEncoding] toPlayers:[NSArray arrayWithObject:playerId] withDataMode:GKMatchSendDataReliable error:nil];
            }
        
        }
    }
    
    if (event.type == CombatEventTypeMemberDied) {
        if ([event.source isKindOfClass:[Archer class]]) {
            [self playAudioForTitle:@"archer_hurt.mp3"];
        } else if ([event.source isKindOfClass:[Guardian class]] || [event.source isKindOfClass:[Champion class]]) {
            [self playAudioForTitle:@"champion_hurt.mp3"];
        } else if ([event.source isKindOfClass:[Berserker class]]) {
            [self playAudioForTitle:@"berserker_hurt.mp3"];
        } else if ([event.source isKindOfClass:[Wizard class]] || [event.source isKindOfClass:[Warlock class]]) {
            [self playAudioForTitle:@"wizard_hurt.mp3"];
        }
        
    }
}

- (GLubyte)opacityForHealthPercentage:(float)percentage
{
    return MIN(255, MAX(0, (int)(255 * pow(1.0-self.player.healthPercentage, 2.5))));
}

#pragma mark - Game Loop

-(void)gameEvent:(ccTime)deltaT
{
    BOOL isNetworkUpdate = NO;
    self.encounter.duration += deltaT;
    self.networkThrottle ++;
    
    if (!self.ambientBattleKey) {
        self.ambientBattleKey = [[SimpleAudioEngine sharedEngine] playEffect:AMBIENT_BATTLE_LOOP pitch:1.0 pan:0.0 gain:.25 loops:YES];
    }

    
    NSMutableArray *focusTargets = [NSMutableArray arrayWithCapacity:self.encounter.enemies.count];
    if (self.networkThrottle >= NETWORK_THROTTLE){
        isNetworkUpdate = YES;
        self.networkThrottle = 0;
    }
    if (self.isServer || (!self.isServer && !self.isClient)){
        //Only perform the simulation if we are not the server
        //Data Events
        
        for (Enemy *enemy in self.encounter.enemies) {
            [enemy combatUpdateForPlayers:self.players enemies:self.encounter.enemies theRaid:self.encounter.raid gameTime:deltaT];
            if (enemy.target) {
                [focusTargets addObject:enemy.target];
            }
        }
        if ([self.playerMoveButton isMoving]){
            [self.player disableCastingWithReason:CastingDisabledReasonMoving];
        }
        else {
            [self.player enableCastingWithReason:CastingDisabledReasonMoving];
        }
    }
    
    [self.encounter scoreTick:deltaT];
    
    if (self.isServer){
        if (isNetworkUpdate){
            //TODO: Need to handle multiple enemies over the network
//            [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"BOSSHEALTH|%i", self.boss.health] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
            
            for (RaidMember *member in self.raid.raidMembers){
                [self.match sendDataToAllPlayers:[[member asNetworkMessage] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
            }
        }
    }else{
        
    }
    
    if (!self.gradientBorder.isFlashing) {
        [self.gradientBorder setOpacity:[self opacityForHealthPercentage:self.player.healthPercentage]];
    }
    
    if (self.isServer){
        for (int i = 1; i < self.players.count; i++){
            Player *clientPlayer = [self.players objectAtIndex:i];
            [clientPlayer combatUpdateForPlayers:self.players enemies:self.encounter.enemies theRaid:self.encounter.raid gameTime:deltaT];
            if (isNetworkUpdate){
                NSArray *playerToNotify = [NSArray arrayWithObject:clientPlayer.playerID];
                [self.match sendData:[[clientPlayer asNetworkMessage] dataUsingEncoding:NSUTF8StringEncoding]  toPlayers:playerToNotify withDataMode:GKMatchSendDataReliable error:nil];
            }
        }
    }
    
    [self updateUIForTime:deltaT];
	
    
	//Determine if there will be another iteration of the gamestate
    NSArray *raidMembers = [self.raid raidMembers];
    NSInteger survivors = 0;
    
    BOOL areAllEnemiesDefeated = YES;
    
    for (RaidMember *member in raidMembers)
    {
        [member setIsFocused:[focusTargets containsObject:member]];
        [member combatUpdateForPlayers:self.players enemies:self.encounter.enemies theRaid:self.encounter.raid gameTime:deltaT];
        if (![member isDead]){
            survivors++;
        }
    }
    
    for (Enemy *enemy in self.encounter.enemies) {
        areAllEnemiesDefeated &= enemy.isDead;
    }
    
    if (DEBUG_WIN_IMMEDIATELY) {
        areAllEnemiesDefeated = YES;
    }
    
    if (!self.isClient){
        if (survivors == 0)
        {
            [self battleEndWithSuccess:NO];
        }
        if (areAllEnemiesDefeated){
            [self battleEndWithSuccess:YES];
        }
    }
}

- (void)updateUIForTime:(ccTime)deltaT
{
    [self.raidView updateRaidHealthWithPlayer:self.player andTimeDelta:deltaT];
	[self.bossHealthView updateHealth];
	[self.playerCastBar update];
	[self.playerStatusView updateWithPlayer:self.player];
	[self.alertStatus setString:[self.player statusText]];
	[self.spellView1 updateUI];
	[self.spellView2 updateUI];
	[self.spellView3 updateUI];
	[self.spellView4 updateUI];
    [self.weaponSpell updateUI];
    [self.enemiesLayer update];
    [self.collectibleLayer updateAllCollectibles:deltaT];
}

-(void)beginChanneling{
	[self.player startChanneling];
}

-(void)endChanneling{
	[self.player stopChanneling];
}

#pragma mark GKMatchDelegate

-(BOOL)isServer{
    if (![GKLocalPlayer localPlayer].playerID){
        return NO;
    }
    return [GKLocalPlayer localPlayer].playerID == self.serverPlayerID;
}

-(void)setIsClient:(BOOL)isCli forServerPlayerId:(NSString *)srverPid{
    _isClient = isCli;
    self.serverPlayerID = srverPid;
}

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {    
    if (self.match != theMatch) return;
    
    NSString* message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (self.isClient){
        
        if ([message hasPrefix:@"BATTLEEND|"]){
            [self battleEndWithSuccess:[[message substringToIndex:10] boolValue]];
        }
        if ([message hasPrefix:@"BOSSHEALTH|"]){
            //TODO: Handle bosses with network pointers
        }
        
        if ([message hasPrefix:@"PLYR"]){
            [self.player updateWithNetworkMessage:message];
        }
        
        if ([message hasPrefix:@"RDMBR|"]){
            NSArray *messageComponents = [message componentsSeparatedByString:@"|"];
            
            NSString* battleID = [messageComponents objectAtIndex:1];

            [[self.raid memberForNetworkId:battleID] updateWithNetworkMessage:message];
        }
        
        if ([message hasPrefix:@"ANNC|"]){
            [self announce:[message substringFromIndex:5]];
        }
        
        if ([message hasPrefix:@"PRJEFF|"]){
            [self handleProjectileEffectMessage:message];
        }
        
        if ([message hasPrefix:@"STMOVER|"]){
            [self displayParticleSystemOverRaidWithName:[message substringFromIndex:8]];
        }
        
        if ([message hasPrefix:@"STMON|"]){
            NSArray *components = [message componentsSeparatedByString:@"|"];

            [self displayParticleSystemOnRaidWithName:[components objectAtIndex:1] forDuration:[[components objectAtIndex:2] floatValue] offset:CGPointMake([[components objectAtIndex:3] floatValue], [[components objectAtIndex:4] floatValue])];
        }
        
        if ([message hasPrefix:@"STMTGT|"]){
            NSArray *components = [message componentsSeparatedByString:@"|"];
            [self displayParticleSystemWithName:[components objectAtIndex:1] onTarget:[self.raid memberForNetworkId:[components objectAtIndex:2]] withOffset:CGPointMake([[components objectAtIndex:3] floatValue], [[components objectAtIndex:4] floatValue]) delay:[[components objectAtIndex:5] floatValue]];
        }
        
        if ([message hasPrefix:@"SPRTOV|"]){
            NSArray *components = [message componentsSeparatedByString:@"|"];
            [self displaySprite:[components objectAtIndex:1] overRaidForDuration:[[components objectAtIndex:2] floatValue]];
        }
        
        if ([message hasPrefix:@"INTERP|"]){
            NSArray *components = [message componentsSeparatedByString:@"|"];
            if ([self.player spellBeingCast]){
                [[self.player spellBeingCast] applyTemporaryCooldown:[[components objectAtIndex:1] floatValue]];
            }
            [self.player interrupt];
        }
        
        if ([message hasPrefix:@"BRTHEFF"]) {
            NSArray *components = [message componentsSeparatedByString:@"|"];
            [self displayBreathEffectOnRaidForDuration:[[components objectAtIndex:1] floatValue] withName:[components objectAtIndex:2]];
        }
        
        if ([message hasPrefix:@"SCRNSHK"]) {
            NSArray *components = [message componentsSeparatedByString:@"|"];
            [self displayScreenShakeForDuration:[[components objectAtIndex:1] floatValue] afterDelay:[[components objectAtIndex:2] floatValue]];
        }
    }
    
    if (self.isServer){
        if ([message hasPrefix:@"BGNSPELL|"]){
            //A client has told us they started casting a spell
            [self handleSpellBeginMessage:message fromPlayer:playerID];
        }
        
        if ([message hasPrefix:@"TRGTSEL"]) {
            NSArray *components = [message componentsSeparatedByString:@"|"];

            RaidMember *member = [self.raid memberForNetworkId:[components objectAtIndex:1]];
            [member targetWasSelectedByPlayer:[self playerForPlayerId:playerID]];
        }
    }
    [message release];
}

- (Player *)playerForPlayerId:(NSString *)playerId
{
    for (Player *candidate in self.players){
        if ([candidate.playerID isEqualToString:playerId]){
            return candidate;
        }
    }
    
    NSLog(@"FAILED TO FIND SENDER! =(");
    return nil;
}

- (void)handleProjectileEffectMessage:(NSString*)message{
    ProjectileEffect *effect = [[[ProjectileEffect alloc] initWithNetworkMessage:message raid:self.raid enemies:self.encounter.enemies] autorelease];
    [self displayProjectileEffect:effect];
}

- (void)handleSpellBeginMessage:(NSString*)message fromPlayer:(NSString*)playerID{
    NSArray *messageComponents = [message componentsSeparatedByString:@"|"];
    Player *sender = [self playerForPlayerId:playerID];
    Spell *chosenSpell = nil;
    
    for (Spell *candidate in sender.activeSpells){
        if ([candidate.spellID isEqualToString:[messageComponents objectAtIndex:1]]){
            chosenSpell = candidate; break;
        }
    }
    if (!chosenSpell){
        NSAssert(chosenSpell, @"Failed to find the spell in active spells.");
    }
    
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:3];
    if (messageComponents.count > 2){
        for (int i = 2; i < messageComponents.count; i++){
            RaidMember *member = [self.raid memberForNetworkId:[messageComponents objectAtIndex:i]];
            if (member){
                [targets addObject:member];
            }else{
                NSLog(@"INVALID SPELL TARGET RECEIVED");
            }
        }
        if (targets.count > 0){
            sender.spellTarget = [targets objectAtIndex:0];
        }else{
            NSLog(@"MALFORMED SPELL MESSAGE: %@", message);
        }
    }
    
    [sender beginCasting:chosenSpell withTargets:targets];
}

// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {   
    if (self.match != theMatch) return;
    
    switch (state) {
        case GKPlayerStateConnected: 
            // handle a new player connection.
            NSLog(@"Player connected!");
            
            break; 
        case GKPlayerStateDisconnected:
            // a player just disconnected.
            [self announce:@"Player Disconnected"];
            NSLog(@"Player disconnected!");
            //[delegate matchEnded];
            break;
    }                     
}

// The match was unable to connect with the player due to an error.
- (void)match:(GKMatch *)theMatch connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error {
    
    if (self.match != theMatch) return;
    
    NSLog(@"Failed to connect to player with error: %@", error.localizedDescription);
    //[delegate matchEnded];
}

// The match was unable to be established with any players due to an error.
- (void)match:(GKMatch *)theMatch didFailWithError:(NSError *)error {
    
    if (self.match != theMatch) return;
    
    NSLog(@"Match failed with error: %@", error.localizedDescription);
}

@end

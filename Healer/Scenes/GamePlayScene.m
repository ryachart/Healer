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
#import "SimpleAudioEngine.h"
#import "CocosDenshion.h"
#import "CDAudioManager.h"

#define DEBUG_AUTO_WIN false

#define RAID_Z 5
#define PAUSEABLE_TAG 812

#define NETWORK_THROTTLE 5

@interface GamePlayScene ()
//Data Models
@property (nonatomic, readwrite) BOOL paused;
@property (nonatomic, retain) Encounter *encounter;
@property (nonatomic, readonly) Raid *raid;
@property (nonatomic, readonly) Boss *boss;
@property (nonatomic, readonly) Player *player;
@property (nonatomic, assign) CCLabelTTFShadow *announcementLabel;
@property (nonatomic, assign) CCLabelTTF *errAnnouncementLabel;
@property (nonatomic, retain) GamePlayPauseLayer *pauseMenuLayer;
@property (nonatomic, readwrite) NSInteger networkThrottle;
@property (nonatomic, readwrite) GradientBorderLayer *gradientBorder;
@property (nonatomic, retain) NSMutableDictionary *playingSoundsDict;

-(void)battleBegin;
-(void)showPauseMenu;

-(void)handleProjectileEffectMessage:(NSString*)message;
-(void)handleSpellBeginMessage:(NSString*)message fromPlayer:(NSString*)playerID;
@end

@implementation GamePlayScene
@synthesize raidView;
@synthesize spellView1, spellView2, spellView3, spellView4;
@synthesize bossHealthView, playerEnergyView, playerMoveButton, playerCastBar;
@synthesize alertStatus;
@synthesize announcementLabel;
@synthesize errAnnouncementLabel;
@synthesize paused;
@synthesize pauseMenuLayer;
@synthesize match, isClient, isServer, players, networkThrottle, matchVoiceChat, serverPlayerID;

- (void)dealloc {
    [spellView1 release];
    [spellView2 release];
    [spellView3 release];
    [spellView4 release];
    [raidView release];
    [bossHealthView release];
    [playerEnergyView release];
    [playerMoveButton release];
    [playerCastBar release];
    [alertStatus release];
    [serverPlayerID release];
    [match release];
    [matchVoiceChat release];
    [players release];
    [selectedRaidMembers release];
    [_encounter release];
    [pauseMenuLayer release];
    [_playingSoundsDict release];
    [super dealloc];
}

- (Player*)player{
    return [self.players objectAtIndex:0];
}

- (Raid*)raid
{
    return self.encounter.raid;
}

- (Boss*)boss
{
    return (Boss*)[self.encounter.enemies objectAtIndex:0];
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
        
        [self.encounter encounterWillBegin];
        
        NSAssert(self.players.count > 0, @"A Battle with no players was initiated.");
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/battle-sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/effect-sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/postbattle.plist"];
        
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:[Encounter backgroundPathForEncounter:self.encounter.levelNumber]] autorelease]];

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
        
        paused = YES;
        [self.boss setLogger:self];
        [self.boss setAnnouncer:self];
        [self.player setLogger:self];
        [self.player setAnnouncer:self];
        [self.player initializeForCombat];
        
        self.players = [NSArray arrayWithObject:self.player];
        
        self.raidView = [[[RaidView alloc] init] autorelease];
        [self.raidView setPosition:CGPointMake(50, 150)];
        [self.raidView setContentSize:CGSizeMake(500, 400)];
        [self addChild:self.raidView z:RAID_Z];
        
        self.bossHealthView = [[[BossHealthView alloc] initWithFrame:CGRectMake(180, 646, 884, 80) andBossKey:self.encounter.bossKey] autorelease];
        [self.bossHealthView setDelegate:self];
        
        self.playerCastBar = [[[PlayerCastBar alloc] initWithFrame:CGRectMake(312,40, 400, 50)] autorelease];
        self.playerEnergyView = [[[PlayerStatusView alloc] initWithFrame:CGRectMake(804, 485, 200, 50)] autorelease];
        
        self.playerMoveButton = [[[PlayerMoveButton alloc] initWithFrame:CGRectMake(-70, 0, 50, 50)] autorelease];
        [self.playerCastBar addChild:self.playerMoveButton];
        
        self.announcementLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(500, 300) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        [self.announcementLabel setPosition:CGPointMake(512, 440)];
        [self.announcementLabel setColor:ccYELLOW];
        [self.announcementLabel setVisible:NO];
        
        self.errAnnouncementLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(500, 300) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        [self.errAnnouncementLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .5, [CCDirector sharedDirector].winSize.height * .62)];
        [self.errAnnouncementLabel setColor:ccRED];
        [self.errAnnouncementLabel setVisible:NO];
        
        [self addChild:self.bossHealthView z:RAID_Z+1];
        [self addChild:self.playerCastBar];
        [self addChild:self.playerEnergyView];
        [self addChild:self.announcementLabel z:100 tag:PAUSEABLE_TAG];
        [self addChild:self.errAnnouncementLabel z:98 tag:PAUSEABLE_TAG];
        //CACHE SOUNDS
        
        for (int i = 0; i < 4; i++){
            switch (i) {
                case 0:
                    self.spellView1 = [[[PlayerSpellButton alloc] initWithFrame:CGRectMake(910, 370, 100, 100)] autorelease];
                    if (self.player.activeSpells.count > i) {
                        Spell *spell = [[self.player activeSpells] objectAtIndex:i];
                        [self preloadSpellAudio:spell];
                        [self.spellView1 setSpellData:spell];
                        [self.spellView1 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                        [self.spellView1 setPlayer:self.player];
                    }
                    [self addChild:self.spellView1];
                    break;
                case 1:
                    self.spellView2 = [[[PlayerSpellButton alloc] initWithFrame:CGRectMake(910, 265, 100, 100)] autorelease];
                    if (self.player.activeSpells.count > i) {
                        Spell *spell = [[self.player activeSpells] objectAtIndex:i];
                        [self preloadSpellAudio:spell];
                        [self.spellView2 setSpellData:spell];
                        [self.spellView2 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                        [self.spellView2 setPlayer:self.player];
                    }
                    [self addChild:self.spellView2];
                    break;
                case 2:
                    self.spellView3 = [[[PlayerSpellButton alloc] initWithFrame:CGRectMake(910, 160, 100, 100)] autorelease];
                    if (self.player.activeSpells.count > i) {
                        Spell *spell = [[self.player activeSpells] objectAtIndex:i];
                        [self preloadSpellAudio:spell];
                        [self.spellView3 setSpellData:spell];
                        [self.spellView3 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                        [self.spellView3 setPlayer:self.player];
                    }
                    [self addChild:self.spellView3];
                    break;
                case 3:
                    self.spellView4 = [[[PlayerSpellButton alloc] initWithFrame:CGRectMake(910, 55, 100, 100)] autorelease];
                    if (self.player.activeSpells.count > i) {
                        Spell *spell = [[self.player activeSpells] objectAtIndex:i];
                        [self preloadSpellAudio:spell];
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
        
        for (Player *player in self.players) {
            [self.raid addPlayer:player];
        }
        
        [raidView spawnRects];
        NSArray *raidMembers = [self.raid raidMembers];
        selectedRaidMembers = [[NSMutableArray alloc] initWithCapacity:5];
        for (RaidMember *member in raidMembers)
        {
            [member setLogger:self];
            [member setAnnouncer:self];
            RaidMemberHealthView *rmhv = [[[RaidMemberHealthView alloc] initWithFrame:[raidView vendNextUsableRect]] autorelease];
            [rmhv setMemberData:member];
            [rmhv setInteractionDelegate:(RaidMemberHealthViewDelegate*)self];
            [raidView addRaidMemberHealthView:rmhv];
        }
        [bossHealthView setBossData:self.boss];
        
        //The timer has to be scheduled after all the init is done!
        BasicButton *menuButtonItem = [BasicButton basicButtonWithTarget:self andSelector:@selector(showPauseMenu) andTitle:@"Pause"];
        [menuButtonItem setScale:.6];
        CCMenu *menuButton = [CCMenu menuWithItems:menuButtonItem, nil];
        [menuButton setPosition:CGPointMake(86, [CCDirector sharedDirector].winSize.height * .9325)];
        [self addChild:menuButton];
        
        self.networkThrottle = 0;
	}
    return self;
}

-(void)setPaused:(BOOL)newPaused{
    
    if (self.paused == newPaused)
        return;
    
    paused = newPaused;
    
    if (self.isClient || self.isServer){
        if (paused == YES){
            return; //Cant pause multiplayerg
        }
    }
    
    if (self.paused){
        for (CCNode *node in self.children) {
            if (node.tag == PAUSEABLE_TAG) {
                [node pauseSchedulerAndActions];
            }
        }
        [self unschedule:@selector(gameEvent:)];
    }else{
        for (CCNode *node in self.children) {
            if (node.tag == PAUSEABLE_TAG) {
                [node resumeSchedulerAndActions];
            }
        }
        [self schedule:@selector(gameEvent:)];
    }
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

-(void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    if (self.encounter.levelNumber == 1){
        [self gameEvent:0.0]; //Bump the UI
        GamePlayFTUELayer *gpfl = [[[GamePlayFTUELayer alloc] init] autorelease];
        [gpfl setDelegate:self];
        [self addChild:gpfl z:1000];
        [gpfl showWelcome];
    }else{
        [self gameEvent:0.0]; //Bump the UI
        [self battleBegin];
    }
}

-(void)ftueLayerDidComplete:(CCNode*)ftueLayer{
    [ftueLayer removeFromParentAndCleanup:YES];
    [self battleBegin];
}

-(void)battleBegin{
    self.announcementLabel.visible = YES;
    __block GamePlayScene *blockSelf = self;
    [blockSelf runAction:[CCSequence actions:
                          [CCCallBlock actionWithBlock:^(){
        [blockSelf.announcementLabel setString:@"Battle Begins in 3"];
    }], 
                          [CCDelayTime actionWithDuration:1.0], 
                          [CCCallBlock actionWithBlock:^(){
        [blockSelf.announcementLabel setString:@"Battle Begins in 2"];
    }], [CCDelayTime actionWithDuration:1.0],
                          [CCCallBlock actionWithBlock:^(){
        [blockSelf.announcementLabel setString:@"Battle Begins in 1"];
    }], [CCDelayTime actionWithDuration:1.0], [CCCallBlock actionWithBlock:^{
        blockSelf.announcementLabel.visible = NO;
        blockSelf.announcementLabel.string = @"";
        [blockSelf setPaused:NO];
    }], nil]];
}

-(void)battleEndWithSuccess:(BOOL)success{    
    if (success && !(self.isServer || self.isClient) && [NormalModeCompleteScene needsNormalModeCompleteSceneForLevelNumber:self.encounter.levelNumber]){
        //If we just beat the final boss for the first time, show the normal mode complete Scene
        NormalModeCompleteScene *nmcs = [[[NormalModeCompleteScene alloc] initWithVictory:success encounter:self.encounter andIsMultiplayer:NO andDuration:self.boss.duration] autorelease];
        [self setPaused:YES];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInT transitionWithDuration:1.0 scene:nmcs]];
        return;
    }

    [self setPaused:YES];
    if (self.isServer){
        [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"BATTLEEND|%i|", success] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
    }
    
    //UNTIL I FINISH THIS EXPERIENCE
    [self transitionToPostBattleWithSuccess:success];
    return;

    ccTime totalTime = 8.0;
    ccTime fadeTime = 2.0;
    
    for (CCNode *child in self.children) {
        if (child.tag == PAUSEABLE_TAG) {
            if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
                [child resumeSchedulerAndActions];
                [child runAction:[CCFadeOut actionWithDuration:fadeTime]];
            } else {
                [child setVisible:NO];
            }
        }
    }
    
    [self.spellView1 setIsTouchEnabled:NO];
    [self.spellView1 runAction:[CCFadeOut actionWithDuration:fadeTime]];
    [self.spellView2 setIsTouchEnabled:NO];
    [self.spellView2 runAction:[CCFadeOut actionWithDuration:fadeTime]];
    [self.spellView3 setIsTouchEnabled:NO];
    [self.spellView3 runAction:[CCFadeOut actionWithDuration:fadeTime]];
    [self.spellView4 setIsTouchEnabled:NO];
    [self.spellView4 runAction:[CCFadeOut actionWithDuration:fadeTime]];
    
    [self.playerCastBar runAction:[CCFadeOut actionWithDuration:fadeTime]];
    [self.playerEnergyView runAction:[CCFadeOut actionWithDuration:fadeTime]];
    
    [self.raidView endBattleWithSuccess:success];
    [self.bossHealthView endBattleWithSuccess:success];
    
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:totalTime], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [(GamePlayScene*)node transitionToPostBattleWithSuccess:success];
    }], nil]];
}

- (void)transitionToPostBattleWithSuccess:(BOOL)success {
    PostBattleScene *pbs = [[[PostBattleScene alloc] initWithVictory:success encounter:self.encounter andIsMultiplayer:self.isClient || self.isServer andDuration:self.boss.duration] autorelease];
    if (self.isServer || self.isClient){
        [pbs setServerPlayerId:self.serverPlayerID];
        [pbs setMatch:self.match];
        [pbs setMatchVoiceChat:self.matchVoiceChat];
    }
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:pbs]];

}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

-(void)thisMemberSelected:(RaidMemberHealthView*)hv
{
	if ([[hv memberData] isDead]) return;
	if ([selectedRaidMembers count] == 0){
		[selectedRaidMembers addObject:hv];
		[hv setSelectionState:RaidViewSelectionStateSelected];
	}
	else if ([selectedRaidMembers objectAtIndex:0] == hv){
		//Here we do nothing because the already selected object has been reselected
	}
	else if ([selectedRaidMembers objectAtIndex:0] != hv){
		RaidMemberHealthView *currentTarget = [selectedRaidMembers objectAtIndex:0];
		if ([currentTarget isTouched]){
			[selectedRaidMembers addObject:hv];
			[hv setSelectionState:RaidViewSelectionStateAltSelected];
		}
		else{
            [currentTarget setSelectionState:RaidViewSelectionStateNone];
			[selectedRaidMembers removeObjectAtIndex:0];
			[selectedRaidMembers insertObject:hv atIndex:0];
            [hv setSelectionState:RaidViewSelectionStateSelected];
		}
		
	}
}

-(void)thisMemberUnselected:(RaidMemberHealthView*)hv
{
    if ([[hv memberData] isDead]) return;
	if (hv != [selectedRaidMembers objectAtIndex:0]){
		[selectedRaidMembers removeObject:hv];
        [hv setSelectionState:RaidViewSelectionStateNone];
	}
	
}

-(void)spellButtonSelected:(PlayerSpellButton*)spell
{
    if ([[spell spellData] cooldownRemaining] > 0.0){
        return;
    }
    
	if ([selectedRaidMembers count] > 0 && [selectedRaidMembers objectAtIndex:0] != nil){
		NSMutableArray *targets = [NSMutableArray arrayWithCapacity:[selectedRaidMembers count]];
		for (RaidMemberHealthView *healthView in selectedRaidMembers){
			[targets addObject:[healthView memberData]];
		}
        
		if ([[spell spellData] conformsToProtocol:@protocol(Chargable)]){
			if ([self.player spellBeingCast] == nil){
				[(Chargable*)[spell spellData] beginCharging:[NSDate date]];
			}
		}
		else{
            [self.player beginCasting:[spell spellData] withTargets:targets];
            if (self.isClient){
                NSMutableString *message = [NSMutableString string];
                [message appendFormat:@"BGNSPELL|%@", [[spell spellData] spellID]];
                for (RaidMember *target in targets){
                    [message appendFormat:@"|%@", target.battleID];
                }
                [match sendDataToAllPlayers:[message dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
            }
		}
	}
}

-(void)spellButtonUnselected:(PlayerSpellButton*)spell{
    if ([[spell spellData] cooldownRemaining] > 0.0){
        return;
    }
	if ([selectedRaidMembers count] > 0 && [selectedRaidMembers objectAtIndex:0] != nil){
		NSMutableArray *targets = [NSMutableArray arrayWithCapacity:[selectedRaidMembers count]];
		for (RaidMemberHealthView *healthView in selectedRaidMembers){
			[targets addObject:[healthView memberData]];
		}
	
		if ([[spell spellData] conformsToProtocol:@protocol(Chargable)]){
			if ([(Chargable*)[spell spellData] chargeStart] != nil){
				[(Chargable*)[spell spellData] endCharging:[NSDate date]];
				[self.player beginCasting:[spell spellData] withTargets:targets];
			}
		}
	}
}

- (void)bossHealthViewShouldDisplayAbility:(AbilityDescriptor *)ability {
    if (self.paused){
        return;
    }
    
    if (self.isServer || self.isClient) {
    } else {
        [self setPaused:YES];
    }
    
    AbilityDescriptionModalLayer *modalLayer = [[AbilityDescriptionModalLayer alloc] initWithAbilityDescriptor:ability];
    [modalLayer setDelegate:self];
    [self addChild:modalLayer z:9999];
    [modalLayer release];
}

- (void)abilityDescriptorModaldidComplete:(id)modal {
    AbilityDescriptionModalLayer *layer = (AbilityDescriptionModalLayer*)modal;
    [layer removeFromParentAndCleanup:YES];
    if (self.isServer || self.isClient){
        
    }else {
        [self setPaused:NO];
    }
}

#pragma mark - Announcer Behaviors

-(float)lengthOfVector:(CGPoint)vec{
    return sqrt(pow(vec.x, 2) + pow(vec.y, 2));
}

-(float)rotationFromPoint:(CGPoint)a toPoint:(CGPoint)b{
    CGPoint aToBVector = CGPointMake(b.x - a.x, a.y - b.y);
    return CC_RADIANS_TO_DEGREES(atan2(aToBVector.y, aToBVector.x));
}

-(void)displayScreenShakeForDuration:(float)duration{
    [self displayScreenShakeForDuration:duration afterDelay:0.0];
}

- (void)displayScreenShakeForDuration:(float)duration afterDelay:(float)delay
{
    if (delay > 0) {
        [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:delay], [CCShakeScreen actionWithDuration:duration], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node setPosition:CGPointMake(0, 0)];
        }], nil] ];
    } else {
        [self runAction:[CCSequence actions:[CCShakeScreen actionWithDuration:duration], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node setPosition:CGPointMake(0, 0)];
        }], nil] ];
    }
}

-(void)displayParticleSystemOnRaidWithName:(NSString*)name forDuration:(float)duration
{
    [self displayParticleSystemOnRaidWithName:name forDuration:duration offset:CGPointZero];
}

-(void)displayParticleSystemOnRaidWithName:(NSString*)name forDuration:(float)duration offset:(CGPoint)offset{
    if (self.isServer){
        NSString* networkMessage = [NSString stringWithFormat:@"STMON|%@", name];
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

- (void)displayParticleSystemOnRaidWithName:(NSString*)name delay:(float)delay
{
    [self displayParticleSystemOnRaidWithName:name delay:delay offset:CGPointZero];
}

- (void)displayParticleSystemOnRaidWithName:(NSString*)name delay:(float)delay offset:(CGPoint)offset
{
    if (delay == 0.0) {
        [self displayParticleSystemOnRaidWithName:name forDuration:0.0 offset:offset];
    } else {
        [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:delay] two:[CCCallBlockN actionWithBlock:^(CCNode *node){
            GamePlayScene *gps = (GamePlayScene *)node;
            [gps displayParticleSystemOnRaidWithName:name forDuration:0.0 offset:offset];
        }]]];
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
    [energyBall runAction:[CCSequence actions:[CCJumpTo actionWithDuration:1.5 position:self.playerEnergyView.position height:100 jumps:1],[CCScaleTo actionWithDuration:.33 scale:0.0], [CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}

- (void)displayArcherAttackFromRaidMember:(RaidMember *)member{
    CCSprite *arrowSprite = [CCSprite spriteWithSpriteFrameName:@"arrow_archer.png"];
    [arrowSprite setScale:.5];
    CGPoint position = [self.raidView frameCenterForMember:member];
    CGFloat rotation = [self rotationFromPoint:position toPoint:CGPointMake(900, 700)] + 90.0;
    [arrowSprite setPosition:position];
    [arrowSprite setRotation:rotation];
    [self addChild:arrowSprite z:RAID_Z-1 tag:PAUSEABLE_TAG];
    
    [arrowSprite runAction:[CCSequence actions:[CCJumpTo actionWithDuration:.66 position:CGPointMake(900, 700) height:25 jumps:1],[CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}

- (void)displayWarlockAttackFromRaidMember:(RaidMember *)member{
    CCSprite *arrowSprite = [CCSprite spriteWithSpriteFrameName:@"green_fireball.png"];
    [arrowSprite setScale:.5];
    CGPoint position = [self.raidView frameCenterForMember:member];
    CGFloat rotation = [self rotationFromPoint:position toPoint:CGPointMake(900, 700)] + 270.0;
    [arrowSprite setPosition:position];
    [arrowSprite setRotation:rotation];
    [self addChild:arrowSprite z:RAID_Z-1 tag:PAUSEABLE_TAG];
    
    [arrowSprite runAction:[CCSequence actions:[CCMoveTo actionWithDuration:1.25 position:CGPointMake(900, 700)],[CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}

- (void)displayBerserkerAttackFromRaidMember:(RaidMember *)member{
    CCSprite *axeSprite = [CCSprite spriteWithSpriteFrameName:@"axe_berserker.png"];
    [axeSprite setScale:.75];
    [axeSprite setPosition:CGPointMake(820 + arc4random() % 40 - 20, 600 + arc4random() % 40 - 20)];
    [self addChild:axeSprite z:RAID_Z - 1 tag:PAUSEABLE_TAG];
    
    [axeSprite runAction:[CCSequence actions:[CCRotateBy actionWithDuration:.33 angle:- 45.0 - (arc4random() % 20)], [CCEaseBackIn actionWithAction:[CCRotateBy actionWithDuration:.33 angle:90.0 - (arc4random() % 20)]],[CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}

- (void)displayChampionAttackFromRaidMember:(RaidMember *)member{
    CCSprite *swordSprite = [CCSprite spriteWithSpriteFrameName:@"sword_champion.png"];
    [swordSprite setScale:.75];
    [swordSprite setPosition:CGPointMake(820 + arc4random() % 40 - 20, 600 + arc4random() % 40 - 20)];
    [self addChild:swordSprite z:RAID_Z - 1 tag:PAUSEABLE_TAG];
    
    [swordSprite runAction:[CCSequence actions:[CCRotateBy actionWithDuration:.15 angle:- 30.0 - (arc4random() % 10)], [CCEaseBackIn actionWithAction:[CCRotateBy actionWithDuration:.45 angle:170.0 - (arc4random() % 20)]],[CCDelayTime actionWithDuration:.25], [CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}

- (void)displayAttackFromRaidMember:(RaidMember*)member
{
    if ([member isMemberOfClass:[Archer class]]) {
        [self displayArcherAttackFromRaidMember:member];
    } else if ([member isMemberOfClass:[Champion class]]) {
        [self displayChampionAttackFromRaidMember:member];
    } else if ([member isMemberOfClass:[Warlock class]]) {
        [self displayWarlockAttackFromRaidMember:member];
    } else if ([member isMemberOfClass:[Berserker class]]) {
        [self displayBerserkerAttackFromRaidMember:member];
    }
}

- (void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target {
    [self displayParticleSystemWithName:name onTarget:target withOffset:CGPointZero];
}

- (void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target withOffset:(CGPoint)offset delay:(NSTimeInterval)delay
{
    if (self.isServer){
        NSString* networkMessage = [NSString stringWithFormat:@"STMTGT|%@|%@", name, target.battleID];
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

- (void)displayBreathEffectOnRaidForDuration:(float)duration {
    if (self.isServer) {
        //TODO: network this shit
    }
    CCParticleSystemQuad *breathEffect = [[ParticleSystemCache sharedCache] systemForKey:@"flame_breath"];
    [breathEffect setDuration:duration];
    [breathEffect setPosition:CGPointMake(800, 650)];
    [self addChild:breathEffect z:100 tag:PAUSEABLE_TAG];
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
    [self displayProjectileEffect:effect fromOrigin:CGPointMake(800, 650)];
}

- (void)displayProjectileEffect:(ProjectileEffect*)effect fromOrigin:(CGPoint)origin
{
    switch (effect.type) {
        case ProjectileEffectTypeThrow:
            [self displayThrowEffect:effect];
            break;
        default:
            [self displayNormalProjectileEffect:effect fromOrigin:origin];
            break;
    }
}

- (void)displayNormalProjectileEffect:(ProjectileEffect *)effect fromOrigin:(CGPoint)origin {
    if (self.isServer){
        effect.type = ProjectileEffectTypeNormal;
        [self.match sendDataToAllPlayers:[effect.asNetworkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    
    CCSprite *projectileSprite = [CCSprite spriteWithSpriteFrameName:effect.spriteName];;
    
    CGPoint originLocation = origin;
    CGPoint destination = [self.raidView frameCenterForMember:effect.target];
    
    if (effect.isFailed){
        destination = [self.raidView randomMissedProjectileDestination];
    }
    CCParticleSystemQuad  *collisionEffect = nil;
    if (effect.collisionParticleName && !effect.isFailed){
        collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:effect.collisionParticleName];
    }
    if (projectileSprite){
        [projectileSprite setAnchorPoint:CGPointMake(.5, .5)];
        [projectileSprite setVisible:NO];
        [projectileSprite setPosition:originLocation];
        [projectileSprite setRotation:[self rotationFromPoint:originLocation toPoint:destination] - 90.0];
        [projectileSprite setColor:effect.spriteColor];
        [self addChild:projectileSprite z:RAID_Z+1 tag:PAUSEABLE_TAG];
        [projectileSprite runAction:[CCSequence actions:[CCDelayTime actionWithDuration:effect.delay], [CCCallBlockN actionWithBlock:^(CCNode* node){ node.visible = YES;}], [CCMoveTo actionWithDuration:effect.collisionTime position:destination],[CCSpawn actions:[CCCallBlockN actionWithBlock:^(CCNode *node){
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

- (void)displayThrowEffect:(ProjectileEffect *)effect{
    if (self.isServer){
        effect.type = ProjectileEffectTypeThrow;
        [self.match sendDataToAllPlayers:[effect.asNetworkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCSprite *projectileSprite = [CCSprite spriteWithSpriteFrameName:effect.spriteName];;

    CGPoint originLocation = CGPointMake(650, 600);
    CGPoint destination = [self.raidView frameCenterForMember:effect.target];
    
    CCParticleSystemQuad  *collisionEffect = nil;
    if (effect.collisionParticleName && !effect.isFailed){
        collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:effect.collisionParticleName];
    }
    
    if (projectileSprite){
        [projectileSprite setAnchorPoint:CGPointMake(.5, .5)];
        [projectileSprite setVisible:NO];
        [projectileSprite setPosition:originLocation];
        [projectileSprite setRotation:CC_RADIANS_TO_DEGREES([self rotationFromPoint:originLocation toPoint:destination]) + 180.0];
        [projectileSprite setColor:effect.spriteColor];
        [self addChild:projectileSprite z:RAID_Z+1 tag:PAUSEABLE_TAG];
        ccBezierConfig bezierConfig = {destination,ccp(destination.x ,originLocation.y), ccp(destination.x,originLocation.y) };
        [projectileSprite runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:.3 angle:360.0]]];
        [projectileSprite runAction:[CCSequence actions:[CCDelayTime actionWithDuration:effect.delay], [CCCallBlockN actionWithBlock:^(CCNode* node){ node.visible = YES;}],[CCSpawn actions:[CCBezierTo actionWithDuration:effect.collisionTime bezier:bezierConfig],nil],[CCSpawn actions:[CCCallBlockN actionWithBlock:^(CCNode *node){
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

- (void)unloadAudioWithTitle:(NSString *)title {
    
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
    NSString *finalTitle = title;
    if (numRandoms > 0) {
        NSArray *components = [title componentsSeparatedByString:@"."];
        finalTitle = [NSString stringWithFormat:@"%@%i.%@", [components objectAtIndex:0], arc4random() % numRandoms + 1, [components objectAtIndex:1]];
    }
    
    NSString *audioPath = [@"sounds" stringByAppendingPathComponent:finalTitle];
    ALuint sound = [[SimpleAudioEngine sharedEngine] playEffect:audioPath];
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
        [[self.raidView healthViewForMember:dodgedTarget] displaySCT:@"Dodge"];
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
}

- (GLubyte)opacityForHealthPercentage:(float)percentage
{
    return MIN(255, MAX(0, (int)(255 * pow(1.0-self.player.healthPercentage, 2.5))));
}

-(void)gameEvent:(ccTime)deltaT
{
    BOOL isNetworkUpdate = NO;
    self.networkThrottle ++;
    if (self.networkThrottle >= NETWORK_THROTTLE){
        isNetworkUpdate = YES;
        self.networkThrottle = 0;
    }
    if (self.isServer || (!self.isServer && !self.isClient)){
        //Only perform the simulation if we are not the server
        //Data Events
        [self.boss combatUpdateForPlayers:self.players enemies:self.encounter.enemies theRaid:self.encounter.raid gameTime:deltaT];
        if ([playerMoveButton isMoving]){
            [self.player disableCastingWithReason:CastingDisabledReasonMoving];
        }
        else {
            [self.player enableCastingWithReason:CastingDisabledReasonMoving];
        }
    }
    
    if (self.isServer){
        if (isNetworkUpdate){
            [match sendDataToAllPlayers:[[NSString stringWithFormat:@"BOSSHEALTH|%i", self.boss.health] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
            
            for (RaidMember *member in self.raid.raidMembers){
                [match sendDataToAllPlayers:[[member asNetworkMessage] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
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
    
	//Update UI
	[raidView updateRaidHealthWithPlayer:self.player andTimeDelta:deltaT];
	[bossHealthView updateHealth];
	[playerCastBar updateTimeRemaining:[self.player remainingCastTime] ofMaxTime:[[self.player spellBeingCast] castTime] forSpell:[self.player spellBeingCast]];
	[playerEnergyView updateWithPlayer:self.player];
	[alertStatus setString:[self.player statusText]];
	[self.spellView1 updateUI];
	[self.spellView2 updateUI];
	[self.spellView3 updateUI];
	[self.spellView4 updateUI];
	
    
	//Determine if there will be another iteration of the gamestate
    NSArray *raidMembers = [self.raid livingMembers];
    NSInteger survivors = 0;
    for (RaidMember *member in raidMembers)
    {
        [member combatUpdateForPlayers:self.players enemies:self.encounter.enemies theRaid:self.encounter.raid gameTime:deltaT];
        if (![member isDead]){
            survivors++;
        }
        
    }
    if (!self.isClient){
        if (survivors == 0)
        {
            [self battleEndWithSuccess:NO];
        }
        if ([self.boss isDead] || (self.boss.health != self.boss.maximumHealth && DEBUG_AUTO_WIN)){
            [self battleEndWithSuccess:YES];
        }
    }
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
    isClient = isCli;
    self.serverPlayerID = srverPid;
}

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {    
    if (match != theMatch) return;
    
    NSString* message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (self.isClient){
        
        if ([message hasPrefix:@"BATTLEEND|"]){
            [self battleEndWithSuccess:[[message substringToIndex:10] boolValue]];
        }
        if ([message hasPrefix:@"BOSSHEALTH|"]){
            self.boss.health = [[message substringFromIndex:11] intValue];
        }
        
        if ([message hasPrefix:@"PLYR"]){
            [self.player updateWithNetworkMessage:message];
        }
        
        if ([message hasPrefix:@"RDMBR|"]){
            NSArray *messageComponents = [message componentsSeparatedByString:@"|"];
            
            NSString* battleID = [messageComponents objectAtIndex:1];

            [[self.raid memberForBattleID:battleID] updateWithNetworkMessage:message];
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
            [self displayParticleSystemOnRaidWithName:[message substringFromIndex:6] forDuration:-1.0];
        }
        
        if ([message hasPrefix:@"STMTGT|"]){
            NSArray *components = [message componentsSeparatedByString:@"|"];
            [self displayParticleSystemWithName:[components objectAtIndex:1] onTarget:[self.raid memberForBattleID:[components objectAtIndex:2]]];
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
    }
    
    if (self.isServer){
        if ([message hasPrefix:@"BGNSPELL|"]){
            //A client has told us they started casting a spell
            [self handleSpellBeginMessage:message fromPlayer:playerID];
        }
    }
    [message release];
}

-(void)handleProjectileEffectMessage:(NSString*)message{
    ProjectileEffect *effect = [[[ProjectileEffect alloc] initWithNetworkMessage:message andRaid:self.raid] autorelease];
    [self displayProjectileEffect:effect];
}


-(void)handleSpellBeginMessage:(NSString*)message fromPlayer:(NSString*)playerID{
    NSArray *messageComponents = [message componentsSeparatedByString:@"|"];
    Player *sender = nil;
    for (Player *candidate in self.players){
        if ([candidate.playerID isEqualToString:playerID]){
            sender = candidate; break;
        }
    }
    
    if (!sender){
        NSLog(@"FAILED TO FIND SENDER! =(");
    }
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
            RaidMember *member = [self.raid memberForBattleID:[messageComponents objectAtIndex:i]];
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
    if (match != theMatch) return;
    
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
    
    if (match != theMatch) return;
    
    NSLog(@"Failed to connect to player with error: %@", error.localizedDescription);
    //[delegate matchEnded];
}

// The match was unable to be established with any players due to an error.
- (void)match:(GKMatch *)theMatch didFailWithError:(NSError *)error {
    
    if (match != theMatch) return;
    
    NSLog(@"Match failed with error: %@", error.localizedDescription);
}

@end

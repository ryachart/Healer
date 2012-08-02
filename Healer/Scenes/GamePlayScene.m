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
#import "BossHealthView.h"
#import "PlayerMoveButton.h"
#import "PostBattleScene.h"
#import "PersistantDataManager.h"
#import "GamePlayPauseLayer.h"
#import "CCShakeScreen.h"
#import "ParticleSystemCache.h"
#import "Encounter.h"
#import "HealableTarget.h"
#import "PlayerHealthView.h"
#import "PlayerEnergyView.h"
#import "PlayerCastBar.h"
#import "BackgroundSprite.h"

#define NETWORK_THROTTLE 5

@interface GamePlayScene ()
//Data Models
@property (nonatomic, readwrite) BOOL paused;
@property (nonatomic, retain) Raid *raid;
@property (nonatomic, retain) Boss *boss;
@property (nonatomic, retain) Player *player;
@property (nonatomic, assign) CCLabelTTF *announcementLabel;
@property (nonatomic, assign) CCLabelTTF *errAnnouncementLabel;
@property (nonatomic, retain) GamePlayPauseLayer *pauseMenuLayer;
@property (nonatomic, readwrite) NSInteger networkThrottle;

-(void)battleBegin;
-(void)showPauseMenu;

-(void)handleProjectileEffectMessage:(NSString*)message;
-(void)handleSpellBeginMessage:(NSString*)message fromPlayer:(NSString*)playerID;
@end

@implementation GamePlayScene
@synthesize raid;
@synthesize boss;
@synthesize player;
@synthesize raidView;
@synthesize spellView1, spellView2, spellView3, spellView4;
@synthesize bossHealthView, playerEnergyView, playerMoveButton, playerCastBar;
@synthesize alertStatus;
@synthesize levelNumber;
@synthesize eventLog;
@synthesize announcementLabel;
@synthesize errAnnouncementLabel;
@synthesize paused;
@synthesize pauseMenuLayer;
@synthesize match, isClient, isServer, players, networkThrottle, matchVoiceChat, serverPlayerID;

-(id)initWithEncounter:(Encounter*)enc andPlayers:(NSArray*)plyers{
    if (self = [self initWithRaid:enc.raid boss:enc.boss andPlayers:plyers]){

    }
    return self;
}

-(id)initWithRaid:(Raid *)raidToUse boss:(Boss *)bossToUse andPlayers:(NSArray *)plyrs{
    if (self = [self initWithRaid:raidToUse boss:bossToUse andPlayer:(Player*)[plyrs objectAtIndex:0]]){
        self.players = plyrs;
        
        for (int i = 1; i < self.players.count; i++){
            Player *iPlayer = [self.players objectAtIndex:i];
            [iPlayer setLogger:self];
            [iPlayer setAnnouncer:self];
            [iPlayer initializeForCombat];
        }
    }
    return self;
}

-(id)initWithRaid:(Raid*)raidToUse boss:(Boss*)bossToUse andPlayer:(Player*)playerToUse
{
    if (self = [super init]){
        [[AudioController sharedInstance] addNewPlayerWithTitle:@"battle" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/battle" ofType:@"mp3"]]];
        NSString *assetsPath = [[NSBundle mainBundle] pathForResource:@"sprites-ipad" ofType:@"plist"  inDirectory:@"assets"];       
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:assetsPath];
        NSString *battleAssetsPath = [[NSBundle mainBundle] pathForResource:@"battle-sprites-ipad" ofType:@"plist"  inDirectory:@"assets"];       
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:battleAssetsPath];
        [self addChild:[[[BackgroundSprite alloc] initWithAssetName:@"battle-background-ipad"] autorelease]];
        paused = YES;
        self.raid = raidToUse;
        self.boss = bossToUse;
        [self.boss setLogger:self];
        [self.boss setAnnouncer:self];
        self.player = playerToUse;
        [self.player setLogger:self];
        [self.player setAnnouncer:self];
        [self.player initializeForCombat];
        
        self.players = [NSArray arrayWithObject:self.player];

        self.eventLog = [NSMutableArray arrayWithCapacity:1000];
        
        self.raidView = [[[RaidView alloc] init] autorelease];
        [self.raidView setPosition:CGPointMake(50, 150)];
        [self.raidView setContentSize:CGSizeMake(500, 400)];
        [self addChild:self.raidView];
        
        self.bossHealthView = [[[BossHealthView alloc] initWithFrame:CGRectMake(100, 560, 884, 80)] autorelease];
        CCLayerColor *playerStatusBackground = [CCLayerColor layerWithColor:ccc4(100, 100, 100, 200)];
        [playerStatusBackground setContentSize:CGSizeMake(210, 60)];
        [playerStatusBackground setPosition:CGPointMake(795, 480)];
        [self addChild:playerStatusBackground];
        
        self.playerCastBar = [[[PlayerCastBar alloc] initWithFrame:CGRectMake(100,40, 400, 50)] autorelease];
        self.playerEnergyView = [[[PlayerEnergyView alloc] initWithFrame:CGRectMake(800, 485, 200, 50)] autorelease];
        self.announcementLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(500, 300) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
        [self.announcementLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .5, [CCDirector sharedDirector].winSize.height * .65)];
        [self.announcementLabel setColor:ccYELLOW];
        [self.announcementLabel setVisible:NO];
        
        self.errAnnouncementLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(500, 300) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
        [self.errAnnouncementLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .5, [CCDirector sharedDirector].winSize.height * .4)];
        [self.errAnnouncementLabel setColor:ccRED];
        [self.errAnnouncementLabel setVisible:NO];
        
        [self addChild:self.bossHealthView];
        [self addChild:self.playerCastBar];
        [self addChild:self.playerEnergyView];
        [self addChild:self.announcementLabel z:100];
        [self addChild:self.errAnnouncementLabel z:99];
        //CACHE SOUNDS
        AudioController *ac = [AudioController sharedInstance];
        for (Spell* aSpell in [player activeSpells]){
            [[aSpell spellAudioData] cacheSpellAudio];
        }
        [ac addNewPlayerWithTitle:CHANNELING_SPELL_TITLE andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/Channeling" ofType:@"wav"]]];
        [ac addNewPlayerWithTitle:OUT_OF_MANA_TITLE andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/OutOfMana" ofType:@"wav"]]];
        
        for (int i = 0; i < [[player activeSpells] count]; i++){
            switch (i) {
                case 0:
                    self.spellView1 = [[[PlayerSpellButton alloc] initWithFrame:CGRectMake(874, 335, 100, 100)] autorelease];
                    [self.spellView1  setSpellData:[[player activeSpells] objectAtIndex:i]];
                    [self.spellView1 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                    [self addChild:self.spellView1];
                    break;
                case 1:
                    self.spellView2 = [[[PlayerSpellButton alloc] initWithFrame:CGRectMake(874, 230, 100, 100)] autorelease];
                    [self.spellView2 setSpellData:[[player activeSpells] objectAtIndex:i]];
                    [self.spellView2 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                    [self addChild:self.spellView2];
                    break;
                case 2:
                    self.spellView3 = [[[PlayerSpellButton alloc] initWithFrame:CGRectMake(874, 125, 100, 100)] autorelease];
                    [self.spellView3 setSpellData:[[player activeSpells] objectAtIndex:i]];
                    [self.spellView3 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                    [self addChild:self.spellView3];
                    break;
                case 3:
                    self.spellView4 = [[[PlayerSpellButton alloc] initWithFrame:CGRectMake(874, 20, 100, 100)] autorelease];
                    [self.spellView4 setSpellData:[[player activeSpells] objectAtIndex:i]];
                    [self.spellView4 setInteractionDelegate:(PlayerSpellButtonDelegate*)self];
                    [self addChild:self.spellView4];
                    break;
                default:
                    break;
            }
        }
        
        
        [raidView spawnRects];
        NSMutableArray *raidMembers = [raid raidMembers];
        selectedRaidMembers = [[NSMutableArray alloc] initWithCapacity:5];
        for (RaidMember *member in raidMembers)
        {
            [member setLogger:self];
            RaidMemberHealthView *rmhv = [[RaidMemberHealthView alloc] initWithFrame:[raidView vendNextUsableRect]];
            [rmhv setMemberData:member];
            [rmhv setInteractionDelegate:(RaidMemberHealthViewDelegate*)self];
            [raidView addRaidMemberHealthView:rmhv];
        }
        [bossHealthView setBossData:boss];
        [playerEnergyView setChannelDelegate:(ChannelingDelegate*)self];
        
        
        //The timer has to be scheduled after all the init is done!
        CCLabelTTF *menuLabel = [CCLabelTTF labelWithString:@"Menu" fontName:@"Arial" fontSize:32.0];
        CCMenu *menuButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:menuLabel target:self selector:@selector(showPauseMenu)], nil];
        [menuButton setPosition:CGPointMake(50, [CCDirector sharedDirector].winSize.height * .95)];
        [menuButton setColor:ccWHITE];
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
        return; //Cant pause multiplayerg
    }
    
    if (self.paused){
        [self unschedule:@selector(gameEvent:)];
    }else{
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
    }
    [self addChild:self.pauseMenuLayer z:10000];

}

-(void)pauseLayerDidFinish{
    [self.pauseMenuLayer removeFromParentAndCleanup:YES];
    [self setPaused:NO];
}

- (void)pauseLayerDidQuit {
    if (self.matchVoiceChat){
        [self.matchVoiceChat stop];
    }
    [self.pauseMenuLayer removeFromParentAndCleanup:YES];
    [self battleEndWithSuccess:NO];
}

-(void)onEnterTransitionDidFinish{
#if DEBUG
    if (self.levelNumber == 1){
        [self gameEvent:0.0]; //Bump the UI
        [self battleBegin];
    }else
#endif
    if (self.levelNumber == 1){
        [self gameEvent:0.0]; //Bump the UI
        GamePlayFTUELayer *gpfl = [[[GamePlayFTUELayer alloc] init] autorelease];
        [gpfl setDelegate:self];
        [self addChild:gpfl z:1000];
        [gpfl showWelcome];
    }else{
        [self gameEvent:0.0]; //Bump the UI
        [self battleBegin];
    }
    [[AudioController sharedInstance] stopAll];
    [[AudioController sharedInstance] playTitle:@"battle" looping:20];
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
    NSInteger numDead = self.raid.raidMembers.count - self.raid.getAliveMembers.count;
    PostBattleScene *pbs = [[PostBattleScene alloc] initWithVictory:success eventLog:self.eventLog levelNumber:self.levelNumber andIsMultiplayer:self.isClient || self.isServer andFallenMembers:numDead];
    [self setPaused:YES];
    if (self.isServer){
        [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"BATTLEEND|%i|", success] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
    }
    if (self.isServer || self.isClient){
        [pbs setServerPlayerId:self.serverPlayerID];
        [pbs setMatch:self.match];
        [pbs setMatchVoiceChat:self.matchVoiceChat];
    }
    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInT transitionWithDuration:1.0 scene:pbs]];
    [pbs release];
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

-(void)playerSelected:(PlayerHealthView *)hv
{
    return;
	if ([[hv memberData] isDead]) return;
	if ([selectedRaidMembers count] == 0){
		[selectedRaidMembers addObject:hv];
		[hv setColor:ccBLUE];
	}
	else if ([selectedRaidMembers objectAtIndex:0] == hv){
		//Here we do nothing because the already selected object has been reselected
	}
	else if ([selectedRaidMembers objectAtIndex:0] != hv){
		PlayerHealthView *currentTarget = [selectedRaidMembers objectAtIndex:0];
		if ([currentTarget isTouched]){
			[selectedRaidMembers addObject:hv];
			[hv setColor:ccc3(255, 0, 255)];
		}
		else{
			[currentTarget setColor:[hv defaultBackgroundColor]];
			[selectedRaidMembers removeObjectAtIndex:0];
			[selectedRaidMembers insertObject:hv atIndex:0];
			[hv setColor:ccBLUE];
		}
		
	}
}
-(void)playerUnselected:(PlayerHealthView *)hv
{
    return;
	if (hv != [selectedRaidMembers objectAtIndex:0]){
		[selectedRaidMembers removeObject:hv];
		[hv setColor:ccBLUE];
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
			if ([player spellBeingCast] == nil){
				[(Chargable*)[spell spellData] beginCharging:[NSDate date]];
				[spell setColor:ccc3(150, 150, 0 )];
			}
		}
		else{
            [player beginCasting:[spell spellData] withTargets:targets];
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
				[player beginCasting:[spell spellData] withTargets:targets];
				[spell setColor:ccc3(255, 255, 255)];
			}
		}
	}
}

#pragma mark - Announcer Behaviors

-(float)lengthOfVector:(CGPoint)vec{
    return sqrt(pow(vec.x, 2) + pow(vec.y, 2));
}

-(float)rotationFromPoint:(CGPoint)a toPoint:(CGPoint)b{
    CGPoint aToBVector = CGPointMake(b.x - a.x , b.y - a.y);
    CGPoint unitVector = ccpNormalize(aToBVector);
    return atan2(unitVector.y, unitVector.x);
}

-(void)displayScreenShakeForDuration:(float)duration{
    [self runAction:[CCSequence actions:[CCShakeScreen actionWithDuration:duration], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node setPosition:CGPointMake(0, 0)];
    }], nil] ];
}
-(void)displayPartcileSystemOnRaidWithName:(NSString*)name forDuration:(float)duration{
    if (self.isServer){
        NSString* networkMessage = [NSString stringWithFormat:@"STMON|%@", name];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCParticleSystemQuad *collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:name];
    CGPoint destination = ccpAdd([self.raidView position], ccp(self.raidView.contentSize.width / 2, self.raidView.contentSize.height /2));
    if (duration != -1.0){
        [collisionEffect setDuration:duration];
    }
    [collisionEffect setPosition:destination];
    [collisionEffect setAutoRemoveOnFinish:YES];
    [self addChild:collisionEffect z:100];
}
-(void)displayPartcileSystemOverRaidWithName:(NSString*)name{
    if (self.isServer){
        NSString* networkMessage = [NSString stringWithFormat:@"STMOVER|%@", name];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCParticleSystemQuad *collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:name];
    CGPoint destination = ccpAdd([self.raidView position], ccp(self.raidView.contentSize.width / 2, self.raidView.contentSize.height));
    [collisionEffect setPosition:destination];
    [collisionEffect setAutoRemoveOnFinish:YES];
    [self addChild:collisionEffect z:100];
}
-(void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target{
    if (self.isServer){
        NSString* networkMessage = [NSString stringWithFormat:@"STMTGT|%@|%@", name, target.battleID];
        [self.match sendDataToAllPlayers:[networkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCParticleSystemQuad *collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:name];
    CGPoint destination = [self.raidView frameCenterForMember:target];
    [collisionEffect setPosition:destination];
    [collisionEffect setAutoRemoveOnFinish:YES];
    [self addChild:collisionEffect z:100];

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
    [self addChild:sprite];
    [sprite runAction:[CCSequence actions:[CCScaleTo actionWithDuration:.33 scale:scaleTo],[CCDelayTime actionWithDuration:duration],[CCFadeOut actionWithDuration:.5] ,[CCCallBlockN actionWithBlock:^(CCNode*node){
        [node removeFromParentAndCleanup:YES];
        
    }], nil]];
    
}

-(void)displayProjectileEffect:(ProjectileEffect*)effect{
    if (self.isServer){
        effect.type = ProjectileEffectTypeNormal;
        [self.match sendDataToAllPlayers:[effect.asNetworkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    
    CCSprite *projectileSprite = [CCSprite spriteWithSpriteFrameName:effect.spriteName];;
    
    CGPoint originLocation = CGPointMake(650, 600);
    CGPoint destination = [self.raidView frameCenterForMember:effect.target];
    CCParticleSystem  *collisionEffect = nil;
    if (effect.collisionParticleName){
        collisionEffect = [[ParticleSystemCache sharedCache] systemForKey:effect.collisionParticleName];
    }
    if (projectileSprite){
        [projectileSprite setAnchorPoint:CGPointMake(.5, .5)];
        [projectileSprite setVisible:NO];
        [projectileSprite setPosition:originLocation];
        [projectileSprite setRotation:CC_RADIANS_TO_DEGREES([self rotationFromPoint:originLocation toPoint:destination]) + 180.0];
        [projectileSprite setColor:effect.spriteColor];
        [self addChild:projectileSprite];
        [projectileSprite runAction:[CCSequence actions:[CCDelayTime actionWithDuration:effect.delay], [CCCallBlockN actionWithBlock:^(CCNode* node){ node.visible = YES;}], [CCMoveTo actionWithDuration:effect.collisionTime position:destination],[CCSpawn actions:[CCCallBlockN actionWithBlock:^(CCNode *node){
            if (collisionEffect){
                [collisionEffect setPosition:destination];
                [collisionEffect setAutoRemoveOnFinish:YES];
                [self addChild:collisionEffect z:100];
            }
        }],[CCScaleTo actionWithDuration:.33 scale:2.0], [CCFadeOut actionWithDuration:.33], nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];
        }], nil]];
    }

}

-(void)displayThrowEffect:(ProjectileEffect *)effect{
    if (self.isServer){
        effect.type = ProjectileEffectTypeThrow;
        [self.match sendDataToAllPlayers:[effect.asNetworkMessage dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
    }
    CCSprite *projectileSprite = [CCSprite spriteWithSpriteFrameName:effect.spriteName];;
    
    CGPoint originLocation = CGPointMake(650, 600);
    CGPoint destination = [self.raidView frameCenterForMember:effect.target];
    if (projectileSprite){
        [projectileSprite setAnchorPoint:CGPointMake(.5, .5)];
        [projectileSprite setVisible:NO];
        [projectileSprite setPosition:originLocation];
        [projectileSprite setRotation:CC_RADIANS_TO_DEGREES([self rotationFromPoint:originLocation toPoint:destination]) + 180.0];
        [projectileSprite setColor:effect.spriteColor];
        [self addChild:projectileSprite];
        ccBezierConfig bezierConfig = {destination,ccp(destination.x ,originLocation.y), ccp(destination.x,originLocation.y) };
        [projectileSprite runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:.3 angle:360.0]]];
        [projectileSprite runAction:[CCSequence actions:[CCDelayTime actionWithDuration:effect.delay], [CCCallBlockN actionWithBlock:^(CCNode* node){ node.visible = YES;}],[CCSpawn actions:[CCBezierTo actionWithDuration:effect.collisionTime bezier:bezierConfig] ,nil ],[CCSpawn actions:[CCScaleTo actionWithDuration:.33 scale:2.0], [CCFadeOut actionWithDuration:.33], nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
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
    [self.errAnnouncementLabel setVisible:YES];
    [self.errAnnouncementLabel setString:announcement];
    [self.errAnnouncementLabel runAction:[CCSequence actions:[CCScaleTo actionWithDuration:1.5 scale:1.25], [CCScaleTo actionWithDuration:1.5 scale:1.0],[CCDelayTime actionWithDuration:5.0], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node setVisible:NO];
        [(CCLabelTTF*)node setString:@""];
    }],nil]];
}

-(void)logEvent:(CombatEvent *)event{
    [self.eventLog addObject:event];
    
    if (event.type == CombatEventTypeDodge){
        RaidMember *dodgedTarget = (RaidMember*)event.target;
        
        for (RaidMemberHealthView *rmhv in self.raidView.raidViews){
            if (rmhv.memberData == dodgedTarget){
                [rmhv displaySCT:@"Dodge!"];
                break;
            }
        }
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
        [boss combatActions:self.players theRaid:raid gameTime:deltaT];
        if ([playerMoveButton isMoving]){
            [player disableCastingWithReason:CastingDisabledReasonMoving];
            [player setPosition:[player position]+1];
        }
        else {
            [player enableCastingWithReason:CastingDisabledReasonMoving];
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
    //The player's simulation must continue...This might not work
    [player combatActions:boss theRaid:raid gameTime:deltaT];
    
    if (self.isServer){
        for (int i = 1; i < self.players.count; i++){
            Player *clientPlayer = [self.players objectAtIndex:i];
            [clientPlayer combatActions:boss theRaid:raid gameTime:deltaT];
            if (isNetworkUpdate){
                NSArray *playerToNotify = [NSArray arrayWithObject:clientPlayer.playerID];
                [self.match sendData:[[clientPlayer asNetworkMessage] dataUsingEncoding:NSUTF8StringEncoding]  toPlayers:playerToNotify withDataMode:GKMatchSendDataReliable error:nil];
            }
        }
        
    }
    
	//Update UI
	[raidView updateRaidHealth];
	[bossHealthView updateHealth];
	[playerCastBar updateTimeRemaining:[player remainingCastTime] ofMaxTime:[[player spellBeingCast] castTime] forSpell:[player spellBeingCast]];
	[playerEnergyView updateWithEnergy:[player energy] andMaxEnergy:[player maximumEnergy]];
	[alertStatus setString:[player statusText]];
	[self.spellView1 updateUI];
	[self.spellView2 updateUI];
	[self.spellView3 updateUI];
	[self.spellView4 updateUI];
	
    
	//Determine if there will be another iteration of the gamestate
    NSMutableArray *raidMembers = [raid raidMembers];
    NSInteger survivors = 0;
    for (RaidMember *member in raidMembers)
    {
        [member combatActions:boss raid:raid players:self.players gameTime:deltaT];
        if (![member isDead]){
            survivors++;
        }
        
    }
    if (!self.isClient){
        if (survivors == 0)
        {
            [self battleEndWithSuccess:NO];
        }
        if ([player isDead]){
            [self battleEndWithSuccess:NO];
        }
        if ([boss isDead]){
            [self battleEndWithSuccess:YES];
        }
    }
}

-(void)beginChanneling{
	[player startChanneling];
}

-(void)endChanneling{
	[player stopChanneling];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

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
    [eventLog release];
    [serverPlayerID release];
    [match release];
    [matchVoiceChat release];
    [players release];
    [selectedRaidMembers release];
    [raid release];
    [boss release];
    [player release];
    
	AudioController *ac = [AudioController sharedInstance];
	for (Spell* aSpell in [player activeSpells]){
		[[aSpell spellAudioData] releaseSpellAudio];
	}
	[ac removeAudioPlayerWithTitle:CHANNELING_SPELL_TITLE];
	[ac removeAudioPlayerWithTitle:OUT_OF_MANA_TITLE];
    [super dealloc];
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
            [self displayPartcileSystemOverRaidWithName:[message substringFromIndex:8]];
        }
        
        if ([message hasPrefix:@"STMON|"]){
            [self displayPartcileSystemOnRaidWithName:[message substringFromIndex:6] forDuration:-1.0];
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
                [[player spellBeingCast] applyTemporaryCooldown:[[components objectAtIndex:1] floatValue]];
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
    ProjectileEffect *effect = [[ProjectileEffect alloc] initWithNetworkMessage:message andRaid:self.raid];
    
    if (effect.type == ProjectileEffectTypeNormal){
        [self displayProjectileEffect:effect];
    }
    
    if (effect.type == ProjectileEffectTypeThrow){
        [self displayThrowEffect:effect];
    }
    [effect release];
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

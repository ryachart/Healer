//
//  HealerStartScene.m
//  Healer
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "HealerStartScene.h"
#import "AppDelegate.h"
#import "PlayerDataManager.h"
#import "Shop.h"
#import "ShopScene.h"
#import "BackgroundSprite.h"
#import "Talents.h"
#import "TalentScene.h"
#import "BasicButton.h"
#import "MultiplayerQueueScene.h"
#import "GoldCounterSprite.h"
#import "LevelSelectMapScene.h"
#import "SettingsScene.h"
#import "RatingCounterSprite.h"
#import "SimpleAudioEngine.h"
#import "TipsLayer.h"
#import "InventoryScene.h"
#import "StaminaCounterNode.h"
#import "TreasureChest.h"


@interface HealerStartScene ()
@property (assign) CCMenu* menu;
@property (assign) CCMenuItem* multiplayerButton;
@property (assign) CCMenuItem* quickPlayButton;
@property (assign) CCMenuItem* storeButton;
@property (nonatomic, readwrite) BOOL authenticationAttempted;
@end

@implementation HealerStartScene
@synthesize menu;
@synthesize multiplayerButton;
@synthesize quickPlayButton;
@synthesize storeButton;
@synthesize authenticationAttempted;
-(id)init{
    if (self = [super init]){
        //Perform Scene Setup   
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/spell-sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/items.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/avatar.plist"];
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg"] autorelease]];
        
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"sounds/button1.mp3"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"sounds/button2.mp3"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"sounds/button3.mp3"];
        if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying]) {
            [[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"sounds/theme.mp3"];
        }
        [SettingsScene configureAudioForUserSettings];
        //self.multiplayerButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(multiplayerSelected) andTitle:@"Multiplayer"];
        
        [[PlayerDataManager localPlayer] unlockAll];
        
        self.quickPlayButton= [BasicButton basicButtonWithTarget:self andSelector:@selector(quickPlaySelected) andTitle:@"Play"];
        
        self.storeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(storeSelected) andTitle:@"Academy"];
        
        BasicButton *armoryButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(armorySelected) andTitle:@"Armory"];
        
        CCMenuItem *divinityButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(divinitySelected) andTitle:@"Talents" andAlertPip:[[PlayerDataManager localPlayer] numUnspentTalentChoices] showsLockForDisabled:![[PlayerDataManager localPlayer] isTalentsUnlocked]];
        
        self.menu = [CCMenu menuWithItems:self.quickPlayButton, self.storeButton, armoryButton, divinityButton, nil];
        
        [self.menu alignItemsVerticallyWithPadding:20.0];
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .81, winSize.height * .48)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu z:2];
        
        StaminaCounterNode *stamina = [[[StaminaCounterNode alloc] init] autorelease];
        [stamina setPosition:CGPointMake(620, 45)];
        [self addChild:stamina];
        
        GoldCounterSprite *goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(920, 45)];
        [self addChild:goldCounter];
        
        RatingCounterSprite *ratingCounter = [[[RatingCounterSprite alloc] init] autorelease];
        [ratingCounter setPosition:CGPointMake(770, 45)];
        [self addChild:ratingCounter];
        
        CCSprite *logoSprite = [CCSprite spriteWithSpriteFrameName:@"home_logo.png"];
        [logoSprite setAnchorPoint:CGPointMake(0, 0)];
        [logoSprite setPosition:CGPointMake(590, 250)];
        [self addChild:logoSprite z:1];
        
        
        CCMenuItem *settingsButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(settingsSelected) andTitle:@"Settings"];
        [settingsButton setScale:.4];
        
        CCMenu *settingsMenu = [CCMenu menuWithItems:settingsButton, nil];
        [settingsMenu setPosition:CGPointMake(50, 20)];
        [self addChild:settingsMenu];
        
        if ([PlayerDataManager localPlayer].highestLevelCompleted > 1) {        
            TipsLayer *tipsLayer = [[[TipsLayer alloc] init] autorelease];
            [self addChild:tipsLayer];
        }
     
        CCSprite *facebook = [CCSprite spriteWithSpriteFrameName:@"facebook.png"];
        CCSprite *facebookSelected = [CCSprite spriteWithSpriteFrameName:@"facebook.png"];
        [facebookSelected setOpacity:122];
        
        CCMenuItem *facebookButton = [CCMenuItemSprite itemWithNormalSprite:facebook selectedSprite:facebookSelected target:self selector:@selector(facebookSelected)];
        [facebookButton setScale:.75];
        
        CCSprite *twitter = [CCSprite spriteWithSpriteFrameName:@"twitter.png"];
        CCSprite *twitterSelected = [CCSprite spriteWithSpriteFrameName:@"twitter.png"];
        [twitterSelected setOpacity:122];
        
        CCMenuItem *twitterButton = [CCMenuItemSprite itemWithNormalSprite:twitter selectedSprite:twitterSelected target:self selector:@selector(twitterSelected)];
        [twitterButton setScale:.75];
        
        CCMenu *socialMediaMenu = [CCMenu menuWithItems:facebookButton, twitterButton, nil];
        [self addChild:socialMediaMenu];
        [socialMediaMenu alignItemsVertically];
        [socialMediaMenu setPosition:CGPointMake(35, 100)];
        
    }
    return self;
}

- (void)settingsSelected {
    SettingsScene *ss = [[SettingsScene new] autorelease];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade   transitionWithDuration:.5 scene:ss]];
}

-(void)multiplayerSelected{
    if (![[PlayerDataManager localPlayer] isMultiplayerUnlocked]){
        UIAlertView *mplayerNotUnlocked = [[UIAlertView alloc] initWithTitle:@"Multiplayer Unavailable!" message:@"Multiplayer is coming in an update soon!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [mplayerNotUnlocked show];
        [mplayerNotUnlocked release];
        
        return;
    }
    __block BOOL multiplayerGamePlayRequested = YES;
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    if (![localPlayer isAuthenticated]){
        [localPlayer authenticateWithCompletionHandler:^(NSError *error){
                if (!error) {
                    if (multiplayerGamePlayRequested){
                        MultiplayerQueueScene *queueScene = [[MultiplayerQueueScene alloc] init];
                        [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInR transitionWithDuration:.5 scene:queueScene]];
                        [queueScene release];
                        self.authenticationAttempted = YES;
                    }
                }else
                {
                    self.authenticationAttempted = NO;
                    NSLog(@"%@", error);
                    UIAlertView *errorAuthenticating = [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease];
                    [errorAuthenticating show];
                }
            multiplayerGamePlayRequested = NO;
        }];
    } else{
        MultiplayerQueueScene *queueScene = [[MultiplayerQueueScene alloc] init];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInR   transitionWithDuration:.5 scene:queueScene]];
        [queueScene release];
    }

}

- (void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying]) {
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"sounds/theme.mp3" loop:YES];
    }
    
}


-(void)quickPlaySelected
{
	LevelSelectMapScene *qpS = [[LevelSelectMapScene new] autorelease];
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:qpS]];
}

-(void)storeSelected{
    ShopScene *ss = [[ShopScene new] autorelease];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:ss]];
}

-(void)divinitySelected{
    if ([[PlayerDataManager localPlayer] isTalentsUnlocked]){
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[TalentScene alloc] init] autorelease]]];
    } else {
        IconDescriptionModalLayer *modalLayer = [[[IconDescriptionModalLayer alloc] initWithIconName:@"lock.png" title:@"Unavailable" andDescription:@"Talents become unlocked once you have acquired 15 boss kill points."] autorelease];
        [modalLayer setDelegate:self];
        [self addChild:modalLayer z:1000];
    }
}

- (void)armorySelected {
    InventoryScene *is = [[InventoryScene new] autorelease];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:is]];
}

- (void)twitterSelected
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.twitter.com/healergame"]];
}

- (void)facebookSelected
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.facebook.com/healergame?_rdr"]];
}

- (void)dealloc {
    [super dealloc];
}

- (void)iconDescriptionModalDidComplete:(id)modal
{
    [(IconDescriptionModalLayer*)modal removeFromParentAndCleanup:YES];
}

@end

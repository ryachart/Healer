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
#import "AudioController.h"
#import "MultiplayerQueueScene.h"
#import "GoldCounterSprite.h"
#import "LevelSelectMapScene.h"
#import "SettingsScene.h"
#import "RatingCounterSprite.h"

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
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg"] autorelease]];
        
        //self.multiplayerButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(multiplayerSelected) andTitle:@"Multiplayer"];
        
        self.quickPlayButton= [BasicButton basicButtonWithTarget:self andSelector:@selector(quickPlaySelected) andTitle:@"Play"];
        
        self.storeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(storeSelected) andTitle:@"Academy"];
        
        CCMenuItem *divinityButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(divinitySelected) andTitle:@"Talents"];
        if (![Talents isDivinityUnlocked]){
            [divinityButton setIsEnabled:NO];
        }
    
        self.menu = [CCMenu menuWithItems:self.quickPlayButton, self.storeButton, divinityButton, nil];
        
        [self.menu alignItemsVerticallyWithPadding:20.0];
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .81, winSize.height * .48)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu z:2];
        
        GoldCounterSprite *goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(900, 50)];
        [self addChild:goldCounter];
        
        RatingCounterSprite *ratingCounter = [[[RatingCounterSprite alloc] init] autorelease];
        [ratingCounter setPosition:CGPointMake(750, 50)];
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
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}


-(void)quickPlaySelected
{
    [[PlayerDataManager localPlayer] unlockAll];
	LevelSelectMapScene *qpS = [[LevelSelectMapScene new] autorelease];
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:qpS]];
}

-(void)storeSelected{
    ShopScene *ss = [[ShopScene new] autorelease];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:ss]];
}

-(void)divinitySelected{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[TalentScene alloc] init] autorelease]]];
}

- (void)dealloc {
    [super dealloc];
}

@end

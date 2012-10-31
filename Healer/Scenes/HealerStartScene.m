//
//  HealerStartScene.m
//  Healer
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "HealerStartScene.h"
#import "AppDelegate.h"
#import "PersistantDataManager.h"
#import "Shop.h"
#import "ShopScene.h"
#import "BackgroundSprite.h"
#import "Divinity.h"
#import "DivinityConfigScene.h"
#import "BasicButton.h"
#import "AudioController.h"
#import "MultiplayerQueueScene.h"
#import "GoldCounterSprite.h"
#import "LevelSelectMapScene.h"

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
        [[AudioController sharedInstance] addNewPlayerWithTitle:@"title" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/title" ofType:@"m4a"]]];
        //Perform Scene Setup   
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/spell-sprites.plist"];
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg"] autorelease]];
        
        self.multiplayerButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(multiplayerSelected) andTitle:@"Multiplayer"];
        
        self.quickPlayButton= [BasicButton basicButtonWithTarget:self andSelector:@selector(quickPlaySelected) andTitle:@"Play"];
        
        self.storeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(storeSelected) andTitle:@"Academy"];
        
        CCMenuItem *divinityButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(divinitySelected) andTitle:@"Divinity"];
        if (![Divinity isDivinityUnlocked]){
            [divinityButton setIsEnabled:NO];
        }
    
        self.menu = [CCMenu menuWithItems:self.quickPlayButton, self.storeButton, self.multiplayerButton, divinityButton, nil];
        
        [self.menu alignItemsVerticallyWithPadding:20.0];
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .81, winSize.height * .45)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu z:2];
        
        GoldCounterSprite *goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(900, 50)];
        [self addChild:goldCounter];
        
        CCSprite *logoSprite = [CCSprite spriteWithSpriteFrameName:@"home_logo.png"];
        [logoSprite setAnchorPoint:CGPointMake(0, 0)];
        [logoSprite setPosition:CGPointMake(590, 250)];
        [self addChild:logoSprite z:1];
        
    }
    return self;
}

-(void)multiplayerSelected{
    if (![PersistantDataManager isMultiplayerUnlocked]){
        UIAlertView *mplayerNotUnlocked = [[UIAlertView alloc] initWithTitle:@"Multiplayer not Unlocked!" message:@"Multiplayer is unlocked after slaying the Plaguebringer Colossus." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
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

    if (![[AudioController sharedInstance] isTitlePlaying:@"title"]) {
        [[AudioController sharedInstance] stopAll];
        [[AudioController sharedInstance] playTitle:@"title" looping:10];
    }
}


-(void)quickPlaySelected
{
	LevelSelectMapScene *qpS = [[LevelSelectMapScene new] autorelease];
	[[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInR transitionWithDuration:.5 scene:qpS]];
}

-(void)storeSelected{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInR transitionWithDuration:.5 scene:[[[ShopScene alloc] init] autorelease]]];
}

-(void)settingsSelected
{
	//No behavior defined yet.
}

-(void)divinitySelected{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInR transitionWithDuration:.5 scene:[[[DivinityConfigScene alloc] init] autorelease]]];
}

- (void)dealloc {
    self.menu = nil;
    self.multiplayerButton = nil;
    self.quickPlayButton = nil;
    [super dealloc];
}

@end

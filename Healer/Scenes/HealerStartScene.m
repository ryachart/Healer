//
//  HealerStartScene.m
//  Healer
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "HealerStartScene.h"
#import "AppDelegate.h"
#import "MultiplayerSetupScene.h"
#import "PersistantDataManager.h"
#import "Shop.h"
#import "StoreScene.h"
#import "BackgroundSprite.h"
#import "Divinity.h"
#import "DivinityConfigScene.h"
#import "BasicButton.h"
#import "AudioController.h"


@interface HealerStartScene ()
@property (assign) CCMenu* menu;
@property (assign) CCMenuItem* multiplayerButton;
@property (assign) CCMenuItem* quickPlayButton;
@property (assign) CCMenuItem* storeButton;
@property (nonatomic, retain) UIViewController* presentingViewController;
@property (readwrite) BOOL matchStarted;

-(void)multiplayerSelected;
-(void)quickPlaySelected;
-(void)settingsSelected;
-(void)storeSelected;
@end

@implementation HealerStartScene
@synthesize menu;
@synthesize multiplayerButton;
@synthesize quickPlayButton;
@synthesize storeButton;
@synthesize presentingViewController;
@synthesize matchStarted;

-(id)init{
    if (self = [super init]){
#if DEBUG
        [Divinity unlockDivinity];
#endif
        [[AudioController sharedInstance] addNewPlayerWithTitle:@"title" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/title" ofType:@"m4a"]]];
        //Perform Scene Setup   
        NSString *assetsPath = [[NSBundle mainBundle] pathForResource:@"sprites-ipad" ofType:@"plist"  inDirectory:@"assets"];       
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:assetsPath];
        [self addChild:[[[BackgroundSprite alloc] initWithAssetName:@"title-ipad"] autorelease]];
        
        self.multiplayerButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(multiplayerSelected) andTitle:@"Multiplayer"];
        [self.multiplayerButton setIsEnabled:NO];
        
        self.quickPlayButton= [BasicButton basicButtonWithTarget:self andSelector:@selector(quickPlaySelected) andTitle:@"Play"];
        
        self.storeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(storeSelected) andTitle:@"Spell Shop"];
        
        CCMenuItem *divinityButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(divinitySelected) andTitle:@"Divinity"];
        if (![Divinity isDivinityUnlocked]){
            [divinityButton setIsEnabled:NO];
        }
        
        self.menu = [CCMenu menuWithItems:self.quickPlayButton, self.storeButton, self.multiplayerButton, divinityButton, nil];
        
        [self.menu alignItemsVerticallyWithPadding:20.0];
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .9, winSize.height * .5)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu];
        
        int playerGold = [Shop localPlayerGold];
        CCSprite *goldBG = [CCSprite spriteWithSpriteFrameName:@"gold_bg.png"];
        CCLabelTTF *goldLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold: %i", playerGold] fontName:@"Arial" fontSize:32.0];
        [goldLabel setColor:ccBLACK];
        [goldLabel setPosition:CGPointMake(goldBG.contentSize.width /2 , goldBG.contentSize.height /2 )];
        [goldBG setPosition:CGPointMake(900, 50)];
        [self addChild:goldBG];
        [goldBG addChild:goldLabel];
        
    }
    return self;
}

-(void)multiplayerSelected{
#if DEBUG
    MultiplayerSetupScene *mpss = [[MultiplayerSetupScene alloc] init];
//    [mpss setMatch:theMatch];
//    theMatch.delegate = mpss;    
    [[CCDirector sharedDirector] replaceScene:mpss];
    [mpss release];
    return;
#endif
    static BOOL authenticationAttempted = NO;
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    if (![localPlayer isAuthenticated]){
        if (authenticationAttempted){
            return;
        }
        [localPlayer authenticateWithCompletionHandler:^(NSError *error){
            [self multiplayerSelected];
            authenticationAttempted = YES;
        }];
    }else{
        GKMatchRequest *request = [[GKMatchRequest  alloc] init];
        [request setMaxPlayers:2];
        [request setMinPlayers:2];
        
        GKMatchmakerViewController *mmvc = 
        [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
        mmvc.matchmakerDelegate = self;
        
        [request release];
            
        [[CCDirector sharedDirector] pause];
        self.presentingViewController = (UIViewController*)[(AppDelegate*)[[UIApplication sharedApplication] delegate] viewController];
        [self.presentingViewController presentViewController:mmvc animated:NO completion:nil];
        
        
        [mmvc release];
    }
    
}

- (void)onEnterTransitionDidFinish {
    [[AudioController sharedInstance] playTitle:@"title" looping:10];
    [super onEnterTransitionDidFinish];
}

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    [[CCDirector sharedDirector] resume];
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];    [[CCDirector sharedDirector] resume];
    NSLog(@"Error finding match: %@", error.localizedDescription);    
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    [[CCDirector sharedDirector] resume];

//    theMatch.delegate = self;
    if (!self.matchStarted && theMatch.expectedPlayerCount == 0) {
        NSLog(@"Ready to start match!");
    }
    
    MultiplayerSetupScene *mpss = [[MultiplayerSetupScene alloc] init];
    [mpss setMatch:theMatch];
    theMatch.delegate = mpss;    
    [[CCDirector sharedDirector] replaceScene:mpss];
    [mpss release];
    
}


-(void)quickPlaySelected
{
	QuickPlayScene *qpS = [QuickPlayScene new];
	[[CCDirector sharedDirector] replaceScene:[CCTransitionRadialCCW transitionWithDuration:.5 scene:qpS]];
	[qpS release];
}

-(void)storeSelected{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionRadialCCW transitionWithDuration:.5 scene:[[[StoreScene alloc] init] autorelease]]];
}

-(void)settingsSelected
{
	//No behavior defined yet.
    
}

-(void)divinitySelected{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionRadialCCW transitionWithDuration:.5 scene:[[[DivinityConfigScene alloc] init] autorelease]]];
}


- (void)dealloc {
    self.menu = nil;
    self.multiplayerButton = nil;
    self.quickPlayButton = nil;
    [super dealloc];
}

@end

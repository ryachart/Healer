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

@interface HealerStartScene ()
@property (assign) CCMenu* menu;
@property (assign) CCMenuItemLabel* multiplayerButton;
@property (assign) CCMenuItemLabel* quickPlayButton;
@property (assign) CCMenuItemLabel* storeButton;
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
        //Perform Scene Setup   
        [self addChild:[[[BackgroundSprite alloc] initWithAssetName:@"wood-bg-ipad"] autorelease]];
        
        self.multiplayerButton = [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Multiplayer" fontName:@"Arial" fontSize:32] target:self selector:@selector(multiplayerSelected)] autorelease];
        self.quickPlayButton= [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Play" fontName:@"Arial" fontSize:32] target:self selector:@selector(quickPlaySelected)] autorelease];
        
        self.storeButton = [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Shop" fontName:@"Arial" fontSize:32] target:self selector:@selector(storeSelected)] autorelease];
        
        CCMenuItemLabel *divinityButton = [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Divinity" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(divinitySelected)] autorelease];
        [divinityButton setOpacity:122];
        [divinityButton setIsEnabled:NO];
        
        self.menu = [CCMenu menuWithItems:self.quickPlayButton, self.storeButton, self.multiplayerButton, divinityButton, nil];
        
        [self.menu alignItemsVerticallyWithPadding:20.0];
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .5, winSize.height * .5)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu];
        
        int playerGold = [Shop localPlayerGold];
        CCLabelTTF *goldLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold: %i", playerGold] fontName:@"Arial" fontSize:32.0];
        
        [goldLabel setPosition:CGPointMake(900, 50)];
        [self addChild:goldLabel];
        
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
    
}


- (void)dealloc {
    self.menu = nil;
    self.multiplayerButton = nil;
    self.quickPlayButton = nil;
    [super dealloc];
}

@end

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
#import "StoreScene.h"
#import "BackgroundSprite.h"
#import "Divinity.h"
#import "DivinityConfigScene.h"
#import "BasicButton.h"
#import "AudioController.h"
#import "MultiplayerQueueScene.h"
#import "GoldCounterSprite.h"

BOOL firstLaunch = YES;

@interface HealerStartScene ()
@property (assign) CCMenu* menu;
@property (assign) CCMenuItem* multiplayerButton;
@property (assign) CCMenuItem* quickPlayButton;
@property (assign) CCMenuItem* storeButton;
@property (nonatomic, readwrite) BOOL authenticationAttempted;

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
@synthesize authenticationAttempted;
-(id)init{
    if (self = [super init]){
#if DEBUG
        [Divinity unlockDivinity];
        [Shop resetDivinity];
        [Shop playerLosesGold:[Shop localPlayerGold]];
        [Shop playerEarnsGold:20000];
#endif
        [[AudioController sharedInstance] addNewPlayerWithTitle:@"title" andURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sounds/title" ofType:@"m4a"]]];
        //Perform Scene Setup   
        NSString *assetsPath = [[NSBundle mainBundle] pathForResource:@"sprites-ipad" ofType:@"plist"  inDirectory:@"assets"];       
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:assetsPath];
        NSString *spellAssetsPath = [[NSBundle mainBundle] pathForResource:@"spell-sprites-ipad" ofType:@"plist"  inDirectory:@"assets"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:spellAssetsPath];
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg-ipad"] autorelease]];
        
        self.multiplayerButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(multiplayerSelected) andTitle:@"Multiplayer"];
        
        self.quickPlayButton= [BasicButton basicButtonWithTarget:self andSelector:@selector(quickPlaySelected) andTitle:@"Play"];
        
        self.storeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(storeSelected) andTitle:@"Spell Shop"];
        
        CCMenuItem *divinityButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(divinitySelected) andTitle:@"Divinity"];
        if (![Divinity isDivinityUnlocked]){
            [divinityButton setIsEnabled:NO];
        }
        
//        NSString *difficultyTitle = [PlayerDataManager hardMode] ? @"Normal Mode" : @"Hard Mode";
//        CCMenuItem *hardModeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(hardModeToggled:) andTitle:difficultyTitle];
//        [hardModeButton setIsEnabled:NO];
        self.menu = [CCMenu menuWithItems:self.quickPlayButton, self.storeButton, self.multiplayerButton, divinityButton/*, hardModeButton*/, nil];
        
        [self.menu alignItemsVerticallyWithPadding:20.0];
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .81, winSize.height * .45)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu];
        
        GoldCounterSprite *goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(900, 50)];
        [self addChild:goldCounter];
        
        CCSprite *logoSprite = [CCSprite spriteWithSpriteFrameName:@"home_logo.png"];
        [logoSprite setAnchorPoint:CGPointMake(0, 0)];
        [self addChild:logoSprite z:5];
        
    }
    return self;
}

-(void)multiplayerSelected{
    if (![PlayerDataManager isMultiplayerUnlocked]){
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
                        [[CCDirector sharedDirector] replaceScene:[CCTransitionRadialCCW transitionWithDuration:.5 scene:queueScene]];
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
        [[CCDirector sharedDirector] replaceScene:[CCTransitionRadialCCW transitionWithDuration:.5 scene:queueScene]];
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
    
    if (firstLaunch){
        BackgroundSprite *bg = [BackgroundSprite launchImageBackground];
        [self addChild:bg z:1001];
        firstLaunch = NO;
        [bg runAction:[CCFadeOut actionWithDuration:1.0]];
    }
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
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInR transitionWithDuration:.5 scene:[[[DivinityConfigScene alloc] init] autorelease]]];
}

- (void)hardModeToggled:(id)sender {
    [PlayerDataManager setHardMode:![PlayerDataManager hardMode]];
    NSString *difficultyTitle = [PlayerDataManager hardMode] ? @"Normal Mode" : @"Hard Mode";
    [(BasicButton*)sender setTitle:difficultyTitle];
}

- (void)dealloc {
    self.menu = nil;
    self.multiplayerButton = nil;
    self.quickPlayButton = nil;
    [super dealloc];
}

@end

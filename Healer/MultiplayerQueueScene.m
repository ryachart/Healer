//
//  MultiplayerQueueScene.m
//  Healer
//
//  Created by Ryan Hart on 7/9/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "MultiplayerQueueScene.h"
#import "MultiplayerSetupScene.h"
#import "AppDelegate.h"
#import "HealerStartScene.h"
#import "Encounter.h"
#import "BackgroundSprite.h"


@interface MultiplayerQueueScene  ()
@property (readwrite) BOOL matchStarted;
@property (readwrite) BOOL authenticationAttempted;
@property (nonatomic, retain) NSString* serverPlayerId;
@property (nonatomic, retain) GKMatch *match;
@property (nonatomic, assign) CCLabelTTF *currentActivityLabel;
@end

@implementation MultiplayerQueueScene


- (void)dealloc {
    [_presentingViewController release];
    [_serverPlayerId release];
    [_match release];
    [super dealloc];
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[[[HealerStartScene alloc] init] autorelease]];
}

- (id)init {
    if (self = [super init]){
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background"] autorelease]];
        CCMenuItemLabel *queueRandom = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Queue Random" dimensions:CGSizeMake(300, 50) hAlignment:kCCTextAlignmentCenter fontName:@"Arial" fontSize:36.0] target:self selector:@selector(queueRandom)];
        
        CCMenu *queueMenu = [CCMenu menuWithItems:queueRandom, nil];
        queueMenu.position = CGPointMake(512, 384);
        [self addChild:queueMenu];
        
        CCMenu *backButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Back" fontName:@"Arial" fontSize:24.0] target:self selector:@selector(back)], nil];
        [backButton setPosition:CGPointMake(40, [CCDirector sharedDirector].winSize.height * .905)];
        [backButton setColor:ccWHITE];
        [self addChild:backButton];
    }
    return self;
}


- (void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    [[GKMatchmaker sharedMatchmaker] queryActivityWithCompletionHandler:^(NSInteger activity, NSError *error){
        if (!error) {
            [self gotActivity:activity];
        }else {
            NSLog(@"Error Fetching Activity: %@", [error description]);
        }
    
    }];
}

- (void)gotActivity:(NSInteger)activity {
    if (!self.currentActivityLabel){
        self.currentActivityLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Server Activity: %i", activity] dimensions:CGSizeMake(300, 50) hAlignment:kCCTextAlignmentCenter fontName:@"Arial" fontSize:28.0];
        [self.currentActivityLabel setPosition:CGPointMake(512, 40)];
        [self addChild:self.currentActivityLabel];
    }else {
        self.currentActivityLabel.string = [NSString stringWithFormat:@"Server Activity: %i", activity];
    }
}

- (void)queueRandom {
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    if (![localPlayer isAuthenticated]){
        if (self.authenticationAttempted){
            return;
        }
        [localPlayer authenticateWithCompletionHandler:^(NSError *error){
            if (!error) {
                [self queueRandom];
                self.authenticationAttempted = YES;
            }else
            {
                NSLog(@"%@", error);
            }
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
        self.presentingViewController = [CCDirector sharedDirector];
        [self.presentingViewController presentViewController:mmvc animated:NO completion:nil];
        
        
        [mmvc release];
    }
}


- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    NSLog(@"MMVC Was Cancelled");
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    [[CCDirector sharedDirector] resume];
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    [[CCDirector sharedDirector] resume];
    NSLog(@"Error finding match: %@", error.localizedDescription);    
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch {
    self.match = theMatch;
    self.match.delegate = self;
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    [[CCDirector sharedDirector] resume];
    
    if (!self.matchStarted && theMatch.expectedPlayerCount == 0) {
        NSLog(@"Ready to start match!");
        [self beginMatch];
    }
}

// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {   
    if (self.match != theMatch) return;
    
    switch (state) {
        case GKPlayerStateConnected: 
            // handle a new player connection.
            NSLog(@"Player connected!");
            if (theMatch.expectedPlayerCount == 0){
                [self beginMatch];
            }
            
            break; 
        case GKPlayerStateDisconnected:
            // a player just disconnected. 
            NSLog(@"Player disconnected!");
            break;
    }                     
}

- (void)beginMatch
{
    
    NSString* localPlayerID = [GKLocalPlayer localPlayer].playerID;
    
    if ([[localPlayerID substringFromIndex:2] intValue] < [[[[self.match playerIDs] objectAtIndex:0] substringFromIndex:2] intValue]){
        self.serverPlayerId = localPlayerID;
    }else{
        self.serverPlayerId = [[self.match playerIDs] objectAtIndex:0];
    }
    [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"ACKSERVER: %@", self.serverPlayerId] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
    
    if ([self.serverPlayerId isEqualToString:localPlayerID]) {
        NSInteger encounterNumber = [Encounter randomMultiplayerEncounter].levelNumber;
        [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"LEVELNUM|%i", encounterNumber] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
        
        MultiplayerSetupScene *mpss = [[MultiplayerSetupScene alloc] initWithPreconfiguredMatch:self.match andServerID:self.serverPlayerId andLevelNumber:encounterNumber];
        self.match.delegate = mpss;
        [[CCDirector sharedDirector] replaceScene:mpss];
        [mpss release];
    }

}

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    if (self.match != theMatch) return;
    
    NSString* message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"message: %@", message);
    NSArray *components = nil;
    
    if ([message hasPrefix:@"LEVELNUM"]){
        components = [message componentsSeparatedByString:@"|"];
        MultiplayerSetupScene *mpss = [[MultiplayerSetupScene alloc] initWithPreconfiguredMatch:self.match andServerID:self.serverPlayerId andLevelNumber:[[components objectAtIndex:1] intValue]];
        self.match.delegate = mpss;
        [[CCDirector sharedDirector] replaceScene:mpss];
        [mpss release];
    }

    [message release];
}
@end

//
//  MultiplayerSetupScene.m
//  Healer
//
//  Created by Ryan Hart on 4/4/12.
//

#import "MultiplayerSetupScene.h"
#import "Raid.h"
#import "Player.h"
#import "Enemy.h"
#import "Spell.h"
#import "Encounter.h"
#import "GamePlayScene.h"
#import <GameKit/GameKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BackgroundSprite.h"
#import "MultiplayerQueueScene.h"
#import "BasicButton.h"
#import "PlayerDataManager.h"

@interface MultiplayerSetupScene ()
@property (nonatomic, retain) Raid *raid;
@property (nonatomic, retain) Enemy *boss;
@property (nonatomic, assign) CCMenu *menu;
@property (nonatomic, assign) CCMenu *encounterSelectMenu;
@property (nonatomic, assign) CCMenuItemLabel *beginButton;
@property (nonatomic, retain) NSMutableArray *waitingOnPlayers;
@property (nonatomic, retain) NSMutableDictionary *otherPlayers;
@property (nonatomic, readwrite) BOOL isPreconfiguredMatch;
@property (nonatomic, readwrite) BOOL isCommittedToReady;

- (void)beginGame;
- (void)generateRaidMemberFromServerWithClass:(NSString*)className andBattleID:(NSString*)battleID;
@end

@implementation MultiplayerSetupScene
@synthesize match, serverPlayerID, matchVoiceChat, waitingOnPlayers, isPreconfiguredMatch;
@synthesize menu, beginButton, raid, boss, selectedEncounter, encounterSelectMenu;
@synthesize isCommittedToReady;
@synthesize otherPlayers;
- (void)dealloc {
    [match release];
    [matchVoiceChat release];
    [serverPlayerID release];
    [selectedEncounter release];
    [waitingOnPlayers release];
    [otherPlayers release];
    [raid release];
    [boss release];
    [super dealloc];
}

#pragma mark GKMatchDelegate

- (id)initWithPreconfiguredMatch:(GKMatch*)preConMatch andServerID:(NSString*)serverID andLevelNumber:(NSInteger)levelNum{
    Encounter *encounter = [Encounter encounterForLevel:levelNum isMultiplayer:YES];
    Player *player = [PlayerDataManager playerFromLocalPlayer];
    [player configureForRecommendedSpells:encounter.recommendedSpells withLastUsedSpells:[PlayerDataManager localPlayer].lastUsedSpells];
    
    if (self = [super initWithEncounter:encounter andPlayer:player]){
        self.match = preConMatch;
        self.serverPlayerID = serverID;
        self.isPreconfiguredMatch = YES;
        if (self.isServer){
            self.waitingOnPlayers = [NSMutableArray arrayWithArray: self.match.playerIDs];
            self.otherPlayers = [NSMutableDictionary  dictionaryWithCapacity:self.match.playerIDs.count];
        }
    }

    return self;
}

- (BOOL)canBegin {
    if (!self.isServer){
        return NO;
    }
    BOOL canBegin = YES;
    for (NSString *playerID in self.waitingOnPlayers){
        if (![self.otherPlayers objectForKey:playerID]){
            canBegin = NO;
        }
    }
    return canBegin;
}

- (void)changeSpells {
    if (!self.isCommittedToReady) {
        [super changeSpells];
    }
}

- (void)back{
    if (self.matchVoiceChat){
        [self.matchVoiceChat stop];
    }
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:1.0 scene:[[[MultiplayerQueueScene alloc] init] autorelease]]];
}

- (void)doneButton{
    if (!self.isServer && !self.isCommittedToReady){
        [match sendData:[[[PlayerDataManager localPlayer] playerMessage] dataUsingEncoding:NSUTF8StringEncoding] toPlayers:[NSArray arrayWithObject:self.serverPlayerID] withDataMode:GKSendDataReliable error:nil];
        self.isCommittedToReady = YES;
    }
    else if ([self canBegin]) {
        NSMutableArray *allPlayers = [NSMutableArray arrayWithCapacity:2];
        [allPlayers addObject:self.player];
        
        for (NSString* playerID in self.waitingOnPlayers) {
            Player *otherPlayer = [self.otherPlayers objectForKey:playerID];
            [otherPlayer setPlayerID:playerID];
            [otherPlayer setIsLocalPlayer:NO];
            [allPlayers addObject:otherPlayer];
        }
        [self.player setPlayerID:self.serverPlayerID];
        [self.boss setIsMultiplayer:YES];
        [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"BEGIN"] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
        GamePlayScene *gps = [[GamePlayScene alloc] initWithEncounter:self.encounter andPlayers:allPlayers];
        [self.match setDelegate:gps];
        [gps setServerPlayerID:self.serverPlayerID];
        [gps setMatch:self.match];
        [gps setMatchVoiceChat:self.matchVoiceChat];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:.5 scene:gps]];
        [gps release];
    }
}

- (void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    if (self.isPreconfiguredMatch){
        if (!self.matchVoiceChat) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            self.matchVoiceChat = [self.match voiceChatWithName:@"general"];
            [self.matchVoiceChat start];
            [self.matchVoiceChat setActive:YES];
        }
        
        if (self.isServer){
            [self.continueButton setTitle:@"Waiting..."];
        }else {
            [self.continueButton setTitle:@"Commit"];
        }
    }
}

- (void)serverAddRaidMember:(RaidMember*)member{
    if (self.isServer){
        int i = self.raid.raidMembers.count;
        [member setNetworkId:[NSString stringWithFormat:@"%@%i", [member class], i]];
        [self.raid addRaidMember:member];
        [match sendDataToAllPlayers:[[NSString stringWithFormat:@"ADDRM|%@|%@%i",[member class], [member class], i] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
    }
}

- (void)beginGame{
    [self.player setPlayerID:[GKLocalPlayer localPlayer].playerID];
    GamePlayScene *gps = [[GamePlayScene alloc] initWithEncounter:self.encounter player:self.player];
    [self.match setDelegate:gps];
    [gps setMatch:self.match];
    [gps setMatchVoiceChat:self.matchVoiceChat];
    [gps setIsClient:YES forServerPlayerId:self.serverPlayerID];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
    [gps release];
}

- (BOOL)isServer{
    if ([self.serverPlayerID isEqualToString:[GKLocalPlayer localPlayer].playerID]){
        return YES;
    }
    return NO;
}

- (void)generateRaidMemberFromServerWithClass:(NSString*)className andBattleID:(NSString*)battleID{
    if (!self.raid){
        self.raid = [[[Raid alloc] init] autorelease];
    }
    
    RaidMember *member = [[NSClassFromString(className) alloc] init];
    [member setNetworkId:battleID];
    [self.raid addRaidMember:member];
    [member release];
    
}

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {    
    if (match != theMatch) return;
    
    NSString* message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (self.isServer){
        if ([message isEqualToString:@"PLRDY"]){
            [self.waitingOnPlayers removeObject:playerID];
        }
        
        if ([message hasPrefix:@"PLAYER|"]) {

            
            Player *player = [PlayerDataManager playerFromPlayerMessage:message];

            [self.otherPlayers setObject:player forKey:playerID];
            if ([self canBegin]){
                [self.continueButton setTitle:@"Battle!"];
            }
            
        }
    }
    
    if ([message isEqualToString:@"BEGIN"]){
        [self beginGame];
    }
    
    if ([message hasPrefix:@"ADDRM"]){
        NSArray *messageComponents = [message componentsSeparatedByString:@"|"];
        
        if (messageComponents.count < 3){
            NSLog(@"MALFORMED ADDRM MESSAGE!");
        }
        NSString* className = [messageComponents objectAtIndex:1];
        NSString* battleID = [messageComponents objectAtIndex:2];
        [self generateRaidMemberFromServerWithClass:className andBattleID:battleID];
    }
    
    [message release];
}

// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {   
    if (match != theMatch) return;
    
    switch (state) {
        case GKPlayerStateConnected: 
            
            break; 
        case GKPlayerStateDisconnected:
            // a player just disconnected. 
            NSLog(@"Player disconnected!");
            if ([theMatch playerIDs].count == 0){
                UIAlertView *noPlayersLeft = [[[UIAlertView alloc] initWithTitle:@"Player Disconnected" message:@"There are no remaining players.  This game will not be able to continue." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil] autorelease];
                [noPlayersLeft show];
            }
            
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

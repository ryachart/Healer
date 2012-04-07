//
//  MultiplayerSetupScene.m
//  Healer
//
//  Created by Ryan Hart on 4/4/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "MultiplayerSetupScene.h"
#import "Raid.h"
#import "Player.h"
#import "Boss.h"
#import "Spell.h"
#import "GamePlayScene.h"
#import <GameKit/GameKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MultiplayerSetupScene ()
@property (nonatomic, retain) Raid *raid;
@property (nonatomic, retain) Boss *boss;
@property (nonatomic, assign) CCMenu *menu;
@property (nonatomic, assign) CCMenuItemLabel *beginButton;

-(void)beginGame;

-(void)generateRaidMemberFromServerWithClass:(NSString*)className andBattleID:(NSString*)battleID;
@end

@implementation MultiplayerSetupScene
@synthesize match, serverPlayerID;
@synthesize menu, beginButton, raid, boss;

#pragma mark GKMatchDelegate

-(id)init{
    if (self = [super init]){
        
        self.beginButton= [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Begin" fontName:@"Arial" fontSize:32] target:self selector:@selector(beginGame)] autorelease];
        [self.beginButton setOpacity:111];
        [self.beginButton setIsEnabled:NO];
        
        self.menu = [CCMenu menuWithItems:self.beginButton, nil];
        
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .5, winSize.height * 1/3)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu];
    }
    return self;
}

-(void)serverAddRaidMember:(RaidMember*)member{
    int i = self.raid.raidMembers.count;
    [member setBattleID:[NSString stringWithFormat:@"%@%i", [member class], i]];
    [self.raid addRaidMember:member];
    [match sendDataToAllPlayers:[[NSString stringWithFormat:@"ADDRM|%@|%@%i",[member class], [member class], i] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
}

-(void)beginGame{
    if (!self.raid){
        self.raid = [[[Raid alloc] init] autorelease];
    }
    Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
    [basicPlayer setPlayerID:[GKLocalPlayer localPlayer].playerID];
    Boss *basicBoss = [SporeRavagers defaultBoss];
    [basicBoss setIsMultiplayer:YES];
    [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [HealingBurst defaultSpell], [Regrow defaultSpell], nil]];

    for (int i = 0; i < 7; i++){
        if (self.isServer){
            [self serverAddRaidMember:[Soldier defaultSoldier]]; 
        }
    }
    for (int i = 0; i < 4; i++){
        if (self.isServer){
            [self serverAddRaidMember:[Champion defaultChampion]];
        }
    }
    for (int i = 0; i < 3; i++){
        if (self.isServer){
            [self serverAddRaidMember:[Guardian defaultGuardian]];
        }
    }
    for (int i = 0; i < 3; i++){
        if (self.isServer){
            [self serverAddRaidMember:[Wizard defaultWizard]];
        }
    }
    for (int i = 0; i < 3; i++){
        if (self.isServer){
            [self serverAddRaidMember:[Demonslayer defaultDemonslayer]];
        }
    }
    
    GamePlayScene *gps = nil;
    
    if (self.isServer){
        Player *otherPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        [otherPlayer setIsAudible:NO];
        [otherPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], [GreaterHeal defaultSpell], [HealingBurst defaultSpell], [Regrow defaultSpell], nil]];
        [otherPlayer setPlayerID:[[self.match playerIDs] objectAtIndex:0]];
        gps = [[GamePlayScene alloc] initWithRaid:self.raid boss:basicBoss andPlayers:[NSArray arrayWithObjects:basicPlayer, otherPlayer, nil]];
        [otherPlayer release];
    }else{
        gps = [[GamePlayScene alloc] initWithRaid:self.raid boss:basicBoss andPlayer:basicPlayer];
    }
    if (self.isServer){
        [gps setIsServer:YES];
    }else{
        [gps setIsClient:YES];
    }

    [gps setLevelNumber:-1];
    [self.match setDelegate:gps];
    [gps setMatch:self.match];

    [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
    [basicPlayer release];
    [gps release];
    
    if (self.isServer){
        [match sendDataToAllPlayers:[[NSString stringWithFormat:@"BEGIN"] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
    }
}

-(BOOL)isServer{
    if ([self.serverPlayerID isEqualToString:[GKLocalPlayer localPlayer].playerID]){
        return YES;
    }
    return NO;
}

-(void)generateRaidMemberFromServerWithClass:(NSString*)className andBattleID:(NSString*)battleID{
    if (!self.raid){
        self.raid = [[[Raid alloc] init] autorelease];
    }
    
    RaidMember *member = [[NSClassFromString(className) alloc] init];
    [member setBattleID:battleID];
    [self.raid addRaidMember:member];
    [member release];
    
}

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {    
    if (match != theMatch) return;
    
    NSString* message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"message: %@", message);
    
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
            // handle a new player connection.
            NSLog(@"Player connected!");
            if (theMatch.expectedPlayerCount == 0){
                NSString* localPlayerID = [GKLocalPlayer localPlayer].playerID;
                
                if ([[localPlayerID substringFromIndex:2] intValue] < [[[[theMatch playerIDs] objectAtIndex:0] substringFromIndex:2] intValue]){
                    self.serverPlayerID = localPlayerID;
                }else{
                    self.serverPlayerID = [[theMatch playerIDs] objectAtIndex:0];
                }
                [match sendDataToAllPlayers:[[NSString stringWithFormat:@"ACKSERVER: %@", self.serverPlayerID] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
                
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
                [[AVAudioSession sharedInstance] setActive:YES error:nil];
                
                GKVoiceChat *voiceChannel = [[theMatch voiceChatWithName:@"mender"] retain];
                [voiceChannel start];
                [voiceChannel setActive:YES];

                
                if (self.isServer){
                    self.beginButton.isEnabled = YES;
                    [self.beginButton setOpacity:255];
                }
            }
            
            break; 
        case GKPlayerStateDisconnected:
            // a player just disconnected. 
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

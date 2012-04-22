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
#import "Encounter.h"
#import "GamePlayScene.h"
#import <GameKit/GameKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MultiplayerSetupScene ()
@property (nonatomic, retain) Raid *raid;
@property (nonatomic, retain) Boss *boss;
@property (nonatomic, assign) CCMenu *menu;
@property (nonatomic, assign) CCMenu *encounterSelectMenu;
@property (nonatomic, assign) CCMenuItemLabel *beginButton;
@property (nonatomic, retain) NSMutableArray *waitingOnPlayers;
@property (nonatomic, readwrite) BOOL isPreconfiguredMatch;

-(void)beginGame;
-(void)encounterSelected:(id)sender;
-(void)generateRaidMemberFromServerWithClass:(NSString*)className andBattleID:(NSString*)battleID;
@end

@implementation MultiplayerSetupScene
@synthesize match, serverPlayerID, matchVoiceChat, waitingOnPlayers, isPreconfiguredMatch;
@synthesize menu, beginButton, raid, boss, selectedEncounter, encounterSelectMenu;

#pragma mark GKMatchDelegate

-(id)initWithPreconfiguredMatch:(GKMatch*)preConMatch andServerID:(NSString*)serverID{
    if (self = [self init]){
        self.match = preConMatch;
        self.serverPlayerID = serverID;
        self.isPreconfiguredMatch = YES;
        if (self.isServer){
            self.waitingOnPlayers = [NSMutableArray arrayWithArray: self.match.playerIDs];
        }
    }
    return self;
}

-(id)init{
    if (self = [super init]){
        
        self.beginButton= [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Begin" fontName:@"Arial" fontSize:32] target:self selector:@selector(beginGame)] autorelease];
        [self.beginButton setOpacity:111];
        [self.beginButton setIsEnabled:NO];
        
        self.encounterSelectMenu = [CCMenu menuWithItems:nil];
        for (int i = 0; i < 8; i++){
            Encounter *encounter = [Encounter encounterForLevel:i+1 isMultiplayer:YES];
            CCMenuItemLabel *levelButton = [[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@", encounter.boss.title] fontName:@"Arial" fontSize:32] target: self selector:@selector(encounterSelected:)];
            levelButton.tag = i +1;
            [levelButton setOpacity:125];
            levelButton.isEnabled = NO;
            [self.encounterSelectMenu addChild:levelButton];
        }
        [self.encounterSelectMenu setPosition:ccp([CCDirector sharedDirector].winSize.width /2, [CCDirector sharedDirector].winSize.height / 2)];
        [self.encounterSelectMenu setColor:ccc3(255, 255, 255)];
        [self.encounterSelectMenu alignItemsInRows:[NSNumber numberWithInt:8]/*,[NSNumber numberWithInt:10]*/, nil];
        [self addChild:self.encounterSelectMenu];
        
        self.menu = [CCMenu menuWithItems:self.beginButton, nil];
        
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .8, winSize.height * .2)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu];
    }
    return self;
}

-(void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    if (self.isPreconfiguredMatch){
        if (self.isServer){
            [match sendDataToAllPlayers:[@"POSTBATTLEEND" dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
            for (CCMenuItemLabel *child in self.encounterSelectMenu.children){
                [child setIsEnabled:YES];
            }
        }
        else{
            [self.match sendData:[@"PLRDY" dataUsingEncoding:NSUTF8StringEncoding] toPlayers:[NSArray arrayWithObject:self.serverPlayerID] withDataMode:GKMatchSendDataReliable error:nil];
        }
    }
}

-(void)serverAddRaidMember:(RaidMember*)member{
    if (self.isServer){
        int i = self.raid.raidMembers.count;
        [member setBattleID:[NSString stringWithFormat:@"%@%i", [member class], i]];
        [self.raid addRaidMember:member];
        [match sendDataToAllPlayers:[[NSString stringWithFormat:@"ADDRM|%@|%@%i",[member class], [member class], i] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
    }
}

-(void)clientEncounterSelected:(int)level{
    for (CCMenuItemLabel *child in self.encounterSelectMenu.children){
        [child setOpacity:125];
    }
    [(CCMenuItemLabel*)[self.encounterSelectMenu getChildByTag:level] setOpacity:255];
    self.selectedEncounter = [Encounter encounterForLevel:level isMultiplayer:YES];
}

-(void)encounterSelected:(CCMenuItemLabel*)sender{
    int level = sender.tag;
    if (self.isServer){
        for (CCMenuItemLabel *child in self.encounterSelectMenu.children){
            [child setOpacity:125];
        }
        [sender setOpacity:255];
        self.selectedEncounter = [Encounter encounterForLevel:level isMultiplayer:YES];
        [match sendDataToAllPlayers:[[NSString stringWithFormat:@"ENCSEL|%i|",level] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
        self.beginButton.isEnabled = YES;
        [self.beginButton setOpacity:255];
    }
}

-(void)beginGame{
    if (self.isServer && self.encounterSelectMenu && self.waitingOnPlayers.count == 0){
        Player *serverPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        NSMutableArray *activeSpells = [NSMutableArray arrayWithCapacity:4];
        for (Spell *spell in self.selectedEncounter.activeSpells){
            [activeSpells addObject:[[spell class] defaultSpell]];
        }
        [serverPlayer setActiveSpells:(NSArray*)activeSpells];
        
        
        NSMutableArray *totalPlayers = [NSMutableArray arrayWithCapacity:4];
        [totalPlayers addObject:serverPlayer];
        [serverPlayer release];
        
        for (int i = 0; i < match.playerIDs.count; i++){
            //Add other players
            Player *clientPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
            [clientPlayer setIsAudible:NO];
            [clientPlayer setPlayerID:[match.playerIDs objectAtIndex:i]];
            NSMutableArray *activeSpells = [NSMutableArray arrayWithCapacity:4];
            for (Spell *spell in self.selectedEncounter.activeSpells){
                [activeSpells addObject:[[spell class] defaultSpell]];
            }
            [clientPlayer setActiveSpells:(NSArray*)activeSpells];
            [totalPlayers addObject:clientPlayer];
            [clientPlayer release];
        }
        [match sendDataToAllPlayers:[@"BEGIN" dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
        
        GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:self.selectedEncounter.raid boss:self.selectedEncounter.boss andPlayers:totalPlayers];
        [self.match setDelegate:gps];
        [gps setMatch:self.match];
        [gps setServerPlayerID:[GKLocalPlayer localPlayer].playerID];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
        [gps release];
    }else{
        NSLog(@"SERVER DOESNT HAVE A SELECTED ENCOUNTER");
    }
    
    if (!self.isServer && self.encounterSelectMenu){
        Player *clientPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
        [clientPlayer setPlayerID:[GKLocalPlayer localPlayer].playerID];
        NSMutableArray *activeSpells = [NSMutableArray arrayWithCapacity:4];
        for (Spell *spell in self.selectedEncounter.activeSpells){
            [activeSpells addObject:[[spell class] defaultSpell]];
        }
        [clientPlayer setActiveSpells:(NSArray*)activeSpells];
        GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:self.selectedEncounter.raid boss:self.selectedEncounter.boss andPlayer:clientPlayer];
        [self.match setDelegate:gps];
        [gps setMatch:self.match];
        [gps setMatchVoiceChat:self.matchVoiceChat];
        [gps setIsClient:YES forServerPlayerId:self.serverPlayerID];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
        [gps release];
        [clientPlayer release];
    }else{
        NSLog(@"CLIENT DOESNT HAVE A SELECTED ENCOUNTER");
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
    
    if (self.isServer){
        if ([message isEqualToString:@"PLRDY"]){
            [self.waitingOnPlayers removeObject:playerID];
            if (self.selectedEncounter){
                [match sendData:[[NSString stringWithFormat:@"ENCSEL|%i|",self.selectedEncounter.levelNumber] dataUsingEncoding:NSUTF8StringEncoding] toPlayers:[NSArray arrayWithObject:playerID] withDataMode:GKSendDataReliable error:nil];
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
    
    if ([message hasPrefix:@"ENCSEL|"]){
        [self clientEncounterSelected:[[message substringFromIndex:7] intValue]];
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
                
                self.matchVoiceChat = [theMatch voiceChatWithName:@"mender"];
                [self.matchVoiceChat start];
                [self.matchVoiceChat setActive:YES];
                
                if (self.isServer){
                    for (CCMenuItemLabel *child in self.encounterSelectMenu.children){
                        [child setIsEnabled:YES];
                    }
                }
            }
            
            break; 
        case GKPlayerStateDisconnected:
            // a player just disconnected. 
            NSLog(@"Player disconnected!");
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

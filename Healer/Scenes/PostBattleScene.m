//
//  PostBattleScene.m
//  Healer
//
//  Created by Ryan Hart on 3/3/12.
//

#import "PostBattleScene.h"
#import "LevelSelectMapScene.h"
#import "MultiplayerSetupScene.h"
#import "CombatEvent.h"
#import "Boss.h"
#import "Encounter.h"
#import "PlayerDataManager.h"
#import <UIKit/UIKit.h>
#import "Shop.h"
#import "ShopScene.h"
#import "BackgroundSprite.h"
#import "TestFlight.h"
#import "Divinity.h"
#import "DivinityConfigScene.h"
#import "AudioController.h"
#import "HealerStartScene.h"
#import "BasicButton.h"
#import "Encounter.h"
#import "Raid.h"
#import "CCNumberChangeAction.h"


@interface PostBattleScene ()
@property (nonatomic, readwrite) BOOL isMultiplayer;
@property (nonatomic, readwrite) BOOL isVictory;
@property (nonatomic, readwrite) BOOL otherPlayerHasQueued;
@property (nonatomic, readwrite) BOOL localPlayerHasQueued;
@property (nonatomic, assign) CCLabelTTF *healingDoneLabel;
@property (nonatomic, assign) CCLabelTTF *overhealingDoneLabel;
@property (nonatomic, assign) CCLabelTTF *damageTakenLabel;
@property (nonatomic, assign) CCMenuItem *queueAgainMenuItem;
@property (nonatomic, retain) Encounter *encounter;

@end

@implementation PostBattleScene
@synthesize matchVoiceChat, serverPlayerId;
@synthesize isMultiplayer;
@synthesize isVictory;
@synthesize healingDoneLabel;
@synthesize overhealingDoneLabel;
@synthesize damageTakenLabel;
@synthesize queueAgainMenuItem;
@synthesize otherPlayerHasQueued;
@synthesize localPlayerHasQueued;

- (void)dealloc {
    [_match release];
    [serverPlayerId release];
    [matchVoiceChat release];
    [_encounter release];
    [super dealloc];
}

- (id)initWithVictory:(BOOL)victory encounter:(Encounter*)enc andIsMultiplayer:(BOOL)isMult andDuration:(NSTimeInterval)duration {
    self = [super init];
    if (self){
        self.encounter = enc;
        self.isMultiplayer = isMult;
        self.isVictory = victory;
        NSInteger reward = 0;
        NSInteger oldRating = 0;
        NSInteger rating = 0;
        NSInteger numDead = self.encounter.raid.deadCount;
        NSTimeInterval fightDuration = duration;
        
        int totalHealingDone = self.encounter.healingDone;
        int overheal = self.encounter.overhealingDone; 
        int totalDamageTaken = self.encounter.damageTaken;
        
        //Data Operations
        if (victory){
            [TestFlight passCheckpoint:[NSString stringWithFormat:@"LevelComplete:%i",self.encounter.levelNumber]];
            if (!self.isMultiplayer){
                [PlayerDataManager completeLevel:self.encounter.levelNumber];
            }
            reward = [self.encounter reward];
            
            oldRating = [PlayerDataManager levelRatingForLevel:self.encounter.levelNumber];
            rating = self.encounter.rating;
            if (rating > oldRating && !self.isMultiplayer){
                if (self.encounter.difficulty > 1) {
                    reward += 25; //Completing a new difficulty bonus, basically.
                }
                [PlayerDataManager setLevelRating:rating forLevel:self.encounter.levelNumber];
            }
        }else {
            [TestFlight passCheckpoint:[NSString stringWithFormat:@"LevelFailed:%i",self.encounter.levelNumber]];
            [PlayerDataManager failLevelInCurrentMode:self.encounter.levelNumber];
            //Partial Progress Reward
            //10 % of the Reward per minute of encounter up to a maximum of 50% encounter reward
            
            NSInteger encounterRewardForSuccess = self.encounter.reward;
            NSInteger partialProgressReward = 0;
            
            if (totalHealingDone >= (totalDamageTaken * .33)){
                partialProgressReward = (fightDuration / 60.0 * (encounterRewardForSuccess * .10));
                partialProgressReward =  MIN(partialProgressReward, encounterRewardForSuccess * .5);
            }
            reward = partialProgressReward;
        }
        
        if (self.encounter.levelNumber == ENDLESS_VOID_ENCOUNTER_NUMBER){
            reward  = [Encounter goldRewardForSurvivalEncounterWithDuration:fightDuration];
        }
        
        if (reward > 0){
            [Shop playerEarnsGold:reward];
        }
        
        [PlayerDataManager saveRemotePlayer];
        
        //UI
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background"] autorelease]];
        if (victory){
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"VICTORY!" fontName:@"Arial" fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
            
            if (enc.levelNumber != 1) {
                CCLabelTTF *scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Score: %i", self.encounter.score] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:36.0];
                [scoreLabel setPosition:CGPointMake(200, 300)];
                [self addChild:scoreLabel];
                
                if (rating > oldRating && !self.isMultiplayer){
//                    CCLabelTTF *newHighScore = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"New High Score!"] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:40.0];
//                    [newHighScore setColor:ccGREEN];
//                    [newHighScore setPosition:CGPointMake(200, 360)];
//                    [self addChild:newHighScore];
//                    [newHighScore runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCScaleTo  actionWithDuration:.75 scale:1.2], [CCScaleTo actionWithDuration:.75 scale:1.0], nil]]];
                }
            }
            
        }else{
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"DEFEAT!" fontName:@"Arial" fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
        }
        
        if (reward > 0){
            CCLabelTTF *goldEarned = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold Earned: %i", reward] fontName:@"Arial" fontSize:32.0];            
            [goldEarned setPosition:CGPointMake(800, 150)];
            [self addChild:goldEarned];
        }
    
        NSString* doneLabelString = self.isMultiplayer ? @"Leave Group" : @"Continue";
        CCMenuItem *done = [BasicButton basicButtonWithTarget:self andSelector:@selector(done) andTitle:doneLabelString];
        CCMenu *menu = [CCMenu menuWithItems:nil];
        menu.position = CGPointMake(512, 200);
        [self addChild:menu];
        
        if (enc.levelNumber != 1) {
            [menu addChild:done];
        }
        
        if (self.isMultiplayer){
            self.queueAgainMenuItem = [BasicButton basicButtonWithTarget:self andSelector:@selector(queueAgain) andTitle:@"Battle Again"];
            [menu addChild:self.queueAgainMenuItem];
            [menu alignItemsVertically];
        }else {
            CCMenuItem *visitShopButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(goToStore) andTitle:@"Academy"];
            [menu addChild:visitShopButton];
            [menu alignItemsVertically];
        }
        
        self.healingDoneLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Healing Done: %i", totalHealingDone] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [self.healingDoneLabel setPosition:CGPointMake(200, 200)];
        
        self.overhealingDoneLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Overhealing: %i", overheal] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [self.overhealingDoneLabel setPosition:CGPointMake(200, 160)];
        
        self.damageTakenLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Damage Taken: %i", totalDamageTaken] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [self.damageTakenLabel setPosition:CGPointMake(200, 120)];
        
        CCLabelTTF *playersLostLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Allies Lost:  %i", numDead] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [playersLostLabel setPosition:CGPointMake(200, 80)];
        
        [self addChild:self.healingDoneLabel];
        [self addChild:self.overhealingDoneLabel];
        [self addChild:self.damageTakenLabel];
        [self addChild:playersLostLabel];
        
        NSString *durationText = [@"Duration: " stringByAppendingString:[self timeStringForTimeInterval:fightDuration]];
        
        CCLabelTTF *durationLabel = [CCLabelTTF labelWithString:durationText dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [durationLabel setPosition:CGPointMake(200, 240)];
        [self addChild:durationLabel];
        
#if DEBUG
        [self.encounter saveCombatLog];
#endif
    }
    return self;
}

- (NSString*)timeStringForTimeInterval:(NSTimeInterval)interval{
    NSInteger minutes = interval / 60;
    NSInteger seconds = (int)interval % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

- (void)showRemotePlayerStats:(NSInteger)healingDone andOverhealing:(NSInteger)overhealing {
    CCLabelTTF *otherPlayersStatsLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Other Player Stats"] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:30.0];
    [otherPlayersStatsLabel setPosition:CGPointMake(900, 730)];
    [self addChild:otherPlayersStatsLabel];
    
    CCLabelTTF *otherHealingDoneLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Healing Done: %i", healingDone] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
    [otherHealingDoneLabel setPosition:CGPointMake(900, 680)];
    [self addChild:otherHealingDoneLabel];
    
    CCLabelTTF *otherOverhealingDoneLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Overhealing: %i", overhealing] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
    [otherOverhealingDoneLabel setPosition:CGPointMake(900, 630)];
    [self addChild:otherOverhealingDoneLabel];
}

- (void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    if (self.encounter.levelNumber >= 6 && ![Divinity isDivinityUnlocked] && !self.isMultiplayer && self.isVictory){
        [Divinity unlockDivinity];
        [self showDivinityUnlocked];
    }
    
    if (self.isMultiplayer) {
        if ([self.serverPlayerId isEqualToString:[GKLocalPlayer localPlayer].playerID]){
            //We are the server.  Lets figure out the stats!
            NSDictionary *localStats = [CombatEvent statsForPlayer:[GKLocalPlayer localPlayer].playerID fromLog:self.encounter.combatLog];
            NSDictionary *remoteStats = [CombatEvent statsForPlayer:[self.match.playerIDs objectAtIndex:0] fromLog:self.encounter.combatLog];
            int localTotalHealingDone = [[localStats objectForKey:PlayerHealingDoneKey] intValue];
            int localOverheal = [[localStats objectForKey:PlayerOverHealingDoneKey] intValue];
            
            int remoteTotalHealingDone = [[remoteStats objectForKey:PlayerHealingDoneKey] intValue];
            int remoteOverheal = [[remoteStats objectForKey:PlayerOverHealingDoneKey] intValue];
            
            int totalDamageTaken = 0;
            for (CombatEvent *event in self.encounter.combatLog){
                if (event.type == CombatEventTypeDamage && [[event source] isKindOfClass:[Boss class]]){
                    NSInteger dmgVal = [[event value] intValue];
                    totalDamageTaken +=  abs(dmgVal);            
                }
            }
            
            [self showRemotePlayerStats:remoteTotalHealingDone andOverhealing:remoteOverheal];
            [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"STATS|%i|%i|%i|%i|%i", localTotalHealingDone, localOverheal, remoteTotalHealingDone, remoteOverheal, totalDamageTaken] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
        }
    }

    CCNumberChangeAction *numberChangeAction = [CCNumberChangeAction actionWithDuration:8.0 fromNumber:0 toNumber:self.encounter.damageTaken];
    [numberChangeAction setPrefix:@"Damage Taken: "];
    [self.damageTakenLabel runAction:numberChangeAction];

}

- (void)onExit {
    [[AudioController sharedInstance] stopAll];
    [[AudioController sharedInstance] playTitle:@"title" looping:10];
    [super onExit];
}

-(void)setMatch:(GKMatch *)mtch{
    [_match release];
    _match = [mtch retain];
    [self.match setDelegate:self];
}

- (void)beginNextGame {
    NSInteger encounterNumber = [Encounter randomMultiplayerEncounter].levelNumber;
    [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"LEVELNUM|%i", encounterNumber] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
    
    MultiplayerSetupScene *mpss = [[[MultiplayerSetupScene alloc] initWithPreconfiguredMatch:self.match andServerID:self.serverPlayerId andLevelNumber:encounterNumber] autorelease];
    self.match.delegate = mpss;
    [mpss setMatchVoiceChat:self.matchVoiceChat];
    [[CCDirector sharedDirector] replaceScene:mpss];
}

- (void)queueAgain {
    if (self.localPlayerHasQueued) return;
    
    BOOL isServer = [self.serverPlayerId isEqualToString:[GKLocalPlayer localPlayer].playerID];
    self.localPlayerHasQueued = YES;
    if (isServer){
        if (self.otherPlayerHasQueued){
            [self beginNextGame];
        }
    }else {
        [self.match sendData:[[NSString stringWithFormat:@"QAGAIN"] dataUsingEncoding:NSUTF8StringEncoding] toPlayers:[NSArray arrayWithObject:self.serverPlayerId] withDataMode:GKMatchSendDataReliable error:nil];
    }
}
                            
- (void)done{
    if (self.isMultiplayer){
        if (self.matchVoiceChat){
            [self.matchVoiceChat stop];
        }
        [[CCDirector sharedDirector] replaceScene:[CCTransitionJumpZoom transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
    }else{
        LevelSelectMapScene *qps = [[[LevelSelectMapScene alloc] init] autorelease];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:.5 scene:qps]];
    }
}

- (void)showDivinityUnlocked {
    CCMenuItemLabel *goToDivinity = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Go to Divinity" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(goToDivinity)];
    CCMenu *goToDivinityMenu = [CCMenu menuWithItems:goToDivinity, nil];
    [goToDivinityMenu setOpacity:0];
    [goToDivinityMenu setPosition:CGPointMake(512, 520)];
    [self addChild:goToDivinityMenu];
    
    CCLabelTTF *divinityUnlocked = [CCLabelTTF labelWithString:@"DIVINITY UNLOCKED!" dimensions:CGSizeMake(600, 200) hAlignment:UITextAlignmentCenter fontName:@"Arial" fontSize:72.0];
    [divinityUnlocked setColor:ccYELLOW];
    [divinityUnlocked setPosition:CGPointMake(512, 614)];
    [divinityUnlocked setScale:3.0];
    [divinityUnlocked setOpacity:0];
    [self addChild:divinityUnlocked];
    
    [divinityUnlocked runAction:[CCSequence actions:[CCSpawn actions:[CCFadeIn actionWithDuration:1.5], [CCScaleTo actionWithDuration:.5 scale:1.0], nil], [CCCallBlock actionWithBlock:^{[goToDivinityMenu runAction:[CCFadeIn actionWithDuration:1.0]];}], nil]];
    
}
                                                                    
- (void)goToDivinity {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:.5 scene:[[[DivinityConfigScene alloc] init] autorelease]]];
}

- (void)goToStore {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:.5 scene:[[ShopScene new] autorelease]]];
}

#pragma mark - GKMatchDelegate
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {    
    if (self.match != theMatch) return;
    BOOL isServer = [self.serverPlayerId isEqualToString:[GKLocalPlayer localPlayer].playerID];
    NSString* message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (!isServer){
        if ([message hasPrefix:@"STATS|"]){
            NSArray *components = [message componentsSeparatedByString:@"|"];
            NSInteger remoteHealingDone = [[components objectAtIndex:1] intValue];
            NSInteger remoteOverHealing = [[components objectAtIndex:2] intValue];
            NSInteger localHealingDone = [[components objectAtIndex:3] intValue];
            NSInteger localOverhealing = [[components objectAtIndex:4] intValue];
            NSInteger damageTaken = [[components objectAtIndex:5] intValue];
            
            [self showRemotePlayerStats:remoteHealingDone andOverhealing:remoteOverHealing];
            
            self.healingDoneLabel.string = [NSString stringWithFormat:@"Healing Done: %i", localHealingDone];
            self.overhealingDoneLabel.string = [NSString stringWithFormat:@"Overhealing: %i", localOverhealing];
            self.damageTakenLabel.string    = [NSString stringWithFormat:@"Damage Taken: %i", damageTaken];
        }
        
        if ([message hasPrefix:@"LEVELNUM"]){
            NSArray *components = [message componentsSeparatedByString:@"|"];
            MultiplayerSetupScene *mpss = [[MultiplayerSetupScene alloc] initWithPreconfiguredMatch:self.match andServerID:self.serverPlayerId andLevelNumber:[[components objectAtIndex:1] intValue]];
            self.match.delegate = mpss;
            [mpss setMatchVoiceChat:self.matchVoiceChat];
            [[CCDirector sharedDirector] replaceScene:mpss];
            [mpss release];
        }
    }else {
        if ([message hasPrefix:@"QAGAIN"]){
            self.otherPlayerHasQueued = YES;
            if (self.localPlayerHasQueued){
                [self beginNextGame];
            }
        }
    }
    
    [message release];
    
}

- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {
    if (theMatch != self.match) {
        return;
    }
    
    if (state == GKPlayerStateDisconnected) {
        self.otherPlayerHasQueued = NO;
        self.queueAgainMenuItem.isEnabled = NO;
        UIAlertView *otherPlayerDisconnected = [[UIAlertView alloc] initWithTitle:@"Other Player Left" message:@"The Other player has left the game" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        
        [otherPlayerDisconnected show];
        [otherPlayerDisconnected release];
    }
    
}

- (void)match:(GKMatch *)match connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error {
    
}

- (void)match:(GKMatch *)match didFailWithError:(NSError *)error  {
    
}
@end

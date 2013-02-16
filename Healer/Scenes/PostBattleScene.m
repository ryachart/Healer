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
#import "Talents.h"
#import "TalentScene.h"
#import "HealerStartScene.h"
#import "BasicButton.h"
#import "Encounter.h"
#import "Raid.h"
#import "CCNumberChangeAction.h"
#import "GoldCounterSprite.h"
#import "CCLabelTTFShadow.h"

@interface PostBattleScene ()
@property (nonatomic, readwrite) BOOL isMultiplayer;
@property (nonatomic, readwrite) BOOL isVictory;
@property (nonatomic, readwrite) BOOL otherPlayerHasQueued;
@property (nonatomic, readwrite) BOOL localPlayerHasQueued;
@property (nonatomic, readwrite) BOOL isNewBestScore;
@property (nonatomic, readwrite) BOOL showsFirstLevelFTUE;
@property (nonatomic, assign) CCLabelTTFShadow *healingDoneLabel;
@property (nonatomic, assign) CCLabelTTFShadow *overhealingDoneLabel;
@property (nonatomic, assign) CCLabelTTFShadow *damageTakenLabel;
@property (nonatomic, assign) CCMenuItem *queueAgainMenuItem;
@property (nonatomic, assign) CCLabelTTFShadow *goldLabel;
@property (nonatomic, assign) CCLabelTTFShadow *scoreLabel;
@property (nonatomic, retain) Encounter *encounter;
@property (nonatomic, assign) GoldCounterSprite *goldCounter;
@property (nonatomic, readwrite) NSInteger reward;
@end

@implementation PostBattleScene

- (void)dealloc {
    if (_encounter && _encounter.bossKey) {
        //Unload the boss specific sprites;
        [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:[NSString stringWithFormat:@"assets/%@.plist", _encounter.bossKey]];
    }
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/battle-sprites.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/effect-sprites.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/postbattle.plist"];
    [_match release];
    [_serverPlayerId release];
    [_matchVoiceChat release];
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
        NSInteger oldScore = [[PlayerDataManager localPlayer] scoreForLevel:self.encounter.levelNumber];
        NSInteger score = self.encounter.score;
        NSInteger numDead = self.encounter.raid.deadCount;
        NSTimeInterval fightDuration = duration;
        
        self.goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [self.goldCounter setUpdatesAutomatically:NO];
        [self.goldCounter setPosition:CGPointMake(882, 40)];
        [self addChild:self.goldCounter z:100];
        
        self.showsFirstLevelFTUE = victory && enc.levelNumber == 1 && [[PlayerDataManager localPlayer] highestLevelCompleted] == 0;
        
        //Data Operations
        if (victory){
            [TestFlight passCheckpoint:[NSString stringWithFormat:@"LevelComplete:%i",self.encounter.levelNumber]];
            if (!self.isMultiplayer){
                [[PlayerDataManager localPlayer] completeLevel:self.encounter.levelNumber];
            }
            reward = [self.encounter reward];
            if (self.showsFirstLevelFTUE) {
                reward = 25;
            }
            
            oldRating = [[PlayerDataManager localPlayer] levelRatingForLevel:self.encounter.levelNumber];
            rating = self.encounter.difficulty;
            if (rating > oldRating && !self.isMultiplayer){
                if (self.encounter.difficulty > 1 && self.encounter.levelNumber != 1) {
                    reward += 25; //Completing a new difficulty bonus, basically.
                }
                [[PlayerDataManager localPlayer] setLevelRating:rating forLevel:self.encounter.levelNumber];
            }
            
            if (oldScore < score && !self.isMultiplayer) {
                self.isNewBestScore = YES;
                [[PlayerDataManager localPlayer] setScore:score forLevel:self.encounter.levelNumber];
            }
            
            [[PlayerDataManager localPlayer] setLastSelectedLevel:-1]; //Clear it so it advances to the furthest level next time
        }else {
            [TestFlight passCheckpoint:[NSString stringWithFormat:@"LevelFailed:%i",self.encounter.levelNumber]];
            [[PlayerDataManager localPlayer] failLevel:self.encounter.levelNumber];
            //Partial Progress Reward
            //10 % of the Reward per minute of encounter up to a maximum of 50% encounter reward
        }
        
        if (self.encounter.levelNumber == ENDLESS_VOID_ENCOUNTER_NUMBER){
            reward  = [Encounter goldRewardForSurvivalEncounterWithDuration:fightDuration];
        }
        
        if (reward > 0){
            [[PlayerDataManager localPlayer] playerEarnsGold:reward];
        }
        
        [[PlayerDataManager localPlayer] saveLocalPlayer];
        
        //UI
        CGPoint textLocation = CGPointMake(512, 680);
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"post-battle"] autorelease]];
        if (victory){
            CCSprite *victoryLabel = [CCSprite spriteWithSpriteFrameName:@"victory_text.png"];
            [victoryLabel setPosition:textLocation];
            [self addChild:victoryLabel];
            
            CCSprite *characterSprite = [CCSprite spriteWithSpriteFrameName:@"victory_sprite.png"];
            [characterSprite setAnchorPoint:CGPointZero];
            [self addChild:characterSprite];
            
            if (enc.levelNumber != 1) {
                self.scoreLabel = [CCLabelTTFShadow labelWithString:@"Score: " dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:36.0];
                [self.scoreLabel setPosition:CGPointMake(54, 230)];
                [self.scoreLabel setAnchorPoint:CGPointZero];
            }
            
        }else{
            CCSprite *victoryLabel = [CCSprite spriteWithSpriteFrameName:@"defeated_text.png"];
            [victoryLabel setPosition:textLocation];
            [self addChild:victoryLabel];
            
            CCSprite *characterSprite = [CCSprite spriteWithSpriteFrameName:@"defeat_sprite.png"];
            [characterSprite setAnchorPoint:CGPointZero];
            [self addChild:characterSprite];
        }
    
        NSString* doneLabelString = self.isMultiplayer ? @"Leave Group" : @"Continue";
        CCMenuItem *done = [BasicButton basicButtonWithTarget:self andSelector:@selector(done) andTitle:doneLabelString];
        CCMenu *menu = [CCMenu menuWithItems:nil];
        menu.position = CGPointMake(880, 150);
        [self addChild:menu];
        
        if (!self.showsFirstLevelFTUE) {
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
        
        CCSprite *statsContainer = [CCSprite spriteWithSpriteFrameName:@"stats_container.png"];
        [statsContainer setPosition:CGPointMake(180, 160)];
        [self addChild:statsContainer];
        
        if (self.scoreLabel) {
            [statsContainer addChild:self.scoreLabel];
        }
        
        if (reward > 0){
            self.goldLabel = [CCLabelTTFShadow labelWithString:@"Gold Earned: 0" fontName:@"TrebuchetMS-Bold" fontSize:32.0];
            [self.goldLabel setScale:5];
            [self.goldLabel setOpacity:0];
            [self.goldLabel setPosition:CGPointMake(36, 30)];
            [self.goldLabel setAnchorPoint:CGPointZero];
            [statsContainer addChild:self.goldLabel];
        }
        
        NSInteger failureAdjustment = 0;
        if (!victory) {
            CCLabelTTFShadow *bossHealthRemaining = [CCLabelTTFShadow labelWithString:[NSString stringWithFormat:@"Boss Health: %1.2f%%", self.encounter.boss.healthPercentage] dimensions:CGSizeMake(250, 100) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:36.0];
            [bossHealthRemaining setPosition:CGPointMake(40, 190)];
            [bossHealthRemaining setAnchorPoint:CGPointZero];
            [statsContainer addChild:bossHealthRemaining];
            failureAdjustment = -50;
        }
        
        self.healingDoneLabel = [CCLabelTTFShadow labelWithString:@"Healing Done: " dimensions:CGSizeMake(250, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.healingDoneLabel setPosition:CGPointMake(12, 150 + failureAdjustment)];
        [self.healingDoneLabel setAnchorPoint:CGPointZero];
        
        self.overhealingDoneLabel = [CCLabelTTFShadow labelWithString:@"Overhealing: " dimensions:CGSizeMake(250, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.overhealingDoneLabel setPosition:CGPointMake(12, 120 + failureAdjustment)];
        [self.overhealingDoneLabel setAnchorPoint:CGPointZero];
        
        self.damageTakenLabel = [CCLabelTTFShadow labelWithString:@"Damage Taken: " dimensions:CGSizeMake(280, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.damageTakenLabel setPosition:CGPointMake(14, 90 + failureAdjustment)];
        [self.damageTakenLabel setAnchorPoint:CGPointZero];
        
        CCLabelTTFShadow *playersLostLabel = [CCLabelTTFShadow labelWithString:[NSString stringWithFormat:@"Allies Lost:  %i", numDead] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [playersLostLabel setPosition:CGPointMake(12, 60 + failureAdjustment)];
        [playersLostLabel setAnchorPoint:CGPointZero];
        
        [statsContainer addChild:self.healingDoneLabel];
        [statsContainer addChild:self.overhealingDoneLabel];
        [statsContainer addChild:self.damageTakenLabel];
        [statsContainer addChild:playersLostLabel];
        
        NSString *durationText = [@"Duration: " stringByAppendingString:[self timeStringForTimeInterval:fightDuration]];
        
        CCLabelTTFShadow *durationLabel = [CCLabelTTFShadow labelWithString:durationText dimensions:CGSizeMake(250, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [durationLabel setPosition:CGPointMake(10, 180 + failureAdjustment)];
        [durationLabel setAnchorPoint:CGPointZero];
        [statsContainer addChild:durationLabel];
        
#if DEBUG
        [self.encounter saveCombatLog];
#endif
        self.reward = reward;
    }
    return self;
}

- (NSString*)timeStringForTimeInterval:(NSTimeInterval)interval{
    NSInteger minutes = interval / 60;
    NSInteger seconds = (int)interval % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

- (void)showRemotePlayerStats:(NSInteger)healingDone andOverhealing:(NSInteger)overhealing {
    CCLabelTTF *otherPlayersStatsLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Other Player Stats"] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Marion-Bold" fontSize:30.0];
    [otherPlayersStatsLabel setPosition:CGPointMake(900, 730)];
    [self addChild:otherPlayersStatsLabel];
    
    CCLabelTTF *otherHealingDoneLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Healing Done: %i", healingDone] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Marion-Bold" fontSize:24.0];
    [otherHealingDoneLabel setPosition:CGPointMake(900, 680)];
    [self addChild:otherHealingDoneLabel];
    
    CCLabelTTF *otherOverhealingDoneLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Overhealing: %i", overhealing] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"Marion-Bold" fontSize:24.0];
    [otherOverhealingDoneLabel setPosition:CGPointMake(900, 630)];
    [self addChild:otherOverhealingDoneLabel];
}

- (void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    
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
    
    NSInteger finalScore = self.encounter.score;

    CCNumberChangeAction *numberChangeAction = [CCNumberChangeAction actionWithDuration:2.0 fromNumber:0 toNumber:self.encounter.damageTaken];
    [numberChangeAction setPrefix:@"Damage Taken: "];
    [self.damageTakenLabel runAction:numberChangeAction];
    
    numberChangeAction = [CCNumberChangeAction actionWithDuration:3.5 fromNumber:0 toNumber:self.encounter.healingDone];
    [numberChangeAction setPrefix:@"Healing Done: "];
    [self.healingDoneLabel runAction:numberChangeAction];

    numberChangeAction = [CCNumberChangeAction actionWithDuration:5.0 fromNumber:0 toNumber:self.encounter.overhealingDone];
    [numberChangeAction setPrefix:@"Overhealing: "];
    [self.overhealingDoneLabel runAction:numberChangeAction];

    NSTimeInterval finalScoreTime = 2.5+(finalScore/10000.0);
    numberChangeAction = [CCNumberChangeAction actionWithDuration:finalScoreTime fromNumber:0 toNumber:finalScore];
    [numberChangeAction setPrefix:@"Score: "];
    if (self.scoreLabel) {
        [self.scoreLabel runAction:[CCSequence actionOne:numberChangeAction two:[CCCallFunc actionWithTarget:self selector:@selector(completeStatAnimations)]]];
    } else {
        [self completeStatAnimations];
    }
    

}

- (void)completeStatAnimations {
    if (self.isNewBestScore && !self.isMultiplayer){
        CCSprite *newHighScore = [CCSprite spriteWithSpriteFrameName:@"new_high_score_text.png"];
        [newHighScore setPosition:CGPointMake(190, 354)];
        [self addChild:newHighScore];
        [newHighScore runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCScaleTo  actionWithDuration:.75 scale:1.2], [CCScaleTo actionWithDuration:.75 scale:1.0], nil]]];
    }
    if (self.isVictory) {
        CCNumberChangeAction *numberChangeAction = [CCNumberChangeAction actionWithDuration:2.5 fromNumber:0 toNumber:self.reward];
        [numberChangeAction setPrefix:@"Gold Earned: "];
        [self.goldLabel runAction:numberChangeAction];
        
        CCNumberChangeAction *countDown = [CCNumberChangeAction actionWithDuration:2.0 fromNumber:self.reward toNumber:0];
        [countDown setPrefix:@"Gold Earned: "];
        [self.goldLabel runAction:[CCSequence actions:[CCSpawn actions:[CCScaleTo actionWithDuration:.5 scale:1.0], [CCFadeTo actionWithDuration:.5 opacity:255], nil], numberChangeAction, [CCDelayTime  actionWithDuration:.5], [CCCallFunc actionWithTarget:self selector:@selector(finishGoldCountUp)], countDown,[CCFadeTo actionWithDuration:.5 opacity:0], [CCCallBlockN actionWithBlock:^(CCNode *node){ [node removeFromParentAndCleanup:YES];}], nil]];
        
    }
}

- (void)finishGoldCountUp
{
    [self.goldCounter updateGoldAnimated:YES toGold:[PlayerDataManager localPlayer].gold];
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
    CCMenuItem *goToDivinity = [BasicButton basicButtonWithTarget:self andSelector:@selector(goToDivinity) andTitle:@"DIVINITY"];
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
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:.5 scene:[[[TalentScene alloc] init] autorelease]]];
}

- (void)goToStore {
    ShopScene *ss = [[ShopScene new] autorelease];
    [ss setReturnsToMap:YES];
    [ss setRequiresGreaterHealFtuePurchase:self.showsFirstLevelFTUE];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:.5 scene:ss]];
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

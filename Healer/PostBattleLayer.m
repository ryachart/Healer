//
//  PostBattleLayer.m
//  Healer
//
//  Created by Ryan Hart on 3/20/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "PostBattleLayer.h"
#import "CCLabelTTFShadow.h"
#import "GoldCounterSprite.h"
#import "Encounter.h"
#import "Raid.h"
#import "PlayerDataManager.h"
#import "TestFlight.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"
#import "CCNumberChangeAction.h"
#import "Enemy.h"
#import "SimpleAudioEngine.h"

@interface PostBattleLayer ()
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

@implementation PostBattleLayer

- (id)initWithVictory:(BOOL)victory encounter:(Encounter*)enc andIsMultiplayer:(BOOL)isMult andDuration:(NSTimeInterval)duration 
{
    if (self = [super initWithColor:ccc4(0, 0, 0, 0)]) {
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
        
        self.showsFirstLevelFTUE = [PlayerDataManager localPlayer].ftueState == FTUEStateBattle1Finished;
        
        if (self.isVictory) {
            self.goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
            [self.goldCounter setUpdatesAutomatically:NO];
            [self.goldCounter setPosition:CGPointMake(512, 470)];
            [self addChild:self.goldCounter z:100];
        }
        
        if (victory){
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
            [[PlayerDataManager localPlayer] failLevel:self.encounter.levelNumber];
            //Partial Progress Reward
            //10 % of the Reward per minute of encounter up to a maximum of 50% encounter reward
        }
        
        if (reward > 0){
            [[PlayerDataManager localPlayer] playerEarnsGold:reward];
        }
        
        [[PlayerDataManager localPlayer] saveLocalPlayer];
        
        
        if (victory && enc.levelNumber != 1){
            self.scoreLabel = [CCLabelTTFShadow labelWithString:@"Score: " dimensions:CGSizeMake(250, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
            [self.scoreLabel setPosition:CGPointMake(12, 130)];
            [self.scoreLabel setAnchorPoint:CGPointZero];
        }
        
        NSString* doneLabelString = self.isMultiplayer ? @"Leave Group" : @"Adventure";
        CCMenuItem *done = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneMap) andTitle:doneLabelString];
        CCMenuItem *academy = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneAcademy) andTitle:@"Academy"];
        CCMenu *menu = [CCMenu menuWithItems:academy, nil];
        menu.position = CGPointMake(890, 470);
        menu.anchorPoint = CGPointMake(0, 0);
        [self addChild:menu];
        
        
        if (!self.showsFirstLevelFTUE) {
            [done setPosition:CGPointMake(0, 76)];
            [menu addChild:done];
            
            if ([[PlayerDataManager localPlayer] numUnspentTalentChoices]) {
                CCMenuItem *talentButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneTalents) andTitle:@"Talents" andAlertPip:YES];
                [talentButton setPosition:CGPointMake(0, 152)];
                [menu addChild:talentButton];
            }
        }
        
        
        CCSprite *statsContainer = [CCSprite spriteWithSpriteFrameName:@"stats_container.png"];
        [statsContainer setPosition:CGPointMake(190, 520)];
        [self addChild:statsContainer];
        
        if (self.scoreLabel) {
            [statsContainer addChild:self.scoreLabel];
        }
        
        if (reward > 0){
            self.goldLabel = [CCLabelTTFShadow labelWithString:@"Gold Earned: 0" fontName:@"TrebuchetMS-Bold" fontSize:32.0];
            [self.goldLabel setColor:ccYELLOW];
            [self.goldLabel setHorizontalAlignment:kCCTextAlignmentCenter];
            [self.goldLabel setScale:5];
            [self.goldLabel setOpacity:0];
            [self.goldLabel setPosition:CGPointMake(512, 530)];
            [self addChild:self.goldLabel];
        }
        
        NSInteger failureAdjustment = victory ? -64 : - 50;
        
        self.healingDoneLabel = [CCLabelTTFShadow labelWithString:@"Healing Done: " dimensions:CGSizeMake(250, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.healingDoneLabel setPosition:CGPointMake(12, 140 + failureAdjustment)];
        [self.healingDoneLabel setAnchorPoint:CGPointZero];
        
        self.overhealingDoneLabel = [CCLabelTTFShadow labelWithString:@"Overhealing: " dimensions:CGSizeMake(250, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.overhealingDoneLabel setPosition:CGPointMake(12, 110 + failureAdjustment)];
        [self.overhealingDoneLabel setAnchorPoint:CGPointZero];
        
        self.damageTakenLabel = [CCLabelTTFShadow labelWithString:@"Damage Taken: " dimensions:CGSizeMake(280, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.damageTakenLabel setPosition:CGPointMake(12, 80 + failureAdjustment)];
        [self.damageTakenLabel setAnchorPoint:CGPointZero];
        
        CCLabelTTFShadow *playersLostLabel = [CCLabelTTFShadow labelWithString:[NSString stringWithFormat:@"Allies Lost:  %i", numDead] dimensions:CGSizeMake(350, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [playersLostLabel setPosition:CGPointMake(12, 50 + failureAdjustment)];
        [playersLostLabel setAnchorPoint:CGPointZero];
        
        [statsContainer addChild:self.healingDoneLabel];
        [statsContainer addChild:self.overhealingDoneLabel];
        [statsContainer addChild:self.damageTakenLabel];
        [statsContainer addChild:playersLostLabel];
        
        NSString *durationText = [@"Duration: " stringByAppendingString:[self timeStringForTimeInterval:fightDuration]];
        
        CCLabelTTFShadow *durationLabel = [CCLabelTTFShadow labelWithString:durationText dimensions:CGSizeMake(250, 50) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [durationLabel setPosition:CGPointMake(12, 168 + failureAdjustment)];
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

- (void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    
    if (self.isMultiplayer) {
        if ([self.serverPlayerId isEqualToString:[GKLocalPlayer localPlayer].playerID]){
            //We are the server.  Lets figure out the stats!
//            NSDictionary *localStats = [CombatEvent statsForPlayer:[GKLocalPlayer localPlayer].playerID fromLog:self.encounter.combatLog];
//            NSDictionary *remoteStats = [CombatEvent statsForPlayer:[self.match.playerIDs objectAtIndex:0] fromLog:self.encounter.combatLog];
//            int localTotalHealingDone = [[localStats objectForKey:PlayerHealingDoneKey] intValue];
//            int localOverheal = [[localStats objectForKey:PlayerOverHealingDoneKey] intValue];
//            
//            int remoteTotalHealingDone = [[remoteStats objectForKey:PlayerHealingDoneKey] intValue];
//            int remoteOverheal = [[remoteStats objectForKey:PlayerOverHealingDoneKey] intValue];
            
            int totalDamageTaken = 0;
            for (CombatEvent *event in self.encounter.combatLog){
                if (event.type == CombatEventTypeDamage && [[event source] isKindOfClass:[Enemy class]]){
                    NSInteger dmgVal = [[event value] intValue];
                    totalDamageTaken +=  abs(dmgVal);
                }
            }
            
//            [self showRemotePlayerStats:remoteTotalHealingDone andOverhealing:remoteOverheal];
//            [self.match sendDataToAllPlayers:[[NSString stringWithFormat:@"STATS|%i|%i|%i|%i|%i", localTotalHealingDone, localOverheal, remoteTotalHealingDone, remoteOverheal, totalDamageTaken] dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKMatchSendDataReliable error:nil];
        }
    }
    
    CGPoint textLocation = CGPointMake(512, 680);
    
    CCSprite *victoryLabel = nil;
    if (self.isVictory){
        victoryLabel = [CCSprite spriteWithSpriteFrameName:@"victory_text.png"];
    } else {
        victoryLabel = [CCSprite spriteWithSpriteFrameName:@"defeated_text.png"];
    }
    [victoryLabel setPosition:textLocation];
    [self addChild:victoryLabel];
    
    victoryLabel.scale = 3.0;
    victoryLabel.opacity = 0;
    [victoryLabel runAction:[CCSpawn actionOne:[CCScaleTo actionWithDuration:.5 scale:1.0] two:[CCFadeTo actionWithDuration:.5 opacity:255]]];
    
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
        [newHighScore setPosition:CGPointMake(190, 640)];
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
    [[SimpleAudioEngine sharedEngine] playEffect:@"sounds/coinschest.mp3"];
    [self.goldCounter updateGoldAnimated:YES toGold:[PlayerDataManager localPlayer].gold];
}

- (void)doneAcademy
{
    [self.delegate postBattleLayerDidTransitionToScene:PostBattleLayerDestinationShop asVictory:self.isVictory];
}

- (void)doneMap
{
    [self.delegate postBattleLayerDidTransitionToScene:PostBattleLayerDestinationMap asVictory:self.isVictory];
}

- (void)doneTalents
{
    [self.delegate postBattleLayerDidTransitionToScene:PostBattleLayerDestinationTalents asVictory:self.isVictory];
}

-(void)setMatch:(GKMatch *)mtch{
    [_match release];
    _match = [mtch retain];
    //[self.match setDelegate:self];
}

@end

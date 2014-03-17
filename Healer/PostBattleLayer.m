//
//  PostBattleLayer.m
//  Healer
//
//  Created by Ryan Hart on 3/20/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "PostBattleLayer.h"
#import "CCLabelTTFShadow.h"
#import "GoldCounterSprite.h"
#import "Encounter.h"
#import "Raid.h"
#import "PlayerDataManager.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"
#import "CCNumberChangeAction.h"
#import "Enemy.h"
#import "SimpleAudioEngine.h"
#import "StaminaCounterNode.h"
#import "ItemDescriptionNode.h"
#import "PurchaseManager.h"
#import "TreasureChest.h"

@interface PostBattleLayer ()
@property (nonatomic, readwrite) BOOL isMultiplayer;
@property (nonatomic, readwrite) BOOL isVictory;
@property (nonatomic, readwrite) BOOL otherPlayerHasQueued;
@property (nonatomic, readwrite) BOOL localPlayerHasQueued;
@property (nonatomic, readwrite) BOOL isNewBestScore;
@property (nonatomic, readwrite) BOOL showsFirstLevelFTUE;
@property (nonatomic, readwrite) BOOL isLootSequencedCompleted;
@property (nonatomic, assign) CCLabelTTFShadow *healingDoneLabel;
@property (nonatomic, assign) CCLabelTTFShadow *overhealingDoneLabel;
@property (nonatomic, assign) CCLabelTTFShadow *damageTakenLabel;
@property (nonatomic, assign) CCMenuItem *queueAgainMenuItem;
@property (nonatomic, assign) CCLabelTTFShadow *goldLabel;
@property (nonatomic, assign) CCLabelTTFShadow *scoreLabel;
@property (nonatomic, retain) Encounter *encounter;
@property (nonatomic, assign) GoldCounterSprite *goldCounter;
@property (nonatomic, readwrite) NSInteger reward;
@property (nonatomic, assign) CCSprite *statsContainer;
@property (nonatomic, assign) CCMenu *advanceMenu;
@property (nonatomic, assign) CCSprite *resultLabel;
@property (nonatomic, assign) CCSprite *betterHighScoreLabel;
@property (nonatomic, readwrite) PostBattleLayerDestination chosenDestination;
@property (nonatomic, assign) CCLabelTTFShadow *errorLabel;

//Loot Award Stuff
@property (nonatomic, assign) TreasureChest *chestSprite;
@property (nonatomic, assign) BasicButton *openChest;
@property (nonatomic, assign) BasicButton *getKeys;
@end

@implementation PostBattleLayer

- (void)processPlayerDataProgressionForMatch
{
    NSInteger oldScore = [[PlayerDataManager localPlayer] scoreForLevel:self.encounter.levelNumber];
    NSInteger score = self.encounter.score;
    NSInteger oldRating = 0;
    NSInteger rating = 0;

    if (self.isVictory) {
        if (!self.isMultiplayer){
            [[PlayerDataManager localPlayer] completeLevel:self.encounter.levelNumber];
        }
        self.reward = [self.encounter reward];
        if (self.showsFirstLevelFTUE) {
            self.reward = 25;
        }
        
        oldRating = [[PlayerDataManager localPlayer] levelRatingForLevel:self.encounter.levelNumber];
        rating = self.encounter.difficulty;
        if (rating > oldRating && !self.isMultiplayer){
            if (self.encounter.difficulty > 1 && self.encounter.levelNumber != 1) {
                self.reward += 25; //Completing a new difficulty bonus, basically.
            }
            [[PlayerDataManager localPlayer] setLevelRating:rating forLevel:self.encounter.levelNumber];
        }
        
        if (oldScore < score && !self.isMultiplayer) {
            self.isNewBestScore = YES;
            [[PlayerDataManager localPlayer] setScore:score forLevel:self.encounter.levelNumber];
        }
        
        [[PlayerDataManager localPlayer] setLastSelectedLevel:-1]; //Clear it so it advances to the furthest level next time
    } else {
        [[PlayerDataManager localPlayer] failLevel:self.encounter.levelNumber];
    }
    
    
    if (self.reward > 0){
        [[PlayerDataManager localPlayer] playerEarnsGold:self.reward];
    }
    [[PlayerDataManager localPlayer] saveLocalPlayer];
}

- (void)initializeDataForVictory:(BOOL)victory encounter:(Encounter *)encounter isMultiplayer:(BOOL)isMultiplayer
{
    self.encounter = encounter;
    self.isMultiplayer = isMultiplayer;
    self.isVictory = victory;
    self.reward = 0;
    
    self.showsFirstLevelFTUE = [PlayerDataManager localPlayer].ftueState == FTUEStateBattle1Finished && ![[PlayerDataManager localPlayer] hasSpell:[GreaterHeal defaultSpell]];
}

- (id)initWithVictory:(BOOL)victory encounter:(Encounter*)enc andIsMultiplayer:(BOOL)isMult
{
    if (self = [super initWithColor:ccc4(0, 0, 0, 0)]) {
        [self initializeDataForVictory:victory encounter:enc isMultiplayer:isMult];
        NSInteger numDead = self.encounter.raid.deadCount;
        NSTimeInterval fightDuration = enc.duration;
        BOOL willAwardLoot = self.encounter.levelNumber > 1 && self.isVictory && ![PlayerDataManager localPlayer].isInventoryFull;
        
        if (self.isVictory) {
            self.goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
            [self.goldCounter setUpdatesAutomatically:NO];
            [self.goldCounter setPosition:CGPointMake(512, 470)];
            [self addChild:self.goldCounter z:100];
        }
        
        [self processPlayerDataProgressionForMatch];
        
        if (victory && enc.levelNumber != 1){
            self.scoreLabel = [CCLabelTTFShadow labelWithString:@"Score: " dimensions:CGSizeMake(250, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
            [self.scoreLabel setPosition:CGPointMake(12, 130)];
            [self.scoreLabel setAnchorPoint:CGPointZero];
        }
        
        if (willAwardLoot) {
            BasicButton *continueToLoot = [BasicButton basicButtonWithTarget:self andSelector:@selector(awardLoot) andTitle:@"Continue"];
            self.advanceMenu = [CCMenu menuWithItems:continueToLoot, nil];
            self.advanceMenu.position = CGPointMake(890, 470);
            self.advanceMenu.anchorPoint = CGPointMake(0, 0);
            [self addChild:self.advanceMenu];
        } else {
            [self configureAdvanceMenu];
            self.advanceMenu.position = CGPointMake(890, 470);
            self.isLootSequencedCompleted = YES;
        
        }
        
        self.statsContainer = [CCSprite spriteWithSpriteFrameName:@"stats_container.png"];
        [self.statsContainer setPosition:CGPointMake(190, 520)];
        [self addChild:self.statsContainer];
        
        if (self.scoreLabel) {
            [self.statsContainer addChild:self.scoreLabel];
        }
        
        if (self.reward > 0){
            self.goldLabel = [CCLabelTTFShadow labelWithString:@"Gold Earned: 0" fontName:@"TrebuchetMS-Bold" fontSize:32.0];
            [self.goldLabel setColor:ccYELLOW];
            [self.goldLabel setHorizontalAlignment:kCCTextAlignmentCenter];
            [self.goldLabel setScale:5];
            [self.goldLabel setOpacity:0];
            [self.goldLabel setPosition:CGPointMake(512, 530)];
            [self addChild:self.goldLabel];
        }
        
        NSInteger failureAdjustment = victory ? -64 : - 50;
        
        self.healingDoneLabel = [CCLabelTTFShadow labelWithString:@"Healing Done: " dimensions:CGSizeMake(250, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.healingDoneLabel setPosition:CGPointMake(12, 140 + failureAdjustment)];
        [self.healingDoneLabel setAnchorPoint:CGPointZero];
        
        self.overhealingDoneLabel = [CCLabelTTFShadow labelWithString:@"Overhealing: " dimensions:CGSizeMake(250, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.overhealingDoneLabel setPosition:CGPointMake(12, 110 + failureAdjustment)];
        [self.overhealingDoneLabel setAnchorPoint:CGPointZero];
        
        self.damageTakenLabel = [CCLabelTTFShadow labelWithString:@"Damage Taken: " dimensions:CGSizeMake(280, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.damageTakenLabel setPosition:CGPointMake(12, 80 + failureAdjustment)];
        [self.damageTakenLabel setAnchorPoint:CGPointZero];
        
        CCLabelTTFShadow *playersLostLabel = [CCLabelTTFShadow labelWithString:[NSString stringWithFormat:@"Allies Lost:  %i", numDead] dimensions:CGSizeMake(350, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [playersLostLabel setPosition:CGPointMake(12, 50 + failureAdjustment)];
        [playersLostLabel setAnchorPoint:CGPointZero];
        
        [self.statsContainer addChild:self.healingDoneLabel];
        [self.statsContainer addChild:self.overhealingDoneLabel];
        [self.statsContainer addChild:self.damageTakenLabel];
        [self.statsContainer addChild:playersLostLabel];
        
        NSString *durationText = [@"Duration: " stringByAppendingString:[self timeStringForTimeInterval:fightDuration]];
        
        CCLabelTTFShadow *durationLabel = [CCLabelTTFShadow labelWithString:durationText dimensions:CGSizeMake(250, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [durationLabel setPosition:CGPointMake(12, 168 + failureAdjustment)];
        [durationLabel setAnchorPoint:CGPointZero];
        [self.statsContainer addChild:durationLabel];
        
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
    
    self.resultLabel = nil;
    if (self.isVictory){
        self.resultLabel = [CCSprite spriteWithSpriteFrameName:@"victory_text.png"];
    } else {
        self.resultLabel = [CCSprite spriteWithSpriteFrameName:@"defeated_text.png"];
    }
    [self.resultLabel setPosition:textLocation];
    [self addChild:self.resultLabel];
    
    self.resultLabel.scale = 3.0;
    self.resultLabel.opacity = 0;
    [self.resultLabel runAction:[CCSpawn actionOne:[CCScaleTo actionWithDuration:.5 scale:1.0] two:[CCFadeTo actionWithDuration:.5 opacity:255]]];
    
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
        self.betterHighScoreLabel = [CCSprite spriteWithSpriteFrameName:@"new_high_score_text.png"];
        [self.betterHighScoreLabel setPosition:CGPointMake(190, 640)];
        [self addChild:self.betterHighScoreLabel];
        [self.betterHighScoreLabel runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCScaleTo  actionWithDuration:.75 scale:1.2], [CCScaleTo actionWithDuration:.75 scale:1.0], nil]]];
    }
    if (self.isVictory) {
        CCNumberChangeAction *numberChangeAction = [CCNumberChangeAction actionWithDuration:2.5 fromNumber:0 toNumber:self.reward];
        [numberChangeAction setPrefix:@"Gold Earned: "];
        [self.goldLabel runAction:numberChangeAction];
        
        CCNumberChangeAction *countDown = [CCNumberChangeAction actionWithDuration:2.0 fromNumber:self.reward toNumber:0];
        [countDown setPrefix:@"Gold Earned: "];
        [self.goldLabel runAction:[CCSequence actions:[CCSpawn actions:[CCScaleTo actionWithDuration:.5 scale:1.0], [CCFadeTo actionWithDuration:.5 opacity:255], nil], numberChangeAction, [CCDelayTime  actionWithDuration:.5], [CCCallFunc actionWithTarget:self selector:@selector(finishGoldCountUp)], countDown,[CCFadeTo actionWithDuration:.5 opacity:0], [CCCallFunc actionWithTarget:self selector:@selector(finishGoldLabel)], nil]];
        
    }
}

- (void)finishGoldLabel
{
    [self.goldLabel removeFromParentAndCleanup:YES];
    self.goldLabel = nil;
}

- (void)finishGoldCountUp
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"sounds/coinschest.mp3"];
    [self.goldCounter updateGoldAnimated:YES toGold:[PlayerDataManager localPlayer].gold];
}

- (void)showConfirmationDialog
{
    IconDescriptionModalLayer *confirmDialog = [[[IconDescriptionModalLayer alloc] initAsConfirmationDialogueWithDescription:@"Are you sure you want to abandon this loot?"] autorelease];
    [confirmDialog setDelegate:self];
    [self addChild:confirmDialog z:1000];
}

- (void)doneAcademy
{
    self.chosenDestination = PostBattleLayerDestinationShop;
    if (self.isLootSequencedCompleted) {
        [self.delegate postBattleLayerDidTransitionToScene:self.chosenDestination asVictory:self.isVictory];
    } else {
        [self showConfirmationDialog];
    }
}

- (void)doneMap
{
    self.chosenDestination = PostBattleLayerDestinationMap;
    if (self.isLootSequencedCompleted) {
        [self.delegate postBattleLayerDidTransitionToScene:self.chosenDestination asVictory:self.isVictory];
    } else {
        [self showConfirmationDialog];
    }
}

- (void)doneTalents
{
    self.chosenDestination = PostBattleLayerDestinationTalents;
    if (self.isLootSequencedCompleted) {
        [self.delegate postBattleLayerDidTransitionToScene:self.chosenDestination asVictory:self.isVictory];
    } else {
        [self showConfirmationDialog];
    }
}

- (void)doneArmory
{
    self.chosenDestination = PostBattleLayerDestinationArmory;
    if (self.isLootSequencedCompleted) {
        [self.delegate postBattleLayerDidTransitionToScene:self.chosenDestination asVictory:self.isVictory];
    } else {
        [self showConfirmationDialog];
    }
}

- (void)awardLoot
{
    [self.delegate postBattleLayerWillAwardLoot];
    
    [self.advanceMenu removeFromParentAndCleanup:YES];
    self.advanceMenu = nil;
    [self.goldCounter removeFromParentAndCleanup:YES];
    [self.goldLabel removeFromParentAndCleanup:YES];
    [self.statsContainer removeFromParentAndCleanup:YES];
    [self.resultLabel removeFromParentAndCleanup:YES];
    [self.betterHighScoreLabel removeFromParentAndCleanup:YES];
    
    self.chestSprite = [[TreasureChest new] autorelease];
    [self.chestSprite setPosition:CGPointMake(512, 1600)];
    [self addChild:self.chestSprite];
    
    StaminaCounterNode *stamina = [[[StaminaCounterNode alloc] init] autorelease];
    [stamina setPosition:CGPointMake(512, 50)];
    [self addChild:stamina];
    
    [self.chestSprite runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1.25], [CCMoveTo actionWithDuration:.5 position:CGPointMake(512, 344)], [CCCallFunc actionWithTarget:self selector:@selector(fadeInLootChoiceButtons)], nil]];
}

- (void)fadeInLootChoiceButtons
{
    self.openChest = [BasicButton basicButtonWithTarget:self andSelector:@selector(lootChest) andTitle:@"Open Chest"];
    if ([PlayerDataManager localPlayer].stamina == 0) {
        self.getKeys = [BasicButton basicButtonWithTarget:self andSelector:@selector(buyKeys) andTitle:@"Buy A Key"];
    }
    
    [self configureAdvanceMenu];
    [self.advanceMenu setPosition:CGPointMake(890, 60)];
    
    CCMenu *openChestMenu = [CCMenu menuWithItems:self.openChest,nil];
    if (self.getKeys) {
        [openChestMenu addChild:self.getKeys];
        [openChestMenu alignItemsHorizontally];
    }
    [openChestMenu setPosition:CGPointMake(512, 240)];
    [self addChild:openChestMenu];
}

- (void)lootChest
{
    [self lootChestWithStaminaRequirement:YES];
}

- (void)displayNetworkErrorModal
{
    IconDescriptionModalLayer *networkError = [[[IconDescriptionModalLayer alloc] initWithIconName:nil title:@"Connection Required" andDescription:@"An Internet Connection is required to loot chests.  Please verify your connection and try again."] autorelease];
    [networkError setDelegate:self];
    [self addChild:networkError z:1000];
}

- (void)displayNeedKeysModal
{
    IconDescriptionModalLayer *needKeysModal = [[[IconDescriptionModalLayer alloc] initWithIconName:nil title:@"Key Required" andDescription:@"You are all out of keys.  Wait for more keys or buy a key to open this chest."] autorelease];
    [needKeysModal setDelegate:self];
    [self addChild:needKeysModal z:1000];
}

- (void)lootChestWithStaminaRequirement:(BOOL)staminaRequirement
{
    self.openChest.visible = NO;
    [self.chestSprite runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCRotateTo actionWithDuration:.33 angle:-5.0], [CCRotateTo actionWithDuration:.33 angle:5.0], nil]]];
    SpendStaminaResultBlock spendStamina = ^(BOOL success){
        [self.chestSprite setRotation:0.0];
        [self.chestSprite stopAllActions];
        if (success) {
            EquipmentItem *itemLooted = self.encounter.randomLootReward;
            [self.chestSprite openWithItem:itemLooted];
            [[PlayerDataManager localPlayer] playerEarnsItem:itemLooted];
            self.isLootSequencedCompleted = YES;
        } else {
            self.openChest.visible = YES;
            if ([PlayerDataManager localPlayer].stamina == 0) {
                self.getKeys.visible = YES;
            }
            
            if ([PlayerDataManager localPlayer].stamina == STAMINA_NOT_LOADED) {
                [self displayNetworkErrorModal];
            } else if ([PlayerDataManager localPlayer].stamina == 0) {
                [self displayNeedKeysModal];
            }
        }
    };
    if (staminaRequirement) {
        [[PlayerDataManager localPlayer] staminaUsedWithCompletion:spendStamina];
    } else {
        spendStamina(YES);
    }
}

- (void)buyKeys
{
    self.openChest.visible = NO;
    self.getKeys.visible = NO;
    [[PurchaseManager sharedPurchaseManager] purchaseChestKeyWithCompletion:^(BOOL success){
        if (success) {
            self.getKeys.visible = NO;
            [self lootChestWithStaminaRequirement:NO];
        } else {
            self.openChest.visible = YES;
            self.getKeys.visible = YES;
        }
    
    }];
}

- (void)configureAdvanceMenu
{
    if (self.advanceMenu) {
        [self.advanceMenu removeFromParentAndCleanup:YES];
        self.advanceMenu = nil;
    }
    
    int totalOptions = 1;
    int buttonHeight = 76;
    NSString* doneLabelString = self.isMultiplayer ? @"Leave Group" : @"Adventure";
    CCMenuItem *done = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneMap) andTitle:doneLabelString];
    CCMenuItem *academy = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneAcademy) andTitle:@"Academy"];
    CCMenuItem *armory = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneArmory) andTitle:@"Armory"];
    self.advanceMenu = [CCMenu menuWithItems:academy, nil];
    self.advanceMenu.anchorPoint = CGPointMake(0, 0);
    [self addChild:self.advanceMenu];
    
    
    if (!self.showsFirstLevelFTUE) {
        [done setPosition:CGPointMake(0, totalOptions * buttonHeight)];
        [self.advanceMenu addChild:done];
        totalOptions++;
        
        [armory setPosition:CGPointMake(0, totalOptions * buttonHeight)];
        [self.advanceMenu addChild:armory];
        totalOptions++;
        
        if ([[PlayerDataManager localPlayer] numUnspentTalentChoices]) {
            CCMenuItem *talentButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneTalents) andTitle:@"Talents" andAlertPip:YES];
            [talentButton setPosition:CGPointMake(0, totalOptions * buttonHeight)];
            [self.advanceMenu addChild:talentButton];
            totalOptions++;
        }
    }

}

-(void)setMatch:(GKMatch *)mtch{
    [_match release];
    _match = [mtch retain];
    //[self.match setDelegate:self];
}

- (void)iconDescriptionModalDidComplete:(id)modal
{
    IconDescriptionModalLayer *completedModal = (IconDescriptionModalLayer*)modal;
    if (completedModal.isConfirmed) {
        [self.delegate postBattleLayerDidTransitionToScene:self.chosenDestination asVictory:self.isVictory];
    }
    [completedModal removeFromParentAndCleanup:YES];
}

@end

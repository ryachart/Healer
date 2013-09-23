//
//  LevelSelectMapScene.m
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "LevelSelectMapScene.h"
#import "BasicButton.h"
#import "HealerStartScene.h"
#import "EncounterCard.h"
#import "Encounter.h"
#import "PreBattleScene.h"
#import "Player.h"
#import "Talents.h"
#import "PlayerDataManager.h"
#import "GoldCounterSprite.h"
#import "SimpleAudioEngine.h"


@interface LevelSelectMapScene ()
@property (nonatomic, assign) LevelSelectMapNode *mapScrollView;
@property (assign) CCMenu *diffMenu;
@property (nonatomic, assign) EncounterCard *encCard;
@property (nonatomic, assign) BasicButton *battleButton;
@property (nonatomic, readwrite) NSInteger selectedLevel;

@end

@implementation LevelSelectMapScene

- (void)dealloc
{
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/mapicon.plist"];
        
        self.mapScrollView = [[[LevelSelectMapNode alloc] init] autorelease];
        [self.mapScrollView setLevelSelectDelegate:self];
        [self addChild:self.mapScrollView];
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:BACK_BUTTON_POS];
        [self addChild:backButton z:100];
        
        self.battleButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(battle) andTitle:@"Continue"];
        CCMenu *battleMenu = [CCMenu menuWithItems:self.battleButton, nil];
        [battleMenu setPosition:CGPointMake(900, 40)];
        [self addChild:battleMenu z:5];
        
        GoldCounterSprite *gcs = [[[GoldCounterSprite alloc] init] autorelease];
        [gcs setPosition:CGPointMake(100, 45)];
        [self addChild:gcs z:100];
        
    }
    return self;
}

- (void)onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    if (![SimpleAudioEngine sharedEngine].isBackgroundMusicPlaying) {
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"sounds/theme.mp3" loop:YES];
    }
    
    if (self.comingFromVictory) {
        if ([[PlayerDataManager localPlayer] shouldRequestAppStore]) {
            UIAlertView *rateUs = [[[UIAlertView alloc] initWithTitle:@"Rate Us?!" message:@"Enjoying Healer? Let others know how you feel by rating us on the App Store!" delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Okay", nil] autorelease];
            [rateUs setDelegate:self];
            [rateUs show];
        }
    }
}

- (void)loadEncounterCardForSelectedEncounter:(NSInteger)selectedEncounter {
    [self.encCard setLevelNum:selectedEncounter];
}

- (void)battle {
    NSInteger level = self.selectedLevel;
    
    if (![[PlayerDataManager localPlayer] hasPurchasedContentWithKey:MainGameContentKey] && level > END_FREE_ENCOUNTER_LEVEL) {
        //Player hasn't unlocked this level yet! Wanna buy Legacy of Torment?
        IconDescriptionModalLayer *purchaseModal = [[[IconDescriptionModalLayer alloc] initAsMainContentSalesModal] autorelease];
        [purchaseModal setDelegate:self];
        [self addChild:purchaseModal z:100];
        return;
    }
    
    Encounter *encounter = [Encounter encounterForLevel:level isMultiplayer:NO];
    Player *basicPlayer = [PlayerDataManager playerFromLocalPlayer];
    [basicPlayer configureForRecommendedSpells:encounter.recommendedSpells withLastUsedSpells:[PlayerDataManager localPlayer].lastUsedSpells];
    
    if (encounter.enemies.count > 0 && basicPlayer && encounter.raid){
        PreBattleScene *pbs = [[[PreBattleScene alloc] initWithEncounter:encounter andPlayer:basicPlayer] autorelease];
        [pbs setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:pbs]];
    }
}

- (void)onExitTransitionDidStart {
    [super onExitTransitionDidStart];
}

-(void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}

- (void)levelSelectMapNodeDidSelectLevelNum:(NSInteger)levelNum
{
    if (self.selectedLevel == levelNum) {
        [self battle];
    } else {
        self.selectedLevel = levelNum;
        [self loadEncounterCardForSelectedEncounter:levelNum];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [[PlayerDataManager localPlayer] appStoreReviewPerformed];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/healer-a-light-in-the-darkness/id641418872?ls=1&mt=8"]];
    }
}

- (void)iconDescriptionModalDidComplete:(id)modal
{
    IconDescriptionModalLayer *idml = (IconDescriptionModalLayer*)modal;
    [idml removeFromParentAndCleanup:YES];
}

@end

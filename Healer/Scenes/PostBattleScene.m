//
//  PostBattleScene.m
//  Healer
//
//  Created by Ryan Hart on 3/3/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "PostBattleScene.h"
#import "QuickPlayScene.h"
#import "MultiplayerSetupScene.h"
#import "CombatEvent.h"
#import "Boss.h"
#import "Encounter.h"
#import "PersistantDataManager.h"
#import <UIKit/UIKit.h>
#import "Shop.h"
#import "StoreScene.h"

@interface PostBattleScene()
@property (nonatomic, readwrite) BOOL canAdvance;
-(void)done;
@end

@implementation PostBattleScene
@synthesize matchVoiceChat, match=_match, serverPlayerId, canAdvance;

-(id)initWithVictory:(BOOL)victory eventLog:(NSArray*)eventLog levelNumber:(NSInteger)levelNumber andIsMultiplayer:(BOOL)isMultiplayer{
    self = [super init];
    if (self){
        if (victory){
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"VICTORY!" fontName:@"Arial" fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
            
            NSInteger reward = 0;
            int i = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue];
            if (levelNumber > i){
                [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:levelNumber] forKey:PlayerHighestLevelCompleted];
                reward = [Encounter goldForLevelNumber:levelNumber isFirstWin:YES isMultiplayer:isMultiplayer];
            }else{
                reward = [Encounter goldForLevelNumber:levelNumber isFirstWin:NO isMultiplayer:isMultiplayer];
            }

            [Shop playerEarnsGold:reward];
            CCLabelTTF *goldEarned = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold Earned: %i", reward] fontName:@"Arial" fontSize:32.0];
            
            [goldEarned setPosition:CGPointMake(800, 150)];
            [self addChild:goldEarned];
            
            if (!isMultiplayer){
                CCMenuItemLabel *visitShopButton = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Visit Shop" fontName:@"Arial" fontSize:32.0] block:^(id sender){
                    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInR transitionWithDuration:.5 scene:[[StoreScene new] autorelease]]];
                }];
                
                CCMenu *visitStoreMenu = [CCMenu menuWithItems:visitShopButton, nil];
                [visitStoreMenu setPosition:CGPointMake(800, 100)];
                [self addChild:visitStoreMenu];
            }
        }else{
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"DEFEAT!" fontName:@"Arial" fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
        }
    
        CCMenuItemLabel *done = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Continue" fontName:@"Arial" fontSize:32] target:self selector:@selector(done)];
        
        CCMenu *menu = [CCMenu menuWithItems:done, nil];
        menu.position = CGPointMake(512, 200);
        [self addChild:menu];
        
        int totalHealingDone = 0;
        
        for (CombatEvent *event in eventLog){
            if (event.type == CombatEventTypeHeal){
                totalHealingDone += [[event value] intValue];
            }
        }
        
        int raidersLost = 0;
        for (CombatEvent *event in eventLog){
            if (event.type == CombatEventTypeMemberDied){
                raidersLost ++;            
            }
        }
        
        int totalDamageTaken = 0;
        for (CombatEvent *event in eventLog){
            if (event.type == CombatEventTypeDamage && [[event source] isKindOfClass:[Boss class]]){
                NSInteger dmgVal = [[event value] intValue];
                if (dmgVal < 0) dmgVal *= -1;
                totalDamageTaken += dmgVal;            
            }
        }
        
        CCLabelTTF *healingDoneLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Healing Done: %i", totalHealingDone] dimensions:CGSizeMake(350, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [healingDoneLabel setPosition:CGPointMake(200, 200)];
        
        CCLabelTTF *damageTakenLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Damage Taken: %i", totalDamageTaken] dimensions:CGSizeMake(350, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [damageTakenLabel setPosition:CGPointMake(200, 135)];
        
        CCLabelTTF *playersLostLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Allies Lost:  %i", raidersLost] dimensions:CGSizeMake(350, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [playersLostLabel setPosition:CGPointMake(200, 90)];
        
        [self addChild:healingDoneLabel];
        [self addChild:damageTakenLabel];
        [self addChild:playersLostLabel];
        
    }
    return self;
}

-(void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    if (self.serverPlayerId == [GKLocalPlayer localPlayer].playerID){
        self.canAdvance = YES;
    }
}

-(void)setMatch:(GKMatch *)mtch{
    [_match release];
    _match = [mtch retain];
    [self.match setDelegate:self];
}
                            
-(void)done{
    if (self.serverPlayerId){
        if (!self.canAdvance){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Waiting on Game Owner" message:@"You must wait for the game's owner to continue"  delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alertView show];
            [alertView release];
            return;
        }
        //Go to multiplayer select
        MultiplayerSetupScene *mss = [[MultiplayerSetupScene alloc] initWithPreconfiguredMatch:self.match andServerID:self.serverPlayerId];
        self.match.delegate = mss;
        [mss setMatchVoiceChat:self.matchVoiceChat];
        [[CCDirector sharedDirector] replaceScene:mss];
        [mss release];
        
    }else{
        QuickPlayScene *qps = [[QuickPlayScene alloc] init];
        [[CCDirector sharedDirector] replaceScene:qps];
        [qps release];
    }
}

#pragma mark - GKMatchDelegate
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {    
    if (self.match != theMatch) return;
    
    NSString* message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([message isEqualToString:@"POSTBATTLEEND"]){
        self.canAdvance = YES;
    }
    [message release];
    
}
@end

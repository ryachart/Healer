//
//  PostBattleScene.m
//  Healer
//
//  Created by Ryan Hart on 3/3/12.
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
#import "BackgroundSprite.h"
#import "TestFlight.h"
#import "Divinity.h"
#import "DivinityConfigScene.h"
#import "AudioController.h"

@interface PostBattleScene()
@property (nonatomic, readwrite) BOOL canAdvance;
@property (nonatomic, readwrite) NSInteger levelNumber;
@property (nonatomic, readwrite) BOOL isMultiplayer;
@property (nonatomic, readwrite) BOOL isVictory;
- (BOOL)writeApplicationData:(NSData *)data toFile:(NSString *)fileName;
- (NSString*)timeStringForTimeInterval:(NSTimeInterval)interval;
- (void)done;
- (void)showDivinityUnlocked;
- (void)goToDivinity;
@end

@implementation PostBattleScene
@synthesize matchVoiceChat, match=_match, serverPlayerId, canAdvance;
@synthesize levelNumber, isMultiplayer;
@synthesize isVictory;
- (void)dealloc {
    [_match release];
    [serverPlayerId release];
    [matchVoiceChat release];
    [super dealloc];
}

-(id)initWithVictory:(BOOL)victory eventLog:(NSArray*)eventLog levelNumber:(NSInteger)levelNum andIsMultiplayer:(BOOL)isMult{
    self = [super init];
    if (self){
        self.levelNumber = levelNum;
        self.isMultiplayer = isMult;
        self.isVictory = victory;
        BackgroundSprite *background = [[[BackgroundSprite alloc] initWithAssetName:@"wood-bg-ipad"] autorelease];
        [self addChild:background];
        if (victory){
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"VICTORY!" fontName:@"Arial" fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
            
            NSInteger reward = 0;
            int i = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue];
            if (self.levelNumber > i){
                [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:self.levelNumber] forKey:PlayerHighestLevelCompleted];
                [TestFlight passCheckpoint:[NSString stringWithFormat:@"LevelComplete:%i",i]];
                reward = [Encounter goldForLevelNumber:self.levelNumber isFirstWin:YES isMultiplayer:self.isMultiplayer];
            }else{
                reward = [Encounter goldForLevelNumber:self.levelNumber isFirstWin:NO isMultiplayer:self.isMultiplayer];
            }

            [Shop playerEarnsGold:reward];
            CCLabelTTF *goldEarned = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold Earned: %i", reward] fontName:@"Arial" fontSize:32.0];
            
            [goldEarned setPosition:CGPointMake(800, 150)];
            [self addChild:goldEarned];
            
            if (!self.isMultiplayer){
                CCMenuItemLabel *visitShopButton = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Visit Shop" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(goToStore)];                
                [visitShopButton.label setColor:ccBLUE];
                CCMenu *visitStoreMenu = [CCMenu menuWithItems:visitShopButton, nil];
                [visitStoreMenu setPosition:CGPointMake(770, 90)];
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
        
        NSTimeInterval fightDuration = [[[eventLog lastObject] timeStamp] timeIntervalSinceDate:[[eventLog objectAtIndex:0] timeStamp]];
        NSString *durationText = [@"Duration: " stringByAppendingString:[self timeStringForTimeInterval:fightDuration]];
        
        CCLabelTTF *durationLabel = [CCLabelTTF labelWithString:durationText dimensions:CGSizeMake(350, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [durationLabel setPosition:CGPointMake(200, 240)];
        [self addChild:durationLabel];
        
#if DEBUG
        NSMutableArray *events = [NSMutableArray arrayWithCapacity:eventLog.count];
        for (CombatEvent *event in eventLog){
            [events addObject:[event logLine]];
        }
        //Save the Combat Log to disk...
        
        [self writeApplicationData:(NSData*)events toFile:[NSString stringWithFormat:@"%@-%@", [[eventLog   objectAtIndex:0] timeStamp], [[eventLog lastObject] timeStamp]]];
#endif

    }
    return self;
}

- (NSString*)timeStringForTimeInterval:(NSTimeInterval)interval{
    NSInteger minutes = interval / 60;
    NSInteger seconds = (int)interval % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}
         
- (BOOL)writeApplicationData:(NSData *)data toFile:(NSString *)fileName {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	if (!documentsDirectory) {
		NSLog(@"Documents directory not found!");
		return NO;
	}
	NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
	return ([data writeToFile:appFile atomically:YES]);
}

- (void)onEnterTransitionDidFinish{
    [super onEnterTransitionDidFinish];
    if (self.serverPlayerId == [GKLocalPlayer localPlayer].playerID){
        self.canAdvance = YES;
    }
    if (self.levelNumber >= 6 && ![Divinity isDivinityUnlocked] && !self.isMultiplayer && self.isVictory){
        [Divinity unlockDivinity];
        [self showDivinityUnlocked];
    }
}

- (void)onExit {
    [[AudioController sharedInstance] stopAll];
    [[AudioController sharedInstance] playTitle:@"title" looping:10];
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

- (void)showDivinityUnlocked {
    CCMenuItemLabel *goToDivinity = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Go to Divinity" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(goToDivinity)];
    CCMenu *goToDivinityMenu = [CCMenu menuWithItems:goToDivinity, nil];
    [goToDivinityMenu setOpacity:0];
    [goToDivinityMenu setPosition:CGPointMake(512, 520)];
    [self addChild:goToDivinityMenu];
    
    CCLabelTTF *divinityUnlocked = [CCLabelTTF labelWithString:@"DIVINITY UNLOCKED!" dimensions:CGSizeMake(600, 200) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:72.0];
    [divinityUnlocked setColor:ccYELLOW];
    [divinityUnlocked setPosition:CGPointMake(512, 614)];
    [divinityUnlocked setScale:3.0];
    [divinityUnlocked setOpacity:0];
    [self addChild:divinityUnlocked];
    
    [divinityUnlocked runAction:[CCSequence actions:[CCSpawn actions:[CCFadeIn actionWithDuration:1.5], [CCScaleTo actionWithDuration:.5 scale:1.0], nil], [CCCallBlock actionWithBlock:^{[goToDivinityMenu runAction:[CCFadeIn actionWithDuration:1.0]];}], nil]];
    
}
                                                                    
- (void)goToDivinity {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionRadialCCW transitionWithDuration:.5 scene:[[[DivinityConfigScene alloc] init] autorelease]]];
}

- (void)goToStore {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInR transitionWithDuration:.5 scene:[[StoreScene new] autorelease]]];
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

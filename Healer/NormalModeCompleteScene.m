//
//  NormalModeCompleteScene.m
//  Healer
//
//  Created by Ryan Hart on 9/21/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "NormalModeCompleteScene.h"
#import "PersistantDataManager.h"
#import "PostBattleScene.h"
#import "BasicButton.h"
#import "BackgroundSprite.h"

@interface NormalModeCompleteScene ()
@property (nonatomic, retain) NSArray *eventLog;
@property (nonatomic, readwrite) NSInteger levelNumber;
@property (nonatomic, readwrite) NSInteger deadCount;
@property (nonatomic, readwrite) NSTimeInterval duration;
@end

@implementation NormalModeCompleteScene
- (void)dealloc {
    [_eventLog release];
    [super dealloc];
}
+ (BOOL)needsNormalModeCompleteSceneForLevelNumber:(NSInteger)levelNumber {
#if TARGET_IPHONE_SIMULATOR
    if (levelNumber == 21){
        return YES;
    }
#endif
    if (CURRENT_MODE == DifficultyModeNormal){
        if (levelNumber == 21){
            return ![PlayerDataManager hasShownNormalModeCompleteScene];
        }
    }
    return NO;
}

- (id)initWithVictory:(BOOL)victory eventLog:(NSArray*)eventLog levelNumber:(NSInteger)levelNumber andIsMultiplayer:(BOOL)isMultiplayer deadCount:(NSInteger)numDead andDuration:(NSTimeInterval)duration {
    if (self = [super init]){
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background-ipad"] autorelease]];

        CCLabelTTF *normalModeCompleteLabel = [CCLabelTTF labelWithString:@"Normal Cleared!" dimensions:CGSizeMake(600, 200) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:64.0];
        [normalModeCompleteLabel setPosition:CGPointMake(512, 600)];
        [self addChild:normalModeCompleteLabel];
        
        NSString* storyDesc = @"Good job beating the game, Tester! Soul of Torment will be available in the final release!  More challenges await you in Hard Mode.";
        CCLabelTTF *storyDescLabel = [CCLabelTTF labelWithString:storyDesc dimensions:CGSizeMake(400, 400) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:20.0];
        [storyDescLabel setPosition:CGPointMake(512, 250)];
        [self addChild:storyDescLabel];
        
        BasicButton *done = [BasicButton basicButtonWithTarget:self andSelector:@selector(done) andTitle:@"Done"];
        CCMenu *doneMenu = [CCMenu menuWithItems:done, nil];
        [doneMenu setPosition:CGPointMake(900, 50)];
        [self addChild:doneMenu];
        
    }
    return self;
}

- (void)done {
    [PlayerDataManager hasShownNormalModeCompleteScene];
    PostBattleScene *pbs = [[PostBattleScene alloc] initWithVictory:YES eventLog:self.eventLog levelNumber:self.levelNumber andIsMultiplayer:NO deadCount:self.deadCount andDuration:self.duration];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInT transitionWithDuration:1.0 scene:pbs]];
    [pbs release];
}
@end

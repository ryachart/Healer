//
//  NormalModeCompleteScene.m
//  Healer
//
//  Created by Ryan Hart on 9/21/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "NormalModeCompleteScene.h"
#import "PlayerDataManager.h"
#import "PostBattleScene.h"
#import "BasicButton.h"
#import "BackgroundSprite.h"
#import "Encounter.h"

@interface NormalModeCompleteScene ()
@property (nonatomic, retain) NSArray *eventLog;
@property (nonatomic, retain) Encounter *encounter;
@property (nonatomic, readwrite) NSInteger deadCount;
@property (nonatomic, readwrite) NSTimeInterval duration;
@end

@implementation NormalModeCompleteScene
- (void)dealloc {
    [_eventLog release];
    [_encounter release];
    [super dealloc];
}
+ (BOOL)needsNormalModeCompleteSceneForLevelNumber:(NSInteger)levelNumber {
#if TARGET_IPHONE_SIMULATOR
    if (levelNumber == 21){
        return YES;
    }
#endif
    if (levelNumber == 21){
        return ![[PlayerDataManager  localPlayer] hasShownNormalModeCompleteScene];
    }
    return NO;
}

- (id)initWithVictory:(BOOL)victory encounter:(Encounter*)encounter andIsMultiplayer:(BOOL)isMultiplayer andDuration:(NSTimeInterval)duration {
    if (self = [super init]){
        self.encounter = encounter;
        self.duration = duration;
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background"] autorelease]];
        
        CCLabelTTF *normalModeCompleteLabel = [CCLabelTTF labelWithString:@"Torment has been Vanquished!" dimensions:CGSizeMake(600, 200) hAlignment:UITextAlignmentCenter fontName:@"Arial" fontSize:64.0];
        [normalModeCompleteLabel setPosition:CGPointMake(512, 600)];
        [self addChild:normalModeCompleteLabel];
        
        NSString* storyDesc = @"The Avatar of Torment has been silenced, and the demons pouring into your homeworld have receeded.  Peace fills your mind, but only for a moment.  Delsarn is but one terrible realm, and it is only a matter of time before more of these terrors find their way to your homeland.";
        CCLabelTTF *storyDescLabel = [CCLabelTTF labelWithString:storyDesc dimensions:CGSizeMake(400, 400) hAlignment:UITextAlignmentCenter fontName:@"Arial" fontSize:20.0];
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
    [[PlayerDataManager localPlayer] hasShownNormalModeCompleteScene];
    PostBattleScene *pbs = [[PostBattleScene alloc] initWithVictory:YES encounter:self.encounter andIsMultiplayer:NO andDuration:self.duration];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInT transitionWithDuration:1.0 scene:pbs]];
    [pbs release];
}
@end

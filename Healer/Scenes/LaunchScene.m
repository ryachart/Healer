//
//  LaunchScene.m
//  Healer
//
//  Created by Ryan Hart on 9/23/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "LaunchScene.h"
#import "BackgroundSprite.h"
#import "HealerStartScene.h"

@interface LaunchScene ()
@end

@implementation LaunchScene
- (void)dealloc {
    [super dealloc];
}

- (void)onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    BackgroundSprite *bg = [BackgroundSprite launchImageBackground];
    [self addChild:bg z:1001];
    [bg runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:1.0] two:[CCCallFunc actionWithTarget:self selector:@selector(goToStart)]]];
}

- (void)goToStart
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[HealerStartScene new] autorelease]]];
}
@end

//
//  LevelSelectScene_iPhone.m
//  Healer
//
//  Created by Ryan Hart on 5/20/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "LevelSelectScene_iPhone.h"
#import "BasicButton.h"
#import "HealerStartScene_iPhone.h"

@implementation LevelSelectScene_iPhone

- (id)init
{
    if (self = [super init]) {
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [self addChild:backButton];
        [backButton setPosition:CGPointMake(50, SCREEN_HEIGHT * .8)];
        
        NSLog(@"SCREEN HEIGHT : %1.2f", SCREEN_HEIGHT);
    }
    return self;
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene_iPhone alloc] init] autorelease]]];
}

@end

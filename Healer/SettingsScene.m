//
//  SettingsScene.m
//  Healer
//
//  Created by Ryan Hart on 11/10/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "SettingsScene.h"
#import "BasicButton.h"
#import "HealerStartScene.h"
#import "BackgroundSprite.h"


@implementation SettingsScene

- (id)init
{
    if (self = [super init]) {
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background"] autorelease]];

        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:CGPointMake(90, [CCDirector sharedDirector].winSize.height * .95)];
        [self addChild:backButton];
    }
    return self;
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}
@end

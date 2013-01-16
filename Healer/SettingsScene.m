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
#import "PlayerDataManager.h"


@implementation SettingsScene

- (id)init
{
    if (self = [super init]) {
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background"] autorelease]];
        
        BasicButton *resetGame = [BasicButton basicButtonWithTarget:self andSelector:@selector(resetGame) andTitle:@"Erase Data"];
        
        CCMenu *settingsMenu = [CCMenu menuWithItems:resetGame, nil];
        [settingsMenu setPosition:CGPointMake(512, 384)];
        [self addChild:settingsMenu];

        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:CGPointMake(90, [CCDirector sharedDirector].winSize.height * .95)];
        [self addChild:backButton];
    }
    return self;
}

- (void)resetGame
{
    UIAlertView *areYouSure = [[[UIAlertView alloc] initWithTitle:@"Are you Sure?" message:@"Are you sure you want to erase all of your game data and start over again? Your data will not be recoverable." delegate:self cancelButtonTitle:@"No!" otherButtonTitles:@"Yes", nil] autorelease];
    [areYouSure show];
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex != buttonIndex) {
        [[PlayerDataManager localPlayer] resetPlayer];
    }
}
@end

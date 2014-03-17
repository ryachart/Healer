//
//  TalentScene_iPhone.m
//  Healer
//
//  Created by Ryan Hart on 3/16/14.
//  Copyright (c) 2014 Ryan Hart Games. All rights reserved.
//

#import "TalentScene_iPhone.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"
#import "HealerStartScene_iPhone.h"

@implementation TalentScene_iPhone

- (id)init
{
    if (self = [super init]) {
        BackgroundSprite *bgSprite = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg"] autorelease];
        [self addChild:bgSprite];
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [self addChild:backButton];
        [backButton setPosition:CGPointMake(85, SCREEN_HEIGHT * .92)];
    }
    return self;
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene_iPhone alloc] init] autorelease]]];
}

@end

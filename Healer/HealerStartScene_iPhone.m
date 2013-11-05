//
//  HealerStartScene-iPhone.m
//  Healer
//
//  Created by Ryan Hart on 5/19/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "HealerStartScene_iPhone.h"
#import "BasicButton.h"
#import "BackgroundSprite.h"
#import "GoldCounterSprite.h"
#import "LevelSelectScene_iPhone.h"
#import "ShopScene_iPhone.h"

@implementation HealerStartScene_iPhone

- (id)init
{
    if (self = [super init]) {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets-iphone/sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets-iphone/spell-sprites.plist"];
        
        BackgroundSprite *bgSprite = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg"] autorelease];
        [self addChild:bgSprite];
        
        BasicButton *playButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(play) andTitle:@"Play"];
        
        BasicButton *academy = [BasicButton basicButtonWithTarget:self andSelector:@selector(academy) andTitle:@"Academy"];
        
        BasicButton *talents = [BasicButton basicButtonWithTarget:self andSelector:@selector(talents) andTitle:@"Talents"];
        
        CCSprite *logo = [CCSprite spriteWithSpriteFrameName:@"home_logo.png"];
        [self addChild:logo];
        [logo setScale:.85];
        logo.position = CGPointMake(160, SCREEN_HEIGHT * .65);
        
        CCMenu *menu = [CCMenu menuWithItems:playButton, academy, talents, nil];
        [self addChild:menu];
        [menu alignItemsVertically];
        
        GoldCounterSprite *goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(234, 40)];
        [self addChild:goldCounter];

    }
    return self;
}

- (void)play
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[LevelSelectScene_iPhone alloc] init] autorelease]]];
}

- (void)academy
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[ShopScene_iPhone alloc] init] autorelease]]];
}

- (void)talents
{
    
}

@end

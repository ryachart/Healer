//
//  PostBattleLayer_iPhone.m
//  Healer
//
//  Created by Ryan Hart on 9/21/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "PostBattleLayer_iPhone.h"
#import "BasicButton.h"

@implementation PostBattleLayer_iPhone

- (id)initWithVictory:(BOOL)victory encounter:(Encounter *)enc andIsMultiplayer:(BOOL)isMult andDuration:(NSTimeInterval)duration
{
    if (self = [super init]) {
        BasicButton *leave = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneMap) andTitle:@"Leave"];
        [leave setPosition:CGPointMake(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 100)];
        [self addChild:leave];
    }
    return self;
}

- (void)doneMap
{
    [self.delegate postBattleLayerDidTransitionToScene:PostBattleLayerDestinationMap asVictory:NO];
}


@end

//
//  RatingCounterSprite.m
//  Healer
//
//  Created by Ryan Hart on 11/16/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "RatingCounterSprite.h"
#import "PlayerDataManager.h"
#import "CCLabelTTFShadow.h"

@interface RatingCounterSprite ()
@end

@implementation RatingCounterSprite

- (void)dealloc{
    [super dealloc];
}

- (id)init {
    if (self = [super init]){
        self.updatesAutomatically = YES;
        
        CCSprite *backgroundSprite = [CCSprite spriteWithSpriteFrameName:@"counter_bg.png"];
        [self addChild:backgroundSprite];
        
        NSInteger rating = [[PlayerDataManager localPlayer] totalRating];
        
        CCSprite *skullSprite = [CCSprite spriteWithSpriteFrameName:@"difficulty_skull_big.png"];
        [skullSprite setPosition:CGPointMake(30, 32)];
        [backgroundSprite addChild:skullSprite];
        
        self.ratingAmountLabel = [CCLabelTTFShadow   labelWithString:[NSString stringWithFormat:@"%i", rating] dimensions:[[CCSprite spriteWithSpriteFrameName:@"gold_bg.png"] contentSize] hAlignment:UITextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        [self.ratingAmountLabel setPosition:CGPointMake(60, 20)];
        [backgroundSprite addChild:self.ratingAmountLabel];
    }
    return self;
}

@end

//
//  DivinityConfigScene.m
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "DivinityConfigScene.h"
#import "HealerStartScene.h"
#import "Divinity.h"
#import "BasicButton.h"
#import "Shop.h"


@interface DivinityConfigScene  ()
- (void)back;

@end

@implementation DivinityConfigScene

- (id)init {
    if (self = [super init]){
        CCMenu *backButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Back" fontName:@"Arial" fontSize:24.0] target:self selector:@selector(back)], nil];
        [backButton setPosition:CGPointMake(30, [CCDirector sharedDirector].winSize.height * .96)];
        [backButton setColor:ccWHITE];
        [self addChild:backButton];
        
        
        for (int i = 0; i < 4; i++){
            //Divider Lines
            CCLayerColor *dividerLine = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
            [dividerLine setContentSize:CGSizeMake(1024, 1)];
            [dividerLine setPosition:CGPointMake(0, (768/5 * (i + 1)))];
            [self addChild:dividerLine];
        }
        
        for (int i = 0; i < 5; i++){
            NSArray *choices = [Divinity divinityChoicesForTier:i];
            for (int j = 0; j < 3; j++){
                CCSprite *choice = [CCSprite spriteWithSpriteFrameName:@"default_divinity.png"];
                CCLabelTTF *choiceTitle =  [CCLabelTTF labelWithString:[choices objectAtIndex:j] dimensions:CGSizeMake(200, 100) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:16.0];
                CCLabelTTF *choiceDesc = [CCLabelTTF labelWithString:[Divinity descriptionForChoice:[choices objectAtIndex:j]] dimensions:CGSizeMake(200, 100) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:16.0];
                [choiceDesc setPosition:CGPointMake(-80, -10)];
                [choiceTitle setPosition:CGPointMake(35, -50)];
                [choice setOpacity:122];
                [choice setPosition:CGPointMake(200 + (250 * j), (768/5 * (5 - i) - 80))];
                [self addChild:choice];
                [choice addChild:choiceTitle];
                [choice addChild:choiceDesc];
            }

        }
        
        NSInteger nextTier = [Shop numDivinityTiersPurchased]; 
        CCMenuItem *buyNextTierButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(buyNextTierSelected) andTitle:@"Buy Tier"];
        
        CCMenu *buyNextTierMenu = [CCMenu menuWithItems:buyNextTierButton, nil];
        [buyNextTierMenu setPosition:CGPointMake(900, (768/5 * (5 - nextTier) - 90))];
        [self addChild:buyNextTierMenu];
        
    }
    return self;
}

- (void)buyNextTierSelected {
    UIAlertView *sorry = [[UIAlertView alloc] initWithTitle:@"Divinity not in" message:@"Building your divinity is coming soon.  Sorry!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
    [sorry show];
    [sorry release];
}

- (void)back {
    [[CCDirector sharedDirector] replaceScene:[[[HealerStartScene alloc] init] autorelease]];
}

@end

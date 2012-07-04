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
- (void)divinityTierSelected:(id)sender;

@end

@implementation DivinityConfigScene

- (id)init {
    if (self = [super init]){
        [self layoutContents];
    }
    return self;
}

- (void)layoutContents {
    [self removeAllChildrenWithCleanup:YES];
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
    NSInteger nextTier = [Shop numDivinityTiersPurchased];
    NSInteger nextTierCost = [Shop costForNextDivinityTier];
    
    for (int i = 0; i < 5; i++){
        NSArray *choices = [Divinity divinityChoicesForTier:i];
        for (int j = 0; j < 3; j++){
            CCMenu *choice = [BasicButton spriteButtonWithSpriteFrameName:@"default_divinity.png" target:self andSelector:@selector(divinityTierSelected:)];
            [[choice.children objectAtIndex:0] setTag:i*10 + j];
            CCLabelTTF *choiceTitle =  [CCLabelTTF labelWithString:[choices objectAtIndex:j] dimensions:CGSizeMake(200, 100) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:16.0];
            NSString *description = @"????";
            if ( i < (nextTier + 2) ){
                description = [Divinity descriptionForChoice:[choices objectAtIndex:j]];
            }
            
            CCLabelTTF *choiceDesc = [CCLabelTTF labelWithString:description dimensions:CGSizeMake(180, 120) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:14.0];
            [choice setOpacity:122];
            [choice setPosition:CGPointMake(210 + (270 * j), (768/5 * (5 - i) - 80))];
            [self addChild:choice z:2];
            [choiceDesc setPosition:CGPointMake(choice.position.x-120, choice.position.y-30)];
            [choiceTitle setPosition:CGPointMake(choice.position.x, choice.position.y -90)];
            
            [self addChild:choiceTitle z:2];
            [self addChild:choiceDesc z:2];
            
            if ([[Divinity selectedChoiceForTier:i] isEqualToString:[choices objectAtIndex:j]] ){
                CCLayerColor *selectedBackground = [CCLayerColor layerWithColor:ccc4(255, 255, 0, 255)];
                [selectedBackground setPosition:CGPointMake((270 * j), (768/5 * (5 - i)) - 150)];
                [selectedBackground setContentSize:CGSizeMake(270, 110)];
                [self addChild:selectedBackground z:0];
                [choiceDesc setColor:ccBLACK];
                [choiceTitle setColor:ccBLACK];
            }
            
            if (i + 1 > nextTier) {
                [choiceTitle setOpacity:255];
                [choiceDesc setOpacity:255];
            }
        }
        
    }
    CCLabelTTF *tierCostLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cost: %i Gold",nextTierCost] dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:20.0];
    CCMenuItem *buyNextTierButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(buyNextTierSelected) andTitle:@"Buy Tier"];
    
    CCMenu *buyNextTierMenu = [CCMenu menuWithItems:buyNextTierButton, nil];
    [buyNextTierMenu setPosition:CGPointMake(900, (768/5 * (5 - nextTier) - 90))];
    
    [tierCostLabel setPosition:CGPointMake(buyNextTierMenu.position.x, buyNextTierMenu.position.y - 55)];
    [self addChild:buyNextTierMenu];
    [self addChild:tierCostLabel];
    
    int playerGold = [Shop localPlayerGold];
    CCSprite *goldBG = [CCSprite spriteWithSpriteFrameName:@"gold_bg.png"];
    CCLabelTTF *goldLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold: %i", playerGold] fontName:@"Arial" fontSize:32.0];
    [goldLabel setColor:ccBLACK];
    [goldLabel setPosition:CGPointMake(goldBG.contentSize.width /2 , goldBG.contentSize.height /2 )];
    [goldBG setPosition:CGPointMake(900, 740)];
    [self addChild:goldBG];
    [goldBG addChild:goldLabel];
}

- (void)buyNextTierSelected {
    if ([Shop localPlayerGold] >= [Shop costForNextDivinityTier]) {
        [Shop purchaseNextDivinityTier];
        [self layoutContents];
    }
//    UIAlertView *sorry = [[UIAlertView alloc] initWithTitle:@"Divinity not in" message:@"Building your divinity is coming soon.  Sorry!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
//    [sorry show];
//    [sorry release];
}

- (void)back {
    [[CCDirector sharedDirector] replaceScene:[[[HealerStartScene alloc] init] autorelease]];
}

- (void)divinityTierSelected:(id)sender {
    CCMenuItem *button = (CCMenuItem*)sender;
    NSInteger tier = button.tag / 10 % 10;
    NSInteger choice = button.tag % 10;
    NSString *choiceName = [[Divinity divinityChoicesForTier:tier] objectAtIndex:choice];
    
    if (tier < [Shop numDivinityTiersPurchased]) {
        [Divinity selectChoice:choiceName forTier:tier];
        [self layoutContents];
    }
    
    
}
@end

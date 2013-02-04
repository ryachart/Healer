//
//  DivinityConfigScene.m
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "TalentScene.h"
#import "HealerStartScene.h"
#import "BasicButton.h"
#import "Shop.h"
#import "GoldCounterSprite.h"
#import "BackgroundSprite.h"
#import "ModalDialogLayer.h"
#import "PlayerDataManager.h"
#import "RatingCounterSprite.h"



#define TIER_TABLE_Z 100
#define CHARGED_BAR_Z 50

@interface TalentScene  ()
@property (nonatomic, readwrite) BOOL showingDivPreview;

@end

@implementation TalentScene

- (id)init {
    if (self = [super init]){
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/divinity-sprites.plist"];
        BackgroundSprite *bgSprite = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"divinity-bg"] autorelease];
        [self addChild:bgSprite z:-100];
        
        RatingCounterSprite *goldCounter = [[[RatingCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(924, 54)];
        [self addChild:goldCounter];
        
        CCSprite *tierTable = [CCSprite spriteWithSpriteFrameName:@"divinity_table_frame.png"];
        [tierTable setAnchorPoint:CGPointMake(0, 0)];
        [self addChild:tierTable z:TIER_TABLE_Z];
        
        CCMenu *backMenu = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backMenu setPosition:CGPointMake(90, 710)];
        [self addChild:backMenu];
        
        CCLabelTTF *divinityLabel = [CCLabelTTF labelWithString:@"TALENTS" fontName:@"TeluguSangamMN-Bold" fontSize:64.0];
        [divinityLabel setPosition:CGPointMake(512, 700)];
        [self addChild:divinityLabel];
        
        [self layoutTierTable];
        [self layoutChargedPipeOverlays];
        [self layoutDivinityItems];
    }
    return self;
}

- (void)layoutTierTable {
    for (int i = 0; i < NUM_DIV_TIERS; i++){
        if (tierTableCards[i]){
            [tierTableCards[i] removeFromParentAndCleanup:YES];
        }
    }
    
    for (int i = 0; i < NUM_DIV_TIERS; i++){
        TalentTierCard *tierCard = [[[TalentTierCard alloc] initForDivinityTier:i] autorelease];
        [tierCard setDelegate:self];
        [tierCard setPosition:CGPointMake(696, 768 - 250 - (i * 96))];
        [self addChild:tierCard z:TIER_TABLE_Z + 1];
        tierTableCards[i] = tierCard;
    }
}

- (void)layoutChargedPipeOverlays {
    for (int i = 0; i < NUM_DIV_TIERS; i++){
        if (chargedPipes[i]){
            [chargedPipes[i] removeFromParentAndCleanup:YES];
        }
    }
    for (int i = 0; i < [Talents numDivinityTiersUnlocked]; i++){
        CCSprite *chargedPipe = [CCSprite spriteWithSpriteFrameName:@"divinity_unlocked_pipe.png"];
        [chargedPipe setAnchorPoint:CGPointZero];
        [chargedPipe setPosition:CGPointMake(133, 768 - 224 - (i * 111))];
        [self addChild:chargedPipe z:CHARGED_BAR_Z];
        chargedPipes[i] = chargedPipe;
    }
}

- (void)layoutDivinityItems {
    for (int i = 0; i < NUM_DIV_TIERS; i++){
        for (int j = 0; j < 3; j++){
            if (iconSprites[i][j]){
                [iconSprites[i][j] removeFromParentAndCleanup:YES];
            }
            if (buttonSprites[i][j]){
                [buttonSprites[i][j] removeFromParentAndCleanup:YES];
            }
        }
    }
    
    for (int i = 0; i < NUM_DIV_TIERS; i++){
        NSArray *choices = [Talents divinityChoicesForTier:i];
        for (int j = 0; j < choices.count; j++){
            NSString *choice = [choices objectAtIndex:j];
            CGPoint choicePosition = CGPointMake(90 + (j * 200), 768 - 152 - (i * 111));
            CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[Talents spriteFrameNameForChoice:choice]];
            if (!frame){
                frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"default_divinity.png"];
            }
            CCSprite *choiceSprite = [CCSprite spriteWithSpriteFrame:frame];
            [choiceSprite setScale:.5];
            [choiceSprite setPosition:choicePosition];
            [self addChild:choiceSprite];
            
            CCLabelTTF *choiceTitleLabel = [CCLabelTTF labelWithString:choice.uppercaseString dimensions:CGSizeMake(2.0 * choiceSprite.contentSize.width, 30) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:24.0];
            [choiceTitleLabel setPosition:CGPointMake(choiceSprite.contentSize.width / 2, -20)];
            [choiceSprite addChild:choiceTitleLabel];
            
            iconSprites[i][j] = choiceSprite;
            
            CCSprite *selectedButtonOverlay = [CCSprite spriteWithSpriteFrameName:@"divinity_item_selected.png"];
            [selectedButtonOverlay setOpacity:0];
            CCSprite *selectedButtonOverlaySelected = [CCSprite spriteWithSpriteFrameName:@"divinity_item_selected.png"];
            if ([[[PlayerDataManager localPlayer] selectedChoiceForTier:i] isEqualToString:choice]){
                [selectedButtonOverlay setOpacity:255];
            }
            if ([Talents numDivinityTiersUnlocked] > i){
                CCMenuItemSprite *menuItem = [CCMenuItemSprite itemWithNormalSprite:selectedButtonOverlay selectedSprite:selectedButtonOverlaySelected target:self selector:@selector(selectedChoice:)];
                [menuItem setTag:i];
                [menuItem setUserData:choice];
                [menuItem setNormalImage:selectedButtonOverlay];
                CCMenu *choiceMenu = [CCMenu menuWithItems:menuItem, nil];
                [choiceMenu  setPosition:CGPointMake(choicePosition.x + 90 + (j > 0 ? 16 : 0), choicePosition.y - 8)];
                [self addChild:choiceMenu z:CHARGED_BAR_Z - 1];
                buttonSprites[i][j] = choiceMenu;
            }else {
                selectedButtonOverlaySelected = [CCSprite spriteWithSpriteFrameName:@"divinity_item_tested.png"];
                CCMenuItemSprite *menuItem = [CCMenuItemSprite itemWithNormalSprite:selectedButtonOverlay selectedSprite:selectedButtonOverlaySelected target:self selector:@selector(testChoice:)];
                [menuItem setTag:i];
                [menuItem setUserData:choice];
                [menuItem setNormalImage:selectedButtonOverlay];
                CCMenu *choiceMenu = [CCMenu menuWithItems:menuItem, nil];
                [choiceMenu  setPosition:CGPointMake(choicePosition.x + 90 + (j > 0 ? 16 : 0), choicePosition.y - 8)];
                [self addChild:choiceMenu z:CHARGED_BAR_Z - 1];
                buttonSprites[i][j] = choiceMenu;
                [choiceSprite setOpacity:122];
            }
        }
    }
}

- (void)selectedChoice:(CCMenuItem*)sender{
    NSString* choice = (NSString*)[sender userData];
    NSInteger tier = [sender tag];
    [[PlayerDataManager localPlayer] selectChoice:choice forTier:tier];
    [self layoutDivinityItems];
    [self layoutTierTable];
}

- (void)testChoice:(CCMenuItem*)sender {
    if (!self.showingDivPreview) {
        NSString* choice = (NSString*)[sender userData];
        NSInteger tier = [sender tag];
        ViewTalentChoiceLayer *choiceAlert = [[[ViewTalentChoiceLayer alloc] initWithDivinityChoice:choice inTier:tier] autorelease];
        [choiceAlert setDelegate:self];
        [self addChild:choiceAlert z:TIER_TABLE_Z + 100];
        self.showingDivPreview = YES;
    }
}

- (void)dismissDivinityChoiceLayer:(CCLayer *)layer
{
    [layer removeFromParentAndCleanup:YES];
    self.showingDivPreview = NO;
}

- (void)back {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}

@end

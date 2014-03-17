//
//  ShopScene_iPhone.m
//  Healer
//
//  Created by Ryan Hart on 10/1/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "ShopScene_iPhone.h"
#import "BasicButton.h"
#import "HealerStartScene_iPhone.h"
#import "PlayerDataManager.h"
#import "CCLabelTTFShadow.h"
#import "BackgroundSprite.h"
#import "Encounter.h"
#import "GamePlayScene.h"
#import "ShopItemNode.h"
#import "GoldCounterSprite.h"

@interface ShopScene_iPhone ()
@property (nonatomic, assign) CCTableView *spellsTableView;
@property (nonatomic, assign) CCMenu *backButton;
@end

@implementation ShopScene_iPhone

- (void)dealloc
{
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets-iphone/shop-sprites.plist"];
    [super dealloc];
}

- (id)init
{
    if (self = [super init])
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets-iphone/shop-sprites.plist"];
        
        BackgroundSprite *bgSprite = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg"] autorelease];
        [self addChild:bgSprite];
        
        self.backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [self addChild:self.backButton];
        [self.backButton setPosition:CGPointMake(85, SCREEN_HEIGHT * .92)];
        
        GoldCounterSprite *goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(240, SCREEN_HEIGHT * .92)];
        [self addChild:goldCounter];
        
        self.spellsTableView = [[[CCTableView alloc] initWithViewSize:CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT - 80)] autorelease];
        self.spellsTableView.verticalFillOrder = SWTableViewFillTopDown;
        [self.spellsTableView setPosition:CGPointMake(0, 0)];
        [self addChild:self.spellsTableView];
        self.spellsTableView.contentSize = CGSizeMake(SCREEN_WIDTH, 2000);
        [self.spellsTableView setDataSource:self];
        [self.spellsTableView setDelegate:self];
        
    }
    return self;
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene_iPhone alloc] init] autorelease]]];
}

- (void)onEnter
{
    [super onEnter];
    [self.spellsTableView reloadData];
    [self.spellsTableView scrollToTopAnimated:NO];
}

- (CGSize)cellSizeForTable:(CCTableView *)table
{
    return CGSizeMake(SCREEN_WIDTH - 20, 80);
}

- (CCTableViewCell*)table:(CCTableView *)table cellAtIndex:(NSUInteger)idx
{
    CCTableViewSpriteCell *availableCell = (CCTableViewSpriteCell*)[table dequeueCell];
    
    if (!availableCell) {
        availableCell = [[[CCTableViewSpriteCell alloc] init] autorelease];
    }
    
    NSInteger spellNumber = idx;
    ShopItem *item = [[Shop allShopItems] objectAtIndex:spellNumber];
    
    ShopItemNode *node = [[[ShopItemNode alloc] initForIphoneWithShopItem:item] autorelease];
    [availableCell setSprite:node];

    //Must happen after setSprite because this tableview API is the worst
    [node setPosition:CGPointMake(30, 0)];
    return availableCell;
}

- (NSUInteger)numberOfCellsInTableView:(CCTableView *)table
{
    return [Shop allShopItems].count;
}

- (void)table:(CCTableView *)table cellTouched:(CCTableViewCell *)cell
{
    NSInteger spellNumber = cell.idx;
    ShopItem *item = [[Shop allShopItems] objectAtIndex:spellNumber];
    [table animateCellsOffscreenWithCompletion:^{
        [self showSpellDescriptionLayerForShopItem:item];
    }];
}

- (void)showSpellDescriptionLayerForShopItem:(ShopItem *)item
{
    SpellDescriptionLayer *descriptionLayer = [[[SpellDescriptionLayer alloc] initWithShopItem:item] autorelease];
    [descriptionLayer setDelegate:self];
    [self addChild:descriptionLayer];
    self.backButton.visible = NO;
}

- (void)spellDescriptionLayerDidComplete:(SpellDescriptionLayer *)layer
{
    [self.spellsTableView restoreCells];
    [layer removeFromParentAndCleanup:YES];
    self.backButton.visible = YES;
}
@end

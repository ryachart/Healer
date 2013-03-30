//
//  StoreScene.m
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "ShopScene.h"
#import "HealerStartScene.h"
#import "Shop.h"
#import "ShopItem.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"
#import "GoldCounterSprite.h"
#import "ShopItemNode.h"
#import "PlayerDataManager.h"
#import "LevelSelectMapScene.h"

#define BOOK_Z -20
#define FLAVOR_Z -19

@interface ShopScene ()
@property (nonatomic, assign) CCLayerColor *darkenLayer;
@property (nonatomic, assign) CCScrollView *itemsTable;
@property (nonatomic, assign) CCSprite *flavorSprite;

@property (nonatomic, assign) CCMenu *categoryMenu;
@property (nonatomic, assign) CCMenuItemToggle *toggleItem;

@property (nonatomic, assign) CCMenuItemSprite *essentialsButton;
@property (nonatomic, assign) CCMenuItemSprite *advancedButton;
@property (nonatomic, assign) CCMenuItemSprite *archivesButton;
@property (nonatomic, assign) CCMenuItemSprite *vaultButton;
@property (nonatomic, assign) CCMenu *backButton;
@property (nonatomic, retain) CCSprite *selectedCategorySprite;

@property (nonatomic, assign) CCSprite *ftueArrow;

- (void)back;
- (void)configureShopForCategory:(ShopCategory)category;
@end

@implementation ShopScene
@synthesize darkenLayer;

- (void)dealloc {
    [_selectedCategorySprite release];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/shop-flavor-1.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/shop-flavor-2.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/shop-sprites.plist"];
    [super dealloc];
}

-(id)init{
    if (self = [super init]){
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/shop-flavor-1.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/shop-flavor-2.plist"];

        BackgroundSprite *book = [[[BackgroundSprite alloc] initWithAssetName:@"shop_book"] autorelease];
        [book setPosition:ccp(38, 110)];
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"shop-bg"] autorelease] z:-100];
        [self addChild:book z:BOOK_Z];

        
        self.itemsTable = [[[CCScrollView alloc] initWithViewSize:CGSizeMake(500, 430)] autorelease];
        [self.itemsTable setDirection:SWScrollViewDirectionVertical];
        self.itemsTable.position = ccp(550, 200);
        self.itemsTable.contentSize = self.itemsTable.viewSize;
        [book addChild:self.itemsTable];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/shop-sprites.plist"];
        
        self.backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [self.backButton setPosition:BACK_BUTTON_POS];
        [self addChild:self.backButton];
                
        GoldCounterSprite *goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(925, 50)];
        [self addChild:goldCounter];
        
        [self configureShopForCategory:ShopCategoryEssentials];
        
        self.darkenLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0)];
        [self addChild:self.darkenLayer z:50];
        
        
        
        self.essentialsButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"shop-tab-essentials.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"shop-tab-essentials.png"] target:self selector:@selector(configureShopCategory:)];
        self.essentialsButton.tag = ShopCategoryEssentials;
        
        self.advancedButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"shop-tab-advanced.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"shop-tab-advanced.png"] target:self selector:@selector(configureShopCategory:)];
        self.advancedButton.tag = ShopCategoryAdvanced;
        
        self.archivesButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"shop-tab-archives.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"shop-tab-archives.png"] target:self selector:@selector(configureShopCategory:)];
        self.archivesButton.tag = ShopCategoryArchives;
        
        self.vaultButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"shop-tab-vault.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"shop-tab-vault.png"] target:self selector:@selector(configureShopCategory:)];
        self.vaultButton.tag = ShopCategoryVault;
        
        self.selectedCategorySprite = [CCSprite spriteWithSpriteFrameName:@"shop-tab-selected.png"];
        [self.selectedCategorySprite setAnchorPoint:CGPointZero];
        [self.essentialsButton addChild:self.selectedCategorySprite];
        
        [self configureCategoryButtons];
        
        
        self.categoryMenu = [CCMenu menuWithItems:self.essentialsButton,self.advancedButton,self.archivesButton, self.vaultButton, nil];
        [self.categoryMenu setPosition:CGPointMake(512, 90)];
        [self.categoryMenu alignItemsHorizontally];
        [self addChild:self.categoryMenu z:BOOK_Z - 1];
    }
    return self;
}

- (void)configureCategoryButtons {
    const NSInteger lockTag = 43972;
    CGPoint lockPosition = CGPointMake(69, 50);
    [self.advancedButton removeChildByTag:lockTag cleanup:YES];
    [self.archivesButton removeChildByTag:lockTag cleanup:YES];
    [self.vaultButton removeChildByTag:lockTag cleanup:YES];
    [self.advancedButton setOpacity:255];
    [self.advancedButton setIsEnabled:YES];
    [self.archivesButton setOpacity:255];
    [self.archivesButton setIsEnabled:YES];
    [self.vaultButton setOpacity:255];
    [self.vaultButton setIsEnabled:YES];
    
    CCSprite *lockSprite = nil;
    switch ([Shop highestCategoryUnlocked]) {
        case ShopCategoryEssentials:
            lockSprite = [CCSprite spriteWithSpriteFrameName:@"lock.png"];
            [lockSprite setPosition:lockPosition];
            [self.advancedButton setOpacity:125];
            [self.advancedButton setIsEnabled:NO];
            [self.advancedButton addChild:lockSprite z:500 tag:lockTag];
        case ShopCategoryAdvanced:
            lockSprite = [CCSprite spriteWithSpriteFrameName:@"lock.png"];
            [lockSprite setPosition:lockPosition];
            [self.archivesButton setOpacity:125];
            [self.archivesButton setIsEnabled:NO];
            [self.archivesButton addChild:lockSprite z:500 tag:lockTag];
        case ShopCategoryArchives:
            lockSprite = [CCSprite spriteWithSpriteFrameName:@"lock.png"];
            [lockSprite setPosition:lockPosition];
            [self.vaultButton setOpacity:125];
            [self.vaultButton setIsEnabled:NO];
            [self.vaultButton addChild:lockSprite z:500 tag:lockTag];
        default:
            break;
    }
}

- (void)configureShopCategory:(CCMenuItemSprite *)selection
{
    [self configureShopForCategory:(ShopCategory)selection.tag];
}

- (void)configureShopForCategory:(ShopCategory)category {
    NSArray *itemsToDisplay = nil;
    NSString *flavorSpriteFrameName = nil;
    [self.selectedCategorySprite removeFromParentAndCleanup:NO];
    switch (category) {
        case ShopCategoryEssentials:
            flavorSpriteFrameName = @"shop-essentials-flavor.png";
            itemsToDisplay = [Shop essentialsShopItems];
            [self.essentialsButton addChild:self.selectedCategorySprite];
            break;
        case ShopCategoryAdvanced:
            flavorSpriteFrameName = @"shop-advanced-flavor.png";
            itemsToDisplay = [Shop advancedShopItems];
            [self.advancedButton addChild:self.selectedCategorySprite];
            break;
        case ShopCategoryArchives:
            flavorSpriteFrameName = @"shop-archives-flavor.png";
            itemsToDisplay = [Shop archivesShopItems];
            [self.archivesButton addChild:self.selectedCategorySprite];
            break;
        case ShopCategoryVault:
            flavorSpriteFrameName = @"shop-vault-flavor.png";
            itemsToDisplay = [Shop vaultShopItems];
            [self.vaultButton addChild:self.selectedCategorySprite];
            break;
        default:
            break;
    }
    
    [self.itemsTable removeAllChildrenWithCleanup:YES];
    
    if (!self.flavorSprite) {
        self.flavorSprite = [CCSprite spriteWithSpriteFrameName:flavorSpriteFrameName];
        [self.flavorSprite setAnchorPoint:CGPointZero];
        [self addChild:self.flavorSprite z:FLAVOR_Z];
    } else {
        [self.flavorSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:flavorSpriteFrameName]];
    }

    CGFloat cellHeight = 160;
    int i = 0;
    for (ShopItem *item in itemsToDisplay) {
        ShopItemNode *node = [[[ShopItemNode alloc] initWithShopItem:item target:self selector:@selector(selectedItem:)] autorelease];
        [node setPosition:CGPointMake(165, (cellHeight * (itemsToDisplay.count - i - 1)) - 30)];
        [self.itemsTable addChild:node];
        i++;
    }
    
    [self.itemsTable setContentSize:CGSizeMake(self.itemsTable.viewSize.width, MAX(self.itemsTable.viewSize.height + 10, 10 + cellHeight * itemsToDisplay.count))];
    [self.itemsTable scrollToTopAnimated:NO];

}

- (void)onEnter
{
    [super onEnter];
    if (self.requiresGreaterHealFtuePurchase) {
        [self.itemsTable setIsScrollingEnabled:NO];
        [[self.backButton.children objectAtIndex:0] setIsEnabled:NO];
        
        self.ftueArrow = [CCSprite spriteWithSpriteFrameName:@"ftue_arrow.png"];
        [self.ftueArrow setPosition:CGPointMake(884, 500)];
        [self.ftueArrow runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCEaseBackOut actionWithAction:[CCMoveBy actionWithDuration:.5 position:CGPointMake(0, 40)]],[CCMoveBy actionWithDuration:.33 position:CGPointMake(0, -40)], nil]]];
        [self addChild:self.ftueArrow];
        
    }
}

-(void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    [self.itemsTable scrollToTopAnimated:NO];
}

-(void)back{
    if (self.returnsToMap) {
        LevelSelectMapScene *mapScene = [[[LevelSelectMapScene alloc] init] autorelease];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:mapScene]];
    } else {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
    }
}

-(void)selectedItem:(ShopItemNode*)selectedNode
{
    if ([[PlayerDataManager localPlayer] canAffordShopItem:selectedNode.item] && ![[PlayerDataManager localPlayer] hasShopItem:selectedNode.item]){
            [[PlayerDataManager localPlayer] purchaseItem:selectedNode.item];
            [self configureCategoryButtons];
            if (self.requiresGreaterHealFtuePurchase) {
                [self.ftueArrow setVisible:NO];
                self.requiresGreaterHealFtuePurchase = NO;
                [[self.backButton.children objectAtIndex:0] setIsEnabled:YES];
                [self.itemsTable setIsScrollingEnabled:YES];
                if ([PlayerDataManager localPlayer].ftueState == FTUEStateBattle1Finished) {
                    self.returnsToMap = YES;
                    [PlayerDataManager localPlayer].ftueState = FTUEStateGreaterHealPurchased;
                }
            }
    }
}

@end

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

- (void)back;
- (void)configureShopForCategory:(ShopCategory)category;
@end

@implementation ShopScene
@synthesize darkenLayer;

- (void)dealloc {
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
        
        CCMenu *storeBackMenu = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [storeBackMenu setPosition:CGPointMake(90, 715)];
        [self addChild:storeBackMenu];
                
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
        
        [self configureCategoryButtons];
        
        
        self.categoryMenu = [CCMenu menuWithItems:self.essentialsButton,self.advancedButton,self.archivesButton, self.vaultButton, nil];
        [self.categoryMenu setPosition:CGPointMake(512, 90)];
        [self.categoryMenu alignItemsHorizontally];
        [self addChild:self.categoryMenu z:BOOK_Z - 1];
    }
    return self;
}

- (void)configureCategoryButtons {
    [self.advancedButton setOpacity:255];
    [self.advancedButton setIsEnabled:YES];
    [self.archivesButton setOpacity:255];
    [self.archivesButton setIsEnabled:YES];
    [self.vaultButton setOpacity:255];
    [self.vaultButton setIsEnabled:YES];
    
    switch ([Shop highestCategoryUnlocked]) {
        case ShopCategoryEssentials:
            [self.advancedButton setOpacity:125];
            [self.advancedButton setIsEnabled:NO];
        case ShopCategoryAdvanced:
            [self.archivesButton setOpacity:125];
            [self.archivesButton setIsEnabled:NO];
        case ShopCategoryArchives:
            [self.vaultButton setOpacity:125];
            [self.vaultButton setIsEnabled:NO];
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
    switch (category) {
        case ShopCategoryEssentials:
            flavorSpriteFrameName = @"shop-essentials-flavor.png";
            itemsToDisplay = [Shop essentialsShopItems];
            break;
        case ShopCategoryAdvanced:
            flavorSpriteFrameName = @"shop-advanced-flavor.png";
            itemsToDisplay = [Shop advancedShopItems];
            break;
        case ShopCategoryArchives:
            flavorSpriteFrameName = @"shop-archives-flavor.png";
            itemsToDisplay = [Shop archivesShopItems];
            break;
        case ShopCategoryVault:
            flavorSpriteFrameName = @"shop-vault-flavor.png";
            itemsToDisplay = [Shop vaultShopItems];
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

-(void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    
    [self.itemsTable scrollToTopAnimated:NO];
}

-(void)back{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInL transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}

-(void)selectedItem:(ShopItemNode*)selectedNode
{
    if ([Shop playerCanAffordShopItem:selectedNode.item] && ![Shop playerHasShopItem:selectedNode.item]){
        [Shop purchaseItem:selectedNode.item];
        [self configureCategoryButtons];
    }
}

@end

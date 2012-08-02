//
//  StoreScene.m
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "StoreScene.h"
#import "HealerStartScene.h"
#import "Shop.h"
#import "ShopItemNode.h"
#import "ShopItem.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"


@interface StoreScene ()
@property (nonatomic, assign) ShopItemExtendedNode *extendedNode;
@property (nonatomic, assign) CCLayerColor *darkenLayer;
@property (nonatomic, assign) CCLabelTTF *goldLabel;
@property (nonatomic, assign) ShopItemNode *possibleChangedNode;
@property (nonatomic, retain) NSMutableArray *itemNodes;
@property (nonatomic, assign) BasicButton *essentialsButton;
@property (nonatomic, assign) BasicButton *topShelfButton;
@property (nonatomic, assign) BasicButton *archivesButton;
@property (nonatomic, assign) BasicButton *vaultButton;
- (void)itemSelected:(ShopItemNode*)item;
- (void)back;
- (void)configureShopForCategory:(ShopCategory)category;
@end

@implementation StoreScene
@synthesize goldLabel, extendedNode, darkenLayer, possibleChangedNode;
- (void)dealloc {
    [_itemNodes release];
    [super dealloc];
}

-(id)init{
    if (self = [super init]){  
        [self addChild:[[[BackgroundSprite alloc] initWithAssetName:@"wood-bg-ipad"] autorelease]];
        NSString *assetsPath = [[NSBundle mainBundle] pathForResource:@"shop-sprites-ipad" ofType:@"plist"  inDirectory:@"assets"];       
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:assetsPath];
        
        CCMenuItemLabel *back = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Back" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(back)];
        
        CCMenu *storeBackMenu = [CCMenu menuWithItems:back, nil];
        [storeBackMenu alignItemsVertically];
        [storeBackMenu setPosition:CGPointMake(50, 700)];
        [self addChild:storeBackMenu];
        
        int playerGold = [Shop localPlayerGold];
        self.goldLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold: %i", playerGold] fontName:@"Arial" fontSize:32.0];
        
        [self.goldLabel setPosition:CGPointMake(900, 50)];
        [self addChild:self.goldLabel];
        
        self.essentialsButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(configureEssentials) andTitle:@"Essentials"];
        
        self.topShelfButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(configureTopShelf) andTitle:@"Top Shelf"];
        if ([Shop highestCategoryUnlocked] < ShopCategoryTopShelf){
            [self.topShelfButton setIsEnabled:NO];
        }
        
        self.archivesButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(configureArchives) andTitle:@"Archives"];
        if ([Shop highestCategoryUnlocked] < ShopCategoryArchives){
            [self.archivesButton setIsEnabled:NO];
        }
        
        self.vaultButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(configureVault) andTitle:@"The Vault"];
        if ([Shop highestCategoryUnlocked] < ShopCategoryVault){
            [self.vaultButton setIsEnabled:NO];
        }
        
        CCMenu *pageConfigMenu = [CCMenu menuWithItems:self.essentialsButton, self.topShelfButton, self.archivesButton, self.vaultButton, nil];
        [pageConfigMenu alignItemsVertically];
        [pageConfigMenu setPosition:CGPointMake(920, 250)];
        [self addChild:pageConfigMenu];
        
        [self configureShopForCategory:ShopCategoryEssentials];
        
        self.darkenLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0)];
        [self addChild:self.darkenLayer z:50];
    }
    return self;
}

- (void)configureEssentials {
    [self configureShopForCategory:ShopCategoryEssentials];
}

- (void)configureTopShelf {
    [self configureShopForCategory:ShopCategoryTopShelf];
}

- (void)configureArchives {
    [self configureShopForCategory:ShopCategoryArchives];
}

- (void)configureVault {
    [self configureShopForCategory:ShopCategoryVault];
}

- (void)configureShopForCategory:(ShopCategory)category {
    NSArray *itemsToDisplay = nil;
    
    switch (category) {
        case ShopCategoryEssentials:
            itemsToDisplay = [Shop essentialsShopItems];
            break;
        case ShopCategoryTopShelf:
            itemsToDisplay = [Shop topShelfShopItems];
            break;
        case ShopCategoryArchives:
            itemsToDisplay = [Shop archivesShopItems];
            break;
        case ShopCategoryVault:
            itemsToDisplay = [Shop vaultShopItems];
            break;
        default:
            break;
    }
    
    for (ShopItemNode *shopItemNode in self.itemNodes) {
        [shopItemNode removeFromParentAndCleanup:YES];
    }
    self.itemNodes = [NSMutableArray arrayWithCapacity:10];
    int i = 0;
    for (ShopItem *item in itemsToDisplay){
        int xOrigin = 300;
        int yOrigin = 200;
        int width = 200;
        int height = 100;
        xOrigin += width * (i % 3);
        yOrigin += height * (3 - (i / 3));
        ShopItemNode *itemNode = [[ShopItemNode alloc] initWithShopItem:item target:self selector:@selector(itemSelected:)];
        [itemNode setPosition:CGPointMake(xOrigin, yOrigin)];
        [self addChild:itemNode];
        [itemNode release];
        [self.itemNodes addObject:itemNode];
        i++;
    };
}

-(void)itemSelected:(ShopItemNode*)item{
    if (self.extendedNode){
        [self.darkenLayer runAction:[CCFadeTo actionWithDuration:1.0 opacity:0]];
        [self.extendedNode runAction:[CCSequence actions:[CCScaleTo actionWithDuration:1.0 scale:0.0], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];
        }],nil]];
        self.extendedNode = nil;
        self.possibleChangedNode = nil;
        return;
    }
    self.possibleChangedNode = item;
    [self.darkenLayer runAction:[CCFadeTo   actionWithDuration:.33 opacity:177]];
    
    self.extendedNode = [[[ShopItemExtendedNode alloc] initWithShopItem:[item item]] autorelease];
    [extendedNode setDelegate:self];
    [extendedNode setScale:0.0];
    [extendedNode setPosition:CGPointMake(self.contentSize.width /2, self.contentSize.height /2)];
    [self addChild:extendedNode z:100];
    [extendedNode runAction:[CCScaleTo actionWithDuration:.33 scale:1.0]];
}

- (void)extendedNodeDidCompleteForShopItem:(ShopItem*)item andNode:(ShopItemExtendedNode *)node{
    [self.darkenLayer runAction:[CCFadeTo  actionWithDuration:.33 opacity:0]];
    [node runAction:[CCSequence actions:[CCScaleTo actionWithDuration:.33 scale:0.0], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node removeFromParentAndCleanup:YES];
    }],nil]];
    [self.possibleChangedNode checkPlayerHasItem];
    self.extendedNode = nil;
    self.possibleChangedNode = nil;
    self.goldLabel.string = [NSString stringWithFormat:@"Gold: %i", [Shop localPlayerGold]];
}

-(void)back{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionRadialCCW transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}

@end

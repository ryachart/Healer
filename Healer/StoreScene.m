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

@interface StoreScene ()
@property (nonatomic, assign) ShopItemExtendedNode *extendedNode;
@property (nonatomic, assign) CCLayerColor *darkenLayer;
@property (nonatomic, assign) CCLabelTTF *goldLabel;
@property (nonatomic, assign) ShopItemNode *possibleChangedNode;
-(void)itemSelected:(ShopItemNode*)item;
-(void)back;
@end

@implementation StoreScene
@synthesize goldLabel, extendedNode, darkenLayer, possibleChangedNode;
-(id)init{
    if (self = [super init]){  
        [self addChild:[[[BackgroundSprite alloc] initWithAssetName:@"wood-bg-ipad"] autorelease]];
        NSString *assetsPath = [[NSBundle mainBundle] pathForResource:@"sprites-ipad" ofType:@"plist"  inDirectory:@"assets"];       
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
        
        int i = 0;
        for (ShopItem *item in [Shop allShopItems]){
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
            i++;
        };
        
        self.darkenLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0)];
        [self addChild:self.darkenLayer z:50];
    }
    return self;
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
    [self.darkenLayer runAction:[CCFadeTo   actionWithDuration:.33 opacity:122]];
    
    self.extendedNode = [[[ShopItemExtendedNode alloc] initWithShopItem:[item item]] autorelease];
    [extendedNode setDelegate:self];
    [extendedNode setScale:0.0];
    [extendedNode setPosition:CGPointMake(self.contentSize.width /2, self.contentSize.height /2)];
    [self addChild:extendedNode z:100];
    [extendedNode runAction:[CCScaleTo actionWithDuration:.33 scale:1.0]];
    //    if ([Shop playerCanAffordShopItem:[item item]] && ![Shop playerHasShopItem:[item item]]){
    //        [Shop purchaseItem:[item item]];
    //        self.goldLabel.string = [NSString stringWithFormat:@"Gold: %i", [Shop localPlayerGold]];
    //        [item checkPlayerHasItem];
    //    }
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

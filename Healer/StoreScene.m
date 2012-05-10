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
@property (nonatomic, assign) CCLabelTTF *goldLabel;
-(void)itemSelected:(ShopItemNode*)item;
-(void)back;
@end

@implementation StoreScene
@synthesize goldLabel;
-(id)init{
    if (self = [super init]){  
        [self addChild:[[[BackgroundSprite alloc] initWithAssetName:@"stone-bg-ipad"] autorelease]];
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
            int xOrigin = 100;
            int yOrigin = 100;
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
    }
    return self;
}

-(void)itemSelected:(ShopItemNode*)item{
    if ([Shop playerCanAffordShopItem:[item item]] && ![Shop playerHasShopItem:[item item]]){
        [Shop purchaseItem:[item item]];
        self.goldLabel.string = [NSString stringWithFormat:@"Gold: %i", [Shop localPlayerGold]];
        [item checkPlayerHasItem];
    }
}

-(void)back{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionRadialCCW transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}

@end

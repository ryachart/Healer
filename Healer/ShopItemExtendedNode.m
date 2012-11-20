//
//  ShopItemExtendedNode.m
//  Healer
//
//  Created by Ryan Hart on 5/22/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ShopItemExtendedNode.h"
#import "ShopItem.h"
#import "PlayerDataManager.h"
#import "Shop.h"

@interface ShopItemExtendedNode ()
@property (nonatomic, retain) ShopItem *item;
@property (nonatomic, assign) CCLabelTTF *itemName;
@property (nonatomic, assign) CCLabelTTF *itemCost;
@property (nonatomic, assign) CCLabelTTF *itemEnergyCost;
@property (nonatomic, assign) CCLabelTTF *itemDescription;
@property (nonatomic, assign) CCLabelTTF *itemCastTime;
@property (nonatomic, assign) CCLabelTTF *itemCooldown;
@property (nonatomic, assign) CCLabelTTF *itemSpellType;

@end

@implementation ShopItemExtendedNode
@synthesize item;
@synthesize itemCastTime, itemCost, itemCooldown, itemName, itemDescription, itemEnergyCost;
@synthesize delegate;

- (void)dealloc{
    [item release];
    [super dealloc];
}

- (id)initWithShopItem:(ShopItem *)itm{
    if (self = [super init]){
        self.item = itm;
        
        CCSprite *background = [CCSprite spriteWithSpriteFrameName:@"shopitem-bg.png"];
        [self addChild:background z:0];
        [background setScale:3.0];
        
        self.itemName = [CCLabelTTF labelWithString:self.item.title dimensions:CGSizeMake(300, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:32.0];
        self.itemName.color = ccBLACK;
        
        self.itemCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold: %i",self.item.goldCost] dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentRight fontName:@"Arial" fontSize:32.0];
        self.itemCost.color = ccBLACK;
        
        self.itemCooldown = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cooldown: %1.2f",self.item.purchasedSpell.cooldown] dimensions:CGSizeMake(300, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        self.itemCooldown.color = ccBLACK;
        
        self.itemEnergyCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cost: %i Energy",self.item.purchasedSpell.energyCost] dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        self.itemEnergyCost.color = ccBLACK;
        
        self.itemCastTime = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cast Time: %1.2f",self.item.purchasedSpell.castTime] dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        self.itemCastTime.color = ccBLACK;
        self.itemDescription = [CCLabelTTF labelWithString:self.item.purchasedSpell.spellDescription dimensions:CGSizeMake(300, 300) hAlignment:UITextAlignmentCenter fontName:@"Arial" fontSize:18.0];
        self.itemDescription.color = ccBLACK;
        
        self.itemSpellType = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Type: %@", self.item.purchasedSpell.spellTypeDescription] dimensions:CGSizeMake(200, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        self.itemSpellType.color = ccBLACK;
        
        
        NSInteger halfWidth = background.contentSize.width * 3 / 2;
        NSInteger halfHeight = background.contentSize.height * 3 / 2;
        NSInteger leftEdge = -halfWidth + 130;
        NSInteger topEdge = halfHeight - 36;
        NSInteger rightEdge = halfWidth - 130;
        NSInteger bottomEdge = -halfHeight + 36;
        
        self.itemName.position = CGPointMake(leftEdge + 50, topEdge);
        self.itemCost.position = CGPointMake(rightEdge, topEdge);
        self.itemEnergyCost.position = CGPointMake(leftEdge, topEdge - 34);
        self.itemCastTime.position = CGPointMake(leftEdge, topEdge - 72);
        self.itemCooldown.position = CGPointMake(leftEdge + 50, topEdge - 112);
        self.itemDescription.position = CGPointMake(rightEdge - 80, topEdge - 210);
        self.itemSpellType.position = CGPointMake(leftEdge, topEdge - 148);
        
        [self addChild:self.itemName];
        [self addChild:self.itemCost];
        [self addChild:self.itemEnergyCost];
        [self addChild:self.itemCooldown];
        [self addChild:self.itemCastTime];
        [self addChild:self.itemDescription];
        [self addChild:self.itemSpellType];
        
        
        CCMenuItemLabel *purchaseLabel = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Buy!" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(purchase)];
        purchaseLabel.label.color = ccBLUE;
        if ([[PlayerDataManager localPlayer] hasShopItem:itm] || ![[PlayerDataManager localPlayer] canAffordShopItem:itm]){
            [purchaseLabel setIsEnabled:NO];
            purchaseLabel.label.opacity = 122;
        }
        
        CCMenuItemLabel *cancelLabel = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Cancel" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(dismiss)];
        cancelLabel.label.color = ccBLACK;
        
        CCMenu *purchaseButton = [CCMenu menuWithItems:purchaseLabel, nil];
        [purchaseButton setPosition:CGPointMake(rightEdge, bottomEdge)];
        
        CCMenu *dismissButton = [CCMenu menuWithItems:cancelLabel, nil];
        [dismissButton setPosition:CGPointMake(leftEdge, bottomEdge)];
        
        [self addChild:purchaseButton];
        [self addChild:dismissButton];
        
    }
    return self;
}

- (void)purchase{
    if ([[PlayerDataManager localPlayer] canAffordShopItem:self.item] && ![[PlayerDataManager localPlayer] hasShopItem:self.item]){
        [[PlayerDataManager localPlayer] purchaseItem:self.item];
    }
    
    [self.delegate extendedNodeDidCompleteForShopItem:self.item andNode:self];
    
}

- (void)dismiss{
    [self.delegate extendedNodeDidCompleteForShopItem:self.item andNode:self];
}
@end

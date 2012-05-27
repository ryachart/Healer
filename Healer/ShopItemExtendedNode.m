//
//  ShopItemExtendedNode.m
//  Healer
//
//  Created by Ryan Hart on 5/22/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ShopItemExtendedNode.h"
#import "ShopItem.h"
#import "Shop.h"

@interface ShopItemExtendedNode ()
@property (nonatomic, retain) ShopItem *item;
@property (nonatomic, assign) CCLabelTTF *itemName;
@property (nonatomic, assign) CCLabelTTF *itemCost;
@property (nonatomic, assign) CCLabelTTF *itemEnergyCost;
@property (nonatomic, assign) CCLabelTTF *itemDescription;
@property (nonatomic, assign) CCLabelTTF *itemCastTime;
@property (nonatomic, assign) CCLabelTTF *itemCooldown;

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
        
        self.itemName = [CCLabelTTF labelWithString:self.item.title dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:32.0];
        self.itemName.color = ccBLACK;
        
        self.itemCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold: %i",self.item.goldCost] dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentRight fontName:@"Arial" fontSize:32.0];
        self.itemCost.color = ccBLACK;
        
        self.itemCooldown = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cooldown: %1.2f",self.item.purchasedSpell.cooldown] dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        self.itemCooldown.color = ccBLACK;
        
        self.itemEnergyCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cost: %i Energy",self.item.purchasedSpell.energyCost] dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        self.itemEnergyCost.color = ccBLACK;
        
        self.itemCastTime = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cast Time: %1.2f",self.item.purchasedSpell.castTime] dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        self.itemCastTime.color = ccBLACK;
        self.itemDescription = [CCLabelTTF labelWithString:self.item.purchasedSpell.spellDescription dimensions:CGSizeMake(400, 80) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:20.0];
        self.itemDescription.color = ccBLACK;
        
        NSInteger halfWidth = background.contentSize.width * 3 / 2;
        NSInteger halfHeight = background.contentSize.height * 3 / 2;
        NSInteger leftEdge = -halfWidth + 130;
        NSInteger topEdge = halfHeight - 36;
        NSInteger rightEdge = halfWidth - 130;
        NSInteger bottomEdge = -halfHeight + 36;
        
        self.itemName.position = CGPointMake(leftEdge, topEdge);
        self.itemCost.position = CGPointMake(rightEdge, topEdge);
        self.itemEnergyCost.position = CGPointMake(leftEdge, topEdge - 34);
        self.itemCastTime.position = CGPointMake(leftEdge, topEdge - 72);
        self.itemCooldown.position = CGPointMake(leftEdge, topEdge - 112);
        self.itemDescription.position = CGPointMake(0, topEdge - 162);
        
        [self addChild:self.itemName];
        [self addChild:self.itemCost];
        [self addChild:self.itemEnergyCost];
        [self addChild:self.itemCooldown];
        [self addChild:self.itemCastTime];
        [self addChild:self.itemDescription];
        
        
        CCMenuItemLabel *purchaseLabel = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Buy!" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(purchase)];
        purchaseLabel.label.color = ccBLUE;
        if ([Shop playerHasShopItem:itm] || ![Shop playerCanAffordShopItem:itm]){
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
    if ([Shop playerCanAffordShopItem:self.item] && ![Shop playerHasShopItem:self.item]){
        [Shop purchaseItem:self.item];
    }
    
    [self.delegate extendedNodeDidCompleteForShopItem:self.item andNode:self];
    
}

- (void)dismiss{
    [self.delegate extendedNodeDidCompleteForShopItem:self.item andNode:self];
}
@end

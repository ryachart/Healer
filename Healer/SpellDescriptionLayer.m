//
//  SpellDescriptionLayer.m
//  Healer
//
//  Created by Ryan Hart on 11/7/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "SpellDescriptionLayer.h"
#import "BasicButton.h"
#import "ShopItem.h"
#import "PlayerDataManager.h"
#import "SimpleAudioEngine.h"

@interface SpellDescriptionLayer ()
@property (nonatomic, retain) ShopItem *item;
@property (nonatomic, assign) CCLabelTTF *itemCost;
@property (nonatomic, assign) CCLabelTTF *itemEnergyCost;
@property (nonatomic, assign) CCLabelTTF *itemDescription;
@property (nonatomic, assign) CCLabelTTF *itemCastTime;
@property (nonatomic, assign) CCLabelTTF *itemCooldown;
@property (nonatomic, assign) CCLabelTTF *itemSpellType;
@end

@implementation SpellDescriptionLayer

- (id)initWithShopItem:(ShopItem*)item
{
    if (self = [super init]) {
        BACK_BUTTON_IPHONE;
        self.item = item;
        
        CCLabelTTF *titleLabel = [CCLabelTTF labelWithString:item.title fontName:@"TrebuchetMS-Bold" fontSize:32.0f];
        titleLabel.position = CGPointMake(SCREEN_WIDTH / 2, SCREEN_HEIGHT * .8);
        [self addChild:titleLabel];
        
        self.itemCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold: %i",self.item.goldCost] dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentRight fontName:@"Arial" fontSize:32.0];
        self.itemCost.color = ccWHITE;
        
        self.itemCooldown = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cooldown: %1.2f",self.item.purchasedSpell.cooldown] dimensions:CGSizeMake(300, 40) hAlignment:kCCTextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        self.itemCooldown.color = ccWHITE;
        
        self.itemEnergyCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cost: %i Energy",self.item.purchasedSpell.energyCost] dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        self.itemEnergyCost.color = ccWHITE;
        
        self.itemCastTime = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cast Time: %1.2f",self.item.purchasedSpell.castTime] dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        self.itemCastTime.color = ccWHITE;
        self.itemDescription = [CCLabelTTF labelWithString:self.item.purchasedSpell.spellDescription dimensions:CGSizeMake(200, SCREEN_HEIGHT * .4) hAlignment:kCCTextAlignmentCenter fontName:@"Arial" fontSize:18.0];
        self.itemDescription.color = ccWHITE;
        
        self.itemSpellType = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Type: %@", self.item.purchasedSpell.spellTypeDescription] dimensions:CGSizeMake(200, 50) hAlignment:kCCTextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        self.itemSpellType.color = ccWHITE;
        
        self.itemCost.position = CGPointMake(50, 30);
//        self.itemEnergyCost.position = CGPointMake(leftEdge, topEdge - 34);
//        self.itemCastTime.position = CGPointMake(leftEdge, topEdge - 72);
//        self.itemCooldown.position = CGPointMake(leftEdge + 50, topEdge - 112);
        self.itemDescription.position = CGPointMake(SCREEN_WIDTH / 2, SCREEN_HEIGHT * .5);
//        self.itemSpellType.position = CGPointMake(leftEdge, topEdge - 148);
        
        [self addChild:self.itemCost];
//        [self addChild:self.itemEnergyCost];
//        [self addChild:self.itemCooldown];
//        [self addChild:self.itemCastTime];
        [self addChild:self.itemDescription];
//        [self addChild:self.itemSpellType];
        
        
        CCMenuItemLabel *purchaseLabel = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Buy!" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(purchase)];
        purchaseLabel.label.color = ccBLUE;
        if ([[PlayerDataManager localPlayer] hasShopItem:self.item] || ![[PlayerDataManager localPlayer] canAffordShopItem:self.item]){
            [purchaseLabel setIsEnabled:NO];
            purchaseLabel.label.opacity = 122;
        }
        
        CCMenu *purchaseButton = [CCMenu menuWithItems:purchaseLabel, nil];
        [purchaseButton setPosition:CGPointMake(250, 30)];
        
        [self addChild:purchaseButton];
    }
    return self;
}

- (void)purchase
{
    if ([[PlayerDataManager localPlayer] canAffordShopItem:self.item] && ![[PlayerDataManager localPlayer] hasShopItem:self.item]){
        [[PlayerDataManager localPlayer] purchaseItem:self.item];
        [[SimpleAudioEngine sharedEngine] playEffect:@"sounds/coinschest.mp3"];
        [self back];
    }
}


- (void)back
{
    [self.delegate spellDescriptionLayerDidComplete:self];
}
@end

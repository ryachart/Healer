//
//  ShopItemNode.m
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "ShopItemNode.h"
#import "ShopItem.h"
#import "Shop.h"
#import "ShopItemExtendedNode.h"
#import "GoldCounterSprite.h"
#import "BasicButton.h"
#import "PlayerDataManager.h"

@interface ShopItemNode ()
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) CCSprite *background;
@property (nonatomic, assign) CCSprite *spellIcon;
@property (nonatomic, assign) CCLabelTTF *titleLabel;
@property (nonatomic, assign) CCNode *goldCostNode;
@property (nonatomic, assign) CCMenu *buyButton;
@property (nonatomic, assign) CCLabelTTF *itemEnergyCost;
@property (nonatomic, assign) CCLabelTTF *itemDescription;
@property (nonatomic, assign) CCLabelTTF *itemCastTime;
@property (nonatomic, assign) CCLabelTTF *itemCooldown;
@property (nonatomic, assign) CCLabelTTF *itemSpellType;
-(void)nodeSelected;
@end

@implementation ShopItemNode
@synthesize item, target, selector;
@synthesize background, titleLabel;

- (void)dealloc {
    [item release];
    [super dealloc];
}

-(id)initWithShopItem:(ShopItem*)itm target:(id)tar selector:(SEL)selc{
    CCSprite *bg = [CCSprite spriteWithSpriteFrameName:@"spell-node-bg.png"];
    self = [super init];
    if (self){
        self.item = itm;
        self.target = tar;
        self.selector = selc;
        self.background = bg;
        
        
        [self addChild:background];
        
        CGFloat itemNameFontSize = 24.0;
        CGFloat titleVerticalAdjustment = 0;
        
//        if (self.item.title.length >= 12) {
//            titleVerticalAdjustment = -6;
//        }
        
        self.titleLabel = [CCLabelTTF labelWithString:itm.title dimensions:CGSizeMake(200, 50) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:itemNameFontSize];
        [self.titleLabel setColor:ccWHITE];
        [self.titleLabel setPosition:CGPointMake(184, 115 + titleVerticalAdjustment)];
        [self.titleLabel setHorizontalAlignment:UITextAlignmentLeft];
        [self.background addChild:titleLabel];
        
        self.spellIcon = [CCSprite spriteWithSpriteFrameName:@"unknown-icon.png"];
        
        CCSpriteFrame *spellSpriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[itm.purchasedSpell spriteFrameName]];
        if (spellSpriteFrame){
            [self.spellIcon setDisplayFrame:spellSpriteFrame];
        }
        [self.spellIcon setPosition:CGPointMake(45, 100)];
        [self.spellIcon setScale:.75];
        [self.background addChild:self.spellIcon];
        
        self.goldCostNode = [GoldCounterSprite goldCostNodeForCost:itm.goldCost];
        [self.goldCostNode setPosition:CGPointMake(384, 73)];
        [self.background addChild:self.goldCostNode];
        
        self.buyButton = [CCMenu menuWithItems:[BasicButton basicButtonWithTarget:self andSelector:@selector(nodeSelected) andTitle:@"Learn"], nil];
        [self.buyButton setAnchorPoint:CGPointZero];
        [self.buyButton setScale:.5];
        [self.buyButton setPosition:CGPointMake(332, 123)];
        [self.background addChild:self.buyButton];
        
        
        self.itemCooldown = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cooldown: %1.2f%@",self.item.purchasedSpell.cooldown, @"s"] dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        
        self.itemEnergyCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i Mana",self.item.purchasedSpell.energyCost] dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        
        NSString *castTimeString = self.item.purchasedSpell.castTime == 0.0 ? @"Instant Cast" : [NSString stringWithFormat:@"Cast: %1.2f%@", self.item.purchasedSpell.castTime, @"s"];
        
        self.itemCastTime = [CCLabelTTF labelWithString:castTimeString dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        self.itemDescription = [CCLabelTTF labelWithString:self.item.purchasedSpell.spellDescription dimensions:CGSizeMake(380, 80) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:15.0];
        
        self.itemSpellType = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@", self.item.purchasedSpell.spellTypeDescription] dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        
//        CCLayerColor *dividerLine = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 225)];
//        [dividerLine setContentSize:CGSizeMake(1, 30)];
//        [dividerLine setPosition:CGPointMake(174, 58)];
//        [self.background addChild:dividerLine];
        
        self.itemEnergyCost.position = CGPointMake(185, 70);
        self.itemCastTime.position = CGPointMake(185, 85);
        self.itemCooldown.position = CGPointMake(270, 70);
        self.itemDescription.position = CGPointMake(200, 23);
        self.itemSpellType.position = CGPointMake(270, 85);
        
        if (self.item.purchasedSpell.cooldown == 0.0) {
            [self.itemCooldown setVisible:NO];
        }
        
        [self.background addChild:self.itemEnergyCost];
        [self.background addChild:self.itemCooldown];
        [self.background addChild:self.itemCastTime];
        [self.background addChild:self.itemDescription];
        [self.background addChild:self.itemSpellType];
        
        
        [self checkPlayerHasItem];
    }
    return self;
}

-(void)checkPlayerHasItem{
    if ([[PlayerDataManager localPlayer] hasShopItem:self.item]){
        [self.goldCostNode setVisible:NO];
        [self.buyButton setVisible:NO];
    }
}

-(void)nodeSelected{
    [self.target performSelector:self.selector withObject:self];
    [self checkPlayerHasItem];
}
@end

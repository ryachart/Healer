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

@interface ShopItemNode ()
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) CCSprite *background;
@property (nonatomic, assign) CCLabelTTF *costLabel;
@property (nonatomic, assign) CCLabelTTF *titleLabel;
-(void)nodeSelected;
@end

@implementation ShopItemNode
@synthesize item, target, selector;
@synthesize background, costLabel, titleLabel;
- (void)dealloc {
    [item release];
    [super dealloc];
}

-(id)initWithShopItem:(ShopItem*)itm target:(id)tar selector:(SEL)selc{
    CCSprite *bg = [CCSprite spriteWithSpriteFrameName:@"shopitem-bg.png"];
    CCSprite *selectedBackground = [CCSprite spriteWithSpriteFrameName:@"shopitem-bg.png"];
    [selectedBackground setOpacity:122];
    CCMenuItem *menuItem = [CCMenuItemSprite itemFromNormalSprite:bg selectedSprite:selectedBackground target:self selector:@selector(nodeSelected)];
    self = [super initWithItem:menuItem];
    if (self){
        self.item = itm;
        self.target = tar;
        self.selector = selc;
        self.background = bg;
        
        self.titleLabel = [CCLabelTTF labelWithString:itm.title fontName:@"Arial" fontSize:20.0];
        [self.titleLabel setColor:ccBLACK];
        [self.titleLabel setPosition:CGPointMake(125, 75)];
        [menuItem addChild:titleLabel];
        
        self.costLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cost %i", itm.goldCost] dimensions:CGSizeMake(140, 20) alignment:UITextAlignmentRight fontName:@"Arial" fontSize:20.0];
        [self.costLabel setPosition:ccp(50, 25)];
        [self.costLabel setColor:ccGREEN];
        
        [menuItem addChild:costLabel];
        
        [self checkPlayerHasItem];
    }
    return self;
}

-(void)checkPlayerHasItem{
    if ([Shop playerHasShopItem:self.item]){
        [costLabel setString:@"Known"];
    }
}

-(void)nodeSelected{
    [self.target performSelector:self.selector withObject:self];
}
@end

//
//  PlayerSprite.m
//  Healer
//
//  Created by Ryan Hart on 6/17/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "PlayerSprite.h"
#import "EquipmentItem.h"

@interface PlayerSprite ()
@property (nonatomic, assign) CCSprite *baseSprite;
@property (nonatomic, assign) CCSprite *pantsSprite;
@property (nonatomic, assign) CCSprite *bootsSprite;
@property (nonatomic, assign) CCSprite *chestSprite;
@property (nonatomic, assign) CCSprite *helmSprite;
@property (nonatomic, assign) CCSprite *neckSprite;
@property (nonatomic, assign) CCSprite *tomeSprite;

@end

@implementation PlayerSprite

- (void)dealloc
{
    [_equippedItems release];
    [super dealloc];
}

- (id)initWithEquippedItems:(NSArray *)items
{
    if (self = [self init]) {
        [self setEquippedItems:items];
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        self.baseSprite = [CCSprite spriteWithSpriteFrameName:@"avatar_base1.png"];
        [self addChild:self.baseSprite z:0];
        
        self.pantsSprite = [CCSprite node];
        [self addChild:self.pantsSprite z:1];
        
        self.bootsSprite = [CCSprite node];
        [self addChild:self.bootsSprite z:2];
        
        self.chestSprite = [CCSprite node];
        [self addChild:self.chestSprite z:3];
        
        self.helmSprite = [CCSprite node];
        [self addChild:self.helmSprite z:4];
        
        self.neckSprite = [CCSprite node];
        [self addChild:self.neckSprite z:5];
        
        self.tomeSprite = [CCSprite node];
        [self addChild:self.tomeSprite z:6];
        
        [self setAllItemSpritesInvisible];
    }
    return self;
}

- (void)setFlipX:(BOOL)flipX
{
    [super setFlipX:flipX];
    for (CCSprite *child in self.children) {
        [child setFlipX:flipX];
    }
}

- (void)configureForItem:(EquipmentItem*)item
{
    CCSpriteFrame *spriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:item.avatarItemName];
    if (spriteFrame) {
        switch (item.slot) {
            case SlotTypeBoots:
                [self.bootsSprite setDisplayFrame:spriteFrame];
                self.bootsSprite.visible = YES;
                break;
            case SlotTypeChest:
                [self.chestSprite setDisplayFrame:spriteFrame];
                self.chestSprite.visible = YES;
                break;
            case SlotTypeHead:
                [self.helmSprite setDisplayFrame:spriteFrame];
                self.helmSprite.visible = YES;
                break;
            case SlotTypeLegs:
                [self.pantsSprite setDisplayFrame:spriteFrame];
                self.pantsSprite.visible = YES;
                break;
            case SlotTypeNeck:
                [self.neckSprite setDisplayFrame:spriteFrame];
                self.neckSprite.visible = YES;
                break;
            case SlotTypeWeapon:
                [self.tomeSprite setDisplayFrame:spriteFrame];
                self.tomeSprite.visible = YES;
                break;
            case SlotTypeMaximum:
            default:
                break;
        }
    }
}

- (void)setAllItemSpritesInvisible
{
    for (CCNode *child in self.children) {
        if (child != self.baseSprite) {
            [child setVisible:NO];
        }
    }
}

- (void)clearEquippedItems
{
    [self.pantsSprite setDisplayFrame:nil];
    [self.bootsSprite setDisplayFrame:nil];
    [self.neckSprite setDisplayFrame:nil];
    [self.tomeSprite setDisplayFrame:nil];
    [self.chestSprite setDisplayFrame:nil];
    [self.helmSprite setDisplayFrame:nil];
    [self setAllItemSpritesInvisible];
}

- (void)configureForEquippedItems
{
    [self clearEquippedItems];
    for (EquipmentItem *item in self.equippedItems) {
        [self configureForItem:item];
    }
    
    if ([self requiresBaseHead]) {
        self.helmSprite.displayFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"avatar_helm1_none.png"];
        self.helmSprite.visible = YES;
    }
    
    if ([self requiresBaseChest]) {
        self.chestSprite.displayFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"avatar_chest1_none.png"];
        self.chestSprite.visible = YES;
    }
    
    if ([self requiresBaseTome]) {
        self.tomeSprite.displayFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"avatar_tome1_none.png"];
        self.tomeSprite.visible = YES;
    }
    
    if ([self requiresBaseBoots]) {
        self.bootsSprite.displayFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"avatar_boots1_none.png"];
        self.bootsSprite.visible = YES;
    }
}

- (void)setEquippedItems:(NSArray *)equippedItems
{
    [_equippedItems release];
    _equippedItems = [equippedItems retain];
    [self configureForEquippedItems];
}

- (BOOL)requiresBaseHead
{
    return !self.helmSprite.visible;
}

- (BOOL)requiresBaseChest
{
    return !self.chestSprite.visible;
}

- (BOOL)requiresBaseTome
{
    return !self.tomeSprite.visible;
}

- (BOOL)requiresBaseBoots
{
    return !self.bootsSprite.visible;
}

- (void)setOpacity:(GLubyte)opacity
{
    [super setOpacity:opacity];
    [self.baseSprite setOpacity:opacity];
    [self.tomeSprite setOpacity:opacity];
    [self.pantsSprite setOpacity:opacity];
    [self.bootsSprite setOpacity:opacity];
    [self.chestSprite setOpacity:opacity];
    [self.helmSprite setOpacity:opacity];
    [self.neckSprite setOpacity:opacity];
}

@end

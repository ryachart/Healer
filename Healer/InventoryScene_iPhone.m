//
//  InventoryScene_iPhone.m
//  Healer
//
//  Created by Ryan Hart on 3/16/14.
//  Copyright (c) 2014 Ryan Hart Games. All rights reserved.
//

#import "InventoryScene_iPhone.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"
#import "HealerStartScene_iPhone.h"
#import "PlayerDataManager.h"
#import "PlayerSprite.h"
#import "Slot.h"
#import "ItemDescriptionNode.h"
#import "DraggableItemIcon.h"

@interface InventoryScene_iPhone ()
@property (nonatomic, assign) PlayerSprite *playerSprite;
@property (nonatomic, assign) Slot *headSlot;
@property (nonatomic, assign) Slot *weaponSlot;
@property (nonatomic, assign) Slot *neckSlot;
@property (nonatomic, assign) Slot *chestSlot;
@property (nonatomic, assign) Slot *legsSlot;
@property (nonatomic, assign) Slot *bootsSlot;
@end

@implementation InventoryScene_iPhone

- (void)dealloc
{
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets-iphone/avatar.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets-iphone/inventory.plist"];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets-iphone/avatar.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets-iphone/inventory.plist"];
        BackgroundSprite *bgSprite = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg"] autorelease];
        [self addChild:bgSprite];
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [self addChild:backButton];
        [backButton setPosition:CGPointMake(85, SCREEN_HEIGHT * .92)];
        
        self.playerSprite = [[[PlayerSprite alloc] initWithEquippedItems:[PlayerDataManager localPlayer].equippedItems] autorelease];
        [self.playerSprite setScale:.5];
        [self.playerSprite setFlipX:YES];
        [self.playerSprite setPosition:CGPointMake(150, 220)];
        [self addChild:self.playerSprite];
        
        CGPoint slotOffsets = CGPointMake(0 * .5, 0 * .5);
        
        self.headSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_head.png" andInhabitantOrNil:nil] autorelease];
        self.headSlot.slotType = SlotTypeHead;
        self.headSlot.scale = .6;
        [self.headSlot setPosition:CGPointMake(50 + slotOffsets.x, 290+slotOffsets.y)];
        [self addChild:self.headSlot];
        
        self.neckSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_neck.png" andInhabitantOrNil:nil] autorelease];
        self.neckSlot.slotType = SlotTypeNeck;
        self.neckSlot.scale = .6;
        [self.neckSlot setPosition:CGPointMake(264+slotOffsets.x, 290+slotOffsets.y)];
        [self addChild:self.neckSlot];
        
        self.chestSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_chest.png" andInhabitantOrNil:nil] autorelease];
        self.chestSlot.slotType = SlotTypeChest;
        self.chestSlot.scale = .6;
        [self.chestSlot setPosition:CGPointMake(50 + slotOffsets.x, 160+slotOffsets.y)];
        [self addChild:self.chestSlot];
        
        self.legsSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_legs.png" andInhabitantOrNil:nil] autorelease];
        self.legsSlot.slotType = SlotTypeLegs;
        self.legsSlot.scale = .6;
        [self.legsSlot setPosition:CGPointMake(50 + slotOffsets.x, 54+slotOffsets.y)];
        [self addChild:self.legsSlot];
        
        self.bootsSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_boots.png" andInhabitantOrNil:nil] autorelease];
        self.bootsSlot.scale = .6;
        self.bootsSlot.slotType = SlotTypeBoots;
        [self.bootsSlot setPosition:CGPointMake(264 + slotOffsets.x, 54+slotOffsets.y)];
        [self addChild:self.bootsSlot];
        
        self.weaponSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_weapon.png" andInhabitantOrNil:nil] autorelease];
        self.weaponSlot.scale = .6;
        self.weaponSlot.slotType = SlotTypeWeapon;
        [self.weaponSlot setPosition:CGPointMake(264 +slotOffsets.x, 160+slotOffsets.y)];
        [self addChild:self.weaponSlot];
        
        [self configureEquippedSlots];
    }
    return self;
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene_iPhone alloc] init] autorelease]]];
}

- (void)configureEquippedSlots
{
    NSMutableArray *specificSlots = [NSMutableArray arrayWithObjects:self.headSlot, self.neckSlot, self.legsSlot, self.chestSlot, self.weaponSlot, self.bootsSlot, nil];
    
    for (Slot *slot in specificSlots) {
        [slot inhabitantRemovedForDragging];
        EquipmentItem *item = [[PlayerDataManager localPlayer] itemForSlot:slot.slotType];
        if (item) {
            DraggableItemIcon *itemSprite = [[[DraggableItemIcon alloc] initWithEquipmentItem:item] autorelease];
            [slot dropInhabitant:itemSprite];
            slot.title = item.name;
            slot.titleColor = [ItemDescriptionNode colorForRarity:item.rarity];
        }
    }
}

@end

//
//  InventoryScene.m
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "InventoryScene.h"
#import "HealerStartScene.h"
#import "LevelSelectMapScene.h"
#import "BasicButton.h"
#import "Slot.h"
#import "BackgroundSprite.h"
#import "PlayerDataManager.h"
#import "EquipmentItem.h"
#import "DraggableItemIcon.h"
#import "ItemDescriptionNode.h"
#import "SellDropSprite.h"
#import "GoldCounterSprite.h"
#import "CCLabelTTFShadow.h"
#import "Encounter.h"
#import "PlayerSprite.h"

@interface InventoryScene ()
@property (nonatomic, assign) PlayerSprite *playerSprite;
@property (nonatomic, assign) Slot *headSlot;
@property (nonatomic, assign) Slot *weaponSlot;
@property (nonatomic, assign) Slot *neckSlot;
@property (nonatomic, assign) Slot *chestSlot;
@property (nonatomic, assign) Slot *legsSlot;
@property (nonatomic, assign) Slot *bootsSlot;
@property (nonatomic, retain) DraggableItemIcon *draggingSprite;
@property (nonatomic, retain) NSMutableArray *inventorySlots;
@property (nonatomic, assign) Slot *lastSelectedSlot;
@property (nonatomic, assign) ItemDescriptionNode *itemDescriptionNode;
@property (nonatomic, assign) SellDropSprite *sellDrop;
@property (nonatomic, assign) CCLabelTTFShadow *statsLabel;
@property (nonatomic, assign) CCLabelTTFShadow *overflowLabel;

@property (nonatomic, assign) CCLabelTTFShadow *allyDamage;
@property (nonatomic, assign) CCLabelTTFShadow *allyHealth;
@property (nonatomic, assign) CCNode *allyDamageCostNode;
@property (nonatomic, assign) CCNode *allyHealthCostNode;
@property (nonatomic, assign) BasicButton *allyHealthUpgradeButton;
@property (nonatomic, assign) BasicButton *allyDamageUpgradeButton;
@property (nonatomic, readwrite) BOOL isTouching;
@end

#define INVENTORY_ROW_SIZE 5
#define INVENTORY_SLOT_TYPE -9999

#define FREE_ITEM 0

@implementation InventoryScene

- (void)dealloc
{
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/battle-sprites.plist"];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"curtain-bg"] autorelease]];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/inventory.plist"];
        
        CCLabelTTF *titleLabel = [CCLabelTTF labelWithString:@"ARMORY" fontName:@"TeluguSangamMN-Bold" fontSize:64.0];
        [titleLabel setPosition:CGPointMake(512, 700)];
        [self addChild:titleLabel];
        
        CCSprite *equipmentBack = [CCSprite spriteWithSpriteFrameName:@"equip_back.png"];
        [equipmentBack setPosition:CGPointMake(260, 400)];
        [self addChild:equipmentBack];
        
        self.playerSprite = [[[PlayerSprite alloc] initWithEquippedItems:[PlayerDataManager localPlayer].equippedItems] autorelease];
        [self.playerSprite setFlipX:YES];
        [self.playerSprite setPosition:CGPointMake(190, 260)];
        [equipmentBack addChild:self.playerSprite];
        
        CGPoint slotOffsets = CGPointMake(equipmentBack.position.x * equipmentBack.anchorPoint.x, equipmentBack.position.y * equipmentBack.anchorPoint.y);
        
        self.headSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_head.png" andInhabitantOrNil:nil] autorelease];
        self.headSlot.slotType = SlotTypeHead;
        self.headSlot.scale = .75;
        [self.headSlot setPosition:CGPointMake(slotOffsets.x, 390+slotOffsets.y)];
        [self addChild:self.headSlot];
        
        self.neckSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_neck.png" andInhabitantOrNil:nil] autorelease];
        self.neckSlot.slotType = SlotTypeNeck;
        self.neckSlot.scale = .75;
        [self.neckSlot setPosition:CGPointMake(256+slotOffsets.x, 390+slotOffsets.y)];
        [self addChild:self.neckSlot];
        
        self.chestSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_chest.png" andInhabitantOrNil:nil] autorelease];
        self.chestSlot.slotType = SlotTypeChest;
        self.chestSlot.scale = .75;
        [self.chestSlot setPosition:CGPointMake(slotOffsets.x, 160+slotOffsets.y)];
        [self addChild:self.chestSlot];
        
        self.legsSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_legs.png" andInhabitantOrNil:nil] autorelease];
        self.legsSlot.slotType = SlotTypeLegs;
        self.legsSlot.scale = .75;
        [self.legsSlot setPosition:CGPointMake(slotOffsets.x, 54+slotOffsets.y)];
        [self addChild:self.legsSlot];
        
        self.bootsSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_boots.png" andInhabitantOrNil:nil] autorelease];
        self.bootsSlot.scale = .75;
        self.bootsSlot.slotType = SlotTypeBoots;
        [self.bootsSlot setPosition:CGPointMake(256 + slotOffsets.x, 54+slotOffsets.y)];
        [self addChild:self.bootsSlot];
        
        self.weaponSlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_weapon.png" andInhabitantOrNil:nil] autorelease];
        self.weaponSlot.scale = .75;
        self.weaponSlot.slotType = SlotTypeWeapon;
        [self.weaponSlot setPosition:CGPointMake(256+slotOffsets.x, 160+slotOffsets.y)];
        [self addChild:self.weaponSlot];
        
        [self configureEquippedSlots];
    
        CGPoint inventoryPosition = CGPointMake(700, 400);
        CGPoint slotsPosition = CGPointMake(526, 490);
        
        CCSprite *inventoryBack = [CCSprite spriteWithSpriteFrameName:@"inventory_back.png"];
        [inventoryBack setPosition:inventoryPosition];
        [self addChild:inventoryBack];
        
        self.inventorySlots = [NSMutableArray arrayWithCapacity:[[PlayerDataManager localPlayer] maximumInventorySize]];
        
        for (int i = 0; i < [[PlayerDataManager localPlayer] maximumInventorySize] / INVENTORY_ROW_SIZE;i++) {
            for (int j = 0; j < INVENTORY_ROW_SIZE; j++) {
                Slot *inventorySlot = [[[Slot alloc] initWithSpriteFrameName:@"slot_empty.png" andInhabitantOrNil:nil] autorelease];
                inventorySlot.scale = .75;
                inventorySlot.slotType = INVENTORY_SLOT_TYPE;
                [inventorySlot setPosition:CGPointMake(slotsPosition.x + 85 * j, slotsPosition.y + (-85 * i))];
                [self.inventorySlots addObject:inventorySlot];
                [self addChild:inventorySlot];
            }
        }
        
//        self.overflowLabel = [CCLabelTTFShadow labelWithString:@"You have items in overflow that will be made available once you can hold them." dimensions:CGSizeMake(400, 50) hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:18.0];
//        self.overflowLabel.position = ccpSub(inventoryPosition, CGPointMake(-180, 180));
//        [self addChild:self.overflowLabel];
        
        [self configureInventory];
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:BACK_BUTTON_POS];
        [self addChild:backButton z:100];
        
#if FREE_ITEM
        CCMenu *freeItem = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(freeItem)];
        [freeItem setPosition:CGPointMake(512, 725)];
        [self addChild:freeItem z:100];
#endif
        
        self.itemDescriptionNode = [[[ItemDescriptionNode alloc] init] autorelease];
        self.itemDescriptionNode.position = CGPointMake(696, 590);
        self.itemDescriptionNode.visible = NO;
        [self addChild:self.itemDescriptionNode];
        
        self.sellDrop = [[[SellDropSprite alloc] init] autorelease];
        [self.sellDrop setPosition:CGPointMake(696, 210)];
        [self addChild:self.sellDrop];
        
        CCSprite *statsBack = [CCSprite spriteWithSpriteFrameName:@"stats_back.png"];
        [statsBack setPosition:CGPointMake(260, 80)];
        [self addChild:statsBack];
        
        CCLabelTTFShadow *statsTitleLabel = [CCLabelTTFShadow labelWithString:@"Stats:" fontName:@"TrebuchetMS-Bold" fontSize:28.0];
        [statsTitleLabel setPosition:CGPointMake(50, 120)];
        [statsBack addChild:statsTitleLabel];
        
        self.statsLabel = [CCLabelTTFShadow labelWithString:[self statsString] dimensions:CGSizeMake(200, 200) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS" fontSize:14.0];
        [self.statsLabel setPosition:CGPointMake(240, 25)];
        [statsBack addChild:self.statsLabel];
        
//        self.allyDamage = [CCLabelTTFShadow labelWithString:@"Ally Damage:\n+0%" fontName:@"TrebuchetMS-Bold" fontSize:28.0];
//        [self.allyDamage setPosition:CGPointMake(300, 120)];
//        [self addChild:self.allyDamage];
        
        GoldCounterSprite *goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(900, 45)];
        [self addChild:goldCounter];
        
        CCSprite *upgradeAllyHealthBack = [CCSprite spriteWithSpriteFrameName:@"allies_back.png"];
        [upgradeAllyHealthBack setPosition:CGPointMake(640, 60)];
        [self addChild:upgradeAllyHealthBack];
        
        self.allyHealth = [CCLabelTTFShadow labelWithString:@"" fontName:@"TrebuchetMS-Bold" fontSize:28.0];
        [self.allyHealth setPosition:CGPointMake(upgradeAllyHealthBack.contentSize.width/2, 100)];
        [upgradeAllyHealthBack addChild:self.allyHealth];
        
        self.allyHealthUpgradeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(upgradeAllyHealth) andTitle:@"Upgrade"];
        [self.allyHealthUpgradeButton setScale:.75];
        
        self.allyHealthCostNode = [GoldCounterSprite goldCostNodeForCost:[PlayerDataManager localPlayer].nextAllyHealthUpgradeCost];
        [self.allyHealthCostNode setPosition:CGPointMake(120, 40)];
        [upgradeAllyHealthBack addChild:self.allyHealthCostNode];
        [self configureAllyUpgrades];
        
        CCMenu *upgradeMenu = [CCMenu menuWithItems:/*self.allyDamageUpgradeButton,*/self.allyHealthUpgradeButton, nil];
        [upgradeMenu setPosition:CGPointMake(upgradeAllyHealthBack.contentSize.width - 116, 54)];
        [upgradeAllyHealthBack addChild:upgradeMenu];
        
    }
    return self;
}

- (NSString *)statsString
{
    NSArray *equippedItems = [[PlayerDataManager localPlayer] equippedItems];
    NSInteger health = 0;
    float regen = 0;
    float crit = 0;
    float healing = 0;
    float speed = 0;
    
    for (EquipmentItem *itm in equippedItems) {
        health += itm.health;
        regen += itm.regen;
        crit += itm.crit;
        healing += itm.healing;
        speed += itm.speed;
    }
    
    return [NSString stringWithFormat:@"Health: +%i\nHealing: +%1.2f%%\nCrit: +%1.2f%%\nSpeed: +%1.2f%%\nMana Regen: +%1.2f%%", health, healing, crit, speed, regen];
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

- (void)configureInventory
{
    NSArray *inventory = [[PlayerDataManager localPlayer] inventory];
    
    for (Slot *slot in self.inventorySlots) {
        [slot inhabitantRemovedForDragging]; //Clear all the inhabitants
    }
    
    for (int i = 0; i < MIN(10,inventory.count); i++) {
        EquipmentItem *currentItem = [inventory objectAtIndex:i];
        DraggableItemIcon *itemSprite = [[[DraggableItemIcon alloc] initWithEquipmentItem:currentItem] autorelease];
        [[self.inventorySlots objectAtIndex:i] dropInhabitant:itemSprite];
    }
    
    if (inventory.count > 10) {
        self.overflowLabel.visible = YES;
    } else {
        self.overflowLabel.visible = NO;
    }
}

- (void)configureAllyUpgrades
{
    CCNode *parent = self.allyHealthCostNode.parent;
    CGPoint position = self.allyHealthCostNode.position;
    
    if (self.allyHealthCostNode) {
        [self.allyHealthCostNode removeFromParentAndCleanup:YES];
    }
    
    self.allyHealth.string = [NSString stringWithFormat:@"Ally Health: +%i%%", [PlayerDataManager localPlayer].allyHealthUpgrades];
    
    self.allyHealthCostNode = [GoldCounterSprite goldCostNodeForCost:[PlayerDataManager localPlayer].nextAllyHealthUpgradeCost];
    [self.allyHealthCostNode setPosition:position];
    [parent addChild:self.allyHealthCostNode];
}

-(void)back
{
    if (self.returnsToMap) {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[LevelSelectMapScene alloc] init] autorelease]]];
    } else {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
    }
}

- (void)freeItem
{
    
//    [[PlayerDataManager localPlayer] staminaUsedWithCompletion:^(BOOL success) {
//        if (success) {
            Encounter *encounter = [Encounter encounterForLevel:arc4random() % 21 + 1 isMultiplayer:NO];
            encounter.difficulty = 5;
            EquipmentItem *randomItem = encounter.randomLootReward;
            [[PlayerDataManager localPlayer] playerEarnsItem:randomItem];
            [self configureInventory];
//        }
//    }];
}

- (NSArray *)allSlots
{
    NSMutableArray *allSlots = [NSMutableArray arrayWithArray:self.inventorySlots];
    [allSlots addObject:self.headSlot];
    [allSlots addObject:self.chestSlot];
    [allSlots addObject:self.weaponSlot];
    [allSlots addObject:self.neckSlot];
    [allSlots addObject:self.bootsSlot];
    [allSlots addObject:self.legsSlot];
    
    return allSlots;
}

- (void)onEnter {
    [super onEnter];
    [[CCDirector sharedDirector].touchDispatcher addTargetedDelegate:self priority:kCCMenuHandlerPriority + 1 swallowsTouches:YES];
}

- (void)onExit {
    [super onExit];
    [[CCDirector sharedDirector].touchDispatcher removeDelegate:self];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    if (self.isTouching ) return NO;
    self.isTouching = YES;
    
    NSArray *allSlots = [self allSlots];
    for (CCNode *child in allSlots){
        if ([child isKindOfClass:[Slot class]]){
            Slot *slotChild = (Slot*)child;
            CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
            CGRect layerRect = [slotChild boundingBox];
            CGPoint convertedToNodeSpacePoint = [child.parent convertToNodeSpace:touchLocation];
            if (CGRectContainsPoint(layerRect, convertedToNodeSpacePoint)){
                if (slotChild.inhabitant){
                    self.draggingSprite = (DraggableItemIcon*)[slotChild inhabitantRemovedForDragging];
                    if (slotChild.slotType != INVENTORY_SLOT_TYPE) {
                        [[PlayerDataManager localPlayer] playerUnequipsItemInSlot:self.draggingSprite.item.slot];
                        [slotChild setTitle:nil];
                    }
                    [self.draggingSprite setAnchorPoint:CGPointMake(.5, .5)];
                    [self addChild:self.draggingSprite];
                    [self.draggingSprite setPosition:slotChild.position];
                    self.draggingSprite.scale = .75;
                    self.itemDescriptionNode.item = self.draggingSprite.item;
                    self.itemDescriptionNode.visible = YES;
                    self.lastSelectedSlot = slotChild;
                }
            }
        }
    }
    [self.playerSprite setEquippedItems:[PlayerDataManager localPlayer].equippedItems];
    return YES;
}

- (void)setLastSelectedSlot:(Slot *)lastSelectedSlot
{
    [_lastSelectedSlot setIsSelected:NO];
    _lastSelectedSlot = lastSelectedSlot;
    [_lastSelectedSlot setIsSelected:YES];
    if (self.draggingSprite.item) {
        [_lastSelectedSlot setSelectionColor:[ItemDescriptionNode colorForRarity:self.draggingSprite.item.rarity]];
    }
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.draggingSprite){
        CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
        [self.draggingSprite setPosition:touchLocation];
    }
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    //Cancelled is the same as ended for us...
    [self ccTouchEnded:touch withEvent:event];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    self.isTouching = NO;
    BOOL droppedIntoSlot = NO;
    NSArray *allSlots = [self allSlots];
    EquipmentItem *droppedItem = self.draggingSprite.item;
    
    if (!self.draggingSprite) return;
    
    self.draggingSprite.scale = 1.0;
    
    for (Slot *slotChild in allSlots){
        if ([slotChild canDropIntoSlotFromRect:self.draggingSprite.boundingBox]){
            
            if (slotChild.slotType == self.draggingSprite.item.slot) {
                [[PlayerDataManager localPlayer] playerEquipsItem:self.draggingSprite.item];
                slotChild.title = self.draggingSprite.item.name;
                slotChild.titleColor = [ItemDescriptionNode colorForRarity:self.draggingSprite.item.rarity];
            }
            if (slotChild.slotType == self.draggingSprite.item.slot || slotChild.slotType == INVENTORY_SLOT_TYPE) {
                [self.draggingSprite removeFromParentAndCleanup:YES];
                [slotChild dropInhabitant:self.draggingSprite];
                self.draggingSprite = nil;
                droppedIntoSlot = YES;
                self.lastSelectedSlot = slotChild;
            }
            break;
        }
    }
    
    if (!droppedIntoSlot) {
        if (CGRectIntersectsRect(self.sellDrop.boundingBox, self.draggingSprite.boundingBox)) {
            IconDescriptionModalLayer *sellConfirm = [[[IconDescriptionModalLayer alloc] initAsItemSellConfirmModalWithItem:self.draggingSprite.item] autorelease];
            [sellConfirm setDelegate:self];
            [self addChild:sellConfirm];
            [self.draggingSprite removeFromParentAndCleanup:YES];
            [self.lastSelectedSlot dropInhabitant:self.draggingSprite];
            self.draggingSprite = nil;
            droppedIntoSlot = YES;
        }
    }
    
    if (!droppedIntoSlot){
        if (self.lastSelectedSlot) {
            if (self.lastSelectedSlot.slotType == self.draggingSprite.item.slot) {
                [[PlayerDataManager localPlayer] playerEquipsItem:self.draggingSprite.item];
            }
            [self.draggingSprite removeFromParentAndCleanup:YES];
            [self.lastSelectedSlot dropInhabitant:self.draggingSprite];
            self.draggingSprite = nil;
            droppedIntoSlot = YES;
        }
    }
    
    if (!droppedIntoSlot) {
        for (Slot *slot in self.inventorySlots) {
            if (!slot.inhabitant) {
                [self.draggingSprite removeFromParentAndCleanup:YES];
                [slot dropInhabitant:self.draggingSprite];
                self.draggingSprite = nil;
                //droppedIntoSlot = YES; //Not required here, but it seems right
            }
        }
    }
    
    if (self.draggingSprite){
        [self.draggingSprite removeFromParentAndCleanup:YES];
        self.draggingSprite = nil;
    }
    
    if (droppedItem) {
        self.lastSelectedSlot.selectionColor = [ItemDescriptionNode colorForRarity:droppedItem.rarity];
    }
    
    self.statsLabel.string = [self statsString];
    [self.playerSprite setEquippedItems:[PlayerDataManager localPlayer].equippedItems];
}

- (NSString *)titleForSlotType:(SlotType)type
{
    switch (type) {
        case SlotTypeBoots:
            return @"Boots";
        case SlotTypeChest:
            return @"Chest";
        case SlotTypeHead:
            return @"Head";
        case SlotTypeLegs:
            return @"Legs";
        case SlotTypeNeck:
            return @"Neck";
        case SlotTypeWeapon:
            return @"Weapon";
        case SlotTypeMaximum:
        default:
            break;
    }
    return nil;
}

- (void)upgradeAllyHealth
{
    [[PlayerDataManager localPlayer] purchaseAllyHealthUpgrade];
    [self configureAllyUpgrades];
}

- (void)upgradeAllyDamage
{
    [[PlayerDataManager localPlayer] purchaseAllyDamageUpgrade];
    [self configureAllyUpgrades];
}

#pragma mark - IconDescriptorModalDelegate

- (void)iconDescriptionModalDidComplete:(id)modal
{
    IconDescriptionModalLayer *layer = (IconDescriptionModalLayer*)modal;
    [layer removeFromParentAndCleanup:YES];
    [self configureInventory];
    [self configureEquippedSlots];
    [self.itemDescriptionNode setItem:nil];
    [self.itemDescriptionNode setVisible:NO];
    [self.lastSelectedSlot setIsSelected:NO];
}

@end

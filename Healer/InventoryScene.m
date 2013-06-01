//
//  InventoryScene.m
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "InventoryScene.h"
#import "HealerStartScene.h"
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

@interface InventoryScene ()
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
@end

#define INVENTORY_ROW_SIZE 5
#define INVENTORY_SLOT_TYPE -9999

@implementation InventoryScene

- (void)dealloc
{
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets/battle-sprites.plist"];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background"] autorelease]];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/battle-sprites.plist"];
        
        CCLabelTTF *titleLabel = [CCLabelTTF labelWithString:@"ARMORY" fontName:@"TeluguSangamMN-Bold" fontSize:64.0];
        [titleLabel setPosition:CGPointMake(512, 700)];
        [self addChild:titleLabel];
        
        CCSprite *healerPortrait = [CCSprite spriteWithSpriteFrameName:@"healer-portrait.png"];
        [healerPortrait setPosition:CGPointMake(180, 380)];
        [self addChild:healerPortrait];
        
        CGPoint slotOffsets = CGPointMake(healerPortrait.position.x * healerPortrait.anchorPoint.x, healerPortrait.position.y * healerPortrait.anchorPoint.y);
        
        self.headSlot = [[[Slot alloc] initWithInhabitantOrNil:nil] autorelease];
        self.headSlot.slotType = SlotTypeHead;
        self.headSlot.scale = .75;
        [self.headSlot setTitle:[self titleForSlotType:self.headSlot.slotType]];
        [self.headSlot setPosition:CGPointMake(100+slotOffsets.x, 400+slotOffsets.y)];
        [self addChild:self.headSlot];
        
        self.neckSlot = [[[Slot alloc] initWithInhabitantOrNil:nil] autorelease];
        self.neckSlot.slotType = SlotTypeNeck;
        self.neckSlot.scale = .75;
        [self.neckSlot setTitle:[self titleForSlotType:self.neckSlot.slotType]];
        [self.neckSlot setPosition:CGPointMake(10+slotOffsets.x, 300+slotOffsets.y)];
        [self addChild:self.neckSlot];
        
        self.chestSlot = [[[Slot alloc] initWithInhabitantOrNil:nil] autorelease];
        self.chestSlot.slotType = SlotTypeChest;
        self.chestSlot.scale = .75;
        [self.chestSlot setTitle:[self titleForSlotType:self.chestSlot.slotType]];
        [self.chestSlot setPosition:CGPointMake(10+slotOffsets.x, 150+slotOffsets.y)];
        [self addChild:self.chestSlot];
        
        self.legsSlot = [[[Slot alloc] initWithInhabitantOrNil:nil] autorelease];
        self.legsSlot.slotType = SlotTypeLegs;
        self.legsSlot.scale = .75;
        [self.legsSlot setTitle:[self titleForSlotType:self.legsSlot.slotType]];
        [self.legsSlot setPosition:CGPointMake(200+slotOffsets.x, 150+slotOffsets.y)];
        [self addChild:self.legsSlot];
        
        self.bootsSlot = [[[Slot alloc] initWithInhabitantOrNil:nil] autorelease];
        self.bootsSlot.scale = .75;
        self.bootsSlot.slotType = SlotTypeBoots;
        [self.bootsSlot setTitle:[self titleForSlotType:self.bootsSlot.slotType]];
        [self.bootsSlot setPosition:CGPointMake(100+slotOffsets.x, 50+slotOffsets.y)];
        [self addChild:self.bootsSlot];
        
        self.weaponSlot = [[[Slot alloc] initWithInhabitantOrNil:nil] autorelease];
        self.weaponSlot.scale = .75;
        self.weaponSlot.slotType = SlotTypeWeapon;
        [self.weaponSlot setTitle:[self titleForSlotType:self.weaponSlot.slotType]];
        [self.weaponSlot setPosition:CGPointMake(200+slotOffsets.x, 300+slotOffsets.y)];
        [self addChild:self.weaponSlot];
        
        [self configureEquippedSlots];
    
        CGPoint inventoryPosition = CGPointMake(620, 500);
        self.inventorySlots = [NSMutableArray arrayWithCapacity:[[PlayerDataManager localPlayer] maximumInventorySize]];
        
        for (int i = 0; i < [[PlayerDataManager localPlayer] maximumInventorySize] / INVENTORY_ROW_SIZE;i++) {
            for (int j = 0; j < INVENTORY_ROW_SIZE; j++) {
                Slot *inventorySlot = [[[Slot alloc] initWithInhabitantOrNil:nil] autorelease];
                inventorySlot.scale = .75;
                inventorySlot.slotType = INVENTORY_SLOT_TYPE;
                [inventorySlot setPosition:CGPointMake(inventoryPosition.x + 85 * j, inventoryPosition.y + (-85 * i))];
                [self.inventorySlots addObject:inventorySlot];
                [self addChild:inventorySlot];
            }
        }
        
        self.overflowLabel = [CCLabelTTFShadow labelWithString:@"You have items in overflow that will be made available once you can hold them." dimensions:CGSizeMake(400, 50) hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        self.overflowLabel.position = ccpSub(inventoryPosition, CGPointMake(-180, 180));
        [self addChild:self.overflowLabel];
        
        [self configureInventory];
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:BACK_BUTTON_POS];
        [self addChild:backButton z:100];
        
//        CCMenu *freeItem = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(freeItem)];
//        [freeItem setPosition:CGPointMake(512, 725)];
//        [self addChild:freeItem z:100];
        
        self.itemDescriptionNode = [[[ItemDescriptionNode alloc] init] autorelease];
        self.itemDescriptionNode.position = CGPointMake(800, 600);
        [self addChild:self.itemDescriptionNode];
        
        self.sellDrop = [[[SellDropSprite alloc] init] autorelease];
        [self.sellDrop setPosition:CGPointMake(800, 200)];
        [self addChild:self.sellDrop];
        
        CCLabelTTFShadow *statsTitleLabel = [CCLabelTTFShadow labelWithString:@"Stats:" fontName:@"TrebuchetMS-Bold" fontSize:28.0];
        [statsTitleLabel setPosition:CGPointMake(400, 550)];
        [self addChild:statsTitleLabel];
        
        self.statsLabel = [CCLabelTTFShadow labelWithString:[self statsString] dimensions:CGSizeMake(200, 600) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS" fontSize:14.0];
        [self.statsLabel setPosition:CGPointMake(475, 220)];
        [self addChild:self.statsLabel];
        
//        self.allyDamage = [CCLabelTTFShadow labelWithString:@"Ally Damage:\n+0%" fontName:@"TrebuchetMS-Bold" fontSize:28.0];
//        [self.allyDamage setPosition:CGPointMake(300, 120)];
//        [self addChild:self.allyDamage];
        
        self.allyHealth = [CCLabelTTFShadow labelWithString:@"Ally Health:\n+0%" fontName:@"TrebuchetMS-Bold" fontSize:28.0];
        [self.allyHealth setPosition:CGPointMake(500, 120)];
        [self addChild:self.allyHealth];
        
        GoldCounterSprite *goldCounter = [[[GoldCounterSprite alloc] init] autorelease];
        [goldCounter setPosition:CGPointMake(900, 45)];
        [self addChild:goldCounter];
        
        self.allyHealthUpgradeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(upgradeAllyHealth) andTitle:@"Upgrade"];
        [self.allyHealthUpgradeButton setScale:.5];
        
//        self.allyDamageUpgradeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(upgradeAllyDamage) andTitle:@"Upgrade"];
//        [self.allyDamageUpgradeButton setScale:.5];
        
        [self configureAllyUpgrades];
        
        CCMenu *upgradeMenu = [CCMenu menuWithItems:/*self.allyDamageUpgradeButton,*/self.allyHealthUpgradeButton, nil];
        [upgradeMenu setPosition:CGPointMake(500, 28)];
//        [upgradeMenu alignItemsHorizontallyWithPadding:90];
        [self addChild:upgradeMenu];
        
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
//    if (self.allyDamageCostNode) {
//        [self.allyDamageCostNode removeFromParentAndCleanup:YES];
//    }
    if (self.allyHealthCostNode) {
        [self.allyHealthCostNode removeFromParentAndCleanup:YES];
    }
    
//    self.allyDamage.string = [NSString stringWithFormat:@"Ally Damage:\n+%i%%", [PlayerDataManager localPlayer].allyDamageUpgrades];
    self.allyHealth.string = [NSString stringWithFormat:@"Ally Health:\n+%i%%", [PlayerDataManager localPlayer].allyHealthUpgrades];
    
    self.allyHealthCostNode = [GoldCounterSprite goldCostNodeForCost:[PlayerDataManager localPlayer].nextAllyHealthUpgradeCost];
    [self.allyHealthCostNode setPosition:CGPointMake(550, 50)];
    [self addChild:self.allyHealthCostNode];
    
//    self.allyDamageCostNode = [GoldCounterSprite goldCostNodeForCost:[PlayerDataManager localPlayer].nextAllyDamageUpgradeCost];
//    [self.allyDamageCostNode setPosition:CGPointMake(350, 50)];
//    [self addChild:self.allyDamageCostNode];
}

-(void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}

- (void)freeItem
{
    [[PlayerDataManager localPlayer] staminaUsedWithCompletion:^(BOOL success) {
        if (success) {
            Encounter *encounter = [Encounter encounterForLevel:arc4random() % 21 + 1 isMultiplayer:NO];
            EquipmentItem *randomItem = encounter.randomLootReward;
            [[PlayerDataManager localPlayer] playerEarnsItem:randomItem];
            [self configureInventory];
        }
    }];
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
                        [slotChild setTitle:[self titleForSlotType:slotChild.slotType]];
                        [slotChild setTitleColor:ccWHITE];
                    }
                    [self.draggingSprite setAnchorPoint:CGPointMake(.5, .5)];
                    [self addChild:self.draggingSprite];
                    [self.draggingSprite setPosition:slotChild.position];
                    self.draggingSprite.scale = .75;
                    self.itemDescriptionNode.item = self.draggingSprite.item;
                    self.lastSelectedSlot = slotChild;
                }
            }
        }
    }
    
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
    [self.lastSelectedSlot setIsSelected:NO];
}

@end

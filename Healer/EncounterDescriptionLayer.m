//
//  EncounterDescriptionLayer.m
//  Healer
//
//  Created by Ryan Hart on 5/31/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "EncounterDescriptionLayer.h"
#import "BackgroundSprite.h"
#import "CCLabelTTFShadow.h"
#import "BasicButton.h"
#import "Encounter.h"
#import "ItemDescriptionNode.h"
#import "Ability.h"
#import "Enemy.h"
#import "EquipmentItem.h"

@interface EncounterDescriptionLayer ()
@property (nonatomic, assign) BackgroundSprite *overpaper;
@property (nonatomic, assign) CCMenu *dismissMenu;
@property (nonatomic, assign) CCMenu *backButton;
@end

@implementation EncounterDescriptionLayer

- (id)initWithEncounter:(Encounter *)encounter
{
    if (self = [super init]) {
        self.overpaper = [[[BackgroundSprite alloc] initWithAssetName:@"over-paper"] autorelease];
        self.overpaper.flipX = YES;
        self.overpaper.position = CGPointMake([CCDirectorIOS sharedDirector].winSize.width, 0);
        [self addChild:self.overpaper];
        
        CCLabelTTFShadow *encounterInfo = [CCLabelTTFShadow labelWithString:@"Drops" dimensions: CGSizeMake(self.overpaper.contentSize.width, 80) hAlignment:kCCTextAlignmentCenter  fontName:@"Cochin-BoldItalic" fontSize:64.0];
        encounterInfo.shadowOffset = CGPointMake(-1, -1);
        [encounterInfo setColor:ccc3(88, 54, 22)];
        [encounterInfo setPosition:CGPointMake(self.overpaper.contentSize.width / 2, self.overpaper.contentSize.height * .9)];
        [self.overpaper addChild:encounterInfo];
        
        self.backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(dismiss)];
        [self.backButton setPosition:BACK_BUTTON_POS];
        [self addChild:self.backButton];
        
        BasicButton *dismiss = [BasicButton basicButtonWithTarget:self andSelector:@selector(dismiss) andTitle:@"HIDE"];
        [dismiss setScale:.75];
        
        self.dismissMenu = [CCMenu menuWithItems:dismiss, nil];
        [self.dismissMenu setPosition:CGPointMake(266, 38)];
        [self addChild:self.dismissMenu];
        
//        //Loot
//        CCLabelTTFShadow *lootHeader = [CCLabelTTFShadow labelWithString:@"Loot" dimensions: CGSizeMake(self.overpaper.contentSize.width, 80) hAlignment:kCCTextAlignmentCenter  fontName:@"Cochin" fontSize:48.0];
//        [lootHeader setColor:ccc3(88, 54, 22)];
//        [lootHeader setPosition:CGPointMake(self.overpaper.contentSize.width / 2, self.overpaper.contentSize.height * .8)];
//        [self.overpaper addChild:lootHeader];
        
        CCLayerColor *divider = [CCLayerColor layerWithColor:ccc4(88, 54, 22, 255)];
        [divider setContentSize:CGSizeMake(self.overpaper.contentSize.width * .8, 2)];
        [divider setPosition:CGPointMake(self.overpaper.contentSize.width * .15, encounterInfo.position.y - 40)];
        [self.overpaper addChild:divider];
        
        NSInteger descriptionHeight = 120;
        NSArray *legendaries = [Encounter legendaryItemsForLevelNumber:encounter.levelNumber];
        NSArray *encounterLoot = [legendaries arrayByAddingObjectsFromArray:[Encounter epicItemsForLevelNumber:encounter.levelNumber]];
        NSInteger height = encounterInfo.position.y - 120;
        for (EquipmentItem *item in encounterLoot) {
            CCSprite *icon = [CCSprite spriteWithSpriteFrameName:item.itemSpriteName];
            [icon setPosition:CGPointMake(self.overpaper.contentSize.width / 4, height)];
            [self.overpaper addChild:icon];
            ItemDescriptionNode *itemDesc = [[[ItemDescriptionNode alloc] init] autorelease];
            [itemDesc setItem:item];
            [itemDesc setPosition:CGPointMake(self.overpaper.contentSize.width / 2 + 80, height)];
            [self.overpaper addChild:itemDesc];
            height -= descriptionHeight;
        }
        
        ItemDescriptionNode *randomBlue = [[[ItemDescriptionNode alloc] init] autorelease];
        [randomBlue configureForRandomWithRarity:ItemRarityRare];
        [randomBlue setPosition:CGPointMake(self.overpaper.contentSize.width / 2 + 80, height)];
        [self.overpaper addChild:randomBlue];
        height -= descriptionHeight;
        
        ItemDescriptionNode *randomGreen = [[[ItemDescriptionNode alloc] init] autorelease];
        [randomGreen configureForRandomWithRarity:ItemRarityUncommon];
        [randomGreen setPosition:CGPointMake(self.overpaper.contentSize.width / 2 + 80, height)];
        [self.overpaper addChild:randomGreen];
        height -= descriptionHeight;
        
        
        NSString *lootInfoString = @"Increased difficulty improves the quality of random loot and the chances of epic loot.";
        
        if ([Encounter legendaryItemsForLevelNumber:encounter.levelNumber].count > 0) {
            lootInfoString = [lootInfoString stringByAppendingString:@" Legendary items can only drop on Brutal difficulty."];
        }
        
        CCLabelTTFShadow *lootInfo = [CCLabelTTFShadow labelWithString:lootInfoString dimensions: CGSizeMake(self.overpaper.contentSize.width * .8, 80) hAlignment:kCCTextAlignmentCenter  fontName:@"Cochin" fontSize:24.0];
        [lootInfo setColor:ccc3(88, 54, 22)];
        lootInfo.shadowOffset = CGPointMake(-1, -1);
        [lootInfo setPosition:CGPointMake(self.overpaper.contentSize.width / 2, height)];
        [self.overpaper addChild:lootInfo];
        //height -= descriptionHeight;
        
    }
    return self;
}

- (void)onEnter
{
    [super onEnter];
    [[CCDirector sharedDirector].touchDispatcher addTargetedDelegate:self priority:kCCMenuHandlerPriority - 100 swallowsTouches:YES];
    [self.dismissMenu setHandlerPriority:kCCMenuHandlerPriority - 101];
    [self.backButton setHandlerPriority:kCCMenuHandlerPriority - 101];

    [self.overpaper runAction:[CCMoveTo actionWithDuration:.33 position:CGPointMake([CCDirectorIOS sharedDirector].winSize.width - self.overpaper.contentSize.width, 0)]];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

- (void)onExit
{
    [super onExit];
    [[CCDirector sharedDirector].touchDispatcher removeDelegate:self];
}

- (void)dismiss
{
    [self.overpaper runAction:[CCMoveTo actionWithDuration:.33 position:CGPointMake([CCDirectorIOS sharedDirector].winSize.width, 0)]];
    [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:.35] two:[CCCallBlockN actionWithBlock:^(CCNode *node){
        [node removeFromParentAndCleanup:YES];
    }]]];
}

@end

//
//  ItemDescriptionNode.m
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "ItemDescriptionNode.h"
#import "CCLabelTTFShadow.h"

@interface ItemDescriptionNode ()
@property (nonatomic, assign) CCLabelTTFShadow *titleLabel;
@property (nonatomic, assign) CCLabelTTFShadow *descriptionLabel;
@property (nonatomic, assign) CCLabelTTFShadow *infoLabel;
@property (nonatomic, assign) CCLabelTTFShadow *slotTypeLabel;
@end

@implementation ItemDescriptionNode

- (void)dealloc
{
    [_item release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        CCSprite *bg = [CCSprite spriteWithSpriteFrameName:@"spell_info_node_bg.png"];
        [self addChild:bg];
        
        self.titleLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        self.titleLabel.position = CGPointMake(2, 34);
        [self addChild:self.titleLabel];
        
        self.descriptionLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 60) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        self.descriptionLabel.position = CGPointMake(0, 0);
        [self addChild:self.descriptionLabel];
        
        self.infoLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(bg.contentSize.width, 34) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        self.infoLabel.position = CGPointMake(10, -bg.contentSize.height / 2 + 24);
        [self addChild:self.infoLabel];
        
        self.slotTypeLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 50) hAlignment:kCCTextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:16.0];
        self.slotTypeLabel.color = ccGRAY;
        self.slotTypeLabel.position = CGPointMake(2, 30);
        [self addChild:self.slotTypeLabel];
    }
    return self;
}

- (void)setItem:(EquipmentItem *)item
{
    [_item release];
    _item = [item retain];
    [self configureForItem];
}

+ (ccColor3B)colorForRarity:(ItemRarity)rarity
{
    switch (rarity) {
        case ItemRarityUncommon:
            return ccGREEN;
        case ItemRarityRare:
            return ccBLUE;
        case ItemRarityEpic:
            return ccc3(200, 0, 200);
        case ItemRarityLegendary:
            return ccORANGE;
    }
    return ccWHITE;
}

- (void)configureForItem
{
    if (self.item) {
        self.titleLabel.string = self.item.name;
        self.titleLabel.color = [ItemDescriptionNode colorForRarity:self.item.rarity];
        self.descriptionLabel.string = [self statsLineForItem:self.item];
        self.infoLabel.string = self.item.info;
        self.slotTypeLabel.string = self.item.slotTypeName;
    } else {
        self.titleLabel.string = @"";
        self.descriptionLabel.string = @"";
        self.infoLabel.string = @"";
        self.slotTypeLabel.string = @"";
    }
}

- (void)formatString:(NSMutableString*)string forCount:(NSInteger)count
{
    if (count % 2 == 0) {
        [string appendString:@"     "];
    } else {
        [string appendString:@"\n"];
    }
}

- (NSString *)statsLineForItem:(EquipmentItem *)item
{
    NSMutableString *statsLine = [NSMutableString string];
    NSInteger statsCount = 0;
    if (item.health > 0) {
        [statsLine appendFormat:@"Health: +%i", item.health];
        statsCount++;
        [self formatString:statsLine forCount:statsCount];
    }
    if (item.healing > 0) {
        [statsLine appendFormat:@"Healing: +%1.1f%%", item.healing];
        statsCount++;
        [self formatString:statsLine forCount:statsCount];
    }
    if (item.speed > 0) {
        [statsLine appendFormat:@"Speed: +%1.1f%%", item.speed];
        statsCount++;
        [self formatString:statsLine forCount:statsCount];
    }
    if (item.crit > 0) {
        [statsLine appendFormat:@"Crit: +%1.1f%%", item.crit];
        statsCount++;
        [self formatString:statsLine forCount:statsCount];
    }
    if (item.regen > 0) {
        [statsLine appendFormat:@"Mana Regen: +%1.1f%%", item.regen];
        statsCount++;
        [self formatString:statsLine forCount:statsCount];
    }
    
    return statsLine;
}

@end

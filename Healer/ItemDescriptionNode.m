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
@property (nonatomic, assign) CCSprite *background;
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
        self.background = [CCSprite spriteWithSpriteFrameName:@"spell_info_node_bg.png"];
        [self addChild:self.background];
        
        self.titleLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        self.titleLabel.position = CGPointMake(2, 46);
        self.titleLabel.shadowOffset = CGPointMake(-1, -1);
        [self addChild:self.titleLabel];
        
        self.descriptionLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 60) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        self.descriptionLabel.position = CGPointMake(0, 0);
        self.descriptionLabel.shadowOffset = CGPointMake(-1, -1);
        [self addChild:self.descriptionLabel];
        
        self.infoLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 34) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        self.infoLabel.position = CGPointMake(2, -self.background.contentSize.height / 2 + 24);
        self.infoLabel.shadowOffset = CGPointMake(-1, -1);
        [self addChild:self.infoLabel];
        
        self.slotTypeLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 50) hAlignment:kCCTextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:16.0];
        self.slotTypeLabel.color = ccGRAY;
        self.slotTypeLabel.position = CGPointMake(2, 20);
        self.slotTypeLabel.shadowOffset = CGPointMake(-1, -1);
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
        CGFloat fontSize = 24.0;
//        if (self.item.name.length > 20) {
//            fontSize = 20.0;
//        }
        self.titleLabel.fontSize = fontSize;
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
    NSInteger statsCount = 1;
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

- (void)configureForRandomWithRarity:(ItemRarity)rarity
{
    self.titleLabel.string = @"Random";
    self.titleLabel.color = [ItemDescriptionNode colorForRarity:rarity];
    self.descriptionLabel.string = @"Health: +??\nHealing: +??%     Speed: +??%\nCrit: +??%     Mana Regen: +??%";
    self.slotTypeLabel.string = @"Random";
    self.infoLabel.string = @"";
}

@end

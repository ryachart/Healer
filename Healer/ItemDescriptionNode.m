//
//  ItemDescriptionNode.m
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "ItemDescriptionNode.h"
#import "CCLabelTTFShadow.h"

@interface ItemDescriptionNode ()
@property (nonatomic, assign) CCLabelTTFShadow *titleLabel;
@property (nonatomic, assign) CCLabelTTFShadow *descriptionLabel;
@property (nonatomic, assign) CCLabelTTFShadow *infoLabel;
@property (nonatomic, assign) CCLabelTTFShadow *slotTypeLabel;
@property (nonatomic, assign) CCSprite *background;
@property (nonatomic, assign) CCSprite *itemSprite;
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
        self.background = [CCSprite spriteWithSpriteFrameName:@"icon_card_back.png"];
        [self addChild:self.background];
        
        
        self.titleLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        self.titleLabel.position = CGPointMake(52, 26);
        self.titleLabel.shadowOffset = CGPointMake(-1, -1);
        [self addChild:self.titleLabel];
        
        self.descriptionLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 40) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        self.descriptionLabel.position = CGPointMake(52, 8);
        self.descriptionLabel.shadowOffset = CGPointMake(-1, -1);
        [self addChild:self.descriptionLabel];
        
        self.infoLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(300, 40) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        self.infoLabel.position = CGPointMake(52, -30);
        self.infoLabel.shadowOffset = CGPointMake(-1, -1);
        self.infoLabel.color = ccYELLOW;
        [self addChild:self.infoLabel];
        
        self.slotTypeLabel = [CCLabelTTFShadow labelWithString:@"" fontName:@"TrebuchetMS-Bold" fontSize:16.0];
        [self.slotTypeLabel setHorizontalAlignment:kCCTextAlignmentRight];
        self.slotTypeLabel.color = ccGRAY;
        self.slotTypeLabel.shadowOffset = CGPointMake(-1, -1);
        [self addChild:self.slotTypeLabel];
        
        self.itemSprite = [CCSprite node];
        [self.itemSprite setPosition:CGPointMake(52, 51)];
        [self.background addChild:self.itemSprite];
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

- (void)configureSlotLabelPosition
{
    self.slotTypeLabel.position = CGPointMake(self.background.contentSize.width / 2 - self.slotTypeLabel.contentSize.width + 4, self.background.contentSize.height / 2 - self.slotTypeLabel.contentSize.height + 4);
}

- (void)configureForItem
{
    if (self.item) {
        CGFloat fontSize = 24.0;
        if (self.item.name.length > 15) {
            fontSize = 20.0;
        }
        self.titleLabel.fontSize = fontSize;
        self.titleLabel.string = self.item.name;
        self.titleLabel.color = [ItemDescriptionNode colorForRarity:self.item.rarity];
        self.descriptionLabel.string = [self statsLineForItem:self.item];
        self.infoLabel.string = self.item.info;
        self.slotTypeLabel.string = self.item.slotTypeName;
        
        [self configureSlotLabelPosition];
        [self.itemSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:self.item.itemSpriteName]];
    } else {
        self.titleLabel.string = @"";
        self.descriptionLabel.string = @"";
        self.infoLabel.string = @"";
        self.slotTypeLabel.string = @"";
        [self.itemSprite setDisplayFrame:nil];
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
        [statsLine appendFormat:@"Crit: +%1.2f%%", item.crit];
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

- (void)setOpacity:(GLubyte)opacity
{
    [super setOpacity:opacity];
    for (CCNode *child in self.children) {
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            [(id<CCRGBAProtocol>)child setOpacity:opacity];
        }
    }
    [self.itemSprite setOpacity:opacity];
}

- (void)configureForRandomWithRarity:(ItemRarity)rarity
{
    self.titleLabel.string = @"Random Item";
    self.titleLabel.color = [ItemDescriptionNode colorForRarity:rarity];
    self.descriptionLabel.string = @"Health: +??     Healing: +??%\nSpeed: +??%     Crit: +??%\nMana Regen: +??%";
    self.slotTypeLabel.string = @"Random";
    self.infoLabel.string = @"";
    [self configureSlotLabelPosition];
}

@end

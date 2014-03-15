//
//  EquipmentItem.h
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SlotTypeHead,
    SlotTypeWeapon,
    SlotTypeChest,
    SlotTypeLegs,
    SlotTypeBoots,
    SlotTypeNeck,
    SlotTypeMaximum
} SlotType;

typedef enum {
    StatTypeHealth,
    StatTypeHealing,
    StatTypeRegen,
    StatTypeCrit,
    StatTypeSpeed,
    StatTypeMaximum
} StatType;

typedef enum {
    ItemRarityUncommon = 1,
    ItemRarityRare,
    ItemRarityEpic = 4,
    ItemRarityLegendary = 5
} ItemRarity;

@class Spell;

@interface EquipmentItem : NSObject
@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, readonly) NSInteger health;
@property (nonatomic, readonly) float regen;
@property (nonatomic, readonly) float speed;
@property (nonatomic, readonly) float crit;
@property (nonatomic, readonly) float healing;
@property (nonatomic, readonly) NSInteger quality;
@property (nonatomic, readonly) SlotType slot;
@property (nonatomic, retain, readonly) NSString *cacheString;
@property (nonatomic, retain, readonly) NSString *itemSpriteName;
@property (nonatomic, readwrite) ItemRarity rarity;
@property (nonatomic, retain, readonly) NSString *specialKey;
@property (nonatomic, readonly) NSInteger salePrice;
@property (nonatomic, readonly) NSInteger uniqueId;
@property (nonatomic, readonly) NSString *info;
@property (nonatomic, readonly) Spell *spellFromItem;
@property (nonatomic, readonly) NSString *slotTypeName;
@property (nonatomic, readonly) NSInteger earnedItemId;
@property (nonatomic, readonly) NSString *avatarItemName;
@property (nonatomic, readonly) NSString *baseString;

- (id)initWithName:(NSString *)name health:(NSInteger)health regen:(float)regen speed:(float)speed crit:(float)crit healing:(float)healing slot:(SlotType)slot rarity:(ItemRarity)rarity specialKey:(NSString *)specialKey quality:(NSInteger)quality uniqueId:(NSInteger)uniqueId;
- (id)initWithItemCacheString:(NSString *)string;

- (void)itemEarnedWithId:(NSInteger)earnedId;
- (BOOL)isEarnedItem:(EquipmentItem *)item;

+ (EquipmentItem *)randomItemWithRarity:(ItemRarity)rarity andQuality:(NSInteger)quality;
@end

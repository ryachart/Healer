//
//  EquipmentItem.m
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "EquipmentItem.h"


static float stat_atoms[StatTypeMaximum] = {
    5, //Health
    0.5, //Healing
    0.5, //Regen
    0.5, //Crit
    0.5}; //Speed

@implementation EquipmentItem

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@", self.name];
}

- (BOOL)isEqual:(id)object
{
    EquipmentItem *otherItem = (EquipmentItem*)object;
    if ([otherItem isKindOfClass:[EquipmentItem class]]) {
        BOOL isEqual = [otherItem.name isEqualToString:self.name] &&
        otherItem.rarity == self.rarity &&
        otherItem.regen == self.regen &&
        otherItem.health == self.health &&
        otherItem.speed == self.speed &&
        otherItem.healing == self.healing &&
        otherItem.crit == self.crit &&
        otherItem.slot == self.slot &&
        otherItem.quality == self.quality &&
        [otherItem.specialKey isEqualToString:self.specialKey];
        return isEqual;
    }
    
    return false;
}

- (id)initWithName:(NSString *)name health:(NSInteger)health regen:(float)regen speed:(float)speed crit:(float)crit healing:(float)healing slot:(SlotType)slot rarity:(ItemRarity)rarity specialKey:(NSString *)specialKey quality:(NSInteger)quality
{
    if (self = [super init]) {
        _slot = slot;
        _healing = healing;
        _crit = crit;
        _health = health;
        _regen = regen;
        _speed = speed;
        _name = [name retain];
        _rarity = rarity;
        _specialKey = [specialKey retain];
        _quality = quality;
    }
    return self;
}

- (id)initWithItemCacheString:(NSString *)string
{
    if (![string isKindOfClass:[NSString class]]) {
        NSLog(@"WUT!?");
    }
    NSArray *components = [string componentsSeparatedByString:@"|"];
    if (components.count < 10) {
        return nil; //Corrupted item
    }
    NSString* name = [components objectAtIndex:0];
    NSInteger health = [[components objectAtIndex:1] integerValue];
    float regen = [[components objectAtIndex:2] floatValue];
    float speed = [[components objectAtIndex:3] floatValue];
    float crit = [[components objectAtIndex:4] floatValue];
    float healing = [[components objectAtIndex:5] floatValue];
    SlotType slot = (SlotType)[[components objectAtIndex:6] integerValue];
    ItemRarity rarity = (ItemRarity)[[components objectAtIndex:7] integerValue];
    NSString *specialKey = [components objectAtIndex:8];
    NSInteger quality = [[components objectAtIndex:9] integerValue];
    self = [self initWithName:name health:health regen:regen speed:speed crit:crit healing:healing slot:slot rarity:rarity specialKey:specialKey quality:quality];
    return self;
}

- (NSString *)cacheString
{
    return [NSString stringWithFormat:@"%@|%i|%1.3f|%1.3f|%1.3f|%1.3f|%i|%i|%@|%i", self.name, self.health, self.regen, self.speed, self.crit, self.healing, self.slot, self.rarity, self.specialKey, self.quality];
}

+ (EquipmentItem *)randomItemWithRarity:(ItemRarity)rarity andQuality:(NSInteger)quality
{
    SlotType slot = arc4random() % SlotTypeMaximum;
    NSInteger totalAtoms = quality * (slot == SlotTypeWeapon ? 1.5 : 1) * (rarity);
    NSInteger totalStats = rarity;
    
    NSMutableArray *stats = [NSMutableArray arrayWithCapacity:StatTypeMaximum];
    
    for (int i = 0; i < StatTypeMaximum; i++) {
        //Load up an array with all the possible stat types
        [stats addObject:[NSNumber numberWithInt:i]];
    }
    
    for (int i = 0; i < (StatTypeMaximum - totalStats); i++) {
        [stats removeObjectAtIndex:arc4random() % stats.count];
    }
    
    //What's left are the stats we're building with.
    //Now to randomly distribute the atoms.
    
    float statValues[StatTypeMaximum] = {0,0,0,0,0};
    
    for (int i = 0; i < stats.count; i++) {
        //First put at least one atom in each stat we rolled
        StatType type = [[stats objectAtIndex:i] integerValue];
        statValues[type] = stat_atoms[type];
        totalAtoms--;
    }
    
    for (int i = 0; i < totalAtoms; i++) {
        StatType type = [[stats objectAtIndex:arc4random() % stats.count] integerValue];
        statValues[type] += stat_atoms[type];
    }
    
    EquipmentItem *item = [[[EquipmentItem alloc] initWithName:[NSString stringWithFormat:@"%@ of Light", [[[EquipmentItem slotPrefixes] objectAtIndex:slot] objectAtIndex:0]] health:statValues[StatTypeHealth] regen:statValues[StatTypeRegen] speed:statValues[StatTypeSpeed] crit:statValues[StatTypeCrit] healing:statValues[StatTypeHealing] slot:slot rarity:rarity specialKey:nil quality:quality] autorelease];
    
    return item;
}

- (NSString *)itemSpriteName
{
    NSString *itemSprite = @"helm.png";
    switch (self.slot) {
        case SlotTypeBoots:
            itemSprite = @"boots.png";
            break;
        case SlotTypeChest:
            itemSprite = @"robe.png";
            break;
        case SlotTypeHead:
            itemSprite = @"helm.png";
            break;
        case SlotTypeLegs:
            itemSprite = @"pants.png";
            break;
        case SlotTypeNeck:
            itemSprite = @"necklace.png";
            break;
        case SlotTypeWeapon:
            itemSprite = @"wand.png";
            break;
        case SlotTypeMaximum:
        default:
            break;
    }
    return itemSprite;
}

- (NSInteger)salePrice
{
    return 5 * (self.quality + (self.rarity * 2));
}

+ (NSArray *)slotPrefixes{
    NSArray *slotPrefix = @[@[@"Helm", @"Cover", @"Hood", @"Hat"], //Head
                            @[@"Wand", @"Tome", @"Staff"], //Weapon
                            @[@"Robe", @"Tunic", @"Garment", @"Vestment"], //Chest,
                            @[@"Pants", @"Pantaloons", @"Trousers", @"Breeches"], //Legs,
                            @[@"Boots", @"Sandals", @"Slippers", @"Shoes"], //Boots,
                            @[@"Necklace", @"Pendant", @"Chain", @"Choker"] //Neck
                            ];
    return slotPrefix;
}

+ (NSArray *)suffixes {
    NSArray *suffix = @[@"Light", //+Healing
                        @"Fortitude", //+Health
                        @"Glory", //+Speed
                        @"Knowledge", //+Regen
                        @"Chance", //+Crit
                        ];
    return suffix;
}
@end

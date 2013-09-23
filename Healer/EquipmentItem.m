//
//  EquipmentItem.m
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "EquipmentItem.h"
#import "Spell.h"
#import "Effect.h"
#import "NSString+Obfuscation.h"

static float stat_atoms[StatTypeMaximum] = {
    5, //Health
    0.5, //Healing
    0.5, //Regen
    0.75, //Crit
    0.5 //Speed
};

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

- (BOOL)isEarnedItem:(EquipmentItem *)item
{
    if (self.earnedItemId && item.earnedItemId == self.earnedItemId) {
        return YES;
    }
    return NO;
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
        [otherItem.specialKey isEqualToString:self.specialKey] &&
        otherItem.uniqueId == self.uniqueId;
        return isEqual;
    }
    
    return false;
}

- (id)initWithName:(NSString *)name health:(NSInteger)health regen:(float)regen speed:(float)speed crit:(float)crit healing:(float)healing slot:(SlotType)slot rarity:(ItemRarity)rarity specialKey:(NSString *)specialKey quality:(NSInteger)quality uniqueId:(NSInteger)uniqueId
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
        _uniqueId = uniqueId;
    }
    return self;
}

- (id)initWithItemCacheString:(NSString *)string
{
    if (![string isKindOfClass:[NSString class]]) {
        NSLog(@"WUT!?");
    }
    NSString *deobString = string.deobfuscatedString;
    NSArray *components = [deobString componentsSeparatedByString:@"|"];
    if (components.count < 12) {
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
    NSInteger uniqueId = [[components objectAtIndex:10] integerValue];
    NSInteger itemId = [[components objectAtIndex:11] integerValue];
    self = [self initWithName:name health:health regen:regen speed:speed crit:crit healing:healing slot:slot rarity:rarity specialKey:specialKey quality:quality uniqueId:uniqueId];
    if (itemId) {
        [self itemEarnedWithId:itemId];
    }
    return self;
}

- (NSString *)cacheString
{
    NSString *baseString = [NSString stringWithFormat:@"%@|%i|%1.3f|%1.3f|%1.3f|%1.3f|%i|%i|%@|%i|%i|%i", self.name, self.health, self.regen, self.speed, self.crit, self.healing, self.slot, self.rarity, self.specialKey, self.quality, self.uniqueId, self.earnedItemId];
    
    return baseString.obfuscatedString;
}

+ (NSString *)randomItemNameForSlot:(SlotType)slot
{
    NSArray *prefixesForSlot = [[EquipmentItem slotPrefixes] objectAtIndex:slot];
    NSArray *suffixes = [EquipmentItem suffixes];
    
    return [NSString stringWithFormat:@"%@ of %@", [prefixesForSlot objectAtIndex:arc4random() % prefixesForSlot.count], [suffixes objectAtIndex:arc4random() % suffixes.count]];
}

+ (EquipmentItem *)randomItemWithRarity:(ItemRarity)rarity andQuality:(NSInteger)quality
{
    SlotType slot = arc4random() % SlotTypeMaximum;
    int slotModifiers[SlotTypeMaximum] = {1.125, 1, 1.25, 1.125, 1, 1};
    NSInteger totalAtoms = quality * slotModifiers[slot] * rarity;
    NSInteger totalStats = rarity;
    
    NSMutableArray *stats = [NSMutableArray arrayWithCapacity:StatTypeMaximum];
    
    if (rarity == ItemRarityUncommon && slot == SlotTypeChest) {
        //Uncommon Chests are really uninteresting because they have only health =/
        totalStats++;
        if (quality == 1) {
            //Ridiculous, but QL1 chests just aren't interesting as they only have +health
            quality = 2;
        }
    }
    
    for (int i = 0; i < StatTypeMaximum; i++) {
        //Load up an array with all the possible stat types
        [stats addObject:[NSNumber numberWithInt:i]];
    }
    
    for (int i = 0; i < (StatTypeMaximum - totalStats); i++) {
        [stats removeObjectAtIndex:arc4random() % stats.count];
    }
    
    if (slot == SlotTypeChest) {
        //Chests must contain the health stat
        if (![stats containsObject:[NSNumber numberWithInt:StatTypeHealth]]) {
            [stats removeObjectAtIndex:arc4random() % stats.count];
            [stats addObject:[NSNumber numberWithInt:StatTypeHealth]];
        }
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
    
    NSString *randomName = [EquipmentItem randomItemNameForSlot:slot];
    NSArray *specialKeys = [EquipmentItem specialKeys];
    NSString *specialKey = nil;
    if (slot == SlotTypeWeapon && quality >= 4) {
        specialKey = [specialKeys objectAtIndex:arc4random() % specialKeys.count];
    }
    
    EquipmentItem *item = [[[EquipmentItem alloc] initWithName:randomName health:statValues[StatTypeHealth] regen:statValues[StatTypeRegen] speed:statValues[StatTypeSpeed] crit:statValues[StatTypeCrit] healing:statValues[StatTypeHealing] slot:slot rarity:rarity specialKey:specialKey quality:quality uniqueId:0] autorelease];
    
    return item;
}

- (NSString *)itemSpriteName
{
    NSString *raritySuffix = nil;
    switch (self.rarity) {
        case ItemRarityUncommon:
            raritySuffix = @"uncommon";
            break;
        case ItemRarityRare:
            raritySuffix = @"rare";
            break;
        case ItemRarityEpic:
            raritySuffix = @"epic";
            break;
        case ItemRarityLegendary:
            raritySuffix = @"legendary";
            break;
    }
    
    NSString *slotName = nil;
    switch (self.slot) {
        case SlotTypeBoots:
            slotName = @"boots";
            break;
        case SlotTypeChest:
            slotName = @"robe";
            break;
        case SlotTypeHead:
            slotName = @"cowl";
            break;
        case SlotTypeLegs:
            slotName = @"pants";
            break;
        case SlotTypeNeck:
            slotName = @"neck";
            break;
        case SlotTypeWeapon:
            slotName = @"tome";
            break;
        case SlotTypeMaximum:
        default:
            break;
    }
    NSInteger key = 1;
    //Adjust key for specific items here
    
    return [NSString stringWithFormat:@"%@_%d_%@.png", slotName, key, raritySuffix];
}

- (NSString *)avatarItemName
{
    NSString *raritySuffix = nil;
    switch (self.rarity) {
        case ItemRarityUncommon:
            raritySuffix = @"uncommon";
            break;
        case ItemRarityRare:
            raritySuffix = @"rare";
            break;
        case ItemRarityEpic:
            raritySuffix = @"epic";
            break;
        case ItemRarityLegendary:
            raritySuffix = @"legendary";
            break;
    }
    
    NSString *slotName = nil;
    switch (self.slot) {
        case SlotTypeBoots:
            slotName = @"boots";
            break;
        case SlotTypeChest:
            slotName = @"chest";
            break;
        case SlotTypeHead:
            slotName = @"helm";
            break;
        case SlotTypeLegs:
            slotName = @"pants";
            break;
        case SlotTypeNeck:
            slotName = @"neck";
            break;
        case SlotTypeWeapon:
            slotName = @"tome";
            break;
        case SlotTypeMaximum:
        default:
            break;
    }
    NSInteger key = 1;
    //Adjust key for specific items here
    
    return [NSString stringWithFormat:@"avatar_%@%d_%@.png", slotName, key, raritySuffix];
}

- (NSInteger)salePrice
{
    return 5 * (self.quality + (self.rarity * 2));
}

- (NSString *)info
{
    if (!self.specialKey) {
        return nil;
    }
    return [EquipmentItem descriptionForSpecialKey:self.specialKey];
}

- (Spell*)spellFromItem
{
    if (self.specialKey) {
        Spell *spell = nil;
        if ([self.specialKey isEqualToString:@"burst1"]) {
            spell = [[[Spell alloc] initWithTitle:@"Burst1" healAmnt:100 energyCost:0 castTime:0 andCooldown:15.0] autorelease];
        }
        if ([self.specialKey isEqualToString:@"burst2"]) {
            spell = [[[Spell alloc] initWithTitle:@"Burst2" healAmnt:150 energyCost:0 castTime:0 andCooldown:15.0] autorelease];
        }
        if ([self.specialKey isEqualToString:@"raidheal1"]) {
            spell = [[[RaidHeal alloc] initWithTitle:@"RaidHeal" healAmnt:30 energyCost:0 castTime:0 andCooldown:30.0] autorelease];
        }
        if ([self.specialKey isEqualToString:@"healbuff1"]) {
            spell = [[[HealBuff alloc] initWithTitle:@"HealBuff" healAmnt:0 energyCost:0 castTime:0 andCooldown:30.0] autorelease];
        }
        
        if ([self.specialKey isEqualToString:@"purify1"]) {
            spell = [[[Purify alloc] initWithTitle:@"PurifyItem" healAmnt:5 energyCost:0 castTime:0 andCooldown:10.0] autorelease];
        }
        
        if ([self.specialKey isEqualToString:@"armor1"]) {
            spell = [[[Spell alloc] initWithTitle:@"Armor" healAmnt:0 energyCost:0 castTime:0 andCooldown:10] autorelease];
            Effect *armor = [[[Effect alloc] initWithDuration:5.0 andEffectType:EffectTypePositiveInvisible] autorelease];
            [armor setDamageTakenMultiplierAdjustment:-.1];
            [armor setTitle:@"armor1-eff"];
            [spell setAppliedEffect:armor];
        }
        
        if ([self.specialKey isEqualToString:@"blast1"]) {
            spell = [[[LightBolt alloc] initWithTitle:@"Bolt1" healAmnt:0 energyCost:0 castTime:0 andCooldown:15.0] autorelease];
        }
        
        if ([self.specialKey isEqualToString:@"aravon1"]) {
            spell = [[[StarsOfAravon alloc] initWithTitle:@"Stars1" healAmnt:0 energyCost:0 castTime:0 andCooldown:15.0] autorelease];
        }
        
        [spell setIsItem:YES];
        [spell setItemSpriteName:self.itemSpriteName];
        return spell;
    }
    return nil;
}

+ (NSArray *)slotPrefixes{
    NSArray *slotPrefix = @[@[@"Cover", @"Hood", @"Shawl", @"Mantle", @"Stole"], //Head
                            @[@"Words", @"Tome", @"Book", @"Libram", @"Codex"], //Weapon
                            @[@"Robe", @"Tunic", @"Garment", @"Vestment", @"Raiment"], //Chest,
                            @[@"Pants", @"Pantaloons", @"Trousers", @"Breeches", @"Leggings"], //Legs,
                            @[@"Boots", @"Sandals", @"Slippers", @"Shoes"], //Boots,
                            @[@"Necklace", @"Pendant", @"Chain", @"Choker"] //Neck
                            ];
    return slotPrefix;
}

+ (NSArray *)suffixes {
    NSArray *suffix = @[@"Light", //+Healing
                        @"Hope", //+Health
                        @"Glory", //+Speed
                        @"Knowledge", //+Regen
                        @"Insight", //+Crit
                        @"Power",
                        @"Solace",
                        @"Radiance",
                        @"Peace",
                        @"Purity",
                        @"Warmth",
                        @"the Sun"];
    return suffix;
}

+ (NSArray *)specialKeys
{
    return @[@"burst1", @"burst2", @"armor1"];
}

+ (NSString *)descriptionForSpecialKey:(NSString *)specialKey
{
    NSDictionary *dict = @{@"burst1" : @"On Use: Heals your target for 100.  15s Cooldown.",
                           @"burst2" : @"On Use: Heals your target for 150.  15s Cooldown.",
                           @"raidheal1" : @"On Use: Heals all allies for 30 over 6 seconds. 30s Cooldown.",
                           @"healbuff1" : @"On Use: Increases your healing done by 25% for 6 seconds. 30s Cooldown.",
                           @"purify1" : @"On Use: Removes all curses and poisons from an ally.  10s Cooldown.",
                           @"armor1" : @"On Use: Reduces the damage taken of target ally by 10% for 5 seconds.  10s Cooldown",
                           @"blast1" : @"On Use: Fire a bolt of light at an enemy dealing 1000 damage. 15s Cooldown.",
                           @"aravon1" : @"On Use: Summons 4 Stars of Aravon from the Heavens.  15s Cooldown."};
    return [dict objectForKey:specialKey];
}

- (NSString *)slotTypeName
{
    switch (self.slot) {
        case SlotTypeWeapon:
            return @"Tome";
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
        case SlotTypeMaximum:
        default:
            break;
    }
    return nil;
}

- (void)itemEarnedWithId:(NSInteger)earnedId
{
    if (!self.earnedItemId) {
        _earnedItemId = earnedId;
    }
}

@end

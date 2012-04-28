//
//  ShopItem.m
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ShopItem.h"

@interface ShopItem ()
@property (nonatomic, retain) Spell *spell;
@end
@implementation ShopItem

@synthesize goldCost, shopSprite, shopDescription, key, spell, title;
+(NSInteger)costForSpell:(NSString*)spell{
    if ([spell isEqualToString:@"Greater Heal"]){
        return 100;
    }
    if ([spell isEqualToString:@"Forked Heal"]){
        return 200;
    }
    if ([spell isEqualToString:@"Regrow"]){
        return 200;
    }
    if ([spell isEqualToString:@"Purify"]){
        return 150;
    }
    if ([spell isEqualToString:@"Barrier"]){
        return 500;
    }
    if ([spell isEqualToString:@"Healing Burst"]){
        return 500;
    }
    if ([spell isEqualToString:@"Light Eternal"]){
        return 600;
    }
    if ([spell isEqualToString:@"Swirling Light"]){
        return 2000;
    }
    if ([spell isEqualToString:@"Orbs of Light"]){
        return 2000;
    }
    return 10000;
}

-(Spell*)purchasedSpell{
    return self.spell;
}

-(NSString*)title{
    return self.spell.title;
}

+(ShopItem*)shopItemWithSpell:(Spell*)spell{
    return [[[ShopItem alloc] initWithSpell:spell] autorelease];
}

-(id)initWithSpell:(Spell*)spll{
    if (self = [super init]){
        self.spell = spll;
        self.shopDescription = [self.spell description];
        key = [self.spell title];
        goldCost = [ShopItem costForSpell:self.spell.title];
    }
    return self;
}
@end
//
//  ShopItem.m
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "ShopItem.h"

@interface ShopItem ()
@property (nonatomic, retain) Spell *spell;
@end
@implementation ShopItem

@synthesize goldCost, shopSprite, shopDescription, key, spell, title;
+(NSInteger)costForSpell:(NSString*)spell{
    
    if ([spell isEqualToString:@"Heal"]) {
        return 0;
    }
    
    if ([spell isEqualToString:@"Greater Heal"]){
        return 25;
    }
    if ([spell isEqualToString:@"Forked Heal"]){
        return 100;
    }
    if ([spell isEqualToString:@"Regrow"]){
        return 75;
    }

    if ([spell isEqualToString:@"Stars of Aravon"]){
        return 300;
    }
    if ([spell isEqualToString:@"Healing Burst"]){
        return 250;
    }
    if ([spell isEqualToString:@"Barrier"]){
        return 300;
    }
    if ([spell isEqualToString:@"Purify"]){
        return 25;
    }
    if ([spell isEqualToString:@"Touch of Hope"]){
        return 300;
    }
    
    
    if ([spell isEqualToString:@"Blessed Armor"]){
        return 500;
    }
    if ([spell isEqualToString:@"Light Eternal"]){
        return 500;
    }
    if ([spell isEqualToString:@"Fading Light"]) {
        return 500;
    }
    if ([spell isEqualToString:@"Sunburst"]){
        return 500;
    }
    if ([spell isEqualToString:@"Swirling Light"]){
        return 500;
    }
    if ([spell isEqualToString:@"Orbs of Light"]){
        return 500;
    }
    
    
    if ([spell isEqualToString:@"Respite"]){
        return 900;
    }
    if ([spell isEqualToString:@"Ward of Ancients"]){
        return 900;
    }
    if ([spell isEqualToString:@"Soaring Spirit"]){
        return 900;
    }
    if ([spell isEqualToString:@"Attunement"]){
        return 900;
    }
    if ([spell isEqualToString:@"Wandering Spirit"]){
        return 900;
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

- (void)dealloc {
    [shopDescription release];
    [spell release];
    [super dealloc];
}
@end

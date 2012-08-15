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
    
    //Tier 1
    //Heal 
    
    //Tier 2
    if ([spell isEqualToString:@"Greater Heal"]){
        return 100;
    }
    if ([spell isEqualToString:@"Purify"]){
        return 10;
    }

    //Tier 3
    if ([spell isEqualToString:@"Forked Heal"]){
        return 200;
    }
    if ([spell isEqualToString:@"Regrow"]){
        return 200;
    }

    //Tier 4
    if ([spell isEqualToString:@"Barrier"]){
        return 300;
    }
    if ([spell isEqualToString:@"Healing Burst"]){
        return 300;
    }
    
    //Tier 5
    if ([spell isEqualToString:@"Light Eternal"]){
        return 300;
    }
    if ([spell isEqualToString:@"Wandering Spirit"]){
        return 300;
    }
    
    //Specials
    if ([spell isEqualToString:@"Respite"]){
        return 500;
    }
    if ([spell isEqualToString:@"Ward of Ancients"]){
        return 500;
    }
    
    //WTF
    if ([spell isEqualToString:@"Swirling Light"]){
        return 750;
    }
    if ([spell isEqualToString:@"Orbs of Light"]){
        return 750;
    }
    if ([spell isEqualToString:@"Touch of Hope"]){
        return 300;
    }
    if ([spell isEqualToString:@"Soaring Spirit"]){
        return 300;
    }
    if ([spell isEqualToString:@"Fading Light"]) {
        return 200;
    }
    if ([spell isEqualToString:@"Sunburst"]){
        return 300;
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

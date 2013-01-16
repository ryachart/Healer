//
//  SpellInfoNode.m
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//

#import "SpellInfoNode.h"
#import "Spell.h"

@interface SpellInfoNode ()
@property (nonatomic, assign) CCSprite *spellIcon;
@property (nonatomic, assign) CCLabelTTF *titleLabel;
@property (nonatomic, assign) CCLabelTTF *itemEnergyCost;
@property (nonatomic, assign) CCLabelTTF *itemDescription;
@property (nonatomic, assign) CCLabelTTF *itemCastTime;
@property (nonatomic, assign) CCLabelTTF *itemCooldown;
@property (nonatomic, assign) CCLabelTTF *itemSpellType;

@end

@implementation SpellInfoNode
-(id)initWithSpell:(Spell*)spell{
    if (self = [super init]){
        CGFloat itemNameFontSize = 20.0;
        
        self.titleLabel = [CCLabelTTF labelWithString:spell.title dimensions:CGSizeMake(180, 40) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:itemNameFontSize];
        [self.titleLabel setColor:ccWHITE];
        [self.titleLabel setPosition:CGPointMake(130, 14)];
        [self.titleLabel setHorizontalAlignment:UITextAlignmentLeft];
        [self addChild:self.titleLabel];
        
        CCSprite *spellIconBack = [CCSprite spriteWithSpriteFrameName:@"spell_icon_back.png"];
        [self addChild:spellIconBack];
        
        self.spellIcon = [CCSprite spriteWithSpriteFrameName:@"unknown-icon.png"];
        
        CCSpriteFrame *spellSpriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[spell spriteFrameName]];
        if (spellSpriteFrame){
            [self.spellIcon setDisplayFrame:spellSpriteFrame];
        }
        [self.spellIcon setPosition:CGPointMake(-2, -5)];
        [self.spellIcon setScale:.75];
        [spellIconBack setPosition:self.spellIcon.position];
        [spellIconBack setScale:self.spellIcon.scale];
        [self addChild:self.spellIcon];
        
        self.itemCooldown = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cooldown: %1.2f%@",spell.cooldown, @"s"] dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        
        self.itemEnergyCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i Mana",spell.energyCost] dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        
        NSString *castTimeString = spell.castTime == 0.0 ? @"Instant Cast" : [NSString stringWithFormat:@"Cast Time: %1.2f%@", spell.castTime, @"s"];
        
        self.itemCastTime = [CCLabelTTF labelWithString:castTimeString dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        self.itemDescription = [CCLabelTTF labelWithString:spell.spellDescription dimensions:CGSizeMake(200, 80) hAlignment:UITextAlignmentLeft fontName:@"TrebuchetMS" fontSize:12.0];
        
        self.itemSpellType = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@", spell.spellTypeDescription] dimensions:CGSizeMake(200, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        
        self.itemEnergyCost.position = CGPointMake(185, 70);
        self.itemCastTime.position = CGPointMake(185, 85);
        self.itemCooldown.position = CGPointMake(283, 70);
        self.itemDescription.position = CGPointMake(140, -26);
        self.itemSpellType.position = CGPointMake(283, 85);
        
        if (spell.cooldown == 0.0) {
            [self.itemCooldown setVisible:NO];
        }
        
//        [self addChild:self.itemEnergyCost];
//        [self addChild:self.itemCooldown];
//        [self addChild:self.itemCastTime];
        [self addChild:self.itemDescription];
//        [self addChild:self.itemSpellType];
        
    }
    return self;
}
@end

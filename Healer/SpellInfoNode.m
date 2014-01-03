//
//  SpellInfoNode.m
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//

#import "SpellInfoNode.h"
#import "Spell.h"
#import "IconDescriptionModalLayer.h"
#import "BasicButton.h"
#import "PreBattleScene.h"


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
    if (self = [super initWithSpriteFrameName:@"spell_info_node_bg.png"]){
        CGFloat itemNameFontSize = 20.0;
        
        self.titleLabel = [CCLabelTTF labelWithString:spell.title dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:itemNameFontSize];
        [self.titleLabel setColor:ccWHITE];
        [self.titleLabel setPosition:CGPointMake(190, 65)];
        [self.titleLabel setHorizontalAlignment:kCCTextAlignmentLeft];
        [self addChild:self.titleLabel];
        
        CCSprite *spellIconBack = [CCSprite spriteWithSpriteFrameName:@"spell_icon_back.png"];
        [self addChild:spellIconBack];
        
        self.spellIcon = [CCSprite spriteWithSpriteFrameName:@"unknown-icon.png"];
        
        CCSpriteFrame *spellSpriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[spell spriteFrameName]];
        if (spellSpriteFrame){
            [self.spellIcon setDisplayFrame:spellSpriteFrame];
        }
        [self.spellIcon setPosition:CGPointMake(48, 45)];
        [self.spellIcon setScale:.75];
        [spellIconBack setPosition:self.spellIcon.position];
        [spellIconBack setScale:self.spellIcon.scale];
        [self addChild:self.spellIcon];
        
        self.itemCooldown = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cooldown: %1.2f%@",spell.cooldown, @"s"] dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        
        self.itemEnergyCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i Mana",spell.energyCost] dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        
        NSString *castTimeString = spell.castTime == 0.0 ? @"Instant Cast" : [NSString stringWithFormat:@"Cast Time: %1.2f%@", spell.castTime, @"s"];
        
        self.itemCastTime = [CCLabelTTF labelWithString:castTimeString dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentLeft fontName:@"Arial" fontSize:12.0];
        self.itemDescription = [CCLabelTTF labelWithString:spell.spellDescription dimensions:CGSizeMake(200, 80) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS" fontSize:12.0];
        
        self.itemSpellType = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@", spell.spellTypeDescription] dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentLeft   fontName:@"Arial" fontSize:12.0];
        
        self.itemEnergyCost.position = CGPointMake(235, 120);
        self.itemCastTime.position = CGPointMake(235, 135);
        self.itemCooldown.position = CGPointMake(334, 120);
        self.itemDescription.position = CGPointMake(190, 24);
        self.itemSpellType.position = CGPointMake(334, 135);
        
        if (spell.cooldown == 0.0) {
            [self.itemCooldown setVisible:NO];
        }
        
        [self addChild:self.itemDescription];
    }
    return self;
}

- (id)initAsEmpty{
    return [self initAsEmpty:NO];
}

- (id)initAsEmpty:(BOOL)locked
{
    if (self = [super initWithSpriteFrameName:@"spell_info_node_bg.png"]){
        CCSprite *spellIconBack = [CCSprite spriteWithSpriteFrameName:@"spell_icon_back.png"];
        [spellIconBack setPosition:CGPointMake(48, 45)];
        [spellIconBack setScale:.75];
        [self addChild:spellIconBack];
        
        if (locked) {
            CCSprite *lockSprite = [CCSprite spriteWithSpriteFrameName:@"lock.png"];
            [lockSprite setPosition:spellIconBack.position];
            [self addChild:lockSprite];
        }
    }
    return self;
}

- (void)setupUnlockButton
{
    BasicButton *button = [BasicButton basicButtonWithTarget:self andSelector:@selector(unlock) andTitle:@"Unlock"];
    [button setScale:.75];
    
    CCMenu *menu = [CCMenu menuWithItems:button, nil];
    [self addChild:menu];
    [menu setPosition:CGPointMake(200, 45)];
}

- (void)unlock
{
    IconDescriptionModalLayer *modalLayer = [[[IconDescriptionModalLayer alloc] initAsMainContentSalesModal] autorelease];
    [modalLayer setDelegate:(PreBattleScene*)self.parent];
    [self.parent addChild:modalLayer z:100];
    
}
@end

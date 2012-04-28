//
//  AddRemoveSpellLayer.m
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "AddRemoveSpellLayer.h"
#import "Spell.h"
#import "Shop.h"

@implementation SpellMenuItemLabel
@synthesize spell;
@end

@interface AddRemoveSpellLayer ()
@property (nonatomic, retain) NSMutableArray *unusedSpells;
@property (nonatomic, retain) NSMutableArray *usedSpells;
@property (nonatomic, retain) CCMenu *unusedSpellsMenu;
@property (nonatomic, retain) CCMenu *usedSpellsMenu;

-(void)configureMenus;
-(void)addSpell:(id)sender;
-(void)removeSpell:(id)sender;
@end

@implementation AddRemoveSpellLayer
@synthesize unusedSpells, usedSpells, unusedSpellsMenu, usedSpellsMenu;
@synthesize delegate;

-(id)initWithCurrentSpells:(NSArray *)spells{
    if (self = [super initWithColor:ccc4(0, 0, 0, 222)]){
        self.unusedSpells = [NSMutableArray arrayWithArray:[Shop allOwnedSpells]];
        [self.unusedSpells removeObjectsInArray:spells];
        
        self.usedSpells = [NSMutableArray arrayWithArray:spells];
        
        CCMenu *dismissButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Dismiss" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(dismiss)], nil];
        [dismissButton setPosition:CGPointMake(900, 700)];
        [self addChild: dismissButton];
        
        [self configureMenus];
        
        CCLabelTTF *inactiveSpellsLabel = [CCLabelTTF labelWithString:@"Inactive Spells:" fontName:@"Arial" fontSize:40.0];
        [inactiveSpellsLabel setPosition:CGPointMake(300, 700)];
        
        
        CCLabelTTF *activeSpellsLabel = [CCLabelTTF labelWithString:@"Active Spells:" fontName:@"Arial" fontSize:40.0];
        [activeSpellsLabel setPosition:CGPointMake(640, 700)];
        
        [self addChild:inactiveSpellsLabel];
        [self addChild:activeSpellsLabel];
        
        CCLayerColor *dividerLine = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
        [dividerLine setContentSize:CGSizeMake(2, 768)];
        [dividerLine setPosition:CGPointMake(490, 0)];
        [self addChild: dividerLine];
    }
    return self;
}

-(void)dismiss{
    if (self.delegate){
        [self.delegate spellSwitchDidCompleteWithActiveSpells:self.usedSpells];
    }
    [self runAction:[CCSequence actions:[CCMoveTo actionWithDuration:.5 position:CGPointMake(-1024, 0)], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];
        }], nil]];
}

-(void)addSpell:(id)sender{
    SpellMenuItemLabel *label = (SpellMenuItemLabel*)sender;
    [label retain];
    Spell *spellToAdd = [label spell];
    
    if (self.usedSpells.count < 4){
        [self.unusedSpells removeObject:spellToAdd];
        [self.usedSpells addObject:spellToAdd];
        [self configureMenus];
    }else{
        
    }
    [label autorelease];
}

-(void)removeSpell:(id)sender{
    SpellMenuItemLabel *label = (SpellMenuItemLabel*)sender;
    [label retain];
    Spell *spellToRemove = [label spell];
    
    if (self.usedSpells.count > 1){
        [self.usedSpells  removeObject:spellToRemove];
        [self.unusedSpells addObject:spellToRemove];
        [self configureMenus];
    }else{
        
    }
    [label autorelease];
}

-(void)configureMenus{
    if (!self.unusedSpellsMenu){
        self.unusedSpellsMenu = [CCMenu menuWithItems: nil];
        [self.unusedSpellsMenu setPosition:CGPointMake(300, 400)];
        [self addChild:self.unusedSpellsMenu];
    }
    
    if (!self.usedSpellsMenu){
        self.usedSpellsMenu = [CCMenu menuWithItems: nil];
        [self.usedSpellsMenu setPosition:CGPointMake(600, 400)];
        [self addChild:self.usedSpellsMenu];
    }
    
    [self.unusedSpellsMenu  removeAllChildrenWithCleanup:YES];
    [self.usedSpellsMenu removeAllChildrenWithCleanup:YES];
    
    for (Spell *spell in self.unusedSpells){
        SpellMenuItemLabel *itemLabel = [[SpellMenuItemLabel alloc] initWithTarget:self selector:@selector(addSpell:)];
        [itemLabel setLabel:[CCLabelTTF labelWithString:spell.title fontName:@"Arial" fontSize:32.0]];
        [itemLabel setSpell:spell];
        [self.unusedSpellsMenu addChild:itemLabel];
        [itemLabel release];
    }
    
    [self.unusedSpellsMenu alignItemsVertically];
    
    for (Spell *spell in self.usedSpells){
        SpellMenuItemLabel *itemLabel = [[SpellMenuItemLabel alloc] initWithTarget:self selector:@selector(removeSpell:)];
        [itemLabel setLabel:[CCLabelTTF labelWithString:spell.title fontName:@"Arial" fontSize:32.0]];
        [itemLabel setSpell:spell];
        [self.usedSpellsMenu addChild:itemLabel];
        [itemLabel release];
    }
    
    [self.usedSpellsMenu alignItemsVertically];
}

@end

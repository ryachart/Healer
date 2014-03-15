//
//  AddRemoveSpellLayer_iPhone.m
//  Healer
//
//  Created by Ryan Hart on 3/3/14.
//  Copyright 2014 Ryan Hart Games. All rights reserved.
//

#import "AddRemoveSpellLayer_iPhone.h"
#import "PlayerDataManager.h"
#import "Shop.h"
#import "ShopItem.h"
#import "ShopItemNode.h"
#import "BasicButton.h"

@interface AddRemoveSpellLayer_iPhone ()
@property (nonatomic, assign) CCTableView *spellsTableView;
@property (nonatomic, retain) NSMutableArray *activeSpellSprites;
@property (nonatomic, assign) CCMenu *closeMenu;

@end

@implementation AddRemoveSpellLayer_iPhone

- (void)dealloc
{
    [_activeSpellSprites release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.closeMenu = [BasicButton basicButtonMenuWithTarget:self selector:@selector(dismiss) title:@"CLOSE" scale:.75];
        [self.closeMenu setPosition:CGPointMake(160, SCREEN_HEIGHT - 35)];
        [self addChild:self.closeMenu];
        
        CCLayerColor *backdrop = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 255)];
        [self addChild:backdrop z:-99];
        
        self.spellsTableView = [[[CCTableView alloc] initWithViewSize:CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT - 100)] autorelease];
        self.spellsTableView.verticalFillOrder = SWTableViewFillTopDown;
        [self.spellsTableView setPosition:CGPointMake(SCREEN_WIDTH * .075, 0)];
        [self addChild:self.spellsTableView];
        self.spellsTableView.contentSize = CGSizeMake(SCREEN_WIDTH, 2000);
        [self.spellsTableView setDataSource:self];
        [self.spellsTableView setDelegate:self];
        
        [self configureActiveSpells];
    }
    return self;
}

- (void)dismiss
{
    [[PlayerDataManager localPlayer] saveLocalPlayer];
    [self removeFromParentAndCleanup:YES];
}

- (void)onEnter
{
    [super onEnter];
    [self.spellsTableView reloadData];
    [self.spellsTableView scrollToTopAnimated:NO];
    
    [[CCDirectorIOS sharedDirector].touchDispatcher addTargetedDelegate:self priority:kCCMenuHandlerPriority -1 swallowsTouches:YES];
    [self.closeMenu setHandlerPriority:kCCMenuHandlerPriority - 2];
}

- (void)onExit{
    [[CCDirectorIOS sharedDirector].touchDispatcher removeDelegate:self];
    [super onExit];
}

- (void)configureActiveSpells
{
    for (CCSprite *sprite in self.activeSpellSprites) {
        [sprite removeFromParentAndCleanup:YES];
    }
    [self.activeSpellSprites removeAllObjects];
    
    int spellCount = 0;
    float scale = .6;
    NSArray *currentPlayersActiveSpells = [PlayerDataManager localPlayer].lastUsedSpells;
    for (Spell *spell in currentPlayersActiveSpells){
        CCSprite *spellSprite = [CCSprite spriteWithSpriteFrameName:spell.spriteFrameName];
        [self addChild:spellSprite];
        [spellSprite setScale:scale];
        [spellSprite setPosition:CGPointMake(70 * spellCount + 50, SCREEN_HEIGHT - 100)];
        [self.activeSpellSprites addObject:spellSprite];
        spellCount ++;
    }
    
    int unusedSpellSlots = 4 - currentPlayersActiveSpells.count;
    for (int i = 0; i < unusedSpellSlots; i++) {
        CCSprite *emptySlotSprite = [CCSprite spriteWithSpriteFrameName:@"spell_icon_back.png"];
        [self addChild:emptySlotSprite];
        [emptySlotSprite setScale:scale];
        [emptySlotSprite setPosition:CGPointMake(70 * spellCount + 50, SCREEN_HEIGHT - 100)];
        [self.activeSpellSprites addObject:emptySlotSprite];
        spellCount++;
    }
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self.spellsTableView ccTouchBegan:touch withEvent:event];
    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self.spellsTableView ccTouchMoved:touch withEvent:event];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self.spellsTableView ccTouchEnded:touch withEvent:event];
}

- (CGSize)cellSizeForTable:(CCTableView *)table
{
    return CGSizeMake(SCREEN_WIDTH - 20, 80);
}

- (CCTableViewCell*)table:(CCTableView *)table cellAtIndex:(NSUInteger)idx
{
    CCTableViewSpriteCell *availableCell = (CCTableViewSpriteCell*)[table dequeueCell];
    
    if (!availableCell) {
        availableCell = [[[CCTableViewSpriteCell alloc] init] autorelease];
    }
    NSInteger spellNumber = idx;
    ShopItem *purchasedItem = [[[PlayerDataManager localPlayer] purchasedItems] objectAtIndex:spellNumber];
    ShopItemNode *node = [[[ShopItemNode alloc] initForIphoneWithShopItem:purchasedItem] autorelease];
    
    [availableCell setSprite:node];
    
    return availableCell;
}

- (NSUInteger)numberOfCellsInTableView:(CCTableView *)table
{
    return [[PlayerDataManager localPlayer] purchasedItems].count;
}

- (void)table:(CCTableView *)table cellTouched:(CCTableViewCell *)cell
{
    NSInteger spellNumber = cell.idx;
    Spell *selectedSpell = [[[[PlayerDataManager localPlayer] purchasedItems] objectAtIndex:spellNumber] purchasedSpell];
    NSMutableArray *usedSpells = [NSMutableArray arrayWithArray:[PlayerDataManager localPlayer].lastUsedSpells];
    
    NSArray *currentPlayersActiveSpells = [PlayerDataManager localPlayer].lastUsedSpells;
    BOOL removed = false;
    for (Spell *spell in currentPlayersActiveSpells) {
        if ([spell.spellID isEqualToString:selectedSpell.spellID]) {
            [usedSpells removeObject:spell];
            removed = true;
        }
    }
    
    if (!removed &&  usedSpells.count < [PlayerDataManager localPlayer].maximumStandardSpellSlots) {
        [usedSpells addObject:selectedSpell];
    }
    [[PlayerDataManager localPlayer] setUsedSpells:usedSpells];
    
    
    [self configureActiveSpells];
}

@end

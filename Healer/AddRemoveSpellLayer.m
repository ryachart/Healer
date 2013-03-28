//
//  AddRemoveSpellLayer.m
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//

#import "AddRemoveSpellLayer.h"
#import "Spell.h"
#import "Shop.h"
#import "PlayerDataManager.h"
#import "DraggableSpellIcon.h"
#import "BasicButton.h"
#import "BackgroundSprite.h"

@interface AddRemoveSpellLayer ()
@property (nonatomic, retain) NSMutableArray *unusedSpells;
@property (nonatomic, retain) NSMutableArray *usedSpells;
@property (nonatomic, retain) DraggableSpellIcon *draggingSprite;
@property (nonatomic, retain) NSMutableArray *spellSlots;
@property (nonatomic, retain) NSMutableDictionary *ownedSpellSlots;
@property (nonatomic, assign) CCMenu *dismissButton;
@property (nonatomic, assign) BackgroundSprite *unusedBoard;
@end

@implementation AddRemoveSpellLayer

- (void)dealloc {
    [_unusedSpells release];
    [_usedSpells release];
    [_draggingSprite release];
    [_spellSlots release];
    [_ownedSpellSlots release];
    [super dealloc];
}

-(id)initWithCurrentSpells:(NSArray *)spells{
    if (self = [super init]){
        
        self.unusedBoard = [[[BackgroundSprite alloc] initWithAssetName:@"over-paper"] autorelease];
        [self addChild:self.unusedBoard];
        
        CCSprite *libraryText = [CCSprite spriteWithSpriteFrameName:@"library_text.png"];
        [libraryText setPosition:CGPointMake(300, 680)];
        [self.unusedBoard addChild:libraryText];
        
//        CCLabelTTF *spellsLabel = [CCLabelTTF labelWithString:@"Knowledge" dimensions:CGSizeMake(300, 200) hAlignment:UITextAlignmentCenter fontName:@"Cochin-BoldItalic" fontSize:64.0];
//        [spellsLabel setPosition:CGPointMake(200, 580)];
//        [spellsLabel setColor:ccc3(88, 54, 22)];
//        [self.unusedBoard addChild:spellsLabel];
        
        self.unusedSpells = [NSMutableArray arrayWithArray:[[PlayerDataManager localPlayer] allOwnedSpells]];
        [self.unusedSpells removeObjectsInArray:spells];
        
        self.usedSpells = [NSMutableArray arrayWithArray:spells];
        
        self.dismissButton = [CCMenu menuWithItems:[BasicButton basicButtonWithTarget:self andSelector:@selector(dismiss) andTitle:@"Apply"], nil];
        [self.dismissButton setPosition:CGPointMake(900, 50)];
        [self addChild: self.dismissButton];
                
//        CCLabelTTF *inactiveSpellsLabel = [CCLabelTTF labelWithString:@"Library" fontName:@"Arial" fontSize:40.0];
//        [inactiveSpellsLabel setPosition:CGPointMake(350, 690)];
//        
//        CCLabelTTF *activeSpellsLabel = [CCLabelTTF labelWithString:@"Memorized" fontName:@"Arial" fontSize:40.0];
//        [activeSpellsLabel setPosition:CGPointMake(850, 690)];
//        
//        [self addChild:inactiveSpellsLabel];
//        [self addChild:activeSpellsLabel];
        
//        CCLayerColor *dividerLine = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
//        [dividerLine setContentSize:CGSizeMake(2, 768)];
//        [dividerLine setPosition:CGPointMake(710, 0)];
//        [self addChild: dividerLine];
        
        const float iconScale = .75;
        
        self.ownedSpellSlots = [NSMutableDictionary dictionaryWithCapacity:20];
        int j = 0;
        for (Spell *spell in [[PlayerDataManager localPlayer] allOwnedSpells]){
            DraggableSpellIcon *inhabitant = nil;
            if (![self.usedSpells containsObject:spell]){
                inhabitant = [[[DraggableSpellIcon alloc] initWithSpell:spell] autorelease];
            }
            Slot *spellSlot = [[[Slot alloc] initWithInhabitantOrNil:inhabitant] autorelease];
            spellSlot.scale = iconScale;
            CCSpriteFrame *spellIcon = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spell.spriteFrameName];
            if (!spellIcon){
                spellIcon = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"unknown-icon.png"];
            }
            
            [spellSlot setDefaultInhabitant:[CCSprite spriteWithSpriteFrame:spellIcon]];
            [spellSlot setTitle:spell.title];
            [spellSlot setDelegate:self];
            [spellSlot setPosition:CGPointMake((180 + (110 * (j % 5))) * iconScale, (700 - (140 * (j / 5))) * iconScale)];
            [self.unusedBoard addChild:spellSlot];
            
            [self.ownedSpellSlots setObject:spellSlot forKey:spell.title];
            j++;
        }
        
        self.spellSlots = [NSMutableArray arrayWithCapacity:4];
        for (int i = 0; i < 4; i++){
            DraggableSpellIcon *inhabitant = nil;
            if (self.usedSpells.count > i){
                Spell *spell = [self.usedSpells objectAtIndex:i];
                inhabitant = [[[DraggableSpellIcon alloc] initWithSpell:spell] autorelease];
            }
            Slot *spellSlot = [[[Slot alloc] initWithInhabitantOrNil:inhabitant] autorelease];
            spellSlot.scale = iconScale;
            [spellSlot setDelegate:self];
            [spellSlot setPosition:CGPointMake(695, 553.5 - (95 * i))];
            [self addChild:spellSlot];
            [self.spellSlots addObject:spellSlot];
        }

    }
    return self;
}

- (void)onEnter {
    [super onEnter];
    [[CCDirector sharedDirector].touchDispatcher addTargetedDelegate:self priority:kCCMenuHandlerPriority - 100 swallowsTouches:YES];
    [self.dismissButton setHandlerPriority:kCCMenuHandlerPriority - 101];
    self.unusedBoard.position = CGPointMake(-self.unusedBoard.contentSize.width, 0);
    
    [self.unusedBoard runAction:[CCMoveTo actionWithDuration:.33 position:CGPointZero]];
}

- (void)onExit {
    [super onExit];
    [[CCDirector sharedDirector].touchDispatcher removeDelegate:self];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    NSArray *childs = [self.children getNSArray];
    NSArray *childrenAndSubchildren = [childs arrayByAddingObjectsFromArray:[self.unusedBoard.children getNSArray]];
    for (CCNode *child in childrenAndSubchildren){
        if ([child isKindOfClass:[Slot class]]){
            Slot *slotChild = (Slot*)child;
            CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
            CGRect layerRect =  [slotChild boundingBox];
            CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
            if (CGRectContainsPoint(layerRect, convertedToNodeSpacePoint)){
                if (slotChild.inhabitant){
                    self.draggingSprite = (DraggableSpellIcon*)[slotChild inhabitantRemovedForDragging];
                    [self.draggingSprite setAnchorPoint:CGPointMake(.5, .5)];
                    [self addChild:self.draggingSprite];
                    [self.draggingSprite setPosition:slotChild.position];
                }
            }
        }
    }
    
    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.draggingSprite){
        CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
        [self.draggingSprite setPosition:touchLocation];
    }
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    //Cancelled is the same as ended for us...
    [self ccTouchEnded:touch withEvent:event];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL droppedIntoSlot = NO;
    for (Slot *slotChild in self.spellSlots){
            if ([slotChild canDropIntoSlotFromRect:self.draggingSprite.boundingBox]){
                [self.draggingSprite removeFromParentAndCleanup:YES];
                [slotChild dropInhabitant:self.draggingSprite];
                self.draggingSprite = nil;
                droppedIntoSlot = YES;
                break;
            }
    }
    if (!droppedIntoSlot){
        Slot *defaultSlot = [self.ownedSpellSlots objectForKey:self.draggingSprite.spell.title];
        [self.draggingSprite removeFromParentAndCleanup:YES];
        [defaultSlot dropInhabitant:self.draggingSprite];
        self.draggingSprite = nil;
    }
    
    if (self.draggingSprite){
        [self.draggingSprite removeFromParentAndCleanup:YES];
        self.draggingSprite = nil;
    }
    [self spellsChanged];
}

- (void)spellsChanged
{
    if (self.delegate){
        int inactives[4] = {0,0,0,0};
        NSMutableArray *newUsedSpells = [NSMutableArray arrayWithCapacity:4];
        for (int i = 0; i < self.spellSlots.count; i++){
            Slot *slot = [self.spellSlots objectAtIndex:i];
            if (slot.inhabitant){
                DraggableSpellIcon *inhabitant = (DraggableSpellIcon*)slot.inhabitant;
                [newUsedSpells addObject:inhabitant.spell];
            } else {
                inactives[i] = 1;
            }
        }
        [[PlayerDataManager localPlayer] setUsedSpells:newUsedSpells];
        [self.delegate spellSwitchDidChangeToActiveSpells:newUsedSpells andInactiveIndexes:inactives];
    }
}

-(void)dismiss{
    if (self.delegate){
        int inactives[4] = {0,0,0,0};
        NSMutableArray *newUsedSpells = [NSMutableArray arrayWithCapacity:4];
        for (int i = 0; i < self.spellSlots.count; i++){
            Slot *slot = [self.spellSlots objectAtIndex:i];
            if (slot.inhabitant){
                DraggableSpellIcon *inhabitant = (DraggableSpellIcon*)slot.inhabitant;
                [newUsedSpells addObject:inhabitant.spell];
            } else {
                inactives[i] = 1;
            }
        }
        [[PlayerDataManager localPlayer] setUsedSpells:newUsedSpells];
        [self.delegate spellSwitchDidCompleteWithActiveSpells:newUsedSpells andInactiveIndexes:inactives];
    }
    
    float dismissDuration = .33;
    [self.unusedBoard runAction:[CCMoveTo actionWithDuration:dismissDuration position:CGPointMake(-self.unusedBoard.contentSize.width, 0)]];

    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:dismissDuration], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];
        }], nil]];
}

#pragma mark - Slot Delegate

- (void)slotDidEmpty:(Slot *)slot {
    
}

@end

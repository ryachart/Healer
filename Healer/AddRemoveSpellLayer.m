//
//  AddRemoveSpellLayer.m
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//

#import "AddRemoveSpellLayer.h"
#import "Spell.h"
#import "Shop.h"
#import "PersistantDataManager.h"
#import "DraggableSpellIcon.h"

@interface AddRemoveSpellLayer ()
@property (nonatomic, retain) NSMutableArray *unusedSpells;
@property (nonatomic, retain) NSMutableArray *usedSpells;
@property (nonatomic, retain) DraggableSpellIcon *draggingSprite;
@property (nonatomic, retain) NSMutableArray *spellSlots;
@property (nonatomic, retain) NSMutableDictionary *ownedSpellSlots;
@property (nonatomic, assign) CCMenu *dismissButton;
@end

@implementation AddRemoveSpellLayer
@synthesize unusedSpells, usedSpells;
@synthesize delegate;

- (void)dealloc {
    [unusedSpells release];
    [usedSpells release];
    [_draggingSprite release];
    [_spellSlots release];
    [_ownedSpellSlots release];
    [super dealloc];
}

-(id)initWithCurrentSpells:(NSArray *)spells{
    if (self = [super initWithColor:ccc4(0, 0, 0, 222)]){
        self.unusedSpells = [NSMutableArray arrayWithArray:[Shop allOwnedSpells]];
        [self.unusedSpells removeObjectsInArray:spells];
        
        self.usedSpells = [NSMutableArray arrayWithArray:spells];
        
        self.dismissButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Dismiss" fontName:@"Arial" fontSize:32.0] target:self selector:@selector(dismiss)], nil];
        [self.dismissButton setPosition:CGPointMake(920, 740)];
        [self addChild: self.dismissButton];
                
        CCLabelTTF *inactiveSpellsLabel = [CCLabelTTF labelWithString:@"Library" fontName:@"Arial" fontSize:40.0];
        [inactiveSpellsLabel setPosition:CGPointMake(350, 690)];
        
        CCLabelTTF *activeSpellsLabel = [CCLabelTTF labelWithString:@"Memorized" fontName:@"Arial" fontSize:40.0];
        [activeSpellsLabel setPosition:CGPointMake(850, 690)];
        
        [self addChild:inactiveSpellsLabel];
        [self addChild:activeSpellsLabel];
        
        CCLayerColor *dividerLine = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
        [dividerLine setContentSize:CGSizeMake(2, 768)];
        [dividerLine setPosition:CGPointMake(710, 0)];
        [self addChild: dividerLine];
        
        self.ownedSpellSlots = [NSMutableDictionary dictionaryWithCapacity:20];
        int j = 0;
        for (Spell *spell in [Shop allOwnedSpells]){
            DraggableSpellIcon *inhabitant = nil;
            if (![self.usedSpells containsObject:spell]){
                inhabitant = [[[DraggableSpellIcon alloc] initWithSpell:spell] autorelease];
            }
            Slot *spellSlot = [[[Slot alloc] initWithInhabitantOrNil:inhabitant] autorelease];
            CCSpriteFrame *spellIcon = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spell.spriteFrameName];
            if (!spellIcon){
                spellIcon = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"unknown-icon.png"];
            }
            
            [spellSlot setDefaultInhabitant:[CCSprite spriteWithSpriteFrame:spellIcon]];
            [spellSlot setTitle:spell.title];
            [spellSlot setDelegate:self];
            [spellSlot setPosition:CGPointMake(130 + (110 * (j % 5)), 610 - (140 * (j / 5)))];
            [self addChild:spellSlot];
            
            [self.ownedSpellSlots setObject:spellSlot forKey:spell.title];
            j++;
        }
        
        self.spellSlots = [NSMutableArray arrayWithCapacity:4];
        for (int i = 0; i < 4; i++){
            DraggableSpellIcon *inhabitant = nil;
            NSString *accessoryTitle = @"Empty";
            if (self.usedSpells.count > i){
                Spell *spell = [self.usedSpells objectAtIndex:i];
                inhabitant = [[[DraggableSpellIcon alloc] initWithSpell:spell] autorelease];
                accessoryTitle = spell.title;
            }
            Slot *spellSlot = [[[Slot alloc] initWithInhabitantOrNil:inhabitant] autorelease];
            [spellSlot setDelegate:self];
            [spellSlot setPosition:CGPointMake(800, 550 - (105 * i))];
            [spellSlot setAccessoryTitle:accessoryTitle];
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
}

- (void)onExit {
    [super onExit];
    [[CCDirector sharedDirector].touchDispatcher removeDelegate:self];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    for (CCNode *child in self.children){
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
                    if ([self.spellSlots containsObject:slotChild]){
                        slotChild.accessoryTitle = @"Empty";
                    }
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
                slotChild.accessoryTitle = self.draggingSprite.spell.title;
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
}

-(void)dismiss{
    if (self.delegate){
        NSMutableArray *newUsedSpells = [NSMutableArray arrayWithCapacity:4];
        for (Slot *slot in self.spellSlots){
            if (slot.inhabitant){
                DraggableSpellIcon *inhabitant = (DraggableSpellIcon*)slot.inhabitant;
                [newUsedSpells addObject:inhabitant.spell];
            }
        }
        [PlayerDataManager setUsedSpells:newUsedSpells];
        [self.delegate spellSwitchDidCompleteWithActiveSpells:newUsedSpells];
    }
    [self runAction:[CCSequence actions:[CCMoveTo actionWithDuration:.5 position:CGPointMake(-1024, 0)], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];
        }], nil]];
}

#pragma mark - Slot Delegate

- (void)slotDidEmpty:(Slot *)slot {
    
}

@end

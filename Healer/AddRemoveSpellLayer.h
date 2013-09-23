//
//  AddRemoveSpellLayer.h
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//

#import "cocos2d.h"
#import "Slot.h"
@class Spell;

@protocol SpellSwitchDelegate <NSObject>

- (void)spellSwitchDidChangeToActiveSpells:(NSArray *)actives andInactiveIndexes:(int[])inactives;
- (void)spellSwitchDidCompleteWithActiveSpells:(NSArray*)actives andInactiveIndexes:(int[])inactives;

@end

@interface AddRemoveSpellLayer : CCLayer <SlotDelegate>
@property (nonatomic, assign) id<SpellSwitchDelegate> delegate;
-(id)initWithCurrentSpells:(NSArray*)spells;

@end

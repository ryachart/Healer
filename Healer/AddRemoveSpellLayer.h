//
//  AddRemoveSpellLayer.h
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//

#import <cocos2d.h>
#import "Slot.h"
@class Spell;

@protocol SpellSwitchDelegate <NSObject>

-(void)spellSwitchDidCompleteWithActiveSpells:(NSArray*)actives;

@end

@interface AddRemoveSpellLayer : CCLayerColor <SlotDelegate>
@property (nonatomic, assign) id<SpellSwitchDelegate> delegate;
-(id)initWithCurrentSpells:(NSArray*)spells;

@end

//
//  AddRemoveSpellLayer.h
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
@class Spell;

@protocol SpellSwitchDelegate <NSObject>

-(void)spellSwitchDidCompleteWithActiveSpells:(NSArray*)actives;

@end

@interface SpellMenuItemLabel : CCMenuItemLabel
@property (nonatomic, retain) Spell *spell;
@end

@interface AddRemoveSpellLayer : CCLayerColor
@property (nonatomic, assign) id<SpellSwitchDelegate> delegate;
-(id)initWithCurrentSpells:(NSArray*)spells;

@end

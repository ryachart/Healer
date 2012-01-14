//
//  PlayerSpellButton.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameObjects.h"
#import "cocos2d.h"

@class PlayerSpellButtonDelegate;
@class Chargable;
@interface PlayerSpellButton : CCLayerColor {
	Spell *spellData;
	
	CCLabelTTF *spellTitle;
	
	PlayerSpellButtonDelegate *interactionDelegate;
}
@property (nonatomic, retain, setter=setSpellData:) Spell *spellData;
@property (retain) PlayerSpellButtonDelegate *interactionDelegate;

-(void)setSpellData:(Spell*)theSpell;
-(void)updateUI;
@end

@protocol PlayerSpellButtonDelegate

-(void)spellButtonSelected:(PlayerSpellButton*)spell;
-(void)spellButtonUnselected:(PlayerSpellButton*)spell;

@end
//
//  SpellView.h
//  RaidLeader
//
//  Created by Ryan Hart on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Spell.h"

@interface SpellView : UIView {
	Spell *spellToDisplay;
	
	UILabel *spellNameView;
}
@property (nonatomic, retain, readwrite, setter=setSpellToDisplay:) Spell *spellToDisplay;
@property (nonatomic, retain) UILabel *spellNameView;

-(void)setSpellToDisplay:(Spell*)spell;

@end

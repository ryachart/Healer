//
//  SelectedSpellView.h
//  RaidLeader
//
//  Created by Ryan Hart on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Spell.h"
#import "SpellView.h"

@interface SelectedSpellView : UIView {
	NSMutableArray *spellsSelected;
	NSInteger nextRect;
	
}

-(void)addSpell:(Spell*)spellToAdd;
-(void)removeSpell:(Spell*)spellToRemove;
-(BOOL)containsSpell:(Spell*)spellToCheck;

-(CGRect)nextRectForSpell;

@end

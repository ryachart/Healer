//
//  SelectedSpellView.m
//  RaidLeader
//
//  Created by Ryan Hart on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SelectedSpellView.h"


@implementation SelectedSpellView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		nextRect = 0;
		spellsSelected = [[NSMutableArray alloc] initWithCapacity:4];
    }
    return self;
}

-(void)awakeFromNib{
	nextRect = 0;
	spellsSelected = [[NSMutableArray alloc] initWithCapacity:4];
}

-(CGRect)nextRectForSpell{
	CGPoint origin = {0,0};
	CGSize size = {0, 0};
	
	origin.x = ((CGRectGetWidth(self.frame) * .04)) + ((CGRectGetWidth(self.frame) * .2) * nextRect);
	origin.y = CGRectGetHeight(self.frame) * .04;
	
	size.width =  (CGRectGetWidth(self.frame) * .2);
	size.height = CGRectGetHeight(self.frame) * .92;
	
	return CGRectMake(origin.x, origin.y, size.width, size.height);
}

-(void)addSpell:(Spell*)spellToAdd{
	if (nextRect == 4){
		return;
	}
	
	if (![self containsSpell:spellToAdd]){
		[spellsSelected addObject:spellToAdd];
		SpellView *sv = [[SpellView alloc] initWithFrame:[self nextRectForSpell]];
		[sv setSpellToDisplay:spellToAdd];
		[self addSubview:sv];
		[sv release];
		nextRect++;
	}
	else {
		UIAlertView *alreadySelectedWarning = [[UIAlertView alloc] initWithTitle:@"Already chosen" message:@"You already chose that!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alreadySelectedWarning show];
		[alreadySelectedWarning release];
	}

	
}

-(void)removeSpell:(Spell*)spellToRemove{
	if (nextRect == 0){
		return;
	}
	
	if ([self containsSpell:spellToRemove]){
		for (Spell *spell in spellsSelected){
			if ([[spell title] isEqualToString:[spellToRemove title]]){
				[spellsSelected removeObject:spell];
				for (SpellView *sv in [self subviews]){
					if ([[[sv spellToDisplay] title] isEqualToString:[spellToRemove title]]){
						[sv removeFromSuperview];
					}
					
				}
				nextRect--;
				return;
			}
		}
		
	}
	
}

-(BOOL)containsSpell:(Spell*)spellToCheck{
	if ([spellsSelected count] == 0){
		return NO;
	}
	
	for (Spell *spell in spellsSelected){
		if ([[spell title] isEqualToString:[spellToCheck title]]){
			return YES;
		}
	}
	
	return NO;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [super dealloc];
}


@end

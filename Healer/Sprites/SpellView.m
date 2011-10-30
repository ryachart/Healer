//
//  SpellView.m
//  RaidLeader
//
//  Created by Ryan Hart on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SpellView.h"


@implementation SpellView
@synthesize spellToDisplay, spellNameView;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		
		spellNameView = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)*.4, CGRectGetWidth(frame), CGRectGetHeight(frame)*.2)];
		[spellNameView setBackgroundColor:[UIColor blueColor]];
		[spellNameView setFont:[UIFont systemFontOfSize:10]];
		[self setBackgroundColor:[UIColor whiteColor]];
		[self addSubview:spellNameView];
    }
    return self;
}

-(void)setSpellToDisplay:(Spell*)spell{
	spellToDisplay = spell;
	[spellNameView setText:[spell title]];
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

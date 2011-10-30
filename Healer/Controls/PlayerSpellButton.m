//
//  PlayerSpellButton.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerSpellButton.h"


@implementation PlayerSpellButton

@synthesize spellData, interactionDelegate;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib{
	//NSLog(@"AwakeFromnib: %1.2f", CGRectGetWidth(self.frame));
	spellTitle = [[UILabel alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)*.2)];
	[spellTitle setFont:[UIFont	 systemFontOfSize:12]];
	//NSLog(@"Spell Title is %@", [spellData title]);
	[spellTitle setText:[spellData title]];
	[self addSubview:spellTitle];
}

-(void)setSpellData:(Spell*)theSpell{
	spellData = theSpell;
	if (spellData == nil)
		[self setHidden:YES];
	else{
		NSLog(@"Spell Title is %@", [spellData title]);
		[spellTitle setText:[spellData title]];
	}
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)updateUI{
	if ([spellData conformsToProtocol:@protocol(Chargable)]){
		if ([(Chargable*)spellData currentChargeTime] >= [(Chargable*)spellData maxChargeTime]){
			[self setBackgroundColor:[UIColor greenColor]];
		}
	}
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[interactionDelegate spellButtonSelected:self];
	
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[interactionDelegate spellButtonUnselected:self];
}
- (void)dealloc {
    [super dealloc];
}


@end

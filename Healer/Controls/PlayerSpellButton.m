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

- (id)init{
    if (self = [super init]) {
        // Initialization code
        spellTitle = [[CCLabelTTF alloc] initWithString:[spellData title] fontName:@"Arial" fontSize:14.0f];
        //NSLog(@"Spell Title is %@", [spellData title]);
        [self addChild:spellTitle];
    }
    return self;
}

-(void)setSpellData:(Spell*)theSpell{
	spellData = theSpell;
	if (spellData == nil)
		[self setVisible:NO];
	else{
		NSLog(@"Spell Title is %@", [spellData title]);
		[spellTitle setString:[spellData title]];
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
			[self setColor:ccc3(0, 1, 0)];
		}
	}
}


-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[interactionDelegate spellButtonSelected:self];
	
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[interactionDelegate spellButtonUnselected:self];
}
- (void)dealloc {
    [super dealloc];
}


@end

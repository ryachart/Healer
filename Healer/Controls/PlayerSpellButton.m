//
//  PlayerSpellButton.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerSpellButton.h"


@implementation PlayerSpellButton

@synthesize spellData, interactionDelegate, spellTitle;

- (id)initWithFrame:(CGRect)frame{
    if (self = [super init]) {
        self.position = frame.origin;
        self.contentSize = frame.size;
        [self setOpacity:255];
        self.isTouchEnabled = YES;
        [self setColor:ccc3(111, 111, 111)];
        // Initialization code
        self.spellTitle = [[[CCLabelTTF alloc] initWithString:[spellData title] fontName:@"Arial" fontSize:14.0f] autorelease];
        [self.spellTitle setPosition:CGPointMake(50, 25)];
        [self addChild:spellTitle];
    }
    return self;
}

-(void)setSpellData:(Spell*)theSpell{
	[spellData release];
    spellData = [theSpell retain];
	if (spellData == nil)
		[self setVisible:NO];
	else{
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
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    CGRect layerRect =  [self boundingBox];
    layerRect.origin = CGPointZero;
    CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
    
    if (interactionDelegate != nil && CGRectContainsPoint(layerRect, convertedToNodeSpacePoint)){
        [interactionDelegate spellButtonSelected:self];
        [self setColor:ccc3(255, 0, 255)];
    }
	
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[interactionDelegate spellButtonUnselected:self];
    [self setColor:ccc3(111, 111, 111)];
}
- (void)dealloc {
    [super dealloc];
}


@end

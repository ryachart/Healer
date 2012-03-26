//
//  PlayerSpellButton.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerSpellButton.h"

@interface PlayerSpellButton ()
@property (nonatomic, assign) CCLayerColor *cooldownCountLayer;
@end

@implementation PlayerSpellButton

@synthesize spellData, interactionDelegate, spellTitle, cooldownCountLayer;

- (id)initWithFrame:(CGRect)frame{
    if (self = [super init]) {
        self.position = frame.origin;
        self.contentSize = frame.size;
        [self setOpacity:255];
        self.isTouchEnabled = YES;
        [self setColor:ccc3(111, 111, 111)];
        // Initialization code
        
        self.cooldownCountLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 175)];
        [self.cooldownCountLayer setContentSize:frame.size];
        [self.cooldownCountLayer setVisible:NO];
        
        self.spellTitle = [[[CCLabelTTF alloc] initWithString:[spellData title] fontName:@"Arial" fontSize:14.0f] autorelease];
        [self.spellTitle setPosition:CGPointMake(50, 25)];
        [self addChild:spellTitle];
        
        [self addChild:self.cooldownCountLayer z:10];
        
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

-(void)updateUI{
	if ([spellData conformsToProtocol:@protocol(Chargable)]){
		if ([(Chargable*)spellData currentChargeTime] >= [(Chargable*)spellData maxChargeTime]){
			[self setColor:ccc3(0, 1, 0)];
		}
	}
    if ([spellData cooldownRemaining] > 0){
        [self.cooldownCountLayer setVisible:YES];
        [self.cooldownCountLayer setContentSize:CGSizeMake(self.cooldownCountLayer.contentSize.width, self.contentSize.height * ([spellData cooldownRemaining]/[spellData cooldown]))];
    }else if ([self.cooldownCountLayer visible]){
        [self.cooldownCountLayer setVisible:NO];
        [self.cooldownCountLayer setContentSize:self.contentSize];
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

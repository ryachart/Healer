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
@property (nonatomic, assign) CCSprite *spellIconSprite;
@property (nonatomic, assign) CCSprite *pressedSprite;
@end

@implementation PlayerSpellButton

@synthesize spellData, interactionDelegate, spellTitle, cooldownCountLayer;

- (id)initWithFrame:(CGRect)frame{
    if (self = [super init]) {
        self.position = frame.origin;
        self.contentSize = frame.size;
        self.isTouchEnabled = YES;
        // Initialization code
        
        self.spellIconSprite = [CCSprite spriteWithSpriteFrameName:@"unknown-icon.png"];
        [self.spellIconSprite setAnchorPoint:CGPointZero];
        [self addChild:self.spellIconSprite];
        
        self.pressedSprite = [CCSprite spriteWithSpriteFrameName:@"spell-down-mask.png"];
        [self.pressedSprite setAnchorPoint:CGPointZero];
        [self.pressedSprite setVisible:NO];
        [self addChild:self.pressedSprite];
        
        self.cooldownCountLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 175)];
        [self.cooldownCountLayer setContentSize:frame.size];
        [self.cooldownCountLayer setVisible:NO];
        
        self.spellTitle = [[[CCLabelTTF alloc] initWithString:[spellData title] fontName:@"Arial" fontSize:18.0f] autorelease];
        [self.spellTitle setPosition:CGPointMake(50, 15)];
        [self.spellTitle setColor:ccBLACK];
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
        CCSpriteFrame *spriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[spellData spriteFrameName]];
        if (spriteFrame){
            [self.spellIconSprite setDisplayFrame:spriteFrame];
        }
	}
}

-(void)updateUI{
	if ([spellData conformsToProtocol:@protocol(Chargable)]){
		if ([(Chargable*)spellData currentChargeTime] >= [(Chargable*)spellData maxChargeTime]){
            //Do something here...
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
        [self.pressedSprite setVisible:YES];
    }
	
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[interactionDelegate spellButtonUnselected:self];
    [self.pressedSprite setVisible:NO];
}

- (void)dealloc {
    [spellData release];
    [spellTitle release];
    [super dealloc];
}


@end

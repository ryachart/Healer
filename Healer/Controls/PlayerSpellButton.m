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
        
        CCSprite *iconSlotBorder = [CCSprite spriteWithSpriteFrameName:@"spell_icon_back.png"];
        [iconSlotBorder setAnchorPoint:CGPointZero];
        [self addChild:iconSlotBorder];
        
        self.spellIconSprite = [CCSprite node];
        [self.spellIconSprite setAnchorPoint:CGPointZero];
        [self addChild:self.spellIconSprite];
        
        self.pressedSprite = [CCSprite spriteWithSpriteFrameName:@"spell-down-mask.png"];
        [self.pressedSprite setAnchorPoint:CGPointZero];
        [self.pressedSprite setVisible:NO];
        [self addChild:self.pressedSprite];
        
        self.cooldownCountLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 175)];
        [self.cooldownCountLayer setContentSize:frame.size];
        [self.cooldownCountLayer setVisible:NO];
        [self addChild:self.cooldownCountLayer z:10];

        
    }
    return self;
}

- (void)configureLabels
{
    [self.spellTitle removeFromParentAndCleanup:YES];
    [self.spellTitleShadow removeFromParentAndCleanup:YES];
    
    CGFloat fontSize = 18.0f;
    CGFloat contentSizeDivisor = 4.5;
    if ([spellData title].length > 8) {
        contentSizeDivisor = 2.0;
    }
    self.spellTitle = [[[CCLabelTTF alloc] initWithString:[spellData title] dimensions:CGSizeMake(self.contentSize.width, self.contentSize.height / contentSizeDivisor) hAlignment:kCCTextAlignmentCenter fontName:@"Marion-Bold" fontSize:fontSize] autorelease];
    [self.spellTitle setPosition:CGPointMake(50, 15)];
    [self.spellTitle setColor:ccc3(25, 25, 25)];
    [self addChild:self.spellTitle z:9];
    
    self.spellTitleShadow = [[[CCLabelTTF alloc] initWithString:[spellData title] dimensions:CGSizeMake(self.contentSize.width, self.contentSize.height / contentSizeDivisor) hAlignment:kCCTextAlignmentCenter fontName:@"Marion-Bold" fontSize:fontSize] autorelease];
    [self.spellTitleShadow setPosition:CGPointMake(49, 14)];
    [self.spellTitleShadow setColor:ccc3(200, 200, 200)];
    [self addChild:self.spellTitleShadow z:8];
    
}

-(void)setSpellData:(Spell*)theSpell{
	[spellData release];
    spellData = [theSpell retain];
	if (spellData == nil)
		[self setVisible:NO];
	else{
        [self configureLabels];
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
    [super dealloc];
}

#pragma mark - CCRBGAProtocol

- (void)setColor:(ccColor3B)color
{
    //Nothing
}

- (ccColor3B)color
{
    return ccBLACK;
}

- (void)setOpacity:(GLubyte)opacity
{
    for (CCNode *child in self.children){
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            id<CCRGBAProtocol> colorChild = (CCSprite*)child;
            [colorChild setOpacity:opacity];
        }
    }
}

- (GLubyte)opacity
{
    float highestOpacity = 0;
    for (CCNode *child in self.children){
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            id<CCRGBAProtocol> colorChild = (CCSprite*)child;
            highestOpacity = [colorChild opacity] > highestOpacity ? [colorChild opacity] : highestOpacity;
        }
    }
    return highestOpacity;
}


@end

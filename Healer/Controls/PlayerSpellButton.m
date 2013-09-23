//
//  PlayerSpellButton.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerSpellButton.h"
#import "Player.h"
#import "CCLabelTTFShadow.h"


@interface PlayerSpellButton ()
@property (nonatomic, assign) CCProgressTimer *cooldownCountLayer;
@property (nonatomic, assign) CCLayerColor *oomLayer;
@property (nonatomic, assign) CCSprite *spellIconSprite;
@property (nonatomic, assign) CCSprite *pressedSprite;
@property (nonatomic, assign) CCLabelTTFShadow *spellTitle;
@end

@implementation PlayerSpellButton

- (id)init{
    if (self = [super init]) {
        self.isTouchEnabled = YES;
        // Initialization code
        
        float frameScale = .9;
        
        CCSprite *iconSlotBorder = [CCSprite spriteWithSpriteFrameName:@"spell_icon_back.png"];
        [iconSlotBorder setAnchorPoint:CGPointZero];
        [iconSlotBorder setScale:frameScale];
        [self addChild:iconSlotBorder];
        
        self.contentSize = iconSlotBorder.contentSize;
        
        self.spellIconSprite = [CCSprite node];
        [self.spellIconSprite setAnchorPoint:CGPointZero];
        [self.spellIconSprite setScale:.9];
        [self addChild:self.spellIconSprite];
        
        self.pressedSprite = [CCSprite spriteWithSpriteFrameName:@"spell-down-mask.png"];
        [self.pressedSprite setAnchorPoint:CGPointZero];
        [self.pressedSprite setVisible:NO];
        [self.pressedSprite setScale:.9];
        [self addChild:self.pressedSprite];
        
        self.cooldownCountLayer = [CCProgressTimer progressWithSprite:[CCSprite spriteWithSpriteFrameName:@"spell-icon-mask.png"]];
        [self.cooldownCountLayer setColor:ccBLACK];
        [self.cooldownCountLayer setOpacity:122];
        [self.cooldownCountLayer setAnchorPoint:CGPointZero];
        [self.cooldownCountLayer setContentSize:self.contentSize];
        [self.cooldownCountLayer setVisible:NO];
        [self.cooldownCountLayer setScale:.9];
        [self addChild:self.cooldownCountLayer z:10];
        
        self.oomLayer = [CCSprite spriteWithSpriteFrameName:@"spell-icon-mask.png"];
        [self.oomLayer setColor:ccRED];
        [self.oomLayer setOpacity:122];
        [self.oomLayer setAnchorPoint:CGPointZero];
        [self.oomLayer setContentSize:self.contentSize];
        [self.oomLayer setVisible:NO];
        [self.oomLayer setScale:.9];
        [self addChild:self.oomLayer z:11];        
    }
    return self;
}

- (void)configureLabels
{
    [self.spellTitle removeFromParentAndCleanup:YES];
    
    CGFloat fontSize = 18.0f;
    CGFloat contentSizeDivisor = 4.5;
    if ([self.spellData title].length > 8) {
        contentSizeDivisor = 2.0;
    }
    self.spellTitle = [[[CCLabelTTFShadow alloc] initWithString:[self.spellData title] dimensions:CGSizeMake(self.contentSize.width - 2, self.contentSize.height / contentSizeDivisor) hAlignment:kCCTextAlignmentCenter fontName:@"Marion-Bold" fontSize:fontSize] autorelease];
    [self.spellTitle setShadowColor:ccc3(200, 200, 200)];
    [self.spellTitle setPosition:CGPointMake(50 * .9, 15 * .9)];
    [self.spellTitle setShadowOffset:CGPointMake(-1, -1)];
    [self.spellTitle setColor:ccc3(25, 25, 25)];
    [self addChild:self.spellTitle z:9];
    
    if (self.spellData.isItem) {
        [self.spellTitle setVisible:NO];
    }
}

-(void)setSpellData:(Spell*)theSpell{
	[_spellData release];
    _spellData = [theSpell retain];
	if (_spellData == nil)
		[self setVisible:NO];
	else{
        [self configureLabels];
        CCSpriteFrame *spriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[_spellData spriteFrameName]];
        if (spriteFrame){
            [self.spellIconSprite setDisplayFrame:spriteFrame];
        }
	}
}

-(void)updateUI{
	if ([self.spellData conformsToProtocol:@protocol(Chargable)]){
		if ([(Chargable*)self.spellData currentChargeTime] >= [(Chargable*)self.spellData maxChargeTime]){
            //Do something here...
        }
	}
    if ([self.spellData cooldownRemaining] > 0){
        [self.cooldownCountLayer setVisible:YES];
        [self.cooldownCountLayer setPercentage:([self.spellData cooldownRemaining]/[self.spellData cooldown])* 100];
    }else if ([self.cooldownCountLayer visible]){
        [self.cooldownCountLayer setVisible:NO];
        [self.cooldownCountLayer setPercentage:0.0];
    }
    
    if (self.player && (self.player.energy < self.spellData.energyCost || self.player.isDead || self.player.isStunned)) {
        [self.oomLayer setVisible:YES];
    } else {
        [self.oomLayer setVisible:NO];
    }
}


-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    CGRect layerRect =  [self boundingBox];
    layerRect.origin = CGPointZero;
    CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
    
    if (self.interactionDelegate != nil && CGRectContainsPoint(layerRect, convertedToNodeSpacePoint)){
        [self.interactionDelegate spellButtonSelected:self];
        [self.pressedSprite setVisible:YES];
    }
	
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[self.interactionDelegate spellButtonUnselected:self];
    [self.pressedSprite setVisible:NO];
}

- (void)dealloc {
    [_spellData release];
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

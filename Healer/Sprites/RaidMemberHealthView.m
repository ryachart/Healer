//
//  RaidMemberHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidMemberHealthView.h"
#import "ClippingNode.h"

#define HEALTH_BAR_BORDER 6
#define FRAME_SCALE .6
#define FILL_INSET_WIDTH 2 * FRAME_SCALE
#define FILL_INSET_HEIGHT 2 * FRAME_SCALE

@interface RaidMemberHealthView ()
@property (nonatomic, assign) CCLabelTTFShadow *isFocusedLabel;

@property (nonatomic, assign) CCSprite *priorityPositiveEffectSprite;
@property (nonatomic, assign) CCSprite *priorityNegativeEffectSprite;

@property (nonatomic, assign) ClippingNode *healthBarClippingNode;
@property (nonatomic, assign) CCSprite *raidFrameTexture;
@property (nonatomic, assign) CCSprite *healthBarMask;
@property (nonatomic, assign) CCSprite *selectionSprite;
@property (nonatomic, assign) CCSprite *classIcon;

@property (nonatomic, assign) ClippingNode *absorptionClippingNode;
@property (nonatomic, assign) CCSprite *absorptionMask;

@property (nonatomic, readwrite) NSInteger lastHealth;

@property (nonatomic, assign) CCLabelBMFont *negativeEffectCountLabel;
@property (nonatomic, assign) CCLabelBMFont *positiveEffectCountLabel;

@property (nonatomic, assign) BOOL newNegativeSpriteIsAnimating;
@property (nonatomic, readwrite) NSInteger lastNegativeEffectsCount;

@property (nonatomic, readwrite) BOOL confusionTriggered;

@property (nonatomic, readwrite) NSTimeInterval alertTextCooldown;
@end

@implementation RaidMemberHealthView

- (void)dealloc {
    [_healthLabel release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
        
        self.lastHealth = 0;
        
        float frameScale = FRAME_SCALE;
        
        self.raidFrameTexture = [CCSprite spriteWithSpriteFrameName:@"raidframe_back.png"];
        [self.raidFrameTexture setAnchorPoint:CGPointZero];
        [self addChild:self.raidFrameTexture];
        [self.raidFrameTexture setScale:frameScale];
        
        self.selectionSprite = [CCSprite spriteWithSpriteFrameName:@"raidframe_selected.png"];
        self.selectionSprite.anchorPoint = CGPointZero;
        [self addChild:self.selectionSprite z:8];
        self.selectionSprite.visible = NO;
        [self.selectionSprite setScale:frameScale];
        [self.selectionSprite setPosition:CGPointMake(FILL_INSET_WIDTH, FILL_INSET_HEIGHT)];
        
        self.healthBarClippingNode = [ClippingNode node];
        self.healthBarMask = [CCSprite spriteWithSpriteFrameName:@"raidframe_fill.png"];
        [self.healthBarMask setAnchorPoint:CGPointZero];
        self.healthBarMask.position = CGPointMake(0, 0);
        [self.healthBarMask setColor:ccGREEN];
        [self.healthBarClippingNode setScale:frameScale];

        [self.healthBarClippingNode setPosition:CGPointMake(FILL_INSET_WIDTH, FILL_INSET_HEIGHT)];
        [self.healthBarClippingNode setContentSize:self.healthBarMask.contentSize];
        [self.healthBarClippingNode setAnchorPoint:CGPointZero];
        [self.healthBarClippingNode setClippingRegion:CGRectMake(0, 0, self.healthBarMask.contentSize.width, self.healthBarMask.contentSize.height)];
        [self.healthBarClippingNode addChild:self.healthBarMask];
        [self addChild:self.healthBarClippingNode];
        
        self.absorptionClippingNode = [ClippingNode node];
        self.absorptionMask = [CCSprite spriteWithSpriteFrameName:@"raidframe_fill.png"];
        [self.absorptionMask setAnchorPoint:CGPointZero];
        [self.absorptionMask setColor:ccc3(0, 70, 140)];
        [self.absorptionMask setOpacity:155];
        [self.absorptionClippingNode setScale:frameScale];
        
        [self.absorptionClippingNode setPosition:CGPointMake(FILL_INSET_WIDTH, FILL_INSET_HEIGHT)];
        [self.absorptionClippingNode setContentSize:self.absorptionMask.contentSize];
        [self.absorptionClippingNode setAnchorPoint:CGPointZero];
        [self.absorptionClippingNode setClippingRegion:CGRectMake(0, 0, self.absorptionMask.contentSize.width, 0)];
        [self.absorptionClippingNode addChild:self.absorptionMask];
        [self addChild:self.absorptionClippingNode];
        
        self.isFocusedLabel = [CCLabelTTFShadow labelWithString:@"" fontName:@"Marion-Bold" fontSize:18.0f];
        [self.isFocusedLabel setPosition:CGPointMake(frameScale *self.raidFrameTexture.contentSize.width / 2, frameScale *self.raidFrameTexture.contentSize.height - 14.0)];
        [self.isFocusedLabel setColor:ccc3(220, 0, 0)];
        [self.isFocusedLabel setShadowOffset:CGPointMake(-1, -1)];
        
		self.healthLabel =  [CCLabelTTFShadow labelWithString:@"" fontName:@"TrebuchetMS-Bold" fontSize:16.0f];
        [self.healthLabel setColor:ccBLACK];
        [self.healthLabel setShadowOffset:CGPointMake(-.8, -.8)];
        [self.healthLabel setShadowColor:ccc3(220, 220, 220)];
        [self.healthLabel setPosition:CGPointMake(frameScale * self.raidFrameTexture.contentSize.width/2, frameScale *self.raidFrameTexture.contentSize.height / 2)];
        
        self.negativeEffectCountLabel = [CCLabelBMFont labelWithString:@"" fntFile:@"fonts/trebuchet-stroke-32.fnt" width:80.0f alignment:kCCTextAlignmentCenter];
        self.negativeEffectCountLabel.scale = .26;
        [self.negativeEffectCountLabel setPosition:CGPointMake(86, 34)];
        [self addChild:self.negativeEffectCountLabel z:10];
        
        self.positiveEffectCountLabel = [CCLabelBMFont labelWithString:@"" fntFile:@"fonts/trebuchet-stroke-32.fnt" width:80.0f alignment:kCCTextAlignmentCenter];
        self.positiveEffectCountLabel.scale = .26;
        [self.positiveEffectCountLabel setPosition:CGPointMake(13, 34)];
        [self addChild:self.positiveEffectCountLabel z:10];
    
        [self addChild:self.healthLabel z:9];
        [self addChild:self.isFocusedLabel z:11];
        
        self.priorityNegativeEffectSprite = [CCSprite node];
        [self.priorityNegativeEffectSprite setPosition:CGPointMake(86, 13)];
        self.priorityNegativeEffectSprite.scale = .16;
        [self addChild:self.priorityNegativeEffectSprite z:10];
		
        self.priorityPositiveEffectSprite = [CCSprite node];
        [self.priorityPositiveEffectSprite setPosition:CGPointMake(13, 13.5)];
        self.priorityPositiveEffectSprite.scale = .25;
        [self addChild:self.priorityPositiveEffectSprite z:10];
    }
    return self;
}

-(ccColor3B)colorForPercentage:(float)percentage{
    if (percentage > .800){
        return ccc3(0, 225, 0);
    }
    
    if (percentage > .600){
        return ccc3(225, 225, 0);
    }
    
    if (percentage > .300){
        return ccc3(225, 115, 0);
    }
    
    if (percentage > 0.0){
        return ccc3(210, 50, 0);
    }
    return ccRED;
}

- (CCSprite *)classIcon
{
    if (!_classIcon){
        NSString* classIconSpriteFrameName = [NSString stringWithFormat:@"class_icon_%@.png", [self.member title].lowercaseString];
        _classIcon = [CCSprite spriteWithSpriteFrameName:classIconSpriteFrameName];
    }
    return _classIcon;
}

- (void)setMember:(RaidMember *)rdMember
{
	_member = rdMember;
	self.lastHealth = _member.health;
    
    [self.classIcon setPosition:CGPointMake(self.contentSize.width / 2, 8)];
    [self addChild:self.classIcon z:9];
}

-(void)onEnter{
    self.isTouchEnabled = YES;
    [super onEnter];
}

-(void)onExit{
    self.isTouchEnabled = NO;
    [super onExit];
}

-(void)displaySCT:(NSString*)sct {
    [self displaySCT:sct asCritical:NO];
}

-(void)displaySCT:(NSString*)sct asCritical:(BOOL)critical {
    CGFloat fontSize = 20;
    NSString *fontName = @"TrebuchetMS";
    float scale = 1.0;
    CCSequence *sctAction = [CCSequence actions:[CCSpawn actions:[CCMoveBy actionWithDuration:1.5 position:CGPointMake(0, 75)], [CCFadeOut actionWithDuration:1.5],nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node removeFromParentAndCleanup:YES];
    }], nil];

    
    if (critical) {
        fontSize = 36;
        fontName = @"TrebuchetMS-Bold";
        scale = 0.0;
        sctAction = [CCSequence actions:[CCScaleTo actionWithDuration:.15 scale:1.0], [CCDelayTime actionWithDuration:.25], [CCScaleTo actionWithDuration:.5 scale:.75],[CCSpawn actions:[CCMoveBy actionWithDuration:1.5 position:CGPointMake(0, 75)], [CCFadeOut actionWithDuration:1.5],nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];}], nil];
    }
    
    
    CCLabelTTFShadow *sctLabel = [CCLabelTTFShadow labelWithString:sct fontName:fontName fontSize:fontSize];
    [sctLabel setColor:ccGREEN];
    [sctLabel setPosition:CGPointMake(self.contentSize.width /2 , self.contentSize.height /2)];
    [sctLabel setScale:scale];
    
    [self addChild:sctLabel z:100];
    
    [sctLabel runAction:sctAction];
}

- (void)animateNewNegativeSprite {
    float currentScale = self.priorityNegativeEffectSprite.scale;
    [self.priorityNegativeEffectSprite runAction:[CCSequence actions:[CCScaleTo actionWithDuration:.4 scale:currentScale * 1.6], [CCScaleTo actionWithDuration:.4 scale:currentScale], nil]];
}

#define BLINK_ACTION_TAG 32432
-(void)updateHealthForInterval:(ccTime)timeDelta
{
    NSInteger healthDelta = abs(self.member.health - self.lastHealth);
    
    switch (self.selectionState) {
        case RaidViewSelectionStateNone:
            self.selectionSprite.visible = NO;
            break;
        case RaidViewSelectionStateSelected:
            self.selectionSprite.visible = YES;
            break;
        default:
            break;
    }
    
    if (self.alertTextCooldown > 0.0) {
        self.alertTextCooldown -= timeDelta;
    }
    
    if (self.alertTextCooldown <= 0.0 && self.member && self.member.health < self.lastHealth){
        int damage = self.lastHealth - self.member.health;
        
        if ((float)damage / self.member.maximumHealth >= .33){
            NSString* sctString = nil;
            NSInteger roll = arc4random() % 5;
            switch (roll) {
                case 0:
                    sctString = @"Ooof!";
                    break;
                case 1:
                    sctString = @"Hrggh!";
                    break;
                case 2:
                    sctString = @"Ouch!";
                    break;
                case 3:
                    sctString = @"Euagh!";
                    break;
                case 4:
                    sctString = @"Augh!";
                    break;
                default:
                    break;
            }
            [self displaySCT:sctString];
            self.alertTextCooldown += 2.0;
        }
        
        if ((float)self.member.health / self.member.maximumHealth <= .25){
            if (self.member.health != 0){
                NSInteger roll = arc4random() % 4;
                NSString *sctString = nil;
                switch (roll) {
                    case 0:
                        sctString = @"Help!";
                        break;
                    case 1:
                        sctString = @"Please!";
                        break;
                    case 2:
                        sctString = @"I'm dying!";
                        break;
                    case 3:
                        sctString = @"Save me!";
                        break;
                    case 4:
                        sctString = @"Heal me!";
                        break;
                    default:
                        break;
                }
                [self displaySCT:sctString];
            }
        }
    }
    
    if (self.member.isFocused && !self.member.isDead){
        if (![self.isFocusedLabel.string isEqualToString:@"FOCUSED"]) {
            [self.isFocusedLabel runAction:[CCSequence actionOne:[CCScaleTo actionWithDuration:.5 scale:1.2] two:[CCScaleTo actionWithDuration:.5 scale:1.0]]];
        }
        [self.isFocusedLabel setString:@"FOCUSED"];
    }else{
        [self.isFocusedLabel setString:@""];
    }
    self.lastHealth = self.member.health;
	NSString *healthText;
	if (self.member.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.0f%%", (((float)self.member.health) / self.member.maximumHealth)*100];
        if (healthDelta != 0) {
            [self.healthBarMask stopAllActions];
            [self.healthBarClippingNode setClippingRegion:CGRectMake(0, 0,self.healthBarMask.contentSize.width , self.healthBarMask.contentSize.height * self.member.healthPercentage)];
        }
        ccColor3B colorForPerc = [self colorForPercentage:(((float)self.member.health) / self.member.maximumHealth)];
        [self.healthBarMask setColor:colorForPerc];
        
        float absorbPercentage = self.member.absorb / (float)self.member.maximumHealth;
        [self.absorptionClippingNode setClippingRegion:CGRectMake(0, 0,self.healthBarMask.contentSize.width , self.healthBarMask.contentSize.height * absorbPercentage)];

	}
	else {
		healthText = @"Dead";
        self.healthLabel.color = ccRED;
        self.healthLabel.shadowColor = ccBLACK;
        [self.healthBarClippingNode setClippingRegion:CGRectMake(0, 0,self.healthBarMask.contentSize.width , 0)];
	}
	
    Effect *negativeEffect = nil;
    Effect *positiveEffect = nil;
    
	for (Effect *eff in self.member.activeEffects){
        if ([eff effectType] == EffectTypePositive){
            if (!positiveEffect || eff.visibilityPriority > positiveEffect.visibilityPriority) {
                positiveEffect = eff;
            }
        }
        if ([eff effectType] == EffectTypeNegative){
            if (!negativeEffect || eff.visibilityPriority > negativeEffect.visibilityPriority) {
                negativeEffect = eff;
            }
        }
	}
    
    if (positiveEffect && positiveEffect.spriteName && !self.member.isDead){
        [self.priorityPositiveEffectSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:positiveEffect.spriteName]];
        [self.priorityPositiveEffectSprite setVisible:YES];
    }else{
        [self.priorityPositiveEffectSprite setVisible:NO];
    }
    
    if (negativeEffect && negativeEffect.spriteName && !self.member.isDead){
        [self.priorityNegativeEffectSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:negativeEffect.spriteName]];
        [self.priorityNegativeEffectSprite setVisible:YES];
    } else{
        [self.priorityNegativeEffectSprite setVisible:NO];
    }
    
    NSInteger positiveEffectCount = [self.member effectCountOfType:EffectTypePositive];
    if (positiveEffectCount > 1){
        self.positiveEffectCountLabel.string = [NSString stringWithFormat:@"%i", positiveEffectCount];
    }else {
        self.positiveEffectCountLabel.string = @"";
    }
    
    
    NSInteger negativeEffectCount = [self.member effectCountOfType:EffectTypeNegative];
    if (negativeEffectCount > 1){
        self.negativeEffectCountLabel.string = [NSString stringWithFormat:@"%i", negativeEffectCount];
    }else {
        self.negativeEffectCountLabel.string = @"";
    }
    if (negativeEffectCount > self.lastNegativeEffectsCount) {
        [self animateNewNegativeSprite];
    }
    self.lastNegativeEffectsCount = negativeEffectCount;

	if (![healthText isEqualToString:[self.healthLabel string]]){
		[self.healthLabel setString:healthText];
	}
}


-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.confusionTriggered) return; //You can't select me while you're confused
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    CGRect layerRect =  [self boundingBox];
    layerRect.origin = CGPointZero;
    CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
    
    if (self.interactionDelegate != nil && CGRectContainsPoint(layerRect, convertedToNodeSpacePoint)){
            [[self interactionDelegate] thisMemberSelected:self];
            _isTouched = YES;
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.confusionTriggered) return; //You can't do any selection while confused;
    
	if (self.interactionDelegate != nil){
        BOOL wasTouched = _isTouched;
		_isTouched = NO;
        if (wasTouched){
            [[self interactionDelegate] thisMemberUnselected:self];
        }
	}
}

- (void)triggerConfusion {
    if (!self.confusionTriggered && self.selectionState != RaidViewSelectionStateSelected && !self.member.isDead){
        self.confusionTriggered = YES;
        
        float transitionDuration = 1.25;
        float confusionDuration = 6.0;
        float angle = (arc4random() % 2) ? 150.0 : -150.0;
        
        [self runAction:[CCSequence actions:[CCSpawn actionOne:[CCScaleTo actionWithDuration:transitionDuration scale:0.0] two:[CCRotateTo actionWithDuration:transitionDuration angle:angle]], [CCDelayTime actionWithDuration:confusionDuration], [CCSpawn actionOne:[CCScaleTo actionWithDuration:transitionDuration scale:1.0] two:[CCRotateTo actionWithDuration:transitionDuration angle:0.0]], [CCCallBlockN actionWithBlock:^(CCNode *node){
            RaidMemberHealthView *thisNode = (RaidMemberHealthView*)node;
            thisNode.confusionTriggered = NO;
        }], nil]];
    }
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

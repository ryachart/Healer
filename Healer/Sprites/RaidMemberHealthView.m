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

@interface RaidMemberHealthView ()
@property (nonatomic, assign) CCLabelTTF *isFocusedLabel;
@property (nonatomic, assign) CCLabelTTF *isFocusedShadowLabel;

@property (nonatomic, assign) CCSprite *priorityPositiveEffectSprite;
@property (nonatomic, assign) CCSprite *priorityNegativeEffectSprite;

@property (nonatomic, assign) ClippingNode *healthBarClippingNode;
@property (nonatomic, assign) CCSprite *raidFrameTexture;
@property (nonatomic, assign) CCSprite *healthBarMask;
@property (nonatomic, assign) CCSprite *selectionSprite;
@property (nonatomic, assign) CCSprite *classIconSprite;

@property (nonatomic, assign) ClippingNode *absorptionClippingNode;
@property (nonatomic, assign) CCSprite *absorptionMask;

@property (nonatomic, assign) ClippingNode *pEffectClippingNode;
@property (nonatomic, assign) CCSprite *pEffectDurationBack;
@property (nonatomic, assign) ClippingNode *nEffectClippingNode;
@property (nonatomic, assign) CCSprite *nEffectDurationBack;

@property (nonatomic, readwrite) NSInteger lastHealth;
@property (nonatomic, assign) CCSprite *shieldBubble;

@property (nonatomic, assign) CCLabelTTF *negativeEffectCountLabel;
@property (nonatomic, assign) CCLabelTTF *positiveEffectCountLabel;

@property (nonatomic, assign) BOOL newNegativeSpriteIsAnimating;
@property (nonatomic, readwrite) NSInteger lastNegativeEffectsCount;

@property (nonatomic, readwrite) BOOL confusionTriggered;
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
        
        self.selectionSprite = [CCSprite spriteWithSpriteFrameName:@"raid_frame_selection.png"];
        self.selectionSprite.anchorPoint = CGPointZero;
        [self addChild:self.selectionSprite];
        self.selectionSprite.visible = NO;
        
        self.healthBarClippingNode = [ClippingNode node];
        self.healthBarMask = [CCSprite spriteWithSpriteFrameName:@"raid_frame_bar_mask.png"];
        [self.healthBarMask setAnchorPoint:CGPointZero];
        self.healthBarMask.position = CGPointMake(0, 0);
        [self.healthBarMask setColor:ccGREEN];
        
        [self.healthBarClippingNode setPosition:CGPointMake(0, 8)];
        [self.healthBarClippingNode setContentSize:self.healthBarMask.contentSize];
        [self.healthBarClippingNode setAnchorPoint:CGPointZero];
        [self.healthBarClippingNode setClippingRegion:CGRectMake(0, 0, self.healthBarMask.contentSize.width, self.healthBarMask.contentSize.height)];
        [self.healthBarClippingNode addChild:self.healthBarMask];
        [self addChild:self.healthBarClippingNode];
        
        self.absorptionClippingNode = [ClippingNode node];
        self.absorptionMask = [CCSprite spriteWithSpriteFrameName:@"raid_frame_bar_mask.png"];
        [self.absorptionMask setAnchorPoint:CGPointZero];
        self.absorptionMask.position = CGPointMake(0, -self.absorptionMask.contentSize.height);
        [self.absorptionMask setColor:ccc3(0, 100, 200)];
        [self.absorptionMask setOpacity:155];
        
        [self.absorptionClippingNode setPosition:CGPointMake(0, 8)];
        [self.absorptionClippingNode setContentSize:self.absorptionMask.contentSize];
        [self.absorptionClippingNode setAnchorPoint:CGPointZero];
        [self.absorptionClippingNode setClippingRegion:CGRectMake(0, 0, self.absorptionMask.contentSize.width, self.absorptionMask.contentSize.height)];
        [self.absorptionClippingNode addChild:self.absorptionMask];
        [self addChild:self.absorptionClippingNode];
        
        self.raidFrameTexture = [CCSprite spriteWithSpriteFrameName:@"raid_frame.png"];
        [self.raidFrameTexture setAnchorPoint:CGPointZero];
        [self addChild:self.raidFrameTexture z:5];
        
        self.isFocusedLabel = [CCLabelTTF labelWithString:@"" fontName:@"Marion-Bold" fontSize:15.0];
        [self.isFocusedLabel setPosition:CGPointMake(50, 64)];
        [self.isFocusedLabel setColor:ccc3(220, 0, 0)];
        
        self.isFocusedShadowLabel = [CCLabelTTF labelWithString:@"" fontName:@"Marion-Bold" fontSize:15.0];
        [self.isFocusedShadowLabel setPosition:CGPointMake(49, 63)];
        [self.isFocusedShadowLabel setColor:ccBLACK];
        
		self.healthLabel =  [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];   
        [self.healthLabel setPosition:CGPointMake(frame.size.width * .71, frame.size.height * .5)];
        [self.healthLabel setContentSize:CGSizeMake(frame.size.width * .5, frame.size.height * .25)];
        [self.healthLabel setColor:ccc3(0, 0, 0)];
        
        self.pEffectClippingNode = [ClippingNode node];
        self.pEffectDurationBack = [CCSprite spriteWithSpriteFrameName:@"effect_bottom_mask.png"];
        [self.pEffectDurationBack setOpacity:70];
        [self.pEffectDurationBack setColor:ccGREEN];
        self.pEffectDurationBack.anchorPoint = CGPointMake(0, 0);
        self.pEffectClippingNode.clippingRegion = CGRectMake(0,0,self.pEffectDurationBack.contentSize.width, 0);
        [self.pEffectClippingNode setPosition:CGPointMake(8, 9)];
        [self.pEffectClippingNode addChild:self.pEffectDurationBack];
        [self addChild:self.pEffectClippingNode z:5];
        
        self.nEffectClippingNode = [ClippingNode node];
        self.nEffectDurationBack = [CCSprite spriteWithSpriteFrameName:@"effect_top_mask.png"];
        [self.nEffectDurationBack setOpacity:70];
        [self.nEffectDurationBack setColor:ccRED];
        self.nEffectDurationBack.anchorPoint = CGPointMake(0, 0);
        self.nEffectClippingNode.clippingRegion = CGRectMake(0,0,self.nEffectDurationBack.contentSize.width, 0);
        [self.nEffectClippingNode setPosition:CGPointMake(8, 44)];
        [self.nEffectClippingNode addChild:self.nEffectDurationBack];
        [self addChild:self.nEffectClippingNode z:5];
        
        self.negativeEffectCountLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(40, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:16.0];
        [self.negativeEffectCountLabel setPosition:CGPointMake(28, 40)];
        [self addChild:self.negativeEffectCountLabel z:10];
        
        self.positiveEffectCountLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(40, 40) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:16.0];
        [self.positiveEffectCountLabel setPosition:CGPointMake(30, 5)];
        [self addChild:self.positiveEffectCountLabel z:10];
        
        self.shieldBubble = [CCSprite spriteWithSpriteFrameName:@"shield_bubble.png"];
        [self.shieldBubble setVisible:NO];
        [self.shieldBubble setPosition:ccp(frame.size.width * .5,frame.size.height * .5)];
    
        [self addChild:self.healthLabel z:9];
        [self addChild:self.isFocusedShadowLabel z:10];
        [self addChild:self.isFocusedLabel z:11];
        [self addChild:self.shieldBubble z:100]; //Above all else!
		_interactionDelegate = nil;
		
		_isTouched = NO;
    }
    return self;
}

-(void)setShieldedOn:(BOOL)isOn{
    return;
    if (isOn && !self.shieldBubble.visible){
        self.shieldBubble.scale = 0.0;
        self.shieldBubble.visible = YES;
        [self.shieldBubble setOpacity:255];
        [self.shieldBubble stopAllActions];
        [self.shieldBubble runAction:[CCSequence actions:[CCEaseBackOut actionWithAction:[CCScaleTo actionWithDuration:.33 scale:1.0]], nil]];
        //Present
    }else if (self.shieldBubble.visible && !isOn){
        //Dismiss
        [self.shieldBubble setVisible:NO];
    }
}

-(ccColor3B)colorForPercentage:(float)percentage{
    if (percentage > .800){
        return ccGREEN;
    }
    
    if (percentage > .600){
        return ccYELLOW;
    }
    
    if (percentage > .300){
        return ccORANGE;
    }
    
    if (percentage > 0.0){
        return ccc3(255, 75, 0);
    }
    return ccRED;
}

-(void)setMemberData:(RaidMember*)rdMember
{
	_memberData = rdMember;
	self.lastHealth = _memberData.health;
    
    NSString* classIconSpriteFrameName = [NSString stringWithFormat:@"class_icon_%@.png", [rdMember title].lowercaseString];
    if (!self.classIconSprite){
        self.classIconSprite = [CCSprite spriteWithSpriteFrameName:classIconSpriteFrameName];
        [self.classIconSprite setPosition:CGPointMake(52, 40)];
        [self addChild:self.classIconSprite z:15];
    } else{
        [self.classIconSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:classIconSpriteFrameName]];
    }
}

-(void)onEnter{
    self.isTouchEnabled = YES;
    [super onEnter];
}

-(void)onExit{
    self.isTouchEnabled = NO;
    [super onExit];
}

-(void)displaySCT:(NSString*)sct{
    CCLabelTTF *shadowLabel = [CCLabelTTF labelWithString:sct fontName:@"Arial" fontSize:20];
    [shadowLabel setColor:ccBLACK];
    [shadowLabel setPosition:CGPointMake(self.contentSize.width /2 -1 , self.contentSize.height /2 + 1)];
    
    CCLabelTTF *sctLabel = [CCLabelTTF labelWithString:sct fontName:@"Arial" fontSize:20];
    [sctLabel setColor:ccGREEN];
    [sctLabel setPosition:CGPointMake(self.contentSize.width /2 , self.contentSize.height /2)];
    
    [self addChild:shadowLabel z:100];
    [self addChild:sctLabel z:100];
    
    [sctLabel runAction:[CCSequence actions:[CCSpawn actions:[CCMoveBy actionWithDuration:2.0 position:CGPointMake(0, 100)], [CCFadeOut actionWithDuration:2.0],nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node removeFromParentAndCleanup:YES];
    }], nil]];
    [shadowLabel runAction:[CCSequence actions:[CCSpawn actions:[CCMoveBy actionWithDuration:2.0 position:CGPointMake(0, 100)], [CCFadeOut actionWithDuration:2.0],nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node removeFromParentAndCleanup:YES];
    }], nil]];
}

- (void)animateNewNegativeSprite {
    [self.priorityNegativeEffectSprite runAction:[CCSequence actions:[CCScaleTo actionWithDuration:.4 scale:1.6], [CCScaleTo actionWithDuration:.4 scale:1.0], nil]];
}

#define BLINK_ACTION_TAG 32432
-(void)updateHealth
{
    NSInteger healthDelta = abs(self.memberData.health - self.lastHealth);
    float deltaPercentage = healthDelta / (float)self.memberData.maximumHealth;
    if (self.memberData && self.memberData.health > self.lastHealth){
        //We were healed.  Lets fire some SCT!
        int heal = self.memberData.health - self.lastHealth;
        [self displaySCT:[NSString stringWithFormat:@"+%i", heal]];
    }
    
    switch (self.selectionState) {
        case RaidViewSelectionStateNone:
            self.selectionSprite.visible = NO;
            break;
        case RaidViewSelectionStateSelected:
            [self.selectionSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"raid_frame_selection.png"]];
            self.selectionSprite.visible = YES;
            break;
        case RaidViewSelectionStateAltSelected:
            [self.selectionSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"raid_frame_alt_selection.png"]];
            self.selectionSprite.visible = YES;
            break;
        default:
            break;
    }
    
    if (self.memberData && self.memberData.health < self.lastHealth){
        int damage = self.lastHealth - self.memberData.health;
        
        if ((float)damage / self.memberData.maximumHealth >= .33){
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
        }
        
        if ((float)self.memberData.health / self.memberData.maximumHealth <= .25){
            if (self.memberData.health != 0){
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
    
    if (self.memberData.isFocused && !self.memberData.isDead){
        if (![self.isFocusedLabel.string isEqualToString:@"FOCUSED"]) {
            [self.isFocusedLabel runAction:[CCSequence actionOne:[CCScaleTo actionWithDuration:.5 scale:1.2] two:[CCScaleTo actionWithDuration:.5 scale:1.0]]];
            [self.isFocusedShadowLabel runAction:[CCSequence actionOne:[CCScaleTo actionWithDuration:.5 scale:1.2] two:[CCScaleTo actionWithDuration:.5 scale:1.0]]];
        }
        [self.isFocusedLabel setString:@"FOCUSED"];
        [self.isFocusedShadowLabel setString:@"FOCUSED"];
    }else{
        [self.isFocusedLabel setString:@""];
        [self.isFocusedShadowLabel setString:@""];
    }
    self.lastHealth = self.memberData.health;
	NSString *healthText;
	if (self.memberData.health >= 1){
        float totalTime = .33;
		healthText = [NSString stringWithFormat:@"%3.1f%%", (((float)self.memberData.health) / self.memberData.maximumHealth)*100];
        if (healthDelta != 0) {
            [self.healthBarMask stopAllActions];
            [self.healthBarMask runAction:[CCMoveTo actionWithDuration:totalTime * deltaPercentage position:CGPointMake(0, -(self.healthBarMask.contentSize.height) * (1 - self.memberData.healthPercentage))]];
        }
        ccColor3B colorForPerc = [self colorForPercentage:(((float)self.memberData.health) / self.memberData.maximumHealth)];
        [self.healthBarMask setColor:colorForPerc];
        
        float absorbPercentage = self.memberData.absorb / (float)self.memberData.maximumHealth;
        self.absorptionMask.position = CGPointMake(0, -(self.absorptionMask.contentSize.height) * (1 - absorbPercentage));

	}
	else {
        [self.nEffectClippingNode setClippingRegion:CGRectMake(0, 0, self.nEffectDurationBack.contentSize.width, 0)];
        [self.pEffectClippingNode setClippingRegion:CGRectMake(0, 0, self.pEffectDurationBack.contentSize.width, 0)];
		healthText = @"Dead";
        [self.raidFrameTexture setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"raid_frame_dead.png"]];
	}
	
    Effect *negativeEffect = nil;
    Effect *positiveEffect = nil;
//    BOOL shieldEffectFound = NO;
	for (Effect *eff in self.memberData.activeEffects){
        if ([eff effectType] == EffectTypePositive){
            positiveEffect = eff;
        }
        if ([eff effectType] == EffectTypeNegative){
            negativeEffect = eff;
        }
	}
    
//    [self setShieldedOn:shieldEffectFound];
    
    if (positiveEffect && positiveEffect.spriteName && !self.memberData.isDead){
        if (!self.priorityPositiveEffectSprite){
            self.priorityPositiveEffectSprite = [CCSprite spriteWithSpriteFrameName:positiveEffect.spriteName];
            [self.priorityPositiveEffectSprite setPosition:CGPointMake(26, 26)];
            [self addChild:self.priorityPositiveEffectSprite z:5];
        }else{
            [self.priorityPositiveEffectSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:positiveEffect.spriteName]];
        }
        
        [self.pEffectClippingNode setClippingRegion:CGRectMake(0, 0, self.pEffectDurationBack.contentSize.width, self.pEffectDurationBack.contentSize.height * (1- (positiveEffect.timeApplied/positiveEffect.duration)))];
        
        [self.priorityPositiveEffectSprite setVisible:YES];
    }else{
        [self.pEffectClippingNode setClippingRegion:CGRectMake(0, 0, self.pEffectDurationBack.contentSize.width, 0)];
        [self.priorityPositiveEffectSprite setVisible:NO];
    }
    
    if (negativeEffect && negativeEffect.spriteName && !self.memberData.isDead){
        if (!self.priorityNegativeEffectSprite){
            self.priorityNegativeEffectSprite = [CCSprite spriteWithSpriteFrameName:negativeEffect.spriteName];
            [self.priorityNegativeEffectSprite setPosition:CGPointMake(26, 58)];
            [self addChild:self.priorityNegativeEffectSprite z:5];
        }else{
            [self.priorityNegativeEffectSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:negativeEffect.spriteName]];
        }
        [self.nEffectClippingNode setClippingRegion:CGRectMake(0, 0, self.nEffectDurationBack.contentSize.width, self.nEffectDurationBack.contentSize.height * (1- (negativeEffect.timeApplied/negativeEffect.duration)))];
        [self.priorityNegativeEffectSprite setVisible:YES];
    } else{
        [self.nEffectClippingNode setClippingRegion:CGRectMake(0, 0, self.nEffectDurationBack.contentSize.width, 0)];
        [self.priorityNegativeEffectSprite setVisible:NO];
    }
    
    NSInteger positiveEffectCount = [self.memberData effectCountOfType:EffectTypePositive];
    if (positiveEffectCount > 1){
        self.positiveEffectCountLabel.string = [NSString stringWithFormat:@"%i", positiveEffectCount];
    }else {
        self.positiveEffectCountLabel.string = @"";
    }
    
    
    NSInteger negativeEffectCount = [self.memberData effectCountOfType:EffectTypeNegative];
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
    if (!self.confusionTriggered && self.selectionState != RaidViewSelectionStateSelected && !self.memberData.isDead){
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

@end

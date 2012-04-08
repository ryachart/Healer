//
//  RaidMemberHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidMemberHealthView.h"
#import "CCRoundedRect.h"

#define HEALTH_BAR_BORDER 6

@interface RaidMemberHealthView ()
@property (nonatomic, assign) CCLabelTTF *isFocusedLabel;
@property (nonatomic, assign) CCSprite *priorityPositiveEffectSprite;
@property (nonatomic, assign) CCSprite *priorityNegativeEffectSprite;
@property (nonatomic, readwrite) NSInteger lastHealth;
@end

@implementation RaidMemberHealthView

@synthesize memberData, classNameLabel, healthLabel, interactionDelegate, defaultBackgroundColor, isTouched, effectsLabel;
@synthesize healthBarLayer, lastHealth, isFocusedLabel, priorityNegativeEffectSprite, priorityPositiveEffectSprite;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        // Initialization code
        
        self.position = frame.origin;
        self.contentSize = frame.size;
        
        self.lastHealth = 0;
        
//        self.healthBarLayer = [CCLayerColor layerWithColor:ccc4(0, 255, 0, 255) width:frame.size.width - (HEALTH_BAR_BORDER *2) height:frame.size.height - (HEALTH_BAR_BORDER *2)];
//        self.healthBarLayer.position = CGPointMake(HEALTH_BAR_BORDER, HEALTH_BAR_BORDER);
        
        float backgroundBorderWidth = 4.0;
        CCRoundedRect *barBackgroundAndBorder = [[[CCRoundedRect alloc] initWithRectSize:CGSizeMake(frame.size.width - (HEALTH_BAR_BORDER * 2), frame.size.height - (HEALTH_BAR_BORDER * 2))] autorelease];
        [barBackgroundAndBorder setFillColor:ccc4(255,255,255, 255)];
        [barBackgroundAndBorder setRadius:6.0];
        [barBackgroundAndBorder setBorderWidth:backgroundBorderWidth];
        [barBackgroundAndBorder setBorderColor:ccc4(0, 0, 0, 255)];
        [barBackgroundAndBorder setPosition:CGPointMake(HEALTH_BAR_BORDER, HEALTH_BAR_BORDER)];
        [self addChild:barBackgroundAndBorder];
        
        self.healthBarLayer = [[[CCRoundedRect alloc] initWithRectSize:CGSizeMake(frame.size.width - ((HEALTH_BAR_BORDER + backgroundBorderWidth/2) * 2), frame.size.height - ((HEALTH_BAR_BORDER+ backgroundBorderWidth/2 ) * 2))] autorelease];
        self.healthBarLayer.position = CGPointMake(HEALTH_BAR_BORDER + backgroundBorderWidth/2, HEALTH_BAR_BORDER + backgroundBorderWidth/2);
        self.healthBarLayer.radius = 6.0;
        self.healthBarLayer.borderWidth = 0.0;
        self.healthBarLayer.borderColor = ccc4(0, 0, 0, 0);
        
		self.classNameLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];            
        [self.classNameLabel setPosition:CGPointMake(frame.size.width * .5, 14)];
        [self.classNameLabel setContentSize:CGSizeMake(frame.size.width, frame.size.height)];
        [self.classNameLabel setColor:ccc3(0, 0, 0)];
        
        self.isFocusedLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:15.0];
        [self.isFocusedLabel setPosition:CGPointMake(50, 54)];
        [self.isFocusedLabel setColor:ccBLACK];
        
		self.healthLabel =  [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];   
        [self.healthLabel setPosition:CGPointMake(frame.size.width * .5, frame.size.height * .34)];
        [self.healthLabel setContentSize:CGSizeMake(frame.size.width * .5, frame.size.height * .25)];
        [self.healthLabel setColor:ccc3(0, 0, 0)];
                
		self.effectsLabel =  [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];
        [self.effectsLabel setPosition:CGPointMake(frame.size.width * .5, frame.size.height * .85)];
        [self.effectsLabel setContentSize:CGSizeMake(frame.size.width, frame.size.height * .15)];
        [self.effectsLabel setColor:ccc3(0, 0, 0)];
			
        [self addChild:self.healthBarLayer];
        [self addChild:self.classNameLabel];
        [self addChild:self.healthLabel];
        [self addChild:self.effectsLabel];
        [self addChild:self.isFocusedLabel];
		interactionDelegate = nil;
		
		isTouched = NO;
    }
    return self;
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
	memberData = rdMember;
	self.lastHealth = memberData.health;
    [self.classNameLabel setString:rdMember.title];

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
    
    [self addChild:shadowLabel z:10];
    [self addChild:sctLabel z:11];
    
    [sctLabel runAction:[CCSequence actions:[CCSpawn actions:[CCMoveBy actionWithDuration:2.0 position:CGPointMake(0, 100)], [CCFadeOut actionWithDuration:2.0],nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node removeFromParentAndCleanup:YES];
    }], nil]];
    [shadowLabel runAction:[CCSequence actions:[CCSpawn actions:[CCMoveBy actionWithDuration:2.0 position:CGPointMake(0, 100)], [CCFadeOut actionWithDuration:2.0],nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node removeFromParentAndCleanup:YES];
    }], nil]];
}

#define BLINK_ACTION_TAG 32432
-(void)updateHealth
{
    if (memberData && memberData.health > self.lastHealth){
        //We were healed.  Lets fire some SCT!
        int heal = memberData.health - lastHealth;
        [self displaySCT:[NSString stringWithFormat:@"+%i", heal]];
        
    }
    
    if (memberData && memberData.health < self.lastHealth){
        int damage = lastHealth - memberData.health;
        
        if ((float)damage / memberData.maximumHealth >= .33){
            [self displaySCT:@"Euagh!"];
        }
        
        if ((float)memberData.health / memberData.maximumHealth <= .25){
            if (memberData.health != 0){
                [self displaySCT:@"Help!"];
            }
        }
    }
    
    if (memberData.isFocused){
        [self.isFocusedLabel setString:@"FOCUSED!"];
    }else{
        [self.isFocusedLabel setString:@""];
    }
    self.lastHealth = memberData.health;
	NSString *healthText;
	if (memberData.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.1f\%", (((float)memberData.health) / memberData.maximumHealth)*100];
		self.healthBarLayer.size = CGSizeMake(self.healthBarLayer.size.width,(int)round((self.contentSize.height - ((HEALTH_BAR_BORDER + 2.0 ) * 2) ) * (((float)memberData.health) / memberData.maximumHealth)));
        ccColor3B colorForPerc = [self colorForPercentage:(((float)memberData.health) / memberData.maximumHealth)];
        [self.healthBarLayer setFillColor:ccc4(colorForPerc.r, colorForPerc.g, colorForPerc.b, 255)];
	}
	else {
		healthText = @"Dead";
        self.healthBarLayer.size = CGSizeMake(self.healthBarLayer.size.width, 0);
        self.healthBarLayer.visible = NO;
		[self setColor:ccc3(255, 0, 0)];
        [self setOpacity:255];
	}
	
    Effect *negativeEffect = nil;
    Effect *positiveEffect = nil;
	for (Effect *eff in self.memberData.activeEffects){
        if ([eff effectType] == EffectTypePositive){
            positiveEffect = eff;
        }
        if ([eff effectType] == EffectTypeNegative){
            negativeEffect = eff;
        }
	}
    
    if (positiveEffect && positiveEffect.spriteName && !self.memberData.isDead){
        if (!self.priorityPositiveEffectSprite){
            self.priorityPositiveEffectSprite = [CCSprite spriteWithSpriteFrameName:positiveEffect.spriteName];
            [self.priorityPositiveEffectSprite setContentSize:CGSizeMake(40, 40)];
            [self.priorityPositiveEffectSprite setPosition:CGPointMake(20, self.contentSize.height * .15)];
            [self addChild:self.priorityPositiveEffectSprite z:5];
        }else{
            [self.priorityPositiveEffectSprite stopAllActions];
            [self.priorityPositiveEffectSprite setOpacity:255];
            [self.priorityPositiveEffectSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:positiveEffect.spriteName]];
        }
        if (positiveEffect.timeApplied/positiveEffect.duration > .8 && ![self.priorityPositiveEffectSprite getActionByTag:BLINK_ACTION_TAG]){
            CCAction *blinkAction = [CCRepeatForever actionWithAction:[CCSequence actions:[CCFadeTo actionWithDuration:.5 opacity:120], [CCFadeTo actionWithDuration:.5 opacity:255], nil]];
            blinkAction.tag = BLINK_ACTION_TAG;
            [self.priorityPositiveEffectSprite runAction:blinkAction];
        }
        [self.priorityPositiveEffectSprite setVisible:YES];
    }else{
        [self.priorityPositiveEffectSprite setVisible:NO];
    }
    
    if (negativeEffect && negativeEffect.spriteName && !self.memberData.isDead){
        if (!self.priorityNegativeEffectSprite){
            self.priorityNegativeEffectSprite = [CCSprite spriteWithSpriteFrameName:negativeEffect.spriteName];
            [self.priorityNegativeEffectSprite setContentSize:CGSizeMake(40, 40)];
            [self.priorityNegativeEffectSprite setPosition:CGPointMake(20, self.contentSize.height * .8)];
            [self addChild:self.priorityNegativeEffectSprite z:5];
        }else{
            [self.priorityNegativeEffectSprite stopAllActions];
            [self.priorityNegativeEffectSprite setOpacity:255];
            [self.priorityNegativeEffectSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:negativeEffect.spriteName]];
        }
        if (negativeEffect.timeApplied/negativeEffect.duration > .8 && ![self.priorityNegativeEffectSprite getActionByTag:BLINK_ACTION_TAG]){
            CCAction *blinkAction = [CCRepeatForever actionWithAction:[CCSequence actions:[CCFadeTo actionWithDuration:.5 opacity:120], [CCFadeTo actionWithDuration:.5 opacity:255], nil]];
            blinkAction.tag = BLINK_ACTION_TAG;
            [self.priorityNegativeEffectSprite runAction:blinkAction];
        }
        [self.priorityNegativeEffectSprite setVisible:YES];
    }else{
        [self.priorityNegativeEffectSprite setVisible:NO];
    }

	if (![healthText isEqualToString:[healthLabel string]]){
		[healthLabel setString:healthText];
	}
}


-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    CGRect layerRect =  [self boundingBox];
    layerRect.origin = CGPointZero;
    CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
    
    if (interactionDelegate != nil && CGRectContainsPoint(layerRect, convertedToNodeSpacePoint)){
            [[self interactionDelegate] thisMemberSelected:self];
            isTouched = YES;
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
	if (interactionDelegate != nil){
        BOOL wasTouched = isTouched;
		isTouched = NO;
        if (wasTouched){
            [[self interactionDelegate] thisMemberUnselected:self];
        }
	}
}

- (void)dealloc {
    [super dealloc];
}


@end

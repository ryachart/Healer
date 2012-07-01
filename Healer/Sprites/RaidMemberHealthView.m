//
//  RaidMemberHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidMemberHealthView.h"
#import "CCRoundedRect.h"
#import "ClippingNode.h"

#define HEALTH_BAR_BORDER 6

@interface RaidMemberHealthView ()
@property (nonatomic, assign) CCLabelTTF *isFocusedLabel;
@property (nonatomic, assign) CCSprite *priorityPositiveEffectSprite;
@property (nonatomic, assign) CCSprite *priorityNegativeEffectSprite;

@property (nonatomic, assign) ClippingNode *healthBarClippingNode;
@property (nonatomic, assign) CCSprite *raidFrameTexture;
@property (nonatomic, assign) CCSprite *healthBarMask;
@property (nonatomic, assign) CCSprite *selectionSprite;
@property (nonatomic, assign) CCSprite *classIconSprite;

@property (nonatomic, readwrite) NSInteger lastHealth;
@property (nonatomic, assign) CCSprite *shieldBubble;
@end

@implementation RaidMemberHealthView

@synthesize memberData, healthLabel, interactionDelegate, isTouched;
@synthesize lastHealth, isFocusedLabel, priorityNegativeEffectSprite, priorityPositiveEffectSprite, shieldBubble;
@synthesize classIconSprite;

@synthesize raidFrameTexture, healthBarClippingNode,  healthBarMask, selectionState, selectionSprite;

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
        
        self.raidFrameTexture = [CCSprite spriteWithSpriteFrameName:@"raid_frame.png"];
        [self.raidFrameTexture setAnchorPoint:CGPointZero];
        [self addChild:self.raidFrameTexture z:5];
        
        self.isFocusedLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:15.0];
        [self.isFocusedLabel setPosition:CGPointMake(50, 64)];
        [self.isFocusedLabel setColor:ccBLACK];
        
		self.healthLabel =  [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];   
        [self.healthLabel setPosition:CGPointMake(frame.size.width * .7, frame.size.height * .5)];
        [self.healthLabel setContentSize:CGSizeMake(frame.size.width * .5, frame.size.height * .25)];
        [self.healthLabel setColor:ccc3(0, 0, 0)];
                
        
        self.shieldBubble = [CCSprite spriteWithSpriteFrameName:@"shield_bubble.png"];
        [self.shieldBubble setVisible:NO];
        [self.shieldBubble setPosition:ccp(frame.size.width * .5,frame.size.height * .5)];
    
        [self addChild:self.healthLabel z:10];
        [self addChild:self.isFocusedLabel z:11];
        [self addChild:self.shieldBubble z:100]; //Above all else!
		interactionDelegate = nil;
		
		isTouched = NO;
    }
    return self;
}

-(void)setShieldedOn:(BOOL)isOn{
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
	memberData = rdMember;
	self.lastHealth = memberData.health;
    
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

#define BLINK_ACTION_TAG 32432
-(void)updateHealth
{
    if (memberData && memberData.health > self.lastHealth){
        //We were healed.  Lets fire some SCT!
        int heal = memberData.health - lastHealth;
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
    
    if (memberData && memberData.health < self.lastHealth){
        int damage = lastHealth - memberData.health;
        
        if ((float)damage / memberData.maximumHealth >= .33){
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
        
        if ((float)memberData.health / memberData.maximumHealth <= .25){
            if (memberData.health != 0){
                NSInteger roll = arc4random() % 3;
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
                    default:
                        break;
                }
                [self displaySCT:sctString];
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
        self.healthBarMask.position = CGPointMake(0, -(self.healthBarMask.contentSize.height) * (1 - memberData.healthPercentage));
        ccColor3B colorForPerc = [self colorForPercentage:(((float)memberData.health) / memberData.maximumHealth)];
        [self.healthBarMask setColor:colorForPerc];
	}
	else {
		healthText = @"Dead";
        [self.raidFrameTexture setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"raid_frame_dead.png"]];
	}
	
    Effect *negativeEffect = nil;
    Effect *positiveEffect = nil;
    BOOL shieldEffectFound = NO;
	for (Effect *eff in self.memberData.activeEffects){
        if ([eff effectType] == EffectTypePositive){
            if ([eff isKindOfClass:[ShieldEffect class]]){
                shieldEffectFound = YES;
            }else{
                positiveEffect = eff;
            }
        }
        if ([eff effectType] == EffectTypeNegative){
            negativeEffect = eff;
        }
	}
    
    [self setShieldedOn:shieldEffectFound];
    
    if (positiveEffect && positiveEffect.spriteName && !self.memberData.isDead){
        if (!self.priorityPositiveEffectSprite){
            self.priorityPositiveEffectSprite = [CCSprite spriteWithSpriteFrameName:positiveEffect.spriteName];
            [self.priorityPositiveEffectSprite setPosition:CGPointMake(50, 40)];
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
            [self.priorityNegativeEffectSprite setPosition:CGPointMake(50, 40)];
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
    [healthLabel release];
    [interactionDelegate release];
    [super dealloc];
}


@end

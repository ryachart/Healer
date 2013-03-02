//
//  PlayerEnergyView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerStatusView.h"
#import "ClippingNode.h"
#import "CCLabelTTFShadow.h"

#define ENERGYBAR_INSET_WIDTH 5.0
#define ENERGYBAR_INSET_HEIGHT 5.0

@interface PlayerStatusView ()
@property (nonatomic, assign) CCProgressTimer *healthBar;
@property (nonatomic, assign) CCProgressTimer *energyBar;
@property (nonatomic, assign) CCLabelTTFShadow *energyLabel;
@property (nonatomic, assign) CCLabelTTFShadow *healthLabel;
@property (nonatomic, readwrite) BOOL isTouched;
@end


@implementation PlayerStatusView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        // Initialization code
		self.percentEnergy = 0.0;
        self.percentChanneled = 0.0;
        
        self.position = frame.origin;
        self.isTouchEnabled = YES;
        self.isTouched = NO;
        
        CCSprite *energyBack = [CCSprite spriteWithSpriteFrameName:@"bar_back_small.png"];
        [self addChild:energyBack];
        
        CCLabelTTFShadow *manaLabel = [CCLabelTTFShadow labelWithString:@"Mana" dimensions:energyBack.contentSize hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:18.0f];
        [manaLabel setShadowOffset:CGPointMake(-1, -1)];
        [manaLabel setPosition:ccpAdd(energyBack.position, CGPointMake(10, -6))];
        [self addChild:manaLabel z:100];
        
        self.energyLabel = [CCLabelTTFShadow labelWithString:@"1000" dimensions:energyBack.contentSize hAlignment:kCCTextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        [self.energyLabel setShadowOffset:CGPointMake(-1, -1)];
        [self.energyLabel setColor:ccc3(230, 230, 230)];
        self.energyLabel.position = ccpAdd(CGPointMake(-8, -6), energyBack.position);
        [self addChild:self.energyLabel z:100];
        
        self.energyBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithSpriteFrameName:@"bar_fill_small.png"]];
        [self.energyBar setColor:ccc3(0, 0, 255)];
        self.energyBar.midpoint = CGPointMake(0, .5);
        self.energyBar.barChangeRate = CGPointMake(1.0, 0);
        self.energyBar.type = kCCProgressTimerTypeBar;
        [self.energyBar setPercentage:100];
        [self addChild:self.energyBar];
        
        CCSprite *healthBack = [CCSprite spriteWithSpriteFrameName:@"bar_back_small.png"];
        [healthBack setPosition:CGPointMake(0, 34)];
        [self addChild:healthBack];
        
        self.healthBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithSpriteFrameName:@"bar_fill_small.png"]];
        [self.healthBar setColor:ccc3(0, 255, 0)];
        self.healthBar.midpoint = CGPointMake(0, .5);
        self.healthBar.barChangeRate = CGPointMake(1.0, 0);
        self.healthBar.type = kCCProgressTimerTypeBar;
        [self.healthBar setPercentage:100];
        [self.healthBar setPosition:healthBack.position];
        [self addChild:self.healthBar];
        
        CCLabelTTFShadow *healthWordLabel = [CCLabelTTFShadow labelWithString:@"Health" dimensions:healthBack.contentSize hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:18.0f];
        [healthWordLabel setShadowOffset:CGPointMake(-1, -1)];
        [healthWordLabel setPosition:ccpAdd(healthBack.position,CGPointMake(10, -6))];
        [self addChild:healthWordLabel z:100];
        
        self.healthLabel = [CCLabelTTFShadow labelWithString:@"100%" dimensions:healthBack.contentSize hAlignment:kCCTextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        [self.healthLabel setShadowOffset:CGPointMake(-1,-1)];
        [self.healthLabel setColor:ccc3(230, 230, 230)];
        self.healthLabel.position = ccpAdd(healthBack.position, CGPointMake(-8, -6));
        [self addChild:self.healthLabel z:100];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[self.channelDelegate beginChanneling];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[self.channelDelegate endChanneling];
}

- (void)updateWithPlayer:(Player*)player
{
	[self.energyLabel setString:[NSString stringWithFormat:@"%i", (int)player.energy]];
    [self.healthLabel setString:[NSString stringWithFormat:@"%1.0f%%", player.healthPercentage * 100.0]];
    
    self.percentEnergy = player.energy/player.maximumEnergy;
    
    [self.healthBar setPercentage:player.healthPercentage * 100];
    [self.energyBar setPercentage:self.percentEnergy * 100];
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

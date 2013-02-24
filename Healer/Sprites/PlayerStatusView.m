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
@property (nonatomic, assign) ClippingNode *energyBarClippingNode;

@property (nonatomic, assign) ClippingNode *healthBarClippingNode;
@property (nonatomic, assign) CCSprite *healthBar;

@property (nonatomic, assign) CCLabelTTFShadow *healthLabel;
@end


@implementation PlayerStatusView

@synthesize channelDelegate, percentChanneled;
@synthesize energyBar, energyLabel;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        // Initialization code
		percentEnergy = 0.0;
        percentChanneled = 0.0;
        
        self.position = frame.origin;
        self.contentSize = frame.size;
        self.isTouchEnabled = YES;
        isTouched = NO;
        
        CCSprite *background = [CCSprite spriteWithSpriteFrameName:@"bar_back_small.png"];
        [background setAnchorPoint:CGPointZero];
        [self addChild:background];
        
        CCLabelTTFShadow *manaLabel = [CCLabelTTFShadow labelWithString:@"Mana" fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        [manaLabel setShadowOffset:CGPointMake(-1, -1)];
        [manaLabel setPosition:CGPointMake(34, 18)];
        [self addChild:manaLabel z:100];
        
        self.energyLabel = [CCLabelTTFShadow labelWithString:@"1000" dimensions:self.contentSize hAlignment:kCCTextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        [self.energyLabel setShadowOffset:CGPointMake(-1, -1)];
        [self.energyLabel setColor:ccc3(230, 230, 230)];
        self.energyLabel.position = CGPointMake(frame.size.width * .45, 3);
        [self addChild:self.energyLabel z:100];
        
        self.energyBar = [CCSprite spriteWithSpriteFrameName:@"bar_fill_small.png"];
        [self.energyBar setColor:ccc3(0, 0, 255)];
        [self.energyBar setPosition:CGPointMake(ENERGYBAR_INSET_WIDTH, ENERGYBAR_INSET_HEIGHT)];
        [self.energyBar setAnchorPoint:CGPointZero];
        
        self.energyBarClippingNode = [ClippingNode node];
        [self.energyBarClippingNode setAnchorPoint:CGPointZero];
        [self.energyBarClippingNode setClippingRegion:CGRectMake(0,0,0,0)];
        [self.energyBarClippingNode addChild:self.energyBar];
        
        [self addChild:self.energyBarClippingNode];
        
        CCSprite *healthBack = [CCSprite spriteWithSpriteFrameName:@"bar_back_small.png"];
        [healthBack setPosition:CGPointMake(0, 34)];
        [healthBack setAnchorPoint:CGPointZero];
        [self addChild:healthBack];
        
        self.healthBar = [CCSprite spriteWithSpriteFrameName:@"bar_fill_small.png"];
        [self.healthBar setColor:ccc3(0, 255, 0)];
        [self.healthBar setPosition:CGPointMake(ENERGYBAR_INSET_WIDTH, ENERGYBAR_INSET_HEIGHT)];
        [self.healthBar setAnchorPoint:CGPointZero];
        
        CCLabelTTFShadow *healthWordLabel = [CCLabelTTFShadow labelWithString:@"Health" fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        [healthWordLabel setShadowOffset:CGPointMake(-1, -1)];
        [healthWordLabel setPosition:CGPointMake(40, 52)];
        [self addChild:healthWordLabel z:100];
        
        self.healthLabel = [CCLabelTTFShadow labelWithString:@"100%" dimensions:self.contentSize hAlignment:kCCTextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        [self.healthLabel setShadowOffset:CGPointMake(-1,-1)];
        [self.healthLabel setColor:ccc3(230, 230, 230)];
        self.healthLabel.position = CGPointMake(frame.size.width * .45, 37);
        [self addChild:self.healthLabel z:100];
        
        self.healthBarClippingNode = [ClippingNode node];
        [self.healthBarClippingNode setPosition:CGPointMake(0, 34)];
        [self.healthBarClippingNode setAnchorPoint:CGPointZero];
        [self.healthBarClippingNode setClippingRegion:CGRectMake(0,0,0,0)];
        [self.healthBarClippingNode addChild:self.healthBar];
        
        [self addChild:self.healthBarClippingNode];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[channelDelegate beginChanneling];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[channelDelegate endChanneling];
}

- (void)updateWithPlayer:(Player*)player
{
    NSInteger playerEnergy = (int)player.energy;
	[energyLabel setString:[NSString stringWithFormat:@"%i", playerEnergy]];
    [self.healthLabel setString:[NSString stringWithFormat:@"%1.0f%%", player.healthPercentage * 100.0]];
    
    percentEnergy = ((float)playerEnergy)/player.maximumEnergy;
    
    [self.energyBarClippingNode setClippingRegion:CGRectMake(0, 0,(self.energyBar.contentSize.width + ENERGYBAR_INSET_WIDTH) * percentEnergy, self.energyBar.contentSize.height + ENERGYBAR_INSET_HEIGHT)];
    [self.healthBarClippingNode setClippingRegion:CGRectMake(0, 0,(self.healthBar.contentSize.width + ENERGYBAR_INSET_WIDTH) * player.healthPercentage, self.healthBar.contentSize.height + ENERGYBAR_INSET_HEIGHT)];
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

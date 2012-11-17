//
//  PlayerEnergyView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerEnergyView.h"
#import "ClippingNode.h"

#define ENERGYBAR_INSET_WIDTH 5.0
#define ENERGYBAR_INSET_HEIGHT 5.0

@interface PlayerEnergyView ()
@property (nonatomic, assign) ClippingNode *energyBarClippingNode;
@property (nonatomic, assign) CCLabelTTF *energyLabelShadow;
@end


@implementation PlayerEnergyView

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
        
        CCSprite *background = [CCSprite spriteWithSpriteFrameName:@"energy_bar_back.png"];
        [background setAnchorPoint:CGPointZero];
        [self addChild:background];
        
        self.energyLabel = [CCLabelTTF labelWithString:@"1000/1000" fontName:@"Marion-Bold" fontSize:18.0];
        [self.energyLabel setColor:ccc3(230, 230, 230)];
        self.energyLabel.position = CGPointMake(frame.size.width * .75, frame.size.height * .30);
        [self addChild:self.energyLabel z:100];
        
        self.energyLabelShadow = [CCLabelTTF labelWithString:@"1000/1000" fontName:@"Marion-Bold" fontSize:18.0];
        [self.energyLabelShadow setColor:ccc3(25, 25, 25)];
        self.energyLabelShadow.position = ccpSub(self.energyLabel.position, ccp(1, 1));
        [self addChild:self.energyLabelShadow z:100];
        
        self.energyBar = [CCSprite spriteWithSpriteFrameName:@"energy_bar_fill.png"];
        [self.energyBar setPosition:CGPointMake(ENERGYBAR_INSET_WIDTH, ENERGYBAR_INSET_HEIGHT)];
        [self.energyBar setAnchorPoint:CGPointZero];
        
        self.energyBarClippingNode = [ClippingNode node];
        [self.energyBarClippingNode setAnchorPoint:CGPointZero];
        [self.energyBarClippingNode setClippingRegion:CGRectMake(0,0,0,0)];
        [self.energyBarClippingNode addChild:self.energyBar];
        
        [self addChild:self.energyBarClippingNode];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[channelDelegate beginChanneling];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[channelDelegate endChanneling];
}

-(void)updateWithEnergy:(NSInteger)current andMaxEnergy:(NSInteger)max
{
	[energyLabel setString:[NSString stringWithFormat:@"%i/%i", current, max]];
    [self.energyLabelShadow setString:[NSString stringWithFormat:@"%i/%i", current, max]];
    
    percentEnergy = ((float)current)/max;
    [self.energyBarClippingNode setClippingRegion:CGRectMake(0, 0,(self.energyBar.contentSize.width + ENERGYBAR_INSET_WIDTH) * percentEnergy, self.energyBar.contentSize.height + ENERGYBAR_INSET_HEIGHT)];
}


@end

//
//  PlayerEnergyView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerEnergyView.h"


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
        //[self setDefaultBackgroundColor:ccWHITE];
        
        self.energyLabel = [CCLabelTTF labelWithString:@"100/100" fontName:@"Arial" fontSize:14];
        [self.energyLabel setColor:ccBLACK];
        self.energyLabel.position = CGPointMake(frame.size.width * .3, frame.size.width * .1);
        [self.energyLabel setContentSize:CGSizeMake(frame.size.width * .4, frame.size.height *.5)];
        [self addChild:self.energyLabel z:100];
        
        self.energyBar = [CCLayerColor layerWithColor:ccc4(0, 0, 255, 255)];
        [self.energyBar setPosition:CGPointMake(0, 0)];
        self.energyBar.contentSize = CGSizeMake(0, frame.size.height);
        [self addChild:self.energyBar];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[channelDelegate beginChanneling];
	[self setColor:ccc3(0, 255, 255)];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[channelDelegate endChanneling];
	[self setColor:ccc3(255, 255, 255)];
}


-(void)updateWithEnergy:(NSInteger)current andMaxEnergy:(NSInteger)max
{
	[energyLabel setString:[NSString stringWithFormat:@"%i/%i", current, max]];
    percentEnergy = ((float)current)/max;
    self.energyBar.contentSize = CGSizeMake(self.contentSize.width * percentEnergy, self.contentSize.height);
		
}
- (void)dealloc {
    [super dealloc];
}


@end

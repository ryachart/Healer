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

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		percentEnergy = 0.0;
    }
    return self;
}

-(void)awakeFromNib
{
	
	energyLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame)*.3,CGRectGetHeight(self.frame)*.1,CGRectGetWidth(self.frame)*.4, CGRectGetHeight(self.frame)*.5)];
	[energyLabel setBackgroundColor:[UIColor clearColor]];
	[self addSubview:energyLabel];
	[energyLabel setTextAlignment:UITextAlignmentCenter];
	[energyLabel setText:@"100/100"];
	percentEnergy = 0.0;
	percentChanneled = 0.0;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[channelDelegate beginChanneling];
	[self setBackgroundColor:[UIColor cyanColor]];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[channelDelegate endChanneling];
	[self setBackgroundColor:[UIColor whiteColor]];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGFloat x = CGRectGetWidth(self.frame) * .025;
	CGFloat y = CGRectGetHeight(self.frame) * .05;
	CGFloat height = CGRectGetHeight(self.frame) * .90;
	CGFloat width = CGRectGetWidth(self.frame) * .95 * percentEnergy;
	//NSLog(@"Width: %f", width);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context,0,.75, .75, 1);
	
	UIRectFill(CGRectMake(x,y,width,height));
}

-(void)updateWithEnergy:(NSInteger)current andMaxEnergy:(NSInteger)max
{
	[energyLabel setText:[NSString stringWithFormat:@"%i/%i", current, max]];
	[self setNeedsDisplay];
	percentEnergy = ((float)current)/max;
		
}
- (void)dealloc {
    [super dealloc];
}


@end

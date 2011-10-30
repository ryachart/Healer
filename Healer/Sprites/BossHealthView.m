//
//  BossHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BossHealthView.h"


@implementation BossHealthView

@synthesize bossNameLabel, healthLabel, bossData;
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		/*
		[self setBackgroundColor:[UIColor darkGrayColor]];
		bossNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(1, 1, CGRectGetWidth(frame), CGRectGetHeight(frame)*.25)];
		[bossNameLabel setBackgroundColor:[UIColor clearColor]];
		[bossNameLabel setFont:[UIFont	systemFontOfSize:12]];
		
		healthLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame)*.3, CGRectGetHeight(frame)*.3, CGRectGetWidth(frame)*.5, CGRectGetHeight(frame)*.25)];
		[healthLabel setBackgroundColor:[UIColor clearColor]];
		[healthLabel setFont:[UIFont systemFontOfSize:12]];
		
		[self addSubview:bossNameLabel];
		[self addSubview:healthLabel];
		 */
    }
    return self;
}



-(void)setBossData:(Boss*)theBoss
{
	bossData = theBoss;
	
	[bossNameLabel setText:[bossData title]];
	
	
}

-(void)updateHealth
{
	NSString *healthText;
	if (bossData.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.1f", (((float)bossData.health) / bossData.maximumHealth)*100];
		
	}
	else {
		healthText = @"Dead";
		[self setBackgroundColor:[UIColor redColor]];
		[self setNeedsDisplay];
	}
	
	if (![healthText isEqualToString:[healthLabel text]]){
		//NSLog(@"DIFFERENT");
		[healthLabel setText:healthText];
		[self setNeedsDisplay];
	}
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGFloat x = CGRectGetWidth(self.frame) * .005;
	CGFloat y = CGRectGetHeight(self.frame) * .05;
	CGFloat height = CGRectGetHeight(self.frame) * .90;
	double percentageOfHealth = ((float)[bossData health])/[bossData maximumHealth];
	CGFloat width = CGRectGetWidth(self.frame) * .990 * percentageOfHealth;
	//NSLog(@"Width: %f", width);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context,1,0, 0, 1);
	
	UIRectFill(CGRectMake(x,y,width,height));
}


- (void)dealloc {
    [super dealloc];
}


@end

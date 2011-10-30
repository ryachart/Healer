//
//  PlayerHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerHealthView.h"


@implementation PlayerHealthView
@synthesize memberData, healthLabel, isTouched, interactionDelegate, defaultBackgroundColor;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib{
	isTouched = NO;
	[self setDefaultBackgroundColor:[UIColor whiteColor]];
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//UITouch *touch = [touches anyObject];
	
	[[self interactionDelegate] playerSelected:self];
	isTouched = YES;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	
	isTouched = NO;
	[[self interactionDelegate] playerUnselected:self];
	
}

-(void)updateHealth
{
	NSString *healthText;
	if (memberData.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.1f", (((float)memberData.health) / memberData.maximumHealth)*100];
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
	double percentageOfHealth = ((float)[memberData health])/[memberData maximumHealth];
	CGFloat width = CGRectGetWidth(self.frame) * .990 * percentageOfHealth;
	//NSLog(@"Width: %f", width);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context,0,1, 0, 1);
	
	UIRectFill(CGRectMake(x,y,width,height));
}


- (void)dealloc {
    [super dealloc];
}


@end

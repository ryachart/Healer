//
//  PlayerCastBar.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerCastBar.h"


@implementation PlayerCastBar


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		percentTimeRemaining = 0.0;
    }
    return self;
}

-(void)awakeFromNib
{
	
	timeRemaining = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame)*.3,CGRectGetHeight(self.frame)*.1,CGRectGetWidth(self.frame)*.4, CGRectGetHeight(self.frame)*.5)];
	//[self addSubview:timeRemaining];
	[timeRemaining setTextAlignment:UITextAlignmentCenter];
	[timeRemaining setText:@"Not casting"];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGFloat x = CGRectGetWidth(self.frame) * .05;
	CGFloat y = CGRectGetHeight(self.frame) * .05;
	CGFloat height = CGRectGetHeight(self.frame) * .90;
	CGFloat width = CGRectGetWidth(self.frame) * .90 * percentTimeRemaining;
	//NSLog(@"Width: %f", width);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context,0,0, 1, 1);
	
	UIRectFill(CGRectMake(x,y,width,height));
	
	[timeRemaining drawTextInRect:timeRemaining.frame];
	
}

-(void)updateTimeRemaining:(NSTimeInterval)remaining ofMaxTime:(NSTimeInterval)maxTime
{
	
	if (remaining <= 0){
		[timeRemaining setText:@"Not casting"];
		percentTimeRemaining = 0.0;
		[self setNeedsDisplay];
	}
	else {
		percentTimeRemaining = remaining/maxTime;
		[timeRemaining setText:[NSString stringWithFormat:@"%1.2f", remaining]];
		[self setNeedsDisplay];
	}
}

- (void)dealloc {
    [super dealloc];
}


@end

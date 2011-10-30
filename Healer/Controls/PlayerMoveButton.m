//
//  PlayerMoveButton.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerMoveButton.h"


@implementation PlayerMoveButton

@synthesize isMoving;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		isMoving = NO;
		
		UILabel	*descLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)*.4, CGRectGetWidth(frame), CGRectGetHeight(frame)*.2)];
		[descLabel setText:@"Move"];
		[self addSubview:descLabel];
    }
    return self;
}

-(void)awakeFromNib{
	isMoving = NO;
	
	UILabel	*descLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.frame)*.4, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)*.2)];
	[descLabel setText:@"Move"];
	[self addSubview:descLabel];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	isMoving = YES;
	[self setBackgroundColor:[UIColor orangeColor]];
	
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	isMoving = NO;
	[self setBackgroundColor:[UIColor whiteColor]];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [super dealloc];
}


@end

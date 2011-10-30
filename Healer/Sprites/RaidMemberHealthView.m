//
//  RaidMemberHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidMemberHealthView.h"


@implementation RaidMemberHealthView

@synthesize memberData, classNameLabel, healthLabel, interactionDelegate, defaultBackgroundColor, isTouched, effectsLabel;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		classNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(1, 1, CGRectGetWidth(frame), CGRectGetHeight(frame)*.25)];
		[classNameLabel setBackgroundColor:[UIColor clearColor]];
		[classNameLabel setFont:[UIFont	systemFontOfSize:12]];

		healthLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame)*.3, CGRectGetHeight(frame)*.3, CGRectGetWidth(frame)*.5, CGRectGetHeight(frame)*.25)];
		[healthLabel setBackgroundColor:[UIColor clearColor]];
		[healthLabel setFont:[UIFont systemFontOfSize:12]];
		
		effectsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)*.85, CGRectGetWidth(frame), CGRectGetHeight(frame)*.15)];
		[effectsLabel setBackgroundColor:[UIColor clearColor]];
		[effectsLabel setFont:[UIFont systemFontOfSize:10]];
			
		//[self addSubview:classNameLabel];
		//[self addSubview:healthLabel];
		interactionDelegate = nil;
		
		isTouched = NO;
    }
    return self;
}

-(void)setMemberData:(RaidMember*)rdMember
{
	memberData = rdMember;
	
	if ([memberData class] == [Witch class]) [classNameLabel setText:@"Witch"];
	if ([memberData class] == [Ogre	 class]) [classNameLabel setText:@"Ogre"];
	if ([memberData class] == [Troll class]) [classNameLabel setText:@"Troll"];

}

-(void)updateHealth
{
	NSString *healthText;
	if (memberData.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.1f", (((float)memberData.health) / memberData.maximumHealth)*100];
		
	}
	else {
		healthText = @"Dead";
		[self setNeedsDisplay];
		[self setBackgroundColor:[UIColor redColor]];
	}
	
	NSMutableString* effectText = [[NSMutableString alloc] initWithCapacity:10];
	for (Effect *eff in self.memberData.activeEffects){
		if ([eff isKindOfClass:[HealOverTimeEffect class]]){
			[effectText appendString:@"H"];
		}
		else if ([eff isKindOfClass:[ShieldEffect class]]){
			[effectText appendString:@"S"];
		}
		else if ([eff effectType] == EffectTypePositive){
			[effectText appendString:@"P"];
		}
	}

	
	

	if (![healthText isEqualToString:[healthLabel text]] || ![effectText isEqualToString:[effectsLabel text]]){
		//NSLog(@"DIFFERENT");
		[effectsLabel setText:effectText];
		[healthLabel setText:healthText];
		[self setNeedsDisplay];
	}
	[effectText release];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//UITouch *touch = [touches anyObject];
	if (interactionDelegate != nil){
		[[self interactionDelegate] thisMemberSelected:self];
		isTouched = YES;
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (interactionDelegate != nil){
		isTouched = NO;
		[[self interactionDelegate] thisMemberUnselected:self];
	}
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGFloat percentageToFill = ((float)memberData.health)/memberData.maximumHealth;
	
	CGFloat width = CGRectGetWidth(self.frame) * .8;
	CGFloat x = CGRectGetWidth(self.frame) * .10; //10% of the rect is a border
	
	CGFloat y = CGRectGetHeight(self.frame) * .10 + (CGRectGetHeight(self.frame) * .8 * (1.0 - percentageToFill));
	CGFloat height = CGRectGetHeight(self.frame) * .8 - (CGRectGetHeight(self.frame) * .8 * (1.0 - percentageToFill));
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context,0,1, 0, 1);
	
	UIRectFill(CGRectMake(x,y,width,height));
	
	
	[classNameLabel drawTextInRect:classNameLabel.frame];
	[healthLabel drawTextInRect:healthLabel.frame];
	[effectsLabel drawTextInRect:effectsLabel.frame];
	/*
	 CGFloat R = arc4random()%200;
	 CGFloat G = arc4random()%200;
	 CGFloat B = arc4random()%200;
	 */
	
	
	
	
}


- (void)dealloc {
    [super dealloc];
}


@end

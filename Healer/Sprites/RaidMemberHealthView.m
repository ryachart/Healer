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
    if ((self = [super init])) {
        // Initialization code
        
        self.position = frame.origin;
        self.contentSize = frame.size;
        
		self.classNameLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];            // [[UILabel alloc] initWithFrame:CGRectMake(1, 1, CGRectGetWidth(frame), CGRectGetHeight(frame)*.25)];
        [self.classNameLabel setPosition:CGPointMake(1, 1)];
        [self.classNameLabel setContentSize:CGSizeMake(frame.size.width, frame.size.height)];
//		[classNameLabel setBackgroundColor:[UIColor clearColor]];
//		[classNameLabel setFont:[UIFont	systemFontOfSize:12]];

		self.healthLabel =  [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];    //[[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame)*.3, CGRectGetHeight(frame)*.3, CGRectGetWidth(frame)*.5, CGRectGetHeight(frame)*.25)];
        [self.healthLabel setPosition:CGPointMake(frame.size.width * .3, frame.size.height * .3)];
        [self.healthLabel setContentSize:CGSizeMake(frame.size.width * .5, frame.size.height * .25)];
		
		self.effectsLabel =  [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];  //[[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)*.85, CGRectGetWidth(frame), CGRectGetHeight(frame)*.15)];
        [self.healthLabel setPosition:CGPointMake(0, frame.size.height * .85)];
        [self.healthLabel setContentSize:CGSizeMake(frame.size.width, frame.size.height * .15)];
			
        
        [self addChild:self.classNameLabel];
        [self addChild:self.healthLabel];
		interactionDelegate = nil;
		
		isTouched = NO;
    }
    return self;
}

-(void)setMemberData:(RaidMember*)rdMember
{
	memberData = rdMember;
	
	if ([memberData class] == [Witch class]) [classNameLabel setString:@"Witch"];
	if ([memberData class] == [Ogre	 class]) [classNameLabel setString:@"Ogre"];
	if ([memberData class] == [Troll class]) [classNameLabel setString:@"Troll"];

}

-(void)updateHealth
{
	NSString *healthText;
	if (memberData.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.1f", (((float)memberData.health) / memberData.maximumHealth)*100];
		
	}
	else {
		healthText = @"Dead";
		[self setColor:ccc3(255, 0, 0)];
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

	
	

	if (![healthText isEqualToString:[healthLabel string]] || ![effectText isEqualToString:[effectsLabel string]]){
		//NSLog(@"DIFFERENT");
		[effectsLabel setString:effectText];
		[healthLabel setString:healthText];
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
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//	CGFloat percentageToFill = ((float)memberData.health)/memberData.maximumHealth;
//	
//	CGFloat width = CGRectGetWidth(self.frame) * .8;
//	CGFloat x = CGRectGetWidth(self.frame) * .10; //10% of the rect is a border
//	
//	CGFloat y = CGRectGetHeight(self.frame) * .10 + (CGRectGetHeight(self.frame) * .8 * (1.0 - percentageToFill));
//	CGFloat height = CGRectGetHeight(self.frame) * .8 - (CGRectGetHeight(self.frame) * .8 * (1.0 - percentageToFill));
//	
//	CGContextRef context = UIGraphicsGetCurrentContext();
//	CGContextSetRGBFillColor(context,0,1, 0, 1);
//	
//	UIRectFill(CGRectMake(x,y,width,height));
//	
//	
//	[classNameLabel drawTextInRect:classNameLabel.frame];
//	[healthLabel drawTextInRect:healthLabel.frame];
//	[effectsLabel drawTextInRect:effectsLabel.frame];
//	/*
//	 CGFloat R = arc4random()%200;
//	 CGFloat G = arc4random()%200;
//	 CGFloat B = arc4random()%200;
//	 */
//	
//	
//	
//	
//}


- (void)dealloc {
    [super dealloc];
}


@end
